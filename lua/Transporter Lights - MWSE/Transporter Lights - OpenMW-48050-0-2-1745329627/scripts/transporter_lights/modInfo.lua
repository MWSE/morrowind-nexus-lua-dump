local CHANGES = [[ 
    Initial Release
    Transporters will equip light at night

    Update for OpenMW 0.49
    Added global interface
]]

return setmetatable({
    MOD_NAME = "Transporter Lights",
    MOD_VERSION = 0.2,
    MIN_API = 70,
    CHANGES = CHANGES
}, {
    __tostring = function(modInfo)
        return string.format("\n[%s]\nVersion: %s\nMinimum API: %s\nChanges: %s", modInfo.MOD_NAME, modInfo.MOD_VERSION, modInfo.MIN_API, modInfo.CHANGES)
    end,
    __metatable = tostring
})

-- require("scripts.transporter_lights.modInfo")
