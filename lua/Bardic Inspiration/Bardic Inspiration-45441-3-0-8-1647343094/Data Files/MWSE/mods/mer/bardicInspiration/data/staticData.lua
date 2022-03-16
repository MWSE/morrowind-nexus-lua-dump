return {
    modName = "Bardic Inspiration",
    configPath = "BardicInspiration",
    --Merchant Data
    merchantContainerId = "mer_BI_merch_cntr",
    containerContents = {
        { item = "mer_lute", count = 1},
    },

    --Lute id mapping
    lutes = {
        ["mer_lute"] = true,
        ["mer_lute_fat"] = true,
    },
    idMapping = {
        ["misc_de_lute_01"] = "mer_lute",
        ["misc_de_lute_01_phat"] = "mer_lute_fat"
    },
    initPlayerData = {
        taverns = {},
        knownSongs = {}
    },
    publicanClasses = {
        publican = true,
        t_sky_publican = true,
        t_cyr_publican = true
    },
    bardClasses = {
        bard = true,
        t_sky_bard = true,
        t_cyr_bard = true
    },
    bardTeachIntervalHours = 48,
    bardTeachSongPlayedMin = 1,
    difficulties = {
        beginner = {
            minSkill = -1,
            expMulti = 0.8,
            songsPerBard = 5,
            tipMulti = 1.0
        },
        intermediate = {
            minSkill = 50,
            expMulti = 0.9,
            songsPerBard = 5,
            tipMulti = 3.0
        },
        advanced = {
            minSkill = 70,
            expMulti = 1.0,
            songsPerBard = 1,
            tipMulti = 5.0
        }
    },
    --experience multipliers
    skillLevelMultis = {
        min = 3.0,
        max = 1.0
    },
    performExperiencePerSecond = 1.0,
    travelPlayExperiencePerSecond = 0.2,
    --Tavern reward configs
    baseRewardAmount = 10,
    maxDispRewardEffect = 2.0,
    maxSkillRewardEffect = 10.0,
    --Tip configs
    minTip = 2,
    baseTip = 5,
    maxSkillTipEffect = 4.0,
    --Tip interval configs
    maxTipInterval = 30,
    baseTipInterval = 20, --seconds
    maxLuckTipIntervalEffect = 0.10,--multiplier
    maxSkillTipIntervalEffect = 0.5,--multiplier
    --Disposition increase configs
    dispIncreasePerRewardAmount = 0.1,
    maxDispositionIncrease = 20,
    --Dialog entries
    dialogueEntries = {
        --"give a performance"
        hasPlayed = {
            dialogue = "give a performance",
            id = "7279130782524329959",
            classFilter = "publican"
        },
        doAccept = {
            dialogue = "give a performance",
            id = "1603219220275755837",
            classFilter = "publican"
        },
        hasAccepted = {
            dialogue = "give a performance",
            id = "115733748750646221139",
            classFilter = "publican"
        },
        describeGig = {
            dialogue = "give a performance",
            id = "2347617621151716375",
            classFilter = "publican"
        },
        askToPerform = {
            dialogue = "give a performance",
            id = "2348628403660916185",
            classFilter = "publican"
        },
        tooLate = {
            dialogue = "give a performance",
            id = "1921131585645619076",
            classFilter = "publican"
        },
        noLute = {
            dialogue = "give a performance",
            id = "11347136332025822472",
            classFilter = "publican"
        },
        noSongs = {
            dialogue = "give a performance",
            id = "2342613600664222302",
            classFilter = "publican"
        },


        --"teach me a song"
        teachCancel = {
            dialogue = "teach me a song",
            id = "1909021375137333678",
            classFilter = "bard"
        },
        teachConfirm = {
            dialogue = "teach me a song",
            id = "1073418513242012439",
            classFilter = "bard"
        },
        teachChoice = {
            dialogue = "teach me a song",
            id = "143714305235015036",
            classFilter = "bard"
        },
        noTeachMustWait = {
            dialogue = "teach me a song",
            id = "1103015831284715100",
            classFilter = "bard"
        },
        noTeachLowSkill = {
            dialogue = "teach me a song",
            id = "27040121121630217252",
            classFilter = "bard"
        },
        noTeachNoSongs = {
            dialogue = "teach me a song",
            id = "1541615497468425745",
            classFilter = "bard"
        },
        noTeachAvgDisp = {
            dialogue = "teach me a song",
            id = "258111209199954193",
            classFilter = "bard"
        },
        noTeachBadDisp = {
            dialogue = "teach me a song",
            id = "635676781298714316",
            classFilter = "bard"
        },
    }
}