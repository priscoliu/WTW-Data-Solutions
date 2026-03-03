let
    // ═══════════════════════════════════════════════════════
    // FACT_REVENUE_SPLIT — Unpivoted state-level revenue
    // ═══════════════════════════════════════════════════════
    // Derived from src_sales_marketing by keeping only
    // PolicyNumber + Revenue Split columns, then unpivoting

    // === SOURCE ===
    Source = Lakehouse.Contents(null),
    Navigation = Source{[workspaceId = "76ec20c3-c400-415a-99c6-708f8207d5f9"]}[Data],
    #"Navigation 1" = Navigation{[lakehouseId = "0ebd6604-a5db-4624-b535-497cd55663c1"]}[Data],
    #"Navigation 2" = #"Navigation 1"{[Id = "src_sales_marketing", ItemKind = "Table"]}[Data],

    // === STEP 1: Keep only PolicyNumber + Revenue Split columns ===
    #"Selected columns" = Table.SelectColumns(#"Navigation 2", {
        "Policy Number",
        "Revenue Split - NSW",
        "Revenue Split - VIC",
        "Revenue Split - QLD",
        "Revenue Split - WA",
        "Revenue Split - SA",
        "Revenue Split - NT",
        "Revenue Split - TAS",
        "Revenue Split - Tas2",
        "Revenue Split - Overseas"
    }),

    // === STEP 2: Rename PolicyNumber ===
    #"Renamed policy" = Table.RenameColumns(#"Selected columns", {
        {"Policy Number", "PolicyNumber"}
    }),

    // === STEP 3: Set revenue columns to number type ===
    _revCols = {
        "Revenue Split - NSW", "Revenue Split - VIC", "Revenue Split - QLD",
        "Revenue Split - WA", "Revenue Split - SA", "Revenue Split - NT",
        "Revenue Split - TAS", "Revenue Split - Tas2", "Revenue Split - Overseas"
    },
    #"Set types" = Table.TransformColumnTypes(
        #"Renamed policy",
        List.Combine({
            {{"PolicyNumber", type text}},
            List.Transform(_revCols, each {_, Currency.Type})
        })
    ),

    // === STEP 4: Unpivot revenue split columns → State + RevenueAmount ===
    #"Unpivoted" = Table.UnpivotOtherColumns(#"Set types", {"PolicyNumber"}, "StateSplit", "RevenueAmount"),

    // === STEP 5: Clean state names (extract state code from column name) ===
    #"Cleaned state" = Table.TransformColumns(#"Unpivoted", {
        {"StateSplit", each Text.Trim(Text.AfterDelimiter(_, "- ")), type text}
    }),
    #"Renamed state col" = Table.RenameColumns(#"Cleaned state", {
        {"StateSplit", "StateCode"}
    }),

    // === STEP 6: Standardise state codes ===
    #"Standardised state" = Table.TransformColumns(#"Renamed state col", {
        {"StateCode", each
            if Text.Upper(_) = "TAS2" then "TAS2"
            else if Text.Upper(_) = "OVERSEAS" then "OVS"
            else Text.Upper(_),
         type text}
    }),

    // === STEP 7: Remove rows where RevenueAmount = 0 or null (no revenue in that state) ===
    #"Filtered zero" = Table.SelectRows(#"Standardised state", each
        [RevenueAmount] <> null and [RevenueAmount] <> 0
    ),

    // === STEP 8: Set final types ===
    #"Set final types" = Table.TransformColumnTypes(#"Filtered zero", {
        {"PolicyNumber", type text},
        {"StateCode", type text},
        {"RevenueAmount", Currency.Type}
    }),

    // === STEP 9: Add RevenueSplitKey ===
    #"Added key" = Table.AddIndexColumn(#"Set final types", "RevenueSplitKey", 1, 1, Int64.Type),

    // === STEP 10: Reorder ===
    #"Reordered" = Table.ReorderColumns(#"Added key", {
        "RevenueSplitKey", "PolicyNumber", "StateCode", "RevenueAmount"
    })
in
    #"Reordered"
