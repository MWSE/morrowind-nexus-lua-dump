local data = require("kindi.security.data")

local config = require("kindi.security.config")

local EasyMCM = require("easyMCM.EasyMCM")

local template = EasyMCM.createTemplate {}
template.name = "Security Success"
template:saveOnClose("security_success", config)

local page =
    template:createSideBarPage {
    label = "Main",
    font = 2,
    description = "This side page will show your statistics and history. In-game only.",
    noScroll = false
}

local general = page:createCategory("General")

onoff =
    general:createOnOffButton {
    label = "Toggles the mod on or off",
    description = "When active, the chance to unlock and disarm the object will be shown in the tooltip.\nWill also reset fPickLockMult and fTrapCostMult to default game values.",
    variable = EasyMCM.createTableVariable {id = "showInfo", table = config},
    callback = function()
        if config.showInfo == true then
            tes3.messageBox("Security Success is turned ON")
            local ts = tes3.getSound("Open Lock")
            ts:play()
            tes3.findGMST(1081).value = tonumber(config.fpicklockmult)
            tes3.findGMST(1082).value = tonumber(config.ftrapcostmult)
        else
            tes3.messageBox("Security Success is turned OFF")
            local ts = tes3.getSound("LockedChest")
            ts:play()
            tes3.findGMST(1081).value = -1
            tes3.findGMST(1082).value = 0
        end
    end
}
general:createYesNoButton {
    label = "Show key to lock and name of trap?",
    description = "When active, reveals the key to the lock(if any) and the trap name/points(if trapped)\nMust be equipping a pick or probe to trigger",
    variable = EasyMCM.createTableVariable {id = "showExtra", table = config},
    callback = function()
        if config.showExtra == true then
            tes3.messageBox("Key and Trap name will be revealed")
            local ts = tes3.getSound("Disarm Trap")
            ts:play()
        else
            tes3.messageBox("Key and Trap name will be hidden")
            local ts = tes3.getSound("LockedDoor")
            ts:play()
        end
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

local stats =
    template:createPage {
    id = -2332,
    label = "About"
}

button1 =
    stats:createCategory {
    label = string.format(
        "Security Success by kindi\n\nINTRO\nThis mod will reveal the pick or disarm chance of the door if it is locked or trapped\n\nAdditionally, the trap name and key name, if the door has a key for it, can optionally be revealed.\n\nThe player must be equpping a lockpick or probe for the information to be shown\n\nFORMULA\nfatigueTerm = fFatigueBase - fFatigueMult * ( 1 - currentFatigue/maxFatigue )\n\nLockpicking: \nx = ( 0.2 * playerAgility ) + ( 0.1 * playerLuck ) + playerSecurity\nx = x * pickQuality * fatigueTerm\nx = x + fPickLockMult * lockLevel\n\nProbing Trap: \nx = ( 0.2 * playerAgility) + ( 0.1 * playerLuck ) + playerSecurity\nx = x + fTrapCostMult * trapSpellPoints\nx = x * probeQuality * fatigueTerm\n\n"
    )
}

EasyMCM.register(template)

function SS_KINDI_UPDATE_STATS(des)
    page.description = des
end
