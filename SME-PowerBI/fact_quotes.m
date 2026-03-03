let
    // ═══════════════════════════════════════════════════════
    // FACT_QUOTES — Lean (11 columns)
    // ═══════════════════════════════════════════════════════
    // ⚠️ Adjust table Id "src_quotes" to match your Lakehouse table name

    // === SOURCE ===
    Source = Lakehouse.Contents(null),
    Nav1 = Source{[workspaceId = "76ec20c3-c400-415a-99c6-708f8207d5f9"]}[Data],
    Nav2 = Nav1{[lakehouseId = "0ebd6604-a5db-4624-b535-497cd55663c1"]}[Data],
    Raw = Nav2{[Id = "src_quote_marketing", ItemKind = "Table"]}[Data],

    // === STEP 1: Filter out test data ===
    #"Filtered" = Table.SelectRows(Raw, each [TestData] <> "Yes"),

    // === STEP 2: Keep only required columns ===
    #"Selected columns" = Table.SelectColumns(#"Filtered", {
        "QuoteReference", "CreationDate", "QuoteStatus", "QuoteType",
        "ProductName", "Insured", "PolicyNumber",
        "BasePremium", "TotalPremium"
    }),

    // === STEP 3: Rename ===
    #"Renamed" = Table.RenameColumns(#"Selected columns", {
        {"Insured", "InsuredName"}
    }),

    // === STEP 4: Clean currency columns (strip $ and commas) ===
    #"Cleaned currency" = Table.TransformColumns(#"Renamed", {
        {"BasePremium", each
            let
                asText = if Value.Is(_, type text) then _ else Text.From(_ ?? "0"),
                stripped = Text.Replace(Text.Replace(Text.Replace(asText, "$", ""), ",", ""), " ", "")
            in
                if stripped = "" or stripped = null then 0 else Number.From(stripped),
         type number},
        {"TotalPremium", each
            let
                asText = if Value.Is(_, type text) then _ else Text.From(_ ?? "0"),
                stripped = Text.Replace(Text.Replace(Text.Replace(asText, "$", ""), ",", ""), " ", "")
            in
                if stripped = "" or stripped = null then 0 else Number.From(stripped),
         type number}
    }),

    // === STEP 5: Set types ===
    #"Set types" = Table.TransformColumnTypes(#"Cleaned currency", {
        {"QuoteReference", type text},
        {"CreationDate", type date},
        {"QuoteStatus", type text},
        {"QuoteType", type text},
        {"ProductName", type text},
        {"InsuredName", type text},
        {"PolicyNumber", type text},
        {"BasePremium", Currency.Type},
        {"TotalPremium", Currency.Type}
    }),

    // === STEP 6: Trim text ===
    #"Trimmed" = Table.TransformColumns(#"Set types", {
        {"QuoteReference", each Text.Trim(_ ?? ""), type text},
        {"QuoteStatus",    each Text.Trim(_ ?? ""), type text},
        {"QuoteType",      each Text.Trim(_ ?? ""), type text},
        {"ProductName",    each Text.Trim(_ ?? ""), type text},
        {"InsuredName",    each Text.Trim(_ ?? ""), type text},
        {"PolicyNumber",   each Text.Trim(_ ?? ""), type text}
    }),

    // === STEP 7: Add QuoteKey ===
    #"Added QuoteKey" = Table.AddIndexColumn(#"Trimmed", "QuoteKey", 1, 1, Int64.Type),

    // === STEP 8: Add CreationDateKey (FK → Dim_Date) ===
    #"Added DateKey" = Table.AddColumn(#"Added QuoteKey", "CreationDateKey", each
        if [CreationDate] = null then null
        else Date.Year([CreationDate]) * 10000
           + Date.Month([CreationDate]) * 100
           + Date.Day([CreationDate]),
        Int64.Type
    ),

    // === FINAL: Reorder ===
    #"Reordered" = Table.ReorderColumns(#"Added DateKey", {
        "QuoteKey", "CreationDateKey",
        "QuoteReference", "CreationDate", "QuoteStatus", "QuoteType",
        "ProductName", "InsuredName", "PolicyNumber",
        "BasePremium", "TotalPremium"
    })
in
    #"Reordered"
