local config = require("castReduce.config")
mwse.log("[Cast Reduce MWSE-Lua] Initialized Version 1.0")

-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
    require("castReduce.mcm")
end)



local function spellMagickaUseCallback(e)
	local casterRef = e.caster
	local spellSource = e.spell
	local castRestore = spellSource.magickaCost
    if (e.caster ~= tes3.player) then
        return
    end
	local leastSchool = spellSource:getLeastProficientSchool(tes3.player)
	if(leastSchool == 0) then
		local spellAmount = tes3.mobilePlayer.alteration.current
		castRestore = spellSource.magickaCost * ((config.spellReductionCost/100) * (spellAmount/100))
	end
	if(leastSchool == 1) then
		local spellAmount = tes3.mobilePlayer.conjuration.current
		castRestore = spellSource.magickaCost * ((config.spellReductionCost/100) * (spellAmount/100))	
	end
	if(leastSchool == 2) then
		local spellAmount = tes3.mobilePlayer.destruction.current
		castRestore = spellSource.magickaCost * ((config.spellReductionCost/100) * (spellAmount/100))	
	end
	if(leastSchool == 3) then
		local spellAmount = tes3.mobilePlayer.alteration.current
		castRestore = spellSource.magickaCost * ((config.spellReductionCost/100) * (spellAmount/100))	
	end
	if(leastSchool == 4) then
		local spellAmount = tes3.mobilePlayer.alteration.current
		castRestore = spellSource.magickaCost * ((config.spellReductionCost/100) * (spellAmount/100))	
	end
	if(leastSchool == 5) then
		local spellAmount = tes3.mobilePlayer.alteration.current
		castRestore = spellSource.magickaCost * ((config.spellReductionCost/100) * (spellAmount/100))		
	end
	if(castRestore > spellSource.magickaCost) then
		castRestore = spellSource.magickaCost
	end
	e.cost = e.cost - castRestore

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
			if(leastSchool == 0) then
				local spellAmount = tes3.mobilePlayer.alteration.current
				castRestore = spell.magickaCost * ((config.spellReductionCost/100) * (spellAmount/100))
			end
			if(leastSchool == 1) then
				local spellAmount = tes3.mobilePlayer.conjuration.current
				castRestore = spell.magickaCost * ((config.spellReductionCost/100) * (spellAmount/100))	
			end
			if(leastSchool == 2) then
				local spellAmount = tes3.mobilePlayer.destruction.current
				castRestore = spell.magickaCost * ((config.spellReductionCost/100) * (spellAmount/100))	
			end
			if(leastSchool == 3) then
				local spellAmount = tes3.mobilePlayer.alteration.current
				castRestore = spell.magickaCost * ((config.spellReductionCost/100) * (spellAmount/100))	
			end
			if(leastSchool == 4) then
				local spellAmount = tes3.mobilePlayer.alteration.current
				castRestore = spell.magickaCost * ((config.spellReductionCost/100) * (spellAmount/100))	
			end
			if(leastSchool == 5) then
				local spellAmount = tes3.mobilePlayer.alteration.current
				castRestore = spell.magickaCost * ((config.spellReductionCost/100) * (spellAmount/100))		
			end
			if(castRestore > spell.magickaCost) then
				castRestore = spell.magickaCost
			end
        child.text = string.format("%d", spell.magickaCost - castRestore)
    end
	
    local chances = e.source:findChild("MagicMenu_spell_percents") --- @chances tes3uiElement
    for _, child in ipairs(chances.children) do
        local spell = child:getPropertyObject("MagicMenu_Spell")
			local leastSchool = spell:getLeastProficientSchool(tes3.player)
			if(leastSchool == 0) then
				local spellAmount = tes3.mobilePlayer.alteration.current
				castRestore = spell.magickaCost * ((config.spellReductionCost/100) * (spellAmount/100))
			end
			if(leastSchool == 1) then
				local spellAmount = tes3.mobilePlayer.conjuration.current
				castRestore = spell.magickaCost * ((config.spellReductionCost/100) * (spellAmount/100))	
			end
			if(leastSchool == 2) then
				local spellAmount = tes3.mobilePlayer.destruction.current
				castRestore = spell.magickaCost * ((config.spellReductionCost/100) * (spellAmount/100))	
			end
			if(leastSchool == 3) then
				local spellAmount = tes3.mobilePlayer.alteration.current
				castRestore = spell.magickaCost * ((config.spellReductionCost/100) * (spellAmount/100))	
			end
			if(leastSchool == 4) then
				local spellAmount = tes3.mobilePlayer.alteration.current
				castRestore = spell.magickaCost * ((config.spellReductionCost/100) * (spellAmount/100))	
			end
			if(leastSchool == 5) then
				local spellAmount = tes3.mobilePlayer.alteration.current
				castRestore = spell.magickaCost * ((config.spellReductionCost/100) * (spellAmount/100))		
			end
			if(castRestore > spell.magickaCost) then
				castRestore = spell.magickaCost
			end
		local spellCost = spell.magickaCost - castRestore
		if(spellCost < tes3.mobilePlayer.magicka.current) then
			child.text = "/" .. string.format("%d", spell:calculateCastChance({ checkMagicka = false, caster = tes3.player })) 
		end
    end	
end

--- @param e uiActivatedEventData
local function onMagicMenuActivated(e)
    if (not e.newlyCreated) then
        return
    end

    -- We need to know when the spell list is updated.
    e.element:registerAfter("preUpdate", updateSpellCosts)
end
event.register(tes3.event.uiActivated, onMagicMenuActivated, { filter = "MenuMagic" })