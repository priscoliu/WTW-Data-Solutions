let
  Source = SharePoint.Files("https://wtwonlineap.sharepoint.com/sites/tctnonclient_APACSCMDat", [ApiVersion = 15]),
  #"Filtered rows" = Table.SelectRows(Source, each ([Extension] = ".xlsx")),
  #"Filtered rows 2" = Table.SelectRows(#"Filtered rows", each [Folder Path] = "https://wtwonlineap.sharepoint.com/sites/tctnonclient_APACSCMDat/Data Library/Client Baseline/02. Raw Data/eGlobal/"),
  #"Filtered hidden files" = Table.SelectRows(#"Filtered rows 2", each [Attributes]?[Hidden]? <> true),
  #"Filtered rows 1" = Table.SelectRows(#"Filtered hidden files", each Text.StartsWith([Name], "Premium_Volume_Report")),
  #"Invoke custom function" = Table.AddColumn(#"Filtered rows 1", "Transform file", each #"Transform file"([Content])),
  #"Renamed columns" = Table.RenameColumns(#"Invoke custom function", {{"Name", "Source.Name"}}),
  #"Removed other columns" = Table.SelectColumns(#"Renamed columns", {"Source.Name", "Transform file"}),
  #"Expanded table column" = Table.ExpandTableColumn(#"Removed other columns", "Transform file", Table.ColumnNames(#"Transform file"(#"Sample file"))),
  #"Changed column type" = Table.TransformColumnTypes(#"Expanded table column", {{"COMPANY", type text}, {"BRANCH", type text}, {"INVOICE NO", type text}, {"COVER NO.", type text}, {"VER NO.", type text}, {"POLICY DEPT", type text}, {"INS CODE", type text}, {"INS BRANCH", type text}, {"INSURER NAME", type text}, {"INSURER COUNTRY", type text}, {"CLIENT NUMBER", type text}, {"CLIENT NAME", type text}, {"CLIENT COUNTRY", type text}, {"BUSINESS CODE", type text}, {"INDUSTRY", type text}, {"Client Willis Industry Code", type text}, {"Client Willis Industry ", type text}, {"RISK DESCRIPTION", type text}, {"CLASS CODE", type text}, {"LINE OF BUSINESS", type text}, {"INVOICE DATE", type date}, {"EFFECTIVE DATE", type date}, {"EXPIRY DATE", type date}, {"RENEWAL DATE", type date}, {"Premium", type number}, {"Levies A", Int64.Type}, {"Levies B", type number}, {"CE Quake", type number}, {"Brokerage", type number}, {"Non Res. Tax", Int64.Type}, {"VAT (Tax) Prem", Int64.Type}, {"VAT (Tax)  Brok", Int64.Type}, {"Nett Payment", type number}, {"ACCOUNT HANDLER", type text}, {"Transaction Type", type text}, {"Income Class", type text}, {"Group Code", type text}, {"Policy Description", type text}, {"Party ID", type text}, {"DUNS Number", type text}})
in
  #"Changed column type"