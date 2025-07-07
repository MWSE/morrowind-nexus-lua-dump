--[[
ErnBurglary for OpenMW.
Copyright (C) 2025 Erin Pentecost

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]] local interfaces = require("openmw.interfaces")
local types = require("openmw.types")
local settings = require("scripts.ErnBurglary.settings")
local self = require("openmw.self")
local core = require("openmw.core")
local localization = core.l10n(settings.MOD_NAME)
local async = require("openmw.async")
local ui = require('openmw.ui')
local util = require('openmw.util')
local aux_util = require('openmw_aux.util')

-- blind is an open eye, night eye is an open eye in partial shadow

-- vanilla blind icon = s\tx_s_blind.tga
-- bigicons blind icon = Icons/s/B_Tx_S_Blind.dds
-- bigicons blind icon = Icons/s/Tx_S_Blind.dds

-- vanilla nighteye icon = s\Tx_S_nighteye.tga
-- bigicons nighteye icon = Icons/s/B_Tx_S_night_eye.dds
-- bigicons nighteye icon = Icons/s/B_Tx_S_nighteye.dds
-- bigicons nighteye icon = Icons/s/Tx_S_night_eye.dds
-- bigicons nighteye icon = Icons/s/Tx_S_nighteye.dds

-- pendingMessage exists so we don't spam a bunch of messages in a row.
-- instead, only show the latest one.
local pendingMessage = nil

local function queueMessage(fmt, args)
    pendingMessage = {
        fmt = fmt,
        args = args,
        delay = 0.3
    }
end

local sneaking = false
local spotted = false

local spottedIcon = nil

local function makeIcon(path)
    local iconSettings = settings.icon()
    settings.debugPrint("icon settings: "..aux_util.deepToString(iconSettings, 3))
    local size = iconSettings["iconSize"]
    -- (0,0) is top left of screen.

    -- default anchor is top-left. 1,0 is top right.
    return ui.create {
        layer = "HUD",
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture {
                path = path,
            },
            position = util.vector2(iconSettings["iconOffsetX"] + 202, iconSettings["iconOffsetY"] - 20),
            relativePosition = util.vector2(0, 1),
            size             = util.vector2(size,size),
            anchor = util.vector2(0, 1),
            color = util.color.hex("f8a102"),

            visible = false,
        },
        size             = util.vector2(size,size),
    }
end

local function drawSpottedIcon()
    if spottedIcon == nil then
        local iconPath = core.magic.effects.records[core.magic.EFFECT_TYPE.Blind].icon
        --local iconPath = core.stats.Skill.records["sneak"].icon
        settings.debugPrint("iconpath: "..iconPath)
        spottedIcon = makeIcon(iconPath)
    end
    if sneaking and spotted and settings.icon()["showIcon"] and interfaces.UI.isHudVisible() then
        settings.debugPrint("Spotted Icon: revealing")
        spottedIcon.layout.props.visible = true
        spottedIcon:update()
        ui.updateAll()
    else
        settings.debugPrint("Spotted Icon: hiding")
        spottedIcon.layout.props.visible = false
        spottedIcon:update()
        ui.updateAll()
    end
end

local function resetIcon()
    if spottedIcon then
        spottedIcon:destroy()
        spottedIcon = nil
    end
    drawSpottedIcon()
end

settings.onUISettingsChange(resetIcon)

local function onSneakChange(sneakStatus)
    sneaking = sneakStatus
    if (settings.quietMode() ~= true) and sneaking and spotted then
        queueMessage(localization("showWarningMessage", {}))
    end

    drawSpottedIcon()
end

local function alertsOnSpottedChange(data)
    if data.spotted == false then
        spotted = false
        for _, spell in pairs(types.Actor.activeSpells(self)) do
            if spell.id == "ernburglary_spotted" then
                types.Actor.activeSpells(self):remove(spell.activeSpellId)
            end
        end

        -- this will execute on every cell change
        settings.debugPrint("showNoWitnessesMessage")
        if (settings.quietMode() ~= true) and sneaking then
            queueMessage(localization("showNoWitnessesMessage", {}))
        end
    else
        spotted = true
        types.Actor.activeSpells(self):add({
            id = "ernburglary_spotted",
            effects = {0},
            ignoreResistances = true,
            ignoreSpellAbsorption = true,
            ignoreReflect = true
        })

        local npcName = types.NPC.record(data.npc).name
        if (settings.quietMode() ~= true) and sneaking then
            queueMessage(localization("showSpottedMessage", {
                actorName = npcName
            }))
        end
    end

    drawSpottedIcon()
end

local function showWantedMessage(data)
    settings.debugPrint("showWantedMessage")
    ui.showMessage(localization("showWantedMessage", {
        value = data.value
    }))
end

local function showExpelledMessage(data)
    settings.debugPrint("showExpelledMessage")
    local faction = core.factions.records[data.faction]
    ui.showMessage(localization("showExpelledMessage", {
        factionName = data.faction.name
    }))
end



local function onUpdate(dt)
    if pendingMessage == nil then
        return
    end
    pendingMessage.delay = pendingMessage.delay - dt
    if pendingMessage.delay > 0 then
        return
    end
    ui.showMessage(pendingMessage.fmt, pendingMessage.args)
    pendingMessage = nil
end

return {
    eventHandlers = {
        [settings.MOD_NAME .. "alertsOnSpottedChange"] = alertsOnSpottedChange,
        [settings.MOD_NAME .. "showWantedMessage"] = showWantedMessage,
        [settings.MOD_NAME .. "showExpelledMessage"] = showExpelledMessage,
        [settings.MOD_NAME .. "onSneakChange"] = onSneakChange
    },
    engineHandlers = {
        onUpdate = onUpdate
    }
}
