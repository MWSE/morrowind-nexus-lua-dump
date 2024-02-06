local function spellMagickaUseCallback(e)
	local casterRef = e.caster
	local spellSource = e.spell
	local castRestore = spellSource.magickaCost
    if (e.caster ~= tes3.player) then
        return
    end
		local spellAmount = tes3.mobilePlayer.conjuration.current
		local name = spellSource.name:lower()
		if (name:lower():startswith("summon ")) then
		castRestore = spellSource.magickaCost * 2
		e.cost = castRestore
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
				local name = spell.name:lower()
				if (name:lower():startswith("summon ")) then
				local spellAmount = tes3.mobilePlayer.conjuration.current
				castRestore = spell.magickaCost * 2	
				child.text = string.format("%d", castRestore)
				end
    end
	
    local chances = e.source:findChild("MagicMenu_spell_percents") --- @chances tes3uiElement
    for _, child in ipairs(chances.children) do
        local spell = child:getPropertyObject("MagicMenu_Spell")
				local name = spell.name:lower()
				if (name:lower():startswith("summon ")) then
				local spellAmount = tes3.mobilePlayer.conjuration.current
				castRestore = spell.magickaCost * 2
			
		local spellCost = castRestore
			
			child.text = "/" .. string.format("%d", math.clamp(spell:calculateCastChance({ checkMagicka = false, caster = tes3.player }), 0, 100)) 
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