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
]]
local interfaces = require("openmw.interfaces")
local types = require("openmw.types")
local settings = require("scripts.ErnBurglary.settings")
local self = require("openmw.self")
local core = require("openmw.core")
local infrequent = require("scripts.ErnBurglary.infrequent")
local localization = core.l10n(settings.MOD_NAME)
local async = require("openmw.async")
local ui = require('openmw.ui')
local util = require('openmw.util')
local aux_util = require('openmw_aux.util')
local aux_ui = require('openmw_aux.ui')

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

local visible = false
local sneaking = false
local spotted = false

local spottedIcon = nil

local function makeIcon(path)
    local iconSettings = settings.icon()
    settings.debugPrint("icon settings: " .. aux_util.deepToString(iconSettings, 3))
    local size = iconSettings["iconSize"]
    -- (0,0) is top left of screen.

    -- default anchor is top-left. 1,0 is top right.
    local box = ui.create {
        name = 'spotted',
        layer = 'HUD',
        type = ui.TYPE.Container,
        template = interfaces.MWUI.templates.boxSolid,
        props = {
            position = util.vector2(iconSettings["iconOffsetX"] + 202, iconSettings["iconOffsetY"] - 18),
            relativePosition = util.vector2(0, 1),
            anchor = util.vector2(0, 1),
            visible = false
        },
        content = ui.content { {
            type = ui.TYPE.Image,
            props = {
                resource = ui.texture {
                    path = path
                },
                color = util.color.hex("f8a102"),
                size = util.vector2(size, size)
            },
            size = util.vector2(size, size)
        } }
    }
    return box
end

local function drawSpottedIcon()
    if spottedIcon == nil then
        local iconPath = core.magic.effects.records[core.magic.EFFECT_TYPE.Blind].icon
        -- local iconPath = core.stats.Skill.records["sneak"].icon
        settings.debugPrint("iconpath: " .. iconPath)
        spottedIcon = makeIcon(iconPath)
    end
    local newVisible = (spotted and interfaces.UI.isHudVisible()) and
        ((settings.icon()["showIcon"] == "always") or (self.controls.sneak and settings.icon()["showIcon"] ~= "never"))

    if newVisible ~= visible then
        visible = newVisible
        spottedIcon.layout.props.visible = newVisible
        spottedIcon:update()
        ui.updateAll()
    end
    spottedIcon.layout.props.visible = visible
    spottedIcon:update()
    ui.updateAll()
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
    local changed = false
    if sneaking ~= sneakStatus then
        changed = true
    end
    sneaking = sneakStatus
    if (settings.quietMode() ~= true) and changed and sneaking and spotted then
        queueMessage(localization("showWarningMessage", {}))
    end
    if changed then
        drawSpottedIcon()
    end
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
            effects = { 0 },
            ignoreResistances = true,
            ignoreSpellAbsorption = true,
            ignoreReflect = true
        })

        -- npc might not be real npc object.
        if (type(data.npc) ~= "table") and types.NPC.objectIsInstance(data.npc) then
            local npcRecord = types.NPC.record(data.npc)
            if (settings.quietMode() ~= true) and sneaking then
                queueMessage(localization("showSpottedMessage", {
                    actorName = npcRecord.name
                }))
            end
        end
    end
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

local function onInfrequentUpdate(dt)
    onSneakChange(self.controls.sneak)

    drawSpottedIcon()

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

local infrequentMap = infrequent.FunctionCollection:new()
infrequentMap:addCallback("onInfrequentUpdate", 0.09, onInfrequentUpdate)

local function onUpdate(dt)
    infrequentMap:onUpdate(dt)
end


return {
    eventHandlers = {
        [settings.MOD_NAME .. "alertsOnSpottedChange"] = alertsOnSpottedChange,
        [settings.MOD_NAME .. "showWantedMessage"] = showWantedMessage,
        [settings.MOD_NAME .. "showExpelledMessage"] = showExpelledMessage,
    },
    engineHandlers = {
        onUpdate = onUpdate,
    }
}
