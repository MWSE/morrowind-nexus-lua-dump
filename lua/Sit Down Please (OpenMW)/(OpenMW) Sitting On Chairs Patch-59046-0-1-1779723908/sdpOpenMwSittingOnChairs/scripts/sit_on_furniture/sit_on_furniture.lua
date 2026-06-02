local self   = require('openmw.self')
local anim   = require('openmw.animation')
local nearby = require('openmw.nearby')
local input  = require('openmw.input')
local camera = require('openmw.camera')
local util   = require('openmw.util')
local core   = require('openmw.core')
local types  = require('openmw.types')
local ui     = require('openmw.ui')

local SITTABLE_PATTERNS = {
    "chair", "stool", "bench", "seat", "throne",
    "furn_com_rm_barstool", "furn_com_rm_chair", "furn_com_rm_bench",
    "furn_com_pm_stool",    "furn_de_r_bench",   "furn_de_p_bench",
    "furn_nord_bench",      "furn_com_bench",    "furn_de_p_chair",
    "com_m_chr",
}

local CUSHION_PATTERNS = {
    "cushion", "furn_de_cushion",
}

local BLACKLIST = {
    ["furn_com_rm_bar_counter"] = true,
}

local SIT_PIVOT_OFFSET = {
    ["furn_de_p_chair_02"] = 1.2,
    ["AB_Furn_DeMidChair"] = 1.2,
    ["furn_de_r_chair_03"] = 1.2,
}

local SIT_PIVOT_OFFSET_FALLBACK = {
    ["furn_com_rm_bar"] = 38,
    ["AB_Furn_DeMidTable02"] = 38,	
    ["furn_de_r_table_07"] = 38,	
    default             = 26,
}

local SIT_ANIM        = "idle6"
local SIT_ANIM_CUSHION = "idle4"
local SIT_LOOPS       = 999
local SIT_PRIORITY    = anim.PRIORITY.Scripted

local isSitting        = false
local sitAnimStarted   = false
local eWasDown         = false
local currentFurniture = nil
local originalChairPos = nil
local originalChairRot = nil
local sitStartTimer    = 0
local SIT_ANIM_WINDOW  = 0.05
local currentSitAnim   = SIT_ANIM
local fatigueTimer = 0
local lastOccupiedSeatMessageAt = -100

local pendingFurniture  = nil
local cameraSwitchTimer = 0
local CAMERA_SWITCH_WAIT = 0.08   
local returnToFirstPerson = false

local OCCUPIED_SEAT_VERTICAL_LIMIT = 76
local OCCUPIED_SEAT_RADIUS = {
    default = 92,
    stool = 64,
    cushion = 72,
    bench = 150,
}

local OCCUPIED_SEAT_ANIMS = {
    "sdpvasitting6",
    "sdpvasitting5",
    "sdpvasitting4",
    "sdpvasitting3",
    "sdpvasitting2",
    "sitidle1",
    "SitIdle1",
}

local function isSittable(recordId)
    if not recordId then return false end
    local lower = recordId:lower()
    if BLACKLIST[lower] then return false end
    for _, p in ipairs(SITTABLE_PATTERNS) do
        if lower:find(p, 1, true) then return true end
    end
    for _, p in ipairs(CUSHION_PATTERNS) do
        if lower:find(p, 1, true) then return true end
    end
    return false
end

local function isCushion(recordId)
    if not recordId then return false end
    local lower = recordId:lower()
    for _, p in ipairs(CUSHION_PATTERNS) do
        if lower:find(p, 1, true) then return true end
    end
    return false
end

local function isActor(obj)
    if not obj or not types.Actor or not types.Actor.objectIsInstance then return false end
    local ok, result = pcall(types.Actor.objectIsInstance, obj)
    return ok and result == true
end

local function actorIsPlayingSeatAnimation(actor)
    if not actor then return false end
    for _, name in ipairs(OCCUPIED_SEAT_ANIMS) do
        local ok, playing = pcall(anim.isPlaying, actor, name)
        if ok and playing == true then return true end
    end
    return false
end

local function horizontalDistance(a, b)
    if not (a and b) then return math.huge end
    local dx = (a.x or 0) - (b.x or 0)
    local dy = (a.y or 0) - (b.y or 0)
    return math.sqrt(dx * dx + dy * dy)
end

local function occupiedSeatRadius(recordId)
    local lower = tostring(recordId or ""):lower()
    if lower:find("bench", 1, true) then return OCCUPIED_SEAT_RADIUS.bench end
    if lower:find("stool", 1, true) or lower:find("barstool", 1, true) then return OCCUPIED_SEAT_RADIUS.stool end
    if isCushion(lower) then return OCCUPIED_SEAT_RADIUS.cushion end
    return OCCUPIED_SEAT_RADIUS.default
end

local function seatIsClaimedByActor(furniture)
    if not (furniture and furniture.position) then return false, nil end
    local radius = occupiedSeatRadius(furniture.recordId)
    for _, actor in ipairs(nearby.actors) do
        if actor and actor ~= self.object and actor.position and actorIsPlayingSeatAnimation(actor) then
            local vertical = math.abs((actor.position.z or 0) - (furniture.position.z or 0))
            if vertical <= OCCUPIED_SEAT_VERTICAL_LIMIT and horizontalDistance(actor.position, furniture.position) <= radius then
                return true, actor
            end
        end
    end
    return false, nil
end

local function showOccupiedSeatMessage(actor)
    local now = core.getRealTime()
    if now - lastOccupiedSeatMessageAt < 1.5 then return end
    lastOccupiedSeatMessageAt = now
    ui.showMessage("That seat is occupied.", { showInDialogue = false })
end

local function getFallbackOffset(recordId)
    if not recordId then return SIT_PIVOT_OFFSET_FALLBACK.default end
    local lower = recordId:lower()
    for pattern, h in pairs(SIT_PIVOT_OFFSET_FALLBACK) do
        if pattern ~= "default" and lower:find(pattern, 1, true) then
            return h
        end
    end
    return SIT_PIVOT_OFFSET_FALLBACK.default
end

local function getObjectYaw(obj)
    local forward = obj.rotation:apply(util.vector3(0, 1, 0))
    return math.atan2(forward.x, forward.y)
end

local MAX_PIERCES = 4

local function castPiercingRay(from, to)
    local current = from
    for _ = 1, MAX_PIERCES do
        local result = nearby.castRenderingRay(current, to)
        if not result or not result.hit then return nil end
        if isActor(result.hitObject) and result.hitObject ~= self.object then
            return nil, result.hitObject
        end
        if result.hitObject and isSittable(result.hitObject.recordId) then
            return result.hitObject, result.hitPos
        end
        local dir = to - current
        local len = dir:length()
        if len < 1 then return nil end
        local step = (result.hitPos - current):length() + 2
        if step >= len then return nil end
        current = current + (dir / len) * step
    end
    return nil
end

local FLAT_RAYS = { { z = 10 }, { z = 30 }, { z = 55 } }
local PITCHED_RAYS = {
    { pitch = math.rad(-10) },
    { pitch = math.rad(-20) },
    { pitch = math.rad(-30) },
}
local EYE_HEIGHT   = 60
local RAY_DISTANCE = 200

local function getFurnitureAhead()
    local yaw     = camera.getYaw()
    local camPos  = camera.getPosition()
    local charPos = self.position
    local eyePos  = charPos + util.vector3(0, 0, EYE_HEIGHT)
    local camOffset = util.vector3(camPos.x - eyePos.x, camPos.y - eyePos.y, 0)
    local offsetLen = camOffset:length()
    local origin
    if offsetLen > 5 then
        local shift = math.min(offsetLen, 30)
        origin = eyePos + (camOffset / offsetLen) * shift
    else
        origin = eyePos
    end

    local flatDir = util.vector3(math.sin(yaw), math.cos(yaw), 0)
    for _, ray in ipairs(FLAT_RAYS) do
        local from = origin + util.vector3(0, 0, ray.z - EYE_HEIGHT)
        local obj, blockedByActor = castPiercingRay(from, from + flatDir * RAY_DISTANCE)
        if obj then return obj end
        if blockedByActor then return nil, blockedByActor end
    end

    for _, ray in ipairs(PITCHED_RAYS) do
        local cp  = math.cos(ray.pitch)
        local dir = util.vector3(
            math.sin(yaw) * cp, math.cos(yaw) * cp, math.sin(ray.pitch))
        local obj, blockedByActor = castPiercingRay(origin, origin + dir * RAY_DISTANCE)
        if obj then return obj end
        if blockedByActor then return nil, blockedByActor end
    end

    return nil
end

local SEAT_PROBE_START  = 150
local SEAT_PROBE_END    = 10
local SEAT_PROBE_RADIUS = 16
local SEAT_MAX_PIERCES  = 10
local SEAT_CLUSTER_DIST = 6
local FATIGUE_TICK_RATE = 0.5
local FATIGUE_TICK_AMOUNT = 10

local function findSeatSurface(chairPos, furniture)
    local r = SEAT_PROBE_RADIUS
    local offsets = {
        util.vector3( 0,  0, 0), util.vector3( r,  0, 0), util.vector3(-r,  0, 0),
        util.vector3( 0,  r, 0), util.vector3( 0, -r, 0), util.vector3( r,  r, 0),
        util.vector3(-r,  r, 0), util.vector3( r, -r, 0), util.vector3(-r, -r, 0),
    }

    local allZHits = {}

    for _, off in ipairs(offsets) do
        local bx = chairPos.x + off.x
        local by = chairPos.y + off.y
        local stopZ   = chairPos.z - SEAT_PROBE_END
        local current = util.vector3(bx, by, chairPos.z + SEAT_PROBE_START)
        local target  = util.vector3(bx, by, stopZ)

        for _ = 1, SEAT_MAX_PIERCES do
            local res = nearby.castRenderingRay(current, target)
            if not res or not res.hit then break end
            local hitZ = res.hitPos.z
            if res.hitObject == furniture or isSittable(res.hitObject and res.hitObject.recordId) then
                table.insert(allZHits, hitZ)
            end
            if hitZ <= stopZ + 2 then break end
            current = util.vector3(bx, by, hitZ - 2)
        end
    end

    if #allZHits == 0 then return nil end
    table.sort(allZHits)

    local clusters = {}
    local cur = { zMin = allZHits[1], zMax = allZHits[1], count = 1 }
    for i = 2, #allZHits do
        if allZHits[i] - cur.zMax <= SEAT_CLUSTER_DIST then
            cur.zMax = allZHits[i]; cur.count = cur.count + 1
        else
            table.insert(clusters, cur)
            cur = { zMin = allZHits[i], zMax = allZHits[i], count = 1 }
        end
	end   
    table.insert(clusters, cur)

    local best = clusters[1]
    for i = 2, #clusters do
        local c = clusters[i]
        if c.count > best.count or (c.count == best.count and c.zMax < best.zMax) then
            best = c
        end
    end

    local bestZ = best.zMax
    local diff  = bestZ - chairPos.z

    local zStr, cStr = "", ""
    for i, z in ipairs(allZHits) do
        zStr = zStr .. string.format("%.1f", z)
        if i < #allZHits then zStr = zStr .. " " end
    end
    for i, c in ipairs(clusters) do
        cStr = cStr .. string.format("[%.1f-%.1f x%d]", c.zMin, c.zMax, c.count)
        if i < #clusters then cStr = cStr .. " " end
    end
    print(string.format(
        "[sit] seat Z=%.1f  pivot Z=%.1f  diff=%.1f  hits=[%s]  clusters=%s",
        bestZ, chairPos.z, diff, zStr, cStr))
    print(string.format("[sit] TIP: if correct, add SIT_PIVOT_OFFSET[\"%s\"] = %.1f",
        furniture.recordId or "?", diff))

    return bestZ
end

local function findObstructionAbove(chairPos, furniture)
    local current = util.vector3(chairPos.x, chairPos.y, chairPos.z + SEAT_PROBE_START)
    local target  = util.vector3(chairPos.x, chairPos.y, chairPos.z + 5)
    for _ = 1, SEAT_MAX_PIERCES do
        local res = nearby.castRenderingRay(current, target)
        if not res or not res.hit then return nil end
        local rid = res.hitObject and res.hitObject.recordId
        if res.hitObject ~= furniture and not isSittable(rid) then
            return res.hitPos.z
        end
        local hitZ = res.hitPos.z
        if hitZ <= chairPos.z + 7 then return nil end
        current = util.vector3(chairPos.x, chairPos.y, hitZ - 2)
    end
    return nil
end

local PUSH_PROBE_COUNT = 12
local PUSH_PROBE_DIST  = 80
local PUSH_STRENGTH    = 15

local function computeSitPushOffset(basePos, furniture)
    local pushX, pushY, totalW = 0, 0, 0
    for i = 0, PUSH_PROBE_COUNT - 1 do
        local angle = (i / PUSH_PROBE_COUNT) * (2 * math.pi)
        local dx, dy = math.sin(angle), math.cos(angle)
        local res = nearby.castRenderingRay(basePos,
            util.vector3(basePos.x + dx * PUSH_PROBE_DIST,
                         basePos.y + dy * PUSH_PROBE_DIST, basePos.z))
        if res.hit and res.hitObject ~= furniture then
            local hdist = math.sqrt(
                (res.hitPos.x - basePos.x)^2 + (res.hitPos.y - basePos.y)^2)
            if hdist < PUSH_PROBE_DIST then
                local w = 1 - hdist / PUSH_PROBE_DIST
                pushX = pushX - dx * w; pushY = pushY - dy * w; totalW = totalW + w
            end
        end
    end
    if totalW < 0.001 then return util.vector3(0, 0, 0) end
    local len = math.sqrt(pushX^2 + pushY^2)
    if len < 0.001 then return util.vector3(0, 0, 0) end
    local scale = PUSH_STRENGTH * math.min(1, totalW / (PUSH_PROBE_COUNT * 0.3))
    return util.vector3(pushX / len * scale, pushY / len * scale, 0)
end

local CHAIR_PUSH_PROBE_COUNT = 8
local CHAIR_PUSH_PROBE_DIST  = 90
local CHAIR_PUSH_MIN_DIST    = 45
local CHAIR_PUSH_MAX_MOVE    = 22
local CHAIR_PUSH_STEP        = 2
local CHAIR_PUSH_MAX_ITER    = 15
local CHAIR_PUSH_ORIGIN_DIST = 100
local CHAIR_PUSH_PROBE_ZS    = { -10, 10, 25, 40, 55, 70, 85 }

local function computeChairPushVector(chairPos, furniture)
    local repX, repY, totalW = 0, 0, 0
    for i = 0, CHAIR_PUSH_PROBE_COUNT - 1 do
        local angle = (i / CHAIR_PUSH_PROBE_COUNT) * (2 * math.pi)
        local dx, dy = math.sin(angle), math.cos(angle)
        local closestDist, didHit = CHAIR_PUSH_PROBE_DIST, false
        for _, dz in ipairs(CHAIR_PUSH_PROBE_ZS) do
            local pivot = util.vector3(chairPos.x, chairPos.y, chairPos.z + dz)
            local far   = util.vector3(
                chairPos.x + dx * CHAIR_PUSH_ORIGIN_DIST,
                chairPos.y + dy * CHAIR_PUSH_ORIGIN_DIST,
                chairPos.z + dz)
            for _, ray in ipairs({ { pivot, far }, { far, pivot } }) do
                local res = nearby.castRenderingRay(ray[1], ray[2])
                if res.hit and res.hitObject and res.hitObject ~= furniture
                   and not isSittable(res.hitObject.recordId) then
                    local dist = math.max(math.sqrt(
                        (res.hitPos.x - chairPos.x)^2 +
                        (res.hitPos.y - chairPos.y)^2), 2)
					if dist < closestDist then closestDist = dist; didHit = true end
				end
			end
		end
        if didHit and closestDist < CHAIR_PUSH_MIN_DIST then
            local w = 1 - closestDist / CHAIR_PUSH_MIN_DIST
            repX = repX - dx * w; repY = repY - dy * w; totalW = totalW + w
        end
    end
    if totalW < 0.001 then return util.vector3(0, 0, 0) end
    local len = math.sqrt(repX^2 + repY^2)
    if len < 0.001 then return util.vector3(0, 0, 0) end
    local scale = CHAIR_PUSH_MAX_MOVE * math.min(1, totalW / (CHAIR_PUSH_PROBE_COUNT * 0.25))
    return util.vector3(repX / len * scale, repY / len * scale, 0)
end

local function resolveChairPosition(furniture)
    local original = furniture.position
    local pos = original
    for iter = 1, CHAIR_PUSH_MAX_ITER do
        local push = computeChairPushVector(pos, furniture)
        if push:length() < 0.5 then
            break
        end
        local stepLen = math.min(push:length(), CHAIR_PUSH_STEP)
        pos = pos + (push / push:length()) * stepLen
        local delta = pos - original
        if math.sqrt(delta.x^2 + delta.y^2) >= CHAIR_PUSH_MAX_MOVE then
            break
        end
    end
    return pos
end

local function computeSeatZ(resolvedChairPos, furniture)
    local rid = furniture.recordId

    local calibrated = rid and SIT_PIVOT_OFFSET[rid]
    if calibrated then
        local seatZ = resolvedChairPos.z + calibrated
		return seatZ			
    end

    local seatZ = findSeatSurface(resolvedChairPos, furniture)
    if seatZ then return seatZ end

    local fallback = getFallbackOffset(rid)
    seatZ = resolvedChairPos.z + fallback

    local blockZ = findObstructionAbove(resolvedChairPos, furniture)
    if blockZ and seatZ >= blockZ - 2 then
        seatZ = blockZ - 28
    end
    return seatZ
end

local function startSitting(furniture)
    currentFurniture = furniture
    originalChairPos = furniture.position
    originalChairRot = furniture.rotation

    currentSitAnim = isCushion(furniture.recordId) and SIT_ANIM_CUSHION or SIT_ANIM

    local resolvedChairPos = resolveChairPosition(furniture)
    local chairYaw         = getObjectYaw(furniture)
    local seatZ            = computeSeatZ(resolvedChairPos, furniture)

    local basePos    = util.vector3(resolvedChairPos.x, resolvedChairPos.y, seatZ)
    local pushOffset = computeSitPushOffset(basePos, furniture)
    local sitPos     = basePos + pushOffset

    core.sendGlobalEvent('SitTeleport', {
        position     = sitPos,
        yaw          = chairYaw,
        furniture    = furniture,
        furniturePos = resolvedChairPos,
    })

    isSitting      = true
	self.object:sendEvent('FPV_SetEyeDropOverride', { offset = -60 })
    sitAnimStarted = false
    sitStartTimer  = SIT_ANIM_WINDOW
end

local function onSitAnimStart(_data)
    if not isSitting then return end
    anim.playBlended(self, currentSitAnim, { loops = SIT_LOOPS, priority = SIT_PRIORITY })
    sitAnimStarted = true
end

local function stopSitting()
    anim.cancel(self, currentSitAnim)
    isSitting = false; sitAnimStarted = false
	fatigueTimer = 0
	self.object:sendEvent('FPV_SetEyeDropOverride', { offset = 0 })
    if returnToFirstPerson then
        camera.setMode(camera.MODE.FirstPerson)
        returnToFirstPerson = false
    end

    if currentFurniture and originalChairPos then
        core.sendGlobalEvent('SitRestoreChair', {
            furniture = currentFurniture,
            position  = originalChairPos,
            rotation  = originalChairRot,
        })
    end
    currentFurniture = nil; originalChairPos = nil; originalChairRot = nil
end

local function trySit(furniture)
    if camera.getMode() == camera.MODE.FirstPerson then
        returnToFirstPerson = true
        camera.setMode(camera.MODE.ThirdPerson)
        pendingFurniture  = furniture
        cameraSwitchTimer = CAMERA_SWITCH_WAIT
    else
        startSitting(furniture)
    end
end

local function onFrame(dt)
    if pendingFurniture then
        cameraSwitchTimer = cameraSwitchTimer - dt
        if cameraSwitchTimer <= 0 then
            startSitting(pendingFurniture)
            pendingFurniture = nil
        end
        return
    end

    if sitStartTimer > 0 then sitStartTimer = sitStartTimer - dt end

    if isSitting then
		fatigueTimer = fatigueTimer + dt
        if fatigueTimer >= FATIGUE_TICK_RATE then
            fatigueTimer = fatigueTimer - FATIGUE_TICK_RATE
			local fatigue = types.Actor.stats.dynamic.fatigue(self)
            fatigue.current = math.min(fatigue.current + FATIGUE_TICK_AMOUNT, fatigue.base)
        end
        if sitAnimStarted and sitStartTimer <= 0
           and not anim.isPlaying(self, currentSitAnim) then
            anim.playBlended(self, currentSitAnim, { loops = SIT_LOOPS, priority = SIT_PRIORITY })
        end
        self.controls.movement     = 0
        self.controls.sideMovement = 0
        self.controls.jump         = false
    end

    local eDown = input.isActionPressed(input.ACTION.Activate)
    if eDown and not eWasDown then
        if isSitting then
            stopSitting()
        else
            local furniture = getFurnitureAhead()
            if furniture then
                local claimed, actor = seatIsClaimedByActor(furniture)
                if claimed then
                    showOccupiedSeatMessage(actor)
                else
                    trySit(furniture)
                end
            end
        end
    end
    eWasDown = eDown
end

return {
    engineHandlers = { onFrame = onFrame },
    eventHandlers  = { SitAnimStart = onSitAnimStart },
}
