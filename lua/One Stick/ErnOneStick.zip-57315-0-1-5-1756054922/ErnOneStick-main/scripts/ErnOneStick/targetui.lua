--[[
ErnOneStick for OpenMW.
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

local settings = require("scripts.ErnOneStick.settings")
local pself = require("openmw.self")
local ui = require('openmw.ui')
local util = require('openmw.util')
local aux_util = require('openmw_aux.util')
local aux_ui = require('openmw_aux.ui')
local interfaces = require("openmw.interfaces")
local types = require('openmw.types')

-- https://openmw.readthedocs.io/en/stable/reference/lua-scripting/widgets/widget.html#properties

-- https://openmw.readthedocs.io/en/stable/reference/lua-scripting/openmw_ui.html##(Template)

local function atLeastRank(npc, factionID, rank)
    local inFaction = false
    for _, foundID in pairs(types.NPC.getFactions(npc)) do
        if foundID == factionID then
            inFaction = true
            break
        end
    end
    if inFaction == false then
        settings.debugPrint("your rank in " .. factionID .. " is <not a member>")
        return false
    end

    local selfRank = types.NPC.getFactionRank(npc, factionID)
    settings.debugPrint("your rank in " .. factionID .. " is " .. tostring(selfRank))
    if selfRank == nil then
        return false
    elseif (rank == nil) then
        return true
    else
        return selfRank >= rank
    end
end

local function isOwned(entity)
    if entity.baseType == types.Actor then
        return false
    end
    if entity.owner == nil then
        return false
    end
    if entity.owner.recordId ~= nil then
        return true
    end
    if entity.owner.factionId ~= nil then
        if atLeastRank(pself, entity.owner.factionId, entity.owner.factionRank) == false then
            return true
        end
    end
    return false
end

local function getRecord(entity)
    return entity.type.records[entity.recordId]
end

local function makeTargetUI(entity)
    -- headerColor = util.color.rgb(223 / 255, 201 / 255, 159 / 255),
    local color = util.color.rgb(223 / 255, 201 / 255, 159 / 255)
    if isOwned(entity) then
        color = util.color.rgb(255 / 255, 99 / 255, 71 / 255)
    end

    -- (0,0) is top left of screen.
    -- default anchor is top-left. 1,0 is top right.
    local lowerBox = ui.create {
        name = 'target',
        layer = 'Windows',
        type = ui.TYPE.Container,
        template = interfaces.MWUI.templates.boxSolid,
        props = {
            relativePosition = util.vector2(0.5, 0.9),
            relativeSize = util.vector2(0.1, 1),
            anchor = util.vector2(0.5, 1),
            visible = true
        },
        content = ui.content { {
            template = interfaces.MWUI.templates.padding,
            props = {
                visible = true
            },
            content = ui.content { {
                relativePosition = util.vector2(0.5, 0.5),
                size = util.vector2(30, 30),
                anchor = util.vector2(0.5, 0.5),
                template = interfaces.MWUI.templates.textHeader,
                type = ui.TYPE.Text,
                props = {
                    text = getRecord(entity).name,
                    textColor = color,
                },
            } },
        } }
    }
    return lowerBox
end

local lowerBar = nil

local function showTargetUI(entity)
    if lowerBar ~= nil then
        lowerBar:destroy()
    end
    lowerBar = makeTargetUI(entity)
    lowerBar:update()
    ui.updateAll()
end

local function destroy()
    if lowerBar ~= nil then
        lowerBar:destroy()
        lowerBar = nil
    end
    ui.updateAll()
end

return {
    showTargetUI = showTargetUI,
    destroy = destroy,
}
