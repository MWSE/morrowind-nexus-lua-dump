return mwse.loadConfig("SimpleAutoSave") or {
    autoSavePeriod = 1,  -- minutes
    saveOnCellChange = true,
    dontSaveOnExtTransitions = true,
    dontSaveInCombat = true,
}
