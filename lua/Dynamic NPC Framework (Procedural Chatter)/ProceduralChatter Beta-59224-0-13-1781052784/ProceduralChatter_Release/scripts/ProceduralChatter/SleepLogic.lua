-- SleepLogic.lua
-- NPC-local sleep module.  Mirrors the SittingLogic pattern:
--   Global SleepManager does bed scanning + lerp positioning.
--   This module handles the local NPC side: blacklist validation,
--   exit-position finding, and sleep animation sequencing.
--
-- Sleep animation sequence (xanim_sleeping.kf, gender-neutral):
--   slee7  lay-down transition  (1 loop)
--   slee8  sleep idle           (999 loops — kept until wake)
--   slee9  get-up transition    (1 loop)
--
-- Exit position approach:
--   On PC_ConsiderBed, cast downward rays on both sides of the bed to find
--   a floor position beside it.  This position is returned as exitPos and
--   becomes both the walk target (NPC walks here first, then lerps into bed)
--   and the wake destination (global lerps NPC back here on wake).
--   No raycasting is needed at wake time.
--
-- Profile-aware: if SleepManager passes profileSlots, use approachPos as the
--   exit/walk target.  Animation normalization offsets are computed here and
--   sent back in PC_BedCheckResult so SleepManager can apply them to seatedPos.

local core   = require('openmw.core')
local util   = require('openmw.util')
local FurnitureRegistry = require("scripts.ProceduralChatter.FurnitureRegistry")
local nearby = require('openmw.nearby')
local self   = require('openmw.self')
local types  = require('openmw.types')
local anim   = require('openmw.animation')
local I      = require('openmw.interfaces')
local ai     = require('openmw.interfaces').AI

local Blacklist = require("scripts.ProceduralChatter.Blacklist")
local StateMachine = require("scripts.ProceduralChatter.StateMachine")
local FurnitureProfiles = require("scripts.ProceduralChatter.data.FurnitureProfiles")
local FurnitureRouteScorer = require("scripts.ProceduralChatter.FurnitureRouteScorer")

local SleepLogic = {}

-- =============================================================================
-- Native home (set from npc.lua on first frame)
-- =============================================================================
local nativeHome = nil
function SleepLogic.setNativeHome(home)
    if not nativeHome then nativeHome = home end
end

-- =============================================================================
-- Per-NPC state machine
-- =============================================================================
local sm

local function createSleepStateMachine()
    return StateMachine.create({
        idle = {
            enter = function(prev, data)
                if prev == "waking_up" then
                    core.sendGlobalEvent("PC_StateChanged", { npcId = self.id, state = "idle" })
                end
            end,
            update = function(dt) end,
            exit = function(next) end,
        },
        walking_to_bed = {
            enter = function(prev, data)
                core.sendGlobalEvent("PC_StateChanged", { npcId = self.id, state = "pending_sleep" })
            end,
            update = function(dt) end,
            exit = function(next) end,
        },
        laying_down = {
            enter = function(prev, data)
                core.sendGlobalEvent("PC_StateChanged", { npcId = self.id, state = "pending_sleep" })
            end,
            update = function(dt)
                local ok, playing = pcall(function() return anim.isPlaying(self, "slee7") end)
                if ok and not playing then
                    sm:transition("sleeping")
                end
            end,
            exit = function(next) end,
        },
        sleeping = {
            enter = function(prev, data)
                core.sendGlobalEvent("PC_StateChanged", { npcId = self.id, state = "sleeping" })
            end,
            update = function(dt)
                local ok, playing = pcall(function() return anim.isPlaying(self, "slee8") end)
                if ok and not playing then
                    pcall(function()
                        I.AnimationController.playBlendedAnimation("slee8", {
                            loops     = 999,
                            forceLoop = true,
                            priority  = anim.PRIORITY.Movement,
                            blendMask = 15,
                        })
                    end)
                end
            end,
            exit = function(next) end,
        },
        waking_up = {
            enter = function(prev, data)
                core.sendGlobalEvent("PC_StateChanged", { npcId = self.id, state = "waking" })
            end,
            update = function(dt) end,
            exit = function(next) end,
        },
    }, "idle")
end

sm = createSleepStateMachine()

local walkTarget = nil   -- exitPos stored for Travel cancellation

-- =============================================================================
-- Predicates
-- =============================================================================
function SleepLogic.isSleeping()
    return sm:is("sleeping")
end

function SleepLogic.getState()
    return sm:get()
end

-- =============================================================================
-- Exit position finder — runs ONCE at assignment time, not at wake time.
-- Casts downward rays on both perpendicular sides of the bed.
-- Returns a floor util.vector3, or nil if both sides miss.
-- =============================================================================
local EXIT_OFFSET = 70  -- units from bed centre to stand beside it

-- Cast a downward ray from above to find the actual floor height at a given XY.
local function projectToFloor(pos)
    if not pos then return nil end
    local from = pos + util.vector3(0, 0, 200)
    local to   = pos - util.vector3(0, 0, 50)
    local result = nearby.castRay(from, to, { collisionType = nearby.COLLISION_TYPE.World })
    if result.hit and result.hitPos then
        return result.hitPos
    end
    return nil
end

-- Determine the bed's actual surface height so we can tell floor from mattress.
local function findBedSurfaceZ(bed, profile)
    local bp = bed.position
    local minZ = profile and profile.surfaceMinZ or nil
    local maxZ = profile and profile.surfaceMaxZ or nil
    local top = bp.z + (maxZ or 260) + 20
    local bottom = bp.z + (minZ or -50) - 20
    local lastHitZ = nil

    for _ = 1, 6 do
        local from = util.vector3(bp.x, bp.y, top)
        local to = util.vector3(bp.x, bp.y, bottom)
        local result = nearby.castRay(from, to, { collisionType = nearby.COLLISION_TYPE.World })
        if result.hit and result.hitPos then
            local localZ = result.hitPos.z - bp.z
            lastHitZ = result.hitPos.z
            if result.hitObject == bed
                    and (not minZ or localZ >= minZ)
                    and (not maxZ or localZ <= maxZ) then
                return result.hitPos.z
            end
            print(string.format("[SleepLogic] findBedSurfaceZ: skipping non-bed/invalid hit recordId=%s localZ=%.1f",
                tostring(result.hitObject and result.hitObject.recordId), localZ))
            top = result.hitPos.z - 1
        else
            break
        end
    end

    if lastHitZ then
        print(string.format("[SleepLogic] findBedSurfaceZ: no profile-valid surface hit for %s, lastHitLocalZ=%.1f",
            tostring(bed.recordId), lastHitZ - bp.z))
    end
    return bp.z + 30  -- fallback guess
end

local function findBedExitPos(bed, profile)
    local bp = bed.position
    local bedSurfaceZ = findBedSurfaceZ(bed, profile)

    -- Validate bed surface against profile range if available.
    if profile then
        local bedSurfaceLocalZ = bedSurfaceZ - bp.z
        if profile.surfaceMinZ and bedSurfaceLocalZ < profile.surfaceMinZ then
            bedSurfaceZ = bp.z + 30
            print(string.format("[SleepLogic] findBedExitPos: bedSurfaceLocalZ below profile min (%.1f < %.1f), using fallback",
                bedSurfaceLocalZ, profile.surfaceMinZ))
        end
        if profile.surfaceMaxZ and bedSurfaceLocalZ > profile.surfaceMaxZ then
            bedSurfaceZ = bp.z + 30
            print(string.format("[SleepLogic] findBedExitPos: bedSurfaceLocalZ above profile max (%.1f > %.1f), using fallback",
                bedSurfaceLocalZ, profile.surfaceMaxZ))
        end
    end

    -- Ring offsets in bed-local XY space (Y = long axis, X = short axis).
    -- These are projected to world space using the bed's rotation.
    local ringOffsets = {
        { x = 0,   y = -120, label = "foot" },
        { x = 0,   y = 120,  label = "head" },
        { x = -100, y = 0,   label = "left" },
        { x = 100,  y = 0,   label = "right" },
        { x = -80,  y = -100, label = "foot_left" },
        { x = 80,   y = -100, label = "foot_right" },
        { x = -80,  y = 100,  label = "head_left" },
        { x = 80,   y = 100,  label = "head_right" },
    }

    local candidates = {}
    for _, off in ipairs(ringOffsets) do
        -- Transform local offset to world space.
        local localOff = bed.rotation * util.vector3(off.x, off.y, 0)
        local testPos  = util.vector3(bp.x + localOff.x, bp.y + localOff.y, bp.z)

        local floorPos = projectToFloor(testPos)
        if floorPos then
            local isFloor   = floorPos.z <= bedSurfaceZ - 6
            local horizDist = math.sqrt((floorPos.x - bp.x)^2 + (floorPos.y - bp.y)^2)
            local farEnough = horizDist >= 60

            -- Wall clearance check: cast outward from the candidate.
            local wallPenalty = 0
            if horizDist > 0 then
                local dir = util.vector3((floorPos.x - bp.x) / horizDist,
                                          (floorPos.y - bp.y) / horizDist, 0)
                local outFrom = floorPos + util.vector3(0, 0, 72)
                local outTo   = outFrom + (dir * 60)
                local outHit  = nearby.castRay(outFrom, outTo, { collisionType = nearby.COLLISION_TYPE.World })
                if outHit.hit then wallPenalty = wallPenalty + 900 end

                if horizDist > 50 then
                    local crossFrom = bp + (dir * 50) + util.vector3(0, 0, 72)
                    local crossTo   = floorPos + util.vector3(0, 0, 72)
                    local crossHit  = nearby.castRay(crossFrom, crossTo, { collisionType = nearby.COLLISION_TYPE.World })
                    if crossHit.hit then wallPenalty = wallPenalty + 450 end
                end
            end

            local score = 0
            if isFloor   then score = score + 2000 end
            if farEnough then score = score + 1000 end
            score = score - wallPenalty

            table.insert(candidates, { pos = floorPos, score = score, isFloor = isFloor, farEnough = farEnough, label = off.label })
        end
    end

    if #candidates == 0 then
        print("[SleepLogic] findBedExitPos: no raycast candidates found, falling back")
        return nil
    end

    table.sort(candidates, function(a, b) return a.score > b.score end)

    for _, c in ipairs(candidates) do
        if c.isFloor and c.farEnough then
            print(string.format("[SleepLogic] findBedExitPos: chose %s pos=%s", c.label, tostring(c.pos)))
            return c.pos
        end
    end

    for _, c in ipairs(candidates) do
        if c.isFloor then
            print(string.format("[SleepLogic] findBedExitPos: chose near-floor %s pos=%s", c.label, tostring(c.pos)))
            return c.pos
        end
    end

    print("[SleepLogic] findBedExitPos: all candidates were above the mattress; falling back to actor position")
    return nil
end

-- =============================================================================
-- PC_ConsiderBed  — validation + exit position find; sends PC_BedCheckResult
-- =============================================================================
function SleepLogic.onConsiderBeds(data)
    local entries = data and data.beds
    if not entries or #entries == 0 then
        core.sendGlobalEvent("PC_BedCheckResult", { npc = self.object, usable = false })
        return
    end

    local rankCandidates = {}
    for _, entry in ipairs(entries) do
        if entry.bed then
            local approachPos = entry.bed.position
            local profileSlots = entry.profileSlots
            if profileSlots and #profileSlots > 0 then
                local slot = profileSlots[1]
                if slot and slot.approachPos then
                    approachPos = slot.approachPos
                end
            end
            table.insert(rankCandidates, {
                object = entry.bed,
                approachPos = approachPos,
                entry = entry,
            })
        end
    end

    local ranked = FurnitureRouteScorer.rank(self.object, rankCandidates, { interaction = "sleep" })

    for _, cand in ipairs(ranked) do
        local entry = cand.entry
        if SleepLogic.onConsiderBed({
            bed = entry.bed,
            teleport = data.teleport,
            profileSlots = entry.profileSlots,
        }) then
            return
        end
    end

    core.sendGlobalEvent("PC_BedCheckResult", { npc = self.object, usable = false })
end

--- Returns true if a usable bed assignment was sent to the global script.
function SleepLogic.onConsiderBed(data)
    local bed = data.bed
    print(string.format("[SleepLogic] onConsiderBed: npc=%s bed=%s",
        self.recordId, tostring(bed and bed.recordId)))

    if Blacklist.isSleepBlacklisted(self.object) then
        core.sendGlobalEvent("PC_BedCheckResult", { npc = self.object, bed = bed, usable = false })
        return false
    end

    -- Reset stale sleep state from a previous cycle.
    sm:transition("walking_to_bed")
    pcall(function() anim.cancel(self, "slee8") end)
    pcall(function() anim.cancel(self, "slee7") end)

    -- Profile-aware exit position.
    local profileSlots = data.profileSlots
    local profile = bed and FurnitureProfiles.getProfileForObject(bed, "sleep") or nil
    if not profileSlots and profile then
        local allSlots = FurnitureProfiles.getSlots(bed, "sleep")
        profileSlots = allSlots
    end

    local exitPos
    if profileSlots and #profileSlots > 0 then
        local slot = profileSlots[1]
        if slot.approachPos then
            exitPos = slot.approachPos
            print(string.format("[SleepLogic] onConsiderBed: using profile approachPos for exitPos=%s", tostring(exitPos)))
        else
            exitPos = findBedExitPos(bed, profile) or self.object.position
            print(string.format("[SleepLogic] onConsiderBed: using computed bed exitPos=%s", tostring(exitPos)))
        end
    else
        exitPos = findBedExitPos(bed, profile) or self.object.position
    end
    walkTarget = exitPos

    local lockReason = FurnitureRouteScorer.routeAccessRejectReason(self.object, exitPos)
    if lockReason then
        print(string.format("[SleepLogic] REJECT bed for %s (route: %s)", self.recordId, lockReason))
        sm:transition("idle")
        pcall(function() anim.cancel(self, "slee8") end)
        pcall(function() anim.cancel(self, "slee7") end)
        core.sendGlobalEvent("PC_BedCheckResult", { npc = self.object, bed = bed, usable = false })
        return false
    end

    -- Animation normalization offset for sleep (applied by SleepManager to seatedPos).
    local animationOffset = nil
    if profile then
        animationOffset = FurnitureProfiles.getAnimationOffset(profile, "slee8", "sleep")
    end

    core.sendGlobalEvent("PC_BedCheckResult", {
        npc     = self.object,
        bed     = bed,
        usable  = true,
        exitPos = exitPos,
        originalPosition = nativeHome and nativeHome.position or nil,
        originalRotation = nativeHome and nativeHome.rotation or nil,
        animationOffset = animationOffset,
    })
    return true
end

-- =============================================================================
-- PC_CancelTravelToBed  — strip the Travel package heading toward the exit pos
-- =============================================================================
function SleepLogic.onCancelTravelToBed(data)
    if ai and ai.filterPackages and walkTarget then
        ai.filterPackages(function(pkg)
            if pkg and pkg.type == "Travel" and pkg.destPosition then
                if (pkg.destPosition - walkTarget):length() < 150 then
                    return false
                end
            end
            return true
        end)
    end
    if not data or data.resetState ~= false then
        walkTarget = nil
        pcall(function() anim.cancel(self, "slee7") end)
        pcall(function() anim.cancel(self, "slee8") end)
        if sm:is("walking_to_bed") or sm:is("laying_down") then
            sm:transition("idle")
        end
    end
end

-- =============================================================================
-- PC_SleepPlease  — begin lay-down animation sequence
-- =============================================================================
function SleepLogic.onSleepPlease(data)
    if sm:is("sleeping") or sm:is("laying_down") then return end
    sm:transition("laying_down")

    pcall(function()
        I.AnimationController.playBlendedAnimation("slee7", {
            loops     = 1,
            forceLoop = false,
            priority  = anim.PRIORITY.Movement,
            blendMask = 15,
        })
    end)
end

-- =============================================================================
-- PC_TeleportSleepPlease  — skip lay-down; go straight to sleep idle
-- (used when persistent exit pos is known — NPC teleports directly to bed)
-- =============================================================================
function SleepLogic.onTeleportSleepPlease(data)
    pcall(function() anim.cancel(self, "slee8") end)
    sm:transition("sleeping")

    local ok, err = pcall(function()
        I.AnimationController.playBlendedAnimation("slee8", {
            loops     = 999,
            forceLoop = true,
            priority  = anim.PRIORITY.Movement,
            blendMask = 15,
        })
    end)
    if not ok then
        print(string.format("[SleepLogic] slee8 failed on %s: %s", self.recordId, tostring(err)))
    end
end

-- =============================================================================
-- PC_WakeUpPlease  — stop animations, restore hello, signal global to lerp back
-- No raycasting — the global has the exit position from assignment time.
-- =============================================================================
function SleepLogic.onWakeUpPlease(data)
    if sm:is("idle") or sm:is("waking_up") then
        -- No-op: NPC is already awake. Return immediately to prevent
        -- triggering global wake lerp/monitor logic.
        return
    end
    sm:transition("waking_up")

    pcall(function() anim.cancel(self, "slee8") end)
    pcall(function() anim.cancel(self, "slee7") end)

    -- wakePos is nil — SleepManager lerps NPC back to the stored preSleepPos
    -- (the exitPos recorded at assignment time).
    core.sendGlobalEvent("PC_WakePositionFound", {
        npc         = self.object,
        wakePos     = nil,
        immediate   = data and data.immediate or false,
        skipLerp    = data and data.skipLerp or false,
        fallbackPos = data and data.fallbackPos or nil,
        fallbackRot = data and data.fallbackRot or nil,
        preActivityPosition = data and data.preActivityPosition or nil,
        preActivityRotation = data and data.preActivityRotation or nil,
        wakeToWander = data and data.wakeToWander or false,
    })

    -- Cancel any lingering travel-to-bed package.
    pcall(function() ai.filterPackages(function(pkg)
        return not (pkg.type == "Travel" and pkg.destPosition
            and walkTarget and (pkg.destPosition - walkTarget):length() < 200)
    end) end)

    walkTarget = nil

    if data and data.skipLerp then
        sm:transition("idle")
    end
end

function SleepLogic.onWakeUpFinished()
    sm:transition("idle")
end

-- =============================================================================
-- Update — state machine update
-- =============================================================================
function SleepLogic.update(dt)
    sm:update(dt)
end

return SleepLogic
