--[[
    Checks whether the player has readied a lute under
    the right conditions, and triggers a performance,
    or else shows a message saying which conditions aren't met.
]]
local common = require("mer.bardicInspiration.common")
local performances = require("mer.bardicInspiration.data.performances")

local messages = require("mer.bardicInspiration.messages.messages")
local songController = require("mer.bardicInspiration.controllers.songController")

---@class BardicInspiration.GigCondition
---@field name string The name of the condition
---@field check fun():boolean The function that checks the condition
---@field message string|nil The message to show if the condition fails

local gigConditions = {
    {
        name = "notCurrentlyPlaying",
        check = function()
            return common.data.songPlaying == nil
        end,
        message = nil
    },
    {
        name = "inTavern",
        check = function()
            for ref in tes3.player.cell:iterateReferences(tes3.objectType.npc) do
                if common.isInnkeeper(ref) then return true end
            end
            return false
        end,
        message = messages.notTavern,
    },
    {
        name = "hasGig",
        check = function()
            return performances.getCurrent() ~= nil
        end,
        message = messages.noGigScheduled,
    },
    {
        name = "isNight",
        check = function()
            local startHour = 18
            local gameHour = tes3.worldController.hour.value
            return gameHour > startHour
        end,
        message = messages.notNightTime,
    },
    {
        name = "hasntAlreadyPlayed",
        check = function()
            local currentPerformance = performances.getCurrent()
            return not (currentPerformance and currentPerformance.state == performances.STATE.PLAYED)
        end,
        message = messages.alreadyPlayed,
    },
    {
        name = "noSkipState",
        check = function()
            local currentPerformance = performances.getCurrent()
            return not(currentPerformance and currentPerformance.state == performances.STATE.SKIP)
        end,
        message = nil,
    },
}

local function isIndoors()
    return tes3.mobilePlayer.cell.isInterior
        and not tes3.mobilePlayer.cell.behavesAsExterior
end

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