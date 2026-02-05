# COMMAND ----------
# Cell 1: Setup & Configuration
# -----------------------------
# Import necessary libraries
from pyspark.sql.functions import col, when, trim, upper, lit, current_date, expr, coalesce, isnan, count, sum as _sum
from pyspark.sql.types import DoubleType, DateType, StringType

# Define Table Names (Update these if your Lakehouse names differ)
TABLE_SRC = "src_eglobal_premium_report"
TABLE_REF_BRANCH = "ref_eglobal_premium_branch_mapping"
TABLE_REF_CCY = "ref_Chloe_asia_currency_mapping"
TABLE_REF_PRODUCT = "ref_Chloe_eglobal_product_mapping"
TABLE_REF_INSURER = "ref_Chloe_insurer_mapping"

TABLE_DEST = "clean_eglobal"

print(f"Configuration Loaded. Destination Table: {TABLE_DEST}")

# COMMAND ----------
# Cell 2: Load Data & Initial QC
# ------------------------------
# Read Bronze Data
df_raw = spark.read.table(TABLE_SRC)

# QC: Initial Row Count
count_initial = df_raw.count()
print(f"Initial Row Count: {count_initial}")

# QC: Check for Nulls in critical columns to identify 'Bad Data' immediately
print("--- Missing Value Summary (Top 5 Columns) ---")
df_raw.select([count(when(col(c).isNull() | isnan(c), c)).alias(c) for c in df_raw.columns[:5]]).show()

# QC: Display sample for visual check
display(df_raw.limit(5))

# COMMAND ----------
# Cell 3: Data Cleaning & Standardization
# ---------------------------------------
# 1. Filter out ACCIDENT records
df_clean = df_raw.filter(
    col("LINE OF BUSINESS").isNull() | 
    (~upper(col("LINE OF BUSINESS")).contains("ACCIDENT"))
)

print(f"Rows after 'ACCIDENT' filter: {df_clean.count()}")

# 2. Standardize Text Columns (Trim + Upper)
# List of columns to standardize
cols_to_upper = ["RISK DESCRIPTION", "INSURER NAME", "Source.Name", "INS BRANCH"]

for c in cols_to_upper:
    # Use Coalesce to handle nulls safely (don't uppercase null)
    if c in df_clean.columns:
        df_clean = df_clean.withColumn(c, trim(upper(col(c))))

# 3. Handle '#N/A' and Invalid Numbers
# Define numeric columns that often have errors
numeric_cols = ["Premium", "Brokerage", "Levies A", "Levies B"]

for c in numeric_cols:
    if c in df_clean.columns:
        # Step A: Replace "#N/A" strings and standard Excel errors with Null
        df_clean = df_clean.withColumn(c, 
            when(col(c).isin("#N/A", "N/A", "NaN", "null"), None)
            .otherwise(col(c))
        )
        # Step B: Cast to Double (Forces non-numbers to Null)
        df_clean = df_clean.withColumn(c, col(c).cast(DoubleType()))
        # Step C: (Optional) Fill Nulls with 0 if business requires, otherwise leave Null
        # df_clean = df_clean.fillna(0, subset=[c]) 

print("Data Cleaning Complete. '#N/A' values replaced with Null.")

# COMMAND ----------
# Cell 4: Transformations (Dates & Country Logic)
# -----------------------------------------------

# 1. Invoice Date Next Year
df_trans = df_clean.withColumn("INVOICE DATE NEXT YEAR", expr("date_add(`INVOICE DATE`, 365)"))

# 2. Replace Effective/Expiry Dates if Null
df_trans = df_trans.withColumn("EFFECTIVE DATE", 
    coalesce(col("EFFECTIVE DATE"), col("INVOICE DATE"))
).withColumn("EXPIRY DATE", 
    coalesce(col("EXPIRY DATE"), col("INVOICE DATE NEXT YEAR"))
)

# 3. Revenue Country Logic (Includes AU/NZ)
# Note: Using `Source.Name` (ensure column name exists and is escaped if it has dot)
df_trans = df_trans.withColumn("Revenue Country",
    when(col("Source.Name").contains("CHINA"), "China")
    .when(col("Source.Name").contains("HONGKONG"), "Hong Kong")
    .when(col("Source.Name").contains("INDONESIA"), "Indonesia")
    .when(col("Source.Name").contains("TAIWAN"), "Taiwan")
    .when(col("Source.Name").contains("KOREA"), "Korea")
    .when(col("Source.Name").contains("PHILIPPINES"), "Philippines")
    .when(col("Source.Name").contains("AUSTRALIA"), "Australia")
    .when(col("Source.Name").contains("NEW ZEALAND"), "New Zealand")
    .otherwise(None)
)

# 4. Currency (CCY) Logic based on Revenue Country
df_trans = df_trans.withColumn("CCY",
    when(col("Revenue Country") == "China", "CNY")
    .when(col("Revenue Country") == "Hong Kong", "HKD")
    .when(col("Revenue Country") == "Indonesia", "IDR")
    .when(col("Revenue Country") == "Taiwan", "TWD")
    .when(col("Revenue Country") == "Korea", "KRW")
    .when(col("Revenue Country") == "Philippines", "PHP")
    .when(col("Revenue Country") == "Australia", "AUD")
    .when(col("Revenue Country") == "New Zealand", "NZD")
    .otherwise(None)
)

# 5. Create Join Keys (CCYYEAR)
df_trans = df_trans.withColumn("FINAL YEAR", expr("year(`INVOICE DATE`)").cast(StringType()))
df_trans = df_trans.withColumn("CCYYEAR", 
    when(col("CCY").isNotNull() & col("FINAL YEAR").isNotNull(), 
         expr("concat(CCY, '-', `FINAL YEAR`)"))
    .otherwise(None)
)

print("Core Business Logic Applied.")

# COMMAND ----------
# Cell 5: Reference Data Joins
# ----------------------------

# Load Reference Tables
ref_branch = spark.read.table(TABLE_REF_BRANCH)
ref_ccy = spark.read.table(TABLE_REF_CCY)
ref_prod = spark.read.table(TABLE_REF_PRODUCT)
ref_insurer = spark.read.table(TABLE_REF_INSURER)

# 1. Join Branch Mapping (Left Join)
df_joined = df_trans.join(ref_branch, df_trans["INS BRANCH"] == ref_branch["BRANCH"], "left") \
    .drop(ref_branch["BRANCH"]) \
    .withColumnRenamed("INSURER COUNTRY", "MAPPED_INS_COUNTRY") # Rename to avoid collision

# Logic: Use Mapped Country if Hong Kong, else keep original
df_joined = df_joined.withColumn("INSURER COUNTRY",
    when((col("Source.Name").contains("HONGKONG")) & col("MAPPED_INS_COUNTRY").isNotNull(), col("MAPPED_INS_COUNTRY"))
    .otherwise(col("INSURER COUNTRY"))
).drop("MAPPED_INS_COUNTRY")

# 2. Join Currency Rate (CCYVALUE)
df_joined = df_joined.join(ref_ccy, "CCYYEAR", "left") \
    .withColumnRenamed("Value", "CCYVALUE")

# 3. Join Product Mapping
df_joined = df_joined.join(ref_prod, df_joined["RISK DESCRIPTION"] == ref_prod["SYSTEM PRODUCT ID"], "left") \
    .drop(ref_prod["SYSTEM PRODUCT ID"])

# 4. Join Insurer Mapping
df_joined = df_joined.join(ref_insurer, df_joined["INSURER NAME"] == ref_insurer["Insurer"], "left") \
    .drop(ref_insurer["Insurer"])

print(f"Joins Complete. Columns: {len(df_joined.columns)}")

# COMMAND ----------
# Cell 6: Final Calculations (USD) & QC
# -------------------------------------

# Calculate USD columns
# Handle Nulls: If Premium or Rate is Null, result is Null (Safest approach)
df_final = df_joined.withColumn("PREMIUM (USD)", col("Premium") * col("CCYVALUE")) \
                    .withColumn("BROKERAGE (USD)", col("Brokerage") * col("CCYVALUE"))

# Create System ID
df_final = df_final.withColumn("SYSTEM ID", expr("concat(coalesce(COMPANY,''), coalesce(BRANCH,''), coalesce(`CLIENT NUMBER`,''))"))

# Final Data Quality Check
count_final = df_final.count()
print(f"Final Row Count: {count_final}")

# Check for exploding joins (if rows increased unexpectedly)
if count_final > count_initial:
    print(f"WARNING: Row count increased by {count_final - count_initial}. Check for duplicates in mapping tables!")
else:
    print("Row count looks healthy (matches or decreased due to filters).")

display(df_final.select("Source.Name", "Revenue Country", "Premium", "CCY", "CCYVALUE", "PREMIUM (USD)").limit(10))

# COMMAND ----------
# Cell 7: Write to Lakehouse (Silver)
# ----------------------------------
# Overwrite or Append? Usually Overwrite for full reload, or Merge for incremental.
# Using Overwrite for simplicity here.

df_final.write.format("delta").mode("overwrite").option("overwriteSchema", "true").saveAsTable(TABLE_DEST)

print(f"Successfully wrote {count_final} rows to {TABLE_DEST}")
