-- Thanks to NullCascade for UI Expansion, which is where I took this from.

local this = {}

--- Fills out a known effects table, given a spell list.
--- @param knownEffects table<number, boolean>
--- @param spellList tes3spellList
local function fillKnownEffectsTable(knownEffects, spellList)
	-- Some pointers can be nil.
	if (not spellList) then
		return
	end

	-- Check the list's iterator. Filter anything that isn't a normal spell.
	for _, spell in ipairs(spellList.iterator) do
		if (spell.castType == tes3.spellType.spell) then
			for _, effect in ipairs(spell.effects) do
				knownEffects[effect.id] = true
			end
		end
	end
end

--- Creates a known effects table for a given mobile. This table will use keys for effect ids, with a value of true if
--- the effect is known.
---
--- Effects are gathered from primary known spells, racial abilities, and birthsigns.
--- @param mobile tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
--- @return table<number, boolean>
function this.getKnownEffectsTable(mobile)
	local knownEffects = {} --- @type table<number, boolean>

	fillKnownEffectsTable(knownEffects, mobile.object.spells)

	local race = mobile.object.race
	if (race) then
		fillKnownEffectsTable(knownEffects, race.abilities)
	end

	local birthsign = mobile.birthsign
	if (birthsign) then
		fillKnownEffectsTable(knownEffects, birthsign.spells)
	end

	knownEffects[-1] = true

	return knownEffects
end

--- Checks to see if all effects are known in a given spell. This is compared to a knownEffects table, created above.
--- @param knownEffects table<number, boolean>
--- @param spell tes3spell
--- @return boolean
function this.getKnowsAllSpellEffects(knownEffects, spell)
	for _, effect in ipairs(spell.effects) do
		if (not knownEffects[effect.id]) then
			return false
		end
	end
	return true
end

return this