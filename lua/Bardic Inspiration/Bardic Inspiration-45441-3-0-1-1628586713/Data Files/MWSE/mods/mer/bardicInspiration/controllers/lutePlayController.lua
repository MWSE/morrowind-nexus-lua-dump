--[[
    Checks whether the player has readied a lute under
    the right conditions, and triggers a performance,
    or else shows a message saying which conditions aren't met.
]]
local common = require("mer.bardicInspiration.common")
local performances = require("mer.bardicInspiration.data.performances")

local messages = require("mer.bardicInspiration.messages.messages")
local songController = require("mer.bardicInspiration.controllers.songController")

local function inTavern()
    for ref in tes3.player.cell:iterateReferences(tes3.objectType.npc) do
        if common.isInnkeeper(ref) then return true end
    end
    return false
end

local function isIndoors()
    return tes3.mobilePlayer.cell.isInterior
        and not tes3.mobilePlayer.cell.behavesAsExterior
end

local function isNight()
    local startHour = 18
    local gameHour = tes3.worldController.hour.value
    return gameHour > startHour
end

local function hasGig()
    return performances.getCurrent() ~= nil
end

local function alreadyPlayed()
    local currentPerformance = performances.getCurrent()
    return currentPerformance and currentPerformance.state == performances.STATE.PLAYED
end

local function doSkip()
    local currentPerformance = performances.getCurrent()
    return currentPerformance and currentPerformance.state == performances.STATE.SKIP
end

local function onReadyLute(e)
    if not common.config.enabled then return end
    if not e.weaponStack then return end
    if not (e.reference == tes3.player) then return end
    if not common.isLute(e.weaponStack.object) then return end
    if not isIndoors() then
        --Play while travelling
        songController.playRandom()
        return
    end

    if common.data.songPlaying then 
        --already playing!
        return 
    end
    if not inTavern() then
        tes3.messageBox(messages.notTavern)
        return
    end

    if not hasGig() then
        tes3.messageBox(messages.noGigScheduled)
        return
    end

    if not isNight() then
        tes3.messageBox(messages.notNightTime)
        return
    end

    if alreadyPlayed() then
        tes3.messageBox(messages.alreadyPlayed)
        return
    end

    if doSkip() then
        return
    end 

    --Perform at tavern
    songController.showMenu()
end

event.register("weaponReadied", onReadyLute)