local camera = require('openmw.camera')
local core = require('openmw.core')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local self = require('openmw.self')
local types = require('openmw.types')

local constants = require('scripts.AutoZoom.constants')
local settings = require('scripts.AutoZoom.settings')
local targeting = require('scripts.AutoZoom.targeting')

local state = {
    focusObjectId = nil,
    focusStartTime = 0,
    lastSeenTime = 0,
    debugAccumulator = 0,
    lastRequestedFov = nil,
    lastRequestTag = 'none',
    overrideCount = 0,
}

local function getSetting(key)
    return settings.get(key)
end

local function toDeg(rad)
    return rad * 180 / math.pi
end

local function modeName(mode)
    if mode == camera.MODE.FirstPerson then
        return 'first'
    end
    if mode == camera.MODE.ThirdPerson then
        return 'third'
    end
    if mode == camera.MODE.Preview then
        return 'preview'
    end
    if mode == camera.MODE.Vanity then
        return 'vanity'
    end
    if mode == camera.MODE.Static then
        return 'static'
    end
    return tostring(mode)
end

local function setFov(value, tag)
    camera.setFieldOfView(value)
    state.lastRequestedFov = value
    state.lastRequestTag = tag or 'unknown'
end

local function debugLog(dt, info)
    if not getSetting('debugLogging') then
        state.debugAccumulator = 0
        return
    end

    state.debugAccumulator = state.debugAccumulator + dt
    if state.debugAccumulator < constants.DEBUG_LOG_INTERVAL then
        return
    end
    state.debugAccumulator = 0

    print(string.format(
        '[AutoZoom] mode=%s manual=%s bow=%s lock=%s auto=%s action=%s fov=%.2f target=%.2f base=%.2f overrides=%d targetId=%s',
        info.mode,
        tostring(info.manual),
        tostring(info.bow),
        tostring(info.locked),
        tostring(info.auto),
        info.action,
        toDeg(info.currentFov),
        toDeg(info.targetFov),
        toDeg(info.baseFov),
        state.overrideCount,
        tostring(state.focusObjectId)
    ))
end

local function isBowAimingLikelyActive()
    local actor = types.Actor
    local weaponType = types.Weapon
    if actor == nil or weaponType == nil then
        return false
    end

    if actor.stance(self) ~= actor.STANCE.Weapon then
        return false
    end

    if not input.isActionPressed(input.ACTION.Activate) then
        return false
    end

    local equipped = actor.equipment(self, actor.EQUIPMENT_SLOT.CarriedRight)
    local record = equipped and equipped.type == weaponType and weaponType.record(equipped)
    if record == nil then
        return false
    end

    local wtype = record.type
    return wtype == weaponType.TYPE.MarksmanBow
        or wtype == weaponType.TYPE.MarksmanCrossbow
        or wtype == weaponType.TYPE.MarksmanThrown
end

local function isAllowedMode(mode)
    if mode == camera.MODE.FirstPerson then
        return getSetting('enableInFirstPerson')
    end

    if mode == camera.MODE.Static then
        return false
    end

    return getSetting('enableInThirdPerson')
end

local function isOutOfCombatContext()
    if I.UI.getMode() ~= nil then
        return false, 'ui'
    end

    local ai = I.AI
    if ai ~= nil then
        local activePackage = ai.getActivePackage()
        if activePackage ~= nil and activePackage.type == 'Combat' then
            return false, 'combat-package'
        end

        local combatTarget = ai.getActiveTarget('Combat')
        if combatTarget ~= nil then
            return false, 'combat-target'
        end

        local combatTargets = ai.getTargets('Combat')
        if combatTargets ~= nil and #combatTargets > 0 then
            return false, 'combat-targets'
        end
    end

    return true, 'free'
end

local function getTargetZoomFov(baseFov)
    local magnification = math.max(1.01, getSetting('magnification'))
    return baseFov / magnification
end

local function resetFocus()
    state.focusObjectId = nil
    state.focusStartTime = 0
    state.lastSeenTime = 0
end

local function updateFocus(target, isTargetingObject, now)
    if isTargetingObject then
        local targetId = target.id or target.recordId
        state.lastSeenTime = now
        if targetId ~= state.focusObjectId then
            state.focusObjectId = targetId
            state.focusStartTime = now
        end
        return true
    end

    if state.focusObjectId ~= nil and (now - state.lastSeenTime) <= constants.TARGET_GRACE_TIME then
        return true
    end

    resetFocus()
    return false
end

local function shouldAutoZoom(isTargetingObject)
    if not isTargetingObject or state.focusObjectId == nil then
        return false
    end

    local focusTime = math.max(0, getSetting('focusTime'))
    return (core.getRealTime() - state.focusStartTime) >= focusTime
end

local function snapBack(baseFov, currentFov, dt)
    if currentFov >= baseFov then
        return
    end

    local snapBackTime = math.max(0, getSetting('snapBackTime'))
    if snapBackTime == 0 then
        setFov(baseFov, 'snap-instant')
        return
    end

    local targetZoomFov = getTargetZoomFov(baseFov)
    local resetSpeed = (baseFov - targetZoomFov) / snapBackTime
    local nextFov = math.min(baseFov, currentFov + resetSpeed * dt)
    setFov(nextFov, 'snap-smooth')
end

local function applyZoom(baseFov, currentFov, dt)
    local targetZoomFov = getTargetZoomFov(baseFov)
    if currentFov <= targetZoomFov then
        return
    end

    local zoomSpeed = math.max(0.01, getSetting('zoomSpeed'))
    local nextFov = math.max(targetZoomFov, currentFov - zoomSpeed * dt)
    setFov(nextFov, 'zoom')
end

local function onFrame(dt)
    local baseFov = camera.getBaseFieldOfView()
    local currentFov = camera.getFieldOfView()
    local mode = camera.getMode()
    local manualZoomKey = settings.get('manualZoomKey')
    local manualZoomCode = settings.getKeyCode(manualZoomKey) or input.KEY.B
    local isManualZooming = input.isKeyPressed(manualZoomCode)
    local bowAiming = isBowAimingLikelyActive()
    local outOfCombatContext, contextReason = isOutOfCombatContext()

    local previousRequestedFov = state.lastRequestedFov
    local previousRequestTag = state.lastRequestTag
    state.lastRequestedFov = nil
    state.lastRequestTag = 'none'
    if previousRequestedFov ~= nil and math.abs(currentFov - previousRequestedFov) > 0.005 then
        state.overrideCount = state.overrideCount + 1
        if getSetting('debugLogging') then
            print(string.format(
                "[AutoZoom] external FOV override suspected (delta=%.4f rad), expected from '%s'",
                currentFov - previousRequestedFov,
                previousRequestTag
            ))
        end
    end

    if not isAllowedMode(mode) then
        if currentFov ~= baseFov then
            setFov(baseFov, 'mode-reset')
        end
        resetFocus()
        debugLog(dt, {
            mode = modeName(mode),
            manual = isManualZooming,
            bow = bowAiming,
            locked = false,
            auto = false,
            action = 'disabled',
            currentFov = currentFov,
            targetFov = baseFov,
            baseFov = baseFov,
        })
        return
    end

    if bowAiming then
        debugLog(dt, {
            mode = modeName(mode),
            manual = isManualZooming,
            bow = bowAiming,
            locked = false,
            auto = false,
            action = 'yield-bow',
            currentFov = currentFov,
            targetFov = getTargetZoomFov(baseFov),
            baseFov = baseFov,
        })
        return
    end

    if not outOfCombatContext then
        if currentFov ~= baseFov then
            setFov(baseFov, 'context-reset')
        end
        resetFocus()
        debugLog(dt, {
            mode = modeName(mode),
            manual = isManualZooming,
            bow = bowAiming,
            locked = false,
            auto = false,
            action = 'blocked-' .. contextReason,
            currentFov = currentFov,
            targetFov = getTargetZoomFov(baseFov),
            baseFov = baseFov,
        })
        return
    end

    local now = core.getRealTime()
    local target = targeting.getObjectUnderCrosshair()
    local isTargetingObject = target ~= nil and target ~= self.object and targeting.isInteractable(target)
    local hasTargetLock = updateFocus(target, isTargetingObject, now)
    local targetFov = getTargetZoomFov(baseFov)
    local autoZooming = shouldAutoZoom(hasTargetLock)
    local manualAllowed = isManualZooming

    if manualAllowed or autoZooming then
        applyZoom(baseFov, currentFov, dt)
        debugLog(dt, {
            mode = modeName(mode),
            manual = manualAllowed,
            bow = bowAiming,
            locked = hasTargetLock,
            auto = autoZooming,
            action = 'zoom',
            currentFov = currentFov,
            targetFov = targetFov,
            baseFov = baseFov,
        })
        return
    end

    snapBack(baseFov, currentFov, dt)
    debugLog(dt, {
        mode = modeName(mode),
        manual = isManualZooming,
        bow = bowAiming,
        locked = hasTargetLock,
        auto = autoZooming,
        action = 'snap',
        currentFov = currentFov,
        targetFov = targetFov,
        baseFov = baseFov,
    })
end

return {
    onFrame = onFrame,
}
