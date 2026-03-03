let
    // ═══════════════════════════════════════════════════════
    // DIM_PRODUCT — Simplified (from Quotes ProductName)
    // ═══════════════════════════════════════════════════════
    // Shared dimension: joins to both Fact_Sales.ProductName
    // and Fact_Quotes.ProductName
    //
    // ⚠️ Assumes Sales "Occupation_" ≈ Quotes "ProductName"
    //    (Fact_Sales renames Occupation_ → ProductName)

    // === SOURCE ===
    Source = Lakehouse.Contents(null),
    Nav1 = Source{[workspaceId = "76ec20c3-c400-415a-99c6-708f8207d5f9"]}[Data],
    Nav2 = Nav1{[lakehouseId = "0ebd6604-a5db-4624-b535-497cd55663c1"]}[Data],
    Raw = Nav2{[Id = "src_quote_marketing", ItemKind = "Table"]}[Data],

    // === Get distinct ProductName ===
    #"Selected" = Table.SelectColumns(Raw, {"ProductName"}),
    #"Trimmed" = Table.TransformColumns(#"Selected", {
        {"ProductName", each Text.Trim(_ ?? ""), type text}
    }),
    #"Distinct" = Table.Distinct(#"Trimmed"),
    #"Filtered" = Table.SelectRows(#"Distinct", each [ProductName] <> "" and [ProductName] <> null),

    // === Add ProductKey ===
    #"Added key" = Table.AddIndexColumn(#"Filtered", "ProductKey", 1, 1, Int64.Type),

    // === Reorder ===
    #"Reordered" = Table.ReorderColumns(#"Added key", {"ProductKey", "ProductName"})
in
    #"Reordered"
