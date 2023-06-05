require("mer.keyScroll.mcm")
local config  = require("mer.keyScroll.config")
local util = require("mer.keyScroll.util")
local logger = util.createLogger("main")

local upDownConfig = {
    up = {
        condition = function(scrollData) return scrollData.index > 1 end,
        indexChange = -1,
    },
    down = {
        condition = function(scrollData) return scrollData.index < #scrollData.contentsElement.children end,
        indexChange = 1,
    }
}

local function doPress(scrollData, upDown)
    logger:debug("doPress: %s", upDown)
    local condition = upDownConfig[upDown].condition
    local indexChange = upDownConfig[upDown].indexChange
    if condition(scrollData) then
        logger:debug("Condition met, pressing button")
        local contentsElement = scrollData.contentsElement
        local index = scrollData.index
        local button = util.getButton(contentsElement, index + indexChange)
        scrollData.index = index + indexChange
        button:triggerEvent("mouseClick")
        tes3.playSound{sound="Menu Click"}
    end
end

local function scrollToButton(scrollData)
    logger:debug("Scroll to button")
    local child = scrollData.contentsElement.children[scrollData.index]
    local scrollPane = scrollData.scrollPane
    local contentsElement = scrollData.contentsElement
    local offset = contentsElement.positionY
    local height = scrollPane.height
    local buttonPosition = -child.positionY
    local buttonHeight = child.height
    --Scroll up if necessary
    if buttonPosition < offset then
        logger:debug("Scrolling up")
        scrollPane.widget.positionY = buttonPosition
    end
    --Scroll down if necessary
    if buttonPosition - height + buttonHeight*2 > offset then
        logger:debug("Scrolling down")
        scrollPane.widget.positionY = buttonPosition - height + buttonHeight*2
    end
    scrollPane:getTopLevelMenu():updateLayout()
end

---@param e keyDownEventData
local function onKeyDown(e)
    logger:trace("Key pressed: %s", e.keyCode)
    if not tes3ui.menuMode() then
        logger:trace("Not in menu mode")
        return
    end
    local menu = tes3ui.getMenuOnTop()
    if not menu then
        logger:trace("No menu on top")
        return
    end
    local upPressed = config.upKeys[e.keyCode]
    local downPressed = config.downKeys[e.keyCode]
    if not (upPressed or downPressed) then
        logger:trace("Not a scroll key")
        return
    end
    logger:debug("%s pressed", upPressed and "Up" or "Down")
    if config.skipMenus[menu.name] then
        logger:debug("Skipping menu: %s", menu.name)
        return
    end
    --block if text input is active
    local blockOnTextInput =
        upPressed and upPressed.blockOnTextInput
        or downPressed and downPressed.blockOnTextInput
    if blockOnTextInput and util.textInputIsActive() then
        logger:debug("Text input active, blocking")
        return
    end
    --get the scroll data
    local scrollData = util.findScrollData(menu)
    if not scrollData then
        logger:debug("No scroll data found")
        return
    end
    --press next button
    if upPressed then
        doPress(scrollData, "up")
    elseif downPressed then
        doPress(scrollData, "down")
    end
    --scroll to button
    scrollToButton(scrollData)
end

event.register("keyDown", function(e)
    logger:trace("Key down: %s", e.keyCode)
    if config.mcm.enabled then
        onKeyDown(e)
    end
end)