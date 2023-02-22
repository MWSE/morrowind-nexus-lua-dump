local config = mwse.loadConfig("PowerWillpower") or {
    enabled = true,
    resistMultiplier = 10,
	defaultWillpower = 65,
	damageAbsorbEnabled = true,
    negativeAllowed = false,
	additiveEnabled = false,
    damageAbsorbThreshold = 200,
    logToConsole = false,
	logToFile = false,
}

local function fatigueTerm(actor)

	local fFatigueBase = tes3.findGMST("fFatigueBase").value
	local fFatigueMult = tes3.findGMST("fFatigueMult").value
	local normalizedFatigue
	
	if ( actor.fatigue.base == 0 ) then
		normalizedFatigue = 1
	else
		normalizedFatigue = ( math.max( actor.fatigue.current, 0 ) / actor.fatigue.base )
	end
	
	return fFatigueBase - fFatigueMult * ( 1 - normalizedFatigue )
	
end

local function onSpellResistCheck(e)


	-- Will not resist if the effect doesn't have an assotiated resist attribute, or if it's an ability:
	if (e.resistAttribute == 28 --no resist
	or e.source.castType == tes3.spellType.ability
	or e.source.castType == tes3.spellType.blight
	or e.source.castType == tes3.spellType.disease
	or e.source.castType == tes3.spellType.curse
	--or e.source.castType == tes3.enchantmentType.constant) then
	or ( e.source.sourceType == tes3.magicSourceType.enchantment and e.source.castType == tes3.enchantmentType.constant ) ) then
		if config.logToConsole == true then tes3ui.log("[r0-willpower]Not resistable.") end
		if config.logToFile == true then mwse.log("[r0-willpower]Not resistable.") end
		return
	end
	
	-- Target side terms:
	local targetActor = e.target.mobile
	local targetResist = targetActor.effectAttributes[e.resistAttribute+1]	
	local targetWillpower = targetActor.willpower.current	
	local targetLuck = targetActor.luck.current
	local targetFatigueTerm = fatigueTerm(targetActor)
	
	-- Caster side terms:	
	local casterActor
	local casterWillpower
	
	if ( e.caster == nil
	or e.source.objectType == tes3.objectType.enchantment ) then
		casterWillpower = config.defaultWillpower
	else
        casterActor = e.caster.mobile
		casterWillpower = casterActor.willpower.current
	end
	
	--tes3ui.log("Caster: %s; Source: %s (%s)", e.caster, e.source, e.source.objectType)
	--tes3ui.log( table.find(tes3.objectType, e.source.objectType) )
	
	-- Resist Chance formila:	
	local resistBonus = config.resistMultiplier / 10 * ( ( targetFatigueTerm * ( ( targetWillpower - casterWillpower ) + 0.1 * targetLuck ) ) )
	if config.negativeAllowed == false then
		resistBonus = math.max( resistBonus, 0 )
	end
	if config.additiveEnabled == true then
		e.resistedPercent = math.min( ( targetResist + resistBonus ), 100 )
	else
		e.resistedPercent = math.min( ( targetResist + ( ( 100 - targetResist ) * resistBonus / 100 ) ), 100 )
	end
	
	-- Debug info:
	if config.logToConsole == true then 
		tes3ui.log("[r0-willpower]Caster Willpower: %f", casterWillpower)
		tes3ui.log("[r0-willpower]Target Willpower: %f", targetWillpower)
		tes3ui.log("[r0-willpower]Target Luck: %f", targetLuck)
		tes3ui.log("[r0-willpower]Target Resist Value: %f", targetResist)	
		tes3ui.log("[r0-willpower]Target Fatigue Term: %f", targetFatigueTerm)	
		tes3ui.log("[r0-willpower]Resist Multiplier: %f", config.resistMultiplier)	
		tes3ui.log("[r0-willpower]Resist bonus: %f", resistBonus)
		tes3ui.log("[r0-willpower]Adjusting resist value: %f", e.resistedPercent)
	end
	if config.logToFile == true then 
		mwse.log("[r0-willpower]Caster Willpower: %f", casterWillpower)
		mwse.log("[r0-willpower]Target Willpower: %f", targetWillpower)
		mwse.log("[r0-willpower]Target Luck: %f", targetLuck)
		mwse.log("[r0-willpower]Target Resist Value: %f", targetResist)	
		mwse.log("[r0-willpower]Target Fatigue Term: %f", targetFatigueTerm)
		mwse.log("[r0-willpower]Resist Multiplier: %f", config.resistMultiplier)		
		mwse.log("[r0-willpower]Resist bonus: %f", resistBonus)
		mwse.log("[r0-willpower]Adjusting resist value: %f", e.resistedPercent)
	end	
	
	-- Whether to apply resist value after the roll:
	local MGEF = tes3.getDataHandler().nonDynamicData.magicEffects
	local dontuseResist = MGEF[e.effect.id+1].hasNoMagnitude
	
	if ( dontuseResist == true ) then	
		if config.logToConsole == true then tes3ui.log("[r0-willpower]No Magnitude, using a chance based resist:") end
		if config.logToFile == true then mwse.log("[r0-willpower]No Magnitude, using a chance based resist:") end
		local roll = math.random(100)		
		if config.logToConsole == true then tes3ui.log("[r0-willpower]Save roll: %f", roll) end
		if config.logToFile == true then mwse.log("[r0-willpower]Save roll: %f", roll) end
		if ( resistBonus > roll ) then
			if config.logToConsole == true then tes3ui.log("[r0-willpower]Success!") end
			if config.logToFile == true then mwse.log("[r0-willpower]Success!") end
			e.resistedPercent = 100
		else
			if config.logToConsole == true then tes3ui.log("[r0-willpower]Fail!") end
			if config.logToFile == true then mwse.log("[r0-willpower]Fail!") end
			e.resistedPercent = 0
		end
	elseif ( targetResist > config.damageAbsorbThreshold ) and ( config.damageAbsorbEnabled == true ) then	
		e.resistedPercent = math.min( ( targetResist - config.damageAbsorbThreshold + 100 ) , 200)
		if config.logToConsole == true then tes3ui.log("[r0-willpower]Absorbing with rate: %f", ( e.resistedPercent - 100 ) ) end
		if config.logToFile == true then mwse.log("[r0-willpower]Absorbing with rate: %f", ( e.resistedPercent - 100 ) ) end
	end	
	
	if config.logToConsole == true then tes3ui.log("[r0-willpower]=======================================") end
	if config.logToFile == true then mwse.log("[r0-willpower]=======================================") end
end

local function registerModConfig()
    local template = mwse.mcm.createTemplate("Putting Power in Willpower")
    template:saveOnClose("PowerWillpower", config)
	template:register()
	
    local page = template:createSideBarPage{label="Preferences"}

	page.sidebar:createInfo{
		text = "Putting Power in Willpower 2: Antimagic Boogaloo\nby R-Zero\n\n  This mod rebalances the willpower-based spell resist mechanic, giving all in-game actors, Player, NPCs and Creatures an ability to shrug off spells through the sheer force of will.\n  The resist chance is affected by the difference in Caster and Target's Willpower score.\n  Try with default settings before changing anything, then adjust as needed.\n  Don't forget to send me your feedback! That would help me to balance this mod better."
	}	
	
    page:createOnOffButton{
        label = "Enable mod",
        variable = mwse.mcm.createTableVariable{
            id = "enabled",
            table = config
        }
    }
	
	page:createSlider{
		label = "Resist multiplier",
		description = " Multiplier used in the resist formula. Numbers higher than 10 will increase the chance, lower than 10 - decrease.\n\nDefault value: 10.",
		min = 0,
        max = 20,
        step = 1,
        jump = 5,
		variable = mwse.mcm.createTableVariable{
		id = "resistMultiplier",
			table = config
		}
	}
	
	page:createSlider{
        label = "Default Willpower value",
        description = " Changes the default Willpower score used by Enchantments and Traps.\n\nDefault value: 65.",
        min = 0,
        max = 100,
        step = 5,
        jump = 20,
        variable = mwse.mcm.createTableVariable{
            id = "defaultWillpower",
            table = config
		}
    }
	
	page:createOnOffButton{
        label = "Allow negative Resist Bonus",
		description = " Allows negative values for Resist Bonus, which makes spells cast by high-Willpower casters deal more than base damage to low-Willpower targets.\n Enable if you want Willpower to have even more POWER (warning: might be unbalanced).\n\nDefault value: Off.",
        variable = mwse.mcm.createTableVariable{
            id = "negativeAllowed",
            table = config
        }
    }		
	
	--page:createOnOffButton{
    --    label = "Enable additive calculation",
	--	description = " Changes the Resist Bonus formula to add its value to the exsisting Resist values instead of multiplying. Purely experimental. Not recommended to use together with 'Allow negative Resist Bonus'.\n\nDefault value: Off.",
    --    variable = mwse.mcm.createTableVariable{
    --        id = "additiveEnabled",
    --        table = config
    --    }
    --}
	
	page:createOnOffButton{
        label = "Enable Damage Absorption",
		description = " Allows NPCs and Creatures with 'Resist [element]' value higher than Damage Absorb Threshold to absorb that type of damage and heal from damaging spells instead.\n Use `Putting Power in Willpower - Absorbonach.esp` together with this setting to make Atronaches heal from their elemental magic.\n\nDefault value: On.",
        variable = mwse.mcm.createTableVariable{
            id = "damageAbsorbEnabled",
            table = config
        }
    }	
	
	page:createSlider{
        label = "Damage Absorb Threshold",
        description = " Changes the value of 'Resist [element]' starting from which NPCs and Creatures start to absorb damage instead of taking it.\n\nDefault value: 200.",
        min = 100,
        max = 500,
        step = 10,
        jump = 50,
        variable = mwse.mcm.createTableVariable{
            id = "damageAbsorbThreshold",
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

event.register("modConfigReady", registerModConfig)
event.register("spellResist", onSpellResistCheck)