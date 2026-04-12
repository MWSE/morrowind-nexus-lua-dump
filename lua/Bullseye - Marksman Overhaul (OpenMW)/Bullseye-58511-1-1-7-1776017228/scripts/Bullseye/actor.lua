local I = require("openmw.interfaces")
local types = require("openmw.types")
local self = require("openmw.self")
local storage = require("openmw.storage")

require("scripts.Bullseye.logic.headshots")
require("scripts.Bullseye.logic.ammo")

local sectionDamageMult = storage.globalSection("SettingsBullseye_damageMult")

local function getDistanceModifier(distance)
    local maxDist = sectionDamageMult:get("defaultDmgMaxDistance")
    local minDist = sectionDamageMult:get("defaultDmgMinDistance")

    if minDist <= distance and distance < maxDist then
        return 0
    elseif distance < minDist then
        return -1 * (minDist - distance) / 1000 * sectionDamageMult:get("distanceDamageFalloff")
    elseif maxDist <= distance then
        return (distance - maxDist) / 1000 * sectionDamageMult:get("distanceDamageBuildup")
    end
end

local function hitHandler(attack)
    if not attack.successful
        or attack.sourceType ~= I.Combat.ATTACK_SOURCE_TYPES.Ranged
        or attack.attacker.type ~= types.Player
    then
        return
    end

    local isThrown = attack.weapon.id == "@0x0"
        -- HOW THE FUCK
        or types.Weapon.records[attack.weapon.recordId].type == types.Weapon.TYPE.MarksmanThrown
    local distance = (attack.attacker.position - self.position):length()
    local distMod = isThrown and 0 or getDistanceModifier(distance)

    local headMod = HeadshotSuccessful(self, attack.hitPos)
        and sectionDamageMult:get("headshotMultiplier") or 0

    local damageModifier = sectionDamageMult:get("baseMult") + distMod + headMod
    damageModifier = math.max(sectionDamageMult:get("minTotalMult"), damageModifier)
    damageModifier = math.min(sectionDamageMult:get("maxTotalMult"), damageModifier)

    if sectionDamageMult:get("showMultMessage") then
        local headshotLine = headMod == 0
            and "" or string.format("\nHeadshot mult: %.2fx", headMod)

        attack.attacker:sendEvent("ShowMessage", {
            message = string.format(
                "[Bullseye]" ..
                "\nShot distance: %d units" ..
                "\nDistance mult: %.2fx" ..
                headshotLine ..
                "\nFinal damage mult: %.2f",
                distance, distMod, damageModifier
            )
        })
    end

    local headshotVolume = sectionDamageMult:get("playHeadshotSFX")
    if headMod ~= 0 and headshotVolume ~= 0 then
        attack.attacker:sendEvent("Bullseye_PlayHeadshotSFX", headshotVolume)
    end

    attack.damage.health = attack.damage.health * damageModifier
end

local function modifyFight()
    -- https://en.uesp.net/wiki/Morrowind:NPCs#Fight
    local fight = self.type.stats.ai.fight(self)
    if fight.modified >= 70 then
        fight.modifier = fight.modifier + 100
    end
end

I.Combat.addOnHitHandler(AmmoHandler)
I.Combat.addOnHitHandler(hitHandler)

return {
    eventHandlers = {
        Bullseye_modifyFight = modifyFight,
    }
}
