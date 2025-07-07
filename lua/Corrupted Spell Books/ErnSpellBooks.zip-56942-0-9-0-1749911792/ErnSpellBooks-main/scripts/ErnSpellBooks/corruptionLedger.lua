--[[
ErnSpellBooks for OpenMW.
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
local settings = require("scripts.ErnSpellBooks.settings")
local core = require("openmw.core")

if require("openmw.core").API_REVISION < 62 then
    error("OpenMW 0.49 or newer is required!")
end

-- corruptionTable maps a corruptionID to a bag with .id, .onApply, and .minimumLevel.
-- minimumLevel informs when it should drop in random tables. This is an integer.
local corruptionTable = {}
-- corruptionIDs is list of just IDs.
local corruptionIDs = {}

-- data has these fields:
-- id
-- minimumLevel
-- prefixName
-- suffixName
-- description
-- onCast takes in a bag with these fields:
--      id (string, this is the corruptionID)
--      caster (actor)
--      spellID (string)
--      bookRecordID (string, unique to the specific book)
-- onApply takes in a bag with these fields:
--      id (string, this is the corruptionID)
--      caster (actor)
--      target (actor)
--      spellID (string)
--      bookRecordID (string, unique to the specific book)
local function registerCorruption(data)
    if (data == nil) or (data.id == nil) or (data.id == "") or ((data.onApply == nil) and (data.onCast == nil)) then
        error("RegisterCorruption() bad data")
        return
    end
    if (data.prefixName == nil) or (data.suffixName == nil) or (data.description == nil) then
        error("RegisterCorruption() bad localization fields in data")
        return
    end
    if corruptionTable[data.id] ~= nil then
        error("re-registering corruption handler forbidden: " .. data.id)
        return
    end
    -- minimumLevel is optional
    if data.minimumLevel == nil then
        data.minimumLevel = 0
    end
    settings.debugPrint("Registered " .. data.id .. " corruption handler.")
    corruptionTable[data.id] = data
    table.insert(corruptionIDs, data.id)
end

local function getCorruption(corruptionID)
    if (corruptionID == nil) or (corruptionID == "") then
        return nil
    end

    local bag = corruptionTable[corruptionID]
    if bag == nil then
        error("corruption with id '" .. corruptionID .. "' not found!")
        return nil
    end

    return bag
end

local function getRandomCorruptionIDs(playerLevel, count)
    local randList = {}
    for _, id in pairs(corruptionIDs) do
        local corruption = corruptionTable[id]
        if corruption == nil then
            error("bad corruptionID: " .. id)
        end
        if corruption.minimumLevel <= playerLevel then
            -- get random index to insert into. 1 to size+1.
            local insertAt = math.random(1, 1 + #randList)
            table.insert(randList, insertAt, id)
            settings.debugPrint("getRandomCorruptions() inserted " .. corruption.id)
        end
    end
    local outList = {table.unpack(randList, 1, count)}
    settings.debugPrint("getRandomCorruptions() selected " .. tostring(#outList) .. " corruptions from " .. tostring(#randList) .. " options.")
    return outList
end

return {
    interfaceName = "ErnCorruptionLedger",
    interface = {
        version = 1,
        registerCorruption = registerCorruption,
        getCorruption = getCorruption,
        getRandomCorruptionIDs = getRandomCorruptionIDs,
    }
}
