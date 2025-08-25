local core = require('openmw.core')
local ambient = require('openmw.ambient')
local self = require('openmw.self')
local I = require('openmw.interfaces')
local T = require('openmw.types')
local input = require('openmw.input')
local async = require('openmw.async')
local camera = require('openmw.camera')
local util = require('openmw.util')
local nearby = require('openmw.nearby')

local log = require('scripts.NCGDMW.log')
local mDef = require('scripts.NCGDMW.definition')
local mCfg = require('scripts.NCGDMW.configuration')
local mS = require('scripts.NCGDMW.settings')
local mC = require('scripts.NCGDMW.common')
local mUi = require("scripts.NCGDMW.ui")
local mDecay = require('scripts.NCGDMW.decay')
local mSpells = require('scripts.NCGDMW.spells')
local mH = require('scripts.NCGDMW.helpers')

local Skills = core.stats.Skill.records
local L = core.l10n(mDef.MOD_NAME)

local magickaSkills = {
    [Skills.destruction.id] = true,
    [Skills.restoration.id] = true,
    [Skills.conjuration.id] = true,
    [Skills.mysticism.id] = true,
    [Skills.illusion.id] = true,
    [Skills.alteration.id] = true,
}

local weaponSkills = {
    [Skills.handtohand.id] = true,
    [Skills.axe.id] = true,
    [Skills.bluntweapon.id] = true,
    [Skills.longblade.id] = true,
    [Skills.marksman.id] = true,
    [Skills.shortblade.id] = true,
    [Skills.spear.id] = true,
}

local armorSkills = {
    [Skills.unarmored.id] = true,
    [Skills.lightarmor.id] = true,
    [Skills.mediumarmor.id] = true,
    [Skills.heavyarmor.id] = true,
}

local healthEffectIds = {
    [core.magic.EFFECT_TYPE.RestoreHealth] = true,
    [core.magic.EFFECT_TYPE.FortifyHealth] = true,
    [core.magic.EFFECT_TYPE.DrainHealth] = true,
    [core.magic.EFFECT_TYPE.DamageHealth] = true,
    [core.magic.EFFECT_TYPE.AbsorbHealth] = true,
    [core.magic.EFFECT_TYPE.FireDamage] = true,
    [core.magic.EFFECT_TYPE.FrostDamage] = true,
    [core.magic.EFFECT_TYPE.ShockDamage] = true,
    [core.magic.EFFECT_TYPE.Poison] = true,
    [core.magic.EFFECT_TYPE.SunDamage] = true,
}

local meleeAttackGroups = {
    handtohand = true,
    weapononehand = true,
    weapontwohand = true,
    weapontwowide = true,
}

local skillOrder = {}
for i, skill in ipairs(Skills) do
    skillOrder[skill.id] = i
end

local externalSkillUsedHandlers = {}
local lastAnimation
local spellSchoolRatios = {}
local modifiedTrainingSkills = {}
local weaponSpeeds = {}
local lockableStats
local gravityAcceleration = 69.99125109 * 8.96
local jumpVelocityFactor = 0.707
local maxSlope = math.rad(46.0);
local lavaIdCache = {}
local inventory = self.type.inventory(self)
local ownedIngredients
local removedIngredients = {}

local module = {}

I.AnimationController.addTextKeyHandler('', function(group, key)
    lastAnimation = { group = group, key = key }
end)

local function isMeleeAttacking()
    return lastAnimation and meleeAttackGroups[lastAnimation.group] and string.sub(lastAnimation.key, -3) == "hit"
end

local function isSpellCasting()
    return lastAnimation and lastAnimation.group == "spellcast" and string.sub(lastAnimation.key, -7) == "release"
end

local function isLockPicking()
    return lastAnimation and lastAnimation.group == "pickprobe" and lastAnimation.key == "start"
end

local function checkIngredients()
    local ingredients = {}
    local removed = {}
    removedIngredients = {}
    for _, ingredient in ipairs(inventory:getAll(T.Ingredient)) do
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

local onHealthModified = function(state, value)
    state.skills.scaled.health = state.skills.scaled.health + value
end
module.onHealthModified = onHealthModified

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

local function setSkillGrowths(state, skillId, skillValue, startValuesRatio, luckGrowthRate)
    state.skills.growth.level[skillId] = state.skills.misc[skillId] and 0 or skillValue - state.skills.start[skillId]

    local attrGrowth = skillValue - startValuesRatio * state.skills.start[skillId]
    local settingKey = state.skills.major[skillId] and "Major" or (state.skills.minor[skillId] and "Minor" or "Misc")
    state.skills.growth.attributes[skillId] = attrGrowth
            * mS.attributesStorage:get("growthFactorFrom" .. settingKey .. "Skills") / 100
            * (1 - luckGrowthRate / 4)
end
module.setSkillGrowths = setSkillGrowths

local function updateSkills(state, baseStatsMods, allAttrs)
    local attributesToUpdate = {}
    local decayEnabled = mS.skillsStorage:get("skillDecayRate") ~= "skillDecayNone"
    local skillsMaxValue = mS.skillsStorage:get("uncapperMaxValue")
    local perSkillMaxValues = mS.getPerSkillMaxValues()
    local startValuesRatio = mS.getAttributeStartValuesRatio(mS.attributesStorage:get("startValuesRatio"))
    local luckGrowthRate = mS.getLuckGrowthRate(mS.attributesStorage:get("luckGrowthRate"))

    for skillId, getter in pairs(T.NPC.stats.skills) do
        local maxValue = perSkillMaxValues[skillId] or skillsMaxValue

        -- Update base and max values in case of manual or uncapper settings changes
        if getter(self).base > maxValue then
            mC.setStat(state, "skills", skillId, maxValue)
        end
        state.skills.max[skillId] = math.min(state.skills.max[skillId], maxValue)

        local actualBase = getter(self).base - (baseStatsMods.skills[skillId] or 0)
        if not decayEnabled then
            state.skills.max[skillId] = actualBase
        end

        local storedBase = state.skills.base[skillId]

        if allAttrs or storedBase ~= actualBase then
            if storedBase ~= actualBase then
                if storedBase ~= nil then
                    log(string.format("Skill \"%s\" has changed from %s to %s", skillId, storedBase, actualBase))
                end
                if (storedBase == nil or actualBase > storedBase) and decayEnabled then
                    mDecay.slowDownSkillDecayOnSkillLevelUp(state, skillId)
                end
            end

            state.skills.base[skillId] = actualBase

            -- Update skill progress to actual value, because:
            -- - skill increases from the console, books or training alters the progression
            -- - skill progresses need to be set for mid-game installs
            state.skills.progress[skillId] = T.NPC.stats.skills[skillId](self).progress

            setSkillGrowths(state, skillId, state.skills.base[skillId], startValuesRatio, luckGrowthRate)

            for attrId, _ in pairs(mCfg.skillsImpactOnAttributes[skillId]) do
                --log(string.format("\"%s\" should be recalculated!", attrId))
                attributesToUpdate[attrId] = true
            end
        end
    end
    if next(attributesToUpdate) then
        state.skills.minMajor = math.huge
        for skillId in pairs(state.skills.major) do
            state.skills.minMajor = math.min(state.skills.base[skillId], state.skills.minMajor)
        end
        state.skills.minMinor = math.huge
        for skillId in pairs(state.skills.minor) do
            state.skills.minMinor = math.min(state.skills.base[skillId], state.skills.minMinor)
        end
    end
    return attributesToUpdate
end
module.updateSkills = updateSkills

local function restoreTrainingSkills()
    for skillId, value in pairs(modifiedTrainingSkills) do
        T.NPC.stats.skills[skillId](self).base = value
    end
    modifiedTrainingSkills = {}
end
module.restoreTrainingSkills = restoreTrainingSkills

local function getTrainingSkillIds(npc)
    local skills = {}
    for skillId in mH.spairs(T.NPC.stats.skills,
            function(t, a, b)
                return t[a](npc).base == t[b](npc).base
                        and skillOrder[a] < skillOrder[b]
                        or t[a](npc).base > t[b](npc).base
            end) do
        table.insert(skills, skillId)
        if #skills == 3 then
            return skills
        end
    end
end

local function capTrainedSkills(state, uiData)
    if not mS.skillsStorage:get("capSkillTraining") then return end

    -- check old mode because BMSO refreshes the training window and we get old mode = new mode
    if uiData.newMode == "Training" and uiData.oldMode ~= "Training" then
        local npc = uiData.arg
        local skillIds = getTrainingSkillIds(npc)
        local messages = {}
        modifiedTrainingSkills = {}
        for _, skillId in ipairs(skillIds) do
            local skill = T.NPC.stats.skills[skillId]
            if skill(self).base < skill(npc).base then
                local msgKey
                if state.skills.minor[skillId] and state.skills.base[skillId] >= state.skills.minMajor then
                    msgKey = "skillTrainingCapMinor"
                end
                if state.skills.misc[skillId] and state.skills.base[skillId] >= state.skills.minMinor then
                    msgKey = "skillTrainingCapMisc"
                end
                if msgKey then
                    modifiedTrainingSkills[skillId] = skill(self).base
                    skill(self).base = skill(npc).base
                    table.insert(messages, L(msgKey, { skill = Skills[skillId].name }))
                end
            end
        end
        if #messages > 0 and (not state.lastTrainer or state.lastTrainer.id ~= npc.id) then
            state.lastTrainer = npc
            for _, message in ipairs(messages) do
                mC.showMessage(state, message)
            end
        end
    elseif uiData.oldMode == "Training" and uiData.newMode ~= "Training" then
        restoreTrainingSkills()
    end
end
module.capTrainedSkills = capTrainedSkills

local function capFactor(ratio)
    return util.clamp(ratio, 0, 1)
end

local function capSkillScaledFactor(factor, range)
    return math.min(range.max, math.max(range.min, factor))
end

local function checkPhysicalDamage(state, deltaTime)
    local armorStats = state.skills.scaled.armor
    local magicDamage = 0
    local hasDrainHealth = false
    local hasFortifyHealth = false
    for _, effect in pairs(T.Actor.activeEffects(self)) do
        if healthEffectIds[effect.id] then
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
    local encumbranceTerm = mC.GMSTs.fJumpEncumbranceBase
            + mC.GMSTs.fJumpEncumbranceMultiplier * (1 - (capacity == 0 and 1 or T.Actor.getEncumbrance(self) / capacity))

    local acrobatics = T.NPC.stats.skills.acrobatics(self).modified
    local a = acrobatics
    local b = 0
    if a > 50 then
        b = a - 50
        a = 50
    end
    local x = mC.GMSTs.fJumpAcrobaticsBase + (a / 15) ^ mC.GMSTs.fJumpAcroMultiplier
    x = x + 3 * b * mC.GMSTs.fJumpAcroMultiplier
    x = x + T.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Jump).magnitude * 64
    x = x * encumbranceTerm
    if self.controls.run then
        x = x * mC.GMSTs.fJumpRunMultiplier
    end
    x = x * mC.GMSTs.fFatigueBase
    x = x + gravityAcceleration
    x = x / 3

    local height = (x ^ 2) / (2 * gravityAcceleration)
    if self.controls.movement ~= 0 or self.controls.sideMovement ~= 0 then
        x = x * jumpVelocityFactor
    end

    local midairVelocity = x + T.Actor.getRunSpeed(self) * (mC.GMSTs.fJumpMoveBase + mC.GMSTs.fJumpMoveMult * acrobatics / 100)
    return { height = height, duration = 2 * x / gravityAcceleration, midairVelocity = midairVelocity }
end

local function getJumpFallLostHealth(depth, soft)
    local skill = T.NPC.stats.skills.acrobatics(self).modified
    if soft then
        depth = depth - mC.GMSTs.fFallDamageDistanceMin
    end
    if depth <= 0 then return 0 end
    depth = math.max(0, depth - 1.5 * skill + T.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Jump).magnitude)
    depth = mC.GMSTs.fFallDistanceBase + mC.GMSTs.fFallDistanceMult * depth
    depth = depth * (mC.GMSTs.fFallAcroBase + mC.GMSTs.fFallAcroMult * (100 - skill))
    return depth <= 0 and 0 or math.max(0, depth * (1 - 0.25 * mC.GMSTs.fFatigueBase))
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

local function getHoleStats(state, stats, landingPos)
    local sum = 0
    local count = 0
    local depthDiff = stats.startPos.z - landingPos.z
    local holeEndPos
    for i = #stats.depth.values, 1, -1 do
        local value = stats.depth.values[i]
        if sum > 0 or value.depth - depthDiff > stats.max.height then
            if sum == 0 then
                holeEndPos = value.posXY
            end
            sum = sum + value.depth
            count = count + 1
        end
        if sum > 0 and value.posXY == stats.holeStartPosXY then
            return holeEndPos, sum / count + state.skills.scaled.acrobatics.maxHeightPos.z - stats.startPos.z
        end
    end
end

local function getDepthInfo(stats, pos, fromZ)
    local to = pos - util.vector3(0, 0, 10000)
    local result = nearby.castRay(pos, to, {
        collisionType = nearby.COLLISION_TYPE.HeightMap + nearby.COLLISION_TYPE.World + nearby.COLLISION_TYPE.Door + nearby.COLLISION_TYPE.Water,
        radius = stats.halfExtents.y,
    })
    if result.hitPos then
        return fromZ - result.hitPos.z, result
    end
    return 10000, to, result
end

local function getDepthFactor(hitInfo)
    local obj = hitInfo.hitObject
    if obj and (lavaIdCache[obj.recordId] or obj.type.record(obj).mwscript == "lava") then
        lavaIdCache[obj.recordId] = true
        return mCfg.jumpGainLavaFactor
    end
    return (self.cell.hasWater and self.cell.waterLevel >= hitInfo.hitPos.z) and mCfg.jumpGainWaterFactor or 1
end

local function getDepthRiskFactor(depth, hitInfo)
    return getDepthFactor(hitInfo) * math.min(mCfg.jumpGainLandingFallDamageMaxFactor, math.max(0, getJumpFallLostHealth(depth) / mC.self.health.base))
end

local function getLandingRiskStillFactor(stats)
    local rotation = util.transform.identity
    local from = self:getBoundingBox().center + util.vector3(0, 0, stats.halfExtents.z / 4)
    -- check risk in 8 directions, each one divided in 5 steps
    local slices = 8
    local steps = 6
    local maxFlatSteps = 3
    local totalSum = 0
    local logStats = {}
    for slice = 1, slices do
        if mC.trace then table.insert(logStats, string.format("\nslice %d", slice)) end
        rotation = rotation * util.transform.rotateZ(2 * math.pi / slices)
        local prevDepth = 0
        local prevDist = 0
        local sum = 0
        local count = 0
        local slipperySlope
        local step = 0
        local holeStarted = false

        local function endOfSlope(depth, hitInfo)
            if not depth or slipperySlope.depth > depth then
                depth = slipperySlope.depth
                hitInfo = slipperySlope.hitInfo
            end
            sum = sum + slipperySlope.count * getDepthRiskFactor(depth, hitInfo)
            count = count + slipperySlope.count
            slipperySlope = nil
        end

        local function handleStep()
            if mC.trace then table.insert(logStats, string.format("step %d", step)) end
            local dist = (2 + (2 * step)) * stats.halfExtents.y
            local pos = from + rotation:apply(util.vector3(0, dist, 0))
            -- first horizontal ray to detect bumps and walls around
            local hRay = nearby.castRay(from, pos, {
                collisionType = nearby.COLLISION_TYPE.HeightMap + nearby.COLLISION_TYPE.World + nearby.COLLISION_TYPE.Door + nearby.COLLISION_TYPE.Water,
                radius = stats.halfExtents.z / 4,
            })
            local depth = 0
            local hitInfo
            local slippery = false
            if hRay.hit then
                -- bump found, stop detecting the risk for this slice
                if mC.trace then table.insert(logStats, "H hit") end
                return false
            end
            depth, hitInfo = getDepthInfo(stats, pos, self.position.z)
            if mC.trace then table.insert(logStats, string.format("depth %d", depth)) end
            if math.atan((depth - prevDepth) / (dist - prevDist)) > maxSlope then
                -- the slope is too steep, we ignore the current step
                slippery = true
                local slideCount = slipperySlope and (slipperySlope.count + 1) or 1
                slipperySlope = { depth = depth, hitInfo = hitInfo, count = slideCount }
                if mC.trace then table.insert(logStats, "slippery") end
            end
            if not slippery then
                if slipperySlope then
                    -- we reached the bottom of the slope
                    endOfSlope(depth, hitInfo)
                end
                if holeStarted and depth < prevDepth then
                    -- we're in the hole and the surface is raising, stop detecting the risk for this slice
                    if mC.trace then table.insert(logStats, "raising") end
                    return false
                end
                local riskFactor = 0
                if depth > stats.max.height then
                    -- we're in the hole (deep enough so the player cannot go back to the landing platform)
                    holeStarted = true
                    riskFactor = getDepthRiskFactor(depth, hitInfo)
                    if mC.trace then table.insert(logStats, string.format("risk %.2f", riskFactor)) end
                elseif step > maxFlatSteps then
                    -- too flat around, stop detecting the risk for this slice
                    if mC.trace then table.insert(logStats, "too flat") end
                    return false
                end
                sum = sum + riskFactor
                count = count + 1
            end
            prevDepth = depth
            prevDist = dist
            return true
        end

        while step < steps do
            if not handleStep() then
                step = steps
            else
                step = step + 1
            end
        end
        if slipperySlope then
            -- last step is the bottom of the slope
            endOfSlope()
        end
        totalSum = totalSum + (count == 0 and 0 or sum / count)
        if mC.trace then table.insert(logStats, string.format("factor %.2f", sum / count)) end
    end
    if mC.trace then log(string.format("Jump landing surroundings risk:%s\n", table.concat(logStats, ", "))) end
    return (totalSum / slices)
end

local function onJumpLanded(state)
    local stats = state.skills.scaled.acrobatics.stats
    local landingRiskStillFactor = capFactor(getLandingRiskStillFactor(stats))
    local pos = self.position
    local jumpDuration = core.getSimulationTime() - state.skills.scaled.acrobatics.lastJumpTime
    local lastTimeFactor = capFactor(stats.timeSinceLastJump / state.skills.scaled.acrobatics.lastJumpMaxDuration) ^ 4
    local avgDepth, depthFactor, holeLength = 0, 0, 0
    local hasHoleEnd = stats.depth.max - (stats.startPos.z - pos.z) > stats.max.height
    if stats.holeStartPosXY and hasHoleEnd then
        local holeEndPos
        holeEndPos, avgDepth = getHoleStats(state, stats, pos)
        local riskDamage = getJumpFallLostHealth(avgDepth)
        local expectedDamage = getJumpFallLostHealth(state.skills.scaled.acrobatics.maxHeightPos.z - pos.z)
        depthFactor = capFactor((riskDamage - expectedDamage) / mC.self.health.base) ^ 0.5
        holeLength = (holeEndPos - stats.holeStartPosXY):length() + 4 * stats.halfExtents.y
    end
    local maxLength = stats.max.midairVelocity * jumpDuration - 2 * stats.halfExtents.y
    local holeLengthFactor = capFactor(holeLength / maxLength)
    local maxLengthFactor = capFactor(mH.groundDist(pos, stats.startPos) / maxLength)
    -- full landing risk factor if the player traveled at least a quarter of the max jump distance (discard vertical jumps)
    local landingRiskFactor = landingRiskStillFactor * capFactor(maxLengthFactor * 4)
    local maxHeightFactor = capFactor((state.skills.scaled.acrobatics.maxHeightPos.z - stats.startPos.z) / stats.max.height)
    local landingHeight = pos.z - stats.startPos.z
    local landingHeightFactor = capFactor(landingHeight / stats.max.height) ^ 2
    local factor = capSkillScaledFactor(
            lastTimeFactor * (mCfg.jumpGainLandingRiskFactor * landingRiskFactor + math.max(
                    mCfg.jumpGainBottomFactor * depthFactor * holeLengthFactor,
                    mCfg.jumpGainLandingHeightFactor * landingHeightFactor,
                    mCfg.jumpGainMaxDistFactor * math.max(maxLengthFactor, maxHeightFactor))),
            mS.getSkillGainScaledRange("acrobaticsSkillScalingRange"))

    log(string.format("Jumped:\n\tStats: since time %.2f/%.2f, landing risk still %.2f, depth avg %.1f/%.1f, hole length %.1f/%.1f, height %.1f/%.1f, landed at %.1f"
            .. "\n\tFactors: last time %.3f x ( %s x landing risk %.2f + max( %s x depth %.3f x length %.3f, %s x landed %.3f, %s x max(maxLength %.3f, maxHeight %.3f) ) ) = final %.3f"
            .. "\n\tGain scale: base %.3f x factor %.3f = %.3f",
    -- Stats
            stats.timeSinceLastJump, stats.max.duration,
            landingRiskStillFactor,
            avgDepth, stats.depth.max + state.skills.scaled.acrobatics.maxHeightPos.z - stats.startPos.z,
            holeLength, maxLength,
            state.skills.scaled.acrobatics.maxHeightPos.z - stats.startPos.z, stats.max.height,
            landingHeight,
    -- Factors
            lastTimeFactor,
            mCfg.jumpGainLandingRiskFactor, landingRiskFactor,
            mCfg.jumpGainBottomFactor, depthFactor, holeLengthFactor,
            mCfg.jumpGainLandingHeightFactor, landingHeightFactor,
            mCfg.jumpGainMaxDistFactor, maxLengthFactor, maxHeightFactor,
            factor, stats.handlerParams.scale, factor, stats.handlerParams.scale * factor))

    onJumpFinished(state, stats, factor)
end

local function handleJumps(state, isOnGround, hasFlyingEffects)
    local stats = state.skills.scaled.acrobatics.stats

    local depth, hitInfo = getDepthInfo(stats, self.position, stats.startPos.z)

    if not stats.holeStartPosXY and depth > stats.max.height then
        stats.holeStartPosXY = mH.v3xy(self.position)
    end
    if stats.holeStartPosXY then
        local depthFactor = getDepthFactor(hitInfo)
        table.insert(stats.depth.values, { posXY = mH.v3xy(self.position), depth = depth * depthFactor })
        stats.depth.max = math.max(stats.depth.max, depth * depthFactor)
    end

    if hasFlyingEffects then
        local minFactor = mS.getSkillGainScaledRange("acrobaticsSkillScalingRange").min
        log(string.format("Used levitate or slowFall during a jump, gain %.3f -> %.3f", stats.handlerParams.skillGain, stats.handlerParams.skillGain * minFactor))
        onJumpFinished(state, stats, stats.handlerParams.skillGain * minFactor)
    end
    if self.position.z > state.skills.scaled.acrobatics.maxHeightPos.z then
        state.skills.scaled.acrobatics.maxHeightPos = self.position
    end

    if state.skills.scaled.acrobatics.maxHeightPos.z > stats.startPos.z and isOnGround then
        onJumpLanded(state)
    end
end

local function getSwimSpeedFactor()
    local factor = 1 + 0.01 * T.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.SwiftSwim).magnitude
    return factor * (0.01 * T.NPC.stats.skills.athletics(self).modified * mC.GMSTs.fSwimRunAthleticsMult + mC.GMSTs.fSwimRunBase)
end

local function handleAthletics(state, isOnGround, deltaTime)
    local stats = state.skills.scaled.athletics
    local isMoving = self.controls.movement ~= 0 or self.controls.sideMovement ~= 0
    if isMoving and self.controls.run then
        stats.deltaTime = stats.deltaTime + deltaTime
        if isOnGround or T.Actor.isSwimming(self) then
            if isOnGround then
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

---- Skill handlers ----

local function addSkillGain(state, skillId, skillGain)
    local skillRequirement = I.SkillProgression.getSkillProgressRequirement(skillId)
    local progress = T.NPC.stats.skills[skillId](self).progress + skillGain / skillRequirement
    local excessSkillGain = (progress - 1) * skillRequirement
    log(string.format("Add skill \"%s\" gain %.3f (requirement %.3f, excess %.3f), progress %.3f to %.3f",
            skillId, skillGain, skillRequirement, excessSkillGain > 0 and excessSkillGain or 0, T.NPC.stats.skills[skillId](self).progress, progress))
    if excessSkillGain >= 0 then
        mC.modStat(state, "skills", skillId, 1)
        if not mS.skillsStorage:get("carryOverExcessSkillGain") or
                T.NPC.stats.skills[skillId](self).base >= mS.getSkillMaxValue(skillId) then
            progress = 0
        else
            T.NPC.stats.skills[skillId](self).progress = 0
            -- Recursive function to allow gaining multiple levels with one skill action (unlikely but possible)
            addSkillGain(state, skillId, excessSkillGain)
            return
        end
    end
    state.skills.progress[skillId] = progress
    T.NPC.stats.skills[skillId](self).progress = progress
end
module.addSkillGain = addSkillGain

local function skillUsedHandlerFinal(state, skillId, params)
    local skillLevel = T.NPC.stats.skills[skillId](self).base
    addSkillGain(state, skillId, params.skillGain)
    if skillLevel ~= T.NPC.stats.skills[skillId](self).base then
        ambient.playSound("skillraise")
        self:sendEvent(mDef.events.updateGrowth)
    end
    -- We handle skill level up
    return false
end

local function skillUsedHandlerReduction(_, skillId, params)
    local range = mS.skillsStorage:get("skillGainFactorRange")
    if range[1] == 100 and range[2] == 100 then return end

    local level = T.NPC.stats.skills[skillId](self).base
    local baseGain = params.skillGain
    local scaledGain = baseGain * params.scale
    params.skillGain = scaledGain * mDef.formulas.getLogRangeFactor(level, range[1], range[2])
    log(string.format("Skill \"%s\" level %d, gain changed from %.5f unscaled to %.5f scaled (scale %.3f) to %.5f, from setting range [%s, %s]",
            skillId, level, baseGain, scaledGain, params.scale, params.skillGain, range[1], range[2]))
end

local function skillUsedHandlerMagickaRefund(_, skillId)
    if not magickaSkills[skillId] or not mS.magickaStorage:get("refundEnabled") then return end
    if not isSpellCasting() then
        log("Magicka refund handler: No spell cast detected, no scaling")
        return
    end

    local spell = T.Actor.getSelectedSpell(self)
    if not spell then
        log(string.format("No spell selected for skill \"%s\" for magicka refund handler, no scaling", skillId))
        return
    end
    local refund = spell.cost * (mS.magickaStorage:get("refundMult") / 5)
            * (1 - 0.5 ^ (math.max(T.NPC.stats.skills[skillId](self).base - mS.magickaStorage:get("refundStart"), 0) / 100))
    if refund > 0 then
        log(string.format("MBSP: Magic skill \"%s\" refund: %.2f", skillId, refund))
        mC.modMagicka(refund)
    end
end

local function skillUsedHandlerMultiSchool(_, skillId, params)
    if not magickaSkills[skillId] then return end
    if not isSpellCasting() then
        log("Multi-school handler: No spell cast detected, no scaling")
        return
    end

    local spell = T.Player.getSelectedSpell(self)
    if not spell then
        log(string.format("Multi-school handler: No spell selected for skill \"%s\" for multi-school handler, no scaling", skillId))
        return
    end
    spellSchoolRatios[spell.id] = spellSchoolRatios[spell.id] or mSpells.getSchoolRatios(spell, self)
    local skillGain = params.skillGain
    for school, ratio in pairs(spellSchoolRatios[spell.id]) do
        if ratio < 1 then
            log(string.format("Magicka skill \"%s\" increase, base gain = %.5f, multi-school ratio = %.2f, split gain = %.5f",
                    school, skillGain, ratio, skillGain * ratio))

            local gain = ratio * skillGain
            if skillId == school then
                params.skillGain = gain
            else
                -- preserve reductions of previous handlers, preserve potential addons changes on base skill gains
                gain = gain * core.stats.Skill.records[skillId].skillGain[1] / core.stats.Skill.records[school].skillGain[1]
                self:sendEvent(mDef.events.applySkillUsedHandlers, {
                    skillId = school,
                    params = { skillGain = gain, scale = params.scale, useType = params.useType },
                    afterHandler = "multiSchool"
                })
            end
        end
    end
end

local function skillUsedExternalHandlers(_, skillId, params)
    for _, handler in ipairs(externalSkillUsedHandlers) do
        if false == handler(skillId, params) then
            return false
        end
    end
end

local function skillUsedHandlerScaled(state, skillId, params)
    local factor = 1
    if magickaSkills[skillId] then
        if not mS.skillUsesScaledStorage:get("magickaBasedSkillScalingEnabled") then return end
        if not isSpellCasting() then
            log("Magicka skill scaling: No spell cast detected, no scaling")
            return
        end
        local spell = T.Actor.getSelectedSpell(self)
        local chance = math.max(0, mC.GMSTs.fFatigueBase * mSpells.calcAutoCastChance(spell, self) / 100)
        factor = capSkillScaledFactor(
                chance < 1 and (2 - chance ^ 2) or (1 - (chance - 1) ^ 4),
                mS.getSkillGainScaledRange("magickaBasedSkillScalingRange"))
        log(string.format("Cast the spell \"%s\" cost %d, chance = %.2f, factor = %.3f, gain %.3f -> %.3f",
                spell.name, spell.cost, chance, factor, params.skillGain, params.skillGain * factor))
    elseif weaponSkills[skillId] and skillId ~= Skills.marksman.id then
        if not mS.skillUsesScaledStorage:get("weaponSkillScalingEnabled") then return end
        if not isMeleeAttacking() then
            log("Weapon skills scaling: No attack detected, no scaling")
            return
        end
        local enemy = getFacedObject()
        if not enemy then
            log("Weapon skills scaling: No enemy found, no scaling")
            return
        end
        if enemy.type.baseType == T.Actor then
            local attackTerm = mC.agilityTerm(skillId) * mC.GMSTs.fFatigueBase
            local defenseTerm = mC.agilityTerm(false, enemy) * mC.GMSTs.fFatigueBase
            local chance = math.floor(0.5 + attackTerm - defenseTerm) / 100
            factor = capSkillScaledFactor(
                    6 / math.max(0.01, 1.5 + chance) - 2,
                    mS.getSkillGainScaledRange("weaponSkillScalingRange"))
            log(string.format("Hit the enemy \"%s\" (attack %.2f, defense %.2f), chance = %.2f, factor = %.3f, gain %.3f -> %.3f",
                    enemy.recordId, attackTerm, defenseTerm, chance, factor, params.skillGain, params.skillGain * factor))
        else
            log(string.format("Weapon skills scaling: The target \"%s\" is not an actor", enemy.recordId))
        end
    elseif skillId == Skills.security.id then
        if not mS.skillUsesScaledStorage:get("securitySkillScalingEnabled") then return end
        if not isLockPicking() then
            log("Security scaling: No lock or disarm attempt detected, no scaling")
            return
        end
        if not lockableStats then
            log("Security scaling: No lockable found, no scaling")
            return
        end
        if lockableStats.lockLevel then
            local chance = mC.agilityTerm(skillId)
                    * mC.GMSTs.fFatigueBase
                    + lockableStats.lockLevel * mC.GMSTs.fPickLockMult
            factor = capSkillScaledFactor(
                    2 * (math.max(0, 1 - chance / 100)) ^ 2,
                    mS.getSkillGainScaledRange("securitySkillScalingRange"))
            log(string.format("Unlocked a lock level %d, chance = %.2f, factor = %.3f, gain %.3f -> %.3f",
                    lockableStats.lockLevel, chance, factor, params.skillGain, params.skillGain * factor))
        elseif lockableStats.trapSpell then
            local chance = mC.agilityTerm(skillId)
                    * mC.GMSTs.fFatigueBase
                    + lockableStats.trapSpell.cost * mC.GMSTs.fTrapCostMult
            factor = capSkillScaledFactor(
                    2 * (math.max(0, 1 - chance / 100)),
                    mS.getSkillGainScaledRange("securitySkillScalingRange"))
            log(string.format("Disarmed a trap with spell cost %d, chance = %.2f, factor = %.3f, gain %.2f -> %.2f",
                    lockableStats.trapSpell.cost, chance, factor, params.skillGain, params.skillGain * factor))
        end
    elseif armorSkills[skillId] then
        if not mS.skillUsesScaledStorage:get("armorSkillScalingEnabled") then return end
        -- if received multiple hits during the same frame, use the merged health damage and apply the skill gain factor on the first triggered armor skill use
        if state.skills.scaled.armor.skillUsedInFrame then
            return false
        end
        state.skills.scaled.armor.skillUsedInFrame = true
        local physicalDamage = checkPhysicalDamage(state, state.skills.scaled.deltaTime)
        if physicalDamage <= 0 then
            log(string.format("Armor scaling: No physical damage (%.1f), no scaling", physicalDamage))
            return
        end
        if mC.self.health.base <= 0 then
            log(string.format("Armor scaling: Base health is not positive (%.1f), no scaling", mC.self.health.base))
            return
        end
        local healthRatio = physicalDamage / mC.self.health.base
        factor = capSkillScaledFactor(
                4 * healthRatio,
                mS.getSkillGainScaledRange("armorSkillScalingRange"))
        log(string.format("Hit by an enemy, health ratio = %.2f, factor = %.3f, gain %.3f -> %.3f",
                healthRatio, factor, params.skillGain, params.skillGain * factor))
    elseif skillId == Skills.acrobatics.id then
        if not mS.skillUsesScaledStorage:get("acrobaticsSkillScalingEnabled") then return end
        if params.useType == I.SkillProgression.SKILL_USE_TYPES.Acrobatics_Fall then
            local height = state.skills.scaled.acrobatics.maxHeightPos.z - self.position.z
            if height < 1 then
                log("Acrobatics fall scaling: No fall detected, no scaling")
                return
            end
            local damage = getJumpFallLostHealth(state.skills.scaled.acrobatics.maxHeightPos.z - self.position.z, true)
            local healthRatio = 2 * capFactor(damage / mC.self.health.base)
            factor = capSkillScaledFactor(healthRatio, mS.getSkillGainScaledRange("acrobaticsSkillScalingRange"))
            log(string.format("Took damage from a fall, damage = %.1f, health ratio = %.2f, factor = %.3f, gain %.3f -> %.3f",
                    damage, healthRatio, factor, params.skillGain, params.skillGain * factor))
            onHealthModified(state, -damage)
        elseif params.useType == I.SkillProgression.SKILL_USE_TYPES.Acrobatics_Jump then
            if not self.controls.jump then
                log("Acrobatics jump scaling: Not jumping, no scaling")
                return
            end
            local time = core.getSimulationTime()
            state.skills.scaled.acrobatics.stats = {
                handlerParams = params,
                max = getJumpMaxStats(),
                holeStartPosXY = nil,
                depth = { values = {}, max = 0 },
                startPos = self.position,
                timeSinceLastJump = time - state.skills.scaled.acrobatics.lastJumpTime,
                halfExtents = T.Actor.getPathfindingAgentBounds(self).halfExtents,
            }
            state.skills.scaled.acrobatics.lastJumpTime = time
            state.skills.scaled.acrobatics.maxHeightPos = self.position
            -- gain will be added on landing
            return false
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
        log(string.format("Athletics run duration %.2f time ratio %.2f velocity %.2f final %.2f, gain %.3f -> %.3f",
                stats.runningDuration, timeRatio, velocityRatio, factor, params.skillGain, params.skillGain * factor))
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
        log(string.format("Created the %s potion from a recipe (%s) with %d positive effects, factor %.2f, gain %.3f -> %.3f",
                mH.ordinal(recipeCount + 1), potionStats.key, potionStats.positiveEffects, factor, params.skillGain, params.skillGain * factor))
        if recipeCount == 100 then
            mC.showMessage(state, L("alchemyScalingRecipeLimit"))
        end
    end

    params.scale = params.scale * factor
    notifySkillScaledGain(skillId, params.useType, factor)
end

local function skillUsedHandlerUses(_, skillId, params)
    params.scale = params.scale or 1

    local gainCustom = mS.getSkillUseGain(skillId, params.useType)
    local gainVanilla = mCfg.skillUseTypes[skillId][params.useType].vanilla
    if gainCustom ~= gainVanilla then
        log(string.format("Custom base gain for skill \"%s\" is %.2f (instead of input %.2f and vanilla %.2f)", skillId, gainCustom, params.skillGain, gainVanilla))
        params.skillGain = gainCustom
    end

    if not weaponSkills[skillId] then
        return
    end
    local speed = 1.5 -- estimated speed for hand to hand
    local weapon = T.Actor.getEquipment(self, T.Actor.EQUIPMENT_SLOT.CarriedRight)
    if weapon then
        weaponSpeeds[weapon.id] = weaponSpeeds[weapon.id] or weapon.type.record(weapon).speed
        speed = weaponSpeeds[weapon.id]
    end
    -- Faster weapons reduce the gain, but less than proportionally to the speed
    -- Examples with gain 0.75:
    -- - speed 1.0 -> gain 0.75
    -- - speed 1.5 -> gain 0.61
    -- - speed 2.0 -> gain 0.53
    -- - speed 2.5 -> gain 0.47
    local scale = 1 / (speed ^ 0.5)
    log(string.format("Modified gain scale for skill \"%s\" from %.5f to %.5f, based on weapon speed %.2f", skillId, params.scale, params.scale * scale, speed))
    params.scale = params.scale * scale
end

local function skillUsedHandlerCapper(_, skillId, _)
    if T.NPC.stats.skills[skillId](self).base >= mS.getSkillMaxValue(skillId) then
        T.NPC.stats.skills[skillId](self).progress = 0
        -- Stop skill used handlers
        return false
    end
end

local function getSkillUsedHandlers(state)
    return {
        { name = "final", handler = function(skillId, params) return skillUsedHandlerFinal(state, skillId, params) end },
        { name = "reduction", handler = function(skillId, params) return skillUsedHandlerReduction(state, skillId, params) end },
        { name = "decay", handler = function(skillId, params) return mDecay.skillUsedHandler(state, skillId, params) end },
        { name = "magickaRefund", handler = function(skillId, params) return skillUsedHandlerMagickaRefund(state, skillId, params) end },
        { name = "multiSchool", handler = function(skillId, params) return skillUsedHandlerMultiSchool(state, skillId, params) end },
        { name = "external", handler = function(skillId, params) return skillUsedExternalHandlers(state, skillId, params) end },
        { name = "scaled", handler = function(skillId, params) return skillUsedHandlerScaled(state, skillId, params) end },
        { name = "uses", handler = function(skillId, params) return skillUsedHandlerUses(state, skillId, params) end },
        { name = "capper", handler = function(skillId, params) return skillUsedHandlerCapper(state, skillId, params) end },
    }
end

local function addSkillUsedHandler(newHandler)
    table.insert(externalSkillUsedHandlers, newHandler)
end
module.addSkillUsedHandler = addSkillUsedHandler

local function addSkillHandlers(state)
    for _, handler in ipairs(getSkillUsedHandlers(state)) do
        I.SkillProgression.addSkillUsedHandler(handler.handler)
    end

    I.SkillProgression.addSkillLevelUpHandler(function(skillId, source)
        if source == I.SkillProgression.SKILL_INCREASE_SOURCES.Book and not mS.skillsStorage:get("skillIncreaseFromBooks") then
            log(string.format("Preventing skill \"%s\" level up from book", skillId))
            -- Stop skill level up handlers
            return false
        end
        local details
        if source == I.SkillProgression.SKILL_INCREASE_SOURCES.Trainer then
            mDecay.setLastTrainedSkillId(skillId)
            if mS.skillsStorage:get("progressiveTrainingDuration") then
                local extraTimePassed = 14 * (state.skills.base[skillId] / 100) ^ 2
                log(string.format("Training skill \"%s\" took 2 + %.2f hours", skillId, extraTimePassed))
                core.sendGlobalEvent(mDef.events.skipGameHours, { player = self, hours = extraTimePassed })
                details = L("trainingDuration", { hours = 2 + math.floor(extraTimePassed), minutes = math.floor(extraTimePassed % 1 * 60) })
            end
        end
        self:sendEvent(mDef.events.updateGrowthAllAttrs)
        mC.modStat(state, "skills", skillId, 1, { details = details })
        ambient.playSound("skillraise")
        return false
    end)
end
module.addSkillHandlers = addSkillHandlers

local function applySkillUsedHandlers(state, skillId, params, afterHandler)
    local apply = not afterHandler
    local handlers = getSkillUsedHandlers(state)
    for i = #handlers, 1, -1 do
        local handler = handlers[i]
        if apply then
            if false == handler.handler(skillId, params) then
                return
            end
        end
        if afterHandler and handler.name == afterHandler then
            apply = true
        end
    end
end
module.applySkillUsedHandlers = applySkillUsedHandlers

local function uiModeChanged(state, data)
    capTrainedSkills(state, data)

    if data.newMode == "Alchemy" and mS.skillUsesScaledStorage:get("alchemySkillScalingEnabled") then
        ownedIngredients = {}
    else
        ownedIngredients = nil
    end

end
module.uiModeChanged = uiModeChanged

module.onUpdate = function(state, deltaTime)
    local isOnGround = T.Actor.isOnGround(self)

    if mS.skillUsesScaledStorage:get("armorSkillScalingEnabled") then
        local stats = state.skills.scaled.armor
        stats.skillUsedInFrame = false
        if state.skills.scaled.health ~= mC.self.health.current or stats.drainHealth ~= 0 then
            -- update drain health data
            checkPhysicalDamage(state, deltaTime)
        end
    end

    if mS.skillUsesScaledStorage:get("acrobaticsSkillScalingEnabled") then
        local stats = state.skills.scaled.acrobatics
        local activeEffects = T.Actor.activeEffects(self)
        local hasFlyingEffects = activeEffects:getEffect(core.magic.EFFECT_TYPE.Levitate).magnitude > 0
                or activeEffects:getEffect(core.magic.EFFECT_TYPE.SlowFall).magnitude > 0
        if stats.stats then
            handleJumps(state, isOnGround, hasFlyingEffects)
        end
        if not isOnGround and state.skills.scaled.isOnGround
                or self.position.z > stats.maxHeightPos.z
                or hasFlyingEffects
        then
            stats.maxHeightPos = self.position
        end
    end

    if mS.skillUsesScaledStorage:get("athleticsSkillScalingEnabled") then
        handleAthletics(state, isOnGround, deltaTime)
    end

    state.skills.scaled.deltaTime = deltaTime
    state.skills.scaled.pos = self.position
    state.skills.scaled.health = mC.self.health.current
    state.skills.scaled.isOnGround = isOnGround
end

module.onFrame = function()
    if ownedIngredients then
        checkIngredients()
    end
end

return module