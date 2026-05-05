I = require('openmw.interfaces')
world = require('openmw.world')
storage = require('openmw.storage')
async = require('openmw.async')
types = require('openmw.types')
core = require('openmw.core')
util = require('openmw.util')
v3 = util.vector3
 
local playerArrays = {}
local processedPlayers = {}
local players = {}
local playerSettings = {}
local playerPools = {}
local activeActors
local getCastChance = require("scripts.SpellTomes.ST_getCastChance")
local replaceableBooks = require("scripts.SpellTomes.ST_replaceableBooks")
 
require("scripts.SpellTomes.ST_database")
require("scripts.SpellTomes.ST_rareSpells")
require("scripts.SpellTomes.ST_spellTomeClasses")
require("scripts.SpellTomes.ST_blacklistedCells")
 
-- registerSpellTome(def) and defs from SpellTomes/*.lua
require("scripts.SpellTomes.ST_api")
 
MOD_NAME = "SpellTomes"
S = {} -- settings cache
local S = S
 
require("scripts.SpellTomes.ST_settings")
local settingsSection = storage.globalSection("Settings" .. MOD_NAME)
local insightAvailable = core.magic.effects.records["t_mysticism_insight"]
 
-- optional companion teaching if "Follower Detection Utility" is installed
local function teachCompanionsAvailable()
	return S.TEACH_COMPANIONS and I.FollowerDetectionUtil ~= nil
end
 
-- merges blacklist database and S.BLACKLISTED_CELLS
local function split_entries(str)
	local entries = {}
	if not str or str == "" then
		return entries
	end
	for entry in string.gmatch(str, "([^;]+)") do
		entry = entry:match("^%s*(.-)%s*$")
		if entry and entry ~= "" then
			entries[entry:lower()] = true
		end
	end
	return entries
end
 
local blacklistedCells = {}
 
local function refreshBlacklist()
	blacklistedCells = split_entries(S.BLACKLISTED_CELLS or "")
	for cell in pairs(hardcodedBlacklistedCells) do
		blacklistedCells[cell:lower()] = true
	end
end
refreshBlacklist()
 
-- weighted random spell tome from custom filtered pool
local function drawFiltered(pool, filterFn)
	local matching = {}
	local weights = {}
	local total = 0
	for i, book in ipairs(pool) do
		if filterFn(book) then
			local def = registeredTomes[book]
			local w = (def and def.weight) or 1
			if w > 0 then
				matching[#matching + 1] = i
				weights[#weights + 1] = w
				total = total + w
			end
		end
	end
	if #matching == 0 then return nil end
	-- weighted pick
	local roll = math.random() * total
	local acc = 0
	for j, w in ipairs(weights) do
		acc = acc + w
		if roll < acc then
			local idx = matching[j]
			return pool[idx], idx
		end
	end
	-- fallback
	local idx = matching[#matching]
	return pool[idx], idx
end
 
local bookArray = {}
for book, spell in pairs(spellTomes) do
	spellTomes[book] = spell:lower()
	if types.Book.record(book) and core.magic.spells.records[spell] then
		table.insert(bookArray, book)
	else
--		print("invalid book/spell", book, spell)
		spellTomes[book] = nil
	end
end
numBooks = #bookArray

local function spawnAlignedTome(tomeId, origBook)
	local cell = origBook.cell
	local rotation = origBook.rotation
	local newItem = world.createObject(tomeId)
	local box = origBook:getBoundingBox()
	local localCenter = v3(0.1106414794921875, 0.001239776611328125, -4.57763671875e-05)
	local localHalf   = v3(16.1646, 19.6805, 3.00805)
	
	-- center offset in world space after the rotation
	local worldCenter = rotation:apply(localCenter)
	
	-- world-aabb halfsize.z of the rotated tome = sum of |row 2 of Q| * localHalf
	local worldHalfZ = math.abs(rotation:apply(v3(localHalf.x, 0, 0)).z)
	                 + math.abs(rotation:apply(v3(0, localHalf.y, 0)).z)
	                 + math.abs(rotation:apply(v3(0, 0, localHalf.z)).z)
	
	-- align world aabb: same xy center as origBook's bbox, bottom z on its floor
	local floorZ = box.center.z - box.halfSize.z
	local newPos = v3(
		box.center.x - worldCenter.x,
		box.center.y - worldCenter.y,
		floorZ + worldHalfZ - worldCenter.z
	)
	
	newItem:teleport(cell, newPos, rotation)
	return newItem
end

local function SpellTomes_transmuteBook(data)
	local player = data[1]
	local book = data[2]
	local cell = player.cell
	local minCastChance = (S.MIN_CAST_CHANCE or 50) / 100
	local maxCastChance = (S.MAX_CAST_CHANCE or 200) / 100
	local addToEnchanters = S.ADD_TO_ENCHANTERS or 0
	local addToBooksellers = S.ADD_TO_BOOKSELLERS or 0
	local npcClassChance = (S.NPC_CLASS_CHANCE or 0) / 100
	local rareSpawnChance = (S.RARE_SPAWN_CHANCE or 0) / 100
	local insightMult = S.INSIGHT_MULT or 1
	if not saveData.playerPools[player.id] then
		return
	end
	--print("==== convertBooksInCell ====")
	local countConverted = 0
	local tempPool = {}
	local knownSpells = {}
	for _, spell in pairs(types.Actor.spells(player)) do
		knownSpells[spell.id] = true
	end
	-- TR spell Insight
	local insightMag = insightAvailable and types.Actor.activeEffects(player):getEffect("t_mysticism_insight").magnitude * insightMult or 0
	
	if insightMag > 0 and playerArrays[player.id] then
		local expandedMin = math.max(0, minCastChance - insightMag / 100)
		for book, chance in pairs(playerArrays[player.id]) do
			if chance >= expandedMin and chance <= maxCastChance then
				local def = registeredTomes[book]
				local knownBlocked = def and def.allowRestockWhenKnown == false and knownSpells[spellTomes[book]]
				-- Rare tomes spawn at RARE_SPAWN_CHANCE per cell
				if not knownBlocked and (not rareSpells[book] or math.random() < rareSpawnChance) then
					table.insert(tempPool, book)
				end
			end
		end
	else
		for _, book in pairs(saveData.playerPools[player.id]) do
			local def = registeredTomes[book]
			local knownBlocked = def and def.allowRestockWhenKnown == false and knownSpells[spellTomes[book]]
			-- Rare tomes spawn at RARE_SPAWN_CHANCE per cell
			if not knownBlocked and (not rareSpells[book] or math.random() < rareSpawnChance) then
				table.insert(tempPool, book)
			end
		end
	end
	
	local poolSize = #tempPool

	if poolSize > 0 then
		local record = types.Book.record(book)
		if book:isValid()
		and book.count > 0
		then
			--print("converting "..tostring(record.id)..":")
			local owner = book.owner
			
			-- only draw tomes flagged replaceable (the default for base-mod tomes)
			local randomBook, randomIndex = drawFiltered(tempPool, function(b)
				local def = registeredTomes[b]
				return not def or def.replaceable
			end)
			if not randomBook then return end
			
			local newItem = spawnAlignedTome(randomBook, book)
			newItem.owner.factionId = owner.factionId
			newItem.owner.factionRank = owner.factionRank
			newItem.owner.recordId = owner.recordId
			countConverted = countConverted + 1
			book:remove()
		end
	end
end

local function convertBooksInCell(data)
	--local timestamp1 = core.getRealTime()
	local player = data.player
	local cell = player.cell
	if blacklistedCells[cell.id:lower()] then
		return
	end
	local chance = (S.CONVERSION_CHANCE or 0) / 100
	local chanceDecline = S.CONVERSION_DECLINE or 1
	local minCastChance = (S.MIN_CAST_CHANCE or 50) / 100
	local maxCastChance = (S.MAX_CAST_CHANCE or 200) / 100
	local addToEnchanters = S.ADD_TO_ENCHANTERS or 0
	local addToBooksellers = S.ADD_TO_BOOKSELLERS or 0
	local npcClassChance = (S.NPC_CLASS_CHANCE or 0) / 100
	local rareSpawnChance = (S.RARE_SPAWN_CHANCE or 0) / 100
	local insightMult = S.INSIGHT_MULT or 1
	if not saveData.playerPools[player.id] then
		return
	end
	if saveData.convertedCells[cell.id] then 
		return 
	end
	--print("==== convertBooksInCell ====")
	local countConverted = 0
	local tempPool = {}
	-- Build a set of spells the player already knows so we can honour
	-- allowRestockWhenKnown when filling the pool
	local knownSpells = {}
	for _, spell in pairs(types.Actor.spells(player)) do
		knownSpells[spell.id] = true
	end
	-- Insight expands the pool downward so higher-tier (harder-to-cast) tomes become eligible
	local insightMag = insightAvailable and types.Actor.activeEffects(player):getEffect("t_mysticism_insight").magnitude * insightMult or 0
	
	if insightMag > 0 and playerArrays[player.id] then
		local expandedMin = math.max(0, minCastChance - insightMag / 100)
		for book, chance in pairs(playerArrays[player.id]) do
			if chance >= expandedMin and chance <= maxCastChance then
				local def = registeredTomes[book]
				local knownBlocked = def and def.allowRestockWhenKnown == false and knownSpells[spellTomes[book]]
				
				if not knownBlocked and (not rareSpells[book] or math.random() < rareSpawnChance) then
					table.insert(tempPool, book)
				end
			end
		end
	else
		for _, book in pairs(saveData.playerPools[player.id]) do
			local def = registeredTomes[book]
			local knownBlocked = def and def.allowRestockWhenKnown == false and knownSpells[spellTomes[book]]
			
			if not knownBlocked and (not rareSpells[book] or math.random() < rareSpawnChance) then
				table.insert(tempPool, book)
			end
		end
	end
	
	local poolSize = #tempPool
	
	if poolSize > 0 then
		for _,book in pairs(cell:getAll(types.Book)) do
			if math.random() < chance
			and replaceableBooks[book.recordId]
			and book:isValid()
			and book.count > 0
			then
				--print("converting "..tostring(record.id)..":")
				local owner = book.owner
				
				-- only draw tomes for replaceable books
				local randomBook, randomIndex = drawFiltered(tempPool, function(b)
					local def = registeredTomes[b]
					return not def or def.replaceable
				end)
				if not randomBook then break end
				
				local newItem = spawnAlignedTome(randomBook, book)
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
			if math.random() < chance
			and replaceableBooks[book.recordId]
			and book:isValid()
			and book.count > 0
			then
				--print("converting "..tostring(record.id)..":")
				local randomBook, randomIndex = drawFiltered(tempPool, function(b)
					local def = registeredTomes[b]
					return not def or def.replaceable
				end)
				if not randomBook then break end
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
			if not types.Container.record(container).isOrganic then
				convertInventory(types.Container.inventory(container), player)
			end
			if poolSize == 0 then break end
		end
	end
	if poolSize > 0 then
		for _, actor in pairs(cell:getAll(types.NPC)) do
			if not saveData.convertedNPCs[actor.id] then
				local inv = types.NPC.inventory(actor)
				convertInventory(inv, player)
				-- enchanters and booksellers always have same number of books
				local isEnchanter = false
				if addToEnchanters > 0 and poolSize > 0 then
					local npcRecord = types.NPC.record(actor)
					if npcRecord.servicesOffered.Enchanting and npcRecord.servicesOffered.Barter then
						isEnchanter = true
						for i = 1, addToEnchanters do
							local randomBook, randomIndex = drawFiltered(tempPool, function(b)
								local def = registeredTomes[b]
								local dm = (def and def.distributeToMerchants) or "both"
								return dm == "both" or dm == "enchanter"
							end)
							if not randomBook then break end
							local newItem = world.createObject(randomBook)
							newItem:moveInto(inv)
							table.remove(tempPool, randomIndex)
							poolSize = poolSize - 1
							if poolSize == 0 then break end
						end
					end
				end
				if not isEnchanter and addToBooksellers > 0 and poolSize > 0 then
					local npcRecord = types.NPC.record(actor)
					if npcRecord.servicesOffered.Books and npcRecord.servicesOffered.Barter then
						for i = 1, addToBooksellers do
							local randomBook, randomIndex = drawFiltered(tempPool, function(b)
								local def = registeredTomes[b]
								local dm = (def and def.distributeToMerchants) or "both"
								return dm == "both" or dm == "bookseller"
							end)
							if not randomBook then break end
							local newItem = world.createObject(randomBook)
							newItem:moveInto(inv)
							table.remove(tempPool, randomIndex)
							poolSize = poolSize - 1
							if poolSize == 0 then break end
						end
					end
				end
				-- npc random class drops
				if npcClassChance > 0 and poolSize > 0 then
					local npcRecord = types.NPC.record(actor)
					if spellTomeClasses[npcRecord.class:lower()] and math.random() < npcClassChance then
						local randomBook, randomIndex = drawFiltered(tempPool, function(b)
							local def = registeredTomes[b]
							return not def or def.distributeToClasses
						end)
						if randomBook then
							local newItem = world.createObject(randomBook)
							newItem:moveInto(inv)
							table.remove(tempPool, randomIndex)
							poolSize = poolSize - 1
						end
					end
				end
				saveData.convertedNPCs[actor.id] = true
			end
		end
	end
 	
	-- spell vendor distribution
	for _, actor in pairs(cell:getAll(types.NPC)) do
		local vendorRecord = types.NPC.record(actor)
		if vendorRecord.servicesOffered.Spells then
			-- lazily computed top-3 skills, only if a def needs a skill check
			local topSkills
			for _, def in pairs(registeredTomes) do
				if def.addSpellToVendors or def.addTomeToVendors then
					local passesTrainerReq = (not def.spellVendorRequireTrainer) or vendorRecord.servicesOffered.Training
					local passesSkillReq = true
					if passesTrainerReq and def.spellVendorSkill then
						if not topSkills then
							topSkills = {}
							for i = 1, 3 do
								local bestId, bestVal = nil, -1
								for _, skillRec in pairs(core.stats.Skill.records) do
									if not topSkills[skillRec.id] then
										local v = types.NPC.stats.skills[skillRec.id](actor).base
										if v > bestVal then
											bestId = skillRec.id
											bestVal = v
										end
									end
								end
								if not bestId then break end
								topSkills[bestId] = bestVal
							end
						end
						local lvl = topSkills[def.spellVendorSkill]
						if not lvl then
							passesSkillReq = false
						elseif def.spellVendorMinLevel and lvl < def.spellVendorMinLevel then
							passesSkillReq = false
						end
					end
					if passesTrainerReq and passesSkillReq then
						if def.addSpellToVendors then
							types.NPC.spells(actor):add(def.spellId)
						end
						if def.addTomeToVendors then
							local newItem = world.createObject(def.tomeId)
							newItem:moveInto(types.NPC.inventory(actor))
						end
					end
				end
			end
		end
	end
	
	if poolSize > 0 then
		for _, actor in pairs(cell:getAll(types.Creature)) do
			convertInventory(types.Creature.inventory(actor), player)
			if poolSize == 0 then break end
		end
	end
	if countConverted > 0 then end
	saveData.convertedCells[cell.id] = true
	--print("converted tomes in cell in ".. (core.getRealTime() - timestamp1)*1000 .."ms") -- 0.5 ms outside
end
 
local function registerPlayer(data)
	local player = data.player
	local minCastChance = (S.MIN_CAST_CHANCE or 50) / 100
	local maxCastChance = (S.MAX_CAST_CHANCE or 200) / 100
	players[player.id] = player
	playerArrays[player.id] = {}
	processedPlayers[player.id] = nil
	playerSettings[player.id] = {minCastChance = minCastChance, maxCastChance = maxCastChance}
end
 
settingsSection:subscribe(async:callback(function(_, setting)
	if setting == "MIN_CAST_CHANCE" or setting == "MAX_CAST_CHANCE" then
		-- cast chance cache
		local minCastChance = (S.MIN_CAST_CHANCE or 50) / 100
		local maxCastChance = (S.MAX_CAST_CHANCE or 200) / 100
		for _, player in ipairs(world.players) do
			local id = player.id
			if playerSettings[id] then
				playerSettings[id].minCastChance = minCastChance
				playerSettings[id].maxCastChance = maxCastChance
				saveData.playerPools[id] = {}
				local pool = saveData.playerPools[id]
				for tome, chance in pairs(playerArrays[id] or {}) do
					if chance >= minCastChance and chance <= maxCastChance then
						pool[#pool + 1] = tome
					end
				end
			end
		end
	end
	if setting == "BLACKLISTED_CELLS" then
		refreshBlacklist()
	end
	-- attach spells to currently active NPCs
	if setting == "TEACH_COMPANIONS" and teachCompanionsAvailable() then
		for _, actor in pairs(world.activeActors) do
			if types.NPC.objectIsInstance(actor) and not actor:hasScript("scripts/SpellTomes/ST_a.lua") then
				actor:addScript("scripts/SpellTomes/ST_a.lua")
			end
		end
	end
end))
 
-- one full player pass per frame. ~700 tomes is microseconds of work,
-- no reason to chunk by single tome. processedPlayers gates so each
-- player only gets recomputed when registerPlayer flips them back to nil.
function onUpdate()
	activeActors = nil
	for playerId, _ in pairs(playerArrays) do
		if not processedPlayers[playerId] then
			local player = players[playerId]
			local arr = playerArrays[playerId]
			local settings = playerSettings[playerId]
			-- compute cast chance for every tome
			for tome, spellId in pairs(spellTomes) do
				arr[tome] = getCastChance(core.magic.spells.records[spellId], player)
			end
			-- rebuild filtered pool from chances
			saveData.playerPools[playerId] = {}
			local pool = saveData.playerPools[playerId]
			for tome, chance in pairs(arr) do
				if chance >= settings.minCastChance and chance <= settings.maxCastChance then
					pool[#pool + 1] = tome
				end
			end
			processedPlayers[playerId] = true
			return
		end
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
	if types.NPC.objectIsInstance(object) and teachCompanionsAvailable() then
		object:addScript("scripts/SpellTomes/ST_a.lua")
	end
end
 
-- tome registrations from I.SpellTomes
local function onRegisterTome(def)
	if registerSpellTome(def) then
		for _, player in ipairs(world.players) do
			registerPlayer({player = player})
		end
	end
end
 
-- send activate event to actor scripts
I.Activation.addHandlerForType(types.Book, function(object, actor)
	local def = registeredTomes[object.recordId:lower()]
	if def and def.learnTrigger == "activate" then
		actor:sendEvent("SpellTomes_activateLearn", { tomeId = object.recordId })
	end
end)
 
-- merits of service interop
local function giveTome(data)
	if not data or not data.player or not data.tomeId then return end
	if not types.Book.record(data.tomeId) then return end
	local item = world.createObject(data.tomeId, 1)
	item:moveInto(types.Actor.inventory(data.player))
end

local function onLoad(data)
	saveData = data or {
		convertedCells = {}
	}
	if not saveData.playerPools then
		saveData.playerPools = {}
	end
	if not saveData.convertedNPCs then
		saveData.convertedNPCs = {}
	end
	if not saveData.meshOffsets then
		saveData.meshOffsets = {}
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
		SpellTomes_registerTome = onRegisterTome,
		SpellTomes_giveTome = giveTome,
		SpellTomes_transmuteBook = SpellTomes_transmuteBook,
	}
}