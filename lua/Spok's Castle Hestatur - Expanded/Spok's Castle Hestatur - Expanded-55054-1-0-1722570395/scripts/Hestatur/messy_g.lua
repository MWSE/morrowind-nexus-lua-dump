local world = require("openmw.world")
local types = require("openmw.types")
local core = require("openmw.core")
local util = require("openmw.util")
local blockManniq = true
local function isHestatur(id)
    if id:find("hestatur" ) then
        return true
    end
    return false
end
local processedCells = {}
local data = {
    ["furn_com_r_chair_01"] = {
        x = 89.2,
        zPos = -15
    }
}

local function createRotation(x, y, z)
    if (core.API_REVISION < 40) then
        return util.vector3(x, y, z)
    else
        local rotate = util.transform.rotateZ(z)
        local rotatex = util.transform.rotateX(x)
        local rotatey = util.transform.rotateY(y)
        rotate = rotate:__mul(rotatex)
        rotate = rotate:__mul(rotatey)
        return rotate
    end
end

local function makeObjMessy(obj)
    if data[obj.recordId] then
        local z,y,x = obj.rotation:getAnglesZYX()
        x =  math.rad(data[obj.recordId].x)
        local pos = obj.position + util.vector3(0,0,data[obj.recordId].zPos)
        local rot = createRotation(x,y,z)
        obj:teleport(obj.cell,pos,rot)
    end
end
local function onObjectActive(obj)
    if not isHestatur(obj.cell.id) or  processedCells[obj.cell.id] then
        return
    end
    for index, value in ipairs(obj.cell:getAll()) do
        makeObjMessy(value)
    end
    processedCells[obj.cell.id] = true
end
local function onActorActive(obj)

end
return {
    engineHandlers = {
        onObjectActive = onObjectActive,
        onActorActive = onActorActive,
        onSave = function ()
            return {processedCells = processedCells}
        end,
        onLoad = function (data)
            if data then
                processedCells = data.processedCells
            end
        end
    }
}
