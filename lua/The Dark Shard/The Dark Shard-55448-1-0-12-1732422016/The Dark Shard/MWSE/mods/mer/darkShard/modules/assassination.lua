local common = require("mer.darkShard.common")
local logger = common.createLogger("Assassination")
local assassinId = "afq_cat_assassin"

local ASSASSIN_WAIT_TIME = 20

local function inWilderness()
    return tes3.player.cell.restingIsIllegal ~= true
end

local function hasTriggered()
    return common.config.persistent.assassinationAttempted == true
end

local function setTriggered()
    common.config.persistent.assassinationAttempted = true
end

local function triggerAssassination()
    logger:debug("Triggering assassination")

    local distanceBehind = 128

    -- Get the player's forward direction vector
    local forwardVector = tes3.getPlayerEyeVector()
    -- Invert it to get the backward direction
    local backwardVector = -forwardVector
    -- Calculate the new position
    local position = tes3.player.position:copy() + backwardVector * distanceBehind

    local assassin = tes3.createReference{
        object = assassinId,
        position = position,
        orientation = tes3.player.orientation:copy(),
        cell = tes3.player.cell
    }
    local safeRef = tes3.makeSafeObjectHandle(assassin)
    timer.delayOneFrame(function()
        if safeRef and safeRef:valid() then
            assassin.mobile.fight = 100
            assassin.mobile.flee = 0
            assassin.mobile:startCombat(tes3.player.mobile)
            tes3.showDialogueMenu{
                reference = assassin,
            }
        end
    end)
    setTriggered()
end

local function journalUpdated()
    return tes3.getJournalIndex{ id = "afq_cult_alchi" } >= 100
        or tes3.getJournalIndex{ id = "afq_cult_apoth" } >= 100
end

event.register("loaded", function()
    timer.start{
        duration = ASSASSIN_WAIT_TIME,
        type = timer.simulate,
        iterations = -1,
        callback = function()
            logger:debug("Checking for assassination")
            if journalUpdated() and inWilderness() and not hasTriggered() then
                triggerAssassination()
            end
        end
    }
end)