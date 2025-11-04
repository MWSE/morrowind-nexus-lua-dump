local core = require('openmw.core')
local I = require('openmw.interfaces')
local T = require('openmw.types')
local input = require('openmw.input')
local async = require('openmw.async')
local camera = require('openmw.camera')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local util = require('openmw.util')

local log = require('scripts.NCGDMW.log')
local mDef = require('scripts.NCGDMW.definition')
local mCfg = require('scripts.NCGDMW.configuration')
local mS = require('scripts.NCGDMW.settings')
local mCore = require('scripts.NCGDMW.core')
local mC = require('scripts.NCGDMW.common')
local mCombat = require('scripts.NCGDMW.combat')
local mUi = require("scripts.NCGDMW.ui")
local mSpells = require('scripts.NCGDMW.spells')
local mH = require('scripts.NCGDMW.helpers')

local Skills = core.stats.Skill.records
local L = core.l10n(mDef.MOD_NAME)

local trace = false
local lockableStats
local lavaIdCache = {}
local ownedIngredients
local removedIngredients = {}
local lastEnemyHitTimes = {}

local module = {}

local function capFactor(ratio)
    return util.clamp(ratio, 0, 1)
end

local function capSkillScaledFactor(factor, range)
    return math.min(range.max, math.max(range.min, factor))
end

local function getFacedObject()
    local from = camera.getPosition()
    local to = from + self.rotation:apply(util.vector3(0, 5000, 0))
    local result = nearby.castRay(from, to, { ignore = self });
    return result.hitObject
end

local function getSecurityTargetStats(weapon)
    if not weapon then return end
    if weapon.type == T.Lockpick then
        local lockable = getFacedObject()
        if lockable and T.Lockable.isLocked(lockable) then
            local lockLevel = T.Lockable.getLockLevel(lockable)
            if lockLevel > 0 then
                return { lockLevel = lockLevel }
            end
        end
    elseif weapon.type == T.Probe then
        local lockable = getFacedObject()
        if lockable then
            local trapSpell = T.Lockable.getTrapSpell(lockable)
            if trapSpell then
                return { trapSpell = trapSpell }
            end
        end
    end
end

input.registerActionHandler("Use", async:callback(function()
    if not input.getBooleanActionValue("Use") then return end
    if T.Actor.getStance(self) ~= T.Actor.STANCE.Weapon then return end
    local weapon = T.Actor.getEquipment(self, T.Actor.EQUIPMENT_SLOT.CarriedRight)
    lockableStats = getSecurityTargetStats(weapon)
end))

local function checkPhysicalDamageOMW49(state, deltaTime)
    local armorStats = state.skills.scaled.armor
    local magicDamage = 0
    local hasDrainHealth = false
    local hasFortifyHealth = false
    for _, effect in pairs(mC.self.activeEffects) do
        if mCore.healthEffectIds[effect.id] then
            local magnitude = math.max(0, effect.magnitude)
            if effect.id == core.magic.EFFECT_TYPE.RestoreHealth then
                magicDamage = magicDamage - magnitude * deltaTime
            elseif effect.id == core.magic.EFFECT_TYPE.FortifyHealth then
                hasFortifyHealth = true
                if magnitude ~= armorStats.fortifyHealth then
                    magicDamage = magicDamage - magnitude + armorStats.fortifyHealth
                    armorStats.fortifyHealth = magnitude
                end
            elseif effect.id == core.magic.EFFECT_TYPE.DrainHealth then
                hasDrainHealth = true
                if state.skills.scaled.health > mC.self.health.base then
                    magicDamage = magicDamage + magnitude
                elseif armorStats.drainHealth < magnitude then
                    magicDamage = magicDamage + magnitude - armorStats.drainHealth
                end
                armorStats.drainHealth = magnitude
            elseif effect.id == core.magic.EFFECT_TYPE.SunDamage then
                if self.cell.isExterior or self.cell:hasTag("QuasiExterior") then
                    magicDamage = magicDamage + magnitude * deltaTime
                end
            else
                magicDamage = magicDamage + magnitude * deltaTime
            end
        end
    end
    local healthDiff = state.skills.scaled.health - mC.self.health.current
    if not hasDrainHealth and armorStats.drainHealth ~= 0 then
        log(string.format("Drain health effect %d stopped", armorStats.drainHealth))
        armorStats.drainHealth = math.min(armorStats.drainHealth, math.max(0, mC.self.health.base - state.skills.scaled.health))
        magicDamage = magicDamage - armorStats.drainHealth
        armorStats.drainHealth = 0
    end
    if not hasFortifyHealth and armorStats.fortifyHealth ~= 0 then
        log(string.format("Fortify health effect %d stopped", armorStats.fortifyHealth))
        magicDamage = magicDamage + armorStats.fortifyHealth
        armorStats.fortifyHealth = 0
    end
    if healthDiff == 0 then
        return 0
    end
    local nonMagicDamage = healthDiff - magicDamage
    log(string.format("The player took %.1f damage (dt %.3f): %.1f non magical, %.1f magic", healthDiff, deltaTime, nonMagicDamage, magicDamage))
    return nonMagicDamage
end

local function getJumpMaxStats()
    local capacity = T.Actor.getCapacity(self)
    local encumbranceTerm = mCore.GMSTs.fJumpEncumbranceBase
            + mCore.GMSTs.fJumpEncumbranceMultiplier * (1 - (capacity == 0 and 1 or T.Actor.getEncumbrance(self) / capacity))

    local acrobatics = T.NPC.stats.skills.acrobatics(self).modified
    local a = acrobatics
    local b = 0
    if a > 50 then
        b = a - 50
        a = 50
    end
    local x = mCore.GMSTs.fJumpAcrobaticsBase + (a / 15) ^ mCore.GMSTs.fJumpAcroMultiplier
    x = x + 3 * b * mCore.GMSTs.fJumpAcroMultiplier
    x = x + mC.self.activeEffects:getEffect(core.magic.EFFECT_TYPE.Jump).magnitude * 64
    x = x * encumbranceTerm
    if self.controls.run then
        x = x * mCore.GMSTs.fJumpRunMultiplier
    end
    x = x * mCore.GMSTs.fFatigueBase
    x = x + mCore.GravityAcceleration
    x = x / 3

    local height = (x ^ 2) / (2 * mCore.GravityAcceleration)
    if self.controls.movement ~= 0 or self.controls.sideMovement ~= 0 then
        x = x * mCore.JumpVelocityFactor
    end

    local midairVelocity = x + T.Actor.getRunSpeed(self) * (mCore.GMSTs.fJumpMoveBase + mCore.GMSTs.fJumpMoveMult * acrobatics / 100)
    return { height = height, duration = 2 * x / mCore.GravityAcceleration, midairVelocity = midairVelocity }
end

local function getFallLostHealth(depth, soft)
    local skill = T.NPC.stats.skills.acrobatics(self).modified
    if soft then
        -- as in vanilla, no damage below a specific height
        depth = depth - mCore.GMSTs.fFallDamageDistanceMin
    end
    if depth <= 0 then return 0 end
    depth = math.max(0, depth - 1.5 * skill + mC.self.activeEffects:getEffect(core.magic.EFFECT_TYPE.Jump).magnitude)
    depth = mCore.GMSTs.fFallDistanceBase + mCore.GMSTs.fFallDistanceMult * depth
    depth = depth * (mCore.GMSTs.fFallAcroBase + mCore.GMSTs.fFallAcroMult * (100 - skill))
    return depth <= 0 and 0 or math.max(0, depth * (1 - 0.25 * mCore.GMSTs.fFatigueBase))
end

local function notifySkillScaledGain(skillId, useType, factor)
    if mS.skillUsesScaledStorage:get("skillScalingDebugNotifsEnabled") then
        mUi.notify(string.format("Scaled %s\n%s: %.1f%%", Skills[skillId].name, mCfg.skillUseTypes[skillId][useType].key, factor * 100))
    end
end

local function onJumpFinished(state, stats, factor)
    local params = stats.handlerParams
    params.scale = params.scale * factor
    self:sendEvent(mDef.events.applySkillUsedHandlers, {
        skillId = Skills.acrobatics.id,
        params = params,
        afterHandler = "scaled",
    })
    notifySkillScaledGain(Skills.acrobatics.id, I.SkillProgression.SKILL_USE_TYPES.Acrobatics_Jump, factor)
    state.skills.scaled.acrobatics.lastJumpMaxDuration = stats.max.duration
    state.skills.scaled.acrobatics.stats = nil
end

local function getDepthInfo(pos, fromZ)
    local to = pos - util.vector3(0, 0, 10000)
    local result = nearby.castRay(pos, to, {
        collisionType = nearby.COLLISION_TYPE.HeightMap + nearby.COLLISION_TYPE.World + nearby.COLLISION_TYPE.Door + nearby.COLLISION_TYPE.Water,
        -- smaller than the player's box to detect medium-sized slippy holes
        radius = mC.self.halfExtents.y / 2,
    })
    if result.hitPos then
        local water, lava = false, false
        local obj = result.hitObject
        if obj and (lavaIdCache[obj.recordId] or obj.type.record(obj).mwscript == "lava") then
            lavaIdCache[obj.recordId] = true
            lava = true
        end
        if self.cell.hasWater and self.cell.waterLevel >= result.hitPos.z then
            local resultNoWater = nearby.castRay(pos, to, {
                collisionType = nearby.COLLISION_TYPE.HeightMap + nearby.COLLISION_TYPE.World + nearby.COLLISION_TYPE.Door,
                radius = mC.self.halfExtents.y / 2,
            })
            if not resultNoWater.hitPos or result.hitPos.z - resultNoWater.hitPos.z > mCore.GMSTs.fSwimHeightScale * 2 * mC.self.halfExtents.z then
                water = true
            end
        end
        return { depth = math.max(0, fromZ - result.hitPos.z), lava = lava, water = water }
    end
    return { depth = 10000, hitInfo = result }
end

local function getHealthRisk(lostHealth)
    -- lost health risk, max at 100, but reduced by the acrobatics level
    return (lostHealth / 100) ^ 0.5
end

local function getLandingRiskStillFactor()
    local rotation = util.transform.identity
    local from = self:getBoundingBox().center + util.vector3(0, 0, mC.self.halfExtents.z / 4)
    -- check risk in 8 directions, and for each direction, check the risk along 10 steps
    local slices = 8
    local steps = 10
    local totalSum = 0
    local logStats = {}
    for slice = 1, slices do
        if trace then table.insert(logStats, string.format("\nslice %d", slice)) end
        rotation = rotation * util.transform.rotateZ(2 * math.pi / slices)
        local prevDepth = 0
        local prevDist = 0
        local maxRisk = 0
        local step = 0
        local dist = 0
        local slipperySlope

        local function getLandingDepthRiskProps(depthInfo)
            local depthFactor = (depthInfo.water and mCfg.jumpGainWaterFactor or 1)
            --if trace then table.insert(logStats, string.format("depthFactor %.2f", depthFactor)) end
            return {
                factor = depthFactor * math.min(mCfg.jumpGainLandingFallDamageMaxFactor, getHealthRisk(getFallLostHealth(depthInfo.depth))),
                bonus = depthInfo.lava and mCfg.jumpGainLavaMaxBonus or 0,
            }
        end

        local function addRiskFactor(riskProps, slopeAngle, _step)
            -- the further the risk, the lower the risk
            local stepFactor = 1 - (_step / (steps + 1))
            -- reduce the factor below 45°, increase it above 45°
            local slopeFactor = (1.5 - (2 * math.max(0, slopeAngle) / math.pi)) ^ 2
            local finalFactor = (riskProps.factor ^ slopeFactor + riskProps.bonus) * stepFactor
            -- only consider the highest risk for a given direction
            maxRisk = math.max(maxRisk, finalFactor)
            if trace then table.insert(logStats, string.format("risk %.2f, slope %.2f, stepF %.2f, slopeF %.2f, bonus %.2f, factor %.2f",
                    riskProps.factor, slopeAngle, stepFactor, slopeFactor, finalFactor)) end
        end

        local function endOfSlipperySlope()
            addRiskFactor(
                    getLandingDepthRiskProps(slipperySlope.depthInfo),
                    mH.angle(slipperySlope.depthInfo.depth, slipperySlope.prevDepth, slipperySlope.dist, slipperySlope.prevDist),
                    slipperySlope.step)
            slipperySlope = nil
        end

        local function handleStep()
            if trace then table.insert(logStats, string.format("-- step %d", step)) end
            dist = (1 + step) * mC.self.halfExtents.y
            local pos = from + rotation:apply(util.vector3(0, dist, 0))
            -- first horizontal ray to detect bumps and walls around
            local hRay = nearby.castRay(from, pos, {
                collisionType = nearby.COLLISION_TYPE.HeightMap + nearby.COLLISION_TYPE.World + nearby.COLLISION_TYPE.Door + nearby.COLLISION_TYPE.Water,
                radius = mC.self.halfExtents.z / 4,
            })
            if hRay.hit then
                -- bump found, stop detecting the risk for this slice
                if trace then table.insert(logStats, "H hit") end
                return false
            end
            local depthInfo = getDepthInfo(pos, self.position.z)
            if trace then table.insert(logStats, string.format("depth %d", depthInfo.depth)) end
            local slippery = false
            local slopeAngle = mH.angle(depthInfo.depth, prevDepth, dist, prevDist)
            if slopeAngle > mCore.MaxSlopeAngle then
                -- the slope is too steep, we ignore the current step and we'll process the risk once we reach the bottom of the slippery slope
                slippery = true
                if not slipperySlope then
                    -- preserve the context of the beginning of the slippery slope
                    slipperySlope = {
                        step = step,
                        prevDepth = prevDepth,
                        dist = dist,
                        prevDist = prevDist,
                    }
                end
                -- update the end context of the slippery slope
                slipperySlope.depthInfo = depthInfo
                if trace then table.insert(logStats, "slippery") end
            end
            if not slippery then
                if slipperySlope then
                    -- we reached the bottom of the slope
                    endOfSlipperySlope()
                end
                local riskProps = getLandingDepthRiskProps(depthInfo)
                addRiskFactor(riskProps, slopeAngle, step)
            end
            prevDepth = depthInfo.depth
            prevDist = dist
            return true
        end

        while step < steps do
            if handleStep() then
                step = step + 1
            else
                step = steps
            end
        end
        if slipperySlope then
            -- last step is still a the slippery slope
            endOfSlipperySlope()
        end
        totalSum = totalSum + maxRisk
        if trace then table.insert(logStats, string.format("factor %.2f", maxRisk)) end
    end
    if trace then log(string.format("Jump landing surroundings risk:%s\n", table.concat(logStats, ", "))) end
    return mH.avg(totalSum, slices)
end

local function onJumpLanded(state)
    local pos = self.position
    local stats = state.skills.scaled.acrobatics.stats
    local avgSpeed = stats.speed.sum / stats.speed.count
    local maxSpeed = stats.max.midairVelocity
    local height = math.max(0, stats.maxHeightPos.z - stats.startPos.z)
    local landingHeight = pos.z - stats.startPos.z
    local avgDepth = mH.avg(stats.depth.sum, stats.depth.count)
    local depth = (2 * stats.depth.max + avgDepth) / 3
    local lavaBonus = mCfg.jumpGainLavaMaxBonus * stats.lava.present / math.max(1, stats.lava.present + stats.lava.absent)
    local riskDamage = getFallLostHealth(depth)
    local expectedDamage = getFallLostHealth(state.skills.scaled.acrobatics.maxFallPos.z - pos.z)
    local depthFactor = capFactor(getHealthRisk(math.max(0, riskDamage - expectedDamage)) + lavaBonus)
    local lastTimeFactor = capFactor(stats.timeSinceLastJump / state.skills.scaled.acrobatics.lastJumpMaxDuration) ^ 4
    local speedFactor = capFactor(avgSpeed / maxSpeed)
    local heightFactor = capFactor(height / stats.max.height)
    local landingHeightFactor = capFactor(landingHeight / stats.max.height)
    local landingRiskStillFactor = capFactor(getLandingRiskStillFactor())
    local landingRiskFactor = landingRiskStillFactor * math.max(landingHeightFactor, speedFactor) ^ 0.5
    local dodgeFactor = mH.sum(stats.dodges)
    local factor = capSkillScaledFactor(math.max(
            lastTimeFactor *
                    math.max(
                            mCfg.jumpGainMaxMovementFactor * math.max(speedFactor, heightFactor),
                            mCfg.jumpGainBottomFactor * speedFactor * depthFactor + mCfg.jumpGainLandingRiskFactor * landingRiskFactor
                    ),
            mCfg.jumpDodgeFactor * dodgeFactor
    ), mS.getSkillGainScaledRange("acrobaticsSkillScalingRange"))

    log(string.format("Jumped:\n\tStats: since time %.2f/%.2f, landing risk still %.2f, depth max %.1f avg %.1f, lava %.3f, damage risk %d expected %d, speed %.1f/%.1f, height %.1f/%.1f, landed at %.1f"
            .. "\n\tFactors: cap(max("
            .. "\n\t    last time %.3f x max("
            .. "\n\t        %s x max(speed %.3f, height %.3f),"
            .. "\n\t        %s x speed %.3f x depth %.3f + %s x landing risk %.3f"
            .. "\n\t    ),"
            .. "\n\t    %s x dodge %.3f"
            .. "\n\t)) = final %.5f"
            .. "\n\tGain scale: %.5f x scaling %.5f = %.5f",
    -- Stats
            stats.timeSinceLastJump, stats.max.duration,
            landingRiskStillFactor,
            stats.depth.max, avgDepth, lavaBonus,
            riskDamage, expectedDamage,
            avgSpeed, maxSpeed,
            height, stats.max.height,
            landingHeight,
    -- Factors
            lastTimeFactor,
            mCfg.jumpGainMaxMovementFactor, speedFactor, heightFactor,
            mCfg.jumpGainBottomFactor, speedFactor, depthFactor,
            mCfg.jumpGainLandingRiskFactor, landingRiskFactor,
            mCfg.jumpDodgeFactor, dodgeFactor,
            factor,
            stats.handlerParams.scale, factor, stats.handlerParams.scale * factor))

    onJumpFinished(state, stats, factor)
end

local function handleJumps(state, isSlowFalling, deltaTime)
    local stats = state.skills.scaled.acrobatics.stats

    local depthInfo = getDepthInfo(self.position, stats.startPos.z)
    if depthInfo.lava then
        stats.lava.present = stats.lava.present + 1
    else
        stats.lava.absent = stats.lava.absent + 1
    end
    local depthFactor = depthInfo.water and mCfg.jumpGainWaterFactor or 1
    local slowFallFactor = isSlowFalling and mCfg.jumpGainSlowFallDepthFactor or 1
    local finalDepth = depthInfo.depth * depthFactor * slowFallFactor
    stats.depth.max = math.max(stats.depth.max, finalDepth)
    stats.depth.sum = stats.depth.sum + finalDepth
    stats.depth.count = stats.depth.count + 1

    stats.speed.sum = stats.speed.sum + state.skills.scaled.groundDist / deltaTime
    stats.speed.count = stats.speed.count + 1

    if self.position.z > stats.maxHeightPos.z then
        stats.maxHeightPos = self.position
    end

    if stats.hasJumpStarted and state.skills.scaled.isOnGround then
        onJumpLanded(state)
    end
end

local function getSwimSpeedFactor()
    local factor = 1 + 0.01 * mC.self.activeEffects:getEffect(core.magic.EFFECT_TYPE.SwiftSwim).magnitude
    return factor * (0.01 * T.NPC.stats.skills.athletics(self).modified * mCore.GMSTs.fSwimRunAthleticsMult + mCore.GMSTs.fSwimRunBase)
end

local function handleAthletics(state, deltaTime)
    local stats = state.skills.scaled.athletics
    local isMoving = self.controls.movement ~= 0 or self.controls.sideMovement ~= 0
    if isMoving and self.controls.run then
        stats.deltaTime = stats.deltaTime + deltaTime
        if state.skills.scaled.isOnGround or T.Actor.isSwimming(self) then
            if state.skills.scaled.isOnGround then
                stats.deltaPos = stats.deltaPos + mH.groundDist(self.position, state.skills.scaled.pos)
            else
                stats.deltaPos = stats.deltaPos + (self.position - state.skills.scaled.pos):length()
            end
            stats.runningDuration = math.min(mCfg.athleticsGainMaxTime, stats.runningDuration + deltaTime)
        end
        return
    end
    stats.deltaTime = 0
    stats.deltaPos = 0
    if isMoving then
        stats.runningDuration = math.max(0, stats.runningDuration - deltaTime)
    else
        stats.runningDuration = math.max(0, stats.runningDuration - 2 * deltaTime)
    end
end

local function checkIngredients()
    local ingredients = {}
    local removed = {}
    removedIngredients = {}
    for _, ingredient in ipairs(mC.self.inventory:getAll(T.Ingredient)) do
        if ownedIngredients[ingredient.recordId] then
            local diff = ownedIngredients[ingredient.recordId].count - ingredient.count
            if diff > 0 then
                removed[ingredient.recordId] = { obj = ingredient, count = diff }
            end
            ownedIngredients[ingredient.recordId] = nil
        end
        ingredients[ingredient.recordId] = { obj = ingredient, count = ingredient.count }
    end
    for _, ingredient in pairs(ownedIngredients) do
        removed[ingredient.obj.recordId] = ingredient
    end
    ownedIngredients = ingredients
    if next(removed) then
        removedIngredients = removed
    end
end

local function getLastPotionStats()
    local ingredients = {}
    for id, ingredient in pairs(removedIngredients) do
        ingredient.count = ingredient.count - 1
        if ingredient.count == 0 then
            removedIngredients[id] = nil
        end
        local effects = {}
        for _, effect in ipairs(ingredient.obj.type.record(ingredient.obj).effects) do
            effects[effect.id] = effect.effect
        end
        table.insert(ingredients, { id = id, effects = effects })
    end
    if #ingredients == 0 then
        return nil
    end
    local effectiveIngredientIds = {}
    local activeEffects = {}
    for i = 1, #ingredients - 1 do
        local ingredient1 = ingredients[i]
        for j = i + 1, #ingredients do
            local ingredient2 = ingredients[j]
            local hasCommonEffect
            for effectId in pairs(ingredient1.effects) do
                if ingredient2.effects[effectId] then
                    hasCommonEffect = true
                    activeEffects[effectId] = ingredient2.effects[effectId]
                end
            end
            if hasCommonEffect then
                effectiveIngredientIds[ingredient1.id] = true
                effectiveIngredientIds[ingredient2.id] = true
            end
        end
    end
    local positiveEffects = 0
    for _, effect in pairs(activeEffects) do
        if not effect.harmful then
            positiveEffects = positiveEffects + 1
        end
    end
    local validIds = {}
    for id in pairs(effectiveIngredientIds) do
        table.insert(validIds, id)
    end
    table.sort(validIds)
    return { key = table.concat(validIds, ":"), positiveEffects = positiveEffects }
end

local function getWeaponScalingFactor(skillId, enemy)
    local attackTerm = mCore.agilityTerm(self, skillId) * mCore.GMSTs.fFatigueBase
    local defenseTerm = mCore.agilityTerm(enemy) * mCore.GMSTs.fFatigueBase
    local chance = math.floor(0.5 + attackTerm - defenseTerm) / 100
    local factor = capSkillScaledFactor(
            6 / math.max(0.01, 1.5 + chance) - 2,
            mS.getSkillGainScaledRange("weaponSkillScalingRange"))
    local message = string.format("Weapon skills scaling: Hit the enemy \"%s\" (attack %.2f, defense %.2f), chance = %.2f",
            enemy.recordId, attackTerm, defenseTerm, chance)
    return factor, message
end

local function getArmorScalingFactor(damage)
    local healthRatio = damage / mC.self.health.base
    local factor = capSkillScaledFactor(
            4 * healthRatio,
            mS.getSkillGainScaledRange("armorSkillScalingRange"))
    local message = string.format("Armor skills scaling: Hit by an enemy, damage = %.1f, health ratio = %.2f", damage, healthRatio)
    return factor, message
end

local function logSkillScaling(message, scale, factor)
    log(string.format("%s, scale = %.5f x scaling %.5f = %.5f", message, scale, factor, scale * factor))
end

module.skillUsedHandler = function(state, skillId, params)
    local factor = 1
    local message = ""
    if mCore.magickaSkills[skillId] then
        if not mS.skillUsesScaledStorage:get("magickaBasedSkillScalingEnabled") then return end
        if not mC.hasJustSpellCasted() then
            log("Magicka skills scaling: No spell cast detected, no scaling")
            return
        end
        local spell = T.Actor.getSelectedSpell(self)
        local chance = math.max(0, mCore.GMSTs.fFatigueBase * mSpells.calcAutoCastChance(spell, self) / 100)
        factor = capSkillScaledFactor(
                chance < 1 and (2 - chance ^ 2) or (1 - (chance - 1) ^ 4),
                mS.getSkillGainScaledRange("magickaBasedSkillScalingRange"))
        message = string.format("Magicka skills scaling: Cast the spell \"%s\" cost %d, chance = %.2f", spell.name, spell.cost, chance)
    elseif mCore.weaponSkills[skillId] then
        if not mS.skillUsesScaledStorage:get("weaponSkillScalingEnabled") then return end
        if mDef.isOpenMW50 then
            state.skills.scaled.weapon = {
                handlerParams = { skillGain = params.skillGain, scale = params.scale, useType = params.useType },
                skillId = skillId,
            }
            -- will be handled on hit
            params.skillGain = 0
            return
        end
        if skillId == Skills.marksman.id then
            return
        end
        if not mC.hasJustMeleeAttacked() then
            log("Weapon skills scaling: No attack detected, no scaling")
            return
        end
        local enemy = getFacedObject()
        if not enemy then
            log("Weapon skills scaling: No enemy found, no scaling")
            return
        end
        if enemy.type.baseType == T.Actor then
            factor, message = getWeaponScalingFactor(skillId, enemy)
        else
            log(string.format("Weapon skills scaling: The target \"%s\" is not an actor", enemy.recordId))
        end
    elseif skillId == Skills.security.id then
        if not mS.skillUsesScaledStorage:get("securitySkillScalingEnabled") then return end
        if not mC.isLockPicking() then
            log("Security scaling: No lock or disarm attempt detected, no scaling")
            return
        end
        if not lockableStats then
            log("Security scaling: No lockable found, no scaling")
            return
        end
        if lockableStats.lockLevel then
            local chance = mCore.agilityTerm(self, skillId)
                    * mCore.GMSTs.fFatigueBase
                    + lockableStats.lockLevel * mCore.GMSTs.fPickLockMult
            factor = capSkillScaledFactor(
                    2 * (math.max(0, 1 - chance / 100)),
                    mS.getSkillGainScaledRange("securitySkillScalingRange"))
            message = string.format("Security scaling: Unlocked a lock level %d, chance = %.2f", lockableStats.lockLevel, chance)
        elseif lockableStats.trapSpell then
            local chance = mCore.agilityTerm(self, skillId)
                    * mCore.GMSTs.fFatigueBase
                    + lockableStats.trapSpell.cost * mCore.GMSTs.fTrapCostMult
            factor = capSkillScaledFactor(
                    2 * (math.max(0, 1 - chance / 100)),
                    mS.getSkillGainScaledRange("securitySkillScalingRange"))
            message = string.format("Security scaling: Disarmed a trap with spell cost %d, chance = %.2f", lockableStats.trapSpell.cost, chance)
        end
    elseif mCore.armorSkills[skillId] then
        if not mS.skillUsesScaledStorage:get("armorSkillScalingEnabled") then return end
        if mDef.isOpenMW50 then
            state.skills.scaled.armor.handlerParams = { skillGain = params.skillGain, scale = params.scale, useType = params.useType }
            state.skills.scaled.armor.skillId = skillId
            -- will be handle on hit
            params.skillGain = 0
            return
        end
        -- if received multiple hits during the same frame, use the merged health damage and apply the skill gain factor on the first triggered armor skill use
        if state.skills.scaled.armor.skillUsedInFrame then
            params.skillGain = 0
            return
        end
        state.skills.scaled.armor.skillUsedInFrame = true
        local physicalDamage = checkPhysicalDamageOMW49(state, state.skills.scaled.deltaTime)
        if physicalDamage <= 0 then
            log(string.format("Armor skills scaling: No physical damage (%.1f), no scaling", physicalDamage))
            return
        end
        if mC.self.health.base <= 0 then
            log(string.format("Armor skills scaling: Base health is not positive (%.1f), no scaling", mC.self.health.base))
            return
        end
        factor, message = getArmorScalingFactor(physicalDamage)
    elseif skillId == Skills.acrobatics.id then
        if not mS.skillUsesScaledStorage:get("acrobaticsSkillScalingEnabled") then return end
        if params.useType == I.SkillProgression.SKILL_USE_TYPES.Acrobatics_Fall then
            local height = state.skills.scaled.acrobatics.maxFallPos.z - self.position.z
            if height < 1 then
                log("Acrobatics fall scaling: No fall detected, no scaling")
                return
            end
            local damage = getFallLostHealth(height, true)
            -- limited to 200% (before death)
            local healthRatio = 2 * capFactor(damage / mC.self.health.base)
            factor = capSkillScaledFactor(healthRatio, mS.getSkillGainScaledRange("acrobaticsSkillScalingRange"))
            message = string.format("Acrobatics fall scaling: Took damage from a fall, damage = %.1f, health ratio = %.2f", damage, healthRatio)
            if not mDef.isOpenMW50 then
                module.onHealthModified(state, -damage)
            end
        elseif params.useType == I.SkillProgression.SKILL_USE_TYPES.Acrobatics_Jump then
            if not self.controls.jump then
                log("Acrobatics jump scaling: Not jumping, no scaling")
                return
            end
            local time = core.getSimulationTime()
            state.skills.scaled.acrobatics.stats = {
                handlerParams = { skillGain = params.skillGain, scale = params.scale, useType = params.useType },
                max = getJumpMaxStats(),
                maxHeightPos = self.position,
                depth = { max = 0, sum = 0, count = 0 },
                speed = { sum = 0, count = 0 },
                lava = { present = 0, absent = 0 },
                startPos = self.position,
                hasJumpStarted = false,
                timeSinceLastJump = time - state.skills.scaled.acrobatics.lastJumpTime,
                dodges = {},
            }
            state.skills.scaled.acrobatics.lastJumpTime = time
            state.skills.scaled.acrobatics.maxFallPos = self.position
            -- gain will be added on landing
            params.skillGain = 0
            return
        end
    elseif skillId == Skills.athletics.id then
        if not mS.skillUsesScaledStorage:get("athleticsSkillScalingEnabled") then return end
        local stats = state.skills.scaled.athletics
        if stats.runningDuration == 0 then
            log("Athletics scaling: Ran for 0 seconds, no scaling")
            return
        end
        local timeRatio = 2 * (stats.runningDuration / mCfg.athleticsGainMaxTime) ^ mCfg.athleticsGainCurvePower
        local maxSpeed = T.Actor.getRunSpeed(self)
        if T.Actor.isSwimming(self) then
            maxSpeed = maxSpeed * getSwimSpeedFactor()
        end
        local velocityRatio = stats.deltaTime > 0
                and math.min(1, stats.deltaPos / (stats.deltaTime * maxSpeed))
                or 1
        factor = capSkillScaledFactor(
                timeRatio * velocityRatio,
                mS.getSkillGainScaledRange("athleticsSkillScalingRange"))
        message = string.format("Athletics scaling: Run duration %.2f, time ratio %.2f, velocity %.2f", stats.runningDuration, timeRatio, velocityRatio)
        stats.deltaTime = 0
        stats.deltaPos = 0
    elseif skillId == Skills.alchemy.id then
        if params.useType ~= I.SkillProgression.SKILL_USE_TYPES.Alchemy_CreatePotion then
            return
        end
        if not mS.skillUsesScaledStorage:get("alchemySkillScalingEnabled") then return end
        local potionStats = getLastPotionStats()
        if not potionStats then
            log("Alchemy scaling: No consumed ingredients, no scaling")
            return
        end
        local recipeCount = state.skills.scaled.alchemy.recipeCounts[potionStats.key] or 0
        state.skills.scaled.alchemy.recipeCounts[potionStats.key] = recipeCount + 1
        factor = capSkillScaledFactor((0.5 + potionStats.positiveEffects / 2)
                * (1 - math.min(recipeCount, 100) / 100) ^ 2, mS.getSkillGainScaledRange("alchemySkillScalingRange"))
        message = string.format("Alchemy scaling: Created the %s potion from a recipe (%s) with %d positive effects",
                mH.ordinal(recipeCount + 1), potionStats.key, potionStats.positiveEffects)
        if recipeCount == 100 then
            mC.showMessage(state, L("alchemyScalingRecipeLimit"))
        end
    end

    logSkillScaling(message, params.scale, factor)
    params.scale = params.scale * factor
    notifySkillScaledGain(skillId, params.useType, factor)
end

module.onActorHit = function(state, actor)
    local stats = state.skills.scaled.weapon
    if not stats.skillId then
        log(string.format("Weapon skills scaling: No skill use, no scaling"))
        return
    end
    local params = stats.handlerParams
    local factor, message = getWeaponScalingFactor(stats.skillId, actor)
    logSkillScaling(message, params.scale, factor)
    params.scale = params.scale * factor
    self:sendEvent(mDef.events.applySkillUsedHandlers, {
        skillId = stats.skillId,
        params = params,
        afterHandler = "scaled",
    })
    notifySkillScaledGain(stats.skillId, params.useType, factor)
    state.skills.scaled.weapon = {}
end

module.onPlayerHit = function(state, attack)
    if attack.sourceType ~= "melee" and attack.sourceType ~= "ranged" then return end
    if attack.attacker and attack.sourceType == "melee" then
        lastEnemyHitTimes[attack.attacker.id] = core.getSimulationTime()
    end
    if not attack.successful or not attack.damage.health then return end
    local stats = state.skills.scaled.armor
    if not stats.skillId then
        log(string.format("Armor skills scaling: No skill use, no scaling"))
        return
    end
    local params = stats.handlerParams
    local baseDamage = attack.damage.health
    I.Combat.adjustDamageForDifficulty(attack)
    local damage = attack.damage.health
    -- restore original damage
    attack.damage.health = baseDamage
    damage = I.Combat.adjustDamageForArmor(damage, self)
    local factor, message = getArmorScalingFactor(damage)
    logSkillScaling(message, params.scale, factor)
    params.scale = params.scale * factor
    self:sendEvent(mDef.events.applySkillUsedHandlers, {
        skillId = stats.skillId,
        params = params,
        afterHandler = "scaled",
    })
    notifySkillScaledGain(stats.skillId, params.useType, factor)
    state.skills.scaled.armor.handlerParams = nil
    state.skills.scaled.armor.skillId = nil
end

module.onActorAnimHit = function(state, actor, animGroup, animKey)
    local lastHitTime = lastEnemyHitTimes[actor.id]
    local stats = state.skills.scaled.acrobatics.stats
    if stats and (not lastHitTime or core.getSimulationTime() - lastHitTime > 0.25) then
        local damage, hitChance = mCombat.getPotentialHitInfo(self, actor, animGroup, animKey, mC.werewolfClawMult)
        local attack = { damage = { health = damage, fatigue = 0, magicka = 0 }, sourceType = "melee", strength = 1, successful = 1 }
        I.Combat.adjustDamageForDifficulty(attack)
        local armorDamage = I.Combat.adjustDamageForArmor(attack.damage.health, self)
        local hitChanceDamage = armorDamage * hitChance
        local healthRatio = hitChanceDamage / mC.self.health.base
        log(string.format("Acrobatics skills scaling: Dodged \"%s\" hit, damage (base %.1f, difficulty %.1f, armor %.1f, hitChance %.1f), hit chance %.2f, health ratio = %.2f",
                actor.recordId, damage, attack.damage.health, armorDamage, hitChanceDamage, hitChance, healthRatio))
        table.insert(stats.dodges, healthRatio)
    end
    -- only consider the first hit when enemies produce multiple animation hits per hit
    lastEnemyHitTimes[actor.id] = core.getSimulationTime()
end

module.onHealthModified = function(state, value)
    state.skills.scaled.health = state.skills.scaled.health + value
end

module.uiModeChanged = function(data)
    if data.newMode == "Alchemy" and mS.skillUsesScaledStorage:get("alchemySkillScalingEnabled") then
        ownedIngredients = {}
    else
        ownedIngredients = nil
    end
end

module.onUpdate = function(state, deltaTime)
    local armorEnabled = mS.skillUsesScaledStorage:get("armorSkillScalingEnabled")
    local acrobaticsEnabled = mS.skillUsesScaledStorage:get("acrobaticsSkillScalingEnabled")
    local athleticsEnabled = mS.skillUsesScaledStorage:get("athleticsSkillScalingEnabled")

    if not mDef.isOpenMW50 and armorEnabled then
        local stats = state.skills.scaled.armor
        stats.skillUsedInFrame = false
        if state.skills.scaled.health ~= mC.self.health.current or stats.drainHealth ~= 0 then
            -- update drain health data
            checkPhysicalDamageOMW49(state, deltaTime)
        end
    end

    local wasOnGround
    if acrobaticsEnabled or athleticsEnabled then
        wasOnGround = state.skills.scaled.isOnGround
        state.skills.scaled.isOnGround = T.Actor.isOnGround(self)
        state.skills.scaled.groundDist = mH.groundDist(self.position, state.skills.scaled.pos)
    end

    if acrobaticsEnabled then
        local isSlowFalling = mC.self.activeEffects:getEffect(core.magic.EFFECT_TYPE.SlowFall).magnitude > 0
        local isLevitating = mC.self.activeEffects:getEffect(core.magic.EFFECT_TYPE.Levitate).magnitude > 0
        if state.skills.scaled.isOnGround or isSlowFalling or isLevitating or self.position.z > state.skills.scaled.acrobatics.maxFallPos.z then
            state.skills.scaled.acrobatics.maxFallPos = self.position
        end
        local stats = state.skills.scaled.acrobatics.stats
        if stats then
            if isLevitating then
                local minFactor = mS.getSkillGainScaledRange("acrobaticsSkillScalingRange").min
                log(string.format("Used levitate during a jump, scaling %.3f", minFactor))
                onJumpFinished(state, stats, minFactor)
            else
                if wasOnGround and not state.skills.scaled.isOnGround then
                    stats.hasJumpStarted = true
                end
                handleJumps(state, isSlowFalling, deltaTime)
            end
        end
    end

    if athleticsEnabled then
        handleAthletics(state, deltaTime)
    end

    state.skills.scaled.pos = self.position
    if not mDef.isOpenMW50 then
        state.skills.scaled.deltaTime = deltaTime
        state.skills.scaled.health = mC.self.health.current
    end
end

module.onFrame = function()
    if ownedIngredients then
        checkIngredients()
    end
end

return module