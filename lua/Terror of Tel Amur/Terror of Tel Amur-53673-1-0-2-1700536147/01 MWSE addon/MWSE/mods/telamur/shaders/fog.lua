local this = {}

---@type mgeShaderHandle|nil
local shader

local NUM_FOG_VOLUMES = 2

local fogVolumes = {
    fogCenters = {
        0, 0, 0,
        0, 0, 0,
    },
    fogRadi = {
        0, 0, 0,
        0, 0, 0,
    },
    fogColors = {
        0, 0, 0,
        0, 0, 0,
    },
    fogDensities = {
        0,
        0,
    },
}

--- Associates each active fog volume to a specific available index.
---@type table<string, number>
local activeFogVolumes = {}

---@class fogParams
---@field color tes3vector3
---@field center tes3vector3
---@field radius tes3vector3
---@field density number


---@return number|nil
local function getNextAvailableIndex()
    for i = 1, NUM_FOG_VOLUMES do
        if not table.find(activeFogVolumes, i) then
            return i
        end
    end
end


---@param id string
---@return number|nil
local function getFogVolumeIndex(id)
    local index = activeFogVolumes[id]
    return index or getNextAvailableIndex()
end


---@param i number
---@param params fogParams
local function setParamsForIndex(i, params)
    local x = (i * 3) - 2
    local y = x + 1
    local z = y + 1

    fogVolumes.fogCenters[x] = params.center.x
    fogVolumes.fogCenters[y] = params.center.y
    fogVolumes.fogCenters[z] = params.center.z

    fogVolumes.fogRadi[x] = params.radius.x
    fogVolumes.fogRadi[y] = params.radius.y
    fogVolumes.fogRadi[z] = params.radius.z

    fogVolumes.fogColors[x] = params.color.x
    fogVolumes.fogColors[y] = params.color.y
    fogVolumes.fogColors[z] = params.color.z

    fogVolumes.fogDensities[i] = params.density
end


local function applyShaderParams()
    shader = mge.shaders.load({ name = "ta_fog_box" })
    if shader then
        shader.fogColors = fogVolumes.fogColors
        shader.fogCenters = fogVolumes.fogCenters
        shader.fogRadi = fogVolumes.fogRadi
        shader.fogDensities = fogVolumes.fogDensities
    end
end


---@param id string
---@param params fogParams
function this.createOrUpdateFog(id, params)
    local index = getFogVolumeIndex(id)
    if index then
        setParamsForIndex(index, params)
        applyShaderParams()
        activeFogVolumes[id] = index
        shader.enabled = true
    end
end


---@param id string
function this.deleteFog(id)
    local index = getFogVolumeIndex(id)
    if index then
        setParamsForIndex(index, {
            color = tes3vector3.new(),
            center = tes3vector3.new(),
            radius = tes3vector3.new(),
            density = 0,
        })
        applyShaderParams()
        activeFogVolumes[id] = nil
        if not next(activeFogVolumes) then
            shader.enabled = false
        end
    end
end


return this
