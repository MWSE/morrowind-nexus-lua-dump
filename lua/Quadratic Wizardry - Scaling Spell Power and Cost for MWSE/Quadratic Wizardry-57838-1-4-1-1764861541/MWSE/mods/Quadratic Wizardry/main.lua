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
		description = "Determines which formula to use for the player's spell costs. \n\nThere are two options for making the cost of spells, each seperately assignable to PCs and NPCs. \n\nExponential starts drastically more expensive but ultimately makes spells cost a mere fraction of what they would have in Vanilla. \n0:     5.00x cost \n25:    2.24x cost \n50:    1.00x cost \n75:    0.45x cost \n100:   0.20x cost \n200+: 0.10x cost \n\nLinear starts at the vanilla cost and goes down more slowly, ultimately reaching the same values for 100 skill and beyond. \n0:     1.0x cost \n25:    0.8x cost \n50:    0.6x cost \n75:    0.4x cost \n100:   0.2x cost \n200+: 0.1x cost \n\nThere are also x2 versions, which have doubled starting points but reach the same values at 100+. Exponential x2 was my original idea for the Exponential formula, but I felt it might have been too much, especially when factoring in NPC skills. \n\nSudden Drop has very consistent costs for up to 50 skill or so but continuously drops faster and faster the further along you are. Might be the best option for NPC balancing. \n0:     1.09x cost \n25:    1.04x cost \n50:    0.95x cost \n75:    0.76x cost \n100:   0.20x cost \n200+: 0.10x cost \n\nDefault: Exponential",
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
			},
			{
				value = 5,
				label = "Sudden Drop"
			}
		},
		defaultSetting = 1,
		showDefaultConfig = true
	}
   
   page:createDropdown{
        label = "NPC Spell Cost Formula",
		description = "Determines which formula to use for NPCs' spell costs. \n\nThere are two options for making the cost of spells, each seperately assignable to PCs and NPCs. \n\nNOTICE: NPCs cannot recognize the altered costs, so they cannot fully take advantage of the system. They will still be able to cast more spells with high skill, but not to the same extend of the player. To avoid them trying to cast spells they have no magicka for, I have idiot-proofed them by letting them use the last of their magicka to cast any such spell attempt, so long as they had enough magicka to cast the spell at its base cost in the first place. \n\nExponential starts drastically more expensive but ultimately makes spells cost a mere fraction of what they would have in Vanilla. \n0:     5.00x cost \n25:    2.24x cost \n50:    1.00x cost \n75:    0.45x cost \n100:   0.20x cost \n200+: 0.10x cost \n\nLinear starts at the vanilla cost and goes down more slowly, ultimately reaching the same values for 100 skill and beyond. \n0:     1.0x cost \n25:    0.8x cost \n50:    0.6x cost \n75:    0.4x cost \n100:   0.2x cost \n200+: 0.1x cost \n\nThere are also x2 versions, which have doubled starting points but reach the same values at 100+. Exponential x2 was my original idea for the Exponential formula, but I felt it might have been too much, especially when factoring in NPC skills. \n\nSudden Drop has very consistent costs for up to 50 skill or so but continuously drops faster and faster the further along you are. Might be the best option for NPC balancing. \n0:     1.09x cost \n25:    1.04x cost \n50:    0.95x cost \n75:    0.76x cost \n100:   0.20x cost \n200+: 0.10x cost \n\nDefault: Exponential",
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
			},
			{
				value = 5,
				label = "Sudden Drop"
			}
		},
		defaultSetting = 1,
		showDefaultConfig = true
	}
	
	page:createOnOffButton{
        label = "Reflect Scaling in Spellmaker",
		description = "Whether or not to show the altered cost in parentheses next to the base cost while using the spellmaker. \n\nDefault: On",
        variable = mwse.mcm.createTableVariable{
			id = "enableSpellmakerChanges",
			table = config
		},
		defaultSetting = true,
		showDefaultConfig = true
	}
	
	page:createOnOffButton{
        label = "Enable Hostile Spell Scaling",
		description = "Whether or not to override spell resistance with a new formula that is primarily derived from a battle of will. 100% resistance does not necessarily grant immunity.\n\n100 - 100 * CasterWillpower / Target Willpower + Elemental Resistance \n\nDefault: On",
        variable = mwse.mcm.createTableVariable{
			id = "enableHostileSpellScaling",
			table = config
		},
		defaultSetting = true,
		showDefaultConfig = true
	}
	
	page:createSlider{
		label = "Resist Formula Percentage",
		description = "Scales the impact of willpower on hostile spell power and resistance. \n\nDefault: 100",
		min = 10,
        max = 200,
        step = 1,
        jump = 20,
		variable = mwse.mcm.createTableVariable{
			id = "resistPercent",
			table = config
		},
	    defaultSetting = 100,
	    showDefaultConfig = true
	}
	
	page:createOnOffButton{
        label = "Enable Passive Spell Scaling",
		description = "Whether or not to allow non-harmful spells and powers to scale with willpower. It will multiply the magnitude.of the spell by 1 + (Willpower - 50 / Dividend).  \n\nDefault: On",
        variable = mwse.mcm.createTableVariable{
			id = "enablePassiveSpellScaling",
			table = config
		},
		defaultSetting = true,
		showDefaultConfig = true
	}
	
	page:createSlider{
		label = "Passive Spell Scaling Dividend",
		description = "The number to divide by when determining the multiplier of non-harmful spells and powers. \n\nThe multiplier is 1 + (Willpower - 50 / Dividend). \n\nThe default setting of 50 makse the multiplier equivalent to Willpower/50. \n\n Set it to 100 to make it identical to the damage multiplier strength provides. \n\nDefault: 50",
		min = 10,
        max = 200,
        step = 1,
        jump = 20,
		variable = mwse.mcm.createTableVariable{
			id = "passivePowerDividend",
			table = config
		},
	    defaultSetting = 50,
	    showDefaultConfig = true
	}
	
	page:createOnOffButton{
        label = "Fixed Enchantment Willpower",
        variable = mwse.mcm.createTableVariable{
		description = "Whether or not to set a static willpower value for enchanted items. If you turn this off, then enchanted items will use the spellcaster's willpower instead of the value set below. \n\nThis setting applies to both hostile and passive spell scaling. \n\nDefault: On",
			id = "useEnchantPower",
			table = config
        },
	   defaultSetting = true,
	   showDefaultConfig = true
	}
	
	page:createSlider{
		label = "Trap Willpower",
		description = "Determines the Willpower used by traps. \n\nDefault: 100",
		min = 5,
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
		min = 5,
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



--Spell Cost Scaling Functions

local function calcSpellCost(spellSkill, magickaCost)
	local formula = config.costFormPC
	local newCost = magickaCost
	
	if (formula == 1 and spellSkill <= 100) then
		newCost = math.ceil(magickaCost * 5 * math.exp(-0.03218875*spellSkill))
	elseif (formula == 2 and spellSkill <= 100) then
		newCost = math.ceil(magickaCost * (-0.008*spellSkill + 1))
	elseif (formula == 3 and spellSkill <= 100) then
		newCost = math.ceil(magickaCost * 10 * math.exp(-0.0391202*spellSkill))
	elseif (formula == 4 and spellSkill <= 100) then
		newCost = math.ceil(magickaCost * (-0.018*spellSkill + 2))
	elseif (formula == 5 and spellSkill <= 100) then
		newCost = math.ceil(magickaCost * (-1 * ((spellSkill/50 - 3)^(-2)) + 1.2))
	elseif (spellSkill > 100 and spellSkill <= 200) then
		newCost = math.ceil(magickaCost * (-0.001*spellSkill + 0.3))
	elseif (spellSkill > 200) then 
		newCost = math.ceil(magickaCost * 0.1) 
	end
	if (newCost < 1) then newCost = 1 end
	
	return newCost
end

local function setCostPlayer(leastSchool, magickaCost)
	local spellSkill = 60
	local newCost = magickaCost
	local skipCalc = false
	
	if formula == 0 then skipCalc = true end
	
	if (leastSchool == 0) then spellSkill = tes3.mobilePlayer.alteration.current
	elseif (leastSchool == 1) then spellSkill = tes3.mobilePlayer.conjuration.current
	elseif (leastSchool == 2) then spellSkill = tes3.mobilePlayer.destruction.current
	elseif (leastSchool == 3) then spellSkill = tes3.mobilePlayer.illusion.current
	elseif (leastSchool == 4) then spellSkill = tes3.mobilePlayer.mysticism.current
	elseif (leastSchool == 5) then spellSkill = tes3.mobilePlayer.restoration.current
	else skipCalc = true end -- Indicates that the spell is not of one of the vanilla schools, and therefore should be excluded
	
	if (skipCalc == false) then
		newCost = calcSpellCost(spellSkill, magickaCost)
	end
	
	return newCost
end

local function setCostNPC(leastSchool, magickaCost, caster)
	local spellSkill = 60
	local newCost = magickaCost
	local formula = config.costFormNPC
	local skipCalc = false
	
	if formula == 0 then skipCalc = true end
	
	if (leastSchool == 0) then spellSkill = caster.mobile.alteration.current
	elseif (leastSchool == 1) then spellSkill = caster.mobile.conjuration.current
	elseif (leastSchool == 2) then spellSkill = caster.mobile.destruction.current
	elseif (leastSchool == 3) then spellSkill = caster.mobile.illusion.current
	elseif (leastSchool == 4) then spellSkill = caster.mobile.mysticism.current
	elseif (leastSchool == 5) then spellSkill = caster.mobile.restoration.current
	else skipCalc = true end 
	
	if skipCalc == false then
		calcSpellCost(spellSkill, magickaCost)
		-- Idiot-proofing NPCs since I cannot force them to understand the dynamic spell costs
		if (newCost > caster.mobile.magicka.current and magickaCost <= caster.mobile.magicka.current) then newCost = caster.mobile.magicka.current end
	end
	
	return newCost
end

--Change the actual cost of spells

local function alterMagickaCosts(e)
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
event.register(tes3.event.spellMagickaUse, alterMagickaCosts)

--Edit the magic menu to reflect the altered costs

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

--Edit the spellmaker to show the adjusted cost in addition to the base cost

local function updateSpellmakerCost(e)
	local spellmaker = tes3ui.findMenu("MenuSpellmaking")
	if (config.enableSpellmakerChanges == true) then
		--Seems I have to find the least proficient school manually
		local spellMenu = spellmaker:findChild("MenuSpellmaking_SpellEffectsLayout")
		local spellEffects = spellMenu:findChild("PartScrollPane_pane").children
		local skill = {}
		for i=1, #spellEffects do
			local school = spellEffects[i]:getPropertyObject("MenuSpellmaking_Effect").school
			if (school == 0) then skill[i] = tes3.mobilePlayer.alteration.current
			elseif (school == 1) then skill[i] = tes3.mobilePlayer.conjuration.current
			elseif (school == 2) then skill[i] = tes3.mobilePlayer.destruction.current
			elseif (school == 3) then skill[i] = tes3.mobilePlayer.illusion.current
			elseif (school == 4) then skill[i] = tes3.mobilePlayer.mysticism.current
			elseif (school == 5) then skill[i] = tes3.mobilePlayer.restoration.current
			end
		end
		local leastSchool = math.min(unpack(skill))
		
		local baseCost = math.floor(e.spellPointCost)
		local newCost = calcSpellCost(leastSchool, baseCost)
		timer.start {
			type = timer.real, duration = 0.01, callback = function()
			spellmaker:findChild("MenuSpellmaking_SpellPointCost").text = tostring(newCost) .. " (" .. tostring(baseCost) .. ")"
		end }
	end
end

event.register(tes3.event.calcSpellmakingSpellPointCost, updateSpellmakerCost)



--Hostile Spell Effectiveness

local function hostileSpellScaling(e)
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
event.register(tes3.event.spellResist, hostileSpellScaling)



-- Passive Spell Multiplie

-- I have to do a manual hostility check because MWSE always calims effects[i].object is a nil value, which makes no sense whatsoever considering that all the other tes3spell properties work just fine

local function passiveSpellScaling(e)
	if ((config.enablePassiveSpellScaling == true) and (e.source.castType == 0 or e.source.castType == 5)) then
		local spell = e.source
		local effects = spell.effects
		local power = 1 + (e.caster.mobile.willpower.current - 50) / config.passivePowerDividend
		local blacklist = { 7, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 45, 46, 47, 48, 49, 50, 51, 52, 53, 53, 54, 57, 58, 60, 61, 62, 63, 85, 86, 87, 88, 89, 101, 118, 119, 132, 133, 135, 136, 220, 263, 323, 324, 328, 329, 331, 334, 400, 401, 402, 403, 404, 405, 517, 518, 519, 520, 521, 522, 523, 524, 525, 526, 527, 528, 529, 530, 531, 532, 533, 534, 535, 536, 537, 538, 539, 540, 541, 542, 543, 544, 545, 546, 547, 548, 549, 550, 551, 552, 553, 554, 555, 786, 900, 901, 902, 1201, 1813, 2136, 2137, 2138, 2140, 10000, 23236 }
		local blacklisted = {}
		local mins = {}
		local maxs = {}
		if (spell.castType == 0 or spell.castType == 5) then
			for i=1, #effects do
				blacklisted[i] = false
				for _, v in ipairs(blacklist) do
					if (v == effects[i].id) then 
						blacklisted[i] = true
						break
					end
				end
				if (blacklisted[i] == false) then
					mins[i] = effects[i].min
					maxs[i] = effects[i].max
					effects[i].min = effects[i].max * power
					effects[i].max = effects[i].max * power
				end
			end
			timer.start {
				type = timer.real, duration = 0.10, callback = function()
				for i=1, #effects do
					if (blacklisted[i] == false) then
						effects[i].min = mins[i]
						effects[i].max = maxs[i]
					end
				end
			end }
		end
	end
end
event.register(tes3.event.spellCasted, passiveSpellScaling)

local function passiveSpellScalingEnchantments(e)
	if (config.enablePassiveSpellScaling == true and e.isCast == true) then
		local spell = e.source
		local effects = spell.effects
		local power
		if (config.useEnchantPower == true) then
			power = 1 + (config.enchantPower - 50) / config.passivePowerDividend
		else
			power = 1 + (e.caster.mobile.willpower.current - 50) / config.passivePowerDividend
		end
		local blacklist = { 7, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 45, 46, 47, 48, 49, 50, 51, 52, 53, 53, 54, 57, 58, 60, 61, 62, 63, 85, 86, 87, 88, 89, 101, 118, 119, 132, 133, 135, 136, 220, 263, 323, 324, 328, 329, 331, 334, 400, 401, 402, 403, 404, 405, 517, 518, 519, 520, 521, 522, 523, 524, 525, 526, 527, 528, 529, 530, 531, 532, 533, 534, 535, 536, 537, 538, 539, 540, 541, 542, 543, 544, 545, 546, 547, 548, 549, 550, 551, 552, 553, 554, 555, 786, 900, 901, 902, 1201, 1813, 2136, 2137, 2138, 2140, 10000, 23236 }
		local blacklisted = {}
		local mins = {}
		local maxs = {}
		for i=1, #effects do
			blacklisted[i] = false
			for _, v in ipairs(blacklist) do
				if (v == effects[i].id) then 
					blacklisted[i] = true
					break
				end
			end
			if (blacklisted[i] == false) then
				mins[i] = effects[i].min
				maxs[i] = effects[i].max
				effects[i].min = effects[i].max * power
				effects[i].max = effects[i].max * power
			end
		end
		timer.start {
			type = timer.real, duration = 0.10, callback = function()
			for i=1, #effects do
				if (blacklisted[i] == false) then
					effects[i].min = mins[i]
					effects[i].max = maxs[i]
				end
			end
		end }
	end
end
event.register(tes3.event.enchantChargeUse, passiveSpellScalingEnchantments)