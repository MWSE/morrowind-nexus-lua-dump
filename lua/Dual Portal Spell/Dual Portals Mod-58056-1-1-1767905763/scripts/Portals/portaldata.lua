local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local world = require("openmw.world")
local async = require("openmw.async")
local constants = require("scripts.Portals.constants")
local data = {}
local followers = {}
local labelData = {}
local function trim(s) return s:match '^()%s*$' and '' or s:match '^%s*(.*%S)' end
local function formatRegion(regionString)
    -- remove the word "region"
    -- capitalize the first letter of each word
    regionString = string.gsub(regionString, "(%a)([%w_']*)", function(first,
                                                                       rest)
        return first:upper() .. rest:lower()
    end)
    -- trim any leading/trailing whitespace
    regionString = trim(regionString)
    return regionString
end
local function getCellName(cell)
    if cell.name and cell.name ~= "" then
        return cell.name
    else
        return formatRegion(cell.region)
    end
end

local function getObjectInCellById(id, cell)
    for index, value in ipairs(cell:getAll(types.Activator)) do
        if value.id == id then return value end
    end
end
local function getPairData(pairName)
    if not data[pairName] then
        data[pairName] = {
            alphaData = {portalId = nil, cellId = nil},
            betaData = {portalId = nil, cellId = nil}
        }
    end

    return data[pairName]
end
local function getAlphaPortalObj(pairName)
    local pairData = getPairData(pairName)
    if pairData.alphaData.portalId then
        local oldcell = world.getCellById(pairData.alphaData.cellId)
        local obj = getObjectInCellById(pairData.alphaData.portalId, oldcell)
        return obj
    end
end
local function getBetaPortalObj(pairName)
    local pairData = getPairData(pairName)
    if pairData.betaData.portalId then
        local oldcell = world.getCellById(pairData.betaData.cellId)
        local obj = getObjectInCellById(pairData.betaData.portalId, oldcell)
        return obj
    end
end
local function closePortal(isAlpha, pairName)

    local portalKey = isAlpha and "alphaData" or "betaData"
    if not data[pairName][portalKey] then
        return
    end
    local oppositePortalKey = isAlpha and "betaData" or "alphaData"
    local cellId = data[pairName][portalKey].cellId
    local sameCellAsPlayer = cellId == world.players[1].cell.id
    local portalObjFunc = isAlpha and getAlphaPortalObj or getBetaPortalObj
    local scalePortalFunc = isAlpha and I.Portal.scaleDownPortal1 or
                                I.Portal.scaleDownPortal2
    local obj = portalObjFunc(pairName)
    if data[pairName][portalKey].portalId then

        labelData[data[pairName][portalKey].portalId] = nil
    end
    if data[pairName][oppositePortalKey].portalId then

        labelData[data[pairName][oppositePortalKey].portalId] = nil
    end
    if sameCellAsPlayer and obj and obj.cell.id == cellId then
        labelData[obj.id] = nil
        scalePortalFunc(obj)
    elseif obj then
        labelData[obj.id] = nil
        obj:remove()
    end
    data[pairName][portalKey] = {}
    world.players[1]:sendEvent("UpdateLabelData", labelData)
end
local function createPortalInternal(pairName, cell, position, rotation, isAlpha)
    if not cell.id then cell = world.getCellById(cell) end

    local pairData = getPairData(pairName)
    local sameCellAsPlayer = cell.id == world.players[1].cell.id
    local portalKey = isAlpha and "alphaData" or "betaData"
    local oppositePortalKey = isAlpha and "betaData" or "alphaData"
    local portalObjFunc = isAlpha and getAlphaPortalObj or getBetaPortalObj
    local placePortalFunc = I.Portal.placePortalAt
    local cost = 0
    local exteriorCell, exteriorPos = I.Portal.findInteriorExterior(cell, {}, 5,
                                                                    true)
    if cell.isExterior then
        exteriorCell = cell
        exteriorPos = position
    end
    if not exteriorCell then
        -- can't find it
        cost = 100
        return
    else
        if data[pairName][oppositePortalKey] and
            data[pairName][oppositePortalKey].exteriorPos then
            local dist = (data[pairName][oppositePortalKey].exteriorPos -
                             exteriorPos):length()
            cost = dist / 2000
        end
    end
    if cost < 4 then cost = 4 end
    local playerMagicka = types.Actor.stats.dynamic.magicka(world.players[1])
                              .current
     print(cost, "cost")
    if playerMagicka > cost then
        world.players[1]:sendEvent("ReduceMagicak_Portal", cost)
    else
        world.players[1]:sendEvent("ShowMessage_Portal",
                                   constants.notEnoughMagicMessage)
        return
    end
    if pairData[portalKey].portalId then closePortal(isAlpha, pairName) end

    local newPortal = placePortalFunc(cell, position, rotation, isAlpha)
    data[pairName][portalKey].portalId = newPortal.id
    data[pairName][portalKey].cellId = cell.id
    data[pairName][portalKey].cellName = getCellName(cell)
    data[pairName][portalKey].exteriorPos = exteriorPos

    if data[pairName][oppositePortalKey].portalId then
        labelData[data[pairName][oppositePortalKey].portalId] =
            data[pairName][portalKey].cellName
        labelData[data[pairName][portalKey].portalId] =
            data[pairName][oppositePortalKey].cellName
    end

    world.players[1]:sendEvent("playPortalOpenSound")
    world.players[1]:sendEvent("UpdateLabelData", labelData)
    -- playPortalOpenSound
end
local function createBetaPortal(pairName, cell, position, rotation)
    createPortalInternal(pairName, cell, position, rotation, false)
end
local function createAlphaPortal(pairName, cell, position, rotation)
    createPortalInternal(pairName, cell, position, rotation, true)
end

local function getPositionBehind(pos, rot, distance, direction)
    local currentRotation = -rot
    local angleOffset = 0

    if direction == "north" then
        angleOffset = math.rad(90)
    elseif direction == "south" then
        angleOffset = math.rad(-90)
    elseif direction == "east" then
        angleOffset = 0
    elseif direction == "west" then
        angleOffset = math.rad(180)
    else
        error(
            "Invalid direction. Please specify 'north', 'south', 'east', or 'west'.")
    end

    currentRotation = currentRotation - angleOffset
    local obj_x_offset = distance * math.cos(currentRotation)
    local obj_y_offset = distance * math.sin(currentRotation)
    local obj_x_position = pos.x + obj_x_offset
    local obj_y_position = pos.y + obj_y_offset
    return util.vector3(obj_x_position, obj_y_position, pos.z)
end
local function teleportToPortal(portalObj)
    local newPosF = getPositionBehind(portalObj.position,
                                      portalObj.rotation:getAnglesZYX(),
                                      constants.exitDistance, "south")

    local newPos = getPositionBehind(portalObj.position,
                                     portalObj.rotation:getAnglesZYX(),
                                     constants.followerExitDistance, "south")
    for i, x in ipairs(followers) do
        x:teleport(portalObj.cell, newPosF,
                   {onGround = true, rotation = portalObj.rotation})
    end
    world.players[1]:teleport(portalObj.cell, newPos,
                              {onGround = true, rotation = portalObj.rotation})
    followers = {}
end
local function goToAlpha(pairName)
    local portalObj = getAlphaPortalObj(pairName)
    if not portalObj then return end
    world.players[1]:sendEvent("playClap")
    teleportToPortal(portalObj)
end
local function goToBeta(pairName)
    local portalObj = getBetaPortalObj(pairName)
    if not portalObj then return end
    world.players[1]:sendEvent("playClap")
    teleportToPortal(portalObj)
end
local portal
local function ActivatePortal(udata)
    portal = udata.portal
    local actors = udata.actors
    if not portal then return end
    async:newUnsavableSimulationTimer(0.05, function()
        for i, x in pairs(data) do
            if x.alphaData and x.alphaData.portalId == portal.id then
                goToBeta(i)
                return
            end
            if x.betaData and x.betaData.portalId == portal.id then
                goToAlpha(i)
                return
            end
        end
    end)
end
local function createRotation(x, y, z)
    local rotate = util.transform.rotateZ(z)
    local rotatex = util.transform.rotateX(x)
    local rotatey = util.transform.rotateY(y)
    rotate = rotate:__mul(rotatex)
    rotate = rotate:__mul(rotatey)
    return rotate
end
local activeSet = constants.defaultSet
local function summonPortal(alpha)
    local player = world.players[1]
    local rotation = createRotation(0, 0, player.rotation:getAnglesZYX() -
                                        math.rad(180))
    local newPos = getPositionBehind(player.position,
                                     player.rotation:getAnglesZYX(),
                                     constants.placeDistance, "south")
    if alpha then
        createAlphaPortal(activeSet, player.cell, newPos, rotation)
    else
        createBetaPortal(activeSet, player.cell, newPos, rotation)
    end
end
local function openPair(data1, data2, id)
    createAlphaPortal(id, data1.cellId, data1.position, data1.rotation)
    createBetaPortal(id, data2.cellId, data2.position, data2.rotation)
end
local function closePortals()
    if getAlphaPortalObj(activeSet) or getBetaPortalObj(activeSet) then

        closePortal(false, activeSet)
        closePortal(true, activeSet)
        world.players[1]:sendEvent("playPortalCloseSound")
    else
        world.players[1]:sendEvent("ShowMessage_Portal",
                                   constants.noOpenPortalsMessage)
    end

end
return {
    interfaceName = "PortalData",
    interface = {
        createAlphaPortal = createAlphaPortal,
        createBetaPortal = createBetaPortal,
        getAlphaPortalObj = getAlphaPortalObj,
        openPair = openPair,
        goToAlpha = goToAlpha,
        setActiveSet = function(d) activeSet = d end,
        goToBeta = goToBeta
    },
    eventHandlers = {
        portaladdFollower = function(act) table.insert(followers, act) end,
        ActivatePortal = ActivatePortal,
        summonPortal = summonPortal,
        closePortals = closePortals
    },
    engineHandlers = {
        onSave = function() return {data = data, labelData = labelData} end,
        onLoad = function(fdata)
            if fdata then
                data = fdata.data
                labelData = fdata.labelData or {}
            end
        end
    }
}
