local core = require("openmw.core")
local async = require('openmw.async')
local storage = require('openmw.storage')
local util = require("openmw.util")
local nearby = require("openmw.nearby")
local I = require("openmw.interfaces")

local config = require("scripts.morrowind_world_randomizer.config.local")

-- config.loadPlayerSettings(storage.playerSection(config.storageName.."_0"):asTable())
-- config.loadPlayerSettings(storage.playerSection(config.storageName.."_1"):asTable())
-- config.loadPlayerSettings(storage.playerSection(config.storageName.."_2"):asTable())
-- core.sendGlobalEvent("mwr_loadLocalConfigData", config.data)

---@class mwr.lowestInCircle.attributes
---@field pos any
---@field radius number
---@field offset number
---@field callbackName string

local pointOnCircleSin = {}
local pointOnCircleCos = {}
for i = 1, 8 do
    pointOnCircleSin[i] = math.sin((math.pi / 4) * i)
    pointOnCircleCos[i] = math.cos((math.pi / 4) * i)
end

local function getGroundZ(vector)
    local res = nearby.castRay(vector, util.vector3(vector.x, vector.y, 0), {collisionType = nearby.COLLISION_TYPE.HeightMap}).hitPos
    return res
end

local function getMinGroundPosInCircle(vector, radius, offset)
    local minZ = math.huge
    for i = 1, 8 do
        local posVector = util.vector3(vector.x + radius * pointOnCircleCos[i], vector.y + radius * pointOnCircleSin[i], vector.z)
        local z = getGroundZ(posVector)
        if z ~= nil then
            minZ = math.min(minZ, z.z)
        end
    end
    local z = getGroundZ(vector)
    if z ~= nil then
        minZ = math.min(minZ, z.z)
    end
    if minZ ~= math.huge then
        return util.vector3(vector.x, vector.y, minZ + offset)
    end
    return nil
end

---@param params mwr.lowestInCircle.attributes
local function lowestInCircle(params)
    local res = getMinGroundPosInCircle(params.pos, params.radius, params.offset)
    if res then
        core.sendGlobalEvent(params.callbackName, {res = res, params = params})
    end
end

local function mwrbd_updateSettings(data)
    local configData = data.configData
    if not configData then return end
    config.data = configData
    local function filStorage(storageSection)
        for name, val in pairs(storageSection:asTable()) do
            local confVal = config.getValueByString(name)
            if confVal ~= nil and confVal ~= val then
                storageSection:set(name, confVal)
            end
        end
    end
    filStorage(storage.playerSection(config.storageName.."_0"))
    filStorage(storage.playerSection(config.storageName.."_1"))
    filStorage(storage.playerSection(config.storageName.."_2"))
    filStorage(storage.playerSection(config.storageName.."_3"))
    filStorage(storage.playerSection(config.storageName.."_4"))
    filStorage(storage.playerSection(config.storageName.."_5"))
    filStorage(storage.playerSection(config.storageName.."_6"))
    require("scripts.morrowind_world_randomizer.settings")
end

local function mwrbd_updateProfiles(data)
    local storageName = config.storageName.."_profiles"
    I.Settings.updateRendererArgument(storageName, "profileSelector", {profiles = data.profileNames, protected = data.protectedNames, maxHeight = 5,})
end

return {
    eventHandlers = {
        mwr_lowestPosInCircle = async:callback(lowestInCircle),
        mwrbd_updateSettings = async:callback(mwrbd_updateSettings),
        mwrbd_updateProfiles = async:callback(mwrbd_updateProfiles),
    },
}