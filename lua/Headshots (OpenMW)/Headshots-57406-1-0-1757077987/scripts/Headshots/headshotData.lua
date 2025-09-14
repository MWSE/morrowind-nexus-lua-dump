local storage = require("openmw.storage")
local types = require("openmw.types")
local self = require("openmw.self")
require("scripts.Headshots.utils")
require("scripts.Headshots.instakillBlacklist")

local sectionValues = storage.globalSection("SettingsHeadshots_values")
local swt = storage.globalSection("SettingsHeadshots_weaponTypes")

MarksmanScaling = {
    ["Linear"] = function(attacker)
        local fm = sectionValues:get("flatMult")
        local am = TryGetActorMarksman(attacker)
        local mm = sectionValues:get("marksmanMult")
        return fm + am * mm
    end,
    ["Threshold"] = function(attacker)
        local fm = sectionValues:get("flatMult")
        local am = TryGetActorMarksman(attacker)
        local step = sectionValues:get("thresholdStep")
        local mm = sectionValues:get("marksmanMult")
        return fm + IntDiv(am, step) * mm
    end,
    ["Instakill"] = function(attacker)
        if InInstakillBlacklist(self) then return 1
        else return math.huge end
    end
}

function AllowedWeaponType(weapon)
    local weaponTypes = {
        [types.Weapon.TYPE.Arrow] =             swt:get("marksmanBowEnabled"),
        [types.Weapon.TYPE.Bolt] =              swt:get("marksmanCrossbowEnabled"),
        [types.Weapon.TYPE.MarksmanBow] =       swt:get("marksmanBowEnabled"),
        [types.Weapon.TYPE.MarksmanCrossbow] =  swt:get("marksmanCrossbowEnabled"),
        [types.Weapon.TYPE.MarksmanThrown] =    swt:get("marksmanThrownEnabled"),
    }
    return weaponTypes[weapon.type]
end