local dataHandler = require("scripts.advanced_world_map.mapDataHandler")
local tableLib = require("scripts.advanced_world_map.utils.table")

local maxDepth = 10

local this = {}


---@return any[]?
function this.findExitPoss(cellId, checked, res, depth)
    if not dataHandler.isInitialized() then return end

    if not checked then checked = {} end
    if not res then res = {} end
    if not depth then depth = 1 end

    ---@type table<string, AdvancedWorldMap.DataHandler.EntranceData>
    local doors = dataHandler.entrances[cellId]

    if (checked[cellId] and checked[cellId] < depth) or depth > maxDepth then
        return
    end
    checked[cellId] = math.min(checked[cellId] or depth, depth)

    for _, door in pairs(doors) do
        if checked[door.dCId] and checked[door.dCId] < depth + 1 then goto continue end

        if door.isDEx then
            res[door] = depth
        else
            this.findExitPoss(door.dCId, checked, res, depth + 1)
        end

        ::continue::
    end

    if depth == 1 then
        local minDepth = math.huge
        for _, d in pairs(res) do
            if d < minDepth then minDepth = d end
        end

        if minDepth == math.huge then return nil end

        local r = {}
        for door, d in pairs(res) do
            if d == minDepth then
                table.insert(r, door.dPos)
            end
        end

        return r
    end

    return nil
end


return this