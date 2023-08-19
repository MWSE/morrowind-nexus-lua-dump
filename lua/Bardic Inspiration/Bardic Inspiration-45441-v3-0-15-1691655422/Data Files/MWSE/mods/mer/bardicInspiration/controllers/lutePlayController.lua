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

local function hasntAlreadyPlayed()
    local currentPerformance = performances.getCurrent()
    return not (currentPerformance and currentPerformance.state == performances.STATE.PLAYED)
end

local function noSkipState()
    local currentPerformance = performances.getCurrent()
    return not(currentPerformance and currentPerformance.state == performances.STATE.SKIP)
end

local function notCurrentlyPlaying()
    return common.data.songPlaying == nil
end

local gigConditions = {
    {
        name = "notCurrentlyPlaying",
        check = notCurrentlyPlaying,
        message = nil
    },
    {
        name = "inTavern",
        check = inTavern,
        message = messages.notTavern,
    },
    {
        name = "hasGig",
        check = hasGig,
        message = messages.noGigScheduled,
    },
    {
        name = "isNight",
        check = isNight,
        message = messages.notNightTime,
    },
    {
        name = "hasntAlreadyPlayed",
        check = hasntAlreadyPlayed,
        message = messages.alreadyPlayed,
    },
    {
        name = "noSkipState",
        check = noSkipState,
        message = nil,
    },
}


---@param e weaponReadiedEventData
local function onReadyLute(e)
    if not common.config.enabled then return end
    if not e.weaponStack then return end
    if not (e.reference == tes3.player) then return end
    if not common.isLute(e.weaponStack.object, e.weaponStack.itemData) then return end

    if not isIndoors() then
        common.log:debug("Playing random")
        --Play while travelling
        songController.playRandom()
        return
    end

    for _, condition in ipairs(gigConditions) do
        if not condition.check() then
            common.log:debug("Failed check %s", condition.name)
            if condition.message then
                tes3.messageBox(condition.message)
            end
            return
        end
    end
    common.log:debug("Passed checks, opening menu")
    --Perform at tavern
    songController.showMenu()
end

event.register("weaponReadied", onReadyLute)