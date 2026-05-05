--[[
ErnDebt for OpenMW.
Copyright (C) Erin Pentecost 2026

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

-- This file is in charge of tracking and exposing path information.
-- Interact with it via the interface it exposes.

local MOD_NAME        = require("scripts.ErnDebt.ns")
local core            = require('openmw.core')
local pself           = require("openmw.self")
local nearby          = require("openmw.nearby")
local settings        = require("scripts.ErnDebt.settings")
local mwjournal       = require("scripts.ErnDebt.mwjournal")
local interfaces      = require("openmw.interfaces")
local ui              = require('openmw.ui')
local util            = require('openmw.util')
local types           = require('openmw.types')
local localization    = core.l10n(MOD_NAME)

-- can't spawn too far, because the actor won't notice the player.
local spawnDist       = 600

local persist         = {
    justWarned = false,
    currentDebt = settings.main.startDebt,
    currentPaymentSkipStreak = 0,
    collectorsKilled = 0,
    lastSpawnTime = core.getGameTime(),
    conversationsSinceLastSpawn = 0,
    -- enabled is true if we are allowed to spawn collectors via the quest state
    enabled = true,
}

local oneWeekDuration = 604800

local function minimumTimePassed()
    local duration = settings.main.debug and 100 or oneWeekDuration

    return persist.lastSpawnTime + duration < core.getGameTime()
end

local function currentGold()
    return pself.type.inventory(pself):countOf("gold_001")
end

local function spawn(cell, position)
    local currentGoldAmt = currentGold()
    -- add missing interest
    local weeksSinceSpawn = (core.getGameTime() - persist.lastSpawnTime) / (oneWeekDuration)
    local newDebt = math.ceil(persist.currentDebt * math.exp(settings.main.interest * weeksSinceSpawn))
    settings.debugPrint("Weeks since spawn: " ..
        tostring(weeksSinceSpawn) ..
        ". Previous debt: " .. tostring(persist.currentDebt) .. ". New Debt: " .. tostring(newDebt) .. ".")
    persist.currentDebt = newDebt
    persist.lastSpawnTime = core.getGameTime()
    persist.currentPaymentSkipStreak = persist.currentPaymentSkipStreak + 1
    persist.justWarned = false
    persist.conversationsSinceLastSpawn = 0
    local minPayment = math.min(persist.currentDebt,
        math.max(500 * persist.currentPaymentSkipStreak, 0.5 * currentGoldAmt))

    if settings.main.debug then
        ui.showMessage(localization("collectorSpawnedMessage",
            { currentDebt = persist.currentDebt, minPayment = minPayment }))
    end

    core.sendGlobalEvent(MOD_NAME .. "onCollectorSpawn", {
        player = pself,
        cellId = cell.id,
        position = { x = position.x, y = position.y, z = position.z },
        currentDebt = persist.currentDebt,
        currentPaymentSkipStreak = persist.currentPaymentSkipStreak,
        collectorsKilled = persist.collectorsKilled,
        playerGold = currentGoldAmt,
        minPayment = minPayment,
        spawnTime = persist.lastSpawnTime,
    })
end

local function shouldSpawn()
    settings.debugPrint("shouldSpawn()")
    if not persist.enabled then
        settings.debugPrint("shouldSpawn() - not enabled")
        return false
    end
    if persist.currentDebt <= 0 then
        settings.debugPrint("shouldSpawn() - no debt")
        return false
    end

    if not minimumTimePassed() then
        settings.debugPrint("shouldSpawn() - minimum time hasn't passed")
        return false
    end

    -- chance to not spawn the collector goes down the more you skip payments.
    local daysLate = math.ceil((core.getGameTime() - persist.lastSpawnTime - oneWeekDuration) / (24 * 60 * 60))
    local chance = math.max(5,
        3 * daysLate + 5 * persist.currentPaymentSkipStreak + (persist.conversationsSinceLastSpawn or 0))
    if settings.main.debug then
        chance = 50
    end
    settings.debugPrint("Days late: " ..
        tostring(daysLate) ..
        ". Skip streak: " .. tostring(persist.currentPaymentSkipStreak) .. ". Spawn chance is " ..
        tostring(chance) .. "pct.")
    if chance > 20 and not persist.justWarned then
        persist.justWarned = true
        ui.showMessage(localization("beingWatchedMessage", {}))
        return false
    end
    if chance < 20 then
        return false
    end
    if math.random(0, 100) < chance then
        return true
    end
    return false
end


local function UiModeChanged(data)
    --- Talking with people makes you easier to track.
    if data.newMode == "Dialogue" then
        persist.conversationsSinceLastSpawn = persist.conversationsSinceLastSpawn + 1
    end
end

local function onCollectorDespawn(data)
    local quest = types.Player.quests(pself)[mwjournal.questId]
    if quest.stage == 1 then
        quest:addJournalEntry(5, pself)
    end

    if data.dead then
        settings.debugPrint("Collector killed.")
        persist.collectorsKilled = persist.collectorsKilled + 1
        if quest.stage < 100 then
            quest:addJournalEntry(10, pself)
        end
    end

    if data.justPaidAmount <= 0 then
        settings.debugPrint("Payment skipped.")
    else
        settings.debugPrint("Paid " .. tostring(data.justPaidAmount) .. ".")
        persist.currentPaymentSkipStreak = 0
        persist.currentDebt = persist.currentDebt - data.justPaidAmount
    end
end

local function ensureQuestStarted()
    local quest = types.Player.quests(pself)[mwjournal.questId]
    if quest.stage <= 0 then
        settings.debugPrint("starting quest")
        quest:addJournalEntry(1, pself)
    end
end

local function onQuestUpdate(questId, stage)
    if questId == mwjournal.questId then
        persist.enabled = mwjournal.enabled(stage)
        settings.debugPrint("quest stage change: " ..
            tostring(mwjournal.questStages[stage]) .. ", enabled: " .. tostring(persist.enabled))
    end
end

local function safeLocation(desired, destination, maxRange)
    local desiredOnNavMesh = nearby.findNearestNavMeshPosition(desired, {
        searchAreaHalfExtents = util.vector3(1000, 1000, 5000),
        includeFlags = nearby.NAVIGATOR_FLAGS.Walk,
    })

    if not desiredOnNavMesh then
        return nil
    end

    -- https://github.com/OpenMW/openmw/blob/a6c053ab4430627494d351c9714eb7bbffa657c7/components/detournavigator/status.hpp
    local status, list = nearby.findPath(desiredOnNavMesh, destination, {
        includeFlags = nearby.NAVIGATOR_FLAGS.Walk +
            nearby.NAVIGATOR_FLAGS.UsePathgrid
    })
    if status ~= nearby.FIND_PATH_STATUS.Success then
        settings.debugPrint("failed to path: " .. tostring(status))
        return nil
    end
    local rangeSquared = maxRange * maxRange
    for i, point in ipairs(list) do
        if (point - desired):length2() < rangeSquared then
            settings.debugPrint("path found after " .. tostring(i) .. " steps")
            return point
        end
    end
    settings.debugPrint("failed to path: out of points")
    return nil
end

local function onExitingInterior(data)
    settings.debugPrint("exiting interior. current cell: " .. tostring(pself.cell.id))
    ensureQuestStarted()
    if not shouldSpawn() then
        return
    end

    local destCell = types.Door.destCell(data.door)
    local destPosition = types.Door.destPosition(data.door)
    local destRotation = types.Door.destRotation(data.door)
    local forward = destRotation:apply(util.vector3(0.0, 1.0, 0.0)):normalize() * spawnDist

    local spot = safeLocation(destPosition + forward, destPosition, spawnDist)
    if spot then
        spawn(destCell, spot)
    else
        settings.debugPrint("failed to find safe spot to spawn")
    end
end

local function onStartDialogue(data)
    interfaces.UI.addMode("Dialogue", data)
end

local function onLoad(data)
    if data then
        persist = data
    end
end
local function onSave()
    return persist
end

return {
    eventHandlers = {
        [MOD_NAME .. "onCollectorDespawn"] = onCollectorDespawn,
        [MOD_NAME .. "onExitingInterior"] = onExitingInterior,
        [MOD_NAME .. "onStartDialogue"] = onStartDialogue,
        UiModeChanged = UiModeChanged,
    },
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
        onQuestUpdate = onQuestUpdate,
    },
}
