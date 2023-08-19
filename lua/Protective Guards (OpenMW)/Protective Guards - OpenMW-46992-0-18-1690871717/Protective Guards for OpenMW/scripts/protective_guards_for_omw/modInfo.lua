local CHANGES = [[ 
    Added interface for mod interop
    Added werewolf check (API > 39)
    Use getCrimeLevel check (API > 39)
]]

return setmetatable({
    MOD_NAME = "Protective Guards",
    MOD_VERSION = 0.18,
    MIN_API = 29,
    CHANGES = CHANGES
}, {
    __tostring = function(modInfo)
        return string.format("\n[%s]\nVersion: %s\nMinimum API: %s\nChanges: %s", modInfo.MOD_NAME, modInfo.MOD_VERSION, modInfo.MIN_API, modInfo.CHANGES)
    end,
    __metatable = tostring
})

-- require("scripts.protective_guards_for_omw.modInfo")