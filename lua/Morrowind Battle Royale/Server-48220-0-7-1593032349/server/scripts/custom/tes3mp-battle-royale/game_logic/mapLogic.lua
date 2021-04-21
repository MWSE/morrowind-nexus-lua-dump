mapLogic = {}

zoneAnchors = {}

-- used to track unique indexes of objects that present cell border
trackedObjects = {
-- basically just fog_border
cellBorderObjects = {}, 
-- items that get spawned at the start of the match
spawnedItems = {},
-- placed containers that contain loot
spawnedLootContainers = {},
-- items that get dropped when player dies
droppedItems = {},
-- items that players manually moved out of their inventory
placedItems = {}
}

mapLogic.DistanceBetweenPositions = function(x1, y1, x2, y2)
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

-- TODO: rewrite this in a way that can generate hybrid zone array (cell-based + geometry-based)
mapLogic.GenerateZones = function()
    
    zoneAnchors = {}
    
    -- TODO: think about introducing some randomness to this. Few cells of random offset?
    -- TEST: 3 cells of random offset 
    previousAnchor = {(brConfig.mapCentre[1]+math.random(-3,3))*8192+4096, (brConfig.mapCentre[2]+math.random(-3,3))*8192+4096}
    --previousAnchor = {brConfig.mapCentre[1]*8192+4096, brConfig.mapCentre[2]*8192+4096}
    
    for zoneIndex, zoneParameters in pairs(brConfig.zoneSizes) do
        zoneAnchors[zoneIndex] = {}
        zoneRadius = zoneParameters[2]*4096
        -- only set previousAnchor if the firt zone defined by mapCentre was already generated
        if zoneIndex > 1 then
            previousAnchor = zoneAnchors[zoneIndex-1]
        end
        
        random_x = math.random(-zoneRadius,zoneRadius)
        -- TODO: learn trigonometry instead of getting your bro Pythagoras to help you cheat
        random_y = (zoneRadius-math.abs(random_x))*math.random(-1,1)
        
        -- make it "snap to grid"
        random_x = random_x - math.fmod(random_x,8192)
        random_y = random_y - math.fmod(random_y,8192)
        
        zoneAnchors[zoneIndex][1] = previousAnchor[1] + random_x
        zoneAnchors[zoneIndex][2] = previousAnchor[2] + random_y
    end
end

-- return X and Y coordinate of the cell where position is located in
mapLogic.GetCellForPosition = function(x, y)
    cell = {}
    cell[1] = math.floor(x/8192)
    cell[2] = math.floor(y/8192)
    return cell
end

-- returns the zone (index) of the smallest zone that cell belongs to
mapLogic.GetZoneForCell = function(x, y)
    -- to take centre of the cell. leave as 0 in order to work with bottom-left corner of the cell
    local centre = 4096
    local x_coordinates = x*8192+centre
    local y_coordinates = y*8192+centre
    local offset = 1000
    -- go through all zones in reverse
    for zone=#zoneAnchors, 1, -1 do
        if zoneAnchors[zone] then
            if mapLogic.DistanceBetweenPositions(x_coordinates, y_coordinates, zoneAnchors[zone][1], zoneAnchors[zone][2]) < (brConfig.zoneSizes[zone][2])*8192+2048 then
                return zone
            end
            -- see if anchor is actually inside cell in question (makes the zones with size 0 still appear)
            anchorCell = mapLogic.GetCellForPosition(zoneAnchors[zone][1], zoneAnchors[zone][2])
            if anchorCell[1] == x and anchorCell[2] == y then
               return zone 
            end
        end
    end
    
    -- cell is outside of the biggest zone
    return 0
end

-- returns all cells that are in zone
mapLogic.GetCellsInZone = function(zone)
    cellsInZone = {}
    brDebug.Log(1, "Getting cells for zone " .. tostring(zone))
    if zone == 0 then
        for x=brConfig.mapBorders[1][1],brConfig.mapBorders[2][1] do
            for y=brConfig.mapBorders[1][2],brConfig.mapBorders[2][2] do
                if mapLogic.GetZoneForCell(x, y) == zone then
                   table.insert(cellsInZone, {x, y}) 
                end
            end
        end
    elseif brConfig.zoneSizes[zone] and zoneAnchors[zone] then
        zoneCentre = mapLogic.GetCellForPosition(zoneAnchors[zone][1], zoneAnchors[zone][2])
        -- TODO: lolwait, am I scanning area 4x too large? Zone takes size as diameter, not as radius. Optimise this
        zoneAreaBottomLeftCorner = {zoneCentre[1]-brConfig.zoneSizes[zone][2], zoneCentre[2]-brConfig.zoneSizes[zone][2]}
        zoneAreaTopRightCorner = {zoneCentre[1]+brConfig.zoneSizes[zone][2], zoneCentre[2]+brConfig.zoneSizes[zone][2]}
        for x=zoneAreaBottomLeftCorner[1],zoneAreaTopRightCorner[1] do
            for y=zoneAreaBottomLeftCorner[2],zoneAreaTopRightCorner[2] do
                if mapLogic.GetZoneForCell(x, y) == zone then
                    table.insert(cellsInZone, {x, y})
                end
            end
        end
    end
    return cellsInZone
end

-- replace the current zone-marking tiles with the normal (vanilla) ones
mapLogic.ResetMapTiles = function(steps, delay)
	tes3mp.LogMessage(2, "Resetting map tiles")
	tes3mp.ClearMapChanges()

	for x=brConfig.mapBorders[1][1],brConfig.mapBorders[2][1] do
	    for y=brConfig.mapBorders[1][2],brConfig.mapBorders[2][2] do
            brDebug.Log(4, "Refreshing tile " .. x .. ", " .. y )
            filePath = tes3mp.GetDataPath() .. "/map/" .. x .. ", " .. y .. ".png"
            tes3mp.LoadMapTileImageFile(x, y, filePath)
        end
    end
end

-- replace the current zone-marking tiles with the normal (vanilla) ones
-- used for debug purposes
mapLogic.ShowZones = function()
	tes3mp.LogMessage(2, "Resetting map tiles")
	tes3mp.ClearMapChanges()
    
    for x=brConfig.mapBorders[1][1],brConfig.mapBorders[2][1] do
	    for y=brConfig.mapBorders[1][2],brConfig.mapBorders[2][2] do
            zone = mapLogic.GetZoneForCell(x, y)
            if zone > 0 then
                brDebug.Log(4, "Colouring tile " .. x .. ", " .. y )
                filePath = tes3mp.GetDataPath() .. "/map/fog" .. tostring(math.fmod(zone,3)+1) .. ".png"
                tes3mp.LoadMapTileImageFile(x, y, filePath)
            end
        end
    end
end

-- prepares tiles in world map to reflect the state of zone shrink
mapLogic.UpdateMap = function()
    
    tes3mp.ClearMapChanges()
    
    -- TODO: figure out how to limit this to just the zones that changed colour
    for zone=0,#zoneAnchors do
        zoneCells = mapLogic.GetCellsInZone(zone)
        brDebug.Log(3, "Got " .. tostring(#zoneCells) .. ", applying tiles")
        for index, cell in pairs(zoneCells) do
            newDamageLevel = matchLogic.GetDamageLevelForZone(zone)
            if newDamageLevel then --and matchLogic.GetDamageLevelForZone(zone-1) ~= then
                filePath = tes3mp.GetDataPath() .. "/map/fog" .. matchLogic.GetDamageLevelForZone(zone) .. ".png"
                tes3mp.LoadMapTileImageFile(cell[1], cell[2], filePath)
            end
        end
        brDebug.Log(4, "Tiles applied")
    end
    
end

-- sets up a ghostfence-looking wall around the given group of cells
mapLogic.PlaceBorderAroundZone = function(zone)
    
        --mapLogic.PlaceCellBorders(x, y, true, false, false, false)
    
    zoneCells = mapLogic.GetCellsInZone(zone)
    
    -- TODO: find something better than this very ugly barbaric way of converting zone to array

    mappedX = {}
    mappedY = {}
    
    for index, cell in pairs(zoneCells) do
        
        -- this should result in an array where indexes are x coordinate and value is table with all y coords in that row
        -- create row if it does not exist yet
        if not mappedX[cell[1]] then
            mappedX[cell[1]] = {}
        end
        table.insert(mappedX[cell[1]], cell[2])
        
        -- repeat for y
        if not mappedY[cell[2]] then
            mappedY[cell[2]] = {}
        end
        table.insert(mappedY[cell[2]], cell[1])
        
    end
    
    for x, y_list in pairs(mappedX) do
        brDebug.Log(3, "Borders on X "..tostring(x)..": min=" .. tostring(math.min(unpack(y_list))) .. ", max=" .. tostring(math.max(unpack(y_list))))
        -- place bottom borders
        mapLogic.PlaceCellBorders(x, math.min(unpack(y_list)), false, true, false, false)
        -- place top borders
        mapLogic.PlaceCellBorders(x, math.max(unpack(y_list)), true, false, false, false)
    end
    
    for y, x_list in pairs(mappedY) do
        brDebug.Log(3, "Borders on Y "..tostring(y)..": min=" .. tostring(math.min(unpack(x_list))) .. ", max=" .. tostring(math.max(unpack(x_list))))
        -- place left borders
        mapLogic.PlaceCellBorders(math.min(unpack(x_list)), y, false, false, true, false)
        -- place right borders
        mapLogic.PlaceCellBorders(math.max(unpack(x_list)), y, false, false, false, true)
    end
end

-- deletes the objects that are currently tracked in cellBorderObjects
mapLogic.RemoveCurrentBorder = function()
    
    if #trackedObjects["cellBorderObjects"] > 0 then
        for index, entry in pairs(trackedObjects["cellBorderObjects"]) do
            mapLogic.DeleteObject(trackedObjects["cellBorderObjects"][index][1], trackedObjects["cellBorderObjects"][index][2])
        end
    end
end

-- sets border at cell edge if given true
-- TODO: use the enumeration instead of 4 booleans
mapLogic.PlaceCellBorders = function(cell_x, cell_y, top, bottom, left, right)
    if top then
        mapLogic.PlaceBorderBetweenCells(cell_x, cell_y, cell_x, cell_y+1)
    end
    if bottom then
        mapLogic.PlaceBorderBetweenCells(cell_x, cell_y, cell_x, cell_y-1)
    end
    if left then
        mapLogic.PlaceBorderBetweenCells(cell_x, cell_y, cell_x-1, cell_y)
    end
    if right then
        mapLogic.PlaceBorderBetweenCells(cell_x, cell_y, cell_x+1, cell_y)
    end
end

-- determines which of the two cells will host the mesh and places a ghostfence mesh on the border between the given cells
mapLogic.PlaceBorderBetweenCells = function(cell1_x, cell1_y, cell2_x, cell2_y)
    local horisontal_border = nil
    -- 3.14159 (pi) is 180 degrees, 1.5708 is 90 degrees
    local rotation = 0

    -- TODO: rewrite this in a decent way, so that it doesn't end up in a CS Diploma meme
    if cell1_x == cell2_x then
        horisontal_border = false
    elseif cell1_y == cell2_y then
        horisontal_border = true
        rotation = 1.5708
    else
        -- turns out cells don't even share the edge lol
        tes3mp.LogMessage(2, "Cells have no sides in common, can't place border between them")
        return
    end
    
    brDebug.Log(3, "Finding host cell for border between " .. tostring(cell1_x) .. ", " .. tostring(cell1_y) .. " and " .. tostring(cell2_x) .. ", " .. tostring(cell2_y))
    
    local host_cell = nil

    if cell1_x > cell2_x or cell1_y > cell2_y then
        host_cell = 1
    else
        host_cell = 2
    end
    
    local cells = {{cell1_x, cell1_y}, {cell2_x, cell2_y}}
    local host_cell_string = tostring(cells[host_cell][1]) .. ", " .. tostring(cells[host_cell][2])
    local x_coordinate = cells[host_cell][1] * 8192
    local y_coordinate = cells[host_cell][2] * 8192

    if horisontal_border then
        y_coordinate = y_coordinate + 4096
    else
        x_coordinate = x_coordinate + 4096
    end
    
    mapLogic.PlaceObject("fog_border", host_cell_string, x_coordinate, y_coordinate, 4200, 0, 3.14159, rotation, 2.677, trackedObjects["cellBorderObjects"])
end

-- used for pseudo-statics. For spawning items use mapLogic.PlaceItem, as items require more parameters
mapLogic.PlaceObject = function(object_id, cell, x, y, z, rot_x, rot_y, rot_z, scale, list)
	brDebug.Log(3, "Placing object " .. tostring(object_id) .. " in cell " .. tostring(cell))
    brDebug.Log(3, "x: " .. tostring(x) .. ", y: " .. tostring(y) .. ", z: " .. tostring(z))
	local mpNum = WorldInstance:GetCurrentMpNum() + 1
	local refId = object_id
    local location = {posX = x, posY = y, posZ = z, rotX = rot_x, rotY = rot_y, rotZ = rot_z}
	local refIndex =  0 .. "-" .. mpNum
	
	WorldInstance:SetCurrentMpNum(mpNum)
	tes3mp.SetCurrentMpNum(mpNum)

	if LoadedCells[cell] == nil then
		logicHandler.LoadCell(cell)
	end
	LoadedCells[cell]:InitializeObjectData(refIndex, refId)
	LoadedCells[cell].data.objectData[refIndex].location = location
	LoadedCells[cell].data.objectData[refIndex].scale = scale
	table.insert(LoadedCells[cell].data.packets.place, refIndex)

    -- add object to the list
    -- this is basically used just to track instances of fog_border
    if list then
        entry = {cell, refIndex}
        table.insert(list, entry)
    end

    -- TODO: ask David about networking. Do we have to send one package for each object placement
    -- or can that be grouped together in some way.
	brDebug.Log(2, "Sending object info to players")
	for index, onlinePid in pairs(matchLogic.GetPlayerList()) do
		if Players[onlinePid]:IsLoggedIn() then
			tes3mp.InitializeEvent(onlinePid)
			tes3mp.SetEventCell(cell)
			tes3mp.SetObjectRefId(refId)
			tes3mp.SetObjectRefNumIndex(0)
			tes3mp.SetObjectMpNum(mpNum)
			tes3mp.SetObjectPosition(location.posX, location.posY, location.posZ)
			tes3mp.SetObjectRotation(location.rotX, location.rotY, location.rotZ)
			tes3mp.SetObjectScale(scale)
			tes3mp.AddWorldObject()
			tes3mp.SendObjectPlace()
			tes3mp.SendObjectScale()
		end
	end
	LoadedCells[cell]:Save()
end

-- places loot at the positions defined in config file
mapLogic.SpawnLoot = function()
    
    matchLogic.PrepareLootTables()
    
    for key, spawnArea in pairs(brConfig.lootSpawnAreas) do
        
         brDebug.Log(1, "Spawning loot in area: " .. key )
        
        -- create a table of all possible position indexes
        local positionIndexTable = {{}, {}, {}, {}}
        for tier=1,4 do
            for i=1,#spawnArea.lootSpawnPositions[tier] do
                table.insert(positionIndexTable[tier], i)
            end
            
            -- shuffle the positions in each tier table so that they get chosen in random order
            if #positionIndexTable[tier] >= 2 then
                for i = #positionIndexTable[tier], 2, -1 do
                    local j = math.random(i)
                    positionIndexTable[tier][i], positionIndexTable[tier][j] = positionIndexTable[tier][j], positionIndexTable[tier][i]
                end
            end
        end
        
        --{"-2, 2", -11607.515625, 1345.39453125, 19497.453125, type(optional) }
        for tier=1,4 do
            local containerCount = spawnArea.containerCount[tier]
            local groundLootCount = spawnArea.groundLootCount[tier]
            local uniqueItemCount = spawnArea.uniqueItemCount[tier]
            for index, positionIndex in pairs(positionIndexTable[tier]) do
                
                local position = spawnArea.lootSpawnPositions[tier][positionIndex]
                
                -- determine the amount of unique items to spawn at current locatiom
                local uniqueItemsOnPosition = 0
                if uniqueItemCount > 0 then
                    uniqueItemsOnPosition = 1
                    uniqueItemCount = uniqueItemCount - 1
                end
                
                -- if statement because one position can have either container or ground loot, can't have both
                if containerCount > 0 then
                    local randomMargin = math.random(0,brConfig.containerLootLimits[2])
                    local randomLoot = matchLogic.GetRandomLoot(brConfig.containerLootLimits[1]+randomMargin, uniqueItemsOnPosition, position[6], tier)
                    mapLogic.SpawnLootContainer(position[1], position[2], position[4], position[3], position[5], randomLoot, tier)
                    containerCount = containerCount - 1
                    
                elseif groundLootCount > 0 then
                    local randomMargin = math.random(0,brConfig.containerLootLimits[2])
                    local randomLoot = matchLogic.GetRandomLoot(brConfig.containerLootLimits[1]+randomMargin, uniqueItemsOnPosition, position[6], tier)
                    mapLogic.SpawnLootAroundPosition(position[1], position[2], position[4], position[3], position[5], randomLoot)
                    groundLootCount = groundLootCount - 1
                    
                else
                    -- all requirements satisfied, nothing left to spawn
                    break
                end
            end
        end
    end
    
    mapLogic.SaveAllLoadedCells()
end

-- TODO: make this actually work as intended
mapLogic.SpawnLootContainer = function(cell, x, y, z, rot_z, lootList, tier)
    --containerID = nil
    --table.insert(trackedObjects.spawnedLootContainers, containerID)
    mapLogic.SpawnLootAroundPosition(cell, x, y, z, rot_z, lootList)
end

-- places items around the given coordinates
-- first one exactly at the giveen position and rest of the items around it
-- TODO: edge case: this will not work as intended if position is too close to cell border
-- maybe check if x and y are too close to 8192x ?
mapLogic.SpawnLootAroundPosition = function(cell, x, y, z, rot_z, lootList)
    local spawnAreaSize = 30
    for index, item in pairs(lootList) do
        local x_offset = 0
        local y_offset = 0
        if index > 1 then
            x_offset = math.sin(index*20)*spawnAreaSize
            y_offset = math.cos(index*20)*spawnAreaSize
        end
        mapLogic.PlaceItem(item[1], cell, x+x_offset, y+y_offset, z+10, rot_z, item[2], -1, trackedObjects["spawnedItems"], true)
    end
end

-- place the given object in the world
mapLogic.PlaceItem = function(object_id, cell, x, y, z, rot_z, item_count, item_charge, list, skipCellSave)
    brDebug.Log(3, "Placing item " .. tostring(object_id) .. " in cell " .. tostring(cell))
    brDebug.Log(3, "x: " .. tostring(x) .. ", y: " .. tostring(y) .. ", z: " .. tostring(z))
    brDebug.Log(4, "item_count: " .. tostring(item_count))
	local mpNum = WorldInstance:GetCurrentMpNum() + 1
	local refId = object_id
    local location = {posX = x, posY = y, posZ = z, rotX = 0, rotY = 0, rotZ = rot_z}
	local refIndex =  0 .. "-" .. mpNum
	
	WorldInstance:SetCurrentMpNum(mpNum)
	tes3mp.SetCurrentMpNum(mpNum)

	if LoadedCells[cell] == nil then
		logicHandler.LoadCell(cell)
	end
	LoadedCells[cell]:InitializeObjectData(refIndex, refId)
	LoadedCells[cell].data.objectData[refIndex].location = location
	table.insert(LoadedCells[cell].data.packets.place, refIndex)

    -- add object to the list
    -- this is basically used just to track instances of fog_border
    if list then
        entry = {cell, refIndex}
        table.insert(list, entry)
    end

    -- TODO: ask David about networking. Do we have to send one package for each object placement
    -- or can that be grouped together in some way.
	brDebug.Log(2, "Sending spawned item info to players")
	for index, onlinePid in pairs(matchLogic.GetPlayerList()) do
		if Players[onlinePid]:IsLoggedIn() then
            tes3mp.InitializeEvent(onlinePid)
            tes3mp.SetEventCell(cell)
            tes3mp.SetObjectRefId(refId)
            tes3mp.SetObjectCount(item_count)
            tes3mp.SetObjectCharge(item_charge)
            tes3mp.SetObjectEnchantmentCharge(item_charge)
            tes3mp.SetObjectRefNumIndex(0)
            tes3mp.SetObjectMpNum(mpNum)
            tes3mp.SetObjectPosition(location.posX, location.posY, location.posZ)
            tes3mp.SetObjectRotation(location.rotX, location.rotY, location.rotZ)
            tes3mp.AddWorldObject()
            tes3mp.SendObjectPlace()
		end
	end
    if not skipCellSave then
        LoadedCells[cell]:Save()
    end
end

-- removes the given object
mapLogic.DeleteObject = function(cellName, objectUniqueIndex)
    if cellName and LoadedCells[cellName] then
        LoadedCells[cellName]:DeleteObjectData(objectUniqueIndex)
        logicHandler.DeleteObjectForEveryone(cellName, objectUniqueIndex)
    end
end

-- TODO: implement this after implementing chests / drop-on-death
mapLogic.ResetWorld = function()

    -- removes the last active border
    mapLogic.RemoveCurrentBorder()

    --cleans up items
    --testBR.RemoveAllItems()
    --testBR.ResetCells()
    --testBR.ResetTimeOfDay()
    --testBR.ResetWeather()

    -- TODO: would this be more elegant with functions or is it fine to just brute-force through the list?
    for _, category in pairs(trackedObjects) do
        for _, list in pairs(category) do
            for index, entry in pairs(list) do
                mapLogic.DeleteObject(entry[1], entry[2])
            end
        end
    end
    
    debug.DeleteExteriorCellData()
    
end

mapLogic.GetZoneAnchors = function()
    return zoneAnchors
end

-- writes to disk all the loaded cell data
-- used so that we don't write to disk for every change in cell during match start
mapLogic.SaveAllLoadedCells = function()
    for index, cell in pairs(LoadedCells) do
        cell:Save()
    end
end

-- checks if player is allowed to be in the cell
mapLogic.ValidateCell = function(pid)
    
    brDebug.Log(4, "Checking if PID " .. tostring(pid) .. " is allowed to be in the cell.")
    
    cell = tes3mp.GetCell(pid)

	-- allow player to spawn in lobby	
	if cell == PlayerLobby.config.cell then
		return true
	end

    if not mapLogic.IsCellExternal(cell) then
		tes3mp.LogMessage(2, "Cell is not external and can not be entered")
		Players[pid].data.location.posX = tes3mp.GetPreviousCellPosX(pid)
		Players[pid].data.location.posY = tes3mp.GetPreviousCellPosY(pid)
		Players[pid].data.location.posZ = tes3mp.GetPreviousCellPosZ(pid)
        Players[pid]:LoadCell()
        return false
    end
    
    return true
end

-- check if cell is external
mapLogic.IsCellExternal = function(cell)
    brDebug.Log(3, "Checking if the cell (" .. cell .. ") is external.")
	_, _, cellX, cellY = string.find(cell, patterns.exteriorCell)
    brDebug.Log(3, "cellX: " .. tostring(cellX) .. ", cellY: " .. tostring(cellY))
    if cellX == nil or cellY == nil then
        return false
    end
    return true
end

mapLogic.GerRandomPositionInsideZone = function(zoneIndex)
    if zoneAnchors[zoneIndex] and brConfig.zoneSizes[zoneIndex] then
        local zoneRadius = brConfig.zoneSizes[zoneIndex][2]*4096
        local random_x_offset = math.random(-zoneRadius,zoneRadius)
        -- TODO: learn trigonometry instead of getting your bro Pythagoras to help you cheat
        local random_y_offset = (zoneRadius-math.abs(random_x_offset))*math.random(-1,1)
        
        local random_x = zoneAnchors[zoneIndex][1] + random_x_offset
        local random_y = zoneAnchors[zoneIndex][2] + random_y_offset
        return {random_x, random_y}
    end
end

return mapLogic