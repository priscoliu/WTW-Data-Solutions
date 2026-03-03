let
    // ═══════════════════════════════════════════════════════
    // FACT_QUOTES — Lean (8 columns)
    // ═══════════════════════════════════════════════════════

    // === SOURCE ===
    Source = Lakehouse.Contents(null),
    Nav1 = Source{[workspaceId = "76ec20c3-c400-415a-99c6-708f8207d5f9"]}[Data],
    Nav2 = Nav1{[lakehouseId = "0ebd6604-a5db-4624-b535-497cd55663c1"]}[Data],
    Raw = Nav2{[Id = "src_quote_marketing", ItemKind = "Table"]}[Data],

    // === STEP 1: Filter out test data ===
    #"Filtered" = Table.SelectRows(Raw, each [TestData] <> "Yes"),

    // === STEP 2: Keep only required columns ===
    #"Selected columns" = Table.SelectColumns(#"Filtered", {
        "QuoteType", "CreationDate", "LastModifiedDate",
        "PolicyNumber", "QuoteReference", "QuoteStatus",
        "BasePremium", "TotalPremium"
    }),

    // === STEP 3: Clean currency columns (strip $ and commas) ===
    #"Cleaned currency" = Table.TransformColumns(#"Selected columns", {
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

    // === STEP 4: Set types ===
    #"Set types" = Table.TransformColumnTypes(#"Cleaned currency", {
        {"QuoteType", type text},
        {"CreationDate", type date},
        {"LastModifiedDate", type date},
        {"PolicyNumber", type text},
        {"QuoteReference", type text},
        {"QuoteStatus", type text},
        {"BasePremium", Currency.Type},
        {"TotalPremium", Currency.Type}
    }),

    // === STEP 5: Trim text ===
    #"Trimmed" = Table.TransformColumns(#"Set types", {
        {"QuoteType",      each Text.Trim(_ ?? ""), type text},
        {"PolicyNumber",   each Text.Trim(_ ?? ""), type text},
        {"QuoteReference", each Text.Trim(_ ?? ""), type text},
        {"QuoteStatus",    each Text.Trim(_ ?? ""), type text}
    }),

    // === STEP 6: Sort by QuoteReference ===
    #"Sorted" = Table.Sort(#"Trimmed", {{"QuoteReference", Order.Ascending}})
in
    #"Sorted"
