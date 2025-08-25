local types = require('openmw.types')

local getObject = require("scripts.quest_guider_lite.core.getObject")


local this = {}


local itemTypes = {
    [types.Apparatus] = true,
    [types.Armor] = true,
    [types.Book] = true,
    [types.Clothing] = true,
    [types.Ingredient] = true,
    [types.Light] = true,
    [types.Lockpick] = true,
    [types.Miscellaneous] = true,
    [types.Potion] = true,
    [types.Probe] = true,
    [types.Repair] = true,
    [types.Weapon] = true,
}


---@param recordId string
---@return boolean?
function this.isItem(recordId)
    local object, objectType = getObject(recordId)
    if not objectType then return end

    return itemTypes[objectType] and true or false
end


return this