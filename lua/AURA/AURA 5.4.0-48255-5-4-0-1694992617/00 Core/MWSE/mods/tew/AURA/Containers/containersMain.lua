local config = require("tew.AURA.config")
local common = require("tew.AURA.common")

local flag = 0
local containersData = require("tew.AURA.Containers.containersData")

local debugLog = common.debugLog

local function buildContainerSounds()
    debugLog("\n")
    debugLog("|---------------------- Creating container sound objects. ----------------------|\n")

    for containerName, data in pairs(containersData) do
        local soundOpen = tes3.createObject{
            id = "tew_" .. containerName .. "_o",
            objectType = tes3.objectType.sound,
            filename = data.open,
        }
        data.openSoundObj = soundOpen
        debugLog("Adding container open file: " .. soundOpen.id)

        local soundClose = tes3.createObject{
            id = "tew_" .. containerName .. "_c",
            objectType = tes3.objectType.sound,
            filename = data.close,
        }
        data.closeSoundObj = soundClose
        debugLog("Adding container close file: " .. soundClose.id)
    end
end

local function getContainerData(id, action)
    debugLog("Fetching sound for container: " .. id)
    local results = {}
    for _, data in pairs(containersData) do
        local match = common.getMatch(data.idPatterns, id)
        if match then
            table.insert(results, {
                matchedPattern = match,
                sound = (action == "open") and data.openSoundObj or data.closeSoundObj,
                volume = data.volume,
            })
        end
    end
    -- Best result is that which matches more characters inside passed id string --
    table.sort(results, function(a, b) return #a.matchedPattern > #b.matchedPattern end)
    return results[1] or results
end

local function playOpenSound(e)
    if not (e.target.object.objectType == tes3.objectType.container) or (e.target.object.objectType == tes3.objectType.npc) then return end

    if not tes3.getLocked({ reference = e.target }) then
        local Cvol = config.volumes.misc.Cvol / 100
        local data = getContainerData(e.target.object.id:lower(), "open")
        local sound = data.sound
        local volume = (data.volume or 0.8) * Cvol
        if sound then
            debugLog("Got cont name: " .. tostring(e.target.object.name))
            debugLog("Got sound: " .. sound.id)
            debugLog("Playing container opening sound. Vol: " .. volume)
            tes3.playSound { sound = sound, reference = e.target, volume = volume }
        end
    end
end

local function playCloseSound(e)
    if not e.reference then return end
    if not (e.reference.object.objectType == tes3.objectType.container) or (e.reference.object.objectType == tes3.objectType.npc) then return end
    if flag == 1 then return end

    local Cvol = config.volumes.misc.Cvol / 100
    local data = getContainerData(e.reference.object.id:lower(), "close")
    local sound = data.sound
    local volume = (data.volume or 0.8) * Cvol

    if sound then
        tes3.removeSound { reference = e.reference }
        debugLog("Got cont name: " .. tostring(e.reference.object.name))
        debugLog("Got sound: " .. sound.id)
        debugLog("Playing container closing sound. Vol: " .. volume)
        tes3.playSound { sound = sound, reference = e.reference, volume = volume }
        flag = 1
    end

    timer.start { type = timer.real, duration = 1.6, callback = function()
        flag = 0
    end }
end

buildContainerSounds()
event.register("activate", playOpenSound)
event.register("containerClosed", playCloseSound)
debugLog("Containers module initialised.")
