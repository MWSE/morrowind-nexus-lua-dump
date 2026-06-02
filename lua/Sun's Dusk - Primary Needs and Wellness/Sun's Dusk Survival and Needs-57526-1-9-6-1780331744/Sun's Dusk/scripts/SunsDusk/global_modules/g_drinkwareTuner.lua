-- dormant until 'lua drinkwaretuner [min|max]' is typed in console (see sd_p onConsoleCommand)

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Drinkware Tuner                                                      │
-- │ Tunes minOffset/minScale and maxOffset/maxScale for liquid visuals   │
-- │ MODE = 1 for minimum fill, MODE = 2 for maximum fill                 │
-- ╰──────────────────────────────────────────────────────────────────────╯

local WATER_STATIC_ID = "sd_food_water_tuner"

-- MODE: 1 = min fill level, 2 = max fill level; default max, overridden by command arg
local MODE = 2

-- spawn every qualifying vessel, ignoring which entries already exist
local SPAWN_ALL = false

-- work on batches of vessels. 
-- ideal workflow: dont blacklist them on your first pass ("lua drinkwaretuner max")
-- this way you get exactly the same set of vessels on your second pass ("lua drinkwaretuner min")
-- on the second pass, blacklist what's applicable
local MAX_NEW_VESSELS = 999

local vesselOffsets = require("scripts.SunsDusk.lib.drinkwareOffsets")
local offsetTracker = {}      -- [vesselId] = { minOffset, minScale, maxOffset, maxScale, waterObj }
local vesselObjToId = {}      -- [vesselObj.id] = vesselId
local waterObjToId = {}       -- [waterObj.id] = vesselId
local blacklist = {}          -- [vesselId] = true
local blacklistHistory = {}   -- LIFO stack of blacklisted vesselIds for restore

local function getVesselId(obj)
	if not obj then return nil end
	return vesselObjToId[obj.id] or waterObjToId[obj.id]
end

local scaleStep = 0.005
local teleportStep = 0.5

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Vessel Detection (mirrored from g_liquids.lua)                       │
-- ╰──────────────────────────────────────────────────────────────────────╯

local BLACKLIST_SUBSTRINGS = { 'broken', 't_com_paintpot' }
local SUBSTRINGS = { 
	'flask', 'beaker', 'cup', 'goblet', 'pitcher', 'tankard', 
	'misc_de_glass', 'drinkinghorn', 't_com_potionbottle_', 'vial', 'mug',
}
local INVENTORY_SUBSTRINGS = { 'bottle', 'canteen', 'misc_flask_03', 'waterskin', 'kettle' }
local ZERO_CHANCE_SUBSTRINGS = { 'bucket' }
local LOW_CHANCE_SUBSTRINGS = { 'vase', 'pot' }
local BLACKLIST = {
	["t_he_direnniflask_07c"] = true,
	["t_he_direnniflask_06f"] = true,
	["tr_m1_ito_fw_keyapothecary"] = true,
	["tr_m2_key_smugeler_ln"] = true,
	["t_com_inkvial_01"] = true,
	["pc_m1_ip_lki4_keyscupper"] = true,
}

local function hasKeyword(hay, kw)
	if not hay then return false end
	return string.find(hay, kw, 1, true) ~= nil
end

local function isQualifyingVessel(rec)
	if not rec then return false end
	
	local id = rec.id
	
	if G_teapotIds[id] or G_coffeePotIds[id] then
		return true
	end
	
	if id:sub(1,3) == "Gen" then print(id) return false end
	local name = (rec.name or ''):lower()
	
	if rec.mwscript then return false end
	if BLACKLIST[id] then return false end
	
	for _, sub in ipairs(BLACKLIST_SUBSTRINGS) do
		if hasKeyword(id, sub) or hasKeyword(name, sub) then
			return false
		end
	end
	
	-- Check all vessel types
	for _, sub in ipairs(SUBSTRINGS) do
		if hasKeyword(id, sub) or hasKeyword(name, sub) then
			return true
		end
	end
	for _, sub in ipairs(INVENTORY_SUBSTRINGS) do
		if hasKeyword(id, sub) or hasKeyword(name, sub) then
			return true
		end
	end
	for _, sub in ipairs(ZERO_CHANCE_SUBSTRINGS) do
		if hasKeyword(id, sub) or hasKeyword(name, sub) then
			return true
		end
	end
	for _, sub in ipairs(LOW_CHANCE_SUBSTRINGS) do
		if hasKeyword(id, sub) or hasKeyword(name, sub) then
			return true
		end
	end
	
	return false
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Offset Calculation (fallback from bounding box)                      │
-- ╰──────────────────────────────────────────────────────────────────────╯

local defaultParams = {
	minZFraction = 0.35,
	maxZFraction = 0.80,
	baseScaleMult = 0.007,
}

local function calculateDefaultOffset(vesselObj, mode)
	local bbox = vesselObj:getBoundingBox()
	local shortestSide = math.min(bbox.halfSize.x * 2, bbox.halfSize.y * 2)
	local baseScale = shortestSide * 1.414 * defaultParams.baseScaleMult
	
	local zFraction = mode == 1 and defaultParams.minZFraction or defaultParams.maxZFraction
	local z = bbox.halfSize.z * 2 * zFraction
	local offset = bbox.center - vesselObj.position + util.vector3(0, 0, z - bbox.halfSize.z)
	
	return offset, baseScale
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Print Functions                                                      │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function printOffset(obj)
	local vesselId = getVesselId(obj)
	if not vesselId then
		print("ERROR: Object not tracked")
		return
	end
	
	local data = offsetTracker[vesselId]
	local modeStr = MODE == 1 and "MIN" or "MAX"
	local offset = MODE == 1 and data.minOffset or data.maxOffset
	local scale = MODE == 1 and data.minScale or data.maxScale
	
	print(string.format("Vessel: %s [%s fill]", vesselId, modeStr))
	print(string.format("  offset = util.vector3(%.2f, %.2f, %.2f)", offset.x, offset.y, offset.z))
	print(string.format("  scale = %.3f", scale))
end

local function printAllOffsets()
	local modeStr = MODE == 1 and "MIN" or "MAX"
	print(string.format("=== Vessel Offsets [%s fill mode] ===", modeStr))
	print("-- Paste into scripts/SunsDusk/lib/drinkwareOffsets.lua (replaces the returned table)")
	print("")
	print("return {")
	
	local count = 0
	local blacklistCount = 0
	
	-- collect all vessel ids from both tracker and presets
	local allVesselIds = {}
	for vesselId in pairs(offsetTracker) do
		allVesselIds[vesselId] = true
	end
	for vesselId in pairs(vesselOffsets) do
		allVesselIds[vesselId] = true
	end

	-- split into blacklisted and rest, each sorted alphabetically
	local blacklistedIds = {}
	local tunedIds = {}
	for vesselId in pairs(allVesselIds) do
		if blacklist[vesselId] or vesselOffsets[vesselId] == false then
			blacklistedIds[#blacklistedIds + 1] = vesselId
		else
			tunedIds[#tunedIds + 1] = vesselId
		end
	end
	table.sort(blacklistedIds)
	table.sort(tunedIds)

	-- blacklisted first
	for _, vesselId in ipairs(blacklistedIds) do
		blacklistCount = blacklistCount + 1
		print(string.format('	["%s"] = false,', vesselId))
	end

	-- tuned vessels
	for _, vesselId in ipairs(tunedIds) do
		local data = offsetTracker[vesselId]
		if data then
			count = count + 1
			-- current mode emits its tuned values; other mode kept from preset
			local preset = vesselOffsets[vesselId]
			local minOffset = MODE == 1 and data.minOffset or (preset and preset.minOffset)
			local minScale  = MODE == 1 and data.minScale  or (preset and preset.minScale)
			local maxOffset = MODE == 2 and data.maxOffset or (preset and preset.maxOffset)
			local maxScale  = MODE == 2 and data.maxScale  or (preset and preset.maxScale)
			print(string.format('	["%s"] = {', vesselId))
			if minOffset then
				print(string.format('		minOffset = util.vector3(%.2f, %.2f, %.2f),', minOffset.x, minOffset.y, minOffset.z))
			end
			if minScale then
				print(string.format('		minScale = %.3f,', minScale))
			end
			if maxOffset then
				print(string.format('		maxOffset = util.vector3(%.2f, %.2f, %.2f),', maxOffset.x, maxOffset.y, maxOffset.z))
			end
			if maxScale then
				print(string.format('		maxScale = %.3f,', maxScale))
			end
			print("	},")
		else
			-- not spawned this session; keep existing preset as-is
			local preset = vesselOffsets[vesselId]
			if preset then
				count = count + 1
				print(string.format('	["%s"] = {', vesselId))
				if preset.minOffset then
					print(string.format('		minOffset = util.vector3(%.2f, %.2f, %.2f),', preset.minOffset.x, preset.minOffset.y, preset.minOffset.z))
				end
				if preset.minScale then
					print(string.format('		minScale = %.3f,', preset.minScale))
				end
				if preset.maxOffset then
					print(string.format('		maxOffset = util.vector3(%.2f, %.2f, %.2f),', preset.maxOffset.x, preset.maxOffset.y, preset.maxOffset.z))
				end
				if preset.maxScale then
					print(string.format('		maxScale = %.3f,', preset.maxScale))
				end
				print("	},")
			end
		end
	end
	
	print("}")
	print(string.format("-- Total: %d vessel(s), %d blacklisted", count, blacklistCount))
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Tuning Functions                                                     │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function scaleUp(payload)
	local obj = payload.obj
	local amount = scaleStep * (payload.mult or 1.0)
	local vesselId = getVesselId(obj)
	if not vesselId then return end
	
	local data = offsetTracker[vesselId]
	local waterObj = data.waterObj
	local newScale = (waterObj.scale or 1.0) + amount
	waterObj:setScale(newScale)
	
	if MODE == 1 then
		data.minScale = newScale
	else
		data.maxScale = newScale
	end
	
	print(string.format("Scaled up to %.3f (+%.3f)", newScale, amount))
	printOffset(obj)
end

local function scaleDown(payload)
	local obj = payload.obj
	local amount = scaleStep * (payload.mult or 1.0)
	local vesselId = getVesselId(obj)
	if not vesselId then return end
	
	local data = offsetTracker[vesselId]
	local waterObj = data.waterObj
	local newScale = math.max(0.01, (waterObj.scale or 1.0) - amount)
	waterObj:setScale(newScale)
	
	if MODE == 1 then
		data.minScale = newScale
	else
		data.maxScale = newScale
	end
	
	print(string.format("Scaled down to %.3f (-%.3f)", newScale, amount))
	printOffset(obj)
end

local function moveUp(payload)
	local obj = payload.obj
	local amount = teleportStep * (payload.mult or 1.0)
	local vesselId = getVesselId(obj)
	if not vesselId then return end
	
	local data = offsetTracker[vesselId]
	local waterObj = data.waterObj
	local pos = waterObj.position
	waterObj:teleport(waterObj.cell, util.vector3(pos.x, pos.y, pos.z + amount), {onGround = false})
	
	if MODE == 1 then
		data.minOffset = util.vector3(data.minOffset.x, data.minOffset.y, data.minOffset.z + amount)
	else
		data.maxOffset = util.vector3(data.maxOffset.x, data.maxOffset.y, data.maxOffset.z + amount)
	end
	
	print(string.format("Moved up by %.2f", amount))
	printOffset(obj)
end

local function moveDown(payload)
	local obj = payload.obj
	local amount = teleportStep * (payload.mult or 1.0)
	local vesselId = getVesselId(obj)
	if not vesselId then return end
	
	local data = offsetTracker[vesselId]
	local waterObj = data.waterObj
	local pos = waterObj.position
	waterObj:teleport(waterObj.cell, util.vector3(pos.x, pos.y, pos.z - amount), {onGround = false})
	
	if MODE == 1 then
		data.minOffset = util.vector3(data.minOffset.x, data.minOffset.y, data.minOffset.z - amount)
	else
		data.maxOffset = util.vector3(data.maxOffset.x, data.maxOffset.y, data.maxOffset.z - amount)
	end
	
	print(string.format("Moved down by %.2f", amount))
	printOffset(obj)
end

local function moveRight(payload)
	local obj = payload.obj
	local amount = teleportStep * (payload.mult or 1.0)
	local vesselId = getVesselId(obj)
	if not vesselId then return end
	
	local data = offsetTracker[vesselId]
	local waterObj = data.waterObj
	local pos = waterObj.position
	waterObj:teleport(waterObj.cell, util.vector3(pos.x + amount, pos.y, pos.z), {onGround = false})
	
	if MODE == 1 then
		data.minOffset = util.vector3(data.minOffset.x + amount, data.minOffset.y, data.minOffset.z)
	else
		data.maxOffset = util.vector3(data.maxOffset.x + amount, data.maxOffset.y, data.maxOffset.z)
	end
	
	print(string.format("Moved right by %.2f", amount))
	printOffset(obj)
end

local function moveLeft(payload)
	local obj = payload.obj
	local amount = teleportStep * (payload.mult or 1.0)
	local vesselId = getVesselId(obj)
	if not vesselId then return end
	
	local data = offsetTracker[vesselId]
	local waterObj = data.waterObj
	local pos = waterObj.position
	waterObj:teleport(waterObj.cell, util.vector3(pos.x - amount, pos.y, pos.z), {onGround = false})
	
	if MODE == 1 then
		data.minOffset = util.vector3(data.minOffset.x - amount, data.minOffset.y, data.minOffset.z)
	else
		data.maxOffset = util.vector3(data.maxOffset.x - amount, data.maxOffset.y, data.maxOffset.z)
	end
	
	print(string.format("Moved left by %.2f", amount))
	printOffset(obj)
end

local function moveForward(payload)
	local obj = payload.obj
	local amount = teleportStep * (payload.mult or 1.0)
	local vesselId = getVesselId(obj)
	if not vesselId then return end
	
	local data = offsetTracker[vesselId]
	local waterObj = data.waterObj
	local pos = waterObj.position
	waterObj:teleport(waterObj.cell, util.vector3(pos.x, pos.y + amount, pos.z), {onGround = false})
	
	if MODE == 1 then
		data.minOffset = util.vector3(data.minOffset.x, data.minOffset.y + amount, data.minOffset.z)
	else
		data.maxOffset = util.vector3(data.maxOffset.x, data.maxOffset.y + amount, data.maxOffset.z)
	end
	
	print(string.format("Moved forward by %.2f", amount))
	printOffset(obj)
end

local function moveBack(payload)
	local obj = payload.obj
	local amount = teleportStep * (payload.mult or 1.0)
	local vesselId = getVesselId(obj)
	if not vesselId then return end
	
	local data = offsetTracker[vesselId]
	local waterObj = data.waterObj
	local pos = waterObj.position
	waterObj:teleport(waterObj.cell, util.vector3(pos.x, pos.y - amount, pos.z), {onGround = false})
	
	if MODE == 1 then
		data.minOffset = util.vector3(data.minOffset.x, data.minOffset.y - amount, data.minOffset.z)
	else
		data.maxOffset = util.vector3(data.maxOffset.x, data.maxOffset.y - amount, data.maxOffset.z)
	end
	
	print(string.format("Moved back by %.2f", amount))
	printOffset(obj)
end

-- buries or unburies both the vessel and its water; safe on missing/invalid objs
local function shiftPair(data, dz)
	for _, obj in ipairs({ data.waterObj, data.vesselObj }) do
		if obj and obj:isValid() then
			local p = obj.position
			obj:teleport(obj.cell, util.vector3(p.x, p.y, p.z + dz), {onGround = false})
		end
	end
end

local function blacklistVessel(obj)
	-- no focus: restore most recently blacklisted
	if not obj then
		local vesselId = table.remove(blacklistHistory)
		if not vesselId then
			print("Nothing to restore")
			return
		end
		blacklist[vesselId] = nil
		local data = offsetTracker[vesselId]
		if data then shiftPair(data, 10000) end
		print(string.format("RESTORED: %s", vesselId))
		return
	end

	local vesselId = getVesselId(obj)
	if not vesselId then
		print("ERROR: Object not tracked")
		return
	end

	-- focused vessel: bury it and push to restore stack
	if not blacklist[vesselId] then
		blacklist[vesselId] = true
		blacklistHistory[#blacklistHistory + 1] = vesselId
	end
	local data = offsetTracker[vesselId]
	if data then shiftPair(data, -10000) end
	print(string.format("ADDED to blacklist: %s", vesselId))
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Event Handlers                                                       │
-- ╰──────────────────────────────────────────────────────────────────────╯

G_eventHandlers.scaleUp = scaleUp
G_eventHandlers.scaleDown = scaleDown
G_eventHandlers.moveUp = moveUp
G_eventHandlers.moveDown = moveDown
G_eventHandlers.moveLeft = moveLeft
G_eventHandlers.moveRight = moveRight
G_eventHandlers.moveForward = moveForward
G_eventHandlers.moveBack = moveBack
G_eventHandlers.toggleBlacklist = blacklistVessel
G_eventHandlers.printAllOffsets = printAllOffsets

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Vessel Collection & Spawning                                         │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function collectAllVessels()
	local vessels = {}
	local newVessels = 0
	for _, rec in ipairs(types.Miscellaneous.records) do
		if isQualifyingVessel(rec) then
			-- spawn vessels missing the current mode's entry (or all, if SPAWN_ALL); skip blacklisted
			local preset = vesselOffsets[rec.id]
			local needsTuning
			if preset == false then
				needsTuning = false
			elseif SPAWN_ALL then
				needsTuning = true
			elseif MODE == 1 then
				needsTuning = not (preset and preset.minOffset)
			else
				needsTuning = not (preset and preset.maxOffset)
			end
			if needsTuning and newVessels < MAX_NEW_VESSELS then
				newVessels = newVessels + 1
				table.insert(vessels, {
					id = rec.id,
					name = rec.name or rec.id,
				})
			end
		end
	end
	return vessels
end

local vesselList = {}   -- populated when tuning starts
local NUM_ROWS = 15
local SPACING_X = 35
local SPACING_Z = 35
local OFFSET_Y = 0

local function spawnVesselGrid(actor)
	local actorPos = actor.position
	local actorRot = actor.rotation
	
	local forward = actorRot * util.vector3(0, 1, 0)
	local right = actorRot * util.vector3(1, 0, 0)
	
	local itemsPerRow = math.ceil(#vesselList / NUM_ROWS)
	local currentIndex = 1
	local modeStr = MODE == 1 and "MIN" or "MAX"
	
	for row = 0, NUM_ROWS - 1 do
		local itemsInThisRow = math.min(itemsPerRow, #vesselList - currentIndex + 1)
		local rowStartOffset = -(itemsInThisRow - 1) * SPACING_X / 2
		
		for col = 0, itemsInThisRow - 1 do
			if currentIndex > #vesselList then break end
			
			local vessel = vesselList[currentIndex]
			local localX = rowStartOffset + (col * SPACING_X)
			local localZ = (row * SPACING_Z) + 100
			local spawnPos = actorPos + (forward * localZ) + (right * localX) + util.vector3(0, 0, OFFSET_Y)
			
			-- Spawn vessel
			local vesselObj = world.createObject(vessel.id)
			vesselObj:teleport(actor.cell, spawnPos, {onGround = false})
			
			-- Calculate defaults first
			local defMinOffset, defMinScale = calculateDefaultOffset(vesselObj, 1)
			local defMaxOffset, defMaxScale = calculateDefaultOffset(vesselObj, 2)
			
			-- use existing vesselOffsets if available, otherwise use defaults
			-- if only one mode is preset, borrow the other mode's x/y and scale (z from bbox)
			local preset = vesselOffsets[vessel.id]
			local presetMin = preset and preset.minOffset
			local presetMax = preset and preset.maxOffset
			local minOffset = presetMin
				or (presetMax and util.vector3(presetMax.x, presetMax.y, defMinOffset.z))
				or defMinOffset
			local minScale = (preset and preset.minScale)
				or (preset and preset.maxScale)
				or defMinScale
			local maxOffset = presetMax
				or (presetMin and util.vector3(presetMin.x, presetMin.y, defMaxOffset.z))
				or defMaxOffset
			local maxScale = (preset and preset.maxScale)
				or (preset and preset.minScale)
				or defMaxScale
			
			-- Spawn water static at current mode's fill position
			local spawnOffset = MODE == 1 and minOffset or maxOffset
			local spawnScale = MODE == 1 and minScale or maxScale
			
			local waterObj = world.createObject(WATER_STATIC_ID)
			waterObj:teleport(actor.cell, spawnPos + spawnOffset, {onGround = false})
			waterObj:setScale(spawnScale)
			
			-- Track for tuning (both vessel and water obj point to same vesselId)
			vesselObjToId[vesselObj.id] = vessel.id
			waterObjToId[waterObj.id] = vessel.id
			offsetTracker[vessel.id] = {
				minOffset = minOffset,
				minScale = minScale,
				maxOffset = maxOffset,
				maxScale = maxScale,
				waterObj = waterObj,
				vesselObj = vesselObj,
			}
			
			currentIndex = currentIndex + 1
		end
	end
	
	return string.format("%d vessels spawned in %d rows [%s fill mode]", #vesselList, NUM_ROWS, modeStr)
end

-- spawn the grid on the 'lua drinkwaretuner [min|max]' console command (see sd_p onConsoleCommand)
G_eventHandlers.spawnDrinkwareGrid = function(data)
	local actor = data.actor or data
	if data.mode == 1 or data.mode == 2 then
		MODE = data.mode
	end
	vesselList = collectAllVessels()
	print(string.format("[DrinkwareTuner] Found %d qualifying vessels (MODE=%d: %s fill)", #vesselList, MODE, MODE == 1 and "MIN" or "MAX"))
	local result = spawnVesselGrid(actor)
	print("[DrinkwareTuner] " .. result)
end

-- hotkeys live in sd_p onKeyPress, gated by G_drinkwareTuning
