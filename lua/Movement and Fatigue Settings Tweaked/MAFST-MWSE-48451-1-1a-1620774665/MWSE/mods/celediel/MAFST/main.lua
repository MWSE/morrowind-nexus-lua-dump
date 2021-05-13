local modName = "Movement and Fatigue Settings Tweaked"
local modAuthor = "nelxxz"
local codeAuthor = "Celediel"
local modConfig = "MAFST"
local modInfo = "This mod tweaks Fatigue (Stamina) settings to make running, walking, " ..
                    "swimming, jumping and attacking slightly less painful.\n\n" ..
                    "In sum, your character will still suffer fatigue loss, but only when carrying " ..
                    "a lot of weight, and especially in low endurance levels. This is compensated " ..
                    "by increased jumping costs and slightly more draining attacks, based on " ..
                    "weapon weight. General movement, however, will be faster and overall more " ..
                    "balanced, both for the player and NPCs, as well as for creatures. " ..
                    "Additionally, while jumping height hasn't changed, the distance traveled from " ..
                    "jumping has been reduced. All in all, there is still reason to both level up " ..
                    "Acrobatics and Athletics, and acquire magical enchanted items and spells to explore."

local defaultConfig = {
    gmst = {
        -- fAthleticsRunBonus = 1.285, -- from The Jogging Mod
        -- fBaseRunMultiplier = 1.465, -- uncomment to use
        fFatigueJumpBase = 15,
        fFatigueRunBase = 2,
        fFatigueRunMult = 1.5,
        fFatigueSwimRunBase = 4,
        fJumpMoveBase = 0.3,
        fJumpMoveMult = 0,
        fMaxWalkSpeed = 250,
        fMinWalkSpeed = 150,
        fMaxWalkSpeedCreature = 350,
        fMinWalkSpeedCreature = 7,
        fWeaponFatigueMult = 0.3
    }
}

local vanilla = {
    values = {
        fAthleticsRunBonus = 1,
        fBaseRunMultiplier = 1.75,
        fFatigueJumpBase = 5,
        fFatigueRunBase = 5,
        fFatigueRunMult = 2,
        fFatigueSwimRunBase = 7,
        fJumpMoveBase = 0.5,
        fJumpMoveMult = 0.5,
        fMaxWalkSpeed = 200,
        fMinWalkSpeed = 100,
        fMaxWalkSpeedCreature = 300,
        fMinWalkSpeedCreature = 5,
        fWeaponFatigueMult = 0.24
    },
    descriptions = {
        fAthleticsRunBonus = "How Athletics affects running speed",
        fBaseRunMultiplier = "How much faster running is than walking",
        fFatigueJumpBase = "Fatigue costs by jumping",
        fFatigueRunBase = "Fatigue costs by running",
        fFatigueRunMult = "Fatigue costs per encumbrance point by running",
        fFatigueSwimRunBase = "Fatigue costs by swimming",
        fJumpMoveBase = "Forward jumping distance",
        fJumpMoveMult = "Forward jumping distance multiplier",
        fMaxWalkSpeed = "Maximum walking speed",
        fMinWalkSpeed = "Minimum walking speed",
        fMaxWalkSpeedCreature = "Maximum walking speed for creatures",
        fMinWalkSpeedCreature = "Minimum walking speed for creatures",
        fWeaponFatigueMult = "Fatigue drain from attacking"
    }
}

local config = mwse.loadConfig(modConfig, defaultConfig)

-- sometimes the config values end up as strings, probably because of MCM text fields?
-- this ensures the value is of the right type
-- a bit extra, but could be future boilerplate so whatever
local function getValueOfRightTypeForGMST(value, gmst)
    local t = gmst:lower():sub(1, 1)
    if t == "f" or t == "i" then
        return tonumber(value)
    elseif t == "s" then
        return tostring(value)
    else
        return value
    end
end

local function applyChanges(showMessage)
    for gmst, value in pairs(config.gmst) do
        tes3.findGMST(tes3.gmst[gmst]).value = getValueOfRightTypeForGMST(value, gmst)
        mwse.log("[%s] %s set to %s", modName, gmst, tes3.findGMST(tes3.gmst[gmst]).value)
    end
    if showMessage then tes3.messageBox("Changes applied!") end
end

local function onInitialized() applyChanges(false) end

local function configMenu()
    local template = mwse.mcm.createTemplate(modName)
    template:saveOnClose(modConfig, config)

    local page = template:createSideBarPage({
        label = "Sidebar Page???",
        description = string.format("%s by %s, MWSE version by %s\n\n%s", modName, modAuthor, codeAuthor, modInfo)
    })

    local category = page:createCategory(modName)

    -- Create text fields for each GMST in the config
    for gmst, _ in pairs(config.gmst) do
        category:createTextField({
            label = gmst,
            description = string.format("Sets value of %s (%s) (Vanilla value: %s, default value: %s)", gmst,
                                        vanilla.descriptions[gmst], vanilla.values[gmst], defaultConfig.gmst[gmst]),
            restartRequired = true,
            restartRequiredMessage = "Restart the game or click the apply button to apply the changes.",
            numbersOnly = true,
            variable = mwse.mcm.createTableVariable({id = gmst, table = config.gmst})
        })
    end

    category:createButton({buttonText = "Apply", callback = applyChanges})

    return template
end

event.register("modConfigReady", function() mwse.mcm.register(configMenu()) end)
event.register("initialized", onInitialized)
