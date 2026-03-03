let
    // ═══════════════════════════════════════════════════════
    // DIM_STATE — Australian states & territories reference
    // ═══════════════════════════════════════════════════════
    // Static dimension for Revenue Splits and Stamp Duty analysis

    // === STEP 1: Define state reference data ===
    StateData = Table.FromRecords({
        [StateKey = 1,  StateCode = "NSW",  StateName = "New South Wales",                 Region = "Eastern"],
        [StateKey = 2,  StateCode = "VIC",  StateName = "Victoria",                        Region = "Eastern"],
        [StateKey = 3,  StateCode = "QLD",  StateName = "Queensland",                      Region = "Eastern"],
        [StateKey = 4,  StateCode = "WA",   StateName = "Western Australia",               Region = "Western"],
        [StateKey = 5,  StateCode = "SA",   StateName = "South Australia",                 Region = "Central"],
        [StateKey = 6,  StateCode = "NT",   StateName = "Northern Territory",              Region = "Northern"],
        [StateKey = 7,  StateCode = "TAS",  StateName = "Tasmania",                        Region = "Southern"],
        [StateKey = 8,  StateCode = "TAS2", StateName = "Tasmania (Secondary)",            Region = "Southern"],
        [StateKey = 9,  StateCode = "ACT",  StateName = "Australian Capital Territory",    Region = "Eastern"],
        [StateKey = 10, StateCode = "OVS",  StateName = "Overseas",                        Region = "International"]
    }),

    // === STEP 2: Set types ===
    #"Set types" = Table.TransformColumnTypes(StateData, {
        {"StateKey",   Int64.Type},
        {"StateCode",  type text},
        {"StateName",  type text},
        {"Region",     type text}
    })
in
    #"Set types"
