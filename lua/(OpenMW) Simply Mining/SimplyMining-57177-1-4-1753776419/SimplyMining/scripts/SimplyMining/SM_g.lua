local I = require('openmw.interfaces')
world = require('openmw.world')
types = require('openmw.types')
local core = require('openmw.core')
local vfs = require('openmw.vfs')
local dispositionBlessings = {}
local procPotions = {}
local recentActive = {}
local soulgems = {}
local slumbering = 0
local currentCells = {}
local async = require('openmw.async')
local removeNextUpdate= nil
local nodeRemoval = {}
require("scripts.SimplyMining.database")
local allowActivation = false

nodeToItemLookup ={}
for item, nodes in pairs(db_nodes_all) do
	for _, node in pairs(nodes) do
		nodeToItemLookup[node] = item
	end
end




local function SimplyMining_spawnOre(data)
		player = data.player
		position = data.position
		rotation = data.rotation
		recordId = data.record
		
	if not types.Container.records[recordId] then
		error(tostring(recordId).." Invalid Container id")
	else
		tempItem = world.createObject(recordId)
		tempItem:teleport(player.cell, position, {rotation = rotation})
		saveData.spawnedOres[tempItem.id] = tempItem
	end

end

local function onLoad(data)
	if not data then
		saveData = {}
	else
		saveData = data
	end
	if not saveData.spawnedOres then
		saveData.spawnedOres = {}
	end
end

local function onSave()
	return saveData
end

local function onUpdate()
	if removeNextUpdate then
		removeNextUpdate:remove(1)
		removeNextUpdate = nil
	end
	for i, node in pairs(nodeRemoval) do
		if node.scale <=0.1 then
			node:remove(1)
			table.remove(nodeRemoval,i)
		else
			node:setScale(node.scale-0.03)
		end
	end
	allowActivation = false
end

local function activateContainer(cont, player)
	if allowActivation then
		return true
	end
	if nodeToItemLookup[cont.recordId] then
		local isVanillaOre = not saveData.spawnedOres[cont.id] and not unavailableOres[nodeToItemLookup[cont.recordId]]
		player:sendEvent("SimplyMining_startMining", {cont, isVanillaOre })
		return false
	end
end
I.Activation.addHandlerForType(types.Container, activateContainer)



local function setNodeSize(data)
	local object = data[1]
	local size = data[2]
	if saveData.spawnedOres[object.id] then
		object:setScale(size)
	end
end

local function removeNode(object)
	if saveData.spawnedOres[object.id] then
		table.insert(nodeRemoval, object)
	else
		types.Container.inventory(object):resolve()
		for a,b in pairs(types.Container.inventory(object):getAll()) do
			b:remove()
		end
	end
end

local function getItem(data)
	local player = data[1]
	local recordId = data[2]
	local count = data[3]
	local cont = data[4]
	local isVanillaOre = data[5]
	local lastHitPos = data[6]
	
	if not isVanillaOre then
		if math.random() < count%1 then
			count = count + 1
		end
		if count <1 then
			player:sendEvent("SimplyMining_notifyFail", lastHitPos)
		else
			--print(player,recordId)
			local tempItem = world.createObject(recordId, math.floor(count))
			tempItem:moveInto(player)
			player:sendEvent("SimplyMining_notifyItem", {tempItem, math.floor(count), lastHitPos})
		end
	else
		types.Container.inventory(cont):resolve()
		for a,b in pairs(types.Container.inventory(cont):getAll()) do
			b:remove()
		end
		if math.random()<0.5 then
			local tempItem = world.createObject( nodeToItemLookup[cont.recordId], 1)
			tempItem:moveInto(cont)
			player:sendEvent("SimplyMining_notifyItem", {tempItem, 1, lastHitPos})
		else
			player:sendEvent("SimplyMining_notifyFail", lastHitPos)
		end
		allowActivation = true
		--world._runStandardActivationAction(cont, player)
		cont:activateBy(player)
	end
end

local function removeAllOres(player)
	for a,b in pairs(saveData.spawnedOres) do
		if b:isValid() then
			b:remove(1)
			saveData.spawnedOres[a] = nil
		end
		--b.enabled = false
	end
end




return {
	engineHandlers = { 
	onObjectActive = onObjectActive,
        onLoad = onLoad,
        onInit = onLoad,
        onSave = onSave,
        onUpdate = onUpdate,
	
	},
	eventHandlers = { 
		SimplyMining_spawnOre = SimplyMining_spawnOre,
		SimplyMining_setNodeSize= setNodeSize,
		SimplyMining_removeNode = removeNode,
		SimplyMining_getItem = getItem,
		SimplyMining_removeAllOres = removeAllOres,
	}
}