# Semantic Model Design Patterns

Complete guide to building Power BI semantic models with star schema design, fact/dimension patterns, and validation rules.

## Star Schema Decision Tree

Use this to decide your model structure:

```
Q: Do you have more than one data source (e.g. Sales + Quotes)?
├── YES → Star schema with shared dimensions
│   Q: Do both sources share common entities (Date, Product, Customer)?
│   ├── YES → Create shared Dim tables, multiple Fact tables
│   └── NO  → Separate Fact tables, independent Dims
└── NO → Flat table may suffice
    Q: Does a single source have >30 columns?
    ├── YES → Consider normalising into Fact + Dims
    └── NO  → Keep flat, add Dim_Date only
```

### When to Create a Dimension Table

| Condition | Create Dim? | Example |
|-----------|:-----------:|---------|
| Column has <10 distinct values | ❌ Keep as column | TransactionType (New Business, Renewal, Cancellation) |
| Column shared across 2+ fact tables | ✅ Create dim | Dim_Date (used by Sales + Quotes) |
| Column needs enrichment (labels, sort order, grouping) | ✅ Create dim | Dim_QuoteStatus (add IsConverted flag, StageOrder) |
| Column is a simple yes/no or code | ❌ Keep as column | RiskClass, QuoteType |
| You want a slicer to filter across multiple visuals | ✅ Create dim | Dim_Product (filter both Sales and Quotes) |

## Fact Table Patterns

### Grain Definition

The **grain** = what one row represents. Define this FIRST before selecting columns.

| Grain | Example | Count measure |
|-------|---------|---------------|
| One row per **transaction** | Invoice line item | `COUNTROWS` |
| One row per **policy × coverage** | Sales × RiskClass | `DISTINCTCOUNT(PolicyNumber)` for policy count |
| One row per **quote** | Quote attempt | `COUNTROWS` |
| One row per **date × product** | Aggregated snapshot | `SUM(Amount)` only |

> **Critical**: If your grain is finer than "one row per entity" (e.g. one row per coverage line), you MUST use `DISTINCTCOUNT` for entity counts, never `COUNTROWS`.

### Handling Rollup / Summary Rows

When source data contains both detail and rollup rows (common in insurance data):

```
| RiskClass              | BasePremium |
|------------------------|-------------|
| Policy ← ROLLUP       | 981.24      |
| Professional Indemnity | 750.00      |
| Public and Product     | 231.24      |
```

**Options**:

1. **Filter OUT rollup rows** (recommended) — keep only detail, calculate totals via DAX `SUM`
2. **Filter TO rollup rows** — use for counts/totals, lose the breakdown
3. **Keep both + flag** — add `IsRollup` column, handle in DAX (more complex)

**Validation**: `SUM(detail rows) = rollup row value`. If not, investigate before choosing.

### Surrogate Keys

- Use `Table.AddIndexColumn("TableKey", 1, 1, Int64.Type)` for auto-increment
- Only needed if you're doing complex relationships
- For simple models, natural keys (PolicyNumber, QuoteReference) often suffice
- **DateKey convention**: `YYYYMMDD` integer (e.g. `20251106` for 2025-11-06)

### Degenerate Dimensions

Columns that look like dimension attributes but belong in the fact table:

- `PolicyNumber` — unique per row group, not worth a separate dim
- `InvoiceNumber` — same
- `QuoteReference` — same

These are "degenerate dimensions" — keep them in the fact for drill-through.

## Dimension Table Patterns

### Dim_Date — Calendar Table (Required)

Every Power BI model needs a Date dimension. Use Power Query M, not DAX `CALENDARAUTO()`.

**Template** (Australian Financial Year, Jul–Jun):

```m
let
    StartDate = #date(2025, 1, 1),
    EndDate   = #date(2026, 12, 31),
    DayCount  = Duration.Days(EndDate - StartDate) + 1,
    DateList  = List.Dates(StartDate, DayCount, #duration(1, 0, 0, 0)),
    ToTable   = Table.FromList(DateList, Splitter.SplitByNothing(), {"Date"}),
    SetType   = Table.TransformColumnTypes(ToTable, {{"Date", type date}}),

    // DateKey — integer YYYYMMDD for fast joins
    AddDateKey = Table.AddColumn(SetType, "DateKey", each
        Date.Year([Date]) * 10000 + Date.Month([Date]) * 100 + Date.Day([Date]),
        Int64.Type),

    // Calendar columns
    AddYear      = Table.AddColumn(AddDateKey, "Year", each Date.Year([Date]), Int64.Type),
    AddMonth     = Table.AddColumn(AddYear, "Month", each Date.Month([Date]), Int64.Type),
    AddMonthName = Table.AddColumn(AddMonth, "MonthName", each Date.MonthName([Date]), type text),
    AddQuarter   = Table.AddColumn(AddMonthName, "Quarter", each
        "Q" & Text.From(Date.QuarterOfYear([Date])), type text),
    AddWeekNum   = Table.AddColumn(AddQuarter, "WeekNumber", each
        Date.WeekOfYear([Date], Day.Monday), Int64.Type),
    AddWeekStart = Table.AddColumn(AddWeekNum, "WeekStartDate", each
        Date.StartOfWeek([Date], Day.Monday), type date),

    // Australian Financial Year (Jul–Jun)
    AddFY = Table.AddColumn(AddWeekStart, "FiscalYear", each
        if Date.Month([Date]) >= 7 then Date.Year([Date]) + 1
        else Date.Year([Date]), Int64.Type),
    AddFYLabel = Table.AddColumn(AddFY, "FiscalYearLabel", each
        "FY" & Text.End(Text.From([FiscalYear]), 2), type text),

    // Relative date flags (recalculated on each refresh)
    Today = DateTime.Date(DateTime.LocalNow()),
    CurrentWeekStart = Date.StartOfWeek(Today, Day.Monday),
    FYStart = if Date.Month(Today) >= 7
        then #date(Date.Year(Today), 7, 1)
        else #date(Date.Year(Today) - 1, 7, 1),

    AddIsWTD = Table.AddColumn(AddFYLabel, "IsWTD", each
        [Date] >= CurrentWeekStart and [Date] <= Today, type logical),
    AddIsYTD = Table.AddColumn(AddIsWTD, "IsYTD", each
        [Date] >= FYStart and [Date] <= Today, type logical),

    // Sort helper
    AddSort = Table.AddColumn(AddIsYTD, "YearMonthSort", each
        Date.Year([Date]) * 100 + Date.Month([Date]), Int64.Type)
in
    AddSort
```

**Key design choices**:

- `DateKey` as integer for joining (faster than Date-to-Date in large models)
- `IsYTD` uses Financial Year (Jul–Jun) by default
- `IsWTD` uses Monday as week start
- Adjust `StartDate`/`EndDate` to cover your full data range + buffer

### Static Dimension Tables

For small, fixed reference data — define inline rather than querying a source:

```m
let
    Data = Table.FromRecords({
        [Key = 1, Code = "NSW", Name = "New South Wales", Region = "Eastern"],
        [Key = 2, Code = "VIC", Name = "Victoria",        Region = "Eastern"],
        ...
    }),
    SetTypes = Table.TransformColumnTypes(Data, {
        {"Key", Int64.Type}, {"Code", type text},
        {"Name", type text}, {"Region", type text}
    })
in
    SetTypes
```

## Relationship Design

### DateKey Integer vs Date-to-Date

| Approach | Pros | Cons |
|----------|------|------|
| **DateKey integer** (YYYYMMDD) | Fast joins, explicit | Need to add computed column |
| **Date-to-Date** | Simpler M code | Slower on large models, time intel needs "Mark as Date Table" |

**Recommendation**: Use Date-to-Date for small models (<1M rows). Use DateKey integer for large models or when you have multiple date roles.

### Role-Playing Dimensions (Multiple Date Columns)

When a fact table has multiple dates (e.g. TransactionDate, EffectiveDate, ExpiryDate):

- Create **one Dim_Date** table
- Set the **primary date** as the **active** relationship
- Set other dates as **inactive** relationships
- Use `USERELATIONSHIP()` in DAX to activate:

```dax
Sales by Effective Date =
CALCULATE(
    [Total Premium],
    USERELATIONSHIP(Fact_Sales[EffectiveDateKey], Dim_Date[DateKey])
)
```

### Multi-Fact Shared Dimensions

When two fact tables share a dimension (e.g. both use Dim_Date):

```
Dim_Date[DateKey] ──1:M──> Fact_Sales[TransactionDateKey]
Dim_Date[DateKey] ──1:M──> Fact_Quotes[CreationDateKey]
```

- Both relationships can be **active** (they connect to different columns)
- Slicing by Dim_Date will filter **both** fact tables simultaneously
- Use `TREATAS()` or `USERELATIONSHIP()` for cross-fact analysis

### Loose / Indirect Relationships

When two fact tables share a business key but at different grains:

```
Fact_Quotes[PolicyNumber] ──...──> Fact_Sales[PolicyNumber]
```

- Do NOT create a direct many-to-many relationship
- Instead, create a **bridge table** or use `TREATAS()` in DAX:

```dax
Converted Quote Premium =
CALCULATE(
    SUM(Fact_Sales[TotalPremium]),
    TREATAS(VALUES(Fact_Quotes[PolicyNumber]), Fact_Sales[PolicyNumber])
)
```

## Naming Conventions

Aligned with WTW Bronze / Silver / Gold lakehouse standards:

| Layer | Table Prefix | Example |
|-------|-------------|---------|
| Bronze (source) | `src_` | `src_sales_marketing`, `src_quote_marketing` |
| Silver (clean) | `clean_` | `clean_baseline_union` |
| Gold (model) | `fact_`, `dim_` | `Fact_Sales`, `Dim_Date` |
| Reference | `ref_` | `ref_Chloe_product_mapping` |

**Column naming**: PascalCase — `PolicyNumber`, `BasePremium`, `TransactionDate`

## Validation Checklist

Before publishing your semantic model:

- [ ] **Grain documented** — one sentence describing what each row represents
- [ ] **No double-counting** — rollup rows filtered out if detail rows exist
- [ ] **FK validation** — every FK value exists in the dimension (no orphans)
- [ ] **Date coverage** — Dim_Date range covers all dates in fact tables
- [ ] **Relationship cardinality** — all joins are 1:M from dim to fact
- [ ] **DISTINCTCOUNT vs COUNTROWS** — correct count measure for the grain
- [ ] **Null handling** — financial nulls → 0, text nulls → "" or filtered out
- [ ] **Premium totals** — SUM of breakdown rows matches known total
- [ ] **No bidirectional filters** — unless explicitly required (rare)
