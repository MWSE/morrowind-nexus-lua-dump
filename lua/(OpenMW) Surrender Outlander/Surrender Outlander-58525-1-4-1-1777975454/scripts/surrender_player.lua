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
local GUARD_PATTERNS   = shared.GUARD_PATTERNS
local GUARD_CLASSES    = shared.GUARD_CLASSES
local DEFAULTS         = shared.DEFAULTS

local section = storage.playerSection("SettingsSurrender")

local snapA = {}
local snapB = {}
local currentSnap = snapA
local prevSnap

local cachedSettings = {
    MOD_ENABLED  = DEFAULTS.MOD_ENABLED,
    MIN_GOLD     = DEFAULTS.MIN_GOLD,
    CEASEFIRE       = DEFAULTS.CEASEFIRE,
    BRIBE_RADIUS    = DEFAULTS.BRIBE_RADIUS,
    CLASS_CEASEFIRE = DEFAULTS.CLASS_CEASEFIRE,
    THROW_GOLD_AMOUNT = DEFAULTS.THROW_GOLD_AMOUNT,
    USE_PHYSICS  = DEFAULTS.USE_PHYSICS,
    SURRENDER_TO_GUARDS = DEFAULTS.SURRENDER_TO_GUARDS,
    GUARD_RADIUS        = DEFAULTS.GUARD_RADIUS,
    LOG          = DEFAULTS.LOG,
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
    refreshCache()
    core.sendGlobalEvent("Surrender_SetLog", cachedSettings.LOG)
end))

local function log(...)
    if cachedSettings.LOG then
        print("[Surrender]", ...)
    end
end

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

local function isGuard(actor)
    if not types.NPC.objectIsInstance(actor) then return false end
    if types.Actor.isDead(actor) then return false end
    local rid = actor.recordId:lower()
    for _, pat in ipairs(GUARD_PATTERNS) do
        if rid:find(pat, 1, true) then return true end
    end
    local rec = types.NPC.record(actor)
    if rec and rec.class and GUARD_CLASSES[rec.class:lower()] then
        return true
    end
    return false
end

local function findNearestGuard()
    local playerPos = self.position
    local closest, closestDist = nil, math.huge
    local scanned, candidates = 0, 0
    for _, actor in ipairs(nearby.actors) do
        scanned = scanned + 1
        if actor ~= self.object and isGuard(actor) then
            candidates = candidates + 1
            local d = (actor.position - playerPos):length()
            log("guard candidate:", actor.recordId, "dist:", math.floor(d), "radius:", cachedSettings.GUARD_RADIUS)
            if d <= cachedSettings.GUARD_RADIUS and d < closestDist then
                closest, closestDist = actor, d
            end
        end
    end
    log("findNearestGuard: scanned", scanned, "actors,", candidates, "guards, closest:", closest and closest.recordId or "none")
    return closest
end

local function hasBounty()
    local b = types.Player.getCrimeLevel(self)
    log("hasBounty: crime level =", b)
    return b > 0
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
    log("findBribeableNPCs: found", #result, "candidate(s)")
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
    log("tryBribe: triggered")
    if not cachedSettings.MOD_ENABLED then
        log("tryBribe: mod disabled, returning")
        return
    end
    if types.Actor.getStance(self.object) ~= 0 then
        log("tryBribe: weapon/spell stance, returning")
        return
    end

    swapAndDiff()
    if not prevSnap then
        log("tryBribe: no prev snapshot, returning")
        return
    end

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
    log("tryBribe: detected dropped gold =", droppedGold, "min =", cachedSettings.MIN_GOLD)

    if droppedGold < cachedSettings.MIN_GOLD then return end

    local npcs = findBribeableNPCs()
    if #npcs == 0 then
        log("tryBribe: no bribeable NPCs in range, returning")
        return
    end

    local goldItem = findDroppedGold(droppedGold)
    if not goldItem then
        log("tryBribe: no matching dropped gold item found in world, returning")
        return
    end

    local overpay   = droppedGold - cachedSettings.MIN_GOLD
    local bonus     = overpay / cachedSettings.MIN_GOLD
    local ceasefire = math.floor((cachedSettings.CEASEFIRE + bonus) * 10 + 0.5) / 10

    log("tryBribe: sending Surrender_Bribe, ceasefire =", ceasefire)
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
    log("tryBribeDirect: triggered, amount =", amount)
    if not cachedSettings.MOD_ENABLED then
        log("tryBribeDirect: mod disabled, returning")
        return
    end
    if types.Actor.getStance(self.object) ~= 0 then
        log("tryBribeDirect: weapon/spell stance, returning")
        return
    end
    if amount < cachedSettings.MIN_GOLD then
        log("tryBribeDirect: amount below MIN_GOLD, returning")
        return
    end

    local npcs = findBribeableNPCs()
    if #npcs == 0 then
        log("tryBribeDirect: no bribeable NPCs in range, returning")
        return
    end

    local goldItem = findDroppedGold(amount)
    if not goldItem then
        log("tryBribeDirect: no matching dropped gold item found in world, returning")
        return
    end

    local overpay   = amount - cachedSettings.MIN_GOLD
    local bonus     = overpay / cachedSettings.MIN_GOLD
    local ceasefire = math.floor((cachedSettings.CEASEFIRE + bonus) * 10 + 0.5) / 10

    log("tryBribeDirect: sending Surrender_Bribe, ceasefire =", ceasefire)
    core.sendGlobalEvent("Surrender_Bribe", {
        goldItem       = goldItem,
        npcs           = npcs,
        ceasefire      = ceasefire,
        classCeasefire = cachedSettings.CLASS_CEASEFIRE,
        player         = self.object,
    })
end

local function surrenderToGuard(guard)
    -- instead of dropping the gold
    log("surrenderToGuard: sending Surrender_OpenGuardDialogue for", guard.recordId)
    core.sendGlobalEvent("Surrender_OpenGuardDialogue", {
        player = self.object,
        guard  = guard,
    })
end

local function throwGold()
    log("throwGold: triggered")
    if not cachedSettings.MOD_ENABLED then
        log("throwGold: mod disabled, returning")
        return
    end
    local stance = types.Actor.getStance(self.object)
    if stance ~= 0 then
        log("throwGold: stance is", stance, "(non-zero), returning")
        return
    end

    log("throwGold: SURRENDER_TO_GUARDS =", cachedSettings.SURRENDER_TO_GUARDS)
    if cachedSettings.SURRENDER_TO_GUARDS and hasBounty() then
        local guard = findNearestGuard()
        if guard then
            log("throwGold: guard found, surrendering instead of throwing")
            surrenderToGuard(guard)
            return
        else
            log("throwGold: no guard in range, falling through to throw gold")
        end
    else
        log("throwGold: surrender skipped (setting off or no bounty)")
    end

    local amount = cachedSettings.THROW_GOLD_AMOUNT

    local inv = types.Actor.inventory(self)
    local totalGold = 0
    for _, item in ipairs(inv:getAll()) do
        if shared.GOLD_IDS[item.recordId:lower()] then
            totalGold = totalGold + item.count
        end
    end
    log("throwGold: totalGold =", totalGold, "required =", amount)
    if totalGold < amount then
        log("throwGold: not enough gold, returning")
        return
    end

    local yaw = self.object.rotation:getAnglesZYX()
    log("throwGold: sending Surrender_ThrowGold, amount =", amount)
    core.sendGlobalEvent('Surrender_ThrowGold', {
        player = self.object,
        amount = amount,
        yaw    = yaw,
        usePhysics = cachedSettings.USE_PHYSICS,
    })
end

local triggerRegistered = false

local function registerTrigger()
    if triggerRegistered then return end
    triggerRegistered = true
    input.registerTriggerHandler('SurrenderThrowGold', async:callback(throwGold))
end

local function initScript()
    refreshCache()
    fillSnapshot(currentSnap)
    registerTrigger()
    core.sendGlobalEvent("Surrender_SetLog", cachedSettings.LOG)
end

local function UiModeChanged(data)
    if data.oldMode == nil and data.newMode == "Interface" then
        fillSnapshot(currentSnap)
    end
    if data.oldMode == "Interface" and data.newMode == nil then
        tryBribe()
    end
end

local function SurrenderMessage(data)
    if data and data.message then
        ui.showMessage(data.message)
    end
end

local function Surrender_TryBribeFromThrow(data)
    async:newUnsavableSimulationTimer(0.05, function()
        fillSnapshot(currentSnap)
        tryBribeDirect(data.amount)
    end)
end

return {
    engineHandlers = {
        onInit = initScript,
        onLoad = initScript,
    },

    eventHandlers = {
        UiModeChanged               = UiModeChanged,
        SurrenderMessage            = SurrenderMessage,
        Surrender_TryBribeFromThrow = Surrender_TryBribeFromThrow,
    },
}