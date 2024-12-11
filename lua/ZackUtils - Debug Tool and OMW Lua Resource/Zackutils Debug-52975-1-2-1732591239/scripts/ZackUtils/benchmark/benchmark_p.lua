local core = require("openmw.core")
local storage = require("openmw.storage")
local messageWin = require("scripts.ZackUtils.MessageWin")

local playerSettings = storage.globalSection("SettingsDebugMode")
local createdWin = false
local function getFrameRate(dt)
    return 1 / dt
end
local timeLimit = 0.1--only update after this amount of time
local timePassed = 0
local frameHistory = {}
local function getAverageFrameRate(duration)
    local currentTime = core.getRealTime()
    local totalFrameRate = 0
    local totalFrames = 0
    for i = #frameHistory, 1, -1 do
        local frame = frameHistory[i]
        if currentTime - frame.time > duration then
            break
        end
        totalFrameRate = totalFrameRate + frame.frameRate
        totalFrames = totalFrames + 1
    end
    return totalFrameRate / totalFrames
end
local function onUpdate(dt)
    timePassed = timePassed + dt
    if timePassed < timeLimit or ( not playerSettings:get("AllowBuildingAnywhere") and not createdWin ) then
        return
    elseif  not playerSettings:get("AllowBuildingAnywhere") and createdWin then
        messageWin:destroy()
        createdWin = false
        return
    end
    timePassed = 0
    local frameLength = core.getRealFrameDuration()--dt 
    local frameRate = getFrameRate(frameLength)
    table.insert(frameHistory, {frameRate = frameRate, frameLength = frameLength, time = core.getRealTime()})

    print("Frame rate:", frameRate)
    messageWin:updateMessageWin{"Frame rate:" .. tostring(math.floor(frameRate)), "Average Frame Rate:" .. tostring(math.floor(getAverageFrameRate(10)))}
    createdWin = true
end
return {
    engineHandlers = {
        onUpdate = onUpdate
    }
}