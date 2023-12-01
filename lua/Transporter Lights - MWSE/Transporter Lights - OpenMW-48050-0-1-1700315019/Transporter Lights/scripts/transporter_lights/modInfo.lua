local CHANGES = [[ 
    Initial Release
    Transporters will equip light at night
]]

return setmetatable({
    MOD_NAME = "Transporter Lights",
    MOD_VERSION = 0.1,
    MIN_API = 37,
    CHANGES = CHANGES
}, {
    __tostring = function(modInfo)
        return string.format("\n[%s]\nVersion: %s\nMinimum API: %s\nChanges: %s", modInfo.MOD_NAME, modInfo.MOD_VERSION, modInfo.MIN_API, modInfo.CHANGES)
    end,
    __metatable = tostring
})

-- require("scripts.transporter_lights.modInfo")
