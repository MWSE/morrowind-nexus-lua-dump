local core = require("openmw.core")
local util = require("openmw.util")

local commaString = (
    util.color.commaString
    or function(gmstValue)
        local r, g, b = assert(gmstValue:match("%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*"))
        return util.color.rgb(tonumber(r) / 255, tonumber(g) / 255, tonumber(b) / 255)
    end
)

---@diagnostic disable
local fontcolor_color_normal = commaString(core.getGMST("FontColor_color_normal"))
local fontcolor_color_normal_over = commaString(core.getGMST("FontColor_color_normal_over"))
local fontcolor_color_normal_pressed = commaString(core.getGMST("FontColor_color_normal_pressed"))
local fontcolor_color_active = commaString(core.getGMST("FontColor_color_active"))
local fontcolor_color_active_over = commaString(core.getGMST("FontColor_color_active_over"))
local fontcolor_color_active_pressed = commaString(core.getGMST("FontColor_color_active_pressed"))
local fontcolor_color_disabled = commaString(core.getGMST("FontColor_color_disabled"))
---@diagnostic enable


---@class FontColors
local this = {}


---@param isSelected boolean?
---@return Color
function this.getNormalColor(isSelected)
    return isSelected and fontcolor_color_active or fontcolor_color_normal
end


---@param isSelected boolean?
---@return Color
function this.getOverColor(isSelected)
    return isSelected and fontcolor_color_active_over or fontcolor_color_normal_over
end


---@param isSelected boolean?
---@return Color
function this.getActiveColor(isSelected)
    return isSelected and fontcolor_color_active_pressed or fontcolor_color_normal_pressed
end


---@param isSelected boolean?
---@param isPressed boolean?
---@return Color
function this.getColor(isSelected, isPressed)
    if isSelected and isPressed then
        return this.getActiveColor(isSelected)
    else
        return this.getNormalColor(isSelected)
    end
end


---@return Color
function this.getDisabledColor()
    return fontcolor_color_disabled
end


return this
