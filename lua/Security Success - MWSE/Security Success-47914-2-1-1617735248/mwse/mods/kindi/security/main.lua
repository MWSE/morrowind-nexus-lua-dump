--[[v2.1]]

local confPath = "Security_Success_Info"
local config = mwse.loadConfig(confPath)
if not config then
    config = {
        showInfo = true,
        showExtra = false,
		ftrapcostmult = 0.0,
		fpicklockmult = -1.0
    }
else
    config = mwse.loadConfig("Security_Success_Info")
end

local function registerModConfig()
    local EasyMCM = require("easyMCM.EasyMCM")

    local template = EasyMCM.createTemplate("Security Success")
    template:saveOnClose(confPath, config)

    local page =
        template:createSideBarPage {
        sidebarComponents = {
            EasyMCM.createInfo {
                text = string.format("Security Success by kindi\n\nINTRO\nThis mod will reveal the pick or disarm chance of the door if it is locked or trapped\n\nAdditionally, the trap name and key name, if the door has a key for it, can optionally be revealed.\n\nThe player must be equpping a lockpick or probe for the information to be shown\n\nFORMULA\nfatigueTerm = fFatigueBase - fFatigueMult * ( 1 - currentFatigue/maxFatigue )\n\nLockpicking: \nx = ( 0.2 * playerAgility ) + ( 0.1 * playerLuck ) + playerSecurity\nx = x * pickQuality * fatigueTerm\nx = x + fPickLockMult * lockLevel\n\nProbing Trap: \nx = ( 0.2 * playerAgility) + ( 0.1 * playerLuck ) + playerSecurity\nx = x + fTrapCostMult * trapSpellPoints\nx = x * probeQuality * fatigueTerm\n\n" )
            }
        }
    }

    local general = page:createCategory("General")

    general:createOnOffButton {
        label = "Toggles the mod on or off",
        description = "When active, the chance to unlock and disarm the object will be shown in the tooltip",
        variable = EasyMCM.createTableVariable {id = "showInfo", table = config},
        callback = function()
            if config.showInfo == true then
                tes3.messageBox("Security Success is turned ON")
            else
                tes3.messageBox("Security Success is turned OFF")
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
            else
                tes3.messageBox("Key and Trap name will be hidden")
            end
        end
    }

	local lockpicking = page:createCategory("LockPicking")
	lockpicking:createTextField{
        label = "fPickLockMult",
        variable = EasyMCM.createTableVariable {id = "fpicklockmult", table = config},
        description = "Changes fPickLockMult GMST\nA large negative value will make lockpicking harder.\nDefault value: -1.0\n",
        numbersOnly = true,
        callback = function()
			 tes3.findGMST(1081).value = tonumber(config.fpicklockmult)
        end
	}


	local probing = page:createCategory("Probing")
	probing:createTextField{
        label = "fTrapCostMult",
        variable = EasyMCM.createTableVariable {id = "ftrapcostmult", table = config},
        description = "Changes fTrapCostMult GMST\nIn the base game, the chance to disarm traps are the same regardless of the type of trap. Adjust this to a negative value to add more difficulty disarming traps.\nDefault value: 0.0\nRecomended value: -1.5",
        numbersOnly = true,
        callback = function()
			 tes3.findGMST(1082).value = tonumber(config.ftrapcostmult)
        end
	}

	local check = page:createCategory("Check GMSTs")
	check:createButton{
        label = "Current fFatigueBase",
		buttonText = "Check",
        description = "Shows current fFatigueBase value\nDefault value: 1.25",
        callback = function()
			 tes3.messageBox(tes3.findGMST(1006).value)
        end
	}
		check:createButton{
        label = "Current fFatigueMult",
		buttonText = "Check",
        description = "Shows current fFatigueMult value\nDefault value: 0.5",
        callback = function()
			 tes3.messageBox(tes3.findGMST(1007).value)
        end
	}
		check:createButton{
        label = "Current fPickLockMult",
		buttonText = "Check",
        description = "Shows current fPickLockMult value\nDefault value: -1.0",
        callback = function()
			 tes3.messageBox(tes3.findGMST(1081).value)
        end
	}
		check:createButton{
        label = "Current fTrapCostMult",
		buttonText = "Check",
        description = "Shows current fTrapCostMult value\nDefault value: 0",
        callback = function()
			 tes3.messageBox(tes3.findGMST(1082).value)
        end
	}

    EasyMCM.register(template)
end
event.register("modConfigReady", registerModConfig)




local function updategmst()
	tes3.findGMST(1081).value = tonumber(config.fpicklockmult)
	tes3.findGMST(1082).value = tonumber(config.ftrapcostmult)
end
event.register("initialized", updategmst)


local function NewTooltipBlock(tooltip, ts, ts1)
    local block = tooltip:createBlock {}
    block.minWidth = 1
    block.maxWidth = 440
    block.autoWidth = true
    block.autoHeight = true
    local label = block:createLabel {text = string.format("%s%s", ts, ts1)}
	label.justifyText = "center"
    label.wrapText = true
    return block
end

local function ShowTheChance(tooltip, pickChance, disarmChance, isLocked, needKey, Tar, trappoints)
    if config.showInfo then
        if isequippingLockpick and isLocked then
            if not needKey then
                local ts = string.format("Unlock Chance: %.2f", pickChance)
                local ts1 = string.format("\nKey: %s", Tar.reference.lockNode.key.name)
                if config.showExtra == false then
                    ts1 = ""
                end
                local newBlock = NewTooltipBlock(tooltip, ts, ts1)
            else
                local ts = string.format("Key: %s", Tar.reference.lockNode.key.name)
                local ts1 = ""
                NewTooltipBlock(tooltip, ts, ts1)
                tes3.messageBox("Lockpicking not possible")
            end
        elseif isequippingProbe and Tar.reference.lockNode.trap then
            local ts = string.format("Disarm Chance: %.2f", disarmChance)
            local ts1 = string.format("\nTrap: %s - %s points", Tar.reference.lockNode.trap.name, trappoints)
            if config.showExtra == false then
                ts1 = ""
            end
            local newBlock = NewTooltipBlock(tooltip, ts, ts1)
        end
    end
end

local function DoyouKnowHowToPickALock(Tar)
    local lockortrap = Tar.reference
    local pickChance = 0
    local needKey = false
    local isLocked = false
    local isTrapped = false
    local tooltip = Tar.tooltip

    if lockortrap == nil or lockortrap.lockNode == nil then
        return
    end

    if
        tes3.player.mobile.readiedWeapon ~= nil and
            (lockortrap.object.objectType == tes3.objectType.container or
                lockortrap.object.objectType == tes3.objectType.door)
     then
        --TERUSKAN USAHA
        isequippingLockpick = (tes3.player.mobile.readiedWeapon.object.objectType == tes3.objectType.lockpick)
        isequippingProbe = (tes3.player.mobile.readiedWeapon.object.objectType == tes3.objectType.probe)
    else
        return
    end

    --tes3.messageBox(tes3.player.mobile.readiedWeapon.object.objectType == tes3.objectType.lockpick)
    --if tes3.player.mobile.readiedWeapon.object.objectType ~= tes3.objectType.lockpick then return end

    if lockortrap.lockNode.locked == false then
        isLocked = false
    else
        isLocked = true
    end
    if tes3.getTrap {reference = lockortrap} == nil then
        isTrapped = false
    else
        isTrapped = true
    end
    if tes3.getLockLevel {reference = lockortrap} > 0 then
        needKey = false
    else
        needKey = true
    end
    if isequippingLockpick and isLocked then
        if (tes3.getLockLevel {reference = lockortrap} ~= nil) then
            pickChance =
                math.max(
                0,
                ((0.2 * tes3.mobilePlayer.agility.current) + (0.1 * tes3.mobilePlayer.luck.current) +
                    tes3.mobilePlayer.security.current) *
                    tes3.getEquippedItem({actor = tes3.player, objectType = tes3.objectType.lockpick}).object.quality *
                    (tes3.findGMST(tes3.gmst.fFatigueBase).value -
                        tes3.findGMST(tes3.gmst.fFatigueMult).value *
                            (1 - tes3.mobilePlayer.fatigue.current / tes3.mobilePlayer.fatigue.base)) +
                    tes3.findGMST(tes3.gmst.fPickLockMult).value * tes3.getLockLevel {reference = lockortrap}
            )
        end
    elseif isequippingProbe and isTrapped then
		trappoints = tes3.getTrap{reference = lockortrap}.magickaCost
        disarmChance =
            math.max(
            0,
            (((0.2 * tes3.mobilePlayer.agility.current) + (0.1 * tes3.mobilePlayer.luck.current) +
                tes3.mobilePlayer.security.current) +
                (tes3.findGMST(tes3.gmst.fTrapCostMult).value * tes3.getTrap {reference = lockortrap}.magickaCost)) *
                tes3.getEquippedItem({actor = tes3.player, objectType = tes3.objectType.probe}).object.quality *
                (tes3.findGMST(tes3.gmst.fFatigueBase).value -
                    tes3.findGMST(tes3.gmst.fFatigueMult).value *
                        (1 - tes3.mobilePlayer.fatigue.current / tes3.mobilePlayer.fatigue.base))
        )
    end
    ShowTheChance(tooltip, pickChance, disarmChance, isLocked, needKey, Tar, trappoints )
end
event.register("uiObjectTooltip", DoyouKnowHowToPickALock)
