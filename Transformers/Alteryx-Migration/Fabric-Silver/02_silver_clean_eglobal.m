let
  Source = Lakehouse.Contents(null),
  Navigation = Source{[workspaceId = "76ec20c3-c400-415a-99c6-708f8207d5f9"]}[Data],
  #"Navigation 1" = Navigation{[lakehouseId = "1c0d3357-c170-4ddd-9738-e1c90bbe99f2"]}[Data],
  
  // UPDATED: Main Source Name
  #"Navigation 2" = #"Navigation 1"{[Id = "src_eglobal_premium_report", ItemKind = "Table"]}[Data],
  
  // Filter out ACCIDENT records
  #"Filtered rows" = Table.SelectRows(#"Navigation 2", each 
    [LINE OF BUSINESS] = null or not Text.Contains([LINE OF BUSINESS], "ACCIDENT", Comparer.OrdinalIgnoreCase)
  ),
  
  // Add INVOICE DATE NEXT YEAR
  #"Added INVOICE DATE NEXT YEAR" = Table.AddColumn(
    #"Filtered rows",
    "INVOICE DATE NEXT YEAR",
    each if [INVOICE DATE] = null then null else Date.AddYears([INVOICE DATE], 1),
    type nullable date
  ),
  
  // Replace EFFECTIVE DATE
  #"Replace EFFECTIVE DATE" = Table.ReplaceValue(
    #"Added INVOICE DATE NEXT YEAR",
    each [EFFECTIVE DATE],
    each if [EFFECTIVE DATE] = null or [EFFECTIVE DATE] = "" then [INVOICE DATE] else [EFFECTIVE DATE],
    Replacer.ReplaceValue,
    {"EFFECTIVE DATE"}
  ),
  
  // Replace EXPIRY DATE
  #"Replace EXPIRY DATE" = Table.ReplaceValue(
    #"Replace EFFECTIVE DATE",
    each [EXPIRY DATE],
    each if [EXPIRY DATE] = null or [EXPIRY DATE] = "" then [INVOICE DATE NEXT YEAR] else [EXPIRY DATE],
    Replacer.ReplaceValue,
    {"EXPIRY DATE"}
  ),
  
  // UPDATED: Join with ref_eglobal_premium_branch_mapping
  #"Merged queries" = Table.NestedJoin(#"Replace EXPIRY DATE", {"INS BRANCH"}, #"ref_eglobal_premium_branch_mapping", {"BRANCH"}, "ref_eglobal_premium_branch_mapping", JoinKind.LeftOuter),
  #"Expanded mapping" = Table.ExpandTableColumn(#"Merged queries", "ref_eglobal_premium_branch_mapping", {"INSURER COUNTRY"}, {"INSURER COUNTRY.1"}),
  
  // Conditional Replace INSURER COUNTRY for Hong Kong
  #"Conditional Replace Country" = Table.ReplaceValue(
    #"Expanded mapping",
    each [INSURER COUNTRY],
    each if Text.Contains([Source.Name], "HONGKONG", Comparer.OrdinalIgnoreCase) and [#"INSURER COUNTRY.1"] <> null 
         then [#"INSURER COUNTRY.1"] 
         else [INSURER COUNTRY],
    Replacer.ReplaceValue,
    {"INSURER COUNTRY"}
  ),
  
  #"Removed Columns" = Table.RemoveColumns(#"Conditional Replace Country", {"INSURER COUNTRY.1"}),
  
  // Add Revenue Country based on Source.Name (Includes AU/NZ)
  #"Added Revenue Country" = Table.AddColumn(
    #"Removed Columns",
    "Revenue Country",
    each if Text.Contains([Source.Name], "China", Comparer.OrdinalIgnoreCase) then "China"
         else if Text.Contains([Source.Name], "HONGKONG", Comparer.OrdinalIgnoreCase) then "Hong Kong"
         else if Text.Contains([Source.Name], "Indonesia", Comparer.OrdinalIgnoreCase) then "Indonesia"
         else if Text.Contains([Source.Name], "Taiwan", Comparer.OrdinalIgnoreCase) then "Taiwan"
         else if Text.Contains([Source.Name], "Korea", Comparer.OrdinalIgnoreCase) then "Korea"
         else if Text.Contains([Source.Name], "Philippines", Comparer.OrdinalIgnoreCase) then "Philippines"
         else if Text.Contains([Source.Name], "Australia", Comparer.OrdinalIgnoreCase) then "Australia"
         else if Text.Contains([Source.Name], "New Zealand", Comparer.OrdinalIgnoreCase) then "New Zealand"
         else null,
    type nullable text
  ),
  
  // Add FINAL DATE
  #"Added FINAL DATE" = Table.AddColumn(
    #"Added Revenue Country",
    "FINAL DATE",
    each [INVOICE DATE],
    type nullable date
  ),
  
  // Add FINAL YEAR
  #"Added FINAL YEAR" = Table.AddColumn(
    #"Added FINAL DATE",
    "FINAL YEAR",
    each if [FINAL DATE] = null then null else Text.From(Date.Year([FINAL DATE])),
    type nullable text
  ),
  
  // Add CCY based on Revenue Country (Includes AUD/NZD)
  #"Added CCY" = Table.AddColumn(
    #"Added FINAL YEAR",
    "CCY",
    each if [Revenue Country] = "China" then "CNY"
         else if [Revenue Country] = "Hong Kong" then "HKD"
         else if [Revenue Country] = "Indonesia" then "IDR"
         else if [Revenue Country] = "Taiwan" then "TWD"
         else if [Revenue Country] = "Korea" then "KRW"
         else if [Revenue Country] = "Philippines" then "PHP"
         else if [Revenue Country] = "Australia" then "AUD"
         else if [Revenue Country] = "New Zealand" then "NZD"
         else null,
    type nullable text
  ),
  
  // Add CCYYEAR
  #"Added CCYYEAR" = Table.AddColumn(
    #"Added CCY",
    "CCYYEAR",
    each if [CCY] = null or [FINAL YEAR] = null then null else [CCY] & "-" & [FINAL YEAR],
    type nullable text
  ),
  
  // Transform Columns: Trim + Uppercase
  #"Transform RISK DESCRIPTION" = Table.TransformColumns(
    #"Added CCYYEAR",
    {{"RISK DESCRIPTION", each if _ = null then null else Text.Trim(Text.Upper(_)), type nullable text}}
  ),
  #"Transform INSURER NAME" = Table.TransformColumns(
    #"Transform RISK DESCRIPTION",
    {{"INSURER NAME", each if _ = null then null else Text.Trim(Text.Upper(_)), type nullable text}}
  ),
  #"Transform CCYYEAR" = Table.TransformColumns(
    #"Transform INSURER NAME",
    {{"CCYYEAR", each if _ = null then null else Text.Trim(Text.Upper(_)), type nullable text}}
  ),
  
  // Replace null RISK DESCRIPTION with "Unknown"
  #"Replace null RISK DESCRIPTION" = Table.ReplaceValue(
    #"Transform CCYYEAR",
    each [RISK DESCRIPTION],
    each if [RISK DESCRIPTION] = null then "Unknown" else [RISK DESCRIPTION],
    Replacer.ReplaceValue,
    {"RISK DESCRIPTION"}
  ),
  
  // UPDATED: Join with ref_Chloe_asia_currency_mapping
  #"Merged queries 1" = Table.NestedJoin(#"Replace null RISK DESCRIPTION", {"CCYYEAR"}, #"ref_Chloe_asia_currency_mapping", {"CCYYEAR"}, "ref_Chloe_asia_currency_mapping", JoinKind.LeftOuter),
  #"Expanded Asia Currency Mapping" = Table.ExpandTableColumn(#"Merged queries 1", "ref_Chloe_asia_currency_mapping", {"Value"}, {"Value"}),
  #"Renamed columns" = Table.RenameColumns(#"Expanded Asia Currency Mapping", {{"Value", "CCYVALUE"}}),
  
  #"Changed column type" = Table.TransformColumnTypes(#"Renamed columns", {{"INSURER COUNTRY", type text}, {"RISK DESCRIPTION", type text}, {"EFFECTIVE DATE", type date}, {"EXPIRY DATE", type date}, {"Levies A", type number}, {"Levies B", type number}}),
  
  // UPDATED: Join with ref_Chloe_eglobal_product_mapping
  #"Merged queries 2" = Table.NestedJoin(#"Changed column type", {"RISK DESCRIPTION"}, #"ref_Chloe_eglobal_product_mapping", {"SYSTEM PRODUCT ID"}, "ref_Chloe_eglobal_product_mapping", JoinKind.LeftOuter),
  #"Expanded E-global Product Mapping" = Table.ExpandTableColumn(#"Merged queries 2", "ref_Chloe_eglobal_product_mapping", {"Sub Product Class", "GLOBs", "GLOBS SPLIT P&C"}, {"Sub Product Class", "GLOBs", "GLOBS SPLIT P&C"}),
  
  // UPDATED: Join with ref_Chloe_insurer_mapping
  #"Merged queries 3" = Table.NestedJoin(#"Expanded E-global Product Mapping", {"INSURER NAME"}, #"ref_Chloe_insurer_mapping", {"Insurer"}, "ref_Chloe_insurer_mapping", JoinKind.LeftOuter),
  #"Expanded Insurer mapping" = Table.ExpandTableColumn(#"Merged queries 3", "ref_Chloe_insurer_mapping", {"MAPPED_INSURER", "LLOYDS", "Lloyd's Asia or Lloyd's London"}, {"MAPPED_INSURER", "LLOYDS", "Lloyd's Asia or Lloyd's London"}),
  
  // Add PREMIUM (USD)
  #"Added PREMIUM (USD)" = Table.AddColumn(
    #"Expanded Insurer mapping",
    "PREMIUM (USD)",
    each if [Premium] = null or [CCYVALUE] = null then null else Number.From([Premium]) * Number.From([CCYVALUE]),
    type number
  ),
  
  // Add BROKERAGE (USD)
  #"Added BROKERAGE (USD)" = Table.AddColumn(
    #"Added PREMIUM (USD)",
    "BROKERAGE (USD)",
    each if [Brokerage] = null or [CCYVALUE] = null then null else Number.From([Brokerage]) * Number.From([CCYVALUE]),
    type number
  ),
  
  // Add SYSTEM ID
  #"Added SYSTEM ID" = Table.AddColumn(
    #"Added BROKERAGE (USD)",
    "SYSTEM ID",
    each if [COMPANY] = null or [BRANCH] = null or [CLIENT NUMBER] = null 
         then null 
         else [COMPANY] & [BRANCH] & [CLIENT NUMBER],
    type nullable text
  ),
  
  // Add CLIENTID
  #"Added CLIENTID" = Table.AddColumn(
    #"Added SYSTEM ID",
    "CLIENTID",
    each if [#"Party ID"] = null then [SYSTEM ID] else [#"Party ID"],
    type text
  ),
  
  // Add BUSINESS TYPE
  #"Added BUSINESS TYPE" = Table.AddColumn(
    #"Added CLIENTID",
    "BUSINESS TYPE",
    each "Unknown",
    type text
  ),
  
  // Add DATA SOURCE
  #"Added DATA SOURCE" = Table.AddColumn(
    #"Added BUSINESS TYPE",
    "DATA SOURCE",
    each "EglobaL",
    type text
  ),
  
  // Add REINSURANCE DESCRIPTION
  #"Added REINSURANCE DESCRIPTION" = Table.AddColumn(
    #"Added DATA SOURCE",
    "REINSURANCE DESCRIPTION",
    each if [RISK DESCRIPTION] <> null and Text.Contains([RISK DESCRIPTION], "Reinsurance", Comparer.OrdinalIgnoreCase)
         then "Reinsurance:Refer to Policy Description" & (if [#"Policy Description"] = null then "" else [#"Policy Description"])
         else "null",
    type nullable text
  ),
  #"Choose columns" = Table.SelectColumns(#"Added REINSURANCE DESCRIPTION", {"INVOICE NO", "POLICY DEPT", "INSURER NAME", "INSURER COUNTRY", "CLIENT NAME", "RISK DESCRIPTION", "INVOICE DATE", "EFFECTIVE DATE", "EXPIRY DATE", "ACCOUNT HANDLER", "Transaction Type", "Policy Description", "Party ID", "DUNS Number", "Revenue Country", "FINAL DATE", "Sub Product Class", "GLOBs", "GLOBS SPLIT P&C", "MAPPED_INSURER", "LLOYDS", "PREMIUM (USD)", "BROKERAGE (USD)", "SYSTEM ID", "CLIENTID", "BUSINESS TYPE", "DATA SOURCE", "REINSURANCE DESCRIPTION"}),
  #"Renamed columns 1" = Table.RenameColumns(#"Choose columns", {{"CLIENTID", "CLIENT ID (WTW)"}, {"DUNS Number", "DUNS NUMBER"}, {"EFFECTIVE DATE", "INCEPTION DATE"}, {"INVOICE NO", "INVOICE/POLICY NUMBER"}, {"Party ID", "PARTY ID (WTW)"}, {"POLICY DEPT", "DEPARTMENT"}, {"Policy Description", "POLICY DESCRIPTION"}, {"RISK DESCRIPTION", "SYSTEM PRODUCT ID"}, {"MAPPED_INSURER", "INSURER MAPPING"}})
in
  #"Renamed columns 1"
