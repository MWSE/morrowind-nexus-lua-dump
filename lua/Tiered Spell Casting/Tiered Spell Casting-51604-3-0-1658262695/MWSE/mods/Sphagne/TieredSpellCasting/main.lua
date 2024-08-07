--[[
    Tiered Spell Casting
    Author: Sphagne
	Credits: OperatorJack, MageKing17, HotFusion4, JaceyS, Greatness7 & NullCascade
--]]

--- - Configuration Settings -- ---

local config = require("Sphagne.TieredSpellCasting.config")

--- --- Check MWSE Version  --- ---

if (mwse.buildDate == nil) or (mwse.buildDate < 20200122) then
    local function warning()
        tes3.messageBox(
            "[Tiered Spell Casting ERROR] MWSE is out of date!"
            .. " Please update to a newer version"
        )
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end

--- --- Spell Mastery Tiers --- ---

local smTiers = {
    [1] = "Cantrip",
    [2] = "Novice",
    [3] = "Apprentice",
    [4] = "Journeyman",
    [5] = "Adept",
    [6] = "Expert",
    [7] = "Master",
    [8] = "Grand Master"
}

--- --- Caster Mastery Tiers -- ---

local cmTiers = {
    [1] = "Initiate",
    [2] = "Novice",
    [3] = "Apprentice",
    [4] = "Journeyman",
    [5] = "Adept",
    [6] = "Expert",
    [7] = "Master",
    [8] = "Grand Master"
}

--- Success Experience by Tier  ---

local xpSuccess = {
    [1] = 1,
    [2] = 2,
    [3] = 4,
    [4] = 6,
    [5] = 9,
    [6] = 12,
    [7] = 16,
    [8] = 20
}

--- Failure Experience by Tier  ---

local xpFailure = {
    [1] = 0.2,
    [2] = 0.3,
    [3] = 0.5,
    [4] = 0.7,
    [5] = 1.0,
    [6] = 1.3,
    [7] = 1.6,
    [8] = 2.0
}

--- --- Spell Tier by Cost  --- ---

local function getSpellTier(cost)
    if (cost < 10) then
        return 1
    elseif (cost < 20) then
        return 2
    elseif (cost < 40) then
        return 3
    elseif (cost < 70) then
        return 4
    elseif (cost < 110) then
        return 5
    elseif (cost < 160) then
        return 6
    elseif (cost < 220) then
        return 7
    else
        return 8
    end
end

-- Caster Mastery by Skill Level --

local function getCasterTier(skill)
	if (config.levUncapped) then	-- Uncapped games
		
		if (skill < 15) then
			return 1
		elseif (skill < 30) then
			return 2
		elseif (skill < 50) then
			return 3
		elseif (skill < 75) then
			return 4
		elseif (skill < 100) then
			return 5
		elseif (skill < 125) then
			return 6
		elseif (skill < 150) then
			return 7
		else
			return 8
		end
		
	else	-- Capped games
		
		if (skill < 15) then
			return 1
		elseif (skill < 30) then
			return 2
		elseif (skill < 45) then
			return 3
		elseif (skill < 60) then
			return 4
		elseif (skill < 75) then
			return 5
		elseif (skill < 90) then
			return 6
		elseif (skill <= 100) then
			return 7
		else
			return 8
		end
		
	end
end

--- --- - Cost Alter Text - --- ---

local function getCostAlterText(alter)
    if (alter > 0) then
		return "%" .. (10 * alter)
	else
		return "None"
	end
end

--- - Cost Reduction by Tiers - ---

local function getCostReduction(casterTier, spellTier)
    local dif = 0
	
	if (config.redCostLoTier) then
		dif = math.max(0, casterTier - spellTier)
	end
	
    local mas = 0
	
	if (config.redCostHiMastery) and (casterTier >= spellTier) then
		mas = math.max(0, casterTier - 3)  -- 3 is Apprentice level tier
	end
	
    return math.max(dif, mas)
end

--- -- Spell Penalty by Tiers - ---

local function getChancePenalty(casterTier, spellTier)
	if (config.penChanceHiTier) then
		return math.clamp(spellTier - casterTier, 0, 3)
	else
		return 0
	end
end

local function getCostPenalty(casterTier, spellTier)
	if (config.penCostHiTier) then
		return math.max(0, spellTier - casterTier)
	else
		return 0
	end
end

--- Spell Casting Chance Penalty --

local penalties = {
    [1] = "Moderate",
    [2] = "Severe",
    [3] = "Impossible"
}

--- --- --- --- --- --- --- --- ---
--- --- -- Spell Tooltips - --- ---
--- --- --- --- --- --- --- --- ---

local function onUiSpellTooltip(e)
	
    local spell = e.spell
	
    if spell.castType ~= tes3.spellType.spell then
        -- Tooltip for spells only --
       return
    end
	
	local cost = spell.magickaCost
	
    if (cost <= 0) then
        -- Ignore zero cost spells --
        return
    end
	
    local caster = tes3.mobilePlayer
	local school = spell:getLeastProficientSchool(caster)
	school = tes3.magicSchoolSkill[school]
	local skill = caster.skills[school + 1].current
	
	local casterTier = getCasterTier(skill)
	local spellTier = getSpellTier(cost)
	
    local outerBlock = e.tooltip:createBlock()
	outerBlock.flowDirection = "top_to_bottom"
    outerBlock.widthProportional = 1
    outerBlock.autoHeight = true
    outerBlock.borderAllSides = 4
	
    outerBlock:createDivider()
	
    local innerBlock1 = outerBlock:createBlock()
	innerBlock1.flowDirection = "left_to_right"
    innerBlock1.widthProportional = 1
    innerBlock1.autoHeight = true
    innerBlock1.borderAllSides = 0

        local smText = "Spell Tier: " .. smTiers[spellTier] .. "                (XP per cast: " .. xpSuccess[spellTier] .. ")"
        local smLabel = innerBlock1:createLabel({ text = smText })
        smLabel.borderAllSides = 4
	
    local innerBlock2 = outerBlock:createBlock()
    innerBlock2.flowDirection = "left_to_right"
    innerBlock2.widthProportional = 1
    innerBlock2.autoHeight = true
    innerBlock2.borderAllSides = 0 

        local cmText = "Caster Mastery: " .. cmTiers[casterTier]
        local cmLabel = innerBlock2:createLabel({ text = cmText })
        cmLabel.borderAllSides = 4
	
	local penChance = getChancePenalty(casterTier, spellTier)
	
	if (penChance > 0) then		-- Casting Chance Penalty
		
		local innerBlock = outerBlock:createBlock()
		innerBlock.flowDirection = "left_to_right"
		innerBlock.widthProportional = 1
		innerBlock.autoHeight = true
		innerBlock.borderAllSides = 0
		
		local efText = "Casting chance penalty: " .. penalties[penChance]
		local efLabel = innerBlock:createLabel({ text = efText })
		
		efLabel.color = tes3ui.getPalette("negative_color")
        efLabel.borderAllSides = 4
		
	end
	
	local penCost = getCostPenalty(casterTier, spellTier)
	
	if (penCost > 0) then		-- Spell Cost Penalty
		
		local innerBlock = outerBlock:createBlock()
		innerBlock.flowDirection = "left_to_right"
		innerBlock.widthProportional = 1
		innerBlock.autoHeight = true
		innerBlock.borderAllSides = 0
		
		local efText = "Spell Cost penalty: " .. getCostAlterText(penCost)
		local efLabel = innerBlock:createLabel({ text = efText })
		
		efLabel.color = tes3ui.getPalette("negative_color")
        efLabel.borderAllSides = 4
		
	end
	
	local redCost = getCostReduction(casterTier, spellTier)
	
	if (redCost > 0) then		-- Spell Cost Recuction
		
		local innerBlock = outerBlock:createBlock()
		innerBlock.flowDirection = "left_to_right"
		innerBlock.widthProportional = 1
		innerBlock.autoHeight = true
		innerBlock.borderAllSides = 0
		
		local efText = "Spell cost reduction: " .. getCostAlterText(redCost)
		local efLabel = innerBlock:createLabel({ text = efText })
		
		efLabel.color = tes3ui.getPalette("positive_color")
        efLabel.borderAllSides = 4
		
	end
	
end

event.register("uiSpellTooltip", onUiSpellTooltip)

--- --- --- --- --- --- --- --- ---
--- --- -- Spell Casting -- --- ---
--- --- --- --- --- --- --- --- ---

local function onSpellCast(e)
	if (config.penChanceHiTier == false) then
        -- Only for spell chance penalty --
        return
	end
	
    if e.source.castType ~= tes3.spellType.spell then
        -- Process spells only --
        return
    end

    if e.caster.object.objectType ~= tes3.objectType.npc then
        -- Ignore creature casters --
        return
    end

    local cost = e.source.magickaCost
	
    if cost <= 0 then
        -- Ignore zero cost spells --
        return
    end

    local caster = e.caster.mobile
	local school = tes3.magicSchoolSkill[e.weakestSchool]
	local skill = caster.skills[school + 1].current
	
	local casterTier = getCasterTier(skill)
	local spellTier = getSpellTier(cost)
	
    -- Cost penalty --
	
	local penalty = getChancePenalty(casterTier, spellTier)

    if (penalty > 0) then
		local newChance = 0.33 * (3 - penalty) * e.castChance
        e.castChance = newChance
    end
end

event.register("spellCast", onSpellCast)

--- --- -- Spell Casted  -- --- ---

local function onSpellCasted(e)
    if e.source.castType ~= tes3.spellType.spell then
        -- Process spells only --
        return
    end

    if e.caster.object.objectType ~= tes3.objectType.npc then
        -- Ignore creature casters --
        return
    end

    local cost = e.source.magickaCost
	
    if cost <= 0 then
        -- Ignore zero cost spells --
        return
    end

    local caster = e.caster.mobile
	local school = tes3.magicSchoolSkill[e.expGainSchool]
	local skill = caster.skills[school + 1].current
	
	local casterTier = getCasterTier(skill)
	local spellTier = getSpellTier(cost)
	
	local reduction = getCostReduction(casterTier, spellTier)
	
	if (reduction > 0) then
		-- Replenish magicka --
		local newMagicka = caster.magicka.current + (cost * (0.1 * reduction))
		tes3.setStatistic{reference=e.caster, name="magicka", current=newMagicka}
	end
	
	local penalty = getCostPenalty(casterTier, spellTier)
	
	if (penalty > 0) then
		-- Cost more magicka --
		local newMagicka = math.max(0, caster.magicka.current - (cost * (0.1 * penalty)))
		tes3.setStatistic{reference=e.caster, name="magicka", current=newMagicka}
	end
	
    -- Player experience --
	
    if caster == tes3.mobilePlayer then
        -- Prevent vanilla experience method --
        e.expGainSchool = tes3.magicSchool.none

        if e.eventType == "spellCasted" then
            caster:exerciseSkill(school, xpSuccess[spellTier])
        else -- spellCastedFailure --
            caster:exerciseSkill(school, xpFailure[spellTier])
        end
    end
end

event.register("spellCasted", onSpellCasted)
event.register("spellCastedFailure", onSpellCasted)

--- --- --- --- --- --- --- --- ---
--- --- --- Initialize  --- --- ---
--- --- --- --- --- --- --- --- ---

local function initialized()
	-- Show initialization event in the log.
	mwse.log("[Tiered Spell Casting] Mod initialized with configuration:")
	mwse.log(json.encode(config, { indent = true }))
end

event.register("initialized", initialized)

--- --- --- --- --- --- --- --- ---
--- --- --- MCM Register -- --- ---
--- --- --- --- --- --- --- --- ---

local function registerModConfig()
	local easyMCM = include("easyMCM.modConfig")
	if (easyMCM) then
		easyMCM.registerMCM(require("Sphagne.TieredSpellCasting.mcm"))
	end
end

event.register("modConfigReady", registerModConfig)

--- --- --- --- --- --- --- --- ---