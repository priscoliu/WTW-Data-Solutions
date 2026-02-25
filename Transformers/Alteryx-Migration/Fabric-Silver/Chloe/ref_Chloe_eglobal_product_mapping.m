let
  Source = SharePoint.Files("https://wtwonlineap.sharepoint.com/sites/rb-projects-prj-apac", [ApiVersion = 15]),
  #"Filtered rows" = Table.SelectRows(Source, each [Name] = "eGlobal Product Mapping.xlsx"),
  Navigation = #"Filtered rows"{[Name = "eGlobal Product Mapping.xlsx", #"Folder Path" = "https://wtwonlineap.sharepoint.com/sites/rb-projects-prj-apac/Shared Documents/General/1. Project Management/CRB Data/Mapping files/Product and LOB/"]}[Content],
  #"Imported Excel workbook" = Excel.Workbook(Navigation, null, true),
  #"Navigation 1" = #"Imported Excel workbook"{[Item = "Sheet1", Kind = "Sheet"]}[Data],
  
  // Set all columns to Text first so "Others" is a valid value
  #"Changed column type" = Table.TransformColumnTypes(#"Navigation 1", {{"Column1", type text}, {"Column2", type text}, {"Column3", type text}, {"Column4", type text}, {"Column5", type text}}),
  #"Promoted headers" = Table.PromoteHeaders(#"Changed column type", [PromoteAllScalars = true]),

  // --- START FIX ---
  
  // 1. Get Column Names
  ColumnHeaders = Table.ColumnNames(#"Promoted headers"),

  // 2. Replace TRUE ERRORS with "OTHERS"
  ErrorReplacementList = List.Transform(ColumnHeaders, each {_, "OTHERS"}),
  #"Replaced True Errors" = Table.ReplaceErrorValues(#"Promoted headers", ErrorReplacementList),

  // 3. Clean and Trim
  TransformOperations = List.Transform(ColumnHeaders, each {_, each if _ <> null then Text.Trim(Text.Clean(_)) else _, type nullable text}),
  #"Cleaned and Trimmed All" = Table.TransformColumns(#"Replaced True Errors", TransformOperations)

  // --- END FIX ---
in
  #"Cleaned and Trimmed All"
