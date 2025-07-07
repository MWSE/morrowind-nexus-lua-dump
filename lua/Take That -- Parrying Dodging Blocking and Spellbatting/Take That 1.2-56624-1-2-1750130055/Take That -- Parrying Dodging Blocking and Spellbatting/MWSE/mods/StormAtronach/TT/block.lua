local block = {
    name = "Block",
    active = false,
    cooldown = false,

}

local common = require("StormAtronach.TT.common")
local config = common.config

-- Logging stuff
local log = mwse.Logger.new({
	name = config.name,
	level = config.log_level,
})

block.window = config.block_window

-- Block mechanic animation ----------------------------------------------------------------

-- 1. Animation stuff

local function resetCooldown()
    block.cooldown = false
end

local function resetAnimation()
    -- We select the reference
   local animReference = tes3.mobilePlayer.is3rdPerson and tes3.player or tes3.player1stPerson
   tes3.playAnimation({
       reference = animReference,
       group = 0,
   })
   log:trace("Animation reset")
end

-- Triggering the block mechanic
function block.onKeyDown()
   log:trace("Active Block has been triggered")

   -- We select the reference
   local animReference = tes3.mobilePlayer.is3rdPerson and tes3.player or tes3.player1stPerson
   tes3.playAnimation({
       reference = animReference,
       upper = tes3.animationGroup.shield,
       startFlag = tes3.animationStartFlag.normal,
       loopCount = 0,
   })

   -- Activate the cooldown flag
   block.cooldown = true

   --Activate the cooldown
   timer.start({duration = math.max(config.block_cool_down_time,1), callback = resetCooldown, type = timer.simulate})

   --Activate the timer to end the animation
   timer.start({duration = math.max(config.block_start_delay+config.block_window,0.5), callback = resetAnimation, type = timer.simulate})

end
--- @param e damageEventData
function block.onDamage(e)
    -- If this is not an attack, exit this stream. Ashfal keeps triggering the damage event to simulate hunger.
    if e.source ~= tes3.damageSource.attack then return end

    if e.reference ~= tes3.player then return end
    -- Let us store the original damage value so we can do fun things with it
    local originalDamage = e.damage
    log:trace(string.format("Modify damage function started. Original damage %s", originalDamage))

    -- Also, let us initialize a reduction factor to use within the functions
    local reductionFactor = 0

    -- And the one handed weapon check, and a placeholder for the player weapon
    local oneHanded = false
    local weapon    = {}

    if block.active then
        -- Do you have a shield?
        local doYouHaveShield   = tes3.mobilePlayer.readiedShield ~= nil
        log:trace(string.format("Has the player a shield equipped: %s", doYouHaveShield))
        -- And perchance a weapon?
        local doYouHaveWeapon   = tes3.mobilePlayer.readiedWeapon ~= nil
        log:trace(string.format("Has the player a weapon equipped: %s", doYouHaveWeapon))

        -- If you have a weapon, which one and is it one handed?
        if doYouHaveWeapon then
            weapon      = tes3.mobilePlayer.readiedWeapon ---@cast weapon tes3equipmentStack
            oneHanded   = common.oneHandedWeaponTable[weapon.object.type]
            log:trace(string.format("Is the weapon one handed: %s", oneHanded))
        end

  ------ Let us start the branches: one for sword and board, one for only weapons (including 2 handed), and one for hand to hand

        -- 1. Sword and board
        if doYouHaveShield and oneHanded then
            log:trace(string.format("Blocking damage with shield and one handed weapon"))

            -- How good are you at blocking?
            local blockSkill = tes3.mobilePlayer:getSkillValue(tes3.skill.block)
            log:trace(string.format("Blocking damage with shield. Block skill: %s", blockSkill))

            -- Calculate the damage to the player. Clamp from 0 to 100
            reductionFactor = math.clamp(config.block_shield_base_pc + config.block_shield_skill_mult*blockSkill, 0, 100)
            log:trace(string.format("Blocking damage with shield. Reduction factor: %s", reductionFactor))

            -- Let us reduce the damage to the player
            e.damage = math.floor(originalDamage*(100 - reductionFactor)/100)
            log:trace(string.format("Blocking damage with shield. Damage reduced to %s", e.damage))

            -- And transfer the damage to the shield. We also check if the shield has itemData, as it may not always be the case
            if tes3.mobilePlayer.readiedShield.itemData and tes3.mobilePlayer.readiedShield.itemData.condition then
            local originalShieldCondition = tes3.mobilePlayer.readiedShield.itemData.condition
            log:trace(string.format("Blocking damage with shield. Original shield condition %s", originalShieldCondition))
            tes3.mobilePlayer.readiedShield.itemData.condition = math.max(0, math.ceil(originalShieldCondition - originalDamage*reductionFactor/100))
            end

            -- Stun the opponent
            e.attacker:hitStun()
            -- And slow them down
            local slowDownType = math.floor(blockSkill/25)
            log:trace(string.format("Blocking damage with shield. Slow down type %s", slowDownType))

            if slowDownType > 0 then
                common.slowedActors[e.attackerReference] = {startTime = os.clock(), duration = 2, typeSlow = math.min(slowDownType,4) } 
            end

            -- Play a sound
            tes3.playSound{ sound = "steamRIGHT" }
            -- Grant experience
            tes3.mobilePlayer:exerciseSkill(tes3.skill.block, config.block_skill_gain)
            -- Show sparks
            -- VFX
            local VFXspark = tes3.getObject("AXE_sa_VFX_WSparks")
            local ar = e.attackerReference
            local a  = e.attacker
            local tr = e.reference
            local t  = e.mobile
            tes3.createVisualEffect{object = VFXspark, repeatCount = 1, position = (ar.position + tes3vector3.new(0,0,a.height*0.9) + tr.position + tes3vector3.new(0,0,t.height*0.9)) / 2}

            -- If damage has been reduced to 0, we block the event
            if e.damage <= 0 then
                e.block = true
                log:trace(string.format("Blocking damage with shield. Damage reduced to %s", e.damage))
            end
            -- And stop this stream
            return
        end

        -- 2. No shield or two handed weapon
        if doYouHaveWeapon then
            -- Now, how good are you?
            local mySkillCheck   =  common.weaponSkillCheck({thisMobileActor = tes3.mobilePlayer, weapon = weapon.object.type})
            local mySkill        = mySkillCheck.weaponSkill
            log:trace(string.format("Blocking damage with weapon. Weapon skill: %s", mySkill))

            -- Shield bonus logic
            local blockSkill   =  tes3.mobilePlayer:getSkillValue(tes3.skill.block)
            log:trace(string.format("Blocking damage with weapon. Block skill: %s", blockSkill))

            --Check the two options
            if config.block_skill_bonus_active == true then
                reductionFactor = math.clamp(config.block_shield_base_pc + config.block_weapon_skill_mult*mySkill + config.block_weapon_blockSkill_bonus*blockSkill, 0, 100)
                log:trace(string.format("Blocking damage with weapon. Shield bonus reduction factor: %s", reductionFactor))
            else
                -- Let's calculate the reduction factor
                reductionFactor = math.clamp(config.block_weapon_base_pc + config.block_weapon_skill_mult*mySkill, 0, 100)
                log:trace(string.format("Blocking damage with weapon. Reduction Factor: %s", reductionFactor))
            end

            -- Let us reduce the damage to the player
            e.damage = math.floor(originalDamage*(100 - reductionFactor)/100)
            log:trace(string.format("Blocking damage with weapon. Reduced damage %s", e.damage))

            -- Let's calculate the damage on the weapon
            if tes3.mobilePlayer.readiedWeapon.itemData and tes3.mobilePlayer.readiedWeapon.itemData.condition then
                local weaponConditionDamage = originalDamage*reductionFactor/100
                log:trace(string.format("Blocking damage with weapon. Weapon condition damage %s", weaponConditionDamage))
                local originalWeaponCondition = tes3.mobilePlayer.readiedWeapon.itemData.condition
                log:trace(string.format("Blocking damage with weapon. Original weapon condition %s", originalWeaponCondition))
                tes3.mobilePlayer.readiedWeapon.itemData.condition = math.max(0, math.ceil(originalWeaponCondition- weaponConditionDamage))
            end

            -- Now, mechanics
            local skillLevel = math.clamp(math.floor(mySkill/25),0,4)
            if skillLevel == 0 then
                e.attacker:hitStun()
            elseif skillLevel == 1 then
                e.attacker:hitStun()
                common.slowedActors[e.attackerReference] = {startTime = os.clock(), duration = 2, typeSlow = 1}
            elseif skillLevel == 2 then
                e.attacker:hitStun()
                common.slowedActors[e.attackerReference] = {startTime = os.clock(), duration = 2, typeSlow = 2}
                e.attacker:damage(originalDamage*0.5)
            elseif skillLevel == 3 then
                e.attacker:hitStun({knockDown = true})
                common.slowedActors[e.attackerReference] = {startTime = os.clock(), duration = 2, typeSlow = 3}
                e.attacker:damage(originalDamage*0.5)
            elseif skillLevel == 4 then
                e.attacker:hitStun({knockDown = true})
                common.slowedActors[e.attackerReference] = {startTime = os.clock(), duration = 2, typeSlow = 4}
                e.attacker:damage(originalDamage)
            end
 
            -- Play a sound
            tes3.playSound{ sound = "repair fail" }
            -- Grant experience
            -- If the bonus is active, send the XP to block. if not, to the weapon skill.
            if config.block_skill_bonus_active == true then
                tes3.mobilePlayer:exerciseSkill(tes3.skill.block, config.block_skill_gain)
            else
                tes3.mobilePlayer:exerciseSkill(mySkillCheck.skillID, config.block_skill_gain)
            end

            -- VFX
            local VFXspark = tes3.getObject("AXE_sa_VFX_WSparks")
            local ar = e.attackerReference
            local a  = e.attacker
            local tr = e.reference
            local t  = e.mobile
            tes3.createVisualEffect{object = VFXspark, repeatCount = 1, position = (ar.position + tes3vector3.new(0,0,a.height*0.9) + tr.position + tes3vector3.new(0,0,t.height*0.9)) / 2}

            -- If damage has been reduced to 0, we block the event
            if e.damage <= 0 then
                e.block = true
                log:trace(string.format("Blocking damage with weapon. Damage reduced to %s", e.damage))
            end
            -- And stop this stream
            return
        end

        -- 3. Kung fu. Only works without shield
        if (not doYouHaveShield) and (not doYouHaveWeapon) then
            local kungFuSkill = tes3.mobilePlayer:getSkillValue(tes3.skill.handToHand)
            log:trace(string.format("Kung Fu blocking. Hand to Hand skill %s", kungFuSkill))
            local kungFu = math.floor(kungFuSkill/25)
            log:trace(string.format("Kung Fu blocking"))

            if kungFu <=1 then
                e.attacker:hitStun()
                log:trace(string.format("Kung Fu blocking: Git Gud!"))
                common.slowedActors[e.attackerReference] = {startTime = os.clock(), duration = 2, typeSlow = 1 }
            elseif kungFu ==2 then
                e.attacker:hitStun({knockDown = true})
                log:trace(string.format("Kung Fu blocking: Thats nice"))
                common.slowedActors[e.attackerReference] = {startTime = os.clock(), duration = 2, typeSlow = 2 }

                e.damage = e.damage*0.5
                log:trace(string.format("Kung Fu blocking: Damage taken %s", e.damage))

            elseif kungFu == 3 then
                tes3.applyMagicSource({
                reference = e.attackerReference,
                bypassResistances = true,
                effects = { { id = tes3.effect.paralyze, min = 100, max = 100, duration = 5 } },
                name = "Nerve attack",
                })
                log:trace(string.format("Kung Fu blocking: Nerve attack"))

                e.damage = e.damage*0.25
                log:trace(string.format("Kung Fu blocking: Damage taken %s", e.damage))

            elseif kungFu == 4 then
                tes3.applyMagicSource({
                reference = e.attackerReference,
                bypassResistances = true,
                effects = { { id = tes3.effect.paralyze, min = 100, max = 100, duration = 5 }, {id = tes3.effect.poison, min = 20, max = 20, duration = 5} },
                name = "Death touch",
                })
                log:trace(string.format("Kung Fu blocking: Death touch"))

                e.damage = 0
                log:trace(string.format("Kung Fu blocking: Damage taken %s", e.damage))

            end

            -- Play a sound
            tes3.playSound{ sound = "Spell Failure Alteration" }
            -- Grant experience
            tes3.mobilePlayer:exerciseSkill(tes3.skill.handToHand, config.block_skill_gain)

            -- If damage has been reduced to 0, we block the event
            if e.damage <= 0 then
                e.block = true
                log:trace(string.format("Blocking damage with kung fu. Damage reduced to %s", e.damage))
            end

            -- and end this stream
            return
        end
    end
end

return block