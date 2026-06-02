G_cellInfoCache = {}

-- Helper: cache interior cellInfo for global-side water type resolution (used by g_liquids)
-- and send to the player script
local function sendCellInfo(player, cell, cellInfo)
	-- dbStatics override: replace heuristic data, keep fires + nextExterior wiring
	if cell and dbStatics[cell.id] and dbStatics[cell.id].cell then
		local fires = cellInfo.fires
		local nextCell = cellInfo.nextExteriorCell
		local nextPos  = cellInfo.nextExteriorPosition
		local nextQE   = cellInfo.nextExteriorCellIsQuasiExterior
		for k in pairs(cellInfo) do cellInfo[k] = nil end
		cellInfo.fires = fires
		cellInfo.nextExteriorCell = nextCell
		cellInfo.nextExteriorPosition = nextPos
		cellInfo.nextExteriorCellIsQuasiExterior = nextQE
		for k, v in pairs(dbStatics[cell.id].cell) do
			cellInfo[k] = v
		end
		if cellInfo.temperature then cellInfo.fixedTemperature = true end
		if cellInfo.climateType then cellInfo.fixedClimateType = true end
	end
	
	if cellInfo.nextExteriorCell then
		local tempCell = cellInfo.nextExteriorCell
		cellInfo.nextExteriorCell = nil
		cellInfo.nextExteriorAnchor = tempCell:getAll()[1]
		player:sendEvent("SunsDusk_receiveCellInfo", cellInfo)
		cellInfo.nextExteriorCell = tempCell
		cellInfo.nextExteriorAnchor = nil
	else
		player:sendEvent("SunsDusk_receiveCellInfo", cellInfo)
	end
	
	if cell and not cellInfo.isExterior then
		G_cellInfoCache[cell.id] = cellInfo
		-- Process any underwater open vessels now that the cell type is known
		G_processInteriorUnderwaterVessels(cell)
	end
end

function cellHasPublican(cell)
	for _, object in pairs(cell:getAll(types.NPC)) do
		local record = types.NPC.record(object)
		local className = record.class:lower()
		if className:find("publican") then
			return true
		end
	end
	return false
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Cell Data                                                            │
-- ╰──────────────────────────────────────────────────────────────────────╯

-- ========= HEAT SOURCES =========

function isHeatSource(object, mode)
	local recordId = object.recordId
	
	local refEntry, recordEntry = dbStatics[object.id], dbStatics[recordId]
	local dbEntry = refEntry and refEntry.heatsource
	if dbEntry == nil then
		dbEntry = recordEntry and recordEntry.heatsource
	end
	
	if dbEntry ~= nil then
		return dbEntry and true
	end
    local heatWords = { "fire", "flame", "torch", "brazier", "lava", "firepit", 
                       "incense", "burner", "tiki", "logpile", "pitfire", "forge" }
    if mode == 3 and (
		string.match(recordId, "cave") 
		or string.match(recordId, "_rock") 
		or string.match(recordId, "boulder")
		or recordId == "in_lava_blacksquare"
	) then
		return false
	end
    -- Exclude if it's off or broken
    if string.match(recordId, "_[Oo]ff$") or string.match(recordId, "burnedout") 
       or string.match(recordId, "broke") or string.match(recordId, "flame light") or string.match(recordId, "roht_mg_fire") then
        return false
    end
    
    -- Check if contains any heat word
    for _, word in ipairs(heatWords) do
        if string.find(recordId, word) then
            return true
        end
    end
    if burningLogs[recordId] then
		return true
	end
    return false
end


-- Cell categorisation based on static objects

local function getClosestExteriorCell(cell, position)
	local cellToDo = { {cell, position} }
	local traversedCells = {}
	
	while #cellToDo > 0 do
		local current = table.remove(cellToDo, 1) -- [1] = cell, [2] = position
		if current[1].isExterior then
			return current[1], current[2], false
		elseif current[1]:hasTag("QuasiExterior") then 
			return current[1], current[2], true
		end
		if not traversedCells[current[1].id] then
			traversedCells[current[1].id] = true
			for _, door in ipairs(current[1]:getAll(types.Door)) do
				if types.Door.isTeleport(door) then
					local dest = types.Door.destCell(door)
					if dest and not traversedCells[dest.id] then
						table.insert(cellToDo, {dest, types.Door.destPosition(door)})
					end
				end
			end
		end
	end
	
	return nil
end


local function getCellInfo(player)
	local cellInfo = {
		isExterior = false,
		isIceCave = false,
		isCave = false,
		isDwemer = false,
		isDaedric = false,
		isMine = false,
		isTomb = false,
		isHouse = false,
		isCastle = false,
		isMushroom = false,  -- Telvanni
		isHlaalu = false,    -- Hlaalu
		isRedoran = false,   -- Redoran
		isIndoril = false,
		isImperial = false,
		isNord = false,
		isSewer = false,     -- Sewers/Underworks
		isTemple = false,    -- Temple interiors
		isBath = false,
	
	--  isAshlander = false,
		hasPublican = false,
		fires = {}
	}
	
	if not NEEDS_TEMP then 
		sendCellInfo(player, nil, cellInfo)
		return
	end
	
	local cell = player.cell
	if not cell then
		sendCellInfo(player, nil, cellInfo)
		return
	end
	
	for _, object in pairs(cell:getAll(types.Activator)) do
		if isHeatSource(object) then
			log(4,"activator heat source:",object)
			table.insert(cellInfo.fires, object)
		end
	end
	
	for _, object in pairs(cell:getAll(types.Light)) do
		if isHeatSource(object) then
			log(4,"light heat source:",object)
			table.insert(cellInfo.fires, object)
		end
	end
	
	for _, object in pairs(cell:getAll(types.Static)) do
		if isHeatSource(object, 3) then
			log(4,"static heat source:",object)
			table.insert(cellInfo.fires, object)
		end
	end
	
	cellInfo.hasPublican = cellHasPublican(cell)
	
	if (cell.isExterior or cell:hasTag("QuasiExterior")) and cell.hasSky then
		cellInfo.isExterior = true
		sendCellInfo(player, cell, cellInfo)
		return
	end
	
	cellInfo.nextExteriorCell, cellInfo.nextExteriorPosition, cellInfo.nextExteriorCellIsQuasiExterior = getClosestExteriorCell(cell, player.position)
	
	local cellId = cell.id
	-- Check for Bath house
	if cellId == "port telvannis, the avenue: subterranean balconies" then
		cellInfo.isHouse    = true
		cellInfo.isCave     = true
		cellInfo.isBath     = true
		cellInfo.isMushroom = true
		log(3,"port telvannis: house, cave, bath, mushroom")
		sendCellInfo(player, cell, cellInfo)
		return -- "Vivec, Foreign Quarter Public Bath" ; "Vivec, Telvanni Public Bath" ; "Vivec, Redoran Public Bath" ; "Vivec, Hlaalu Public Bath"
	elseif cellId == "odai mudbaths" then
		cellInfo.isBath     = true
		sendCellInfo(player, cell, cellInfo)
		return
	elseif cellId == "vivec, telvanni public bath" then
		cellInfo.isMushroom = true
		cellInfo.isBath     = true
		sendCellInfo(player, cell, cellInfo)
		return
	elseif cellId == "vivec, redoran public bath" then
		cellInfo.isRedoran  = true
		cellInfo.isBath     = true
		sendCellInfo(player, cell, cellInfo)
		return
	elseif cellId == "vivec, hlaalu public bath" then
		cellInfo.isHlaalu   = true
		cellInfo.isBath     = true
		sendCellInfo(player, cell, cellInfo)
		return
	elseif cellId == "mournhold, healing bath" then
		cellInfo.isTemple   = true
		cellInfo.isBath     = true
		sendCellInfo(player, cell, cellInfo)
		return
	elseif cellId == "vivec, bath house" then
		cellInfo.isTemple   = true
		cellInfo.isBath     = true
		sendCellInfo(player, cell, cellInfo)
		return
	elseif cellId == "balmora, bath house" then
		cellInfo.isTemple   = true
		cellInfo.isBath     = true
		sendCellInfo(player, cell, cellInfo)
		return
	elseif cellId:find("sea of ghosts") then
		cellInfo.isIceCave  = true
		cellInfo.isCave     = true
	elseif cellId:find("grotto") then
		cellInfo.isBath     = true
		cellInfo.isCave     = true
	elseif cellId:find("bath") then
		cellInfo.isBath     = true
		--isntHouse = true -- cancelled before house part anyway
	elseif cellId:find("sewer") then
		cellInfo.isSewer    = true
		isntHouse           = true
	elseif cellId:find("catac") then
		cellInfo.isTomb     = true
		isntHouse           = true
	--elseif cellId:find("temple") or cellId:find("shrine") then
	--	cellInfo.isTomb = true
	--	isntHouse = true
	end
	
	-- Counters for weighted detection
	local counts = {
		iceCave  = 0,
		cave     = 0,
		dwemer   = 0,
		daedric  = 0,
		mine     = 0,
		tomb     = 0,
		house    = 0,
		castle   = 0,
		mushroom = 0,   -- Telvanni
		hlaalu   = 0,     
		redoran  = 0,
		indoril  = 0,
		imperial  = 0,
		nord  = 0,
		sewer    = 0,
		temple   = 0,
		bath     = 0,
	--  ashlander= 0,
	}
	
	-- iterate through all statics in the cell, TD patterns start with t_
	for _, object in pairs(cell:getAll(types.Static)) do
		local id = object.recordId
		local tags = {}
		
		-- ice cave
		if (id:find("ice") or id:find("frost") or id:find("snow") or id:find("frozen") or
		   id:find("_caveic_") or id:find("t_glb_terrice_") or id:find("icicle"))
			and not id:find("practice") and not id:find("office") and not id:find("justice") then
			counts.iceCave = counts.iceCave + 1
			tags[#tags+1] = "iceCave"
		end

		-- dwemer
		if id:find("dwrv_") or id:find("in_dwe") or id:find("ex_dwe") or
		   id:find("dwemer") or id:find("_dwe_") or id:find("centurion") or
		   id:find("t_dwe_dng") then
			counts.dwemer = counts.dwemer + 1
			tags[#tags+1] = "dwemer"
		end

		-- daedric
		if id:find("_dae_") or id:find("daedric") or id:find("ex_dae") or
		   id:find("in_dae") or id:find("daed_") or id:find("t_dae_dng") then
			counts.daedric = counts.daedric + 1
			tags[#tags+1] = "daedric"
		end

		-- mine
		if id:find("mine") or id:find("in_cavern_") or id:find("eggmine") or
		   id:find("kvatch") or id:find("t_com_setmine_") or
		   id:find("mineentr") then
			counts.mine = counts.mine + 1
			tags[#tags+1] = "mine"
		end

		-- general cave
		if id:find("cave") or id:find("cavern") or id:find("grotto") or
		   id:find("t_cnq_cave_") or (id:find("t_glb_cave") and not id:find("_caveic_")) then
			counts.cave = counts.cave + 1
			tags[#tags+1] = "cave"
		end

		-- castle/fortress (strongholds, keeps, forts, guard towers, large defensive structures)
		if id:find("stronghold") or id:find("_keep") or id:find("fort") or
		   id:find("castle") or id:find("guardtower") or id:find("imp_tower") or
		   id:find("wall_512") or id:find("battlement") or id:find("ex_vivec") or
		   id:find("in_impbig") or
		   id:find("t_bre_setostc_") or id:find("keepwall") or id:find("keepbase") then
			counts.castle = counts.castle + 1
			tags[#tags+1] = "castle"
		end

		-- ashlander (in_ashl, includes yurts)
--[[		if id:find("") or id:find("") or id:find("") or
			id:find("") or id:find("") or id:find("") then
			counts.ashlander = counts.ashlander + 1
			tags[#tags+1] = "ashlander"
		end
]]

		-- mushroom (telvanni)
		if id:find("in_t_") then
			counts.mushroom = counts.mushroom + 1
			tags[#tags+1] = "mushroom"
		end

		-- hlaalu
		if id:find("in_hlaalu") or id:find("in_h_") then
			counts.hlaalu = counts.hlaalu + 1
			tags[#tags+1] = "hlaalu"
		end

		-- redoran (in_redoran, in_r_s_int)
		if id:find("in_redoran") or id:find("in_r_") then
			counts.redoran = counts.redoran + 1
			tags[#tags+1] = "redoran"
		end
		
		-- indoril
		if id:find("in_mh_int_") then
			counts.indoril = counts.indoril + 1
			tags[#tags+1] = "indoril"
		end
		
		-- imperial
		if id:find("in_impsmall_") or id:find("t_imp_setgc_") then
			counts.imperial = counts.imperial + 1
			tags[#tags+1] = "imperial"
		end
		
		-- nord
		if id:find("t_nor_setmarkarth_") or id:find("t_rga_setreach_") or id:find("t_nor_") then
			counts.nord = counts.nord + 1
			tags[#tags+1] = "nord"
		end			
		
		-- sewer/underworks
		if id:find("sewer") or id:find("underwork") then
			counts.sewer = counts.sewer + 1
			tags[#tags+1] = "sewer"
		end

		-- tomb
		if id:find("tomb") or id:find("in_om_") or id:find("in_bm_") or
		   id:find("ancestral") or id:find("crypt") or id:find("burial") or
		   id:find("furn_bone") or
		   id:find("t_bre_dngcrypt") or id:find("coffin") or id:find("sarcophagus") then
			counts.tomb = counts.tomb + 1
			tags[#tags+1] = "tomb"
		end

		-- temple
		if id:find("temple") or id:find("shrine") or id:find("in_velothi") or id:find("prayer_stool") then
			counts.temple = counts.temple + 1
			if id:find("in_mh_temple") then
				counts.temple = counts.temple + 4
				tags[#tags+1] = "temple!!!!"
			else
				tags[#tags+1] = "temple"
			end
		end

		-- house (residential buildings, shacks, interior furniture)
		if id:find("house") or id:find("shack") or id:find("hut") or
		   id:find("in_common_") or id:find("in_de_") or id:find("in_nord_") or
		   id:find("in_redoran_") or id:find("in_hlaalu_") or
		   id:find("furn_") or id:find("t_.*_furn") or
		   id:find("ex_common_building") or id:find("ex_nord_house") or
		   id:find("ex_redoran_hut") or id:find("housepod") or id:find("housestem") then
			counts.house = counts.house + 1
			tags[#tags+1] = "house"
		end

		if #tags > 1 then
			if not prevDash then
				log(5, "-----")
			end
			for _, tag in ipairs(tags) do
				log(5, tag, id)
			end
			log(5, "-----")
			prevDash = true
		elseif #tags == 1 then
			prevDash = false
			log(5, tags[1], id)
		else
			prevDash = false
			log(5, id)
		end
	end
	log(5, "==============")
	local threshold = 3 -- Minimum number of matching statics to classify
	
	if counts.mushroom >= threshold then
		cellInfo.isMushroom = true
		log(3, "isMushroom")
	end
	if counts.hlaalu >= threshold then
		cellInfo.isHlaalu = true
		log(3, "isHlaalu")
	end
	if counts.redoran >= threshold then
		cellInfo.isRedoran = true
		log(3, "isRedoran")
	end
	if counts.indoril >= threshold then
		cellInfo.isIndoril = true
		log(3, "isIndoril")
	end
	if counts.imperial >= threshold then
		cellInfo.isImperial = true
		log(3, "isImperial")
	end
	if counts.nord >= threshold then
		cellInfo.isNord = true
		log(3, "isNord")
	end
	
	-- for bathhouses, only big house is relevant
	if cellInfo.isBath then
		sendCellInfo(player, cell, cellInfo)
		log(3, "isBath")
		return
	end
	
	-- Determine cell types based on thresholds
	-- Prioritise more specific types over general ones
	local isntHouse = false
	if counts.iceCave >= threshold then
		cellInfo.isIceCave = true
		cellInfo.isCave = true -- Ice caves are also caves
		isntHouse = true
		log(3, "isIceCave")
		log(3, "isCave")
	end

	if counts.mine >= threshold then
		cellInfo.isMine = true
		cellInfo.isCave = true -- Mines are cave-like
		isntHouse = true
		log(3, "isMine")
		log(3, "isCave")
	end
--[[if counts.ashlander >= threshold then
		cellInfo.isAshlander = true
		log(3, "isAshlander")
	end]]
-- note: "bath house" can be both bath AND telvanni/redoran/hlaalu/temple

	if counts.sewer >= threshold then
		cellInfo.isSewer = true
		isntHouse = true
		log(3, "isSewer")
	end
	if counts.temple >= threshold then
		cellInfo.isTemple = true
		isntHouse = true
		log(3, "isTemple")
	end
	if counts.daedric >= threshold then
		cellInfo.isDaedric = true
		isntHouse = true
		log(3, "isDaedric")
	elseif counts.dwemer >= threshold then
		cellInfo.isDwemer = true
		isntHouse = true
		log(3, "isDwemer")
	elseif counts.tomb >= threshold*2 then
		cellInfo.isTomb = true
		isntHouse = true
		log(3, "isTomb")
	elseif counts.castle >= threshold then
		cellInfo.isCastle = true
		isntHouse = true
		log(3, "isCastle")
	end
	local countShrines = 0
	for _, object in pairs(cell:getAll(types.Activator)) do
		local recordId = object.recordId
		if recordId == "furn_shrine_tribunal_cure_01" then
			log(3," - temple activator",object.recordId)
			isntHouse = true
			cellInfo.isTomb = false
			cellInfo.isTemple = true
			break
		elseif recordId:find("furn_shrine") then
			countShrines = countShrines + 1
		elseif cellInfo.isTomb and not cellInfo.isSewer then
			local scrName = (types.Activator.record(recordId).mwscript or ''):lower()
			if (scrName == "bed_standard" or scrName == "chargenbed") and not recordId:find("bedroll") then
				log(3," - tomb with bed = temple",recordId)
				isntHouse = true
				cellInfo.isTomb = false
				cellInfo.isTemple = true
				break
			end
		end
	end
	if countShrines > 3 then
		isntHouse = true
		cellInfo.isTomb = false
		cellInfo.isTemple = true
		log(3," - temple (many shrines):",countShrines)
	end
	-- Only mark as generic cave if no other specific type was found
	if counts.cave >= threshold and not (cellInfo.isIceCave or cellInfo.isDwemer or 
	   cellInfo.isDaedric or cellInfo.isTomb or cellInfo.isMine) then
		cellInfo.isCave = true
		isntHouse = true
		log(3, "isCave")
	end
	
	if counts.cave >= threshold and not isntHouse then
		cellInfo.isCave = true
		isntHouse = true
		log(3, "isCave")
	end
	
	if counts.house >= threshold and not isntHouse then
		cellInfo.isHouse = true
		log(3, "isHouse")
	end
	
	sendCellInfo(player, cell, cellInfo)
end

G_eventHandlers.SunsDusk_getCellInfo = getCellInfo