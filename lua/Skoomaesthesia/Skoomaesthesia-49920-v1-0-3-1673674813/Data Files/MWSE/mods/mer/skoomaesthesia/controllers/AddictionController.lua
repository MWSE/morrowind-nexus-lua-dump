
local AddictionService = require('mer.skoomaesthesia.services.AddictionService')
local common = require('mer.skoomaesthesia.common')
local logger = common.createLogger("AddictionController")
local config = require('mer.skoomaesthesia.config')

local function checkAddiction()
    logger:trace("AddictionService: checkAddiction()")
    if not AddictionService.getIsAddicted() then return end
    local lastSmoked = config.persistent.lastSmoked
    if not lastSmoked then return end
    local now = tes3.getSimulationTimestamp()
    local timeAddicted = now - lastSmoked
    logger:trace("Last Smoked: %s", lastSmoked)
    logger:trace("Now: %s", now)
    logger:trace("time Addicted: %s", timeAddicted)
    if timeAddicted < config.static.hoursToWithdrawal then
        logger:trace("checkAddiction() removing withdrawals")
        --smoked recently
        AddictionService.removeWithdrawals()
    elseif timeAddicted < config.static.hoursToRecovery then
        logger:trace("checkAddiction() add withdrawals if needed")
        AddictionService.addWithdrawals()
    else
        logger:trace("checkAddiction() recover")
        AddictionService.recover()
    end
end

event.register("loaded", function()
    timer.start{
        type = timer.simulate,
        duration = 1,
        iterations = -1,
        callback = checkAddiction
    }
end)