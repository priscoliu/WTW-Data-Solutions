let
    // ═══════════════════════════════════════════════════════
    // DIM_CUSTOMER — Deduplicated insured parties
    // ═══════════════════════════════════════════════════════
    // Primary source: src_sales_marketing (has full address details)
    // Secondary source: src_quotes (name + employee count only)
    // Join key: InsuredName (fuzzy match may be needed)

    // === SOURCE: Sales table (primary — has address) ===
    Source = Lakehouse.Contents(null),
    Navigation = Source{[workspaceId = "76ec20c3-c400-415a-99c6-708f8207d5f9"]}[Data],
    #"Navigation 1" = Navigation{[lakehouseId = "0ebd6604-a5db-4624-b535-497cd55663c1"]}[Data],
    SalesTable = #"Navigation 1"{[Id = "src_sales_marketing", ItemKind = "Table"]}[Data],

    // === STEP 1: Select customer columns from Sales ===
    #"Selected sales cols" = Table.SelectColumns(SalesTable, {
        "Insured Name", "Street No_", "Street Name", "City/Suburb",
        "State", "Postcode", "GNAF", "Employee Numbers"
    }),

    // === STEP 2: Rename columns ===
    #"Renamed columns" = Table.RenameColumns(#"Selected sales cols", {
        {"Insured Name", "InsuredName"},
        {"Street No_", "StreetNumber"},
        {"Street Name", "StreetName"},
        {"City/Suburb", "City"},
        {"State", "State"},
        {"Postcode", "Postcode"},
        {"GNAF", "GNAF"},
        {"Employee Numbers", "EmployeeNumbers"}
    }),

    // === STEP 3: Trim & standardise text ===
    #"Cleaned text" = Table.TransformColumns(#"Renamed columns", {
        {"InsuredName",   each Text.Trim(_ ?? ""), type text},
        {"StreetNumber",  each Text.Trim(_ ?? ""), type text},
        {"StreetName",    each Text.Trim(_ ?? ""), type text},
        {"City",          each Text.Trim(_ ?? ""), type text},
        {"Postcode",      each Text.Trim(_ ?? ""), type text},
        {"GNAF",          each Text.Trim(_ ?? ""), type text}
    }),

    // === STEP 4: Standardise State codes to uppercase ===
    #"Standardised state" = Table.TransformColumns(#"Cleaned text", {
        {"State", each Text.Upper(Text.Trim(_ ?? "")), type text}
    }),

    // === STEP 5: Deduplicate by InsuredName (keep first occurrence) ===
    #"Removed duplicates" = Table.Distinct(#"Standardised state", {"InsuredName"}),

    // === STEP 6: Remove blank insured names ===
    #"Filtered blanks" = Table.SelectRows(#"Removed duplicates", each
        [InsuredName] <> "" and [InsuredName] <> null
    ),

    // === STEP 7: Set data types ===
    #"Set types" = Table.TransformColumnTypes(#"Filtered blanks", {
        {"InsuredName", type text},
        {"StreetNumber", type text},
        {"StreetName", type text},
        {"City", type text},
        {"State", type text},
        {"Postcode", type text},
        {"GNAF", type text},
        {"EmployeeNumbers", Int64.Type}
    }),

    // === STEP 8: Add CustomerKey (surrogate key) ===
    #"Added CustomerKey" = Table.AddIndexColumn(#"Set types", "CustomerKey", 1, 1, Int64.Type),

    // === STEP 9: Reorder ===
    #"Reordered" = Table.ReorderColumns(#"Added CustomerKey", {
        "CustomerKey", "InsuredName",
        "StreetNumber", "StreetName", "City", "State", "Postcode", "GNAF",
        "EmployeeNumbers"
    })
in
    #"Reordered"
