# Power Query (M Code) Patterns

Common M code patterns for building Power BI semantic models with Microsoft Fabric Lakehouse sources.

## Lakehouse Connection Boilerplate

Standard pattern for connecting to a Fabric Lakehouse table:

```m
let
    Source = Lakehouse.Contents(null),
    Nav1 = Source{[workspaceId = "YOUR_WORKSPACE_ID"]}[Data],
    Nav2 = Nav1{[lakehouseId = "YOUR_LAKEHOUSE_ID"]}[Data],
    Raw = Nav2{[Id = "table_name", ItemKind = "Table"]}[Data]
in
    Raw
```

**Finding IDs**:

- `workspaceId` — from the Fabric workspace URL
- `lakehouseId` — from the Lakehouse URL or settings
- `Id` — the exact table name in the Lakehouse (case-sensitive)

## Column Operations

### Select Columns (keep only what you need)

```m
#"Selected" = Table.SelectColumns(Raw, {
    "Column A", "Column B", "Column C"
})
```

### Remove Columns (drop what you don't need)

```m
#"Removed" = Table.RemoveColumns(Raw, {
    "Column X", "Column Y"
})
```

### Rename Columns

```m
#"Renamed" = Table.RenameColumns(#"Previous Step", {
    {"Source Column Name", "CleanName"},
    {"Another Column", "BetterName"},
    {"Occupation_", "ProductName"}
})
```

**Conventions**:

- Remove trailing underscores (`Occupation_` → `Occupation`)
- Fix typos (`Ramsomware` → `Ransomware`, `Theft Exces` → `TheftExcess`)
- Use PascalCase (`Base Premium` → `BasePremium`)

## Type Casting

### Common Types

| M Type | Use For | Example Values |
|--------|---------|----------------|
| `type text` | Codes, names, IDs | "NSW", "AUMP000009" |
| `type date` | Dates | 2025-11-06 |
| `Int64.Type` | Whole numbers, keys | 1, 20251106 |
| `Currency.Type` | Money (fixed decimal) | 981.24, 0.00 |
| `type number` | Decimals, percentages | 0.15, 3.14159 |
| `type logical` | TRUE/FALSE flags | TRUE, FALSE |

### Setting Types on Multiple Columns

```m
#"Set types" = Table.TransformColumnTypes(#"Previous", {
    {"PolicyNumber", type text},
    {"TransactionDate", type date},
    {"BasePremium", Currency.Type},
    {"TotalPremium", Currency.Type}
})
```

### Dynamic Type Setting (for many columns of the same type)

```m
_financialCols = {"BasePremium", "TotalPremium", "Commission", "GST"},
#"Set currency" = Table.TransformColumnTypes(
    #"Previous",
    List.Transform(_financialCols, each {_, Currency.Type})
)
```

## Currency Cleaning

### Strip $ and Commas from Text (Quote data pattern)

When source data has values like `"$1,799.38"`:

```m
#"Cleaned" = Table.TransformColumns(#"Previous", {
    {"BasePremium", each
        let
            asText = if Value.Is(_, type text) then _ else Text.From(_ ?? "0"),
            stripped = Text.Replace(
                Text.Replace(
                    Text.Replace(asText, "$", ""),
                ",", ""),
            " ", "")
        in
            if stripped = "" or stripped = null then 0
            else Number.From(stripped),
     type number}
})
```

### Safe Number Conversion (Bronze/Silver layers)

```m
each try Number.From(_) otherwise 0, type nullable number
```

## Null Handling

### Financial Columns — null → 0

```m
#"Nulls to zero" = Table.ReplaceValue(
    #"Previous", null, 0, Replacer.ReplaceValue, {"BasePremium"}
)
```

### Multiple Financial Columns — batch pattern

```m
_financialCols = {"BasePremium", "TotalPremium", "Commission"},
#"All nulls to zero" = List.Accumulate(
    _financialCols,
    #"Previous",
    (state, col) => Table.ReplaceValue(state, null, 0, Replacer.ReplaceValue, {col})
)
```

### Nested Null-Safe Replace (3 columns, inline)

```m
#"Null to zero" = Table.ReplaceValue(
    Table.ReplaceValue(
        Table.ReplaceValue(#"Previous", null, 0, Replacer.ReplaceValue, {"BasePremium"}),
        null, 0, Replacer.ReplaceValue, {"TotalPremium"}
    ),
    null, 0, Replacer.ReplaceValue, {"Commission"}
)
```

### Text Columns — null-safe trim

```m
#"Trimmed" = Table.TransformColumns(#"Previous", {
    {"PolicyNumber",    each Text.Trim(_ ?? ""), type text},
    {"TransactionType", each Text.Trim(_ ?? ""), type text}
})
```

## Filtering

### Exclude Specific Values

```m
#"Filtered" = Table.SelectRows(#"Previous", each [RiskClass] <> "Policy")
```

### Exclude Test Data

```m
#"No test" = Table.SelectRows(#"Previous", each [TestData] <> "Yes")
```

### Remove Blank / Null Rows

```m
#"No blanks" = Table.SelectRows(#"Previous", each
    [InsuredName] <> "" and [InsuredName] <> null
)
```

### Filter to Distinct Values (for dimensions)

```m
#"Selected" = Table.SelectColumns(Raw, {"ProductName"}),
#"Trimmed" = Table.TransformColumns(#"Selected", {
    {"ProductName", each Text.Trim(_ ?? ""), type text}
}),
#"Distinct" = Table.Distinct(#"Trimmed"),
#"Filtered" = Table.SelectRows(#"Distinct", each
    [ProductName] <> "" and [ProductName] <> null
)
```

## Unpivoting

### Columns → Rows (Revenue Split pattern)

Source:

```
| PolicyNumber | Rev Split - NSW | Rev Split - VIC | Rev Split - QLD |
|---|---|---|---|
| AUMP000009 | 0 | 0 | 100 |
```

Target:

```
| PolicyNumber | StateCode | RevenueAmount |
|---|---|---|
| AUMP000009 | QLD | 100 |
```

```m
// Keep PolicyNumber fixed, unpivot all others
#"Unpivoted" = Table.UnpivotOtherColumns(
    #"Previous",
    {"PolicyNumber"},
    "StateSplit",
    "RevenueAmount"
),
// Clean state names from column headers
#"Cleaned state" = Table.TransformColumns(#"Unpivoted", {
    {"StateSplit", each Text.Trim(Text.AfterDelimiter(_, "- ")), type text}
}),
// Filter out zero-revenue rows
#"Non-zero" = Table.SelectRows(#"Cleaned state", each [RevenueAmount] <> 0)
```

## Index / Key Generation

### Surrogate Key (auto-increment)

```m
#"Added key" = Table.AddIndexColumn(#"Previous", "SalesKey", 1, 1, Int64.Type)
```

### DateKey Calculation (YYYYMMDD integer)

```m
#"Added DateKey" = Table.AddColumn(#"Previous", "TransactionDateKey", each
    if [TransactionDate] = null then null
    else Date.Year([TransactionDate]) * 10000
       + Date.Month([TransactionDate]) * 100
       + Date.Day([TransactionDate]),
    Int64.Type
)
```

## Sorting

### Sort by Column

```m
#"Sorted" = Table.Sort(#"Previous", {{"QuoteReference", Order.Ascending}})
```

### Reorder Columns (logical grouping)

```m
#"Reordered" = Table.ReorderColumns(#"Previous", {
    // Keys first
    "SalesKey", "TransactionDateKey",
    // Dimension FKs
    "PolicyNumber", "TransactionType", "RiskClass",
    // Dates
    "TransactionDate",
    // Measures
    "BasePremium", "TotalPremium", "Commission"
})
```

## Adding Computed Columns

### Boolean Flag

```m
#"Added flag" = Table.AddColumn(#"Previous", "IsConverted", each
    [QuoteStatus] = "Complete",
    type logical
)
```

### Conditional Text

```m
#"Added category" = Table.AddColumn(#"Previous", "SizeCategory", each
    if [EmployeeNumbers] <= 5 then "Micro"
    else if [EmployeeNumbers] <= 20 then "Small"
    else if [EmployeeNumbers] <= 200 then "Medium"
    else "Large",
    type text
)
```

## Common Gotchas

### Step Name Quoting

```m
// ✅ CORRECT — use #"" when step name has spaces or was defined with #""
#"Set types" = Table.TransformColumnTypes(#"Renamed", {...})

// ❌ WRONG — missing quotes will cause error if step was defined with #""
#"Set types" = Table.TransformColumnTypes(Renamed, {...})
```

**Rule**: If the step name was defined as `#"Step Name"`, always reference it as `#"Step Name"`.

### Null Coalescing in Transforms

```m
// ❌ WRONG — will error on null values
each Text.Trim(_)

// ✅ CORRECT — handle null first
each Text.Trim(_ ?? "")
```

### Type Setting After Currency Clean

When you strip `$` and convert to number, the type is `type number`. You need a **separate** `TransformColumnTypes` step to set it to `Currency.Type`:

```m
// Step 1: Strip $ → number
#"Cleaned" = Table.TransformColumns(#"Previous", {
    {"BasePremium", each ... Number.From(stripped) ..., type number}
}),
// Step 2: Set to Currency (for proper formatting)
#"Set currency" = Table.TransformColumnTypes(#"Cleaned", {
    {"BasePremium", Currency.Type}
})
```

## Standard Fact Table Recipe

Follow this order for every fact table:

```
1. SOURCE      → Lakehouse.Contents(null) → Navigate to table
2. FILTER      → Remove test data, rollup rows
3. SELECT      → Keep only needed columns
4. RENAME      → PascalCase, fix typos
5. CLEAN       → Strip currency symbols, trim text
6. TYPE        → Set all column types explicitly
7. NULL        → Financial nulls → 0, text nulls → ""
8. COMPUTE     → Add DateKeys, flags, categories
9. REORDER     → Keys → FKs → Dates → Measures
```
