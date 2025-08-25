local types = require('openmw.types')

local supportedObjectTypes = {
    [types.NPC] = true,
    [types.Creature] = true,
    [types.Apparatus] = true,
    [types.Armor] = true,
    [types.Book] = true,
    [types.Clothing] = true,
    [types.Container] = true,
    [types.Door] = true,
    [types.Ingredient] = true,
    [types.Light] = true,
    [types.Lockpick] = true,
    [types.Miscellaneous] = true,
    [types.Potion] = true,
    [types.Probe] = true,
    [types.Repair] = true,
    [types.Weapon] = true,
}

---@param id string
---@return any? record
---@return any? type
return function(id)
    for tp, _ in pairs(supportedObjectTypes) do
        local rec = tp.record(id)
        if rec then return rec, tp end
    end
    return nil
end