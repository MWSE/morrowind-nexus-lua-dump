local async = require 'openmw.async'
local camera = require 'openmw.camera'
local gameSelf = require 'openmw.self'
local input = require 'openmw.input'
local nearby = require 'openmw.nearby'
local types = require 'openmw.types'
local util = require 'openmw.util'
local ui = require 'openmw.ui'

local ModInfo = require 'scripts.sw4.modinfo'

local I = require 'openmw.interfaces'

local DeltaMultStart = 50
local DeltaMultEnd = 10000
local RealActivationRange = 500

---@type ManagementStore
local GlobalManagement

---@class CursorController
---@field StartFromCenter boolean whether or not the cursor starts from the center of the screen each time it is brought back up
---@field ShowBanner boolean
---@field IconName string basename of the icon path for the cursor
---@field TargetFlickThreshold number Length of continuous movement required to switch targets
---@field BannerFontSize integer
---@field DefaultColor util.color Default cursor color for non-interactive or out-of-range objects
---@field FriendlyActorColor util.color Cursor color used for friendly actors but whom are not vendors or service providers
---@field FightingActorColor util.color Cursor color used for actors whom are in combat
---@field ServiceActorColor util.color Cursor color used for actors whom provide some service
---@field LockedColor util.color Cursor color used for locked objects
---@field TeleportDoorColor util.color Cursor color used for teleport doors
---@field Sensitivity number input sensitivity (multiplier)
---@field CursorSize number integer size of the icon
---@field XAnchor number float X-axis anchor
---@field YAnchor number float Y-axis anchor
local CursorController = I.StarwindVersion4ProtectedTable.new {
    modName = ModInfo.name,
    logPrefix = ModInfo.logPrefix,
    inputGroupName = 'SettingsGlobal' .. ModInfo.name .. 'CursorGroup',
}

function CursorController.getCursorIcon(baseName)
    return ('textures/sw4/cursor/%s.dds'):format(baseName)
end

function CursorController:startPos()
    return ui.screenSize() / 2
end

CursorController.state = {
    cursorPos = CursorController:startPos(),
    changeThisFrame = util.vector2(0, 0),
    shouldShow = false,
    currentTarget = nil,
    cumulativeXMove = 0,
    flickTriggered = false,
    configuredTexture = CursorController.IconName,
}

local Cursor = ui.create {
    layer = 'HUD',
    name = 'SW4_Cursor',
    type = ui.TYPE.Image,
    props = {
        size = util.vector2(CursorController.CursorSize, CursorController.CursorSize),
        anchor = util.vector2(CursorController.XAnchor, CursorController.YAnchor),
        resource = ui.texture { path = CursorController.getCursorIcon(CursorController.IconName) },
        position = CursorController:startPos(),
        visible = false,
    }
}

local Constants = require 'scripts.omw.mwui.constants'
local DarkFactor = 0.8
local LightFactor = 1.25

local DarkColor = util.color.rgb(
    Constants.normalColor.r * DarkFactor,
    Constants.normalColor.g * DarkFactor,
    Constants.normalColor.b * DarkFactor
)

local LightColor = util.color.rgb(
    Constants.normalColor.r * LightFactor,
    Constants.normalColor.g * LightFactor,
    Constants.normalColor.b * LightFactor
)

local BannerSize = ui.screenSize():emul(util.vector2(0.15, 0.065))
local CursorBanner = ui.create {
    layer = 'HUD',
    name = 'SW4_CursorBanner',
    template = I.MWUI.templates.boxTransparent,
    props = {
        relativePosition = util.vector2(0.5, 0),
        anchor = util.vector2(0.5, 0),
        visible = false,
    },
    content = ui.content {
        {
            name = 'SW4_CursorBannerText',
            template = I.MWUI.textHeader,
            type = ui.TYPE.Text,
            props = {
                autoSize = false,
                size = BannerSize,
                text = '',
                textColor = Constants.normalColor,
                textSize = CursorController.BannerFontSize,
                textAlignH = ui.ALIGNMENT.Center,
                textAlignV = ui.ALIGNMENT.Center,
                wordWrap = true,
                multiline = true,
            }
        },
    }
}

function CursorController:getCursor()
    return Cursor
end

function CursorController:getCursorBanner()
    return CursorBanner
end

function CursorController:shouldShowCursor()
    return self.state.shouldShow
        and not GlobalManagement.LockOn.getMarkerVisibility()
        and not I.UI.getMode()
        and camera.getMode() ~= camera.MODE.FirstPerson
end

--- However appropriate, implement X and Y axis scaling and inversion
function CursorController:onFrameBegin(dt)
    -- HACK: The internal cursor's position does not change if a UI mode is not up
    -- However, ours does. We have to disable position tracking when a UI mode is up.
    -- Which, naturally, is quite a bitch, as we will essentially have to roll our own UI modes to use this cursor if it actually works.
    -- Or, maybe later, we *could* just make the normal cursor icon invisible.

    local ScreenSize = ui.screenSize()

    local changeThisFrame = util.vector2(input.getMouseMoveX(), input.getMouseMoveY()) * self.Sensitivity
    local markerVisible = GlobalManagement.LockOn.getMarkerVisibility()

    self.state.changeThisFrame = changeThisFrame

    if not I.UI.getMode() then
        self.state.cursorPos = util.vector2(
            util.clamp(self.state.cursorPos.x + changeThisFrame.x, 0, ScreenSize.x),
            util.clamp(self.state.cursorPos.y + changeThisFrame.y, 0, ScreenSize.y)
        )
    end

    self.state.cumulativeXMove = self.state.cumulativeXMove + changeThisFrame.x

    if math.abs(self.state.cumulativeXMove) >= (self.TargetFlickThreshold * self.Sensitivity) and not self.state.flickTriggered then
        if not I.UI.getMode() and markerVisible then
            GlobalManagement.LockOn:selectNearestTarget(self.state.cumulativeXMove < 0)
            self.state.flickTriggered = true
        end
    end

    if changeThisFrame:length() == 0 then
        self.state.cumulativeXMove = 0
        self.state.flickTriggered = false
    end

    local showCursor = self:shouldShowCursor()

    camera.showCrosshair(not showCursor)
    I.Controls.overrideCombatControls(showCursor)
    self:setCursorPosition(self.state.cursorPos)

    local cursorProps = Cursor.layout.props
    if CursorController.IconName ~= CursorController.state.configuredTexture then
        CursorController.state.configuredTexture = CursorController.IconName
        cursorProps.resource = ui.texture { path = CursorController.getCursorIcon(CursorController.IconName) }
    end

    cursorProps.size = util.vector2(CursorController.CursorSize, CursorController.CursorSize)
    cursorProps.anchor = util.vector2(CursorController.XAnchor, CursorController.YAnchor)
    cursorProps.color = self:getCursorColor(self.state.currentTarget)

    self:setCursorVisible(showCursor)
end

local canActivate = false
input.bindAction('Use', async:callback(function()
        local pressed = input.isActionPressed(input.ACTION.Use)

        if CursorController:getCursorVisible() then
            if not CursorController.state.currentTarget then return false end

            return pressed and canActivate
        end

        return pressed
    end),
    {})

input.registerActionHandler('Use', async:callback(function(state)
    if not state or not CursorController:shouldShowCursor() or not CursorController.state.currentTarget then return end

    CursorController.state.currentTarget:activateBy(gameSelf)
end))

input.registerActionHandler('Run', async:callback(function(state)
    if not state or I.UI.getMode() then return end

    CursorController.state.shouldShow = not CursorController.state.shouldShow

    --- Start from the center only when the user *manually* disables the cursor, other UI mode changes should preserve the original position like the engine cursor
    if CursorController.StartFromCenter and not CursorController.state.shouldShow then
        CursorController:setCursorPosition(ui.screenSize() / 2)
    end
end))

---@param targetActor userdata
---@return boolean hasServices whether the actor provides any service or not
function CursorController.actorProvidesServices(targetActor)
    assert(types.Actor.objectIsInstance(targetActor))
    local services = targetActor.type.records[targetActor.recordId].servicesOffered

    for _, hasService in pairs(services) do
        if hasService then return true end
    end

    return false
end

function CursorController:getCursorColor(targetObject)
    if not targetObject or types.Static.objectIsInstance(targetObject) then
        return self.DefaultColor
    elseif types.Actor.objectIsInstance(targetObject) then
        if targetObject.type.getStance(targetObject) == targetObject.type.STANCE.Nothing then
            if canActivate then
                if self.actorProvidesServices(targetObject) then
                    return self.ServiceActorColor
                end

                return self.FriendlyActorColor
            end
        else
            return self.FightingActorColor
        end
    elseif types.Lockable.objectIsInstance(targetObject) and types.Lockable.isLocked(targetObject) and canActivate then
        return self.LockedColor
    elseif types.Door.objectIsInstance(targetObject) and types.Door.isTeleport(targetObject) and canActivate then
        return self.TeleportDoorColor
    end

    return canActivate and self.FriendlyActorColor or self.DefaultColor
end

function CursorController:updateBanner(targetObject)
    local objectName = targetObject.type.records[targetObject.recordId].name
    local hasValidName = (objectName ~= nil and objectName ~= '')

    local bannerProps = CursorBanner.layout.props
    bannerProps.visible = self.ShowBanner and hasValidName

    if hasValidName then
        self.state.currentTarget = targetObject

        local bannerTextProps = CursorBanner.layout.content.SW4_CursorBannerText.props
        bannerTextProps.textColor = canActivate and LightColor or DarkColor
        bannerTextProps.text = objectName
        bannerTextProps.textSize = self.BannerFontSize
    else
        self.state.currentTarget = nil
    end

    CursorBanner:update()
end

function CursorController:onFrame(dt)
    if not self:shouldShowCursor() then return end
    local rayResult = self:getObjectUnderMouse()

    if rayResult then
        self:updateBanner(rayResult.hitObject)
    end


    if self.state.changeThisFrame:length() == 0 then return end
end

function CursorController:getCursorPosition()
    return self.state.cursorPos
end

function CursorController:getCursorVisible()
    return Cursor.layout.props.visible
end

function CursorController:setCursorVisible(state)
    if Cursor.layout.props.visible == state then return end

    Cursor.layout.props.visible = state
    Cursor:update()

    if not state and self.StartFromCenter then
        self:setCursorPosition(self:startPos())
    end
end

---@param newAnchor util.vector2 a normalized vector from which to position the cursor
function CursorController:setCursorAnchor(newAnchor)
    Cursor.layout.props.anchor = newAnchor

    if not Cursor.layout.props.visible then return end
    Cursor:update()
end

---@return util.vector2
function CursorController:getCursorSize()
    return Cursor.layout.props.size
end

---@param newSize util.vector2
function CursorController:setCursorSize(newSize)
    Cursor.layout.props.size = newSize

    if not Cursor.layout.props.visible then return end
    Cursor:update()
end

function CursorController:getNormalizedCursorPosition()
    return self.state.cursorPos:ediv(ui.screenSize())
end

function CursorController:getCursorMove()
    return input.getMouseMoveX(), input.getMouseMoveY()
end

function CursorController.checkTarget(ray)
    if ray.hitObject and types.Actor.objectIsInstance(ray.hitObject) then return true end
    local delta = ray.hitPos - gameSelf.position
    return delta.z < 160 or delta.z < 0.5 * delta:length()
end

function CursorController:getObjectUnderMouse()
    local delta = camera.viewportToWorldVector(self:getNormalizedCursorPosition())
    local basePos = camera.getPosition() + delta * DeltaMultStart
    local endPos = basePos + delta * DeltaMultEnd

    local options, result = { ignore = { gameSelf, } }, nil

    result = nearby.castRenderingRay(basePos, endPos, options)
    if result.hitObject and self.checkTarget(result) then
        canActivate = (gameSelf.position - result.hitPos):length() < RealActivationRange
        return result
    end
end

---@param newPos util.vector2
function CursorController:setCursorPosition(newPos)
    local ScreenSize = ui.screenSize()

    newPos = util.vector2(
        util.clamp(newPos.x, 0, ScreenSize.x),
        util.clamp(newPos.y, 0, ScreenSize.y)
    )

    self.state.cursorPos = newPos
    Cursor.layout.props.position = newPos

    if not Cursor.layout.props.visible then return end
    Cursor:update()
end

---@param globalManagement ManagementStore
---@return CursorController
return function(globalManagement)
    assert(globalManagement)
    GlobalManagement = globalManagement
    return CursorController
end
