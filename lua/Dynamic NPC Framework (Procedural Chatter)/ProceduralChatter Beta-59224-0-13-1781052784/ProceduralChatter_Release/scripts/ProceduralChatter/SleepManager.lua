-- SleepManager.lua
-- Global sleep system.  Mirrors SittingGlobal's pattern:
--   scanAndAssignBeds  — find beds, find NPCs, send PC_ConsiderBed
--   onBedCheckResult   — claim slot, start lerp (or teleport if mid-night)
--   onUpdate           — lerp loop, period-transition triggers, wake-on-dawn
--
-- Bed detection uses SHOP's proven Activator-name pattern:
--   types.Activator.record(obj).name == "Bed"
-- This covers all vanilla and modded beds without maintaining a record-ID list.
--
-- No Z offset is applied to bed positions.  The NPC stands on the bed surface
-- (found by SleepLogic's raycast) and the sleep animation naturally lays them flat.

local core    = require('openmw.core')
local world   = require('openmw.world')
local types   = require('openmw.types')
local util    = require('openmw.util')
local storage = require('openmw.storage')

local FurnitureRegistry    = require("scripts.ProceduralChatter.FurnitureRegistry")
local NPCState             = require("scripts.ProceduralChatter.NPCState")
local TimeService          = require("scripts.ProceduralChatter.TimeService")
local ScheduleConfig       = require("scripts.ProceduralChatter.data.ScheduleConfig")
local FurnitureProfiles    = require("scripts.ProceduralChatter.data.FurnitureProfiles")
local Blacklist            = require("scripts.ProceduralChatter.Blacklist")


-- =============================================================================
-- Persistent bed exit positions
-- Keyed by tostring(bed.id) — stable across sessions for static world objects.
-- Stored as { x, y, z, yaw } since util.vector3/transform can't be serialised.
-- =============================================================================
local bedExitStore  = storage.globalSection('PC_BedExits')
local bedExitCache  = {}   -- [bedId] -> { pos=vector3, rot=transform }  (session cache)


local function saveBedExit(bed, pos, rot)
    local key = tostring(bed.id)
    local yaw = 0
    pcall(function()
        local fwd = rot * util.vector3(0, 1, 0)
        yaw = math.atan2(fwd.x, fwd.y)
    end)
    bedExitCache[key] = { pos = pos, rot = rot }
    bedExitStore:set(key, { x = pos.x, y = pos.y, z = pos.z, yaw = yaw })
end

local function loadBedExit(bed)
    local key = tostring(bed.id)
    if bedExitCache[key] then
        return bedExitCache[key].pos, bedExitCache[key].rot
    end
    local data = bedExitStore:get(key)
    if not data then return nil, nil end
    local pos = util.vector3(data.x, data.y, data.z)
    local rot = util.transform.rotateZ(data.yaw or 0)
    bedExitCache[key] = { pos = pos, rot = rot }
    return pos, rot
end

local function getCurrentCellName(npc)
    local cellName = ""
    pcall(function()
        cellName = npc and npc.cell and npc.cell.name or ""
    end)
    return cellName
end

local function resolvePreActivityTarget(npc, fallbackPos, fallbackRot, hintedOriginalPosition, hintedOriginalRotation)
    local originalCellName, storedOriginalPosition, storedOriginalRotation = NPCState.loadNativeHome(npc)
    local originalPosition = storedOriginalPosition or hintedOriginalPosition
    local originalRotation = storedOriginalRotation or hintedOriginalRotation

    local preActivityPosition = fallbackPos
    local preActivityRotation = fallbackRot
    local sameOriginCell = false

    if originalPosition then
        local currentCellName = getCurrentCellName(npc)
        if currentCellName ~= "" and originalCellName ~= "" and currentCellName == originalCellName then
            sameOriginCell = true
            preActivityPosition = originalPosition
            preActivityRotation = originalRotation or fallbackRot
        end
    end

    return preActivityPosition, preActivityRotation, sameOriginCell
end

local SleepManager = {}

-- =============================================================================
-- Config
-- =============================================================================
local WAKE_HOUR         = ScheduleConfig.WAKE_HOUR   -- NPCs get up at this game hour
local SNAP_HOUR         = WAKE_HOUR + 3              -- If current hour >= this when wake fires, teleport home instead of lerp
local MAX_ASSIGN_DIST   = 999999  -- interior cells are never large enough for distance to matter
local BED_Z_OFFSET      = 19    -- Z units above bed origin to snap NPC (tune per feel)
local WALK_TIMEOUT      = 90.0  -- hard safety timeout; only fires if stall detection never triggers
local BED_ARRIVE_DIST      = 32   -- units from walkTarget; NPC is "there" — begin lay-down lerp
                                    -- Reduced from 75 to prevent NPCs lerping into bed from too far away.
local LAYDOWN_LERP_DURATION = 0.35 -- seconds to lerp NPC from standing to bed surface
local WAKE_LERP_DURATION    = 0.65 -- seconds to lerp NPC from bed surface to floor beside bed
-- Square Z bias for bed assignment: penalises vertical separation between NPC and bed
-- so NPCs always prefer a bed on the same floor over a closer-in-XY bed upstairs.
-- biasedDist = sqrt(dx²+dy²) + dz² * Z_SQUARE_SCALE
-- At dz≈180 (one Morrowind floor): bias ≈ 4860, well above MAX_ASSIGN_DIST.
-- At dz≈30  (same floor variance):  bias ≈ 135,  small vs typical XY distances.
local Z_SQUARE_SCALE    = 0.15

-- =============================================================================
-- Tavern cell blacklist — sleep system is disabled in taverns for now
-- =============================================================================
local TAVERN_CELLS = {
    ["akamora, the laughing goblin"] = true,
    ["ald-ruhn, ald skar inn"] = true,
    ["ald-ruhn, the rat in the pot"] = true,
    ["almas thirr, hostel of the crossing"] = true,
    ["almas thirr, limping scrib"] = true,
    ["almas thirr, lower waistworks"] = true,
    ["almas thirr, the pious pirate"] = true,
    ["almas thirr, upper waistworks"] = true,
    ["bal foyen, cat-catchers' cornerclub"] = true,
    ["bal foyen, council club"] = true,
    ["bal foyen, golden moons club"] = true,
    ["bal foyen, the dancing cup"] = true,
    ["balmora, council club"] = true,
    ["balmora, eight plates"] = true,
    ["balmora, lucky lockup"] = true,
    ["balmora, south wall cornerclub"] = true,
    ["caldera, shenk's shovel"] = true,
    ["dagon fel, the end of the world"] = true,
    ["darvonis, the windbreak hostel"] = true,
    ["ebonheart, six fishes"] = true,
    ["firewatch, the howling noose"] = true,
    ["firewatch, the queen's cutlass"] = true,
    ["gnisis, madach tradehouse"] = true,
    ["helnim, mjornir's meadhouse"] = true,
    ["helnim, the red drake"] = true,
    ["khuul, thongar's tradehouse"] = true,
    ["maar gan, andus tradehouse"] = true,
    ["molag mar, st. veloth's hostel"] = true,
    ["molag mar, waistworks"] = true,
    ["necrom, pilgrim's respite"] = true,
    ["necrom, seafarer's rest hostel"] = true,
    ["old ebonheart, the empress katariah"] = true,
    ["old ebonheart, the moth and tiger"] = true,
    ["old ebonheart, the salty futtocks"] = true,
    ["pelagiad, halfway tavern"] = true,
    ["sadrith mora, dirty muriel's cornerclub"] = true,
    ["sadrith mora, fara's hole in the wall"] = true,
    ["sadrith mora, gateway inn: north wing"] = true,
    ["seyda neen, arrille's tradehouse"] = true,
    ["suran, desele's house of earthly delights"] = true,
    ["suran, suran tradehouse"] = true,
    ["tel aruhn, plot and plaster"] = true,
    ["tel branora, sethan's tradehouse"] = true,
    ["tel gilain, the cliff racer's rest"] = true,
    ["tel mora, the covenant"] = true,
}

local function isTavernCell(cellName)
    if not cellName then return false end
    return TAVERN_CELLS[string.lower(cellName)] == true
end

-- Per-record bed overrides are now loaded from
-- data/furniture_profiles/bed_profiles.txt via FurnitureProfiles.lua.

-- =============================================================================
-- State
-- =============================================================================
local bedNpcs     = {}  -- [npcId] = { npc, bed, walkTarget, seatedPosition, seatedRotation, arrived, preSleepPos, preSleepRot, walkTimer }
local wakingNpcs  = {}  -- [npcId] = { npc, startPos, targetPos, lerpTime, returnPos, returnTimer, returning }
local pendingBeds = {}  -- [tostring(bed)] = true  (awaiting PC_BedCheckResult)
local pendingNpcs = {}  -- [npcId]         = true
local sleepQueue  = {}  -- [npcId] = npc  (busy NPCs waiting for a free moment to go to bed)
local prevHour    = nil
local lastCell    = nil
local rescanTimer = nil   -- seconds until post-wake rescan; nil = no rescan pending
local nightRescanTimer = 0  -- periodic rescan during night to catch late-available NPCs
local lastNightReconcileHour = nil
local dialogueQueue = {}  -- [npcId] = activator object (pending dialogue after wake)
local pendingScanCell = nil  -- deferred scan requested by PostArrivalCoordinator (avoids double-scan race on cell entry)
local dialogueMenuActive = false

-- =============================================================================
-- Helpers
-- =============================================================================
local Utils = require("scripts.ProceduralChatter.Utils")

-- Sleep blacklist: only exclude NPCs that genuinely never sleep (on-duty guards,
-- publicans who run the place 24/7).  Service providers, merchants, trainers etc.
-- all have beds and should sleep normally.
local Scheduler = require("scripts.ProceduralChatter.schedule.Scheduler")
local function isBlacklisted(npc)
    -- Also block NPCs that are in transit or already sleeping
    if NPCState.isInTransit(npc.id) then return true end
    if NPCState.isSleeping(npc.id) then return true end
    if Blacklist.isCompanion(npc) then return true end
    local rec = types.NPC.record(npc)
    if not rec then return false end
    local cls  = string.lower(rec.class or "")
    local name = string.lower(rec.name  or "")
    if cls == "guard" or name:find("guard", 1, true) then return true end
    if cls == "publican" then return true end
    return false
end

local function isPlayerActor(npc)
    if not npc then return false end
    local player = world.players and world.players[1]
    if not player then return false end
    if npc.id == player.id then return true end
    local rid = ""
    pcall(function() rid = string.lower(npc.recordId or "") end)
    return rid == "player"
end

local function isInAssignedDestinationCell(npc, assignment)
    if not npc or not assignment or not assignment.dest then return false end
    local assignedCell = string.lower(assignment.dest.destCellName or "")
    local currentCell = ""
    pcall(function() currentCell = string.lower(npc.cell and npc.cell.name or "") end)
    return assignedCell ~= "" and currentCell ~= "" and assignedCell == currentCell
end

local function collectCellNpcs(cell)
    return Utils.collectCellNpcs(cell)
end

local function refreshActorHandle(npcId, cell)
    local refreshed = nil
    pcall(function()
        for _, actor in ipairs(world.activeActors) do
            if actor.id == npcId then
                refreshed = actor
                return
            end
        end
    end)
    if refreshed then return refreshed end

    pcall(function()
        if not cell then return end
        for _, actor in ipairs(cell:getAll(types.NPC)) do
            if actor.id == npcId then
                refreshed = actor
                return
            end
        end
    end)
    return refreshed
end

local function preemptNpcForSleep(npc, reason)
    if not npc or not Utils.isObjValid(npc) then return end
    print(string.format("[SleepManager] Preempting for sleep: npc=%s reason=%s",
        tostring(npc.recordId), tostring(reason)))
    pcall(function() npc:sendEvent("PC_ClearMovementState", {}) end)
    pcall(function() npc:sendEvent("PC_Stop", {}) end)
    pcall(function() npc:sendEvent("PC_StopActivity", { silent = true, forceClearAll = true }) end)
    pcall(function() npc:sendEvent("PC_StopWander", {}) end)
    pcall(function() npc:sendEvent("PC_CancelTravelToSeat", {}) end)
    if NPCState.get(npc.id) == "traveling_to_seat" then
        NPCState.clear(npc.id)
    end
    pcall(function() npc:sendEvent("PC_StandUpPlease", {}) end)
end

local function reconcileSleepHour(cell, hourInt)
    if dialogueMenuActive then return end
    if not cell then return end
    local cellName = ""
    pcall(function() cellName = cell.name or "" end)
    if isTavernCell(cellName) then
        if ScheduleConfig.DEBUG_MODE then
            print(string.format("[SleepManager] reconcileSleepHour: skipped tavern '%s'", cellName))
        end
        return
    end
    print(string.format("[SleepManager] reconcileSleepHour: hour=%d", hourInt))
    local allNpcs = collectCellNpcs(cell)
    for _, npc in ipairs(allNpcs) do
        local enabled = false
        pcall(function() enabled = npc.enabled end)
        if not enabled then goto continue end
        if not isPlayerActor(npc) and not isBlacklisted(npc) then
            local npcId = npc.id
            local state = NPCState.get(npcId)
            local inBed = bedNpcs[npcId] ~= nil
            local inPending = pendingNpcs[npcId] ~= nil
            if not inBed and not inPending and not NPCState.isSleeping(npcId) and state ~= "waking" then
                if not NPCState.canSleep(npcId) and not NPCState.isInTransit(npcId) and not NPCState.isScheduled(npcId) then
                    preemptNpcForSleep(npc, "hourly_reconcile")
                end
            end
        end
        ::continue::
    end
    SleepManager.scanAndAssignBeds(cell)
end

-- =============================================================================
-- Bed scanning & assignment
-- =============================================================================

-- Register a bed in FurnitureRegistry on first encounter.
local function ensureBedRegistered(bed)
    if FurnitureRegistry.isRegistered(bed) then return end
    if FurnitureProfiles.isFurnitureObjectBlacklisted(bed) then return end

    local rid      = string.lower(bed.recordId or "")
    local profileSlots = FurnitureProfiles.getSlots(bed, "sleep")
    if profileSlots and #profileSlots > 0 then
        print(string.format("[SleepManager] registering profile bed recordId='%s' slots=%d",
            rid, #profileSlots))
        FurnitureRegistry.register(bed, profileSlots)
        return
    end

    local override = FurnitureProfiles.getBedOverrides(rid)
    print(string.format("[SleepManager] registering bed recordId='%s' override=%s", rid, tostring(override ~= nil)))

    if override then
        -- Custom slot layout: positions are explicit offsets from bed.position.
        -- Facing still derived from bed rotation so it respects world placement.
        local ok, forward = pcall(function() return bed.rotation * util.vector3(1, 0, 0) end)
        local facingDir   = (ok and forward) and forward or util.vector3(1, 0, 0)
        local bp          = bed.position
        local slotDefs    = {}
        for _, off in ipairs(override) do
            table.insert(slotDefs, {
                pos        = util.vector3(bp.x + off.x, bp.y + off.y, bp.z + off.z),
                facing     = facingDir,
                isOverride = true,
            })
        end
        FurnitureRegistry.register(bed, slotDefs)
        return
    end

    -- Normal path: derive slot positions from orientation.
    local axis, length, zLevel, width = FurnitureRegistry.getOrientation(bed)
    local slotCount = (width >= 80) and 2 or 1
    local positions = FurnitureRegistry.getSlotPositions(bed, slotCount)
    local facingDir = (axis == "x") and util.vector3(1, 0, 0) or util.vector3(0, 1, 0)

    local slotDefs = {}
    for _, pos in ipairs(positions) do
        table.insert(slotDefs, { pos = pos, facing = facingDir })
    end
    FurnitureRegistry.register(bed, slotDefs)
end

-- Returns true if obj is a bed with an explicit furniture profile.
local function isBedObject(obj)
    if FurnitureProfiles.isFurnitureObjectBlacklisted(obj) then return false end
    return FurnitureProfiles.getProfileForObject(obj, "sleep") ~= nil
end

-- Scan the cell for beds and assign eligible idle NPCs to them.
-- If teleport=true, skip the lerp and snap NPCs directly (used on late cell entry).
local function doScanAndAssign(cell, teleport)
    if dialogueMenuActive then return end
    -- Never assign beds outside the night period.  The period-transition handler
    -- in onUpdate fires the scan at 23:00; onCellChange calls here for mid-night
    -- cell entries.  Both paths are harmless during daytime/evening because of
    -- this guard.
    local scanCellName = "nil"
    pcall(function() scanCellName = tostring(cell) end)
    local cellName = ""
    pcall(function() cellName = cell.name or "" end)
    if isTavernCell(cellName) then
        if ScheduleConfig.DEBUG_MODE then
            print(string.format("[SleepManager] doScanAndAssign skipped tavern '%s'", cellName))
        end
        return
    end
    local useTeleport = teleport or TimeService.isDeepNight()
    print(string.format("[SleepManager] doScanAndAssign called: cell='%s' teleport=%s period=%s deepNight=%s",
        scanCellName, tostring(useTeleport), TimeService.getPeriod(), tostring(TimeService.isDeepNight())))
    if TimeService.getPeriod() ~= "night" then return end

    -- Clear any NPCs still in the "waking" monitor phase — they've had their
    -- chance to walk home.  Without this, leftover "waking" state blocks them
    -- from being re-assigned beds on subsequent nights.
    for npcId, wd in pairs(wakingNpcs) do
        NPCState.clear(npcId)
    end
    wakingNpcs = {}

    -- Clean up stale bedNpcs entries: if an NPC is tracked as "in bed" but
    -- their NPCState is no longer sleeping/pending sleep, they were displaced
    -- by another system (e.g. SittingGlobal overrode the Travel-to-bed) and
    -- the bed slot was never released. Without this cleanup the NPC is
    -- permanently skipped as "already in bed" on every subsequent scan.
    for npcId, data in pairs(bedNpcs) do
        if not NPCState.isSleeping(npcId) and not NPCState.isPendingSleep(npcId) then
            FurnitureRegistry.releaseByNpc(npcId)
            bedNpcs[npcId] = nil
            print(string.format("[SleepManager] Released stale bed entry for npc=%s (was not sleeping/pending)", tostring(npcId)))
        end
    end

    -- Reset pending flags — any in-flight PC_ConsiderBed that never got a
    -- PC_BedCheckResult reply (e.g. SleepLogic error) would permanently block
    -- those NPCs and beds from future scans.  A fresh scan supersedes them.
    pendingNpcs = {}
    pendingBeds = {}

    -- Collect unoccupied beds.
    local beds = {}
    for _, obj in ipairs(cell:getAll()) do
        if isBedObject(obj) then
            ensureBedRegistered(obj)
            local bedKey = tostring(obj)
            if not FurnitureRegistry.isOccupied(obj) and not pendingBeds[bedKey] then
                table.insert(beds, obj)
            end
        end
    end
    print(string.format("[SleepManager] doScanAndAssign: found %d beds (teleport=%s)", #beds, tostring(teleport)))
    if #beds == 0 then return end

    -- Collect eligible NPCs.
    -- Idle and sitting NPCs are immediate candidates.
    -- Working/conversation NPCs go into sleepQueue to be assigned when free.
    local candidates = {}
    -- Use world.activeActors filtered to this cell instead of cell:getAll(types.NPC).
    -- cell:getAll has a first-load quirk where it returns 0 NPCs even when the cell
    -- is fully loaded; activeActors is always authoritative.
    local allNpcs = Utils.collectCellNpcs(cell)
    local cellName = "unknown"
    pcall(function() cellName = tostring(cell) end)
    print(string.format("[SleepManager] NPC scan: %d total NPCs in cell '%s'",
        #allNpcs, cellName))
    for _, npc in ipairs(allNpcs) do
        local enabled = false
        pcall(function() enabled = npc.enabled end)
        if not enabled then goto pending_continue end
        if NPCState.isPendingSleep(npc.id) and not bedNpcs[npc.id] and TimeService.getPeriod() ~= "night" then
            NPCState.clear(npc.id)
        end
        ::pending_continue::
    end
    for _, npc in ipairs(allNpcs) do
        local enabled = false
        pcall(function() enabled = npc.enabled end)
        if not enabled then goto continue end
        if isPlayerActor(npc) then
            goto continue
        end
        local id    = npc.id
        local state = NPCState.get(id)
        local inPending   = pendingNpcs[id]
        local inBed       = bedNpcs[id] ~= nil
        local schedAssign = Scheduler.getAssignment(id)
        local assignedHere = isInAssignedDestinationCell(npc, schedAssign)

        -- Resolve blacklist details for verbose logging
        local blacklisted = false
        local blacklistReason = ""
        local rec = types.NPC.record(npc)
        if rec then
            local cls  = string.lower(rec.class or "")
            local name = string.lower(rec.name  or "")
            if cls == "guard" or name:find("guard", 1, true) then
                blacklisted = true
                blacklistReason = "guard class/name"
            elseif cls == "publican" then
                blacklisted = true
                blacklistReason = "publican class"
            end
        end

        -- An NPC assigned to HomeNight and already at their destination is
        -- settled at home — treat "at_destination" the same as "at_home".
        local effectiveState = state
        if state == "at_destination" then
            if assignedHere or (schedAssign and schedAssign.moduleName == "HomeNight") then
                effectiveState = "at_home"
            end
        end

        -- Scheduler assignment info for logging
        local schedInfo = schedAssign and
            string.format("sched=%s/%s", schedAssign.moduleName, schedAssign.phase) or
            "sched=none"

        if blacklisted then
            print(string.format("[SleepManager] SKIP  %-30s state=%-28s %s  REASON: blacklisted (%s)",
                npc.recordId, state, schedInfo, blacklistReason))
        elseif inPending then
            print(string.format("[SleepManager] SKIP  %-30s state=%-28s %s  REASON: already pending",
                npc.recordId, state, schedInfo))
        elseif inBed then
            print(string.format("[SleepManager] SKIP  %-30s state=%-28s %s  REASON: already in bed",
                npc.recordId, state, schedInfo))
        elseif NPCState.canSleep(id) or effectiveState == "at_home" then
            print(string.format("[SleepManager] CAND  %-30s state=%-28s %s",
                npc.recordId, state, schedInfo))
            table.insert(candidates, npc)
        elseif useTeleport and (state == "activity" or state == "conversation"
                or state == "walking" or state == "traveling_to_seat" or state == "returning") then
            print(string.format("[SleepManager] CAND  %-30s state=%-28s %s  REASON: deep-night preempt",
                npc.recordId, state, schedInfo))
            preemptNpcForSleep(npc, "deep_night_reload")
            sleepQueue[id] = nil
            NPCState.set(id, "pending_sleep")
            table.insert(candidates, npc)
        elseif state == "sleeping" and useTeleport then
            print(string.format("[SleepManager] CAND  %-30s state=%-28s %s  REASON: reload sleeper reclaim",
                npc.recordId, state, schedInfo))
            NPCState.set(id, "pending_sleep")
            table.insert(candidates, npc)
        elseif NPCState.get(id) == "sleeping" and not inBed then
            print(string.format("[SleepManager] CLEAR stale sleep state for %s (not in bed)", npc.recordId))
            NPCState.clear(id)
        elseif state == "activity" or state == "conversation" then
            print(string.format("[SleepManager] QUEUE %-30s state=%-28s %s",
                npc.recordId, state, schedInfo))
            if not sleepQueue[id] then
                sleepQueue[id] = npc
            end
        else
            print(string.format("[SleepManager] SKIP  %-30s state=%-28s %s  REASON: ineligible state",
                npc.recordId, state, schedInfo))
        end
        ::continue::
    end
    print(string.format("[SleepManager] doScanAndAssign: %d candidates, %d queued", #candidates, (function() local n=0 for _ in pairs(sleepQueue) do n=n+1 end return n end)()))
    if #candidates == 0 then return end

    local shortlistSize = ScheduleConfig.SLEEP_SHORTLIST_SIZE or 4

    for _, npc in ipairs(candidates) do
        local distEntries = {}
        for _, bed in ipairs(beds) do
            if not FurnitureRegistry.isOccupied(bed) then
                local dp = npc.position - bed.position
                local dz = math.abs(dp.z)
                local d  = math.sqrt(dp.x * dp.x + dp.y * dp.y) + dz * dz * Z_SQUARE_SCALE
                if d < MAX_ASSIGN_DIST then
                    table.insert(distEntries, { bed = bed, dist = d })
                end
            end
        end
        table.sort(distEntries, function(a, b) return a.dist < b.dist end)

        local shortlist = {}
        for i = 1, math.min(shortlistSize, #distEntries) do
            local bed = distEntries[i].bed
            if FurnitureRegistry.peekFreeSlotIndex(bed) then
                local profileSlots = FurnitureProfiles.getSlots(bed, "sleep")
                table.insert(shortlist, {
                    bed = bed,
                    profileSlots = profileSlots,
                })
            end
        end

        if #shortlist > 0 then
            pendingNpcs[npc.id] = true
            NPCState.set(npc.id, "pending_sleep")
            print(string.format("[SleepManager] Sending PC_ConsiderBeds to %s (%d candidates, navmesh rank, teleport=%s)",
                npc.recordId, #shortlist, tostring(useTeleport)))
            npc:sendEvent("PC_ConsiderBeds", {
                beds = shortlist,
                teleport = useTeleport,
            })
        else
            print(string.format("[SleepManager] NO BED for %s — no beds in range", npc.recordId))
        end
    end
end

function SleepManager.scanAndAssignBeds(cell)
    doScanAndAssign(cell, TimeService.isDeepNight())
end

-- =============================================================================
-- PC_BedCheckResult  — NPC replied; claim slot and start lerp (or teleport)
-- =============================================================================
function SleepManager.clearPendingForNpc(npcId)
    pendingNpcs[npcId] = nil
    sleepQueue[npcId] = nil
end

function SleepManager.clearForScheduleRelocation(npcId, npc)
    if not npcId then return end

    local data = bedNpcs[npcId]
    if data and data.bed then
        pendingBeds[tostring(data.bed)] = nil
    end

    FurnitureRegistry.releaseByNpc(npcId)
    bedNpcs[npcId] = nil
    wakingNpcs[npcId] = nil
    pendingNpcs[npcId] = nil
    sleepQueue[npcId] = nil
    dialogueQueue[npcId] = nil

    if npc then
        pcall(function()
            npc:sendEvent("PC_WakeUpPlease", { immediate = true, skipLerp = true })
        end)
    end

    NPCState.clear(npcId)
    print(string.format("[SleepManager] clearForScheduleRelocation npc=%s", tostring(npcId)))
end

function SleepManager.onBedCheckResult(ev)
    local npc = ev.npc
    if not npc then return end

    -- Reject stale results for hostile NPCs
    if NPCState.isHostile(npc.id) then
        print(string.format("[SleepManager] onBedCheckResult IGNORE hostile npc=%s", tostring(npc.recordId)))
        pendingNpcs[npc.id] = nil
        local bedKey = ev.bed and tostring(ev.bed) or nil
        if bedKey then pendingBeds[bedKey] = nil end
        return
    end

    pendingNpcs[npc.id] = nil
    local bed    = ev.bed
    local bedKey = bed and tostring(bed) or nil
    if bedKey then pendingBeds[bedKey] = nil end

    print(string.format("[SleepManager] onBedCheckResult: npc=%s usable=%s",
        npc.recordId, tostring(ev.usable)))
    if not ev.usable or not bed then
        local state = NPCState.get(npc.id)
        if (state == "sleeping" or state == "pending_sleep") and not bedNpcs[npc.id] then
            NPCState.clear(npc.id)
        end
        return
    end

    -- Claim the first free slot (authoritative; losers retry on next rescan).
    local slot = FurnitureRegistry.claimSlot(bed, npc.id)
    if not slot then
        ensureBedRegistered(bed)
        slot = FurnitureRegistry.claimSlot(bed, npc.id)
    end
    if not slot then
        print(string.format("[SleepManager] SOFT REJECT %s — claim race on bed %s",
            npc.recordId, tostring(bed and bed.recordId)))
        pendingNpcs[npc.id] = nil
        pcall(function() npc:sendEvent("PC_CancelTravelToBed", { reason = "bed_claim_race" }) end)
        pcall(function() npc:sendEvent("PC_RestoreHello", {}) end)
        local state = NPCState.get(npc.id)
        if (state == "sleeping" or state == "pending_sleep") and not bedNpcs[npc.id] then
            NPCState.clear(npc.id)
        end
        return
    end

    local poseSlot = slot
    if slot.isOverride then
        local freshSlots = FurnitureProfiles.getSlots(bed, "sleep")
        local freshSlot = freshSlots and (freshSlots[slot.index or 1] or freshSlots[1]) or nil
        if freshSlot and freshSlot.pos then
            poseSlot = freshSlot
        end
    end

    -- Only disturb a sitting NPC after the authoritative bed claim succeeds.
    -- Several NPCs can validate the same nearby bed in parallel; cancelling
    -- sitting before this point makes claim-race losers stand up for no reason.
    local SittingGlobal = require("scripts.ProceduralChatter.SittingGlobal")
    local wasSitting = NPCState.isSitting(npc.id) or SittingGlobal.isSitting(npc)
    if wasSitting then
        SittingGlobal.forceRelease(npc.id)
        npc:sendEvent("PC_CancelTravelToSeat", {})
        if NPCState.get(npc.id) == "traveling_to_seat" then
            NPCState.clear(npc.id)
        end
        npc:sendEvent("PC_StandUpPlease", {})
        print(string.format("[SleepManager] Cancelled sitting for %s after bed claim", npc.recordId))
    end

    -- Facing: bed long axis + 180° correction so the NPC lies
    -- head-toward-headboard rather than feet-toward-headboard.
    -- Use local X directly (proven correct for standard Morrowind beds).
    -- FurnitureRegistry.getOrientation requires openmw.nearby which is
    -- unavailable in global scripts and always returns a "y" fallback,
    -- causing a 90° rotation on beds whose long axis is local X.
    local longAxisLocal = util.vector3(1, 0, 0)
    local facingAngle
    local ok, forward = pcall(function() return bed.rotation * longAxisLocal end)
    if poseSlot.facing then
        facingAngle = math.atan2(poseSlot.facing.x, poseSlot.facing.y)
        forward = poseSlot.facing
    elseif ok and forward then
        facingAngle = math.atan2(forward.x, forward.y) + math.pi
    else
        facingAngle = math.pi
    end

    -- Seated position: override slots have explicit offsets; normal slots use BED_Z_OFFSET.
    local seatedPos
    if poseSlot.isOverride and poseSlot.pos then
        seatedPos = poseSlot.pos
    else
        local base = poseSlot.pos or bed.position
        seatedPos  = util.vector3(base.x, base.y, base.z + BED_Z_OFFSET)
    end

    -- Apply animation normalization offset if provided by SleepLogic.
    if ev.animationOffset then
        local off = ev.animationOffset
        local fwd = util.vector3(math.sin(facingAngle), math.cos(facingAngle), 0)
        local right = util.vector3(fwd.y, -fwd.x, 0)
        seatedPos = util.vector3(
            seatedPos.x + right.x * (off.finalRightOffset or 0) + fwd.x * (off.finalForwardOffset or 0),
            seatedPos.y + right.y * (off.finalRightOffset or 0) + fwd.y * (off.finalForwardOffset or 0),
            seatedPos.z + (off.finalZOffset or 0)
        )
        if off.yawOffset then
            facingAngle = facingAngle + (off.yawOffset * math.pi / 180)
            forward = util.vector3(math.sin(facingAngle), math.cos(facingAngle), 0)
        end
    end

    print(string.format(
        "[SleepManager] bed pose npc=%s bed=%s bedPos=%s slotPos=%s seatedPos=%s slotOverride=%s profileId=%s slotId=%s animOffset=(%s,%s,%s yaw=%s)",
        tostring(npc.recordId),
        tostring(bed.recordId),
        tostring(bed.position),
        tostring(poseSlot.pos),
        tostring(seatedPos),
        tostring(poseSlot.isOverride),
        tostring(poseSlot.profileId),
        tostring(poseSlot.slotId),
        tostring(ev.animationOffset and ev.animationOffset.finalRightOffset),
        tostring(ev.animationOffset and ev.animationOffset.finalForwardOffset),
        tostring(ev.animationOffset and ev.animationOffset.finalZOffset),
        tostring(ev.animationOffset and ev.animationOffset.yawOffset)
    ))

    local seatedRot = util.transform.rotateZ(facingAngle)

    -- Mark pending sleep while the NPC walks/lerps into bed. SleepLogic sends
    -- the authoritative "sleeping" state once PC_TeleportSleepPlease starts
    -- the sleep idle on the local actor.
    NPCState.set(npc.id, "pending_sleep")

    -- Cancel any stale wake lerp.
    wakingNpcs[npc.id] = nil

    -- exitPos: floor position beside the bed, found by SleepLogic via nearby raycast.
    -- This is where the NPC walks to and where they return on wake.
    local exitPos    = ev.exitPos
    -- Guard against bad navmesh snaps that place exitPos far from the bed.
    if not exitPos or (exitPos - bed.position):length() > 200 then
        exitPos = npc.position
    end
    local exitRot    = npc.rotation  -- facing at assignment time; good enough for return

    -- Canonical original position may be used as pre-activity return point only
    -- when the NPC is currently in their original cell.
    local eventOriginalPosition = ev.originalPosition
    local eventOriginalRotation = ev.originalRotation

    -- Save exit position to persistent storage immediately — available on wake
    -- even if the cell unloads before the NPC reaches the bed.
    if exitPos then
        saveBedExit(bed, exitPos, exitRot)
    end

    local preSleepPos = exitPos or npc.position
    local preSleepRot = exitRot or npc.rotation
    local preActivityPosition, preActivityRotation, sameOriginCell = resolvePreActivityTarget(
        npc,
        preSleepPos,
        preSleepRot,
        eventOriginalPosition,
        eventOriginalRotation
    )

    local walkTarget = preSleepPos  -- NPC walks to exitPos, not to the bed itself

    bedNpcs[npc.id] = {
        npc            = npc,
        bed            = bed,
        walkTarget     = walkTarget,
        seatedPosition = seatedPos,
        seatedRotation = seatedRot,
        arrived        = false,
        preActivityPosition = preActivityPosition,
        preActivityRotation = preActivityRotation,
        wakeToWander   = not sameOriginCell,
        preSleepPos    = preSleepPos,
        preSleepRot    = preSleepRot,
    }

    if TimeService.isDeepNight() then
        -- Deep night: exitPos is already known from the raycast, so teleport directly.
        -- NPC goes straight to bed; wake will lerp back to the saved exit position.
        local npcId = npc.id
        local sleepCell = nil
        pcall(function() sleepCell = npc.cell end)
        Utils.tryTeleport(npc, sleepCell, seatedPos, { rotation = seatedRot })
        local refreshed = refreshActorHandle(npcId, sleepCell)
        if refreshed then
            bedNpcs[npcId].npc = refreshed
            npc = refreshed
        end
        local evOk = pcall(function() npc:sendEvent("PC_TeleportSleepPlease", {}) end)
        bedNpcs[npcId].sleepEventPending = not evOk
        bedNpcs[npcId].arrived = true
    else
        -- Normal bedtime: walk to exitPos, then lerp into bed on arrival.
        npc:sendEvent("PC_SaveBehavior", {})
        npc:sendEvent("StartAIPackage", {
            type         = "Travel",
            destPosition = walkTarget,
            isRepeat     = false,
        })
    end
end

-- =============================================================================
-- PC_WakePositionFound — NPC-local raycasted a valid floor spot; act on it
-- =============================================================================
function SleepManager.onWakePositionFound(ev)
    local npc = ev.npc
    if not npc or not Utils.isObjValid(npc) then return end
    local npcId = npc.id
    print(string.format("[SleepManager] onWakePositionFound: npc=%s immediate=%s skipLerp=%s fallbackPos=%s",
        npc.recordId, tostring(ev.immediate), tostring(ev.skipLerp), tostring(ev.fallbackPos)))
    -- Discard stale event if NPC was re-assigned to a bed (fast wait race).
    if bedNpcs[npcId] then return end
    -- Daytime snap already handled in forceWake; this event is just the anim-stop signal.
    if ev.skipLerp then return end

    -- wakePos is always nil with the new exit-pos-at-assignment approach.
    -- The destination is the preSleepPos passed back as fallbackPos.
    local exitPos  = ev.fallbackPos   -- lerp destination: floor beside bed
    local exitRot  = ev.fallbackRot
    local preActivityPosition = ev.preActivityPosition
    local preActivityRotation = ev.preActivityRotation

    if not exitPos then
        print(string.format("[SleepManager] No wake destination for %s — skipping", npc.recordId))
        NPCState.clear(npcId)
        return
    end

    local startPos = npc.position  -- NPC is lying on bed surface

    if ev.immediate then
        -- Player-initiated wake: teleport directly to exit pos, no lerp.
        Utils.tryTeleport(npc, npc.cell, exitPos, { rotation = exitRot or npc.rotation })
        if TimeService.getPeriod() == "night" then
            SleepManager._rescanAfterWake = true
        end
        wakingNpcs[npcId] = {
            npc          = npc,
            startPos     = exitPos,
            targetPos    = exitPos,
            lerpTime     = WAKE_LERP_DURATION,  -- skip lerp phase
            monitorTimer = 0,
            fallbackPos  = exitPos,
            fallbackRot  = exitRot,
            preActivityPosition = preActivityPosition,
            preActivityRotation = preActivityRotation,
            wakeToWander = ev.wakeToWander,
            lastPos      = exitPos,
        }
        -- If this wake was for dialogue, open it now that the NPC is standing.
        local activator = dialogueQueue[npcId]
        if activator then
            dialogueQueue[npcId] = nil
            npc:sendEvent("PC_ActivateBy", { activator = activator })
        end
    else
        -- Natural wake (dawn/combat): lerp from bed surface to floor beside bed.
        wakingNpcs[npcId] = {
            npc          = npc,
            startPos     = startPos,
            targetPos    = exitPos,
            lerpTime     = 0,
            monitorTimer = 0,
            fallbackPos  = exitPos,
            fallbackRot  = exitRot,
            preActivityPosition = preActivityPosition,
            preActivityRotation = preActivityRotation,
            wakeToWander = ev.wakeToWander,
            lastPos      = nil,
        }
    end
end

-- =============================================================================
-- PC_SleepWakeComplete — NPC finished the get-up animation; clean up global state
-- =============================================================================
function SleepManager.onSleepWakeComplete(ev)
    local npc = ev.npc
    if not npc then return end
    -- State was already cleared in forceWake; this is just a completion signal.
    -- Future use: e.g. re-assign a new wander package after getting up.
end

-- =============================================================================
-- Force-wake a single NPC (combat, alarm, dawn)
-- =============================================================================
-- immediate=true   -> player-interaction wake: teleport to exitPos, no lerp.
-- immediate=false  -> natural wake (dawn/combat): lerp from bed to exitPos,
--                    then travel home.
-- Daytime (≥10:00) -> skip everything: teleport straight to preActivityPosition instantly.
local DAYTIME_WAKE_HOUR = 10
function SleepManager.forceWake(npcId, immediate, snapToHome)
    -- Clear any queued dialogue — this wake supersedes it.
    dialogueQueue[npcId] = nil

    local data = bedNpcs[npcId]
    if not data then return end

    -- exitPos: floor beside bed — lerp destination.
    -- preActivityPosition: local return destination after wake.
    local exitPos = data.preSleepPos
    local exitRot = data.preSleepRot
    if not exitPos and data.bed then
        exitPos, exitRot = loadBedExit(data.bed)
    end
    local homeCellName = ""
    if not exitPos and data.npc then
        homeCellName, exitPos, exitRot = NPCState.loadNativeHome(data.npc)
    end

    local preActivityPosition = data.preActivityPosition
    local preActivityRotation = data.preActivityRotation
    local wakeToWander = data.wakeToWander

    print(string.format(
        "[SleepManager] forceWake: npcId=%s immediate=%s snapToHome=%s exitPos=%s preActivity=%s",
        tostring(npcId), tostring(immediate), tostring(snapToHome), tostring(exitPos), tostring(preActivityPosition)
    ))

    FurnitureRegistry.releaseByNpc(npcId)
    NPCState.set(npcId, "waking")
    bedNpcs[npcId] = nil

    local npc = data.npc
    if not Utils.isObjValid(npc) then return end

        -- Snap to home only when the player fast-waited (time skipped in a single frame).
    if snapToHome then
        local dest  = preActivityPosition or exitPos
        local destR = preActivityRotation or exitRot
        if dest then
            -- Use the stored home cell name so interior NPCs don't get dumped into the void.
            local teleportCell = homeCellName
            if not teleportCell or teleportCell == "" then
                teleportCell = npc.cell and npc.cell.name or ""
            end
            Utils.tryTeleport(npc, teleportCell, dest, { rotation = destR or npc.rotation })
        end
        -- Tell the local script to stop the animation and restore hello.
        npc:sendEvent("PC_WakeUpPlease", { immediate = true, skipLerp = true,
            fallbackPos = dest, fallbackRot = destR,
            preActivityPosition = preActivityPosition,
            preActivityRotation = preActivityRotation,
            wakeToWander = wakeToWander,
        })
        NPCState.clear(npcId)   -- no monitor window needed; NPC is already home
        wakingNpcs[npcId] = nil
        return
    end

    npc:sendEvent("PC_WakeUpPlease", {
        immediate   = immediate or false,
        fallbackPos = exitPos,
        fallbackRot = exitRot,
        preActivityPosition = preActivityPosition,
        preActivityRotation = preActivityRotation,
        wakeToWander = wakeToWander,
    })

    -- Defensive fallback: if the NPC-local wake callback is dropped or delayed,
    -- keep a wake entry so the global loop can still lerp/monitor recovery.
    if exitPos then
        wakingNpcs[npcId] = wakingNpcs[npcId] or {
            npc          = npc,
            startPos     = npc.position,
            targetPos    = exitPos,
            lerpTime     = (immediate and WAKE_LERP_DURATION) or 0,
            monitorTimer = 0,
            fallbackPos  = exitPos,
            fallbackRot  = exitRot,
            preActivityPosition = preActivityPosition,
            preActivityRotation = preActivityRotation,
            wakeToWander = wakeToWander,
            lastPos      = immediate and exitPos or nil,
        }
    end
end

-- Wake all currently sleeping NPCs (dawn transition or cell change).
-- snapToHome=true skips lerp and teleports directly to native home (used on fast-wait).
local function wakeAll(snapToHome)
    local count = 0
    for _ in pairs(bedNpcs) do count = count + 1 end
    print(string.format("[SleepManager] wakeAll: sleepingCount=%d snapToHome=%s", count, tostring(snapToHome)))
    for npcId, _ in pairs(bedNpcs) do
        SleepManager.forceWake(npcId, false, snapToHome)
    end
end

--- Returns true if the NPC is currently tracked as in-bed by SleepManager.
function SleepManager.isInBed(npcId)
    return bedNpcs[npcId] ~= nil
end

--- Request a deferred sleep scan for the given cell.  Used by
--- PostArrivalCoordinator so that SleepManager can batch scans and avoid
--- racing with onCellChange on player cell entry.
function SleepManager.setDialogueMenuActive(active)
    dialogueMenuActive = active
end

function SleepManager.requestScan(cell)
    pendingScanCell = cell
end

-- =============================================================================
-- Cell change
-- =============================================================================
function SleepManager.onCellChange(cell)
    -- Snapshot NPC positions FIRST — before wakeAll() or any scan touches them.
    NPCState.snapshotCell(cell)

    local period = TimeService.getPeriod()
    local hour   = TimeService.getHour()
    print(string.format("[SleepManager] onCellChange: period=%s hour=%.1f", period, hour))

    if period ~= "night" then
        -- Daytime: wake everyone up, release slots, clear tracking.
        wakeAll()
    else
        -- Night: preserve bedNpcs for NPCs still present in the cell
        -- so the frame-rate lock teleport keeps running. Only release
        -- slots and clear entries for NPCs that are no longer loaded.
        local newBedNpcs = {}
        for npcId, data in pairs(bedNpcs) do
            if Utils.isObjValid(data.npc) and data.npc.cell and data.npc.cell.name == cell.name then
                newBedNpcs[npcId] = data
            else
                FurnitureRegistry.releaseByNpc(npcId)
            end
        end
        bedNpcs = newBedNpcs
    end
    wakingNpcs  = {}
    pendingBeds = {}
    pendingNpcs = {}
    sleepQueue  = {}
    prevHour    = nil
    nightRescanTimer = 0
    -- Set reconcile hour so onUpdate doesn't fire reconcileSleepHour
    -- immediately after onCellChange already scanned.
    lastNightReconcileHour = math.floor(TimeService.getHour()) % 24

    -- doScanAndAssign guards itself against non-night periods, so this is safe
    -- to call unconditionally.  It handles mid-night cell entry correctly.
    -- Clear any pending scan request first — onCellChange is the authoritative scan.
    pendingScanCell = nil
    doScanAndAssign(cell, TimeService.isDeepNight())
end

-- =============================================================================
-- onUpdate — lerp loop + period-transition triggers
-- =============================================================================
function SleepManager.onUpdate(dt)
    if not ScheduleConfig.SLEEP_MANAGER_ENABLED then return end
    local player = world.players[1]
    if not player then return end

    -- Cell change detection.
    if player.cell ~= lastCell then
        lastCell = player.cell
        SleepManager.onCellChange(player.cell)
        return  -- let next frame pick up lerp
    end

    -- Post-wake rescan: put NPCs back to sleep after a delay (lets conversation finish).
    if SleepManager._rescanAfterWake then
        SleepManager._rescanAfterWake = nil
        rescanTimer = 60.0   -- 60s before re-assigning NPCs to beds
    end
    if rescanTimer then
        rescanTimer = rescanTimer - dt
        if rescanTimer <= 0 then
            rescanTimer = nil
            if TimeService.getPeriod() == "night" then
                SleepManager.scanAndAssignBeds(player.cell)
            end
        end
    end

    -- Period transition detection.
    local nowHour = TimeService.getHour()
    local nowHourInt = math.floor(nowHour) % 24
    if prevHour == nil then
        prevHour = nowHour
    else
        local transition = TimeService.getPeriodTransition(prevHour, nowHour)
        if transition == "night" then
            if not dialogueMenuActive then
                SleepManager.scanAndAssignBeds(player.cell)
            end
        elseif TimeService.justCrossed(prevHour, nowHour, WAKE_HOUR) then
            print(string.format("[SleepManager] WAKE_HOUR crossed: prev=%.2f now=%.2f wakeHour=%d",
                prevHour, nowHour, WAKE_HOUR))
            -- Snap to home only when it's already well past wake time (player entered
            -- late or fast-waited far past 9 AM).  Between 7-9 AM always do normal wake.
            local snapToHome = (nowHour >= SNAP_HOUR and nowHour < 23)
            wakeAll(snapToHome)
        end
        prevHour = nowHour
    end

    if TimeService.getPeriod() == "night" then
        if lastNightReconcileHour ~= nowHourInt then
            lastNightReconcileHour = nowHourInt
            reconcileSleepHour(player.cell, nowHourInt)
        end
    else
        lastNightReconcileHour = nil
    end

    -- Periodic night rescan: catch NPCs that became available after the initial
    -- 23:00 scan (e.g. schedule state resolved, conversation ended, etc.).
    if TimeService.getPeriod() == "night" then
        nightRescanTimer = nightRescanTimer + dt
        if nightRescanTimer >= 60.0 then
            nightRescanTimer = 0
            SleepManager.scanAndAssignBeds(player.cell)
        end
    else
        nightRescanTimer = 0
    end

    -- Arrival-snap loop (mirrors SittingGlobal pattern).
    for npcId, data in pairs(bedNpcs) do
        local npc = data.npc
        if not Utils.isObjValid(npc) then
            -- Try to refresh the handle from active actors before giving up.
            -- Handles can become stale across cell reloads; the NPC may still exist.
            local refreshed = refreshActorHandle(npcId, player.cell)
            if refreshed then
                data.npc = refreshed
                data.missingHandleTimer = nil
                if data.sleepEventPending then
                    pcall(function() refreshed:sendEvent("PC_TeleportSleepPlease", {}) end)
                    data.sleepEventPending = nil
                end
                if ScheduleConfig.DEBUG_MODE then
                    print(string.format("[SleepManager] Refreshed stale bed handle for npc=%s", tostring(npcId)))
                end
            else
                data.missingHandleTimer = (data.missingHandleTimer or 0) + dt
                if data.missingHandleTimer >= 3.0 then
                    FurnitureRegistry.releaseByNpc(npcId)
                    NPCState.clear(npcId)
                    bedNpcs[npcId] = nil
                    print(string.format("[SleepManager] Cleared bed entry for npc=%s (handle invalid, not found after grace)", tostring(npcId)))
                end
            end
        elseif data.arrived then
            -- Already snapped to bed; lock position every frame so engine AI
            -- can't nudge the NPC off the surface.
            Utils.tryTeleport(npc, npc.cell, data.seatedPosition, { rotation = data.seatedRotation })
        else
            -- Still walking toward the bed.
            data.walkTimer = (data.walkTimer or 0) + dt
            local dp = npc.position - data.walkTarget
            local horizDist = math.sqrt(dp.x * dp.x + dp.y * dp.y)
            local zDiff = math.abs(dp.z)
            local dist = math.sqrt(dp.x * dp.x + dp.y * dp.y + dp.z * dp.z)

            -- Snap when arrived at the exit position (or safety timeout).
            -- NPC is walking to a real floor point so normal pathfinding gets them there;
            -- BED_ARRIVE_DIST catches the last few units where pathfinding stops.
            local shouldSnap = false
            if data.walkTimer >= WALK_TIMEOUT then
                print(string.format("[SleepManager] Walk timeout for %s (dist=%.0f horiz=%.0f z=%.0f) — snapping to bed.",
                    npc.recordId, dist, horizDist, zDiff))
                shouldSnap = true
            elseif dist < BED_ARRIVE_DIST or horizDist < BED_ARRIVE_DIST then
                if zDiff > BED_ARRIVE_DIST then
                    print(string.format("[SleepManager] Bed arrival for %s using horizontal distance (horiz=%.0f z=%.0f target=%s)",
                        npc.recordId, horizDist, zDiff, tostring(data.walkTarget)))
                end
                shouldSnap = true
            end

            if shouldSnap and not data.laydownLerp then
                npc:sendEvent("PC_CancelTravelToBed", { resetState = false })
                -- Start full sleep idle (slee8) and positional lerp simultaneously.
                npc:sendEvent("PC_TeleportSleepPlease", {})
                -- Capture the exact point where bed laydown lerp starts so wake returns
                -- to the practical reachable spot, not a potentially bad bed-side probe.
                data.preSleepPos = npc.position
                data.preSleepRot = npc.rotation
                data.laydownLerp = {
                    startPos = npc.position,
                    lerpTime = 0,
                }
            end

            if data.laydownLerp then
                local ld = data.laydownLerp
                ld.lerpTime = ld.lerpTime + dt
                local t = math.min(ld.lerpTime / LAYDOWN_LERP_DURATION, 1.0)
                local p = ld.startPos + (data.seatedPosition - ld.startPos) * t
                Utils.tryTeleport(npc, npc.cell, p, { rotation = data.seatedRotation })
                if t >= 1.0 then
                    data.laydownLerp = nil
                    data.arrived     = true
                    -- Animation already in progress (slee7 -> slee8 via SleepLogic.update).
                    -- No additional event needed here.
                end
            end
        end
    end

    -- Wake lerp + 30s safety-net loop.
    local MONITOR_TIMEOUT = 30.0
    local MONITOR_TIMEOUT_WANDER = 5.0
    local STUCK_DIST      = 20   -- NPC moved less than this = considered stuck
    for npcId, wd in pairs(wakingNpcs) do
        local npc = wd.npc
        if not Utils.isObjValid(npc) then
            wakingNpcs[npcId] = nil
        elseif wd.lerpTime < WAKE_LERP_DURATION then
            -- Lerp phase: slide from bed surface to floor beside bed.
            wd.lerpTime = wd.lerpTime + dt
            local t = math.min(wd.lerpTime / WAKE_LERP_DURATION, 1.0)
            local p = wd.startPos + (wd.targetPos - wd.startPos) * t
            Utils.tryTeleport(npc, npc.cell, p, {})
            if t >= 1.0 then
                wd.lastPos = npc.position
                -- Notify local script that wake-up is PHYSICALLY complete.
                npc:sendEvent("PC_WakeUpFinished", {})
                
                -- Decide what to do after the NPC stands up.
                -- If this NPC is under HomeNight's schedule they are still inside
                -- their home interior and will be sent outside at LEAVE_HOME_HOUR.
                -- Sending Travel to the native exterior position from an interior
                -- is unreachable and freezes them in place, so send Wander instead.
                -- For all other NPCs (e.g. mid-night combat wake), Travel home.
                local isHomeScheduled = false
                local a = Scheduler.getAssignment(npcId)
                isHomeScheduled = a ~= nil and a.moduleName == "HomeNight"

                local didWander = false
                if isHomeScheduled then
                    print(string.format("[SleepManager] wake complete: npc=%s path=homeScheduledWander",
                        npc.recordId))
                    npc:sendEvent("PC_StartWander", {})
                    didWander = true
                else
                    if wd.wakeToWander then
                        print(string.format("[SleepManager] wake complete: npc=%s path=originCellMismatchWander",
                            npc.recordId))
                        npc:sendEvent("PC_StartWander", {})
                        didWander = true
                        if TimeService.getPeriod() == "night" then
                            SleepManager._rescanAfterWake = true
                        end
                        goto wake_complete_continue
                    end
                    local travelDest = wd.preActivityPosition or wd.fallbackPos
                    if not travelDest then
                        print(string.format("[SleepManager] wake complete: npc=%s path=fallbackWander",
                            npc.recordId))
                        npc:sendEvent("PC_StartWander", {})
                        didWander = true
                    else
                        print(string.format("[SleepManager] wake complete: npc=%s path=travel dest=%s",
                            npc.recordId, tostring(travelDest)))
                        npc:sendEvent("PC_SaveBehavior", {})
                        npc:sendEvent("StartAIPackage", {
                            type         = "Travel",
                            destPosition = travelDest,
                            isRepeat     = false,
                        })
                    end
                end
                ::wake_complete_continue::
                -- Keep a short monitor window for wander handoff (5s) and
                -- the full safety window for travel-to-return (30s).
                wd.monitorTimer = 0
                wd.monitorTimeout = didWander and MONITOR_TIMEOUT_WANDER or MONITOR_TIMEOUT
                if TimeService.getPeriod() == "night" then
                    SleepManager._rescanAfterWake = true
                end
            end
        else
            -- Monitoring phase: watch for 30s in case NPC landed in a bad spot.
            wd.monitorTimer = (wd.monitorTimer or 0) + dt
            local timeout = wd.monitorTimeout or MONITOR_TIMEOUT
            if wd.monitorTimer >= timeout then
                -- Check if NPC has barely moved (stuck in void/wall).
                local moved = wd.lastPos and (npc.position - wd.lastPos):length() or math.huge
                if moved < STUCK_DIST and wd.fallbackPos then
                    print(string.format("[SleepManager] Safety teleport for stuck NPC %s", npc.recordId))
                    Utils.tryTeleport(npc, npc.cell, wd.fallbackPos,
                        { rotation = wd.fallbackRot or npc.rotation })
                end
                NPCState.clear(npcId)   -- waking -> idle; now safe for activities
                wakingNpcs[npcId] = nil
            end
        end
    end

    -- Sleep queue: assign beds to NPCs that were busy at scan time but are now idle.
    -- Only runs during night period to avoid assigning beds after dawn.
    if TimeService.getPeriod() == "night" and not dialogueMenuActive then
        for npcId, npc in pairs(sleepQueue) do
            if not Utils.isObjValid(npc) then
                sleepQueue[npcId] = nil
            elseif (NPCState.canSleep(npcId) or TimeService.isDeepNight()) and not pendingNpcs[npcId] then
                sleepQueue[npcId] = nil
                -- Find nearest available bed and send PC_ConsiderBed.
                local best, bestDist = nil, math.huge
                for _, obj in ipairs(player.cell:getAll()) do
                    if isBedObject(obj) and not FurnitureRegistry.isOccupied(obj)
                            and not pendingBeds[tostring(obj)] then
                        local d = (npc.position - obj.position):length()
                        if d < bestDist and d < MAX_ASSIGN_DIST then
                            best     = obj
                            bestDist = d
                        end
                    end
                end
                if best then
                    if TimeService.isDeepNight() then
                        preemptNpcForSleep(npc, "deep_night_queue_flush")
                    end
                    print(string.format("[SleepManager] Sleep-queue assigning %s to bed (dist=%.0f)", npc.recordId, bestDist))
                    pendingNpcs[npcId]          = true
                    pendingBeds[tostring(best)] = true
                    NPCState.set(npcId, "pending_sleep")
                    npc:sendEvent("PC_ConsiderBed", {
                        bed = best,
                        teleport = TimeService.isDeepNight(),
                    })
                end
            end
        end
    end

    -- Process any deferred scan request (e.g. from PostArrivalCoordinator for
    -- NPCs that materialised after onCellChange already ran).  This avoids the
    -- double-scan race where PostArrivalCoordinator and onCellChange both send
    -- PC_ConsiderBeds to the same newly-arrived NPC before the first reply lands.
    if pendingScanCell and not dialogueMenuActive then
        local cell = pendingScanCell
        pendingScanCell = nil
        doScanAndAssign(cell, TimeService.isDeepNight())
    end
end

-- =============================================================================
-- PC_WakeForDialogue — player activated a sleeping NPC; wake them and queue dialogue
-- =============================================================================
function SleepManager.onWakeForDialogue(ev)
    local npc = ev.npc
    local activator = ev.activator
    if not npc then return end
    local npcId = npc.id

    print(string.format("[SleepManager] WakeForDialogue: npc=%s", npc.recordId))
    dialogueQueue[npcId] = activator
    SleepManager.forceWake(npcId, true)
end

-- =============================================================================
-- Combat hook — wake NPC if they enter combat while sleeping
-- =============================================================================
function SleepManager.onCombatStarted(ev)
    local actor = ev.actor
    if not actor then return end
    if bedNpcs[actor.id] then
        SleepManager.forceWake(actor.id)
    end
end

return SleepManager
