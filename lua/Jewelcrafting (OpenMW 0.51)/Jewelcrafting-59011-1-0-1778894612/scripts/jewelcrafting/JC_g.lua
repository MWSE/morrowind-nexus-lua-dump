core  = require('openmw.core')
types = require('openmw.types')
world = require('openmw.world')
util  = require('openmw.util')
async = require('openmw.async')
I     = require('openmw.interfaces')

G_testBoost = 1

G_hasSimplyMining = core.contentFiles.has("SimplyMining.omwscripts")

-- distilled view: only craftItem fallback needs the recipe level.
local recipeLevel = {}
for _, r in ipairs(require("scripts.jewelcrafting.recipes")) do
	recipeLevel[r.id:lower()] = r.level
end

G_eventHandlers  = {}
G_engineHandlers = {}

require("scripts.Jewelcrafting.JC_restocking")

------------------------------ engine handlers ------------------------------

G_engineHandlers.onLoad = function(data)
	saveData = data or {}
	saveData.restockingNPCs  = saveData.restockingNPCs  or {}
	saveData.unlockedRecipes = saveData.unlockedRecipes or {}
	saveData.playerSkill     = saveData.playerSkill     or {}
	local _, v = next(saveData.unlockedRecipes)
	if v ~= nil and type(v) ~= "table" then saveData.unlockedRecipes = {} end
end
G_engineHandlers.onInit = G_engineHandlers.onLoad
G_engineHandlers.onSave = function() return saveData end

G_eventHandlers.Test_toggleBoost = function(val)
	G_testBoost = val
end

------------------------------ event handlers ------------------------------

G_eventHandlers.Jewelcrafting_giveGem = function(data)
	local player, gemId = data[1], data[2]
	if not player or not gemId then return end
	local gem = world.createObject(gemId, 1)
	if not gem then return end
	gem:moveInto(types.Actor.inventory(player))
	local record = types.Ingredient.records[gemId] -- or types.Miscellaneous.records[gemId] no gems are misc items but ingots are
	player:sendEvent("Jewelcrafting_notifyGemFound", { record and record.name or gemId })
end

G_eventHandlers.Jewelcrafting_giveItem = function(data)
	local player, recordId, count = data[1], data[2], data[3] or 1
	if not player or not recordId then return end
	local item = world.createObject(recordId, count)
	if item then item:moveInto(types.Actor.inventory(player)) end
end

G_eventHandlers.Jewelcrafting_removeItem = function(data)
	local _, object, count = data[1], data[2], data[3] or 1
	if not object or not object:isValid() then return end
	object:remove(count)
end

G_eventHandlers.Jewelcrafting_syncUnlock = function(data)
	if not data.player or not data.recipe then return end
	local pid = data.player.id
	saveData.unlockedRecipes[pid] = saveData.unlockedRecipes[pid] or {}
	saveData.unlockedRecipes[pid][data.recipe:lower()] = true
end

G_eventHandlers.Jewelcrafting_syncSkill = function(data)
	saveData.playerSkill[data.player.id] = data.skill
end

-- scale enchantCapacity by jc + enchant skill
G_eventHandlers.Jewelcrafting_craftItem = function(data)
	if (I.CraftingFramework.version or 0) >= 3 then
		return I.CraftingFramework.craftItem(data)
	end
	local player = data.player
	if not player then return end
	local rLevel = recipeLevel[(data.recordId or ""):lower()] or 1
	local jcSkill = saveData.playerSkill[player.id] or 5
	local enchantSkill = types.NPC.stats.skills.enchant(player).modified
	local artisan = (data.qualityMult or 0) > 1
	local jcRatio = jcSkill / rLevel
	if artisan then jcRatio = (jcRatio + 1) / 2 end
	jcRatio = math.max(0.4, math.min(1.5, jcRatio))
	local q = jcRatio + enchantSkill / 400
	if artisan then q = q + 0.10 end
	q = math.floor(q * 50 + 0.5) / 50
	data.qualityMult = (math.abs(q - 1) < 0.001) and nil or q
	I.CraftingFramework.craftItem(data)
end

G_eventHandlers.SimplyMining_setNodeSize = function(data)
	local player = data[7] or world.players[1]
	player:sendEvent("Jewelcrafting_gemMiningProgress", data)
end

-- recursive door walk: interior cell counts as red mountain if any door chain reaches it
local function cellInRedMountain(cell, explored)
	if explored[cell.id] then return false end
	explored[cell.id] = true
	for _, door in pairs(cell:getAll(types.Door)) do
		local destCell = types.Door.destCell(door)
		if destCell then
			if destCell.isExterior then
				if destCell.region == "red mountain region" then
					return true
				end
			elseif cellInRedMountain(destCell, explored) then
				return true
			end
		end
	end
	return false
end

G_eventHandlers.Jewelcrafting_checkInRM = function(data)
	local player, cellId = data[1], data[2]
	if not player or not cellId then return end
	local cell = world.getCellById(cellId)
	if not cell then return end
	player:sendEvent("Jewelcrafting_updateInRM", { cellId, cellInRedMountain(cell, {}) })
end

-- spawn a cursed gem in front of the player and activate it next tick so the
-- record's mwscript fires with the player as actor (the curse trigger)
G_eventHandlers.Jewelcrafting_spawnCursedGem = function(data)
	local player, cursedId = data[1], data[2]
	if not player or not cursedId then return end
	local gem = world.createObject(cursedId, 1)
	if not gem then return end
	local yaw = player.rotation:getYaw()
	local forward = util.vector3(math.sin(yaw), math.cos(yaw), 0)
	gem:teleport(player.cell, player.position + forward * 80, player.rotation)
	async:newUnsavableSimulationTimer(0, function()
		if gem:isValid() then gem:activateBy(player) end
	end)
end

------------------------------ direct hooks ------------------------------

I.ItemUsage.addHandlerForType(types.Miscellaneous, function(item, actor)
	if item.recordId ~= "jc_pliers_common" then return end
	actor:sendEvent("Jewelcrafting_openCraftingUI", {})
end)

-- ore-container without Simply Mining
if not G_hasSimplyMining then
	I.Activation.addHandlerForType(types.Container, function(object, actor)
		if not types.Container.record(object).isOrganic then return end
		local rid = object.recordId:lower()
		if rid:find("ore") 
		or rid:find("mine") 
		or rid:find("vein")
		or rid:find("mineral") 
		or rid:find("deposit")
		or rid:find("geode") 
		or rid:find("crystal") then
			actor:sendEvent("Jewelcrafting_fallbackActivation", { object })
		end
	end)
end

return {
	engineHandlers = G_engineHandlers,
	eventHandlers  = G_eventHandlers,
}