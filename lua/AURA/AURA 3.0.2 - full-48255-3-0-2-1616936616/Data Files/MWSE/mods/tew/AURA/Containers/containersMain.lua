local modversion = require("tew\\AURA\\version")
local version = modversion.version
local config = require("tew\\AURA\\config")
local debugLogOn=config.debugLogOn

local tewLib = require("tew\\tewLib\\tewLib")
local findWholeWords = tewLib.findWholeWords

local path = ""
local flag = 0
local containersData = require("tew\\AURA\\Containers\\containersData")

local function debugLog(string)
    if debugLogOn then
       mwse.log("[AURA "..version.."] C: "..string)
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
    if not e.target.object.objectType == tes3.objectType.container then return end
    local Cvol=config.Cvol/200
    local containerType
    if not tes3.getLocked({reference=e.target}) then
        for cont, filepath in pairs(containersData["open"]) do
            if e.target.object.name:lower() == cont then
                containerType=cont
                path=filepath
                break
            end
        end
        if path == "" then
            for cont, filepath in pairs(containersData["open"]) do
                if findWholeWords(e.target.object.name:lower(), cont) then
                    containerType=cont
                    path=filepath
                    break
                end
            end
        end
        if path ~= "" then
            tes3.playSound{soundPath=path, reference=e.target, volume=getVolume(containerType)*Cvol}
            debugLog("Playing container opening sound.")
        end
        path=""
    end
end

local function playCloseSound(e)
    local Cvol=config.Cvol/200
    if flag == 1 then return end
    local containerType
    for cont, filepath in pairs(containersData["close"]) do
        if e.reference.object.name:lower() == cont then
            path=filepath
            containerType=cont
            break
        end
    end
    if path == "" then
        for cont, filepath in pairs(containersData["close"]) do
            if findWholeWords(e.reference.object.name:lower(), cont) then
                path=filepath
                containerType=cont
                break
            end
        end
    end
    if path ~= "" then
        tes3.removeSound{reference=e.reference}
        tes3.playSound{soundPath=path, reference=e.reference, volume=getVolume(containerType)*Cvol}
        debugLog("Playing container closing sound.")
        flag=1
    end
    path=""
    timer.start{type=timer.real, duration=1.6, callback=function()
        flag=0
    end}
end


debugLog("Containers module initialised.")

event.register("activate", playOpenSound)
event.register("containerClosed", playCloseSound)