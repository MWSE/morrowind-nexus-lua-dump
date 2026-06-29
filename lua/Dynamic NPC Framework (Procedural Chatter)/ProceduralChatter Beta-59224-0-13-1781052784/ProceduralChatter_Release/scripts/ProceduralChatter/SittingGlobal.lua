-- SittingGlobal.lua
local core = require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')
-- Lazy-load world so local scripts can require this module for isSitting().
local world = nil
local FurnitureRegistry = require("scripts.ProceduralChatter.FurnitureRegistry")
local NPCState = require("scripts.ProceduralChatter.NPCState")
local ScheduleConfig = require("scripts.ProceduralChatter.data.ScheduleConfig")

local SittingGlobal = {}

local Utils = require("scripts.ProceduralChatter.Utils")
local Blacklist = require("scripts.ProceduralChatter.Blacklist")
local FurnitureProfiles = require("scripts.ProceduralChatter.data.FurnitureProfiles")
local ConversationManager

-- Animation access for detecting external sitters (best-effort in global context).
local anim = nil
pcall(function() anim = require('openmw.animation') end)

-- =============================================================================
-- State
-- =============================================================================
local assignedNpcs = {} -- Map: npc.id -> { npc, position, facingDirection, ... }
-- assignedStools migrated to FurnitureRegistry (claimSlot/releaseByNpc)
local pendingOffers = {} -- Map: npc.id -> { stool = obj, slotIndex = number? } (NPC is currently thinking)
local pendingStools = {} -- Map: stool.id -> true (Stool is being considered)
local rejectedStools = {} -- Map: stool.id -> expiry time after local geometry rejection
local conversationOverrides = {} -- Map: npc.id -> targetAngle (float) or nil

local pendingStandTeleports = {} 
local lastCell = nil
local scanTimer = 0 
local sittingTime = 0
local externallyOccupiedStools = {} -- Map: stool.id -> true (external NPC sitting on it)

-- Config
local DEFAULT_SITTING_Z_OFFSET = -36
local DEFAULT_SITTING_FORWARD_OFFSET = -7
local REJECTED_STOOL_COOLDOWN = 30.0
local lerpDuration = 1.0

-- Retrieve per-record offsets from TSV profiles, falling back to defaults.
local function getSittingOffsets(stool)
    if not stool then
        return DEFAULT_SITTING_Z_OFFSET, DEFAULT_SITTING_FORWARD_OFFSET
    end
    local rid = ""
    pcall(function() rid = stool.recordId or "" end)
    local profile = FurnitureProfiles.getChairOffsets(rid)
    if profile then
        return profile.zOffset or DEFAULT_SITTING_Z_OFFSET,
               profile.forwardOffset or DEFAULT_SITTING_FORWARD_OFFSET
    end
    return DEFAULT_SITTING_Z_OFFSET, DEFAULT_SITTING_FORWARD_OFFSET
end

local function angleToForward(angle)
    return util.vector3(math.sin(angle), math.cos(angle), 0)
end

local function applySeatedPoseOffsets(anchor, baseAngle, zOffset, fwdOffset, animationOffset)
    local baseFwd = angleToForward(baseAngle)
    local pos = anchor + util.vector3(
        baseFwd.x * (fwdOffset or 0),
        baseFwd.y * (fwdOffset or 0),
        zOffset or 0
    )
    local visualAngle = baseAngle
    if animationOffset then
        local yawOffset = (animationOffset.yawOffset or 0) * math.pi / 180
        local baseRight = util.vector3(baseFwd.y, -baseFwd.x, 0)
        pos = util.vector3(
            pos.x + baseRight.x * (animationOffset.finalRightOffset or 0) + baseFwd.x * (animationOffset.finalForwardOffset or 0),
            pos.y + baseRight.y * (animationOffset.finalRightOffset or 0) + baseFwd.y * (animationOffset.finalForwardOffset or 0),
            pos.z + (animationOffset.finalZOffset or 0)
        )
        visualAngle = visualAngle + yawOffset
    end
    return pos, visualAngle
end

local function getHardcodedSeatSlotCount(recordId)
    local id = string.lower(recordId or "")
    if id == "furn_de_p_bench_03" or id == "furn_com_p_bench_01" then
        return 2
    end
    if id == "furn_de_p_stool_01"
            or id == "furn_com_p_stool_01"
            or id == "furn_com_rm_chair_03"
            or id:find("barstool", 1, true) then
        return 1
    end
    return nil
end

local function ensureSeatRegistered(obj)
    if FurnitureProfiles.isFurnitureObjectBlacklisted(obj) then return false end
    if FurnitureRegistry.isRegistered(obj) then return true end

    local slots = FurnitureProfiles.getSlots(obj, "sit")
    if slots and #slots > 0 then
        FurnitureRegistry.register(obj, slots)
        return true
    end

    local count = getHardcodedSeatSlotCount(obj.recordId)
    if count then
        FurnitureRegistry.register(obj, count)
        return true
    end
    return false
end

local function isSeatObject(obj)
    if not obj then return false end
    if FurnitureProfiles.isFurnitureObjectBlacklisted(obj) then return false end
    if FurnitureProfiles.getProfileForObject(obj, "sit") then return true end
    return getHardcodedSeatSlotCount(obj.recordId) ~= nil
end

-- =============================================================================
-- Core Logic
-- =============================================================================

-- Helper: Get object ID safely
local function getObjId(obj)
    -- Use tostring(obj) to ensure unique instance key (Userdata pointer/ID)
    return tostring(obj)
end

local function isTemporarilyRejected(obj)
    local expiry = rejectedStools[getObjId(obj)]
    if not expiry then return false end
    if expiry <= sittingTime then
        rejectedStools[getObjId(obj)] = nil
        return false
    end
    return true
end

local function isConversationActive(npc)
    if not npc then return false end
    if not ConversationManager then
        pcall(function() ConversationManager = require("scripts.ProceduralChatter.ConversationManager") end)
    end
    return ConversationManager and ConversationManager.isActive and ConversationManager.isActive(npc)
end

local function findNearestBarCounter(stool, cell)
    if not stool or not cell then return nil end
    local nearest, nearestDist = nil, math.huge
    for _, obj in ipairs(cell:getAll()) do
        local rid = ""
        pcall(function() rid = obj.recordId or "" end)
        local id = string.lower(rid)
        if id:find("bar", 1, true) and not id:find("barstool", 1, true) then
            local d = (obj.position - stool.position):length()
            if d < nearestDist and d < 500 then
                nearestDist = d
                nearest = obj
            end
        end
    end
    return nearest
end

local function findNearestTable(stool, cell)
    if not stool or not cell then return nil end
    local nearest, nearestDist = nil, math.huge
    for _, obj in ipairs(cell:getAll()) do
        if FurnitureProfiles.isTableObject(obj) then
            local d = (obj.position - stool.position):length()
            if d < nearestDist and d < 300 then
                nearestDist = d
                nearest = obj
            end
        end
    end
    return nearest
end

-- =============================================================================
-- External-Sitter Guard: skip stools already occupied by NPCs from other mods
-- =============================================================================

local EXTERNAL_SITTER_H_RADIUS = 35   -- horizontal distance threshold
local EXTERNAL_SITTER_V_RADIUS = 30   -- vertical distance threshold
local RELOAD_SITTER_H_RADIUS = 120
local RELOAD_SITTER_V_RADIUS = 100

local function isNpcManagedByUs(npc)
    local id = npc.id
    if assignedNpcs[id] or pendingOffers[id] then return true end
    if NPCState.isSitting(id) or NPCState.isSleeping(id) or NPCState.isPendingSleep(id) then return true end
    local state = NPCState.get(id)
    if state == "waking" then return true end
    return false
end

local function clearSeatOfferState(npcId)
    local state = NPCState.get(npcId)
    if state == "traveling_to_seat" then
        NPCState.clear(npcId)
    end
end

local function isStoolExternallyOccupied(stool, cell)
    for _, npc in ipairs(cell:getAll(types.NPC)) do
        if npc.enabled and not isNpcManagedByUs(npc) then
            local dp = npc.position - stool.position
            local horiz = math.sqrt(dp.x * dp.x + dp.y * dp.y)
            local vert = math.abs(dp.z)
            if horiz < EXTERNAL_SITTER_H_RADIUS and vert < EXTERNAL_SITTER_V_RADIUS then
                if ScheduleConfig.DEBUG_MODE then
                    print(string.format("[SittingGlobal] Stool %s externally occupied by %s (dist h=%.1f v=%.1f)",
                        stool.recordId, npc.recordId, horiz, vert))
                end
                return true
            end
        end
    end
    return false
end

--- Attempt to take control of an NPC that is on or inside a stool.
-- If successful the stool is NOT marked externally occupied and the NPC
-- is added to our management system.
-- NOTE: We intentionally skip the animation check here.
-- NPCs from other mods may use custom idle animations that don't read as
-- standard sit animations, but the explicit sitting blacklist still wins.
local function tryTakeoverExternalSitter(npc, stool, cell)
    -- Already managed? Nothing to do.
    if assignedNpcs[npc.id] or pendingOffers[npc.id] then
        return true
    end

    if Blacklist.isSitBlacklisted(npc) then
        NPCState.clear(npc.id)
        return false
    end

    -- Register / claim the stool.
    if not ensureSeatRegistered(stool) then return false end
    local reservedSlot = FurnitureRegistry.claimSlot(stool, npc.id)
    if not reservedSlot then return false end

    -- The NPC is already physically seated.  Preserve their current transform
    -- until the local script returns a fresh stool-surface placement; recovered
    -- sitters use a final seated position with zero extra global offsets.
    local npcPos = util.vector3(npc.position.x, npc.position.y, npc.position.z)
    local yaw = 0
    pcall(function() yaw = npc.rotation:getYaw() end)
    local facingDir = util.vector3(math.sin(yaw), math.cos(yaw), 0)
    local rid = ""
    pcall(function() rid = stool.recordId or "" end)

    -- Populate assignedNpcs so the NPC is treated as fully managed.
    assignedNpcs[npc.id] = {
        npc = npc,
        stool = stool,
        stoolRecordId = rid,
        zOffset = 0,
        fwdOffset = 0,
        animationOffset = nil,
        position = npcPos,
        exitPos = npcPos,
        facingDirection = facingDir,
        currentFacing = facingDir,
        targetFacing = facingDir,
        lerpTime = lerpDuration,      -- skip lerp entirely
        rotationLerpTime = 1.0,
        sentSitDownPlease = true,
        settleFrames = 999,
        walkTimer = 0,
        npcStandingPos = npcPos,
        npcStandingRot = npc.rotation,
        slotIndex = reservedSlot.index,
        seatedLocked = true,
        visualAngle = math.atan2(facingDir.x, facingDir.y),
    }

    pendingStandTeleports[npc.id] = nil  -- Clear any pending stand-up teleports for this NPC
    FurnitureRegistry.fillSlot(stool, npc.id, npcPos, facingDir)
    NPCState.set(npc.id, "sitting")

    -- Tell the local script to start (or re-apply) the sit animation.
    npc:sendEvent('PC_SitDownPlease')
    npc:sendEvent('PC_RecheckStoolFacing', {
        stool = stool,
        barTarget = findNearestBarCounter(stool, cell),
        tableTarget = findNearestTable(stool, cell),
        slotIndex = reservedSlot.index,
    })

    print(string.format("[SittingGlobal] TAKEOVER external sitter %s on stool %s",
        npc.recordId, stool.recordId))
    return true
end

-- =============================================================================
-- Global Blacklist Logic (Ported from SittingLogic to prevent round-trip rejections)
-- =============================================================================


function SittingGlobal.assignNpcsToStools(cell)
    if not ScheduleConfig.SITTING_GLOBAL_ENABLED then return end
    if cell and cell.isExterior then return end

    -- Collect stools first so the stale-state cleanup can use them.
    local stools = {}
    for _, obj in ipairs(cell:getAll()) do
        if isSeatObject(obj) then
            ensureSeatRegistered(obj)
            if not FurnitureRegistry.isOccupied(obj)
                    and not pendingStools[getObjId(obj)]
                    and not isTemporarilyRejected(obj) then
                local ok, upVec = pcall(function()
                    return obj.rotation * util.vector3(0, 0, 1)
                end)
                if not ok or not upVec or upVec.z >= 0.7 then
                    table.insert(stools, obj)
                end
            end
        end
    end

    -- Stale-state cleanup: only clear NPCs who are marked sitting but are NOT
    -- near any stool. If they're near a stool they may be legitimately sitting.
    local allNpcs = cell:getAll(types.NPC)
    for _, npc in ipairs(allNpcs) do
        if NPCState.get(npc.id) == "sitting" then
            if not assignedNpcs[npc.id] and not pendingOffers[npc.id] then
                local nearStool = false
                for _, stool in ipairs(stools) do
                    local dp = npc.position - stool.position
                    local horiz = math.sqrt(dp.x * dp.x + dp.y * dp.y)
                    local vert = math.abs(dp.z)
                    if horiz < EXTERNAL_SITTER_H_RADIUS and vert < EXTERNAL_SITTER_V_RADIUS then
                        nearStool = true
                        break
                    end
                end
                if not nearStool then
                    print(string.format("[SittingGlobal] Clearing stale sitting state for %s (not near any stool)", npc.recordId))
                    NPCState.clear(npc.id)
                end
            end
        end
    end
    -- 1. Find Valid Stools (fresh table; do not append to the pre-cleanup list)
    stools = {}
    for _, obj in ipairs(cell:getAll()) do
        if isSeatObject(obj) then
            print(string.format("[SittingGlobal] FOUND stool %s", tostring(obj.recordId)))
            -- Ensure registered in FurnitureRegistry
            ensureSeatRegistered(obj)
            -- Skip if Occupied or Pending
            if not FurnitureRegistry.isOccupied(obj)
                    and not pendingStools[getObjId(obj)]
                    and not isTemporarilyRejected(obj) then
                -- Skip fallen/tipped stools: check that the stool's local up vector is
                -- still mostly pointing upward (z > 0.7 ≈ less than ~45° tilt)
                local ok, upVec = pcall(function()
                    return obj.rotation * util.vector3(0, 0, 1)
                end)
                if ok and upVec and upVec.z < 0.7 then
                    -- Stool is tipped over, skip it
                else
                    table.insert(stools, obj)
                end
            end
        end
    end

    -- 1b. Filter out stools occupied by external NPCs, but attempt takeover
    --     for NPCs that are already sitting.
    local filteredStools = {}
    for _, stool in ipairs(stools) do
        local sid = getObjId(stool)
        if externallyOccupiedStools[sid] then
            -- already known external occupant that we couldn't take over
        else
            local occupied = false
            local claimed = false
            for _, npc in ipairs(cell:getAll(types.NPC)) do
                if npc.enabled then
                    local needsReloadRecovery = NPCState.isSitting(npc.id)
                        and not assignedNpcs[npc.id]
                        and not pendingOffers[npc.id]
                    local shouldCheck = needsReloadRecovery or not isNpcManagedByUs(npc)
                    if shouldCheck then
                        local dp = npc.position - stool.position
                        local horiz = math.sqrt(dp.x * dp.x + dp.y * dp.y)
                        local vert = math.abs(dp.z)
                        local hRadius = needsReloadRecovery and RELOAD_SITTER_H_RADIUS or EXTERNAL_SITTER_H_RADIUS
                        local vRadius = needsReloadRecovery and RELOAD_SITTER_V_RADIUS or EXTERNAL_SITTER_V_RADIUS
                        if horiz < hRadius and vert < vRadius then
                            if not tryTakeoverExternalSitter(npc, stool, cell) then
                                occupied = true
                                if ScheduleConfig.DEBUG_MODE then
                                    print(string.format("[SittingGlobal] Stool %s externally occupied by %s (dist h=%.1f v=%.1f)",
                                        stool.recordId, npc.recordId, horiz, vert))
                                end
                            else
                                claimed = true
                            end
                        end
                    end
                end
            end
            if occupied then
                externallyOccupiedStools[sid] = true
            elseif not claimed then
                table.insert(filteredStools, stool)
            end
        end
    end
    stools = filteredStools

    -- 2. Find Candidates and Bar Counters
    local candidates = {}
    local barCounters = {} 
    
    -- Scan strictly for Bar Counters (Misc/Furniture that looks like a bar)
    -- This assumes checking all objects again or filtering earlier scan?
    -- cell:getAll() is cheap enough.
    local tables = {}
    for _, obj in ipairs(cell:getAll()) do
        local id = obj.recordId:lower()
        if id:find("bar") and not id:find("barstool") then
             -- Exclude known non-counter items if needed
             -- Heuristic: "something with bar but not barstool"
             table.insert(barCounters, obj)
        end
        if FurnitureProfiles.isTableObject(obj) then
             table.insert(tables, obj)
        end
    end

    for _, npc in ipairs(cell:getAll(types.NPC)) do
        -- Check Assignment, Pending, Blacklist, and enabled state
        if not npc.enabled then
            print(string.format("[SittingGlobal] SKIP %s (not enabled)", tostring(npc.recordId)))
        elseif assignedNpcs[npc.id] then
            print(string.format("[SittingGlobal] SKIP %s (already assigned)", tostring(npc.recordId)))
        elseif pendingOffers[npc.id] then
            print(string.format("[SittingGlobal] SKIP %s (pending offer)", tostring(npc.recordId)))
        else
            local state = NPCState.get(npc.id)
            local blacklisted = Blacklist.isSitBlacklisted(npc)
            if blacklisted then
                print(string.format("[SittingGlobal] BLACKLISTED %s class=%s", tostring(npc.recordId), tostring(types.NPC.record(npc).class)))
            elseif isConversationActive(npc) then
                print(string.format("[SittingGlobal] SKIP %s (conversation active)", tostring(npc.recordId)))
            elseif not NPCState.canSit(npc.id) then
                print(string.format("[SittingGlobal] SKIP %s (state=%s)", tostring(npc.recordId), tostring(state)))
            else
                print(string.format("[SittingGlobal] CANDIDATE %s (state=%s)", tostring(npc.recordId), tostring(state)))
                table.insert(candidates, npc)
            end
        end
    end
    
    -- local targetPublican = nil -- Removed global single publican
    -- if #publicans > 0 then targetPublican = publicans[1] end

    if #stools > 0 and #candidates > 0 then
        print(string.format("[SittingGlobal] Assigning: Found %d Empty Stools, %d Free Candidates", #stools, #candidates))
    end
    
    if #stools == 0 or #candidates == 0 then return end

    -- Sort stools by priority: barstools > stools > benches > chairs
    table.sort(stools, function(a, b)
        local function priority(obj)
            local id = obj.recordId:lower()
            if id:find("barstool") then return 1 end
            if id:find("stool") and not id:find("barstool") then return 2 end
            if id:find("bench") then return 3 end
            return 4 -- chairs and everything else last
        end
        return priority(a) < priority(b)
    end)

    local function barAndTableForStool(stool)
        local targetBar, targetTable = nil, nil
        local stoolId = ""
        pcall(function() stoolId = string.lower(stool.recordId or "") end)
        if #barCounters > 0 and stoolId:find("barstool") then
            local minDist = math.huge
            for _, bar in ipairs(barCounters) do
                local d = (bar.position - stool.position):length()
                if d < minDist and d < 500 then
                    minDist = d
                    targetBar = bar
                end
            end
        end
        if #tables > 0 then
            local minDist = math.huge
            for _, tbl in ipairs(tables) do
                local d = (tbl.position - stool.position):length()
                if d < minDist and d < 300 then
                    minDist = d
                    targetTable = tbl
                end
            end
        end
        return targetBar, targetTable
    end

    local shortlistSize = ScheduleConfig.SIT_SHORTLIST_SIZE or 6
    local maxScanDist = ScheduleConfig.SIT_SCAN_DISTANCE or 4096
    local zSquareScale = ScheduleConfig.SIT_Z_SQUARE_SCALE or 0.15

    -- Per-NPC shortlist by biased distance; local script ranks by navmesh and picks best.
    for _, npc in ipairs(candidates) do
        local distEntries = {}
        local nearestHoriz = math.huge
        local nearestZ = 0
        local nearestScore = math.huge
        for _, stool in ipairs(stools) do
            if not FurnitureRegistry.isOccupied(stool) then
                local dp = npc.position - stool.position
                local horiz = math.sqrt(dp.x * dp.x + dp.y * dp.y)
                local zDiff = math.abs(dp.z)
                local dist = horiz + (zDiff * zDiff * zSquareScale)
                if dist < nearestScore then
                    nearestScore = dist
                    nearestHoriz = horiz
                    nearestZ = zDiff
                end
                if dist < maxScanDist then
                    table.insert(distEntries, { stool = stool, dist = dist })
                end
            end
        end
        table.sort(distEntries, function(a, b) return a.dist < b.dist end)

        local shortlist = {}
        for i = 1, math.min(shortlistSize, #distEntries) do
            local stool = distEntries[i].stool
            local slotIndex = FurnitureRegistry.peekFreeSlotIndex(stool)
            if slotIndex then
                local targetBar, targetTable = barAndTableForStool(stool)
                table.insert(shortlist, {
                    stool = stool,
                    slotIndex = slotIndex,
                    barTarget = targetBar,
                    tableTarget = targetTable,
                })
            end
        end

        if #shortlist > 0 then
            pendingOffers[npc.id] = { shortlist = true }
            print(string.format("[SittingGlobal] Offering %d stool candidates to %s (navmesh rank)",
                #shortlist, npc.recordId))
            pendingStandTeleports[npc.id] = nil  -- Clear any pending stand-up teleports for this NPC
            npc:sendEvent("PC_ConsiderStools", { stools = shortlist })
        else
            print(string.format("[SittingGlobal] No reachable stool shortlist for %s (nearby=%d scanDist=%d nearestScore=%.1f horiz=%.1f z=%.1f zScale=%.2f)",
                tostring(npc.recordId), #distEntries, maxScanDist, nearestScore, nearestHoriz, nearestZ, zSquareScale))
        end
    end
end

function SittingGlobal.onCellChange()
    if not world then world = require('openmw.world') end
    local player = world.players[1]
    if not player then return end
    local cell = player.cell
    
    assignedNpcs = {}
    pendingOffers = {}
    pendingStools = {}
    rejectedStools = {}
    pendingStandTeleports = {}
    externallyOccupiedStools = {}
    FurnitureRegistry.reset()
    NPCState.reset()
    -- Clear stale transit states for NPCs in this cell.
    for _, npc in ipairs(cell:getAll(types.NPC)) do
        if NPCState.get(npc.id) == "traveling_to_seat" then
            NPCState.clear(npc.id)
        end
    end
    SittingGlobal.assignNpcsToStools(cell)
end

function SittingGlobal.isSitting(actor)
    if not actor or not actor.id then return false end
    return assignedNpcs[actor.id] ~= nil or pendingOffers[actor.id] ~= nil
        or NPCState.isSitting(actor.id)
end

function SittingGlobal.isSeatingInProgress(actorOrId)
    local npcId = actorOrId
    if actorOrId and type(actorOrId) ~= "string" and type(actorOrId) ~= "number" then
        pcall(function() npcId = actorOrId.id end)
    end
    if not npcId then return false end
    if pendingOffers[npcId] then return true end

    local data = assignedNpcs[npcId]
    if not data then return false end
    return not data.seatedLocked and not NPCState.isSitting(npcId)
end

-- Event from NPC Local
function SittingGlobal.onStoolCheckResult(ev)
    local npc = ev.npc
    print(string.format("[SittingGlobal] onStoolCheckResult npc=%s usable=%s stool=%s reason=%s",
        tostring(npc and npc.recordId),
        tostring(ev.usable),
        tostring(ev.stool and ev.stool.recordId),
        tostring(ev.reason)))
    if not npc then print("[SittingGlobal] onStoolCheckResult ABORT no npc"); return end

    -- Reject stale results for hostile NPCs
    if NPCState.isHostile(npc.id) then
        print(string.format("[SittingGlobal] onStoolCheckResult IGNORE hostile npc=%s", tostring(npc.recordId)))
        if ev.stool then
            pcall(function() FurnitureRegistry.releaseSlot(ev.stool, npc.id) end)
            pendingStools[getObjId(ev.stool)] = nil
        end
        pendingOffers[npc.id] = nil
        return
    end

    local localUsable = ev.usable
    local pending = pendingOffers[npc.id]
    
    -- Clear Pending
    pendingOffers[npc.id] = nil
    
    local stool = ev.stool 

    if not pending then
        print(string.format("[SittingGlobal] IGNORE stale stool result for %s", tostring(npc.recordId)))
        if stool then
            pendingStools[getObjId(stool)] = nil
            pcall(function() FurnitureRegistry.releaseSlot(stool, npc.id) end)
        end
        return
    end

    if ev.usable and stool and isConversationActive(npc) then
        print(string.format("[SittingGlobal] REJECTED stool for %s (conversation active)", tostring(npc.recordId)))
        ev.usable = false
    end

    if ev.usable and stool then
        if not FurnitureRegistry.isRegistered(stool) then ensureSeatRegistered(stool) end
        local reservedSlot = nil
        pcall(function() reservedSlot = FurnitureRegistry.claimSlot(stool, npc.id) end)
        if not reservedSlot then
            print(string.format("[SittingGlobal] SOFT REJECT %s — claim race on stool %s",
                tostring(npc.recordId), tostring(stool.recordId)))
            clearSeatOfferState(npc.id)
            return
        end

        print(string.format("[SittingGlobal] ASSIGNING stool %s to %s", tostring(stool.recordId), tostring(npc.recordId)))

        local exitPos = ev.exitPos
        local rid2 = ""
        pcall(function() rid2 = stool.recordId or "" end)
        local zOff2, fwdOff2 = getSittingOffsets(stool)
        if ev.zOffset ~= nil then zOff2 = ev.zOffset end
        if ev.fwdOffset ~= nil then fwdOff2 = ev.fwdOffset end
        assignedNpcs[npc.id] = {
            npc = npc,
            stool = stool,
            stoolRecordId = rid2,
            zOffset = zOff2,
            fwdOffset = fwdOff2,
            animationId = ev.animationId,
            animationOffset = ev.animationOffset,
            position = ev.hitPos,
            exitPos = exitPos,
            facingDirection = ev.facingDirection,
            currentFacing = ev.facingDirection,
            targetFacing = ev.facingDirection,
            lerpTime = 0,
            rotationLerpTime = 1.0,
            sentSitDownPlease = false,
            settleFrames = 0,
            walkTimer = 0,
            slotIndex = reservedSlot.index,
        }
        pendingStandTeleports[npc.id] = nil  -- Clear any pending stand-up teleports for this NPC
        FurnitureRegistry.fillSlot(stool, npc.id, ev.hitPos, ev.facingDirection)
        pendingStools[getObjId(stool)] = nil

        -- Walk to exitPos (floor beside stool), not the stool surface itself.
        -- Lerp onto the stool begins on arrival there.
        local walkTarget = exitPos or ev.hitPos
        print(string.format("[SittingGlobal] SENDING StartAIPackage Travel to %s for %s walkTarget=%s", tostring(npc.recordId), tostring(stool.recordId), tostring(walkTarget)))
        npc:sendEvent("PC_SaveBehavior", {})
        npc:sendEvent("PC_StopWander", {})
        npc:sendEvent('StartAIPackage', {
            type = "Travel",
            destPosition = walkTarget,
            isRepeat = false
        })
    else
        print(string.format("[SittingGlobal] REJECTED stool for %s reason=%s shortlist=%s ranked=%s",
            tostring(npc.recordId),
            tostring(ev.reason),
            tostring(ev.shortlistCount),
            tostring(ev.rankedCount)))
        clearSeatOfferState(npc.id)
        if stool then
            pcall(function() FurnitureRegistry.releaseSlot(stool, npc.id) end)
            pendingStools[getObjId(stool)] = nil
            if localUsable == false and ev.geometryReject == true then
                rejectedStools[getObjId(stool)] = sittingTime + REJECTED_STOOL_COOLDOWN
            end
        end
        -- print(string.format("[SittingGlobal] NPC %s rejected stool.", npc.recordId))
        
        -- Retry logic? The periodic timer will handle it next tick.
    end
end

function SittingGlobal.onStoolFacingResult(ev)
    local npc = ev and ev.npc
    local facing = ev and ev.facingDirection
    if not npc or not npc.id or not facing then return end

    local data = assignedNpcs[npc.id]
    if not data then return end

    if ev.seatAnchor then
        data.position = ev.seatAnchor
        if data.stool then
            pcall(function() FurnitureRegistry.fillSlot(data.stool, npc.id, ev.seatAnchor, facing) end)
        end
    end
    if ev.zOffset ~= nil then
        data.zOffset = ev.zOffset
    end
    if ev.fwdOffset ~= nil then
        data.fwdOffset = ev.fwdOffset
    end
    if ev.animationId ~= nil then
        data.animationId = ev.animationId
        data.animationOffset = ev.animationOffset
    end
    if ev.exitPos then
        data.exitPos = ev.exitPos
        pcall(function() FurnitureRegistry.recordExitPos(data.stool, npc.id, ev.exitPos, data.npcStandingRot or npc.rotation) end)
    end

    local f = util.vector3(facing.x, facing.y, 0)
    local len = math.sqrt(f.x * f.x + f.y * f.y)
    if len <= 0.001 then return end

    f = util.vector3(f.x / len, f.y / len, 0)
    data.facingDirection = f
    data.currentFacing = f
    data.targetFacing = f
    local _, visualAngle = applySeatedPoseOffsets(
        data.position,
        math.atan2(f.x, f.y),
        data.zOffset or DEFAULT_SITTING_Z_OFFSET,
        data.fwdOffset or DEFAULT_SITTING_FORWARD_OFFSET,
        data.animationOffset
    )
    data.visualAngle = visualAngle
    conversationOverrides[npc.id] = nil

    print(string.format("[SittingGlobal] Reload-facing restored for %s", tostring(npc.recordId)))
end

-- NEW: Handle Explicit Arrival (Called by Local script when Travel package finishes)
function SittingGlobal.onArrived(ev)
    local npc = ev.actor or ev.npc
    if not npc then return end
    
    local data = assignedNpcs[npc.id]
    if data then
         -- NPC has arrived at their destination (Stool HitPos)
         -- Force snap to ensure distance check passes and logic proceeds
         -- Only force if we haven't started sitting yet
         if data.lerpTime == 0 and not data.npcStandingPos then
             local dist = (npc.position - data.position):length()
             
             if dist > 5 then
                 print(string.format("[SittingGlobal] NPC %s Arrived event (Dist: %.2f). Snapping to start point.", npc.recordId, dist))
                 Utils.tryTeleport(npc, npc.cell, data.position, { rotation = data.facingDirection })
             else
                 -- Already close enough, next update will catch it
             end
         end
    end
end

-- Release an NPC from stool assignment without stand-up teleport.
-- Used by SleepManager when overriding sitting with sleep.
function SittingGlobal.forceRelease(npcId)
    pendingStandTeleports[npcId] = nil  -- Clear any pending stand-up teleports for this NPC
    local data = assignedNpcs[npcId]
    if data then
        FurnitureRegistry.releaseByNpc(npcId)
        assignedNpcs[npcId] = nil
    end
    local pending = pendingOffers[npcId]
    if pending and pending.stool then
        pcall(function() FurnitureRegistry.releaseSlot(pending.stool, npcId) end)
        pendingStools[getObjId(pending.stool)] = nil
    end
    pendingOffers[npcId] = nil
end

function SittingGlobal.forceStandForDeparture(npcId)
    local data = assignedNpcs[npcId]
    if data then
        FurnitureRegistry.releaseByNpc(npcId)
        assignedNpcs[npcId] = nil
        conversationOverrides[npcId] = nil

        local npc = data.npc
        if Utils.isObjValid(npc) and data.exitPos then
            local standUpZ = 10
            pendingStandTeleports[npcId] = {
                npc = npc,
                position = data.exitPos + util.vector3(0, 0, standUpZ),
                rotation = data.npcStandingRot or npc.rotation
            }
        end
    end

    local pending = pendingOffers[npcId]
    if pending and pending.stool then
        pcall(function() FurnitureRegistry.releaseSlot(pending.stool, npcId) end)
        pendingStools[getObjId(pending.stool)] = nil
    end
    pendingOffers[npcId] = nil
end

function SittingGlobal.onCancelSittingForNpc(ev)
    local npc = ev and ev.npc
    if not npc or not npc.id then return end
    
    local data = assignedNpcs[npc.id]
    if data then
         FurnitureRegistry.releaseByNpc(npc.id)
         NPCState.clear(npc.id)
         assignedNpcs[npc.id] = nil
         
         -- Stand Up Teleport logic...
        if data.exitPos then
            local standUpZ = 10
            local standPos = data.exitPos + util.vector3(0, 0, standUpZ)
            pendingStandTeleports[npc.id] = {
                npc = npc,
                position = standPos,
                rotation = data.npcStandingRot or npc.rotation
            }
        end
    end
    
    npc:sendEvent('PC_StandUpPlease')
    npc:sendEvent('PC_StandUpPlease')
end

-- NEW: Separated Conversation Rotation
function SittingGlobal.onConversationRotate(ev)
    if not ev.npc or not ev.position then return end
    
    local data = assignedNpcs[ev.npc.id]
    if data then
        -- RULE 1: Stools Only (chairs keep their fixed facing)
        if data.stool then
            local stoolId = string.lower(data.stool.recordId)
            -- Only stools rotate toward conversation partner; chairs keep fixed facing
            local isStool = string.find(stoolId, "stool")
            if not isStool then
                 print(string.format("[SittingGlobal] Rotation skipped for %s: Furniture '%s' is not a stool.", ev.npc.recordId, stoolId))
                 return
            end
        end

        -- RULE 2: Nearby Sitting Exclusion (Sit-to-Sit Logic)
        if ev.target then
             local targetData = assignedNpcs[ev.target.id]
             if targetData then
                 -- Target is also sitting. Check distance.
                 local dist = (ev.npc.position - ev.target.position):length()
                 if dist < 150 then -- Approx 2m
                      print(string.format("[SittingGlobal] Rotation skipped for %s: Target %s is sitting nearby (Dist: %.1f < 150)", ev.npc.recordId, ev.target.recordId, dist))
                      return
                 end
             end
             -- If Target is NOT in assignedNpcs, they are Standing (or unrelated).
             -- Rule 3: Standing Target -> Always Rotate (passed by default here).
        end

        -- Calculate target angle (Yaw)
        local delta = ev.position - data.position
        conversationOverrides[ev.npc.id] = math.atan2(delta.x, delta.y)
        print(string.format("[SittingGlobal] Set Override Angle for %s: %.2f", ev.npc.recordId, conversationOverrides[ev.npc.id]))
    end
end

function SittingGlobal.onConversationReset(ev)
    if not ev.npc then return end
    if conversationOverrides[ev.npc.id] then
        conversationOverrides[ev.npc.id] = nil
        print(string.format("[SittingGlobal] Cleared Override Angle for %s", ev.npc.recordId))
    end
end

function SittingGlobal.onRequestSeatRotate(ev)
    local npc = ev.npc
    if not npc or not npc.id then return end
    
    local data = assignedNpcs[npc.id]
    if not data then return end
    
    local newTarget = nil
    
    if ev.reset then
        -- Restore original facing
        newTarget = data.facingDirection
    elseif ev.targetPosition then
        -- Calculate direction to target
        local dir = (ev.targetPosition - data.position):normalize()
        newTarget = util.vector3(dir.x, dir.y, 0)
    end
    
    if newTarget then
        -- Check if change is significant
        local dot = data.targetFacing:dot(newTarget)
        if dot < 0.99 then
             -- Start new Lerp
             data.startFacing = data.currentFacing
             data.targetFacing = newTarget
             data.rotationLerpTime = 0
             -- print(string.format("[SittingGlobal] Rotating %s to new target.", npc.recordId))
        end
    end
end

-- Update Loop
function SittingGlobal.onUpdate(dt, waitMenuPaused, dialogueMenuPaused)
    if not ScheduleConfig.SITTING_GLOBAL_ENABLED then return end
    sittingTime = sittingTime + dt
    if not world then world = require('openmw.world') end
    local player = world.players[1]
    if not player then return end
    
    -- Cell Change Detection (compare by name/grid; userdata identity is unstable)
    local cellId = ""
    pcall(function()
        if player.cell then
            if player.cell.isExterior then
                cellId = string.format("ext_%d_%d", player.cell.gridX or 0, player.cell.gridY or 0)
            else
                cellId = player.cell.name or ""
            end
        end
    end)
    if cellId ~= lastCell then
        lastCell = cellId
        SittingGlobal.onCellChange()
    end
    
    -- Manage Assignments
    for npcId, data in pairs(assignedNpcs) do
        local npc = data.npc
        if not Utils.isObjValid(npc) then
            -- 1.2: complete cleanup on invalidation — release furniture slot
            -- and clear state so the NPC isn't permanently stuck in tables.
            FurnitureRegistry.releaseByNpc(npcId)
            NPCState.clear(npcId)
            assignedNpcs[npcId] = nil
        elseif NPCState.isSleeping(npcId) or NPCState.isPendingSleep(npcId) then
            -- SleepManager claimed this NPC; release stool so we stop
            -- teleporting them back to the seat every frame.
            FurnitureRegistry.releaseByNpc(npcId)
            assignedNpcs[npcId] = nil
        elseif (NPCState.get(npcId) == "conversation" or NPCState.get(npcId) == "activity")
                and not data.seatedLocked and not NPCState.isSitting(npcId) then
            -- An activity or conversation started before the NPC reached the seat
            -- (either via the async-gap race or a forced assignment). Release the
            -- stool so we stop teleporting them toward it every frame.
            print(string.format("[SittingGlobal] Releasing unfinished seat assignment for %s (%s started mid-walk)",
                npc.recordId, NPCState.get(npcId)))
            FurnitureRegistry.releaseByNpc(npcId)
            NPCState.setSitCooldown(npcId, 30)
            assignedNpcs[npcId] = nil
            pcall(function() npc:sendEvent("PC_CancelTravelToSeat", {}) end)
        else
            -- Phase 1: detect arrival at exitPos (floor beside stool), then begin lerp.
            if not data.npcStandingPos then
                local arriveTarget = data.exitPos or data.position
                local dist = (npc.position - arriveTarget):length()
                -- Also check distance to stool itself; exitPos can be 60+ units away
                -- and geometry may block the last few units.
                local dpStool = npc.position - data.position
                local distToStool = math.sqrt(dpStool.x * dpStool.x + dpStool.y * dpStool.y)
                
                data.walkTimer = (data.walkTimer or 0) + dt
                
                local zDiff = math.abs(npc.position.z - arriveTarget.z)
                local arriveDist = ScheduleConfig.SIT_ARRIVE_DIST or 40
                local stoolArriveDist = ScheduleConfig.SIT_STOOL_ARRIVE_DIST or 60
                local stuckMultiplier = ScheduleConfig.SIT_APPROACH_STUCK_MULTIPLIER or 2
                local stuckSeconds = ScheduleConfig.SIT_APPROACH_STUCK_SECONDS or 2.5
                local progressEpsilon = ScheduleConfig.SIT_APPROACH_PROGRESS_EPSILON or 5
                local approachTimeout = ScheduleConfig.SIT_APPROACH_TIMEOUT or 25.0

                local bestDist = data.bestApproachDist
                if not bestDist or (bestDist - dist) >= progressEpsilon then
                    data.bestApproachDist = dist
                    data.approachStuckTimer = 0
                elseif ((dist < arriveDist * stuckMultiplier)
                        or (distToStool < stoolArriveDist * stuckMultiplier))
                        and zDiff < 50 then
                    data.approachStuckTimer = (data.approachStuckTimer or 0) + dt
                else
                    data.approachStuckTimer = 0
                end

                local timerInt = math.floor(data.walkTimer)
                local prevTimerInt = math.floor(data.walkTimer - dt)
                if timerInt ~= prevTimerInt and timerInt > 0 and timerInt % 5 == 0 then
                    print(string.format("[SittingGlobal] NPC %s walking to stool: dist=%.1f distToStool=%.1f zDiff=%.1f timer=%.1f arrive=%s",
                        npc.recordId, dist, distToStool, zDiff, data.walkTimer, tostring(arriveTarget)))
                end
                local normalArrival = ((dist < arriveDist or distToStool < stoolArriveDist) and zDiff < 50)
                local expandedStuckArrival = (data.approachStuckTimer or 0) >= stuckSeconds
                local hardTimedOut = data.walkTimer > approachTimeout
                if normalArrival or expandedStuckArrival or hardTimedOut then
                    if hardTimedOut then
                        print(string.format("[SittingGlobal] NPC %s timed out walking to stool (Dist: %.2f). Snapping to stool exit pos.", npc.recordId, dist))
                        local arriveTarget = data.exitPos or data.position
                        Utils.tryTeleport(npc, npc.cell, arriveTarget, { rotation = data.facingDirection })
                    elseif expandedStuckArrival then
                        print(string.format("[SittingGlobal] NPC %s stalled near stool (Dist: %.2f, Stool: %.2f). Starting expanded Sit Lerp.", npc.recordId, dist, distToStool))
                    else
                        print(string.format("[SittingGlobal] NPC %s arrived at stool exit pos. Starting Sit Lerp.", npc.recordId))
                    end
                    -- Capture the NPC's ACTUAL arrival position on the floor so that
                    -- stand-up always returns to the exact safe spot they just walked to.
                    -- Global "sitting" state is now mirrored from SittingLogic via PC_StateChanged.
                    data.npcStandingPos = util.vector3(npc.position.x, npc.position.y, npc.position.z)
                    data.npcStandingRot = npc.rotation
                    data.exitPos = data.npcStandingPos
                    pcall(function()
                        FurnitureRegistry.recordExitPos(data.stool, npc.id, data.exitPos, data.npcStandingRot)
                    end)
                    npc:sendEvent('PC_CancelTravelToSeat', { keepHelloSuppressed = true })
                end
            end

            -- Phase 2+: run once lerp has started (regardless of current distance)
            if data.npcStandingPos then
                data.lerpTime = data.lerpTime + dt
                local t = math.min(data.lerpTime / lerpDuration, 1.0)

                local baseAngle     = math.atan2(data.facingDirection.x, data.facingDirection.y)
                local sittingPos, sittingAngle = applySeatedPoseOffsets(
                    data.position,
                    baseAngle,
                    data.zOffset or DEFAULT_SITTING_Z_OFFSET,
                    data.fwdOffset or DEFAULT_SITTING_FORWARD_OFFSET,
                    data.animationOffset
                )

                if t < 1.0 then
                    -- LERP PHASE
                    if t >= 0.5 and not data.sentSitDownPlease then
                        data.sentSitDownPlease = true
                        npc:sendEvent('PC_SitDownPlease')
                    end
                    local newPos   = Utils.lerp(data.npcStandingPos, sittingPos, t)
                    local newAngle = Utils.lerpAngle(data.npcStandingRot:getYaw(), sittingAngle, t)
                    local ok, err  = Utils.tryTeleport(npc, npc.cell, newPos, { rotation = util.transform.rotateZ(newAngle) })
                    if not ok then
                        print(string.format("[SittingGlobal] Teleport failed for %s: %s", npc.recordId, tostring(err)))
                        assignedNpcs[npcId] = nil
                    end
                else
                    -- FULLY SEATED PHASE
                    if not data.seatedLocked then
                        data.seatedLocked = true
                        data.visualAngle  = sittingAngle
                        print(string.format("[SittingGlobal] NPC %s fully seated.", npc.recordId))
                    end

                    -- Smooth rotation toward conversation override (or base)
                    local _, targetAngle = applySeatedPoseOffsets(
                        data.position,
                        conversationOverrides[npc.id] or baseAngle,
                        data.zOffset or DEFAULT_SITTING_Z_OFFSET,
                        data.fwdOffset or DEFAULT_SITTING_FORWARD_OFFSET,
                        data.animationOffset
                    )
                    local diff = targetAngle - data.visualAngle
                    while diff >  math.pi do diff = diff - 2 * math.pi end
                    while diff < -math.pi do diff = diff + 2 * math.pi end
                    if math.abs(diff) > 0.01 then
                        data.visualAngle = data.visualAngle + diff * math.min(1.0, dt * 2.0)
                    end

                    -- Recompute seated position from current angle so the forward
                    -- offset rotates with the NPC (prevents sliding off the stool).
                    local poseYaw = data.animationOffset and ((data.animationOffset.yawOffset or 0) * math.pi / 180) or 0
                    local currentBaseAngle = data.visualAngle - poseYaw
                    local currentSeatPos = applySeatedPoseOffsets(
                        data.position,
                        currentBaseAngle,
                        data.zOffset or DEFAULT_SITTING_Z_OFFSET,
                        data.fwdOffset or DEFAULT_SITTING_FORWARD_OFFSET,
                        data.animationOffset
                    )
                    Utils.tryTeleport(npc, npc.cell, currentSeatPos, { rotation = util.transform.rotateZ(data.visualAngle) })
                end
            end
        end
    end
    
    -- Pending Stand Teleports
    for npcId, tdata in pairs(pendingStandTeleports) do
        -- ... (existing teleport logic) ...
        local npc = tdata.npc
        if not Utils.isObjValid(npc) then
            pendingStandTeleports[npcId] = nil
        else
            local ok, err = Utils.tryTeleport(npc, npc.cell, tdata.position, { rotation = tdata.rotation or npc.rotation })
            if ok then
                pendingStandTeleports[npcId] = nil
                -- Notify local script that stand-up is PHYSICALLY complete.
                npc:sendEvent("PC_StandUpFinished", {})
            else
                -- Retry if busy
            end
        end
    end

    -- Periodic Re-Assignment (Every 5s) — paused while wait/rest menu or dialogue is open
    if not waitMenuPaused and not dialogueMenuPaused then
        if not scanTimer then scanTimer = 0 end
        scanTimer = scanTimer + dt
        if scanTimer > 5.0 then
            scanTimer = 0
            SittingGlobal.assignNpcsToStools(player.cell)
        end
    end
end

function SittingGlobal.isAssigned(npcId)
    return assignedNpcs[npcId] ~= nil
end

-- Return Module for Global usage
return SittingGlobal
