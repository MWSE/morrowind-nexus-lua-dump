local storage = require("openmw.storage")
local types = require("openmw.types")
local self = require("openmw.self")
require("scripts.Headshots.headshotData")

local sectionValues = storage.globalSection("SettingsHeadshots_values")
local sectionDebug = storage.globalSection("SettingsHeadshots_debug")

local function headHit(attack)
    local headShotLevel = sectionValues:get("headHeight")
    -- code from Ranged Headshot mod by SkyHasCats
    -- https://modding-openmw.gitlab.io/ranged-headshot/
    local bbox = self:getBoundingBox()
    local half = bbox.halfSize
    local center = bbox.center
    -- Local hit position relative to center
    local rel = attack.hitPos - center
    -- Convert to 0..1 along vertical axis
    -- bottom = -half.z, top = +half.z
    local normalizedHeight = (rel.z + half.z) / (2 * half.z)
    -- print(string.format("Hit height ratio: %.2f", normalizedHeight))
    if normalizedHeight > headShotLevel then
        return true
    else
        return false
    end
end

local function isHeadshotSuccessful(attack)
    -- basic attack check
    if not (attack.successful and attack.sourceType == "ranged") then return false end
    -- weapon type check
    local weaponRecord = types.Weapon.record(attack.ammo)
    if not AllowedWeaponType(weaponRecord) then return false end
    -- we chill if head takes 100% of the hitbox
    if not headHit(attack) then return false end
    -- distance check
    local distance = (attack.attacker.position - self.position):length()
    if distance < sectionValues:get("distanceMin") then return false end

    return true
end

local function getHeadshotMultiplier(attack)
    -- initial damage mult calculation
    local scale = MarksmanScaling[sectionValues:get("mode")]
    local damageMult = scale(attack.attacker)

    local distance = (attack.attacker.position - self.position):length()
    damageMult = damageMult + distance * sectionValues:get("damagePerUnit") / 1000

    if sectionDebug:get("printToConsole") then
        print("Headshots multiplier debug message!" ..
            "\nVictim:                  " .. self.recordId ..
            "\nAmmo used:               " .. attack.ammo ..
            "\nDistance between actors: " .. tostring(distance) ..
            "\nDamage modifier:        x" .. tostring(damageMult)..
            "\nInitital damage:         " .. tostring(attack.damage.health)..
            "\nFinal damage:            " .. tostring(attack.damage.health * damageMult))
    end

    -- you shouldn't be able to hit for less damage
    return math.max(damageMult, 1)
end

function DoHeadshot(attack)
    -- if the mod is disabled
    if sectionValues:get("headSize") == 1 then return end
    
    if not isHeadshotSuccessful(attack) then return end

    local damageMult = getHeadshotMultiplier(attack)
    if damageMult == 1 then return end
    local distance = (attack.attacker.position - self.position):length()

    attack.damage.health = attack.damage.health * damageMult

    attack.attacker:sendEvent("onHeadshot", {damageMult, distance})
end
