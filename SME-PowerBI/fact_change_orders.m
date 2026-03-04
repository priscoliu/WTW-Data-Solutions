let
    // ═══════════════════════════════════════════════════════
    // FACT_CHANGE_ORDERS — Change Requests (Technology page)
    // ═══════════════════════════════════════════════════════
    // Spend = SUM(ApprovedCost) where Status is open/in-progress
    // Due date is free text — kept as-is (not a real date)

    // === SOURCE ===
    Source = Lakehouse.Contents(null),
    Nav1 = Source{[workspaceId = "76ec20c3-c400-415a-99c6-708f8207d5f9"]}[Data],
    Nav2 = Nav1{[lakehouseId = "0ebd6604-a5db-4624-b535-497cd55663c1"]}[Data],
    Raw = Nav2{[Id = "src_change_technology", ItemKind = "Table"]}[Data],

    // === STEP 1: Filter out header/junk rows (Status = year like "2026") ===
    #"Filtered junk" = Table.SelectRows(Raw, each
        [Change Request Number] <> null and [Change Request Number] <> ""
    ),

    // === STEP 2: Rename to PascalCase ===
    #"Renamed" = Table.RenameColumns(#"Filtered junk", {
        {"Change Request", "ChangeRequestDesc"},
        {"Change Request Number", "ChangeRequestNumber"},
        {"Requirements and Acceptance Criteria", "Requirements"},
        {"Approved date", "ApprovedDate"},
        {"Target Release Date to UAT", "TargetReleaseUAT"},
        {"Release Date _Actual Release to Prod_", "ActualReleaseProd"},
        {"Approved Cost", "ApprovedCost"},
        {"Cost Type", "CostType"},
        {"% Completion | Time and Materials", "CompletionPct"},
        {"Due date", "DueDateNote"}
    }),

    // === STEP 3: Trim text ===
    #"Trimmed" = Table.TransformColumns(#"Renamed", {
        {"ChangeRequestNumber", each Text.Trim(_ ?? ""), type text},
        {"ChangeRequestDesc",   each Text.Trim(_ ?? ""), type text},
        {"Status",              each Text.Trim(_ ?? ""), type text},
        {"Requirements",        each Text.Trim(_ ?? ""), type text},
        {"TargetReleaseUAT",    each Text.Trim(_ ?? ""), type text},
        {"CostType",            each Text.Trim(_ ?? ""), type text},
        {"CompletionPct",       each Text.Trim(_ ?? ""), type text},
        {"DueDateNote",         each Text.Trim(_ ?? ""), type text}
    }),

    // === STEP 4: Handle nulls for cost ===
    #"Null cost" = Table.ReplaceValue(#"Trimmed", null, 0,
        Replacer.ReplaceValue, {"ApprovedCost"}),

    // === STEP 5: Add IsOpen flag ===
    #"Added IsOpen" = Table.AddColumn(#"Null cost", "IsOpen", each
        [Status] <> "Completed" and [Status] <> "Closed" and [Status] <> "Cancelled",
        type logical),

    // === STEP 6: Set types ===
    #"Set types" = Table.TransformColumnTypes(#"Added IsOpen", {
        {"ChangeRequestNumber", type text},
        {"ChangeRequestDesc", type text},
        {"Status", type text},
        {"Requirements", type text},
        {"ApprovedDate", type date},
        {"TargetReleaseUAT", type text},
        {"ActualReleaseProd", type date},
        {"ApprovedCost", Currency.Type},
        {"CostType", type text},
        {"CompletionPct", type text},
        {"DueDateNote", type text}
    }),

    // === FINAL: Reorder ===
    #"Reordered" = Table.ReorderColumns(#"Set types", {
        "ChangeRequestNumber", "ChangeRequestDesc", "Status", "IsOpen",
        "ApprovedDate", "TargetReleaseUAT", "ActualReleaseProd", "DueDateNote",
        "ApprovedCost", "CostType", "CompletionPct", "Requirements"
    })
in
    #"Reordered"
