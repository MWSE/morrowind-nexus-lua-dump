-- ============================================================
-- Spells of Morrowind: Haggle-light and Travel Illumination — PLAYER Script
-- Pure-container Haggle-light rewrite
--
-- UPDATES:
-- - Added light position (Left/Right) support with live slot updates
-- - Added slot refresh event handler for position changes
-- - Added UI mode detection to pause attach-light movement during UI
-- - Added post-UI cleanup to handle ghost pickup via inventory drag
-- ============================================================

local self   = require('openmw.self')
local util   = require('openmw.util')
local core   = require('openmw.core')
local types  = require('openmw.types')
local nearby = require('openmw.nearby')
local I      = require('openmw.interfaces')

-- ============================================================
-- Helper Functions
-- ============================================================

local function lerpVector3(a, b, t)
    return util.vector3(
        a.x + (b.x - a.x) * t,
        a.y + (b.y - a.y) * t,
        a.z + (b.z - a.z) * t
    )
end

local function debugLog(msg)
    -- print("[AI Player] " .. tostring(msg))
end

-- ============================================================
-- Constants
-- ============================================================

local FLOAT_HEIGHT        = 160
local ORBIT_RADIUS        = 75
local MOVE_SPEED          = 300
local WAYPOINT_SKIP       = 60
local BLOCK_FRAMES        = 15
local CEILING_MARGIN      = 25
local Z_LERP_SPEED        = 150
local POSITION_LERP_SPEED = 8.0
local PROBE_RADIUS        = 25
local ESCAPE_STEP         = 20
local ESCAPE_MAX          = 80
local ESCAPE_THRESHOLD    = 0.95

local HAGGLE_IDLE_MOVE_EPS = 2.0

-- ============================================================
-- Per-orb state
-- MOVED HERE so pollUIMode can reference attachLantern
-- ============================================================

local function newOrbState()
    return {
        active      = false,
        groundPos   = nil,
        currentSlot = 1,
        blockedFor  = 0,
        currentZ    = FLOAT_HEIGHT,

        freezeRotWhileIdle = false,
        anchorRotation     = nil,
        lastPlayerPos      = nil,
        smoothedPos        = nil,
    }
end

local animateLantern = newOrbState()
local attachLantern  = newOrbState()
local lightWisp      = newOrbState()
local haggleLantern  = newOrbState()

-- ============================================================
-- UI State tracking
-- I.UI is player-only; we poll it every frame and notify the
-- global script when the mode changes so it can gate teleports.
-- ============================================================

local uiModeWas   = nil
local uiModeNow   = nil
local attachWasActiveWhenUiOpened = false
local pendingUIClosedCheck = false   -- NEW: flag to defer cleanup until next frame

local function pollUIMode()
    local newMode = I.UI.getMode()

    if newMode == uiModeWas then
        -- No change in UI state, but check if we have a pending cleanup request
        if pendingUIClosedCheck and uiModeNow == nil then
            -- UI is confirmed closed and we had a pending check — send it now
            core.sendGlobalEvent('ArcaneIllumination_AttachUIClosed', {})
            debugLog("UI confirmed closed, sending deferred pickup check")
            pendingUIClosedCheck = false
        end
        return
    end

    local wasOpen = (uiModeWas ~= nil)
    local isOpen  = (newMode  ~= nil)
    uiModeWas = newMode
    uiModeNow = newMode

    core.sendGlobalEvent('ArcaneIllumination_UiStateChanged', { uiOpen = isOpen })
    debugLog("UI mode changed: " .. tostring(newMode) .. " (open=" .. tostring(isOpen) .. ")")

    if isOpen and not wasOpen then
        attachWasActiveWhenUiOpened = attachLantern.active
    end

    if not isOpen and wasOpen then
        -- UI just closed
        if attachWasActiveWhenUiOpened then
            -- Defer the actual check until next frame to ensure engine has fully committed the item move
            pendingUIClosedCheck = true
            debugLog("UI closed while attach was active — deferring pickup check to next frame")
        end
        attachWasActiveWhenUiOpened = false
    end
end

-- ============================================================
-- Slot positions (local coordinates relative to player)
-- ============================================================

local SLOTS = {
    util.vector3(-0.5,  1.0, 0),
    util.vector3( 0.5,  1.0, 0),
    util.vector3(-1.0,  0.0, 0),
    util.vector3( 0.0, -1.0, 0),
}
for i, s in ipairs(SLOTS) do
    SLOTS[i] = util.vector3(s.x, s.y, 0):normalize()
end

local SLOTS_MIRRORED = {}
for i, s in ipairs(SLOTS) do
    SLOTS_MIRRORED[i] = util.vector3(-s.x, s.y, 0):normalize()
end

local PROBE_OFFSETS = {
    util.vector3(0,             0,            0),
    util.vector3( PROBE_RADIUS, 0,            0),
    util.vector3(-PROBE_RADIUS, 0,            0),
    util.vector3(0,             PROBE_RADIUS, 0),
    util.vector3(0,            -PROBE_RADIUS, 0),
}

-- ============================================================
-- SETTINGS CACHE
-- ============================================================

local currentLightPosition = "Left"

local function updateLightPositionSetting(newPosition)
    if newPosition and newPosition ~= currentLightPosition then
        currentLightPosition = newPosition
        debugLog("Light position updated to: " .. newPosition)
    end
end

local function getCurrentSlots()
    if currentLightPosition:lower() == "right" then
        return SLOTS_MIRRORED
    else
        return SLOTS
    end
end

-- ============================================================
-- Navmesh helpers
-- ============================================================

local NAV_FLAGS = nearby.NAVIGATOR_FLAGS.Walk
                + nearby.NAVIGATOR_FLAGS.Swim
                + nearby.NAVIGATOR_FLAGS.OpenDoor

local function getAgentBounds()
    return types.Actor.getPathfindingAgentBounds(self)
end

local function snapToNavmesh(pos)
    return nearby.findNearestNavMeshPosition(pos, {
        includeFlags          = NAV_FLAGS,
        agentBounds           = getAgentBounds(),
        searchAreaHalfExtents = util.vector3(200, 200, 200),
    }) or pos
end

local function stepAlongNavmesh(currentPos, targetPos, moveSpeed)
    local directDist = (targetPos - currentPos):length()

    if directDist > 600 then
        return targetPos
    end

    local status, path = nearby.findPath(currentPos, targetPos, {
        includeFlags = NAV_FLAGS,
        agentBounds  = getAgentBounds(),
    })

    if path and #path > 0 then
        for i = 1, #path do
            local toWp = path[i] - currentPos
            local dist = toWp:length()
            if dist > WAYPOINT_SKIP then
                if dist <= moveSpeed then return path[i] end
                return currentPos + toWp:normalize() * moveSpeed
            end
        end
        return path[1]
    end

    local toTarget = targetPos - currentPos
    local dist     = toTarget:length()

    local rayFrom = currentPos + util.vector3(0, 0, 20)
    local rayTo   = targetPos  + util.vector3(0, 0, 20)
    local hit     = nearby.castRay(rayFrom, rayTo, { ignore = self })

    if not hit or not hit.hitPos or (hit.hitPos - rayTo):length() < 10 then
        if dist <= moveSpeed then return targetPos end
        return currentPos + toTarget:normalize() * moveSpeed
    end

    if dist <= (moveSpeed * 0.3) then return targetPos end
    return currentPos + toTarget:normalize() * (moveSpeed * 0.3)
end

-- ============================================================
-- Slot helpers
-- ============================================================

local function getSlotGroundPos(slotLocalDir, rotationOverride)
    local rot      = rotationOverride or self.rotation
    local worldDir = rot * slotLocalDir
    local flatDir  = util.vector3(worldDir.x, worldDir.y, 0):normalize()
    return snapToNavmesh(self.position + flatDir * ORBIT_RADIUS)
end

local function isSlotClear(slotGroundPos)
    local snapped = snapToNavmesh(slotGroundPos)
    local from    = self.position + util.vector3(0, 0, 85)
    local to      = snapped + util.vector3(0, 0, FLOAT_HEIGHT)
    local hit     = nearby.castRay(from, to, { ignore = self })
    return not (hit and hit.hitPos)
end

local function pickBestSlot(currentSlot, rotationOverride)
    local slots = getCurrentSlots()
    if isSlotClear(getSlotGroundPos(slots[currentSlot], rotationOverride)) then
        return currentSlot
    end
    for i = 1, #slots do
        if isSlotClear(getSlotGroundPos(slots[i], rotationOverride)) then
            return i
        end
    end
    return currentSlot
end

-- ============================================================
-- Ceiling probe + horizontal escape
-- ============================================================

local function probeHeadroom(groundPos, desiredZ)
    local minZ = desiredZ
    for _, offset in ipairs(PROBE_OFFSETS) do
        local probe   = groundPos + offset
        local rayFrom = probe + util.vector3(0, 0, 25)
        local rayTo   = probe + util.vector3(0, 0, desiredZ + CEILING_MARGIN + 10)
        local hit     = nearby.castRay(rayFrom, rayTo, { ignore = self })
        if hit and hit.hitPos then
            local headroom = hit.hitPos.z - groundPos.z - CEILING_MARGIN
            minZ = math.min(minZ, math.max(10, headroom))
        end
    end
    return minZ
end

local function getAdaptivePosition(groundPos, desiredZ)
    local safeZ = probeHeadroom(groundPos, desiredZ)

    if safeZ >= desiredZ * ESCAPE_THRESHOLD then
        return groundPos, safeZ
    end

    local outDir = util.vector3(
        groundPos.x - self.position.x,
        groundPos.y - self.position.y,
        0)
    if outDir:length() < 1 then return groundPos, safeZ end
    outDir = outDir:normalize()

    local pushed = groundPos
    for _ = 1, math.floor(ESCAPE_MAX / ESCAPE_STEP) do
        local candidate  = snapToNavmesh(pushed + outDir * ESCAPE_STEP)
        local candidateZ = probeHeadroom(candidate, desiredZ)
        pushed = candidate
        safeZ  = candidateZ
        if candidateZ >= desiredZ * ESCAPE_THRESHOLD then break end
    end

    return pushed, safeZ
end

-- ============================================================
-- Core per-frame orb logic
-- ============================================================

local function advanceOrb(orb, eventName, dt)
    local step = MOVE_SPEED * math.max(dt, 0.001)

    local rotForSlots = self.rotation

    if orb.freezeRotWhileIdle then
        if not orb.lastPlayerPos  then orb.lastPlayerPos  = self.position end
        if not orb.anchorRotation then orb.anchorRotation = self.rotation end

        local movedDist   = (self.position - orb.lastPlayerPos):length()
        local playerMoved = movedDist > HAGGLE_IDLE_MOVE_EPS

        if playerMoved then
            orb.lastPlayerPos  = self.position
            orb.anchorRotation = self.rotation
        end
        rotForSlots = orb.anchorRotation or self.rotation
    end

    local slots      = getCurrentSlots()
    local slotGround = getSlotGroundPos(slots[orb.currentSlot], rotForSlots)

    if isSlotClear(slotGround) then
        orb.blockedFor = 0
    else
        orb.blockedFor = orb.blockedFor + 1
        if orb.blockedFor >= BLOCK_FRAMES then
            local newSlot = pickBestSlot(orb.currentSlot, rotForSlots)
            if newSlot ~= orb.currentSlot then
                orb.currentSlot = newSlot
                orb.blockedFor  = 0
                slotGround      = getSlotGroundPos(slots[orb.currentSlot], rotForSlots)
            end
        end
    end

    if not orb.groundPos then
        orb.groundPos = snapToNavmesh(self.position)
    end

    local nextGround = orb.groundPos
    local dist = (slotGround - orb.groundPos):length()
    if dist > 5 then
        nextGround = stepAlongNavmesh(orb.groundPos, slotGround, step)
    end

    local playerDist = (nextGround - self.position):length()
    if playerDist < 40 then
        local pushDir = (nextGround - self.position):normalize()
        nextGround = snapToNavmesh(self.position + pushDir * 40)
    end

    orb.groundPos = nextGround

    local safeGround, targetZ = getAdaptivePosition(orb.groundPos, FLOAT_HEIGHT)

    local zDiff = targetZ - orb.currentZ
    local zStep = Z_LERP_SPEED * math.max(dt, 0.001)
    if math.abs(zDiff) <= zStep then
        orb.currentZ = targetZ
    else
        orb.currentZ = orb.currentZ + (zDiff > 0 and zStep or -zStep)
    end

    local floatPos = safeGround + util.vector3(0, 0, orb.currentZ)

    if not orb.smoothedPos then
        orb.smoothedPos = floatPos
    else
        local lerpFactor = math.min(POSITION_LERP_SPEED * math.max(dt, 0.001), 1.0)
        orb.smoothedPos = lerpVector3(orb.smoothedPos, floatPos, lerpFactor)
    end

    local dir = (orb.smoothedPos - self.position):normalize()

    core.sendGlobalEvent(eventName, { position = orb.smoothedPos, direction = dir })
end

-- ============================================================
-- Update loop
-- Attach lantern movement is paused while any UI is open to
-- prevent teleporting a world object that the engine may have
-- moved into inventory via drag-and-drop (cell = nullptr crash).
-- ============================================================

local function onUpdate(dt)
    pollUIMode()

    local uiIsOpen = (uiModeNow ~= nil)

    if animateLantern.active then advanceOrb(animateLantern, "AnimateLantern_Update", dt) end

    if attachLantern.active and not uiIsOpen then
        advanceOrb(attachLantern, "AttachLantern_Update", dt)
    end

    if lightWisp.active      then advanceOrb(lightWisp,      "LightWisp_Update",   dt) end
    if haggleLantern.active  then advanceOrb(haggleLantern,  "HaggleLight_Update", dt) end
end

-- ============================================================
-- Event handlers
-- ============================================================

local function onAnimateLanternStarted()
    animateLantern.active      = true
    animateLantern.groundPos   = nil
    animateLantern.currentSlot = 1
    animateLantern.smoothedPos = nil
    animateLantern.blockedFor  = 0
    animateLantern.currentZ    = FLOAT_HEIGHT
end

local function onAnimateLanternEnded()
    animateLantern.active = false
end

local function onAttachLanternStarted()
    attachLantern.active      = true
    attachLantern.groundPos   = nil
    attachLantern.currentSlot = 1
    attachLantern.smoothedPos = nil
    attachLantern.blockedFor  = 0
    attachLantern.currentZ    = FLOAT_HEIGHT
end

local function onAttachLanternEnded()
    attachLantern.active = false
end

local function onLightWispStarted()
    lightWisp.active      = true
    lightWisp.groundPos   = nil
    lightWisp.currentSlot = 1
    lightWisp.smoothedPos = nil
    lightWisp.blockedFor  = 0
    lightWisp.currentZ    = FLOAT_HEIGHT
end

local function onLightWispEnded()
    lightWisp.active = false
end

local function onHaggleLightStarted()
    haggleLantern.active      = true
    haggleLantern.groundPos   = nil
    haggleLantern.currentSlot = 1
    haggleLantern.smoothedPos = nil
    haggleLantern.blockedFor  = 0
    haggleLantern.currentZ    = FLOAT_HEIGHT

    haggleLantern.freezeRotWhileIdle = true
    haggleLantern.anchorRotation     = self.rotation
    haggleLantern.lastPlayerPos      = self.position
end

local function onHaggleLightEnded()
    haggleLantern.active             = false
    haggleLantern.freezeRotWhileIdle = false
    haggleLantern.anchorRotation     = nil
    haggleLantern.lastPlayerPos      = nil
end

local function onRefreshSlots()
    if animateLantern.active then
        animateLantern.currentSlot = pickBestSlot(animateLantern.currentSlot)
    end
    if attachLantern.active then
        attachLantern.currentSlot = pickBestSlot(attachLantern.currentSlot)
    end
    if lightWisp.active then
        lightWisp.currentSlot = pickBestSlot(lightWisp.currentSlot)
    end
    if haggleLantern.active then
        haggleLantern.currentSlot = pickBestSlot(haggleLantern.currentSlot)
    end
end

local function onUpdateLightPosition(data)
    if data and data.position then
        updateLightPositionSetting(data.position)
        onRefreshSlots()
    end
end

-- ============================================================
-- RETURN
-- ============================================================

return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
    eventHandlers = {
        AnimateLantern_Started            = onAnimateLanternStarted,
        AnimateLantern_Ended              = onAnimateLanternEnded,

        AttachLantern_Started             = onAttachLanternStarted,
        AttachLantern_Ended               = onAttachLanternEnded,

        LightWisp_Started                 = onLightWispStarted,
        LightWisp_Ended                   = onLightWispEnded,

        HaggleLight_Started               = onHaggleLightStarted,
        HaggleLight_Ended                 = onHaggleLightEnded,

        ArcaneIllumination_RefreshSlots   = onRefreshSlots,
        ArcaneIllumination_UpdateLightPos = onUpdateLightPosition,
    },
}