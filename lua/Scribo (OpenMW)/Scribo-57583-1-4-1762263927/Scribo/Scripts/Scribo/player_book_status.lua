-- Since Scribo is not compatible with trav's OpenMW Books Enhanced mod, I moved a piece of the mod with the display of the status of reading books as a separate add-on.
-- https://www.nexusmods.com/morrowind/mods/55126

local I = require('openmw.interfaces')
local core = require('openmw.core')
local util = require('openmw.util')
local types = require('openmw.types')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local ui = require('openmw.ui')
local storage = require('openmw.storage')
local camera = require('openmw.camera')

local storage = require('openmw.storage')
local playerSettings = storage.playerSection('SettingsPlayerScribo')


local tooltip = nil
local inspectedBook = nil

local function destroyTooltip()
    inspectedBook = nil
    if tooltip then
        tooltip:destroy()
        tooltip = nil
    end
end
local function getColorFromGameSettings(colorTag)
    local result = core.getGMST(colorTag)
    local rgb = {}
    for color in string.gmatch(result, '(%d+)') do
        table.insert(rgb, tonumber(color))
    end
    if #rgb ~= 3 then
        return util.color.rgb(1, 1, 1)
    end
    return util.color.rgb(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255)
end

local function createTooltip()
    local iconSize = 30
    local posX = 0.5 
    local posY = 0.5 
    local color = getColorFromGameSettings("FontColor_color_normal")

    return ui.create(
        {
            layer = 'HUD',
            type = ui.TYPE.Image,
            props = {
                visible = true,
                relativePosition = util.vector2(posX, posY),
                size = util.vector2(iconSize, iconSize),
                resource = ui.texture { path = 'textures/scribo/tx_travbook_readIndicator.dds' },
                color = color,
            },
        })
end

local readedBook = {}

local function isBookRead(itemRecordId)
    return readedBook[itemRecordId]
end

local function showTooltip()
    -- Если UI находится в режиме взаимодействия — завершаем
    if I.UI.getMode() then
        destroyTooltip()
        return
    end

    local cameraPos = camera.getPosition()
    local baseActivationDistance = core.getGMST("iMaxActivateDist") + 0.1
    local viewDirection = camera.viewportToWorldVector(util.vector2(0.5, 0.5))
    
    -- Вычисляем общее расстояние до объекта
    local activationDistance = baseActivationDistance + camera.getThirdPersonDistance()
    
    -- Учитываем эффект телекинеза (если есть)
    local telekinesis = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Telekinesis)
    if telekinesis then
        activationDistance = activationDistance + (telekinesis.magnitude * 22)
    end
    activationDistance = activationDistance + 0.1

    -- Пробрасываем луч для определения целевого объекта
    local raycastResult = nearby.castRenderingRay(
        cameraPos,
        cameraPos + viewDirection * activationDistance,
        { ignore = self }
    )

    -- Если луч не попал в объект — завершаем
    if not raycastResult.hitObject then
        destroyTooltip()
        return
    end

    local hitObject = raycastResult.hitObject
    local recordId = hitObject.recordId

    -- Игнорируем повторную проверку того же объекта
    if recordId == inspectedBook then
        return
    end

    -- Проверяем тип объекта и состояние "уже прочитан"
    if not (
        types.Book.objectIsInstance(hitObject) 
        and isBookRead(recordId)
    ) then
        destroyTooltip()
        return
    end

    -- Обновляем состояние и создаем подсказку
    inspectedBook = recordId
    destroyTooltip()  -- Очистка предыдущего элемента
    tooltip = createTooltip()
    tooltip:update()
end

local function readBook(data)
    local bookRecord = types.Book.record(data.book)
    readedBook[bookRecord.id] = true
end


local function onFrame()
    showTooltip()    
end

local function onLoad(data)
    if data then
        readedBook = data.readedBook
    end
    if not readedBook then
        readedBook = {}
    end
end
local function onSave()
    return {
        readedBook = readedBook,
    }
end

return {
    engineHandlers = {
        onFrame = onFrame,
        onLoad = onLoad,
        onSave = onSave,
    },
    eventHandlers = {
        readBook = readBook,

    },    
}
