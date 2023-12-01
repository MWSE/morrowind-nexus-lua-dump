local CHANGES = [[
    Initial Release
]]

return setmetatable({
    MOD_NAME = "Cursed Offerings",
    MOD_VERSION = 0.1,
    MIN_API = 50,
    CHANGES = CHANGES
}, {
    __tostring = function(modInfo)
        return string.format("\n[%s]\nVersion: %s\nMinimum API: %s\nChanges: %s", modInfo.MOD_NAME, modInfo.MOD_VERSION,
            modInfo.MIN_API, modInfo.CHANGES)
    end,
    __metatable = tostring
})

-- require("scripts.cursed_offerings.modInfo")
