--
local version = 1.0

-- modules
-- init common and load
local common = require("ngc.common")
common.loadConfig()
-- init mcm and load
local mcm = require("ngc.mcm")
event.register("modConfigReady", mcm.registerModConfig)
-- weapon modules
local multistrike
local critical
local bleed
local stun
local momentum
local block
local bow
local crossbow
local thrown
-- locals
local attackBonusSpell = "ngc_ready_to_strike"
local handToHandReferences = {}
local currentlyKnockedDown = {}
local knockdownPlayer = false
local playerKnockdownTimer

-- this function is just here to clean up the old ability from legacy saves
local function updatePlayer()
    if mwscript.getSpellEffects({reference = tes3.player, spell = attackBonusSpell}) then
        mwscript.removeSpell({reference = tes3.player, spell = attackBonusSpell})
    end
end

-- setup hit chance and block chance
local function alwaysHit(e)
    if common.config.toggleAlwaysHit then
        e.hitChance = 100
    end

    if common.config.toggleActiveBlocking then
        if e.target == tes3.player then
            if block.currentlyActiveBlocking then
                if common.config.showDebugMessages then
                    tes3.messageBox({ message = "Setting max block!" })
                end
                block.setMaxBlock()

                -- check if reduced min fatigue for active blocking
                local fatigueMin = tes3.mobilePlayer.fatigue.base * common.config.activeBlockingFatigueMin
                if tes3.mobilePlayer.fatigue.current < fatigueMin then
                    block.activeBlockingOff()
                end
            else
                block.resetMaxBlock()
            end
        end

        if e.target ~= tes3.player then
            block.resetMaxBlock()
        end
    end
end

-- on game load
local function onLoaded(e)
    updatePlayer()

    -- get enemy health bar widget for hand to hand
    local menu_multi = tes3ui.registerID("MenuMulti")
    local health_bar = tes3ui.registerID("MenuMulti_npc_health_bar")
    common.enemyHealthBar = tes3ui.findMenu(menu_multi):findChild(health_bar)

    -- set GMSTs
    if common.config.toggleHandToHandPerks then
        -- vanilla hand to hand changes
        local minHandToHand = tes3.findGMST("fMinHandToHandMult")
        local maxHandToHand = tes3.findGMST("fMaxHandToHandMult")
        minHandToHand.value = 0.05 -- half of vanilla values
        maxHandToHand.value = 0.25 -- half of vanilla values
    end

    if common.config.toggleBalanceGMSTs then
        -- tweak knockdown values
        local knockdownMult = tes3.findGMST("fKnockDownMult")
        local knockdownOddsMult = tes3.findGMST("iKnockDownOddsMult")
        knockdownMult.value = common.config.gmst.knockdownMult
        knockdownOddsMult.value = common.config.gmst.knockdownOddsMult

        -- tweak fatigue combat values
        local fatigueAttackMult = tes3.findGMST("fFatigueAttackMult")
        local fatigueAttackBase = tes3.findGMST("fFatigueAttackBase")
        local weaponFatigueMult = tes3.findGMST("fWeaponFatigueMult")
        fatigueAttackMult.value = common.config.gmst.fatigueAttackMult
        fatigueAttackBase.value = common.config.gmst.fatigueAttackBase
        weaponFatigueMult.value = common.config.gmst.weaponFatigueMult

        -- tweak marksman projectile values
        local projectileMaxSpeed = tes3.findGMST("fProjectileMaxSpeed")
        local projectileMinSpeed = tes3.findGMST("fProjectileMinSpeed")
        local thrownWeaponMaxSpeed = tes3.findGMST("fThrownWeaponMaxSpeed")
        local thrownWeaponMinSpeed = tes3.findGMST("fThrownWeaponMinSpeed")
        projectileMaxSpeed.value = common.config.gmst.projectileMaxSpeed
        projectileMinSpeed.value = common.config.gmst.projectileMinSpeed
        thrownWeaponMaxSpeed.value = common.config.gmst.thrownWeaponMaxSpeed
        thrownWeaponMinSpeed.value = common.config.gmst.thrownWeaponMinSpeed
    end

    -- get block default GMSTs
    local blockMaxGMST = tes3.findGMST("iBlockMaxChance")
    local blockMinGMST = tes3.findGMST("iBlockMinChance")
    block.maxBlockDefault = blockMaxGMST.value
    block.minBlockDefault = blockMinGMST.value
end

-- clean up after combat
local function onCombatEnd(e)
    if (e.actor.reference == tes3.player) then
        -- reset multistrike counters
        common.multistrikeCounters = {}
        common.currentArmorCache = {}
        -- remove expose weakness on all currently exposed
        for targetId,spellId in pairs(common.currentlyExposed) do
            mwscript.removeSpell({reference = targetId, spell = spellId})
        end
        common.currentlyExposed = {}
        -- remove all bleeds and cancel all timers
        for targetId,_ in pairs(common.currentlyBleeding) do
            common.currentlyBleeding[targetId].timer:cancel()
        end
        common.currentlyBleeding = {}
        -- clean up hand to hand tracking
        handToHandReferences = {}
        -- clean up knockdown tracking
        currentlyKnockedDown = {}
        knockdownPlayer = false
    end
end

local function damageMessage(damageType, damageDone)
    if common.config.showMessages then
        local msgString = damageType
        if (common.config.showDamageNumbers and damageDone) then
            msgString = msgString .. " Extra damage: " .. math.round(damageDone, 2)
        end
        tes3.messageBox({ message = msgString })
    end
end

-- Core damage features
-- Attack bonus modifier for damage
local function attackBonusMod(attackBonus)
    return ((attackBonus * common.config.attackBonusModifier) / 100)
end

-- Bonus damage for weapon skill and attack bonus (if always hit)
local function coreBonusDamage(damage, weaponoSkillLevel, attackBonus)
    local damageMod
    local fortifyAttackMod = 0

    -- modify damage for weapon skill bonus
    local weaponSkillMod = ((weaponoSkillLevel * common.config.weaponSkillModifier) / 100)

    -- modify damage for Fortify Attack bonus
    if common.config.toggleAlwaysHit then
        fortifyAttackMod = attackBonusMod(attackBonus)
    end

    damageMod = damage * (weaponSkillMod + fortifyAttackMod)

    return damageMod
end

-- vanilla game strength modifier
local function strengthModifier(damage, strength)
    return damage * (0.5 + (strength / 100))
end

-- Blinkd check
local function blindCheck(attacker, source)
    if attacker.blind > 0 then
        local missChanceRoll = math.random(100)
        if attacker.blind >= missChanceRoll then
            -- you blind, you miss
            if (common.config.showMessages and source == tes3.player) then
                tes3.messageBox({ message = "Missed!" })
            end
            -- no damage
            return true
        end
    end

    return false
end

-- Calculate the reduction from the defenders sanctuary bonus
local function damageReductionFromSanctuary(defender, damageTaken)
    local damageReduced
    -- reduction from sanctuary
    local scantuaryMod = (((defender.agility.current + defender.luck.current) - 30) * common.config.sanctuaryModifier) / 100
    local reductionFromSanctuary
    if (scantuaryMod >= 0.1) then
        reductionFromSanctuary = (defender.sanctuary * scantuaryMod) / 100
    else
        reductionFromSanctuary = (defender.sanctuary * 0.1) / 100 -- minimum sanctuary reduction
    end

    if reductionFromSanctuary then
        damageReduced = damageTaken * reductionFromSanctuary
    end

    return damageReduced
end

-- Calculate the reduction from attackers fatigue left
local function damageReductionFromFatigue(attacker, damageTaken)
    local fatigueMod = ((1 - (attacker.fatigue.current / attacker.fatigue.base)) * common.config.fatigueReductionModifier)

    return damageTaken * fatigueMod
end

local function getTotalDamageReduced(attacker, defender, damageTaken)
    local newDamageTaken
    local damageReduced = 0

    if attacker then
        local reductionFromFatigue = damageReductionFromFatigue(attacker, damageTaken)
        if reductionFromFatigue then
            damageReduced = damageReduced + reductionFromFatigue
        end
    end

    if defender then
        -- reduction from sanctuary
        local reductionFromSanctuary = damageReductionFromSanctuary(defender, damageTaken)
        if reductionFromSanctuary then
            damageReduced = damageReduced + reductionFromSanctuary
        end
    end

    if damageReduced > 0 then
        newDamageTaken = damageTaken - damageReduced
        if newDamageTaken > 0 then
            return newDamageTaken, damageReduced
        else
            return 0, damageReduced
        end
    end
end

-- custom knockdown event
local function playKnockdown(targetReference, source)
    if (common.config.showMessages and source == tes3.player) then
        tes3.messageBox({ message = "Knockdown!" })
    end
    currentlyKnockedDown[targetReference.id] = true
    tes3.playAnimation({
        reference = targetReference,
        group = 0x22,
        startFlag = 1,
    })
    timer.start({
        duration = 3,
        callback = function ()
            currentlyKnockedDown[targetReference.id] = nil
            tes3.playAnimation({
                reference = targetReference,
                group = 0x0,
                startFlag = 0,
            })
        end,
        iterations = 1
    })
end

-- Calculate the knockdown chance modifier scaling with agility
local function agilityKnockdownChance(targetActor)
    local agilityChanceMod = 1
    -- full knockdown chance unless Agility is higher than 30
    if (targetActor.agility.current >= 30 and targetActor.agility.current < 100) then
        agilityChanceMod = ((100 - targetActor.agility.current) / 100)
    end
    if agilityChanceMod < common.config.agilityKnockdownChanceMinMod then
        agilityChanceMod = common.config.agilityKnockdownChanceMinMod
    end

    return agilityChanceMod
end


-- Damage events for weapon perks
local function onDamage(e)
    local attacker = e.attacker
    local defender = e.mobile

    local source = e.attackerReference
    local target = e.reference
    local sourceActor = attacker
    local targetActor = defender

    local damageTaken = e.damage
    local damageAdded = 0
    local damageReduced = 0

    if e.source == 'attack' then
        if common.config.toggleAlwaysHit then
            if attacker then
                -- roll for blind first
                if blindCheck(attacker, source) then
                    return
                end
            end

            local newDamageTaken
            local newDamageReduced
            newDamageTaken, newDamageReduced = getTotalDamageReduced(attacker, defender, damageTaken)
            if newDamageTaken ~= nil then
                damageTaken = newDamageTaken
            end
            if newDamageReduced ~= nil then
                damageReduced = newDamageReduced
            end
        end

        if attacker then
            -- core damage values
            local weapon = e.attacker.readiedWeapon
            local sourceAttackBonus = sourceActor.attackBonus

            if attacker.actorType == 0 then
                -- standard creature bonus without weapons
                local fortifyAttackMod = 0
                if common.config.toggleAlwaysHit then
                    fortifyAttackMod = attackBonusMod(sourceAttackBonus)
                end
                local creatureStrengthMod = ((sourceActor.strength.current * common.config.creatureBonusModifier) / 100)
                damageAdded = damageTaken * (fortifyAttackMod + creatureStrengthMod)
            elseif weapon then
                -- handle player/NPC attacks with weapons

                if weapon.object.type > 8 then
                    -- ranged hit
                    local weaponSkill = sourceActor.marksman.current
                    -- core bonus damage for ranged hits
                    damageAdded = coreBonusDamage(damageTaken, weaponSkill, sourceAttackBonus)

                    if weapon.object.type == 9 then
                        -- bow hit
                        if source == tes3.player then
                            -- player bow hits
                            local damageDone

                            if common.bonusMultiplierFromAttackEvent[source.id] then
                                damageDone = (damageTaken * common.bonusMultiplierFromAttackEvent[source.id])
                                damageAdded = damageAdded + damageDone
                                common.bonusMultiplierFromAttackEvent[source.id] = nil
                                if common.config.showDamageNumbers then
                                    -- just show extra damage for bow hits
                                    damageMessage("", damageDone)
                                end
                            end
                        else
                            -- NPC bow hits
                            local bonusMultiplier = bow.NPCFullDrawBonus(weaponSkill)
                            if bonusMultiplier then
                                damageAdded = damageAdded + (damageTaken * bonusMultiplier)
                            end
                        end

                        -- hamstring chance
                        bow.performHamstring(weaponSkill, source, target)
                    elseif weapon.object.type == 10 then
                        -- crossbow hits
                        local distance = source.position:distance(target.position)
                        local damageDone = crossbow.criticalRangeDamage(damageTaken, distance, weaponSkill)
                        if damageDone ~= nil then
                            if (source == tes3.player and common.config.showDamageNumbers) then
                                damageMessage("Critical Damage!", damageDone)
                            end
                            damageAdded = damageAdded + damageDone
                        end
                    elseif weapon.object.type == 11 then
                        -- thrown weapon hits
                        local damageDone = thrown.agilityBonusMod(damageTaken, sourceActor.agility.current)
                        damageAdded = damageAdded + damageDone
                        local damageCrit = thrown.performCritical(damageTaken, weaponSkill)
                        if damageCrit ~= nil then
                            if (source == tes3.player and common.config.showDamageNumbers) then
                                damageMessage("Critical strike!", damageCrit)
                            end
                            damageAdded = damageAdded + damageCrit
                        end
                    end
                elseif weapon.object.type > 6 then
                    -- axe
                    local weaponSkill = sourceActor.axe.current
                    damageAdded = coreBonusDamage(damageTaken, weaponSkill, sourceAttackBonus)

                    if common.config.toggleWeaponPerks then
                        local damageDone = bleed.perform(damageTaken, target, targetActor, weaponSkill)
                        if (damageDone ~= nil and source == tes3.player) then
                            damageMessage("Bleeding!", damageDone)
                        end
                    end
                elseif weapon.object.type > 5 then
                    -- spear
                    local weaponSkill = sourceActor.spear.current
                    damageAdded = coreBonusDamage(damageTaken, weaponSkill, sourceAttackBonus)

                    if common.config.toggleWeaponPerks then
                        local damageDone = momentum.perform(damageTaken, source, sourceActor, targetActor, weaponSkill)
                        if damageDone ~= nil then
                            if (source == tes3.player and common.config.showDamageNumbers) then
                                damageMessage("Momentum!", damageDone)
                            end
                            damageAdded = damageAdded + damageDone
                        end
                    end
                elseif weapon.object.type > 2 then
                    -- blunt
                    local weaponSkill = sourceActor.bluntWeapon.current
                    local stunned
                    local damageDone
                    damageAdded = coreBonusDamage(damageTaken, weaponSkill, sourceAttackBonus)

                    if common.config.toggleWeaponPerks then
                        stunned, damageDone = stun.perform(damageTaken, target, targetActor, weaponSkill)
                        if (stunned and source == tes3.player) then
                            damageMessage("Stunned!", damageDone)
                        elseif (source == tes3.player and common.config.showDamageNumbers) then
                            -- just show extra damage for blunt weapon if no stun
                            damageMessage("", damageDone)
                        end
                        if damageDone ~= nil then
                            damageAdded = damageAdded + damageDone
                        end
                    end
                elseif weapon.object.type > 0 then
                    -- long blade
                    local weaponSkill = sourceActor.longBlade.current
                    damageAdded = coreBonusDamage(damageTaken, weaponSkill, sourceAttackBonus)

                    if common.config.toggleWeaponPerks then
                        common.multistrikeCounters = longblade.checkCounters(source.id)
                        if common.multistrikeCounters[source.id] == 3 then
                            local damageDone = longblade.perform(damageTaken, source, weaponSkill)
                            common.multistrikeCounters[source.id] = 0
                            if source == tes3.player then
                                damageMessage("Multistrike!", damageDone)
                            end
                            damageAdded = damageAdded + damageDone
                        end

                        if longblade.riposteTimers[source.id] then
                            local damageDone = damageTaken * common.config.riposteDamageMultiplier
                            if (source == tes3.player and common.config.showDamageNumbers) then
                                damageMessage("", damageDone)
                            end
                            damageAdded = damageAdded + damageDone
                        end
                    end
                elseif weapon.object.type > -1 then
                    -- short blade
                    local weaponSkill = sourceActor.shortBlade.current
                    local damageDone
                    local critDamage
                    damageAdded = coreBonusDamage(damageTaken, weaponSkill, sourceAttackBonus)

                    if common.config.toggleWeaponPerks then
                        damageDone, critDamage = critical.perform(damageTaken, source, targetActor, weaponSkill)
                        if damageDone ~= nil then
                            if (critDamage > 0 and source == tes3.player) then
                                damageMessage("Critical strike!", damageDone)
                            elseif (damageDone > 0 and source == tes3.player and common.config.showDamageNumbers) then
                                -- just show extra damage for execute
                                damageMessage("", damageDone)
                            end
                            damageAdded = damageAdded + damageDone
                        end
                    end
                end
            end
        end
        
        --[[
            Defender damage events
        ]]--
        if defender then
            local defenderWeapon = defender.readiedWeapon

            if defenderWeapon then
                if defenderWeapon.object.type == 1 or defenderWeapon.object.type == 2 then
                    local weaponSkill = targetActor.longBlade.current

                    longblade.rollForRiposte(target, weaponSkill)
                end
            end
        end
    end

    --[[
        Hand to hand block
    ]]--
    if e.source == nil and handToHandReferences[target.id] then
        -- nil sources of damage come from bleed and hand to hand so are special cases
        local handToHandAttacker = handToHandReferences[target.id]
        -- reset the attacker refernece
        handToHandReferences[target.id] = nil

        if common.config.toggleAlwaysHit then
            -- roll for blind first
            if blindCheck(handToHandAttacker.attacker, source) then
                return
            end

            local newDamageTaken
            local newDamageReduced
            newDamageTaken, newDamageReduced = getTotalDamageReduced(handToHandAttacker.attacker, defender, damageTaken)
            if newDamageTaken ~= nil then
                damageTaken = newDamageTaken
            end
            if newDamageReduced ~= nil then
                damageReduced = newDamageReduced
            end
        end

        damageAdded = coreBonusDamage(damageTaken, handToHandAttacker.weaponSkill, handToHandAttacker.attackBonus)
    end

    --[[
        Deal with any damage added or reduced by modifying e.damage
    ]]--
    if damageAdded then
        -- we already have damageReduced taken into account with damageTaken
        e.damage = damageTaken + damageAdded
        if common.config.showDebugMessages then
            local showReducedDamage = 0
            if damageReduced then
                showReducedDamage = damageReduced
            end
            tes3.messageBox({ message = "Final damage: " .. math.round(e.damage, 2) .. ". Reduced: " .. math.round(showReducedDamage, 2) .. ". Added: " .. math.round(damageAdded, 2)  })
        end
    elseif damageReduced then
        -- we don't have any damage added but we still have damage reduced
        e.damage = e.damage - damageReduced
        if common.config.showDebugMessages then
            tes3.messageBox({ message = "Reduced: " .. math.round(damageReduced, 2) })
        end
    end
end

local function onAttack(e)
    -- this is mainly for hand to hand
    local source = e.reference
    local sourceActor = e.mobile
    local target = e.targetReference
    local targetActor = e.targetMobile
    local weapon = sourceActor.readiedWeapon

    --[[
        Hand to hand block
    ]]--
    if (weapon == nil and
        targetActor and
        sourceActor.werewolf == false and
        common.config.toggleWeaponPerks and
        common.config.toggleHandToHandPerks) then
        -- this must be a hand to hand attack
        if sourceActor.handToHand then
            local bonusDamage
            local weaponSkill = sourceActor.handToHand.current

            handToHandReferences[target.id] = {
                attackerReference = source,
                attacker = sourceActor,
                weaponSkill = weaponSkill,
                attackBonus = sourceActor.attackBonus,
            }

            local bonusKnockdownMod
            local knockdownChance = math.random(100)
            local agilityChanceMod = agilityKnockdownChance(targetActor)
            if weaponSkill >= common.config.weaponTier4.weaponSkillMin then
                if (common.config.weaponTier4.handToHandKnockdownChance * agilityChanceMod) >= knockdownChance then
                    if target == tes3.player then
                        knockdownPlayer = true
                    else
                        playKnockdown(target, source)
                    end
                end
                bonusDamage = math.random(common.config.weaponTier4.handToHandBaseDamageMin, common.config.weaponTier4.handToHandBaseDamageMax)
                if currentlyKnockedDown[target.id] or knockdownPlayer then
                    bonusKnockdownMod = common.config.weaponTier4.handToHandKnockdownDamageMultiplier
                end
            elseif weaponSkill >= common.config.weaponTier3.weaponSkillMin then
                if (common.config.weaponTier3.handToHandKnockdownChance * agilityChanceMod) >= knockdownChance then
                    if target == tes3.player then
                        knockdownPlayer = true
                    else
                        playKnockdown(target, source)
                    end
                end
                bonusDamage = math.random(common.config.weaponTier3.handToHandBaseDamageMin, common.config.weaponTier3.handToHandBaseDamageMax)
                if currentlyKnockedDown[target.id] or knockdownPlayer then
                    bonusKnockdownMod = common.config.weaponTier3.handToHandKnockdownDamageMultiplier
                end
            elseif weaponSkill >= common.config.weaponTier2.weaponSkillMin then
                if (common.config.weaponTier2.handToHandKnockdownChance * agilityChanceMod) >= knockdownChance then
                    if target == tes3.player then
                        knockdownPlayer = true
                    else
                        playKnockdown(target, source)
                    end
                end
                bonusDamage = math.random(common.config.weaponTier2.handToHandBaseDamageMin, common.config.weaponTier2.handToHandBaseDamageMax)
                if currentlyKnockedDown[target.id] or knockdownPlayer then
                    bonusKnockdownMod = common.config.weaponTier2.handToHandKnockdownDamageMultiplier
                end
            elseif weaponSkill >= common.config.weaponTier1.weaponSkillMin then
                if (common.config.weaponTier1.handToHandKnockdownChance * agilityChanceMod) >= knockdownChance then
                    if target == tes3.player then
                        knockdownPlayer = true
                    else
                        playKnockdown(target, source)
                    end
                end
                bonusDamage = math.random(common.config.weaponTier1.handToHandBaseDamageMin, common.config.weaponTier1.handToHandBaseDamageMax)
                if currentlyKnockedDown[target.id] or knockdownPlayer then
                    bonusKnockdownMod = common.config.weaponTier1.handToHandKnockdownDamageMultiplier
                end
            else
                bonusDamage = math.random(common.config.handToHandBaseDamageMin, common.config.handToHandBaseDamageMax)
            end

            if bonusDamage then
                bonusDamage = bonusDamage + strengthModifier(bonusDamage, sourceActor.strength.current)
                if bonusKnockdownMod then
                    local bonusKnockdownDamage = (bonusDamage * bonusKnockdownMod)
                    bonusDamage = bonusDamage + bonusKnockdownDamage
                    if (source == tes3.player and common.config.showDamageNumbers) then
                        -- just show extra damage for knockdown
                        damageMessage("", bonusDamage)
                    end
                end
                local armorGMST = tes3.findGMST("fCombatArmorMinMult")
                local totalAR = common.getARforTarget(target)
                local damageMod = bonusDamage / (bonusDamage + totalAR)
                if damageMod <= armorGMST.value then
                    damageMod = armorGMST.value
                end
                bonusDamage = bonusDamage * damageMod
                if knockdownPlayer then
                    -- we want to knckdown the player
                    if common.config.showDebugMessages then
                        tes3.messageBox({ message = "Knocking down player!" })
                    end
                    local currentFatigue = tes3.mobilePlayer.fatigue.current
                    tes3.setStatistic({ reference = tes3.player, name = "fatigue", current = -100 })
                    if playerKnockdownTimer == nil or playerKnockdownTimer.state == timer.expired  then
                        playerKnockdownTimer = timer.start({
                            duration = 2,
                            callback = function ()
                                knockdownPlayer = false
                                tes3.setStatistic({ reference = tes3.player, name = "fatigue", current = currentFatigue })
                            end,
                            iterations = 1
                        })
                    end
                end
                targetActor:applyHealthDamage(bonusDamage, false, true, false)
                -- we've done some damage, let's get some exp
                if source == tes3.player then
                    tes3.mobilePlayer:exerciseSkill(tes3.skill.handToHand, 1)
                end

                if source == tes3.player then
                    common.updateEnemyHealthBar(targetActor)
                end
            end
        end
    end

    if (weapon and common.config.toggleWeaponPerks) then
        --[[
            Bow block
        ]]--
        if (weapon.object.type == 9 and source == tes3.player) then
            local weaponSkill = sourceActor.marksman.current
            local bonusMultiplier

            if bow.playerCurrentlyFullDrawn then
                bonusMultiplier = bow.playerFullDrawBonus(weaponSkill)
            end

            if bonusMultiplier then
                common.bonusMultiplierFromAttackEvent[source.id] = bonusMultiplier
            else
                common.bonusMultiplierFromAttackEvent[source.id] = nil
            end
        end

        --[[
            Thrown weapon block
        ]]--
        if (weapon.object.type == 11 and source == tes3.player) then
            local weaponSkill = sourceActor.marksman.current
            -- thrown chance GMST
            local thrownChanceGMST = tes3.findGMST("fProjectileThrownStoreChance")
            thrownChanceGMST.value = thrown.getThrownRecoverChance(weaponSkill)
        end
    end
end

-- currently only used for hamstring debuff
local function onCalcMoveSpeed(e)
    local source = e.reference

    if (common.currentlyHamstrung[source.id]) then
        e.speed = e.speed * common.config.hamstringModifier
    end

    if (bow.playerCurrentlyFullDrawn and source == tes3.player and e.mobile.isMovingBack) then
        e.speed = e.speed * common.config.fullDrawBackSpeedModifier
    end
end

local function onExerciseSkill(e)
    local modifier

    if common.weaponSkills[e.skill] then
        -- this is a weapon skill
        local weaponSkillLevel = tes3.mobilePlayer.skills[e.skill+1].base
        modifier = common.config.weaponSkillGainBaseModifier
        if weaponSkillLevel >= common.config.weaponTier4.weaponSkillMin then
            modifier = common.config.weaponTier4.weaponSkillGainModifier
        elseif weaponSkillLevel >= common.config.weaponTier3.weaponSkillMin then
            modifier = common.config.weaponTier3.weaponSkillGainModifier
        elseif weaponSkillLevel >= common.config.weaponTier2.weaponSkillMin then
            modifier = common.config.weaponTier2.weaponSkillGainModifier
        elseif weaponSkillLevel >= common.config.weaponTier1.weaponSkillMin then
            modifier = common.config.weaponTier1.weaponSkillGainModifier
        end
    end

    if common.armorSkills[e.skill] then
        modifier = common.config.armorSkillGainBaseModifier
    end

    if modifier then
        if common.config.showSkillGainDebugMessages then
            tes3.messageBox({ message = "Base skill exp: " .. e.progress .. " Modified skill exp: " .. (e.progress * modifier)})
        end
        e.progress = e.progress * modifier
    end
end

local function initialized(e)
	if tes3.isModActive("Next Generation Combat.esp") then
        -- load modules
        longblade = require("ngc.perks.longblade")
        critical = require("ngc.perks.critical")
        bleed = require("ngc.perks.bleed")
        stun = require("ngc.perks.stun")
        momentum = require("ngc.perks.momentum")
        block = require("ngc.block")
        bow = require("ngc.perks.bow")
        crossbow = require("ngc.perks.crossbow")
        thrown = require("ngc.perks.thrown")

        -- register events
        event.register("loaded", onLoaded)
        event.register("calcHitChance", alwaysHit)
        event.register("combatStopped", onCombatEnd)
        event.register("attack", onAttack)
        event.register("damage", onDamage)
        if common.config.toggleSkillGain then
            event.register("exerciseSkill", onExerciseSkill)
        end
        if common.config.toggleActiveBlocking then
            event.register("keyDown", block.keyPressed, { filter = common.config.activeBlockKey.keyCode } )
            event.register("keyUp", block.keyReleased, { filter = common.config.activeBlockKey.keyCode } )
            -- release block on any menu mode enter
            event.register("menuEnter", block.keyReleased)
            event.register("uiCreated", block.createBlockUI, { filter = "MenuMulti" })

            if common.config.toggleActiveBlockingMouse2 then
                event.register("mouseButtonDown", block.keyPressed, { filter = 1 } )
                event.register("mouseButtonUp", block.keyReleased, { filter = 1 } )
            end
        end
        if common.config.toggleWeaponPerks then
            -- bow
            mge.enableZoom()
            if common.config.nonStandardAttackKey.keyCode then
                event.register("keyDown", bow.attackPressed, { filter = common.config.nonStandardAttackKey.keyCode } )
                event.register("keyUp", bow.attackReleased, { filter = common.config.nonStandardAttackKey.keyCode } )
            else
                event.register("mouseButtonDown", bow.attackPressed, { filter = 0 } )
                event.register("mouseButtonUp", bow.attackReleased, { filter = 0 } )
            end
            event.register("menuEnter", bow.attackReleased)
            event.register("calcMoveSpeed", onCalcMoveSpeed)
            -- crossbow
            if common.config.nonStandardAttackKey.keyCode then
                event.register("keyDown", crossbow.attackPressed, { filter = common.config.nonStandardAttackKey.keyCode } )
                event.register("keyUp", crossbow.attackReleased, { filter = common.config.nonStandardAttackKey.keyCode } )
            else
                event.register("mouseButtonDown", crossbow.attackPressed, { filter = 0 })
                event.register("mouseButtonUp", crossbow.attackReleased, { filter = 0 } )
            end
            event.register("menuEnter", crossbow.attackReleased)
        end

		mwse.log("[Next Generation Combat] Initialized version v%d", version)
	end
end
event.register("initialized", initialized)