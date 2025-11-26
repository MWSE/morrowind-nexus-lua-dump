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
local MOD_NAME = require("scripts.ErnPerkFramework.settings").MOD_NAME
local perkUtil = require("scripts.ErnPerkFramework.perk")
local pself = require("openmw.self")
local reqs = require("scripts.ErnPerkFramework.requirements")
local types = require("openmw.types")
local settings = require("scripts.ErnPerkFramework.settings")

if require("openmw.core").API_REVISION < 62 then
    error("OpenMW 0.49 or newer is required!")
end

local version = 1

-- manifest of registered perks. This is a map of ID -> perk record.
local perkTable = {}
-- list of all perk IDs.
local perkIDs = {}

-- list of perks, in the order they were picked.
local playerPerks = {}

--- Validates a single requirement data table.
--- Requirements must have `id` (string) and `check` (function).
--- `localizedName` (string or function) is optional.
--- @param requirement table The requirement data to validate.
--- @return boolean True if valid, false otherwise (errors are thrown on failure).
local function validateRequirement(requirement)
    if (not requirement) or (type(requirement) ~= "table") then
        error("validateRequirement() argument is not a table.", 3)
        return false
    end
    if (not requirement.id) or (type(requirement.id) ~= "string") then
        error("validateRequirement() requirement data is missing a string 'id' field.", 3)
        return false
    end
    if (not requirement.check) or (type(requirement.check) ~= "function") then
        error("validateRequirement() requirement data is missing a function 'check' field.", 3)
        return false
    end
    if (requirement.localizedName ~= nil) then
        if (type(requirement.localizedName) ~= "function") and (type(requirement.localizedName) ~= "string") then
            error(
                "validateRequirement() requirement data has a 'localizedName' field, which must be a string or a function that returns a string.",
                3)
            return false
        end
    end
    return true
end

--- Registers a new perk into the framework.
--- Perks must have `id`, `requirements` (table), `onAdd` (function), and `onRemove` (function).
--- Optional fields: `localizedName`, `localizedDescription`, `art`, `hidden`, `cost`.
--- If a perk with the same ID already exists, it is replaced.
--- @param data table The perk record data to register.
--- @return boolean True upon successful registration.
local function registerPerk(data)
    if (not data) or (type(data) ~= "table") then
        error("validateRequirement() argument is not a table.", 2)
        return false
    end
    if (not data.id) or (type(data.id) ~= "string") then
        error("registerPerk() perk data is missing a string 'id' field.", 2)
        return false
    end
    if (not data.requirements) or (type(data.requirements) ~= "table") then
        error("registerPerk(" .. tostring(data.id) .. ") perk data is missing a table 'requirements' field.", 2)
        return false
    end
    if (not data.onAdd) or (type(data.onAdd) ~= "function") then
        error("registerPerk(" .. tostring(data.id) .. ") perk data is missing a function 'onAdd' field.", 2)
        return false
    end
    if (not data.onRemove) or (type(data.onRemove) ~= "function") then
        error("registerPerk(" .. tostring(data.id) .. ") perk data is missing a function 'onRemove' field.", 2)
        return false
    end
    if (data.localizedName ~= nil) then
        if (type(data.localizedName) ~= "function") and (type(data.localizedName) ~= "string") then
            error(
                "registerPerk(" ..
                tostring(data.id) ..
                ") perk data has a 'localizedName' field, which must be a string or a function that returns a string.", 2)
            return false
        end
    end
    if (data.localizedDescription ~= nil) then
        if (type(data.localizedDescription) ~= "function") and (type(data.localizedDescription) ~= "string") then
            error(
                "registerPerk(" ..
                tostring(data.id) ..
                ") perk data has a 'localizedDescription' field, which must be a string or a function that returns a string.",
                2)
            return false
        end
    end
    if (data.art ~= nil) then
        if (type(data.art) ~= "function") and (type(data.art) ~= "string") then
            error(
                "registerPerk(" ..
                tostring(data.id) ..
                ") perk data has an 'art' field, which must be a string or a function that returns a texture path.",
                2)
            return false
        end
    end
    if (data.hidden ~= nil) then
        -- Hidden perks don't normally appear in the menu.
        if (type(data.hidden) ~= "function") and (type(data.hidden) ~= "boolean") then
            error(
                "registerPerk(" ..
                tostring(data.id) ..
                ") perk data has a 'hidden' field, which must be a boolean or a function that returns a boolean.",
                2)
            return false
        end
    end
    if (data.cost ~= nil) then
        if (type(data.cost) ~= "function") and (type(data.cost) ~= "number") then
            error(
                "registerPerk(" ..
                tostring(data.id) ..
                ") perk data has a 'cost' field, which must be a number or a function that returns a number.",
                2)
            return false
        end
    end

    for i, r in ipairs(data.requirements) do
        if not validateRequirement(r) then
            error("registerPerk(" .. tostring(data.id) .. ") perk data has a bad requirement at index " .. tostring(i), 2)
            return false
        end
    end

    -- check if we have an id collision.
    -- we want to allow this so perk mods can patch eachother.
    if perkTable[data.id] ~= nil then
        print("registerPerk(" .. tostring(data.id) .. ") is replacing an existing perk.")
        -- Call onRemove for any player that registered the old one previously?
        -- Gets messy because the ID of the removed perk is unavailable once we leave this
        -- function.
    else
        -- didn't previously exist
        print("registerPerk(" .. tostring(data.id) .. ") completed.")
        table.insert(perkIDs, data.id)
    end

    perkTable[data.id] = perkUtil.NewPerk(data)
    return true
end

--- Gets the map of all registered perks (ID -> perk object).
--- @return table A map of registered perk ID to perk object.
local function getPerks()
    return perkTable
end

--- Gets a list of all registered perk IDs.
--- @return table A list (array) of perk IDs (strings).
local function getPerkIDs()
    return perkIDs
end

--- Gets the table of common requirement builder functions.
--- @return table The requirement builder functions module.
local function requirements()
    return reqs
end

--- getPerksForPlayer returns a list of perk IDs in the order that the player chose them.
--- This list only contains the IDs of the perks the player currently has.
--- @return table A list (array) of perk IDs (strings).
local function getPlayerPerks()
    return playerPerks
end

--- setPlayerPerks replaces the ordered list of perk IDs that the player chose.
--- You probably don't want to use this for general perk manipulation.
--- @param perkIDList table The new ordered list of perk IDs to set for the player.
local function setPlayerPerks(perkIDList)
    playerPerks = perkIDList
end

--- totalAllowedPoints returns how many total perk points a player has.
--- This value includes spent and unspent points.
local function totalAllowedPoints()
    local level = types.Actor.stats.level(pself).current
    return math.floor(settings.perksPerLevel * level)
end

--- currentSpentPoints returns how many perk points have been allocated.
local function currentSpentPoints()
    local total = 0
    for _, foundID in ipairs(getPlayerPerks()) do
        total = total + getPerks()[foundID]:cost()
    end
    return total
end

--- Saves the player's perk state for persistence.
--- @return table The save data table.
local function onSave()
    return {
        version = version,
        playerPerks = playerPerks,
    }
end

--- Loads the player's perk state from saved data.
--- Clears existing perks if the version changes.
--- @param data table The loaded save data.
local function onLoad(data)
    if (data == nil) then
        return
    end
    if (not data) or (not data.version) or (data.version ~= version) then
        -- throw all known perks away since version changed.
        return
    end
    playerPerks = data.playerPerks
    for _, p in ipairs(playerPerks) do
        print("Active Perk: " .. p)
    end
end

return {
    interfaceName = MOD_NAME,
    interface = {
        version = version,
        registerPerk = registerPerk,
        getPerks = getPerks,
        getPerkIDs = getPerkIDs,
        requirements = requirements,
        getPlayerPerks = getPlayerPerks,
        setPlayerPerks = setPlayerPerks,
        currentSpentPoints = currentSpentPoints,
        totalAllowedPoints = totalAllowedPoints,
    },
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
    }
}
