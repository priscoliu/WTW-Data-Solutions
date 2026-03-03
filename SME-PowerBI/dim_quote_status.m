let
    // ═══════════════════════════════════════════════════════
    // DIM_QUOTE_STATUS — Simplified
    // ═══════════════════════════════════════════════════════

    // === SOURCE ===
    Source = Lakehouse.Contents(null),
    Nav1 = Source{[workspaceId = "76ec20c3-c400-415a-99c6-708f8207d5f9"]}[Data],
    Nav2 = Nav1{[lakehouseId = "0ebd6604-a5db-4624-b535-497cd55663c1"]}[Data],
    Raw = Nav2{[Id = "src_quote_marketing", ItemKind = "Table"]}[Data],

    // === Get distinct QuoteStatus ===
    #"Selected" = Table.SelectColumns(Raw, {"QuoteStatus"}),
    #"Trimmed" = Table.TransformColumns(#"Selected", {
        {"QuoteStatus", each Text.Trim(_ ?? ""), type text}
    }),
    #"Distinct" = Table.Distinct(#"Trimmed"),
    #"Filtered" = Table.SelectRows(#"Distinct", each [QuoteStatus] <> "" and [QuoteStatus] <> null),

    // === Add IsConverted flag (Complete = became a sale) ===
    #"Added flag" = Table.AddColumn(#"Filtered", "IsConverted", each
        [QuoteStatus] = "Complete", type logical),

    // === Add sort order for funnel visuals ===
    #"Added sort" = Table.AddColumn(#"Added flag", "StageOrder", each
        if [QuoteStatus] = "Incomplete"  then 1
        else if [QuoteStatus] = "Assessment"  then 2
        else if [QuoteStatus] = "Approved"    then 3
        else if [QuoteStatus] = "Complete"    then 4
        else if [QuoteStatus] = "Declined"    then 5
        else 99,
        Int64.Type),

    // === Add key ===
    #"Added key" = Table.AddIndexColumn(#"Added sort", "QuoteStatusKey", 1, 1, Int64.Type),

    // === Reorder ===
    #"Reordered" = Table.ReorderColumns(#"Added key", {
        "QuoteStatusKey", "QuoteStatus", "IsConverted", "StageOrder"
    })
in
    #"Reordered"
