local self    = require("openmw.self")
local types   = require("openmw.types")
local core    = require("openmw.core")
local async   = require("openmw.async")
local anim    = require("openmw.animation")
local storage = require("openmw.storage")
local I       = require("openmw.interfaces")

local shared  = require("scripts.pickupanim_shared")

-- per-type animation tuning sourced from the shared defaults file.
local ANIM_TUNING = shared.ANIM_TUNING

local section = storage.playerSection("SettingsPickupAnim")
local function getSetting(key, default)
    local v = section:get(key)
    if v ~= nil then return v end
    return default
end

local DEFAULTS = shared.DEFAULTS

local cfg = {
    ENABLED_ITEMS      = getSetting("ENABLED_ITEMS", DEFAULTS.ENABLED_ITEMS),
    ENABLED_DOORS      = getSetting("ENABLED_DOORS", DEFAULTS.ENABLED_DOORS),
    ENABLED_CONTAINERS = getSetting("ENABLED_CONTAINERS", DEFAULTS.ENABLED_CONTAINERS),
    ITEM_SPEED         = getSetting("ITEM_SPEED", DEFAULTS.ITEM_SPEED),
    DISABLE_CAMERA_SHAKE = getSetting("DISABLE_CAMERA_SHAKE", DEFAULTS.DISABLE_CAMERA_SHAKE),
}
section:subscribe(async:callback(function()
    cfg.ENABLED_ITEMS      = getSetting("ENABLED_ITEMS", DEFAULTS.ENABLED_ITEMS)
    cfg.ENABLED_DOORS      = getSetting("ENABLED_DOORS", DEFAULTS.ENABLED_DOORS)
    cfg.ENABLED_CONTAINERS = getSetting("ENABLED_CONTAINERS", DEFAULTS.ENABLED_CONTAINERS)
    cfg.ITEM_SPEED         = getSetting("ITEM_SPEED", DEFAULTS.ITEM_SPEED)
    cfg.DISABLE_CAMERA_SHAKE = getSetting("DISABLE_CAMERA_SHAKE", DEFAULTS.DISABLE_CAMERA_SHAKE)
end))

-- returns the toggle state for a given object type.
local function isTypeEnabled(objectType)
    if objectType == types.Door then
        return cfg.ENABLED_DOORS
    elseif objectType == types.Container or objectType == types.Activator then
        return cfg.ENABLED_CONTAINERS
    end
    return cfg.ENABLED_ITEMS
end

-- track state globally
local currentObject = nil
local currentTriggerKey = nil
local currentAnimName = nil          -- animation group currently playing
local currentExpectedRuntime = 0     -- expected playtime in seconds (native length / speed)
local currentVisualOnly = false      -- AnimatedPickup present, anim is cosmetic
local backupTimer = nil
local animationStartTime = 0 -- tracks when the current animation track began
local quickLootSingleUntil = 0 -- no loot3 when using containers with solo QL

local function finish()
    if not currentObject then return end
    
    if backupTimer then
        backupTimer:cancel()
        backupTimer = nil
    end

    local obj = currentObject
    local visualOnly = currentVisualOnly
    currentObject = nil
    currentTriggerKey = nil
    currentAnimName = nil
    currentExpectedRuntime = 0
    currentVisualOnly = false
    animationStartTime = 0

    core.sendGlobalEvent("PickupAnim_Done", {
        object     = obj,
        actor      = self.object,
        visualOnly = visualOnly,
    })
end

-- text key handlers with a timestamp check to filter out ghost blending keys
-- legacy safeguard since animation is cancelled now when the new starts
local function makeTextKeyHandler()
    return function(_, key)
        local elapsed = core.getSimulationTime() - animationStartTime
        if elapsed < currentExpectedRuntime * 0.3 then return end
        if key == currentTriggerKey then finish() end
    end
end

I.AnimationController.addTextKeyHandler("loot1", makeTextKeyHandler())
I.AnimationController.addTextKeyHandler("loot2", makeTextKeyHandler())
I.AnimationController.addTextKeyHandler("loot3", makeTextKeyHandler())
I.AnimationController.addTextKeyHandler("loot4", makeTextKeyHandler())

local function playPickupAnimation(object, animName, triggerKey, speed, duration, visualOnly)
    anim.cancel(self, animName)
    currentObject = object
    currentTriggerKey = triggerKey
    currentAnimName = animName
    currentVisualOnly = visualOnly or false
    -- native loot animation length is 0.5s
    currentExpectedRuntime = 0.5 / speed
    animationStartTime = core.getSimulationTime()

    local mask = anim.BLEND_MASK.RightArm
    if not cfg.DISABLE_CAMERA_SHAKE then
        mask = mask + anim.BLEND_MASK.Torso
    end

    I.AnimationController.playBlendedAnimation(animName, {
        startKey = "start",
        stopKey  = "stop",
        priority = anim.PRIORITY.Scripted,
        blendMask = mask,
        speed    = speed,
    })

    backupTimer = async:newUnsavableSimulationTimer(duration, finish)
end

local function onPlay(data)
    if not data or not data.object then return end

    local visualOnly = data.visualOnly or false

    -- determine the object type in case another mod (like Bardcraft) deleted it
    local objType = data.fallbackType
    if data.object:isValid() then
        objType = data.object.type
    end

    -- Fallback to Container if type is completely unknown
    if not objType then objType = types.Container end

    -- a QuickLoot single-item take just started a loot1; the container activation
    -- that follows would otherwise replace it with loot3. ignore it within the window.
    if quickLootSingleUntil > 0 and core.getSimulationTime() < quickLootSingleUntil then
        local t = data.object.type
        if t == types.Container or t == types.Activator then
            core.sendGlobalEvent("PickupAnim_Done", {
                object     = data.object,
                actor      = self.object,
                visualOnly = visualOnly,
            })
            return
        end
    end

    -- skip the animation if this object's type is toggled off
    if not isTypeEnabled(data.object.type) then
        core.sendGlobalEvent("PickupAnim_Done", {
            object     = data.object,
            actor      = self.object,
            visualOnly = visualOnly,
        })
        return
    end

    if currentObject then
        finish()
    end

    local animName = "loot1"
    local triggerKey = "attach"
    local tuning = ANIM_TUNING.default

    if data.object.type == types.Door then
        if types.Door.isOpen(data.object) then
            animName = "loot4"
            triggerKey = "discard"
        else
            animName = "loot2"
            triggerKey = "attach"
        end
        tuning = ANIM_TUNING.door
    elseif data.object.type == types.Container or data.object.type == types.Activator then
        animName = "loot3"
        triggerKey = "discard"
        tuning = ANIM_TUNING.container
    end

    -- loot1 (item pickup) speed is player-configurable
    local speed    = tuning.speed
    local duration = tuning.duration
    if animName == "loot1" then
        speed    = cfg.ITEM_SPEED
        duration = 0.5 / cfg.ITEM_SPEED + 0.1
    end

    playPickupAnimation(data.object, animName, triggerKey, speed, duration, visualOnly)
end

-- AnimatedPickup interop
-- AnimatedPickup owns item pickups and notifies IA via ANP_Event
local function onAnpEvent(e)
    if not e or not e.eventName then return end

    -- handle standard cosmetic single-item pickups
    if e.eventName == "PickupAnimationStart" then
        if not e.object then return end
        onPlay({ object = e.object, visualOnly = true })

    -- take all flag from Quickloot
    elseif e.eventName == "PickupItemActivate" then
        if e.takeAll == true then
            local target = e.container or self.object 
            
            -- use the same logic as for for QuickLoot Take-All
            if not cfg.ENABLED_CONTAINERS then return end
            
            if currentObject then return end 

            local tuning = ANIM_TUNING.container
            playPickupAnimation(target, "loot3", "discard", tuning.speed, tuning.duration, true)
        end

    -- handle purchase menus canceling the animation
    elseif e.eventName == "OpenPurchaseMenu" then
        local object = e.object
        if object and currentObject and currentObject.id == object.id then
            if currentAnimName then
                anim.cancel(self, currentAnimName)
            end
            finish()
        end
    end
end

-- a single item from a Quickloot container
local function playQuickLootSingle(container)
    if not container then return end
    if not cfg.ENABLED_CONTAINERS then return end
    if currentObject then return end

    local speed    = cfg.ITEM_SPEED
    local duration = 0.5 / cfg.ITEM_SPEED + 0.1
    -- loot1 because loot3 is too self-imposing
    -- mark a short window so the trailing container onPlay (loot3) doesn't override
    quickLootSingleUntil = core.getSimulationTime() + 0.1
    playPickupAnimation(container, "loot1", "attach", speed, duration, true)
end

-- multiple items from a Quickloot container
local function playQuickLootTakeAll(container)
    if not container then return end
    if not cfg.ENABLED_CONTAINERS then return end
    if currentObject then return end

    local tuning = ANIM_TUNING.container
    local speed    = tuning.speed
    local duration = tuning.duration
    
    -- plays the longer container searching animation
    playPickupAnimation(container, "loot3", "discard", speed, duration, true)
end

local function playQuickLootDepositSingle(container)
    if not container then return end
    if not cfg.ENABLED_CONTAINERS then return end
    if currentObject then return end

    local speed    = cfg.ITEM_SPEED
    local duration = 0.5 / cfg.ITEM_SPEED + 0.1
    playPickupAnimation(container, "loot3", "attach", speed, duration, true)
end

local function onQuickLootTake(e)
    local container = e and e[1]
    playQuickLootSingle(container)
end

local function onQuickLootTakeAll(e)
    local container   = e and e[1]
    local lootedItems = e and e[2]
    
    -- skip if nothing was actually taken
    if not lootedItems or #lootedItems == 0 then return end
    
    playQuickLootTakeAll(container)
end

local function onQuickLootDeposit(e)
    local container = e and e.container
    playQuickLootDepositSingle(container)
end

local function onQuickLootDepositAll(e)
    local container = e and e.container
    playQuickLootTakeAll(container) 
end

return {
    eventHandlers = {
        PickupAnim_Play              = onPlay,
        ANP_Event                    = onAnpEvent,
        OwnlysQuickLoot_lootedItem   = onQuickLootTake,
        OwnlysQuickLoot_lootedItems  = onQuickLootTakeAll,
        PickupAnim_QuickLootDeposit     = onQuickLootDeposit,
        PickupAnim_QuickLootDepositAll  = onQuickLootDepositAll,
    },
}