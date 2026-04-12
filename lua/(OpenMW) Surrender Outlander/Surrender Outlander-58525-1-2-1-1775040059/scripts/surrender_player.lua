local core    = require("openmw.core")
local self    = require("openmw.self")
local types   = require("openmw.types")
local nearby  = require("openmw.nearby")
local ui      = require("openmw.ui")
local storage = require("openmw.storage")
local async   = require("openmw.async")
local input   = require("openmw.input")

local shared           = require("scripts.surrender_shared")
local BRIBEABLE_CLASSES = shared.BRIBEABLE_CLASSES
local EXEMPT_NPCS      = shared.EXEMPT_NPCS
local GOLD_IDS         = shared.GOLD_IDS
local DEFAULTS         = shared.DEFAULTS

local section = storage.playerSection("SettingsSurrender")

local snapA = {}
local snapB = {}
local currentSnap = snapA
local prevSnap
local settingsDirty = false

local cachedSettings = {
    MOD_ENABLED  = DEFAULTS.MOD_ENABLED,
    MIN_GOLD     = DEFAULTS.MIN_GOLD,
    CEASEFIRE       = DEFAULTS.CEASEFIRE,
    BRIBE_RADIUS    = DEFAULTS.BRIBE_RADIUS,
    CLASS_CEASEFIRE = DEFAULTS.CLASS_CEASEFIRE,
    THROW_GOLD_AMOUNT = DEFAULTS.THROW_GOLD_AMOUNT,
}

local function get(key)
    local val = section:get(key)
    if val ~= nil then return val end
    return DEFAULTS[key]
end

local function refreshCache()
    for k in pairs(cachedSettings) do
        cachedSettings[k] = get(k)
    end
end

section:subscribe(async:callback(function()
    settingsDirty = true
end))

local function fillSnapshot(t)
    for k in pairs(t) do t[k] = nil end
    local inv = types.Actor.inventory(self)
    if not inv then return end
    for _, item in ipairs(inv:getAll()) do
        t[item.id] = { recordId = string.lower(item.recordId), count = item.count }
    end
end

local function swapAndDiff()
    if currentSnap == snapA then
        prevSnap    = snapA
        currentSnap = snapB
    else
        prevSnap    = snapB
        currentSnap = snapA
    end
    fillSnapshot(currentSnap)
end

local function goldRecordForAmount(amount)
    if amount >= 100 then return "gold_100" end
    if amount >= 25  then return "gold_025" end
    if amount >= 10  then return "gold_010" end
    if amount >= 5   then return "gold_005" end
    return "gold_001"
end

local function isBribeable(actor)
    if not types.NPC.objectIsInstance(actor) then return false end
    if types.Actor.isDead(actor) then return false end
    local recordId = actor.recordId:lower()
    if EXEMPT_NPCS[recordId] then return false end
    local record = types.NPC.record(actor)
    if not record or not record.class then return false end
    return BRIBEABLE_CLASSES[record.class:lower()] == true
end

local function looksHostile(actor)
    local stance = types.Actor.getStance(actor)
    return stance == 1 or stance == 2
end

local function findBribeableNPCs()
    local result = {}
    local playerPos = self.position
    for _, actor in ipairs(nearby.actors) do
        if actor ~= self.object
           and isBribeable(actor)
           and looksHostile(actor)
           and (actor.position - playerPos):length() <= cachedSettings.BRIBE_RADIUS then
            table.insert(result, actor)
        end
    end
    return result
end

local function findDroppedGold(amount)
    local worldId = goldRecordForAmount(amount)
    for _, item in ipairs(nearby.items) do
        if string.lower(item.recordId) == worldId
           and item.count == amount
           and (item.position - self.position):length() <= cachedSettings.BRIBE_RADIUS then
            return item
        end
    end
    return nil
end

local function tryBribe()
    if not cachedSettings.MOD_ENABLED then return end
    if types.Actor.getStance(self.object) ~= 0 then return end

    swapAndDiff()
    if not prevSnap then return end

    local droppedGold = 0
    for itemId, prev in pairs(prevSnap) do
        if GOLD_IDS[prev.recordId] then
            local curr    = currentSnap[itemId]
            local dropped = prev.count - (curr and curr.count or 0)
            if dropped > 0 then
                droppedGold = droppedGold + dropped
            end
        end
    end

    if droppedGold < cachedSettings.MIN_GOLD then return end

    local npcs = findBribeableNPCs()
    if #npcs == 0 then return end

    local goldItem = findDroppedGold(droppedGold)
    if not goldItem then return end

    local overpay   = droppedGold - cachedSettings.MIN_GOLD
    local bonus     = overpay / cachedSettings.MIN_GOLD
    local ceasefire = math.floor((cachedSettings.CEASEFIRE + bonus) * 10 + 0.5) / 10

    core.sendGlobalEvent("Surrender_Bribe", {
        goldItem       = goldItem,
        npcs           = npcs,
        ceasefire      = ceasefire,
        classCeasefire = cachedSettings.CLASS_CEASEFIRE,
        player         = self.object,
    })
end

-- standalone bribe attempt for quick-throw, bypasses snapshot diff
local function tryBribeDirect(amount)
    if not cachedSettings.MOD_ENABLED then return end
    if types.Actor.getStance(self.object) ~= 0 then return end
    if amount < cachedSettings.MIN_GOLD then return end

    local npcs = findBribeableNPCs()
    if #npcs == 0 then return end

    local goldItem = findDroppedGold(amount)
    if not goldItem then return end

    local overpay   = amount - cachedSettings.MIN_GOLD
    local bonus     = overpay / cachedSettings.MIN_GOLD
    local ceasefire = math.floor((cachedSettings.CEASEFIRE + bonus) * 10 + 0.5) / 10

    core.sendGlobalEvent("Surrender_Bribe", {
        goldItem       = goldItem,
        npcs           = npcs,
        ceasefire      = ceasefire,
        classCeasefire = cachedSettings.CLASS_CEASEFIRE,
        player         = self.object,
    })
end

local function throwGold()
    if not cachedSettings.MOD_ENABLED then return end
    if types.Actor.getStance(self.object) ~= 0 then return end

    local amount = cachedSettings.THROW_GOLD_AMOUNT

    local inv = types.Actor.inventory(self)
    local totalGold = 0
    for _, item in ipairs(inv:getAll()) do
        if shared.GOLD_IDS[item.recordId:lower()] then
            totalGold = totalGold + item.count
        end
    end
    if totalGold < amount then return end

    local yaw = self.object.rotation:getAnglesZYX()
    core.sendGlobalEvent('Surrender_ThrowGold', {
        player = self.object,
        amount = amount,
        yaw    = yaw,
    })
end

local triggerRegistered = false

local function registerTrigger()
    if triggerRegistered then return end
    triggerRegistered = true
    input.registerTriggerHandler('SurrenderThrowGold', async:callback(throwGold))
end

return {
    engineHandlers = {
        onInit = function()
            refreshCache()
            fillSnapshot(currentSnap)
            registerTrigger()
        end,

        onLoad = function()
            refreshCache()
            fillSnapshot(currentSnap)
            registerTrigger()
        end,

        onFrame = function(dt)
            if settingsDirty then
                settingsDirty = false
                refreshCache()
            end
        end,
    },

    eventHandlers = {
        UiModeChanged = function(data)
            if data.oldMode == nil and data.newMode == "Interface" then
                fillSnapshot(currentSnap)
            end
            if data.oldMode == "Interface" and data.newMode == nil then
                tryBribe()
            end
        end,

        SurrenderMessage = function(data)
            if data and data.message then
                ui.showMessage(data.message)
            end
        end,

        Surrender_TryBribeFromThrow = function(data)
            async:newUnsavableSimulationTimer(0.05, function()
                fillSnapshot(currentSnap)
                tryBribeDirect(data.amount)
            end)
        end,
    },
}