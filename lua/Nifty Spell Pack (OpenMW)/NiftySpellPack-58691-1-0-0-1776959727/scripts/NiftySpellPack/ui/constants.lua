local core = require('openmw.core')
local util = require('openmw.util')

local colorFromGMST = function(gmst)
    local colorString = core.getGMST(gmst)
    local numberTable = {}
    for numberString in colorString:gmatch("([^,]+)") do
        if #numberTable == 3 then break end
        local number = tonumber(numberString:match("^%s*(.-)%s*$"))
        if number then
            table.insert(numberTable, number / 255)
        end
    end

    if #numberTable < 3 then error('Invalid color GMST name: ' .. gmst) end

    return util.color.rgb(table.unpack(numberTable))
end

local Constants = {}

Constants.SCROLL_BAR_OUTER_WIDTH = 16
Constants.SCROLL_BAR_INNER_WIDTH = 14

-- Colors
Constants.uiColors = {
    -- GMST colors
    DEFAULT = colorFromGMST('fontcolor_color_normal'),
    DEFAULT_LIGHT = colorFromGMST('fontcolor_color_normal_over'),
    DEFAULT_PRESSED = colorFromGMST('fontcolor_color_normal_pressed'),
    ACTIVE = colorFromGMST('fontcolor_color_active'),
    ACTIVE_LIGHT = colorFromGMST('fontcolor_color_active_over'),
    ACTIVE_PRESSED = colorFromGMST('fontcolor_color_active_pressed'),
    DISABLED = colorFromGMST('fontcolor_color_disabled'),
    DISABLED_LIGHT = colorFromGMST('fontcolor_color_disabled_over'),
    DISABLED_PRESSED = colorFromGMST('fontcolor_color_disabled_pressed'),
    -- Preset colors
    WHITE = util.color.rgb(1, 1, 1),
    GRAY = util.color.rgb(0.5, 0.5, 0.5),
    BLACK = util.color.rgb(0, 0, 0),
    CYAN = util.color.rgb(0, 1, 1),
    YELLOW = util.color.rgb(1, 1, 0),
    RED = util.color.rgb(1, 0, 0),
    DARK_RED = util.color.rgb(0.5, 0, 0),
    -- Magic colors
    CONJURATION = util.color.rgb(255/255, 243/255, 173/255),
    MYSTICISM = util.color.rgb(249/255, 224/255, 255/255),
}

return Constants
