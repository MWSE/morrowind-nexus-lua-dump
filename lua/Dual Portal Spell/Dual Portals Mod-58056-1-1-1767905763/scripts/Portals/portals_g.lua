local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local world = require("openmw.world")
local async = require("openmw.async")
local constants = require("scripts.Portals.constants")

local portalActivatorId
local portalActivatorIdBlue

local function getPortalRecord(alpha)
    if not alpha then
        if portalActivatorIdBlue and types.Activator.records[portalActivatorIdBlue] then
            return types.Activator.records[portalActivatorIdBlue]
        end
        local newRecordDraft = types.Activator.createRecordDraft {
            -- model = "meshes/oaab/e/portal_fire.nif"
            model = "meshes/portal_fire_blue.nif"
        }
        local newRecord = world.createRecord(newRecordDraft)
        portalActivatorIdBlue = newRecord.id
        return newRecord
    end
    if portalActivatorId and types.Activator.records[portalActivatorId] then
        return types.Activator.records[portalActivatorId]
    end
    local newRecordDraft = types.Activator.createRecordDraft {
        model = "meshes/oaab/e/portal_fire.nif"
    }
    local newRecord = world.createRecord(newRecordDraft)
    portalActivatorId = newRecord.id
    return newRecord
end
local placePortal
local shrinkPortal1
local shrinkPortal2
local function scaleUpPortal(portal)
    if portal then
        placePortal = portal
    end
    if placePortal and placePortal.scale < constants.baseScale then
        placePortal:setScale(placePortal.scale + constants.scaleMultiplier)
        async:newUnsavableSimulationTimer(constants.scaleDelay, scaleUpPortal)
    elseif placePortal then
        placePortal:setScale(constants.baseScale)
        placePortal = nil
    end
end
local function scaleDownPortal1(portal)
    if portal then
        shrinkPortal1 = portal
    end
    if shrinkPortal1 and shrinkPortal1.scale > constants.scaleMultiplier then
        shrinkPortal1:setScale(shrinkPortal1.scale - constants.scaleMultiplier)
        async:newUnsavableSimulationTimer(constants.scaleDelay, scaleDownPortal1)
    elseif shrinkPortal1 then
        shrinkPortal1:remove()
        shrinkPortal1 = nil
    end
end
local function scaleDownPortal2(portal)
    if portal then
        shrinkPortal2 = portal
    end
    if shrinkPortal2 and shrinkPortal2.scale > constants.scaleMultiplier then
        shrinkPortal2:setScale(shrinkPortal2.scale - constants.scaleMultiplier)
        async:newUnsavableSimulationTimer(constants.scaleDelay, scaleDownPortal2)
    elseif shrinkPortal2 then
        shrinkPortal2:remove()
        shrinkPortal2 = nil
    end
end
local function placePortalAt(cell, pos, rotation, alpha)
    local newPortal = world.createObject(getPortalRecord(alpha).id)
    local halfSize = constants.heightOffset
    newPortal:addScript("scripts/portals/portals_a.lua")
    local bb = newPortal:getBoundingBox()
    print(bb.halfSize.z)
    local newPos = util.vector3(pos.x, pos.y, pos.z + (((halfSize / 2) * constants.baseScale) ))
    newPortal:teleport(cell, newPos, rotation)
    newPortal:setScale(0)
    placePortal = newPortal
    async:newUnsavableSimulationTimer(0.1, scaleUpPortal)
    return newPortal
end
local function findInteriorExterior(cell, visited, depth, top)
    if cell.isExterior then
        return cell, nil
    end

    visited = visited or {}
    local maxDepth = depth or math.huge
    local queue = {{cell = cell, depth = 0}}
    visited[cell.id] = true
    local head = 1

    while queue[head] do
        local node = queue[head]
        head = head + 1

        if node.depth < maxDepth then
            local objList = node.cell:getAll(types.Door)
            for i, x in ipairs(objList) do
                if types.Door.isTeleport(x) then
                    local destCell = types.Door.destCell(x)
                    local destPos = types.Door.destPosition(x)

                    if destCell and destCell.isExterior then
                        return destCell, destPos
                    end

                    if destCell and destCell.id and not visited[destCell.id] then
                        visited[destCell.id] = true
                        queue[#queue + 1] = {
                            cell = destCell,
                            depth = node.depth + 1
                        }
                    end
                end
            end
        end
    end

    return nil, nil
end



return {
    interfaceName = "Portal",
    interface = {
        getPortalRecord = getPortalRecord,
        placePortalAt = placePortalAt,
        scaleDownPortal1 = scaleDownPortal1,
        scaleDownPortal2 = scaleDownPortal2,
        scaleUpPortal = scaleUpPortal,
        findInteriorExterior = findInteriorExterior,
    },
    eventHandlers = {
        placePortalAt = function(data)
            placePortalAt(data.cell, data.pos)
        end
    },
    engineHandlers = {
        onSave = function()
            return { portalActivatorId = portalActivatorId, portalActivatorIdBlue = portalActivatorIdBlue }
        end,
        onLoad = function(data)
            if data then
                portalActivatorId = data.portalActivatorId
                portalActivatorIdBlue = data.portalActivatorIdBlue
            end
        end
    }
}
