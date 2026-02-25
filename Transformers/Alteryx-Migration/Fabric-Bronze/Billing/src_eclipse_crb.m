let
  Source = SharePoint.Files("https://wtwonlineap.sharepoint.com/sites/tctnonclient_APACSCMDat", [ApiVersion = 15]),
  #"Filtered rows" = Table.SelectRows(Source, each [Folder Path] = "https://wtwonlineap.sharepoint.com/sites/tctnonclient_APACSCMDat/Data Library/Client Baseline/02. Raw Data/Eclipse/"),
  Navigation = #"Filtered rows"{[Name = "Eclipse Recurring Report.xlsm", #"Folder Path" = "https://wtwonlineap.sharepoint.com/sites/tctnonclient_APACSCMDat/Data Library/Client Baseline/02. Raw Data/Eclipse/"]}[Content],
  #"Imported Excel workbook" = Excel.Workbook(Navigation, null, true),
  #"Navigation 1" = #"Imported Excel workbook"{[Item = "RAW Data - 2018 -2019 Postings", Kind = "Sheet"]}[Data],
  #"Changed column type" = Table.TransformColumnTypes(#"Navigation 1", {{"Column1", type text}, {"Column2", type text}, {"Column3", type text}, {"Column4", type text}, {"Column5", type text}, {"Column6", type text}, {"Column7", type text}, {"Column10", type text}, {"Column11", type text}, {"Column12", type text}, {"Column13", type text}, {"Column14", type text}, {"Column16", type text}, {"Column17", type text}, {"Column18", type text}, {"Column19", type text}, {"Column20", type text}, {"Column21", type text}, {"Column22", type text}, {"Column23", type text}, {"Column28", type text}, {"Column29", type text}, {"Column30", type text}, {"Column31", type text}, {"Column34", type text}, {"Column35", type text}}),
  #"Removed top rows" = Table.Skip(#"Changed column type", 1),
  #"Promoted headers" = Table.PromoteHeaders(#"Removed top rows", [PromoteAllScalars = true]),
  #"Changed column type 1" = Table.TransformColumnTypes(#"Promoted headers", {{"InceptionDate", type datetime}, {"ExpiryDate", type datetime}, {"CreatedDate", type datetime}, {"NetBkgeUSDPlan", type number}, {"GrossBkgeUSDPlan", type number}, {"GrossPremNonTtyUSDPlan", type number}, {"NetClientPremNonTtyUSDPlan", type number}, {"Willis Party ID", type text}, {"Dun and Bradstreet No", type text}, {"Effective Date", type datetime}, {"InsuredID", type text}, {"Billing Amount", type number}})
in
  #"Changed column type 1"