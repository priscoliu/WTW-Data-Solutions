let
  Source = SharePoint.Files("https://wtwonlineap.sharepoint.com/sites/tctnonclient_APACSCMDat", [ApiVersion = 15]),
  #"Filtered rows" = Table.SelectRows(Source, each ([Folder Path] = "https://wtwonlineap.sharepoint.com/sites/tctnonclient_APACSCMDat/Data Library/Client Baseline/02. Raw Data/eGlobal/")),
  #"Filtered rows 1" = Table.SelectRows(#"Filtered rows", each Text.StartsWith([Name], "IncomebyDepartmentandClient")),
  #"Filtered hidden files" = Table.SelectRows(#"Filtered rows 1", each [Attributes]?[Hidden]? <> true),
  #"Filtered hidden files 1" = Table.SelectRows(#"Filtered hidden files", each [Attributes]?[Hidden]? <> true),
  #"Invoke custom function" = Table.AddColumn(#"Filtered hidden files 1", "Transform file (2)", each #"Transform file (2)"([Content])),
  #"Renamed columns" = Table.RenameColumns(#"Invoke custom function", {{"Name", "Source.Name"}}),
  #"Removed other columns" = Table.SelectColumns(#"Renamed columns", {"Source.Name", "Transform file (2)"}),
  #"Expanded table column" = Table.ExpandTableColumn(#"Removed other columns", "Transform file (2)", Table.ColumnNames(#"Transform file (2)"(#"Sample file (2)"))),
  #"Changed column type" = Table.TransformColumnTypes(#"Expanded table column", {{"Column1", type text}, {"Column2", type text}, {"Column3", type text}, {"Column4", type text}, {"Column14", type text}, {"Column15", type text}, {"Column16", type text}, {"Column17", type text}, {"Column18", type text}, {"Column20", type text}, {"Column21", type text}, {"Column22", type text}, {"Column23", type text}, {"Column24", type text}, {"Column25", type text}, {"Column26", type text}, {"Column27", type text}, {"Column29", type text}, {"Column31", type text}, {"Column36", type text}, {"Column38", type text}, {"Column39", type text}, {"Column40", type text}}),
  #"Removed top rows" = Table.Skip(#"Changed column type", 2),
  #"Promoted headers" = Table.PromoteHeaders(#"Removed top rows", [PromoteAllScalars = true]),
  
  // Safe numeric conversion - ALL as nullable number (no Int64)
  #"Safe Numeric Conversion" = Table.TransformColumns(#"Promoted headers", {
    {"PREMIUM", each try Number.From(_) otherwise 0, type nullable number},
    {"CEQUAKE", each try Number.From(_) otherwise 0, type nullable number},
    {"BSC FEE", each try Number.From(_) otherwise 0, type nullable number},
    {"ADMIN FEE", each try Number.From(_) otherwise 0, type nullable number},
    {"POLICY FEE", each try Number.From(_) otherwise 0, type nullable number},
    {"BROKERAGE", each try Number.From(_) otherwise 0, type nullable number},
    {"DISCOUNT", each try Number.From(_) otherwise 0, type nullable number},
    {"SUB AGENT", each try Number.From(_) otherwise 0, type nullable number},
    {"TOTAL INCOME", each try Number.From(_) otherwise 0, type nullable number},
    {"EXCHANGE RATE", each try Number.From(_) otherwise null, type nullable number}
  }),

  // Safe date conversion
  #"Safe Date Conversion" = Table.TransformColumns(#"Safe Numeric Conversion", {
    {"Inv Date ", each try Date.From(_) otherwise null, type nullable date},
    {"INCEPTION DATE", each try Date.From(_) otherwise null, type nullable date},
    {"EFFECTIVE DATE", each try Date.From(_) otherwise null, type nullable date},
    {"RENEWAL DATE", each try Date.From(_) otherwise null, type nullable date},
    {"LAST RENEWAL DATE", each try Date.From(_) otherwise null, type nullable date},
    {"INCOME DATE", each try Date.From(_) otherwise null, type nullable date}
  }),

  // Set text types
  #"Set Text Types" = Table.TransformColumnTypes(#"Safe Date Conversion", {
    {"Client No", type text},
    {"Inv No", type text},
    {"Cover No", type text},
    {"Ver. No", type text},
    {"NO OF INSTALMENTS", type text},
    {"PARTY ID", type text},
    {"DUNS NUMBER", type text}
  }),

  #"Renamed columns 1" = Table.RenameColumns(#"Set Text Types", {{"IncomebyDepartmentandClient_AU_InvoiceDate_2024.xlsx", "Source.Name"}})
in
  #"Renamed columns 1"