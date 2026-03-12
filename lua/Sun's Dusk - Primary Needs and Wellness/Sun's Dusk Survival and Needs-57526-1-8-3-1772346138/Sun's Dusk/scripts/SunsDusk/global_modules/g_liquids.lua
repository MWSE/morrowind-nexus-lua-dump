openBottles = {
--	["misc_com_bottle_01"] = true,
--	["misc_com_bottle_02"] = true,
--	["misc_com_bottle_06"] = true,
--	["misc_com_bottle_09"] = true,
--	["misc_com_bottle_11"] = true,
--	["misc_com_bottle_13"] = true,
--	["misc_com_bottle_13"] = true,
	-- Starwind
}

openBottlesForSpawning = {
	["misc_com_bottle_01"] = true,
	["misc_com_bottle_02"] = true,
	["misc_com_bottle_06"] = true,
	["misc_com_bottle_09"] = true,
	["misc_com_bottle_11"] = true,
	["misc_com_bottle_13"] = true,
	["misc_com_bottle_13"] = true,
}

extraClosedBottles = {
	["misc_com_redware_flask"] = true,
	["ab_misc_waterskin"]	   = true,
}

-- maxVolumeQ: only vessels with Q <= this can roll the liquid
-- spawnChance: relative weight
-- valuePerQ: value added per Q

-- ALSO ADD TO localizedLiquidNames !!!
local LIQUIDS = {
	water = {
		templateId  = 'sd_waterbottle_template',
		displayName = 'Water',
		maxVolumeQ  = math.huge,
		spawnChance = 1.0,
		valuePerQ   = 1,
		static = 'sd_food_water',
	},
	saltWater = {
		templateId  = 'sd_saltwater_template',
		displayName = 'Saltwater',
		maxVolumeQ  = 0,
		spawnChance = 0,
		valuePerQ   = 1,
		static = 'sd_food_water',
	},
	susWater = {
		templateId  = 'sd_suswater_template',
		displayName = 'Suspicious Water',
		maxVolumeQ  = 0,
		spawnChance = 0,
		valuePerQ   = 1,
		static = 'sd_food_suswater',
	},
	sujamma = {
		templateId  = 'sd_sujamma_template',
		displayName = 'Sujamma',
		maxVolumeQ  = 2,	-- Q<=2 (<=500 ml per Q step*2) by default
		spawnChance = 0.3,  -- less common than water
		valuePerQ   = 6,	-- pricier kick
		static = 'sd_food_sujamma',
	},
	flin = {
		templateId  = 'sd_flin_template',
		displayName = 'Flin',
		maxVolumeQ  = 1,	-- Q<=1 (<=250 ml per Q step*2) by default
		spawnChance = 0.15, -- less common than sujamma
		valuePerQ   = 10,	-- pricier kick
		static = 'sd_food_flin',
	},
	-- Starwind: sd_bluemilk_template ; sd_bluebooze_template ; sd_banthamilk_template
	tea_SF = {
		templateId  = 'sd_tea_sf_template',
		displayName = 'Stoneflower Tea', -- name of the liquid
		maxVolumeQ  = 0,	-- not appearing randomly
		spawnChance = 0.80, -- ignored then
		valuePerQ   = 40,	-- pricy
		steaming = true,
		static = 'sd_food_tea_sf',
	},
	tea_H = {
		templateId  = 'sd_tea_h_template',
		displayName = 'Heather Tea', -- name of the liquid
		maxVolumeQ  = 0,	-- not appearing randomly
		spawnChance = 0.80, -- ignored then
		valuePerQ   = 40,	-- pricy
		steaming = true,
		static = 'sd_food_tea_h',
	},
--[[	tea_CR = {
		templateId  = 'sd_tea_cr_template',
		displayName = 'Canit Root Tea', -- name of the liquid
		maxVolumeQ  = 0,	-- not appearing randomly
		spawnChance = 0.80, -- ignored then
		valuePerQ   = 40,	-- pricy
	},
]]	
}


--mwscriptIds = {
--	"water",
--	"saltWater",
--	"susWater",
--	"sujamma",
--	"flin",
--	"tea_SF",
--	"tea_H",
--}
--
--local reverseMwscriptIds = {}
--for a,b in pairs(mwscriptIds) do
--	reverseMwscriptIds[b] = a
--end

-- teacup - Misc_Com_Redware_Cup ; AB_Misc_DeCeramicCup_02 // teapot - ceramicteapot ; AB_Misc_kettleceremonial ; AB_Misc_debugteapot

local vesselLiquids = {
	["misc_com_redware_cup"] 		= { "tea_SF", "tea_H" },
	["misc_de_pot_redware_03"] 		= { "tea_SF", "tea_H" },
--	["t_com_copperkettle_01"] 		= { "tea_SF", "tea_H" },
--	["t_com_coppetteapot_01"] 		= { "tea_SF", "tea_H" },
	["ab_misc_deceramiccup_01"] 	= { "tea_SF", "tea_H" },	
	["ab_misc_deceramiccup_02"] 	= { "tea_SF", "tea_H" },
	["ab_misc_deceramicflask_01"] 	= { "tea_SF", "tea_H" },	
--	["ab_misc_kettleceremonial"] 	= { "tea_SF", "tea_H" },
--	["ab_misc_debugteapot"] 		= { "tea_SF", "tea_H" },	
}
local unspillableLiquids = {
	'stoneflower tea',
	'heather tea',
--	'canis root tea',
}

-- Per-vessel visual offset/scale for liquid statics
-- minOffset/minScale = empty, maxOffset/maxScale = full
local vesselOffsets = require("scripts.SunsDusk.lib.drinkwareOffsets") --["ORIGINAL_VESSEL_RECORD_ID"] = false || {minOffset = v3, minScale = float, maxOffset = v3, maxScale = float}

-- Fallback offset calculation from bounding box for vessels not in table
local defaultVesselOffsetParams = {
	minZFraction = 0.25,  -- empty liquid sits at 25% height
	maxZFraction = 0.80,  -- full liquid sits at 80% height
	minScaleFactor = 1.0, -- empty scale multiplier
	maxScaleFactor = 1.0, -- full scale multiplier
	baseScaleMult = 0.043,
}

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Constants															  │
-- ╰──────────────────────────────────────────────────────────────────────╯
downgradedWorldObjects = {} --for world interaction workaround
local STEP_ML = 250

-- substrings -> fallback liters
local FALLBACK_LITERS = {
	bottle  		= 1.0,
	flask   		= 0.5,
	beaker  		= 0.5,
	cup	 			= 0.25,
	misc_de_glass   = 0.25,
	goblet  		= 0.25,
	pitcher 		= 0.75,
	tankard 		= 0.5,
	vase			= 2.0,
	bucket			= 4.0,
	teapot			= 1.0,
}

local ZERO_CHANCE_SUBSTRINGS = { 'bucket' }
local LOW_CHANCE_SUBSTRINGS  = { 'vase', 'pot' }
local SUBSTRINGS			 = { 
	'flask', 
	'beaker', 
	'cup', 
	'goblet', 
	'pitcher', 
	'tankard', 
	'misc_de_glass', 
	'drinkinghorn', 
	't_com_potionbottle_',
	'vial',
	'mug',
}
local INVENTORY_SUBSTRINGS   = { 'bottle', 'canteen', 'misc_flask_03', 'waterskin' }
local BLACKLIST_SUBSTRINGS   = { 'broken', 't_com_paintpot' }
local BLACKLIST = {
	["t_he_direnniflask_07c"] = true,
	["t_he_direnniflask_06f"] = true,
	["tr_m1_ito_fw_keyapothecary"] = true,
	["tr_m2_key_smugeler_ln"] = true,
	["t_com_inkvial_01"] = true,
}
-- Starwind

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Utils																  │
-- ╰──────────────────────────────────────────────────────────────────────╯

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



-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Cell Water Type Resolution (global-side)							  │
-- ╰──────────────────────────────────────────────────────────────────────╯

require('scripts.SunsDusk.lib.temp_water_sources') -- provides WATER_BODIES

local VIVEC_POSITION = util.vector3(32467.130859, -90863.234375, 100)
local VIVEC_RADIUS = 20000

-- Resolve water type for a cell, mirroring the player-side logic
-- in p_liquids.lua but usable from the global script (e.g. for objects in
-- adjacent exterior cells). Results are cached per cell.id.
local waterTypeCache = {}

table.insert(G_settingsChangedJobs, function(sectionName)
	if sectionName == "SettingsSunsDuskWATER" then
		waterTypeCache = {}
	end
end)

function resolveWaterType(cell, position)
	if not cell then return "water" end

	local cached = waterTypeCache[cell.id]
	if cached then return cached end

	if WATER_CLEAN_ALWAYS then
		waterTypeCache[cell.id] = "water"
		return "water"
	end

	-- ═══ Interior ═══
	if not cell.isExterior then
		local info = G_cellInfoCache and G_cellInfoCache[cell.id]
		if not info then return "water" end -- not yet classified, don't cache

		-- Quasi-exterior: fall through to exterior logic
		if info.isExterior then
			-- fall through below
		else
			local waterType

			if info.isSewer then waterType = "susWater"
			elseif info.isBath    then waterType = "water"
			elseif info.isTemple  then waterType = "water"
			elseif info.isHouse   then waterType = "water"
			elseif info.isCastle  then waterType = "water"
			elseif info.isHlaalu  then waterType = "water"
			elseif info.isRedoran then waterType = "water"
			elseif info.isMushroom then waterType = "water"
			elseif info.isDaedric and not WATER_CLEAN_DUNGEONS then waterType = "susWater"
			elseif info.isDwemer  and not WATER_CLEAN_DUNGEONS then waterType = "susWater"
			elseif info.isTomb    and not WATER_CLEAN_DUNGEONS then waterType = "susWater"
			elseif info.isMine    and not WATER_CLEAN_DUNGEONS then waterType = "susWater"
			elseif info.isIceCave then waterType = "water"
			elseif info.isCave    and not WATER_CLEAN_DUNGEONS then waterType = "susWater"
			else waterType = "water"
			end

			waterTypeCache[cell.id] = waterType
			return waterType
		end
	end

	-- ═══ Exterior (+ quasi-exterior fallthrough) ═══
	local pos = position
	local maxWaterInfluence = 0
	local maxWaterType = nil

	for _, source in ipairs(WATER_BODIES) do
		local distance = (pos - source.position):length()
		if distance < source.radius then
			local influence = distance / source.radius
			if influence > maxWaterInfluence then
				maxWaterInfluence = influence
				maxWaterType = source.waterType or source.blendMode or 1
			end
		end
	end

	local waterType
	if not maxWaterType then
		waterType = "saltWater"
	elseif maxWaterType == 1 then
		waterType = "water"
	elseif maxWaterType == 2 then
		waterType = "saltWater"
	elseif maxWaterType == 3 then
		waterType = "susWater"
	else
		waterType = maxWaterType
	end

	if waterType == "saltWater" and WATER_CLEAN_VIVEC then
		if (pos - VIVEC_POSITION):length() < VIVEC_RADIUS then
			waterType = "water"
		end
	end

	if not WATER_CLEAN_BODIES and waterType == "water" then
		waterType = "susWater"
	end

	waterTypeCache[cell.id] = waterType
	return waterType
end


-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Vessel Types 														  │
-- ╰──────────────────────────────────────────────────────────────────────╯

-- Returns (chance, avgFill) or false.
local function isVesselRecord(rec, isSealed)
	if not rec then
		return false
	end

	local id   = rec.id
	local name = (rec.name or ''):lower()

	-- Avoid scripted items to prevent conflicts
	if rec.mwscript then
		return false
	end
	if BLACKLIST[id] then return false end
	
	for _, sub in ipairs(BLACKLIST_SUBSTRINGS) do
		if hasKeyword(id, sub) or hasKeyword(name, sub) then
			return false
		end
	end

	if isSealed == true then
		if extraClosedBottles[id] then
			return 2, 1
		end
		if openBottles[id] then
			return false
		end
		for _, sub in ipairs(INVENTORY_SUBSTRINGS) do
			if hasKeyword(id, sub) or hasKeyword(name, sub) then
				return 2, 1
			end
		end
	elseif isSealed == false then
		if openBottles[id] then
			return 0.6, 0.35
		end
		for _, sub in ipairs(ZERO_CHANCE_SUBSTRINGS) do
			if hasKeyword(id, sub) or hasKeyword(name, sub) then
				return 0.05, 0.75
			end
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
		if openBottles[id] then
			return 0.6, 0.35
		end
		for _, sub in ipairs(ZERO_CHANCE_SUBSTRINGS) do
			if hasKeyword(id, sub) or hasKeyword(name, sub) then
				return 0.05, 0.75
			end
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

	local id   = rec.id
	local name = (rec.name or ''):lower()

	if rec.mwscript then
		return ""
	end
	for _, sub in ipairs(BLACKLIST_SUBSTRINGS) do
		if hasKeyword(id, sub) or hasKeyword(name, sub) then
			return ""
		end
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
	for _, sub in ipairs(ZERO_CHANCE_SUBSTRINGS) do
		if hasKeyword(id, sub) or hasKeyword(name, sub) then
			return "open container"
		end
	end
	for _, sub in ipairs(LOW_CHANCE_SUBSTRINGS) do
		if hasKeyword(id, sub) or hasKeyword(name, sub) then
			return "open container"
		end
	end
	for _, sub in ipairs(SUBSTRINGS) do
		if hasKeyword(id, sub) or hasKeyword(name, sub) then
			return "open drink " .. sub
		end
	end
	return ""
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Vessel Capacity													  │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function fallbackLitersFrom(rec)
	local id   = rec.id
	local name = (rec.name or ''):lower()
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
		--log(5, "[WaterBottles] Fallback volume for " .. rec.id .. " = " .. trimZeros(chosenL) .. " L")
		return chosenL
	end

	return 1.0
end

local function litersFor(origId)
	local miscRec = types.Miscellaneous.record(origId)
	if miscRec then
		return fallbackLitersFrom(miscRec)
	end

	return 1.0
end


local function fmt_amount_ml(ml)
	if ml >= 1000 then
		local liters = ml / 1000
		return trimZeros(liters) .. "L"
	end
	return tostring(ml) .. " ml"
end

function resolveMaxQ(origId)
	local q = saveData.maxQ[origId]
	if q then
		return q
	end

	local liters	 = litersFor(origId)
	local capacityMl = math.max(STEP_ML, math.floor(liters * 1000 + 0.5))
	q = math.max(1, math.ceil(capacityMl / STEP_ML))
	saveData.maxQ[origId] = q

	--log(5, "[WaterBottles] maxQ for " .. origId .. " = " .. tostring(q) ..	" (" .. fmt_amount_ml(q * STEP_ML) .. " capacity)")
	return q
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Liquid Helpers														  │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function ensureLiquidDB(liquidKey)
	if not saveData.liquidDB[liquidKey] then
		saveData.liquidDB[liquidKey] = {}
	end
	return saveData.liquidDB[liquidKey]
end

-- Weighted choice with interior v exterior bias  
local function chooseLiquidFor(origId, containerType)
	local vQ		 = resolveMaxQ(origId)
	local pool	  	 = {}
	local total	 	 = 0
	
	
	if vesselLiquids[origId] and containerType ~= "Container" then
		return vesselLiquids[origId][math.random(1, #vesselLiquids[origId])]
	end
	
	local vesselType = categorizeVessel(types.Miscellaneous.records[origId])
	local exp		 = 1
	
-- high chance regardless of interior or exterior
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
		--log(5, "[WaterBottles]", origId, "Fallback liquid -> water")
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

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Record Creation													  │
-- ╰──────────────────────────────────────────────────────────────────────╯

function ensurePotionFor(origId, q, liquidKey)
	local def = LIQUIDS[liquidKey or 'water']
	if not def then
		def = LIQUIDS.water
	end

	local maxQ = resolveMaxQ(origId)
	if q < 1 then
		q = 1
	elseif q > maxQ then
		q = maxQ
	end

	local liquidDB  = ensureLiquidDB(liquidKey or 'water')
	liquidDB[origId] = liquidDB[origId] or {}
	local existing  = liquidDB[origId][q]
	if existing then
		return existing
	end

	local tmpl = types.Potion.record(def.templateId)
	if not tmpl then
		log(1, "[WaterBottles] ERROR: template potion missing: " .. tostring(def.templateId))
		return nil
	end

	local miscRec = types.Miscellaneous.record(origId)
	if not miscRec then
		log(1, "[WaterBottles] ERROR: misc record missing: " .. tostring(origId))
		return nil
	end

	local baseMl   = maxQ * STEP_ML
	local leftMl   = q * STEP_ML
	local nameBase = (miscRec.name and miscRec.name ~= '') and miscRec.name or 'Liquid Container'
	if saveData.newLiquidNaming then
		nameBase = " "..nameBase
		if (liquidKey or 'water') == 'water' then
			nameBase = " "..nameBase
		end
	end
	local newName  = nameBase .. " (" .. fmt_amount_ml(leftMl) .. "/" .. fmt_amount_ml(baseMl) .. " " .. def.displayName .. ")"
	local newWeight = (miscRec.weight or tmpl.weight) + leftMl / 1000
	local newValue  = (miscRec.value or 0) + q * (def.valuePerQ or 1)

	local recordDraft = types.Potion.createRecordDraft({
		name	= newName,
		template= tmpl,
		model   = (miscRec.model and miscRec.model ~= '') and miscRec.model or tmpl.model,
		icon	= (miscRec.icon and miscRec.icon ~= '') and miscRec.icon or tmpl.icon,
		weight  = newWeight,
		value   = newValue,
		mwscript = "sd_liquid_tracker",
	})
	
	
	local rec  = world.createRecord(recordDraft)
	local newId = rec.id

	liquidDB[origId][q] = newId
	saveData.reverse[newId] = { orig = origId, q = q, liquid = liquidKey or 'water' }
	--log(4, "[WaterBottles] Created record " .. newId .. " for " .. origId .. " q=" .. tostring(q) .. "/" .. tostring(maxQ) .. " [" .. (liquidKey or 'water') .. "]")
	
	--for _, player in pairs(world.players) do
	--	player:sendEvent("SunsDusk_addLiquid", { newId, saveData.reverse[newId]})
	--end

	return newId
end

local function randomFillQ(maxQ, avg)
	local u	= math.random()
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

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Replacements														  │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function createObject(id, quantity)
	local object = world.createObject(id, quantity)
	table.insert(G_delayedUpdateJobs, {
			3,  -- Wait 3 ticks
			function(dt)
				if object:isValid() and object.count > 0 then
					local mwscript = world.mwscript.getLocalScript(object)
					if mwscript and mwscript.variables.timestamp then
						mwscript.variables.timestamp = math.floor(core.getGameTime())
					end
				end
			end
	})
	return object
end


local function replaceWorldObjectWithFull(obj)
	local rec = types.Miscellaneous.record(obj)
	local chance, averageFillLevel = isVesselRecord(rec)

	if not chance or math.random() > chance * WATER_SPAWN_CHANCE / 100 then
		return 0
	end

	local origId	= rec.id
	
	-- Check if this is an open vessel and if it's tilted more than 90 degrees
	local isOpen = isVesselRecord(rec, false)
	if isOpen or openBottlesForSpawning[origId] then
		local upVector = obj.rotation:apply(util.vector3(0, 0, 1))
		if upVector.z < 0.1 then
			return 0
		end
	end
	
	local liquidKey = chooseLiquidFor(origId, "World")
	local newId	 = ensurePotionFor(origId, randomFillQ(resolveMaxQ(origId), averageFillLevel), liquidKey)

	if not newId then
		return 0
	end

	local cell  = obj.cell
	local pos   = obj.position
	local rot   = obj.rotation
	local owner = obj.owner
	local count = (obj.count or 1)

	obj:remove()
	local newItem = createObject(newId, count)
	newItem.owner.factionId  = owner.factionId
	newItem.owner.factionRank= owner.factionRank
	newItem.owner.recordId   = owner.recordId
	newItem:teleport(cell, pos, rot)

	return count
end

local function replaceInInventory(inv, cont, containerType)
    local Misc      = types.Miscellaneous
    local replaced  = 0
    if cont and types.Container.record(cont).isOrganic then
        return 0
    end

	if not inv:isResolved() and (not cont or not types.Container.record(cont).isOrganic) then
		inv:resolve()
	end

	for _, item in ipairs(inv:getAll(Misc)) do
		if item:isValid() and item.count > 0 then
			local rec = Misc.record(item)
			local chance, averageFillLevel = isVesselRecord(rec, true)

			if chance and math.random() < chance * WATER_SPAWN_CHANCE / 100 then
				local origId	= rec.id
				local liquidKey = chooseLiquidFor(origId, containerType)
				local fullId	= ensurePotionFor(origId, resolveMaxQ(origId), liquidKey)

				if fullId then
					local count = item.count
					item:remove()
					createObject(fullId, count):moveInto(inv)
					replaced = replaced + count
				end
			end
		end
	end

	if replaced > 0 then
		--log(5, "[WaterBottles] Inventory replaced " .. tostring(replaced) .. " items")
	end

	return replaced
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ NPC Stocking														  │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function addFullToClassNPC(npc)

	-- Original logic preserved for future use
	local cls = (types.NPC.record(npc).class or ''):lower()
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

	local liquidKey = chooseLiquidFor(anyOrig, "Restock")
	local fullId = ensurePotionFor(anyOrig, resolveMaxQ(anyOrig), liquidKey)
	if not fullId then
		return false
	end

	local inv = types.NPC.inventory(npc)
	local rndAmount = math.random(1, 5)
	createObject(fullId, rndAmount):moveInto(inv)
	log(5, "[WaterBottles] Stocked " .. tostring(rndAmount) .. " bottles to " .. npc.id)
	return true
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Downgrade															  │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function downgradeWaterItem(data)
	local item   = data.item
	local inv	= data.inv
	local player = data.player

	if not inv then
		inv = types.NPC.inventory(player)
	end

	-- Skip if this object was already downgraded in the world
	if downgradedWorldObjects[item.id] then
		return false
	end

	local rev	 = saveData.reverse[item.recordId]
	if not rev then
		return false
	end

	--if item:isValid() and item.count > 0 then
	--	item:remove(1)
	--end

	local nextQ = rev.q - 1
	if nextQ >= 1 then
		local nextId = ensurePotionFor(rev.orig, nextQ, rev.liquid or 'water')
		if nextId then
			createObject(nextId):moveInto(inv)
		end
		log(5, "[WaterBottles] Drank " .. (rev.liquid or 'water') .. ": " .. rev.orig .. " -> q=" .. tostring(nextQ))
	else
		createObject(rev.orig):moveInto(inv)
		log(5, "[WaterBottles] Emptied " .. (rev.liquid or 'water') .. ": " .. rev.orig .. " -> original misc")
	end

	player:sendEvent("SunsDusk_WaterBottles_consumedWater", rev.liquid or 'water')
	return true
end

-- Downgrade a consumable in the world (not in inventory)
local function downgradeWorldConsumable(data)
	local player = data[1]
	local object = data[2]
	if not object or not object:isValid() then
		return false
	end
	-- Store position and rotation before removing
	local cell = object.cell
	local pos = object.position
	local rot = object.rotation
	
	-- Remember this object ID so downgradeWaterItem will skip it
	downgradedWorldObjects[object.id] = true
	
	local rev = saveData.reverse[object.recordId]
	if not rev then
		-- stew
		local stewData = saveData.stewRegistry[object.recordId]
		if stewData and stewData.foodwareRecordId then
			world.createObject(stewData.foodwareRecordId, 1):teleport(cell, pos, {rotation = rot})
		end
	
		object:remove()
		return false
	end

	



	-- Calculate the next quality level
	local nextQ = rev.q - 1
	local newObject

	if nextQ >= 1 then
		-- Spawn a downgraded version with Q-1
		local nextId = ensurePotionFor(rev.orig, nextQ, rev.liquid or 'water')
		if nextId then
			newObject = world.createObject(nextId, 1)
			log(5, "[WaterBottles] World downgrade " .. (rev.liquid or 'water') .. ": " .. rev.orig .. " -> q=" .. tostring(nextQ))
		end
	else
		-- Spawn the original empty vessel
		newObject = world.createObject(rev.orig, 1)
		log(5, "[WaterBottles] World emptied " .. (rev.liquid or 'water') .. ": " .. rev.orig .. " -> original misc")
	end

	-- Remove the original object
	object:remove()

	-- Place the new object if created
	if newObject then
		newObject:teleport(cell, pos, {rotation = rot})
	end
	player:sendEvent("SunsDusk_WaterBottles_consumedWater", rev.liquid or 'water')
	return true
end

function consumeMilliliters(player, mlToConsume, liquidType)
	if not player or not mlToConsume or mlToConsume <= 0 then
		return 0
	end
	
	local mlConsumed = 0
	local inventory = types.Actor.inventory(player)
	
	-- Collect all liquid items and categorize them
	local openVessels = {}
	local closedVessels = {}
	
	for _, item in pairs(inventory:getAll()) do
		local pid = item.recordId
		local info = saveData.reverse[pid]
		if info and info.orig and info.q and (not liquidType and info.liquid:lower():find("water") or info.liquid == liquidType) then
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
				local rev = saveData.reverse[pid]
				
				-- Remove current bottle
				item:remove(1)
				
				-- Add downgraded bottle if not empty
				if newQ > 0 then
					local liquid = info.liquid or 'water'
					local liquidDB = saveData.liquidDB[liquid]
					
					local newId = ensurePotionFor(rev.orig, newQ, rev.liquid)
					if newId then
						createObject(newId, 1):moveInto(inventory)
					end					
				else
					createObject(info.orig, 1):moveInto(inventory)
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

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Cell Conversion													  │
-- ╰──────────────────────────────────────────────────────────────────────╯

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
		converted = converted + replaceInInventory(types.Container.inventory(c), c, "Container")
	end

	for _, npc in ipairs(cell:getAll(types.NPC)) do
		if not saveData.convertedNPCsWater[npc.id] then
			converted = converted + replaceInInventory(types.NPC.inventory(npc), nil, "NPC")

			if addFullToClassNPC(npc) then
				stocked = stocked + 1
			end

			saveData.convertedNPCsWater[npc.id] = true
		end
	end

	for _, cr in ipairs(cell:getAll(types.Creature)) do
		converted = converted + replaceInInventory(types.Creature.inventory(cr), nil, "Creature")
	end

	if converted > 0 then
		log(3, "[WaterBottles] Converted " .. tostring(converted) .. " items in cell " .. tostring(cell.id))
	end

	if stocked > 0 then
		log(3, "[WaterBottles] Gave bottles to " .. tostring(stocked) .. " NPCs")
	end

	saveData.convertedCellsWater[cell.id] = true
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Spillage															  │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function spillWater(player)
	local Misc	  = types.Miscellaneous
	local spilledMl = 0
	local inv	   = types.NPC.inventory(player)
	for _, item in ipairs(inv:getAll(types.Potion)) do
		local rev = saveData.reverse[item.recordId]
		if rev then
			local isBottle = isVesselRecord(Misc.record(rev.orig), true)
			if not isBottle then
				local spillableLiquid = true
				for _, pattern in pairs(unspillableLiquids) do
					if item.type.record(item).name:find(pattern, 1, true) then
						spillableLiquid = false
					end
				end
				if spillableLiquid then
					local quantity = item.count
					local maxQ = resolveMaxQ(rev.orig)
					local targetQ = math.floor(rev.q/2)
					if targetQ >= 1 and rev.q>math.floor(maxQ/2) then
						spilledMl = spilledMl + (rev.q-targetQ) * 250 * quantity
						local newId = ensurePotionFor(rev.orig, targetQ, rev.liquid)
						if newId then
							item:remove()
							createObject(newId, quantity):moveInto(inv)
						end
					else
						spilledMl = spilledMl + rev.q * 250 * quantity
						item:remove()
						createObject(rev.orig, quantity):moveInto(inv)
					end
				end
			end
		end
	end

	if spilledMl > 0 then
		player:sendEvent("SunsDusk_spilledWater", spilledMl)
	end
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ purify																  │
-- ╰──────────────────────────────────────────────────────────────────────╯

local function purifyWater(data)
	local player = data[1]
	
	local mlPurified = 0
	local inventory = types.Actor.inventory(player)
	
	local dirtyLiquids = {
		saltWater = true,
		susWater = true,
	}
	
	-- Collect all dirty water items
	local dirtyItems = {}
	
	for _, item in pairs(inventory:getAll(types.Potion)) do
		local pid = item.recordId
		local info = saveData.reverse[pid]
		
		if info and info.orig and info.q and dirtyLiquids[info.liquid] then
			table.insert(dirtyItems, {item = item, pid = pid, info = info})
		end
	end
	
	log(5, string.format("Found %d dirty water vessels to purify", #dirtyItems))
	
	local purifiedLiquids = {}
	
	for _, itemData in ipairs(dirtyItems) do
		local item = itemData.item
		local info = itemData.info
		local count = item.count
		local mlInBottle = info.q * STEP_ML
		
		-- Remove all dirty water bottles of this type
		item:remove(count)
		-- Add purified water
		local purifiedId = ensurePotionFor(info.orig, info.q, 'water')
		if purifiedId then
			createObject(purifiedId, count):moveInto(inventory)
		end
		
		mlPurified = mlPurified + (mlInBottle * count)
		purifiedLiquids[info.liquid] = (purifiedLiquids[info.liquid] or 0) + (mlInBottle * count)
	end
	
	log(4, string.format("Purified %dml of dirty water", mlPurified))
	player:sendEvent("SunsDusk_WaterBottles_waterPurified", purifiedLiquids)
end


-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Refilling															  │
-- ╰──────────────────────────────────────────────────────────────────────╯

-- Starwind ; Saltwater, Sus water
local function refillBottlesWell(data)
	local player = data[1]
	local liquidType = data[2] or 'water'
	local inv	= types.NPC.inventory(player)
	local Misc   = types.Miscellaneous
	local Potion = types.Potion

	local replaced = 0

	for _, item in ipairs(inv:getAll(Misc)) do
		if item:isValid() and item.count > 0 then
			local rec	= Misc.record(item)
			local chance = isVesselRecord(rec, true)

			if chance then
				local origId = rec.id
				local fullId = ensurePotionFor(origId, resolveMaxQ(origId), liquidType)
				
				if fullId then
					local count = item.count
					item:remove()
					createObject(fullId, count):moveInto(inv)
					replaced = replaced + count
				end
			end
		end
	end
	
	
	for _, item in ipairs(inv:getAll(Potion)) do
		if item:isValid() and item.count > 0 then
			local rev = saveData.reverse[item.recordId]
			if rev then
				local origId = rev.orig
				local maxQ   = resolveMaxQ(origId)
				local fullId = ensurePotionFor(origId, maxQ, liquidType)
				
				if maxQ and rev.q < maxQ and fullId then
					local count = item.count
					item:remove()
					createObject(fullId, count):moveInto(inv)
					replaced = replaced + count
				end
			end
		end
	end
	local data = { 
		["replaced"]  	= replaced,
		["liquidType"]  = liquidType,
	}
	
	player:sendEvent("SunsDusk_refilledBottlesWell", data)

end

-- open sources only refill spillables; keep water
local function refillSpillables(data)
	local player = data[1]
	local liquidType = data[2] or 'water'
	
	local inv	= types.NPC.inventory(player)
	local Misc   = types.Miscellaneous
	local Potion = types.Potion

	local replaced = 0

	for _, item in ipairs(inv:getAll(Misc)) do
		if item:isValid() and item.count > 0 then
			local rec   = Misc.record(item)
			local isOpen = isVesselRecord(rec, false)
			if isOpen then
				local origId = rec.id
				local fullId = ensurePotionFor(origId, resolveMaxQ(origId), liquidType)

				if fullId then
					local count = item.count
					item:remove()
					createObject(fullId, count):moveInto(inv)
					replaced = replaced + count
				end
			end
		end
	end

	for _, item in ipairs(inv:getAll(Potion)) do
		if item:isValid() and item.count > 0 then
			local rev = saveData.reverse[item.recordId]
			if rev then
				local origId = rev.orig
				local isOpen = isVesselRecord(Misc.records[origId], false)

				if isOpen then
					local maxQ   = resolveMaxQ(origId)
					local fullId = ensurePotionFor(origId, maxQ, liquidType)

					if maxQ and rev.q < maxQ and fullId then
						local count = item.count
						item:remove()
						createObject(fullId, count):moveInto(inv)
						replaced = replaced + count
					end
				end
			end
		end
	end

	if replaced > 0 then
		local str = "Refilled " .. tostring(replaced) .. " bottles with " .. tostring(LIQUIDS[liquidType]["displayName"])
		player:sendEvent("SunsDusk_messageBox", { 3, str })
	end
end

G_onLoadJobs.liquids = function(data)

	saveData.maxQ					= saveData.maxQ					or {}
	saveData.reverse				= saveData.reverse				or {}
	saveData.convertedCellsWater	= saveData.convertedCellsWater	or {}
	saveData.convertedNPCsWater		= saveData.convertedNPCsWater	or {}
	
	if data then
		saveData.newLiquidNaming = false
	else
		saveData.newLiquidNaming = true
		saveData.liquidVersion = 3
	end

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
	
	-- Migration: Fix old lowercase "generated:..." to "Generated:..."
	if saveData.fixedGeneratedCase then
		saveData.liquidVersion = 1
	end
	if not saveData.liquidVersion then
		local keysToFix = {}
		for key in pairs(saveData.reverse) do
			if key:sub(1, 10) == "generated:" then
				table.insert(keysToFix, key)
			end
		end
		
		for _, oldKey in ipairs(keysToFix) do
			local newKey = "G" .. oldKey:sub(2)  -- Replace 'g' with 'G'
			saveData.reverse[newKey] = saveData.reverse[oldKey]
			saveData.reverse[oldKey] = nil
		end
		
		if #keysToFix > 0 then
			log(3, string.format("[Liquids Migration] Fixed %d generated ID keys from lowercase to uppercase", #keysToFix))
		end
		
		saveData.liquidVersion = 1
	end
	if saveData.liquidVersion < 2 then
		saveData.liquidDB = {}
		saveData.liquidDB.water = {}
		saveData.liquidVersion = 2
	end
	
	if saveData.liquidVersion < 3 then
		data = nil
	end
	
	if not data then
		-- ── Recover reverse lookup from existing potion records ──
		-- If saveData was lost/corrupted, rebuild reverse (and liquidDB for
		-- current-version records) by parsing the naming convention baked into
		-- every liquid potion:  "VesselName (leftMl/totalMl DisplayName)"
		
		local displayToKey = {}
		for key, def in pairs(LIQUIDS) do
			displayToKey[def.displayName] = key
		end
		
		-- model → first matching misc recordId, used to recover origId
		local modelToMisc = {}
		for _, rec in pairs(types.Miscellaneous.records) do
			if rec.model and rec.model ~= '' and not modelToMisc[rec.model] then
				modelToMisc[rec.model] = rec.id
			end
		end
		
		local recovered = 0
		for _, rec in pairs(types.Potion.records) do 
			if saveData.reverse[rec.id] then goto continue end
			
			local inner = (rec.name or ''):match('%((.+)%)$')
			if not inner then goto continue end
			
			local slashPos = inner:find('/', 1, true)
			if not slashPos then goto continue end
			
			local leftStr = inner:sub(1, slashPos - 1)
			local rest = inner:sub(slashPos + 1)
			
			-- rest is e.g. "1L Water" or "500 ml Suspicious Water"
			local totalStr, dispName = rest:match('^(%d+ ml) (.+)$')
			if not totalStr then
				totalStr, dispName = rest:match('^([%d%.]+L) (.+)$')
			end
			if not totalStr then goto continue end
			
			local liquidKey = displayToKey[dispName]
			if not liquidKey then goto continue end
			
			-- parse "250 ml" or "1.5L" → milliliters
			local leftMl = tonumber(leftStr:match('^(%d+) ml$')) or (tonumber(leftStr:match('^([%d%.]+)L$')) or 0) * 1000
			local totalMl = tonumber(totalStr:match('^(%d+) ml$')) or (tonumber(totalStr:match('^([%d%.]+)L$')) or 0) * 1000
			if leftMl == 0 or totalMl == 0 then goto continue end
			
			local origId = rec.model and modelToMisc[rec.model]
			if not origId then goto continue end
			
			local q    = math.max(1, math.floor(leftMl / STEP_ML + 0.5))
			local maxQ = math.max(1, math.floor(totalMl / STEP_ML + 0.5))
			--print(rec.name, liquidKey, q, maxQ)
			
			saveData.reverse[rec.id] = { orig = origId, q = q, liquid = liquidKey }
			if not saveData.maxQ[origId] then
				saveData.maxQ[origId] = maxQ
			end
			
			-- Only rebuild liquidDB for current-version records (with sd_liquid_tracker)
			if rec.mwscript == "sd_liquid_tracker" then
				if not saveData.liquidDB[liquidKey] then
					saveData.liquidDB[liquidKey] = {}
				end
				if not saveData.liquidDB[liquidKey][origId] then
					saveData.liquidDB[liquidKey][origId] = {}
				end
				if not saveData.liquidDB[liquidKey][origId][q] then
					saveData.liquidDB[liquidKey][origId][q] = rec.id
				end
			end
			
			recovered = recovered + 1
			
			::continue::
		end
		
		if recovered > 0 then
			log(2, "[SunsDusk] Recovered " .. recovered .. " liquid records into reverse lookup")
			if false and saveData.liquidVersion == 3 then -- only notify when saveData has *just* been lost or mod was reinstalled
				for _, player in pairs(world.players) do
					player:sendEvent("SunsDusk_errorDetection", {message = [[Sun's Dusk was reinstalled or had a severe error in your last session.
Was able to recover ]]..recovered..[[ drinkware records.
If you didn't restart the game since you last played this save,
please upload your openmw.log (in Documents\My Games\OpenMW)
to our OpenMW Discord channel
or at https://www.nexusmods.com/morrowind/mods/57526]]})
				end
			end
		end
		saveData.liquidVersion = 3
	end
end

local function refillSingleBottle(data)
	local player = data.player
	local usedItem = data.item
	local liquidType = data.liquidType or 'water'
	
	local inv = types.NPC.inventory(player)
	local Misc = types.Miscellaneous
	local Potion = types.Potion
	
	-- Check if it's an empty vessel (Misc item)
	local rec = Misc.record(usedItem.recordId)
	if rec then
		local isVessel = isVesselRecord(rec, true) or isVesselRecord(rec, false)
		if isVessel then
			local origId = rec.id
			local fullId = ensurePotionFor(origId, resolveMaxQ(origId), liquidType)
			
			if fullId then
				usedItem:remove(1)
				createObject(fullId, 1):moveInto(inv)
				player:sendEvent("SunsDusk_playSound", "item potion up")
				player:sendEvent("SunsDusk_messageBox", {3, "Refilled bottle with " .. tostring(LIQUIDS[liquidType]["displayName"])})
				return
			end
		end
	end
	
	-- Check if it's a partially filled potion
	local rev = saveData.reverse[usedItem.recordId]
	if rev then
		local origId = rev.orig
		local maxQ = resolveMaxQ(origId)
		local fullId = ensurePotionFor(origId, maxQ, liquidType)
		
		if maxQ and rev.q < maxQ and fullId then
			usedItem:remove(1)
			createObject(fullId, 1):moveInto(inv)
			player:sendEvent("SunsDusk_playSound", "item potion up")
			player:sendEvent("SunsDusk_messageBox", {3, "Refilled bottle with " .. tostring(LIQUIDS[liquidType]["displayName"])})
		end
	end
end

G_eventHandlers.SunsDusk_WaterBottles_refillSingleBottle = refillSingleBottle
G_eventHandlers.SunsDusk_WaterBottles_convertMiscInCell		= convertMiscInCell
G_eventHandlers.SunsDusk_WaterBottles_downgradeWaterItem	= downgradeWaterItem
G_eventHandlers.SunsDusk_downgradeWorldConsumable			= downgradeWorldConsumable
G_eventHandlers.SunsDusk_WaterBottles_spillWater			= spillWater
G_eventHandlers.SunsDusk_WaterBottles_refillBottlesWell		= refillBottlesWell
G_eventHandlers.SunsDusk_WaterBottles_refillSpillables		= refillSpillables
G_eventHandlers.SunsDusk_WaterBottles_consumeWater			= consumeWater
G_eventHandlers.SunsDusk_WaterBottles_purifyWater			= purifyWater

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Liquid Visual System (water level + steam)							  │
-- ╰──────────────────────────────────────────────────────────────────────╯

local useVfx = world.vfx and world.vfx.remove ~= nil

local function cleanupVfxEntry(data)
	if data.vfxId then world.vfx.remove(data.vfxId) end
	if data.steamVfxId then world.vfx.remove(data.steamVfxId) end
	if data.static and data.static:isValid() and data.static.count > 0 then
		data.static:remove()
	end
	if data.steamStatic and data.steamStatic:isValid() and data.steamStatic.count > 0 then
		data.steamStatic:remove()
	end
end


-- Process underwater open vessels in an interior cell.
-- Called from g_cellInfo.lua after cellInfo is cached, so resolveWaterType
-- is guaranteed to have the data it needs.
G_processInteriorUnderwaterVessels = function(cell)
	if not cell or not cell.hasWater then return end
	local waterLevel = (cell.waterLevel or -math.huge) - 10

	local function processObject(object)
		if object.position.z >= waterLevel then return end

		local rev = saveData.reverse[object.recordId]
		local origId, isOpen
		if rev then
			origId = rev.orig
			isOpen = isVesselRecord(types.Miscellaneous.records[origId], false)
		elseif types.Miscellaneous.objectIsInstance(object) then
			local rec = types.Miscellaneous.record(object)
			isOpen = isVesselRecord(rec, false)
			if isOpen then origId = rec.id end
		end

		if not isOpen or not origId then return end

		local waterType = resolveWaterType(cell, object.position)
		local maxQ = resolveMaxQ(origId)
		if rev and rev.liquid == waterType and rev.q == maxQ then return end

		local fullId = ensurePotionFor(origId, maxQ, waterType)
		if not fullId then return end

		if saveData.consumableVfx[object.id] then
			cleanupVfxEntry(saveData.consumableVfx[object.id])
			saveData.consumableVfx[object.id] = nil
		end
		local newBottle = createObject(fullId, object.count)
		newBottle.owner.factionId   = object.owner.factionId
		newBottle.owner.factionRank = object.owner.factionRank
		newBottle.owner.recordId    = object.owner.recordId
		newBottle:teleport(cell, object.position, {rotation = object.rotation})
		object:remove()
	end

	for _, object in pairs(cell:getAll(types.Miscellaneous)) do
		processObject(object)
	end
	for _, object in pairs(cell:getAll(types.Potion)) do
		processObject(object)
	end
end


G_onObjectActiveJobs.liquids = function(object)
	if not types.Miscellaneous.objectIsInstance(object) and not types.Potion.objectIsInstance(object) then return end
	local rev = saveData.reverse[object.recordId]

	-- Exterior underwater fill: use WATER_BODIES position lookup (no cache needed)
	-- Interior underwater fill is handled by G_processInteriorUnderwaterVessels via getCellInfo
	if object.cell.isExterior and object.cell.hasWater then
		local waterLevel = (object.cell.waterLevel or -math.huge) - 7
		if object.position.z < waterLevel then
			local origId, isOpen
			if rev then
				origId = rev.orig
				isOpen = isVesselRecord(types.Miscellaneous.records[origId], false)
			elseif types.Miscellaneous.objectIsInstance(object) then
				local rec = types.Miscellaneous.record(object)
				isOpen = isVesselRecord(rec, false)
				if isOpen then origId = rec.id end
			end

			if isOpen and origId then
				local waterType = resolveWaterType(object.cell, object.position)
				local maxQ = resolveMaxQ(origId)
				if rev and rev.liquid == waterType and rev.q == maxQ then
					return -- already full of this water
				end
				local fullId = ensurePotionFor(origId, maxQ, waterType)
				if fullId then
					if saveData.consumableVfx[object.id] then
						cleanupVfxEntry(saveData.consumableVfx[object.id])
						saveData.consumableVfx[object.id] = nil
					end
					local newBottle = createObject(fullId, object.count)
					newBottle.owner.factionId   = object.owner.factionId
					newBottle.owner.factionRank = object.owner.factionRank
					newBottle.owner.recordId    = object.owner.recordId
					newBottle:teleport(object.cell, object.position, {rotation = object.rotation})
					object:remove()
					return -- no VFX for underwater objects
				end
			end
			return
		end
	end
	-- underwater fill logic is now handled above via resolveWaterType
	
	if not rev then return end
	
	-- Already tracking this object
	if saveData.consumableVfx[object.id] then
		if useVfx then
			-- VFX needs to be recreated every activation; remove old ones just in case
			cleanupVfxEntry(saveData.consumableVfx[object.id])
			saveData.consumableVfx[object.id] = nil
			-- fall through to recreate
		else
			local data = saveData.consumableVfx[object.id]
			if data.scale then
				if data.steamStatic then
					data.steamStatic:setScale(data.scale)
				end
				if data.static then
					data.static:setScale(0.161*data.scale)
				end
			end
			return
		end
	end
	
	local origId = rev.orig
	local q = rev.q
	local maxQ = resolveMaxQ(origId)
	local fillRatio = q / maxQ
	
	-- Assign loot ID for detection (shared counter with cooking)
	saveData.consumableVfxCounter = saveData.consumableVfxCounter + 1
	local lootId = saveData.consumableVfxCounter
	
	local mwscript = world.mwscript.getLocalScript(object)
	if mwscript then
		mwscript.variables.lootId = lootId
	else
		return
	end
	
	-- Get timestamp for steam calculation
	local timestamp = nil
	if mwscript and mwscript.variables.timestamp then
		timestamp = mwscript.variables.timestamp
	end
	
	-- Calculate offset and scale based on fill level
	local vesselData = vesselOffsets[origId]
	local waterStatic
	local steamStatic
	local waterVfxId
	local steamVfxIdResult
	local finalOffset, finalScale
	if vesselData ~= false then
		if vesselData then
			-- Interpolate between min and max based on fill ratio
			local minOff = vesselData.minOffset
			local maxOff = vesselData.maxOffset
			finalOffset = minOff + (maxOff - minOff) * fillRatio
			finalOffset = object.rotation:apply(finalOffset)
			finalScale = (vesselData.minScale + (vesselData.maxScale - vesselData.minScale) * fillRatio)
		else
			-- Fallback: calculate from bounding box
			local bbox = object:getBoundingBox()
			if not isValidBBox(bbox) then
				return
			end
			local shortestSide = math.min(bbox.halfSize.x * 2, bbox.halfSize.y * 2)
			local baseScale = shortestSide * 1.414 * defaultVesselOffsetParams.baseScaleMult
			
			local minZ = bbox.halfSize.z * 2 * defaultVesselOffsetParams.minZFraction
			local maxZ = bbox.halfSize.z * 2 * defaultVesselOffsetParams.maxZFraction
			local zOffset = minZ + (maxZ - minZ) * fillRatio
			
			finalOffset = bbox.center - object.position + v3(0, 0, zOffset - bbox.halfSize.z)
			finalScale = baseScale * (defaultVesselOffsetParams.minScaleFactor + (defaultVesselOffsetParams.maxScaleFactor - defaultVesselOffsetParams.minScaleFactor) * fillRatio)
		end
		
		-- Create water static
		if useVfx then
			local vfxId = "sd_liq_" .. tostring(object.id)
			local model = types.Static.records[LIQUIDS[rev.liquid].static].model
			world.vfx.spawn(model, object.position + finalOffset, {
				loop = true,
				vfxId = vfxId,
				scale = 0.161 * finalScale,
			})
			waterVfxId = vfxId
		else
			waterStatic = world.createObject(LIQUIDS[rev.liquid].static)
			waterStatic:teleport(object.cell, object.position + finalOffset, {onGround = false})
			waterStatic:setScale(0.161*finalScale)
		end
		
		-- Create steam if recently filled (within 3 hours game time)
		if timestamp then
			--print(LIQUIDS[rev.liquid].steaming, timestamp)
			if LIQUIDS[rev.liquid].steaming then
				local currentTime = core.getGameTime()
				local ageInHours = (currentTime - timestamp) / 3600
				
				if ageInHours < 3 then
					if useVfx then
						local steamVfxId = "sd_stm_" .. tostring(object.id)
						local steamModel = types.Static.records["sd_food_steam"].model
						world.vfx.spawn(steamModel, object.position + finalOffset, {
							loop = true,
							vfxId = steamVfxId,
							scale = finalScale,
						})
						steamVfxIdResult = steamVfxId
					else
						steamStatic = world.createObject("sd_food_steam")
						steamStatic:teleport(object.cell, object.position + finalOffset, {onGround = false})
						steamStatic:setScale(finalScale)
					end
				end
			end
		end
	end
	
	saveData.consumableVfx[object.id] = {
		object = object,
		static = waterStatic,
		steamStatic = steamStatic,
		vfxId = waterVfxId,
		steamVfxId = steamVfxIdResult,
		lootId = lootId,
		timestamp = timestamp,
		scale = finalScale,
	}
end

-- Shared loot detector (also handles cooking - see g_cooking.lua)
-- If cookingLootDetector already exists, this extends it; otherwise creates it
G_onUpdateJobs.cookingLootDetector = function(dt)
	
	local globals = world.mwscript.getGlobalVariables()
	local lootedId = globals.sd_loot_signal or 0
	if lootedId < 1 then return end
	
	-- Check liquids
	for objectId, data in pairs(saveData.consumableVfx) do
		if data.lootId == lootedId then
			cleanupVfxEntry(data)
			saveData.consumableVfx[objectId] = nil
			globals.sd_loot_signal = 0
			return
		end
	end
	globals.sd_loot_signal = 0
end

G_eventHandlers.SunsDusk_LootVfxItem = function(object)
	if not object:isValid() then return end
	
	-- Try to find this object in consumableVfx by object ID
	local vfxData = saveData.consumableVfx[object.id]
	
	if vfxData then
		-- Found by object ID - clean up VFX
		cleanupVfxEntry(vfxData)
		saveData.consumableVfx[object.id] = nil
	end
end

-- Steam age checker - removes steam after 3 hours game time
local liquidSteamIterator
G_onUpdateJobs.liquidsSteamAgeChecker = function(dt)
	local currentTime = core.getGameTime()
	
	local data
	liquidSteamIterator, data = next(saveData.consumableVfx, liquidSteamIterator)
	if liquidSteamIterator then
		if data.timestamp then
			local ageInHours = (currentTime - data.timestamp) / 3600
			if ageInHours >= 3 then
				if data.steamVfxId then
					world.vfx.remove(data.steamVfxId)
					data.steamVfxId = nil
				end
				if data.steamStatic and data.steamStatic:isValid() then
					data.steamStatic:remove()
					data.steamStatic = nil
				end
			end
		end
	end
end

I.ItemUsage.addHandlerForType(types.Potion, function(item, actor)
    local mwscript = world.mwscript.getLocalScript(item)
    if not mwscript or not mwscript.variables.timestamp then
        return
    end
    
    local rev = saveData.reverse[item.recordId]
    if not rev then
        return
    end
    
    actor:sendEvent("SunsDusk_consumedWithTimestamp", {
        item = item,
        liquidType = rev.liquid,
        timestamp = mwscript.variables.timestamp,
    })
end)