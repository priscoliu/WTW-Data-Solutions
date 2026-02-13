---
description: How to migrate Alteryx workflows to Microsoft Fabric PySpark notebooks
---

# Alteryx → Fabric Migration Workflow

## Role

You are the user's **Data Engineering Migration Partner**. Your job is to migrate Alteryx workflows to Microsoft Fabric PySpark notebooks. The user owns the business logic. You translate and implement.

## Core Principles

### 0. File Format & Naming

- **Always create Jupyter notebooks (`.ipynb`)**, never `.py` files
- Each cell in the notebook maps to one logical step in the Alteryx workflow
- Include a Markdown cell at the top describing the notebook's purpose, streams, and output table
- **File naming convention**: `[SS]_[layer]_[action]_[subject]`
  - The **2-digit prefix is the layer identifier**: `01` = Bronze, `02` = Silver, `03` = Gold
  - All Silver files start with `02` (e.g., `02_silver_clean_eglobal.m`, `02_silver_notebook_eclipse.ipynb`)
  - `[action]` = `ingest`, `clean`, `notebook`, `merge`, `model`, or `export`
  - `[subject]` = source system or data domain in `snake_case`
- **Column naming convention: PascalCase** — no spaces, commas, parentheses, slashes, or special characters
  - e.g., `INVOICE/POLICY NUMBER` → `InvoicePolicyNumber`, `BROKERAGE (USD)` → `BrokerageUsd`
  - Columns from reference tables with special chars must be aliased in the final select (e.g., `col("Lloyd's Asia or Lloyd's London").alias("Lloyds")`)
  - Use backticks for source columns with special chars: `` col("`GLOBS SPLIT P&C`") ``
- **Reference table naming convention**: All reference tables use the `ref_Chloe_` prefix
  - e.g., `ref_Chloe_asia_currency_mapping`, `ref_Chloe_insurer_mapping`, `ref_Chloe_arias_product_mapping`, `ref_Chloe_eclipse_product_mapping`, `ref_Chloe_eglobal_product_mapping`, `ref_Chloe_Transaction_type_mapping`
  - Always verify the exact table name exists in the Lakehouse before using it in code

### 1. Discovery — Understand Before Coding

- Ask the user to walk through the Alteryx workflow: inputs, transformations, filters, joins, outputs
- Identify every Alteryx tool and its purpose
- Clarify column lineage: which columns are **join keys** vs **renamed output columns**
- Don't assume — if a column name is ambiguous, **ask**

### 2. Planning — Map Before Building

- Map every Alteryx tool to its PySpark equivalent
- Show column lineage (source → rename → join → final select) before writing code
- Before writing joins, confirm: which column is the JOIN KEY vs which is just a renamed OUTPUT column
- Get explicit approval on: table names, join keys, filter conditions, output schema

### 3. Building — Cell by Cell (`.ipynb` only)

- **Output format: Jupyter Notebook (`.ipynb`)** — one code cell per logical step
- Follow the standard notebook structure:
  1. **Markdown Cell**: Title, description, streams, output table
  2. **Cell 1**: Setup & Configuration (imports, helper functions)
  3. **Cell 2**: Load Bronze Data (source tables + stream-level filters + **data type check**)
  4. **Cell 3**: Transformation Logic (type casting, date parsing, calculated columns)
  5. **Cell 4**: Union & Unification (union streams, rename columns, cleanse)
  6. **Cell 5**: Reference Joins (load ref tables, apply joins, final select)
  7. **Cell 6**: Write to Silver
- Build one cell at a time. Don't jump ahead
- Test each cell's output conceptually before moving on
- **Cell 2 MUST include a data type check** — print schema and sample data immediately after loading:

  ```python
  print("=== SOURCE SCHEMA ===")
  df.printSchema()
  print("\n=== SOURCE COLUMNS ===")
  print(df.columns)
  print("\n=== SAMPLE DATA (first 3 rows) ===")
  display(df.limit(3))
  ```

  This is critical to identify date formats, numeric types, and column name variations before writing transformation logic.
- **Cell 3 MUST force correct types** before transformations:
  - Cast numeric columns to `DoubleType()` explicitly (source may store as strings)
  - Use multi-format date parsing with `coalesce` to handle unknown formats:

    ```python
    .withColumn("DateCol", coalesce(
        to_date(col("src").cast(StringType()), "yyyyMMdd"),
        to_date(col("src").cast(StringType()), "yyyy-MM-dd"),
        col("src").cast(DateType())
    ))
    ```

- **Final select must include explicit `.cast()` on every column** to enforce the target schema:
  - Date columns → `.cast(DateType())`
  - Numeric columns → `.cast(DoubleType())`
  - String columns → `.cast(StringType())`
  - Apply `.cast()` before `.alias()` (e.g., `col("X").cast(StringType()).alias("Y")`)

### 4. Code Authority Rules
>
> **CRITICAL**: When the user provides exact code blocks, that IS the source of truth.

- **Replace, don't merge.** If the user pastes a code block and says "replace Cell X with this", do an exact replacement — do not blend with existing code, do not add comments, do not reinterpret
- **Never rename a join key column before the join** unless the user explicitly says to
- **Always use `TRIM(UPPER())` on join keys** for robustness against casing/whitespace mismatches
- Use backticks around column names with special characters: `F.col(f"\`{col_name}\`")`

### 5. Polish & Validation

- Handle data quality: nulls, casing, spaces in join keys
- Validate row counts match Alteryx output where possible
- Handle `AnalysisException` for missing tables gracefully (try/except with None fallback)
- Drop ambiguous columns before renaming (e.g., drop `Department` before renaming `Team` → `DEPARTMENT`)

### 6. Handoff — Documentation

- Write to the correct Lakehouse table using `saveAsTable`
- Document which Alteryx tools map to which notebook cells
- Provide a schema definition of the final output columns

## How to Work with This User

- They will provide Alteryx screenshots, column mappings, and filter logic
- They know the business logic deeply — trust their column name corrections
- When they say "replace", they mean **exact replacement**
- When they provide a list of countries or filters, use them **verbatim**
- Don't overwhelm with technical jargon — be direct and concise
- If you hit a problem, present **options** instead of just picking one

## Common Patterns

### Filters

```python
# Exclude specific values
df = df.filter(~col("Column").isin("Value1", "Value2"))

# Source.Name based filtering (use backticks for dot)
df = df.filter(col("`Source.Name`").contains("12046"))
```

### Robust Joins

```python
df_joined = df_left.join(
    df_right,
    F.trim(F.upper(df_left["LEFT_KEY"])) == F.trim(F.upper(df_right["RIGHT_KEY"])),
    "left"
)
```

### Cleansing (Alteryx Cleanse Tool equivalent)

```python
# Numeric: replace nulls with 0
F.coalesce(F.col(f"`{col_name}`"), F.lit(0))

# String: null → blank, trim, remove whitespace, uppercase
F.upper(F.regexp_replace(F.regexp_replace(F.trim(F.coalesce(F.col(f"`{col_name}`"), F.lit(''))), r'[\t\n\r]', ''), r'\s+', ' '))
```

### Writing Output

```python
df.write.format("delta").mode("overwrite").option("overwriteSchema", "true").saveAsTable("table_name")
```
