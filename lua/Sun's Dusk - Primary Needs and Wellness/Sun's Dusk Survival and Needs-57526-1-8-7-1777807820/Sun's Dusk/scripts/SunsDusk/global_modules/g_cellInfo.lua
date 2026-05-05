G_cellInfoCache = {}

-- G_cellInfoCache[cell.id] =
-- .isExterior = false,
-- .isIceCave = false,
-- .isCave = false,
-- .isDwemer = false,
-- .isDaedric = false,
-- .isMine = false,
-- .isTomb = false,
-- .isHouse = false,
-- .isCastle = false,
-- .isMushroom = false,  -- Telvanni
-- .isHlaalu = false,    -- Hlaalu
-- .isRedoran = false,   -- Redoran
-- .isSewer = false,     -- Sewers/Underworks
-- .isTemple = false,    -- Temple interiors
-- .isBath = false,
-- .isAshlander = false,
-- .hasPublican = false,
-- .nextExteriorCell = cell
-- .nextExteriorPosition = v3
-- .fires = {}


-- Helper: cache interior cellInfo for global-side water type resolution (used by g_liquids)
-- and send to the player script
local function sendCellInfo(player, cell, cellInfo)
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
		sewer    = 0,      
		temple   = 0,
		bath     = 0,
	--  ashlander= 0,
	}
	
	-- Iterate through all statics in the cell, TD patterns start with t_
	for _, object in pairs(cell:getAll(types.Static)) do
		local id = object.recordId
		local foundMatch = false
		
		-- Check for Ice Cave indicators
		if (id:find("ice") or id:find("frost") or id:find("snow") or id:find("frozen") or
		   id:find("_caveic_") or id:find("t_glb_terrice_") or id:find("icicle"))
			and not id:find("practice") and not id:find("office") and not id:find("justice") then
			foundMatch = true
			log(5,"iceCave",id)
			counts.iceCave = counts.iceCave + 1
		end
		
		-- Check for Dwemer indicators
		if id:find("dwrv_") or id:find("in_dwe") or id:find("ex_dwe") or 
		   id:find("dwemer") or id:find("_dwe_") or id:find("centurion") or
		   id:find("t_dwe_dng") then
			foundMatch = true
			log(5,"dwemer",id)
			counts.dwemer = counts.dwemer + 1
		end
		
		-- Check for Daedric indicators
		if id:find("_dae_") or id:find("daedric") or id:find("ex_dae") or 
		   id:find("in_dae") or id:find("daed_") or id:find("t_dae_dng") then
			foundMatch = true
			log(5,"daedric",id)
			counts.daedric = counts.daedric + 1
		end
		
		-- Check for Mine indicators
		if id:find("mine") or id:find("in_cavern_") or id:find("eggmine") or
		   id:find("kvatch") or id:find("t_com_setmine_") or
		   id:find("mineentr") then
			foundMatch = true
			log(5,"mine",id)
			counts.mine = counts.mine + 1
		end
		
		-- Check for general Cave indicators
		if id:find("cave") or id:find("cavern") or id:find("grotto") or
		   id:find("t_cnq_cave_") or (id:find("t_glb_cave") and not id:find("_caveic_")) then
			foundMatch = true
			log(5,"cave",id)
			counts.cave = counts.cave + 1
		end
		
		-- Check for Castle/Fortress indicators (strongholds, keeps, forts, guard towers, and large defensive structures)
		if id:find("stronghold") or id:find("_keep") or id:find("fort") or
		   id:find("castle") or id:find("guardtower") or id:find("imp_tower") or
		   id:find("wall_512") or id:find("battlement") or id:find("ex_vivec") or
		   id:find("in_impbig") or
		   id:find("t_bre_setostc_") or id:find("keepwall") or id:find("keepbase") then
			foundMatch = true
			log(5,"castle",id)
			counts.castle = counts.castle + 1
		end
		
		-- Check for Ashlander indicators in_ashl
		-- Includes yurts
--[[		if id:find("") or id:find("") or id:find("") or
			id:find("") or id:find("") or id:find("") then
			foundMatch = true
			log(5,"ashlander",id)
			counts.ashlander = counts.ashlander + 1
		end
]]

		if id:find("in_t_") then
			foundMatch = true
			counts.mushroom = counts.mushroom + 1
		end
		
		-- Texture pattern: in_hlaalu
		if id:find("in_hlaalu") or id:find("in_h_") then
			foundMatch = true
			counts.hlaalu = counts.hlaalu + 1
			log(5, "hlaalu", id)
		end
		
		-- Texture patterns: in_redoran, in_r_s_int
		if id:find("in_redoran") or id:find("in_r_") then
			foundMatch = true
			counts.redoran = counts.redoran + 1
			log(5, "redoran", id)
		end
		
		-- Check for Sewer/Underworks indicators
		if id:find("sewer") or id:find("underwork") then
			foundMatch = true
			counts.sewer = counts.sewer + 1
			log(5, "sewer", id)
		end
				-- Check for Tomb indicators
		if id:find("tomb") or id:find("in_om_") or id:find("in_bm_") or 
		   id:find("ancestral") or id:find("crypt") or id:find("burial") or
		   id:find("furn_bone") or
		   id:find("t_bre_dngcrypt") or id:find("coffin") or id:find("sarcophagus") then
			foundMatch = true
			log(5,"tomb",id)
			counts.tomb = counts.tomb + 1
		end
		-- Check for Temple indicators
		if id:find("temple") or id:find("shrine") or id:find("in_velothi") or id:find("prayer_stool")  then -- no idea about this static
			foundMatch = true
			counts.temple = counts.temple + 1
			if id:find("in_mh_temple") then
				counts.temple = counts.temple + 4
				log(5, "temple!!!!!", id)
			else
				log(5, "temple", id)
			end
		-- Check for House indicators (residential buildings, shacks, and interior furniture) 
		end
		if (id:find("house") or id:find("shack") or id:find("hut") or
		   id:find("in_common_") or id:find("in_de_") or id:find("in_nord_") or
		   id:find("in_redoran_") or id:find("in_hlaalu_") or
		   id:find("furn_") or id:find("t_.*_furn") or
		   id:find("ex_common_building") or id:find("ex_nord_house") or
		   id:find("ex_redoran_hut") or id:find("housepod") or id:find("housestem")) then
		--and not foundMatch then
			foundMatch = true
			log(5,"house",id)
			counts.house = counts.house + 1
		end

		if not foundMatch then
			log(5,id)
		end
		log(5,"----")
	end
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