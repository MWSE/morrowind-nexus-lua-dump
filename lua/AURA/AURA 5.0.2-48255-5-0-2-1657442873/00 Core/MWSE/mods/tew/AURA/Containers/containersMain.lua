local config = require("tew.AURA.config")
local common = require("tew.AURA.common")
local tewLib = require("tew.tewLib.tewLib")
local findWholeWords = tewLib.findWholeWords

local flag = 0
local containersData = require("tew.AURA.Containers.containersData")

local debugLog = common.debugLog

local containers = {
    ["open"] = {},
    ["close"] ={}
}

local function buildContainerSounds()
    mwse.log("\n")
	debugLog("|---------------------- Creating container sound objects. ----------------------|\n")

    for cont, filepath in pairs(containersData["open"]) do
        local sound = tes3.createObject{
            id = "tew_"..cont.."_o",
            objectType = tes3.objectType.sound,
            filename = filepath,
        }
        containers["open"][cont] = sound
        debugLog("Adding container open file: "..sound.id)
    end

    for cont, filepath in pairs(containersData["close"]) do
        local sound = tes3.createObject{
            id = "tew_"..cont.."_c",
            objectType = tes3.objectType.sound,
            filename = filepath,
        }
        containers["close"][cont] = sound
        debugLog("Adding container close file: "..sound.id)
    end
end

local function getContainerSound(name, type)
    debugLog("Fetching sound for container: "..name)
    for cont, sound in pairs(containers[type]) do
        if name == cont or findWholeWords(name, cont) then
            return cont, sound
        end
    end
end

local function getVolume(containerType)
    if not containerType then return 1.0 end
    local vol
    for k, v in pairs(containersData["volume"]) do
        if containerType:lower() == k then
            vol=v
        end
    end
    return vol or 0.8
end

local function playOpenSound(e)
    if not (e.target.object.objectType == tes3.objectType.container) or (e.target.object.objectType == tes3.objectType.npc) then return end
    local Cvol=config.Cvol/200

    if not tes3.getLocked({reference=e.target}) then
        local containerType, sound = getContainerSound(e.target.object.name:lower(), "open")
        if sound then
            tes3.playSound{sound = sound, reference=e.target, volume=getVolume(containerType)*Cvol}
            debugLog("Playing container opening sound.")
        end
    end
end

local function playCloseSound(e)
    if not (e.reference.object.objectType == tes3.objectType.container) or (e.reference.object.objectType == tes3.objectType.npc)  then return end
    local Cvol=config.Cvol/200
    if flag == 1 then return end
   
    local containerType, sound = getContainerSound(e.reference.object.name:lower(), "close")

    if sound then
        tes3.removeSound{reference=e.reference}
        tes3.playSound{sound = sound, reference=e.reference, volume=getVolume(containerType)*Cvol}
        debugLog("Playing container closing sound.")
        flag=1
    end

    timer.start{type=timer.real, duration=1.6, callback=function()
        flag=0
    end}
end

debugLog("Containers module initialised.")

buildContainerSounds()
event.register("activate", playOpenSound)
event.register("containerClosed", playCloseSound)