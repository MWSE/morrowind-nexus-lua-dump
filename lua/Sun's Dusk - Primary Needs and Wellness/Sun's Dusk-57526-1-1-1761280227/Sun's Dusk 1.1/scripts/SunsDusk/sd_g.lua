-- ╭───────────────────────────────────────────────────────────────────╮
-- │ 					Suns Dusk: Water & Wares                       │
-- │ 					“Hydrate or diedrate.”						   │
-- ╰───────────────────────────────────────────────────────────────────╯
	
MODNAME = "SunsDusk"
I       = require('openmw.interfaces')
world   = require('openmw.world')
types   = require('openmw.types')
core    = require('openmw.core')
storage = require('openmw.storage')
async   = require('openmw.async')
vfs     = require('openmw.vfs')
util 	= require('openmw.util')
onUpdateJobs = {}


local function onUpdate(dt)
	for _, func in pairs(onUpdateJobs) do
		func(dt)
	end
end


-- ───────────────────────────────────────────────────────────── Logger gang ─────────────────────────────────────────────────────────────
DEBUG_LEVEL = 5  --  { "Silent", "Quiet", "Chatty", "Deep", "Trace" }
local _raw_print = print 
function log(level, ...)
	if level <= DEBUG_LEVEL then
		_raw_print(...)
	end
end



-- ───────────────────────────────────────────────────────────────── Settings ─────────────────────────────────────────────────────────────────

local function applyHiddenDifficultySettings(diff)
	if diff == "Default" then
		WAKEVALUE_MULT = 1
		FOODVALUE_MULT = 1
		DRINKVALUE_MULT = 1
	elseif diff == "Hard" then
		WAKEVALUE_MULT = 0.75
		FOODVALUE_MULT = 0.75
		DRINKVALUE_MULT = 0.75
	elseif diff == "Hardcore" then
		WAKEVALUE_MULT = 0.5
		FOODVALUE_MULT = 0.5
		DRINKVALUE_MULT = 0.5
	end
end

require('scripts.SunsDusk.sd_settings')
for id, template in pairs(settingsTemplate) do
	I.Settings.registerGroup(template)
end

local debugLevelNames = { "Silent", "Quiet", "Chatty", "Deep", "Trace" }

local function readAllSettings()
	for _, template in pairs(settingsTemplate) do
        local settingsSection = storage.globalSection(template.key)
        for _, entry in pairs(template.settings) do
            _G[entry.key] = settingsSection:get(entry.key)
			if entry.key == "DIFFICULTY_PRESET" then
				applyHiddenDifficultySettings(settingsSection:get("DIFFICULTY_PRESET"))
			end
        end
    end
	for i, name in pairs(debugLevelNames) do
		DEBUG_LEVEL = i
		if name == DEBUG_LEVEL_NAME then
			break
		end
	end
end

readAllSettings()

-- ───────────────────────────────────────────────────────────── Settings Event ──────────────────────────────────────────────────────────────
local function difficultyPresetJob(_, setting)
	if not saveData then return end
	if setting == "DIFFICULTY_PRESET" then
		onUpdateJobs["applyPreset"] = function()
			for newSettingId, newSettingValue in pairs(DifficultyPresets[DIFFICULTY_PRESET]) do
				for _, template in pairs(settingsTemplate) do
					for _, setting in pairs(template.settings) do
						if setting.key == newSettingId then
							local settingsSection = storage.globalSection(template.key)
							settingsSection:set(newSettingId, newSettingValue)
						end
					end
				end
			end
			onUpdateJobs["applyPreset"] = nil
		end
	end
end

for _, template in pairs(settingsTemplate) do
	local settingsSection = storage.globalSection(template.key)
	settingsSection:subscribe(async:callback(function(_, setting)
		local oldValue = _G[setting]
		_G[setting] = settingsSection:get(setting)
		difficultyPresetJob(_, setting)
		if setting == "DEBUG_LEVEL_NAME" then
			for i, name in pairs(debugLevelNames) do
				DEBUG_LEVEL = i
				if name == DEBUG_LEVEL_NAME then
					break
				end
			end
		end
		if setting == "DIFFICULTY_PRESET" then
			applyHiddenDifficultySettings(settingsSection:get("DIFFICULTY_PRESET"))
		end
	end))
end


-- ────────────────────────────────────────────────────── Databases ──────────────────────────────────────────────────────
require('scripts.SunsDusk.spreadsheetParser')

openBottles = {
	["misc_com_bottle_06"] = true,
	["misc_com_bottle_09"] = true,
	["misc_com_bottle_11"] = true,
	["misc_com_bottle_13"] = true,
	["misc_com_bottle_13"] = true,
	["misc_com_bottle_02"] = true,
	["misc_com_bottle_01"] = true,
}
extraClosedBottles = {
	["misc_com_redware_flask"] = true,
}

-- maxVolumeQ: only vessels with Q <= this can roll the liquid
-- spawnChance: relative weight
-- valuePerQ: value added per Q
local LIQUIDS = {
	water = {
		templateId  = 'sd_waterbottle_template',
		displayName = 'Water',
		maxVolumeQ  = math.huge,
		spawnChance = 1.0,
		valuePerQ   = 1,
	},
	sujamma = {
		templateId  = 'sd_sujamma_template',
		displayName = 'Sujamma',
		maxVolumeQ  = 2,    -- Q<=2 (<=500 ml per Q step*2) by default
		spawnChance = 0.3,  -- less common than water
		valuePerQ   = 6,    -- pricier kick
	},
	-- ...
}


-- ───────────────────────────────────────────────────────────────── Constants ─────────────────────────────────────────────────────────
local STEP_ML = 250


-- substrings → fallback liters
local FALLBACK_LITERS = {
	bottle  = 1.0,
	flask   = 0.5,
	beaker  = 0.5,
	cup     = 0.25,
	misc_de_glass = 0.25,
	goblet  = 0.25,
	pitcher = 0.75,
	tankard = 0.5,
	vase    = 2.0,
}

local LOW_CHANCE_SUBSTRINGS = { 'vase', 'pot' }
local SUBSTRINGS            = { 'flask', 'beaker', 'cup', 'goblet', 'pitcher', 'tankard', 'misc_de_glass' }
local INVENTORY_SUBSTRINGS  = { 'bottle' }




-- ───────────────────────────────────────────────────────────────── Utilities ────────────────────────────────────────────────────────────
local function lc(s)
	if s then
		return string.lower(s)
	end
	return s
end

local function hasKeyword(hay, kw)
	if not hay then
		return false
	end
	return string.find(hay, kw, 1, true) ~= nil
end

-- Trim trailing zeros from decimal strings.
local function trimZeros(num)
	-- num is number
	local n = math.floor(num * 100 + 0.5) / 100
	local s = tostring(n)
	if string.find(s, "%.") then
		s = s:gsub("0+$", "")
		s = s:gsub("%.$", "")
	end
	return s
end


-- ─────────────────────────────────────────────────────── Vessel heuristics & types ───────────────────────────────────────────────────────
-- Returns (chance, avgFill) or false.
local function isVesselRecord(rec, isSealed)
	if not rec then
		return false
	end

	local id   = lc(rec.id)
	local name = lc(rec.name or '')

	-- Avoid scripted items to prevent conflicts
	if rec.mwscript then
		return false
	end

	if isSealed == true then
		if extraClosedBottles[id] then
			return 2, 1
		end

		if openBottles[name] then
			return false
		end

		for _, sub in ipairs(INVENTORY_SUBSTRINGS) do
			if hasKeyword(id, sub) or hasKeyword(name, sub) then
				return 2, 1
			end
		end

	elseif isSealed == false then
		if openBottles[name] then
			return 0.6, 0.35
		end

		for _, sub in ipairs(LOW_CHANCE_SUBSTRINGS) do
			if hasKeyword(id, sub) or hasKeyword(name, sub) then
				return 0.3, 0.75
			end
		end

		for _, sub in ipairs(SUBSTRINGS) do
			if hasKeyword(id, sub) or hasKeyword(name, sub) then
				return 0.6, 0.75
			end
		end

		if extraClosedBottles[id] then
			return 1.5, 1.5
		end

	else
		if openBottles[name] then
			return 0.6, 0.35
		end

		for _, sub in ipairs(LOW_CHANCE_SUBSTRINGS) do
			if hasKeyword(id, sub) or hasKeyword(name, sub) then
				return 0.3, 0.75
			end
		end

		for _, sub in ipairs(INVENTORY_SUBSTRINGS) do
			if hasKeyword(id, sub) or hasKeyword(name, sub) then
				return 1.5, 1.5
			end
		end

		for _, sub in ipairs(SUBSTRINGS) do
			if hasKeyword(id, sub) or hasKeyword(name, sub) then
				return 0.99, 0.75
			end
		end

		if extraClosedBottles[id] then
			return 1.5, 1.5
		end
	end

	return false
end

local function categorizeVessel(rec)
	if not rec then
		return ""
	end

	local id   = lc(rec.id)
	local name = lc(rec.name or '')

	if rec.mwscript then
		return ""
	end

	if extraClosedBottles[id] then
		return "closed bottle"
	end

	if openBottles[name] then
		return "open bottle"
	end

	for _, sub in ipairs(INVENTORY_SUBSTRINGS) do
		if hasKeyword(id, sub) or hasKeyword(name, sub) then
			return "closed bottle"
		end
	end

	for _, sub in ipairs(LOW_CHANCE_SUBSTRINGS) do
		if hasKeyword(id, sub) or hasKeyword(name, sub) then
			return "open vase"
		end
	end

	for _, sub in ipairs(SUBSTRINGS) do
		if hasKeyword(id, sub) or hasKeyword(name, sub) then
			return "open drink " .. sub
		end
	end

	return ""
end


-- ──────────────────────────────────────────────────────── Capacity resolution (Q) ──────────────────────────────────────────────────────
local function fallbackLitersFrom(rec)
	local id   = lc(rec.id)
	local name = lc(rec.name or '')
	local chosen
	local chosenL = nil

	for k, L in pairs(FALLBACK_LITERS) do
		if hasKeyword(id, k) or hasKeyword(name, k) then
			if not chosenL or L > chosenL then
				chosen  = k
				chosenL = L
			end
		end
	end

	if chosenL then
		log(2, "[WaterBottles] Fallback volume for " .. rec.id .. " = " .. trimZeros(chosenL) .. " L")
		return chosenL
	end

	return 1.0
end

local function litersFor(origIdLower)
	local ok, db = pcall(function()
		return dbConsumables
	end)

	if ok and db then
		local row = db[origIdLower]
		if row and type(row.volume) == 'number' and row.volume > 0 then
			return row.volume
		end
	end

	local miscRec = types.Miscellaneous.record(origIdLower)
	if miscRec then
		return fallbackLitersFrom(miscRec)
	end

	return 1.0
end

local function ceildiv(n, d)
	return math.floor((n + d - 1) / d)
end

local function fmt_amount_ml(ml)
	if ml >= 1000 then
		local liters = ml / 1000
		return trimZeros(liters) .. "L"
	end
	return tostring(ml) .. " ml"
end

local function resolveMaxQ(origIdLower)
	local q = saveData.maxQ[origIdLower]
	if q then
		return q
	end

	local liters     = litersFor(origIdLower)
	local capacityMl = math.max(STEP_ML, math.floor(liters * 1000 + 0.5))
	q = math.max(1, ceildiv(capacityMl, STEP_ML))
	saveData.maxQ[origIdLower] = q

	log(2, "[WaterBottles] maxQ for " .. origIdLower .. " = " .. tostring(q) ..
		" (" .. fmt_amount_ml(q * STEP_ML) .. " capacity)")
	return q
end


-- ───────────────────────────────────────────────────────────────── Liquid helpers ───────────────────────────────────────────────────────────
local function ensureLiquidDB(liquidKey)
	if not saveData.liquidDB[liquidKey] then
		saveData.liquidDB[liquidKey] = {}
	end
	return saveData.liquidDB[liquidKey]
end

-- Weighted choice with interior v exterior bias
local function chooseLiquidFor(origIdLower)
	local vQ         = resolveMaxQ(origIdLower)
	local pool       = {}
	local total      = 0
	local vesselType = categorizeVessel(types.Miscellaneous.records[origIdLower])
	local exp        = 1

	if vesselType:find("open") and isExterior then
		-- outside - Stronger bias to non-water if open
		exp = 2
	elseif vesselType:find("open drink") and not isExterior then
		-- inside cups lean back to water a bit
		exp = 0.99
	end

	for key, def in pairs(LIQUIDS) do
		if vQ <= def.maxVolumeQ and def.spawnChance > 0 then
			if not isExterior and exp == 0.99 and key == "water" then
				local w = def.spawnChance * 0.1
				total = total + w
				pool[#pool + 1] = { key = key, w = w }
			else
				local w = def.spawnChance ^ exp
				total = total + w
				pool[#pool + 1] = { key = key, w = w }
			end
		end
	end

	-- fallback for edge cases. nod to the well
	if isSealed == 0.3 or #pool == 0 then
		log(4, "[WaterBottles]", origIdLower, "Fallback liquid → water")
		return 'water'
	end

	local r, acc = math.random() * total, 0
	for _, e in ipairs(pool) do
		acc = acc + e.w
		if r <= acc then
			return e.key
		end
	end

	return pool[#pool].key
end


-- ───────────────────────────────────────────────────────────── Record creation ──────────────────────────────────────────────────────────
-- alchemy division: matter cannot be created or destroyed, the law of equivalent exchange my dude
local function ensurePotionFor(origIdLower, q, liquidKey)
	local def = LIQUIDS[liquidKey or 'water']
	if not def then
		def = LIQUIDS.water
	end

	local maxQ = resolveMaxQ(origIdLower)
	if q < 1 then
		q = 1
	elseif q > maxQ then
		q = maxQ
	end

	local liquidDB  = ensureLiquidDB(liquidKey or 'water')
	liquidDB[origIdLower] = liquidDB[origIdLower] or {}
	local existing  = liquidDB[origIdLower][q]
	if existing then
		return existing
	end

	local tmpl = types.Potion.record(def.templateId)
	if not tmpl then
		log(1, "[WaterBottles] ERROR: template potion missing: " .. tostring(def.templateId))
		return nil
	end

	local miscRec = types.Miscellaneous.record(origIdLower)
	if not miscRec then
		log(1, "[WaterBottles] ERROR: misc record missing: " .. tostring(origIdLower))
		return nil
	end

	local baseMl   = maxQ * STEP_ML
	local leftMl   = q * STEP_ML
	local nameBase = (miscRec.name and miscRec.name ~= '') and miscRec.name or 'Liquid Container'
	local newName  = nameBase .. " (" .. fmt_amount_ml(leftMl) .. "/" .. fmt_amount_ml(baseMl) .. " " .. def.displayName .. ")"
	local newWeight = (miscRec.weight or tmpl.weight) + leftMl / 1000
	local newValue  = (miscRec.value or 0) + q * (def.valuePerQ or 1)

	local recordDraft = types.Potion.createRecordDraft({
		name    = newName,
		template= tmpl,
		model   = (miscRec.model and miscRec.model ~= '') and miscRec.model or tmpl.model,
		icon    = (miscRec.icon and miscRec.icon ~= '') and miscRec.icon or tmpl.icon,
		weight  = newWeight,
		value   = newValue,
	})

	local rec  = world.createRecord(recordDraft)
	local newId = rec.id

	liquidDB[origIdLower][q] = newId
	saveData.reverse[lc(newId)] = { orig = origIdLower, q = q, liquid = liquidKey or 'water' }

	log(2, "[WaterBottles] Created record " .. newId .. " for " .. origIdLower ..
		" q=" .. tostring(q) .. "/" .. tostring(maxQ) .. " [" .. (liquidKey or 'water') .. "]")

	return newId
end

local function randomFillQ(maxQ, avg)
	local u    = math.random()
	local mode = avg
	local fill

	if u < mode then
		fill = math.sqrt(u * mode)
	else
		fill = 1 - math.sqrt((1 - u) * (1 - mode))
	end

	local q = math.max(1, math.floor(fill * maxQ + 0.5))
	return q
end


-- ───────────────────────────────────────────────────────────────── Replacements ──────────────────────────────────────────────────────────
-- where clutter is learns to hydrate
local function replaceWorldObjectWithFull(obj)
	local rec = types.Miscellaneous.record(obj)
	local chance, averageFillLevel = isVesselRecord(rec)

	if not chance or math.random() > chance * WATER_SPAWN_CHANCE / 100 then
		return 0
	end

	local origId    = lc(rec.id)
	local liquidKey = chooseLiquidFor(origId)
	local newId     = ensurePotionFor(origId, randomFillQ(resolveMaxQ(origId), averageFillLevel), liquidKey)

	if not newId then
		return 0
	end

	local cell  = obj.cell
	local pos   = obj.position
	local rot   = obj.rotation
	local owner = obj.owner
	local count = (obj.count or 1)

	obj:remove()
	local newItem = world.createObject(newId, count)
	newItem.owner.factionId  = owner.factionId
	newItem.owner.factionRank= owner.factionRank
	newItem.owner.recordId   = owner.recordId
	newItem:teleport(cell, pos, rot)

	log(1, "[WaterBottles] World replaced " .. tostring(count) .. " × " .. rec.id)
	return count
end

local function replaceInInventory(inv, cont)
	local Misc      = types.Miscellaneous
	local replaced  = 0

	if not inv:isResolved() and (not cont or not types.Container.record(cont).isOrganic) then
		inv:resolve()
	end

	for _, item in ipairs(inv:getAll(Misc)) do
		if item:isValid() and item.count > 0 then
			local rec = Misc.record(item)
			local chance, averageFillLevel = isVesselRecord(rec, true)

			if chance and math.random() < chance * WATER_SPAWN_CHANCE / 100 then
				local origId    = lc(rec.id)
				local liquidKey = chooseLiquidFor(origId)
				local fullId    = ensurePotionFor(origId, resolveMaxQ(origId), liquidKey)

				if fullId then
					local count = item.count
					item:remove()
					world.createObject(fullId, count):moveInto(inv)
					replaced = replaced + count
				end
			end
		end
	end

	if replaced > 0 then
		log(1, "[WaterBottles] Inventory replaced " .. tostring(replaced) .. " items")
	end

	return replaced
end


-- ───────────────────────────────────────────────────────────────── NPC stocking ──────────────────────────────────────────────────────────
-- publicans get more water + traders diversify later
local function addFullToClassNPC(npc)

	-- Original logic preserved for future use
	local cls = lc(types.NPC.record(npc).class or '')
	if cls ~= 'publican' and cls ~= 'trader' then
		return false
	end

	local anyOrig
	if cls == 'publican' then
		for orig, _ in pairs(saveData.maxQ) do
			if (orig:find('flask') or orig:find('bottle') or orig:find('flask') or
			    orig:find('cup') or orig:find('goblet') or orig:find('pitcher') or orig:find('tankard'))
			    and math.random() < 0.3 then
				anyOrig = orig
				break
			end
		end
	else
		for orig, _ in pairs(saveData.maxQ) do
			if orig:find('bottle') and math.random() < 0.5 then
				anyOrig = orig
				break
			end
		end
	end

	if not anyOrig then
		return false
	end

	local liquidKey = chooseLiquidFor(anyOrig)
	local fullId = ensurePotionFor(anyOrig, resolveMaxQ(anyOrig), liquidKey)
	if not fullId then
		return false
	end

	local inv = types.NPC.inventory(npc)
	local rndAmount = math.random(1, 5)
	world.createObject(fullId, rndAmount):moveInto(inv)
	log(1, "[WaterBottles] Stocked " .. tostring(rndAmount) .. " bottles to " .. npc.id)
	return true
end


-- ───────────────────────────────────────────────────────────────── Downgrade ─────────────────────────────────────────────────────────────
-- drink. downgrade. upgrade. repeat. hydration is a ladder.
local function downgradeWaterItem(data)
	local item   = data.item
	local inv    = data.inv
	local player = data.player

	if not inv then
		inv = types.NPC.inventory(player)
	end

	local idLower = lc(item.recordId)
	local rev     = saveData.reverse[idLower]
	if not rev then
		return false
	end

	if item:isValid() and item.count > 0 then
		item:remove(1)
	end

	local nextQ = rev.q - 1
	if nextQ >= 1 then
		local nextId = ensurePotionFor(rev.orig, nextQ, rev.liquid or 'water')
		if nextId then
			world.createObject(nextId):moveInto(inv)
		end
		log(3, "[WaterBottles] Drank " .. (rev.liquid or 'water') .. ": " .. rev.orig .. " -> q=" .. tostring(nextQ))
	else
		world.createObject(rev.orig):moveInto(inv)
		log(3, "[WaterBottles] Emptied " .. (rev.liquid or 'water') .. ": " .. rev.orig .. " -> original misc")
	end

	player:sendEvent("SunsDusk_WaterBottles_consumedWater", rev.liquid or 'water')
	return true
end


local function consumeMilliliters(player, mlToConsume)
	if not player or not mlToConsume or mlToConsume <= 0 then
		return 0
	end
	
	local mlConsumed = 0
	local inventory = types.Actor.inventory(player)
	
	-- Collect all liquid items and categorize them
	local openVessels = {}
	local closedVessels = {}
	
	for _, item in pairs(inventory:getAll()) do
		local pid = item.recordId:lower()
		local info = saveData.reverse[pid]
		
		if info and info.orig and info.q then
			-- Get the original vessel record and categorize it
			local origRecord = types.Miscellaneous.record(info.orig)
			if origRecord then
				local category = categorizeVessel(origRecord)
				
				if category and category:find("open") then
					table.insert(openVessels, {item = item, pid = pid, info = info})
				else
					table.insert(closedVessels, {item = item, pid = pid, info = info})
				end
			end
		end
	end
	
	log(5, string.format("Found %d open, %d closed vessels", #openVessels, #closedVessels))
	
	-- Process a list of vessels
	local function processVessels(vesselList)
		for _, data in ipairs(vesselList) do
			if mlConsumed >= mlToConsume then
				break
			end
			
			local item = data.item
			local pid = data.pid
			local info = data.info
			local count = item.count
			
			for i = 1, count do
				if mlConsumed >= mlToConsume then
					break
				end
				
				local mlInBottle = info.q * STEP_ML
				local mlNeeded = mlToConsume - mlConsumed
				local mlToTake = math.min(mlInBottle, mlNeeded)
				local qToRemove = math.ceil(mlToTake / STEP_ML)
				local newQ = info.q - qToRemove
				
				-- Remove current bottle
				item:remove(1)
				
				-- Add downgraded bottle if not empty
				if newQ > 0 then
					local liquid = info.liquid or 'water'
					local liquidDB = saveData.liquidDB[liquid]
					if liquidDB and liquidDB[info.orig] and liquidDB[info.orig][newQ] then
						world.createObject(liquidDB[info.orig][newQ], 1):moveInto(inventory)
					end
				else
					world.createObject(info.orig, 1):moveInto(inventory)
				end
				
				mlConsumed = mlConsumed + mlToTake
			end
		end
	end
	
	-- Process open vessels first, then closed
	processVessels(openVessels)
	
	if mlConsumed < mlToConsume then
		processVessels(closedVessels)
	end
	
	log(4, string.format("Consumed %d/%d ml from player inventory", mlConsumed, mlToConsume))
	
	return mlConsumed
end

-- Consume water from inventory, prioritizing open vessels
local function consumeWater(data)
	local player = data.player
	local amountMl = data.amountMl or 250
	consumeMilliliters(player, amountMl)
end

-- ──────────────────────────────────────────────────────────────── Cell pass ──────────────────────────────────────────────────────────────
-- some items get wet
local function convertMiscInCell(data)
	local cell = data.player.cell
	isExterior = cell:hasTag("QuasiExterior") or cell.isExterior

	if saveData.convertedCellsWater[cell.id] then
		return
	end

	local converted = 0
	local stocked   = 0

	for _, obj in ipairs(cell:getAll(types.Miscellaneous)) do
		if obj:isValid() and (obj.count or 1) > 0 then
			converted = converted + replaceWorldObjectWithFull(obj)
		end
	end

	for _, c in ipairs(cell:getAll(types.Container)) do
		converted = converted + replaceInInventory(types.Container.inventory(c), c)
	end

	for _, npc in ipairs(cell:getAll(types.NPC)) do
		local idLower = lc(npc.id)
		if not saveData.convertedNPCsWater[idLower] then
			converted = converted + replaceInInventory(types.NPC.inventory(npc))

			if addFullToClassNPC(npc) then
				stocked = stocked + 1
			end

			saveData.convertedNPCsWater[idLower] = true
		end
	end

	for _, cr in ipairs(cell:getAll(types.Creature)) do
		converted = converted + replaceInInventory(types.Creature.inventory(cr))
	end

	if converted > 0 then
		log(2, "[WaterBottles] Converted " .. tostring(converted) .. " items in cell " .. tostring(cell.id))
	end

	if stocked > 0 then
		log(2, "[WaterBottles] Gave bottles to " .. tostring(stocked) .. " NPCs")
	end

	saveData.convertedCellsWater[cell.id] = true
end


-- ──────────────────────────────────────────────────────────────── Spillage ─────────────────────────────────────────────────────────────
-- water doesn't survive a jump :( courtesy of ownlyme
local function spillWater(player)
	local Misc      = types.Miscellaneous
	local spilledMl = 0
	local inv       = types.NPC.inventory(player)

	for _, item in ipairs(inv:getAll(types.Potion)) do
		local rev = saveData.reverse[item.recordId:lower()]
		if rev then
			local isBottle = isVesselRecord(Misc.record(rev.orig), true)
			if not isBottle then
				local quantity = item.count
				spilledMl = spilledMl + rev.q * 250 * quantity
				item:remove()
				world.createObject(rev.orig):moveInto(inv)
			end
		end
	end

	if spilledMl > 0 then
		player:sendEvent("SunsDusk_spilledWater", spilledMl)
	end
end


-- ───────────────────────────────────────────────────────────────── NPC Scripts ─────────────────────────────────────────────────────────
-- we tug at actor hooks
local function unhookObject(object)
	object:removeScript("scripts/SunsDusk/sd_a.lua")
end

local function onObjectActive(object)
	if types.Actor.objectIsInstance(object) then
		object:addScript("scripts/SunsDusk/sd_a.lua")
	end
end


-- ─────────────────────────────────────────────────────────────── Sleep ─────────────────────────────────────────────────────────────────
-- the bed calls and the script listens
local function activateBed(object, actor)
	local scrName = (types.Activator.record(object.recordId).mwscript or ''):lower()
	if scrName == "bed_standard" or scrName == "chargenbed" or scrName == "Bed_Standard" then
		actor:sendEvent("SunsDusk_ActivatedBed", object)
	end
end

I.Activation.addHandlerForType(types.Activator, activateBed)


-- ─────────────────────────────────────────────────────────────── Refill ────────────────────────────────────────────────────────────
-- wells give water + open sources top off spillage
-- wells only refill water
local function refillBottlesWell(player)
	local inv    = types.NPC.inventory(player)
	local Misc   = types.Miscellaneous
	local Potion = types.Potion

	local replaced = 0

	for _, item in ipairs(inv:getAll(Misc)) do
		if item:isValid() and item.count > 0 then
			local rec    = Misc.record(item)
			local chance = isVesselRecord(rec, true)

			if chance then
				local origId = lc(rec.id)
				local fullId = ensurePotionFor(origId, resolveMaxQ(origId), 'water')

				if fullId then
					local count = item.count
					item:remove()
					world.createObject(fullId, count):moveInto(inv)
					replaced = replaced + count
				end
			end
		end
	end

	for _, item in ipairs(inv:getAll(Potion)) do
		if item:isValid() and item.count > 0 then
			local rev = saveData.reverse[item.recordId:lower()]
			if rev then
				local origId = lc(rev.orig)
				local maxQ   = resolveMaxQ(origId)
				local fullId = ensurePotionFor(origId, maxQ, 'water')

				if maxQ and rev.q < maxQ and fullId then
					local count = item.count
					item:remove()
					world.createObject(fullId, count):moveInto(inv)
					replaced = replaced + count
				end
			end
		end
	end

	if replaced > 0 then
		local str = "Refilled " .. tostring(replaced) .. " bottles"
		player:sendEvent("SunsDusk_refilledBottlesWell", str)
	end
end

-- open sources only refill spillables; keep water
local function refillSpillables(player)
	local inv    = types.NPC.inventory(player)
	local Misc   = types.Miscellaneous
	local Potion = types.Potion

	local replaced = 0

	for _, item in ipairs(inv:getAll(Misc)) do
		if item:isValid() and item.count > 0 then
			local rec   = Misc.record(item)
			local isOpen = isVesselRecord(rec, false)

			if isOpen then
				local origId = lc(rec.id)
				local fullId = ensurePotionFor(origId, resolveMaxQ(origId), 'water')

				if fullId then
					local count = item.count
					item:remove()
					world.createObject(fullId, count):moveInto(inv)
					replaced = replaced + count
				end
			end
		end
	end

	for _, item in ipairs(inv:getAll(Potion)) do
		if item:isValid() and item.count > 0 then
			local rev = saveData.reverse[item.recordId:lower()]
			if rev then
				local origId = lc(rev.orig)
				local isOpen = isVesselRecord(Misc.records[origId], false)

				if isOpen then
					local maxQ   = resolveMaxQ(origId)
					local fullId = ensurePotionFor(origId, maxQ, 'water')

					if maxQ and rev.q < maxQ and fullId then
						local count = item.count
						item:remove()
						world.createObject(fullId, count):moveInto(inv)
						replaced = replaced + count
					end
				end
			end
		end
	end

	if replaced > 0 then
		local str = "Refilled " .. tostring(replaced) .. " bottles"
		player:sendEvent("SunsDusk_messageBox", str)
	end
end

function toBitPositions(n, step)
    step = step or 1  -- default to standard binary (step of 1)
    n = math.floor(n / step) -- Convert magnitude to "units" based on step
    local result = {}
    local position = 1
    while n > 0 do
        if n % 2 == 1 then
            table.insert(result, position)
        end
        n = math.floor(n / 2)
        position = position + 1
    end
    return result
end

local shortBits = {
["sd-detectenchantment1"] = 4,
["sd-detectenchantment2"] = 4,
["sd-detectenchantment3"] = 4,
["sd-detectenchantment4"] = 4,
["sd-fortifyhealth1"] = 4,
["sd-fortifyhealth2"] = 4,
["sd-fortifyhealth3"] = 4,
["sd-fortifyhealth4"] = 4,
["sd-cureblightdisease1"] = 4,
["sd-cureblightdisease2"] = 4,
["sd-cureblightdisease3"] = 4,
["sd-cureblightdisease4"] = 4,
["sd-spellabsorption1"] = 4,
["sd-spellabsorption2"] = 4,
["sd-spellabsorption3"] = 4,
["sd-spellabsorption4"] = 4,
["sd-waterbreathing1"] = 1,
["sd-waterbreathing2"] = 1,
["sd-waterbreathing3"] = 1,
["sd-waterbreathing4"] = 1,
["sd-cureparalyzation1"] = 4,
["sd-cureparalyzation2"] = 4,
["sd-cureparalyzation3"] = 4,
["sd-cureparalyzation4"] = 4,
["sd-restoremagicka1"] = 4,
["sd-restoremagicka2"] = 4,
["sd-restoremagicka3"] = 4,
["sd-restoremagicka4"] = 4,
["sd-resistfire1"] = 4,
["sd-resistfire2"] = 4,
["sd-resistfire3"] = 4,
["sd-resistfire4"] = 4,
["sd-lightningshield1"] = 4,
["sd-lightningshield2"] = 4,
["sd-lightningshield3"] = 4,
["sd-lightningshield4"] = 4,
["sd-drainfatigue1"] = 4,
["sd-drainfatigue2"] = 4,
["sd-drainfatigue3"] = 4,
["sd-drainfatigue4"] = 4,
["sd-swiftswim1"] = 4,
["sd-swiftswim2"] = 4,
["sd-swiftswim3"] = 4,
["sd-swiftswim4"] = 4,
["sd-fortifyattack1"] = 4,
["sd-fortifyattack2"] = 4,
["sd-fortifyattack3"] = 4,
["sd-fortifyattack4"] = 4,
["sd-resistfrost1"] = 4,
["sd-resistfrost2"] = 4,
["sd-resistfrost3"] = 4,
["sd-resistfrost4"] = 4,
["sd-resistpoison1"] = 4,
["sd-resistpoison2"] = 4,
["sd-resistpoison3"] = 4,
["sd-resistpoison4"] = 4,
["sd-resistshock1"] = 4,
["sd-resistshock2"] = 4,
["sd-resistshock3"] = 4,
["sd-resistshock4"] = 4,
["sd-curepoison1"] = 4,
["sd-curepoison2"] = 4,
["sd-curepoison3"] = 4,
["sd-curepoison4"] = 4,
["sd-invisibility1"] = 1,
["sd-invisibility2"] = 1,
["sd-invisibility3"] = 1,
["sd-invisibility4"] = 1,
["sd-restorehealth1"] = 5,
["sd-restorehealth2"] = 5,
["sd-restorehealth3"] = 5,
["sd-restorehealth4"] = 5,
["sd-nighteye1"] = 4,
["sd-nighteye2"] = 4,
["sd-nighteye3"] = 4,
["sd-nighteye4"] = 4,
["sd-almsiviintervention1"] = 4,
["sd-almsiviintervention2"] = 4,
["sd-almsiviintervention3"] = 4,
["sd-almsiviintervention4"] = 4,
["sd-burden1"] = 4,
["sd-burden2"] = 4,
["sd-burden3"] = 4,
["sd-burden4"] = 4,
["sd-detectkey1"] = 4,
["sd-detectkey2"] = 4,
["sd-detectkey3"] = 4,
["sd-detectkey4"] = 4,
["sd-restorefatigue1"] = 5,
["sd-restorefatigue2"] = 5,
["sd-restorefatigue3"] = 5,
["sd-restorefatigue4"] = 5,
["sd-fortifyfatigue1"] = 4,
["sd-fortifyfatigue2"] = 4,
["sd-fortifyfatigue3"] = 4,
["sd-fortifyfatigue4"] = 4,
["sd-jump1"] = 4,
["sd-jump2"] = 4,
["sd-jump3"] = 4,
["sd-jump4"] = 4,
["sd-sanctuary1"] = 4,
["sd-sanctuary2"] = 4,
["sd-sanctuary3"] = 4,
["sd-sanctuary4"] = 4,
["sd-waterwalking1"] = 1,
["sd-waterwalking2"] = 1,
["sd-waterwalking3"] = 1,
["sd-waterwalking4"] = 1,
["sd-shield1"] = 4,
["sd-shield2"] = 4,
["sd-shield3"] = 4,
["sd-shield4"] = 4,
["sd-light1"] = 4,
["sd-light2"] = 4,
["sd-light3"] = 4,
["sd-light4"] = 4,
["sd-levitate1"] = 4,
["sd-levitate2"] = 4,
["sd-levitate3"] = 4,
["sd-levitate4"] = 4,
["sd-fireshield1"] = 4,
["sd-fireshield2"] = 4,
["sd-fireshield3"] = 4,
["sd-fireshield4"] = 4,
["sd-telekinesis1"] = 4,
["sd-telekinesis2"] = 4,
["sd-telekinesis3"] = 4,
["sd-telekinesis4"] = 4,
["sd-fortifyattributepersonality1"] = 4,
["sd-fortifyattributewillpower1"] = 4,
["sd-fortifyattributestrength1"] = 4,
["sd-fortifyattributespeed1"] = 4,
["sd-fortifyattributeagility1"] = 4,
["sd-fortifyattributeintelligence1"] = 4,
["sd-fortifyattributeluck1"] = 4,
["sd-fortifyattributeendurance1"] = 4,
["sd-fortifyattributepersonality2"] = 4,
["sd-fortifyattributewillpower2"] = 4,
["sd-fortifyattributestrength2"] = 4,
["sd-fortifyattributespeed2"] = 4,
["sd-fortifyattributeagility2"] = 4,
["sd-fortifyattributeintelligence2"] = 4,
["sd-fortifyattributeluck2"] = 4,
["sd-fortifyattributeendurance2"] = 4,
["sd-fortifyattributepersonality3"] = 4,
["sd-fortifyattributewillpower3"] = 4,
["sd-fortifyattributestrength3"] = 4,
["sd-fortifyattributespeed3"] = 4,
["sd-fortifyattributeagility3"] = 4,
["sd-fortifyattributeintelligence3"] = 4,
["sd-fortifyattributeluck3"] = 4,
["sd-fortifyattributeendurance3"] = 4,
["sd-fortifyattributepersonality4"] = 4,
["sd-fortifyattributewillpower4"] = 4,
["sd-fortifyattributestrength4"] = 4,
["sd-fortifyattributespeed4"] = 4,
["sd-fortifyattributeagility4"] = 4,
["sd-fortifyattributeintelligence4"] = 4,
["sd-fortifyattributeluck4"] = 4,
["sd-fortifyattributeendurance4"] = 4,
["sd-frostshield1"] = 4,
["sd-frostshield2"] = 4,
["sd-frostshield3"] = 4,
["sd-frostshield4"] = 4,
["sd-resistmagicka1"] = 4,
["sd-resistmagicka2"] = 4,
["sd-resistmagicka3"] = 4,
["sd-resistmagicka4"] = 4,
["sd-slowfall1"] = 4,
["sd-slowfall2"] = 4,
["sd-slowfall3"] = 4,
["sd-slowfall4"] = 4,
["sd-curecommondisease1"] = 4,
["sd-curecommondisease2"] = 4,
["sd-curecommondisease3"] = 4,
["sd-curecommondisease4"] = 4,
["sd-feather1"] = 4,
["sd-feather2"] = 4,
["sd-feather3"] = 4,
["sd-feather4"] = 4,
["sd-chameleon1"] = 4,
["sd-chameleon2"] = 4,
["sd-chameleon3"] = 4,
["sd-chameleon4"] = 4,
["sd-detectanimal1"] = 4,
["sd-detectanimal2"] = 4,
["sd-detectanimal3"] = 4,
["sd-detectanimal4"] = 4,
}

local longBits = {
sd_weaknesstoblightdisease1 = 3,
sd_weaknesstoblightdisease2 = 3,
sd_fortifymagicka1 = 5,
sd_fortifymagicka2 = 5,
sd_spellabsorption1 = 3,
sd_spellabsorption2 = 3,
sd_reflect1 = 3,
sd_reflect2 = 3,
sd_blind1 = 3,
sd_blind2 = 3,
sd_waterwalking1 = 1,
sd_waterwalking2 = 1,
sd_absorbmagicka1 = 3,
sd_absorbmagicka2 = 3,
sd_detectanimal1 = 7,
sd_detectanimal2 = 7,
sd_fortifymaximummagicka1 = 3,
sd_fortifymaximummagicka2 = 3,
sd_swiftswim1 = 6,
sd_swiftswim2 = 6,
sd_weaknesstoshock1 = 3,
sd_weaknesstoshock2 = 3,
sd_calmcreature1 = 5,
sd_calmcreature2 = 5,
sd_sound1 = 3,
sd_sound2 = 3,
sd_levitate1 = 2,
sd_levitate2 = 2,
sd_poison1 = 2,
sd_poison2 = 2,
sd_weaknesstofire1 = 3,
sd_weaknesstofire2 = 3,
sd_drainskillbluntweapon1 = 4,
sd_drainskillaxe1 = 4,
sd_drainskillarmorer1 = 4,
sd_drainskillrestoration1 = 4,
sd_drainskillenchant1 = 4,
sd_drainskillathletics1 = 4,
sd_drainskillmarksman1 = 4,
sd_drainskillmediumarmor1 = 4,
sd_drainskillunarmored1 = 4,
sd_drainskillspear1 = 4,
sd_drainskillalteration1 = 4,
sd_drainskilldestruction1 = 4,
sd_drainskillspeechcraft1 = 4,
sd_drainskillshortblade1 = 4,
sd_drainskilllongblade1 = 4,
sd_drainskillmysticism1 = 4,
sd_drainskillsecurity1 = 4,
sd_drainskillillusion1 = 4,
sd_drainskillblock1 = 4,
sd_drainskilllightarmor1 = 4,
sd_drainskillheavyarmor1 = 4,
sd_drainskillhandtohand1 = 4,
sd_drainskillalchemy1 = 4,
sd_drainskillsneak1 = 4,
sd_drainskillconjuration1 = 4,
sd_drainskillacrobatics1 = 4,
sd_drainskillmercantile1 = 4,
sd_drainskillbluntweapon2 = 4,
sd_drainskillaxe2 = 4,
sd_drainskillarmorer2 = 4,
sd_drainskillrestoration2 = 4,
sd_drainskillenchant2 = 4,
sd_drainskillathletics2 = 4,
sd_drainskillmarksman2 = 4,
sd_drainskillmediumarmor2 = 4,
sd_drainskillunarmored2 = 4,
sd_drainskillspear2 = 4,
sd_drainskillalteration2 = 4,
sd_drainskilldestruction2 = 4,
sd_drainskillspeechcraft2 = 4,
sd_drainskillshortblade2 = 4,
sd_drainskilllongblade2 = 4,
sd_drainskillmysticism2 = 4,
sd_drainskillsecurity2 = 4,
sd_drainskillillusion2 = 4,
sd_drainskillblock2 = 4,
sd_drainskilllightarmor2 = 4,
sd_drainskillheavyarmor2 = 4,
sd_drainskillhandtohand2 = 4,
sd_drainskillalchemy2 = 4,
sd_drainskillsneak2 = 4,
sd_drainskillconjuration2 = 4,
sd_drainskillacrobatics2 = 4,
sd_drainskillmercantile2 = 4,
sd_firedamage1 = 2,
sd_firedamage2 = 2,
sd_rallycreature1 = 8,
sd_rallycreature2 = 8,
sd_weaknesstocorprusdisease1 = 3,
sd_weaknesstocorprusdisease2 = 3,
sd_weaknesstofrost1 = 3,
sd_weaknesstofrost2 = 3,
sd_resistcorprusdisease1 = 6,
sd_resistcorprusdisease2 = 6,
sd_absorbskillbluntweapon1 = 3,
sd_absorbskillaxe1 = 3,
sd_absorbskillarmorer1 = 3,
sd_absorbskillrestoration1 = 3,
sd_absorbskillenchant1 = 3,
sd_absorbskillathletics1 = 3,
sd_absorbskillmarksman1 = 3,
sd_absorbskillmediumarmor1 = 3,
sd_absorbskillunarmored1 = 3,
sd_absorbskillspear1 = 3,
sd_absorbskillalteration1 = 3,
sd_absorbskilldestruction1 = 3,
sd_absorbskillspeechcraft1 = 3,
sd_absorbskillshortblade1 = 3,
sd_absorbskilllongblade1 = 3,
sd_absorbskillmysticism1 = 3,
sd_absorbskillsecurity1 = 3,
sd_absorbskillillusion1 = 3,
sd_absorbskillblock1 = 3,
sd_absorbskilllightarmor1 = 3,
sd_absorbskillheavyarmor1 = 3,
sd_absorbskillhandtohand1 = 3,
sd_absorbskillalchemy1 = 3,
sd_absorbskillsneak1 = 3,
sd_absorbskillconjuration1 = 3,
sd_absorbskillacrobatics1 = 3,
sd_absorbskillmercantile1 = 3,
sd_absorbskillbluntweapon2 = 3,
sd_absorbskillaxe2 = 3,
sd_absorbskillarmorer2 = 3,
sd_absorbskillrestoration2 = 3,
sd_absorbskillenchant2 = 3,
sd_absorbskillathletics2 = 3,
sd_absorbskillmarksman2 = 3,
sd_absorbskillmediumarmor2 = 3,
sd_absorbskillunarmored2 = 3,
sd_absorbskillspear2 = 3,
sd_absorbskillalteration2 = 3,
sd_absorbskilldestruction2 = 3,
sd_absorbskillspeechcraft2 = 3,
sd_absorbskillshortblade2 = 3,
sd_absorbskilllongblade2 = 3,
sd_absorbskillmysticism2 = 3,
sd_absorbskillsecurity2 = 3,
sd_absorbskillillusion2 = 3,
sd_absorbskillblock2 = 3,
sd_absorbskilllightarmor2 = 3,
sd_absorbskillheavyarmor2 = 3,
sd_absorbskillhandtohand2 = 3,
sd_absorbskillalchemy2 = 3,
sd_absorbskillsneak2 = 3,
sd_absorbskillconjuration2 = 3,
sd_absorbskillacrobatics2 = 3,
sd_absorbskillmercantile2 = 3,
sd_commandhumanoid1 = 2,
sd_commandhumanoid2 = 2,
sd_fortifyattributepersonality1 = 6,
sd_fortifyattributewillpower1 = 6,
sd_fortifyattributestrength1 = 6,
sd_fortifyattributespeed1 = 6,
sd_fortifyattributeagility1 = 6,
sd_fortifyattributeintelligence1 = 6,
sd_fortifyattributeluck1 = 6,
sd_fortifyattributeendurance1 = 6,
sd_fortifyattributepersonality2 = 6,
sd_fortifyattributewillpower2 = 6,
sd_fortifyattributestrength2 = 6,
sd_fortifyattributespeed2 = 6,
sd_fortifyattributeagility2 = 6,
sd_fortifyattributeintelligence2 = 6,
sd_fortifyattributeluck2 = 6,
sd_fortifyattributeendurance2 = 6,
sd_weaknesstocommondisease1 = 4,
sd_weaknesstocommondisease2 = 4,
sd_frenzycreature1 = 5,
sd_frenzycreature2 = 5,
sd_weaknesstonormalweapons1 = 3,
sd_weaknesstonormalweapons2 = 3,
sd_fireshield1 = 5,
sd_fireshield2 = 5,
sd_sanctuary1 = 5,
sd_sanctuary2 = 5,
sd_slowfall1 = 4,
sd_slowfall2 = 4,
sd_calmhumanoid1 = 5,
sd_calmhumanoid2 = 5,
sd_fortifyfatigue1 = 6,
sd_fortifyfatigue2 = 6,
sd_restoreskillbluntweapon1 = 4,
sd_restoreskillaxe1 = 4,
sd_restoreskillarmorer1 = 4,
sd_restoreskillrestoration1 = 4,
sd_restoreskillenchant1 = 4,
sd_restoreskillathletics1 = 4,
sd_restoreskillmarksman1 = 4,
sd_restoreskillmediumarmor1 = 4,
sd_restoreskillunarmored1 = 4,
sd_restoreskillspear1 = 4,
sd_restoreskillalteration1 = 4,
sd_restoreskilldestruction1 = 4,
sd_restoreskillspeechcraft1 = 4,
sd_restoreskillshortblade1 = 4,
sd_restoreskilllongblade1 = 4,
sd_restoreskillmysticism1 = 4,
sd_restoreskillsecurity1 = 4,
sd_restoreskillillusion1 = 4,
sd_restoreskillblock1 = 4,
sd_restoreskilllightarmor1 = 4,
sd_restoreskillheavyarmor1 = 4,
sd_restoreskillhandtohand1 = 4,
sd_restoreskillalchemy1 = 4,
sd_restoreskillsneak1 = 4,
sd_restoreskillconjuration1 = 4,
sd_restoreskillacrobatics1 = 4,
sd_restoreskillmercantile1 = 4,
sd_restoreskillbluntweapon2 = 4,
sd_restoreskillaxe2 = 4,
sd_restoreskillarmorer2 = 4,
sd_restoreskillrestoration2 = 4,
sd_restoreskillenchant2 = 4,
sd_restoreskillathletics2 = 4,
sd_restoreskillmarksman2 = 4,
sd_restoreskillmediumarmor2 = 4,
sd_restoreskillunarmored2 = 4,
sd_restoreskillspear2 = 4,
sd_restoreskillalteration2 = 4,
sd_restoreskilldestruction2 = 4,
sd_restoreskillspeechcraft2 = 4,
sd_restoreskillshortblade2 = 4,
sd_restoreskilllongblade2 = 4,
sd_restoreskillmysticism2 = 4,
sd_restoreskillsecurity2 = 4,
sd_restoreskillillusion2 = 4,
sd_restoreskillblock2 = 4,
sd_restoreskilllightarmor2 = 4,
sd_restoreskillheavyarmor2 = 4,
sd_restoreskillhandtohand2 = 4,
sd_restoreskillalchemy2 = 4,
sd_restoreskillsneak2 = 4,
sd_restoreskillconjuration2 = 4,
sd_restoreskillacrobatics2 = 4,
sd_restoreskillmercantile2 = 4,
sd_restoremagicka1 = 2,
sd_restoremagicka2 = 2,
sd_restoreattributepersonality1 = 4,
sd_restoreattributewillpower1 = 4,
sd_restoreattributestrength1 = 4,
sd_restoreattributespeed1 = 4,
sd_restoreattributeagility1 = 4,
sd_restoreattributeintelligence1 = 4,
sd_restoreattributeluck1 = 4,
sd_restoreattributeendurance1 = 4,
sd_restoreattributepersonality2 = 4,
sd_restoreattributewillpower2 = 4,
sd_restoreattributestrength2 = 4,
sd_restoreattributespeed2 = 4,
sd_restoreattributeagility2 = 4,
sd_restoreattributeintelligence2 = 4,
sd_restoreattributeluck2 = 4,
sd_restoreattributeendurance2 = 4,
sd_resistcommondisease1 = 6,
sd_resistcommondisease2 = 6,
sd_drainattributepersonality1 = 4,
sd_drainattributewillpower1 = 4,
sd_drainattributestrength1 = 4,
sd_drainattributespeed1 = 4,
sd_drainattributeagility1 = 4,
sd_drainattributeintelligence1 = 4,
sd_drainattributeluck1 = 4,
sd_drainattributeendurance1 = 4,
sd_drainattributepersonality2 = 4,
sd_drainattributewillpower2 = 4,
sd_drainattributestrength2 = 4,
sd_drainattributespeed2 = 4,
sd_drainattributeagility2 = 4,
sd_drainattributeintelligence2 = 4,
sd_drainattributeluck2 = 4,
sd_drainattributeendurance2 = 4,
sd_resistfrost1 = 5,
sd_resistfrost2 = 5,
sd_resistshock1 = 5,
sd_resistshock2 = 5,
sd_restorehealth1 = 2,
sd_restorehealth2 = 2,
sd_nighteye1 = 7,
sd_nighteye2 = 7,
sd_frostshield1 = 5,
sd_frostshield2 = 5,
sd_resistnormalweapons1 = 4,
sd_resistnormalweapons2 = 4,
sd_damagefatigue1 = 2,
sd_damagefatigue2 = 2,
sd_demoralizecreature1 = 5,
sd_demoralizecreature2 = 5,
sd_telekinesis1 = 7,
sd_telekinesis2 = 7,
sd_resistmagicka1 = 5,
sd_resistmagicka2 = 5,
sd_fortifyskillbluntweapon1 = 6,
sd_fortifyskillaxe1 = 6,
sd_fortifyskillarmorer1 = 6,
sd_fortifyskillrestoration1 = 6,
sd_fortifyskillenchant1 = 6,
sd_fortifyskillathletics1 = 6,
sd_fortifyskillmarksman1 = 6,
sd_fortifyskillmediumarmor1 = 6,
sd_fortifyskillunarmored1 = 6,
sd_fortifyskillspear1 = 6,
sd_fortifyskillalteration1 = 6,
sd_fortifyskilldestruction1 = 6,
sd_fortifyskillspeechcraft1 = 6,
sd_fortifyskillshortblade1 = 6,
sd_fortifyskilllongblade1 = 6,
sd_fortifyskillmysticism1 = 6,
sd_fortifyskillsecurity1 = 6,
sd_fortifyskillillusion1 = 6,
sd_fortifyskillblock1 = 6,
sd_fortifyskilllightarmor1 = 6,
sd_fortifyskillheavyarmor1 = 6,
sd_fortifyskillhandtohand1 = 6,
sd_fortifyskillalchemy1 = 6,
sd_fortifyskillsneak1 = 6,
sd_fortifyskillconjuration1 = 6,
sd_fortifyskillacrobatics1 = 6,
sd_fortifyskillmercantile1 = 6,
sd_fortifyskillbluntweapon2 = 6,
sd_fortifyskillaxe2 = 6,
sd_fortifyskillarmorer2 = 6,
sd_fortifyskillrestoration2 = 6,
sd_fortifyskillenchant2 = 6,
sd_fortifyskillathletics2 = 6,
sd_fortifyskillmarksman2 = 6,
sd_fortifyskillmediumarmor2 = 6,
sd_fortifyskillunarmored2 = 6,
sd_fortifyskillspear2 = 6,
sd_fortifyskillalteration2 = 6,
sd_fortifyskilldestruction2 = 6,
sd_fortifyskillspeechcraft2 = 6,
sd_fortifyskillshortblade2 = 6,
sd_fortifyskilllongblade2 = 6,
sd_fortifyskillmysticism2 = 6,
sd_fortifyskillsecurity2 = 6,
sd_fortifyskillillusion2 = 6,
sd_fortifyskillblock2 = 6,
sd_fortifyskilllightarmor2 = 6,
sd_fortifyskillheavyarmor2 = 6,
sd_fortifyskillhandtohand2 = 6,
sd_fortifyskillalchemy2 = 6,
sd_fortifyskillsneak2 = 6,
sd_fortifyskillconjuration2 = 6,
sd_fortifyskillacrobatics2 = 6,
sd_fortifyskillmercantile2 = 6,
sd_frenzyhumanoid1 = 5,
sd_frenzyhumanoid2 = 5,
sd_absorbhealth1 = 3,
sd_absorbhealth2 = 3,
sd_waterbreathing1 = 1,
sd_waterbreathing2 = 1,
sd_shockdamage1 = 2,
sd_shockdamage2 = 2,
sd_detectkey1 = 7,
sd_detectkey2 = 7,
sd_resistparalysis1 = 5,
sd_resistparalysis2 = 5,
sd_demoralizehumanoid1 = 5,
sd_demoralizehumanoid2 = 5,
sd_lightningshield1 = 5,
sd_lightningshield2 = 5,
sd_commandcreature1 = 2,
sd_commandcreature2 = 2,
sd_resistfire1 = 5,
sd_resistfire2 = 5,
sd_fortifyattack1 = 6,
sd_fortifyattack2 = 6,
sd_resistpoison1 = 5,
sd_resistpoison2 = 5,
sd_detectenchantment1 = 7,
sd_detectenchantment2 = 7,
sd_weaknesstopoison1 = 4,
sd_weaknesstopoison2 = 4,
sd_absorbfatigue1 = 3,
sd_absorbfatigue2 = 3,
sd_resistblightdisease1 = 6,
sd_resistblightdisease2 = 6,
sd_burden1 = 5,
sd_burden2 = 5,
sd_sundamage1 = 2,
sd_sundamage2 = 2,
sd_restorefatigue1 = 2,
sd_restorefatigue2 = 2,
sd_weaknesstomagicka1 = 3,
sd_weaknesstomagicka2 = 3,
sd_frostdamage1 = 2,
sd_frostdamage2 = 2,
sd_fortifyhealth1 = 5,
sd_fortifyhealth2 = 5,
sd_rallyhumanoid1 = 8,
sd_rallyhumanoid2 = 8,
sd_feather1 = 6,
sd_feather2 = 6,
sd_absorbattributepersonality1 = 3,
sd_absorbattributewillpower1 = 3,
sd_absorbattributestrength1 = 3,
sd_absorbattributespeed1 = 3,
sd_absorbattributeagility1 = 3,
sd_absorbattributeintelligence1 = 3,
sd_absorbattributeluck1 = 3,
sd_absorbattributeendurance1 = 3,
sd_absorbattributepersonality2 = 3,
sd_absorbattributewillpower2 = 3,
sd_absorbattributestrength2 = 3,
sd_absorbattributespeed2 = 3,
sd_absorbattributeagility2 = 3,
sd_absorbattributeintelligence2 = 3,
sd_absorbattributeluck2 = 3,
sd_absorbattributeendurance2 = 3,
sd_shield1 = 5,
sd_shield2 = 5,
sd_jump1 = 5,
sd_jump2 = 5,
sd_charm1 = 2,
sd_charm2 = 2,
sd_chameleon1 = 5,
sd_chameleon2 = 5,
}

--maxlength	32

local function createStew(data)
	local player = data[1]
	local foodData = data[2]
	local dbName = foodData.foodValue.."-"..foodData.drinkValue.."-"..foodData.wakeValue.."-"..tostring(foodData.isToxic).."-"..tostring(foodData.isGreenPact)
	
	--if not saveData.foodDB[dbName] then
		local tmpl = types.Potion.record("sd_waterbottle_template")
		
		local infoBracket = math.floor(foodData.foodValue+0.5)
		if foodData.wakeValue > 0 then
			infoBracket = infoBracket.."/"..math.floor(foodData.drinkValue+0.5).."/"..math.floor(foodData.wakeValue+0.5)
		elseif foodData.drinkValue > 0 then
			infoBracket = infoBracket.."/"..math.floor(foodData.drinkValue+0.5)
		end
		
		local newEffects = {}
		
		for uniqueId, effectData in pairs(foodData.dynamicEffects) do
			local magnitude = effectData.magnitude
			if math.random() < magnitude%1 then
				magnitude = magnitude + 1
			end
			local step = 1
			local maxBits = longBits[uniqueId] or 0
			
			if foodData.shortBuff then
				step = 5
				maxBits = shortBits[uniqueId] or 0
				magnitude = math.floor(magnitude / 5 + 0.5) * 5 -- Round to nearest multiple of 5
				if effectData.successfulContributors and effectData.successfulContributors > 0 then
					magnitude = math.max(5, magnitude)
				end
			else
				magnitude = math.floor(magnitude)
			end
			
			local maxMagnitude = step * (2^maxBits - 1)

			magnitude = math.min(maxMagnitude, magnitude)
			
			if magnitude >= step then --(min mag of 1 or 5)
				local sourcePotion = types.Potion.records[uniqueId]
				if sourcePotion then
					if foodData.shortBuff then
						table.insert(newEffects, sourcePotion.effects[math.floor(magnitude/5)])
					else
						for _, pos in pairs(toBitPositions(magnitude, step)) do
							table.insert(newEffects, sourcePotion.effects[pos])
						end
					end
				end
			end
		end
		
		local recordDraft = types.Potion.createRecordDraft({
			name    = "Stew ["..infoBracket.."]",
			template= tmpl,
			model   = "meshes/SunsDusk/contain_couldron10.nif",
			icon    = "icons/SunsDusk/cooking_pot.dds",
			weight  = 1,
			value   = 30,
			effects = newEffects,
		})
		
		local rec  = world.createRecord(recordDraft)
		local newId = rec.id
		saveData.foodDB[dbName] = rec.id
		player:sendEvent("SunsDusk_addConsumable", {rec.id, {
				recordType 		    = "Potion", 
				localizedName	    = "Stew ["..infoBracket.."]", 
				consumeCategory     = foodData.consumeCategory, 
				foodValue 		    = foodData.foodValue or 0, 
				foodValue2 		    = foodData.foodValue2 or 0, 
				drinkValue 		    = foodData.drinkValue or 0, 
				drinkValue2 		= foodData.drinkValue2 or 0, 
				wakeValue		    = foodData.wakeValue or 0,
				wakeValue2		    = foodData.wakeValue2 or 0,
				isToxic    			= foodData.isToxic,
				isGreenPact   		= foodData.isGreenPact,
				isCookedMeal 		= true,
			}}
		)
	--end
	world.createObject(saveData.foodDB[dbName], foodData.count):moveInto(types.Actor.inventory(player))
end

local function consumeIngredients(data)
	local player = data[1]
	local ingredients = data[2]
	for _, item in pairs(types.Actor.inventory(player):getAll()) do
		if ingredients[item.recordId] then
			item:remove(ingredients[item.recordId])
		end
	end
end
-- ──────────────────────────────────────────────────────────────── Lifecycle ──────────────────────────────────────────────────────────────
-- versions drift like ash but we hold the save
local function migrate_v1_to_v2(sd)
	-- v1 -> v2: waterDB -> liquidDB['water']; reverse adds liquid='water'
	
end

local function onLoad(data)
	saveData = data or {}
	saveData.maxQ                  = saveData.maxQ                  or {}
	saveData.reverse              = saveData.reverse              or {}
	saveData.convertedCellsWater  = saveData.convertedCellsWater  or {}
	saveData.convertedNPCsWater   = saveData.convertedNPCsWater   or {}

	-- migration and container sanity
	if not saveData.liquidDB then
		saveData.liquidDB = {}
	
		if saveData.waterDB then
			saveData.liquidDB.water = saveData.waterDB
			saveData.waterDB = nil
		else
			saveData.liquidDB.water = {}
		end
		
		for pid, info in pairs(saveData.reverse) do
			if info and info.orig and info.q and not info.liquid then
				info.liquid = 'water'
			end
		end
	end
	
	if not saveData.foodDB then
		saveData.foodDB = {}
	end
	
	saveData.liquidDB = saveData.liquidDB or { water = {} }

end

local function onSave()
	return saveData
end


-- ───────────────────────────────────────────────────────────── Utility Events ──────────────────────────────────────────────────────────
-- creatures of the night and moon enjoyers. a quick ping
local function checkIfVampireWerewolf(player)
	local gv       = world.mwscript.getGlobalVariables(player)
	local vampire  = gv.PCVampire
	local werewolf = gv.PCWerewolf
	player:sendEvent("SunsDusk_checkedIfVampireWerewolf", { vampire, werewolf })
end

-- ───────────────────────────────────────────────────────────── Registrations ─────────────────────────────────────────────────────────
-- tie the knots. let the engine tug
return {
	engineHandlers = {
		onLoad        = onLoad,
		onInit        = onLoad,
		onSave        = onSave,
		onObjectActive= onObjectActive,
		onUpdate	  = onUpdate,
	},
	eventHandlers = {
		SunsDusk_Unhook                              = unhookObject,
		SunsDusk_WaterBottles_convertMiscInCell     = convertMiscInCell,
		SunsDusk_WaterBottles_downgradeWaterItem    = downgradeWaterItem,
		SunsDusk_WaterBottles_spillWater            = spillWater,
		SunsDusk_WaterBottles_refillBottlesWell     = refillBottlesWell,
		SunsDusk_WaterBottles_refillSpillables      = refillSpillables,
		SunsDusk_WaterBottles_consumeWater			= consumeWater,
		SunsDusk_checkIfVampireWerewolf             = checkIfVampireWerewolf,
		SunsDusk_createStew							= createStew,
		SunsDusk_consumeIngredients					= consumeIngredients,
	},
}
