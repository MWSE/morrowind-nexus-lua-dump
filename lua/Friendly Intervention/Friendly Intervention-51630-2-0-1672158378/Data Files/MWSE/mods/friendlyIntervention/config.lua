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
    useEnchant = true,
    playSound = true,
    playEffect = true,
    playerSkillReq = 75,
    npcSkillReqS = 50,
    npcSkillReqO = 75,
    mExpanded = false,
    teleportMenu = true,
    npcMark = true,
    noColor = false,
    logLevel = "NONE"
}




local mwseConfig = mwse.loadConfig("Friendly Intervention", defaultConfig)

return mwseConfig;
