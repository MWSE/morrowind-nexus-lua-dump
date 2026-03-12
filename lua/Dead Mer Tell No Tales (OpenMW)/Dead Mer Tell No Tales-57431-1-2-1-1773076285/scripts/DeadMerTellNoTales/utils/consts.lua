-- cells in which items will not be disowned under any circumstances
CellBlacklist = {
    -- in case it will be needed

    -- by cell name (lowercase!)
    -- ["balmora, caius cosades' house"] = true,

    -- by coords (only for exteriors)
    -- ["0,0"] = true
}

-- actors whose items will not be disowned under any circumstances
ActorBlacklist = {
    -- by actor referenceId (lowercase!)
    -- ["almalexia_warrior"] = true,
}

-- if the quest stage was met, then these actors will be recorded as dead
NPCMovedInsteadOfDisabled = {
    -- everything must be in lowercase
    -- https://en.uesp.net/wiki/Project_Tamriel:Cyrodiil/Unwanted_Advances
    pc_m1_mg_cha3 = {
        stage = 80,
        actor = "pc_m1_ugenring"
    }
}

IgnoredCellsWhileQuestActive = {
    ["ald-ruhn, guild of mages"] = {
        {
            id = "TG_LootAldruhnMG",
            stage = 10,
        },
    },
}
