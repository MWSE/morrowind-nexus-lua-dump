local interop = {}

---@class weapon
---@field id string
---@field handles string[] Handle node(s).
---@field blades string[] Blade node(s).
---@field rootIndexes integer[] Root node indexes.

---@type table<string, table<string[], string[], integer[]>>
interop.weaponList = {}

-- ---@class part
-- ---@field id string
-- ---@field yOffset integer

-- ---@type table<string, boolean>
-- interop.partList = {}

---@param weapon weapon
function interop:registerWeapon(weapon)
    interop.weaponList[weapon.id] = { handles = weapon.handles, blades = weapon.blades, rootIndexes = weapon.rootIndexes }
end

---@param weapons weapon[]
function interop:registerWeapons(weapons)
    for id, weapon in pairs(weapons) do
        if (type(id) == "string") then
            interop:registerWeapon{ id = id, handles = weapon.handles, blades = weapon.blades, rootIndexes = weapon.rootIndexes }
        else
            interop:registerWeapon(weapon)
        end
    end
end

-- ---@param part part
-- function interop:registerPart(part)
--     interop.partList[part.id] = part or 0
-- end

-- ---@param parts part[]
-- function interop:registerParts(parts)
--     for id, part in pairs(parts) do
--         if (type(id) == "string") then
--             interop:registerPart{ id = id, yOffset = part.yOffset }
--         else
--             interop:registerPart(part)
--         end
--     end
-- end

return interop