local common = require("StormAtronach.TT.common")
local config = common.config
local parry = {
    name = "Parry",
    window = config.parry_window,
    cooldown = false,
    active = false
}
local log = common.log
--[[
local function resetParryCooldown()
    parry.cooldown = false
end
]]

function parry.onCalcHitChance(e)
--[[
Event Data
attacker (tes3reference): Read-only. A shortcut to the mobile's reference.
attackerMobile (tes3mobileActor): Read-only. The mobile who is making the attack.
hitChance (number): The hit chance for the actor. This may be adjusted.
projectile (tes3mobileProjectile, nil): Read-only. The projectile, if applicable, that hit the target.
target (tes3reference): Read-only. A shortcut to the target mobile's reference. May not always be available.
targetMobile (tes3mobileActor): Read-only. The mobile who is being attacked. May not always be available.
]]
    log:trace("Parry onCalcHitChance event started")
    e.hitChance = 0
    -- Now, for the opposed skill check
    local attackerWeapon        = e.attackerMobile.readiedWeapon
    local attackerWeaponType    = nil

    if attackerWeapon then
        attackerWeaponType      = attackerWeapon.object.type
        log:debug("Attacker weapon type: " .. attackerWeaponType)
    end

    local attackerSkillCheck    = common.weaponSkillCheck({thisMobileActor = e.attackerMobile, weapon = attackerWeaponType})
    local attackerSkillLevel    = math.floor(attackerSkillCheck.weaponSkill/25)

    local defenderWeapon          = e.targetMobile.readiedWeapon
    local defenderWeaponType      = nil
    if defenderWeapon then
        defenderWeaponType        = defenderWeapon.object.type
    end

    local defenderSkillCheck      = common.weaponSkillCheck({thisMobileActor = e.targetMobile, weapon = defenderWeaponType})
    local defenderSkillLevel      = math.floor(defenderSkillCheck.weaponSkill/25)
    local opposedSkillCheck     = defenderSkillLevel - attackerSkillLevel
    log:debug(string.format("Parry skill check: %s - %s = %s", defenderSkillLevel, attackerSkillLevel, opposedSkillCheck))
    if opposedSkillCheck    < 0 then
        e.targetMobile:hitStun()
        e.attackerMobile:hitStun()
    elseif opposedSkillCheck == 0 then
        e.attackerMobile:hitStun()
    elseif opposedSkillCheck == 1 then
        e.attackerMobile:hitStun()
        common.slowedActors[e.attacker] = {startTime = os.clock(), duration = 1, typeSlow = 1 }
    elseif opposedSkillCheck == 2 then
        e.attackerMobile:hitStun( {knockDown = true})
        common.slowedActors[e.attacker] = {startTime = os.clock(), duration = 1, typeSlow = 2 }
    elseif opposedSkillCheck == 3 then
        e.attackerMobile:hitStun( {knockDown = true})
        common.slowedActors[e.attacker] = {startTime = os.clock(), duration = 1, typeSlow = 3 }
    end

    -- Play a sound
    tes3.playSound{ sound = "repair fail" }
    if e.target == tes3.player then
    -- Grant experience
    tes3.mobilePlayer:exerciseSkill(defenderSkillCheck.skillID, config.parry_skill_gain)
    log:trace("Player parry mechanic finished")
    else
    log:trace("NPC parry mechanic finished")
    end

    -- Brief shimmer for visual feedback
     tes3.applyMagicSource({
                reference = e.target,
                bypassResistances = true,
                effects = { { id = tes3.effect.light, min = config.parry_light_magnitude, max = config.parry_light_magnitude, duration = config.parry_light_duration } },
                name = "Parried!",
                })


end


function parry.onAttack()
    log:trace("Parry onAttack event started")

    -- Update the window
    if next(common.attacksCounter) == nil then
        parry.window = config.parry_window
    else
        local aux = 0
        local newWindow = 0
        for _, _ in pairs(common.attacksCounter) do
            aux = aux + 1
        end
        newWindow = config.parry_window/math.max(1,aux*common.config.parry_red_per_attack)
        parry.window = newWindow
     end
    -- Start the window
    timer.start({duration = parry.window, callback = function() parry.active = false end, type = timer.simulate})

    -- Let us register the attack in the attacks counter table for the dynamic cooldown
    local timestamp = os.clock() -- Can't use the os.clock() function directly in the table, so we need to store it in a variable
    common.attacksCounter[timestamp] = common.config.parry_red_per_attack  -- We need to clean this on startup

end



return parry