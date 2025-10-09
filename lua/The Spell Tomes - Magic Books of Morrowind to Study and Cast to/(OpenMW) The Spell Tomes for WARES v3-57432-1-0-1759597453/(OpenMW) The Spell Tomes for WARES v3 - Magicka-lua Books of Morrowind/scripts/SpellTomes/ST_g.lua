local I = require('openmw.interfaces')
local world = require('openmw.world')
local types = require('openmw.types')
local core = require('openmw.core')
local getCastChance = require("Scripts.SpellTomes.ST_getCastChance")
local playerArrays = {}
local iteratePlayers = nil
local iterateBooks = nil
local processedPlayers = {}
local players = {}
local playerSettings = {}
local playerPools = {}
local activeActors
require("Scripts.SpellTomes.ST_database")

local bookArray = {}
for book, spell in pairs(spellTomes) do
	spellTomes[book] = spell:lower()
	if types.Book.record(book) and core.magic.spells.records[spell] then
		table.insert(bookArray, book)
	else
		print("invalid book/spell", book, spell)
		spellTomes[book] = nil
	end
end
numBooks = #bookArray

local function convertBooksInCell(data)
	local player = data.player
	local cell = player.cell
	local chance = data.chance
	local chanceDecline = data.chanceDecline
	local minCastChance = data.minCastChance
	local maxCastChance = data.maxCastChance
	local addToEnchanters = data.addToEnchanters
	if not saveData.playerPools[player.id] then
		return
	end
	if saveData.convertedCells[cell.id] then 
		return 
	end
	--print("==== convertBooksInCell ====")
	local countConverted = 0
	local tempPool = {}
	for _, book in pairs(saveData.playerPools[player.id]) do
		table.insert(tempPool, book)
	end
	local poolSize = #tempPool

	if poolSize > 0 then
		for _,book in pairs(cell:getAll(types.Book)) do
			local record = types.Book.record(book)
			if math.random() < chance
			and not record.skill 
			and not record.isScroll 
			and not record.enchant 
			and not record.mwscript 
			and not blacklist[record.id]
			and book:isValid()
			and book.count > 0
			then
				--print("converting "..tostring(record.id)..":")
				local cell = book.cell
				local position = book.position
				local owner = book.owner
				local rotation = book.rotation
				local count = book.count
				
				local randomIndex = math.random(1,poolSize)
				local randomBook = tempPool[randomIndex]
				
				local newItem = world.createObject(randomBook)
				newItem:teleport(cell, position, rotation)
				newItem.owner.factionId = owner.factionId
				newItem.owner.factionRank = owner.factionRank
				newItem.owner.recordId = owner.recordId
				countConverted = countConverted + 1
				book:remove()
				
				chance = chance * chanceDecline
				table.remove(tempPool, randomIndex)
				poolSize = poolSize - 1
				if poolSize == 0 then break end	
			end
		end
	end
	
	local function convertInventory(inv)
		for _,book in pairs(inv:getAll(types.Book)) do
			local record = types.Book.record(book)
			if math.random() < chance
			and not record.skill 
			and not record.isScroll 
			and not record.enchant 
			and not record.mwscript 
			and not blacklist[record.id]
			and book:isValid()
			and book.count > 0
			then
				--print("converting "..tostring(record.id)..":")
				local randomIndex = math.random(1,poolSize)
				local randomBook = tempPool[randomIndex]
				local newItem = world.createObject(randomBook)
				newItem:moveInto(inv)
				chance = chance * chanceDecline
				book:remove()
				countConverted = countConverted + 1
				table.remove(tempPool, randomIndex)
				poolSize = poolSize - 1
				if poolSize == 0 then break end
			end
		end
	end
	if poolSize > 0 then
		for _, container in pairs(cell:getAll(types.Container)) do
			convertInventory(types.Container.inventory(container), player)
			if poolSize == 0 then break end
		end
	end
	if poolSize > 0 then
		for _, actor in pairs(cell:getAll(types.NPC)) do
			if not saveData.convertedNPCs[actor.id] then
				local inv = types.NPC.inventory(actor)
				convertInventory(inv, player)
				if addToEnchanters > 0 then
					local npcRecord = types.NPC.record(actor)
					if npcRecord.servicesOffered.Enchanting and npcRecord.servicesOffered.Barter then
						for i = 1, addToEnchanters do
							local randomIndex = math.random(1,poolSize)
							local randomBook = tempPool[randomIndex]
							local newItem = world.createObject(randomBook)
							newItem:moveInto(inv)
							table.remove(tempPool, randomIndex)
							poolSize = poolSize - 1
							if poolSize == 0 then break end
						end
					end
				end
				saveData.convertedNPCs[actor.id] = true
			end
		end
	end
	if poolSize > 0 then
		for _, actor in pairs(cell:getAll(types.Creature)) do
			convertInventory(types.Creature.inventory(actor), player)
			if poolSize == 0 then break end
		end
	end
	if countConverted > 0 then
		print("[Spell Tomes] Converted "..countConverted.." books in "..tostring(cell.id))
	end
	saveData.convertedCells[cell.id] = true
end

local function registerPlayer(data)
	local player = data.player
	local minCastChance = data.minCastChance
	local maxCastChance = data.maxCastChance
	--print("[Spell Tomes] resetted player "..player.id)
	players[player.id] = player
	playerArrays[player.id] = {}
	processedPlayers[player.id] = nil
	playerSettings[player.id] = {minCastChance = minCastChance, maxCastChance = maxCastChance}
	iteratePlayers = nil
	iterateBooks = nil
end

function onUpdate()
	activeActors = nil
	if not next(playerArrays) then
		return 
	end
	if not iterateBooks then
		if iteratePlayers and not processedPlayers[iteratePlayers] then
			processedPlayers[iteratePlayers] = true
			saveData.playerPools[iteratePlayers] = {}
			--print("==== books for "..iteratePlayers..": ====")
			for book, chance in pairs(playerArrays[iteratePlayers]) do
				if chance >= playerSettings[iteratePlayers].minCastChance and chance <= playerSettings[iteratePlayers].maxCastChance then
					table.insert(saveData.playerPools[iteratePlayers], book)
					--print(book)
				end
			end
		end	
		iteratePlayers = next(playerArrays, iteratePlayers) or next(playerArrays)
	end
	iterateBooks = next(spellTomes, iterateBooks)
	if processedPlayers[iteratePlayers] then
		--print("already processed "..iteratePlayers)
		iterateBooks = nil
	end
	if iterateBooks then
		playerArrays[iteratePlayers][iterateBooks] = getCastChance(core.magic.spells.records[spellTomes[iterateBooks]], players[iteratePlayers])
		--print(iteratePlayers,iterateBooks, playerArrays[iteratePlayers][iterateBooks])
	end
end

local function unhookObject(object)
	if not activeActors then
		activeActors = {}
		for _, actor in pairs(world.activeActors) do
			activeActors[actor.id] = true
		end
	end
	if not activeActors[object.id] then
		--print("-",object)
		object:removeScript("scripts/SpellTomes/ST_a.lua")
	end
end

local function onObjectActive(object)
	if types.NPC.objectIsInstance(object) then
		--print("+",object)
		object:addScript("scripts/SpellTomes/ST_a.lua")
	end
end

local function onLoad(data)
	saveData = data or {
		convertedCells = {}
	}
	--migration:
	if not saveData.playerPools then
		saveData.playerPools = {}
	end
	if not saveData.convertedNPCs then
		saveData.convertedNPCs = {}
	end
end

local function onSave()
	return saveData
end

return {
	engineHandlers = {
		onLoad = onLoad,
		onInit = onLoad,
		onSave = onSave,
		onUpdate = onUpdate,
		onObjectActive = onObjectActive,
	},
	eventHandlers = { 
		SpellTomes_convertBooksInCell = convertBooksInCell,
		SpellTomes_registerPlayer = registerPlayer,
		SpellTomes_unhookObject = unhookObject,
	}
}