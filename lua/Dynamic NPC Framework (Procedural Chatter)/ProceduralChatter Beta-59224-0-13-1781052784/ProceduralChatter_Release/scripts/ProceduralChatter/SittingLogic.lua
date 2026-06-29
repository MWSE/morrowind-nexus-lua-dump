-- SittingLogic.lua
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local util = require('openmw.util')
local self = require('openmw.self')
local I = require('openmw.interfaces')
local anim = require('openmw.animation')
local ai = require('openmw.interfaces').AI
local types = require('openmw.types')

local SittingLogic = {}

local Blacklist = require("scripts.ProceduralChatter.Blacklist")
local FurnitureProfiles = require("scripts.ProceduralChatter.data.FurnitureProfiles")
local FurnitureRouteScorer = require("scripts.ProceduralChatter.FurnitureRouteScorer")
local StateMachine = require("scripts.ProceduralChatter.StateMachine")

local AI_POLL_INTERVAL = 0.5

-- State Machine
local sm = StateMachine.create({
    idle = {
        enter = function(prev, data) end,
        update = function(dt) end,
        exit = function(next) end,
    },
    walking_to_seat = {
        enter = function(prev, data)
            core.sendGlobalEvent("PC_StateChanged", { npcId = self.id, state = "traveling_to_seat" })
        end,
        update = function(dt) end,
        exit = function(next) end,
    },
    seated = {
        enter = function(prev, data)
            core.sendGlobalEvent("PC_StateChanged", { npcId = self.id, state = "sitting" })
        end,
        update = function(dt) end,
        exit = function(next)
            core.sendGlobalEvent("PC_StateChanged", { npcId = self.id, state = "idle" })
        end,
    },
    standing_up = {
        enter = function(prev, data)
            core.sendGlobalEvent("PC_StateChanged", { npcId = self.id, state = "idle" })
        end,
        update = function(dt) end,
        exit = function(next) end,
    },
}, "idle")

local stool = nil
local seatPos = nil
local aiPollTimer = 0

-- Helper: Faction Leader Check
local function isFactionLeader(actor)
    if not actor or not types.NPC.objectIsInstance(actor) then return false end
    if not (types.NPC.getFactions and types.NPC.getFactionRank) then return false end
    -- core.factions might not be available in local scope? 
    -- core.factions is GLOBAL only in older OpenMW? Check docs.
    -- StoolSeeker used it.
    if not (core.factions and core.factions.records) then return false end

    local factionIds = types.NPC.getFactions(actor)
    if not factionIds then return false end

    for _, factionId in ipairs(factionIds) do
        local factionRec = core.factions.records[factionId] or core.factions.records[string.lower(factionId)]
        if factionRec and factionRec.ranks then
            local maxRank = #factionRec.ranks
            local ok, rank = pcall(types.NPC.getFactionRank, actor, factionId)
            if ok and rank == maxRank and rank > 0 then
                return true
            end
        end
    end
    return false
end

-- Bench/Stool Helpers
local function determineBenchOrientationAndLength(bench)
    local center = bench.position
    local xHits, yHits = 0, 0
    local xLength, yLength = 0, 0
    local zLevel = center.z

    for i = -5, 5 do
        local xFrom = center + util.vector3(i * 10, 0, 100)
        local xTo = center + util.vector3(i * 10, 0, 0)
        local xResult = nearby.castRay(xFrom, xTo, { collisionType = nearby.COLLISION_TYPE.World })
        if xResult.hit and xResult.hitObject == bench then
            xHits = xHits + 1
            xLength = xLength + 10
            zLevel = xResult.hitPos.z
        end

        local yFrom = center + util.vector3(0, i * 10, 100)
        local yTo = center + util.vector3(0, i * 10, 0)
        local yResult = nearby.castRay(yFrom, yTo, { collisionType = nearby.COLLISION_TYPE.World })
        if yResult.hit and yResult.hitObject == bench then
            yHits = yHits + 1
            yLength = yLength + 10
            zLevel = yResult.hitPos.z
        end
    end

    if xHits > yHits then return "x", xLength, zLevel else return "y", yLength, zLevel end
end

local function getSittingPositions(bench, orientation, length, zLevel)
    local center = bench.position
    local halfLength = length / 2
    local positions = {}
    if orientation == "x" then
        table.insert(positions, util.vector3(center.x - halfLength / 2, center.y, zLevel))
        table.insert(positions, util.vector3(center.x + halfLength / 2, center.y, zLevel))
    else
        table.insert(positions, util.vector3(center.x, center.y - halfLength / 2, zLevel))
        table.insert(positions, util.vector3(center.x, center.y + halfLength / 2, zLevel))
    end
    return positions
end

local function determineFacingDirection(sitPosition, orientation, obj)
    local directions = {}
    if orientation then
        if orientation == "x" then
            table.insert(directions, util.vector3(0, -1, 0))
            table.insert(directions, util.vector3(0, 1, 0))
        else
            table.insert(directions, util.vector3(-1, 0, 0))
            table.insert(directions, util.vector3(1, 0, 0))
        end
    else
        local angleStep = math.pi / 6
        for i = 0, 11 do
            local angle = i * angleStep
            table.insert(directions, util.vector3(math.cos(angle), math.sin(angle), 0))
        end
    end

    -- Pick the direction with the most clearance (furthest from walls/objects).
    -- This makes lone stools face toward the center of the room naturally.
    local scanRange = 400
    local bestDirection = nil
    local bestClearance = -1

    for _, direction in ipairs(directions) do
        local from = sitPosition + util.vector3(0, 0, 70)
        local to = from + direction * scanRange
        local result = nearby.castRay(from, to, { collisionType = nearby.COLLISION_TYPE.World, ignore = obj })
        local clearance = result.hit and (result.hitPos - from):length() or scanRange
        if clearance > bestClearance then
            bestClearance = clearance
            bestDirection = direction
        end
    end

    return bestDirection or util.vector3(1, 0, 0)
end

-- Helper: safe object check
local Utils = require("scripts.ProceduralChatter.Utils")

-- Find a floor position beside the stool/bench in the facing direction.
-- NPC walks here first, then lerps onto the seat; stands back here on exit.
local SEAT_EXIT_OFFSET = 60
local CHAIR_BACK_BLOCKED_DISTANCE = 55
local CHAIR_APPROACH_CLEARANCE = 35
local CHAIR_GROUND_Z_TOLERANCE = 35

local function canFaceNearestTableOrCounter(profile)
    if not profile then return true end
    return profile.rotationMode == "faceNearestTableOrCounter"
        and (profile.seatType == "stool" or profile.seatType == "barstool")
end

local function getFaceTarget(data, profile)
    if type(data) ~= "table" then return nil end
    if not canFaceNearestTableOrCounter(profile) then return nil end
    if data.barTarget and Utils.isObjValid(data.barTarget) then return data.barTarget end
    if profile and data.tableTarget and Utils.isObjValid(data.tableTarget) then return data.tableTarget end
    return nil
end

local function normalize2D(vec)
    if not vec then return nil end
    local out = util.vector3(vec.x, vec.y, 0)
    local len = math.sqrt(out.x * out.x + out.y * out.y)
    if len <= 0.001 then return nil end
    return util.vector3(out.x / len, out.y / len, 0)
end

local function floorPosNear(pos)
    local ok, navPos = pcall(nearby.findNearestNavMeshPosition, pos)
    if ok and navPos then return navPos end

    local top = util.vector3(pos.x, pos.y, pos.z + 100)
    local bot = util.vector3(pos.x, pos.y, pos.z - 200)
    local res = nearby.castRay(top, bot, { collisionType = nearby.COLLISION_TYPE.World })
    return res.hit and res.hitPos or pos
end

local function groundPosBelow(pos, ignoredObj)
    if not pos then return nil end
    local top = util.vector3(pos.x, pos.y, pos.z + 120)
    local bot = util.vector3(pos.x, pos.y, pos.z - 220)
    local ok, res = pcall(nearby.castRay, top, bot, { collisionType = nearby.COLLISION_TYPE.World, ignore = ignoredObj })
    if ok and res and res.hit then return res.hitPos end
    return nil
end

local function floorPosInDirection(targetPos, anchorPos, direction, minProgress)
    local pos = floorPosNear(targetPos)
    local delta = pos - anchorPos
    local progress = delta.x * direction.x + delta.y * direction.y
    if progress >= (minProgress or 0) then
        return pos
    end
    return nil
end

local function horizontalClearance(fromPos, direction, distance, ignoredObj)
    local from = fromPos + util.vector3(0, 0, 80)
    local to = from + direction * distance
    local res = nearby.castRay(from, to, { collisionType = nearby.COLLISION_TYPE.World, ignore = ignoredObj })
    return res.hit and (res.hitPos - from):length() or distance
end

local function pickDirectionToward(pos, targetPos, dirA, dirB)
    local toTarget = normalize2D(targetPos - pos)
    if not toTarget then return dirA end
    local dotA = dirA.x * toTarget.x + dirA.y * toTarget.y
    local dotB = dirB.x * toTarget.x + dirB.y * toTarget.y
    return (dotA >= dotB) and dirA or dirB
end

local function buildChairApproachCandidates(actor, stoolObj, sitPosition, front, hasTable)
    local right = normalize2D(util.vector3(front.y, -front.x, 0)) or util.vector3(0, -1, 0)
    local left = util.vector3(-right.x, -right.y, 0)
    local back = util.vector3(-front.x, -front.y, 0)
    local chairGround = groundPosBelow(sitPosition, stoolObj)
    local specs = {}

    if hasTable then
        table.insert(specs, { label = "back", dir = back, requiredClearance = CHAIR_BACK_BLOCKED_DISTANCE })
        table.insert(specs, { label = "left", dir = left, requiredClearance = CHAIR_APPROACH_CLEARANCE })
        table.insert(specs, { label = "right", dir = right, requiredClearance = CHAIR_APPROACH_CLEARANCE })
    else
        table.insert(specs, { label = "front", dir = front, requiredClearance = CHAIR_APPROACH_CLEARANCE })
        table.insert(specs, { label = "left", dir = left, requiredClearance = CHAIR_APPROACH_CLEARANCE })
        table.insert(specs, { label = "right", dir = right, requiredClearance = CHAIR_APPROACH_CLEARANCE })
        table.insert(specs, { label = "back", dir = back, requiredClearance = CHAIR_APPROACH_CLEARANCE })
    end

    local sameGroundCandidates = {}
    local fallbackCandidates = {}
    local bestClearance = -1

    for _, spec in ipairs(specs) do
        local clearance = horizontalClearance(sitPosition, spec.dir, SEAT_EXIT_OFFSET, stoolObj)
        if clearance > bestClearance then bestClearance = clearance end
        if clearance >= (spec.requiredClearance or CHAIR_APPROACH_CLEARANCE) then
            local targetPos = sitPosition + spec.dir * SEAT_EXIT_OFFSET
            local groundPos = groundPosBelow(targetPos, stoolObj)
            if groundPos then
                local delta = groundPos - sitPosition
                local progress = delta.x * spec.dir.x + delta.y * spec.dir.y
                if progress >= CHAIR_APPROACH_CLEARANCE then
                    local navPos = floorPosInDirection(targetPos, sitPosition, spec.dir, CHAIR_APPROACH_CLEARANCE)
                    if navPos then
                        local groundDelta = chairGround and math.abs(groundPos.z - chairGround.z) or 0
                        local navGroundDelta = math.abs(navPos.z - groundPos.z)
                        local candidate = {
                            object = stoolObj,
                            approachPos = navPos,
                            approachLabel = spec.label,
                            roughDist = (actor and (actor.position - navPos):length()) or nil,
                            groundDelta = groundDelta,
                            navGroundDelta = navGroundDelta,
                        }
                        if groundDelta <= CHAIR_GROUND_Z_TOLERANCE and navGroundDelta <= CHAIR_GROUND_Z_TOLERANCE then
                            table.insert(sameGroundCandidates, candidate)
                        else
                            table.insert(fallbackCandidates, candidate)
                        end
                    end
                end
            end
        end
    end

    local candidates = (#sameGroundCandidates > 0) and sameGroundCandidates or fallbackCandidates
    if #candidates == 0 then
        return nil, bestClearance
    end

    local ranked = FurnitureRouteScorer.rank(actor, candidates, { interaction = "sit" })
    local best = ranked and ranked[1] or candidates[1]
    return best and best.approachPos or nil, bestClearance, best
end

local function findSeatExitPos(seatPos, isBench, benchPerpA, benchPerpB, avoidPos, obj)
    -- If there's a nearby object to avoid (e.g. a table), benches should exit
    -- on the side that faces AWAY from it so NPCs don't get placed on top.
    if isBench and avoidPos and benchPerpA and benchPerpB then
        local away = (seatPos - avoidPos):normalize()
        away = util.vector3(away.x, away.y, 0)
        local dotA = benchPerpA.x * away.x + benchPerpA.y * away.y
        local dotB = benchPerpB.x * away.x + benchPerpB.y * away.y
        local finalDir = (dotA >= dotB) and benchPerpA or benchPerpB
        local cx = seatPos.x + finalDir.x * SEAT_EXIT_OFFSET
        local cy = seatPos.y + finalDir.y * SEAT_EXIT_OFFSET
        local targetPos = util.vector3(cx, cy, seatPos.z)
        local ok, navPos = pcall(nearby.findNearestNavMeshPosition, targetPos)
        if ok and navPos then return navPos end
        local top = util.vector3(cx, cy, seatPos.z + 100)
        local bot = util.vector3(cx, cy, seatPos.z - 200)
        local res = nearby.castRay(top, bot, { collisionType = nearby.COLLISION_TYPE.World })
        if res.hit then return res.hitPos end
        return nil
    end

    local directions = {}
    if isBench then
        if benchPerpA then table.insert(directions, benchPerpA) end
        if benchPerpB then table.insert(directions, benchPerpB) end
        if #directions == 0 then
            -- No perps provided (profile-driven bench) — fall back to radial scan.
            local angleStep = math.pi / 6
            for i = 0, 11 do
                local angle = i * angleStep
                table.insert(directions, util.vector3(math.cos(angle), math.sin(angle), 0))
            end
        end
    else
        local angleStep = math.pi / 6
        for i = 0, 11 do
            local angle = i * angleStep
            table.insert(directions, util.vector3(math.cos(angle), math.sin(angle), 0))
        end
    end

    local scanRange = 400
    local bestDirection = nil
    local bestClearance = -1

    for _, direction in ipairs(directions) do
        local from = seatPos + util.vector3(0, 0, 70)
        local to = from + direction * scanRange
        local result = nearby.castRay(from, to, { collisionType = nearby.COLLISION_TYPE.World, ignore = obj })
        local clearance = result.hit and (result.hitPos - from):length() or scanRange
        if clearance > bestClearance then
            bestClearance = clearance
            bestDirection = direction
        end
    end

    local finalDir = bestDirection or directions[1]
    local cx  = seatPos.x + finalDir.x * SEAT_EXIT_OFFSET
    local cy  = seatPos.y + finalDir.y * SEAT_EXIT_OFFSET
    local targetPos = util.vector3(cx, cy, seatPos.z)
    
    local ok, navPos = pcall(nearby.findNearestNavMeshPosition, targetPos)
    if ok and navPos then return navPos end
    
    -- Fallback geometry drop if NavMesh API is failing
    local top = util.vector3(cx, cy, seatPos.z + 100)
    local bot = util.vector3(cx, cy, seatPos.z - 200)
    local res = nearby.castRay(top, bot, { collisionType = nearby.COLLISION_TYPE.World })
    if res.hit then return res.hitPos end
    return nil
end

-- Event Handlers
-- Helper: apply animation normalization offset to a world-space sit position.
local function applyActorSpaceOffset(sitPosition, facingDirection, actorOffset)
    if not actorOffset then return sitPosition end
    local fwd = normalize2D(facingDirection)
    if not fwd then return sitPosition end
    local right = util.vector3(fwd.y, -fwd.x, 0)
    return util.vector3(
        sitPosition.x + right.x * (actorOffset.x or 0) + fwd.x * (actorOffset.y or 0),
        sitPosition.y + right.y * (actorOffset.x or 0) + fwd.y * (actorOffset.y or 0),
        sitPosition.z
    )
end

local function actorOffsetForSeatType(actorOffset, seatType)
    if not actorOffset then return nil end
    if seatType == "backed_chair" or seatType == "single_seat_bench" then
        return { x = actorOffset.x or 0, y = 0 }
    end
    return actorOffset
end

local function stoolVisualAnchor(pos, profile)
    if not pos or not profile then return pos end
    local z = profile.finalZOffset
    if z == nil then return pos end
    return util.vector3(pos.x, pos.y, pos.z + z)
end

local function chooseSitAnimation()
    local okPc, hasPc = pcall(anim.hasGroup, self, 'pcdbssit5')
    if okPc and hasPc then return 'pcdbssit5' end
    local okDbs, hasDbs = pcall(anim.hasGroup, self, 'dbssit5')
    if okDbs and hasDbs then return 'dbssit5' end
    local okIdle, hasIdle = pcall(anim.hasGroup, self, 'sitidle1')
    if okIdle and hasIdle then return 'sitidle1' end
    return nil
end

local function withSitAnimationOffset(result, profile, profileSlot)
    local animationId = chooseSitAnimation()
    if animationId then
        result.animationId = animationId
        result.animationOffset = FurnitureProfiles.getAnimationOffset(profile, animationId, "sit", result.stool, profileSlot)
    end
    return result
end

function SittingLogic.evaluateStool(data)
    print(string.format("[SittingLogic] evaluateStool called for %s (Stool: %s)", self.recordId, data.stool and data.stool.recordId))
    if sm:is("seated") or sm:is("standing_up") then
        SittingLogic.requestStand("new_stool_offer")
    end
    sm:transition("idle")
    seatPos = nil
    aiPollTimer = 0

    if Blacklist.isSitBlacklisted(self.object) then
        print(string.format("[SittingLogic] REJECTING stool for %s (blacklisted)", self.recordId))
        return { usable = false, stool = data.stool, geometryReject = false, reason = "sit_blacklisted" }
    end

    stool = data.stool
    local profile = FurnitureProfiles.getProfileForObject(stool, "sit")
    local seatType = profile and profile.seatType or nil
    local isBench = stool.recordId == "furn_de_p_bench_03"
        or stool.recordId == "furn_com_p_bench_01"
        or seatType == "bench"
    local isChair = stool.recordId == "furn_com_rm_chair_03"
        or seatType == "backed_chair"
        or seatType == "single_seat_bench"

    local profileSlots = FurnitureProfiles.getSlots(stool, "sit")
    local result, usable
    local rejectReason = nil
    if isChair then
        -- Manual seat position — no raycast. Seat surface is a fixed offset
        -- above the chair origin; tweak CHAIR_SEAT_Z_OFFSET as needed.
        usable = true
    else
        local from = stool.position + util.vector3(0, 0, 100)
        local to = stool.position
        result = nearby.castRay(from, to, { collisionType = nearby.COLLISION_TYPE.World })
        usable = result.hit and result.hitObject == stool
        if not usable then
            rejectReason = result.hit and "seat_surface_hit_other_object" or "seat_surface_not_found"
        end
    end

    if usable and isBench then
        local profileSlot = profileSlots and (profileSlots[data.slotIndex or 1] or profileSlots[1]) or nil
        local sitPosition, facingDirection, exitPos
        if profileSlot and not profileSlot.usesSharedSeatAnchor then
            sitPosition = profileSlot.pos
            -- Ignore profile facing for benches; use raycast-based open-side logic.
            -- Derive perpendiculars from the bench's rotation (same as fallback path).
            local localX = stool.rotation * util.vector3(1, 0, 0)
            local localY = stool.rotation * util.vector3(0, 1, 0)
            local longAxis = util.vector3(localX.x, localX.y, 0)
            local axLen = math.sqrt(longAxis.x * longAxis.x + longAxis.y * longAxis.y)
            if axLen > 0.001 then longAxis = util.vector3(longAxis.x / axLen, longAxis.y / axLen, 0) end
            local perpA = util.vector3(-longAxis.y,  longAxis.x, 0)
            local perpB = util.vector3( longAxis.y, -longAxis.x, 0)

            if data.tableTarget and Utils.isObjValid(data.tableTarget) then
                print(string.format("[SittingLogic] Facing Table %s from bench", data.tableTarget.recordId))
                facingDirection = pickDirectionToward(sitPosition, data.tableTarget.position, perpA, perpB)
            else
                local from      = sitPosition + util.vector3(0, 0, 70)
                local scanRange = 400
                local resA = nearby.castRay(from, from + perpA * scanRange, { collisionType = nearby.COLLISION_TYPE.World, ignore = stool })
                local resB = nearby.castRay(from, from + perpB * scanRange, { collisionType = nearby.COLLISION_TYPE.World, ignore = stool })
                local clearA = resA.hit and (resA.hitPos - from):length() or scanRange
                local clearB = resB.hit and (resB.hitPos - from):length() or scanRange
                facingDirection = (clearA >= clearB) and perpA or perpB
            end
            sitPosition = applyActorSpaceOffset(sitPosition, facingDirection, profileSlot.actorSpaceOffset)
            exitPos = findSeatExitPos(sitPosition, true, perpA, perpB,
                data.tableTarget and data.tableTarget.position or nil, stool)
        else
            local orientation, length, _ = determineBenchOrientationAndLength(stool)
            local surfaceZ = result.hitPos.z

            -- Derive the actual world-space long axis from the bench's rotation so that
            -- sitting positions and facing directions align with the mesh exactly, not
            -- with the nearest cardinal axis (which can be ~15° off for rotated benches).
            local localX = stool.rotation * util.vector3(1, 0, 0)
            local localY = stool.rotation * util.vector3(0, 1, 0)
            -- Pick whichever local axis best matches the raycast-determined orientation.
            local longAxis
            if orientation == "x" then
                longAxis = (math.abs(localX.x) >= math.abs(localY.x)) and localX or localY
            else
                longAxis = (math.abs(localX.y) >= math.abs(localY.y)) and localX or localY
            end
            -- Flatten to XY and normalise.
            longAxis = util.vector3(longAxis.x, longAxis.y, 0)
            local axLen = math.sqrt(longAxis.x * longAxis.x + longAxis.y * longAxis.y)
            if axLen > 0.001 then longAxis = util.vector3(longAxis.x / axLen, longAxis.y / axLen, 0) end

            -- Two sitting positions offset from bench centre along the real long axis.
            local halfOff  = length / 4
            local centre   = util.vector3(stool.position.x, stool.position.y, surfaceZ)
            local sitA     = centre + util.vector3( longAxis.x * halfOff,  longAxis.y * halfOff, 0)
            local sitB     = centre + util.vector3(-longAxis.x * halfOff, -longAxis.y * halfOff, 0)
            local slotIndex = tonumber(data.slotIndex)
            if slotIndex == 1 then
                sitPosition = sitA
            elseif slotIndex == 2 then
                sitPosition = sitB
            else
                sitPosition = (math.random(2) == 1) and sitA or sitB
            end

            -- The two valid facing directions are exactly perpendicular to the long axis.
            local perpA = util.vector3(-longAxis.y,  longAxis.x, 0)
            local perpB = util.vector3( longAxis.y, -longAxis.x, 0)

            if data.tableTarget and Utils.isObjValid(data.tableTarget) then
                -- Face toward the nearby table using only the two valid bench sides.
                print(string.format("[SittingLogic] Facing Table %s from bench", data.tableTarget.recordId))
                facingDirection = pickDirectionToward(sitPosition, data.tableTarget.position, perpA, perpB)
            else
                -- Pick whichever perpendicular side has more open space.
                local from      = sitPosition + util.vector3(0, 0, 70)
                local scanRange = 400
                local resA = nearby.castRay(from, from + perpA * scanRange, { collisionType = nearby.COLLISION_TYPE.World, ignore = stool })
                local resB = nearby.castRay(from, from + perpB * scanRange, { collisionType = nearby.COLLISION_TYPE.World, ignore = stool })
                local clearA = resA.hit and (resA.hitPos - from):length() or scanRange
                local clearB = resB.hit and (resB.hitPos - from):length() or scanRange
                facingDirection = (clearA >= clearB) and perpA or perpB
            end

            exitPos = findSeatExitPos(sitPosition, true, perpA, perpB,
                data.tableTarget and data.tableTarget.position or nil, stool)
        end

        seatPos = sitPosition
        sm:transition("walking_to_seat")
        return withSitAnimationOffset({
            usable = usable, stool = stool, hitPos = sitPosition,
            facingDirection = facingDirection, exitPos = exitPos, geometryReject = false,
        }, profile, profileSlot)
    elseif usable and isChair then
        -- Fixed-facing chair: single slot, manual offset from origin.
        -- Morrowind chair models (furn_com_rm_chair_03) have their local +Y
        -- pointing to the BACK of the chair, so we negate to get the front.
        local profileSlot = profileSlots and profileSlots[data.slotIndex or 1] or nil
        local sitPosition
        local front
        local back
        if profileSlot and profileSlot.pos and profileSlot.facing then
            sitPosition = profileSlot.pos
            front = util.vector3(profileSlot.facing.x, profileSlot.facing.y, 0)
            back = util.vector3(-front.x, -front.y, 0)
        else
            local off = FurnitureProfiles.getChairSeatOffset(stool.recordId) or { x = 0, y = 0, z = 0 }
            sitPosition = util.vector3(
                stool.position.x + off.x,
                stool.position.y + off.y,
                stool.position.z + off.z
            )
            local backRaw = stool.rotation * util.vector3(0, 1, 0)
            back = util.vector3(backRaw.x, backRaw.y, 0)
            local bLen = math.sqrt(back.x * back.x + back.y * back.y)
            if bLen > 0.001 then
                back = util.vector3(back.x / bLen, back.y / bLen, 0)
            end
            front = util.vector3(-back.x, -back.y, 0)
        end

        front = normalize2D(front) or util.vector3(1, 0, 0)
        if profileSlot and profileSlot.actorSpaceOffset then
            sitPosition = applyActorSpaceOffset(sitPosition, front, actorOffsetForSeatType(profileSlot.actorSpaceOffset, seatType))
        end

        -- Backed chairs respect their furniture-forward profile. Prefer
        -- candidates whose downward ground ray stays on the chair's floor so
        -- stairs below do not become the walk target.
        local hasTable = false
        local exitPos, approachClearance, approachCandidate = buildChairApproachCandidates(self.object, stool, sitPosition, front, hasTable)

        -- Reject chair if no approachable position exists.
        if usable and (not exitPos or approachClearance < CHAIR_APPROACH_CLEARANCE) then
            rejectReason = string.format("no_approachable_position_clearance_%.1f", approachClearance or -1)
            print(string.format("[SittingLogic] REJECTING chair %s for %s (no approachable position)", stool.recordId, self.recordId))
            usable = false
        elseif usable and approachCandidate then
            print(string.format(
                "[SittingLogic] chair approach %s for %s via %s (groundDelta=%.1f navGroundDelta=%.1f)",
                tostring(stool.recordId),
                tostring(self.recordId),
                tostring(approachCandidate.approachLabel),
                approachCandidate.groundDelta or -1,
                approachCandidate.navGroundDelta or -1
            ))
        end

        if usable then
            seatPos = sitPosition
            sm:transition("walking_to_seat")
        end
        return withSitAnimationOffset({
            usable = usable, stool = stool, hitPos = sitPosition,
            facingDirection = front, exitPos = exitPos,
            geometryReject = not usable,
            reason = rejectReason,
        }, profile, profileSlot)
    else
        -- Stool logic
        local sitPosition, facingDirection, exitPos

        if profileSlots and #profileSlots > 0 then
            local slot = profileSlots[data.slotIndex or 1] or profileSlots[1]
            sitPosition = slot.pos
            if result and result.hit and result.hitObject == stool then
                sitPosition = result.hitPos
            end
            -- Stools are circular; profiled table/counter-aware stools face
            -- the nearby social surface, otherwise use the open-space scan.
            local faceTarget = getFaceTarget(data, profile)
            if faceTarget then
                print(string.format("[SittingLogic] Facing %s from stool (profile)", tostring(faceTarget.recordId)))
                local dir = (faceTarget.position - stool.position):normalize()
                facingDirection = util.vector3(dir.x, dir.y, 0)
            else
                facingDirection = determineFacingDirection(sitPosition, nil, stool)
            end
            sitPosition = applyActorSpaceOffset(sitPosition, facingDirection, actorOffsetForSeatType(slot.actorSpaceOffset, seatType))
            if seatType == "stool" or seatType == "barstool" then
                sitPosition = stoolVisualAnchor(sitPosition, profile)
            end
            exitPos = slot.approachPos or findSeatExitPos(sitPosition, false, nil, nil, nil, stool)
        else
            local faceTarget = getFaceTarget(data, profile)
            if faceTarget then
                 print(string.format("[SittingLogic] Facing %s from stool", tostring(faceTarget.recordId)))
                 local dir = (faceTarget.position - stool.position):normalize()
                 facingDirection = util.vector3(dir.x, dir.y, 0)
            else
                facingDirection = determineFacingDirection(result.hitPos, nil, stool)
            end

            sitPosition = result.hitPos

            if faceTarget then
                -- Table/counter stool: place exitPos directly behind the stool.
                local behindDir = util.vector3(-facingDirection.x, -facingDirection.y, 0)
                local targetX = sitPosition.x + behindDir.x * SEAT_EXIT_OFFSET
                local targetY = sitPosition.y + behindDir.y * SEAT_EXIT_OFFSET
                local targetPos = util.vector3(targetX, targetY, sitPosition.z)
                local ok, navPos = pcall(nearby.findNearestNavMeshPosition, targetPos)
                if ok and navPos then
                    exitPos = navPos
                else
                    local top = util.vector3(targetX, targetY, sitPosition.z + 100)
                    local bot = util.vector3(targetX, targetY, sitPosition.z - 200)
                    local res = nearby.castRay(top, bot, { collisionType = nearby.COLLISION_TYPE.World })
                    exitPos = res.hit and res.hitPos or targetPos
                end
            else
                exitPos = findSeatExitPos(sitPosition, false, nil, nil, nil, stool)
            end
        end

        if usable then
            seatPos = sitPosition
            sm:transition("walking_to_seat")
        end
        local evalResult = {
            usable = usable, stool = stool, hitPos = sitPosition,
            facingDirection = facingDirection, exitPos = exitPos, geometryReject = false,
            reason = rejectReason,
        }
        if (seatType == "stool" or seatType == "barstool") and profileSlots and #profileSlots > 0 then
            evalResult.zOffset = 0
        end
        return withSitAnimationOffset(evalResult, profile, profileSlots and (profileSlots[data.slotIndex or 1] or profileSlots[1]) or nil)
    end

    return { usable = false, stool = stool, geometryReject = false, reason = rejectReason or "unsupported_or_unusable_seat" }
end

function SittingLogic.onConsiderTheStool(data)
    local result = SittingLogic.evaluateStool(data)
    if result.usable and result.exitPos then
        local lockReason = FurnitureRouteScorer.routeAccessRejectReason(self.object, result.exitPos)
        if lockReason then
            print(string.format("[SittingLogic] REJECT stool for %s (route: %s)", self.recordId, lockReason))
            result.usable = false
            sm:transition("idle")
            seatPos = nil
        end
    end
    core.sendGlobalEvent("PC_StoolCheckResult", {
        npc = self.object,
        stool = result.stool,
        usable = result.usable,
        hitPos = result.hitPos,
        facingDirection = result.facingDirection,
        exitPos = result.exitPos,
        zOffset = result.zOffset,
        fwdOffset = result.fwdOffset,
        animationId = result.animationId,
        animationOffset = result.animationOffset,
        geometryReject = result.geometryReject,
        reason = result.reason,
    })
end

function SittingLogic.onConsiderStools(data)
    local entries = data and data.stools
    if not entries or #entries == 0 then
        core.sendGlobalEvent("PC_StoolCheckResult", { npc = self.object, usable = false, reason = "empty_shortlist" })
        return
    end

    local rankCandidates = {}
    for _, entry in ipairs(entries) do
        if entry.stool then
            local approachPos = entry.stool.position
            local profileSlots = FurnitureProfiles.getSlots(entry.stool, "sit")
            if profileSlots and #profileSlots > 0 then
                local slot = profileSlots[entry.slotIndex or 1] or profileSlots[1]
                if slot and slot.approachPos then
                    approachPos = slot.approachPos
                end
            end
            table.insert(rankCandidates, {
                object = entry.stool,
                approachPos = approachPos,
                entry = entry,
            })
        end
    end

    local ranked = FurnitureRouteScorer.rank(self.object, rankCandidates, { interaction = "sit" })
    local anyGeometryReject = false
    local rejectReasons = {}
    local function addRejectReason(stoolObj, reason)
        if not reason then return end
        rejectReasons[#rejectReasons + 1] = string.format("%s:%s",
            tostring(stoolObj and stoolObj.recordId or "unknown"),
            tostring(reason))
    end
    for _, cand in ipairs(ranked) do
        local entry = cand.entry
        local result = SittingLogic.evaluateStool({
            stool = entry.stool,
            barTarget = entry.barTarget,
            tableTarget = entry.tableTarget,
            slotIndex = entry.slotIndex,
        })
        if result.usable and result.exitPos then
            local lockReason = FurnitureRouteScorer.routeAccessRejectReason(self.object, result.exitPos)
            if lockReason then
                print(string.format("[SittingLogic] skip stool %s for %s (route: %s)",
                    tostring(entry.stool and entry.stool.recordId), self.recordId, lockReason))
                addRejectReason(entry.stool, lockReason)
                sm:transition("idle")
                seatPos = nil
            else
                core.sendGlobalEvent("PC_StoolCheckResult", {
                    npc = self.object,
                    stool = result.stool,
                    usable = true,
                    hitPos = result.hitPos,
                    facingDirection = result.facingDirection,
                    exitPos = result.exitPos,
                    zOffset = result.zOffset,
                    fwdOffset = result.fwdOffset,
                    animationId = result.animationId,
                    animationOffset = result.animationOffset,
                })
                return
            end
        elseif result.usable then
            core.sendGlobalEvent("PC_StoolCheckResult", {
                npc = self.object,
                stool = result.stool,
                usable = true,
                hitPos = result.hitPos,
                facingDirection = result.facingDirection,
                exitPos = result.exitPos,
                zOffset = result.zOffset,
                fwdOffset = result.fwdOffset,
                animationId = result.animationId,
                animationOffset = result.animationOffset,
            })
            return
        end
        if result.geometryReject then anyGeometryReject = true end
        addRejectReason(entry.stool, result.reason)
    end

    local reason = "no_usable_stool"
    if #ranked == 0 then
        reason = "no_ranked_candidates"
    elseif #rejectReasons > 0 then
        reason = table.concat(rejectReasons, "; ")
    end
    core.sendGlobalEvent("PC_StoolCheckResult", {
        npc = self.object,
        usable = false,
        geometryReject = anyGeometryReject,
        reason = reason,
        shortlistCount = #entries,
        rankedCount = #ranked,
    })
end

-- NEW: Verification Logic (Checks if animation is missing, then applies masked)
function SittingLogic.onVerifySitState()
    if sm:is("standing_up") then return end -- Don't force sit if standing requested
    
    local anim = require('openmw.animation')
    
    -- Optimized Check: Is it already playing?
    local isPlaying = false
    local ok, res = pcall(function() 
        return anim.isPlaying(self, "sdpvasitting6")
            or anim.isPlaying(self, "pcdbssit5")
            or anim.isPlaying(self, "dbssit5")
            or anim.isPlaying(self, "dbssit6")
            or anim.isPlaying(self, "sitidle1")
            or anim.isPlaying(self, "IdleSit")
            or anim.isPlaying(self, "ChairSit01")
    end)
    if ok and res then isPlaying = true end
    
    if isPlaying then
        -- All good, no action needed
        return
    end
    
    -- Not playing? Re-apply base sit animation (full body) so posture is correct.
    if I.AnimationController then
        local animToPlay = chooseSitAnimation() or 'sitidle1'
        I.AnimationController.playBlendedAnimation(animToPlay, {
            loops = 999,
            forceLoop = true,
            priority = anim.PRIORITY.Movement
        })
    end
end

function SittingLogic.onRecheckStoolFacing(data)
    local checkStool = data and data.stool
    if not checkStool then return end

    local baseAnchor = nil
    local profile = FurnitureProfiles.getProfileForObject(checkStool, "sit")
    local seatType = profile and profile.seatType or nil
    local profileSlots = FurnitureProfiles.getSlots(checkStool, "sit")
    local isBench = checkStool.recordId == "furn_de_p_bench_03"
        or checkStool.recordId == "furn_com_p_bench_01"
        or seatType == "bench"
    local facingDirection
    local actorSpaceOffset = nil

    if isBench then
        local result = nearby.castRay(
            checkStool.position + util.vector3(0, 0, 100),
            checkStool.position,
            { collisionType = nearby.COLLISION_TYPE.World }
        )
        local surfaceZ = (result.hit and result.hitObject == checkStool) and result.hitPos.z or checkStool.position.z
        local orientation, length, _ = determineBenchOrientationAndLength(checkStool)
        local localX = checkStool.rotation * util.vector3(1, 0, 0)
        local localY = checkStool.rotation * util.vector3(0, 1, 0)
        local longAxis
        if orientation == "x" then
            longAxis = (math.abs(localX.x) >= math.abs(localY.x)) and localX or localY
        else
            longAxis = (math.abs(localX.y) >= math.abs(localY.y)) and localX or localY
        end
        longAxis = util.vector3(longAxis.x, longAxis.y, 0)
        local axLen = math.sqrt(longAxis.x * longAxis.x + longAxis.y * longAxis.y)
        if axLen > 0.001 then longAxis = util.vector3(longAxis.x / axLen, longAxis.y / axLen, 0) end

        local halfOff = length / 4
        local centre = util.vector3(checkStool.position.x, checkStool.position.y, surfaceZ)
        local sitA = centre + util.vector3(longAxis.x * halfOff, longAxis.y * halfOff, 0)
        local sitB = centre + util.vector3(-longAxis.x * halfOff, -longAxis.y * halfOff, 0)
        local slotIndex = tonumber(data.slotIndex)
        if slotIndex == 1 then
            baseAnchor = sitA
        elseif slotIndex == 2 then
            baseAnchor = sitB
        else
            baseAnchor = ((self.position - sitA):length() <= (self.position - sitB):length()) and sitA or sitB
        end

        local perpA = util.vector3(-longAxis.y, longAxis.x, 0)
        local perpB = util.vector3(longAxis.y, -longAxis.x, 0)
        if data.tableTarget and Utils.isObjValid(data.tableTarget) then
            facingDirection = pickDirectionToward(baseAnchor, data.tableTarget.position, perpA, perpB)
        else
            local from = baseAnchor + util.vector3(0, 0, 70)
            local scanRange = 400
            local resA = nearby.castRay(from, from + perpA * scanRange, { collisionType = nearby.COLLISION_TYPE.World, ignore = checkStool })
            local resB = nearby.castRay(from, from + perpB * scanRange, { collisionType = nearby.COLLISION_TYPE.World, ignore = checkStool })
            local clearA = resA.hit and (resA.hitPos - from):length() or scanRange
            local clearB = resB.hit and (resB.hitPos - from):length() or scanRange
            facingDirection = (clearA >= clearB) and perpA or perpB
        end
    elseif profileSlots and #profileSlots > 0 then
        local slot = profileSlots[data.slotIndex or 1] or profileSlots[1]
        baseAnchor = slot.pos
        if seatType == "stool" or seatType == "barstool" then
            local result = nearby.castRay(
                checkStool.position + util.vector3(0, 0, 100),
                checkStool.position,
                { collisionType = nearby.COLLISION_TYPE.World }
            )
            if result.hit and result.hitObject == checkStool then
                baseAnchor = result.hitPos
            end
        end
        actorSpaceOffset = actorOffsetForSeatType(slot.actorSpaceOffset, seatType)
        if slot.facing and (seatType == "backed_chair" or seatType == "single_seat_bench") then
            facingDirection = util.vector3(slot.facing.x, slot.facing.y, 0)
        end
    else
        local from = checkStool.position + util.vector3(0, 0, 100)
        local to = checkStool.position
        local result = nearby.castRay(from, to, { collisionType = nearby.COLLISION_TYPE.World })
        if result.hit and result.hitObject == checkStool then
            baseAnchor = result.hitPos
        end
    end

    if not baseAnchor then
        baseAnchor = checkStool.position
    end

    local faceTarget = getFaceTarget(data, profile)
    if not facingDirection and faceTarget then
        local dir = (faceTarget.position - checkStool.position):normalize()
        facingDirection = util.vector3(dir.x, dir.y, 0)
    elseif not facingDirection then
        facingDirection = determineFacingDirection(baseAnchor, nil, checkStool)
    end

    local finalSeatPos = baseAnchor
    finalSeatPos = applyActorSpaceOffset(finalSeatPos, facingDirection, actorSpaceOffset)
    if seatType == "stool" or seatType == "barstool" then
        finalSeatPos = stoolVisualAnchor(finalSeatPos, profile)
    end
    if not (profileSlots and #profileSlots > 0) then
        local fwd = util.vector2(facingDirection.x, facingDirection.y):normalize() * -7
        finalSeatPos = finalSeatPos + util.vector3(fwd.x, fwd.y, -36)
    end

    local exitPos = nil
    if seatType == "backed_chair" or seatType == "single_seat_bench" then
        local approachDir = util.vector3(-facingDirection.x, -facingDirection.y, 0)
        local approachClearance = horizontalClearance(finalSeatPos, approachDir, SEAT_EXIT_OFFSET, checkStool)
        if approachClearance >= CHAIR_APPROACH_CLEARANCE then
            exitPos = floorPosInDirection(
                finalSeatPos + approachDir * SEAT_EXIT_OFFSET,
                finalSeatPos,
                approachDir,
                CHAIR_APPROACH_CLEARANCE
            )
        end
    elseif seatType == "stool" or seatType == "barstool" then
        exitPos = findSeatExitPos(finalSeatPos, false, nil, nil, nil, checkStool)
    end

    local ev = {
        npc = self.object,
        stool = checkStool,
        facingDirection = facingDirection,
        seatAnchor = finalSeatPos,
        exitPos = exitPos,
    }
    local animationId = chooseSitAnimation()
    if animationId then
        ev.animationId = animationId
        ev.animationOffset = FurnitureProfiles.getAnimationOffset(profile, animationId, "sit", checkStool, profileSlots and (profileSlots[data.slotIndex or 1] or profileSlots[1]) or nil)
    end
    if seatType == "stool" or seatType == "barstool" then
        ev.zOffset = 0
        ev.fwdOffset = profile and profile.finalForwardOffset or -7
    elseif profileSlots and #profileSlots > 0 and profile then
        ev.zOffset = profile.finalZOffset
        ev.fwdOffset = profile.finalForwardOffset
    elseif not (profileSlots and #profileSlots > 0) then
        ev.zOffset = 0
        ev.fwdOffset = 0
    end
    core.sendGlobalEvent("PC_StoolFacingResult", ev)
end

function SittingLogic.onSitDownPlease()
    if sm:is("standing_up") or sm:is("seated") then return end
    sm:transition("seated")

    local animToPlay = chooseSitAnimation()

    if not animToPlay then
        print(string.format("[SittingLogic] Warning: Actor %s missing both 'pcdbssit5' and 'sitidle1'.", self.recordId))
        return
    end

    -- Using custom Interface expected from original mod
    if I.AnimationController then
        print(string.format("[SittingLogic] Playing '%s' (full body) on %s", animToPlay, self.recordId))
        I.AnimationController.playBlendedAnimation(animToPlay, {
            loops = 999,
            forceLoop = true,
            priority = anim.PRIORITY.Movement
        })
    else
        print(string.format("[SittingLogic] ERROR: I.AnimationController missing on %s", self.recordId))
    end
end

function SittingLogic.stopSittingAnim()
    if anim and anim.cancel then
        pcall(function()
            anim.cancel(self, 'sdpvasitting6')
            anim.cancel(self, 'pcdbssit5')
            anim.cancel(self, 'dbssit5')
            anim.cancel(self, 'dbssit6')
            anim.cancel(self, 'sitidle1')
        end)
    end
end

function SittingLogic.onCancelTravelToSeat()
    if ai and ai.filterPackages and seatPos then
        ai.filterPackages(function(pkg)
            if pkg and pkg.type == 'Travel' and pkg.destPosition then
                if (pkg.destPosition - seatPos):length() < 150 then return false end
            end
            return true
        end)
    end
    if sm:is("walking_to_seat") then
        sm:transition("idle")
    end
end

function SittingLogic.requestStand(reason)
    if sm:is("standing_up") or sm:is("idle") then return end
    sm:transition("standing_up")
    SittingLogic.stopSittingAnim()
    
    if ai and ai.filterPackages and seatPos then
        ai.filterPackages(function(pkg)
            if pkg and pkg.type == 'Travel' and pkg.destPosition then
                if (pkg.destPosition - seatPos):length() < 50 then return false end
            end
            return true
        end)
    end
    core.sendGlobalEvent('PC_CancelSittingForNpc', { npc = self.object, reason = reason })
end

function SittingLogic.onStandUpPlease()
    SittingLogic.stopSittingAnim()
    sm:transition("idle")
    aiPollTimer = 0
end

function SittingLogic.onDied()
    SittingLogic.requestStand('died')
end

function SittingLogic.isSitting()
    return sm:is("seated")
end

function SittingLogic.getState()
    return sm:get()
end

-- Update Loop
function SittingLogic.update(dt)
    if sm:is("seated") then self.controls.yawChange = 0 end

    if (sm:is("seated") or sm:is("walking_to_seat")) and not sm:is("standing_up") then
        aiPollTimer = aiPollTimer + dt
        if aiPollTimer < AI_POLL_INTERVAL then return end
        aiPollTimer = 0

        if ai and ai.getTargets then
            local followTargets = ai.getTargets("Follow")
            if followTargets and #followTargets > 0 then SittingLogic.requestStand('follow') end
            local escortTargets = ai.getTargets("Escort")
            if escortTargets and #escortTargets > 0 then SittingLogic.requestStand('escort') end
        end

        if not sm:is("standing_up") and ai and ai.getActivePackage then
            local pkg = ai.getActivePackage()
            if pkg then
                 if pkg.type == "Combat" or pkg.type == "Pursue" then SittingLogic.requestStand('combat')
                 elseif pkg.type == "Follow" or pkg.type == "Escort" then SittingLogic.requestStand('follow_or_escort')
                 elseif pkg.type == "Travel" then
                     if not sm:is("walking_to_seat") and not (seatPos and pkg.destPosition and (pkg.destPosition - seatPos):length() < 50) then
                         SittingLogic.requestStand('other_travel')
                     end
                 elseif pkg.type ~= "Wander" then SittingLogic.requestStand('other_ai_package') end
            end
        end
    end
    sm:update(dt)
end

return SittingLogic
