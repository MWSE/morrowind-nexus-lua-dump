local world = require('openmw.world')
local core	= require('openmw.core')
local types = require('openmw.types')
local I		= require('openmw.interfaces')

-- [InfuseSoulGems .. "_PickUp"]       = pickUpInfuser
-- for picking up soul gem infusor with a spell

I.Activation.addHandlerForType(types.NPC, function(npc, player)
	local npcIsSpellVendor = npc.type.record(npc).servicesOffered.Spells
	local npcIsTrainer = npc.type.record(npc).servicesOffered.Training
	
	if not npcIsSpellVendor or not npcIsTrainer then return end

    local picked = {}
    for i = 1, 3 do
        local bestId, bestVal = nil, -1
        for _, skill in pairs(core.stats.Skill.records) do
            if not picked[skill.id] then
                local value = types.NPC.stats.skills[skill.id](npc).base
                if value > bestVal then
                    bestId = skill.id
                    bestVal = value
                end
            end
        end
        if not bestId then break end
        picked[bestId] = bestVal
    end
	if picked["alteration"] then 
		types.NPC.spells(npc):add("transmute_ore_l")
		if picked["alteration"] >= 50 then
			types.NPC.spells(npc):add("transmute_ore_gr")
		end
	end
end)

local transmuteMap = {
	["t_ingmine_oreiron_01"] = "t_ingmine_oresilver_01",
	["t_ingmine_oresilver_01"] = "t_ingmine_oregold_01",
	["t_ingmine_oregold_01"] = "t_ingmine_oreiron_01",
}

local transmutePriorities = { "t_ingmine_oreiron_01", "t_ingmine_oresilver_01" }

local function transmuteOreInventory(data)
	local player = data.player
	local inv = player.type.inventory(player)
	
	for i, oreRecordId in ipairs(transmutePriorities) do
		local oreObject = inv:find(oreRecordId)
		if oreObject then
			local oreCount = oreObject.count
			if oreCount >= 2 then
				oreObject:remove(2)
				
				local newObject = world.createObject(transmuteMap[oreRecordId], 1)
				newObject:moveInto(inv)
				local oreName = types.Ingredient.records[oreRecordId].name
				player:sendEvent("showMessage", { message = "Transmuted "..oreName })
				return
			end
		end
	end
	player:sendEvent("showMessage", { message = "You don't have enough ore to transmute."})
end

local function transmuteOreRaycast(data)
	local player = data.player
	local target = data.target
	local newRecordId = data.newRecordId

	if not target or not target:isValid() or target.count < 1 then return end

	local pos = target.position
	local cell = target.cell
	local rotation = target.rotation
	local count = target.count
	
	world.vfx.spawn(
		"meshes/e/magic_area_alt.nif",
		target:getBoundingBox().center,
		{scale = 1}
	)

	target:remove()

	local newObject = world.createObject(newRecordId, count)
	newObject:teleport(cell, pos, { rotation = rotation })
end

local function onCreatureActivated(creature, actor)
    if creature.recordId:find("scrib") then
		actor:sendEvent("US_scribActivated", creature)
		if creature.recordId == "scrib_summon" and creature.scale < 1.5 then
			local currentHealth = creature.type.stats.dynamic.health(creature).current
			local baseHealth = creature.type.stats.dynamic.health(creature).base
			local healthMissing = baseHealth - currentHealth
			local healing = math.min(10, healthMissing)
			if healing > 0 then
				creature:sendEvent('ModifyStat', {stat = 'health', amount = healing})
			end
			creature:setScale(math.min(1.5, creature.scale + 0.05))
		end	
	end
end

I.Activation.addHandlerForType(types.Creature, onCreatureActivated)

--local function SimplyMining_setNodeSize(data)
--    local object = data[1]
--    local size = data[2]        -- remaining fraction 0-1
--    local progressed = data[3]  -- how much was just mined (0-1 fraction)
--    local currentProgress = data[4]
--    local usedSkill = data[5]
--    local skillLevel = data[6]
--	local player = data[7]
--	
--	if player then
--		player:sendEvent("UtilitySpells_miningProgress", data)
--	else
--		world.players[1]:sendEvent("UtilitySpells_miningProgress", data)
--	end
--end

return {
	eventHandlers = {
		TransmuteOre_transmute_gr = transmuteOreRaycast,
		TransmuteOre_transmute_l = transmuteOreInventory,
--		SimplyMining_setNodeSize = SimplyMining_setNodeSize,
	},
}