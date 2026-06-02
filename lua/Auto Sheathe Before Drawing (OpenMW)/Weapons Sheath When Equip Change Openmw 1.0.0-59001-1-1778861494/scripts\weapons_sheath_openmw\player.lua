-- weapons_sheath_openmw / player.lua
--
-- OpenMW Lua port of the MWSE mod weapons_sheath_when_equip_change.
--
-- Goal: when the player swaps weapons while the weapon is drawn, force the
-- character to sheathe the previous weapon first, then equip the new one and
-- draw it. Without this, OpenMW (like vanilla Morrowind) instantly swaps the
-- mesh in-hand without playing the sheathe/draw animation pair.
--
-- Strategy (OpenMW has no cancelable equip event):
--   1. Each frame we observe Actor.getEquipment(self)[CarriedRight] and the current
--      stance (Nothing / Weapon / Spell).
--   2. When we detect that the carried-right weapon changed AND the previous
--      stance was Weapon (drawn), we restore the previous weapon silently and
--      kick off a small state machine:
--          sheathing       -> setStance(Nothing), wait until stance settles
--          postUnreadyPause-> optional configurable pause
--          equipNew        -> native UseItem equip, optional pause
--          drawing         -> setStance(Weapon), wait until stance settles
--          idle            -> done
--   3. While the state machine runs we suppress new detections so our own
--      mutations cannot re-trigger a swap.
--
-- This script runs as a PLAYER local script (see the .omwscripts file at the
-- mod root). In OpenMW, Actor.setEquipment / Actor.setStance are callable on
-- `self` from a player local script, so no GLOBAL helper script is needed.

local self    = require('openmw.self')
local types   = require('openmw.types')
local core    = require('openmw.core')
local anim    = require('openmw.animation')
local Actor   = types.Actor
local STANCE  = Actor.STANCE
local SLOT    = Actor.EQUIPMENT_SLOT

print('[weapons_sheath_openmw] player script loaded')

-- ---------------------------------------------------------------------------
-- Configuration
-- ---------------------------------------------------------------------------
-- Edit these values directly until a Settings page is added.

local CONFIG = {
    enabled             = true,
    -- Seconds to wait after the sheathe stance settles before equipping the
    -- new weapon. 0 means "as fast as possible".
    postUnreadyDelay    = 0.0,
    -- Seconds to wait after equipping the new weapon (still sheathed) before
    -- starting the draw animation. 0 means "draw immediately".
    postEquipDrawDelay  = 0.3,
    -- Re-issue draw while OpenMW is still settling equipment/left-hand state.
    -- This is especially important when a shield is equipped.
    drawRetryInterval   = 0.15,
    -- 0.7 = 30% slower sheathe/draw playback. This is applied only while this
    -- state machine is actively sheathing or drawing.
    animationSpeed      = 0.7,
    -- Safety: if any single phase exceeds this many seconds, abort the swap
    -- so the player is never stuck.
    maxPhaseSeconds     = 4.0,
    -- Print verbose state transitions to the OpenMW log.
    debugLog            = false,
}

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function log(fmt, ...)
    if CONFIG.debugLog then
        print(string.format("[weapons_sheath_openmw] " .. fmt, ...))
    end
end

local function itemId(item)
    return (item and item.recordId) or "<none>"
end

local function getCarriedRight()
    local eq = Actor.getEquipment(self)
    return eq[SLOT.CarriedRight]
end

-- Returns true if `obj` looks like a weapon (or weapon-like one-hand item:
-- lockpick / probe). OpenMW exposes these via types.Weapon / types.Lockpick /
-- types.Probe; we tolerate any of them so the behaviour matches the MWSE mod.
local function isWeaponLike(obj)
    if obj == nil then return false end
    if types.Weapon and types.Weapon.objectIsInstance and types.Weapon.objectIsInstance(obj) then
        return true
    end
    if types.Lockpick and types.Lockpick.objectIsInstance and types.Lockpick.objectIsInstance(obj) then
        return true
    end
    if types.Probe and types.Probe.objectIsInstance and types.Probe.objectIsInstance(obj) then
        return true
    end
    return false
end

local function sameItem(a, b)
    if a == nil or b == nil then return a == b end
    if a == b then return true end
    -- GameObject equality should hold for the same instance, but compare
    -- recordId as a defensive fallback.
    if a.recordId and b.recordId and a.recordId == b.recordId then return true end
    return false
end

local function setEquipmentSlot(slot, item)
    local eq = Actor.getEquipment(self)
    eq[slot] = item
    Actor.setEquipment(self, eq)
end

-- ---------------------------------------------------------------------------
-- State machine
-- ---------------------------------------------------------------------------

local PHASE = {
    IDLE              = 'idle',
    SHEATHING         = 'sheathing',
    POST_UNREADY      = 'postUnreadyPause',
    EQUIP_NEW         = 'equipNew',
    POST_EQUIP        = 'postEquipPause',
    DRAWING           = 'drawing',
}

local state = {
    phase          = PHASE.IDLE,
    timer          = 0,
    drawRetryTimer = 0,
    oldItem        = nil,
    newItem        = nil,
}

-- Last-seen values, refreshed at the END of every onUpdate tick that is not
-- mid-swap. Used to detect external swaps initiated by the player UI / hotkey.
local lastWeapon = nil
local lastStance = STANCE.Nothing

local function abortSwap(reason)
    log("Abort swap (%s) at phase=%s", reason or "?", state.phase)
    state.phase          = PHASE.IDLE
    state.timer          = 0
    state.drawRetryTimer = 0
    state.oldItem        = nil
    state.newItem        = nil
    lastWeapon           = getCarriedRight()
    lastStance           = Actor.getStance(self)
end

local function applyTransitionAnimationSpeed()
    local speed = tonumber(CONFIG.animationSpeed) or 1
    if speed <= 0 or speed == 1 then return end
    if not anim.hasAnimation(self) then return end

    local touched = {}
    for _, boneGroup in ipairs({ anim.BONE_GROUP.Torso, anim.BONE_GROUP.LeftArm, anim.BONE_GROUP.RightArm }) do
        local ok, groupName = pcall(anim.getActiveGroup, self, boneGroup)
        if ok and groupName and not touched[groupName] then
            touched[groupName] = true
            local hasSpeed, currentSpeed = pcall(anim.getSpeed, self, groupName)
            if hasSpeed and currentSpeed ~= nil then
                pcall(anim.setSpeed, self, groupName, speed)
            end
        end
    end
end

local function requestDraw()
    Actor.setStance(self, STANCE.Weapon)
    state.drawRetryTimer = 0
end

local function equipNewWeapon(item)
    -- Let the engine's standard item-use path settle weapon/shield interaction.
    -- Direct setEquipment works for simple weapon swaps, but can leave the
    -- carried-left shield visual/stance state stale.
    core.sendGlobalEvent('UseItem', { object = item, actor = self })
end

local function startSwap(oldItem, newItem)
    log("Start swap: %s -> %s",
        itemId(oldItem),
        itemId(newItem))
    state.phase   = PHASE.SHEATHING
    state.timer   = 0
    state.drawRetryTimer = 0
    state.oldItem = oldItem
    state.newItem = newItem
    -- Restore the previous weapon silently so the sheathe animation plays the
    -- correct mesh. The player already triggered the swap, so the engine has
    -- the new weapon in CarriedRight; put the old one back before sheathing.
    setEquipmentSlot(SLOT.CarriedRight, oldItem)
    Actor.setStance(self, STANCE.Nothing)
end

local function advance(dt)
    state.timer = state.timer + dt

    if state.timer > CONFIG.maxPhaseSeconds then
        abortSwap("phase timeout")
        return
    end

    local stance = Actor.getStance(self)

    if state.phase == PHASE.SHEATHING then
        applyTransitionAnimationSpeed()

        -- Wait for the sheathe animation: stance becomes Nothing once the
        -- weapon is fully holstered. We also accept "weapon slot is empty
        -- visually" as a fallback by just trusting the stance value here.
        if stance == STANCE.Nothing then
            log("Sheathed.")
            state.phase = PHASE.POST_UNREADY
            state.timer = 0
        end
        return
    end

    if state.phase == PHASE.POST_UNREADY then
        if state.timer >= CONFIG.postUnreadyDelay then
            state.phase = PHASE.EQUIP_NEW
            state.timer = 0
        end
        return
    end

    if state.phase == PHASE.EQUIP_NEW then
        equipNewWeapon(state.newItem)
        log("Requested native equip for new weapon (sheathed).")
        state.phase = PHASE.POST_EQUIP
        state.timer = 0
        return
    end

    if state.phase == PHASE.POST_EQUIP then
        if not sameItem(getCarriedRight(), state.newItem) then
            if state.timer >= 0.5 then
                log("Native equip has not settled; applying direct equipment fallback.")
                setEquipmentSlot(SLOT.CarriedRight, state.newItem)
                state.timer = 0
            end
            return
        end

        if state.timer >= CONFIG.postEquipDrawDelay then
            requestDraw()
            state.phase = PHASE.DRAWING
            state.timer = 0
        end
        return
    end

    if state.phase == PHASE.DRAWING then
        applyTransitionAnimationSpeed()

        if stance == STANCE.Weapon then
            log("Draw complete.")
            state.phase = PHASE.IDLE
            state.timer = 0
            state.drawRetryTimer = 0
            -- Refresh tracking so the just-completed swap is not re-detected.
            lastWeapon = getCarriedRight()
            lastStance = stance
            state.oldItem = nil
            state.newItem = nil
            return
        end

        state.drawRetryTimer = state.drawRetryTimer + dt
        if state.drawRetryTimer >= CONFIG.drawRetryInterval then
            requestDraw()
        end
        return
    end
end

-- ---------------------------------------------------------------------------
-- Engine handler
-- ---------------------------------------------------------------------------

local function onUpdate(dt)
    if not CONFIG.enabled then
        if state.phase ~= PHASE.IDLE then abortSwap("disabled") end
        lastWeapon = getCarriedRight()
        lastStance = Actor.getStance(self)
        return
    end

    if state.phase ~= PHASE.IDLE then
        advance(dt)
        return
    end

    local stance = Actor.getStance(self)
    local weapon = getCarriedRight()

    if not sameItem(weapon, lastWeapon) or stance ~= lastStance then
        log("Observed idle state: weapon=%s stance=%s lastWeapon=%s lastStance=%s",
            itemId(weapon),
            tostring(stance),
            itemId(lastWeapon),
            tostring(lastStance))
    end

    -- Detection: intervene when the previous frame had the weapon drawn and
    -- the carried-right item changed to a different weapon-like item. Do not
    -- require the current frame to still be Weapon: OpenMW can update stance
    -- and equipment in the same frame, depending on whether the swap came
    -- from inventory UI, hotkey, or another Lua mod.
    if lastStance == STANCE.Weapon
       and lastWeapon ~= nil
       and weapon ~= nil
       and isWeaponLike(weapon)
       and isWeaponLike(lastWeapon)
       and not sameItem(weapon, lastWeapon)
    then
        startSwap(lastWeapon, weapon)
        return
    end

    lastWeapon = weapon
    lastStance = stance
end

local function onLoad()
    state.phase   = PHASE.IDLE
    state.timer   = 0
    state.drawRetryTimer = 0
    state.oldItem        = nil
    state.newItem        = nil
    lastWeapon = getCarriedRight()
    lastStance = Actor.getStance(self)
    log("State initialized. weapon=%s stance=%s",
        itemId(lastWeapon),
        tostring(lastStance))
end

local function onSave()
    -- Nothing to persist: the swap is purely transient visual sequencing.
    return nil
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onInit   = onLoad,
        onLoad   = onLoad,
        onSave   = onSave,
    },
}
