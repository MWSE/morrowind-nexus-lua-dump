local storage = require("openmw.storage")
local types = require("openmw.types")
local self = require("openmw.self")
local I = require('openmw.interfaces')
require("scripts.Backstabs.backstabData")

local sectionToggles = storage.globalSection("SettingsBackstabs_toggles")
local sectionValues = storage.globalSection("SettingsBackstabs_values")
local sectionWeaponTypes = storage.globalSection("SettingsBackstabs_weaponTypes")
local sectionDebug = storage.globalSection("SettingsBackstabs_debug")

local selfIsPlayer = self.type == types.Player
PlayerIsSneaking = false
PlayerIsInvisible = false

function UpdatePlayerSneakStatus(currentSneakStatus)
    PlayerIsSneaking = currentSneakStatus
end

function UpdatePlayerInvisStatus(currentInvisStatus)
    PlayerIsInvisible = currentInvisStatus
end

local function isBackstabSuccessful(attack)
    -- basic attack check
    if not (
        attack.successful
        and (attack.sourceType == "melee"
            or attack.sourceType == "ranged"
        )
    ) then
        return false
    end

    if sectionDebug:get("alwaysBackstab") then return true end

    -- weapon type check
    local weapon = attack.weapon
    if weapon then
        -- armed attack
        local weaponType = types.Weapon.record(weapon.recordId).type
        if not WeaponTypes[weaponType]() then return false end
    else
        -- unarmed attack
        if (selfIsPlayer and not sectionToggles:get("creatureBackstabsEnabled"))
            or (not selfIsPlayer and not sectionWeaponTypes:get("h2hEnabled"))
        then
            return false
        end
    end

    -- player crouch check
    if attack.attacker.type == types.Player
        and sectionToggles:get("requireCrouching")
        and not PlayerIsSneaking
    then
        return false
    end

    -- check attacker active effects
    local chameleonEffect = types.Actor.activeEffects(attack.attacker):getEffect("chameleon")
    if chameleonEffect.magnitude >= 100 then return true end
    if PlayerIsInvisible then return true end

    -- check if attacker is seen
    local attackerYaw = attack.attacker.rotation:getYaw()
    local victimYaw = self.rotation:getYaw()
    local diff = math.abs(victimYaw - attackerYaw)
    local npcFov = math.pi * math.abs(sectionValues:get("npcFov") - 360) / 360
    if diff > npcFov then return false end

    -- if all checks passed, backstab is successful
    return true
end

local function getBackstabMultiplier(attack)
    -- init damage mult calculation
    local mode = Modes[sectionValues:get("mode")]
    local damageMult = mode(attack.attacker)

    -- [[special cases]]
    -- if actor is an npc in combat
    if (not selfIsPlayer
            and I.AI.getActivePackage() ~= nil
            and I.AI.getActivePackage().type == "Combat")
        -- or a player has a weapon or spell ready
        or (selfIsPlayer and types.Actor.getStance(self) ~= types.Actor.STANCE.Nothing)
    then
        damageMult = damageMult * sectionValues:get("fightingMult")
    end
    -- special weapon used
    if sectionToggles:get("enableSpecialWeaponInstakill")
        and InInstakillBlacklist(attack.attacker)
        and attack.weapon
    then
        for _, instakillWeapon in ipairs(InstakillWeapons) do
            if attack.weapon.recordId == instakillWeapon then
                damageMult = math.huge
                break
            end
        end
    end

    -- you shouldn't be able to hit for less damage
    damageMult = math.max(damageMult, 1)

    if sectionDebug:get("printToConsole") then
        print("Backstabs multiplier debug message!" ..
            "\nAttacker:            " .. attack.attacker.recordId ..
            "\nVictim:              " .. self.recordId ..
            "\nIs victim in combat: " .. tostring(
                not selfIsPlayer
                and I.AI.getActivePackage() ~= nil
                and I.AI.getActivePackage().type == "Combat") ..
            "\nWeapon used:         " ..
            (attack.weapon ~= nil and attack.weapon.recordId or "nil") ..
            "\nDamage modifier:     x" .. tostring(damageMult))
    end

    return damageMult
end

function DoBackstab(attack)
    if not sectionToggles:get("modEnabled") then return end

    if not isBackstabSuccessful(attack) then return end

    local damageMult = getBackstabMultiplier(attack)
    if damageMult == 1 then return end

    -- mesage for debugging
    local msg = "Backstabs damage debug message!" ..
        "\nDamage is dealt to:  %s" ..
        "\nInitial damage:      %f" ..
        "\nDamage modifier:     x" .. tostring(damageMult) ..
        "\nFinal damage:        " .. tostring(attack.damage.health)
    -- I don't want to mix them together
    if attack.damage.health then
        local initDamage = attack.damage.health
        attack.damage.health = attack.damage.health * damageMult
        msg = string.format(msg, "health", tostring(initDamage))
    elseif attack.damage.fatigue then
        local initDamage = attack.damage.fatigue
        attack.damage.fatigue = attack.damage.fatigue * damageMult
        msg = string.format(msg, "fatigue", tostring(initDamage))
    else
        return
    end

    if sectionDebug:get("printToConsole") then print(msg) end
    attack.attacker:sendEvent("onBackstab", damageMult)
end
