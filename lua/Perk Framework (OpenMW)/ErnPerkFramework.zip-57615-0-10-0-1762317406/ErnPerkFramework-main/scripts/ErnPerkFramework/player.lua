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
local interfaces = require("openmw.interfaces")
local storage = require('openmw.storage')
local pself = require("openmw.self")
local types = require("openmw.types")
local log = require("scripts.ErnPerkFramework.log")
local settings = require("scripts.ErnPerkFramework.settings")
local UI = require('openmw.interfaces').UI

settings.init()

local function hasPerk(id)
    for _, foundID in ipairs(interfaces.ErnPerkFramework.getPlayerPerks()) do
        if foundID == id then
            return true
        end
    end
    return false
end

local function shouldShowUI()
    local remainingPoints = interfaces.ErnPerkFramework.totalAllowedPoints() -
        interfaces.ErnPerkFramework.currentSpentPoints()
    -- now we have to see if there is at least one perk that we could buy
    for id, perk in pairs(interfaces.ErnPerkFramework.getPerks()) do
        if (not hasPerk(id)) and perk:evaluateRequirements().satisfied and perk:cost() <= remainingPoints then
            return true
        end
    end
    return false
end

local function syncPerks()
    log(nil, "syncPerks() started.")
    -- keep calling this until the number of perks stops going down.
    -- this handles perks that require other perks to exist.
    local snapshot = interfaces.ErnPerkFramework.getPlayerPerks()
    local currentCount = #snapshot
    local allowedPoints = interfaces.ErnPerkFramework.totalAllowedPoints()
    for i = 1, 1000 do
        local currentPerksTotalCost = 0
        local filteredPerks = {}
        -- iterate from oldest to newest.
        for _, perkID in ipairs(snapshot) do
            local foundPerk = interfaces.ErnPerkFramework.getPerks()[perkID]
            if (foundPerk == nil) then
                -- Maybe don't do this, so late-registering providers aren't deleted.
                log(nil, "Removing perk " .. perkID .. ", missing.")
            elseif foundPerk:evaluateRequirements().satisfied then
                if currentPerksTotalCost + foundPerk:cost() > allowedPoints then
                    log(nil, "Removing perk " .. perkID .. ", not enough points.")
                    foundPerk:onRemove()
                else
                    currentPerksTotalCost = currentPerksTotalCost + foundPerk:cost()
                    table.insert(filteredPerks, perkID)
                end
            else
                log(nil, "Removing perk " .. perkID .. ", don't meet requirements.")
                foundPerk:onRemove()
            end
            coroutine.yield()
        end
        snapshot = filteredPerks

        if currentCount == #snapshot then
            -- there were no changes, so stop.
            break
        end
    end
    -- now that we're done removing them, apply them.
    interfaces.ErnPerkFramework.setPlayerPerks(snapshot)
    for _, perkID in ipairs(interfaces.ErnPerkFramework.getPlayerPerks()) do
        log(nil, "Adding perk " .. perkID .. "!")
        local foundPerk = interfaces.ErnPerkFramework.getPerks()[perkID]
        foundPerk:onAdd()
    end
    log(nil, "syncPerks() ended.")
end

local remainingDT = 0
local syncCoroutine = nil
local function processSync()
    if syncCoroutine == nil then
        syncCoroutine = coroutine.create(syncPerks)
    end
    local ok = coroutine.resume(syncCoroutine)
    if not ok then
        syncCoroutine = nil
        remainingDT = 20
    end
end

local function onUpdate(dt)
    -- don't call this all the time
    remainingDT = remainingDT - dt
    if remainingDT > 0 then
        return
    end

    -- don't do anything if we are in the UI.
    if UI.getMode() ~= nil and UI.getMode() ~= "" then
        return
    end

    -- sync often in case we drop requirements somehow
    processSync()
end

local function addPerk(data)
    if (data == nil) or (not data.perkID) then
        error("addPerk() called with invalid data.")
        return
    end
    local foundPerk = interfaces.ErnPerkFramework.getPerks()[data.perkID]
    if foundPerk == nil then
        error("addPerk(" .. tostring(data.perkID) .. ") called with bad perkID.")
        return
    end
    if foundPerk:evaluateRequirements().satisfied then
        local totalAllowed = interfaces.ErnPerkFramework.totalAllowedPoints()
        if interfaces.ErnPerkFramework.currentSpentPoints() + foundPerk:cost() <= totalAllowed then
            local activePerksByID = interfaces.ErnPerkFramework.getPlayerPerks()
            table.insert(activePerksByID, data.perkID)
            interfaces.ErnPerkFramework.setPlayerPerks(activePerksByID)
            foundPerk:onAdd()
        else
            log(nil,
                "Perk " ..
                tostring(data.perkID) ..
                " point cost can't be paid. Can't add it.")
        end
    else
        log(nil, "Perk " .. tostring(data.perkID) .. " requirements are not met. Can't add it.")
    end
end

local function removePerk(data)
    if (data == nil) or (not data.perkID) then
        error("removePerk() called with invalid data.")
        return
    end
    local foundPerk = interfaces.ErnPerkFramework.getPerks()[data.perkID]
    if foundPerk == nil then
        error("removePerk(" .. tostring(data.perkID) .. ") called with bad perkID.")
        return
    end
    local activePerksByID = interfaces.ErnPerkFramework.getPlayerPerks()
    for i, p in ipairs(activePerksByID) do
        if p == data.perkID then
            table.remove(activePerksByID, i)
            break
        end
    end
    interfaces.ErnPerkFramework.setPlayerPerks(activePerksByID)
    foundPerk:onRemove()
end

local function splitString(str)
    local out = {}
    for item in str:gmatch("([^,%s]+)") do
        table.insert(out, item)
    end
    return out
end

local function onConsoleCommand(mode, command, selectedObject)
    local function getSuffixForCmd(prefix)
        if string.sub(command:lower(), 1, string.len(prefix)) == prefix then
            return string.sub(command, string.len(prefix) + 1)
        else
            return nil
        end
    end
    local show = getSuffixForCmd("lua perks")
    local respec = getSuffixForCmd("lua perkrespec")

    if show ~= nil then
        print("Perk Show Menu: " .. tostring(show))
        local visible = splitString(show)
        if #visible == 0 then
            visible = nil
        end
        pself:sendEvent(settings.MOD_NAME .. "showPerkUI",
            { visiblePerks = visible })
    elseif respec ~= nil then
        print("Perk Respec")
        interfaces.ErnPerkFramework.setPlayerPerks({})
        remainingDT = 0
    end
end

local function UiModeChanged(data)
    if (data.newMode ~= nil) then
        return
    end
    local hasNCGDMW = interfaces.NCGDMW ~= nil
    -- spawn perk UI after the levelup UI.
    if data.oldMode == 'LevelUp' then
        if shouldShowUI() then
            pself:sendEvent(settings.MOD_NAME .. "showPerkUI", {})
        end
    elseif hasNCGDMW and data.oldMode == 'Rest' then
        if shouldShowUI() then
            pself:sendEvent(settings.MOD_NAME .. "showPerkUI", {})
        end
    else
        pself:sendEvent(settings.MOD_NAME .. "closePerkUI", {})
    end
end

return {
    eventHandlers = {
        UiModeChanged = UiModeChanged,
        [settings.MOD_NAME .. "addPerk"] = addPerk,
        [settings.MOD_NAME .. "removePerk"] = removePerk,
    },
    engineHandlers = {
        onUpdate = onUpdate,
        onConsoleCommand = onConsoleCommand,
    }
}
