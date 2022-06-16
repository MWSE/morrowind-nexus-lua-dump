local config = mwse.loadConfig("L.A.M.P.", {
    levelUpMode = "normal",
    useGMST = false,
    levelUpMult1 = 2,
    levelUpMult2 = 2,
    levelUpMult3 = 2,
    levelUpMult4 = 2,
    levelUpMult5 = 3,
    levelUpMult6 = 3,
    levelUpMult7 = 3,
    levelUpMult8 = 4,
    levelUpMult9 = 4,
    levelUpMult10 = 5,
    levelUpTotal = 10,
    majorMult = 1,
    minorMult = 1,
    majorAttr = 1,
    minorAttr = 1,
    miscAttr = 1
})

local attributeLevels = {}
local skillUpsToDrop = {}
local defaultGMST

local function resetGMST()
    tes3.findGMST("iLevelUp01Mult").value = defaultGMST[1]
    tes3.findGMST("iLevelUp02Mult").value = defaultGMST[2]
    tes3.findGMST("iLevelUp03Mult").value = defaultGMST[3]
    tes3.findGMST("iLevelUp04Mult").value = defaultGMST[4]
    tes3.findGMST("iLevelUp05Mult").value = defaultGMST[5]
    tes3.findGMST("iLevelUp06Mult").value = defaultGMST[6]
    tes3.findGMST("iLevelUp07Mult").value = defaultGMST[7]
    tes3.findGMST("iLevelUp08Mult").value = defaultGMST[8]
    tes3.findGMST("iLevelUp09Mult").value = defaultGMST[9]
    tes3.findGMST("iLevelUp10Mult").value = defaultGMST[10]
    tes3.findGMST("iLevelupTotal").value = defaultGMST[11]
    tes3.findGMST("iLevelupMajorMult").value = defaultGMST[12]
    tes3.findGMST("iLevelupMinorMult").value = defaultGMST[13]
    tes3.findGMST("iLevelupMajorMultAttribute").value = defaultGMST[14]
    tes3.findGMST("iLevelupMinorMultAttribute").value = defaultGMST[15]
    tes3.findGMST("iLevelupMiscMultAttriubte").value = defaultGMST[16]

    config.levelUpMult1 = tes3.findGMST("iLevelUp01Mult").value
    config.levelUpMult2 = tes3.findGMST("iLevelUp02Mult").value
    config.levelUpMult3 = tes3.findGMST("iLevelUp03Mult").value
    config.levelUpMult4 = tes3.findGMST("iLevelUp04Mult").value
    config.levelUpMult5 = tes3.findGMST("iLevelUp05Mult").value
    config.levelUpMult6 = tes3.findGMST("iLevelUp06Mult").value
    config.levelUpMult7 = tes3.findGMST("iLevelUp07Mult").value
    config.levelUpMult8 = tes3.findGMST("iLevelUp08Mult").value
    config.levelUpMult9 = tes3.findGMST("iLevelUp09Mult").value
    config.levelUpMult10 = tes3.findGMST("iLevelUp10Mult").value
    config.levelUpTotal = tes3.findGMST("iLevelupTotal").value
    config.majorMult = tes3.findGMST("iLevelupMajorMult").value
    config.minorMult = tes3.findGMST("iLevelupMinorMult").value
    config.majorAttr = tes3.findGMST("iLevelupMajorMultAttribute").value
    config.minorAttr = tes3.findGMST("iLevelupMinorMultAttribute").value
    config.miscAttr = tes3.findGMST("iLevelupMiscMultAttriubte").value
end

local function setGMST()

    tes3.findGMST("iLevelUp01Mult").value = config.levelUpMult1
    tes3.findGMST("iLevelUp02Mult").value = config.levelUpMult2
    tes3.findGMST("iLevelUp03Mult").value = config.levelUpMult3
    tes3.findGMST("iLevelUp04Mult").value = config.levelUpMult4
    tes3.findGMST("iLevelUp05Mult").value = config.levelUpMult5
    tes3.findGMST("iLevelUp06Mult").value = config.levelUpMult6
    tes3.findGMST("iLevelUp07Mult").value = config.levelUpMult7
    tes3.findGMST("iLevelUp08Mult").value = config.levelUpMult8
    tes3.findGMST("iLevelUp09Mult").value = config.levelUpMult9
    tes3.findGMST("iLevelUp10Mult").value = config.levelUpMult10
    tes3.findGMST("iLevelupTotal").value = config.levelUpTotal
    tes3.findGMST("iLevelupMajorMult").value = config.majorMult
    tes3.findGMST("iLevelupMinorMult").value = config.minorMult
    tes3.findGMST("iLevelupMajorMultAttribute").value = config.majorAttr
    tes3.findGMST("iLevelupMinorMultAttribute").value = config.minorAttr
    tes3.findGMST("iLevelupMiscMultAttriubte").value = config.miscAttr

    if tes3.findGMST("iLevelUp01Mult").value > tes3.findGMST("iLevelUp02Mult").value then

        tes3.findGMST("iLevelUp02Mult").value = tes3.findGMST("iLevelUp01Mult").value
    end

    if tes3.findGMST("iLevelUp02Mult").value > tes3.findGMST("iLevelUp03Mult").value then

        tes3.findGMST("iLevelUp03Mult").value = tes3.findGMST("iLevelUp02Mult").value
    end

    if tes3.findGMST("iLevelUp03Mult").value > tes3.findGMST("iLevelUp04Mult").value then

        tes3.findGMST("iLevelUp04Mult").value = tes3.findGMST("iLevelUp03Mult").value
    end

    if tes3.findGMST("iLevelUp04Mult").value > tes3.findGMST("iLevelUp05Mult").value then

        tes3.findGMST("iLevelUp05Mult").value = tes3.findGMST("iLevelUp04Mult").value
    end

    if tes3.findGMST("iLevelUp05Mult").value > tes3.findGMST("iLevelUp06Mult").value then

        tes3.findGMST("iLevelUp06Mult").value = tes3.findGMST("iLevelUp05Mult").value
    end

    if tes3.findGMST("iLevelUp06Mult").value > tes3.findGMST("iLevelUp07Mult").value then

        tes3.findGMST("iLevelUp07Mult").value = tes3.findGMST("iLevelUp06Mult").value
    end

    if tes3.findGMST("iLevelUp07Mult").value > tes3.findGMST("iLevelUp08Mult").value then

        tes3.findGMST("iLevelUp08Mult").value = tes3.findGMST("iLevelUp07Mult").value
    end

    if tes3.findGMST("iLevelUp08Mult").value > tes3.findGMST("iLevelUp09Mult").value then

        tes3.findGMST("iLevelUp09Mult").value = tes3.findGMST("iLevelUp08Mult").value
    end

    if tes3.findGMST("iLevelUp09Mult").value > tes3.findGMST("iLevelUp10Mult").value then

        tes3.findGMST("iLevelUp10Mult").value = tes3.findGMST("iLevelUp09Mult").value
    end

    config.levelUpMult1 = tes3.findGMST("iLevelUp01Mult").value
    config.levelUpMult2 = tes3.findGMST("iLevelUp02Mult").value
    config.levelUpMult3 = tes3.findGMST("iLevelUp03Mult").value
    config.levelUpMult4 = tes3.findGMST("iLevelUp04Mult").value
    config.levelUpMult5 = tes3.findGMST("iLevelUp05Mult").value
    config.levelUpMult6 = tes3.findGMST("iLevelUp06Mult").value
    config.levelUpMult7 = tes3.findGMST("iLevelUp07Mult").value
    config.levelUpMult8 = tes3.findGMST("iLevelUp08Mult").value
    config.levelUpMult9 = tes3.findGMST("iLevelUp09Mult").value
    config.levelUpMult10 = tes3.findGMST("iLevelUp10Mult").value
    config.levelUpTotal = tes3.findGMST("iLevelupTotal").value
    config.majorMult = tes3.findGMST("iLevelupMajorMult").value
    config.minorMult = tes3.findGMST("iLevelupMinorMult").value
    config.majorAttr = tes3.findGMST("iLevelupMajorMultAttribute").value
    config.minorAttr = tes3.findGMST("iLevelupMinorMultAttribute").value
    config.miscAttr = tes3.findGMST("iLevelupMiscMultAttriubte").value
end

local function onLevelUp()

    if config.levelUpMode == "off" then

        for i = 1, 8, 1 do

            if tes3.player.data.krimsonLAMP[i] ~= 0 then

                tes3.player.data.krimsonLAMP[i] = 0
            end
        end
        return
    end

    for i = 1, 8, 1 do

        if attributeLevels[i] < tes3.mobilePlayer.attributes[i].base then

            if tes3.player.data.krimsonLAMP[i] > 0 then

                tes3.player.data.krimsonLAMP[i] = tes3.player.data.krimsonLAMP[i] - skillUpsToDrop[i]
            end
        end

        if tes3.player.data.krimsonLAMP[i] < 0 then

            tes3.player.data.krimsonLAMP[i] = 0
        end

        tes3.mobilePlayer.levelupsPerAttribute[i] = tes3.player.data.krimsonLAMP[i]
    end
end

local function onPreLevel()

    if config.levelUpMode == "off" then

        return
    end

    local gmstValue
    local gmstValueTable = {
        tes3.findGMST("iLevelUp01Mult").value,
        tes3.findGMST("iLevelUp02Mult").value,
        tes3.findGMST("iLevelUp03Mult").value,
        tes3.findGMST("iLevelUp04Mult").value,
        tes3.findGMST("iLevelUp05Mult").value,
        tes3.findGMST("iLevelUp06Mult").value,
        tes3.findGMST("iLevelUp07Mult").value,
        tes3.findGMST("iLevelUp08Mult").value,
        tes3.findGMST("iLevelUp09Mult").value,
        tes3.findGMST("iLevelUp10Mult").value
    }

    for i = 1, 8, 1 do

        attributeLevels[i] = tes3.mobilePlayer.attributes[i].base

        if config.levelUpMode == "normal" then

            if tes3.mobilePlayer.levelupsPerAttribute[i] < 10 then

                skillUpsToDrop[i] = tes3.mobilePlayer.levelupsPerAttribute[i]
            else
                skillUpsToDrop[i] = 10
            end

        elseif config.levelUpMode == "least" then

            if tes3.mobilePlayer.levelupsPerAttribute[i] == 0 then

                skillUpsToDrop[i] = 0

            elseif tes3.mobilePlayer.levelupsPerAttribute[i] <= 10 then

                for index, value in pairs(gmstValueTable) do

                    if tes3.mobilePlayer.levelupsPerAttribute[i] == index then

                        gmstValue = value
                        break
                    end
                end

                for index, value in pairs(gmstValueTable) do

                    if gmstValue == value then

                        skillUpsToDrop[i] = index
                        break
                    end
                end
            else
                skillUpsToDrop[i] = 10
            end
        end
    end
end

local function onSkillRaised(e)

    local skill = tes3.getSkill(e.skill)
    local raisedSkill = tes3.mobilePlayer:getSkillStatistic(e.skill)
    local raiseNum

    if raisedSkill.type == tes3.skillType.major then

        raiseNum = tes3.findGMST("iLevelupMajorMultAttribute").value

    elseif raisedSkill.type == tes3.skillType.minor then

        raiseNum = tes3.findGMST("iLevelupMinorMultAttribute").value

    elseif raisedSkill.type == tes3.skillType.misc then

        raiseNum = tes3.findGMST("iLevelupMiscMultAttriubte").value
    end

    if skill.attribute == tes3.attribute.strength then

        tes3.player.data.krimsonLAMP[1] = tes3.player.data.krimsonLAMP[1] + raiseNum

    elseif skill.attribute == tes3.attribute.intelligence then

        tes3.player.data.krimsonLAMP[2] = tes3.player.data.krimsonLAMP[2] + raiseNum

    elseif skill.attribute == tes3.attribute.willpower then

        tes3.player.data.krimsonLAMP[3] = tes3.player.data.krimsonLAMP[3] + raiseNum

    elseif skill.attribute == tes3.attribute.agility then

        tes3.player.data.krimsonLAMP[4] = tes3.player.data.krimsonLAMP[4] + raiseNum

    elseif skill.attribute == tes3.attribute.speed then

        tes3.player.data.krimsonLAMP[5] = tes3.player.data.krimsonLAMP[5] + raiseNum

    elseif skill.attribute == tes3.attribute.endurance then

        tes3.player.data.krimsonLAMP[6] = tes3.player.data.krimsonLAMP[6] + raiseNum

    elseif skill.attribute == tes3.attribute.personality then

        tes3.player.data.krimsonLAMP[7] = tes3.player.data.krimsonLAMP[7] + raiseNum

    elseif skill.attribute == tes3.attribute.luck then

        tes3.player.data.krimsonLAMP[8] = tes3.player.data.krimsonLAMP[8] + raiseNum
    end
end

local function onLoaded(e)

    if not e.newGame then

        if tes3.player.data.krimsonLAMP == nil then

            tes3.player.data.krimsonLAMP = {0, 0, 0, 0, 0, 0, 0, 0}
        end
    else
        tes3.player.data.krimsonLAMP = {0, 0, 0, 0, 0, 0, 0, 0}
    end

    for i = 1, 8, 1 do

        if tes3.player.data.krimsonLAMP[i] < tes3.mobilePlayer.levelupsPerAttribute[i] then

            tes3.player.data.krimsonLAMP[i] = tes3.mobilePlayer.levelupsPerAttribute[i]

        elseif tes3.player.data.krimsonLAMP[i] > tes3.mobilePlayer.levelupsPerAttribute[i] then

            tes3.mobilePlayer.levelupsPerAttribute[i] = tes3.player.data.krimsonLAMP[i]
        end
    end

    if config.useGMST then
        setGMST()
    else
        resetGMST()
    end
end

local function registerConfig()

    local template = mwse.mcm.createTemplate("L.A.M.P.")
    template.onClose = function()
        mwse.saveConfig("L.A.M.P.", config)

        if config.useGMST then
            setGMST()
        else
            resetGMST()
        end
    end
    template:register()

    local page = template:createSideBarPage({
        label = "Mode Settings",
        description = "Normal:\n\nUses the normal amount of skill ups for attribute modifiers, any left over will be saved for later.\n\nX2 uses up to 4, X3 uses up to 7, X4 uses up to 9, and X5 uses 10.\nWill use the amount you have up to the numbers listed.\n\n\n\n"..
        "Least:\n\nUses the least amount of skill ups for attribute modifiers, any left over will be saved for later.\n\nX2 uses 1, X3 uses 5, X4 uses 8, and X5 uses 10.\n\n\n\n"..
        "Off:\n\nTurns the mod off, like vanilla all attribute modifiers will reset to 0 on leveling up.\n\nWhile off any skill ups will still be saved between leveling."
    })

    local settings = page:createCategory("Leftover Attribute Modifiers Persist\n\n\n")

    settings:createDropdown({
		label = "Mode Options",
		description = "Changes the amount of skill ups to use for attribute modifiers on leveling up, then saves any left over for the next level up.\n\nDefault: Normal\n\n"..
            "If the level up menu is open any changes will NOT take effect until after it is closed.",
		options = {
			{label = "Normal amount", value = "normal", description = "Uses the normal amount of skill ups for attribute modifiers, any left over will be saved for later.\n\nX2 uses 4, X3 uses 7, X4 uses 9, and X5 uses 10."},
            {label = "Least amount", value = "least", description = "Uses the least amount of skill ups for attribute modifiers, any left over will be saved for later.\n\nX2 uses 1, X3 uses 5, X4 uses 8, and X5 uses 10."},
			{label = "Off", value = "off", description = "Turns the mod off, like vanilla all attribute modifiers will reset to 0 on leveling up.\n\nWhile off any skill ups will still be saved between leveling."},
		},
		variable = mwse.mcm:createTableVariable{id = "levelUpMode", table = config},
	})

    settings:createYesNoButton({
        label = "Use custom values for GMSTs? Set values on the following page.",
        variable = mwse.mcm.createTableVariable {id = "useGMST", table = config}
    })

    local page2 = template:createSideBarPage({
        label = "GMST Settings",
        description = "Changes the Attribute multipliers that are recieved for the number of skill level increases.\n\nAll values will override the ones below it until it hits a value that is equal or higher.\n\nChanges will take effect after this menu is closed."
    })

    local settings2 = page2:createCategory("Leftover Attribute Modifiers Persist\n\n\n")

    settings2:createSlider{
        label = "iLevelUp01Mult",
        min = 0,
        max = 25,
        step = 1,
        jump = 5,
        variable = mwse.mcm:createTableVariable{id = "levelUpMult1", table = config},
    }

    settings2:createSlider{
        label = "iLevelUp02Mult",
        min = 0,
        max = 25,
        step = 1,
        jump = 5,
        variable = mwse.mcm:createTableVariable{id = "levelUpMult2", table = config},
    }

    settings2:createSlider{
        label = "iLevelUp03Mult",
        min = 0,
        max = 25,
        step = 1,
        jump = 5,
        variable = mwse.mcm:createTableVariable{id = "levelUpMult3", table = config},
    }

    settings2:createSlider{
        label = "iLevelUp04Mult",
        min = 0,
        max = 25,
        step = 1,
        jump = 5,
        variable = mwse.mcm:createTableVariable{id = "levelUpMult4", table = config},
    }

    settings2:createSlider{
        label = "iLevelUp05Mult",
        min = 0,
        max = 25,
        step = 1,
        jump = 5,
        variable = mwse.mcm:createTableVariable{id = "levelUpMult5", table = config},
    }

    settings2:createSlider{
        label = "iLevelUp06Mult",
        min = 0,
        max = 25,
        step = 1,
        jump = 5,
        variable = mwse.mcm:createTableVariable{id = "levelUpMult6", table = config},
    }

    settings2:createSlider{
        label = "iLevelUp07Mult",
        min = 0,
        max = 25,
        step = 1,
        jump = 5,
        variable = mwse.mcm:createTableVariable{id = "levelUpMult7", table = config},
    }

    settings2:createSlider{
        label = "iLevelUp08Mult",
        min = 0,
        max = 25,
        step = 1,
        jump = 5,
        variable = mwse.mcm:createTableVariable{id = "levelUpMult8", table = config},
    }

    settings2:createSlider{
        label = "iLevelUp09Mult",
        min = 0,
        max = 25,
        step = 1,
        jump = 5,
        variable = mwse.mcm:createTableVariable{id = "levelUpMult9", table = config},
    }

    settings2:createSlider{
        label = "iLevelUp10Mult",
        min = 0,
        max = 25,
        step = 1,
        jump = 5,
        variable = mwse.mcm:createTableVariable{id = "levelUpMult10", table = config},
    }

    settings2:createSlider{
        label = "# of skill points needed to level up",
        min = 0,
        max = 25,
        step = 1,
        jump = 5,
        variable = mwse.mcm:createTableVariable{id = "levelUpTotal", table = config},
    }

    settings2:createSlider{
        label = "# of skill points given by Major skills",
        min = 0,
        max = 25,
        step = 1,
        jump = 5,
        variable = mwse.mcm:createTableVariable{id = "majorMult", table = config},
    }

    settings2:createSlider{
        label = "# of skill points given by Minor skills",
        min = 0,
        max = 25,
        step = 1,
        jump = 5,
        variable = mwse.mcm:createTableVariable{id = "minorMult", table = config},
    }

    settings2:createSlider{
        label = "# of attribute multipliers given by Major skills",
        min = 0,
        max = 25,
        step = 1,
        jump = 5,
        variable = mwse.mcm:createTableVariable{id = "majorAttr", table = config},
    }

    settings2:createSlider{
        label = "# of attribute multipliers given by Minor skills",
        min = 0,
        max = 25,
        step = 1,
        jump = 5,
        variable = mwse.mcm:createTableVariable{id = "minorAttr", table = config},
    }

    settings2:createSlider{
        label = "# of attribute multipliers given by Misc skills",
        min = 0,
        max = 25,
        step = 1,
        jump = 5,
        variable = mwse.mcm:createTableVariable{id = "miscAttr", table = config},
    }

    settings2:createButton{
        label = "Resets GMSTs to vanilla default values or defaults from another mod that changes them. Numbers above will not change until you switch pages.",
        buttonText = "Reset GMSTs",
        callback = (
            function()
                resetGMST()
            end
        )
    }
end

event.register("modConfigReady", registerConfig)

local function onInitialized()

    defaultGMST = {
        tes3.findGMST("iLevelUp01Mult").value,
        tes3.findGMST("iLevelUp02Mult").value,
        tes3.findGMST("iLevelUp03Mult").value,
        tes3.findGMST("iLevelUp04Mult").value,
        tes3.findGMST("iLevelUp05Mult").value,
        tes3.findGMST("iLevelUp06Mult").value,
        tes3.findGMST("iLevelUp07Mult").value,
        tes3.findGMST("iLevelUp08Mult").value,
        tes3.findGMST("iLevelUp09Mult").value,
        tes3.findGMST("iLevelUp10Mult").value,
        tes3.findGMST("iLevelupTotal").value,
        tes3.findGMST("iLevelupMajorMult").value,
        tes3.findGMST("iLevelupMinorMult").value,
        tes3.findGMST("iLevelupMajorMultAttribute").value,
        tes3.findGMST("iLevelupMinorMultAttribute").value,
        tes3.findGMST("iLevelupMiscMultAttriubte").value
    }
    event.register("skillRaised", onSkillRaised)
    event.register("preLevelUp", onPreLevel)
    event.register("levelUp", onLevelUp)
    event.register("loaded", onLoaded)
    mwse.log("Krimson L.A.M.P. initialized")
end

event.register("initialized", onInitialized)