local lastCell
local lastPosition
local CELL_SIZE = 8192

local MIN_ORE_PER_CELL = 3
local MAX_FAILS_PER_CELL = 33

-- interior vars
local MAX_INTERIOR_ORE = 10
local MAX_INTERIOR_FAILS = 100

local activeCells = {}
local currentCellIndex = 1
local spawnedOrePositions = {}
local framesInCell = 0


local function parseCellID(cellID)
	local x, y = cellID:match("Esm3ExteriorCell:(-?%d+):(-?%d+)")
	return tonumber(x), tonumber(y)
end

local function updateActiveCells()
	if not self.cell or not self.cell.gridX then 
		return 
	end
	
	activeCells = {}
	local px, py = parseCellID(self.cell.id)
	
	for dx = -1, 1 do
		for dy = -1, 1 do
			local targetCellID = string.format("Esm3ExteriorCell:%d:%d", px + dx, py + dy)
			if (saveData.cellOreCount[targetCellID] or 0) >= MIN_ORE_PER_CELL or (saveData.cellFailCount[targetCellID] or 0) >= MAX_FAILS_PER_CELL then
				-- already full
			else
				table.insert(activeCells, targetCellID)
			end
		end
	end
	currentCellIndex = 1
end



local function getCellBounds(cellID)
	local cellX, cellY = parseCellID(cellID)
	
	return {
		minX = cellX * CELL_SIZE,
		maxX = (cellX + 1) * CELL_SIZE,
		minY = cellY * CELL_SIZE,
		maxY = (cellY + 1) * CELL_SIZE
	}
end

function pointInPolygon(x, y, polygon)
    local n = #polygon
    local inside = false
    
    local j = n
    for i = 1, n do
        local xi, yi = polygon[i][1], polygon[i][2]
        local xj, yj = polygon[j][1], polygon[j][2]
        
        -- Prüfe ob Punkt genau auf einer Kante liegt
        local minY, maxY = math.min(yi, yj), math.max(yi, yj)
        local minX, maxX = math.min(xi, xj), math.max(xi, xj)
        
        -- Punkt auf horizontaler Kante
        if yi == yj and yi == y and x >= minX and x <= maxX then
            return true
        end
        
        -- Punkt auf vertikaler Kante  
        if xi == xj and xi == x and y >= minY and y <= maxY then
            return true
        end
        
        -- Punkt auf schräger Kante
        if yi ~= yj and xi ~= xj then
            local cross = (y - yi) * (xj - xi) - (x - xi) * (yj - yi)
            if math.abs(cross) < 0.0001 and x >= minX and x <= maxX and y >= minY and y <= maxY then
                return true
            end
        end
        
        -- Standard Ray-Casting mit angepassten Grenzfällen
        if ((yi > y) ~= (yj > y)) then
            local intersectX = (xj - xi) * (y - yi) / (yj - yi) + xi
            if x < intersectX then
                inside = not inside
            elseif math.abs(x - intersectX) < 0.0001 then
                -- Punkt liegt genau auf dem Schnittpunkt
                return true
            end
        end
        
        j = i
    end
    
    return inside
end

local redMountain = {
    {-3, 10}, {-3, 9}, {-2, 9}, {-1, 9}, {-1, 8}, {0, 8}, {0, 7},
    {1, 7}, {1, 6}, {0, 6}, {0, 5}, {1, 5}, {1, 4}, {2, 4}, {3, 4},
    {3, 5}, {4, 5}, {4, 6}, {4, 7}, {5, 7}, {5, 8}, {5, 9}, {5, 10},
    {5, 11}, {4, 11}, {3, 11}, {2, 11}, {1, 11}, {0, 11}, {-1, 11},
    {-2, 11}, {-3, 10}
}

local function isInRedMountain(cellID)
	local x,y = parseCellID(cellID)
	local ret = pointInPolygon(x,y,redMountain)
	--print(cellID.." red mountain:", ret,x,y)
	return ret
end

-- Function to calculate 2D surface area spanned by actors
-- Assumes actors have a .position field with .x and .y components
function calculateActorSurfaceArea()
    -- Cross product of two 2D vectors
    local function cross2D(o, a, b)
        return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
    end

    -- Graham scan algorithm to find convex hull
    local function convexHull(points)
        if #points < 3 then
            return points -- Not enough points for a polygon
        end
        
        -- Find the bottom-most point (or left most in case of tie)
        local start = 1
        for i = 2, #points do
            if points[i].y < points[start].y or 
               (points[i].y == points[start].y and points[i].x < points[start].x) then
                start = i
            end
        end
        
        -- Swap to put start point first
        points[1], points[start] = points[start], points[1]
        local pivot = points[1]
        
        -- Sort points by polar angle with respect to pivot
        local function polarAngleCompare(a, b)
            local cross = cross2D(pivot, a, b)
            if cross == 0 then
                -- If collinear, sort by distance
                local distA = (a.x - pivot.x)^2 + (a.y - pivot.y)^2
                local distB = (b.x - pivot.x)^2 + (b.y - pivot.y)^2
                return distA < distB
            end
            return cross > 0
        end
        
        -- Sort points 2 to n
        local sortablePoints = {}
        for i = 2, #points do
            table.insert(sortablePoints, points[i])
        end
        table.sort(sortablePoints, polarAngleCompare)
        
        -- Rebuild points array
        local sortedPoints = {points[1]}
        for i = 1, #sortablePoints do
            table.insert(sortedPoints, sortablePoints[i])
        end
        
        -- Graham scan
        local hull = {}
        for i = 1, #sortedPoints do
            -- Remove points that make clockwise turn
            while #hull >= 2 and cross2D(hull[#hull-1], hull[#hull], sortedPoints[i]) <= 0 do
                table.remove(hull)
            end
            table.insert(hull, sortedPoints[i])
        end
        
        return hull
    end

    -- Calculate area of polygon using shoelace formula
    local function polygonArea(points)
        if #points < 3 then
            return 0
        end
        
        local area = 0
        local n = #points
        
        for i = 1, n do
            local j = (i % n) + 1
            area = area + (points[i].x * points[j].y)
            area = area - (points[j].x * points[i].y)
        end
        
        return math.abs(area) / 2
    end
    -- Extract positions from actors
    local positions = {}
    print("wtf")
    for _, actor in pairs(nearby.actors) do
		print(actor)
        if actor.position and actor.position.x and actor.position.y then
            table.insert(positions, {
                x = actor.position.x,
                y = actor.position.y
            })
        end
    end
    
    if #positions < 3 then
        return 0 -- Need at least 3 points to form a surface
    end
    
    -- Remove duplicate points
    local uniquePositions = {}
    for i = 1, #positions do
        local isDuplicate = false
        for j = 1, #uniquePositions do
            if math.abs(positions[i].x - uniquePositions[j].x) < 1e-10 and
               math.abs(positions[i].y - uniquePositions[j].y) < 1e-10 then
                isDuplicate = true
                break
            end
        end
        if not isDuplicate then
            table.insert(uniquePositions, positions[i])
        end
    end
    
    if #uniquePositions < 3 then
        return 100*100
    end
    
    -- Find convex hull
    local hull = convexHull(uniquePositions)
    
    -- Calculate area
    return polygonArea(hull)
end


local function isValidSurface(hitObject)
	return (
		not hitObject 
		or (
			not hitObject.recordId:find("_stal")
			and not hitObject.recordId:find("form")
			and not hitObject.recordId:find("bone")
			and not hitObject.recordId:find("_dae")
			
		)
		and
		(
			hitObject.recordId:find("rock") 
			--or (hitObject.recordId:find("moldcave") and not hitObject.recordId:find("moldcave_stal") and not hitObject.recordId:find("moldcave_form"))
			--or (hitObject.recordId:find("mudcave") and not hitObject.recordId:find("mudcave_stal") and not hitObject.recordId:find("mudcave_form"))
			--or (hitObject.recordId:find("pycave") and not hitObject.recordId:find("pycave_stal") and not hitObject.recordId:find("pycave_form"))
			--or (hitObject.recordId:find("lavacave") and not hitObject.recordId:find("lavacave_stal") and not hitObject.recordId:find("lavacave_form"))
			--or hitObject.recordId:find("bm_cave")
			
			or hitObject.recordId:find("cave") 
			or hitObject.recordId:find("tunnel") 
			or hitObject.recordId:find("boulder")
		)
	)

end


local function checkForStalactite(rayStart, rayEnd, rayDir, originalHitPos)
	-- Erstelle zwei senkrechte Vektoren zum ursprünglichen Ray
	local up = util.vector3(0, 0, 1)
	local right = rayDir:cross(up):normalize()
	
	-- Parallele Rays in verschiedenen Richtungen
	local offset = 150 -- ca. 1.5 Meter seitlicher Abstand
	local parallelRays = {
		{ start = rayStart + right * offset, dir = rayDir },	  -- rechts
		{ start = rayStart + right * offset*1.5, dir = rayDir },	  -- rechts
		{ start = rayStart - right * offset, dir = rayDir },	  -- links
		{ start = rayStart - right * offset*1.5, dir = rayDir },	  -- links
		{ start = rayStart + up * offset, dir = rayDir },		 -- oben
		{ start = rayStart - up * offset, dir = rayDir }		  -- unten
	}
	
	local validHits = {}
	
	for _, ray in ipairs(parallelRays) do
		local testEnd = ray.start + ray.dir * (rayEnd - rayStart):length()*1.5
		
		local testRes = nearby.castRay(
			ray.start,
			testEnd,
			{ radius = 1, collisionType = nearby.COLLISION_TYPE.AnyPhysical}
		)
		
		-- Sammle gültige Treffer auf Gestein
		if testRes.hit and isValidSurface(testRes.hitObject) then
			table.insert(validHits, testRes.hitPos)
		end
	end
	
	-- Prüfe Entfernungen zwischen den HitPositions
	if #validHits < 3 then
		return true -- Zu wenige Treffer = wahrscheinlich Stalaktit
	end
	
	-- Prüfe ob die parallelen Hits zu weit vom ursprünglichen Hit entfernt sind
	local maxAllowedDistance = 300 -- ca. 2.5 Meter
	local farHits = 0
	
	for _, hitPos in ipairs(validHits) do
		local distance = (hitPos - originalHitPos):length()
		if distance > maxAllowedDistance then
			farHits = farHits + 1
		end
	end
	
	-- Wenn mehr als die Hälfte der Hits zu weit weg sind, ist es wahrscheinlich ein Stalaktit
	return farHits > (#validHits / 2)
end

local function trySpawnInteriorOre(cellID)
	--print(interiorFailCount)
	if not saveData.cellOreCount[cellID] then
		local area = calculateActorSurfaceArea()^0.5
		maxOres = math.ceil(area/800)
		saveData.cellOreCount[cellID] = MAX_INTERIOR_ORE-maxOres
		saveData.cellFailCount[cellID] = 0
		print(area,"m2, max",maxOres,"ores", #nearby.actors,"actors")
	end
	if not saveData.realCellOreCount[cellID] then
		saveData.realCellOreCount[cellID] = 0
	end
	
	if saveData.cellOreCount[cellID] >= MAX_INTERIOR_ORE or saveData.cellFailCount[cellID] >= MAX_INTERIOR_FAILS then
		if saveData.cellOreCount[cellID] == MAX_INTERIOR_ORE or saveData.cellFailCount[cellID] == MAX_INTERIOR_FAILS then
			print(cellID..": spawned "..saveData.realCellOreCount[cellID].." ores ("..saveData.cellFailCount[cellID].." fails)")
			saveData.cellOreCount[cellID] = MAX_INTERIOR_ORE + 1
			saveData.cellFailCount[cellID] = MAX_INTERIOR_FAILS + 1
		end
		return false
	end
	local nearbyActors = nearby.actors
	local randomActor = nearbyActors[math.random(1,#nearbyActors)]
	local randomPoint = nearby.findRandomPointAroundCircle(randomActor.position, 2000, {})
	if not randomPoint then
		saveData.cellFailCount[cellID] = saveData.cellFailCount[cellID] + 1
		return true
	end
	
	-- zufällige richtung für raycast
	local angle = math.random() * math.pi * 2
	local rayDir = util.vector3(math.cos(angle), math.sin(angle), math.random(-0.5, 0.5))
	rayDir = rayDir:normalize()
	
	local rayStart = randomPoint + util.vector3(0, 0, 100)
	local rayEnd = rayStart + rayDir * 500
	
	local res = nearby.castRay(
		rayStart,
		rayEnd,
		{ radius = 1, collisionType = nearby.COLLISION_TYPE.AnyPhysical}
	)
	
	if res.hit and isValidSurface(res.hitObject) then
		-- Prüfe Mindestabstand zu bereits gespawnten Erzen
		local minDistance = 700
		local tooClose = false
		
		for _, existingPos in ipairs(spawnedOrePositions) do
			local distance = (res.hitPos - existingPos):length()
			if distance < minDistance then
				tooClose = true
				print("2close")
				break
			end
		end
		
		if tooClose then
			saveData.cellFailCount[cellID] = saveData.cellFailCount[cellID] + 1
			--print("Ore spawn too close to existing ore, skipping")
		else
			local isStalactite = checkForStalactite(rayStart, rayEnd, rayDir, res.hitPos)
			
			if isStalactite then
				saveData.cellFailCount[cellID] = saveData.cellFailCount[cellID] + 1
				print("Detected stalactite, skipping ore spawn")
			else
				-- berechne rotation zur getroffenen oberfläche
				local up = util.vector3(0, 0, -1)
				local normal = res.hitNormal or util.vector3(0, 0, 1)
				local axis = up:cross(rayDir):normalize()
				local rotAngle = math.acos(math.max(-1, math.min(1, up:dot(rayDir))))
				rotation = util.transform.rotate(rotAngle, axis)
				
				
				local spawnOffset = -70
				local spawnPosition = res.hitPos + normal * spawnOffset
				
				
				core.sendGlobalEvent("SimplyMining_spawnOre", {
					player = self,
					position = spawnPosition,
					rotation = rotation,
					record = randomNode(saveData.lastExteriorCell and isInRedMountain(saveData.lastExteriorCell) and 7 or 0)
				})
				
				-- Speichere die Position für zukünftige Abstandsprüfungen
				table.insert(spawnedOrePositions, res.hitPos)
				
				saveData.cellOreCount[cellID] = saveData.cellOreCount[cellID] + 1
				saveData.realCellOreCount[cellID] = saveData.realCellOreCount[cellID] + 1
				--print("Spawned interior ore at:", res.hitPos, "count:", saveData.cellOreCount[cellID])
			end
		end
	else
		--print(res.hitObject)
		saveData.cellFailCount[cellID] = saveData.cellFailCount[cellID] + 1
	end
	
	return true
end


local function trySpawnOreInCell(cellID)
	if not saveData.cellOreCount[cellID] then
		saveData.cellOreCount[cellID] = 0
	end
	if not saveData.cellFailCount[cellID] then
		saveData.cellFailCount[cellID] = 0
	end
	if not saveData.realCellOreCount[cellID] then
		saveData.realCellOreCount[cellID] = 0
	end
	
	if saveData.cellOreCount[cellID] >= MIN_ORE_PER_CELL or saveData.cellFailCount[cellID] >= MAX_FAILS_PER_CELL then
		if saveData.cellOreCount[cellID] == MIN_ORE_PER_CELL or saveData.cellFailCount[cellID] == MAX_FAILS_PER_CELL then
			print(cellID..": spawned "..saveData.realCellOreCount[cellID].." ores ("..saveData.cellFailCount[cellID].." fails)")
			saveData.cellOreCount[cellID] = MAX_INTERIOR_ORE + 1
			saveData.cellFailCount[cellID] = MAX_INTERIOR_FAILS + 1
		end
		return false
	end
	
	local bounds = getCellBounds(cellID)
	local rndX = bounds.minX + math.random() * CELL_SIZE
	local rndY = bounds.minY + math.random() * CELL_SIZE
	local playerZ = self.position.z
	
	local res = nearby.castRay(
		util.vector3(rndX, rndY, playerZ + 4000),
		util.vector3(rndX, rndY, playerZ - 3000),
		{ radius = 300, collisionType = nearby.COLLISION_TYPE.AnyPhysical}
	)
	
	if res.hit and (not res.hitObject or res.hitObject.recordId:find("rock")) then
		local waterLevel = self.cell.waterLevel and self.cell.waterLevel or -9999
		if math.abs(res.hitPos.z -waterLevel) < 150 and not res.hitObject then -- check underwater too
			--print("probably underwater")
			res = nearby.castRay(
				util.vector3(rndX, rndY, playerZ + 3000),
				util.vector3(rndX, rndY, playerZ - 4000),
				{ radius = 300, collisionType = nearby.COLLISION_TYPE.HeightMap}
			)
		end
		if res.hit and (not res.hitObject or res.hitObject.recordId:find("rock") and not nodeToItemLookup[res.hitObject.recordId])  then
			first=res.hitNormal
			if res.hitPos.z < waterLevel then
				saveData.cellOreCount[cellID] = saveData.cellOreCount[cellID] + math.random(1,2)
				--print("underwater")
			end
			local rndX2 = 5+math.random()*5 -- only positive, whatever
			local rndY2 = 5+math.random()*5
				
			res = nearby.castRay(
				res.hitPos +util.vector3(rndX2,rndY2, 200),
				res.hitPos - util.vector3(rndX2,rndY2, 200),
				{ collisionType = nearby.COLLISION_TYPE.AnyPhysical}
			)
			if res.hit then
			--print(first)
			--print(res.hitNormal)
				local dotProduct = first:dot(res.hitNormal)  -- or v1 * v2
				local angle = math.acos(dotProduct)	
				if math.deg(angle) <25 then
					local defaultUp = util.vector3(0, 0, 1) -- assuming Z is up
					local angle = math.acos(defaultUp:dot(res.hitNormal:normalize()))
					local axis = defaultUp:cross(res.hitNormal:normalize()):normalize()
					
					local transformM = util.transform.rotate(angle, axis)
					core.sendGlobalEvent("SimplyMining_spawnOre", {
						player = self,
						position = res.hitPos,
						--rotation = util.transform.identity,
						rotation = transformM,
						record = randomNode(isInRedMountain(cellID) and 7 or 0)
					})
					saveData.cellOreCount[cellID] = saveData.cellOreCount[cellID] + 1
					saveData.realCellOreCount[cellID] = saveData.realCellOreCount[cellID] + 1
					--print("Spawned ore at:", res.hitPos, "in cell:", cellID, "count:", saveData.cellOreCount[cellID])
				else
					print(math.deg(angle).."*")
				end
			else
				print("ore spawn error?")
				saveData.cellFailCount[cellID] = saveData.cellFailCount[cellID] + 1
			end
		else
			saveData.cellFailCount[cellID] = saveData.cellFailCount[cellID] + 1
		end
	else
		saveData.cellFailCount[cellID] = saveData.cellFailCount[cellID] + 1
	end
	
	return true
end


table.insert(onFrameFunctions, function()
	framesInCell = framesInCell + 1
	if self.cell then
		if not playerSection:get("UNINSTALL") then
			if not lastCell then
				lastCell = self.cell
				framesInCell = 0
				if self.cell.isExterior then
					updateActiveCells()
				end
			elseif self.cell.id ~= lastCell.id then
				framesInCell = 0
				print("entering ".. self.cell.id)
				spawnedOrePositions = {}
				--print("Cell changed:", lastCell.id, "->", self.cell.id)
				if self.cell.isExterior then
					updateActiveCells()
					saveData.lastExteriorCell = self.cell.id
				end
				
				lastCell = self.cell
			end
			if self.cell.isExterior then
				-- exterior logic
				if #activeCells > 0 then
					local cellID = activeCells[currentCellIndex]
					local keepGoing = trySpawnOreInCell(cellID)
					
					if not keepGoing then
						table.remove(activeCells, currentCellIndex)
						if currentCellIndex > #activeCells then
							currentCellIndex = 1
						end
					else
						currentCellIndex = currentCellIndex + 1
						if currentCellIndex > #activeCells then
							currentCellIndex = 1
						end
					end
				end
			elseif framesInCell > 3 then
				-- interior logic
				trySpawnInteriorOre(self.cell.id)
			end
		else
			if not lastCell then
				lastCell = self.cell
			elseif self.cell.id ~= lastCell.id then
				spawnedOrePositions = {}
				--print("Cell changed:", lastCell.id, "->", self.cell.id)
				if self.cell.isExterior then
					saveData.lastExteriorCell = self.cell.id
				end
				lastCell = self.cell
			end
		end
		if self.position then
			lastPosition = {x = self.position.x, y = self.position.y, z = self.position.z}
		end
	end
end)