local core  = require("openmw.core")
local types = require("openmw.types")
local world = require("openmw.world")
local async = require("openmw.async")
local I     = require("openmw.interfaces")

local shared       = require("scripts.gshared")
local KHAJIIT_RACE = shared.KHAJIIT_RACE
local GOLD_IDS     = shared.GOLD_IDS
local DEFAULTS     = shared.DEFAULTS

local messages = require("scripts.gnddys_messages")

local LOCAL_SCRIPT = "scripts/gnddys_local.lua"

local cfg = {}
for k, v in pairs(DEFAULTS) do cfg[k] = v end

local lastBroadcastData = nil
local pendingItems      = {}

local function pickFrom(pool)
    return pool[math.random(#pool)]
end

local function randomMessage()
    return pickFrom(messages.PICKUP_MESSAGES)
end

local function khajiitMessage(isMoonSugar)
    if isMoonSugar then return pickFrom(messages.KHAJIIT_SUGAR_MESSAGES) end
    return pickFrom(messages.KHAJIIT_MESSAGES)
end

local function ammoMessage(ammoType, isKhajiit)
    if ammoType == "bolt" then
        return pickFrom(isKhajiit and messages.KHAJIIT_BOLT_PICKUP_MESSAGES
                                  or messages.BOLT_PICKUP_MESSAGES)
    end
    return pickFrom(isKhajiit and messages.KHAJIIT_ARROW_PICKUP_MESSAGES
                              or messages.ARROW_PICKUP_MESSAGES)
end

local function tooHeavyMessage(isKhajiit)
    return pickFrom(isKhajiit and messages.KHAJIIT_TOO_HEAVY_MESSAGES
                              or messages.TOO_HEAVY_MESSAGES)
end

local function sendNpcMessage(npc, message)
    local player = world.players[1]
    if not player then return end
    local npcName = types.NPC.record(npc).name or "Someone"
    player:sendEvent("NpcPickupMessage", {
        message = npcName .. ": \"" .. message .. "\"",
    })
end

local ARROW = types.Weapon.TYPE.Arrow
local BOLT  = types.Weapon.TYPE.Bolt

local function getAmmoType(item)
    if not types.Weapon.objectIsInstance(item) then return nil end
    local wtype = types.Weapon.record(item).type
    if wtype == ARROW then return "arrow" end
    if wtype == BOLT  then return "bolt"  end
    return nil
end

local function pickupSoundFor(item, ammoType)
    local id = string.lower(item.recordId)
    if GOLD_IDS[id]                              then return "Item Gold Up" end
    if ammoType                                  then return "Item Ammo Up" end
    if types.Weapon.objectIsInstance(item)       then return "Item Weapon Shortblade Up" end
    if types.Book.objectIsInstance(item)         then return "Item Book Up" end
    if types.Apparatus.objectIsInstance(item)    then return "Item Apparatus Up" end
    if types.Clothing.objectIsInstance(item)     then return "Item Clothes Up" end
    if types.Armor.objectIsInstance(item)        then return "Item Armor Medium Up" end
    if types.Ingredient.objectIsInstance(item)   then return "Item Ingredient Up" end
    if types.Potion.objectIsInstance(item)       then return "Item Potion Up" end
    if types.Lockpick.objectIsInstance(item)     then return "Item Lockpick Up" end
    if types.Probe.objectIsInstance(item)        then return "Item Probe Up" end
    if types.Repair.objectIsInstance(item)       then return "Item Repair Up" end
    return "Item Misc Up"
end

local function isTransferValid(npc, item)
    if not item or not item:isValid() then return false end
    if not npc  or not npc:isValid()  then return false end
    if types.Actor.isDead(npc)        then return false end
    if item.cell == nil               then return false end
    if item.count <= 0                then return false end
    return true
end

local function announcePickup(npc, item, ammoType)
    if not cfg.SHOW_PICKUP_MESSAGES then return end

    local id      = string.lower(item.recordId)
    local npcRace = (types.NPC.record(npc).race or ""):lower()
    local isKh    = KHAJIIT_RACE[npcRace] or false

    local msg
    if ammoType then
        msg = ammoMessage(ammoType, isKh)
    elseif isKh then
        msg = khajiitMessage(id == "ingred_moon_sugar_01")
    else
        msg = randomMessage()
    end
    sendNpcMessage(npc, msg)
end

local function maybeEquipArmor(npc, item)
    if not cfg.EQUIP_ARMOR then return end
    if not types.Armor.objectIsInstance(item) then return end
    npc:sendEvent("GNPCs_TryEquipArmor", { item = item })
end

-- moves the item (or split portion) into the NPC, plays sound, shows message, equips armor.
local function finalizeItemTransfer(npc, item, maxCount)
    if not isTransferValid(npc, item) then return end

    local pickCount = maxCount and math.min(maxCount, item.count) or item.count
    if pickCount <= 0 then return end

    local moved
    if pickCount < item.count then
        moved = item:split(pickCount)
        moved:moveInto(types.Actor.inventory(npc))
    else
        item:moveInto(types.Actor.inventory(npc))
        moved = item
    end

    local ammoType = getAmmoType(moved)
    core.sound.playSound3d(pickupSoundFor(moved, ammoType), npc)

    announcePickup(npc, moved, ammoType)
    maybeEquipArmor(npc, moved)
end

local function ensureLocalScript(npc)
    if npc:hasScript(LOCAL_SCRIPT) then return end
    npc:addScript(LOCAL_SCRIPT)
    if lastBroadcastData then
        npc:sendEvent("GreedyNPCs_SettingsUpdated", lastBroadcastData)
    end
end

local function broadcastSettingsToActors(data)
    for _, actor in ipairs(world.activeActors) do
        if actor:hasScript(LOCAL_SCRIPT) then
            actor:sendEvent("GreedyNPCs_SettingsUpdated", data)
        end
    end
end

local function applySettingsBroadcast(data)
    for k, _ in pairs(DEFAULTS) do
        if data[k] ~= nil then
            cfg[k] = data[k]
        end
    end
    -- explicit fallbacks for any nilable booleans the player forgot to send
    if cfg.SHOW_PICKUP_MESSAGES == nil then cfg.SHOW_PICKUP_MESSAGES = DEFAULTS.SHOW_PICKUP_MESSAGES end
    if cfg.SHOW_HEAVY_MESSAGES  == nil then cfg.SHOW_HEAVY_MESSAGES  = DEFAULTS.SHOW_HEAVY_MESSAGES  end
    lastBroadcastData = data
    broadcastSettingsToActors(data)
end

local function onSettingsUpdated(data)
    applySettingsBroadcast(data)
end

local function onNpcTooHeavyItem(data)
    local item, npc = data.item, data.npc
    if not item or not item:isValid() then return end
    if not npc  or not npc:isValid()  then return end

    if pendingItems[item.id] then return end
    pendingItems[item.id] = true

    if cfg.SHOW_HEAVY_MESSAGES then
        local npcRace = (types.NPC.record(npc).race or ""):lower()
        sendNpcMessage(npc, tooHeavyMessage(KHAJIIT_RACE[npcRace] or false))
    end

    async:newUnsavableSimulationTimer(cfg.PICKUP_DELAY, function()
        pendingItems[item.id] = nil
    end)
end

local function onEnsureLocalAndQueryPickup(data)
    if not data or not data.npc or not data.npc:isValid() then return end
    if not data.item or not data.item:isValid()           then return end
    ensureLocalScript(data.npc)
    data.npc:sendEvent("GNPCs_QueryPickup", { item = data.item })
end

local function onEnsureLocalAndLure(data)
    if not data or not data.npc or not data.npc:isValid() then return end
    if not data.item or not data.item:isValid()           then return end
    ensureLocalScript(data.npc)
    data.npc:sendEvent("GNPCs_LureToItem", {
        item    = data.item,
        itemPos = data.itemPos,
    })
end

local function onEnsureLocalAndQueryCrime(data)
    if not data or not data.npc or not data.npc:isValid() then return end
    if not data.player or not data.player:isValid()        then return end
    ensureLocalScript(data.npc)
    data.npc:sendEvent("GNPCs_QueryCrime", { player = data.player })
end

local function onRequestRemoval(npc)
    if not npc or not npc:isValid() then return end
    async:newUnsavableSimulationTimer(5.0, function()
        if npc:isValid() and npc:hasScript(LOCAL_SCRIPT) then
            npc:removeScript(LOCAL_SCRIPT)
        end
    end)
end

local function onNpcPickupItem(data)
    local item     = data.item
    local npc      = data.npc
    local maxCount = data.maxCount  -- nil means full stack
    if not item or not item:isValid() then return end
    if not npc  or not npc:isValid()  then return end

    if pendingItems[item.id] then return end
    pendingItems[item.id] = true

    async:newUnsavableSimulationTimer(cfg.PICKUP_DELAY, function()
        pendingItems[item.id] = nil

        if not item:isValid()                                then return end
        if not npc:isValid() or types.Actor.isDead(npc)      then return end
        local player = world.players[1]
        if not player                                        then return end
        if (item.position - player.position):length() > cfg.PICKUP_RADIUS then return end
        if item.cell == nil                                  then return end
        if item.count <= 0                                   then return end

        -- brief Travel to face the item, then animate.
        npc:sendEvent("GNPCs_StartPickupAnimation", {
            item     = item,
            maxCount = maxCount,
        })
    end)
end

local function onFinalizePickup(data)
    if not data then return end
    finalizeItemTransfer(data.npc, data.item, data.maxCount)
end

local function onContrabandCrime(data)
    if not data or not data.player then return end
    I.Crimes.commitCrime(data.player, {
        type        = types.Player.OFFENSE_TYPE.Trespassing,
        victimAware = true,
    })
end

-- ArrowStick mod notifies when an arrow/bolt is placed in the world
local function onArrowStickPlaced(data)
    if not data or not data.arrowSticked then return end
    local item = data.item
    if not item or not item:isValid() then return end
    local player = world.players[1]
    if not player then return end
    player:sendEvent("GNPCs_NotifyItemDrop", {
        recordId = item.recordId,
        position = item.position,
    })
end

return {
    eventHandlers = {
        GreedyNPCs_SettingsUpdated      = onSettingsUpdated,
        NpcTooHeavyItem                 = onNpcTooHeavyItem,
        GNPCs_EnsureLocalAndQueryPickup = onEnsureLocalAndQueryPickup,
        GNPCs_EnsureLocalAndLure        = onEnsureLocalAndLure,
        GNPCs_EnsureLocalAndQueryCrime  = onEnsureLocalAndQueryCrime,
        GNPCs_RequestRemoval            = onRequestRemoval,
        NpcPickupItem                   = onNpcPickupItem,
        GNPCs_FinalizePickup            = onFinalizePickup,
        ContrabandCrime                 = onContrabandCrime,
        ArrowStick_ArrowPlaced          = onArrowStickPlaced,
    },
}