# Agent Guidelines & Context

## About This Project

**WTW Data Solutions System** is the central hub for data engineering and visualization at Willis Towers Watson. This workspace unifies:

1. **Transformers**: Data engineering (Alteryx, SQL, Fabric).
2. **Semantic Models**: Data modeling (Power BI, DAX).
3. **Design System**: Visual reporting (HTML Cards, SVG, Branding).

## Microsoft Fabric Standards

### Lakehouse Naming Conventions

Follow this pattern for all Lakehouse objects (Tables) and ETL Artifacts (Notebooks/Dataflows).

| Category | Object Type | Naming Pattern | Examples | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **Tables** | **Bronze Layer** (Raw) | `src_[Source]_[Content]` | `src_saiba_policies` | Raw input. Group by source. |
| **Tables** | **Silver Layer** (Clean) | `clean_[Content]` or `master_[Entity]` | `clean_baseline_union` | Technical fixes / Deduplicated master. |
| **Tables** | **Gold Layer** (Power BI) | `fact_[Process]` or `dim_[Context]` | `fact_transactions` | Star Schema standards. |
| **ETL** | **Notebooks / Dataflows** | `[Seq]_[Layer]_[Action]_[Subject]` | `01_bronze_ingest_saiba` | Sortable execution order. |

#### Prefix Reference

* **src_**: Source / Raw data (Bronze).
* **clean_**: Technical fixes (Silver).
* **master_**: Deduplicated entities (Silver).
* **dim_**: Dimension (Who, What, Where, When) (Gold).
* **fact_**: Fact (How much, How many) (Gold).
* **agg_**: Pre-calculated totals.
* **map_**: Mapping tables.

#### ETL Actions

* **ingest**: Source -> Bronze
* **clean**: Bronze -> Silver (Fixes)
* **merge/union**: Combining sources
* **model**: Silver -> Gold (Star Schema)
* **export**: Lakehouse -> External

### Fabric Dataflow Best Practices

#### Robust Data Handling (Coping Mechanism)

Fabric Lakehouses are strict about data types (unlike Power Query preview). writing "Text" into a "Number" column causes refresh failures (Error 104100).

**Standard: Safe Numeric Conversion (The "Try-Otherwise" Pattern)**
For all Bronze Layer ingestion of Excel/Text files, use the robust `try Number.From(_) otherwise 0` pattern directly in `Table.TransformColumns`.

* **Use `type nullable number`** even for integers (avoid `Int64.Type` errors).
* **Do not use separate Clean/Trim steps** if finding they break the query; `Number.From` handles standard whitespace well, provided you handle the error.

**Pattern (M Code)**:

```powerquery
#"Safe Numeric Conversion" = Table.TransformColumns(#"Promoted headers", {
    {"PREMIUM", each try Number.From(_) otherwise 0, type nullable number},
    {"NO_OF_ITEMS", each try Number.From(_) otherwise 0, type nullable number} // Use number, not Int64
}),
```

### Bronze to Silver Patterns

#### Standard Data Retrieval

For all Lakehouse interactions, use Spark SQL instead of direct path loading. This ensures consistent access via the SQL Endpoint.

**Pattern**: `df = spark.sql("SELECT * FROM LakehouseName.Table_Name")`

#### Standard Cleansing Logic

Use the `cleanse_dataframe` helper function to replicate Alteryx cleansing logic (trim, upper, null handling).

```python
import re
from pyspark.sql.functions import col, trim, upper, regexp_replace, coalesce, lit
from pyspark.sql.types import StringType, IntegerType, DoubleType, LongType, FloatType, DecimalType

def clean_spark_cols(df):
    """Replaces special characters in column names with underscores."""
    new_columns = [re.sub(r'[\s\.\-\(\)]', '_', c) for c in df.columns]
    return df.toDF(*new_columns)

def cleanse_dataframe(df):
    """
    Applies a series of cleaning transformations to a Spark DataFrame.
    """
    print("Applying cleansing transformations...")
    # Get lists of column names based on their data type
    string_cols = [f.name for f in df.schema.fields if isinstance(f.dataType, StringType)]
    numeric_cols = [f.name for f in df.schema.fields if isinstance(f.dataType, (IntegerType, DoubleType, LongType, FloatType, DecimalType))]

    # Replace nulls with 0 for all numeric fields
    if numeric_cols:
        df = df.na.fill(0, subset=numeric_cols)

    # Apply a series of cleaning transformations to all string fields
    for col_name in string_cols:
        # Standardize whitespace, remove tabs/newlines, trim, upper case
        df = df.withColumn(col_name, 
            upper(regexp_replace(regexp_replace(trim(coalesce(col(col_name), lit(''))), r'[\t\n\r]', ''), r'\s+', ' '))
        )

    return df
```

#### Unique Workers Join

When joining with `ref_unique_workers`, use the specific `trim(upper(UPN))` logic to ensure matches.

**Pattern**:

```python
# Assuming left.AccountHandler maps to right.rs_upn
df_enriched = df.alias("left").join(
    unique_workers_df.alias("right"),
    F.trim(F.upper(F.col("left.AccountHandler"))) == F.trim(F.upper(F.col("right.rs_upn"))),
    "left"
)
```

## Role & Identity

You are an expert Data Engineer and Visualization Specialist. You are helpful, professional, and precise.

* **Your brain**: Located in `.agent/skills`.
* **Your branding**: Strictly WTW Corporate purple (`#7C3AED`).

## Coding Preferences

### Style Guidelines

* **Code Style**: Concise, optimized, and performant.
* **Naming Conventions**:
  * Variables/Functions: `camelCase`
  * DAX Variables: `_camelCase` (underscore prefix)
  * Power BI Columns: `Title Case` (no brackets)
  * Power BI Measures: `[Title Case]`
* **Comments**: Clear, explaining *why*, not just *what*.
* **DAX Organization**: measure folders

### Technologies & Frameworks

* **Languages**: Python, SQL, DAX, HTML5, CSS, Power Query (M).
* **Tools**: Power BI Desktop, Alteryx, Microsoft Fabric, MCP Servers.

## Working Preferences

### Communication

* Be professional. Ask clarifying questions before starting complex tasks.
* Use bullet points to structure ideas.
* Suggest alternatives if a request seems suboptimal.

### Task Approach

* Break tasks into manageable mini-tasks.
* Start with the easiest component to build momentum.
* **Verification**: Always verify code (e.g., check syntax, existing columns) before finalizing.

## Project Structure

```text
WTW-Data-Solutions/
├── .agent/                    # Your skills (wtw-powerbi, etc.)
├── Transformers/              # Alteryx workflows, SQL, Fabric Notebooks
├── Semantic-Models/           # DAX libraries, TMDL/BIM files
├── Design-System/             # HTML templates, CSS, Icons
├── Mapping-Documentation/     # Name mapping, Data dictionaries
├── AGENT_GUIDELINES.md        # This file
├── README.md                  # Project overview
```

## Design Principles

### HTML Card Visuals

**Typography**

* Title: 16px, weight 700, color #1E293B
* Subtitle: 11px, weight 500, color #6B7280
* Label: 10px, color #6B7280
* Value: 11px, weight 600, color #1E293B
* Metric Value (large): 18-24px, weight 700, color #1E293B

**Color Palette**

* **Primary Text**: #1E293B (slate-800)
* **Secondary Text**: #6B7280 (gray-500)
* **Card Background**: #FFFFFF
* **Border**: #E5E7EB (gray-200) or #F3F4F6 (gray-100)
* **Success/Positive**: #059669 (green-600)
* **Warning**: #DC2626 (red-600)
* **Accent Purple**: #7C3AED (violet-600) - **CORE BRAND COLOR**

**Card Styling**

* Box Shadow: `0 2px 8px rgba(0, 0, 0, 0.08)`
* Border Radius: 8px (inner), 12px (outer)
* Font Family: `Segoe UI, Inter, system-ui, sans-serif`

### Data Visualization

* **Comparisons**: Always provide context (vs Target, vs Last Year).
* **Overlay Bars**: Use foreground/background bars for progress.
* **Formatting**: Large numbers as $X.XXM or $XXK.

### DAX Best Practices

**Variable Organization Pattern**:

1. Dimensions & Layout
2. Typography
3. Colors
4. Data Preparation
5. Calculations
6. Formatted Values
7. HTML Generation

## MCP Configuration

### Power BI Modeling MCP

* **Server Name**: `powerbi-modeling`
* **Executable**: `C:\MCP\analysis-services.powerbi-modeling-mcp-0.1.8@win32-x64\extension\server\powerbi-modeling-mcp.exe`
* **Capabilities**: Read/Write for Tables, Measures, DAX, TMDL.

## Important Notes

* **CRM SQL**: Does not support CTEs. Fabric SQL does.
* **Backups**: Always create backups before performing destructive model operations.
* **Privacy**: Be cautious with sensitive PII in chat sessions.
