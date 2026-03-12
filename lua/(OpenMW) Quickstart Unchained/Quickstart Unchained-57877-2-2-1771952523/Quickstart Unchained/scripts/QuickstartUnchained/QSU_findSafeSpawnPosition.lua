local function computeConvexHull(points)
	if #points < 3 then return nil end
	
	table.sort(points, function(a, b)
		return a.x < b.x or (a.x == b.x and a.y < b.y)
	end)
	
	local function cross(o, a, b)
		return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
	end
	
	local lower = {}
	for i = 1, #points do
		while #lower >= 2 and cross(lower[#lower - 1], lower[#lower], points[i]) <= 0 do
			table.remove(lower)
		end
		table.insert(lower, points[i])
	end
	
	local upper = {}
	for i = #points, 1, -1 do
		while #upper >= 2 and cross(upper[#upper - 1], upper[#upper], points[i]) <= 0 do
			table.remove(upper)
		end
		table.insert(upper, points[i])
	end
	
	table.remove(lower)
	table.remove(upper)
	for _, p in ipairs(upper) do
		table.insert(lower, p)
	end
	
	return lower
end

local function pointInConvexHull(point, hull)
	if not hull or #hull < 3 then return true end
	
	for i = 1, #hull do
		local p1 = hull[i]
		local p2 = hull[i % #hull + 1]
		local cross = (p2.x - p1.x) * (point.y - p1.y) - (p2.y - p1.y) * (point.x - p1.x)
		if cross < 0 then
			return false
		end
	end
	return true
end

local function expandHull(hull, margin)
	if not hull or #hull < 3 then return hull end
	
	local cx, cy = 0, 0
	for _, p in ipairs(hull) do
		cx = cx + p.x
		cy = cy + p.y
	end
	cx = cx / #hull
	cy = cy / #hull
	
	local expanded = {}
	for _, p in ipairs(hull) do
		local dx = p.x - cx
		local dy = p.y - cy
		local len = math.sqrt(dx * dx + dy * dy)
		if len > 0 then
			table.insert(expanded, {
				x = p.x + dx / len * margin,
				y = p.y + dy / len * margin,
			})
		else
			table.insert(expanded, {x = p.x, y = p.y})
		end
	end
	return expanded
end


--findSafeSpawnPosition( npc, baseDistance)
return function (npc, baseDistance)
	local cell = npc.cell
	local npcYaw = npc.rotation:getYaw()
	local npcPos = npc.position
	local playerHalfExtents = util.vector3(20, 20, 64)
	
	local obstacles = {}
	for _, objType in ipairs({types.Static, types.Activator, types.Container, types.Door}) do
		for _, obj in pairs(cell:getAll(objType)) do
			local dist = (obj.position - npcPos):length()
			if dist < baseDistance + 100 then
				local bbox = obj:getBoundingBox()
				if math.min(bbox.halfSize.x, bbox.halfSize.y) < 220 then
					table.insert(obstacles, {
						min = bbox.center - bbox.halfSize,
						max = bbox.center + bbox.halfSize,
					})
				end
			end
		end
	end
	
	local guestPositions2D = {}
	for _, otherNpc in pairs(cell:getAll(types.NPC)) do
		if math.abs(otherNpc.position.z - npcPos.z) < 50 then
			table.insert(guestPositions2D, {x = otherNpc.position.x, y = otherNpc.position.y})
			if otherNpc ~= npc then
				local npcHalfSize = util.vector3(30, 30, 64)
				table.insert(obstacles, {
					min = otherNpc.position - npcHalfSize,
					max = otherNpc.position + npcHalfSize,
				})
			end
		end
	end
	
	local pubNpcHalfSize = util.vector3(50, 50, 64)
	table.insert(obstacles, {
		min = npcPos - pubNpcHalfSize,
		max = npcPos + pubNpcHalfSize,
	})
	
	local validArea = expandHull(computeConvexHull(guestPositions2D), 50)
	
	local guestDirection = nil
	if #guestPositions2D > 1 then
		local avgX, avgY = 0, 0
		for _, pos in ipairs(guestPositions2D) do
			avgX = avgX + pos.x
			avgY = avgY + pos.y
		end
		avgX = avgX / #guestPositions2D
		avgY = avgY / #guestPositions2D
		guestDirection = math.atan2(avgX - npcPos.x, avgY - npcPos.y)
	end
	
	local angles
	if guestDirection then
		local relAngle = guestDirection - npcYaw
		angles = {relAngle, 0, math.pi, math.pi/2, -math.pi/2, math.pi/4, -math.pi/4, 3*math.pi/4, -3*math.pi/4}
	else
		angles = {0, math.pi, math.pi/2, -math.pi/2, math.pi/4, -math.pi/4, 3*math.pi/4, -3*math.pi/4}
	end
	
	for _, angleOffset in ipairs(angles) do
		local testYaw = npcYaw + angleOffset
		local facingDir = util.vector3(math.sin(testYaw), math.cos(testYaw), 0)
		local rightDir = util.vector3(math.cos(testYaw), -math.sin(testYaw), 0)
		
		for dist = baseDistance, baseDistance + 100, 20 do
			for lateralOffset = 0, 80, 20 do
				for _, side in ipairs({0, 1, -1}) do
					local offset = facingDir * dist + rightDir * (lateralOffset * side)
					local testPos = npcPos + offset
					
					if pointInConvexHull({x = testPos.x, y = testPos.y}, validArea) then
						local playerMin = testPos - playerHalfExtents
						local playerMax = testPos + playerHalfExtents
						
						local clear = true
						for _, obs in ipairs(obstacles) do
							if playerMax.x > obs.min.x and playerMin.x < obs.max.x and
							   playerMax.y > obs.min.y and playerMin.y < obs.max.y and
							   playerMax.z > obs.min.z and playerMin.z < obs.max.z then
								clear = false
								break
							end
						end
						
						if clear then
							local toNpc = npcPos - testPos
							local faceNpcYaw = math.atan2(toNpc.x, toNpc.y)
							return testPos, faceNpcYaw
						end
					end
				end
			end
		end
	end
	
	return nil, nil
end
