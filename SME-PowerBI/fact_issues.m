let
    // ═══════════════════════════════════════════════════════
    // FACT_ISSUES — uBind Issues (Technology page)
    // ═══════════════════════════════════════════════════════
    // Backlog = Status is "Open"
    // No criticality column in source data

    // === SOURCE ===
    Source = Lakehouse.Contents(null),
    Nav1 = Source{[workspaceId = "76ec20c3-c400-415a-99c6-708f8207d5f9"]}[Data],
    Nav2 = Nav1{[lakehouseId = "0ebd6604-a5db-4624-b535-497cd55663c1"]}[Data],
    Raw = Nav2{[Id = "src_issue_technology", ItemKind = "Table"]}[Data],

    // === STEP 1: Rename to PascalCase ===
    #"Renamed" = Table.RenameColumns(Raw, {
        {"Date", "RaisedDate"},
        {"Ticket Number", "TicketNumber"},
        {"Date Fixed", "FixedDate"}
    }),

    // === STEP 2: Trim text ===
    #"Trimmed" = Table.TransformColumns(#"Renamed", {
        {"TicketNumber",  each Text.Trim(_ ?? ""), type text},
        {"Description",   each Text.Trim(_ ?? ""), type text},
        {"Status",        each Text.Trim(_ ?? ""), type text},
        {"Reporter",      each Text.Trim(_ ?? ""), type text}
    }),

    // === STEP 3: Filter out blank tickets ===
    #"Filtered" = Table.SelectRows(#"Trimmed", each
        [TicketNumber] <> "" and [TicketNumber] <> null
    ),

    // === STEP 4: Add computed columns ===
    #"Added IsOpen" = Table.AddColumn(#"Filtered", "IsOpen", each
        [Status] = "Open", type logical),
    #"Added DaysOpen" = Table.AddColumn(#"Added IsOpen", "DaysOpen", each
        if [FixedDate] <> null then Duration.Days([FixedDate] - [RaisedDate])
        else if [IsOpen] then Duration.Days(DateTime.Date(DateTime.LocalNow()) - [RaisedDate])
        else null,
        type nullable Int64.Type),

    // === STEP 5: Set types ===
    #"Set types" = Table.TransformColumnTypes(#"Added DaysOpen", {
        {"RaisedDate", type date},
        {"TicketNumber", type text},
        {"Description", type text},
        {"Status", type text},
        {"Reporter", type text},
        {"FixedDate", type date}
    }),

    // === FINAL: Reorder ===
    #"Reordered" = Table.ReorderColumns(#"Set types", {
        "TicketNumber", "RaisedDate", "FixedDate",
        "Status", "IsOpen", "DaysOpen",
        "Description", "Reporter"
    })
in
    #"Reordered"
