
local AddictionService = require('mer.skoomaesthesia.services.AddictionService')
local config = require('mer.skoomaesthesia.config')
local Util = require('mer.skoomaesthesia.util.Util')

local function checkAddiction()
    Util.log:trace("AddictionService: checkAddiction()")
    if not AddictionService.getIsAddicted() then return end
    local lastSmoked = config.persistent.lastSmoked
    if not lastSmoked then return end
    local now = tes3.getSimulationTimestamp()
    local timeAddicted = now - lastSmoked
    Util.log:trace("Last Smoked: %s", lastSmoked)
    Util.log:trace("Now: %s", now)
    Util.log:trace("time Addicted: %s", timeAddicted)
    if timeAddicted < config.static.hoursToWithdrawal then
        Util.log:trace("checkAddiction() removing withdrawals")
        --smoked recently
        AddictionService.removeWithdrawals()
    elseif timeAddicted < config.static.hoursToRecovery then
        Util.log:trace("checkAddiction() add withdrawals if needed")
        AddictionService.addWithdrawals()
    else
        Util.log:trace("checkAddiction() recover")
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