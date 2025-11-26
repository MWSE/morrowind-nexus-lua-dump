local settings = require("scripts.openmw_books_enhanced.settings")
local I = require('openmw.interfaces')
local core = require('openmw.core')
local util = require('openmw.util')
local types = require('openmw.types')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local ui = require('openmw.ui')
local storage = require('openmw.storage')
local camera = require('openmw.camera')

local currentlyInspectedBookItemRecordId = nil

local tooltipForReadStatus = nil

local RSS = {}

local function destroyTooltip()
    if tooltipForReadStatus then
        tooltipForReadStatus:destroy()
        tooltipForReadStatus = nil
    end
end

local function destroyTooltipAndRecord()
    if not currentlyInspectedBookItemRecordId then return end
    destroyTooltip()
    currentlyInspectedBookItemRecordId = nil
end

local function isItemAlreadyRead(itemRecordId, savedDataForThisMod)
    if savedDataForThisMod
        and savedDataForThisMod.alreadyReadTexts
        and (savedDataForThisMod.alreadyReadTexts[itemRecordId] ~= nil) then
        return true
    end
    return false
end

local function createTooltipSpace()
    local iconSize = settings.SettingsTravOpenmwBooksEnhanced_readStatusIndicatorSize()
    local posX = settings.SettingsTravOpenmwBooksEnhanced_readStatusIndicatorPosX()
    local posY = settings.SettingsTravOpenmwBooksEnhanced_readStatusIndicatorPosY()
    local color = settings.SettingsTravOpenmwBooksEnhanced_readStatusIndicatorColor()

    local result = ui.create(
        {
            layer = 'HUD',
            type = ui.TYPE.Image,
            props = {
                visible = true,
                relativePosition = util.vector2(posX, posY),
                size = util.vector2(iconSize, iconSize),
                resource = ui.texture { path = 'textures/openmw_books_enhanced/tx_travbook_readIndicator.dds' },
                color = color,
            },
        })

    return result
end

function RSS.runReadStatusCheckerOnPointedItem(savedDataForThisMod)
    if I.UI.getMode()
        or not settings.SettingsTravOpenmwBooksEnhanced_enableReadStatusDetector()
        or not (savedDataForThisMod and savedDataForThisMod.alreadyReadTexts) then
        destroyTooltipAndRecord()
        return
    end

    local cameraPos = camera.getPosition()
    local iMaxActivateDist = core.getGMST("iMaxActivateDist") + 0.1
    local activationDistance = iMaxActivateDist + camera.getThirdPersonDistance();
    local telekinesis = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Telekinesis);
    if telekinesis then
        activationDistance = activationDistance + (telekinesis.magnitude * 22);
    end
    activationDistance = activationDistance + 0.1
    local res = nearby.castRenderingRay(
        cameraPos,
        cameraPos + camera.viewportToWorldVector(util.vector2(0.5, 0.5)) * activationDistance,
        { ignore = self })

    if not res.hitObject then
        destroyTooltipAndRecord()
        return
    end

    if res.hitObject.recordId == currentlyInspectedBookItemRecordId then
        return
    end

    if not types.Book.objectIsInstance(res.hitObject)
        or not isItemAlreadyRead(res.hitObject.recordId, savedDataForThisMod) then
        destroyTooltipAndRecord()
        return
    end

    currentlyInspectedBookItemRecordId = res.hitObject.recordId

    destroyTooltip()
    tooltipForReadStatus = createTooltipSpace()
    tooltipForReadStatus:update()
end

return RSS
