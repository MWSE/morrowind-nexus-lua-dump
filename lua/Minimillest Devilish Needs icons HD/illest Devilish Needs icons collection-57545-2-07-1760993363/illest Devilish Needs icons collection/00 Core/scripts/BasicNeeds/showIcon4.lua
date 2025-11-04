-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/ShowIcon4.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com> (original author)
-- 2025 -- Modified by DetailDevil for Devilish Needs 
-- -----------------------------------------------------------------------------

local ui       = require("openmw.ui")
local util     = require("openmw.util")
local self     = require("openmw.self")
local types    = require("openmw.types")
local settings = require("scripts.BasicNeeds.settings")

-- Track state and image reference
local temperatureImageElement = nil
local currentTemperatureStatus = nil

-- Return status and image path
local function getTemperatureStatus()
    local spells = types.Actor.activeSpells(self)
    if spells:isSpellActive("aaj_freezing")     then return -4, "icons/temperature4.dds" end
    if spells:isSpellActive("aak_very_cold")    then return -3, "icons/temperature3.dds" end
    if spells:isSpellActive("aal_cold")         then return -2, "icons/temperature2.dds" end
    if spells:isSpellActive("aap_chilly")       then return -1, "icons/temperature1.dds" end
    if spells:isSpellActive("detd_burninghot")  then return  4, "icons/temperatureh4.dds" end
    if spells:isSpellActive("detd_veryhot")     then return  3, "icons/temperatureh3.dds" end
    if spells:isSpellActive("detd_hot")         then return  2, "icons/temperatureh2.dds" end
    if spells:isSpellActive("detd_warm")        then return  1, "icons/temperatureh1.dds" end
    return 0, "icons/temperature0.dds"
end

-- Build temperature image
local function createImage(texturePath, config)
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
                and util.vector2(-82 + hudOffsetX, -38 - hudOffsetY)
                or  util.vector2(-16 + hudOffsetX,  66 - hudOffsetY),
            size             = util.vector2(32,32),
        }
    }
end

-- Main function: updates only if temperature state changes, and always reapplies position
local function showTemperatureImage()
    local temperatureStatus, texturePath = getTemperatureStatus()
    local config = settings.getValues(settings.group)

    -- Recreate element if status changed
    if temperatureStatus ~= currentTemperatureStatus then
        currentTemperatureStatus = temperatureStatus
        print("Temperature Status:", temperatureStatus)
        print("Texture Path:", texturePath)

        if temperatureImageElement then
            temperatureImageElement:destroy()
        end
        temperatureImageElement = createImage(texturePath, config)
    end

    -- Always recalc and apply position from settings
    do
        local cfg    = config
        local newPos = util.vector2(
            (cfg.alternativeHud and -82 or -16) + cfg.hudOffsetX,
            (cfg.alternativeHud and -38 or  66) - cfg.hudOffsetY
        )
        temperatureImageElement.layout.props.position = newPos
        -- hide the icon whenever the HUD itself is hidden:
        temperatureImageElement.layout.props.visible = require("openmw.interfaces").UI.isHudVisible()
        temperatureImageElement:update()
    end

    --ui.updateAll()
end

return showTemperatureImage
