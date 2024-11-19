local common = require("mer.darkShard.common")
local logger = common.createLogger("dialog")

---@param e infoFilterEventData
event.register("infoFilter", function(e)
    local now = tes3.getSimulationTimestamp()
    local unlockTime = common.config.persistent.phenomenonDialogUnlockTime
    if not unlockTime then return end
    if now < unlockTime then
        logger:debug("Blocking dialog")
        e.passes = false
    end
end, { filter = tes3.getDialogueInfo({ id = "11468287051252816678", dialogue = "Greeting 1"}) })


local function startPhenomenon25HourWait(hours)
    logger:debug("Starting 25 hour wait")
    hours = hours or 25
    common.config.persistent.phenomenonDialogUnlockTime = tes3.getSimulationTimestamp() + hours
end

---@param e dialogueEnvironmentCreatedEventData
event.register(tes3.event.dialogueEnvironmentCreated, function(e)
    ---@class mwseDialogueEnvironment
    local env = e.environment
    env.DarkShard = {
        startPhenomenon25HourWait = startPhenomenon25HourWait
    }
end)
