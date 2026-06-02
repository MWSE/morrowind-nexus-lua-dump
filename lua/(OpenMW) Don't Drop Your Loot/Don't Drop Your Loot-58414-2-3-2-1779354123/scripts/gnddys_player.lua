local core    = require("openmw.core")
local self    = require("openmw.self")
local types   = require("openmw.types")
local nearby  = require("openmw.nearby")
local util    = require("openmw.util")
local ui      = require("openmw.ui")
local storage = require("openmw.storage")
local async   = require("openmw.async")
local time    = require("openmw_aux.time")
local I       = require("openmw.interfaces")

local shared            = require("scripts.gshared")
local EXEMPT_CLASSES    = shared.EXEMPT_CLASSES
local EXEMPT_NPCS       = shared.EXEMPT_NPCS
local KHAJIIT_RACE      = shared.KHAJIIT_RACE
local EXEMPT_FACTIONS   = shared.EXEMPT_FACTIONS
local NARCOTIC          = shared.NARCOTIC
local CONTRABAND        = shared.CONTRABAND
local PAUPER_CONTRABAND = shared.PAUPER_CONTRABAND
local GOLD_IDS          = shared.GOLD_IDS
local DEFAULTS          = shared.DEFAULTS
local EXEMPT_CELLS      = shared.EXEMPT_CELLS
local EXEMPT_NPCS_FULL  = shared.EXEMPT_NPCS_FULL
local LURE_EXCLUDED     = shared.LURE_EXCLUDED
local ALLOWED_ANIMS     = shared.ALLOWED_ANIMS


local VEC_FORWARD  = util.vector3(0, 1, 0)
local HEAD_OFFSET  = util.vector3(0, 0, 95)
local CHEST_OFFSET = util.vector3(0, 0, 60)
local COS_FOV      = math.cos(math.rad(80))

local UPDATE_INTERVAL = 0.1 * time.second  -- cell + sneak polling rate


local section       = storage.playerSection("SettingsGreedyNPCs")
local sectionValues = storage.playerSection("SettingsGreedyNPCsValues")
local sectionLure   = storage.playerSection("SettingsGreedyNPCsLure")

local cfg = {}

local function getSetting(key)
    local val = section:get(key)
    if val ~= nil then return val end
    val = sectionValues:get(key)
    if val ~= nil then return val end
    val = sectionLure:get(key)
    if val ~= nil then return val end
    return DEFAULTS[key]
end

local function reloadAllSettings()
    for k in pairs(DEFAULTS) do
        cfg[k] = getSetting(k)
    end
end

reloadAllSettings()

local function broadcastSettings()
    core.sendGlobalEvent("GreedyNPCs_SettingsUpdated", {
        PICKUP_RADIUS        = cfg.PICKUP_RADIUS,
        PICKUP_DELAY         = cfg.PICKUP_DELAY,
        PICKUP_ENABLED       = cfg.PICKUP_ENABLED,
        CRIME_ENABLED        = cfg.CRIME_ENABLED,
        MIN_APPARATUS        = cfg.MIN_APPARATUS,
        MIN_BOOK             = cfg.MIN_BOOK,
        MIN_CLOTHING         = cfg.MIN_CLOTHING,
        MIN_ARMOR            = cfg.MIN_ARMOR,
        MIN_WEAPON           = cfg.MIN_WEAPON,
        MIN_INGREDIENT       = cfg.MIN_INGREDIENT,
        MIN_POTION           = cfg.MIN_POTION,
        MIN_LOCKPICK         = cfg.MIN_LOCKPICK,
        MIN_PROBE            = cfg.MIN_PROBE,
        MIN_REPAIR           = cfg.MIN_REPAIR,
        MIN_MISC             = cfg.MIN_MISC,
        LURE_PICKUP_DELAY    = cfg.LURE_PICKUP_DELAY,
        LURE_RETURN_DELAY    = cfg.LURE_RETURN_DELAY,
        LURE_LINGER_DELAY    = cfg.LURE_LINGER_DELAY,
        ESCORT_FOLLOW_BUSY   = cfg.ESCORT_FOLLOW_BUSY,
        EQUIP_ARMOR          = cfg.EQUIP_ARMOR,
        JUMP_WHEN_STUCK      = cfg.JUMP_WHEN_STUCK,
        SHOW_PICKUP_MESSAGES = cfg.SHOW_PICKUP_MESSAGES,
        SHOW_HEAVY_MESSAGES  = cfg.SHOW_HEAVY_MESSAGES,
    })
end

local function refreshCache()
    reloadAllSettings()
    broadcastSettings()
end

local settingsDirty = false
local function markDirty()
    settingsDirty = true
end

section      :subscribe(async:callback(markDirty))
sectionValues:subscribe(async:callback(markDirty))
sectionLure  :subscribe(async:callback(markDirty))

local snapA, snapB = {}, {}
local currentSnap  = snapA
local prevSnap

local playerIsSneaking = false
local wasSneak         = false

local cachedCellName   = nil
local cachedCellExempt = false
local lastCellName     = nil

local updateTimer      = 0

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
        prevSnap, currentSnap = snapA, snapB
    else
        prevSnap, currentSnap = snapB, snapA
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

local function isValuable(item)
    local id = string.lower(item.recordId)
    if GOLD_IDS[id] then return true end
    if types.Ingredient.objectIsInstance(item)    then return types.Ingredient.record(item).value    >= cfg.MIN_INGREDIENT end
    if types.Potion.objectIsInstance(item)        then return types.Potion.record(item).value        >= cfg.MIN_POTION     end
    if types.Apparatus.objectIsInstance(item)     then return types.Apparatus.record(item).value     >= cfg.MIN_APPARATUS  end
    if types.Book.objectIsInstance(item)          then return types.Book.record(item).value          >= cfg.MIN_BOOK       end
    if types.Clothing.objectIsInstance(item)      then return types.Clothing.record(item).value      >= cfg.MIN_CLOTHING   end
    if types.Armor.objectIsInstance(item)         then return types.Armor.record(item).value         >= cfg.MIN_ARMOR      end
    if types.Weapon.objectIsInstance(item)        then return types.Weapon.record(item).value        >= cfg.MIN_WEAPON     end
    if types.Lockpick.objectIsInstance(item)      then return types.Lockpick.record(item).value      >= cfg.MIN_LOCKPICK   end
    if types.Probe.objectIsInstance(item)         then return types.Probe.record(item).value         >= cfg.MIN_PROBE      end
    if types.Repair.objectIsInstance(item)        then return types.Repair.record(item).value        >= cfg.MIN_REPAIR     end
    if types.Miscellaneous.objectIsInstance(item) then return types.Miscellaneous.record(item).value >= cfg.MIN_MISC       end
    return false
end

local function isOutrankedByPlayer(actor)
    if not cfg.RANK_EXEMPT_ENABLED then return false end
    local playerObj = self.object
    for _, factionId in pairs(types.NPC.getFactions(actor)) do
        local npcRank    = types.NPC.getFactionRank(actor, factionId)
        local playerRank = types.NPC.getFactionRank(playerObj, factionId)
        if playerRank > 0 and npcRank > 0 then
            if playerRank >= 9 or (playerRank - npcRank) >= cfg.RANK_EXEMPT_DIFF then
                return true
            end
        end
    end
    return false
end

local function isInCombat(actor)
    local stance = types.Actor.getStance(actor)
    return stance == 1 or stance == 2
end

local function resolveIsSneaking()
    if cfg.SIGN_COMPAT then
        local signIface = I.SneakIsGoodNow
        if signIface and signIface.playerState then
            return signIface.playerState.isSneaking == true
        end
        return false
    end
    return self.controls.sneak
end

local function isPlayerHidden()
    local player = self.object
    local eff    = types.Actor.activeEffects(player)
    local cham   = eff and eff:getEffect("chameleon")
    if cham and cham.magnitude and cham.magnitude >= cfg.CHAMELEON_THRESHOLD then
        return true
    end
    if playerIsSneaking then
        if cfg.SIGN_COMPAT then return true end
        local sneak = types.NPC.stats.skills.sneak(player).modified
        if sneak >= cfg.SNEAK_THRESHOLD then return true end
    end
    return false
end

local function canSeePlayer(npc, radius)
    local toPlayer = self.position - npc.position
    local len = toPlayer:length()
    if len == 0       then return true  end
    if len > radius   then return false end
    local npcForward = npc.rotation:apply(VEC_FORWARD)
    if npcForward:dot(toPlayer / len) < COS_FOV then return false end
    local result = nearby.castRay(
        npc.position + HEAD_OFFSET,
        self.position + CHEST_OFFSET,
        { collisionType = 3, ignore = { npc } }
    )
    return not result.hit
end

local function isExemptFromCrime(actor)
    if isInCombat(actor) then return true end
    local record = types.NPC.record(actor)
    if not record then return true end
    local recordId = actor.recordId:lower()
    if EXEMPT_NPCS_FULL[recordId]                                  then return true end
    if EXEMPT_NPCS[recordId]                                       then return true end
    if isOutrankedByPlayer(actor)                                  then return true end
    if record.class and EXEMPT_CLASSES[record.class:lower()]       then return true end
    for _, factionId in pairs(types.NPC.getFactions(actor)) do
        if EXEMPT_FACTIONS[factionId:lower()] then return true end
    end
    return false
end

local function wantsItem(actor, narcotic, contraband, pauperContraband)
    if isInCombat(actor) then return false end
    local record = types.NPC.record(actor)
    if not record                                                  then return false end
    if not ALLOWED_ANIMS[(record.model or ""):lower()]             then return false end
    if EXEMPT_NPCS_FULL[actor.recordId:lower()]                    then return false end
    if isOutrankedByPlayer(actor)                                  then return false end

    local isPauper  = record.class and EXEMPT_CLASSES[record.class:lower()]
    local isKhajiit = record.race  and KHAJIIT_RACE[record.race:lower()]

    if isPauper then
        if contraband then return pauperContraband end
        return true
    end
    if isKhajiit then
        return not contraband
    end
    if narcotic or contraband then return false end
    return true
end

local function findPickupNPC(itemPos, narcotic, contraband, pauperContraband)
    local best, bestDist = nil, math.huge
    local pickupRadius = cfg.PICKUP_RADIUS
    for _, actor in ipairs(nearby.actors) do
        if actor ~= self.object
           and types.NPC.objectIsInstance(actor)
           and not types.Actor.isDead(actor)
           and wantsItem(actor, narcotic, contraband, pauperContraband)
           and canSeePlayer(actor, pickupRadius) then
            local dist = (actor.position - itemPos):length()
            if dist <= pickupRadius and dist < bestDist then
                bestDist = dist
                best     = actor
            end
        end
    end
    return best
end

local function findLureNPCs(itemPos, narcotic, contraband, pauperContraband)
    local results    = {}
    local lureRadius = cfg.LURE_RADIUS
    local pickRadius = cfg.PICKUP_RADIUS
    for _, actor in ipairs(nearby.actors) do
        if actor ~= self.object
           and types.NPC.objectIsInstance(actor)
           and not types.Actor.isDead(actor)
           and not LURE_EXCLUDED[actor.recordId:lower()]
           and wantsItem(actor, narcotic, contraband, pauperContraband) then
            local dist = (actor.position - itemPos):length()
            if dist > pickRadius and dist <= lureRadius then
                results[#results + 1] = actor
            end
        end
    end
    return results
end

-- Like findLureNPCs but searches the full lure radius (0..LURE_RADIUS),
-- not just the ring outside pickup radius. Used for externally spawned items
-- where the NPC hears the impact and should investigate regardless of distance.
local function findLureNPCsInRange(itemPos)
    local results    = {}
    local lureRadius = cfg.LURE_RADIUS
    for _, actor in ipairs(nearby.actors) do
        if actor ~= self.object
           and types.NPC.objectIsInstance(actor)
           and not types.Actor.isDead(actor)
           and not LURE_EXCLUDED[actor.recordId:lower()]
           and wantsItem(actor, false, false, false) then
            local dist = (actor.position - itemPos):length()
            if dist <= lureRadius then
                results[#results + 1] = actor
            end
        end
    end
    return results
end

local function sendLure(npcs, item, itemPos)
    for _, npc in ipairs(npcs) do
        core.sendGlobalEvent("GNPCs_EnsureLocalAndLure", {
            npc     = npc,
            item    = item,
            itemPos = itemPos,
        })
    end
end

local function updateCellCache()
    local cell = self.cell
    if not cell then
        cachedCellExempt = false
        return
    end
    local name = cell.name
    if name ~= cachedCellName then
        cachedCellName   = name
        cachedCellExempt = EXEMPT_CELLS[name:lower()] == true
    end
    if name ~= lastCellName then
        lastCellName = name
        fillSnapshot(currentSnap)
    end
end

local function checkCrime(narcotic)
    if isPlayerHidden() then return end
    for _, actor in ipairs(nearby.actors) do
        if actor.type == types.NPC
           and not types.Actor.isDead(actor)
           and not isExemptFromCrime(actor)
           and canSeePlayer(actor, cfg.CONTRABAND_RADIUS) then
            local record    = types.NPC.record(actor)
            local isKhajiit = record and record.race and KHAJIIT_RACE[record.race:lower()]
            if not (narcotic and isKhajiit) then
                core.sendGlobalEvent("GNPCs_EnsureLocalAndQueryCrime", {
                    npc    = actor,
                    player = self.object,
                })
                return
            end
        end
    end
end

local function dispatchPickupOrLure(item, narcotic, contraband, pauperContraband)
    local npc = findPickupNPC(item.position, narcotic, contraband, pauperContraband)
    if npc then
        core.sendGlobalEvent("GNPCs_EnsureLocalAndQueryPickup", {
            npc  = npc,
            item = item,
        })
        return true
    end
    if cfg.LURE_ENABLED then
        local lureNpcs = findLureNPCs(item.position, narcotic, contraband, pauperContraband)
        if #lureNpcs > 0 then
            sendLure(lureNpcs, item, item.position)
            return true
        end
    end
    return false
end

local function tryPickupByItemId(itemId, recordId)
    local narcotic         = NARCOTIC[recordId] or false
    local contraband       = CONTRABAND[recordId] or false
    local pauperContraband = contraband and PAUPER_CONTRABAND[recordId] or false
    for _, item in ipairs(nearby.items) do
        if item.id == itemId
           and (item.position - self.position):length() <= cfg.PICKUP_RADIUS
           and (narcotic or contraband or isValuable(item)) then
            dispatchPickupOrLure(item, narcotic, contraband, pauperContraband)
            return
        end
    end
end

local function tryPickupByRecordId(recordId, count)
    local narcotic         = NARCOTIC[recordId] or false
    local contraband       = CONTRABAND[recordId] or false
    local pauperContraband = contraband and PAUPER_CONTRABAND[recordId] or false
    local found = 0
    for _, item in ipairs(nearby.items) do
        if string.lower(item.recordId) == recordId
           and (item.position - self.position):length() <= cfg.PICKUP_RADIUS
           and (narcotic or contraband or isValuable(item)) then
            if dispatchPickupOrLure(item, narcotic, contraband, pauperContraband) then
                found = found + 1
                if found >= count then return end
            end
        end
    end
end

-- if you drop two+ stacks of gold, an npc will pick up none. maybe later think of a way to fix this
local function tryPickupDroppedGold(amount)
    local worldId = goldRecordForAmount(amount)
    for _, item in ipairs(nearby.items) do
        if string.lower(item.recordId) == worldId
           and item.count == amount
           and (item.position - self.position):length() <= cfg.PICKUP_RADIUS then
            dispatchPickupOrLure(item, false, false, false)
            return
        end
    end
end

local function checkDroppedItems()
    if cachedCellExempt then return end
    swapAndDiff()

    if isInCombat(self.object) then return end

    local hidden        = isPlayerHidden()
    local dropped_exact = {}
    local dropped_count = {}
    local anyNarcotic   = false
    local anyContraband = false

    for itemId, prev in pairs(prevSnap) do
        local curr    = currentSnap[itemId]
        local dropped = prev.count - (curr and curr.count or 0)
        if dropped > 0 then
            local recordId = prev.recordId
            if not hidden and cfg.CRIME_ENABLED then
                if NARCOTIC[recordId]   then anyNarcotic   = true end
                if CONTRABAND[recordId] then anyContraband = true end
            end
            if cfg.PICKUP_ENABLED then
                if GOLD_IDS[recordId] then
                    tryPickupDroppedGold(dropped)
                else
                    if not curr then
                        dropped_exact[itemId] = recordId
                        dropped = dropped - 1
                    end
                    if dropped > 0 then
                        dropped_count[recordId] = (dropped_count[recordId] or 0) + dropped
                    end
                end
            end
        end
    end

    for itemId, recordId in pairs(dropped_exact) do
        tryPickupByItemId(itemId, recordId)
    end
    for recordId, count in pairs(dropped_count) do
        tryPickupByRecordId(recordId, count)
    end

    if anyNarcotic or anyContraband then
        checkCrime(anyNarcotic)
    end
end

local function onInit()
    fillSnapshot(currentSnap)
    updateCellCache()
    broadcastSettings()
end

local function onLoad()
    fillSnapshot(currentSnap)
    updateCellCache()
    broadcastSettings()
end

local function onUpdate(dt)
    -- Tick-gated: cell tracking and sneak edge detection don't need 300fps
    updateTimer = updateTimer + dt
    if updateTimer < UPDATE_INTERVAL then return end
    updateTimer = updateTimer - UPDATE_INTERVAL  -- preserve remainder

    if settingsDirty then
        settingsDirty = false
        refreshCache()
    end

    updateCellCache()

    local isSneak = resolveIsSneaking()
    if isSneak ~= wasSneak then
        wasSneak         = isSneak
        playerIsSneaking = isSneak
    end
end

local function onUiModeChanged(data)
    if data.oldMode == nil and data.newMode == "Interface" then
        fillSnapshot(currentSnap)
    end
    if data.oldMode == "Interface" and data.newMode == nil then
        checkDroppedItems()
    end
end

local function onNpcPickupMessage(data)
    if data and data.message then
        ui.showMessage(data.message)
    end
end

local function onNotifyGoldDrop(data)
    if not cfg.PICKUP_ENABLED then return end
    if cachedCellExempt        then return end
    if isPlayerHidden()        then return end
    if not data or not data.amount then return end
    async:newUnsavableSimulationTimer(0.01, function()
        fillSnapshot(currentSnap)
        tryPickupDroppedGold(data.amount)
    end)
end

-- External mods (e.g. ArrowStick) notify about items created directly in the world.
-- NPC hears the impact and goes to investigate via lure mechanic;
-- player stealth is irrelevant — the item is already visible in the world.
local function onNotifyItemDrop(data)
    if not cfg.PICKUP_ENABLED then return end
    if not cfg.LURE_ENABLED   then return end
    if cachedCellExempt        then return end
    if not data or not data.recordId or not data.position then return end

    local recordId = string.lower(data.recordId)
    local pos      = data.position
    for _, item in ipairs(nearby.items) do
        if string.lower(item.recordId) == recordId
           and (item.position - pos):length() <= 64 then
            local lureNpcs = findLureNPCsInRange(item.position)
            if #lureNpcs > 0 then
                sendLure(lureNpcs, item, item.position)
            end
            return
        end
    end
end

return {
    engineHandlers = {
        onInit   = onInit,
        onLoad   = onLoad,
        onUpdate = onUpdate,
    },
    eventHandlers = {
        UiModeChanged        = onUiModeChanged,
        NpcPickupMessage     = onNpcPickupMessage,
        GNPCs_NotifyGoldDrop = onNotifyGoldDrop,
        GNPCs_NotifyItemDrop = onNotifyItemDrop,
    },
}