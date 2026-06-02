local types = require("openmw.types")
local core  = require("openmw.core")
local I     = require("openmw.interfaces")

local ITEM_TYPES = {
    types.Activator,
    types.Apparatus,
    types.Armor,
    types.Book,
    types.Clothing,
    types.Ingredient,
    types.Light,
    types.Lockpick,
    types.Miscellaneous,
    types.Potion,
    types.Probe,
    types.Repair,
    types.Weapon,
}

local pending     = {}
local passthrough = {}
local busyActors  = {}
local actorQueues = {} -- tracks pending interaction queues per player
local quickloot   = {} -- [object.id] = true for items currently being moved by QuickLoot

local function isItemType(object)
    for _, t in ipairs(ITEM_TYPES) do
        if object.type == t then return true end
    end
    return false
end

local isBardcraftInstalled = core.contentFiles.has("Bardcraft.ESP")

-- when AnimatedPickup is installed it owns item pickups entirely
local function animatedPickupActive()
    return I.AnimatedPickup ~= nil
end

local function processQueue(actor)
    local queue = actorQueues[actor.id]
    if not queue or #queue == 0 then
        busyActors[actor.id] = nil
        return
    end

    -- pull the next interaction request from the queue
    local nextObject = table.remove(queue, 1)

    -- ensure the object hasn't been deleted/picked up already by another system
    if not nextObject:isValid() then
        processQueue(actor)
        return
    end

    pending[nextObject.id] = true
    busyActors[actor.id] = true
    actor:sendEvent("PickupAnim_Play", { object = nextObject })
end

local function onActivate(object, actor)
    if not actor or actor.type ~= types.Player then return end


    -- Bardcraft Music Box compatibility: Skip intercepting so the UI opens instantly
    if isBardcraftInstalled and object.recordId and string.sub(object.recordId, 1, 12) == "r_bc_musbox_" then
        actor:sendEvent("PickupAnim_Play", { object = object, visualOnly = true })
        return
    end

    if passthrough[object.id] then
        passthrough[object.id] = nil
        return
    end

    if pending[object.id] then return false end

    -- QuickLoot interop
    if quickloot[object.id] then
        quickloot[object.id] = nil
        return
    end

    -- actors: only intercept dead ones (looting a corpse)
    if types.NPC.objectIsInstance(object) or types.Creature.objectIsInstance(object) then
        if not types.Actor.isDead(object) then
            return
        end
    end

    -- strange things happen when animating teleport doors: actor rotates sometimes before resuming their right position
    if types.Door.objectIsInstance(object) and types.Door.isTeleport(object) then
        return
    end

    -- AnimatedPickup interop
    if animatedPickupActive() and isItemType(object)
        and not types.Activator.objectIsInstance(object)
        and not types.Book.objectIsInstance(object) then
        return
    end

    -- if the actor is already animating, queue up this new object instead of dropping it
    if busyActors[actor.id] then
        if not actorQueues[actor.id] then actorQueues[actor.id] = {} end

        for _, queuedObj in ipairs(actorQueues[actor.id]) do
            if queuedObj.id == object.id then return false end
        end

        table.insert(actorQueues[actor.id], object)
        return false
    end

    pending[object.id] = true
    busyActors[actor.id] = true
    actor:sendEvent("PickupAnim_Play", { object = object })
    return false
end

local function onAnimDone(data)
    local object = data and data.object
    local actor  = data and data.actor
    if not object or not actor then return end

    -- visual-only animations, AnimatedPickup drove the pickup
    if data.visualOnly then return end

    busyActors[actor.id] = true

    if not object:isValid() then
        pending[object.id] = nil
        processQueue(actor)
        return
    end

    pending[object.id]     = nil
    passthrough[object.id] = true
    object:activateBy(actor)

    processQueue(actor)
end

for _, t in ipairs(ITEM_TYPES) do
    I.Activation.addHandlerForType(t, onActivate)
end
I.Activation.addHandlerForType(types.Container, onActivate)
I.Activation.addHandlerForType(types.Door, onActivate)
I.Activation.addHandlerForType(types.NPC, onActivate)
I.Activation.addHandlerForType(types.Creature, onActivate)

-- QuickLoot interop
local function logQuicklootTake(e)
    local item = e and e[3]
    if item and item.id then
        quickloot[item.id] = true
    end
end

local function logQuicklootTakeAll(e)
    local container = e and e[2]
    if not container then return end
    local t = types.Container.objectIsInstance(container) and types.Container
        or types.Actor
    local inv = t.inventory(container)
    if not inv then return end
    for _, item in pairs(inv:getAll()) do
        quickloot[item.id] = true
    end
end

-- intercept QuickLoot's global single deposit request
local function onQuicklootDeposit(data)
    local player    = data and data[1]
    local container = data and data[2]
    
    if player and player.type == types.Player and container then
        player:sendEvent("PickupAnim_QuickLootDeposit", { container = container })
    end
end

-- intercept QuickLoot's global mass deposit request
local function onQuicklootDepositAll(data)
    local player    = data and data[1]
    local container = data and data[2]
    
    if player and player.type == types.Player and container then
        player:sendEvent("PickupAnim_QuickLootDepositAll", { container = container })
    end
end

local function onMusicBoxPickup(data)
    local actor = data and data.actor
    local object = data and data.object
    if actor and actor.type == types.Player and object then
        -- Trigger a visual-only item pickup animation. 
        -- Removed fallbackType because engine types cannot be serialized over events.
        -- The player script will automatically handle the fallback.
        actor:sendEvent("PickupAnim_Play", { object = object, visualOnly = true })
    end
end

return {
    interfaceName = "PickupAnim",
    interface = { active = true },
    eventHandlers = {
        PickupAnim_Done         = onAnimDone,
        OwnlysQuickLoot_take    = logQuicklootTake,
        OwnlysQuickLoot_takeAll = logQuicklootTakeAll,
        OwnlysQuickLoot_deposit    = onQuicklootDeposit,
        OwnlysQuickLoot_depositAll = onQuicklootDepositAll,
        BC_MusicBoxPickup          = onMusicBoxPickup,
    },
}