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
local MOD_NAME = require("scripts.ErnBurglary.ns")
local localization = core.l10n(MOD_NAME)
local async = require("openmw.async")
local ui = require('openmw.ui')
local util = require('openmw.util')

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

local function isVisible()
    local newVisible = (spotted and interfaces.UI.isHudVisible()) and
        ((settings.ui().showIcon == "always") or (self.controls.sneak and settings.ui().showIcon ~= "never"))

    if not settings.ui().lockIcon then
        newVisible = true
    end
    return newVisible
end

local function position()
    return util.vector2(settings.ui().iconX, settings.ui().iconY)
end

local function layer()
    return settings.ui().lockIcon and 'Scene' or 'Modal'
end

local function size()
    return util.vector2(settings.ui().iconSize, settings.ui().iconSize)
end

local function makeIconLayout()
    -- (0,0) is top left of screen.
    -- default anchor is top-left. 1,0 is top right.
    return {
        name = 'spotted',
        layer = layer(),
        type = ui.TYPE.Container,
        template = interfaces.MWUI.templates.boxSolid,
        props = {
            --position = util.vector2(settings.ui.iconX + 202, settings.ui.iconY - 18),
            --relativePosition = util.vector2(0.3, 0.9),
            relativePosition = position(),
            anchor = util.vector2(0.5, 0.5),
            visible = isVisible()
        },
        content = ui.content { {
            name = "image",
            type = ui.TYPE.Image,
            props = {
                resource = ui.texture {
                    path = "icons\\ernburglary\\b_tx_spotted.dds"
                },
                size = size()
            }
        } }
    }
end

local spottedIcon = ui.create(makeIconLayout())

if not spottedIcon then
    error("failed to make spotted icon")
    return
end

local iconEvents = nil

local timeAccumulator = 0
local function updateSpottedIcon()
    if settings.ui().lockIcon then
        spottedIcon.layout.content["image"].props.color = nil
    else
        timeAccumulator = timeAccumulator + 10 * core.getRealFrameDuration()
        if timeAccumulator > 1000 then
            timeAccumulator = timeAccumulator - 1000
        end
        local notRed = math.sin(timeAccumulator) / 2
        spottedIcon.layout.content["image"].props.color = util.color.rgb(1, notRed, notRed)
    end
    spottedIcon.layout.props.relativePosition = position()
    spottedIcon.layout.props.visible = isVisible()
    spottedIcon.layout.props.size = size()

    spottedIcon.layout.layer = layer()
    spottedIcon:update()
end

local function round(num)
    return math.floor(num * 10000 + 0.5) / 10000
end

local screenSize = ui.screenSize()
iconEvents = {
    mousePress = async:callback(function(data, elem)
        if data.button == 1 then -- Left mouse button
            if settings.ui().lockIcon then
                return
            end
            settings.debugPrint("left click start spotted icon")
            if not elem.userData then
                elem.userData = {}
            end
            elem.userData.isDragging = true
            elem.userData.dragStartPosition = data.position
            elem.userData.windowStartPosition = spottedIcon.layout.props.relativePosition or util.vector2(0, 0)
        end
        spottedIcon:update()
    end),

    mouseRelease = async:callback(function(data, elem)
        settings.debugPrint("left click spotted icon")
        if elem.userData then
            elem.userData.isDragging = false
            --settings.ui().section:set("iconX", elem.userData.newPosition.x)
            --settings.ui().section:set("iconY", elem.userData.newPosition.y)
            --drawSpottedIcon()
        end
    end),

    mouseMove = async:callback(function(data, elem)
        if elem.userData and elem.userData.isDragging then
            -- Calculate new position based on mouse movement
            local deltaX = data.position.x - elem.userData.dragStartPosition.x
            local deltaY = data.position.y - elem.userData.dragStartPosition.y
            local newPosition = util.vector2(
                elem.userData.windowStartPosition.x + deltaX / screenSize.x,
                elem.userData.windowStartPosition.y + deltaY / screenSize.y
            )
            --elem.userData.newPosition = newPosition
            settings.ui().section:set("iconX", round(newPosition.x))
            settings.ui().section:set("iconY", round(newPosition.y))
            settings.debugPrint("x: " .. tostring(newPosition.x) .. ", y: " .. tostring(newPosition.y))
            --spottedIcon.layout.props.relativePosition = newPosition
            --spottedIcon:update()
        end
    end),
}
spottedIcon.layout.events = iconEvents

settings.ui().subscribe(async:callback(function(_, key)
    updateSpottedIcon()
end))

local function onSneakChange(sneakStatus)
    local changed = false
    if sneaking ~= sneakStatus then
        changed = true
    end
    sneaking = sneakStatus
    if (settings.ui().quietMode ~= true) and changed and sneaking and spotted then
        queueMessage(localization("showWarningMessage", {}))
    end
    if changed then
        updateSpottedIcon()
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
        if (settings.ui().quietMode ~= true) and sneaking then
            queueMessage(localization("showNoWitnessesMessage", {}))
        end
    else
        spotted = true
        if settings.ui().drain then
            types.Actor.activeSpells(self):add({
                id = "ernburglary_spotted",
                effects = { 0 },
                ignoreResistances = true,
                ignoreSpellAbsorption = true,
                ignoreReflect = true
            })
        end

        -- npc might not be real npc object.
        if (type(data.npc) ~= "table") and types.NPC.objectIsInstance(data.npc) then
            local npcRecord = types.NPC.record(data.npc)
            if (settings.ui().quietMode ~= true) and sneaking then
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
    --local faction = core.factions.records[data.faction]
    ui.showMessage(localization("showExpelledMessage", {
        factionName = data.faction.name
    }))
end

local function update(dt)
    onSneakChange(self.controls.sneak)

    updateSpottedIcon()

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

-- Redrawing the UI should work while paused.
local frameCountDown = 30
local simTime = 0
local function onFrame(dt)
    frameCountDown = frameCountDown - 1
    simTime = simTime + dt
    if frameCountDown <= 0 then
        update(simTime)
        frameCountDown = 30
        simTime = 0
    end
end


return {
    eventHandlers = {
        [MOD_NAME .. "alertsOnSpottedChange"] = alertsOnSpottedChange,
        [MOD_NAME .. "showWantedMessage"] = showWantedMessage,
        [MOD_NAME .. "showExpelledMessage"] = showExpelledMessage,
    },
    engineHandlers = {
        onFrame = onFrame,
    }
}
