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
local merchantUiModes = { Barter = true, Enchanting = true, MerchantRepair = true }
local currentUiMode
local merchant
local playerGold
local playerGoldChanges = {}
local ownedIngredients
local removedIngredients = {}
local ownedPotions
local addedPotions = {}
local lastEnemyHitTimes = {}

local module = {}

local function capFactor(ratio)
    return util.clamp(ratio, 0, 1)
end

local function capSkillScaledFactor(factor, rangeKey)
    local range = mS.getSkillUsesScaledRange(rangeKey)
    return math.min(range.max, math.max(range.min, factor))
end

module.formatFeatProps = function(feat)
    local props = feat.props
    if mCore.magickaSkills[feat.skillId] then
        if props.magickaRatio then
            return L("featSpell", props)
        else
            return L("featSpellOld", props)
        end
    elseif feat.skillId == Skills.security.id then
        if feat.useType == I.SkillProgression.SKILL_USE_TYPES.Security_PickLock then
            return L("featUnlock", props)
        else
            return L("featDisarm", props)
        end
    elseif feat.skillId == Skills.athletics.id then
        return L("featRun", props)
    elseif feat.skillId == Skills.alchemy.id then
        return L("featPotion", {
            count = props.count,
            positiveEffects = props.positiveEffects,
            ingredients = #props.ingredientIds,
        })
    elseif mCore.weaponSkills[feat.skillId] then
        return L("featWeapon", props)
    elseif mCore.armorSkills[feat.skillId] then
        return L("featArmor", props)
    elseif feat.skillId == Skills.block.id then
        if props.damageHealth then
            return L("featBlockHealth", {
                enemyName = props.enemyName,
                enemyLevel = props.enemyLevel,
                hitChance = props.hitChance,
                damage = props.damage,
                damageRatio = props.damageRatio,
            })
        else
            return L("featBlockFatigue", {
                enemyName = props.enemyName,
                enemyLevel = props.enemyLevel,
                hitChance = props.hitChance,
                damage = props.damage,
                damageRatio = props.damageRatio,
            })
        end
    elseif feat.skillId == Skills.acrobatics.id then
        if feat.useType == I.SkillProgression.SKILL_USE_TYPES.Acrobatics_Fall then
            return L("featFall", {
                height = util.round(props.height / mCore.unitsPerFoot),
                damage = props.damage,
                healthRatio = props.healthRatio,
            })
        else
            if props.hasLevitated then
                return L("featJumpLevitate")
            end
            local msg = { L("featJumpDepth", { depthFactor = props.depthFactor }) }
            if props.overLava then
                table.insert(msg, L("featJumpLava"))
            end
            table.insert(msg, L("featJumpLanded", { landingFactor = props.landingFactor }))
            if props.dodgedHits ~= 0 then
                table.insert(msg, L("featJumpDodges", { dodgedHits = props.dodgedHits }))
            end
            return table.concat(msg, ", ")
        end
    elseif feat.skillId == Skills.mercantile.id then
        if props.goldDiff < 0 then
            return L("featMercantileBuy", { merchantName = props.merchantName, gold = -props.goldDiff })
        else
            return L("featMercantileSell", { merchantName = props.merchantName, gold = props.goldDiff })
        end
    end
end

local function getFeatId(feat)
    local props = feat.props
    if mCore.magickaSkills[feat.skillId] then
        return props.spellId
    elseif feat.skillId == Skills.security.id then
        if feat.useType == I.SkillProgression.SKILL_USE_TYPES.Security_PickLock then
            return props.objectId
        else
            return string.format("%s_%s", props.spellId, props.objectId)
        end
    elseif feat.skillId == Skills.alchemy.id then
        return table.concat(props.ingredientIds, "_")
    elseif mCore.weaponSkills[feat.skillId] then
        return props.enemyId
    elseif mCore.armorSkills[feat.skillId] then
        return props.enemyId
    elseif feat.skillId == Skills.block.id then
        return props.enemyId
    elseif feat.skillId == Skills.mercantile.id then
        return props.merchantId
    end
end

local function newFeats()
    return {
        factorMax = 0,
        averages = {
            allTime = mH.newAvg(),
            prevLevel = mH.newAvg(),
            currLevel = mH.newAvg(),
        },
        lists = {
            best = {},
            level = {},
            last = {},
        },
    }
end

local function newFeat(factor, skillId, useType, props)
    return {
        factor = 100 * factor,
        skillId = skillId,
        useType = useType,
        props = props,
        skillLvl = T.NPC.stats.skills[skillId](self).base,
        playerLvl = mCore.self.level.current,
        cellName = self.cell.name,
        regionName = self.cell.region,
    }
end

local function addFeat(state, skillId, feat)
    state.skills.feats[skillId][feat.useType] = state.skills.feats[skillId][feat.useType] or newFeats()
    state.skills.feats[skillId][feat.useType].factorMax = feat.factorMax
    for key, avg in pairs(state.skills.feats[skillId][feat.useType].averages) do
        if key ~= "prevLevel" then
            mH.addToAvg(avg, feat.factor)
        end
    end
    local lists = state.skills.feats[skillId][feat.useType].lists
    mH.addToSortedTable(feat, function(f) return f.factor end, getFeatId, lists.best, mCfg.maxFeatStats)
    mH.addToSortedTable(feat, function(f) return f.factor end, getFeatId, lists.level, mCfg.maxFeatStats)
    table.insert(lists.last, 1, feat)
    if #lists.last > mCfg.maxFeatStats then
        table.remove(lists.last, mCfg.maxFeatStats + 1)
    end
end

local function setScaling(state, skillId, factor, params, featProps, message)
    log(string.format("%s, scale = %.5f x scaling %.5f = %.5f", message, params.scale, factor, params.scale * factor))
    params.scale = params.scale * factor
    addFeat(state, skillId, newFeat(factor, skillId, params.useType, featProps))
    if mS.skillUsesScaledStorage:get("skillScalingDebugNotifsEnabled") then
        mNotifs.notify(string.format("Scaled %s\n%s: %.1f%%",
                Skills[skillId].name, mCfg.skillUseTypes[skillId][params.useType].key, factor * 100))
    end
end

local function setDelayedScaling(state, skillId, factor, params, featProps, message)
    setScaling(state, skillId, factor, params, featProps, message)
    self:sendEvent(mDef.events.applySkillUsedHandlers, {
        skillId = skillId,
        params = params,
        afterHandler = "scaled",
    })
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
                return { lockLevel = lockLevel, object = lockable }
            end
        end
    elseif weapon.type == T.Probe then
        local lockable = getFacedObject()
        if lockable then
            local trapSpell = T.Lockable.getTrapSpell(lockable)
            if trapSpell then
                return { trapSpell = trapSpell, object = lockable }
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

local function onJumpFinished(state, stats, factor, featProps)
    local params = stats.handlerParams
    setDelayedScaling(state, Skills.acrobatics.id, factor, params, featProps, "Acrobatics scaling: Jumped")
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
        local object = result.hitObject
        if object and (lavaIdCache[object.recordId] or object.type.record(object).mwscript == "lava") then
            lavaIdCache[object.recordId] = true
            lava = true
        end
        if self.cell.hasWater and self.cell.waterLevel >= result.hitPos.z then
            local resultNoWater = nearby.castRay(pos, to, {
                collisionType = nearby.COLLISION_TYPE.HeightMap + nearby.COLLISION_TYPE.World + nearby.COLLISION_TYPE.Door,
                radius = mCore.self.halfExtents.y / 2,
            })
            if not resultNoWater.hitPos
                    or result.hitPos.z - resultNoWater.hitPos.z > mCore.GMSTs.fSwimHeightScale * 2 * mCore.self.halfExtents.z then
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

local function getLandingStillFactor()
    local rotation = util.transform.identity
    local from = self:getBoundingBox().center + util.vector3(0, 0, mCore.self.halfExtents.z / 4)
    -- check risk in 8 directions, and for each direction, check the risk along 10 steps
    local slices = 8
    local steps = 10
    local risk = mH.newAvg()
    risk.count = slices
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
            if trace then table.insert(logStats, string.format(
                    "risk %.2f, slope %.2f, stepF %.2f, slopeF %.2f, bonus %.2f, factor %.2f",
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
        risk.sum = risk.sum + maxRisk
        if trace then table.insert(logStats, string.format("factor %.2f", maxRisk)) end
    end
    if trace then log(string.format("Jump landing surroundings risk:%s\n", table.concat(logStats, ", "))) end
    return mH.avg(risk)
end

local function onJumpLanded(state)
    local pos = self.position
    local stats = state.scaled.acrobatics.stats
    local avgSpeed = mH.avg(stats.speed)
    local maxSpeed = stats.max.midairVelocity
    local height = math.max(0, stats.maxHeightPos.z - stats.startPos.z)
    local landingHeight = pos.z - stats.startPos.z
    local avgDepth = mH.avg(stats.depth)
    local depth = (2 * stats.depth.max + avgDepth) / 3
    local lavaBonus = mCfg.jumpGainLavaMaxBonus * stats.lava.present / math.max(1, stats.lava.present + stats.lava.absent)
    local riskDamage = getFallLostHealth(depth)
    local expectedDamage = getFallLostHealth(state.scaled.acrobatics.maxFallPos.z - pos.z)
    local depthFactor = capFactor(getHealthRisk(math.max(0, riskDamage - expectedDamage)) + lavaBonus)
    local lastTimeFactor = capFactor(stats.timeSinceLastJump / state.scaled.acrobatics.lastJumpMaxDuration) ^ 4
    local speedFactor = capFactor(avgSpeed / maxSpeed)
    local heightFactor = capFactor(height / stats.max.height)
    local landingHeightFactor = capFactor(landingHeight / stats.max.height)
    local landingStillFactor = capFactor(getLandingStillFactor())
    local landingFactor = landingStillFactor * math.max(landingHeightFactor, speedFactor) ^ 0.5
    local dodgeFactor = mH.sum(stats.dodges)
    local factor = capSkillScaledFactor(math.max(
            lastTimeFactor *
                    math.max(
                            mCfg.jumpGainMaxMovementFactor * math.max(speedFactor, heightFactor),
                            mCfg.jumpGainBottomFactor * speedFactor * depthFactor + mCfg.jumpGainLandingRiskFactor * landingFactor
                    ),
            mCfg.jumpDodgeFactor * dodgeFactor
    ), "acrobaticsSkillScaling")

    log(string.format("Jumped:\n\tStats: since time %.2f/%.2f, landing risk still %.2f, depth max %.1f avg %.1f, lava %.3f, damage risk %d expected %d, speed %.1f/%.1f, height %.1f/%.1f, landed at %.1f"
            .. "\n\tFactors: cap(max("
            .. "\n\t    last time %.3f x max("
            .. "\n\t        %s x max(speed %.3f, height %.3f),"
            .. "\n\t        %s x speed %.3f x depth %.3f + %s x landing risk %.3f"
            .. "\n\t    ),"
            .. "\n\t    %s x dodge %.3f"
            .. "\n\t)) = final %.5f",
    -- Stats
            stats.timeSinceLastJump, stats.max.duration,
            landingStillFactor,
            stats.depth.max, avgDepth, lavaBonus,
            riskDamage, expectedDamage,
            avgSpeed, maxSpeed,
            height, stats.max.height,
            landingHeight,
    -- Factors
            lastTimeFactor,
            mCfg.jumpGainMaxMovementFactor, speedFactor, heightFactor,
            mCfg.jumpGainBottomFactor, speedFactor, depthFactor,
            mCfg.jumpGainLandingRiskFactor, landingFactor,
            mCfg.jumpDodgeFactor, dodgeFactor,
            factor))

    local featProps = {
        depthFactor = util.round(100 * depthFactor),
        landingFactor = util.round(100 * landingFactor),
        dodgedHits = #stats.dodges,
        overLava = lavaBonus ~= 0
    }
    onJumpFinished(state, stats, factor, featProps)
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
    mH.addToAvg(stats.depth, finalDepth)

    mH.addToAvg(stats.speed, state.scaled.groundDist / deltaTime)

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
                removed[ingredient.recordId] = { object = ingredient, count = diff }
            end
            ownedIngredients[ingredient.recordId] = nil
        end
        ingredients[ingredient.recordId] = { object = ingredient, count = ingredient.count }
    end
    for _, ingredient in pairs(ownedIngredients) do
        removed[ingredient.object.recordId] = ingredient
    end
    ownedIngredients = ingredients
    if next(removed) then
        removedIngredients = removed
    end
end

local function checkPotions()
    local potions = {}
    addedPotions = {}
    for _, potion in ipairs(mCore.self.inventory:getAll(T.Potion)) do
        if ownedPotions[potion.recordId] then
            local diff = potion.count - ownedPotions[potion.recordId].count
            if diff > 0 then
                addedPotions[potion.recordId] = { object = potion, count = diff }
            end
        else
            addedPotions[potion.recordId] = { object = potion, count = potion.count }
        end
        potions[potion.recordId] = { object = potion, count = potion.count }
    end
    ownedPotions = potions
end

local function getLastRecipeStats()
    local ingredients = {}
    local ingredientIds = {}
    local value = 0
    for id, ingredient in pairs(removedIngredients) do
        ingredient.count = ingredient.count - 1
        if ingredient.count == 0 then
            removedIngredients[id] = nil
        end
        local effects = {}
        local record = ingredient.object.type.record(ingredient.object)
        for _, effect in ipairs(record.effects) do
            effects[effect.id] = { harmful = effect.effect.harmful, affectedAttribute = effect.affectedAttribute, affectedSkill = effect.affectedSkill }
        end
        table.insert(ingredients, { id = id, effects = effects })
        table.insert(ingredientIds, record.id)
        value = value + record.value
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
            for effectId, effect1 in pairs(ingredient1.effects) do
                local effect2 = ingredient2.effects[effectId]
                if effect2 and effect1.affectedAttribute == effect2.affectedAttribute and effect1.affectedSkill == effect2.affectedSkill then
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
    local effectCount = 0
    local positiveEffects = 0
    for _, effect in pairs(activeEffects) do
        effectCount = effectCount + 1
        if not effect.harmful then
            positiveEffects = positiveEffects + 1
        end
    end
    local validIds = {}
    for id in pairs(effectiveIngredientIds) do
        table.insert(validIds, id)
    end
    table.sort(validIds)
    table.sort(ingredientIds)
    return {
        key = table.concat(validIds, ":"),
        effectCount = effectCount,
        positiveEffects = positiveEffects,
        ingredientIds = ingredientIds,
        value = math.max(1, value),
    }
end

local function setPotionPrice(potionData, record, ingredientValue, positiveEffectsRatio)
    if mCore.GMSTs.iAlchemyMod == 0 then return end
    local valueMod = mS.potionsStorage:get("potionValueMod")
    if valueMod == 0 then return end

    local newRecord = {}
    for _, key in pairs({ "effects", "mwscript", "name", "weight" }) do
        newRecord[key] = record[key]
    end
    local value = valueMod * record.value / mCore.GMSTs.iAlchemyMod
    local ingredientValuePercent = mS.potionsStorage:get("potionMaxIngredientValuePercent")
    if ingredientValuePercent > 0 then
        value = math.min(value, ingredientValue * ingredientValuePercent / 100)
    end
    local positiveEffectsImpact = mS.potionsStorage:get("potionPositiveEffectsBasedPrice")
    if positiveEffectsImpact then
        value = value * positiveEffectsRatio
    end
    newRecord.value = util.round(value)

    local samePotion = mCore.findSamePotion(newRecord)
    if samePotion then
        log(string.format("Found same potion %s", mCore.objectId(samePotion)))
        core.sendGlobalEvent(mDef.events.addObject, {
            player = self,
            recordId = samePotion.recordId,
            count = potionData.count,
        })
    else
        log(string.format("No potion same as %s", mH.mapToString(newRecord)))
        core.sendGlobalEvent(mDef.events.addNewPotion, {
            player = self,
            basePotion = potionData.object,
            recordPatch = { value = newRecord.value },
            count = potionData.count,
        })
    end
    log(string.format("Potion Price: potion %s \"%s\", count %d, value %d, mod %.2f, ingredient value %d percent %d%%, positive effects %s ratio %.2f, final value %d",
            record.id, record.name, potionData.count, record.value, valueMod, ingredientValue, ingredientValuePercent, positiveEffectsImpact, positiveEffectsRatio, value))
    core.sendGlobalEvent(mDef.events.removeObject, { object = potionData.object, count = potionData.count })
end

local function getTimePassed(setting, skill)
    return math.max(0, setting[2] + (setting[1] - setting[2]) * (1 - skill / 100))
end

local function addPotionTime(potionData, record, recipeCount)
    local minutesCfg = mS.timeStorage:get("minutesPerPotionCreation")
    if not minutesCfg[3] then return end

    local skill = math.min(100, T.NPC.stats.skills.alchemy(self).modified)
    local timeReduction = mS.timeStorage:get("potionMaxRecipeCountBasedTimeReduction")
    local minutes = 0
    for _ = 1, potionData.count do
        recipeCount = recipeCount + 1
        minutes = minutes
                + (100 - recipeCount + (recipeCount * timeReduction) / 100) / 100
                * getTimePassed(minutesCfg, skill)
    end

    log(string.format("Potion Time: potion %s \"%s\", count %d, recipe count %d, duration %.1f minutes",
            record.id, record.name, potionData.count, recipeCount, minutes))
    core.sendGlobalEvent(mDef.events.skipGameHours, { player = self, hours = minutes / 60 })
end

local function addRepairTime()
    local minutesCfg = mS.timeStorage:get("minutesPerSelfRepair")
    if not minutesCfg[3] then return end

    local skill = T.NPC.stats.skills.armorer(self).modified
    local minutes = getTimePassed(minutesCfg, skill)
    log(string.format("Self Repair Time: Armorer level %d, duration %.1f minutes", skill, minutes))
    core.sendGlobalEvent(mDef.events.skipGameHours, { player = self, hours = minutes / 60 })
end

local function addEnchantTime()
    local minutesCfg = mS.timeStorage:get("minutesPerSelfEnchanting")
    if not minutesCfg[3] then return end

    local skill = T.NPC.stats.skills.enchant(self).modified
    local minutes = getTimePassed(minutesCfg, skill)
    log(string.format("Self Enchanting Time: Enchant level %d, duration %.1f minutes", skill, minutes))
    core.sendGlobalEvent(mDef.events.skipGameHours, { player = self, hours = minutes / 60 })
end

local function checkGoldDiff()
    if not playerGold or not playerGold:isValid() then
        playerGold = mCore.getPlayerGold()
    end
    local playerGoldCount = playerGold and playerGold.count or 0
    if #playerGoldChanges == 0 then
        playerGoldChanges[1] = playerGoldCount
        return
    end

    local goldDiff = playerGoldCount - playerGoldChanges[1]
    if goldDiff == 0 then return end

    log(string.format("Player gold changed from %d to %d", playerGoldCount, playerGoldChanges[1]))
    table.insert(playerGoldChanges, 1, playerGoldCount)

    if goldDiff < 0 then
        if currentUiMode == "MerchantRepair" then
            local minutes = mS.timeStorage:get("minutesPerNPCRepair")
            if minutes > 0 then
                log(string.format("NPC Repair Time: duration %.1f minutes", minutes))
                core.sendGlobalEvent(mDef.events.skipGameHours, { player = self, hours = minutes / 60 })
            end
        elseif currentUiMode == "Enchanting" then
            local minutes = mS.timeStorage:get("minutesPerNPCEnchanting")
            if minutes > 0 then
                log(string.format("NPC Enchanting Time: duration %.1f minutes", minutes))
                core.sendGlobalEvent(mDef.events.skipGameHours, { player = self, hours = minutes / 60 })
            end
        end
    end
end

module.skillUsedHandler = function(state, skillId, params)
    local factor = 1
    local featProps = {}
    local logMessage = ""
    if mCore.magickaSkills[skillId] then
        if not mS.isSkillScalingEnabled("magickaBasedSkillScaling") then return end
        if not mCore.hasJustSpellCasted() then
            log("Magicka skills scaling: No spell cast detected, no scaling")
            return
        end
        local spell = T.Actor.getSelectedSpell(self)
        local chance = math.max(0, mCore.GMSTs.fFatigueBase * mSpells.calcAutoCastChance(spell, self) / 100)
        local chanceFactor = chance < 1 and (3 - 2 * chance) or (1 - (chance - 1) ^ 4)
        local magickaRatio = mCore.self.magicka.base <= 0 and 0 or spell.cost / mCore.self.magicka.base
        local magickaRatioFactor = magickaRatio <= 0.05 and (1 - (10 * magickaRatio - 1) ^ 2) or 1
        factor = capSkillScaledFactor(magickaRatioFactor * chanceFactor, "magickaBasedSkillScaling")
        featProps = { spellId = spell.id, spellName = spell.name, chance = math.floor(100 * chance), magickaRatio = util.round(100 * magickaRatio) }
        logMessage = string.format("Magicka skills scaling: Cast the spell \"%s\" cost %d, chance = %.2f, magicka ratio = %.3f, ratio factor = %.3f",
                spell.name, spell.cost, chance, magickaRatio, magickaRatioFactor)
    elseif mCore.weaponSkills[skillId] then
        if not mS.isSkillScalingEnabled("weaponSkillScaling") then return end
        state.scaled.weapon = {
            handlerParams = { skillGain = params.skillGain, scale = params.scale, useType = params.useType },
            skillId = skillId,
        }
        -- will be handled on hit
        params.skillGain = 0
        return
    elseif mCore.armorSkills[skillId] then
        if not mS.isSkillScalingEnabled("armorSkillScaling") then return end
        state.scaled.armor = {
            handlerParams = { skillGain = params.skillGain, scale = params.scale, useType = params.useType },
            skillId = skillId,
        }
        -- will be handle on hit
        params.skillGain = 0
        return
    elseif skillId == Skills.block.id then
        if not mS.isSkillScalingEnabled("blockSkillScaling") then return end
        state.scaled.block = {
            handlerParams = { skillGain = params.skillGain, scale = params.scale, useType = params.useType },
            time = core.getSimulationTime(),
            attacker = nil,
        }
        -- will be handle on hit
        params.skillGain = 0
        return
    elseif skillId == Skills.security.id then
        if not mS.isSkillScalingEnabled("securitySkillScaling") then return end
        if not mCore.isLockPicking() then
            log("Security scaling: No lock or disarm attempt detected, no scaling")
            return
        end
        if not lockableStats then
            log("Security scaling: No lockable found, no scaling")
            return
        end
        featProps = {
            objectId = lockableStats.object.recordId,
            objectName = lockableStats.object.type.record(lockableStats.object).name,
        }
        local chance
        if lockableStats.lockLevel then
            chance = mCore.agilityTerm(self, skillId)
                    * mCore.GMSTs.fFatigueBase
                    + lockableStats.lockLevel * mCore.GMSTs.fPickLockMult
            factor = capSkillScaledFactor(2 * (math.max(0, 1 - chance / 100)), "securitySkillScaling")
            logMessage = string.format("Security scaling: Unlocked a lock level %d, chance = %.2f",
                    lockableStats.lockLevel, chance)
        elseif lockableStats.trapSpell then
            chance = mCore.agilityTerm(self, skillId)
                    * mCore.GMSTs.fFatigueBase
                    + lockableStats.trapSpell.cost * mCore.GMSTs.fTrapCostMult
            factor = capSkillScaledFactor(2 * (math.max(0, 1 - chance / 100)), "securitySkillScaling")
            featProps.spellName = lockableStats.trapSpell.name
            featProps.spellId = lockableStats.trapSpell.id
            logMessage = string.format("Security scaling: Disarmed a trap with spell cost %d, chance = %.2f",
                    lockableStats.trapSpell.cost, chance)
        end
        featProps.chance = math.floor(chance)
    elseif skillId == Skills.acrobatics.id then
        if not mS.isSkillScalingEnabled("acrobaticsSkillScaling") then return end
        if params.useType == I.SkillProgression.SKILL_USE_TYPES.Acrobatics_Fall then
            local height = state.scaled.acrobatics.maxFallPos.z - self.position.z
            if height < 1 then
                log("Acrobatics fall scaling: No fall detected, no scaling")
                return
            end
            local damage = getFallLostHealth(height, true)
            -- limited to 200% (before death)
            local healthRatio = 2 * capFactor(damage / mCore.self.health.base)
            factor = capSkillScaledFactor(healthRatio, "acrobaticsSkillScaling")
            featProps = { height = height, damage = util.round(damage), healthRatio = util.round(100 * healthRatio) }
            logMessage = string.format(
                    "Acrobatics fall scaling: Took damage from a fall, height = %.1f, damage = %.1f, health ratio = %.2f",
                    height, damage, healthRatio)
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
                depth = mH.newAvg({ max = 0 }),
                speed = mH.newAvg(),
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
        if not mS.isSkillScalingEnabled("athleticsSkillScaling") then return end
        local stats = state.scaled.athletics
        if stats.runningDuration == 0 then
            log("Athletics scaling: Ran for 0 seconds, no scaling")
            return
        end
        local timeRatio = capFactor(stats.runningDuration / mCfg.athleticsGainMaxTime) ^ mCfg.athleticsGainCurvePower
        local maxSpeed = T.Actor.getRunSpeed(self)
        if T.Actor.isSwimming(self) then
            maxSpeed = maxSpeed * getSwimSpeedFactor()
        end
        local velocityRatio = stats.deltaTime > 0
                and math.min(1, capFactor(stats.deltaPos / (stats.deltaTime * maxSpeed)))
                or 1
        local capacity = T.Actor.getCapacity(self)
        local encumbranceRatio = capFactor((capacity == 0 and 1 or T.Actor.getEncumbrance(self) / capacity))
        factor = capSkillScaledFactor(0.5 * encumbranceRatio + 1.5 * timeRatio * velocityRatio, "athleticsSkillScaling")
        featProps = {
            duration = util.round(10 * stats.runningDuration) / 10,
            speed = util.round(100 * velocityRatio),
            encumbrance = util.round(100 * encumbranceRatio),
        }
        logMessage = string.format(
                "Athletics scaling: Run duration %.2f, time ratio %.2f, velocity %.2f, encumbrance ratio %.1f",
                stats.runningDuration, timeRatio, velocityRatio, encumbranceRatio)
        stats.deltaTime = 0
        stats.deltaPos = 0
    elseif skillId == Skills.alchemy.id then
        if params.useType ~= I.SkillProgression.SKILL_USE_TYPES.Alchemy_CreatePotion then
            return
        end

        local recipeStats = getLastRecipeStats()
        if not recipeStats then
            log("Alchemy scaling: No consumed ingredients, no scaling, no potion creation features")
            return
        end
        local recipeCount = state.scaled.alchemy.recipeCounts[recipeStats.key] or 0
        if ownedPotions then
            for _, potionData in pairs(addedPotions) do
                local record = potionData.object.type.record(potionData.object)
                setPotionPrice(potionData, record, recipeStats.value, recipeStats.positiveEffects / recipeStats.effectCount)
                addPotionTime(potionData, record, recipeCount)
            end
            addedPotions = {}
        end

        if not ownedIngredients then return end

        state.scaled.alchemy.recipeCounts[recipeStats.key] = recipeCount + 1
        factor = capSkillScaledFactor((0.5 + recipeStats.positiveEffects / 2) * (1 - math.min(recipeCount, 100) / 100) ^ 2,
                "alchemySkillScaling")
        featProps = { count = recipeCount + 1, positiveEffects = recipeStats.positiveEffects, ingredientIds = recipeStats.ingredientIds }
        logMessage = string.format("Alchemy scaling: Created the %s potion from a recipe (%s) with %d positive effects",
                mH.ordinal(recipeCount + 1), recipeStats.key, recipeStats.positiveEffects)
        if recipeCount == 100 then
            self:sendEvent(mDef.events.showMessage, L("alchemyScalingRecipeLimit"))
        end
    elseif skillId == Skills.mercantile.id then
        factor = params.scale
        params.scale = 1
        local record = merchant.type.record(merchant)
        local goldDiff = playerGoldChanges[1] - playerGoldChanges[2]
        featProps = { merchantId = merchant.recordId, merchantName = record.name, goldDiff = goldDiff }
        logMessage = string.format("Mercantile scaling: Spent %d gold with \"%s\"", goldDiff, record.name)
    elseif skillId == Skills.armorer.id then
        addRepairTime()
        return
    elseif skillId == Skills.enchant.id then
        if params.useType == I.SkillProgression.SKILL_USE_TYPES.Enchant_CreateMagicItem then
            addEnchantTime()
        end
        return
    else
        return
    end

    setScaling(state, skillId, factor, params, featProps, logMessage)
end

module.onActorHit = function(state, enemy)
    local stats = state.scaled.weapon
    if not stats then
        log(string.format("Weapon skills scaling: No skill use, no scaling"))
        return
    end
    local params = stats.handlerParams
    local attackTerm = mCore.agilityTerm(self, stats.skillId) * mCore.GMSTs.fFatigueBase
    local defenseTerm = mCore.agilityTerm(enemy) * mCore.GMSTs.fFatigueBase
    local chance = math.floor(0.5 + attackTerm - defenseTerm) / 100
    local factor = capSkillScaledFactor(6 / math.max(0.01, 1.5 + chance) - 2, "weaponSkillScaling")
    local featProps = {
        enemyId = enemy.recordId,
        chance = math.floor(100 * chance),
        enemyName = enemy.type.record(enemy).name,
        enemyLevel = T.Actor.stats.level(enemy).current,
    }
    local message = string.format("Weapon skills scaling: Hit the enemy \"%s\" (attack %.2f, defense %.2f), chance = %.2f",
            enemy.recordId, attackTerm, defenseTerm, chance)
    setDelayedScaling(state, stats.skillId, factor, params, featProps, message)
    state.scaled.weapon = nil
end

module.onPlayerHit = function(state, attack)
    if attack.sourceType ~= "melee" and attack.sourceType ~= "ranged" then return end
    local time = core.getSimulationTime()
    local enemy = attack.attacker
    if enemy and attack.sourceType == "melee" then
        lastEnemyHitTimes[attack.attacker.id] = time
    end

    if not attack.successful or not attack.damage then return end
    local healthDamage = attack.damage.health or 0
    local fatigueDamage = attack.damage.fatigue or 0

    if healthDamage == 0 and fatigueDamage == 0 then
        local blockStats = state.scaled.block
        if blockStats then
            if time - blockStats.time > 0.25 then
                state.scaled.block = nil
                log(string.format("Block scaling: No skill use, no scaling"))
            else
                blockStats.attacker = enemy
            end
        end
        state.scaled.armor = nil
        log(string.format("Armor/weapon skills scaling: No damage, no scaling"))
        return
    end
    local armorStats = state.scaled.armor
    if not armorStats or healthDamage == 0 then
        log(string.format("Armor skills scaling: No skill use, no scaling"))
        return
    end
    local params = armorStats.handlerParams
    local baseDamage = attack.damage.health
    I.Combat.adjustDamageForDifficulty(attack)
    local damage = attack.damage.health
    -- restore original damage
    attack.damage.health = baseDamage
    local damageRatio = damage / mCore.self.health.base
    local factor = capSkillScaledFactor(4 * damageRatio, "armorSkillScaling")
    local featProps = {
        damage = util.round(damage),
        damageRatio = util.round(100 * damageRatio),
        enemyId = enemy.recordId,
        enemyName = enemy.type.record(enemy).name,
        enemyLevel = T.Actor.stats.level(enemy).current,
    }
    local message = string.format("Armor skills scaling: Hit by an enemy, raw damage = %.1f, health ratio = %.2f", damage, damageRatio)
    setDelayedScaling(state, armorStats.skillId, factor, params, featProps, message)
    state.scaled.armor = nil
end

local function getHitDamageStats(actor, animGroup, animKey)
    local damage, damageHealth, hitChance = mCombat.getPotentialHitInfo(self, actor, animGroup, animKey, mCore.werewolfClawMult)
    local damageRatio
    if damageHealth then
        local attack = { damage = { health = damage, fatigue = 0, magicka = 0 }, sourceType = "melee", strength = 1, successful = 1 }
        I.Combat.adjustDamageForDifficulty(attack)
        damageRatio = attack.damage.health / mCore.self.health.base
        return attack.damage.health, damageHealth, damageRatio, hitChance, string.format(
                "%s hit, health damage (base %.1f, difficulty %.1f), hit chance %.2f, health ratio = %.2f",
                mCore.objectId(actor), damage, attack.damage.health, hitChance, damageRatio)
    else
        damageRatio = damage / mCore.self.fatigue.base
        return damage, damageHealth, damageRatio, hitChance, string.format(
                "%s hit, fatigue damage %.1f, hit chance %.2f, fatigue ratio = %.2f",
                mCore.objectId(actor), damage, hitChance, damageRatio)
    end
end

module.onActorAnimHit = function(state, enemy, animGroup, animKey)
    local lastHitTime = lastEnemyHitTimes[enemy.id]
    local acroStats = state.scaled.acrobatics.stats
    local hasDodged = acroStats and (not lastHitTime or core.getSimulationTime() - lastHitTime > 0.25)
    local blockStats = state.scaled.block
    local hasBlocked = blockStats and blockStats.attacker and blockStats.attacker.id == enemy.id
    if not hasDodged and not hasBlocked then return end
    local damage, damageHealth, damageRatio, hitChance, message = getHitDamageStats(enemy, animGroup, animKey)
    if hasDodged then
        log(string.format("Acrobatics scaling: Dodged %s", message))
        local factor = damageRatio * hitChance
        if not damageHealth then
            factor = factor * mCfg.scaledFatigueFactor
        end
        table.insert(acroStats.dodges, factor)
    end
    if hasBlocked then
        local blockFactor = damageRatio * mCfg.blockFactor
        if not damageHealth then
            blockFactor = blockFactor * mCfg.scaledFatigueFactor
        end
        local factor = capSkillScaledFactor(blockFactor, "blockSkillScaling")
        local params = blockStats.handlerParams
        local featProps = {
            enemyId = enemy.recordId,
            damage = util.round(damage),
            damageHealth = damageHealth,
            damageRatio = util.round(100 * damageRatio),
            hitChance = hitChance,
            enemyName = enemy.type.record(enemy).name,
            enemyLevel = T.Actor.stats.level(enemy).current,
        }
        message = string.format("Block scaling: Blocked %s", message)
        setDelayedScaling(state, Skills.block.id, factor, params, featProps, message)
        state.scaled.block = nil
    end
    -- only consider the first hit when enemies produce multiple animation hits per hit
    lastEnemyHitTimes[enemy.id] = core.getSimulationTime()
end

module.uiModeChanged = function(data)
    currentUiMode = data.newMode
    if data.newMode == "Alchemy" then
        if mS.isSkillScalingEnabled("alchemySkillScaling") then
            ownedIngredients = {}
        end
        ownedPotions = {}
    elseif merchantUiModes[data.newMode] then
        merchant = data.arg and data.arg.type == T.NPC and data.arg
    else
        ownedIngredients = nil
        ownedPotions = nil
        if not data.oldMode then
            merchant = nil
            playerGold = nil
            playerGoldChanges = {}
        end
    end
end

module.onUpdate = function(state, deltaTime)
    local acrobaticsEnabled = mS.isSkillScalingEnabled("acrobaticsSkillScaling")
    local athleticsEnabled = mS.isSkillScalingEnabled("athleticsSkillScaling")

    local wasOnGround
    if acrobaticsEnabled or athleticsEnabled then
        wasOnGround = state.scaled.isOnGround
        state.scaled.isOnGround = T.Actor.isOnGround(self)
        state.scaled.groundDist = mH.groundDist(self.position, state.scaled.pos)
    end

    if acrobaticsEnabled then
        local isSlowFalling = mCore.self.activeEffects:getEffect(core.magic.EFFECT_TYPE.SlowFall).magnitude > 0
        local isLevitating = mCore.self.activeEffects:getEffect(core.magic.EFFECT_TYPE.Levitate).magnitude > 0
        local stats = state.scaled.acrobatics.stats
        if (state.scaled.isOnGround and (not stats or not stats.hasJumpStarted)) or isSlowFalling or isLevitating or self.position.z > state.scaled.acrobatics.maxFallPos.z then
            state.scaled.acrobatics.maxFallPos = self.position
        end
        if stats then
            if isLevitating then
                local factorRange = mS.getSkillUsesScaledRange("acrobaticsSkillScaling")
                log(string.format("Used levitate during a jump, scaling %.3f", factorRange.min))
                onJumpFinished(state, stats, factorRange.min, { hasLevitated = true })
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
    if ownedPotions then
        checkPotions()
    end
    if merchant then
        checkGoldDiff()
    end
end

return module