---@diagnostic disable: undefined-global

-- weapons_sheath_when_equip_change/main.lua
--
-- Intercepts weapon equip events and replays them as a sheathe -> draw sequence.
--
-- Active flow:
--   1. onEquip fires before the vanilla equip. We BLOCK the vanilla equip (e.block=true)
--      so the engine never updates readiedWeapon / weaponDrawn / equipped slot. Then we
--      queue our own swap with a clean snapshot of the pre-equip state.
--   2. State machine (driven by onSimulate + onWeaponUnreadied):
--        waitingForUnreadied -> equipNew -> waitingForReadied
--   3. onEquipped is only a defensive observer that clears stale captured state.
--
-- Why we block instead of restoring after the fact: the vanilla quickslot path begins
-- the sheathe of the previous weapon AFTER updating readiedWeapon to point at the new
-- weapon. The sheathe animation then renders the new weapon's mesh in the player's hand,
-- which is the visible "weapon morphs mid-sheathe" glitch. tes3.equip with
-- bypassEquipEvents=true cannot rewrite readiedWeapon, so it cannot fix this after the
-- fact. Blocking is the only way to keep readiedWeapon pointing at the previous weapon
-- while the sheathe animation plays.
--
-- Key invariant: ALL internal equip calls use tes3.equip({bypassEquipEvents=true}).
-- mobile:equip() always fires the equip Lua event; tes3.equip with bypassEquipEvents=true
-- does not. This prevents our own equip calls from re-triggering the handlers.
--
-- Known quirk: vanilla quickslot sets MobilePlayer::weaponReady (plain bool, 0x5BD) to
-- false BEFORE firing the equip event, so reading weaponReady at equip-event time returns
-- false even when the weapon is still physically drawn. We read mobile.weaponDrawn
-- (the WeaponDrawn actorFlag) instead, which vanilla does NOT clear before the event.

local MOD_ID = "weapons_sheath_when_equip_change"
local ACTIVE_SWAP_TIMEOUT_SECONDS = 3.0
local SUPPORTED_HAND_OBJECT_TYPES = {
    [tes3.objectType.weapon]   = true,
    [tes3.objectType.lockpick] = true,
    [tes3.objectType.probe]    = true,
}
local FALLBACK_HAND_OBJECT_TYPES = {
    tes3.objectType.lockpick,
    tes3.objectType.probe,
}
local QUICKSLOT_KEYBIND_TO_SLOT = {
    [tes3.keybind.quick1] = 1,
    [tes3.keybind.quick2] = 2,
    [tes3.keybind.quick3] = 3,
    [tes3.keybind.quick4] = 4,
    [tes3.keybind.quick5] = 5,
    [tes3.keybind.quick6] = 6,
    [tes3.keybind.quick7] = 7,
    [tes3.keybind.quick8] = 8,
    [tes3.keybind.quick9] = 9,
}

local config = require(MOD_ID .. ".config")
local logger = require(MOD_ID .. ".util.logger")

require(MOD_ID .. ".mcm")

local runtime = {
    activeSwap       = nil,
    pendingSwap      = nil,
    capturedPrevious = nil, -- state captured in onEquip before the vanilla equip changes inventory
    trackedDrawn     = false,
    trackedWeapon    = nil,
}

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function getNow()
    return os.clock()
end

local function setSwapPhase(swap, phase)
    swap.phase = phase
    swap.phaseStartedAt = getNow()
end

local function getSwapElapsedTime(swap)
    if not swap or not swap.phaseStartedAt then return 0 end
    return getNow() - swap.phaseStartedAt
end

local function getFeatureFlags()
    return config.get().featureFlags or {}
end

local function isModEnabled()
    return getFeatureFlags().enabled ~= false
end

local function isWeapon(item)
    return item ~= nil and SUPPORTED_HAND_OBJECT_TYPES[item.objectType] == true
end

local function makeWeaponSnapshot(item, itemData)
    if not isWeapon(item) then return nil end
    return { item = item, itemData = itemData }
end

local function usesWeaponReadyState(weapon)
    return weapon ~= nil
        and weapon.item ~= nil
        and weapon.item.objectType == tes3.objectType.weapon
end

local function captureCurrentWeapon(mobile)
    if not mobile then return nil end

    local weaponStack = tes3.getEquippedItem({ actor = mobile, objectType = tes3.objectType.weapon })
    if weaponStack then
        return makeWeaponSnapshot(weaponStack.object, weaponStack.itemData)
    end

    for _, objectType in ipairs(FALLBACK_HAND_OBJECT_TYPES) do
        local stack = tes3.getEquippedItem({ actor = mobile, objectType = objectType })
        if stack then return makeWeaponSnapshot(stack.object, stack.itemData) end
    end

    if mobile.readiedWeapon then
        return makeWeaponSnapshot(mobile.readiedWeapon.object, mobile.readiedWeapon.itemData)
    end

    return nil
end

local function captureEquippedHandItem(mobile)
    if not mobile then return nil end

    local weaponStack = tes3.getEquippedItem({ actor = mobile, objectType = tes3.objectType.weapon })
    if weaponStack then
        return makeWeaponSnapshot(weaponStack.object, weaponStack.itemData)
    end

    for _, objectType in ipairs(FALLBACK_HAND_OBJECT_TYPES) do
        local stack = tes3.getEquippedItem({ actor = mobile, objectType = objectType })
        if stack then return makeWeaponSnapshot(stack.object, stack.itemData) end
    end

    return nil
end

local function captureQuickslotWeapon(keybind)
    local slot = QUICKSLOT_KEYBIND_TO_SLOT[keybind]
    if not slot then return nil end

    local quickKey = tes3.getQuickKey({ slot = slot })
    if not quickKey then return nil end

    local item, itemData = quickKey:getItem()
    if not isWeapon(item) then return nil end

    return makeWeaponSnapshot(item, itemData)
end

local function sameWeapon(left, right)
    if left == nil or right == nil then return left == right end
    -- Keep itemData on snapshots so internalEquip can target a specific stack when
    -- needed, but do NOT use it as a state-machine identity check. Once a weapon is
    -- equipped/readied, MWSE can surface a different itemData pointer for what is
    -- functionally and visually the same weapon, which caused waitingForReadied to
    -- loop forever re-equipping the already-equipped weapon.
    return left.item == right.item
end

local function describeWeapon(weapon)
    if not weapon or not weapon.item then return "<none>" end
    return weapon.item.id or weapon.item.name or "<unknown>"
end

local function isHandItemVisible(mobile, weapon)
    if not mobile or not weapon then return false end

    local current = captureCurrentWeapon(mobile)
    if not sameWeapon(current, weapon) then return false end

    if usesWeaponReadyState(weapon) then
        return mobile.weaponReady == true and mobile.weaponDrawn == true
    end

    return true
end

local function syncTrackedState(mobile)
    runtime.trackedWeapon = captureCurrentWeapon(mobile)
    runtime.trackedDrawn  = isHandItemVisible(mobile, runtime.trackedWeapon)
end

local function resetRuntimeState()
    runtime.activeSwap       = nil
    runtime.pendingSwap      = nil
    runtime.capturedPrevious = nil
    syncTrackedState(tes3.mobilePlayer)
end

-- internalEquip: equips bypassing the equip Lua event so onEquip never
-- intercepts swap-driven calls. mobile:equip() always fires the event;
-- tes3.equip with bypassEquipEvents=true does not.
local function internalEquip(weapon, playSound)
    if not weapon then return false end

    return tes3.equip({
        reference         = tes3.player,
        item              = weapon.item,
        itemData          = weapon.itemData,
        bypassEquipEvents = true,
        playSound         = playSound ~= false,
    })
end

local function canAdvanceSwap(mobile)
    return mobile ~= nil
        and tes3ui.menuMode() == false
        and mobile.canAct == true
        and mobile.isAttackingOrCasting == false
end

local function canStartPendingSwap(mobile, swap)
    if not mobile or tes3ui.menuMode() then return false end
    return canAdvanceSwap(mobile)
end

local function queueSwap(params)
    if not params.newWeapon then return end

    runtime.pendingSwap = {
        newWeapon               = params.newWeapon,
        previousWeapon          = params.previousWeapon,
        previousDrawn           = params.previousDrawn == true,
        restoreOldBeforeSheathe = params.restoreOldBeforeSheathe == true,
        source                  = params.source or "unknown",
    }

    logger.debug(
        "Queued swap (%s): %s -> %s",
        runtime.pendingSwap.source,
        describeWeapon(runtime.pendingSwap.previousWeapon),
        describeWeapon(runtime.pendingSwap.newWeapon)
    )
end

local function finishActiveSwap(success)
    local activeSwap = runtime.activeSwap
    if not activeSwap then return end

    if success then
        logger.debug("Completed swap (%s): %s", activeSwap.source, describeWeapon(activeSwap.newWeapon))
    else
        logger.warn("Aborted swap (%s): %s", activeSwap.source, describeWeapon(activeSwap.newWeapon))
    end

    local m = tes3.mobilePlayer
    mwse.log(
        "[WSE DIAG finishActiveSwap] success=%s phase=%s weapon=%s weaponReady=%s weaponDrawn=%s isReadyingWeapon=%s",
        tostring(success),
        activeSwap.phase or "nil",
        describeWeapon(activeSwap.newWeapon),
        m and tostring(m.weaponReady) or "nil",
        m and tostring(m.weaponDrawn) or "nil",
        m and tostring(m.isReadyingWeapon) or "nil"
    )

    runtime.activeSwap = nil
    syncTrackedState(tes3.mobilePlayer)
end

local function clearTimedOutActiveSwap()
    local activeSwap = runtime.activeSwap
    if not activeSwap then return false end

    local elapsed = getSwapElapsedTime(activeSwap)
    if elapsed < ACTIVE_SWAP_TIMEOUT_SECONDS then return false end

    logger.warn(
        "Resetting timed out swap (%s / %s) after %.2fs: %s -> %s",
        activeSwap.source, activeSwap.phase or "unknown", elapsed,
        describeWeapon(activeSwap.previousWeapon),
        describeWeapon(activeSwap.newWeapon)
    )

    finishActiveSwap(false)
    return true
end

local function tryStartPendingSwap(reason)
    if runtime.activeSwap then return end

    local swap = runtime.pendingSwap
    if not swap then return end

    local mobile = tes3.mobilePlayer
    if not canStartPendingSwap(mobile, swap) then return end

    local currentWeapon = captureCurrentWeapon(mobile)
    if not swap.forceReplay and sameWeapon(currentWeapon, swap.newWeapon) then
        logger.debug("Dropped redundant swap: %s", describeWeapon(swap.newWeapon))
        runtime.pendingSwap = nil
        syncTrackedState(mobile)
        return
    end

    runtime.pendingSwap = nil
    runtime.activeSwap  = swap

    logger.debug(
        "Starting swap (%s / %s): %s -> %s",
        swap.source, reason or "unknown",
        describeWeapon(swap.previousWeapon),
        describeWeapon(swap.newWeapon)
    )

    -- DIAG: log state at swap-start time.
    local m = tes3.mobilePlayer
    if m then
        mwse.log(
            "[WSE DIAG tryStart] source=%s reason=%s previousDrawn=%s restoreOldBeforeSheathe=%s weaponReady=%s weaponDrawn=%s isReadyingWeapon=%s canAct=%s",
            swap.source or "unknown",
            reason or "unknown",
            tostring(swap.previousDrawn),
            tostring(swap.restoreOldBeforeSheathe == true),
            tostring(m.weaponReady),
            tostring(m.weaponDrawn),
            tostring(m.isReadyingWeapon),
            tostring(m.canAct)
        )
    end

    if swap.restoreOldBeforeSheathe and swap.previousWeapon then
        local restored = internalEquip(swap.previousWeapon, false)
        if not restored then
            logger.warn("Failed to restore previous weapon before replay: %s", describeWeapon(swap.previousWeapon))
        end
        setSwapPhase(swap, "waitingForPreviousVisible")
        return
    end

    -- Always enter the unready phase when the previous weapon was drawn.
    -- previousDrawn is captured from mobile.weaponDrawn (the actual WeaponDrawn actorFlag)
    -- which vanilla quickslot does NOT clear before the equip event — it only clears
    -- mobile.weaponReady (the player desired-state bool at 0x5BD). weaponDrawn is only
    -- cleared when the sheathe animation physically completes via OnUnreadyWeapon.
    if swap.previousDrawn then
        mobile.weaponReady = false
        setSwapPhase(swap, "waitingForUnreadied")
        return
    end

    setSwapPhase(swap, "equipNew")
end

local function advanceActiveSwap()
    local swap = runtime.activeSwap
    if not swap then return end

    local mobile = tes3.mobilePlayer
    if not mobile then runtime.activeSwap = nil; return end

    if tes3ui.menuMode() then return end

    -- Phase: re-equip old weapon and wait until it is visually in hand.
    if swap.phase == "waitingForPreviousVisible" then
        if not isHandItemVisible(mobile, swap.previousWeapon) then
            if not canStartPendingSwap(mobile, swap) then return end

            local restored = internalEquip(swap.previousWeapon, false)
            if restored then swap.phaseStartedAt = getNow() end
            return
        end

        if usesWeaponReadyState(swap.previousWeapon) and mobile.weaponReady then
            mobile.weaponReady = false
            setSwapPhase(swap, "waitingForUnreadied")
            return
        end

        setSwapPhase(swap, "equipNew")
        return
    end

    -- Phase: wait for the sheathe animation to finish.
    -- Primary trigger: onWeaponUnreadied sets swap.weaponUnreadiedFired = true (event-driven).
    -- Polling fallback: also exits when isReadyingWeapon clears (covers edge cases).
    if swap.phase == "waitingForUnreadied" then
        if mobile.weaponReady then
            mobile.weaponReady = false
            swap.phaseStartedAt = getNow()
            return
        end

        -- Wait while the sheathe animation is still in progress.
        if mobile.isReadyingWeapon then return end

        -- Wait until we get confirmation the weapon is fully unreadied. This comes either
        -- from the weaponUnreadied event (reliable) or from weaponDrawn clearing (fallback).
        if not swap.weaponUnreadiedFired and mobile.weaponDrawn then return end

        mwse.log(
            "[WSE DIAG waitingForUnreadied->exit] elapsed=%.3fs eventFired=%s weaponReady=%s weaponDrawn=%s isReadyingWeapon=%s canAct=%s",
            getSwapElapsedTime(swap),
            tostring(swap.weaponUnreadiedFired == true),
            tostring(mobile.weaponReady),
            tostring(mobile.weaponDrawn),
            tostring(mobile.isReadyingWeapon),
            tostring(mobile.canAct)
        )
        setSwapPhase(swap, "equipNew")
        return
    end

    -- Phase: equip the new weapon (sheathed at hip, not yet drawn).
    if swap.phase == "equipNew" then
        if not canAdvanceSwap(mobile) then return end

        local equipped = internalEquip(swap.newWeapon, false)
        if not equipped then
            logger.warn("Failed to equip queued weapon: %s", describeWeapon(swap.newWeapon))
            finishActiveSwap(false)
            return
        end

        mwse.log(
            "[WSE DIAG equipNew] weapon=%s weaponReady=%s weaponDrawn=%s readiedWeapon=%s",
            describeWeapon(swap.newWeapon),
            tostring(mobile.weaponReady),
            tostring(mobile.weaponDrawn),
            mobile.readiedWeapon and tostring(mobile.readiedWeapon.object.id) or "nil"
        )

        mobile.weaponReady = true
        setSwapPhase(swap, "waitingForReadied")
        return
    end

    -- Phase: wait for the draw animation to complete.
    if swap.phase == "waitingForReadied" then
        local currentWeapon = captureCurrentWeapon(mobile)
        if not sameWeapon(currentWeapon, swap.newWeapon) then
            if not canAdvanceSwap(mobile) then return end

            mwse.log(
                "[WSE DIAG waitingForReadied REEQUIP] currentWeapon=%s newWeapon=%s weaponReady=%s weaponDrawn=%s isReadyingWeapon=%s readiedWeapon=%s",
                currentWeapon and describeWeapon(currentWeapon) or "nil",
                describeWeapon(swap.newWeapon),
                tostring(mobile.weaponReady),
                tostring(mobile.weaponDrawn),
                tostring(mobile.isReadyingWeapon),
                mobile.readiedWeapon and tostring(mobile.readiedWeapon.object.id) or "nil"
            )

            local equipped = internalEquip(swap.newWeapon, false)
            if not equipped then
                logger.warn("Failed to re-equip active weapon: %s", describeWeapon(swap.newWeapon))
                finishActiveSwap(false)
                return
            end

            mobile.weaponReady = true
            return
        end

        if mobile.isReadyingWeapon then return end

        if not usesWeaponReadyState(swap.newWeapon) then
            finishActiveSwap(true)
            return
        end

        if not mobile.weaponReady then
            if canAdvanceSwap(mobile) then
                logger.debug("Retrying draw for equipped weapon: %s", describeWeapon(swap.newWeapon))
                mwse.log("[WSE DIAG waitingForReadied RETRY] weaponReady=%s weaponDrawn=%s isReadyingWeapon=%s readiedWeapon=%s",
                    tostring(mobile.weaponReady), tostring(mobile.weaponDrawn), tostring(mobile.isReadyingWeapon),
                    mobile.readiedWeapon and tostring(mobile.readiedWeapon.object.id) or "nil")
                mobile.weaponReady = true
                swap.phaseStartedAt = getNow()
            end
            return
        end

        if not mobile.weaponDrawn then return end

        finishActiveSwap(true)
    end
end

-- ---------------------------------------------------------------------------
-- Event registration
-- ---------------------------------------------------------------------------

local function onQuickslotKeybindTested(e)
    if not isModEnabled() then return end
    if e.transition ~= tes3.keyTransition.downThisFrame or not e.result then return end

    local requestedWeapon = captureQuickslotWeapon(e.keybind)
    if not requestedWeapon then return end

    local mobile = tes3.mobilePlayer
    if not mobile or tes3ui.menuMode() then return end

    local currentWeapon = captureCurrentWeapon(mobile)
    if sameWeapon(currentWeapon, requestedWeapon) then return end

    e.result = false
    e.block = true
    e.claim = true

    mwse.log(
        "[WSE DIAG block-only keybind] blocked item=%s slot=%s",
        requestedWeapon.item and requestedWeapon.item.id or "nil",
        tostring(QUICKSLOT_KEYBIND_TO_SLOT[e.keybind])
    )
end

local function onEquip(e)
    if not isModEnabled() then return end
    if e.reference ~= tes3.player or not isWeapon(e.item) then return end

    -- If a swap is already running, don't intercept — let our internalEquip calls
    -- (which use bypassEquipEvents=true) and any unrelated equips proceed normally.
    if runtime.activeSwap then
        runtime.capturedPrevious = nil
        return
    end

    local mobile = tes3.mobilePlayer
    if not mobile then return end

    local requestedWeapon = makeWeaponSnapshot(e.item, e.itemData)

    -- Some hotkey mods (e.g. Hotkeys Extended) call mobilePlayer:unequip{} on the
    -- current weapon BEFORE firing the equip event, then equip the new one. By the
    -- time we get here, the old weapon may already be unequipped (no longer present
    -- in the equipped weapon slot). In that case captureCurrentWeapon would return
    -- nil and we'd lose the previous-weapon context. Use the tracked state captured
    -- in the previous simulate tick as the source of truth for the previous weapon.
    local currentWeapon = captureCurrentWeapon(mobile) or runtime.trackedWeapon

    -- No previous weapon, or equipping the same weapon: nothing to intercept.
    if not currentWeapon or sameWeapon(currentWeapon, requestedWeapon) then
        runtime.capturedPrevious = nil
        return
    end

    -- Drawn-state source of truth: the tracked state from before this swap began.
    -- mobile.weaponDrawn at this moment is unreliable when another mod has already
    -- called unequip; rely on what we observed in the last simulate tick instead.
    local previousDrawn = runtime.trackedDrawn == true

    -- If a third party already unequipped the previous weapon, the engine has
    -- mutated the visual attachment (and possibly readiedWeapon). Restore the
    -- previous weapon silently so our state machine can sheathe the correct mesh.
    local currentlyEquipped = captureEquippedHandItem(mobile)
    if not sameWeapon(currentlyEquipped, currentWeapon) then
        local restored = internalEquip(currentWeapon, false)
        mwse.log(
            "[WSE DIAG onEquip restore-after-external-unequip] prev=%s currentEquipped=%s restored=%s",
            describeWeapon(currentWeapon),
            describeWeapon(currentlyEquipped),
            tostring(restored)
        )
    end

    mwse.log("[WSE DIAG onEquip block] new=%s prev=%s prevDrawn=%s menuMode=%s",
        describeWeapon(requestedWeapon), describeWeapon(currentWeapon),
        tostring(previousDrawn), tostring(tes3ui.menuMode()))

    -- Block the vanilla equip so the engine never updates readiedWeapon / equipped
    -- slot / weaponDrawn. Our state machine will perform the swap from a clean state.
    e.block = true
    runtime.capturedPrevious = nil

    queueSwap({
        newWeapon               = requestedWeapon,
        previousWeapon          = currentWeapon,
        previousDrawn           = previousDrawn,
        restoreOldBeforeSheathe = false,
        source                  = "equip-blocked",
    })

    tryStartPendingSwap("equip-blocked")
end

local function onEquipped(e)
    if not isModEnabled() then return end
    if e.reference ~= tes3.player or not isWeapon(e.item) then return end

    -- onEquip blocks vanilla equips, so this path is normally only reached for our
    -- own internalEquip calls (which use bypassEquipEvents=true and shouldn't even
    -- fire equipped). Just drop any stale captured state here so it can't leak into
    -- a future swap.
    if runtime.activeSwap then return end
    runtime.capturedPrevious = nil
end

local function onInitialized()
    config.load()
    resetRuntimeState()
    logger.info("Initialized.")
end

local function onLoaded()
    resetRuntimeState()
    logger.debug("Runtime state synced after load.")
end

local function onSimulate()
    if not isModEnabled() then
        runtime.activeSwap  = nil
        runtime.pendingSwap = nil
        syncTrackedState(tes3.mobilePlayer)
        return
    end

    clearTimedOutActiveSwap()
    advanceActiveSwap()
    if runtime.activeSwap then return end

    if runtime.pendingSwap then
        tryStartPendingSwap("simulate")
        if runtime.activeSwap then return end
    end

    if not runtime.activeSwap and not runtime.pendingSwap then
        syncTrackedState(tes3.mobilePlayer)
    end
end

-- Driven by the weaponUnreadied event to reliably advance the waitingForUnreadied
-- phase. This fires inside OnUnreadyWeapon after the sheathe animation physically
-- completes, so it is the definitive signal that the weapon is no longer drawn.
local function onWeaponUnreadied(e)
    if e.reference ~= tes3.player then return end
    mwse.log("[WSE DIAG weaponUnreadied] phase=%s activeSwap=%s",
        runtime.activeSwap and runtime.activeSwap.phase or "nil",
        tostring(runtime.activeSwap ~= nil)
    )
    local swap = runtime.activeSwap
    if swap and swap.phase == "waitingForUnreadied" then
        swap.weaponUnreadiedFired = true
    end
end

event.register(tes3.event.equip,           onEquip)
event.register(tes3.event.equipped,        onEquipped)
event.register(tes3.event.weaponUnreadied, onWeaponUnreadied)
event.register(tes3.event.initialized,     onInitialized)
event.register(tes3.event.loaded,          onLoaded)
event.register(tes3.event.simulate,        onSimulate)
