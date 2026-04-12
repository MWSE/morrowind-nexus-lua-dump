local time = require("openmw_aux.time")
local world = require("openmw.world")
local storage = require("openmw.storage")

require("scripts.ItBeats.utils.consts")
require("scripts.ItBeats.utils.cellGlobal")

local sectionHeartbeat = storage.globalSection("SettingsItBeats_heartbeat")
local sectionDebug = storage.globalSection("SettingsItBeats_debug")

local playerData = {}
local heartIsDead = false

local function hearbeatOffset(player)
    player:sendEvent("ItBeats_PlaySFX")
end

local callback = time.registerTimerCallback("Heartbeat", hearbeatOffset)

local function doHeartbeat()
    local offset = math.random(0, sectionHeartbeat:get("maxOffset") * 100) / 100

    for _, data in pairs(playerData) do
        local currCell = data.player.cell

        if currCell.id ~= data.lastCell.id then
            data.lastCell = currCell
            if data.lastCell.isExterior then
                data.region = currCell.region
            elseif IsInteriorInRMR(data.lastCell) then
                data.region = RedMountainRegion
            else
                data.region = "Don't know, don't care"
            end
        end

        if InteriorBlacklist[data.lastCell.id] then return end

        if data.region == RedMountainRegion
            or InteriorWhitelist[data.lastCell.id]
            or sectionDebug:get("ignoreRegionRequirement")
        then
            time.newSimulationTimer(offset, callback, data.player)
        end
    end
end

local stopTimer
if not heartIsDead or sectionDebug:get("ignoreQuestRequirement") then
    stopTimer = time.runRepeatedly(
        doHeartbeat,
        sectionHeartbeat:get("tempo"),
        { type = time.SimulationTime }
    )
end

local function heartDied()
    heartIsDead = true
    if stopTimer and not sectionDebug:get("ignoreQuestRequirement") then
        stopTimer()
    end
end

local function onPlayerAdded(player)
    local cell = player.cell
    -- yeah yeah, we get it, chargen
    if not cell then return end

    playerData[player.id] = {
        player = player,
        lastCell = cell,
        region = cell.region,
    }

    if not cell.region and IsInteriorInRMR(cell) then
        playerData[player.id].region = RedMountainRegion
    end
end

local function onSave()
    return {
        heartIsDead = heartIsDead
    }
end

local function onLoad(saveData)
    if saveData then
        heartIsDead = saveData.heartIsDead
    else
        for _, player in ipairs(world.players) do
            local quest = player.type.quests(player)[HeartQuest.id]
            ---@diagnostic disable-next-line: undefined-field
            if quest and quest.stage >= HeartQuest.stage then
                heartIsDead = true
                return
            end
        end
        heartIsDead = false
    end
end

-- idiot-proof solution
for _, player in ipairs(world.players) do
    onPlayerAdded(player)
end

return {
    engineHandlers = {
        onPlayerAdded = onPlayerAdded,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        ItBeats_HeartIsDead = heartDied,
    }
}
