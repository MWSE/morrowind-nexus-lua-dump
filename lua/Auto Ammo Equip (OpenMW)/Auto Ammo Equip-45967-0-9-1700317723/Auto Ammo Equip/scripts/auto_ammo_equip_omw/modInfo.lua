local CHANGES = [[
    Initial Release
    Automatically equips ammunition for marksman weapons
]]

return setmetatable({
    MOD_NAME = "Auto Ammo Equip",
    MOD_VERSION = 0.9,
    MIN_API = 50,
    CHANGES = CHANGES
}, {
    __tostring = function(modInfo)
        return string.format("\n[%s]\nVersion: %s\nMinimum API: %s\nChanges: %s", modInfo.MOD_NAME, modInfo.MOD_VERSION,
            modInfo.MIN_API, modInfo.CHANGES)
    end,
    __metatable = tostring
})

-- require("scripts.auto_ammo_equip_omw.modInfo")
