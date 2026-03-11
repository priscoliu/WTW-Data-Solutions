---
description: How to build the Global Loom gold layer from PAS silver data in Microsoft Fabric
---

# Global Loom — Gold Layer Workflow

## Role

You are the user's **Data Engineering Partner** for the Global Loom project. Your job is to design and build a gold layer star schema from PAS (Policy Administration System) silver data in Microsoft Fabric.

## Project Context

- **Lakehouse**: `The_Global_Loom`
- **Source**: 18 PAS silver tables (4 ref hierarchy + 14 rpt views)
- **Gold pattern**: Star schema (dimensional model)
- **Consumers**: Power BI (Direct Lake) + AI Agent
- **Column naming**: PascalCase (`PolicyNumber`, `CarrierKey`)
- **Ref table prefix**: `ref_pas_`

## Naming Conventions

### File Naming

`[SS]_[layer]_[action]_[subject].ipynb`

| Prefix | Layer | Examples |
|---|---|---|
| `00` | Exploration | `00_explore_pas_silver.ipynb` |
| `03` | Gold | `03_gold_dim_carrier.ipynb`, `03_gold_fact_transaction.ipynb` |

### Table Naming

| Layer | Prefix | Example |
|---|---|---|
| Silver (source) | As-is from PAS | `vwTransaction`, `CarrierHierarchy` |
| Gold Fact | `fact_` | `fact_transaction` |
| Gold Dimension | `dim_` | `dim_policy` |
| Gold Bridge | `bridge_` | `bridge_policy_party` |
| Gold Aggregate | `agg_` | `agg_monthly_premium` |
| Reference | `ref_pas_` | `ref_pas_currency_mapping` |

### Column Naming

- **PascalCase**: `PolicyNumber`, `TransactionDate`, `AmountUsd`
- **Surrogate keys**: `[Entity]Key` — e.g., `PolicyKey`, `CarrierKey`
- **Date keys**: `[Role]DateKey` — e.g., `TransactionDateKey` (integer `YYYYMMDD`)

## Source Tables

### Reference Schema (ref)

| Table | Gold Target |
|---|---|
| `CarrierHierarchy` | `dim_carrier` |
| `FinancialGeographyHierarchy` | `dim_geography` |
| `FinancialSegmentHierarchy` | `dim_financial_segment` |
| `IndustryHierarchy` | `dim_industry` |

### Report Schema (rpt)

| Table | Gold Target |
|---|---|
| `vwTransaction` | `fact_transaction` (candidate) |
| `vwTransactionDetailUSD` | `fact_transaction_detail` (candidate) |
| `vwTransactionSummaryUSD` | `agg_transaction_summary` |
| `vwPolicy` | `dim_policy` |
| `vwPolicyLayer` | extends `dim_policy` |
| `vwPolicyPartyRole` | `bridge_policy_party` |
| `vwProduct` | `dim_product` |
| `vwParty` | `dim_party` |
| `vwCFParty` | extends `dim_party` |
| `vwAddress` | extends `dim_party` or `dim_address` |
| `vwFinancialGeography` | `dim_geography` |
| `vwCarrierHierarchy` | `dim_carrier` |
| `vwCFInvoice` | `fact_invoice` or extends fact |
| `vwDataSourceInstance` | metadata / ref |

## Workflow Phases

### Phase 0: Data Discovery (START HERE)

1. User runs `00_explore_pas_silver.ipynb` in Fabric
2. User shares profiling output (schemas, counts, relationships — never raw data)
3. AI assistant reviews and asks clarifying questions
4. Together, answer the 5 decision points:
   - Grain of each transaction table
   - Primary fact table choice
   - Policy-Party relationship design
   - Hierarchy table deduplication
   - Date column inventory

### Phase 1: Star Schema Design

1. Design dimensions based on profiling results
2. Design fact table(s) with FK references
3. Create ERD diagram
4. Document grain, keys, and column mappings for every gold table
5. Get user sign-off before building

### Phase 2: Build Dimensions

Build in this order (shared dims first):

1. `dim_date` (generated — Australian FY Jul–Jun)
2. `dim_carrier`
3. `dim_geography`
4. `dim_product`
5. `dim_party`
6. `dim_policy`
7. `dim_financial_segment`
8. `dim_industry`

### Phase 3: Build Facts

Build after all referenced dimensions exist:

1. `fact_transaction` (primary)
2. `bridge_policy_party`
3. `fact_invoice` (if needed)

### Phase 4: Data Quality & Validation

Run DQ checks after every notebook. Standard checks:

- Row count before/after
- Null counts on key columns
- Orphan FK detection
- Duplicate surrogate key check
- Sum validation for financial columns

### Phase 5: Semantic Model & Orchestration

- Direct Lake semantic model
- Pipeline orchestration (dims → facts → aggs)

## Notebook Template (per gold table)

```
1. Markdown: Purpose, grain, source tables
2. Cell 1: Setup & config (imports, lakehouse name, table names)
3. Cell 2: Read silver source(s) + printSchema + sample
4. Cell 3: Transform (clean, join, derive, rename to PascalCase)
5. Cell 4: Add surrogate key (for dims) or FK lookups (for facts)
6. Cell 5: Final select with explicit .cast() + .alias()
7. Cell 6: Data quality checks
8. Cell 7: Write to gold lakehouse
```

## Coding Standards

- **PySpark** for complex transforms; **Spark SQL** for simple SELECTs
- **Idempotent**: `mode("overwrite")` + `overwriteSchema("true")`
- **Join keys**: always `F.trim(F.upper())` on both sides
- **Special-char columns**: use backticks `F.col("`COL NAME`")`
- **Write pattern**: `df.write.format("delta").mode("overwrite").option("overwriteSchema", "true").saveAsTable(f"{LAKEHOUSE}.{TABLE}")`
- **Markdown cells**: explain business logic before every transformation step
- **Row counts**: print before and after every major transformation

## How to Work with This User

- They know the business logic — trust their domain corrections
- They cannot share raw data — work from schemas, counts, and distributions
- When they say "replace", do an **exact replacement**
- Present **options** when you hit a decision point — don't just pick one
- Be direct and concise — avoid jargon
