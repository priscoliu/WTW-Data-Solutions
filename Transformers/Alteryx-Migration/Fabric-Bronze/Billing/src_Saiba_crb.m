let
  Source = SharePoint.Files("https://wtwonlineap.sharepoint.com/sites/tctnonclient_APACSCMDat", [ApiVersion = 15]),
  #"Filtered rows" = Table.SelectRows(Source, each [Folder Path] = "https://wtwonlineap.sharepoint.com/sites/tctnonclient_APACSCMDat/Data Library/Client Baseline/02. Raw Data/Saiba/"),
  Navigation = #"Filtered rows"{[Name = "For Baseline - Saiba 2018 onwards (Entry Date).xlsx", #"Folder Path" = "https://wtwonlineap.sharepoint.com/sites/tctnonclient_APACSCMDat/Data Library/Client Baseline/02. Raw Data/Saiba/"]}[Content],
  #"Imported Excel workbook" = Excel.Workbook(Navigation, null, true),
  #"Navigation 1" = #"Imported Excel workbook"{[Item = "Sheet1", Kind = "Sheet"]}[Data],
  #"Promoted headers" = Table.PromoteHeaders(#"Navigation 1", [PromoteAllScalars = true]),
  #"Changed column type" = Table.TransformColumnTypes(#"Promoted headers", {{"S.NO.", type text}, {"CNo", type text}, {"InstNo", type text}, {"BrokerBranch", type text}, {"RMName", type text}, {"CSCName", type text}, {"Cust.Vertical", type text}, {"CustName", type text}, {"CustCode", type text}, {"GCID", type text}, {"Insurer", type text}, {"Insurer Branch", type text}, {"Policy Type", type text}, {"Department", type text}, {"Share", type number}, {"PolicyNo", type text}, {"EndorsementNo.", type text}, {"BizType", type text}, {"StartDate", type date}, {"ExpiryDate", type date}, {"Brok Prem.", type number}, {"Brok.%", type number}, {"Brokerage", type number}, {"TPPremium", type number}, {"TPBrok%", Int64.Type}, {"TPBrokAmt", type number}, {"TotalBrok.", type number}, {"Rew%", type number}, {"RewAmt.", type number}, {"TPRew%", Int64.Type}, {"TPRewAmount", Int64.Type}, {"TotalRewAmt", type number}, {"Total(Brok+Rew+TP)", type number}, {"EntryDate", type date}}),

  // Replace errors with null across all columns
  #"Replaced errors" = Table.ReplaceErrorValues(#"Changed column type", 
    List.Transform(Table.ColumnNames(#"Changed column type"), each {_, null})),

  // Replace nulls with 0 for numeric columns
  #"Replaced null numbers" = Table.ReplaceValue(#"Replaced errors", null, 0, Replacer.ReplaceValue, 
    {"Share", "Brok Prem.", "Brok.%", "Brokerage", "TPPremium", "TPBrok%", "TPBrokAmt", "TotalBrok.", "Rew%", "RewAmt.", "TPRew%", "TPRewAmount", "TotalRewAmt", "Total(Brok+Rew+TP)"}),

  // Replace nulls with "" for text columns
  #"Replaced null text" = Table.ReplaceValue(#"Replaced null numbers", null, "", Replacer.ReplaceValue, 
    {"S.NO.", "CNo", "InstNo", "BrokerBranch", "RMName", "CSCName", "Cust.Vertical", "CustName", "CustCode", "GCID", "Insurer", "Insurer Branch", "Policy Type", "Department", "PolicyNo", "EndorsementNo.", "BizType"})
in
  #"Replaced null text"