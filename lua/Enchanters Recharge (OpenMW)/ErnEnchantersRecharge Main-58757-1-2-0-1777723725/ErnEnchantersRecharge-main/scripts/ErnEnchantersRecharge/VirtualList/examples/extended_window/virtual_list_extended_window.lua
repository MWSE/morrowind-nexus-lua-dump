local ui = require("openmw.ui")
local util = require("openmw.util")
local input = require("openmw.input")

local I = require("openmw.interfaces")

local lib = require("scripts.extended_window.virtual_list.extras")

---@type VirtualListExt
local List = lib.VirtualListExt

--- We'll render a list of random strings.

local items = {}

for i = 1, 10000 do
    items[i] = "Item " .. i
end

-- Use hotkey X to toggle the window on/off.

local window

local windowPosition = util.vector2(0.5, 0.5)
local windowSize = util.vector2(400, 800)
local itemSize = util.vector2(400, 16)

local function onKeyPressX()
    -- Note the list must know the sizes involved to do its math.
    local list = List.create({
        viewportSize = windowSize,
        itemSize = itemSize,
        itemCount = #items,
        itemLayout = function(i, list)
            return list:createItemLayout({
                index = i,
                props = {
                    text = items[i],
                },
                onMousePress = function(e) -- Optional mouse press handler
                    if e.button == 1 then
                        list:changeSelection(i)
                        ui.showMessage("Mouse press: " .. items[i])
                    end
                end,
            })
        end,
    })

    -- Optionally we can set a key press handler for the list.
    list:setKeyPressHandler({
        setSelectedIndex = function(i)
            list:changeSelection(i)
            ui.showMessage("Key press: " .. items[i])
        end,
    })

    -- Put our list in a bordered window with a black background.
    window = ui.create({
        layer = "Windows",
        type = ui.TYPE.Image,
        template = I.MWUI.templates.borders,
        props = {
            size = windowSize,
            anchor = windowPosition,
            relativePosition = windowPosition,
            resource = ui.texture({ path = "black" }),
        },
        content = ui.content({ list:getElement() }),
    })
end

return {
    engineHandlers = {
        onKeyPress = function(key)
            if key.code == input.KEY.X then
                if window == nil then
                    onKeyPressX()
                else
                    window:destroy()
                    window = nil
                end
            end
        end,
        -- Optional mouse wheel handling for scrolling.
        onMouseWheel = List.getMouseWheelHandler(),
    },
}
