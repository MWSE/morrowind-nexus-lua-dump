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
self.type.addTopic(self,"bank")
local factionBanks = {}
local voucherData = {}
local function removeItem(obj, itemId, count)
    core.sendGlobalEvent("removeItemEvent_FB", { obj = obj, itemId = itemId, count = count })
end
local function addItem(obj, itemId, count)
    core.sendGlobalEvent("addItemEvent_FB", { obj = obj, itemId = itemId, count = count })
end
local function getPlayerGold()
    local count = types.Container.content(self):countOf("gold_001")
    return count
end

local function createBank(factionId)
    factionBanks[factionId] = {
        balance = 0
    }
end
local function getBankBalance(factionId)
    if factionBanks[factionId] then
        return factionBanks[factionId].balance
    else
        createBank(factionId)
    end
    return 0
end
local function depositToBank(factionId, amount, keepGold)
    local playerGold = getPlayerGold()
    if not keepGold and playerGold < amount then
        amount = playerGold
        if amount == 0 then
            return
        end
    end
    if not factionBanks[factionId] then
        createBank(factionId)
    end
    local bankAmount = getBankBalance(factionId)
    factionBanks[factionId].balance = bankAmount + amount
    if not keepGold then
        removeItem(self, "gold_001", amount)
        playerGold = playerGold - amount
    end
    return playerGold
end
local function getCarriedVoucherBalance(factionId)
        local inventory = types.Actor.inventory(self):getAll(types.Book)
    local itemsToKill = {}
    local totalAmount = 0
    for id, x in ipairs(inventory) do
        if voucherData[x.recordId] then
            totalAmount = totalAmount + voucherData[x.recordId]
        end
    end
    --(factionId,totalAmount)
    return totalAmount
end
local function depositVouchers(factionId)
    local inventory = types.Actor.inventory(self):getAll(types.Book)
    local itemsToKill = {}
    local totalAmount = 0
    for id, x in ipairs(inventory) do
        if voucherData[x.recordId] then
            table.insert(itemsToKill, x)
            totalAmount = totalAmount + voucherData[x.recordId]
            voucherData[x.recordId] = nil
        end
    end
   -- print(factionId,totalAmount)
    depositToBank(factionId, totalAmount,true)
    core.sendGlobalEvent("removeVouchers", itemsToKill)
    return totalAmount
end
local function reduceBalance(factionId,amount)
    
    factionBanks[factionId].balance = factionBanks[factionId].balance - amount
end
local function withdrawFromBank(factionId, amount, toVoucher)
    if not factionBanks[factionId] then
        createBank(factionId)
    end
    local playerGold = getPlayerGold()
    local bankAmount = getBankBalance(factionId)
    if bankAmount < amount then
        amount = bankAmount
        if amount == 0 then
            return
        end
    end
    if toVoucher and amount > 0 then
        core.sendGlobalEvent("createVoucher", { amount = amount })
    else
        playerGold = playerGold + amount
        addItem(self, "gold_001", amount)
    end
    reduceBalance(factionId,amount)
    return playerGold
end
local function storeVoucherData(data)
    local adjustedAmount = data.adjustedAmount
    local id = data.itemId
    voucherData[id] = adjustedAmount
end
local  function onLoad(data)
    if not data then return end
    factionBanks = data.factionBanks
    voucherData = data.voucherData or {}
end
local function onSave()
    return { factionBanks = factionBanks, voucherData = voucherData }
end
return {
    engineHandlers = {
        onSave = onSave,
        onLoad =onLoad
    },
    eventHandlers = {
        openDepositBox = function(cont)
            I.UI.setMode("Container", { target = cont })
        end,
        storeVoucherData = storeVoucherData,

    },
    interfaceName = "FactionBankData",
    interface = {
        getCarriedVoucherBalance = getCarriedVoucherBalance,
        withdrawFromBank = withdrawFromBank,
        reduceBalance = reduceBalance,
        depositToBank = depositToBank,
        getBankBalance = getBankBalance,
        depositVouchers = depositVouchers,
        onSave = onSave,
        onLoad = onLoad,
    }
}
