local config = mwse.loadConfig("L.A.M.P.", {
    levelUpMode = "normal",
})

local attributeLevels = {}
local skillUpsToDrop = {}

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

    for i = 1, 8, 1 do

        attributeLevels[i] = tes3.mobilePlayer.attributes[i].base

        if config.levelUpMode == "normal" then

            if tes3.mobilePlayer.levelupsPerAttribute[i] < 10 then

                skillUpsToDrop[i] = tes3.mobilePlayer.levelupsPerAttribute[i]
            else
                skillUpsToDrop[i] = 10
            end

        elseif config.levelUpMode == "least" then

            if tes3.mobilePlayer.levelupsPerAttribute[i] >= 10 then

                skillUpsToDrop[i] = 10

            elseif tes3.mobilePlayer.levelupsPerAttribute[i] >= 8 then

                skillUpsToDrop[i] = 8

            elseif tes3.mobilePlayer.levelupsPerAttribute[i] >= 5 then

                skillUpsToDrop[i] = 5

            elseif tes3.mobilePlayer.levelupsPerAttribute[i] >= 1 then

                skillUpsToDrop[i] = 1
            end
        end
    end
end

local function onSkillRaised(e)

    if e.skill.attribute == tes3.attribute.strength then

        tes3.player.data.krimsonLAMP[1] = tes3.player.data.krimsonLAMP[1] + 1

    elseif e.skill.attribute == tes3.attribute.intelligence then

        tes3.player.data.krimsonLAMP[2] = tes3.player.data.krimsonLAMP[2] + 1

    elseif e.skill.attribute == tes3.attribute.willpower then

        tes3.player.data.krimsonLAMP[3] = tes3.player.data.krimsonLAMP[3] + 1

    elseif e.skill.attribute == tes3.attribute.agility then

        tes3.player.data.krimsonLAMP[4] = tes3.player.data.krimsonLAMP[4] + 1

    elseif e.skill.attribute == tes3.attribute.speed then

        tes3.player.data.krimsonLAMP[5] = tes3.player.data.krimsonLAMP[5] + 1

    elseif e.skill.attribute == tes3.attribute.endurance then

        tes3.player.data.krimsonLAMP[6] = tes3.player.data.krimsonLAMP[6] + 1

    elseif e.skill.attribute == tes3.attribute.personality then

        tes3.player.data.krimsonLAMP[7] = tes3.player.data.krimsonLAMP[7] + 1

    elseif e.skill.attribute == tes3.attribute.luck then

        tes3.player.data.krimsonLAMP[8] = tes3.player.data.krimsonLAMP[8] + 1
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
end

local function registerConfig()

    local template = mwse.mcm.createTemplate("L.A.M.P.")
        template:saveOnClose("L.A.M.P.", config)
        template:register()

    local page = template:createSideBarPage({
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
end

event.register("modConfigReady", registerConfig)

local function onInitialized()

    event.register("skillRaised", onSkillRaised)
    event.register("preLevelUp", onPreLevel)
    event.register("levelUp", onLevelUp)
    event.register("loaded", onLoaded)
    mwse.log("Krimson L.A.M.P. initialized")
end

event.register("initialized", onInitialized)