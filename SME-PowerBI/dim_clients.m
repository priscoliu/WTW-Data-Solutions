let
    // ═══════════════════════════════════════════════════════
    // DIM_CLIENTS — Insured parties (Quotes + Sales address)
    // ═══════════════════════════════════════════════════════

    // === SOURCE: Quotes (primary — has all insured names) ===
    Source = Lakehouse.Contents(null),
    Nav1 = Source{[workspaceId = "76ec20c3-c400-415a-99c6-708f8207d5f9"]}[Data],
    Nav2 = Nav1{[lakehouseId = "0ebd6604-a5db-4624-b535-497cd55663c1"]}[Data],
    Raw = Nav2{[Id = "src_quote_marketing", ItemKind = "Table"]}[Data],

    // === STEP 1: Get distinct insured from Quotes ===
    #"Distinct insured" = Table.Distinct(Raw, {"Insured"}),
    #"Selected cols" = Table.SelectColumns(#"Distinct insured", {"Insured", "NumberOfEmployees"}),

    // === STEP 2: Clean Insured name (for matching) ===
    #"Cleaned insured" = Table.TransformColumns(#"Selected cols", {
        {"Insured", each Text.Upper(Text.Trim(Text.Clean(_ ?? ""))), type text}
    }),

    // === STEP 3: Clean NumberOfEmployees (strip leading apostrophe + trim) ===
    #"Cleaned employees" = Table.TransformColumns(#"Cleaned insured", {
        {"NumberOfEmployees", each
            let
                raw = Text.Trim(Text.Replace(_ ?? "", "'", ""))
            in
                if raw = "" then null else raw,
         type text}
    }),

    // === STEP 4: Remove blank/null insured names ===
    #"Filtered blanks" = Table.SelectRows(#"Cleaned employees", each
        [Insured] <> "" and [Insured] <> null
    ),

    // === STEP 5: Merge with Sales for address details ===
    #"Merged" = Table.NestedJoin(
        #"Filtered blanks", {"Insured"},
        clean_sales_marketing, {"Insured Name"},
        "SalesData",
        JoinKind.LeftOuter
    ),
    #"Expanded" = Table.ExpandTableColumn(#"Merged", "SalesData", {
        "Street No_", "Street Name", "City/Suburb",
        "State", "Postcode", "GNAF", "Occupation_", "Revenue"
    }),

    // === STEP 6: Rename to PascalCase ===
    #"Renamed" = Table.RenameColumns(#"Expanded", {
        {"Insured", "InsuredName"},
        {"NumberOfEmployees", "EmployeeRange"},
        {"Street No_", "StreetNumber"},
        {"Street Name", "StreetName"},
        {"City/Suburb", "City"},
        {"Occupation_", "Occupation"},
        {"Revenue", "InsuredRevenue"}
    }),

    // === STEP 7: Trim address fields (may have trailing spaces) ===
    #"Trimmed" = Table.TransformColumns(#"Renamed", {
        {"StreetNumber", each Text.Trim(_ ?? ""), type text},
        {"StreetName",   each Text.Trim(_ ?? ""), type text},
        {"City",         each Text.Trim(_ ?? ""), type text},
        {"State",        each Text.Upper(Text.Trim(_ ?? "")), type text},
        {"Postcode",     each Text.Trim(_ ?? ""), type text},
        {"GNAF",         each Text.Trim(_ ?? ""), type text},
        {"Occupation",   each Text.Trim(_ ?? ""), type text}
    }),

    // === STEP 8: Set types ===
    #"Set types" = Table.TransformColumnTypes(#"Trimmed", {
        {"InsuredName", type text},
        {"EmployeeRange", type text},
        {"StreetNumber", type text},
        {"StreetName", type text},
        {"City", type text},
        {"State", type text},
        {"Postcode", type text},
        {"GNAF", type text},
        {"Occupation", type text},
        {"InsuredRevenue", Currency.Type}
    }),

    // === STEP 9: Add ClientKey ===
    #"Added key" = Table.AddIndexColumn(#"Set types", "ClientKey", 1, 1, Int64.Type),

    // === FINAL: Reorder ===
    #"Reordered" = Table.ReorderColumns(#"Added key", {
        "ClientKey", "InsuredName", "EmployeeRange",
        "StreetNumber", "StreetName", "City", "State", "Postcode", "GNAF",
        "Occupation", "InsuredRevenue"
    })
in
    #"Reordered"
