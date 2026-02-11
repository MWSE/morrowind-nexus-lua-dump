local storage = require("openmw.storage")
local self = require("openmw.self")

require("scripts.LuaPoweredArtifacts.utils.omwUtils")
require("scripts.LuaPoweredArtifacts.utils.consts")

local sectionScourge = storage.globalSection("SettingsLuaPoweredArtifacts_scourge")

function DoBanish(attack)
    local dmgMult = 0
    if SummonedDaedra[self.recordId] then
        dmgMult = sectionScourge:get("summonedDaedraDmgModifier")
    elseif self.type.records[self.recordId].type == 1 then
        dmgMult = sectionScourge:get("normalDaedraDmgModifier")
    end

    local msg = "Scourge debug messagen" ..
        "Victim:      " .. self.recordId .. "\n" ..
        "Is summoned: " .. tostring(SummonedDaedra[self.recordId] ~= nil) .. "\n" ..
        "Is normal:   " .. tostring(self.type.records[self.recordId].type == 1) .. "\n" ..
        "Damage mult: " .. tostring(dmgMult)

    if dmgMult > 0 then
        msg = msg .. "\n" ..
            "Initial HP damage:      " .. tostring(attack.damage.health) .. "\n" ..
            "Final HP damage:        " .. tostring(attack.damage.health and attack.damage.health * dmgMult) .. "\n" ..
            "Initial fatigue damage: " .. tostring(attack.damage.fatigue) .. "\n" ..
            "Final fatigue damage:   " .. tostring(attack.damage.fatigue and attack.damage.fatigue * dmgMult)
        
        attack.damage.health = attack.damage.health and attack.damage.health * dmgMult
        attack.damage.fatigue = attack.damage.fatigue and attack.damage.fatigue * dmgMult

    elseif dmgMult < 0 then
        msg = msg .. "\n" ..
            "Instakill:   " .. tostring(dmgMult < 0)

        self.type.stats.dynamic.health(self).current = 0
        if sectionScourge:get("instakillPreventsSoultrap") then
            ---@diagnostic disable-next-line: missing-parameter
            self.type.activeEffects(self):remove("soultrap")
        end
        attack.attacker:sendEvent("ScourgeInstakill")
    end

    if dmgMult ~= 0 then
        Log(msg)
    end
end
