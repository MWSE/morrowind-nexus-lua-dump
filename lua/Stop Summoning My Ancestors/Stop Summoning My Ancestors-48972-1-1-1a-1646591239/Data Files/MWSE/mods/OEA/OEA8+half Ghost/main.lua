local config = require("OEA.OEA8+half Ghost.config")

local function onLoaded(e)
	tes3.player.data.OEA812 = {}

	for object in tes3.iterateObjects({tes3.objectType.spell, tes3.objectType.enchantment, tes3.objectType.alchemy}) do
		if (object.effects) then
			for i = 1, 8 do
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
	if (config.Ghosts > 1) then
		DunmerPower.name = "Ancestor Guardians"
	else
		DunmerPower.name = "Ancestor Guardian"
	end
	DunmerPower.magickaCost = 0
	DunmerPower.castType = tes3.spellType.power

	for i = 1, 8 do
		if (i <= config.Ghosts) then
			DunmerPower.effects[i].id = tes3.effect.summonAncestralGhost
			DunmerPower.effects[i].rangeType = tes3.effectRange.self
			DunmerPower.effects[i].min = nil
			DunmerPower.effects[i].max = nil
			DunmerPower.effects[i].duration = 30
			DunmerPower.effects[i].radius = 0
			DunmerPower.effects[i].skill = nil
			DunmerPower.effects[i].attribute = nil
		else
			DunmerPower.effects[i].id = -1
		end
	end

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

event.register("modConfigReady", function()
	require("OEA.OEA8+half Ghost.mcm")
end)