local core = require('openmw.core')
local I = require('openmw.interfaces')
local T = require('openmw.types')
local input = require('openmw.input')
local async = require('openmw.async')
local camera = require('openmw.camera')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local util = require('openmw.util')

local log = require('scripts.skill-evolution.util.log')
local mDef = require('scripts.skill-evolution.config.definition')
local mCfg = require('scripts.skill-evolution.config.configuration')
local mS = require('scripts.skill-evolution.config.settings')
local mCore = require('scripts.skill-evolution.util.core')
local mCombat = require('scripts.skill-evolution.util.combat')
local mSpells = require('scripts.skill-evolution.util.spells')
local mNotifs = require("scripts.skill-evolution.ui.notifications")
local mH = require('scripts.skill-evolution.util.helpers')

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
    x = x + mCore.self.activeEffects:getEffect(core.magic.EFFECT_TYPE.Jump).magnitude * 64
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
    depth = math.max(0, depth - 1.5 * skill + mCore.self.activeEffects:getEffect(core.magic.EFFECT_TYPE.Jump).magnitude)
    depth = mCore.GMSTs.fFallDistanceBase + mCore.GMSTs.fFallDistanceMult * depth
    depth = depth * (mCore.GMSTs.fFallAcroBase + mCore.GMSTs.fFallAcroMult * (100 - skill))
    return depth <= 0 and 0 or math.max(0, depth * (1 - 0.25 * mCore.GMSTs.fFatigueBase))
end

local function notifySkillScaledGain(skillId, useType, factor)
    if mS.skillUsesScaledStorage:get("skillScalingDebugNotifsEnabled") then
        mNotifs.notify(string.format("Scaled %s\n%s: %.1f%%", Skills[skillId].name, mCfg.skillUseTypes[skillId][useType].key, factor * 100))
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
    state.scaled.acrobatics.lastJumpMaxDuration = stats.max.duration
    state.scaled.acrobatics.stats = nil
end

local function getDepthInfo(pos, fromZ)
    local to = pos - util.vector3(0, 0, 10000)
    local result = nearby.castRay(pos, to, {
        collisionType = nearby.COLLISION_TYPE.HeightMap + nearby.COLLISION_TYPE.World + nearby.COLLISION_TYPE.Door + nearby.COLLISION_TYPE.Water,
        -- smaller than the player's box to detect medium-sized slippy holes
        radius = mCore.self.halfExtents.y / 2,
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
                radius = mCore.self.halfExtents.y / 2,
            })
            if not resultNoWater.hitPos or result.hitPos.z - resultNoWater.hitPos.z > mCore.GMSTs.fSwimHeightScale * 2 * mCore.self.halfExtents.z then
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
    local from = self:getBoundingBox().center + util.vector3(0, 0, mCore.self.halfExtents.z / 4)
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
            dist = (1 + step) * mCore.self.halfExtents.y
            local pos = from + rotation:apply(util.vector3(0, dist, 0))
            -- first horizontal ray to detect bumps and walls around
            local hRay = nearby.castRay(from, pos, {
                collisionType = nearby.COLLISION_TYPE.HeightMap + nearby.COLLISION_TYPE.World + nearby.COLLISION_TYPE.Door + nearby.COLLISION_TYPE.Water,
                radius = mCore.self.halfExtents.z / 4,
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
    local stats = state.scaled.acrobatics.stats
    local avgSpeed = stats.speed.sum / stats.speed.count
    local maxSpeed = stats.max.midairVelocity
    local height = math.max(0, stats.maxHeightPos.z - stats.startPos.z)
    local landingHeight = pos.z - stats.startPos.z
    local avgDepth = mH.avg(stats.depth.sum, stats.depth.count)
    local depth = (2 * stats.depth.max + avgDepth) / 3
    local lavaBonus = mCfg.jumpGainLavaMaxBonus * stats.lava.present / math.max(1, stats.lava.present + stats.lava.absent)
    local riskDamage = getFallLostHealth(depth)
    local expectedDamage = getFallLostHealth(state.scaled.acrobatics.maxFallPos.z - pos.z)
    local depthFactor = capFactor(getHealthRisk(math.max(0, riskDamage - expectedDamage)) + lavaBonus)
    local lastTimeFactor = capFactor(stats.timeSinceLastJump / state.scaled.acrobatics.lastJumpMaxDuration) ^ 4
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
    ), mS.getSkillUsesScaledRange("acrobaticsSkillScalingRange"))

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
    local stats = state.scaled.acrobatics.stats

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

    stats.speed.sum = stats.speed.sum + state.scaled.groundDist / deltaTime
    stats.speed.count = stats.speed.count + 1

    if self.position.z > stats.maxHeightPos.z then
        stats.maxHeightPos = self.position
    end

    if stats.hasJumpStarted and state.scaled.isOnGround then
        onJumpLanded(state)
    end
end

local function getSwimSpeedFactor()
    local factor = 1 + 0.01 * mCore.self.activeEffects:getEffect(core.magic.EFFECT_TYPE.SwiftSwim).magnitude
    return factor * (0.01 * T.NPC.stats.skills.athletics(self).modified * mCore.GMSTs.fSwimRunAthleticsMult + mCore.GMSTs.fSwimRunBase)
end

local function handleAthletics(state, deltaTime)
    local stats = state.scaled.athletics
    local isMoving = self.controls.movement ~= 0 or self.controls.sideMovement ~= 0
    if isMoving and self.controls.run then
        stats.deltaTime = stats.deltaTime + deltaTime
        if state.scaled.isOnGround or T.Actor.isSwimming(self) then
            if state.scaled.isOnGround then
                stats.deltaPos = stats.deltaPos + mH.groundDist(self.position, state.scaled.pos)
            else
                stats.deltaPos = stats.deltaPos + (self.position - state.scaled.pos):length()
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
    for _, ingredient in ipairs(mCore.self.inventory:getAll(T.Ingredient)) do
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
            mS.getSkillUsesScaledRange("weaponSkillScalingRange"))
    local message = string.format("Weapon skills scaling: Hit the enemy \"%s\" (attack %.2f, defense %.2f), chance = %.2f",
            enemy.recordId, attackTerm, defenseTerm, chance)
    return factor, message
end

local function getArmorScalingFactor(damage)
    local healthRatio = damage / mCore.self.health.base
    local factor = capSkillScaledFactor(
            4 * healthRatio,
            mS.getSkillUsesScaledRange("armorSkillScalingRange"))
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
        if not mCore.hasJustSpellCasted() then
            log("Magicka skills scaling: No spell cast detected, no scaling")
            return
        end
        local spell = T.Actor.getSelectedSpell(self)
        local chance = math.max(0, mCore.GMSTs.fFatigueBase * mSpells.calcAutoCastChance(spell, self) / 100)
        factor = capSkillScaledFactor(
                chance < 1 and (2 - chance ^ 2) or (1 - (chance - 1) ^ 4),
                mS.getSkillUsesScaledRange("magickaBasedSkillScalingRange"))
        message = string.format("Magicka skills scaling: Cast the spell \"%s\" cost %d, chance = %.2f", spell.name, spell.cost, chance)
    elseif mCore.weaponSkills[skillId] then
        if not mS.skillUsesScaledStorage:get("weaponSkillScalingEnabled") then return end
        state.scaled.weapon = {
            handlerParams = { skillGain = params.skillGain, scale = params.scale, useType = params.useType },
            skillId = skillId,
        }
        -- will be handled on hit
        params.skillGain = 0
        return
    elseif mCore.armorSkills[skillId] then
        if not mS.skillUsesScaledStorage:get("armorSkillScalingEnabled") then return end
        state.scaled.armor = {
            handlerParams = { skillGain = params.skillGain, scale = params.scale, useType = params.useType },
            skillId = skillId,
        }
        -- will be handle on hit
        params.skillGain = 0
        return
    elseif skillId == Skills.block.id then
        if not mS.skillUsesScaledStorage:get("blockSkillScalingEnabled") then return end
        state.scaled.block = {
            handlerParams = { skillGain = params.skillGain, scale = params.scale, useType = params.useType },
            time = core.getSimulationTime(),
            attacker = nil,
        }
        -- will be handle on hit
        params.skillGain = 0
        return
    elseif skillId == Skills.security.id then
        if not mS.skillUsesScaledStorage:get("securitySkillScalingEnabled") then return end
        if not mCore.isLockPicking() then
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
                    mS.getSkillUsesScaledRange("securitySkillScalingRange"))
            message = string.format("Security scaling: Unlocked a lock level %d, chance = %.2f", lockableStats.lockLevel, chance)
        elseif lockableStats.trapSpell then
            local chance = mCore.agilityTerm(self, skillId)
                    * mCore.GMSTs.fFatigueBase
                    + lockableStats.trapSpell.cost * mCore.GMSTs.fTrapCostMult
            factor = capSkillScaledFactor(
                    2 * (math.max(0, 1 - chance / 100)),
                    mS.getSkillUsesScaledRange("securitySkillScalingRange"))
            message = string.format("Security scaling: Disarmed a trap with spell cost %d, chance = %.2f", lockableStats.trapSpell.cost, chance)
        end
    elseif skillId == Skills.acrobatics.id then
        if not mS.skillUsesScaledStorage:get("acrobaticsSkillScalingEnabled") then return end
        if params.useType == I.SkillProgression.SKILL_USE_TYPES.Acrobatics_Fall then
            local height = state.scaled.acrobatics.maxFallPos.z - self.position.z
            if height < 1 then
                log("Acrobatics fall scaling: No fall detected, no scaling")
                return
            end
            local damage = getFallLostHealth(height, true)
            -- limited to 200% (before death)
            local healthRatio = 2 * capFactor(damage / mCore.self.health.base)
            factor = capSkillScaledFactor(healthRatio, mS.getSkillUsesScaledRange("acrobaticsSkillScalingRange"))
            message = string.format("Acrobatics fall scaling: Took damage from a fall, damage = %.1f, health ratio = %.2f", damage, healthRatio)
        elseif params.useType == I.SkillProgression.SKILL_USE_TYPES.Acrobatics_Jump then
            if not self.controls.jump then
                log("Acrobatics jump scaling: Not jumping, no scaling")
                return
            end
            local time = core.getSimulationTime()
            state.scaled.acrobatics.stats = {
                handlerParams = { skillGain = params.skillGain, scale = params.scale, useType = params.useType },
                max = getJumpMaxStats(),
                maxHeightPos = self.position,
                depth = { max = 0, sum = 0, count = 0 },
                speed = { sum = 0, count = 0 },
                lava = { present = 0, absent = 0 },
                startPos = self.position,
                hasJumpStarted = false,
                timeSinceLastJump = time - state.scaled.acrobatics.lastJumpTime,
                dodges = {},
            }
            state.scaled.acrobatics.lastJumpTime = time
            state.scaled.acrobatics.maxFallPos = self.position
            -- gain will be added on landing
            params.skillGain = 0
            return
        end
    elseif skillId == Skills.athletics.id then
        if not mS.skillUsesScaledStorage:get("athleticsSkillScalingEnabled") then return end
        local stats = state.scaled.athletics
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
                mS.getSkillUsesScaledRange("athleticsSkillScalingRange"))
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
        local recipeCount = state.scaled.alchemy.recipeCounts[potionStats.key] or 0
        state.scaled.alchemy.recipeCounts[potionStats.key] = recipeCount + 1
        factor = capSkillScaledFactor((0.5 + potionStats.positiveEffects / 2)
                * (1 - math.min(recipeCount, 100) / 100) ^ 2, mS.getSkillUsesScaledRange("alchemySkillScalingRange"))
        message = string.format("Alchemy scaling: Created the %s potion from a recipe (%s) with %d positive effects",
                mH.ordinal(recipeCount + 1), potionStats.key, potionStats.positiveEffects)
        if recipeCount == 100 then
            self:sendEvent(mDef.events.showMessage, L("alchemyScalingRecipeLimit"))
        end
    end

    logSkillScaling(message, params.scale, factor)
    params.scale = params.scale * factor
    notifySkillScaledGain(skillId, params.useType, factor)
end

module.onActorHit = function(state, actor)
    local stats = state.scaled.weapon
    if not stats then
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
    state.scaled.weapon = nil
end

module.onPlayerHit = function(state, attack)
    if attack.sourceType ~= "melee" and attack.sourceType ~= "ranged" then return end
    local time = core.getSimulationTime()
    if attack.attacker and attack.sourceType == "melee" then
        lastEnemyHitTimes[attack.attacker.id] = time
    end
    if not attack.successful or not attack.damage.health then return end
    local blockStats = state.scaled.block
    if blockStats and attack.damage.health == 0 then
        if time - blockStats.time > 0.25 then
            state.damage.scaled.block = nil
            log(string.format("Block scaling: No skill use, no scaling"))
        else
            blockStats.attacker = attack.attacker
        end
    end
    local armorStats = state.scaled.armor
    if attack.damage.health == 0 then
        state.scaled.armor = nil
        log(string.format("Armor skills scaling: No damage, no scaling"))
        return
    end
    if not armorStats then
        log(string.format("Armor skills scaling: No skill use, no scaling"))
        return
    end
    local params = armorStats.handlerParams
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
        skillId = armorStats.skillId,
        params = params,
        afterHandler = "scaled",
    })
    notifySkillScaledGain(armorStats.skillId, params.useType, factor)
    state.scaled.armor = nil
end

local getHitHealthRatio = function(actor, animGroup, animKey)
    local damage, hitChance = mCombat.getPotentialHitInfo(self, actor, animGroup, animKey, mCore.werewolfClawMult)
    local attack = { damage = { health = damage, fatigue = 0, magicka = 0 }, sourceType = "melee", strength = 1, successful = 1 }
    I.Combat.adjustDamageForDifficulty(attack)
    local armorDamage = I.Combat.adjustDamageForArmor(attack.damage.health, self)
    local healthRatio = armorDamage / mCore.self.health.base
    return healthRatio, hitChance, string.format("\"%s\" hit, damage (base %.1f, difficulty %.1f, armor %.1f), hit chance %.2f, health ratio = %.2f",
            actor.recordId, damage, attack.damage.health, armorDamage, hitChance, healthRatio)
end

module.onActorAnimHit = function(state, actor, animGroup, animKey)
    local lastHitTime = lastEnemyHitTimes[actor.id]
    local acroStats = state.scaled.acrobatics.stats
    local hasDodged = acroStats and (not lastHitTime or core.getSimulationTime() - lastHitTime > 0.25)
    local blockStats = state.scaled.block
    local hasBlocked = blockStats and blockStats.attacker.id == actor.id
    if not hasDodged and not hasBlocked then return end
    local healthRatio, hitChance, message = getHitHealthRatio(actor, animGroup, animKey)
    if hasDodged then
        log(string.format("Acrobatics scaling: Dodged %s", message))
        local factor = healthRatio * hitChance
        table.insert(acroStats.dodges, factor)
    end
    if hasBlocked then
        message = string.format("Block scaling: Blocked %s", message)
        local factor = capSkillScaledFactor(
                4 * healthRatio,
                mS.getSkillUsesScaledRange("blockSkillScalingRange"))
        local params = blockStats.handlerParams
        logSkillScaling(message, params.scale, factor)
        params.scale = params.scale * factor
        self:sendEvent(mDef.events.applySkillUsedHandlers, {
            skillId = Skills.block.id,
            params = params,
            afterHandler = "scaled",
        })
        notifySkillScaledGain(Skills.block.id, params.useType, factor)
        state.scaled.block = nil
    end
    -- only consider the first hit when enemies produce multiple animation hits per hit
    lastEnemyHitTimes[actor.id] = core.getSimulationTime()
end

module.uiModeChanged = function(data)
    if data.newMode == "Alchemy" and mS.skillUsesScaledStorage:get("alchemySkillScalingEnabled") then
        ownedIngredients = {}
    else
        ownedIngredients = nil
    end
end

module.onUpdate = function(state, deltaTime)
    local acrobaticsEnabled = mS.skillUsesScaledStorage:get("acrobaticsSkillScalingEnabled")
    local athleticsEnabled = mS.skillUsesScaledStorage:get("athleticsSkillScalingEnabled")

    local wasOnGround
    if acrobaticsEnabled or athleticsEnabled then
        wasOnGround = state.scaled.isOnGround
        state.scaled.isOnGround = T.Actor.isOnGround(self)
        state.scaled.groundDist = mH.groundDist(self.position, state.scaled.pos)
    end

    if acrobaticsEnabled then
        local isSlowFalling = mCore.self.activeEffects:getEffect(core.magic.EFFECT_TYPE.SlowFall).magnitude > 0
        local isLevitating = mCore.self.activeEffects:getEffect(core.magic.EFFECT_TYPE.Levitate).magnitude > 0
        if state.scaled.isOnGround or isSlowFalling or isLevitating or self.position.z > state.scaled.acrobatics.maxFallPos.z then
            state.scaled.acrobatics.maxFallPos = self.position
        end
        local stats = state.scaled.acrobatics.stats
        if stats then
            if isLevitating then
                local minFactor = mS.getSkillUsesScaledRange("acrobaticsSkillScalingRange").min
                log(string.format("Used levitate during a jump, scaling %.3f", minFactor))
                onJumpFinished(state, stats, minFactor)
            else
                if wasOnGround and not state.scaled.isOnGround then
                    stats.hasJumpStarted = true
                end
                handleJumps(state, isSlowFalling, deltaTime)
            end
        end
    end

    if athleticsEnabled then
        handleAthletics(state, deltaTime)
    end

    state.scaled.pos = self.position
end

module.onFrame = function()
    if ownedIngredients then
        checkIngredients()
    end
end

return module