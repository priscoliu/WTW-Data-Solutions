let
    // ═══════════════════════════════════════════════════════
    // FACT_SALES — Lean (8 columns)
    // ═══════════════════════════════════════════════════════

    // === SOURCE ===
    Source = Lakehouse.Contents(null),
    Nav1 = Source{[workspaceId = "76ec20c3-c400-415a-99c6-708f8207d5f9"]}[Data],
    Nav2 = Nav1{[lakehouseId = "0ebd6604-a5db-4624-b535-497cd55663c1"]}[Data],
    Raw = Nav2{[Id = "src_sales_marketing", ItemKind = "Table"]}[Data],

    // === STEP 1: Keep only required columns ===
    #"Selected columns" = Table.SelectColumns(Raw, {
        "Policy Number", "Transaction Type", "Transaction Date",
        "Invoice Number / Closing Reference", "Risk Class",
        "Base Premium", "TOTAL", "Commission"
    }),

    // === STEP 2: Rename ===
    #"Renamed" = Table.RenameColumns(#"Selected columns", {
        {"Policy Number", "PolicyNumber"},
        {"Transaction Date", "TransactionDate"},
        {"Transaction Type", "TransactionType"},
        {"Risk Class", "CoverageType"},
        {"Invoice Number / Closing Reference", "InvoiceNumber"},
        {"Base Premium", "BasePremium"},
        {"TOTAL", "TotalPremium"},
        {"Commission", "Commission"}
    }),

    // === STEP 3: Set types ===
    #"Set types" = Table.TransformColumnTypes(#"Renamed", {
        {"PolicyNumber", type text},
        {"TransactionDate", type date},
        {"TransactionType", type text},
        {"CoverageType", type text},
        {"InvoiceNumber", type text},
        {"BasePremium", Currency.Type},
        {"TotalPremium", Currency.Type},
        {"Commission", Currency.Type}
    }),

    // === STEP 4: Trim text ===
    #"Trimmed" = Table.TransformColumns(#"Set types", {
        {"PolicyNumber",    each Text.Trim(_ ?? ""), type text},
        {"TransactionType", each Text.Trim(_ ?? ""), type text},
        {"CoverageType",    each Text.Trim(_ ?? ""), type text},
        {"InvoiceNumber",   each Text.Trim(_ ?? ""), type text}
    }),

    // === STEP 5: Replace nulls → 0 for financials ===
    #"Null to zero" = Table.ReplaceValue(
        Table.ReplaceValue(
            Table.ReplaceValue(#"Trimmed", null, 0, Replacer.ReplaceValue, {"BasePremium"}),
            null, 0, Replacer.ReplaceValue, {"TotalPremium"}
        ),
        null, 0, Replacer.ReplaceValue, {"Commission"}
    ),

    // === STEP 6: Filter out "Policy" rollup rows (avoid double-counting) ===
    #"Filtered rows" = Table.SelectRows(#"Null to zero", each [CoverageType] <> "Policy"),

    // === STEP 7: Reorder ===
    #"Reordered" = Table.ReorderColumns(#"Filtered rows", {
        "PolicyNumber", "TransactionDate", "TransactionType",
        "CoverageType", "InvoiceNumber",
        "BasePremium", "TotalPremium", "Commission"
    }),

    // === STEP 8: Final rename CoverageType → ProductClass ===
    #"Renamed columns" = Table.RenameColumns(#"Reordered", {{"CoverageType", "ProductClass"}})
in
    #"Renamed columns"
