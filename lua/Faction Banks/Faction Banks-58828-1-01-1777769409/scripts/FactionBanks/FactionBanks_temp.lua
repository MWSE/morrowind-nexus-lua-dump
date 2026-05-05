local ui = require("openmw.ui")
local I = require("openmw.interfaces")
--local layers = require("scripts.ControllerInterface.ci_layers")
local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local types = require("openmw.types")
local ambient = require('openmw.ambient')
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local Camera = require("openmw.camera")
local camera = require("openmw.camera")
local input = require("openmw.input")
local async = require("openmw.async")
local storage = require("openmw.storage")
local Player = require('openmw.types').Player


local originalBankAmount = 0
local originalPlayerGold = 0
local faction
local function enterTempMode(factionId)
    faction = factionId
    originalBankAmount = I.FactionBankData.getBankBalance(factionId)
    originalPlayerGold = types.Container.content(self):countOf("gold_001")
    I.FactionBankData.withdrawFromBank(factionId, originalBankAmount)
end

local function exitTempMode()
    local PlayerGold = types.Container.content(self):countOf("gold_001")
    local amountToDeposit = originalBankAmount
    if PlayerGold <= originalPlayerGold then --if we have less than we started with, we keep that amount
        amountToDeposit = 0
    elseif PlayerGold > originalPlayerGold then
        amountToDeposit = PlayerGold - originalPlayerGold
    end
    if self.controls.sneak then --if we're sneaking, we don't deposit, we just exit temp mode
        return PlayerGold
    end
    print(amountToDeposit,"depo")
    if faction then
        I.FactionBankData.depositToBank(faction, amountToDeposit)
        faction = nil
        originalBankAmount = 0
    end
    return PlayerGold - amountToDeposit
end

return {
    interfaceName = "FactionBankTemp",
    interface = {
        exitTempMode = exitTempMode,
        enterTempMode = enterTempMode
    },
    eventHandlers = {
        UiModeChanged = function(data)
            if not data.newMode and faction then
                exitTempMode()
            end
        end,
        EnterTempMode = function(data)
            local NPCFaction = data.faction or types.NPC.getFactions(data.actor)[1]
            enterTempMode(NPCFaction)
        end
    }
}
