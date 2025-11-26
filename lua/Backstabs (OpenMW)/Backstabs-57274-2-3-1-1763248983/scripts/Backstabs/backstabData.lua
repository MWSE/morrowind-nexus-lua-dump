local storage = require("openmw.storage")
local types = require("openmw.types")
local self = require("openmw.self")
require("scripts.Backstabs.utils")
require("scripts.Backstabs.instakillBlacklist")

local sectionValues = storage.globalSection("SettingsBackstabs_values")
local swt = storage.globalSection("SettingsBackstabs_weaponTypes")

InstakillWeapons = {
    "mehrunes'_razor_unique"
}

Modes = {
    ["Linear"] = function(attacker)
        local fm = sectionValues:get("flatMult")
        local as = TryGetActorSneak(attacker)
        local sm = sectionValues:get("sneakMult")
        return fm + as * sm
    end,
    ["Threshold"] = function(attacker)
        local fm = sectionValues:get("flatMult")
        local as = TryGetActorSneak(attacker)
        local step = sectionValues:get("thresholdStep")
        local sm = sectionValues:get("sneakMult")
        return fm + IntDiv(as, step) * sm
    end,
    ["Instakill"] = function(attacker)
        if InInstakillBlacklist(self) then return 1
        else return math.huge end
    end
}

WeaponTypes = {
    [types.Weapon.TYPE.Arrow] =                 function() return swt:get("marksmanBowEnabled") end,
    [types.Weapon.TYPE.AxeOneHand] =            function() return swt:get("axeOneEnabled") end,
    [types.Weapon.TYPE.AxeTwoHand] =            function() return swt:get("axeTwoEnabled") end,
    [types.Weapon.TYPE.BluntOneHand] =          function() return swt:get("bluntOneEnabled") end,
    [types.Weapon.TYPE.BluntTwoClose] =         function() return swt:get("bluntTwoCloseEnabled") end,
    [types.Weapon.TYPE.BluntTwoWide] =          function() return swt:get("bluntTwoWideEnabled") end,
    [types.Weapon.TYPE.Bolt] =                  function() return swt:get("marksmanCrossbowEnabled") end,
    [types.Weapon.TYPE.LongBladeOneHand] =      function() return swt:get("longBladeOneEnabled") end,
    [types.Weapon.TYPE.LongBladeTwoHand] =      function() return swt:get("longBladeTwoEnabled") end,
    [types.Weapon.TYPE.MarksmanBow] =           function() return swt:get("marksmanBowEnabled") end,
    [types.Weapon.TYPE.MarksmanCrossbow] =      function() return swt:get("marksmanCrossbowEnabled") end,
    [types.Weapon.TYPE.MarksmanThrown] =        function() return swt:get("marksmanThrownEnabled") end,
    [types.Weapon.TYPE.ShortBladeOneHand] =     function() return swt:get("shortBladesnabled") end,
    [types.Weapon.TYPE.SpearTwoWide] =          function() return swt:get("spearsEnabled") end,
}
