--[[
ErnPerkFramework for OpenMW.
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

-- This file contains some common requirements builders that could be re-used by lots of stuff.

local MOD_NAME = require("scripts.ErnPerkFramework.settings").MOD_NAME
local core = require("openmw.core")
local localization = core.l10n(MOD_NAME)
local pself = require("openmw.self")
local types = require("openmw.types")
local builtin = MOD_NAME .. '_builtin_'
local interfaces = require("openmw.interfaces")
local storage = require('openmw.storage')
local log = require("scripts.ErnPerkFramework.log")

local mwVars = storage.globalSection(MOD_NAME .. "_mwVars")

--- Resolves a field that might be a literal value or a function that returns a value.
--- @param field any A literal value or a function.
--- @return any The value of the field, or the return value of the function.
local function resolve(field)
    if type(field) == 'function' then
        return field()
    else
        return field
    end
end

--- Creates a requirement for a minimum player level.
--- @param level number The required minimum level.
--- @return table The requirement data table.
local function minimumLevel(level)
    return {
        id = builtin .. 'minimumLevel',
        localizedName = localization('req_minimumLevel', { level = level }),
        check = function()
            return types.Actor.stats.level(pself).current >= level
        end
    }
end

--- Creates a requirement for a minimum base skill level.
--- @param skillID string The ID of the skill (e.g., "Acrobatics").
--- @param level number The required minimum base skill level.
--- @return table The requirement data table.
local function minimumSkillLevel(skillID, level)
    local skillRecord = core.stats.Skill.records[skillID]
    return {
        id = builtin .. 'minimumSkillLevel',
        localizedName = localization('req_minimumSkillLevel', { skill = skillRecord.name, level = level }),
        check = function()
            return types.NPC.stats.skills[skillID](pself).base >= level
        end
    }
end

--- Creates a requirement for a minimum base attribute level.
--- @param attributeID string The ID of the attribute (e.g., "Strength").
--- @param level number The required minimum base attribute level.
--- @return table The requirement data table.
local function minimumAttributeLevel(attributeID, level)
    local attributeRecord = core.stats.Attribute.records[attributeID]
    return {
        id = builtin .. 'minimumAttributeLevel',
        localizedName = localization('req_minimumAttributeLevel', { attribute = attributeRecord.name, level = level }),
        check = function()
            return types.Actor.stats.attributes[attributeID](pself).base >= level
        end
    }
end

--- Creates a requirement that checks if an NPC is a member of a faction and meets a minimum rank.
--- @param npc table The NPC object (usually pself).
--- @param factionID string The ID of the faction.
--- @param rank number The required minimum rank (1-indexed, or nil to check for membership only).
--- @return boolean True if the NPC is a member and meets the rank, false otherwise.
local function atLeastRank(npc, factionID, rank)
    local inFaction = false
    for _, foundID in pairs(types.NPC.getFactions(npc)) do
        if foundID == factionID then
            inFaction = true
            break
        end
    end
    if inFaction == false then
        -- not a member
        return false
    end

    local selfRank = types.NPC.getFactionRank(npc, factionID)
    if selfRank == nil then
        return false
    elseif (rank == nil) then
        return true
    else
        return selfRank >= rank
    end
end

--- Creates a requirement for a minimum faction rank.
--- Rank 0 is the first rank of a guild (to match uesp.net/Morrowind/Factions).
--- Note: The check function uses 1-based index internally for OpenMW's API.
--- @param factionID string The ID of the faction.
--- @param rank number The required minimum rank (0-indexed).
--- @return table The requirement data table.
local function minimumFactionRank(factionID, rank)
    local factionRecord = core.factions.records[factionID]
    local factionRankName = factionRecord.ranks[rank + 1].name

    return {
        id = builtin .. 'minimumFactionRank',
        localizedName = localization('req_minimumFactionRank',
            { factionName = factionRecord.name, factionRankName = factionRankName }),
        check = function()
            return atLeastRank(pself, factionID, rank + 1)
        end
    }
end

--- Formats a list of strings into a localized string joined by "or".
--- @param items table A list of strings.
--- @return string The combined and localized string.
local function orList(items)
    local out = ""
    if #items == 1 then
        return items[1]
    end

    for i, item in ipairs(items) do
        if i == 1 then
            out = items[1]
        elseif i == #items then
            out = localization('list_join_or',
                { prevList = out, nextItem = item })
        else
            out = localization('list_join',
                { prevList = out, nextItem = item })
        end
    end

    return out
end

--- Formats a list of strings into a localized string joined by "and", and groups it.
--- @param items table A list of strings.
--- @return string The combined and localized string.
local function andList(items)
    local out = ""
    if #items == 1 then
        return items[1]
    end

    for i, item in ipairs(items) do
        if i == 1 then
            out = items[1]
        elseif i == #items then
            out = localization('list_join_and',
                { prevList = out, nextItem = item })
        else
            out = localization('list_join',
                { prevList = out, nextItem = item })
        end
    end

    if #items > 1 then
        out = localization('list_group', { list = out })
    end

    return out
end

--- Creates a requirement that is met if the player has *any* of the specified perks.
--- @param ... string One or more perk IDs.
--- @return table The requirement data table.
local function hasPerk(...)
    local args = { select(1, ...) }
    return {
        id = builtin .. 'perk',
        localizedName = function()
            local perkNames = {}
            for _, id in ipairs(args) do
                table.insert(perkNames, interfaces.ErnPerkFramework.getPerks()[id]:name())
            end
            return orList(perkNames)
        end,
        check = function()
            for _, foundPerk in ipairs(interfaces.ErnPerkFramework.getPlayerPerks()) do
                for _, checkPerk in ipairs(args) do
                    if checkPerk == foundPerk then
                        return true
                    end
                end
            end
            return false
        end
    }
end

--- Creates a requirement that is met if the player's race is *any* of the specified races.
--- @param ... string One or more race IDs.
--- @return table The requirement data table.
local function race(...)
    local args = { select(1, ...) }
    return {
        id = builtin .. 'race',
        localizedName = function()
            local raceNames = {}
            for _, id in ipairs(args) do
                table.insert(raceNames, types.NPC.races.records[id].name)
            end
            return orList(raceNames)
        end,
        check = function()
            local actualRaceID = types.NPC.record(pself).race
            for _, testRace in ipairs(args) do
                if testRace == actualRaceID then
                    return true
                end
            end
            return false
        end
    }
end

--- Groups multiple requirements using a logical OR.
--- The requirement is met if at least one grouped requirement is met.
--- @param ... table One or more requirement data tables.
--- @return table The combined OR requirement data table.
local function orGroup(...)
    local args = { select(1, ...) }
    return {
        id = builtin .. 'or',
        localizedName = function()
            local reqNames = {}
            for _, req in ipairs(args) do
                table.insert(reqNames, resolve(req.localizedName))
            end
            return orList(reqNames)
        end,
        check = function()
            for _, req in ipairs(args) do
                if req.check() then
                    return true
                end
            end
            return false
        end
    }
end

--- Groups multiple requirements using a logical AND.
--- The requirement is met only if all grouped requirements are met.
--- (This is typically unnecessary as top-level requirements are already ANDed).
--- @param ... table One or more requirement data tables.
--- @return table The combined AND requirement data table.
local function andGroup(...)
    local args = { select(1, ...) }
    return {
        id = builtin .. 'and',
        localizedName = function()
            local reqNames = {}
            for _, req in ipairs(args) do
                table.insert(reqNames, resolve(req.localizedName))
            end
            return andList(reqNames)
        end,
        check = function()
            for _, req in ipairs(args) do
                if not req.check() then
                    return false
                end
            end
            return true
        end
    }
end

--- Inverts a requirement using a logical NOT.
--- The requirement is met if the wrapped requirement is NOT met.
--- @param someReq table The requirement data table to invert.
--- @return table The inverted requirement data table.
local function invert(someReq)
    return {
        id = builtin .. 'not',
        localizedName = function()
            return localization('not_req', { req = resolve(someReq.localizedName) })
        end,
        check = function()
            return not someReq.check()
        end
    }
end

--- Reads the value of a global variable from the shared global storage.
--- @param name string The name of the global variable.
--- @return any The value of the global variable.
local function readGlobalVariable(name)
    local readVal = mwVars:get(pself.id)[name]
    log(name, "Variable " .. name .. ": " .. tostring(readVal))
    return readVal
end

--- Creates a requirement checking for werewolf status.
--- Checks the global variable "PCWerewolf".
--- @param status boolean If true, checks if the player is a werewolf (PCWerewolf == 1). If false, checks if they are not.
--- @return table The requirement data table.
local function werewolf(status)
    if status then
        return {
            id = builtin .. 'is_a_werewolf',
            localizedName = localization('req_is_a_werewolf', {}),
            check = function()
                return readGlobalVariable("pcwerewolf") == 1
            end
        }
    else
        return {
            id = builtin .. 'is_not_a_werewolf',
            localizedName = localization('req_is_not_a_werewolf', {}),
            check = function()
                return readGlobalVariable("pcwerewolf") ~= 1
            end
        }
    end
end


--- Checks if the player is a vampire by checking for the "vampire attributes" spell.
--- @return boolean True if the player is a vampire, false otherwise.
local function isVampire()
    -- test with:
    -- player->AddSpell "vampire blood aundae"
    for _, spell in pairs(types.Actor.spells(pself)) do
        if spell.id == "vampire attributes" then
            return true
        end
    end
    return false
end

--- Creates a requirement checking for vampire status.
--- @param status boolean If true, checks if the player is a vampire. If false, checks if they are not.
--- @return table The requirement data table.
local function vampire(status)
    if status then
        return {
            id = builtin .. 'is_a_vampire',
            localizedName = localization('req_is_a_vampire', {}),
            check = function()
                return isVampire()
            end
        }
    else
        return {
            id = builtin .. 'is_not_a_vampire',
            localizedName = localization('req_is_not_a_vampire', {}),
            check = function()
                return not isVampire()
            end
        }
    end
end

return {
    minimumLevel = minimumLevel,
    minimumSkillLevel = minimumSkillLevel,
    minimumAttributeLevel = minimumAttributeLevel,
    minimumFactionRank = minimumFactionRank,
    vampire = vampire,
    werewolf = werewolf,
    race = race,
    hasPerk = hasPerk,
    orGroup = orGroup,
    andGroup = andGroup,
    invert = invert,
    readGlobalVariable = readGlobalVariable,
}
