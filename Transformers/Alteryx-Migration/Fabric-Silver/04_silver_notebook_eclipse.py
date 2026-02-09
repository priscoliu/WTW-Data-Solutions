# COMMAND ----------
# Cell 1: Setup & Configuration
# -----------------------------
from pyspark.sql.functions import col, when, trim, upper, lit, current_date, coalesce, isnan, count, concat, expr, size, collect_set
from pyspark.sql.types import IntegerType, DoubleType, DateType
from pyspark.sql.utils import AnalysisException

# Helper: Safe Casting
def safe_cast_number(df, cols):
    for c in cols:
        if c in df.columns:
            # Replace #N/A, NaN, empty string, then cast
            df = df.withColumn(c, 
                               when(col(c).cast("string").isin("#N/A", "NaN", ""), lit(0))
                               .otherwise(col(c)).cast(DoubleType()))
            df = df.fillna(0, subset=[c])
    return df

# COMMAND ----------
# Cell 2: Load Bronze Data
# ------------------------
# 1. Asia Stream (Eclipse Recurring Report)
try:
    df_asia = spark.read.format("delta").load("Tables/src_eclipse_asia")
    df_asia = df_asia.withColumn("Origin_Stream", lit("Asia"))
except AnalysisException:
    print("WARNING: src_eclipse_asia not found. Creating empty dummy DF.")
    df_asia = spark.createDataFrame([], schema="LegalEntity string, BusinessUnit string, Team string, ClassOfBusiness string, UW string")

# 2. London Stream (Combined MIR files)
try:
    df_london = spark.read.format("delta").load("Tables/src_eclipse_london")
    df_london = df_london.withColumn("Origin_Stream", lit("London"))
except AnalysisException:
    print("WARNING: src_eclipse_london not found. Creating empty dummy DF.")
    df_london = spark.createDataFrame([], schema="LegalEntity string, BusinessUnit string, Team string, ClassOfBusiness string, UW string")

# COMMAND ----------
# Cell 3: Transformation Logic (Replicating Alteryx Tools 93 & 134)
# -----------------------------------------------------------------

# --- ASIA LOGIC (Alteryx Tool 93) ---
# REVENUE COUNTRY Logic:
cond_rev_country_asia = (
    when(col("BU + TEAM") == "Retail+Commercial", "Singapore")
    .when(col("BU + TEAM") == "Retail+Construction", "Singapore")
    .when(col("BU + TEAM").contains("Retail+Client Service Team"), "Singapore")
    .when(col("LegalEntity").contains("Hong Kong"), "Hong Kong")
    .when(col("LegalEntity").contains("Philippines"), "Philippines")
    .otherwise("Regional Specialism")
)

df_asia_trans = df_asia \
    .withColumn("DATA SOURCE", lit("Eclipse")) \
    .withColumn("CLIENT ID", coalesce(col("Willis Party ID"), col("InsuredID"))) \
    .withColumn("BU + TEAM", concat(col("BusinessUnit"), lit("+"), col("Team"))) \
    .withColumn("REVENUE COUNTRY", cond_rev_country_asia) \
    .withColumn("PRODUCTS TO BE MAPPED", upper(concat(col("BusinessUnit"), lit("+"), col("Team"), lit("+"), col("ClassOfBusiness")))) \
    .withColumn("UW_CLEAN", upper(trim(col("UW"))))

# --- LONDON LOGIC (Alteryx Tool 134) ---
df_london_trans = df_london \
    .withColumn("DATA SOURCE", lit("Eclipse")) \
    .withColumn("CLIENT ID", coalesce(col("Willis Party ID"), col("InsuredID"))) \
    .withColumn("REVENUE COUNTRY", lit("London Placements")) \
    .withColumn("PRODUCTS TO BE MAPPED", upper(trim(col("ClassOfBusiness")))) \
    .withColumn("UW_CLEAN", upper(trim(col("UW"))))

# COMMAND ----------
# Cell 4: Union & Unification (Replacting Alteryx Union)
# ------------------------------------------------------
# Standardize columns before union if needed, or rely on allowMissingColumns
df_unified = df_asia_trans.unionByName(df_london_trans, allowMissingColumns=True)

# Common Final Transform (Alteryx Select Tool 131 Rename)
df_final = df_unified \
    .withColumnRenamed("Team", "DEPARTMENT") \
    .withColumnRenamed("PolicyRef", "INVOICE/POLICY NUMBER") \
    .withColumnRenamed("BusinessType", "BUSINESS TYPE") \
    .withColumnRenamed("InceptionDate", "INCEPTION DATE") \
    .withColumnRenamed("ExpiryDate", "EXPIRY DATE") \
    .withColumnRenamed("Account Handler", "ACCOUNT HANDLER") \
    .withColumnRenamed("CreatedDate", "INVOICE DATE") \
    .withColumnRenamed("Insured", "CLIENT NAME") \
    .withColumnRenamed("UW", "INSURER NAME") \
    .withColumnRenamed("UWCountry", "INSURER COUNTRY") \
    .withColumnRenamed("GrossBkgeUSDPlan", "BROKERAGE (USD)") \
    .withColumnRenamed("GrossPremNonTtyUSDPlan", "PREMIUM (USD)") \
    .withColumnRenamed("ClassOfBusiness", "SYSTEM PRODUCT ID") \
    .withColumnRenamed("Willis Party ID", "PARTY ID (WTW)") \
    .withColumnRenamed("Dun and Bradstreet No", "DUNS NUMBER") \
    .withColumnRenamed("Revenue Type", "TRANSACTION TYPE")

# Clean Numeric Columns
num_cols = ["BROKERAGE (USD)", "PREMIUM (USD)", "NetBkgeUSDPlan", "NetClientPremNonTtyUSDPlan"]
df_final = safe_cast_number(df_final, num_cols)

# COMMAND ----------
# Cell 5: Reference Joins (Replicating Tools 101, 102, 139, 140)
# --------------------------------------------------------------

# 1. Load Reference Tables
try:
    ref_insurer = spark.read.format("delta").load("Tables/ref_insurer_mapping")
    ref_product = spark.read.format("delta").load("Tables/ref_eclipse_product_mapping")
except:
    print("Reference tables missing. Skipping joins (Mock Mode).")
    ref_insurer = None
    ref_product = None

# 2. Join Insurer
if ref_insurer:
    df_joined_1 = df_final.join(ref_insurer, df_final["INSURER NAME"] == ref_insurer.Insurer, "left")
else:
    df_joined_1 = df_final

# 3. Join Product
if ref_product:
    # Note: Asia used 'PRODUCTS TO BE MAPPED', London used the same field name but different logic
    df_joined_2 = df_joined_1.join(ref_product, df_joined_1["PRODUCTS TO BE MAPPED"] == ref_product["Filter Fac Product"], "left")
else:
    df_joined_2 = df_joined_1

# COMMAND ----------
# Cell 6: Write to Silver
# -----------------------
df_joined_2.write.format("delta").mode("overwrite").save("Tables/clean_eclipse")

print(f"Success. Rows Processed: {df_joined_2.count()}")
display(df_joined_2.limit(10))
