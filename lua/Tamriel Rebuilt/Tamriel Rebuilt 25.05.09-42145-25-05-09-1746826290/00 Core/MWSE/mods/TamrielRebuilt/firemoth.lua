-- NB: this file is used by both MWSE and OpenMW.

-- List of Firemoth mods that require the remover plugin.
local mods = {
    "Siege at Firemoth.esp",
    "LegionAtFiremoth.esp",
    "FiremothReclaimed.esp",
    "OfficialMods_v5.esp",
    "Unofficial Morrowind Official Plugins Patched.esp",
    "Ogg Fort Firemoth Manor.esp",
}

return function(isActive)
    for k, mod in pairs(mods) do
        if isActive(mod) then
            return mod
        end
    end
end
