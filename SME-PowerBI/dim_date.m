let
    // ═══════════════════════════════════════════════════════
    // DIM_DATE — Simplified calendar dimension
    // ═══════════════════════════════════════════════════════
    // ⚠️ Adjust StartDate/EndDate to match your data range

    StartDate = #date(2025, 6, 1),
    EndDate   = #date(2026, 6, 30),
    DayCount  = Duration.Days(EndDate - StartDate) + 1,

    // === Generate date list ===
    DateList = List.Dates(StartDate, DayCount, #duration(1, 0, 0, 0)),
    #"To table" = Table.FromList(DateList, Splitter.SplitByNothing(), {"Date"}, null, ExtraValues.Error),
    #"Set date type" = Table.TransformColumnTypes(#"To table", {{"Date", type date}}),

    // === Add calendar columns ===
    #"Added DateKey" = Table.AddColumn(#"Set date type", "DateKey", each
        Date.Year([Date]) * 10000 + Date.Month([Date]) * 100 + Date.Day([Date]),
        Int64.Type),
    #"Added Year" = Table.AddColumn(#"Added DateKey", "Year", each Date.Year([Date]), Int64.Type),
    #"Added Month" = Table.AddColumn(#"Added Year", "Month", each Date.Month([Date]), Int64.Type),
    #"Added MonthName" = Table.AddColumn(#"Added Month", "MonthName", each Date.MonthName([Date]), type text),
    #"Added Quarter" = Table.AddColumn(#"Added MonthName", "Quarter", each
        "Q" & Text.From(Date.QuarterOfYear([Date])), type text),
    #"Added WeekNumber" = Table.AddColumn(#"Added Quarter", "WeekNumber", each
        Date.WeekOfYear([Date], Day.Monday), Int64.Type),
    #"Added WeekStart" = Table.AddColumn(#"Added WeekNumber", "WeekStartDate", each
        Date.StartOfWeek([Date], Day.Monday), type date),

    // === Australian Financial Year (Jul–Jun) ===
    #"Added FiscalYear" = Table.AddColumn(#"Added WeekStart", "FiscalYear", each
        if Date.Month([Date]) >= 7 then Date.Year([Date]) + 1 else Date.Year([Date]),
        Int64.Type),
    #"Added FYLabel" = Table.AddColumn(#"Added FiscalYear", "FiscalYearLabel", each
        "FY" & Text.End(Text.From([FiscalYear]), 2), type text),

    // === YTD & WTD flags ===
    Today = DateTime.Date(DateTime.LocalNow()),
    CurrentWeekStart = Date.StartOfWeek(Today, Day.Monday),
    CurrentFY_Start = if Date.Month(Today) >= 7
        then #date(Date.Year(Today), 7, 1)
        else #date(Date.Year(Today) - 1, 7, 1),

    #"Added IsWTD" = Table.AddColumn(#"Added FYLabel", "IsWTD", each
        [Date] >= CurrentWeekStart and [Date] <= Today, type logical),
    #"Added IsYTD" = Table.AddColumn(#"Added IsWTD", "IsYTD", each
        [Date] >= CurrentFY_Start and [Date] <= Today, type logical),

    // === Sort helper ===
    #"Added YearMonthSort" = Table.AddColumn(#"Added IsYTD", "YearMonthSort", each
        Date.Year([Date]) * 100 + Date.Month([Date]), Int64.Type),

    // === Reorder ===
    #"Reordered" = Table.ReorderColumns(#"Added YearMonthSort", {
        "DateKey", "Date",
        "Year", "Quarter", "Month", "MonthName", "YearMonthSort",
        "WeekNumber", "WeekStartDate",
        "FiscalYear", "FiscalYearLabel",
        "IsWTD", "IsYTD"
    })
in
    #"Reordered"
