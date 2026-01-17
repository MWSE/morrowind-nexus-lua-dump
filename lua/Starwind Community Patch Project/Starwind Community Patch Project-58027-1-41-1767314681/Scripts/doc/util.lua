---@module 'openmw.util'
local util = {}

---@class openmw.util
---@field vector2 util.vector2
---@field vector3 util.vector3
---@field remap fun(value: number, oldMin: number, oldMax: number, newMin: number, newMax: number): number remap a value from one range into another
---@field round fun(value: number): number rounds a number to the nearest whole integer
---@field color.rgb fun(r: number, g: number, b: number): util.color Given normalized values for RGB channels, return a color
---@field color.rgba fun(r: number, g: number, b: number, a: number): util.color Given normalized values for RGBA channels, return a color
---@field color.hex fun(hexColor: string): util.color Given a valid hex color string, return a color

return util
