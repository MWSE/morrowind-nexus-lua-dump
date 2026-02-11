local interop = {}
--[[ 
    Damage category
        1: Slashing
        2: Piercing
        3: Bludgeoning
    Attack types per the Physical Attack Types table in tes3, which align nicely with the array
        1 Slash
        2 Chop
        3 Thrust
]]
interop.weaponAttackTypes = {
       {tes3.weaponType.shortBladeOneHand,  {1, 1, 2}},
       {tes3.weaponType.longBladeOneHand,   {1, 1, 2}},
       {tes3.weaponType.longBladeTwoClose,  {1, 1, 2}},
       {tes3.weaponType.bluntOneHand,       {3, 3, 3}},
       {tes3.weaponType.bluntTwoClose,      {3, 3, 3}},
       {tes3.weaponType.bluntTwoWide,       {3, 3, 3}},
       {tes3.weaponType.spearTwoWide,       {1, 1, 2}},
       {tes3.weaponType.axeOneHand,         {1, 1, 3}},
       {tes3.weaponType.axeTwoHand,         {1, 1, 3}},
--     {tes3.weaponType.marksmanBow,        {3, 3, 3}}, -- Not needed
--     {tes3.weaponType.marksmanCrossbow,   {3, 3, 3}}, -- Not needed
       {tes3.weaponType.marksmanThrown,     {2, 2, 2}},
       {tes3.weaponType.arrow,              {2, 2, 2}},
       {tes3.weaponType.bolt,               {2, 2, 2}},
       {"kungFu",                           {3, 3, 3}},
    }

---@class creature
---@field [1] number Damage modifier for slashing attacks.
---@field [2] number Damage modifier for piercing attacks.
---@field [3] number Damage modifier for bludgeoning attacks.
---@field [4] integer Material type the creature is weak/resistant against.
---@field [5] number Bonus damage applied for that material.
--[[ Example:
    creatures["skeleton"] = {0.75, 0.25, 1.75, 4, 0.5}
]]
---@alias UniqueWeaponEntry { [1]: number, [2]: number, [3]: number }
---@type table<string, UniqueWeaponEntry>
-- uniqueWeapons["weapon_id"] = {slashMod, pierceMod, bludgeonMod, materialType, materialBonus}

---@alias MaterialWeaponEntry { [1]: integer, [2]: number }
---@type table<string, MaterialWeaponEntry>
-- materialsWeapons["weapon_id"] = {materialType, defaultMaterialBonus}


interop.creatures           = {}
interop.uniqueWeapons       = {}
interop.materialsWeapons    = {}

interop.modifiersMessages   = {
    ["0"]    = "Utterly ineffective!",
    ["0.25"] = "Just a scratch.",
    ["0.5"]  = "That did not do much.",
    ["0.75"] = "Did not bite deep.",
 
    ["1.25"] = "Solid blow.",
    ["1.5"]  = "Good strike.",
    ["1.75"] = "Very effective.",
    ["2"]    = "Savage!"
}

return interop
