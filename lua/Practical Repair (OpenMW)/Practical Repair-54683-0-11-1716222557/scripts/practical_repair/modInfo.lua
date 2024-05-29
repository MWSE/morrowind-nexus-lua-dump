local CHANGES = [[ 
    Added checks when activating uninteractable objects such as statics
    Added missing template file addWorkstations.lua
    Handles rare cases of errors when activating a workstation
    Added an interface function -blockActivation(actor)- to allow other mods to block activation of a station
]]

return setmetatable({
    MOD_NAME = "Practical Repair",
    MOD_VERSION = 0.11,
    MIN_API = 60,
    CHANGES = CHANGES
}, {
    __tostring = function(modInfo)
        return string.format("\n[%s]\nVersion: %s\nMinimum API: %s\nChanges: %s", modInfo.MOD_NAME, modInfo.MOD_VERSION, modInfo.MIN_API, modInfo.CHANGES)
    end,
    __metatable = tostring
})

-- require("scripts.practical_repair.modInfo")
