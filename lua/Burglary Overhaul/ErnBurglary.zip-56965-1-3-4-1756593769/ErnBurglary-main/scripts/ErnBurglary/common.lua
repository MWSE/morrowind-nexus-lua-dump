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
local settings = require("scripts.ErnBurglary.settings")
local types = require("openmw.types")
local aux_util = require('openmw_aux.util')

local function serializeOwner(owner)
    if (owner == nil) or ((owner.recordId == nil) and (owner.factionId == nil)) then
        return nil
    end
    return {
        recordId = owner.recordId,
        factionRank = owner.factionRank,
        factionId = owner.factionId
    }
end

local function ownerToString(owner)
    return "recordId=" .. tostring(owner.recordId) .. "!factionRank=" .. tostring(owner.factionRank) .. "!factionId=" .. tostring(owner.factionId) .. "!"
end

local function stringToOwner(str)
    local owner = {}
    for k, v in string.gmatch(str, "([^=]+)=([^=]+)!") do
        if v ~= nil then
        owner[k] = v
        end
    end
    if owner.factionRank ~= nil then
        owner.factionRank = tonumber(owner.factionRank)
    end
    return owner
end

-- getInventoryOwnership returns a map of item instance id to {item, owner}.
local function getInventoryOwnership(inventory, backupOwner)
    local itemIDtoOwnership = {}
    for _, itemInContainer in ipairs(inventory:getAll()) do
        if (itemInContainer.owner ~= nil) and ((itemInContainer.owner.recordId ~= nil) or (itemInContainer.factionId ~= nil)) then
            itemIDtoOwnership[itemInContainer.id] = {item=itemInContainer, owner=serializeOwner(itemInContainer.owner)}
            --settings.debugPrint("found owner for item in container: " .. itemInContainer.recordId)
        else
            itemIDtoOwnership[itemInContainer.id] = {item=itemInContainer, owner=serializeOwner(backupOwner)}
            --settings.debugPrint("no owner for item in container: " .. itemInContainer.recordId)
        end
    end
    return itemIDtoOwnership
end

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

local function test()
    local npcOwner = {
        recordId = "person",
    }
    local npcParsed = stringToOwner(ownerToString(npcOwner))
    if npcOwner.recordId ~= npcParsed.recordId then
        error("owner serialization failed")
    end

    local factionNilOwner = {
        factionId = "group",
    }
    local factionNilParsed = stringToOwner(ownerToString(factionNilOwner))
    if factionNilOwner.factionId ~= factionNilParsed.factionId then
        error("owner serialization failed")
    end

    local factionOwner = {
        factionId = "group",
        factionRank = 3,
    }
    local factionParsed = stringToOwner(ownerToString(factionOwner))
    if factionOwner.factionId ~= factionParsed.factionId then
        error("owner serialization failed")
    end
    if factionOwner.factionRank ~= factionParsed.factionRank then
        error("owner serialization failed")
    end
end

test()

return {
    ownerToString = ownerToString,
    stringToOwner = stringToOwner,
    serializeOwner = serializeOwner,
    getInventoryOwnership = getInventoryOwnership,
    atLeastRank = atLeastRank,
}