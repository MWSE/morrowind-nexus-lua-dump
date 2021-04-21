local defaultConfig = {
    version = "The Law is Sacred, v1.1.3",
    resistArrestDialogueID = "17814103293101015617",
    deathWarrantDialogueID = "58028831233554797",
    resistArrestPenalty = 300,
    guardKillPenalty = 1000,
    messages = true,
    animateKO = true,
    confirm = true,
    deathWarrant = false,
    deathWarrantValue = 5000,
    goToJailModTitle = "Go To Jail 3.7.esp",
    goToJailModTitleNOM = "Go To Jail 3.7 - NOM.esp",
    goToJailModThreshold = 1000,
    goToJailModTopic = "Let me out",
}

local config = mwse.loadConfig ("TheLawIsSacred", defaultConfig)
return config