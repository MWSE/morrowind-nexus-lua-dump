local playerRef = require("openmw.self")
local util = require("openmw.util")
local ui = require("openmw.ui")

local commonData = require("scripts.advanced_world_map.common")

local this = {}

this.textures = {}

for i = 0, 72 do
    this.textures[i] = ui.texture{ path = commonData.playerMarkerDir..tostring(i)..".png" }
end


---@param angleOffset number?
function this.getTexture(angleOffset, yaw)
    yaw  = yaw or playerRef.rotation:getYaw()

    local offset = angleOffset or 0
    local angle = util.normalizeAngle(yaw - offset - math.pi * 1 / 144)
    local index = (util.round((angle / (2 * math.pi)) * 72) + 72) % 72

    return this.textures[index] or this.textures[0]
end


return this