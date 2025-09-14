local common = require("StormAtronach.TT.common")
local config = require("StormAtronach.TT.config")
local parry = {
    name = "Parry",
    window = config.parry_window,
    cooldown = false,
    active = false
}

-- Logging stuff
local log = mwse.Logger.new({
	name = config.name,
	level = config.log_level,
})

--- @param e attackHitEventData
function parry.attackHitCallback(e)
    log:trace("Parry attackHit event started")
    e.mobile.actionData.physicalDamage = 0
    -- Now, for the opposed skill check
    local attackerWeapon        = e.mobile.readiedWeapon
    local attackerWeaponType    = nil

    if attackerWeapon then
        attackerWeaponType      = attackerWeapon.object.type
        log:debug("Attacker weapon type: " .. attackerWeaponType)
    end

    local attackerSkillCheck    = common.weaponSkillCheck({thisMobileActor = e.mobile, weapon = attackerWeaponType})
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
        e.mobile:hitStun()
    elseif opposedSkillCheck == 0 then
        e.mobile:hitStun()
    elseif opposedSkillCheck == 1 then
        e.mobile:hitStun()
        common.slowedActors[e.reference] = {startTime = os.clock(), duration = 1, typeSlow = 1 }
    elseif opposedSkillCheck == 2 then
        e.mobile:hitStun( {knockDown = true})
        common.slowedActors[e.reference] = {startTime = os.clock(), duration = 1, typeSlow = 2 }
    elseif opposedSkillCheck == 3 then
        e.mobile:hitStun( {knockDown = true})
        common.slowedActors[e.reference] = {startTime = os.clock(), duration = 1, typeSlow = 3 }
    end

    -- Play a sound
    tes3.playSound{ sound = "repair fail" }
    if e.targetReference == tes3.player then
    -- Grant experience
    tes3.mobilePlayer:exerciseSkill(defenderSkillCheck.skillID, config.parry_skill_gain)
    log:trace("Player parry mechanic finished")
    else
    log:trace("NPC parry mechanic finished")
    end
    
    local ar = e.reference
    local a  = e.mobile
    local tr = e.targetReference
    local t  = e.targetMobile
    -- VFX
    local VFXspark = tes3.getObject("AXE_sa_VFX_WSparks")
    tes3.createVisualEffect{object = VFXspark, repeatCount = 1, position = (ar.position + tes3vector3.new(0,0,a.height*0.9) + tr.position + tes3vector3.new(0,0,t.height*0.9)) / 2}



    -- Brief shimmer for visual feedback
     tes3.applyMagicSource({
                reference = e.targetReference,
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
        newWindow = config.parry_window/math.max(1,aux*config.parry_red_per_attack)
        parry.window = newWindow
     end
    -- Start the window
    --timer.start({duration = parry.window, callback = function() parry.active = false end, type = timer.simulate})

    -- Let us register the attack in the attacks counter table for the dynamic cooldown
    local timestamp = os.clock() -- Can't use the os.clock() function directly in the table, so we need to store it in a variable
    common.attacksCounter[timestamp] = config.parry_red_per_attack  -- We need to clean this on startup

end



return parry