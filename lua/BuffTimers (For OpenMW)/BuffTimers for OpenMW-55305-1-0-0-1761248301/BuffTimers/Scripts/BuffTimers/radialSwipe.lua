-- Consider making myAtlas user configurable
local ui = require('openmw.ui')
local vector2 = require('openmw.util').vector2
local util = require('openmw.util')
local shader = {}
local modInfo = require("Scripts.BuffTimers.modInfo")
local storage = require("openmw.storage")
local userInterfaceSettings = storage.playerSection("SettingsPlayer" .. modInfo.name .. "UI")
local swipeOpt = userInterfaceSettings:get("radialSwipe")


shader.radialWipe = function(fx)
    if not fx then return end
    if not fx.duration or fx.durationLeft <= 0 then return end
    local myAtlas = (swipeOpt == "Unshade") and 'textures/radial/partial.png' or 'textures/radial/partial_invert.png' -- a 4096x4096 atlas
    local offset = 204 -- each square is 204 x 204
    local durL = fx.durationLeft
    local dur = fx.duration
    local maxDegree = 360
    local position = math.floor(maxDegree - ((durL / dur) * maxDegree)) -- determine the corresponding tile from thr 360 tiles
    local col = position % 20 -- Determine remainder to get x tile position; the tile images is 20 x 20
    local colOffset = col * offset -- multiply by tile width
    local row = math.floor(position/20) -- determine which row we're in on atlas map
    local rowOffset = row * offset -- multiply row by height of tile
    local texture1 = ui.texture { -- texture in the top left corner of the atlas
        path = myAtlas,
        offset = vector2(0, 0),
        size = vector2(0, 0),
    }
    local texture2 = ui.texture { -- texture in the top right corner of the atlas
        path = myAtlas,
        offset = vector2(colOffset, rowOffset),
        size = vector2(204, 204), --This needs to be the size of the resource
    }
	return texture2
end

shader.Overlay = function(atlasMap,iconSize)
    if not atlasMap then return {} end
    local radialSwipeOverlay = {
        name = "RadialSwipe",
        type = ui.TYPE.Image,
        props = {
            size = vector2(iconSize, iconSize),
            visible = true,
            alpha = 1,
            inheritAlpha = false,
            resource = atlasMap,
            color = util.color.rgb(25/255,25/255,25/255),
            },
        events = {
        },
    }
    return radialSwipeOverlay
end

return shader