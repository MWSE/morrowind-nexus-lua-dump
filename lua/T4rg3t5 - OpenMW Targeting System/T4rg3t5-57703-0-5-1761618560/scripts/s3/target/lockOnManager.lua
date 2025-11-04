local async = require 'openmw.async'
local aux_util = require 'openmw_aux.util'
local camera = require 'openmw.camera'
local gameSelf = require 'openmw.self'
local input = require 'openmw.input'
local nearby = require 'openmw.nearby'
local types = require 'openmw.types'
local ui = require 'openmw.ui'
---@type openmw.util
local util = require 'openmw.util'

local I = require 'openmw.interfaces'
local s3lf = I.s3lf

local CamHelper = require 'scripts.s3.target.cameraHelper'
local ModInfo = require 'scripts.s3.target.modinfo'

local CenterVector2 = util.vector2(0.5, 0.5)
local ZeroVector2 = util.vector2(0, 0)

local function isWielding()
    return s3lf.getStance() ~= s3lf.STANCE.Nothing
end

--- TODO: Make a subscript function to reconstruct the vectors for the size remapping instead of reconstructing vectors on every call expensive!
--- Refer to globalSettings.lua for field default values
---@class LockOnManager:ProtectedTable
---@field SwitchOnDeadTarget boolean whether or not to automatically select the nearest (screen-space) target when the current one dies
---@field CheckLOS boolean whether to use line-of-sight when deciding whether to break a target lock
---@field TargetLockIcon string baseName of the texture file used for the lock-on icon
---@field TargetMinSize integer minimum size of the target lock icon
---@field TargetMaxSize integer maximum size of the target lock icon
---@field TargetMinDistance integer Distance from the target to the camera at which the target lock icon will be minimum size
---@field TargetMaxDistance integer Distance from the target to the camera at which the target lock icon will be maximum size
---@field TargetColorF util.color Color applied to the target icon when target has >= 100% health. Mixes with TargetColorVH below 100%.
---@field TargetColorVH util.color Color applied to the target icon when target has 60% - 80% health. Mixes with TargetColorH below 80%.
---@field TargetColorH util.color Color applied to the target icon when target has 40% - 60% health. Mixes with TargetColorW below 60%.
---@field TargetColorW util.color Color applied to the target icon when target has 20% - 40% health. Mixes with TargetColorVW below 40%.
---@field TargetColorVW util.color Color applied to the target icon when target has 0% - 20% health. Mixes with TargetColorD below 20%.
---@field TargetColorD util.color Color applied to the target icon when target has <= 0% health.
---@field EnableFlickSwitch boolean Whether or not to allow changing targets by quickly flicking the mouse
---@field FlickSwitchDistance number how far the mouse has to move to flick-switch targets
---@field EnableHitBounce boolean Whether or not to dynamically increase the icon size when a target has been hit
---@field HitBounceSize number How much the icon size should increase/decrease when bouncing
---@field DisableLockWhenSheathing boolean whether to un-set the locked target when sheathing your own weapon
---@field LockOnCombatStart boolean whether or not to automatically lock onto whatever target started combat with you
local LockOnManager = I.S3ProtectedTable.new {
    inputGroupName = 'SettingsGlobal' .. ModInfo.name .. 'LockOnGroup',
    logPrefix = ModInfo.logPrefix,
    modName = ModInfo.name,
    subscribeHandler = false,
}

LockOnManager.state = {
    targetObject = nil,
    targetHealth = nil,
    lockOnMarker = nil,
    currentTexture = nil,
    canDoLockOn = false,
    flickTriggered = false,
    cumulativeXMove = 0,
    isBouncing = false,
    bouncedSize = 0,
    bounceUpOrDown = true,
}

---@alias MarkerTransform util.vector3 info about the marker; z element is distance from camera, xy are normalized screenpos of target

---@class MarkerUpdateInfo
---@field doUpdate boolean? whether to redraw or not
---@field transform MarkerTransform Onscreen position to place the marker at

function LockOnManager.getLockOnFileName(baseName)
    return ('textures/s3/crosshair/%s.dds'):format(baseName)
end

function LockOnManager.canLockOn()
    return LockOnManager.state.canDoLockOn
end

function LockOnManager.setCanLockOn(state)
    assert(type(state) == 'boolean')
    LockOnManager.state.canDoLockOn = state
end

---@param markerUpdateData MarkerUpdateInfo
function LockOnManager:updateMarker(markerUpdateData)
    local element = self.getLockOnMarker()
    assert(element, 'LockOnManager: Failed to locate lock on marker to set its position!')

    local elementSize = self:getIconSize(markerUpdateData.transform.z) + self.state.bouncedSize
    element.layout.props.size = util.vector2(elementSize, elementSize)
    element.layout.props.color = self:getIconColor()
    element.layout.props.relativePosition = markerUpdateData.transform.xy

    local configuredTexture = LockOnManager.TargetLockIcon
    if configuredTexture ~= LockOnManager.state.currentTexture then
        LockOnManager.state.currentTexture = configuredTexture
        element.layout.props.resource = ui.texture { path = LockOnManager.getLockOnFileName(configuredTexture) }
    end

    if markerUpdateData.doUpdate ~= true then return end
    element:update()
end

function LockOnManager.getLockOnMarker()
    return LockOnManager.state.lockOnMarker
end

---@return GameObject lockTarget
function LockOnManager.getTargetObject()
    return LockOnManager.state.targetObject
end

--- Returns false if the target doesn't exist, or isn't an NPC/Creature
---@return boolean isActor
function LockOnManager.targetIsActor()
    local target = LockOnManager.getTargetObject()
    if not target then return false end

    return types.Actor.objectIsInstance(target)
end

function LockOnManager.getMarkerVisibility()
    local marker = LockOnManager.getLockOnMarker()
    if marker == nil then return false end

    local visibility = true

    if marker.layout.props.visible ~= nil then
        visibility = marker.layout.props.visible
    end

    return visibility
end

---@param goLeft boolean? whether to check the right or left side of screen space. Nil indicates both sides should be checked.
function LockOnManager:selectNearestTarget(goLeft)
    local result = aux_util.findMinScore(nearby.actors, function(actor)
        if actor.recordId == 'player'
            or actor == self.state.targetObject
            or actor.type.isDead(actor)
            or actor.type.getStance(actor) == actor.type.STANCE.Nothing
        then
            return false
        end

        local screenPos = CamHelper.objectIsOnscreen(actor)

        if not screenPos
            or screenPos.z > self.TargetMaxDistance
            or (goLeft == true and screenPos.x > 0.5)
            or (goLeft == false and screenPos.x < 0.5) then
            return false
        end

        local LOSCheckPos = util.vector3(actor.position.x, actor.position.y,
            actor.position.z + actor:getBoundingBox().halfSize.z * 2)

        local checkLOSRay = nearby.castRay(camera.getPosition(), LOSCheckPos, {
            ignore = {
                gameSelf,
            }
        })

        -- What if there's no hit...?
        if checkLOSRay.hit then
            if not checkLOSRay.hitObject or checkLOSRay.hitObject ~= actor then
                return false
            end
        end

        return (screenPos.xy - util.vector2(0.5, 0.5)):length()
    end)

    if not result then return end

    s3lf.gameObject:sendEvent('S3TargetLockOnto', result)

    return result
end

--- Depending on whether it already exists or not, creates the lock on marker
--- or simply toggles its visibility
---@return nil
function LockOnManager.toggleLockOnMarkerDisplay()
    local marker = LockOnManager.getLockOnMarker()

    if not marker then
        LockOnManager.state.currentTexture = LockOnManager.getLockOnFileName(LockOnManager.TargetLockIcon)
        LockOnManager.state.lockOnMarker = ui.create {
            layer = 'HUD',
            type = ui.TYPE.Image,
            props = {
                anchor = CenterVector2,
                relativePosition = ZeroVector2,
                size = ZeroVector2,
                resource = ui.texture { path = LockOnManager.state.currentTexture },
                visible = false,
            },
        }
    else
        LockOnManager.setMarkerVisibility(false)
    end
end

---@param target GameObject?
function LockOnManager.setTarget(target)
    if target then
        assert(types.Actor.objectIsInstance(target), 'LockOnManager.setTarget only accepts actor types!!')
    end

    LockOnManager.state.targetObject = target
    LockOnManager.state.targetHealth = target and target.type.stats.dynamic.health(target) or nil
end

--- Responds to the 'SW4_TargetLock' action, engaging or disengaging target locking as appropriate
--- Toggle type action, but, maybe we could make it a hold??
function LockOnManager.lockOnHandler()
    if LockOnManager.getMarkerVisibility() then
        s3lf.sendEvent(s3lf.gameObject, 'S3TargetLockOnto')
        LockOnManager.toggleLockOnMarkerDisplay()
        return
    end

    LockOnManager:selectNearestTarget()
end

--- sets marker visibility. Always triggers a redraw
---@param state boolean whether or not the marker should be visible
---@return boolean? changed whether or not the state actually updated (due to the marker not existing)
function LockOnManager.setMarkerVisibility(state)
    local marker = LockOnManager.getLockOnMarker()
    if not marker then return end

    local markerState = LockOnManager.state
    markerState.isBouncing = false
    markerState.bouncedSize = 0
    markerState.bounceUpOrDown = true

    marker.layout.props.visible = state
    marker:update()
    return true
end

---@param targetIsActor boolean whether or not the target is an actor
---@return boolean? updated whether or not the marker was hidden due to the target being dead
function LockOnManager.checkForDeadTarget(targetIsActor)
    local targetObject = LockOnManager.getTargetObject()

    if not targetObject or not targetIsActor then return end
    if not targetObject.type.isDead(targetObject) then return end

    if LockOnManager.setMarkerVisibility(false) then
        s3lf.sendEvent(s3lf.gameObject, 'S3TargetLockOnto')
        return true
    end
end

--- Given both the old and new ranges, map a numeric value from one to the other and round it.
---@param inputValue number
---@param oldRange util.vector2
---@param newRange util.vector2
local function remapFromRange(inputValue, oldRange, newRange)
    return util.round(
        math.max(
            math.min(
                util.remap(
                    inputValue,
                    oldRange.x,
                    oldRange.y,
                    newRange.x,
                    newRange.y
                ),
                newRange.y
            ),
            newRange.x
        )
    )
end

---@param distanceFromCamera number distance in todd units from targeted object to the camera
---@return number iconSize rounded icon size, remapped from the camera distance range to the size range
function LockOnManager:getIconSize(distanceFromCamera)
    local markerSizeRange = util.vector2(self.TargetMinSize, self.TargetMaxSize)
    local markerDistanceRange = util.vector2(self.TargetMinDistance, self.TargetMaxDistance)
    return remapFromRange(distanceFromCamera, markerDistanceRange, markerSizeRange)
end

function LockOnManager:getIconColor()
    --- Figure out which of the existing log functions is most appropriate to use when this happens, as it shouldn't
    if self.state.targetHealth == nil then
        return self.TargetColorD
    end

    local normalizedHealth = self.state.targetHealth.current / self.state.targetHealth.base

    if normalizedHealth >= 1.0 then
        return self.TargetColorF
    elseif normalizedHealth < 0.0 then
        return self.TargetColorD
    end

    local targetColorMin, targetColorMax

    if normalizedHealth < 1.0 and normalizedHealth >= 0.8 then
        targetColorMin = self.TargetColorVH:asRgb()
        targetColorMax = self.TargetColorF:asRgb()
    elseif normalizedHealth < 0.8 and normalizedHealth >= 0.6 then
        targetColorMin = self.TargetColorH:asRgb()
        targetColorMax = self.TargetColorVH:asRgb()
    elseif normalizedHealth < 0.6 and normalizedHealth >= 0.4 then
        targetColorMin = self.TargetColorW:asRgb()
        targetColorMax = self.TargetColorH:asRgb()
    elseif normalizedHealth < 0.4 and normalizedHealth >= 0.2 then
        targetColorMin = self.TargetColorVW:asRgb()
        targetColorMax = self.TargetColorW:asRgb()
    elseif normalizedHealth < 0.2 and normalizedHealth >= 0.0 then
        targetColorMin = self.TargetColorD:asRgb()
        targetColorMax = self.TargetColorVW:asRgb()
    end

    local colorMix = {}
    colorMix[#colorMix + 1] = util.remap(normalizedHealth, 0.0, 1.0, targetColorMin.x, targetColorMax.x)
    colorMix[#colorMix + 1] = util.remap(normalizedHealth, 0.0, 1.0, targetColorMin.y, targetColorMax.y)
    colorMix[#colorMix + 1] = util.remap(normalizedHealth, 0.0, 1.0, targetColorMin.z, targetColorMax.z)

    return util.color.rgb(colorMix[1], colorMix[2], colorMix[3])
end

function LockOnManager:onFrameBegin()
    if I.UI.getMode() or not LockOnManager.getMarkerVisibility() then return end

    local mouseMoveThisFrame = util.vector2(input.getMouseMoveX(), input.getMouseMoveY())

    self.state.cumulativeXMove = self.state.cumulativeXMove + mouseMoveThisFrame.x

    if
        self.EnableFlickSwitch
        and self.getMarkerVisibility()
        and math.abs(self.state.cumulativeXMove) >= self.FlickSwitchDistance
        and not self.state.flickTriggered
    then
        self:selectNearestTarget(self.state.cumulativeXMove < 0)
        self.state.flickTriggered = true
    end

    if mouseMoveThisFrame:length() == 0 then
        self.state.cumulativeXMove = 0
        self.state.flickTriggered = false
    end
end

function LockOnManager:onFrame()
    local targetIsActor = LockOnManager.targetIsActor()
    local targetWasDead = LockOnManager.checkForDeadTarget(targetIsActor)

    if targetWasDead and self.SwitchOnDeadTarget then
        self:selectNearestTarget()
    end

    local targetObject = LockOnManager.getTargetObject()

    if self.CheckLOS and targetObject then
        if not CamHelper.objectIsOnscreen(targetObject) then
            s3lf.sendEvent(s3lf.gameObject, 'S3TargetLockOnto')
        else
            local LOStest = nearby.castRay(
                camera.getPosition(),
                targetObject:getBoundingBox().center,
                { ignore = { gameSelf, } }
            )

            if not LOStest.hit or not LOStest.hitObject or LOStest.hitObject ~= targetObject then
                s3lf.sendEvent(s3lf.gameObject, 'S3TargetLockOnto')
            end
        end
    end

    LockOnManager.setCanLockOn(
        targetObject ~= nil and (
            (targetIsActor and isWielding())
        )
    )

    local markerExists = LockOnManager.getLockOnMarker() ~= nil
    local markerIsVisible = LockOnManager.getMarkerVisibility()

    if LockOnManager.canLockOn() then
        assert(targetObject)
        if not markerExists then
            LockOnManager.toggleLockOnMarkerDisplay()
        elseif not markerIsVisible then
            LockOnManager.setMarkerVisibility(true)
        end

        local normalizedPos = CamHelper.objectIsOnscreen(targetObject, not types.NPC.objectIsInstance(targetObject))

        if normalizedPos and normalizedPos.z <= self.TargetMaxDistance then
            CamHelper.trackTargetUsingViewport(targetObject, normalizedPos)
            LockOnManager:updateMarker {
                transform = normalizedPos,
                doUpdate = true,
            }
            camera.showCrosshair(false)
        else
            LockOnManager.setMarkerVisibility(false)
            camera.showCrosshair(true)
        end
    else
        if markerIsVisible then
            LockOnManager.setMarkerVisibility(false)
            camera.showCrosshair(true)
        end
    end

    return LockOnManager.canLockOn()
end

--- Checks whether the lock-on icon is currently "bouncing" from a hit
---@return boolean isBouncing whether or not a target has already been hit and started a "bounce"
function LockOnManager.isBouncing()
    return LockOnManager.state.isBouncing
end

function LockOnManager:startBounce()
    if self.state.isBouncing or not self.getMarkerVisibility() then return end

    self.state.isBouncing = true
end

function LockOnManager:bounce()
    if not self.isBouncing() or not self.getMarkerVisibility() then return end

    local state = LockOnManager.state

    if state.bounceUpOrDown then
        state.bouncedSize = state.bouncedSize + 1
    else
        state.bouncedSize = state.bouncedSize - 1
    end

    if state.bouncedSize == LockOnManager.HitBounceSize then
        state.bounceUpOrDown = false
    elseif state.bouncedSize == 0 then
        state.isBouncing = false
        state.bounceUpOrDown = true
    end
end

--- Handle late-stage actions such as un-targeting when the weapon is sheathed,
--- bouncing, and other stuff that depends on earlier frame interactions
function LockOnManager:onFrameEnd()
    self:bounce()

    if
        self.DisableLockWhenSheathing
        and not isWielding()
        and self.getTargetObject()
    then
        s3lf.sendEvent(s3lf.gameObject, 'S3TargetLockOnto')
    end
end

---@class TargetChangeData
---@field targets GameObject[]
---@field actor GameObject

---@param targetChangeData TargetChangeData
function LockOnManager.lockOnCombatStart(targetChangeData)
    if
        not LockOnManager.LockOnCombatStart
        or LockOnManager.getMarkerVisibility()
        or next(targetChangeData.targets) == nil
    then
        return
    end

    local targetIsMe = false
    for _, target in ipairs(targetChangeData.targets) do
        if target.id == s3lf.id then
            targetIsMe = true
            break
        end
    end

    local hasWeapon = s3lf.getEquipment(s3lf.EQUIPMENT_SLOT.CarriedRight) ~= nil
    local hasSpell = s3lf.getSelectedEnchantedItem() ~= nil or s3lf.getSelectedSpell() ~= nil
    if
        not targetIsMe
        or (not hasWeapon and not hasSpell)
    then
        return
    end

    if not isWielding() then
        local stance = hasWeapon and s3lf.STANCE.Weapon or s3lf.STANCE.Spell

        s3lf.setStance(stance)
    end

    s3lf.sendEvent(s3lf.gameObject, 'S3TargetLockOnto', targetChangeData.actor)

    local myYaw, theirYaw = s3lf.rotation:getYaw(), targetChangeData.actor.rotation:getYaw()

    theirYaw = theirYaw - math.rad(180)
    local difference = theirYaw - myYaw

    s3lf.controls.yawChange = math.atan2(
        math.sin(difference),
        math.cos(difference)
    )
end

function LockOnManager.bounceOnHit(target)
    if
    --- Maybe we also want to bail if the marker isn't visible... ?
        not LockOnManager.EnableHitBounce
        or LockOnManager.isBouncing()
    then
        return
    end

    local targetObject = LockOnManager.getTargetObject()

    --- Don't screw around and switch targets when we hit someone else on accident, but have a locked-on target already.
    if targetObject and targetObject ~= target then
        return
    end

    LockOnManager:startBounce()
end

input.registerTriggerHandler('S3TargetLock', async:callback(LockOnManager.lockOnHandler))

return {
    engineHandlers = {
        onFrame = function()
            LockOnManager:onFrameBegin()
            LockOnManager:onFrame()
            LockOnManager:onFrameEnd()
        end,
    },
    eventHandlers = {
        OMWMusicCombatTargetsChanged = LockOnManager.lockOnCombatStart,
        S3TargetLockOnto = LockOnManager.setTarget,
        S3TargetLockHit = LockOnManager.bounceOnHit,
    },
    interfaceName = 'S3LockOn',
    interface = {
        version = 1,
        Manager = LockOnManager,
    },
}
