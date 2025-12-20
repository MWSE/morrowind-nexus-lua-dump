local mHelpers = require("scripts.fresh-loot.util.helpers")
local log = require("scripts.fresh-loot.util.log")

--[[
Modifiers have levels: 1 to 5
Stats of the different levels of a modifier are represented by arrays, false values mean no mod for that level
Fields supporting levels are: multipliers, modifiers, effects.{min, max, duration}, and levels for effects without min/max/duration
- value (price) field:
  * the value field is multiplied by the level and added to the base item value
  * for multipliers fields, the value is first added to the the base item value and the total is multiplied by the level
- itemTypes can be set to:
  * true: All items of that type
  * table:
    - Either select only those in the "types" field or select all except those in the "notTypes" field
    - For armor, all armors or only those matching the "classes" field
- cost and charge define level 1 modifiers, and will be multiplied by the level
]]

local modifiers = {}
for _, category in ipairs({ "properties", "alteration", "conjuration", "destruction", "illusion", "mysticism", "restoration", "multi-schools", "compromises" }) do
    local mods = require("scripts.fresh-loot.modifiers." .. category)
    log(string.format("Found %d modifiers in the \"%s\" category", #mods, category))
    mHelpers.addArrayToArray(modifiers, mods)
end

return modifiers
