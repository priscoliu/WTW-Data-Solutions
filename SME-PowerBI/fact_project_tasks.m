let
    // ═══════════════════════════════════════════════════════
    // FACT_PROJECT_TASKS — Project Plan (Delivery page)
    // ═══════════════════════════════════════════════════════
    // Dates come as "Thu 12/04/25" (DD/MM/YY) — strip day name, parse date
    // Duration comes as "84 days?" — strip "days" and "?"

    // === SOURCE ===
    Source = Lakehouse.Contents(null),
    Nav1 = Source{[workspaceId = "76ec20c3-c400-415a-99c6-708f8207d5f9"]}[Data],
    Nav2 = Nav1{[lakehouseId = "0ebd6604-a5db-4624-b535-497cd55663c1"]}[Data],
    Raw = Nav2{[Id = "src_project_delivery", ItemKind = "Table"]}[Data],

    // === STEP 1: Rename to PascalCase ===
    #"Renamed" = Table.RenameColumns(Raw, {
        {"% Complete", "PctComplete"},
        {"Task Mode", "TaskMode"},
        {"Task Name", "TaskName"},
        {"Actual Finish", "ActualFinish"},
        {"Resource Names", "ResourceNames"},
        {"Baseline Deliverable Start", "BaselineStart"},
        {"Baseline Deliverable Finish", "BaselineFinish"}
    }),

    // === STEP 2: Parse dates — strip day names, MM/DD/YY format (MS Project) ===
    _parseDate = (val as nullable text) as nullable date =>
        let
            raw = Text.Trim(val ?? ""),
            // Remove all day-of-week prefixes
            s1 = Text.Replace(raw, "Mon ", ""),
            s2 = Text.Replace(s1, "Tue ", ""),
            s3 = Text.Replace(s2, "Wed ", ""),
            s4 = Text.Replace(s3, "Thu ", ""),
            s5 = Text.Replace(s4, "Fri ", ""),
            s6 = Text.Replace(s5, "Sat ", ""),
            s7 = Text.Replace(s6, "Sun ", ""),
            cleaned = Text.Trim(s7),
            // Try multiple date formats (US MM/DD from MS Project)
            parsed =
                if cleaned = "" or cleaned = "NA" or cleaned = "N/A" then null
                else try Date.FromText(cleaned, [Format = "MM/dd/yy", Culture = "en-US"])
                     otherwise try Date.FromText(cleaned, [Format = "M/dd/yy", Culture = "en-US"])
                     otherwise try Date.FromText(cleaned, [Format = "MM/dd/yyyy", Culture = "en-US"])
                     otherwise try Date.FromText(cleaned, [Format = "M/d/yy", Culture = "en-US"])
                     otherwise try Date.From(cleaned)
                     otherwise null
        in
            parsed,

    #"Parsed Start" = Table.TransformColumns(#"Renamed", {
        {"Start",          _parseDate, type nullable date},
        {"Finish",         _parseDate, type nullable date},
        {"ActualFinish",   _parseDate, type nullable date},
        {"BaselineStart",  _parseDate, type nullable date},
        {"BaselineFinish", _parseDate, type nullable date}
    }),

    // === STEP 3: Parse duration ("84 days?" → 84) ===
    #"Parsed Duration" = Table.TransformColumns(#"Parsed Start", {
        {"Duration", each
            let
                raw = Text.Trim(_ ?? ""),
                stripped = Text.Replace(Text.Replace(Text.Replace(raw, "days", ""), "day", ""), "?", ""),
                num = try Number.From(Text.Trim(stripped)) otherwise null
            in
                num,
         type nullable number}
    }),

    // === STEP 4: Trim text ===
    #"Trimmed" = Table.TransformColumns(#"Parsed Duration", {
        {"TaskMode",      each Text.Trim(_ ?? ""), type text},
        {"TaskName",      each Text.Trim(_ ?? ""), type text},
        {"ResourceNames", each Text.Trim(_ ?? ""), type text},
        {"Critical",      each Text.Trim(_ ?? ""), type text},
        {"Notes",         each Text.Trim(_ ?? ""), type text}
    }),

    // === STEP 5: Filter out blank task names ===
    #"Filtered" = Table.SelectRows(#"Trimmed", each
        [TaskName] <> "" and [TaskName] <> null
    ),

    // === STEP 6: Effective finish (ActualFinish overrides Finish) ===
    #"Added EffFinish" = Table.AddColumn(#"Filtered", "EffectiveFinish", each
        if [ActualFinish] <> null then [ActualFinish] else [Finish],
        type nullable date),

    // Recalculate actual duration (Start → EffectiveFinish) in days
    #"Added ActDuration" = Table.AddColumn(#"Added EffFinish", "ActualDuration", each
        if [Start] <> null and [EffectiveFinish] <> null
        then Duration.Days([EffectiveFinish] - [Start])
        else [Duration],
        type nullable number),

    // === STEP 7: Add computed columns ===
    // IsCritical flag
    #"Added IsCritical" = Table.AddColumn(#"Added ActDuration", "IsCritical", each
        [Critical] = "Yes", type logical),

    // Milestone horizon (30/60/90 days from today) based on EffectiveFinish
    Today = DateTime.Date(DateTime.LocalNow()),
    #"Added Horizon" = Table.AddColumn(#"Added IsCritical", "MilestoneHorizon", each
        if [EffectiveFinish] = null then null
        else
            let daysUntil = Duration.Days([EffectiveFinish] - Today)
            in
                if daysUntil < 0 then "Overdue"
                else if daysUntil <= 30 then "Next 30 Days"
                else if daysUntil <= 60 then "Next 60 Days"
                else if daysUntil <= 90 then "Next 90 Days"
                else "Beyond 90 Days",
        type text),

    // Days until effective finish
    #"Added DaysUntil" = Table.AddColumn(#"Added Horizon", "DaysUntilFinish", each
        if [EffectiveFinish] = null then null
        else Duration.Days([EffectiveFinish] - Today),
        Int64.Type),

    // Is delayed (EffectiveFinish > BaselineFinish)
    #"Added IsDelayed" = Table.AddColumn(#"Added DaysUntil", "IsDelayed", each
        if [EffectiveFinish] = null or [BaselineFinish] = null then null
        else [EffectiveFinish] > [BaselineFinish],
        type nullable logical),

    // === STEP 8: Set types ===
    #"Set types" = Table.TransformColumnTypes(#"Added IsDelayed", {
        {"PctComplete", Percentage.Type},
        {"Predecessors", Int64.Type}
    }),

    // === FINAL: Reorder ===
    #"Reordered" = Table.ReorderColumns(#"Set types", {
        "TaskName", "Start", "Finish", "ActualFinish", "EffectiveFinish",
        "Duration", "ActualDuration", "PctComplete",
        "MilestoneHorizon", "DaysUntilFinish", "IsCritical", "IsDelayed",
        "BaselineStart", "BaselineFinish",
        "TaskMode", "ResourceNames", "Critical", "Predecessors", "Notes"
    })
in
    #"Reordered"
