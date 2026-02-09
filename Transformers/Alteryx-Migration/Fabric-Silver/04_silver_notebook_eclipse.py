# COMMAND ----------
# Cell 1: Setup & Configuration
# -----------------------------
from pyspark.sql.functions import col, when, trim, upper, lit, current_date, coalesce, isnan, count, concat, expr, size, collect_set, regexp_replace
import pyspark.sql.functions as F
from pyspark.sql.types import IntegerType, DoubleType, DateType, StringType, LongType, FloatType, DecimalType
from pyspark.sql.utils import AnalysisException
import re

# Helper: Safe Casting
# --- APPLY CLEANSING TRANSFORMATIONS ---
print("Applying cleansing transformations...")

def cleanse_dataframe(df):
    print("Applying cleansing transformations...")
    
    string_cols = [f.name for f in df.schema.fields if isinstance(f.dataType, StringType)]
    numeric_cols = [f.name for f in df.schema.fields if isinstance(f.dataType, (IntegerType, DoubleType, LongType, FloatType, DecimalType))]

    cleansed_df = df

    for col_name in numeric_cols:
        cleansed_df = cleansed_df.withColumn(
            col_name,
            F.coalesce(F.col(f"`{col_name}`"), F.lit(0))
        )

    for col_name in string_cols:
        cleansed_df = cleansed_df.withColumn(
            col_name,
            F.upper(
                F.regexp_replace(
                    F.regexp_replace(
                        F.trim(
                            F.coalesce(F.col(f"`{col_name}`"), F.lit(''))
                        ),
                        r'[\t\n\r]', ''
                    ),
                    r'\s+', ' '
                )
            )
        )

    if 'Likelihood_of_Win' in cleansed_df.columns:
        cleansed_df = cleansed_df.withColumn(
            "Likelihood_of_Win",
            F.regexp_replace(F.col("`Likelihood_of_Win`"), "%", "").cast(DoubleType())
        )

    print("Cleansing finished.")
    return cleansed_df

# COMMAND ----------
# Cell 2: Load Bronze Data
# ------------------------
# 1. Asia Stream (Eclipse Recurring Report)
try:
    # UPDATED: Using SQL Endpoint access as per standard
    df_asia = spark.sql("SELECT * FROM APAC_CRM_Analytics_LH.src_eclipse_crb")
    df_asia = df_asia.withColumn("Origin_Stream", lit("Asia")) \
        .filter(~col("LegalEntity").isin("PT. Willis Reinsurance Brokers Indonesia", "Willis Towers Watson Taiwan Limited"))
except AnalysisException:
    print("WARNING: src_eclipse_crb not found in APAC_CRM_Analytics_LH. Creating empty dummy DF.")
    df_asia = spark.createDataFrame([], schema="LegalEntity string, BusinessUnit string, Team string, ClassOfBusiness string, UW string")

# 2. London Stream (Combined MIR files)
try:
    # UPDATED: Using SQL Endpoint access as per standard
    df_london = spark.sql("SELECT * FROM APAC_CRM_Analytics_LH.src_eclipse_london")
    df_london = df_london.withColumn("Origin_Stream", lit("London"))

    # London Filters (Source.Name based logic)
    # Lists for exclusion based on filename context
    exclude_12046 = ["China", "Hong Kong", "India", "Japan", "Malaysia", "New Zealand", "Philippines", "Republic of Korea", "Singapore", "Taiwan", "Thailand"]
    exclude_12047 = ["Bahrain", "Cyprus", "Georgia", "Jordan", "Kazakhstan", "Kuwait", "Oman", "Qatar", "Turkey", "United Arab Emirates"]

    # Condition: (Contains 12046 AND Country in Exclude List A) OR (Contains 12047 AND Country NOT in Exclude List B)
    # Using backticks for Source.Name to handle the dot
    cond_exclude = (
        (col("`Source.Name`").contains("12046") & col("UWCountry").isin(exclude_12046)) | 
        (col("`Source.Name`").contains("12047") & ~col("UWCountry").isin(exclude_12047))
    )
    df_london = df_london.filter(~cond_exclude)
except AnalysisException:
    print("WARNING: src_eclipse_london not found in APAC_CRM_Analytics_LH. Creating empty dummy DF.")
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
    .withColumn("UW_CLEAN", upper(trim(col("UW")))) \
    .withColumn("FINAL DATE", when(col("TransRef") == "INVOICE DATE", col("CreatedDate")).otherwise(col("InceptionDate"))) \
    .withColumn("POLICY DESCRIPTION", when(col("BusinessType") == "Reinsurance", lit("Reinsurance")).otherwise(lit("null"))) \
    .withColumn("REINSURANCE DESCRIPTION", lit("null"))

# --- LONDON LOGIC (Alteryx Tool 134) ---
df_london_trans = df_london \
    .withColumn("DATA SOURCE", lit("Eclipse")) \
    .withColumn("CLIENT ID", coalesce(col("Willis Party ID"), col("InsuredID"))) \
    .withColumn("REVENUE COUNTRY", lit("London Placements")) \
    .withColumn("PRODUCTS TO BE MAPPED", trim(upper(col("ClassOfBusiness")))) \
    .withColumn("UW_CLEAN", upper(trim(col("UW")))) \
    .withColumn("FINAL DATE", when(col("TransRef") == "INVOICE DATE", col("CreatedDate")).otherwise(col("InceptionDate"))) \
    .withColumn("POLICY DESCRIPTION", when(col("BusinessType") == "Reinsurance", lit("Reinsurance")).otherwise(lit("null"))) \
    .withColumn("REINSURANCE DESCRIPTION", lit("null"))

# COMMAND ----------
# Cell 4: Union & Unification (Replacting Alteryx Union)
# ------------------------------------------------------
# Standardize columns before union if needed, or rely on allowMissingColumns
df_unified = df_asia_trans.unionByName(df_london_trans, allowMissingColumns=True)

# Common Final Transform (Alteryx Select Tool 131 Rename)
# We rename columns first to matches the target schema before cleaning and joining

# FIX: Drop existing 'DEPARTMENT' column if it exists to avoid ambiguity when renaming 'Team'
# Spark's drop is case-insensitive usually, but being explicit.
for c in [col_name for col_name in df_unified.columns if col_name.lower() == "department"]:
    df_unified = df_unified.drop(c)

df_renamed = df_unified \
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

# --- APPLY CLEANSING TRANSFORMATIONS ---
# Apply the robust cleansing function here (Replaces nulls, trims, uppercases strings)
df_cleansed = cleanse_dataframe(df_renamed)

# Clean Numeric Columns (Safe Cast)
num_cols = ["BROKERAGE (USD)", "PREMIUM (USD)", "NetBkgeUSDPlan", "NetClientPremNonTtyUSDPlan"]
df_final = safe_cast_number(df_cleansed, num_cols)

# COMMAND ----------
# Cell 5: Reference Joins (Replicating Tools 101, 102, 139, 140 & Unique Workers 258)
# --------------------------------------------------------------

# 1. Load Reference Tables
try:
    # UPDATED: Using SQL Endpoint access as per standard, correct table names
    ref_insurer = spark.sql("SELECT * FROM APAC_CRM_Analytics_LH.ref_Chloe_insurer_mapping")
    ref_product = spark.sql("SELECT * FROM APAC_CRM_Analytics_LH.ref_Chloe_eclipse_product_mapping")
    ref_trans = spark.sql("SELECT * FROM APAC_CRM_Analytics_LH.ref_Chloe_Transaction_type_mapping")
except:
    print("Reference tables missing (Insurer/Product/TransType). Skipping specific joins (Mock Mode).")
    ref_insurer = None
    ref_product = None
    ref_trans = None


# 2. Join Insurer
if ref_insurer:
    # Join on INSURER NAME == Insurer (Robust: Trim + Upper)
    df_joined_1 = df_final.join(
        ref_insurer, 
        F.trim(F.upper(df_final["INSURER NAME"])) == F.trim(F.upper(ref_insurer["Insurer"])), 
        "left"
    )
else:
    df_joined_1 = df_final

# 3. Join Product
if ref_product:
    # Join on PRODUCTS TO BE MAPPED == Filter Fac Product (Robust: Trim + Upper)
    df_joined_2 = df_joined_1.join(
        ref_product, 
        F.trim(F.upper(df_joined_1["PRODUCTS TO BE MAPPED"])) == F.trim(F.upper(ref_product["Filter Fac Product"])), 
        "left"
    )
else:
    df_joined_2 = df_joined_1

# 4. Join Transaction Type
if ref_trans:
    # Join on TransType == TransType (Robust: Trim + Upper)
    df_joined_3 = df_joined_2.join(
        ref_trans, 
        F.trim(F.upper(df_joined_2["TransType"])) == F.trim(F.upper(ref_trans["TransType"])), 
        "left"
    )
else:
    df_joined_3 = df_joined_2

# 5. Join Unique Workers (REMOVED as per request)
# df_enriched = df_joined_3 ... 

# Set final dataframe for output
df_enriched = df_joined_3.select(
    col("DEPARTMENT"),
    col("INVOICE/POLICY NUMBER"),
    col("BUSINESS TYPE"),
    col("INCEPTION DATE"),
    col("EXPIRY DATE"),
    col("ACCOUNT HANDLER"),
    col("INVOICE DATE"),
    col("CLIENT NAME"),
    col("INSURER NAME"),
    col("INSURER COUNTRY"),
    col("BROKERAGE (USD)"),
    col("PREMIUM (USD)"),
    col("SYSTEM PRODUCT ID"),
    col("PARTY ID (WTW)"),
    col("DUNS NUMBER"),
    col("TRANSACTION TYPE"),
    col("DATA SOURCE"),
    col("CLIENT ID").alias("CLIENT ID (WTW)"),
    col("REVENUE COUNTRY"),
    col("FINAL DATE"),
    col("POLICY DESCRIPTION"),
    col("REINSURANCE DESCRIPTION"),
    col("MAPPED_INSURER").alias("INSURER MAPPING"),
    col("Lloyd's Asia or Lloyd's London").alias("LLOYDS"),
    col("Level 2 Mapping").alias("SUB PRODUCT CLASS"),
    col("GLOBS"),
    col("GLOBS SPLIT P&C")
    # SYSTEM ID skipped if not known source, assuming specific list
)

# COMMAND ----------
# Cell 6: Write to Silver
# -----------------------
# Using saveAsTable to default catalog/schema if configured, or specific path
# User indicated output to Lakehouse, likely a specific table
target_table = "APAC_Reporting_LH.clean_eclipse"  # Assuming schema based on user input 'APAC_Reporting_LH' and file context

print(f"Writing to {target_table}...")
df_enriched.write.format("delta").mode("overwrite").option("overwriteSchema", "true").saveAsTable("clean_eclipse") 

print(f"Success. Rows Processed: {df_enriched.count()}")
display(df_enriched.limit(10))
