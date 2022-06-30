local function refresh()
        local MCMModList = tes3ui.findMenu("MWSE:ModConfigMenu").children

        for child in table.traverse(MCMModList) do
            if child.text == "Security Adjuster" then
                child:triggerEvent("mouseClick")
            end
        end
end

local data = require("kindi.security.data")

local config = require("kindi.security.config")

local EasyMCM = require("easyMCM.EasyMCM")

local template = EasyMCM.createTemplate {}
template.name = "Security Adjuster"
template:saveOnClose("security_success", config)

local page =
    template:createSideBarPage {
    label = "Main",
    font = 2,
    description = "This side page will show your statistics and history. In-game only.",
    noScroll = false
}

local modActive = page:createCategory("Mod Status")

modActive:createOnOffButton{
    label = "Mod status",
    description = "Turns the mod on or off",
    variable = EasyMCM.createTableVariable {id = "isModActive", table = config},
    callback = function()
        if config.isModActive then
            tes3.messageBox("Mod is ON")
        else
            tes3.messageBox("Mod is OFF")
        end
    end
}

local general = page:createCategory("General")

general:createYesNoButton {
    label = "Show chance to unlock?",
    description = "When active, the chance to unlock the object will be shown in the tooltip\nMust equip a pick to trigger",
    variable = EasyMCM.createTableVariable {id = "showUnlockChance", table = config},
    callback = function()

    end
}
general:createYesNoButton {
    label = "Show chance to disarm?",
    description = "When active, the chance to disarm the object will be shown in the tooltip\nMust equip a probe to trigger",
    variable = EasyMCM.createTableVariable {id = "showDisarmChance", table = config},
    callback = function()

    end
}
general:createYesNoButton {
    label = "Show the key of the lock?",
    description = "When active, reveals the key name of the lock (if any)\nMust equip a pick to trigger",
    variable = EasyMCM.createTableVariable {id = "showKeyName", table = config},
    callback = function()
    
    end
}
general:createYesNoButton {
    label = "Show the name of the trap and spell points?",
    description = "When active, reveals the trap name (and the spell points)\nMust equip a probe to trigger",
    variable = EasyMCM.createTableVariable {id = "showTrapName", table = config},
    callback = function()
    
    end
}
general:createYesNoButton {
    label = "Only display the information when a security tool is equipped?",
    description = "Must equip either a lockpick or probe to see the appropriate information",
    variable = EasyMCM.createTableVariable {id = "toolsIsNeededToSee", table = config},
    callback = function()
    
    end
}
general:createDropdown {
    label = "How will lock level be displayed in the tooltip?",
    description = "Difficulty range:\n\nLevel 1 - 20 = 'Novice'\nLevel 21 - 40 = 'Apprentice'\nLevel 41 - 60 = 'Adept'\nLevel 61 - 80 = 'Expert'\nLevel 81 above = 'Master'\n",
    variable = EasyMCM.createTableVariable {id = "lockLevelDisplay", table = config},
	callback = function () end,
    options = {
        {label = "Normal", value = "Normal"},
        {label = "Difficulty", value = "Difficulty"},
        {label = "Hidden", value = "Hidden"}
    }
}
general:createDropdown {
    label = "How will trap status be displayed in the tooltip?",
    description = "Severity:\nSafe = Absolutely no danger\nHarmless = Only a nuisance\nUnsafe = Damaging to stats\nPainful = Considerable health damage\nDangerous = Can be fatal\nDeadly = Absolutely fatal",
    variable = EasyMCM.createTableVariable {id = "trapDisplay", table = config},
	callback = function () end,
    options = {
        {label = "Hidden", value = "Hidden"},
        {label = "Normal", value = "Normal"},
        {label = "Severity", value = "Severity"},
    }
}
general:createDropdown {
    label = "How will trap effects be displayed in the tooltip?",
    description = "The list of magic effects of the trap\n\nUsing verbose with icon can lead to error if the icon file for the magic effect is missing",
    variable = EasyMCM.createTableVariable {id = "trapEffectsDisplay", table = config},
	callback = function () end,
    options = {
        {label = "Hidden", value = "Hidden"},
        {label = "Simple", value = "Simple"},
        {label = "Verbose", value = "Verbose"},
        {label = "Verbose With Icon", value = "VerboseIcon"},
    }
}
general:createDropdown {
    label = "Show enchantment-like visual effect on trapped objects?",
    description = "Displays a glowing visual effect that corresponds to the trap on the trapped object.",
    variable = EasyMCM.createTableVariable {id = "showTrapEnchantmentEffect", table = config},
    callback = function()
        if tes3.getPlayerCell() then
            event.trigger("SA_KINDI_REFRESH_TRAPPED_VFX", {cell = tes3.getPlayerCell()})
        end
    end,
    options = {
        {label = "Never", value = "No VFX"},
        {label = "Always", value = "Always"},
        {label = "When Targeted Only", value = "Target"},
    }    
}
general:createDropdown {
    label = "How frequent will the tooltip update?",
    description = "May save some FPS depending on the circumstances\n\nInstant: Every Frame\nReaction Time: 0.25 seconds\nOn Target Changed Only: Activation target for the player changes",
    variable = EasyMCM.createTableVariable {id = "tooltipRefreshFrequency", table = config},
	callback = function () end,
    options = {
        {label = "Instant", value = 0},
        {label = "Reaction Time", value = 0.25},
        {label = "Half-Second", value = 0.5},
        {label = "Per-Second", value = 1},
        {label = "On Target Changed Only", value = false},
    }
}
general:createButton {
    label = "Reset fPickLockMult and fTrapCostMult to default values?",
    buttonText = "Reset GMST",
    description = "Resets the GMST to default values",
    callback = function()
        tes3.messageBox("Reset Done")
        tes3.findGMST(1081).value = -1
        tes3.findGMST(1082).value = 0
        config.fpicklockmult = tes3.findGMST(1081).value
        config.ftrapcostmult = tes3.findGMST(1082).value
        refresh()
    end
}
local lockpicking = page:createCategory("LockPicking")
lockpicking:createTextField {
    label = "fPickLockMult",
    variable = EasyMCM.createTableVariable {id = "fpicklockmult", table = config},
    description = "Changes fPickLockMult GMST\nA large negative value will make lockpicking harder.\nDefault value: -1.0\n",
    numbersOnly = false,
    callback = function()
        tes3.messageBox(config.fpicklockmult)
        if config.showInfo == true then
            tes3.findGMST(1081).value = tonumber(config.fpicklockmult)
        end
    end
}

local probing = page:createCategory("Probing")
probing:createTextField {
    label = "fTrapCostMult",
    variable = EasyMCM.createTableVariable {id = "ftrapcostmult", table = config},
    description = "Changes fTrapCostMult GMST\nIn the base game, the chance to disarm traps are the same regardless of the type of trap. Adjust this to a negative value to add more difficulty disarming traps.\nDefault value: 0.0\nRecomended value: -1.5",
    numbersOnly = false,
    callback = function()
        if config.showInfo == true then
            tes3.findGMST(1082).value = tonumber(config.ftrapcostmult)
        end
    end
}

local check = page:createCategory("Check GMSTs")
check:createButton {
    label = "Current fFatigueBase",
    buttonText = "Check",
    description = "Shows current fFatigueBase value\nDefault value: 1.25",
    callback = function()
        tes3.messageBox("fFatigueBase : " .. tes3.findGMST(1006).value)
    end
}
check:createButton {
    label = "Current fFatigueMult",
    buttonText = "Check",
    description = "Shows current fFatigueMult value\nDefault value: 0.5",
    callback = function()
        tes3.messageBox("fFatigueMult : " .. tes3.findGMST(1007).value)
    end
}
check:createButton {
    label = "Current fPickLockMult",
    buttonText = "Check",
    description = "Shows current fPickLockMult value\nDefault value: -1.0",
    callback = function()
        tes3.messageBox("fPickLockMult : " .. tes3.findGMST(1081).value)
    end
}
check:createButton {
    label = "Current fTrapCostMult",
    buttonText = "Check",
    description = "Shows current fTrapCostMult value\nDefault value: 0",
    callback = function()
        tes3.messageBox("fTrapCostMult : " .. tes3.findGMST(1082).value)
    end
}

local advanced =
    template:createPage {
    label = "Advanced"
}

advanced:createCategory {
    label = "Coming Soon..."
}

local about =
    template:createPage {
    label = "About"
}

about:createHyperlink {text = "Security Adjuster - Locks and Traps", exec = string.format("start %s", "https://www.nexusmods.com/morrowind/mods/47914")}

about:createCategory {
    label = string.format(
        "INTRO\nReveals the pick or disarm chance of the door if it is locked or trapped\n\nReveals the trap name and key name if the door is trapped and has a key\n\nChoose how the lock level is shown, either by points or difficulty\n\nThe player must be equpping a lockpick or probe for the information to be shown\n\nFORMULA\nfatigueTerm = fFatigueBase - fFatigueMult * ( 1 - currentFatigue/maxFatigue )\n\nLockpicking: \nx = ( 0.2 * playerAgility ) + ( 0.1 * playerLuck ) + playerSecurity\nx = x * pickQuality * fatigueTerm\nx = x + fPickLockMult * lockLevel\n\nProbing Trap: \nx = ( 0.2 * playerAgility) + ( 0.1 * playerLuck ) + playerSecurity\nx = x + fTrapCostMult * trapSpellPoints\nx = x * probeQuality * fatigueTerm\n\nEnsure you are aware about these options in MCP:\nHide locks\nHide traps\n\nIt is recommended to turn it OFF. This mod provides a similar option, use it instead.\n\nIf you have Quick Loot, please check your Quick Loot configuration.\n'Hide Lock Status' will hide lock status, including from this mod. Recommended to turn it OFF.\n'Hide Trapped Container Items' is suggested to turn ON for best experience."
    )
}

EasyMCM.register(template)

function SS_KINDI_UPDATE_STATS(des)
    page.description = des
end
