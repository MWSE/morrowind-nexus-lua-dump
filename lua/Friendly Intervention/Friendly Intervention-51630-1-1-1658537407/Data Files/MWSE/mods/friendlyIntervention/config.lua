local defaultConfig = {
    modEnabled = true,
    msgEnabled = true,
    trainMyst = true,
    magickaReq = true,
    smnFree = true,
    magickaMod = 25,
    skillLimit = true,
    playerSkill = true,
    npcSkill = true,
    useScroll = true,
    playSound = true,
    playEffect = true,
    playerSkillReq = 75,
    npcSkillReq = 50,
    mExpanded = false,
    logLevel = "NONE"
}




local mwseConfig = mwse.loadConfig("Friendly Intervention", defaultConfig)

return mwseConfig;