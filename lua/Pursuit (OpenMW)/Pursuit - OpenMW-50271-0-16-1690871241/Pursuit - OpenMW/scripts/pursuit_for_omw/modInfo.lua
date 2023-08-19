local CHANGES = [[ 
    Added creature pursuit setting
    Added NPC return setting
    Added interface for mod interop
    Added vampire check (API > 39)
    Added locked door check (API > 39)
]]

return setmetatable({
    MOD_NAME = "Pursuit",
    MOD_VERSION = 0.16,
    MIN_API = 29,
    CHANGES = CHANGES
}, {
    __tostring = function(modInfo)
        return string.format("\n[%s]\nVersion: %s\nMinimum API: %s\nChanges: %s", modInfo.MOD_NAME, modInfo.MOD_VERSION, modInfo.MIN_API, modInfo.CHANGES)
    end,
    __metatable = tostring
})

-- require("scripts.pursuit_for_omw.modInfo")
