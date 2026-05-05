local util = require("openmw.util")
local core = require('openmw.core')

local colorFromGMST = function(gmst)
    local colorString = core.getGMST(gmst)
    local numberTable = {}
    ---@diagnostic disable-next-line: need-check-nil
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

local C = {}

C.Colors = {
    -- CFG colors
    DEFAULT          = colorFromGMST('fontcolor_color_normal'),
    DEFAULT_LIGHT    = colorFromGMST('fontcolor_color_normal_over'),
    DEFAULT_PRESSED  = colorFromGMST('fontcolor_color_normal_pressed'),
    ACTIVE           = colorFromGMST('fontcolor_color_active'),
    ACTIVE_LIGHT     = colorFromGMST('fontcolor_color_active_over'),
    ACTIVE_PRESSED   = colorFromGMST('fontcolor_color_active_pressed'),
    DISABLED         = colorFromGMST('fontcolor_color_disabled'),
    DISABLED_LIGHT   = colorFromGMST('fontcolor_color_disabled_over'),
    DISABLED_PRESSED = colorFromGMST('fontcolor_color_disabled_pressed'),
    BAR_HEALTH       = colorFromGMST('fontcolor_color_health'),
    BAR_MAGIC        = colorFromGMST('fontcolor_color_magic'),
    BAR_FATIGUE      = colorFromGMST('fontcolor_color_fatigue'),
    POSITIVE         = colorFromGMST('fontcolor_color_positive'),
    DAMAGED          = colorFromGMST('fontcolor_color_negative'),
    BACKGROUND       = colorFromGMST('fontcolor_color_background'),
    -- Generic colors
    WHITE            = util.color.rgb(1, 1, 1),
    GRAY             = util.color.rgb(0.5, 0.5, 0.5),
    DARK_GRAY        = util.color.rgb(0.25, 0.25, 0.25),
    BLACK            = util.color.rgb(0, 0, 0),
    CYAN             = util.color.rgb(0, 1, 1),
    YELLOW           = util.color.rgb(1, 1, 0),
    RED              = util.color.rgb(1, 0, 0),
    DARK_RED         = util.color.rgb(0.5, 0, 0),
    RED_DESAT        = util.color.rgb(0.7, 0.3, 0.3),
    DARK_RED_DESAT   = util.color.rgb(0.3, 0.05, 0.05),
}

return C