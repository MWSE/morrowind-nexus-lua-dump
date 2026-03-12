local ui = require("openmw.ui")
local util = require("openmw.util")
local storage = require("openmw.storage")
local async = require("openmw.async")
local I = require("openmw.interfaces")
local input = require('openmw.input')

local C = require("scripts.AmmoCountHUD.utils.consts")

local settingsLooks = storage.playerSection("SettingsAmmoCountHUD_looks")

local elements = {}

elements.ammo = ui.create {
    layer = settingsLooks:get("positionLocked") and "HUD" or 'Modal',
    name = "AmmoCountHUD",
    type = ui.TYPE.Text,
    events = {},
    props = {
        anchor = C.getAnchorPoint[settingsLooks:get("textAlignment")],
        position = util.vector2(
            settingsLooks:get("posX"),
            settingsLooks:get("posY")
        ),
        visible = settingsLooks:get("enabled") and I.UI.isHudVisible(),
        text = "",
        textSize = settingsLooks:get("fontSize"),
        textColor = settingsLooks:get("fontColor"),
    },
    userData = {
        windowStartPosition = util.vector2(
            settingsLooks:get("posX"),
            settingsLooks:get("posY")
        )
    }
}

-- +--------------------+
-- | Draggable UI logic |
-- +--------------------+

local function mousePress(data, elem)
    if data.button ~= 1 then return end -- Left mouse button
    if not elem.userData then
        elem.userData = {}
    end
    elem.userData.isDragging = true
    elem.userData.dragStartPosition = data.position
    elem.userData.windowStartPosition = elements.ammo.layout.props.position or util.vector2(0, 0)

    elements.ammo:update()
end

local function mouseMove(data, elem)
    if not (elem.userData and elem.userData.isDragging) then return end
    -- Calculate new position based on mouse movement
    local deltaX = data.position.x - elem.userData.dragStartPosition.x
    local deltaY = data.position.y - elem.userData.dragStartPosition.y
    print(deltaX, deltaY)
    local newPosition = util.vector2(
        elem.userData.windowStartPosition.x + deltaX,
        elem.userData.windowStartPosition.y + deltaY
    )
    settingsLooks:set("posX", math.floor(newPosition.x))
    settingsLooks:set("posY", math.floor(newPosition.y))
    elements.ammo.layout.props.position = newPosition

    elements.ammo:update()
end

local function mouseRelease(data, elem)
    if elem.userData then
        elem.userData.isDragging = false
    end
    elements.ammo:update()
end

elements.ammo.layout.events.mousePress = async:callback(mousePress)
elements.ammo.layout.events.mouseMove = async:callback(mouseMove)
elements.ammo.layout.events.mouseRelease = async:callback(mouseRelease)
elements.ammo:update()

-- +---------------------+
-- | Scrollable UI Logic |
-- +---------------------+

local function scaleFontSize(vertical)
    settingsLooks:set("fontSize", math.max(5, settingsLooks:get("fontSize") + vertical))
end

if input.triggers["MenuMouseWheelUp"] then
    input.registerTriggerHandler("MenuMouseWheelUp", async:callback(function()
        if not elements.ammo.layout.userData.isDragging then return end
        if settingsLooks:get("positionLocked") then return end
        scaleFontSize(1)
    end))
end
if input.triggers["MenuMouseWheelDown"] then
    input.registerTriggerHandler("MenuMouseWheelDown", async:callback(function()
        if not elements.ammo.layout.userData.isDragging then return end
        if settingsLooks:get("positionLocked") then return end
        scaleFontSize(-1)
    end))
end

-- +--------------------+
-- | Settings Callbacks |
-- +--------------------+

local callbacks = {
    ["enabled"] = function(settingValue)
        elements.ammo.layout.props.visible = settingValue and I.UI.isHudVisible()
    end,
    ["positionLocked"] = function(settingValue)
        elements.ammo.layout.layer = settingValue and "HUD" or 'Modal'
    end,
    ["posX"] = function(settingValue)
        elements.ammo.layout.props.position = util.vector2(
            settingValue,
            settingsLooks:get("posY")
        )
    end,
    ["posY"] = function(settingValue)
        elements.ammo.layout.props.position = util.vector2(
            settingsLooks:get("posX"),
            settingValue
        )
    end,
    ["fontColor"] = function(settingValue)
        elements.ammo.layout.props.textColor = settingValue
    end,
    ["fontSize"] = function(settingValue)
        elements.ammo.layout.props.textSize = settingValue
    end,
    ["textAlignment"] = function(settingValue)
        elements.ammo.layout.props.anchor = C.getAnchorPoint[settingValue]
    end
}

settingsLooks:subscribe(async:callback(
    function(sectionName, settingKey)
        local callback = callbacks[settingKey]
        if callback then
            callback(settingsLooks:get(settingKey))
            elements.ammo:update()
        end
    end)
)

return elements
