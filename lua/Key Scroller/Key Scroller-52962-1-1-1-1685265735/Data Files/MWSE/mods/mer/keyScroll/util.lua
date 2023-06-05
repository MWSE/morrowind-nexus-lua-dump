---@class KeyScroll.Util
local Util = {}

local config = require("mer.keyScroll.config")
local MWSELogger = require("logging.logger")

Util.loggers = {}
function Util.createLogger(serviceName)
    local logger = MWSELogger.new{
        name = string.format("%s - %s",
            config.metadata.package.name, serviceName),
        logLevel = config.mcm.logLevel,
        includeTimestamp = true,
    }
    Util.loggers[serviceName] = logger
    return logger
end
local logger = Util.createLogger("util")

function Util.textInputIsActive()
    local menuController = tes3.worldController.menuController
    local inputFocus = menuController.inputController.textInputFocus
    if (not inputFocus or not inputFocus.visible) then
        return false
    end
    return true
end

function Util.isActive(element)
    local colors = {
        tes3ui.getPalette("active_color"),
        tes3ui.getPalette("active_over_color"),
        tes3ui.getPalette("active_pressed_color"),
    }
    for _, color in ipairs(colors) do
        if element.color[1] == color[1]
        and element.color[2] == color[2]
        and element.color[3] == color[3] then
            return true
        end
    end
end

function Util.getButton(element, index)
    local child = element.children[index]
    local blankText = child.text == nil or child.text == ""
    local hasChildren = child.children and #child.children > 0
    if blankText and hasChildren  then
        for _, c in ipairs(child.children) do
            if c.text then
                return c
            end
        end
    end
    return child
end

---@param parent  tes3uiElement
function Util.findScrollData(parent)
    logger:trace("Finding scroll pane")
    local id = "PartScrollPane_vert_scrollbar"
    local scrollPaneData
    local function recurse(e)
        if e.children then
            for _, child in ipairs(e.children) do
                logger:trace("child: %s", e.name or "-")
                if child.name == id then
                    local scrollPane = child.parent
                    local contentsElement = scrollPane:getContentElement()
                    logger:trace("Found vert scroll bar on %s", scrollPane.name)
                    for i, _ in ipairs(contentsElement.children) do
                        local button = Util.getButton(contentsElement, i)
                        logger:trace("- %s", button.text or "-")
                        if Util.isActive(button) then
                            logger:trace("Found active button: %s", button.text)
                            scrollPaneData = {
                                scrollPane = scrollPane,
                                contentsElement = contentsElement,
                                index = i,
                            }
                            return
                        end
                    end
                end
                recurse(child)
            end
        end
    end
    recurse(parent)
    return scrollPaneData
end

return Util