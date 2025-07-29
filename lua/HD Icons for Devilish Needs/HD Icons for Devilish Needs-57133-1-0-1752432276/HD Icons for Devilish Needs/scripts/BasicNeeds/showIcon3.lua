
-- File: scripts/MyShowExhaustionImage.lua
-- SPDX-License-Identifier: GPL-3.0-or-later

local ui     = require("openmw.ui")
local util   = require("openmw.util")
local self   = require("openmw.self")
local types  = require("openmw.types")
local settings = require("scripts.BasicNeeds.settings")

-- Keep track of current exhaustion state and image element
local exhaustionImageElement = nil
local currentExhaustionStatus = -1

-- Map exhaustion state to texture path
local function getExhaustionStatus()
    local spells = types.Actor.activeSpells(self)
    if spells:isSpellActive("jz_critical_exhaustion") then return 4, "icons/detd_exhaustion_starving.dds" end
    if spells:isSpellActive("jz_severe_exhaustion")   then return 3, "icons/detd_exhaustion_famished.dds" end
    if spells:isSpellActive("jz_moderate_exhaustion") then return 2, "icons/detd_exhaustion_hungry.dds" end
    if spells:isSpellActive("jz_mild_exhaustion")     then return 1, "icons/detd_exhaustion_slightly.dds" end
    return 0, "icons/detd_exhaustion_full.dds"
end

-- Create exhaustion icon image
local function createImage2(texturePath, config)
    local iconBaseX  = config.alternativeHud
    local hudOffsetX = config.hudOffsetX
    local hudOffsetY = config.hudOffsetY

    return ui.create {
        layer = "HUD",
        type  = ui.TYPE.Image,
        props = {
            resource         = ui.texture { path = texturePath, offset = util.vector2(0,0), size = util.vector2(64,64) },
            relativePosition = iconBaseX and util.vector2(1,1) or util.vector2(1,0.5),
            anchor           = iconBaseX and util.vector2(1,1) or util.vector2(1,0.5),
            position         = iconBaseX
                and util.vector2(-120 + hudOffsetX, -38 - hudOffsetY)
                or  util.vector2(-16  + hudOffsetX, 28  - hudOffsetY),
            size             = util.vector2(32,32),
        }
    }
end

-- Main function to show or update exhaustion icon
local function showExhaustionImage()
    local status, texturePath = getExhaustionStatus()
    local config = settings.getValues(settings.group)

    if status ~= currentExhaustionStatus then
        currentExhaustionStatus = status
        if exhaustionImageElement then exhaustionImageElement:destroy() end
        exhaustionImageElement = createImage2(texturePath, config)
    end

    -- always recalc position
    do
        local cfg = config
        local newPos = util.vector2(
            (cfg.alternativeHud and -120 or -16) + cfg.hudOffsetX,
            (cfg.alternativeHud and -38  or 28)  - cfg.hudOffsetY
        )
        exhaustionImageElement.layout.props.position = newPos
            -- hide the icon whenever the HUD itself is hidden:
        exhaustionImageElement.layout.props.visible = require("openmw.interfaces").UI.isHudVisible()
        exhaustionImageElement:update()
    end

    ui.updateAll()
end

return showExhaustionImage