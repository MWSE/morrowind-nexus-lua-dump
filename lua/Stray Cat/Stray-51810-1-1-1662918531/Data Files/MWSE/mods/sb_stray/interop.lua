local interop = {}

interop.raceBreedAssociation = {
    ["Argonian"] = "sb_cat_tabby",
    ["Breton"] = "sb_cat_silver",
    ["Dark Elf"] = "sb_cat_grey",
    ["High Elf"] = "sb_cat_silver",
    ["Imperial"] = "sb_cat_silver",
    ["Khajiit"] = "sb_cat_orange",
    ["Nord"] = "sb_cat_silver",
    ["Orc"] = "sb_cat_tabby",
    ["Redguard"] = "sb_cat_black",
    ["Wood Elf"] = "sb_cat_silver"
}

interop.item = "sb_stray_collar"

interop.spell = "sb_stray_purr"

---@type tes3reference
interop.cat = nil

---Register a new race-breed association.
---@param race string
---@param breed string
function interop.register(race, breed)
    interop.raceBreedAssociation[race] = breed
end

return interop
