local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
local functions = require("OperatorJack.MiscastEnhanced.functions")


-- Events for effects.
local calcHitChanceMobiles = {}
event.register("calcHitChance", function(e)
    if (calcHitChanceMobiles[e.attackerMobile]) then
        e.hitChance = e.hitChance - calcHitChanceMobiles[e.attackerMobile]
    end
end)

local calcSwimSpeedMobiles = {}
event.register("calcSwimSpeed", function(e)
    if (calcSwimSpeedMobiles[e.mobile]) then
        e.speed = e.speed - calcHitChanceMobiles[e.attackerMobile]
    end
end)

local isActivationDisabled = false
event.register("activate", function(e)
    if (e.activator == tes3.player) then
        if (isActivationDisabled == true) then
            return false
        end
    end
end, {priority = 1})

local isFloatEnabled = false
local floatMagnitude = 0
local isAccelerateEnabled = false
local isWatersinkEnabled = false
local isBreathingDisabled = false
event.register("simulate", function()
    if (isFloatEnabled == true) then
        tes3.mobilePlayer.velocity = tes3vector3.new(0, 0, floatMagnitude * 10)
    end
    if (isAccelerateEnabled == true and (tes3.mobilePlayer.isFlying or tes3.mobilePlayer.isJumping)) then
        tes3.mobilePlayer.impulseVelocity = tes3.mobilePlayer.impulseVelocity * 50
    end
    if(isWatersinkEnabled == true and 
        tes3.mobilePlayer.underwater == true
    ) then
        tes3.player.position.z = tes3.mobilePlayer.lastGroundZ
    end
end)

event.register("load", function(e)
    calcHitChanceMobiles = {}
    calcSwimSpeedMobiles = {}
    isFloatEnabled = false
    floatMagnitude = 0
    isAccelerateEnabled = false
    isWatersinkEnabled = false
    isBreathingDisabled = false
end)

-- Effect handlers.
local effects = {
    [tes3.effect.absorbAttribute] = function (params)
        functions.handlers.genericInverseEffectHandler({
            effectIdToUse = tes3.effect.damageAttribute,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.absorbHealth] = function (params)
        functions.handlers.genericInverseEffectHandler({
            effectIdToUse = tes3.effect.damageHealth,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.absorbFatigue] = function (params)
        functions.handlers.genericInverseEffectHandler({
            effectIdToUse = tes3.effect.damageFatigue,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.absorbMagicka] = function (params)
        functions.handlers.genericInverseEffectHandler({
            effectIdToUse = tes3.effect.damageMagicka,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.absorbSkill] = function (params)
        functions.handlers.genericInverseEffectHandler({
            effectIdToUse = tes3.effect.damageSkill,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.almsiviIntervention] = function (params)
        functions.handlers.genericTeleportEffectHandler({
            reference = params.caster
        })
    end,
    [tes3.effect.blind] = function (params)
        functions.handlers.genericInverseEffectHandler({
            effectIdToUse = tes3.effect.blind,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.boundBattleAxe] = function (params)
        functions.handlers.genericBoundItemHandler({
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.boundBoots] = function (params)
        functions.handlers.genericBoundItemHandler({
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.boundCuirass] = function (params)
        functions.handlers.genericBoundItemHandler({
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.boundDagger] = function (params)
        functions.handlers.genericBoundItemHandler({
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.boundGloves] = function (params)
        functions.handlers.genericBoundItemHandler({
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.boundHelm] = function (params)
        functions.handlers.genericBoundItemHandler({
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.boundLongbow] = function (params)
        functions.handlers.genericBoundItemHandler({
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.boundLongsword] = function (params)
        functions.handlers.genericBoundItemHandler({
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.boundMace] = function (params)
        functions.handlers.genericBoundItemHandler({
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.boundShield] = function (params)
        functions.handlers.genericBoundItemHandler({
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.boundSpear] = function (params)
        functions.handlers.genericBoundItemHandler({
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.burden] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.feather,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.callBear] = function (params)
        functions.handlers.genericSummoningEffectHandler({
            creatureIdToUse = "BM_bear_black_summon",
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.callWolf] = function (params)
        functions.handlers.genericSummoningEffectHandler({
            creatureIdToUse = "BM_wolf_grey_summon",
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.calmCreature] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.frenzyCreature,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.calmHumanoid] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.frenzyHumanoid,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.chameleon] = function (params) 
        functions.handlers.genericAreaEffectHandler({
            distance = 500,
            effectIdToUse = tes3.effect.chameleon,
            effect = params.effect,
            reference = params.caster
        })   
    end,
    [tes3.effect.charm] = function (params) 
        local magnitude = functions.getModifiedMagnitudeFromEffect(params.effect)  
        local distance = magnitude * 10
        local actors = framework.functions.getActorsNearTargetPosition(params.caster.cell, params.caster.position, distance)
        
        -- For any actors within range, lower disposition by 10.
        for _, actor in pairs(actors) do
            actor.object.disposition = actor.object.disposition - 10
        end    

        functions.gatedMessageBox("Nearby people seem less friendly towards you now.")
    end,
    [tes3.effect.commandCreature] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.frenzyCreature,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.commandHumanoid] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.frenzyHumanoid,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.cureBlightDisease] = function (params)
        functions.handlers.genericCureEffectHandler({
            effectIdToUse = tes3.effect.weaknesstoBlightDisease,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.cureCommonDisease] = function (params)
        functions.handlers.genericCureEffectHandler({
            effectIdToUse = tes3.effect.weaknesstoCommonDisease,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.cureCorprusDisease] = function (params)
        functions.handlers.genericCureEffectHandler({
            effectIdToUse = tes3.effect.weaknesstoCorprusDisease,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.cureParalyzation] = function (params)
        functions.handlers.genericInverseEffectHandler({
            effectIdToUse = tes3.effect.paralyze,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.curePoison] = function (params)
        functions.handlers.genericCureEffectHandler({
            effectIdToUse = tes3.effect.weaknesstoPoison,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.damageAttribute] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.restoreAttribute,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.damageFatigue] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.restoreFatigue,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.damageHealth] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.restoreHealth,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.damageMagicka] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.restoreMagicka,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.damageSkill] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.restoreSkill,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.demoralizeCreature] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.frenzyCreature,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.demoralizeHumanoid] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.frenzyHumanoid,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.detectAnimal] = function (params) 
        local magnitude = functions.getModifiedMagnitudeFromEffect(params.effect)  
        local distance = magnitude * 10
        local actors = framework.functions.getActorsNearTargetPosition(params.caster.cell, params.caster.position, distance)
        
        -- For any actors within range, check if animal. If so, start combat.
        for _, actor in pairs(actors) do
            if (actor.object.objectType == tes3.creatureType.normal) then
                mwscript.startCombat({
                    reference = actor,
                    target = params.caster
                })
            end
        end    

        functions.gatedMessageBox("Nearby animals seem more aware and aggresive towards you now.")  
    end,
    [tes3.effect.disintegrateArmor] = function (params)
        functions.handlers.genericInverseEffectHandler({
            effectIdToUse = tes3.effect.disintegrateArmor,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.disintegrateWeapon] = function (params)
        functions.handlers.genericInverseEffectHandler({
            effectIdToUse = tes3.effect.disintegrateWeapon,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.dispel] = function (params) 
        functions.handlers.genericAreaEffectHandler({
            distance = 500,
            effectIdToUse = tes3.effect.dispel,
            effect = params.effect,
            reference = params.caster
        })   
    end,
    [tes3.effect.divineIntervention] = function (params)
        functions.handlers.genericTeleportEffectHandler({
            reference = params.caster
        })
    end,
    [tes3.effect.drainAttribute] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.restoreAttribute,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.drainFatigue] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.restoreFatigue,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.drainHealth] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.restoreHealth,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.drainMagicka] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.restoreMagicka,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.drainSkill] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.restoreSkill,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.feather] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.burden,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.fireDamage] = function (params)
        functions.handlers.genericInverseEffectHandler({
            effectIdToUse = tes3.effect.fireDamage,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.fireShield] = function (params)
        functions.handlers.genericInverseEffectHandler({
            effectIdToUse = tes3.effect.fireShield,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.fortifyAttack] = function (params)  
        local magnitude = functions.getModifiedMagnitudeFromEffect(params.effect)  
        local duration = functions.getModifiedDurationFromEffect(params.effect)
        local mobile = params.caster.mobile
        calcHitChanceMobiles[mobile] = magnitude
        if (params.caster == tes3.player) then  
            functions.gatedMessageBox("Your ability to hit your target is reduced.")
        end
        timer.start({
            duration = duration,
            callback = function()
                if (mobile == tes3.mobilePlayer) then  
                    functions.gatedMessageBox("Your ability to hit your target is restored.")
                end
                calcHitChanceMobiles[mobile] = nil
            end
        })
    end,
    [tes3.effect.fortifyAttribute] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.damageAttribute,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.fortifyFatigue] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.damageFatigue,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.fortifyHealth] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.damageHealth,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.fortifyMagicka] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.damageMagicka,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.fortifyMaximumMagicka] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.damageMagicka,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.fortifySkill] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.damageSkill,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.frenzyCreature] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.calmCreature,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.frenzyHumanoid] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.calmHumanoid,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.frostDamage] = function (params)
        functions.handlers.genericInverseEffectHandler({
            effectIdToUse = tes3.effect.frostDamage,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.frostShield] = function (params)
        functions.handlers.genericInverseEffectHandler({
            effectIdToUse = tes3.effect.frostShield,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.invisibility] = function (params) 
        functions.handlers.genericAreaEffectHandler({
            distance = 500,
            effectIdToUse = tes3.effect.invisibility,
            effect = params.effect,
            reference = params.caster
        }) 
    end,
    [tes3.effect.jump] = function (params) 
        if (params.caster == tes3.player and tes3.mobilePlayer.jumpingDisabled == false) then
            functions.gatedMessageBox("Your ability to hit your jump is reduced.")
            tes3.mobilePlayer.jumpingDisabled = true
            timer.start({
                duration = 5,
                callback = function()
                    functions.gatedMessageBox("Your ability to hit your jump is restored.")
                    tes3.mobilePlayer.jumpingDisabled = false
                end
            })
        end
    end,
    [tes3.effect.levitate] = function (params) 
        if (params.caster == tes3.player) then
            floatMagnitude = functions.getModifiedMagnitudeFromEffect(params.effect)   
            local duration = functions.getModifiedDurationFromEffect(params.effect)
            tes3.player.position = tes3.player.position + tes3vector3.new(0, 0, 64)  
            functions.gatedMessageBox("You begin to float upwards.")
            isFloatEnabled = true
            timer.start({
                duration = duration,
                callback = function()
                    functions.gatedMessageBox("The floatation magic has stopped.")
                    isFloatEnabled = false
                end
            })
        end
    end,
    [tes3.effect.light] = function (params) 
        functions.handlers.genericAreaEffectHandler({
            distance = 500,
            effectIdToUse = tes3.effect.light,
            effect = params.effect,
            reference = params.caster
        })   
    end,
    [tes3.effect.lightningShield] = function (params)
        functions.handlers.genericInverseEffectHandler({
            effectIdToUse = tes3.effect.lightningShield,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.lock] = function (params)
        local magnitude = functions.getModifiedMagnitudeFromEffect(params.effect)
        local target = tes3.getPlayerTarget()
        local currentLockLevel = tes3.getLockLevel({reference = target})
        if (currentLockLevel) then
            local newLocklevel = currentLockLevel + magnitude
            tes3.setLockLevel({
                reference = target,
                level = newLocklevel
            })
            functions.gatedMessageBox("The lock appears even more complex now.")
        end
    end,
    [tes3.effect.mark] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.recall,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.nightEye] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.blind,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.open] = function (params)
        local magnitude = functions.getModifiedMagnitudeFromEffect(params.effect)
        local target = tes3.getPlayerTarget()
        local currentLockLevel = tes3.getLockLevel({reference = target})
        if (currentLockLevel) then
            local newLocklevel = currentLockLevel + magnitude
            tes3.setLockLevel({
                reference = target,
                level = newLocklevel
            })
            functions.gatedMessageBox("The lock appears even more complex now.")
        end
    end,
    [tes3.effect.paralyze] = function (params)
        functions.handlers.genericInverseEffectHandler({
            effectIdToUse = tes3.effect.paralyze,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.poison] = function (params)
        functions.handlers.genericInverseEffectHandler({
            effectIdToUse = tes3.effect.poison,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.rallyCreature] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.demoralizeCreature,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.rallyHumanoid] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.demoralizeHumanoid,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.recall] = function (params)
        functions.handlers.genericTeleportEffectHandler({
            reference = params.caster
        })
    end,
    [tes3.effect.reflect] = function (params)
        functions.handlers.genericInverseEffectHandler({
            effectIdToUse = tes3.effect.reflect,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.resistBlightDisease] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.weaknesstoBlightDisease,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.resistCommonDisease] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.weaknesstoCommonDisease,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.resistFire] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.weaknesstoFire,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.resistFrost] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.weaknesstoFrost,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.resistMagicka] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.weaknesstoMagicka,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.resistNormalWeapons] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.weaknesstoNormalWeapons,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.resistParalysis] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.paralyze,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.resistPoison] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.weaknesstoPoison,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.resistShock] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.weaknesstoShock,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.restoreAttribute] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.damageAttribute,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.restoreFatigue] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.damageFatigue,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.restoreHealth] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.damageHealth,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.restoreMagicka] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.damageMagicka,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.restoreSkill] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.damageSkill,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.sanctuary] = function (params)  
        local magnitude = functions.getModifiedMagnitudeFromEffect(params.effect)  
        local duration = functions.getModifiedDurationFromEffect(params.effect)
        local mobile = params.caster.mobile
        calcHitChanceMobiles[mobile] = magnitude
        if (params.caster == tes3.player) then
            functions.gatedMessageBox("Your ability to hit your target is reduced.")
        end
        timer.start({
            duration = duration,
            callback = function()
                if (mobile == tes3.mobilePlayer) then
                    functions.gatedMessageBox("Your ability to hit your target is restored.")
                end
                calcHitChanceMobiles[mobile] = nil
            end
        })
    end,
    [tes3.effect.shield] = function (params) 
        functions.handlers.genericAreaEffectHandler({
            distance = 500,
            effectIdToUse = tes3.effect.shield,
            effect = params.effect,
            reference = params.caster
        })   
    end,
    [tes3.effect.shockDamage] = function (params)
        functions.handlers.genericInverseEffectHandler({
            effectIdToUse = tes3.effect.shockDamage,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.silence] = function (params)
        functions.handlers.genericInverseEffectHandler({
            effectIdToUse = tes3.effect.silence,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.slowFall] = function (params)
        if (params.caster == tes3.player) then 
            local duration = functions.getModifiedDurationFromEffect(params.effect)
            functions.gatedMessageBox("Your body feels more dense, as through it moves through the air more easily.")
            isAccelerateEnabled = true
            timer.start({
                duration = duration,
                callback = function()
                    functions.gatedMessageBox("Your body begins to feel normal again.")
                    isAccelerateEnabled = false
                end
            })
        end
    end,
    [tes3.effect.soultrap] = function (params)
        if (params.caster == tes3.player) then
            local soulgemId

            local soulgems = {}
            for _, stack in pairs(tes3.player.object.inventory) do
                if (stack.object.isSoulGem == true and stack.object.id ~= "Misc_SoulGem_Azura") then
                    table.insert(soulgems, stack.object.id)
                end
            end
            if (#soulgems > 1) then
                soulgemId = soulgems[math.random(#table)]
            elseif (#soulgems == 1) then
                soulgemId = soulgems[1]
            end

            if (soulgemId ~= nil) then
                tes3.removeItem({
                    reference = tes3.player,
                    item = soulgemId,
                    count = 1,
                    playSound = false
                })
                functions.gatedMessageBox("One of your soulgems is destroyed by the miscast.")
            end
        end
    end,
    [tes3.effect.sound] = function (params)
        functions.handlers.genericInverseEffectHandler({
            effectIdToUse = tes3.effect.sound,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.spellAbsorption] = function (params)
        functions.handlers.genericInverseEffectHandler({
            effectIdToUse = tes3.effect.spellAbsorption,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.summonAncestralGhost] = function (params)
        functions.handlers.genericSummoningEffectHandler({
            creatureIdToUse = "ancestor_ghost_summon",
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.summonBonelord] = function (params)
        functions.handlers.genericSummoningEffectHandler({
            creatureIdToUse = "bonelord_summon",
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.summonBonewalker] = function (params)
        functions.handlers.genericSummoningEffectHandler({
            creatureIdToUse = "bonewalker_summon",
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.summonBonewolf] = function (params)
        functions.handlers.genericSummoningEffectHandler({
            creatureIdToUse = "BM_wolf_bone_summon",
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.summonCenturionSphere] = function (params)
        functions.handlers.genericSummoningEffectHandler({
            creatureIdToUse = "centurion_sphere_summon",
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.summonClannfear] = function (params)
        functions.handlers.genericSummoningEffectHandler({
            creatureIdToUse = "clannfear_summon",
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.summonDaedroth] = function (params)
        functions.handlers.genericSummoningEffectHandler({
            creatureIdToUse = "daedroth_summon",
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.summonDremora] = function (params)
        functions.handlers.genericSummoningEffectHandler({
            creatureIdToUse = "dremora_summon",
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.summonFabricant] = function (params)
        functions.handlers.genericSummoningEffectHandler({
            creatureIdToUse = "fabricant_summon",
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.summonFlameAtronach] = function (params)
        functions.handlers.genericSummoningEffectHandler({
            creatureIdToUse = "atronach_flame_summon",
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.summonFrostAtronach] = function (params)
        functions.handlers.genericSummoningEffectHandler({
            creatureIdToUse = "atronach_frost_summon",
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.summonGoldenSaint] = function (params)
        functions.handlers.genericSummoningEffectHandler({
            creatureIdToUse = "golden saint_summon",
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.summonGreaterBonewalker] = function (params)
        functions.handlers.genericSummoningEffectHandler({
            creatureIdToUse = "Bonewalker_Greater_summ",
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.summonHunger] = function (params)
        functions.handlers.genericSummoningEffectHandler({
            creatureIdToUse = "hunger_summon",
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.summonScamp] = function (params)
        functions.handlers.genericSummoningEffectHandler({
            creatureIdToUse = "scamp_summon",
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.summonSkeletalMinion] = function (params)
        functions.handlers.genericSummoningEffectHandler({
            creatureIdToUse = "skeleton",
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.summonStormAtronach] = function (params)
        functions.handlers.genericSummoningEffectHandler({
            creatureIdToUse = "atronach_storm_summon",
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.summonWingedTwilight] = function (params)
        functions.handlers.genericSummoningEffectHandler({
            creatureIdToUse = "winged twilight_summon",
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.swiftSwim] = function (params)  
        local magnitude = functions.getModifiedMagnitudeFromEffect(params.effect)  
        local duration = functions.getModifiedDurationFromEffect(params.effect)
        local mobile = params.caster.mobile
        if (mobile == tes3.mobilePlayer) then
            functions.gatedMessageBox("Your ability to swim is reduced.")
        end
        calcSwimSpeedMobiles[mobile] = magnitude
        timer.start({
            duration = duration,
            callback = function()
                if (mobile == tes3.mobilePlayer) then
                    functions.gatedMessageBox("Your ability to swim is restored.")
                end
                calcSwimSpeedMobiles[mobile] = nil
            end
        })
    end,
    [tes3.effect.telekinesis] = function (params)  
        local duration = functions.getModifiedDurationFromEffect(params.effect)
        isActivationDisabled = true
        functions.gatedMessageBox("Your ability to interact with objects is disabled.")
        timer.start({
            duration = duration,
            callback = function()
                functions.gatedMessageBox("Your ability to interact with objects is restored.")
                isActivationDisabled = false
            end
        })
    end,
    [tes3.effect.turnUndead] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.frenzyCreature,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.waterBreathing] = function (params)
        if (params.caster == tes3.player and isBreathingDisabled == false) then 
            local duration = functions.getModifiedDurationFromEffect(params.effect)
            iterations = math.ceil(duration / 2)
            functions.gatedMessageBox("You are unable to breath air.")
            isBreathingDisabled = true
            timer.start({
                duration = 2,
                iterations = iterations,
                callback = function()
                    if (isBreathingDisabled == true and 
                    tes3.mobilePlayer.underwater == false
                    ) then
                        tes3.mobilePlayer:applyHealthDamage(5)
                    end
                end
            })
            timer.start({
                duration = duration,
                callback = function()
                    functions.gatedMessageBox("Your ability to breath returns to normal.")
                    isBreathingDisabled = false
                end
            })
        end
    end,
    [tes3.effect.waterWalking] = function (params)
        if (params.caster == tes3.player and isWatersinkEnabled == false) then 
            local duration = functions.getModifiedDurationFromEffect(params.effect)
            functions.gatedMessageBox("You are unable to swim in deeper waters.")
            isWatersinkEnabled = true
            timer.start({
                duration = duration,
                callback = function()
                    functions.gatedMessageBox("Your ability to swim is restored.")
                    isWatersinkEnabled = false
                end
            })
        end
    end,
    [tes3.effect.weaknesstoBlightDisease] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.resistBlightDisease,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.weaknesstoCommonDisease] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.resistCommonDisease,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.weaknesstoFire] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.resistFire,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.weaknesstoFrost] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.resistFrost,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.weaknesstoMagicka] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.resistMagicka,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.weaknesstoNormalWeapons] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.resistNormalWeapons,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.weaknesstoPoison] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.resistPoison,
            effect = params.effect,
            reference = params.caster
        })
    end,
    [tes3.effect.weaknesstoShock] = function (params)
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = tes3.effect.resistShock,
            effect = params.effect,
            reference = params.caster
        })
    end,
}
local function onRegister()
    for effect, handler in pairs(effects) do
        functions.setEffectHandler(effect, handler)
    end
end
event.register("Miscast:Register", onRegister)