local interop = {}

---@param list string List starting with "n_", ending with "_n", or has an associated list starting / ending with the previous strings.
---@param creature string A creature to insert.
---@param level number At which player level the creature can be resolved from the leveled list.
---@return boolean
function interop.AddToList(list, creature, level)
    ---@type tes3leveledCreature
    local listObj = (list:startswith("n_") or list:endswith("_n")) and tes3.getObject(list) or
        tes3.getObject("n_" .. list) or tes3.getObject(list .. "_n")
    return listObj and listObj:insert(tes3.getObject(creature), level) or false
end

---@param list string List starting with "n_", ending with "_n", or has an associated list starting / ending with the previous strings.
---@param creature string A creature to remove.
---@param level number At which player level the creature can be resolved from the leveled list.
---@return boolean
function interop.RemoveFromList(list, creature, level)
    ---@type tes3leveledCreature
    local listObj = (list:startswith("n_") or list:endswith("_n")) and tes3.getObject(list) or
        tes3.getObject("n_" .. list) or tes3.getObject(list .. "_n")
    return listObj and listObj:remove(tes3.getObject(creature), level) or false
end

---@param list string List starting with "n_", ending with "_n", or has an associated list starting / ending with the previous strings.
---@param creature string A creature to update.
---@param oldLevel number At which player level the creature can be resolved from the leveled list.
---@param newLevel number At which player level the creature can be resolved from the leveled list.
---@return boolean
function interop.AdjustLevel(list, creature, oldLevel, newLevel)
    ---@type tes3leveledCreature
    local listObj = (list:startswith("n_") or list:endswith("_n")) and tes3.getObject(list) or
        tes3.getObject("n_" .. list) or tes3.getObject(list .. "_n")
    if (listObj and interop.RemoveFromList(list, creature, oldLevel) or false) then
        return listObj and interop.AddToList(list, creature, newLevel) or false
    end
    return false
end

return interop
