local this = {}

this.i18n = mwse.loadTranslations("TamrielData")

this.gh_config = include("graphicHerbalism.config")

---@param cell tes3cell
---@param cellVisitTable table<tes3cell, boolean>|nil
---@return tes3cell?
function this.getExteriorCell(cell, cellVisitTable)
	if cell.isOrBehavesAsExterior then
		return cell
	end

	-- A hashset of cells that have already been checked, to prevent infinite loops and redundant checks.
	cellVisitTable = cellVisitTable or {}
	if (cellVisitTable[cell]) then
		return
	end
	cellVisitTable[cell] = true

	for ref in cell:iterateReferences(tes3.objectType.door) do
		if ref.destination and ref.destination.cell then
			local linkedExterior = this.getExteriorCell(ref.destination.cell, cellVisitTable)
			if linkedExterior then
				return linkedExterior
			end
		end
	end
end

function this.initQueue()
    local q = {}

    q.stack = {}

    function q:push(e)
        table.insert(self.stack, e)
    end

    function q:pull()
        local e = self.stack[1]
        table.remove(self.stack, 1)
        return e
    end

    function q:count()
        return #self.stack
    end

    return q
end

-- This function is currently designed around distances for path grid nodes and deviates from how a priority queue would normally be set up; that should probably be changed if something else ever needs it.
function this.initPriorityQueue()
    local pq = {}

    pq.stack = {}
    pq.allNodes = {}

    function pq:push(e)
        table.insert(self.stack, e)
        table.insert(self.allNodes, e)
    end

    function pq:pull()
        local minDistance = math.huge
        local index = 1

        for i = 1, #self.stack, 1 do
            if self.stack[i][2] < minDistance then
                minDistance = self.stack[i][2]
                index = i
            end
        end

        local e = self.stack[index]
        table.remove(self.stack, index)

        return e
    end

    function pq:count()
        return #self.stack
    end

    return pq
end

---@param ref tes3reference
---@return tes3pathGridNode
function this.getClosestNode(ref)
    local distance = 0
    local bestDistance = math.huge
    local initialNode

    for _,node in pairs(ref.cell.pathGrid.nodes) do
        distance = ref.position:distance(node.position)

        if distance < bestDistance then
            bestDistance = distance
            initialNode = node
        end
    end

    return initialNode
end

---@param ref tes3reference
---@param maxDistance number|nil
---@return tes3pathGridNode[]
function this.getClosestNodes(ref, maxDistance)
    local distance = 0
    local firstDistance = math.huge
    local secondDistance = math.huge
    local thirdDistance = math.huge
    local closestNodes = { }

    for _,node in pairs(ref.cell.pathGrid.nodes) do
        distance = ref.position:distance(node.position)

        if not maxDistance or distance <= maxDistance then
            if distance < firstDistance then
                thirdDistance = secondDistance
                secondDistance = firstDistance
                firstDistance = distance
                closestNodes[3] = closestNodes[2]
                closestNodes[2] = closestNodes[1]
                closestNodes[1] = node
            elseif distance < secondDistance then
                thirdDistance = secondDistance
                secondDistance = distance
                closestNodes[3] = closestNodes[2]
                closestNodes[2] = node
            elseif distance < thirdDistance then
                thirdDistance = distance
                closestNodes[3] = node
            end
        end
    end

    return closestNodes
end

-- Finds the shortest path by the number of nodes between two given nodes of a path grid using a BFS.
---@param firstNode tes3pathGridNode
---@param finalNode tes3pathGridNode
---@return tes3pathGridNode[]|boolean
function this.pathGridBFS(firstNode, finalNode)
    local visited = {}
    local queue = this.initQueue()
	
    queue:push({firstNode})
    table.insert(visited, firstNode)

    while queue:count() > 0 do
        local path = queue:pull()
        local node = path[#path]

        if node == finalNode then return path end

        for _,connectedNode in pairs(node.connectedNodes) do
            if not table.contains(visited, connectedNode) then
                table.insert(visited, connectedNode)

                if connectedNode.connectedNodes then
                    local new = table.copy(path)

                    table.insert(new, connectedNode)
                    queue:push(new)
                end
            end
        end
    end

    return false
end

-- Finds the shortest path by distance between two given nodes of a path grid using a particularly unpleasant implementation of Dijkstra's algorithm. While the function's structure might look similar to that of pathGridBFS, the implementation is quite different.
---@param firstNode tes3pathGridNode
---@param finalNode tes3pathGridNode
---@return tes3pathGridNode[]|boolean
function this.pathGridDijkstra(firstNode, finalNode)
    local queue = this.initPriorityQueue()
    for _,node in pairs(firstNode.grid.nodes) do
        if node == firstNode then queue:push({ node, 0, nil })
        else queue:push({ node, math.huge, nil }) end
    end

    while queue:count() > 0 do
        local currentNode = queue:pull()

        if currentNode[1] == finalNode then 
            local path = {}

            repeat
                table.insert(path, 1, currentNode[1])
                for _,queueNode in pairs(queue.allNodes) do    -- This is an inefficient setup, but something like it has to exist, right?
                    if queueNode[1] == currentNode[3] then
                        currentNode = queueNode
                        break
                    end
                end
            until not currentNode[3]

            table.insert(path, 1, currentNode[1])   -- Adds the first node to the path

            return path
        end

        for _,connectedNode in pairs(currentNode[1].connectedNodes) do
            local alternate = currentNode[2] + currentNode[1].position:distance(connectedNode.position)
            for _,queueNode in pairs(queue.stack) do    -- This is also an inefficient setup
                if queueNode[1] == connectedNode then
                    if alternate < queueNode[2] then
                        queueNode[2] = alternate
                        queueNode[3] = currentNode[1]
                    end
                end
            end
        end
    end

    return false
end

---@param hue number
---@param saturation number
---@param value number
---@return niColor
function this.hsvToRGB(hue, saturation, value)
    local chroma = saturation * value
    local minimum = value - chroma

    local x = chroma * (1 - math.abs((hue / 60) % 2 - 1))

    if hue < 60 then
        return niColor.new(chroma + minimum, x + minimum, minimum)
    elseif hue < 120 then
        return niColor.new(x + minimum, chroma + minimum, minimum)
    elseif hue < 180 then
        return niColor.new(minimum, chroma + minimum, x + minimum)
    elseif hue < 240 then
        return niColor.new(minimum, x + minimum, chroma + minimum)
    elseif hue < 300 then
        return niColor.new(x + minimum, minimum, chroma + minimum)
    else
        return niColor.new(chroma + minimum, minimum, x + minimum)
    end
end

---@param node niNode
---@param clip boolean
---@param blend boolean
---@return boolean|nil
function this.hasAlpha(node, clip, blend)
    clip = clip or true
    blend = blend or true
    
	for _,child in pairs(node.children) do
		if child then
			if child.alphaProperty then
                if clip and blend then
                    return true
                elseif not clip and (child.alphaProperty.propertyFlags % 2) ~= 0 then
					return true
                elseif not blend and (child.alphaProperty.propertyFlags % 2) == 0 then
                    return true
                end
			end
	
			if child.children then
                local childHasAlpha = this.hasAlpha(child, clip, blend)
				if childHasAlpha then
                    return childHasAlpha
                end
			end
		end
	end

    return false
end

return this