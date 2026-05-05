local world = require('openmw.world')
local types = require('openmw.types')
local core = require('openmw.core')
local storage = require('openmw.storage')
local Activation = require('openmw.interfaces').Activation
local Settings = require('openmw.interfaces').Settings
local Crimes = require('openmw.interfaces').Crimes
local C = require('scripts.ReanimateDead.common')

local l10n = core.l10n(C.L10N)

-- Groups registered from a global script back onto storage.globalSection
-- (scripts/omw/settings/common.lua picks playerSection when it's
-- defined, globalSection otherwise), making them readable from local
-- and custom scripts.
--
-- The Spell group (duration, magnitude) is registered from player.lua
-- instead because load.lua needs to read its values, and LOAD-context
-- storage only exposes `playerSection` (verified in
-- components/lua/storage.cpp `initLoadPackage`).

Settings.registerGroup({
    key = C.SETTINGS.SECTION_BEHAVIOR,
    page = C.SETTINGS.PAGE,
    l10n = C.L10N,
    name = 'group_behavior_name',
    description = 'group_behavior_description',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'suppressDialog',
            renderer = 'checkbox',
            name = 'setting_suppress_dialog_name',
            description = 'setting_suppress_dialog_description',
            default = true,
        },
        {
            key = 'soulTrapImmune',
            renderer = 'checkbox',
            name = 'setting_soul_trap_immune_name',
            description = 'setting_soul_trap_immune_description',
            default = true,
        },
        {
            key = 'crime',
            renderer = 'checkbox',
            name = 'setting_crime_name',
            description = 'setting_crime_description',
            default = true,
        },
        {
            key = 'factionExpulsion',
            renderer = 'checkbox',
            name = 'setting_faction_expulsion_name',
            description = 'setting_faction_expulsion_description',
            default = true,
        },
        {
            key = 'raiseUndead',
            renderer = 'checkbox',
            name = 'setting_raise_undead_name',
            description = 'setting_raise_undead_description',
            default = false,
        },
        {
            key = 'raiseDaedra',
            renderer = 'checkbox',
            name = 'setting_raise_daedra_name',
            description = 'setting_raise_daedra_description',
            default = false,
        },
        {
            key = 'reraiseMinions',
            renderer = 'checkbox',
            name = 'setting_reraise_minions_name',
            description = 'setting_reraise_minions_description',
            default = false,
        },
    },
})

Settings.registerGroup({
    key = C.SETTINGS.SECTION_EFFECTS,
    page = C.SETTINGS.PAGE,
    l10n = C.L10N,
    name = 'group_effects_name',
    description = 'group_effects_description',
    permanentStorage = true,
    order = 2,
    settings = {
        {
            key = 'aura',
            renderer = 'checkbox',
            name = 'setting_aura_name',
            description = 'setting_aura_description',
            default = true,
        },
    },
})

local behaviorSettings = storage.globalSection(C.SETTINGS.SECTION_BEHAVIOR)

local FALLBACK_RECORD = 'skeleton'

local function risenName(orig)
    return l10n(C.L10N_KEYS.RISEN_NAME_PREFIX) .. (orig.name or orig.id or 'Corpse')
end

-- `createRecordDraft` accepts an undocumented `template` field
-- (verified in the C++ binding source) that takes a record OBJECT and
-- does a wholesale field-copy of its underlying ESM struct onto the
-- draft *before* applying overrides. This carries through fields the
-- Lua schema doesn't expose individually — including the stat block —
-- so the new actor is born with non-zero health and isn't flagged
-- dead at creation.
local function buildRisenCreatureRecord(corpse)
    local orig = types.Creature.record(corpse)
    local draft = {
        template = orig,
        name = risenName(orig),
        type = types.Creature.TYPE.Undead,
        isEssential = false,
        isRespawning = false,
    }
    -- Engine's soulTrap (mwmechanics/actors.cpp ~170) short-circuits
    -- when `mData.mSoul == 0`, the same hook vanilla uses for
    -- skeletons/atronachs. NPCs are filtered earlier by
    -- `target.getType() == ESM::Creature::sRecordId`, so this only
    -- matters for creature minions.
    if behaviorSettings:get("soulTrapImmune") then
        draft.soulValue = 0
    end
    return world.createRecord(types.Creature.createRecordDraft(draft))
end

local function buildRisenNpcRecord(corpse)
    local orig = types.NPC.record(corpse)
    local draft = types.NPC.createRecordDraft({
        template = orig,
        name = risenName(orig),
        isEssential = false,
        isRespawning = false,
    })
    return world.createRecord(draft)
end

-- Cache from source record id → Risen record id, persisted so the
-- mapping survives save/load. `ESMStore::insert<NPC|Creature>` mints
-- a fresh ID via `ESM::RefId::generated(mDynamicCount++)` per call
-- (esmstore.cpp:818) with no by-content dedupe — without this cache,
-- every raise leaks a new dynamic record. `ESMStore::write`
-- (esmstore.cpp:698) serializes those records into the save.
local minionRecordCache = {}

-- The cache survives save/load (esmstore.cpp:698-722), but a record id
-- can still go stale if the player swapped content files between
-- sessions.
local function recordExists(id)
    return types.NPC.records[id] ~= nil or types.Creature.records[id] ~= nil
end

local function pickMinionRecordId(corpse)
    local sourceId = corpse.recordId
    local cached = minionRecordCache[sourceId]
    if cached and recordExists(cached) then
        return cached
    elseif cached then
        minionRecordCache[sourceId] = nil
    end

    -- Re-raise: the corpse is already a Risen record, so reuse its id
    -- directly. Avoids a "Risen Risen <name>" compound from running it
    -- through the template-prototype copy a second time.
    if corpse:hasScript(C.MINION_SCRIPT) then
        minionRecordCache[sourceId] = sourceId
        return sourceId
    end

    local builder
    if corpse.type == types.Creature then
        builder = buildRisenCreatureRecord
    elseif corpse.type == types.NPC then
        builder = buildRisenNpcRecord
    end
    if builder then
        local ok, record = pcall(builder, corpse)
        if ok and record and record.id then
            minionRecordCache[sourceId] = record.id
            return record.id
        end
    end
    return FALLBACK_RECORD
end

local function onSave()
    return { minionRecordCache = minionRecordCache }
end

local function onLoad(saved)
    if saved and saved.minionRecordCache then
        minionRecordCache = saved.minionRecordCache
    end
end

-- Uses `world.vfx.spawn` rather than `animation.addVfx` because addVfx
-- requires SelfObject (a local script attached to the target) and
-- rejected corpses have no script. `Static.records[id].model` already
-- includes the `meshes/` prefix (Lua binding wraps mModel via
-- correctMeshPath in mwlua/types/modelproperty.hpp), matching what
-- World::spawnEffect expects.
local function spawnConsideredVfx(corpse)
    local rec = types.Static.records[C.VFX.SUMMON_START]
    if not (rec and rec.model) then return end
    pcall(function()
        world.vfx.spawn(rec.model, corpse.position, {
            particleTextureOverride = C.VFX.PARTICLE_TEXTURE,
        })
    end)
end

local function onSpawnConsideredVfx(data)
    if data and data.corpse then
        spawnConsideredVfx(data.corpse)
    end
end

local function raiseOne(corpse, caster, activeSpellId, deathAnim)
    if not corpse:isValid() or not types.Actor.isDead(corpse) then
        return
    end
    -- Re-rise filter. Lives here (not in player.lua) because
    -- `hasScript` is GObject-only (objectbindings.cpp:416). CUSTOM
    -- scripts persist with the actor's RefData through death, so
    -- hasScript is a stable marker for "previously raised."
    if not behaviorSettings:get('reraiseMinions') and corpse:hasScript(C.MINION_SCRIPT) then
        -- Bounce the rejection to the caster's player script —
        -- openmw.ui is PLAYER/MENU only (mwlua/luabindings.cpp:69-90).
        if caster then
            caster:sendEvent(C.EVENTS.SHOW_REJECTION, { key = C.L10N_KEYS.NO_EFFECT_MINION })
        end
        spawnConsideredVfx(corpse)
        return
    end

    -- Event-passed dead actors are in a "soft-removed" state where
    -- writes throw — re-resolve to a fresh writable reference.
    local fresh
    for _, actor in ipairs(world.activeActors) do
        if actor.id == corpse.id then
            fresh = actor
            break
        end
    end
    if fresh then
        fresh.enabled = false
    end

    local minionRecordId = pickMinionRecordId(corpse)
    local minion = world.createObject(minionRecordId)
    -- Without explicit rotation, teleport falls back to
    -- `ptr.getRefData().getPosition().asRotationVec3()`
    -- (objectbindings.cpp:517), which is zeroed for a brand-new
    -- object — so the minion would pop in facing north while the
    -- reverse death anim plays from the original facing.
    minion:teleport(corpse.cell, corpse.position, { rotation = corpse.rotation })

    -- {slot = recordId} snapshot. Live item GameObjects can't be
    -- passed — they're corpse-instance refs that won't exist in the
    -- minion's inventory after the transfer. The engine's auto-equip
    -- picks "best" gear by stat, not what the corpse was actually
    -- wearing, so the minion replays this map via setEquipment.
    local equipMap = {}
    local okEq, srcEquip = pcall(types.Actor.getEquipment, fresh or corpse)
    if okEq and srcEquip then
        for slot, item in pairs(srcEquip) do
            if item and item.recordId then
                equipMap[slot] = item.recordId
            end
        end
    end

    minion:addScript(C.MINION_SCRIPT, {
        caster = caster,
        activeSpellId = activeSpellId,
        equipMap = equipMap,
        deathAnim = deathAnim,
    })

    -- Inventory swap is deferred a frame. `item:remove()` /
    -- `item:moveInto()` (objectbindings.cpp:451) synchronously call
    -- `setCount(0)` on the source item, with the actual removal queued
    -- as a delayed action. The `:teleport()` above is also a delayed
    -- action, so both end up in the same `applyDelayedActions` cycle:
    -- teleport runs first, copying the minion's InventoryStore via
    -- copySlots → store.index → std::distance(cbegin, iter). The
    -- iterator's operator++ (containerstore.cpp:1449) skips count=0
    -- items, so cbegin walks straight past every just-zeroed slot
    -- and never equals iter — infinite loop on the main thread.
    -- Confirmed via WinDbg dump. Routing through a self-event punts
    -- the drain to the next frame, after the teleport's queue drains.
    core.sendGlobalEvent(C.EVENTS.TRANSFER_INVENTORY, {
        corpse = fresh or corpse,
        minion = minion,
    })
end

-- The engine's `autoEquip()` fires automatically when armor or
-- clothing is added to a non-player NPC (inventorystore.cpp:145-153),
-- equipping both armor and weapon — so no setEquipment call is needed
-- here (and couldn't be issued anyway: setEquipment is SelfObject-only,
-- actor.cpp:360). Slot-accurate restoration is replayed in minion.lua
-- via the equipMap snapshot.
local function onTransferInventory(data)
    local corpse, minion = data.corpse, data.minion
    if not (corpse and minion) then return end
    local srcInv = types.Actor.inventory(corpse)
    local tgtInv = types.Actor.inventory(minion)
    if not (srcInv and tgtInv) then return end

    -- The template-prototype clone carries the source record's
    -- predefined item list, so the minion spawns with the engine's
    -- auto-roll from that list — drop it before transfer to avoid
    -- duplicating the corpse's loot.
    for _, item in ipairs(tgtInv:getAll()) do
        pcall(function() item:remove() end)
    end

    for _, item in ipairs(srcInv:getAll()) do
        pcall(function() item:moveInto(tgtInv) end)
    end
end

-- Vanilla Morrowind faction record IDs, matched case-insensitively
-- against the player's faction list.
local NECROMANCY_HOSTILE_FACTIONS = {
    'Temple',
    'Imperial Cult',
    'Redoran',
    'Mages Guild',
}

local function expelFromAntiNecromancyFactions(player)
    local hostileLookup = {}
    for _, id in ipairs(NECROMANCY_HOSTILE_FACTIONS) do
        hostileLookup[string.lower(id)] = id
    end
    -- The Lua `expel` binding hardcodes `expell(factionId, false)`
    -- (mwlua/types/npc.cpp:462), suppressing the engine's expulsion
    -- notification — replay it ourselves via player.lua so
    -- ui.showMessage runs in PLAYER context (luabindings.cpp).
    local prefix = core.getGMST('sExpelledMessage') or ''
    local playerFactions = types.NPC.getFactions(player) or {}
    for _, factionId in ipairs(playerFactions) do
        if hostileLookup[string.lower(factionId)] and not types.NPC.isExpelled(player, factionId) then
            local ok = pcall(types.NPC.expel, player, factionId)
            if ok then
                local rec = core.factions.records[factionId]
                local factionName = (rec and rec.name) or factionId
                player:sendEvent(C.EVENTS.SHOW_EXPEL_MESSAGE, {
                    message = prefix .. factionName,
                })
            end
        end
    end
end

local function castIncludesNpc(corpses)
    for _, corpse in ipairs(corpses) do
        if corpse.type == types.NPC then return true end
    end
    return false
end

local function onReanimateDeadCast(data)
    -- `commitCrime` runs the engine's full witness pipeline:
    -- alarm-radius, LOS, faction filtering, follower exclusion
    -- (mechanicsmanagerimp.cpp:1147+). OT_Murder is uniquely "audible"
    -- — neighbors register it without LOS (line 1186), matching a
    -- loud-ritual framing. No victim is required; the engine still
    -- applies iCrimeKilling bounty and iFightKilling combat trigger.
    if behaviorSettings:get("crime") and castIncludesNpc(data.corpses) then
        local result = Crimes.commitCrime(data.caster, {
            type = types.Player.OFFENSE_TYPE.Murder,
        })
        if result and result.wasCrimeSeen and behaviorSettings:get("factionExpulsion") then
            expelFromAntiNecromancyFactions(data.caster)
        end
    end
    for _, corpse in ipairs(data.corpses) do
        raiseOne(corpse, data.caster, data.activeSpellId, data.deathAnim)
    end
end

-- Both NPC and Creature classes return `ActionTalk` from `activate()`
-- on living non-combat actors (mwclass/npc.cpp:891,
-- mwclass/creature.cpp:486), which opens the dialogue window.
-- Returning false from an Activation handler ends the chain *and*
-- skips `world._runStandardActivationAction`
-- (scripts/omw/activationhandlers.lua:42-47), so `activate()` never
-- runs. Blocked only while alive so the corpse stays lootable.
local function suppressDialogIfMinion(obj, _actor)
    if not behaviorSettings:get("suppressDialog") then return end
    if not obj:hasScript(C.MINION_SCRIPT) then return end
    if types.Actor.isDead(obj) then return end
    return false
end

Activation.addHandlerForType(types.NPC, suppressDialogIfMinion)
Activation.addHandlerForType(types.Creature, suppressDialogIfMinion)

return {
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        [C.EVENTS.CAST] = onReanimateDeadCast,
        [C.EVENTS.TRANSFER_INVENTORY] = onTransferInventory,
        [C.EVENTS.SPAWN_CONSIDERED_VFX] = onSpawnConsideredVfx,
    },
}
