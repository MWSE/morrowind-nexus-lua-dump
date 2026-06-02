--[[
    Spellsword! Skill — Global Script

    Bridge between our player-side skill state and base Spellsword's
    IW_ActiveSpell / SettingsImbuleWeapon globalSections.

    Responsibilities (global scope only):
      * Receive mirrored settings from the player script and persist them
        to our own Runtime_SpellswordSkill globalSection so any global-scope
        read inside this file can pull them back.
      * Listen to IW_SpellCast events from Spellsword. After a one-tick
        delay (so base Spellsword's handler has finished storing the cast),
        override the stored `activeSpell.charges` to our skill-scaled value
        (or remove the entry entirely if invalid).
      * Listen to IW_DecrementSpellCharge to forward "chargeSpend" XP grants
        to the player script (where I.SkillFramework.skillUsed lives).
      * Continuously drive the base Spellsword settings the player asked us
        to manage: ElementalBuffAmount, SpellStacking. We snapshot the
        user's original values on first override, and restore that snapshot
        when our skill mod is disabled at runtime.

    Cross-script ordering note:
      OpenMW does not guarantee event delivery order across scripts. For
      IW_SpellCast we must run AFTER base Spellsword's handleNewSpell so
      our override sticks. We queue the override and apply it on the next
      onUpdate tick, by which point base Spellsword's writeback has completed.
      This is the same "delayed override" pattern Skill Framework uses for
      modifySkill calls that race with engine state recovery.
]]

local core    = require('openmw.core')
local storage = require('openmw.storage')

local config = require('scripts.spellsword_skill.config')

local MODNAME = 'Spellsword'

-- ─── Mirrored player settings ──────────────────────────────────────────────

local runtimeSection = storage.globalSection('Runtime_SpellswordSkill')

local function setRuntime(key, value)
    runtimeSection:set(key, value)
end

local function getRuntime(key, default)
    local v = runtimeSection:get(key)
    if v == nil then return default end
    return v
end

local function onSyncSettings(payload)
    if type(payload) ~= 'table' then return end
    for k, v in pairs(payload) do
        setRuntime(k, v)
    end
end

-- ─── Base Spellsword settings handle ───────────────────────────────────────
-- The base mod registers its group as `SettingsImbuleWeapon` with
-- `permanentStorage = false` (see ImbuleWeapon_settingsGlobal.lua).
-- That means we can write to it freely from a global script and the writes
-- are session-scoped — exactly what we want for a runtime override.

local spellswordSettings = storage.globalSection('SettingsImbuleWeapon')

local function debugEnabled(category)
    if not getRuntime('debugMessages', false) then return false end
    if not category then return true end
    return getRuntime(category, false)
end

local function debugLog(msg, category)
    if debugEnabled(category) then
        print('[Spellsword! global] ' .. tostring(msg))
    end
end

-- ─── Mechanic math (mirrors init.lua but reads from runtime section) ──────

local function clampInt(value, fallback, lo, hi)
    value = tonumber(value) or fallback
    value = math.floor(value)
    if value < lo then value = lo end
    if value > hi then value = hi end
    return value
end

local function clampNum(value, fallback, lo, hi)
    value = tonumber(value) or fallback
    if value < lo then value = lo end
    if value > hi then value = hi end
    return value
end

local function currentSkill()
    return clampInt(getRuntime('currentSkill', config.startLevel), config.startLevel, 0, 9999)
end

local function effectiveMilestoneInterval()
    return clampInt(getRuntime('milestoneInterval', config.charges.milestoneInterval),
        config.charges.milestoneInterval, 1, 100)
end

local function milestonesPassedAt(skill, interval)
    interval = interval or effectiveMilestoneInterval()
    if interval <= 0 then return 0 end
    return math.floor((tonumber(skill) or 0) / interval)
end

local function chargesAtSkill(skill)
    local base = clampInt(getRuntime('baseCharges', config.charges.baseCharges),
        config.charges.baseCharges, 0, 9999)
    local step = clampInt(getRuntime('chargesPerMilestone', config.charges.chargesPerMilestone),
        config.charges.chargesPerMilestone, 0, 9999)
    local cap = clampInt(getRuntime('maxCharges', config.charges.maxCharges),
        config.charges.maxCharges, 0, 9999)
    local total = base + milestonesPassedAt(skill) * step
    if total > cap then total = cap end
    if total < 0 then total = 0 end
    return total
end

local function elementalBuffAtSkill(skill)
    local base = clampNum(getRuntime('baseElementalBuff', config.elementalBuff.baseBuff),
        config.elementalBuff.baseBuff, 0, 999)
    local step = clampNum(getRuntime('elementalStepPerMilestone', config.elementalBuff.stepPerMilestone),
        config.elementalBuff.stepPerMilestone, 0, 999)
    local cap = clampNum(getRuntime('maxElementalBuff', config.elementalBuff.maxBuff),
        config.elementalBuff.maxBuff, 0, 999)
    local total = base + milestonesPassedAt(skill) * step
    if total > cap then total = cap end
    if total < 0 then total = 0 end
    return total
end

local function spellStackingUnlocked(skill)
    if not getRuntime('allowSpellStacking', true) then return false end
    local unlock = clampInt(getRuntime('spellStackingUnlockLevel', config.spellStacking.unlockLevel),
        config.spellStacking.unlockLevel, 0, 9999)
    return (tonumber(skill) or 0) >= unlock
end

-- ─── Perk gating (global side) ─────────────────────────────────────────────

local function allPerksEnabled()
    return getRuntime('enableAllPerks', true)
end

local function perkActive(perkId, skill)
    if not allPerksEnabled() then return false end
    local levelKey = ({
        lingeringImbue  = 'lingeringImbueLevel',
        arcaneFlow      = 'arcaneFlowLevel',
        perfectConduit  = 'perfectConduitLevel',
        arcaneOverdrive = 'arcaneOverdriveLevel',
    })[perkId]
    if not levelKey then return false end
    local enableKey = ({
        lingeringImbue  = 'enableLingeringImbue',
        arcaneFlow      = 'enableArcaneFlow',
        perfectConduit  = 'enablePerfectConduit',
        arcaneOverdrive = 'enableArcaneOverdrive',
    })[perkId]
    if not getRuntime(enableKey, true) then return false end
    local level = tonumber(config.perks[levelKey]) or 999
    return (tonumber(skill) or 0) >= level
end

local function isOverdriveActive(skill)
    if not perkActive('arcaneOverdrive', skill) then return false end
    return getRuntime('overdriveActive', false) and true or false
end

-- ─── Valid imbue spell gate ────────────────────────────────────────────────

local function isValidImbueSpellId(id)
    if type(id) ~= 'string' then return false end
    return config.validImbueSpellIds[id] == true
end

-- ─── Snapshot + restore of base Spellsword settings ────────────────────────
-- We capture the player's pre-override values for ElementalBuffAmount and
-- SpellStacking the first time we enable any drive; restore them when our
-- skill mod is disabled. Snapshots persist in our runtime section so a save
-- + reload doesn't lose the originals.

local SNAPSHOT_PREFIX = 'snapshot_'

local function snapshotIfNeeded(key)
    local snapKey = SNAPSHOT_PREFIX .. key
    if runtimeSection:get(snapKey) ~= nil then return end
    local current = spellswordSettings:get(key)
    if current == nil then return end
    runtimeSection:set(snapKey, current)
    debugLog('Snapshot stored for SettingsImbuleWeapon.' .. key
        .. ' = ' .. tostring(current), 'debugOverrideMessages')
end

local function restoreSnapshot(key)
    local snapKey = SNAPSHOT_PREFIX .. key
    local snap = runtimeSection:get(snapKey)
    if snap == nil then return end
    local current = spellswordSettings:get(key)
    if current == snap then return end
    spellswordSettings:set(key, snap)
    debugLog('Restored SettingsImbuleWeapon.' .. key .. ' to '
        .. tostring(snap) .. ' (from ' .. tostring(current) .. ')', 'debugOverrideMessages')
end

local function setSpellswordSetting(key, value)
    snapshotIfNeeded(key)
    local current = spellswordSettings:get(key)
    if current == value then return false end
    spellswordSettings:set(key, value)
    debugLog('Wrote SettingsImbuleWeapon.' .. key .. ' = '
        .. tostring(value) .. ' (was ' .. tostring(current) .. ')', 'debugOverrideMessages')
    return true
end

-- ─── Drive base Spellsword settings every tick ─────────────────────────────

local function driveSpellswordSettings()
    if not getRuntime('enabled', true) then
        -- Restore originals once on disable.
        restoreSnapshot('ElementalBuffAmount')
        restoreSnapshot('SpellStacking')
        return
    end

    local skill = currentSkill()

    if getRuntime('driveBaseElementalBuff', true) then
        local desired = elementalBuffAtSkill(skill)
        setSpellswordSetting('ElementalBuffAmount', desired)
    else
        restoreSnapshot('ElementalBuffAmount')
    end

    if getRuntime('driveSpellStacking', true) then
        local desired = spellStackingUnlocked(skill)
        setSpellswordSetting('SpellStacking', desired and true or false)
    else
        restoreSnapshot('SpellStacking')
    end
end

-- ─── Charge override (delayed by one tick after IW_SpellCast) ─────────────
-- Why delayed:
--   Base Spellsword's `handleNewSpell` (in ImbuleWeapon_g.lua) reads the
--   existing activeSpell from IW_ActiveSpell, and either overwrites or stacks
--   onto it. Our override needs to see the result of that write to decide
--   whether the cast was fresh (different id) or stacked (same id). Both
--   event handlers fire as part of the same event dispatch, so we queue the
--   override and consume it in the next onUpdate tick — by then handleNewSpell
--   has definitely completed.

local pendingOverride = nil
local lastObservedSpellId = nil
local lastObservedCharges = 0

-- The player object is captured by our SpellswordSkill_RequestInit handler
-- below. We declare it ABOVE applyPendingOverride and the charge handler so
-- the function bodies bind to this local (not a global of the same name).
local trackedPlayer = nil

local function onIWSpellCast(data)
    if not getRuntime('enabled', true) then return end
    if not getRuntime('driveCharges', true) then return end
    if type(data) ~= 'table' or type(data.spell) ~= 'table' then return end

    local spellId = data.spell.id
    if not isValidImbueSpellId(spellId) then
        -- Spellmaking / modded absorb-based spells reach here too. The
        -- requirement is that they NOT grant XP and NOT receive our
        -- charge scaling. We deliberately leave the original behaviour
        -- intact for those: don't override, don't credit XP.
        debugLog('IW_SpellCast for non-Spellsword imbue id=' .. tostring(spellId)
            .. ' — ignored (no override, no XP).', 'debugOverrideMessages')
        return
    end

    pendingOverride = {
        spellId = spellId,
        spellName = data.spell.name,
        firstUse = data.spell.firstUse,
        scheduledAt = core.getSimulationTime(),
    }
    debugLog('Queued charge override for ' .. tostring(spellId), 'debugOverrideMessages')
end

local function applyPendingOverride()
    if not pendingOverride then return end

    local store = storage.globalSection('IW_ActiveSpell')
    local stored = store:getCopy('activeSpell')
    if not stored then
        debugLog('applyPendingOverride: no activeSpell stored — discarding override.', 'debugOverrideMessages')
        pendingOverride = nil
        return
    end
    if stored.id ~= pendingOverride.spellId then
        debugLog('applyPendingOverride: stored id ' .. tostring(stored.id)
            .. ' != pending id ' .. tostring(pendingOverride.spellId)
            .. ' — discarding override.', 'debugOverrideMessages')
        pendingOverride = nil
        return
    end

    local skill = currentSkill()
    local ourCharges = chargesAtSkill(skill)
    local overdriveOn = isOverdriveActive(skill)

    -- Detect stacking by what the base mod actually wrote, not what our settings
    -- predict it should have done. That way our override stays correct even if
    -- the user has driveSpellStacking off and the base mod's SpellStacking is
    -- set independently.
    --
    --   - same spell id as before AND
    --   - base wrote a HIGHER charge count than was previously live AND
    --   - we actually had a previous live count
    --   → base stacked. Add our scaled charges to the previous live count.
    local wasStacked = (lastObservedSpellId == stored.id)
        and (tonumber(stored.charges) or 0) > (lastObservedCharges or 0)
        and (lastObservedCharges or 0) > 0

    local crossElementSourceId = nil   -- captured for Perfect Conduit trigger
    if wasStacked then
        local newCharges = (lastObservedCharges or 0) + ourCharges
        stored.charges = newCharges
        debugLog(string.format('Stacked cast: %d + %d (skill %d) = %d charges',
            lastObservedCharges or 0, ourCharges, skill, newCharges), 'debugOverrideMessages')
    else
        -- Lingering Imbue (Perk 25) carries previous charges into the new
        -- cast when the previous active spell was a DIFFERENT valid imbue.
        -- Arcane Overdrive (Perk 100) forces the same carry-over while its
        -- window is open, regardless of whether Lingering Imbue is enabled —
        -- "triple-element stacking" is delivered by combining the carry-over
        -- with the scaled charges of every fresh cast during the window.
        local carriedOver = 0
        local shouldCarry = (perkActive('lingeringImbue', skill) or overdriveOn)
            and lastObservedSpellId
            and lastObservedSpellId ~= stored.id
            and isValidImbueSpellId(lastObservedSpellId)
            and (lastObservedCharges or 0) > 0
        if shouldCarry then
            carriedOver = lastObservedCharges or 0
            crossElementSourceId = lastObservedSpellId
            debugLog(string.format(
                '%s carry-over: %d charges from %s → %s',
                overdriveOn and 'Overdrive' or 'Lingering Imbue',
                carriedOver, tostring(lastObservedSpellId), tostring(stored.id)
            ), 'debugOverrideMessages')
        end
        stored.charges = ourCharges + carriedOver
        if carriedOver > 0 then
            debugLog(string.format(
                'Fresh cast: %d charges + %d carry-over (skill %d) = %d total',
                ourCharges, carriedOver, skill, stored.charges
            ), 'debugOverrideMessages')
        else
            debugLog(string.format('Fresh cast: %d charges (skill %d)', ourCharges, skill), 'debugOverrideMessages')
        end
        -- Even without our Lingering-Imbue carry-over (e.g. perk locked), we
        -- still want to detect cross-element transitions for Perfect Conduit.
        if not crossElementSourceId
            and lastObservedSpellId
            and lastObservedSpellId ~= stored.id
            and isValidImbueSpellId(lastObservedSpellId)
        then
            crossElementSourceId = lastObservedSpellId
        end
    end

    store:set('activeSpell', stored)

    lastObservedSpellId = stored.id
    lastObservedCharges = stored.charges

    -- Perfect Conduit (Perk 75) trigger — global tells the player which
    -- transition happened; player decides whether the perk is enabled and
    -- applies the buff.
    if crossElementSourceId
        and perkActive('perfectConduit', skill)
        and trackedPlayer
    then
        trackedPlayer:sendEvent('SpellswordSkill_PerfectConduitTrigger', {
            from = crossElementSourceId,
            to   = stored.id,
        })
    end

    -- Forward apply XP to the player.
    if getRuntime('xpOnApply', true) then
        core.sendGlobalEvent('SpellswordSkill_GrantXp_Local', { useType = 'apply' })
    end

    pendingOverride = nil
end

-- ─── Track live activeSpell so we know how many charges remain ────────────
-- We refresh lastObservedSpellId/Charges every tick so that the next cast's
-- stack decision and our charge-spend XP forwarding both see accurate data.

local function refreshActiveSpellObservation()
    local store = storage.globalSection('IW_ActiveSpell')
    local stored = store:get('activeSpell')
    if not stored then
        lastObservedSpellId = nil
        lastObservedCharges = 0
        return
    end
    lastObservedSpellId = stored.id
    lastObservedCharges = tonumber(stored.charges) or 0
end

-- ─── IW_DecrementSpellCharge: detect charge consumption, forward XP ───────
-- Base Spellsword's decrementSpellCharge:
--   - if data.firstUse == nil → actual charge consumption (mode = Charges)
--   - else → flag update only (Active mode first-hit toggling)
-- We only want to award chargeSpend XP for genuine consumption events on a
-- valid Spellsword imbue. Active-mode magicka events are handled separately
-- in init.lua's IW_RemoveMagicka observer.

local function onIWDecrementSpellCharge(data)
    if not getRuntime('enabled', true) then return end
    if type(data) ~= 'table' then data = {} end

    -- Determine which spell is being decremented. The live IW_ActiveSpell is
    -- the most reliable signal, but base Spellsword RESETS activeSpell when
    -- the last charge is spent — and if our handler runs after the base one,
    -- the live store is already empty. Fall back to lastObservedSpellId (which
    -- we refresh every tick) so the final-charge XP grant still fires.
    local store = storage.globalSection('IW_ActiveSpell')
    local stored = store:get('activeSpell')
    local spellId = (stored and stored.id) or lastObservedSpellId
    if not isValidImbueSpellId(spellId) then return end

    if data.firstUse == nil then
        -- ─── Real charge spend (Charges mode) ──────────────────────────────
        local skill = currentSkill()

        -- Arcane Overdrive (Perk 100): during the window, every charge spend
        -- is refunded — charges effectively don't deplete.
        if isOverdriveActive(skill) then
            local activeStill = store:getCopy('activeSpell')
            if activeStill and activeStill.id == spellId then
                activeStill.charges = (tonumber(activeStill.charges) or 0) + 1
                store:set('activeSpell', activeStill)
                lastObservedCharges = activeStill.charges
                debugLog(string.format(
                    'Arcane Overdrive: charge refunded (now %d)', activeStill.charges
                ), 'debugOverrideMessages')
            end
        end

        -- Arcane Flow (Perk 50): forward charge-spend events to the player
        -- so the cooldown-gated magicka restore runs in one common place
        -- across both modes.
        if trackedPlayer then
            trackedPlayer:sendEvent('SpellswordSkill_ChargeSpent', { spellId = spellId })
        end

        -- XP grant (always fires for a charge-spend event, even if rescued —
        -- the player still struck with an imbued weapon, which is what
        -- advances the skill).
        if getRuntime('xpOnChargeSpend', true) then
            core.sendGlobalEvent('SpellswordSkill_GrantXp_Local', { useType = 'chargeSpend' })
        end
    else
        -- This is the Active-mode "first hit" flag toggle (firstUse=false
        -- sent after the free first hit). Award a small "first hit free" XP
        -- once if the user enabled it.
        if data.firstUse == false and getRuntime('xpOnFirstUseFree', true) then
            core.sendGlobalEvent('SpellswordSkill_GrantXp_Local', { useType = 'firstUseFree' })
        end
    end
end

-- We route XP forwarding through ourselves so we control the player target
-- lookup in one place. The XP grant ends up in the player handler
-- (init.lua: onGrantXp) which calls I.SkillFramework.skillUsed.
-- trackedPlayer is declared at the top of the file so applyPendingOverride
-- and onIWDecrementSpellCharge can reach it.

local function onRequestInit(data)
    if type(data) == 'table' and data.player then
        trackedPlayer = data.player
    end
end

local function onGrantXpLocal(data)
    if type(data) ~= 'table' then return end
    if not trackedPlayer then return end
    trackedPlayer:sendEvent('SpellswordSkill_GrantXp', data)
end

-- ─── onUpdate driver ───────────────────────────────────────────────────────

local updateTimer = 0

local function onUpdate(dt)
    dt = tonumber(dt) or 0

    -- Apply any pending charge override IMMEDIATELY each tick (no throttle):
    -- the user shouldn't wait half a second to see their imbue activate.
    applyPendingOverride()

    -- Refresh our view of the active spell every frame so charge math stays
    -- accurate for the next cast/stack decision.
    refreshActiveSpellObservation()

    -- Throttle settings drive to ~5 Hz. The base Spellsword hit handler reads
    -- ElementalBuffAmount at hit time, so as long as our value is in storage
    -- within ~200ms of any change, the player won't notice.
    updateTimer = updateTimer + dt
    if updateTimer < 0.2 then return end
    while updateTimer >= 0.2 do updateTimer = updateTimer - 0.2 end

    driveSpellswordSettings()
end

-- ─── Save / load ───────────────────────────────────────────────────────────
-- The snapshots live in runtimeSection (a globalSection), which is
-- automatically persisted. We restore them on load by re-reading.

local function onSave()
    return {
        lastObservedSpellId = lastObservedSpellId,
        lastObservedCharges = lastObservedCharges,
    }
end

local function onLoad(data)
    if type(data) == 'table' then
        lastObservedSpellId = data.lastObservedSpellId
        lastObservedCharges = tonumber(data.lastObservedCharges) or 0
    else
        lastObservedSpellId = nil
        lastObservedCharges = 0
    end
    pendingOverride = nil
    -- Re-sync our view in case the save was made mid-imbue.
    refreshActiveSpellObservation()
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave   = onSave,
        onLoad   = onLoad,
    },
    eventHandlers = {
        SpellswordSkill_SyncSettings  = onSyncSettings,
        SpellswordSkill_RequestInit   = onRequestInit,
        SpellswordSkill_GrantXp_Local = onGrantXpLocal,

        -- Base Spellsword events we observe in parallel.
        IW_SpellCast              = onIWSpellCast,
        IW_DecrementSpellCharge   = onIWDecrementSpellCharge,
    },
}
