local config = mwse.loadConfig("Quadratic Wizardry") or {
}

local function registerModConfig()
	local template = mwse.mcm.createTemplate("Quadratic Wizardry")
	template:saveOnClose("Quadratic Wizardry", config)
	template:register()
	
	local page = template:createSideBarPage{label="Preferences"}

	page.sidebar:createInfo{
		text = "Quadratic Wizardry  \n\nThis mod serves two functions: \n\n-Make the magicka cost of spells scale with skill, both for PCs as well as NPCs. Creatures are not affected. \n\n-Make the effectiveness of hostile spells strongly influenced on the caster's and target's willpower. Applies to all actors. \n\nI recommend using another mod of mine, Wizard Equalizer, to make PCs and NPCs play by the same rules when it comes to determining their maximum magicka. \n\nThere are no actual quadratic functions involved. This mod is named after the Linear Fighter, Quadratic Wizard trope established by early DnD and inherited by the first two TES games."
	}	
	
	page:createDropdown{
        label = "Player Spell Cost Formula",
		description = "Determines which formula to use for the player's spell costs. \n\nThere are two options for making the cost of spells, each seperately assignable to PCs and NPCs. \nExponential starts drastically more expensive but ultimately makes spells cost a mere fraction of what they would have in Vanilla. \n0:     5.00x cost \n25:    2.24x cost \n50:    1.00x cost \n75:    0.45x cost \n100:   0.20x cost \n200+: 0.10x cost \n\nLinear starts at the vanilla cost and goes down more slowly, ultimately reaching the same values for 100 skill and beyond. \n0:     1.0x cost \n25:    0.8x cost \n50:    0.6x cost \n75:    0.4x cost \n100:   0.2x cost \n200+: 0.1x cost \n\nThere are also x2 versions, which have doubled starting points but reach the same values at 100+. Exponential x2 was my original idea for the Exponential formula, but I felt it might have been too much, especially when factoring in NPC skills. \n\nDefault: Exponential",
        variable = mwse.mcm.createTableVariable{
			id = "costFormPC",
			table = config
		},
		options = {
			{
				value = 0,
				label = "Off"
			},
			{
				value = 1,
				label = "Exponential"
			},
			{
				value = 2,
				label = "Linear"
			},
			{
				value = 3,
				label = "Exponential x2"
			},
			{
				value = 4,
				label = "Linear x2"
			}
		},
		defaultSetting = 1,
		showDefaultConfig = true
	}
   
   page:createDropdown{
        label = "NPC Spell Cost Formula",
		description = "Determines which formula to use for NPCs' spell costs. \n\nThere are two options for making the cost of spells, each seperately assignable to PCs and NPCs. \nExponential starts drastically more expensive but ultimately makes spells cost a mere fraction of what they would have in Vanilla. \n0:     5.00x cost \n25:    2.24x cost \n50:    1.00x cost \n75:    0.45x cost \n100:   0.20x cost \n200+: 0.10x cost \n\nLinear starts at the vanilla cost and goes down more slowly, ultimately reaching the same values for 100 skill and beyond. \n0:     1.0x cost \n25:    0.8x cost \n50:    0.6x cost \n75:    0.4x cost \n100:   0.2x cost \n200+: 0.1x cost \n\nThere are also x2 versions, which have doubled starting points but reach the same values at 100+. Exponential x2 was my original idea for the Exponential formula, but I felt it might have been too much, especially when factoring in NPC skills. \n\nNOTICE: NPCs cannot recognize the altered costs, so they cannot fully take advantage of the system. They will still be able to cast more spells with high skill, but not to the same extend of the player. To avoid them trying to cast spells they have no magicka for, I have idiot-proofed them by letting them use the last of their magicka to cast any such spell attempt, so long as they had enough magicka to cast the spell at its base cost in the first place. \n\nDefault: Exponential",
        variable = mwse.mcm.createTableVariable{
			id = "costFormNPC",
			table = config
		},
		options = {
			{
				value = 0,
				label = "Off"
			},
			{
				value = 1,
				label = "Exponential"
			},
			{
				value = 2,
				label = "Linear"
			},
			{
				value = 3,
				label = "Exponential x2"
			},
			{
				value = 4,
				label = "Linear x2"
			}
		},
		defaultSetting = 1,
		showDefaultConfig = true
	}
	
	page:createOnOffButton{
        label = "Enable Hostile Spell Scaling",
		description = " Whether or not to override spell resistance with a new formula. 100% resistance does not necessarily grant immunity.\n 100 - 100 * CasterWillpower / Target Willpower + Elemental Resistance \n\nDefault: On",
        variable = mwse.mcm.createTableVariable{
			id = "enableHostileSpellScaling",
			table = config
		},
		defaultSetting = true,
		showDefaultConfig = true
	}
	
	page:createSlider{
		label = "Resist Formula Percentage",
		description = "Scales the impact of willpower on spell resistance. \n\nDefault: 100",
		min = 0,
        max = 100,
        step = 1,
        jump = 10,
		variable = mwse.mcm.createTableVariable{
			id = "resistPercent",
			table = config
		},
	    defaultSetting = 100,
	    showDefaultConfig = true
	}
	
	page:createOnOffButton{
        label = "Fixed Enchantment Willpower",
        variable = mwse.mcm.createTableVariable{
		description = " Whether or not to set a statis willpower value for enchanted items. If you turn this off, then enchanted items will use the spellcaster's willpower instead of the value set below. \n\nDefault: On",
			id = "useEnchantPower",
			table = config
        },
	   defaultSetting = true,
	   showDefaultConfig = true
	}
	
	page:createSlider{
		label = "Trap Willpower",
		description = "Determines the Willpower used by traps. \n\nDefault: 100",
		min = 0,
		max = 200,
		step = 10,
		jump = 20,
		variable = mwse.mcm.createTableVariable{
			id = "trapPower",
			table = config
		},
		defaultSetting = 100,
		showDefaultConfig = true
	}
	
	page:createSlider{
		label = "Enchantment Willpower",
		description = "Determines the Willpower used by traps if Fixed Enchantment Willpower is enabled. \n\nDefault: 50",
		min = 0,
		max = 200,
		step = 10,
		jump = 20,
		variable = mwse.mcm.createTableVariable{
			id = "enchantPower",
			table = config
		},
		defaultSetting = 50,
		showDefaultConfig = true
	}
	
	page:createSlider{
       label = "Caster Willpower Floor",
       description = "Determines the minimum value for the caster's willpower to be considered as by the resist formula \n\nDefault: 20",
       min = 5,
       max = 100,
       step = 5,
       jump = 20,
       variable = mwse.mcm.createTableVariable{
			id = "casterWillFloor",
			table = config
	   },
	   defaultSetting = 20,
	   showDefaultConfig = true
	}
	
	page:createSlider{
       label = "Target Willpower Floor",
       description = "Determines the minimum value for the target's willpower to be considered as by the resist formula \n\nDefault: 50",
       min = 5,
       max = 100,
       step = 5,
       jump = 20,
       variable = mwse.mcm.createTableVariable{
			id = "targetWillFloor",
			table = config
	   },
	   defaultSetting = 50,
	   showDefaultConfig = true
	}
end
event.register("modConfigReady", registerModConfig)



mwse.log("Quadratic Wizardry is now injecting your game with sheer magical awesomeness.")



--Spell costs scaling with skill

local function setCostPlayer(leastSchool, magickaCost)
	local spellSkillLevel = 60
	local newCost = magickaCost
	local formula = config.costFormPC
	local skipCalc = false
	
	if formula == 0 then skipCalc = true end
	
	if (leastSchool == 0) then spellSkillLevel = tes3.mobilePlayer.alteration.current
	elseif (leastSchool == 1) then spellSkillLevel = tes3.mobilePlayer.conjuration.current
	elseif (leastSchool == 2) then spellSkillLevel = tes3.mobilePlayer.destruction.current
	elseif (leastSchool == 3) then spellSkillLevel = tes3.mobilePlayer.illusion.current
	elseif (leastSchool == 4) then spellSkillLevel = tes3.mobilePlayer.mysticism.current
	elseif (leastSchool == 5) then spellSkillLevel = tes3.mobilePlayer.restoration.current
	else skipCalc = true end -- Indicates that the spell is not of one of the vanilla schools, and therefore should be excluded
	
	if (skipCalc == false) then
		if (formula == 1 and spellSkillLevel <= 100) then
			newCost = math.ceil(magickaCost * 5 * math.exp(-0.0321888*spellSkillLevel))
		elseif (formula == 2 and spellSkillLevel <= 100) then
			newCost = math.ceil(magickaCost * (-0.008*spellSkillLevel + 1))
		elseif (formula == 3 and spellSkillLevel <= 100) then
			newCost = math.ceil(magickaCost * 10 * math.exp(-0.0391202*spellSkillLevel))
		elseif (formula == 4 and spellSkillLevel <= 100) then
			newCost = math.ceil(magickaCost * (-0.018*spellSkillLevel + 2))
		end
		if (spellSkillLevel > 100 and spellSkillLevel <= 200) then
			newCost = math.ceil(magickaCost * (-0.001*spellSkillLevel + 0.3))
		elseif (spellSkillLevel > 200) then 
			newCost = math.ceil(magickaCost * 0.1) 
		end
		if (newCost < 1) then newCost = 1 end
	end
	
	return newCost
end

local function setCostNPC(leastSchool, magickaCost, caster)
	local spellSkillLevel = 60
	local newCost = magickaCost
	local formula = config.costFormNPC
	local skipCalc = false
	
	if formula == 0 then skipCalc = true end
	
	if (leastSchool == 0) then spellSkillLevel = caster.mobile.alteration.current
	elseif (leastSchool == 1) then spellSkillLevel = caster.mobile.conjuration.current
	elseif (leastSchool == 2) then spellSkillLevel = caster.mobile.destruction.current
	elseif (leastSchool == 3) then spellSkillLevel = caster.mobile.illusion.current
	elseif (leastSchool == 4) then spellSkillLevel = caster.mobile.mysticism.current
	elseif (leastSchool == 5) then spellSkillLevel = caster.mobile.restoration.current
	else skipCalc = true end 
	
	if skipCalc == false then
		if (formula == 1 and spellSkillLevel <= 100) then
			newCost = math.ceil(magickaCost * 5 * math.exp(-0.0321888*spellSkillLevel))
		elseif (formula == 2 and spellSkillLevel <= 100) then
			newCost = math.ceil(magickaCost * (-0.008*spellSkillLevel + 1))
		elseif (formula == 3 and spellSkillLevel <= 100) then
			newCost = math.ceil(magickaCost * 10 * math.exp(-0.0391202*spellSkillLevel))
		elseif (formula == 4 and spellSkillLevel <= 100) then
			newCost = math.ceil(magickaCost * (-0.018*spellSkillLevel + 2))
		end
		if (spellSkillLevel > 100 and spellSkillLevel <= 200) then
			newCost = math.ceil(magickaCost * (-0.001*spellSkillLevel + 0.3))
		elseif (spellSkillLevel > 200) then 
			newCost = math.ceil(magickaCost * 0.1) 
		end
		if (newCost < 1) then newCost = 1 end
		-- Idiot-proofing NPCs since I cannot force them to understand the dynamic spell costs
		if (newCost > caster.mobile.magicka.current and magickaCost <= caster.mobile.magicka.current) then newCost = caster.mobile.magicka.current end
	end
	
	return newCost
end

local function spellMagickaUseCallback(e)
	local caster = e.caster
	local spell = e.spell
    if (caster == tes3.player) then
		local leastSchool = spell:getLeastProficientSchool(tes3.player)
		local newCost = setCostPlayer(leastSchool, spell.magickaCost)
		e.cost = newCost
	elseif (caster.mobile.actorType == 1) then
		local leastSchool = spell:getLeastProficientSchool(caster)
		local newCost = setCostNPC(leastSchool, spell.magickaCost, caster)
		e.cost = newCost
	end
end
event.register(tes3.event.spellMagickaUse, spellMagickaUseCallback)

local function updateSpellCosts(e)
	if(tes3.player == nil) then
		return
	end
	
    local costs = e.source:findChild("MagicMenu_spell_costs") --- @cast costs tes3uiElement
    for _, child in ipairs(costs.children) do
        local spell = child:getPropertyObject("MagicMenu_Spell")
		local leastSchool = spell:getLeastProficientSchool(tes3.player)
		local newCost = setCostPlayer(leastSchool, spell.magickaCost)
        child.text = string.format("%d", newCost)
    end
	
    local chances = e.source:findChild("MagicMenu_spell_percents") --- @chances tes3uiElement
    for _, child in ipairs(chances.children) do
        local spell = child:getPropertyObject("MagicMenu_Spell")
		local leastSchool = spell:getLeastProficientSchool(tes3.player)
		local newCost = setCostPlayer(leastSchool, spell.magickaCost)
		if(newCost < tes3.mobilePlayer.magicka.current) then			
			child.text = "/" .. string.format("%d", math.clamp(spell:calculateCastChance({ checkMagicka = false, caster = tes3.player }), 0, 100)) 
		end
    end	
end

local function onMagicMenuActivated(e)
    if (not e.newlyCreated) then
        return
    end

    -- We need to know when the spell list is updated.
    e.element:registerAfter("preUpdate", updateSpellCosts)
end
event.register(tes3.event.uiActivated, onMagicMenuActivated, { filter = "MenuMagic" })



-- Hostile Spell Effectiveness

local function spellResistCallback(e)
	if (config.enableHostileSpellScaling == true) then
		-- Target side terms:
		local targetActor = e.target.mobile
		local targetResist = targetActor.effectAttributes[e.resistAttribute+1]
		local targetWillpower = math.max(config.targetWillFloor, targetActor.willpower.current)
		
		-- Caster side terms:	
		local casterActor
		local casterWillpower
		
		if ( e.caster == nil ) then --Traps
			casterWillpower = config.trapPower
		elseif (e.source.objectType == tes3.objectType.enchantment and config.useEnchantPower == true) then -- Enchantments
			casterWillpower = config.enchantPower
		else 
			casterActor = e.caster.mobile
			casterWillpower = math.max(config.casterWillFloor, casterActor.willpower.current)
		end
		
		-- Resistance Chance:	
		local newResist
		if targetResist ~= nil then newResist = ((config.resistPercent/100) * (100 - 100*casterWillpower/targetWillpower) + targetResist)
		else newResist = (100 - 100*casterWillpower/targetWillpower) end
		e.resistedPercent = math.min(newResist, 100)
	end
end
event.register(tes3.event.spellResist, spellResistCallback)



-- Beneficial Spell Multiplier, currently causes the magnitude to be increased permenantly

--local function spellCastedCallback(e)
--local spell = e.source
--	local power = e.caster.mobile.willpower.current / 50
--	if (spell.castType == 0) then
--		for _, effect in ipairs(spell.effects) do
--			if (effect.rangeType == 0) then
--				effect.min = effect.min * power
--				effect.max = effect.max * power
--			end
--		end
--	end
--end
--event.register(tes3.event.spellCasted, spellCastedCallback)