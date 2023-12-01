local CHANGES = [[
    Initial release
    Embark on a unique journey with Morrowind's favorite scamp merchant, Creeper!
    The daedric trader has decided to expand his business beyond the confines of Ghorak Manor,
    venturing into the diverse towns and cities of Vvardenfell. Follow Creeper's travels as he
    brings his eclectic wares to new locations, offering a dynamic and ever-changing shopping experience.
]]

return setmetatable({
    MOD_NAME = "Roaming Creeper",
    MOD_VERSION = 0.1,
    MIN_API = 51,
    CHANGES = CHANGES
}, {
    __tostring = function(modInfo)
        return string.format("\n[%s]\nVersion: %s\nMinimum API: %s\nChanges: %s", modInfo.MOD_NAME, modInfo.MOD_VERSION,
            modInfo.MIN_API, modInfo.CHANGES)
    end,
    __metatable = tostring
})

-- require("scripts.roaming_creeper.modInfo")
