local AddictionService = {}
local SpellService = require('mer.skoomaesthesia.services.SpellService')
local withdrawalStates = require('mer.skoomaesthesia.withdrawalStates')
local config = require('mer.skoomaesthesia.config')
local Util = require('mer.skoomaesthesia.util.Util')

local function becomeAddicted()
    Util.log:trace("becomeAddicted()")
    config.persistent.isAddicted = true
    tes3.messageBox{
        message = "You have become addicted to skooma.",
        buttons = { tes3.findGMST(tes3.gmst.sOK).value }
    }
end 

local function tryGetAddicted()
    if AddictionService.getIsAddicted() then return end
    Util.log:debug("AddictionService: tryGetAddicted()")
    local baseChance = config.static.baseAddictionChance / 100
    local willpower = tes3.mobilePlayer.willpower.current
    local minMulti = config.static.minAddictionMulti
    local maxMulti = config.static.maxAddictionMulti
    local willpowerEffect = math.remap(willpower, 0, 100, maxMulti, minMulti)
    willpowerEffect = math.clamp(willpowerEffect, minMulti, maxMulti)
    local thisChance = baseChance * willpowerEffect
    local diceroll = math.random()
    Util.log:debug("diceroll: %.2f, needed: %.2f", diceroll, thisChance)
    if diceroll < thisChance then
        Util.log:debug("Passed, getting addicted")
        becomeAddicted()
    end
end

--public functions
function AddictionService.smoke()
    Util.log:trace("AddictionService: smoke()")
    AddictionService.resetSmokedTimer()
    tryGetAddicted()
end

function AddictionService.resetSmokedTimer()
    Util.log:trace("AddictionService: resetSmokedTimer()")
    config.persistent.lastSmoked = tes3.getSimulationTimestamp()
end

function AddictionService.hasWithdrawals()
    local hasWithdrawals = false
    for _, state in pairs(withdrawalStates) do
        local spell = SpellService.getSpellForState(state)
        if spell and tes3.player.object.spells:contains(spell) then
            hasWithdrawals = true
        end
    end
    return hasWithdrawals
end

function AddictionService.addWithdrawals()
    if AddictionService.getIsAddicted() and not AddictionService.hasWithdrawals() then
        Util.log:trace("adding Withdrawals")
        local spell = SpellService.getSpellForState(withdrawalStates.withdraw_mild)
        mwscript.addSpell({ reference = tes3.player, spell = spell })
        tes3.messageBox({
            message = "You are suffering from skooma withdrawals.",
            --buttons = { tes3.findGMST(tes3.gmst.sOK).value }
        })
    end
end

function AddictionService.removeWithdrawals()
    if AddictionService.hasWithdrawals() then
        Util.log:trace("removing Withdrawals")
        local spell = SpellService.getSpellForState(withdrawalStates.withdraw_mild)
        mwscript.removeSpell({ reference = tes3.player, spell = spell })
    end
end


function AddictionService.recover()
    Util.log:trace("recover()")
    AddictionService.removeWithdrawals()
    config.persistent.isAddicted = false
    tes3.messageBox{
        message = "You are no longer addicted to skooma.",
        --buttons = { tes3.findGMST(tes3.gmst.sOK).value }
    }
end



function AddictionService.getIsAddicted()
    return config.persistent.isAddicted == true
end





return AddictionService