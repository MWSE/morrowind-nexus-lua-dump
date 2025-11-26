local module = {}

module.daedraAnyCaseIdBlacklist = {
--  ['<daedraAnyCaseId>'             ] = true, -- <Mod>   - <Daedra>
    ['scamp_creeper'                 ] = true, -- Vanilla - Creeper (Sold equipment is safe)
--  [''] = true, --  - 
}

module.weaponAnyCaseIdBlacklist = {
--  ['<weaponAnyCaseId>'             ] = true, -- <Mod>   - <Daedra> - <Weapon>
--  ['BM_hunterspear_unique'         ] = true, -- Vanilla - Hircine's Aspect of Guile - Spear of the Hunter (Example)
--  [''] = true, --  -  - 
}

module.armorAnyCaseIdBlacklist = {
--  ['<armorAnyCaseId>'              ] = true, -- <Mod>   - <Daedra> - <Armor>
--  ['ebony_closed_helm_fghl'        ] = true, -- Vanilla - Hunger - Sarano Ebony Helm (Example)
--  [''] = true, --  -  - 
}

return module
