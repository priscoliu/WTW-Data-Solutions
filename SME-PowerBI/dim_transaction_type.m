let
    // ═══════════════════════════════════════════════════════
    // DIM_TRANSACTION_TYPE — Sales transaction categories
    // ═══════════════════════════════════════════════════════
    // Derived from distinct TransactionType values in Sales

    // === SOURCE ===
    Source = Lakehouse.Contents(null),
    Navigation = Source{[workspaceId = "76ec20c3-c400-415a-99c6-708f8207d5f9"]}[Data],
    #"Navigation 1" = Navigation{[lakehouseId = "0ebd6604-a5db-4624-b535-497cd55663c1"]}[Data],
    #"Navigation 2" = #"Navigation 1"{[Id = "src_sales_marketing", ItemKind = "Table"]}[Data],

    // === STEP 1: Select Transaction Type column ===
    #"Selected col" = Table.SelectColumns(#"Navigation 2", {"Transaction Type"}),

    // === STEP 2: Rename ===
    #"Renamed" = Table.RenameColumns(#"Selected col", {
        {"Transaction Type", "TransactionType"}
    }),

    // === STEP 3: Clean & deduplicate ===
    #"Cleaned" = Table.TransformColumns(#"Renamed", {
        {"TransactionType", each Text.Trim(_ ?? ""), type text}
    }),
    #"Distinct" = Table.Distinct(#"Cleaned"),
    #"Filtered blanks" = Table.SelectRows(#"Distinct", each
        [TransactionType] <> "" and [TransactionType] <> null
    ),

    // === STEP 4: Add display name / sort ===
    #"Added SortOrder" = Table.AddColumn(#"Filtered blanks", "SortOrder", each
        if [TransactionType] = "New Business" then 1
        else if [TransactionType] = "Renewal" then 2
        else if [TransactionType] = "Endorsement" then 3
        else if [TransactionType] = "Cancellation" then 4
        else 99,
        Int64.Type
    ),

    // === STEP 5: Add TransactionTypeKey ===
    #"Added key" = Table.AddIndexColumn(#"Added SortOrder", "TransactionTypeKey", 1, 1, Int64.Type),

    // === STEP 6: Reorder ===
    #"Reordered" = Table.ReorderColumns(#"Added key", {
        "TransactionTypeKey", "TransactionType", "SortOrder"
    })
in
    #"Reordered"
