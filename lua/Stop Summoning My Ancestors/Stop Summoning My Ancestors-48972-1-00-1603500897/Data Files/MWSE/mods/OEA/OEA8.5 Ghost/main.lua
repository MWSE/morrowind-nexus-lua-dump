local function onLoaded(e)
	tes3.player.data.OEA812 = {}

	for object in tes3.iterateObjects({tes3.objectType.spell, tes3.objectType.enchantment, tes3.objectType.alchemy}) do
		if (object.effects) then
			for i=1, 8 do
				if (object.effects[i]) then
					if (object.effects[i].id == tes3.effect.summonAncestralGhost) then
						object.effects[i].id = tes3.effect.summonScamp
						if (object.id ~= "ancestor guardian") then
							tes3.player.data.OEA812[object.id] = 1
						end
					end
				end
			end
		end
	end

	local effect = tes3.dataHandler.nonDynamicData.magicEffects[107]
	effect.allowSpellmaking = false
	effect.allowEnchanting = false

	local DunmerPower = tes3.getObject("ancestor guardian")
	DunmerPower.name = "Ancestor Guardians"
	DunmerPower.magickaCost = 0
	DunmerPower.castType = tes3.spellType.power

	DunmerPower.effects[1].id = tes3.effect.summonAncestralGhost
	DunmerPower.effects[1].rangeType = tes3.effectRange.self
	DunmerPower.effects[1].min = nil
	DunmerPower.effects[1].max = nil
	DunmerPower.effects[1].duration = 30
	DunmerPower.effects[1].radius = 0
	DunmerPower.effects[1].skill = nil
	DunmerPower.effects[1].attribute = nil

	DunmerPower.effects[2].id = tes3.effect.summonAncestralGhost
	DunmerPower.effects[2].rangeType = tes3.effectRange.self
	DunmerPower.effects[2].min = nil
	DunmerPower.effects[2].max = nil
	DunmerPower.effects[2].duration = 30
	DunmerPower.effects[2].radius = 0
	DunmerPower.effects[2].skill = nil
	DunmerPower.effects[2].attribute = nil

	DunmerPower.effects[3].id = tes3.effect.summonAncestralGhost
	DunmerPower.effects[3].rangeType = tes3.effectRange.self
	DunmerPower.effects[3].min = nil
	DunmerPower.effects[3].max = nil
	DunmerPower.effects[3].duration = 30
	DunmerPower.effects[3].radius = 0
	DunmerPower.effects[3].skill = nil
	DunmerPower.effects[3].attribute = nil

	DunmerPower.effects[4].id = -1
	DunmerPower.effects[5].id = -1
	DunmerPower.effects[6].id = -1
	DunmerPower.effects[7].id = -1
	DunmerPower.effects[8].id = -1

	mwse.log("[OEA8.5] Initialized.")
end

local function CellChanged(e)
	for npc in e.cell:iterateReferences(tes3.objectType.npc) do
		for spell, _ in pairs(tes3.player.data.OEA812) do
			local Spell = tes3.getObject(spell)
			mwscript.removeSpell({ reference = npc.id, spell = Spell })
		end
	end
end

event.register("loaded", onLoaded)
event.register("cellChanged", CellChanged)