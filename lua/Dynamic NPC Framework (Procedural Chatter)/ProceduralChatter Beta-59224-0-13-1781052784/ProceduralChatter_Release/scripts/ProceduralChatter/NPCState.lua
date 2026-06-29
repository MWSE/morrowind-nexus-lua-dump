-- NPCState.lua
-- Centralised NPC state bus for global scripts.
-- Replaces the scattered isSitting/isBusy/isActive checks spread across
-- SittingGlobal, ActivityManager, and ConversationManager.
--
-- Canonical states:
--   "idle" | "walking" | "sitting" | "sleeping" | "waking" | "conversation" | "activity"
--   "returning" | "departing" | "transitioning" | "arriving"
--   "traveling_to_destination" | "at_destination" | "traveling_home" | "at_home"
--   "traveling_to_seat"
--   "hostile"  (runtime-only; not persisted)
-- Anything not explicitly set is treated as "idle".
--
-- Migration: legacy "working" is transparently remapped to "activity" on read.
--
-- Also owns the persistent native home registry:
--   NPCState.saveNativeHome(npc)      — write-once; first sighting wins
--   NPCState.loadNativeHome(npc)      — returns pos, rot (or nil, nil)
--   NPCState.snapshotCell(cell)       — save all NPCs in cell not yet recorded
-- This is the authoritative return destination for ALL systems (sleep, conversation,
-- activities) so that NPCs always come back to their pre-script positions, even after
-- the cell has been unloaded and reloaded mid-displacement.

local util    = require('openmw.util')
local storage = require('openmw.storage')
local types   = require('openmw.types')
local core    = require('openmw.core')

local NPCState = {}

-- =============================================================================
-- Internal storage
-- =============================================================================
local states = {}   -- [npcId] -> state string
local meta   = {}   -- [npcId] -> { key -> value }

local PERSISTENT_STATES = {
    sitting = true,
    -- Cross-script transient: player-side conversation scans must see bed-bound
    -- NPCs immediately, or they can start chatter during the walk-to-bed window.
    pending_sleep = true,
    -- Player-side conversation scans must also see fully sleeping NPCs. The
    -- SleepManager already validates and clears stale sleep labels when an NPC
    -- is no longer actually assigned to a bed.
    sleeping = true,
    -- Runtime managers own the physical/animation data for activities.
    -- Persisting activity without its live manager tables strands NPCs after
    -- reloadlua/save-load.
    conversation = true,
    -- traveling_to_seat must be persisted so local-script NPCState.get() reads
    -- the correct state during the async gap between SittingLogic sending
    -- PC_StateChanged and the global processing it. Without this, ActivityManager
    -- and ConversationManager see 'idle' and interrupt the walk-to-stool.
    traveling_to_seat = true,
    traveling_to_destination = true,
    at_destination = true,
    at_home = true,
    -- Return / door walks must survive local-script reload after cross-cell teleports.
    traveling_home = true,
    departing = true,
    transitioning = true,
    arriving = true,
    returning = true,
}

-- =============================================================================
-- Persistent native home registry
-- Write-once keyed by tostring(npc.id).  Global scripts write; any script reads.
-- =============================================================================
local _homeStore = storage.globalSection('PC_NativeHomes')
local _homeCache = {}  -- [key] -> { pos=vector3, rot=transform, cellName=string }
-- Generation counter: when incremented, all cached/stored entries are stale and
-- saveNativeHome will overwrite them.  Bumped by clearAllNativeHomes().
local _homeGeneration = 0

-- =============================================================================
-- Persistent interior home registry (schedule destinations)
-- Stores the resolved interior cell + door entry position for each NPC so the
-- same cell is used every night rather than re-resolving.
-- Write-once keyed by tostring(npc.id).
-- =============================================================================
local _interiorHomeStore = storage.globalSection('PC_InteriorHomes')
local _interiorHomeCache = {}  -- [key] -> { cellName=string, pos=vector3, rot=transform }

-- =============================================================================
-- Persistent NPC state registry
-- Ensures NPCs remember their state (idle, traveling, sleeping, etc.)
-- across saves and cell unloads.
-- =============================================================================
local _stateStore = storage.globalSection('PC_NPCStates')
local _cooldownStore = storage.globalSection('PC_NPCCooldowns')

local function storeSet(section, key, value)
    pcall(function()
        section:set(key, value)
    end)
end

local function isHostileByDefault(actor)
    if not actor or not types.Actor or not types.Actor.stats or not types.Actor.stats.ai then
        return false
    end
    local fightAccessor = types.Actor.stats.ai.fight
    if type(fightAccessor) ~= "function" then return false end
    local ok, fight = pcall(fightAccessor, actor)
    if not ok or not fight then return false end
    local value = fight.base or fight.current
    return value ~= nil and value >= 80
end

--- Save native home for npc if not already recorded.
-- Write-once EXCEPT for old-format records that lack cellName — those are
-- overwritten so the format upgrade is applied on first encounter.
function NPCState.saveNativeHome(npc)
    if isHostileByDefault(npc) then return end
    local key = tostring(npc.id)
    -- Check cache first (fast path).
    local cached = _homeCache[key]
    if cached and cached.generation == _homeGeneration then return end
    -- Check storage: skip if a valid entry exists for the current generation.
    local existing = _homeStore:get(key)
    if existing and (existing.generation or 0) == _homeGeneration then return end
    local pos = npc.position
    local yaw = 0
    pcall(function()
        local fwd = npc.rotation * util.vector3(0, 1, 0)
        yaw = math.atan2(fwd.x, fwd.y)
    end)
    local cellName = ""
    pcall(function()
        cellName = npc.cell and npc.cell.name or ""
    end)
    _homeStore:set(key, { x = pos.x, y = pos.y, z = pos.z, yaw = yaw, cellName = cellName, generation = _homeGeneration })
    _homeCache[key] = { pos = pos, rot = npc.rotation, cellName = cellName, generation = _homeGeneration }
end

--- Load the persistent native home for npc. Returns cellName, pos, rot or nil, nil, nil.
-- Returns nil if no record exists OR if the record is old format (no cellName),
-- so callers know a fresh saveNativeHome is needed.
function NPCState.loadNativeHome(npc)
    local key = tostring(npc.id)
    local cached = _homeCache[key]
    if cached and cached.generation == _homeGeneration then
        return cached.cellName, cached.pos, cached.rot
    end
    local data = _homeStore:get(key)
    if not data or (data.generation or 0) ~= _homeGeneration then return nil, nil, nil end
    local pos = util.vector3(data.x, data.y, data.z)
    local rot = util.transform.rotateZ(data.yaw or 0)
    local cellName = data.cellName or ""
    _homeCache[key] = { pos = pos, rot = rot, cellName = cellName, generation = _homeGeneration }
    return cellName, pos, rot
end

function NPCState.persistNativeWander(data)
    if not data or not data.wander or data.wander.type ~= "Wander" then return end
    local npc = data.npc
    local npcId = data.npcId or (npc and npc.id)
    if not npcId then return end

    local key = tostring(npcId)
    local stored = _homeStore:get(key)
    local out
    if stored then
        out = {
            x = stored.x,
            y = stored.y,
            z = stored.z,
            yaw = stored.yaw,
            cellName = stored.cellName,
            generation = stored.generation,
        }
    else
        local pos = data.position
        if not pos and npc then
            pcall(function() pos = npc.position end)
        end
        if not pos then return end
        local yaw = data.yaw or 0
        if npc and not data.yaw then
            pcall(function()
                local fwd = npc.rotation * util.vector3(0, 1, 0)
                yaw = math.atan2(fwd.x, fwd.y)
            end)
        end
        out = {
            x = pos.x,
            y = pos.y,
            z = pos.z,
            yaw = yaw,
            cellName = data.cellName or "",
            generation = _homeGeneration,
        }
    end

    if (not out.cellName or out.cellName == "") and npc then
        pcall(function() out.cellName = npc.cell and npc.cell.name or "" end)
    end

    out.wander = {
        type = "Wander",
        distance = data.wander.distance,
        duration = data.wander.duration,
        idle = data.wander.idle and {
            min = data.wander.idle.min,
            max = data.wander.idle.max,
        } or nil,
        isRepeat = data.wander.isRepeat ~= false,
    }

    _homeStore:set(key, out)
    local pos = util.vector3(out.x, out.y, out.z)
    local rot = util.transform.rotateZ(out.yaw or 0)
    _homeCache[key] = {
        pos = pos,
        rot = rot,
        cellName = out.cellName or "",
        generation = out.generation or _homeGeneration,
    }
end

--- Snapshot every NPC in a cell — call on cell change before any displacement.
-- Skips NPCs already in storage (write-once guarantee preserved).
function NPCState.snapshotCell(cell)
    if not cell then return end
    local ok, npcs = pcall(function() return cell:getAll(types.NPC) end)
    if not ok or not npcs then return end
    for _, npc in ipairs(npcs) do
        if not isHostileByDefault(npc) then
            pcall(NPCState.saveNativeHome, npc)
        end
    end
end

-- =============================================================================
-- State API
-- =============================================================================

--- Set the current state for an NPC.
function NPCState.set(npcId, state)
    if state == "working" then state = "activity" end
    local key = tostring(npcId)
    states[key] = state
    if PERSISTENT_STATES[state] then
        storeSet(_stateStore, key, state)
    else
        storeSet(_stateStore, key, nil)
    end
end

--- Get the current state for an NPC. Returns "idle" if not set.
-- Legacy "working" is transparently remapped to "activity".
-- When _stateStore has a value it is authoritative (cross-VM); local cache alone
-- must not mask a newer persistent state written by another script context.
function NPCState.get(npcId)
    local key = tostring(npcId)
    local stored = _stateStore:get(key)
    if stored == "working" then
        stored = "activity"
        storeSet(_stateStore, key, stored)
    elseif stored and not PERSISTENT_STATES[stored] then
        storeSet(_stateStore, key, nil)
        stored = nil
    end
    local s = states[key]
    if stored then
        s = stored
        states[key] = stored
    elseif PERSISTENT_STATES[s] then
        -- Another script VM cleared the persistent state. Do not let this VM's
        -- old cache keep returning conversation/sitting/schedule labels forever.
        states[key] = nil
        s = nil
    end
    if s == "working" then
        s = "activity"
        states[key] = s
        storeSet(_stateStore, key, s)
    end
    return s or "idle"
end

--- Clear state back to idle and wipe metadata.
function NPCState.clear(npcId)
    local key = tostring(npcId)
    states[key] = nil
    meta[npcId] = nil
    storeSet(_stateStore, key, nil)
end

--- Returns true if the NPC is safe to assign a new activity.
-- DEPRECATED: Use capability predicates (canActivity, canConverse, etc.) instead.
function NPCState.isAvailable(npcId)
    local s = NPCState.get(npcId)
    return s == "idle"
end

-- =============================================================================
-- Metadata API  (for storing per-NPC auxiliary data, e.g. cached hello value)
-- =============================================================================

function NPCState.setMeta(npcId, key, value)
    if not meta[npcId] then meta[npcId] = {} end
    meta[npcId][key] = value
end

function NPCState.getMeta(npcId, key)
    return meta[npcId] and meta[npcId][key]
end

function NPCState.clearMeta(npcId, key)
    if meta[npcId] then meta[npcId][key] = nil end
end

local function getSimulationTime()
    local ok, now = pcall(core.getSimulationTime)
    if ok and now then return now end
    return 0
end

function NPCState.setSitCooldown(npcId, seconds)
    if not npcId then return end
    local duration = seconds or 60
    if duration <= 0 then
        NPCState.clearMeta(npcId, "sitCooldownUntil")
        return
    end
    NPCState.setMeta(npcId, "sitCooldownUntil", getSimulationTime() + duration)
end

function NPCState.getSitCooldownRemaining(npcId)
    local expiresAt = NPCState.getMeta(npcId, "sitCooldownUntil")
    if not expiresAt then return 0 end
    local remaining = expiresAt - getSimulationTime()
    if remaining <= 0 then
        NPCState.clearMeta(npcId, "sitCooldownUntil")
        return 0
    end
    return remaining
end

function NPCState.isSitCooldownActive(npcId)
    return NPCState.getSitCooldownRemaining(npcId) > 0
end

-- =============================================================================
-- Arrival cooldown (prevents conversations grabbing NPCs right after materialization)
-- =============================================================================

local ARRIVAL_COOLDOWN_SECONDS = 5.0

function NPCState.setArrivalCooldown(npcId, seconds)
    local m = NPCState.getMeta(npcId)
    if not m then
        meta[npcId] = {}
        m = meta[npcId]
    end
    local untilTime = core.getSimulationTime() + (seconds or ARRIVAL_COOLDOWN_SECONDS)
    m.arrivalCooldownUntil = untilTime
    storeSet(_cooldownStore, tostring(npcId), untilTime)
end

function NPCState.isArrivalCooldownActive(npcId)
    local m = meta[npcId]
    local untilTime = m and m.arrivalCooldownUntil or _cooldownStore:get(tostring(npcId))
    if not untilTime then return false end
    if core.getSimulationTime() < untilTime then return true end
    if m then m.arrivalCooldownUntil = nil end
    storeSet(_cooldownStore, tostring(npcId), nil)
    return false
end

-- =============================================================================
-- Bulk helpers (used on cell change to flush stale entries)
-- =============================================================================

--- Remove all state for NPCs whose IDs are not in the provided set.
-- @param liveIds  Table used as a set: { [npcId] = true }
function NPCState.flush(liveIds)
    for npcId in pairs(states) do
        if not liveIds[npcId] then
            states[npcId] = nil
            meta[npcId]   = nil
            storeSet(_stateStore, tostring(npcId), nil)
        end
    end
end

--- Wipe everything (e.g. on full cell change).
function NPCState.reset()
    states = {}
    meta   = {}
    -- Intentionally do NOT wipe _stateStore here.
    -- reset() is used on cell change to clear local caches only.
end

-- =============================================================================
-- Capability predicates (single source of truth for availability)
-- =============================================================================

function NPCState.isSitting(npcId)    return NPCState.get(npcId) == "sitting"    end
function NPCState.isSleeping(npcId)   return NPCState.get(npcId) == "sleeping"   end
function NPCState.isPendingSleep(npcId) return NPCState.get(npcId) == "pending_sleep" end
function NPCState.isInConversation(npcId) return NPCState.get(npcId) == "conversation" end
function NPCState.isWorking(npcId)    return NPCState.get(npcId) == "activity"    end
function NPCState.isHostile(npcId)    return NPCState.get(npcId) == "hostile"    end

--- Returns true if the NPC is currently under schedule control (traveling or at destination).
function NPCState.isScheduled(npcId)
    local s = NPCState.get(npcId)
    return s == "traveling_to_destination"
        or s == "at_destination"
        or s == "traveling_home"
        or s == "at_home"
end

--- Returns true if the NPC is in a transit state (walking between locations).
function NPCState.isInTransit(npcId)
    local s = NPCState.get(npcId)
    return s == "traveling_to_destination"
        or s == "traveling_home"
        or s == "pending_sleep"
        or s == "departing"
        or s == "transitioning"
        or s == "arriving"
        or s == "traveling_to_seat"
        or s == "walking"
        or s == "returning"
end

--- Returns true if the NPC can be assigned a new activity.
function NPCState.canActivity(npcId)
    if NPCState.isArrivalCooldownActive(npcId) then return false end
    local s = NPCState.get(npcId)
    if s == "hostile" then return false end
    return s == "idle"
        or s == "sitting"
        or s == "at_destination"
        or s == "at_home"
end

--- Returns true if the NPC can be offered a stool/seat.
function NPCState.canSit(npcId)
    if NPCState.isSitCooldownActive(npcId) then return false end
    local s = NPCState.get(npcId)
    if s == "hostile" then return false end
    return s == "idle"
        or s == "at_destination"
        or s == "at_home"
        or s == "pending_conversation"
        or s == "pending_activity"
end

--- Returns true if the NPC can be assigned a bed.
function NPCState.canSleep(npcId)
    local s = NPCState.get(npcId)
    if s == "hostile" then return false end
    return s == "idle"
        or s == "sitting"
        or s == "at_destination"
        or s == "at_home"
        or s == "pending_conversation"
        or s == "pending_activity"
        or s == "pending_sleep"
end

--- Returns true if the NPC can participate in a conversation.
-- Sitting and activity NPCs are explicitly allowed so they can be interrupted politely.
function NPCState.canConverse(npcId)
    if NPCState.isArrivalCooldownActive(npcId) then return false end
    local s = NPCState.get(npcId)
    if s == "hostile" then return false end
    return s == "idle"
        or s == "sitting"
        or s == "at_destination"
        or s == "at_home"
        or s == "activity"
        or s == "pending_conversation"
        or s == "conversation"
end

--- Returns true if the NPC can be sent a WalkTo command.
function NPCState.canWalkTo(npcId)
    local s = NPCState.get(npcId)
    if s == "hostile" then return false end
    return s == "idle"
        or s == "sitting"
        or s == "at_destination"
        or s == "at_home"
        or s == "activity"
        or s == "conversation"
        or s == "pending_conversation"
end

--- DEBUG: invalidate all stored native homes so they are re-captured on next onActorActive.
-- Increments the generation counter; any entry from a prior generation is ignored by
-- loadNativeHome and overwritten by saveNativeHome on next NPC activation.
-- Called via global event PC_ClearNativeHomes.
function NPCState.clearAllNativeHomes()
    _homeGeneration = _homeGeneration + 1
    _homeCache = {}
    print("[NPCState] clearAllNativeHomes: generation=" .. _homeGeneration
        .. "; all native homes will be re-captured on next NPC activation")
end

--- Save interior home destination for npc (write-once; first assignment wins).
-- cellName: destination interior cell name string
-- pos: util.vector3 of door-inside position
-- rot: transform (rotation)
function NPCState.saveInteriorHome(npc, cellName, pos, rot)
    local key = tostring(npc.id)
    if _interiorHomeStore:get(key) then return end
    local yaw = 0
    pcall(function()
        local fwd = rot * util.vector3(0, 1, 0)
        yaw = math.atan2(fwd.x, fwd.y)
    end)
    _interiorHomeStore:set(key, { cellName = cellName, x = pos.x, y = pos.y, z = pos.z, yaw = yaw })
    _interiorHomeCache[key] = { cellName = cellName, pos = pos, rot = rot }
end

--- Load the persistent interior home destination for npc.
-- Returns cellName, pos, rot  or  nil, nil, nil.
function NPCState.loadInteriorHome(npc)
    local key = tostring(npc.id)
    if _interiorHomeCache[key] then
        local c = _interiorHomeCache[key]
        return c.cellName, c.pos, c.rot
    end
    local data = _interiorHomeStore:get(key)
    if not data then return nil, nil, nil end
    local pos = util.vector3(data.x, data.y, data.z)
    local rot = util.transform.rotateZ(data.yaw or 0)
    _interiorHomeCache[key] = { cellName = data.cellName, pos = pos, rot = rot }
    return data.cellName, pos, rot
end

return NPCState
