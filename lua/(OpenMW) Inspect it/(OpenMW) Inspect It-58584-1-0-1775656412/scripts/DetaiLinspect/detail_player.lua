local input = require('openmw.input')
local camera = require('openmw.camera')
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local self_ = require('openmw.self')
local util = require('openmw.util')
local ui = require('openmw.ui')

local paused = false
local startingSimulationTimeScale = 1.0

local overlay = nil
local hintOverlay = nil

local ROTATE_SPEED = 0.003
local ZOOM_STEP = 1.0
local MIN_DIST = 100.0
local MAX_DIST = 110.0
local DEFAULT_DIST = 105.0

local active = false
local target = nil
local scrollAccum = 0
local inspectKeyWasDown = false
local currentZoom = DEFAULT_DIST 

local function isAllowedType(object)
    if not object then return false end

    local t = object.type

    if     t == types.Weapon        then return true
    elseif t == types.Armor         then return true
    elseif t == types.Clothing      then return true
    elseif t == types.Book          then return true
    elseif t == types.Ingredient    then return true
    elseif t == types.Potion        then return true
    elseif t == types.Miscellaneous then return true
    elseif t == types.Apparatus     then return true
    elseif t == types.Lockpick      then return true
    elseif t == types.Probe         then return true
    elseif t == types.Repair        then return true
    elseif t == types.Light         then return true
    else
        return false
    end
end

local function safeField(rec, field)
    if rec == nil then return nil end
    local ok, v = pcall(function() return rec[field] end)
    return ok and v or nil
end

local function typeName(obj)
    local t = obj.type
    if t == types.Weapon then return 'Weapon'
    elseif t == types.Armor then return 'Armor'
    elseif t == types.Clothing then return 'Clothing'
    elseif t == types.Book then return 'Book/Scroll'
    elseif t == types.Ingredient then return 'Ingredient'
    elseif t == types.Potion then return 'Potion'
    elseif t == types.Miscellaneous then return 'Misc. Item'
    elseif t == types.Apparatus then return 'Apparatus'
    elseif t == types.Lockpick then return 'Lockpick'
    elseif t == types.Probe then return 'Probe'
    elseif t == types.Repair then return 'Repair Item'
    elseif t == types.Light then return 'Light'
    else return 'Object'
    end
end

local function buildInfoText(obj)
    local ok, rec = pcall(function() return obj.type.record(obj) end)
    if not ok then rec = nil end

    local lines = {}
    lines[#lines + 1] = '[ ' .. typeName(obj) .. ' ]'
    lines[#lines + 1] = safeField(rec, 'name') or obj.recordId or '?'

    local w = safeField(rec, 'weight')
    local v = safeField(rec, 'value')
    if w then lines[#lines + 1] = string.format('Weight: %.2f', w) end
    if v then lines[#lines + 1] = string.format('Value: %d gold', v) end

    return table.concat(lines, '\n')
end

local function destroyUI()
    if overlay then
        overlay:destroy()
        overlay = nil
    end
    if hintOverlay then
        hintOverlay:destroy()
        hintOverlay = nil
    end
end

local function createUI(obj)
    destroyUI()

    overlay = ui.create {
        layer = 'HUD',
        type = ui.TYPE.Flex,
        props = {
            position = util.vector2(16, 16),
            autoSize = true,
            vertical = true,
            backgroundColor = util.color.rgba(0, 0, 0, 0.65),
        },
        content = ui.content {
            {
                type = ui.TYPE.Text,
                props = {
                    text = buildInfoText(obj),
                    textSize = 16,
                    textColor = util.color.rgb(1.0, 0.88, 0.55),
                    autoSize = true,
            wordWrap = true,
            size = util.vector2(320, 0),
                },
            },
        },
    }

    hintOverlay = ui.create {
        layer = 'HUD',
        type = ui.TYPE.Text,
        props = {
            relativePosition = util.vector2(0.5, 1.0),
            anchor = util.vector2(0.5, 1.0),
            position = util.vector2(0, -14),
            text = '[LMB drag] Rotate  [Scroll] Zoom  [Configured Key] Exit',
            textSize = 13,
            textColor = util.color.rgb(0.6, 0.6, 0.6),
            autoSize = true,
        },
    }
end

local function disablePlayerControl()
    types.Player.setControlSwitch(self_, types.Player.CONTROL_SWITCH.Controls, false)
    types.Player.setControlSwitch(self_, types.Player.CONTROL_SWITCH.Fighting, false)
    types.Player.setControlSwitch(self_, types.Player.CONTROL_SWITCH.Jumping, false)
    types.Player.setControlSwitch(self_, types.Player.CONTROL_SWITCH.Looking, false)
    types.Player.setControlSwitch(self_, types.Player.CONTROL_SWITCH.Magic, false)
    types.Player.setControlSwitch(self_, types.Player.CONTROL_SWITCH.VanityMode, false)
    types.Player.setControlSwitch(self_, types.Player.CONTROL_SWITCH.ViewMode, false)
end

local function restorePlayerControl()
    types.Player.setControlSwitch(self_, types.Player.CONTROL_SWITCH.Controls, true)
    types.Player.setControlSwitch(self_, types.Player.CONTROL_SWITCH.Fighting, true)
    types.Player.setControlSwitch(self_, types.Player.CONTROL_SWITCH.Jumping, true)
    types.Player.setControlSwitch(self_, types.Player.CONTROL_SWITCH.Looking, true)
    types.Player.setControlSwitch(self_, types.Player.CONTROL_SWITCH.Magic, true)
    types.Player.setControlSwitch(self_, types.Player.CONTROL_SWITCH.VanityMode, true)
    types.Player.setControlSwitch(self_, types.Player.CONTROL_SWITCH.ViewMode, true)
end

local function freezeTime()
    if paused then
        return
    end
    paused = true
    startingSimulationTimeScale = core.getSimulationTimeScale()
    local success = pcall(function()
        core.sendGlobalEvent('toggleSimulation', 0)
    end)
end

local function unfreezeTime()
    if not paused then
        return
    end
    paused = false
    local success = pcall(function()
        core.sendGlobalEvent('toggleSimulation', startingSimulationTimeScale)
    end)
end

local function getPointedObject()
    local cameraPos = camera.getPosition()
    local iMaxActivateDist = core.getGMST("iMaxActivateDist") + 0.1
    local activationDistance = iMaxActivateDist + camera.getThirdPersonDistance()

    local telekinesis = types.Actor.activeEffects(self_):getEffect(core.magic.EFFECT_TYPE.Telekinesis)
    if telekinesis then
        activationDistance = activationDistance + (telekinesis.magnitude * 22)
    end

    activationDistance = activationDistance + 0.1

    local res = nearby.castRenderingRay(
        cameraPos,
        cameraPos + camera.viewportToWorldVector(util.vector2(0.5, 0.5)) * activationDistance,
        { ignore = self_ }
    )

    return res.hitObject
end

local function getRecordIdOfPointedItem()
    local cameraPos = camera.getPosition()
    local iMaxActivateDist = core.getGMST("iMaxActivateDist") + 0.1
    local activationDistance = iMaxActivateDist + camera.getThirdPersonDistance()

    local telekinesis = types.Actor.activeEffects(self_):getEffect(core.magic.EFFECT_TYPE.Telekinesis)
    if telekinesis then
        activationDistance = activationDistance + (telekinesis.magnitude * 22)
    end

    activationDistance = activationDistance + 0.1

    local res = nearby.castRenderingRay(
        cameraPos,
        cameraPos + camera.viewportToWorldVector(util.vector2(0.5, 0.5)) * activationDistance,
        { ignore = self_ }
    )

    if res.hitObject and isAllowedType(res.hitObject) then
        return res.hitObject.recordId, res.hitObject
    else
        return nil, nil
    end
end

local function beginInspect(recordId)
    if not recordId then
        return
    end

    active = true
    target = recordId

    disablePlayerControl()
    freezeTime()

    core.sendGlobalEvent('createObjectToPreview', { referenceId = recordId })

    local _, hitObject = getRecordIdOfPointedItem()
    if hitObject then
        createUI(hitObject)
    end
end

local function endInspect()
    if not active then return end

    active = false
    target = nil
    currentZoom = DEFAULT_DIST

    destroyUI()

    restorePlayerControl()
    unfreezeTime()
    core.sendGlobalEvent('destroyObjectToPreview')
end

local function handleMouseInput()
    if not active or not input.isMouseButtonPressed(1) then return end

    if input.isAltPressed() then
        core.sendGlobalEvent('translatePreviewObject', {
            movePos = {
                x = input.getMouseMoveX(),
                y = input.getMouseMoveY()
            }
        })
    else
        core.sendGlobalEvent('rotatePreviewObject', {
            movePos = {
                x = input.getMouseMoveX(),
                y = input.getMouseMoveY()
            }
        })
    end
end

local function onFrame(dt)
    local inspectKeyDown = input.getBooleanActionValue('DetailItemAction')
    if inspectKeyDown and not inspectKeyWasDown then
        if active then
            endInspect()
        else
            local recordId, hitObject = getRecordIdOfPointedItem()
            if recordId then
                beginInspect(recordId)
            end
        end
    end

    inspectKeyWasDown = inspectKeyDown
    handleMouseInput()
end

local function onMouseWheel(delta)
    if not active then return end

    scrollAccum = scrollAccum + delta

    if math.abs(scrollAccum) > 0.1 then
        local newZoom = currentZoom - (scrollAccum * ZOOM_STEP)

        newZoom = math.max(MIN_DIST, math.min(MAX_DIST, newZoom))

        if newZoom ~= currentZoom then
            core.sendGlobalEvent('zoomPreviewObject', { zoom = newZoom - currentZoom })
            currentZoom = newZoom
        end

        scrollAccum = 0
    end
end

function onUnload()
    destroyUI()
    unfreezeTime()
end

return {
    engineHandlers = {
        onFrame = onFrame,
        onMouseWheel = onMouseWheel
    },
    eventHandlers = {
        InspectPreview_InspectConfirmed = function(data)
            if data and data.recordId then
                beginInspect(data.recordId)
            end
        end,
        InspectPreview_InspectDenied = function(data)
        end
    }
}
