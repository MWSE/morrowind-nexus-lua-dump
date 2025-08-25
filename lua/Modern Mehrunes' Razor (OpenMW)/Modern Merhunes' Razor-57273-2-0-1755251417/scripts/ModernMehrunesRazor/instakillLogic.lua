local storage = require("openmw.storage")
local self = require("openmw.self")
require("scripts.ModernMehrunesRazor.instakillBlacklist")
require("scripts.ModernMehrunesRazor.instakillData")

local sectionGeneral = storage.globalSection("SettingsModernMehrunesRazor_general")

function DoInstakill(attack)
    if not sectionGeneral:get("modEnabled") then return end
    if not (attack.weapon.recordId == "mehrunes'_razor_unique" and attack.successful) then return end
    if InInstakillBlacklist(self) then return end

    local gameRoll = math.random()
    local preset = Presets[sectionGeneral:get("preset")]
    local instakillChance = preset(attack.attacker)

    if sectionGeneral:get("counterRollEnabled") then
        local el = GetActorLuck(self).modified
        local elm = sectionGeneral:get("counterRollModifier")
        instakillChance = instakillChance - el * elm
    end

    -- scaling down values to floats for precision
    instakillChance = instakillChance / 100
    if instakillChance >= gameRoll then
        attack.damage.health = math.huge
        attack.attacker:sendEvent("onInstakill")
    end

    if sectionGeneral:get("debugMode") then
        print("Modern Mehrunes' Razor debug message!\n" ..
            "Victim:            " .. self.recordId .. "\n" ..
            "Player chance:     " .. preset(attack.attacker) / 100 .. "\n" ..
            "Enemy chance:      " .. GetActorLuck(self).modified * sectionGeneral:get("counterRollModifier") .. "\n" ..
            "Calculated chance: " .. instakillChance .. "\n" ..
            "Game roll:         " .. gameRoll .. "\n" ..
            "Instakill:         " .. tostring(instakillChance >= gameRoll))
    end
end