local config = mwse.loadConfig("r0_crit_config") or {
    enabled = true,
    showMessageBox = false,
    damageMultiplier = 3,
	logToConsole = false,
	logToFile = false,
}

local function onDamage(e)

	if e.source ~= "attack" then return end
	if e.attacker == nil then return end
	
	local target		= e.reference
	local luck			= e.attacker.attributes[7+1].current
	local critChance	= ((luck / 100) ^ 3 / 2)
	local roll			= math.random()
	
	local critMult		= config.damageMultiplier
	
	local speedMult		= 2	
	if e.attacker.readiedWeapon ~= nil then
		speedMult = e.attacker.readiedWeapon.object.speed
	end
	if e.projectile ~= nil then
		speedMult = e.projectile.firingWeapon.speed
	end
	
	if critChance > roll then
		e.damage = e.damage * critMult * speedMult
		tes3.playSound({ reference = target, sound = "critical damage" })
		if ((e.attackerReference == tes3.getPlayerRef()) and config.showMessageBox) then
			tes3.messageBox({ message = tes3.findGMST("sTargetCriticalStrike").value })
		end
	end
	
		-- Debug info:
	if config.logToConsole == true then 
		tes3ui.log("[r0-luckystrike]Attacker Luck: %f", luck)
		tes3ui.log("[r0-luckystrike]Attacker Crit Chance: %f", critChance)
		tes3ui.log("[r0-luckystrike]Random roll: %f", roll)
		tes3ui.log("[r0-luckystrike]Critical Damage Multiplier: %f", critMult)
		tes3ui.log("[r0-luckystrike]Weapon Speed: %f", speedMult)
	end
	if config.logToFile == true then 
		mwse.log("[r0-luckystrike]Attacker Luck: %f", luck)
		mwse.log("[r0-luckystrike]Attacker Crit Chance: %f", critChance)
		mwse.log("[r0-luckystrike]Random roll: %f", roll)
		mwse.log("[r0-luckystrike]Critical Damage Multiplier: %f", critMult)
		mwse.log("[r0-luckystrike]Weapon Speed: %f", speedMult)
	end

end

local function registerModConfig()
    local template = mwse.mcm.createTemplate("Lucky Strike")
    template:saveOnClose("r0_crit_config", config)
	template:register()
	
    local page = template:createSideBarPage{label="Preferences"}

	page.sidebar:createInfo{
		text = "Lucky Strike - a Critical Hit Mod\nby R-Zero\n\n  Adds a Luck-based Critical Strike mechanic reminiscent of one in Daggerfall.\n  With this mod, any attack, no matter if Player's or some other actor's, which has hit its target will have a chance to be upgraded to a Critical Hit, dealing much more damage than usual. The Critical Hit chance depends on the Attacker's Luck attribute. The Critical Hit damage depends on the configurable miltiplier (3 by default) as well as the weapon speed - faster weapons like daggers and clubs will benefit more from a Critical Hit.\n  Try with default settings before changing anything, then adjust as needed.\n  Don't forget to send me your feedback! That would help me to balance this mod better."
	}	
	
    page:createOnOffButton{
        label = "Enable mod",
        variable = mwse.mcm.createTableVariable{
            id = "enabled",
            table = config
        }
    }
	
	page:createOnOffButton{
        label = "Show critical hit message",
        variable = mwse.mcm.createTableVariable{
            id = "showMessageBox",
            table = config
        }
    }	
	
	page:createSlider{
		label = "Damage multiplier",
		description = " Multiplier used in the critical damage formula.\n\nDefault value: 3.",
		min = 1,
        max = 10,
        step = 1,
        jump = 5,
		variable = mwse.mcm.createTableVariable{
		id = "damageMultiplier",
			table = config
		}
	}
	
		page:createOnOffButton{
        label = "Log to console",
		description = " Logs the debug information into the game's console, available using the '~' key.\n\nDefault value: Off.",
        variable = mwse.mcm.createTableVariable{
            id = "logToConsole",
            table = config
        }
    }
	
	page:createOnOffButton{
        label = "Log to file",
		description = " Logs the debug information into the mwse.log file, found in Morrowind folder.\n\nDefault value: Off.",
        variable = mwse.mcm.createTableVariable{
            id = "logToFile",
            table = config
        }
    }

end

event.register("damage", onDamage)
event.register("modConfigReady", registerModConfig)