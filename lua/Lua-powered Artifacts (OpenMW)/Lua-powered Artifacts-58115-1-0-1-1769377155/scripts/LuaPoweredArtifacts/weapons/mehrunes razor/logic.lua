local storage = require("openmw.storage")
local self = require("openmw.self")

require("scripts.LuaPoweredArtifacts.utils.omwUtils")
require("scripts.LuaPoweredArtifacts.weapons.mehrunes razor.data")

local sectionRazor = storage.globalSection("SettingsLuaPoweredArtifacts_razor")

function DoInstakill(attack)
    -- instakill calculation
    local gameRoll = math.random()
    local preset = Presets[sectionRazor:get("preset")]
    local instakillChance = preset(attack.attacker)

    -- counter roll calculation
    if sectionRazor:get("counterRollEnabled") then
        local el = GetActorLuck(self).modified
        local elm = sectionRazor:get("counterRollModifier")
        instakillChance = instakillChance - el * elm
    end

    -- scaling down values to floats for precision
    instakillChance = instakillChance / 100
    if instakillChance >= gameRoll then
        self.type.stats.dynamic.health(self).current = 0
        attack.attacker:sendEvent("RazorInstakill")
    end

    Log("Mehrunes' Razor debug message!\n" ..
        "Victim:            " .. self.recordId .. "\n" ..
        "Player chance:     " .. preset(attack.attacker) / 100 .. "\n" ..
        "Enemy chance:      " .. GetActorLuck(self).modified * sectionRazor:get("counterRollModifier") .. "\n" ..
        "Calculated chance: " .. instakillChance .. "\n" ..
        "Game roll:         " .. gameRoll .. "\n" ..
        "Instakill:         " .. tostring(instakillChance >= gameRoll))
end
