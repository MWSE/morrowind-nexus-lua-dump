return mwse.loadConfig("SimpleAutoSave") or {
    autoSavePeriod = 3,  -- minutes
    saveOnCellChange = true,
    dontSaveOnExtTransitions = true,
    dontSaveInCombat = true,
}
