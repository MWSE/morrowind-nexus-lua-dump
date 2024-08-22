local this = {}

local log = include("Morrowind_World_Randomizer.log")
local random = include("Morrowind_World_Randomizer.Random")
local effectLib = include("Morrowind_World_Randomizer.magicEffect")
local generator = include("Morrowind_World_Randomizer.generator")
local dataSaver = include("Morrowind_World_Randomizer.dataSaver")
local saveRestore = include("Morrowind_World_Randomizer.saveRestore")
local globalConfig = include("Morrowind_World_Randomizer.config").global
this.config = include("Morrowind_World_Randomizer.config").data

this.storage = include("Morrowind_World_Randomizer.storage")

this.getUniqueId = include("Morrowind_World_Randomizer.uniqueId").getUniqueId

local enchPrefix = "_mwrand_new_ench_"
local itemPrefix = "_mwrand_new_item_"

this.dummyConstEnchId = "_mwrand_dummy_ench_01"
this.dummyStrikeEnchId = "_mwrand_dummy_ench_02"

---@type mwr.itemStatsData
this.data = nil

this.itemTypeForEnchantment = {
    [tes3.objectType.armor] = true,
    [tes3.objectType.book] = true,
    [tes3.objectType.clothing] = true,
    [tes3.objectType.weapon] = true,
    [tes3.objectType.ammunition] = true,
}

this.itemTypeForUnique = {
    [tes3.objectType.armor] = true,
    [tes3.objectType.clothing] = true,
    [tes3.objectType.weapon] = true,
    [tes3.objectType.ammunition] = true,
}

this.itemTypeForEffects = {
    [tes3.objectType.alchemy] = true,
    [tes3.objectType.ingredient] = true,
}

this.enchCostMul = {
    [tes3.objectType.weapon] = {
        [0] = 0.6,
    },
    [tes3.objectType.armor] = {
        [tes3.armorSlot.helmet] = 0.6,
        [tes3.armorSlot.cuirass] = 0.6,
        [tes3.armorSlot.leftPauldron] = 0.3,
        [tes3.armorSlot.rightPauldron] = 0.3,
        [tes3.armorSlot.greaves] = 0.6,
        [tes3.armorSlot.boots] = 0.5,
        [tes3.armorSlot.leftGauntlet] = 0.4,
        [tes3.armorSlot.rightGauntlet] = 0.4,
        [tes3.armorSlot.shield] = 1,
        [tes3.armorSlot.leftBracer] = 0.3,
        [tes3.armorSlot.rightBracer] = 0.3,
    },
    [tes3.objectType.clothing] = {
        [tes3.clothingSlot.pants] = 0.3,
        [tes3.clothingSlot.shoes] = 0.2,
        [tes3.clothingSlot.shirt] = 0.3,
        [tes3.clothingSlot.belt] = 0.2,
        [tes3.clothingSlot.robe] = 0.4,
        [tes3.clothingSlot.rightGlove] = 0.2,
        [tes3.clothingSlot.leftGlove] = 0.2,
        [tes3.clothingSlot.skirt] = 0.3,
        [tes3.clothingSlot.ring] = 0.8,
        [tes3.clothingSlot.amulet] = 1,
    },
    [tes3.objectType.ammunition] = {
        [0] = 0.2,
    },
    [tes3.objectType.book] = {
        [1] = 0.5,
    },
}

function this.iterItems(inventory)
    local function iterator()
        for _, stack in pairs(inventory) do
            ---@cast stack tes3itemStack
            local item = stack.object

            local count = math.abs(stack.count)

            -- first yield stacks with custom data
            if stack.variables then
                for _, data in pairs(stack.variables) do
                    if data then
                        coroutine.yield(stack, item, data.count, data)
                        count = count - data.count
                    end
                end
            end
            -- then yield all the remaining copies
            if count ~= 0 then
                coroutine.yield(stack, item, count)
            end
        end
    end
    return coroutine.wrap(iterator)
end

function this.isEnchantContainsForbiddenEffect(enchant)
    if not enchant or not enchant.effects then return end
    for i, eff in pairs(enchant.effects) do
        if effectLib.effectsData.forbiddenForConstantType[eff.id] then return true end
    end
    return false
end

local function chooseGroup(enchType, isConstant)
    local rangeType = enchType == tes3.enchantmentType.onStrike and tes3.effectRange.touch or
        isConstant and tes3.effectRange.self or math.random(0, 2)
    local groupType = isConstant and "selfMagnitude" or rangeType
    local effGroup_p = effectLib.effectsData.forEnchant.positive[groupType]
    local effGroup_n = effectLib.effectsData.forEnchant.negative[groupType]
    return rangeType, effGroup_p, effGroup_n
end

local fortifyEffectIds = {79, 80, 81, 82, 83, 84}
local damageEffectIds = {14, 15, 16, 23,}
local restoreStatsEffectIds = {75, 76, 77}

function this.randomizeEffects(effects, effData, config)
    local effCount = effData.effectCount
    local thresholdVal = effData.thresholdValue
    local oneType = effData.oneType
    local rangeType = effData.rangeType
    local effGroup_p = effData.effGroup_p
    local effGroup_n = effData.effGroup_n
    local enchType = effData.enchantmentType
    local isConstant = effData.isConstant
    local enchPower = effData.power
    local strongThreshold = effData.strongThreshold or true
    local preferValue = effData.preferValue or false
    local isAlchemy = effData.isAlchemy or false
    local mulForConst = config.enchantment.effects.durationForConstant
    --clear old data
    for i = 1, 8 do
        effects[i].id = -1
        effects[i].skill = 0
        effects[i].attribute = 0
        effects[i].min = 0
        effects[i].max = 0
        effects[i].duration = 0
        effects[i].radius = 0
    end

    --add a new effect with a minimum value until it reaches the threshold
    local effectUniqueness = {}
    local addedCount = 0
    local enchVal = 0
    for i = 1, effCount do
        if enchVal < thresholdVal then
            if not oneType then
                rangeType, effGroup_p, effGroup_n = chooseGroup(enchType, isConstant)
            end
            local configChance = rangeType ~= tes3.effectRange.self and config.enchantment.effects.chanceToNegativeForTarget or
                config.enchantment.effects.chanceToNegative
            local isNegative = math.random() < configChance
            local group = isNegative and effGroup_n or effGroup_p
            local effectId
            if not isNegative and isAlchemy and rangeType == tes3.effectRange.self and config.enchantment.effects.restoreForAlchemyChance > math.random() then
                effectId = restoreStatsEffectIds[math.random(1, #restoreStatsEffectIds)]
            elseif not isNegative and rangeType == tes3.effectRange.self and config.enchantment.effects.fortifyForSelfChance > math.random() then
                effectId = fortifyEffectIds[math.random(1, #fortifyEffectIds)]
            elseif isNegative and rangeType ~= tes3.effectRange.self and config.enchantment.effects.damageForTargetChance > math.random() then
                effectId = damageEffectIds[math.random(1, #damageEffectIds)]
            else
                effectId = random.GetRandomFromGroup(group, (config.enchantment.effects.safeMode and isConstant) and
                    effectLib.effectsData.forbiddenForConstantType or {}) or -1
            end

            local iteration = 0
            while ((((effectLib.effectsData.cost[effectId] or 0) > thresholdVal - enchVal) and strongThreshold) or effectUniqueness[effectId]) and iteration < 40 do
                iteration = iteration + 1
                effectId = random.GetRandomFromGroup(group, (config.enchantment.effects.safeMode and isConstant) and
                    effectLib.effectsData.forbiddenForConstantType or {}) or -1
            end

            effectUniqueness[effectId] = true
            effects[i].id = effectId
            local magicEffect = effects[i].object
            -- if not magicEffect.hasNoMagnitude then
                effects[i].min = 1
                effects[i].max = 1
            -- end
            effects[i].duration = 1
            if not isConstant and not magicEffect.hasNoDuration and magicEffect.appliesOnce then
                effects[i].duration = config.enchantment.effects.minAppOnceDuration
            end
            effects[i].radius = 0
            effects[i].rangeType = rangeType
            log("range %s", tostring(rangeType))
            if magicEffect.targetsSkills then
                effects[i].skill = math.random(0, 26)
                log("skill %s", tostring(effects[i].skill))
            end
            if magicEffect.targetsAttributes then
                effects[i].attribute = math.random(0, 7)
                log("attribute %s", tostring(effects[i].attribute))
            end
            if (rangeType == tes3.effectRange.self and magicEffect.isHarmful) or
                    (rangeType ~= tes3.effectRange.self and not magicEffect.isHarmful) then
                enchVal = enchVal - (isConstant and effectLib.calculateEffectCostForConstant(effects[i], mulForConst) or
                    effectLib.calculateEffectCost(effects[i]))
            else
                enchVal = enchVal + (isConstant and effectLib.calculateEffectCostForConstant(effects[i], mulForConst) or
                    effectLib.calculateEffectCost(effects[i]))
            end
            addedCount = addedCount + 1
        else
            break
        end
    end

    if addedCount == 0 then return nil end

    --tune new effects
    local effs = {}
    for i = 1, addedCount do
        local effect = effects[i]
        if effect.id >= 0 then
            effs[i] = {id = effect.id, min = effect.min, max = effect.max, duration = effect.duration, radius = effect.radius,}
        else
            break
        end
    end
    local minmaxThreshold = preferValue and 0.9 or 0.6
    local iterations = 2 * config.enchantment.effects.tuneStepsCount
    local stepPow = (enchPower - enchVal) / config.enchantment.effects.tuneStepsCount
    while enchVal < enchPower and iterations > 0 do
        iterations = iterations - 1
        local effectPos = math.random(1, #effs)
        local effect = effects[effectPos]
        local effectData = effs[effectPos]
        local effectCost = (isConstant and effectLib.calculateEffectCostForConstant(effectData, mulForConst) or effectLib.calculateEffectCost(effectData))
        local magicEffect = effect.object
        if magicEffect == nil then goto continue end
        local baseCost = magicEffect.baseMagickaCost
        local rnd = isConstant and 0 or math.random()
        if rnd < minmaxThreshold and not magicEffect.hasNoMagnitude then
            local mul = effect.rangeType == tes3.effectRange.target and 1.5 or 1
            local magnitude
            local min, max
            if isConstant then
                magnitude = ((((40 * (effectCost + stepPow) / (baseCost * mul)) - effectData.radius) / mulForConst) - (effectData.min + effectData.max)) * 0.5
                local val = random.GetBetween(0, magnitude)
                min = val
                max = val
            else
                magnitude = (((40 * (effectCost + stepPow) / (baseCost * mul)) - effectData.radius) / ((effectData.duration)) -
                    (effectData.min + effectData.max)) * 0.5
                min = random.GetBetween(0, 0.75 * magnitude)
                max = random.GetBetween(0, 1.25 * magnitude)
            end
            if min > max then min = max end
            effectData.min = math.min(effectData.min + min, config.enchantment.effects.maxMagnitude)
            effectData.max = math.min(effectData.max + max, config.enchantment.effects.maxMagnitude)

        elseif rnd < 0.97 and not magicEffect.hasNoDuration and not isConstant then
            local mul = effect.rangeType == tes3.effectRange.target and 1.5 or 1
            local magnitude = ((40 * (effectCost + stepPow) / (baseCost * mul)) - effectData.radius) / (effectData.min + effectData.max) -
                (effectData.duration)
            effectData.duration = math.min(effectData.duration + random.GetBetween(0, magnitude), config.enchantment.effects.maxDuration)

        elseif not isConstant and effect.rangeType ~= tes3.effectRange.self then
            local mul = effect.rangeType == tes3.effectRange.target and 1.5 or 1
            local magnitude = (40 * (effectCost + stepPow) / (baseCost * mul)) - (effectData.min + effectData.max) * (effectData.duration) -
                effectData.radius
            effectData.radius = math.min(effectData.radius + random.GetBetween(0, magnitude), config.enchantment.effects.maxRadius)

        end
        if (effect.rangeType == tes3.effectRange.self and magicEffect.isHarmful) or
                (effect.rangeType ~= tes3.effectRange.self and not magicEffect.isHarmful) then
            enchVal = enchVal - ((isConstant and effectLib.calculateEffectCostForConstant(effectData, mulForConst) or
                effectLib.calculateEffectCost(effectData)) - effectCost)
        else
            enchVal = enchVal + ((isConstant and effectLib.calculateEffectCostForConstant(effectData, mulForConst) or
                effectLib.calculateEffectCost(effectData)) - effectCost)
        end
        ::continue::
    end

    for i = 1, addedCount do
        local data = effs[i]
        if data then
            local effect = effects[i]
            effect.min = math.ceil(data.min)
            effect.max = math.ceil(data.max)
            effect.duration = math.ceil(data.duration)
            effect.radius = math.ceil(data.radius)
            log("id %s min %s max %s dur %s r %s", tostring(effect.id), tostring(effect.min), tostring(effect.max), tostring(effect.duration), tostring(effect.radius))
        end
    end
end

local enchantLastRand = {}

--cannot randomise more than once every 2 seconds for an enchantment
function this.randomizeEnchantment(enchantment, enchType, power, canBeUsedOnce, effectCount, preferValue, config)
    if enchantment then
        local time = enchantLastRand[enchantment.id]
        if not time then
            enchantLastRand[enchantment.id] = os.time()
        elseif time > os.time() + 1 then
            return enchantment
        else
            enchantLastRand[enchantment.id] = os.time()
        end
    end
    local isConstant = enchType == tes3.enchantmentType.constant
    local enchPower = (isConstant or enchType == tes3.enchantmentType.castOnce or canBeUsedOnce) and power or
        power / random.GetBetween(config.enchantment.numberOfCasts.min, config.enchantment.numberOfCasts.max)
    if enchPower < 1 then enchPower = 1 end
    if not isConstant and enchPower > config.enchantment.cost.max then enchPower = config.enchantment.cost.max end
    local chargeCost
    local maxCharge
    if not isConstant then
        chargeCost = math.floor(enchPower)
        if chargeCost < 1 then chargeCost = 1 end
        maxCharge = math.floor(power)
        maxCharge = math.max(maxCharge, 1)
    end
    local newEnch = enchantment ~= nil and enchantment or
        tes3.createObject{id = enchPrefix..tostring(this.getUniqueId()), objectType = tes3.objectType.enchantment,
        castType = enchType, chargeCost = chargeCost, maxCharge = maxCharge}
    log("Enchantment randomization id %s type %i maxCharge %s charge %s", tostring(newEnch), enchType, tostring(power), tostring(enchPower))
    newEnch.maxCharge = power
    local effCount = math.random(1, effectCount or config.enchantment.effects.maxCount)
    local thresholdVal = enchPower * config.enchantment.effects.threshold
    local oneType = config.enchantment.effects.oneTypeChance > math.random()
    local effGroup_p
    local effGroup_n
    local rangeType
    if oneType or isConstant then
        rangeType, effGroup_p, effGroup_n = chooseGroup(enchType, isConstant)
    end

    this.randomizeEffects(newEnch.effects, {
        effectCount = effCount,
        thresholdValue = thresholdVal,
        oneType = oneType,
        rangeType = rangeType,
        effGroup_p = effGroup_p,
        effGroup_n = effGroup_n,
        enchantmentType = enchType,
        isConstant = isConstant,
        power = enchPower,
        strongThreshold = false,
        preferValue = preferValue,
    }, config)

    return newEnch
end

function this.randomizeStats(object, minMul, maxMul, weaponMin, weaponMax, baseData)
    if not baseData then baseData = {} end
    if not minMul then minMul = this.config.item.stats.region.min end
    if not maxMul then maxMul = this.config.item.stats.region.max end
    if not weaponMin then weaponMin = this.config.item.stats.weapon.region.min end
    if not weaponMax then weaponMax = this.config.item.stats.weapon.region.max end

    local intVars = {"enchantCapacity", "armorRating", "maxCondition"}
    local floatVars_p = {"quality", "time"}
    local floatVars_n = {"weight"}
    log("Item stats id %s", tostring(object))
    if object.value then
        local value = baseData.value or object.value
        local minValue = math.min(1, value)
        object.value = math.max(minValue, object.objectType ~= tes3.objectType.clothing and math.floor(math.max(0, value * random.GetBetweenForMulDiv(minMul, maxMul))) or
            tes3.objectType.clothing and math.floor(math.min(65535, math.max(0, value * random.GetBetweenForMulDiv(minMul, maxMul)))))
        log("value %s", tostring(object.value))
    end
    for _, var in pairs(intVars) do
        if object[var] then
            local val = baseData[var] or object[var]
            object[var] = math.floor(math.max(0, val * random.GetBetweenForMulDiv(minMul, maxMul)))
            log("%s %s", var, tostring(object[var]))
        end
    end
    for _, var in pairs(floatVars_p) do
        if object[var] then
            local val = baseData[var] or object[var]
            object[var] = math.max(0, val * random.GetBetweenForMulDiv(minMul, maxMul))
            log("%s %s", var, tostring(object[var]))
        end
    end
    for _, var in pairs(floatVars_n) do
        if object[var] then
            local div = random.GetBetweenForMulDiv(minMul, maxMul)
            if div == 0 then div = 0.05 end
            local val = baseData[var] or object[var]
            object[var] = math.max(0, val / div)
            log("%s %s", var, tostring(object[var]))
        end
    end
    if object.speed then
        local speed = baseData.speed or object.speed
        object.speed = math.max(0, speed * random.GetBetweenForMulDiv(weaponMin, weaponMax))
    end
    if object.chopMin then
        local chopMin = baseData.chopMin or object.chopMin
        local chopMax = baseData.chopMax or object.chopMax
        object.chopMin = math.min(65535, math.max(0, chopMin * random.GetBetweenForMulDiv(weaponMin, weaponMax)))
        object.chopMax = math.min(65535, math.max(0, chopMax * random.GetBetweenForMulDiv(weaponMin, weaponMax)))
        if object.chopMax < object.chopMin then object.chopMax = object.chopMin end
        log("chop %s %s", tostring(object.chopMin), tostring(object.chopMax))
    end
    if object.slashMin then
        local slashMin = baseData.slashMin or object.slashMin
        local slashMax = baseData.slashMax or object.slashMax
        object.slashMin = math.min(65535, math.max(0, slashMin * random.GetBetweenForMulDiv(weaponMin, weaponMax)))
        object.slashMax = math.min(65535, math.max(0, slashMax * random.GetBetweenForMulDiv(weaponMin, weaponMax)))
        if object.slashMax < object.slashMin then object.slashMax = object.slashMin end
        log("slash %s %s", tostring(object.slashMin), tostring(object.slashMax))
    end
    if object.thrustMin then
        local thrustMin = baseData.thrustMin or object.thrustMin
        local thrustMax = baseData.thrustMax or object.thrustMax
        object.thrustMin = math.min(65535, math.max(0, thrustMin * random.GetBetweenForMulDiv(weaponMin, weaponMax)))
        object.thrustMax = math.min(65535, math.max(0, thrustMax * random.GetBetweenForMulDiv(weaponMin, weaponMax)))
        if object.thrustMax < object.thrustMin then object.thrustMax = object.thrustMin end
        log("thrust %s %s", tostring(object.thrustMin), tostring(object.thrustMax))
    end
    if object.color then
        object.color[1] = math.floor(255 * math.random())
        object.color[2] = math.floor(255 * math.random())
        object.color[3] = math.floor(255 * math.random())
        log("color %s %s %s", tostring(object.color[1]), tostring(object.color[2]), tostring(object.color[3]))
    end
end

---@class mwr.item.randomizeBaseItem.params
---@field itemsData mwr.itemStatsData|nil
---@field createNewItem boolean|nil
---@field modifiedFlag boolean|nil unused
---@field effectCount integer|nil
---@field enchCost number|nil
---@field newEnchValue number|nil

---@param params mwr.item.randomizeBaseItem.params
function this.randomizeBaseItem(object, params)
    local itemsData = (params and params.itemsData) or this.data

    if object == nil or itemsData == nil then return end

    local createNewItem = params.createNewItem or false
    local modifiedFlag = params.modifiedFlag or false
    local effectCount = params.effectCount or math.random(1, this.config.item.enchantment.effects.maxCount)
    local enchCost = params.enchCost
    local newEnchValue = params.newEnchValue

    log("Base object randomization %s", tostring(object))

    if generator.itemTypeWhiteList[object.objectType] then

        this.storage.saveItem(object, nil, true)

        local baseData = this.storage.getItemData(object.id, true)

        local newBase = createNewItem and object:createCopy{id = itemPrefix..tostring(this.getUniqueId())} or object
        if createNewItem and newBase.enchantment then
            newBase.enchantment = nil
        end

        if this.config.item.stats.randomize then
            this.randomizeStats(newBase, nil, nil, nil, nil, baseData)
        end

        if not newEnchValue then
            newEnchValue = baseData.enchantCapacity or object.enchantCapacity
            if newEnchValue == 0 and object.objectType == tes3.objectType.book then
                newEnchValue = this.config.item.enchantment.scrollBase
            end
        else
            newEnchValue = math.max(this.config.item.enchantment.cost.min, newEnchValue)
        end

        this.randomizeBaseItemVisuals(newBase, itemsData)

        local preferValue = false
        local addEnch = this.config.item.enchantment.add.chance > math.random()
        local removeEnch = this.config.item.enchantment.remove.chance > math.random() and
            not (this.config.item.enchantment.remove.exceptScrolls and object.objectType == tes3.objectType.book)

        if (this.config.item.enchantment.randomize or (object.enchantment == nil and addEnch) or (object.enchantment and removeEnch)) and
                (this.itemTypeForEnchantment[object.objectType] or this.itemTypeForEffects[object.objectType]) and
                (object.objectType ~= tes3.objectType.book or object.type == tes3.bookType.scroll) and
                not (this.config.item.enchantment.exceptAlchemy and object.objectType == tes3.objectType.alchemy) and
                not (this.config.item.enchantment.exceptScrolls and object.objectType == tes3.objectType.book) and
                not (this.config.item.enchantment.exceptIngredient and object.objectType == tes3.objectType.ingredient) then
            local newEnch = object.enchantment
            local enchPower = enchCost or 0
            if this.config.item.unique and (not object.script or this.config.item.uniqueScriptItems) then
                newEnch = nil
            end
            if newEnch ~= nil then
                if removeEnch then
                    newEnch = nil
                    enchPower = -1
                else
                    if enchCost == nil then
                        enchCost = effectLib.getEffectsPower(newEnch.effects)
                    end
                end

            elseif addEnch then
                enchPower = (newEnchValue or 1) *
                    random.GetBetween(this.config.item.enchantment.add.region.min, this.config.item.enchantment.add.region.max)
            end

            if enchPower > 0 or this.itemTypeForEffects[object.objectType] then
                if this.itemTypeForEffects[object.objectType] and object.effects then
                    if object.objectType == tes3.objectType.ingredient then
                        local effGroup = effectLib.effectsData.forEnchant[tes3.effectRange.self]
                        local addedEff = {}
                        local effCOunt = math.random(math.floor(this.config.item.enchantment.effects.ingredient.count.min),
                            math.floor(this.config.item.enchantment.effects.ingredient.count.max))
                        for i = 1, 4 do
                            if i <= effCOunt then
                                local id = math.random(1, #effGroup)
                                while addedEff[id] do
                                    id = math.random(1, #effGroup)
                                end
                                object.effects[i] = id
                                addedEff[id] = true
                                local magEff = effectLib.effectsData.effect[id]
                                object.effectSkillIds[i] = magEff.targetsSkills and math.random(0, 26) or -1
                                object.effectAttributeIds[i] = magEff.targetsAttributes and math.random(0, 7) or -1
                            else
                                object.effects[i] = -1
                            end
                        end
                    else
                        this.randomizeEffects(object.effects, {
                            effectCount = math.random(math.floor(this.config.item.enchantment.effects.alchemyCount.min),
                                math.floor(this.config.item.enchantment.effects.alchemyCount.max)),
                            thresholdValue = enchPower * this.config.item.enchantment.effects.threshold,
                            oneType = true,
                            rangeType = tes3.effectRange.self,
                            effGroup_p = effectLib.effectsData.forEnchant.positive[tes3.effectRange.self],
                            effGroup_n = effectLib.effectsData.forEnchant.negative[tes3.effectRange.self],
                            enchantmentType = tes3.enchantmentType.castOnce,
                            isConstant = false,
                            power = enchPower,
                            strongThreshold = false,
                            isAlchemy = true,
                        }, this.config.item)
                    end
                else
                    enchPower = ((newEnch and newEnch.castType ~= tes3.enchantmentType.constant) and newEnch.maxCharge or enchPower) *
                        random.GetBetween(this.config.item.enchantment.region.min, this.config.item.enchantment.region.max)
                    local enchType = object.objectType == tes3.objectType.weapon and tes3.enchantmentType.onStrike or math.random(2, 3)
                    local usedOnce = false
                    if object.objectType == tes3.objectType.weapon or object.objectType == tes3.objectType.ammunition then
                        if object.isProjectile or object.isAmmo then
                            enchType = tes3.enchantmentType.onStrike
                            enchPower = enchPower * this.config.item.enchantment.arrowPower
                            usedOnce = true
                        elseif object.isRanged then
                            enchType = math.random(2, 3)
                        else
                            enchType = math.random(1, 3)
                        end
                        if enchType == tes3.enchantmentType.onStrike then preferValue = true end
                    elseif object.objectType == tes3.objectType.book then
                        enchType = tes3.enchantmentType.castOnce
                    else
                        enchType = math.random(2, 3)
                    end

                    if this.config.item.enchantment.useExisting and not this.config.item.unique then
                        local group = itemsData.enchantments.Groups[enchType]
                        if group then
                            local itemPos
                            if newEnch then
                                itemPos = itemsData.enchantments.Items[newEnch.id:lower()]
                            end
                            if not itemPos then
                                itemPos = math.floor(#group.Items * math.min(1, newEnchValue / group.Max95))
                            end
                            local pos = random.GetRandom(itemPos, #group.Items,
                                this.config.item.enchantment.existing.region.min, this.config.item.enchantment.existing.region.max)
                            newEnch = tes3.getObject(group.Items[pos] or "err")
                            if enchType == tes3.enchantmentType.constant and this.config.item.enchantment.effects.safeMode and
                                    this.isEnchantContainsForbiddenEffect(newEnch) then
                                newEnch = nil
                            end
                        end
                    else
                        newEnch = this.randomizeEnchantment(newEnch, enchType, enchPower, usedOnce, effectCount, preferValue, this.config.item)
                    end
                    -- if newEnch then newEnch.modified = modifiedFlag end
                end
            end
            if newEnch then tes3.setSourceless(newEnch, true) end
            if this.itemTypeForEnchantment[object.objectType] then newBase.enchantment = newEnch end
        end
        tes3.setSourceless(newBase, true)
        this.storage.saveItem(newBase, object.id)
        -- newBase.modified = modifiedFlag
        return newBase
    end
    return nil
end

---@return boolean, string|nil
function this.isItemWasCreated(id)
    local data = this.storage.getItemData(id)
    if data then
        return data.created, data.originalId
    end
    return false, nil
end

---@param itemsData mwr.itemStatsData
function this.randomizeBaseItemVisuals(item, itemsData)
    local meshChanged = false
    if item.parts and this.config.item.changeParts then
        local objSubType
        if item.type then
            objSubType = item.type
        elseif item.slot then
            objSubType = item.slot
        end
        local partsData = itemsData.parts[item.objectType][objSubType][math.random(1, #itemsData.parts[item.objectType][objSubType])]
        if partsData then
            for pos = 1, #item.parts do
                local newPartData = partsData.parts[pos]
                local part = item.parts[pos]
                if newPartData then
                    log("Item part %s %s %s %s", tostring(item), tostring(newPartData[1]), tostring(newPartData[2]), tostring(newPartData[3]))
                    part.type = newPartData[1]
                    part.female = newPartData[2] and tes3.getObject(newPartData[2]) or nil
                    part.male = newPartData[3] and tes3.getObject(newPartData[3]) or nil
                else
                    part.type = 255
                    part.female = nil
                    part.male = nil
                end
            end
            if this.config.item.linkMeshToParts then
                item.mesh = partsData.mesh
                log("Item mesh %s %s", tostring(item), tostring(item.mesh))
                meshChanged = true
            end
        end
    end
    if item.mesh and this.config.item.changeMesh and not meshChanged then
        local meshes
        local dt = itemsData.itemGroup[item.objectType]
        if item.objectType == tes3.objectType.weapon then
            if item.type == tes3.weaponType.marksmanBow and dt.bowMeshes then
                meshes = dt.bowMeshes
            elseif item.type == tes3.weaponType.marksmanCrossbow and dt.crossbowMeshes then
                meshes = dt.crossbowMeshes
            end
        elseif item.objectType == tes3.objectType.ammunition then
            if item.type == tes3.weaponType.arrow then
                meshes = dt.arrowMeshes
            elseif item.type == tes3.weaponType.bolt then
                meshes = dt.boltMeshes
            end
        else
            meshes = dt.meshes
        end
        if meshes then
            local mesh = meshes[math.random(1, #meshes)]
            item.mesh = mesh
            log("Item mesh %s %s", tostring(item), tostring(mesh))
        end
    end
end

---@return mwr.itemStatsData
function this.generateData()
    this.data = generator.generateItemData()
    return this.data
end

function this.randomizeIngredients(data)
    if not data then return end
    log("Randomization of effects for ingredients")
    local forbidden = {}
    for i = 120, 133 do forbidden[i] = true end
    local itemArr = {}
    local itCount = #data.items
    local effGroup = {}
    local effGroupDummy = {}
    for i, val in pairs(effectLib.effectsData.forEnchant[tes3.effectRange.self]) do
        if not forbidden[val] then
            table.insert(effGroupDummy, {id = val, value = effectLib.effectsData.cost[val]})
        end
    end
    table.sort(effGroupDummy, function(a, b) return a.value < b.value end)
    for _, val in pairs(effGroupDummy) do
        table.insert(effGroup, val.id)
    end

    for i, item in pairs(data.items) do
        local effCOunt = math.random(math.floor(this.config.item.enchantment.effects.ingredient.count.min),
            math.floor(this.config.item.enchantment.effects.ingredient.count.max))
        itemArr[i] = {count = effCOunt, effects = {}, id = item.id}
    end

    local effCount = #effGroup

    local itNormalizedMul = itCount / effCount
    for i, effId in pairs(effGroup) do
        local magicEffect = effectLib.effectsData.effect[effId]
        local normalizedPos = math.floor(i * itNormalizedMul)
        local count = 1
        if magicEffect.targetsSkills then
            goto continue
            -- count = 27
        elseif magicEffect.targetsAttributes then
            count = 8
        end
        for j = 1, count do
            local skillId = magicEffect.targetsSkills and j - 1 or -1
            local attrId = magicEffect.targetsAttributes and j - 1 or -1
            local effAltId = string.format("%s%02d%02d", effId, attrId, skillId)
            for k = 1, this.config.item.enchantment.effects.ingredient.minimumIngrForOneEffect do
                local pos = random.GetRandom(normalizedPos, itCount, this.config.item.enchantment.effects.ingredient.region.min,
                    this.config.item.enchantment.effects.ingredient.region.max)
                local iteration = 0
                while (itemArr[pos].count <= 0 or itemArr[pos].effects[effAltId]) and iteration < itCount do
                    pos = pos + 1
                    if pos > itCount then pos = 1 end
                    iteration = iteration + 1
                end
                if iteration < 40 then
                    itemArr[pos].count = itemArr[pos].count - 1
                    itemArr[pos].effects[effAltId] = {id = effId, attr = attrId, skill = skillId}
                else
                    log("Cannot find an item for %s", effAltId)
                end
            end
        end
        ::continue::
    end

    local effNormalizedMul = effCount / itCount
    for i, itData in pairs(itemArr) do
        if itData.count > 0 then
            for j = 1, itData.count do
                local normalizedPos = math.floor(i * effNormalizedMul)
                local pos = random.GetRandom(normalizedPos, effCount, this.config.item.enchantment.effects.ingredient.region.min,
                    this.config.item.enchantment.effects.ingredient.region.max)
                local iteration = 0
                while itData.effects[effGroup[pos]] and iteration < 30 do
                    pos = random.GetRandom(normalizedPos, effCount, this.config.item.enchantment.effects.ingredient.region.min,
                        this.config.item.enchantment.effects.ingredient.region.max)
                    iteration = iteration + 1
                end
                if iteration < 20 then
                    local effId = effGroup[pos]
                    local magicEffect = effectLib.effectsData.effect[effId]
                    local skillId = magicEffect.targetsSkills and math.random(0, 26) or -1
                    local attrId = magicEffect.targetsAttributes and math.random(0, 7) or -1
                    local effAltId = string.format("%s%02d%02d", effId, attrId, skillId)
                    itData.effects[effAltId] = {id = effId, attr = attrId, skill = skillId}
                else
                    log("Cannot add an effect to %s", tostring(itData.id))
                end
            end
            itData.count = 0
        end
    end

    for _, itData in pairs(itemArr) do
        local object = tes3.getObject(itData.id)
        if object and object.effects then
            local count = 0
            for _, effData in pairs(itData.effects) do
                count = count + 1
                if count <= 4 then
                    object.effects[count] = effData.id
                    object.effectSkillIds[count] = effData.skill
                    object.effectAttributeIds[count] = effData.attr
                end
            end
            for i = count + 1, 4 do
                object.effects[i] = -1
            end

            if this.config.item.stats.randomize then
                this.randomizeStats(object, this.config.item.stats.region.min, this.config.item.stats.region.max)
            end

            this.storage.saveItem(object)
        end
    end
    log("Done effects %s items %s", tostring(effCount), tostring(itCount))
end

function this.randomizeItems(itemsData)
    local plData = dataSaver.getObjectData(tes3.player)
    if plData then
        plData.hasRandomizedItemStats = true
        if this.config.item.changeMesh then plData.hasRandomizedItemMeshes = true end
    end

    for itType, data in pairs(itemsData.itemGroup) do
        if itType == tes3.objectType.ingredient then
            if this.config.item.enchantment.effects.ingredient.smartRandomization and
                    not this.config.item.enchantment.exceptIngredient then
                this.randomizeIngredients(data)
            end
        else
            local count = #data.items
            for i, item in pairs(data.items) do
                if this.config.item.unique and this.itemTypeForUnique[itType] and (not item.script or this.config.item.uniqueScriptItems) then
                    goto continue
                end
                if item.objectType == tes3.objectType.book and item.enchantment == nil then goto continue end
                local enchVal = data.enchantValues[item.id]
                local mul = (i / count) ^ this.config.item.enchantment.powMul
                local encCount = math.max(1, this.config.item.enchantment.effects.maxCount * (mul ^ this.config.item.enchantment.effects.countPowMul))
                local meshes = data.meshes
                if itType == tes3.objectType.weapon then
                    if item.type == tes3.weaponType.marksmanBow and data.bowMeshes then
                        meshes = data.bowMeshes
                    elseif item.type == tes3.weaponType.marksmanCrossbow and data.crossbowMeshes then
                        meshes = data.crossbowMeshes
                    end
                end

                this.randomizeBaseItem(item, {itemsData = itemsData, createNewItem = false, modifiedFlag = false, effectCount = encCount, enchCost = enchVal,
                    newEnchValue = mul * math.min(this.config.item.enchantment.minMaximumGroupCost, data.enchant95)})
                ::continue::
            end
        end
    end
end

---@deprecated
function this.restoreItems()
    local plData = dataSaver.getObjectData(tes3.player)
    if plData and plData.newObjects and plData.newObjects.items then
        for id, data in pairs(plData.newObjects.items) do
            -- local object = tes3.getObject(id)
            -- this.storage.saveItem(object)
            this.storage.addItemData(id, data)
            if data.enchantment then
                this.storage.restoreEnchantment(data.enchantment.id)
            end
            this.storage.restoreItem(id, false)
        end
        plData.newObjects.items = nil
    end
    -- this.storage.restoreAllItems()
end

---@deprecated
function this.resetItemStorage()
    local plData = dataSaver.getObjectData(tes3.player)
    if plData then
        plData.newObjects = nil
        plData.hasRandomizedItemStats = false
        plData.hasRandomizedItemMeshes = false
    end
end

function this.clearFixedCellList()
    local data = dataSaver.getObjectData(tes3.player)
    if data then
        data.fixedCellList = {}
    end
end

function this.fixItemData(itemData, item)
    if not itemData or not item then return end
    if item.enchantment and (itemData.charge == -1 or itemData.charge > item.enchantment.maxCharge) then
        itemData.charge = item.enchantment.maxCharge
    end
    if item.maxCondition and itemData.condition and itemData.condition > item.maxCondition then
        itemData.condition = item.maxCondition
    end
end

function this.hasRandomizedItems()
    local plData = dataSaver.getObjectData(tes3.player)
    if plData and plData.hasRandomizedItemStats then
        return true
    end
    return false
end

function this.hasRandomizedMeshes()
    local plData = dataSaver.getObjectData(tes3.player)
    if plData and plData.hasRandomizedItemMeshes then
        return true
    end
    return false
end

function this.fixInventory(inventory)
    if not inventory then return end
    for stack, item, count, itemData in this.iterItems(inventory) do
        if stack.count > 0 then
            this.fixItemData(itemData, item)
        end
    end
end

local function getZ(vector, root, ignore, disatance)
    local res = tes3.rayTest {
        position = vector,
        direction = tes3vector3.new(0, 0, -1),
        observeAppCullFlag  = true,
        root = root,
        useBackTriangles = true,
        maxDistance = disatance or 100,
        ignore = ignore,
    }
    if res then return res.intersection.z end
    log("Ray tracing failed %s %s %s", tostring(vector.x), tostring(vector.y), tostring(vector.z))
    return nil
end

---@param cell tes3cell
---@param updateModels boolean|nil
---@param force boolean|nil
function this.fixCell(cell, updateModels, force)
    local plData = dataSaver.getObjectData(tes3.player)
    if not plData then return end
    if not plData.fixedCellList then plData.fixedCellList = {} end

    if not force and plData.fixedCellList[cell.editorName] then return end

    for ref in cell:iterateReferences() do
        local data = dataSaver.getObjectData(ref)
        if not (data ~= nil and data.stopRand == true) then
            if ref.object and ref.object.inventory then
                this.fixInventory(ref.object.inventory)
            end
            if this.storage.getItemData(ref.baseObject.id) then
                if this.config.item.tryToFixZCoordinate then
                    local boundingBox = ref.baseObject.boundingBox
                    if not boundingBox then
                        local ms = tes3.loadMesh(ref.baseObject.mesh)
                        boundingBox = ms:createBoundingBox()
                    end
                    if boundingBox then
                        local offset = math.max(20, boundingBox.max.z * ref.scale)
                        local topPos = tes3vector3.new(ref.position.x, ref.position.y, ref.position.z + offset)
                        local z = getZ(topPos, tes3.game.worldObjectRoot, {ref}, 50 + offset)
                        local zBox = boundingBox.min.z * ref.scale
                        if z then
                            ref.position = tes3vector3.new(ref.position.x, ref.position.y, z - zBox + 0.1)
                            if ref.orientation.x > 1 or ref.orientation.y > 1 then
                                ref.orientation = tes3vector3.new(0, 0, ref.orientation.z)
                            end
                            log("Position fixed %s", tostring(ref))
                        end
                    end
                end
                this.fixItemData(ref.itemData, ref.baseObject)
            end
            if updateModels and ref.object.objectType == tes3.objectType.npc then
                ref:updateEquipment()
            end
        end
    end
    plData.fixedCellList[cell.editorName] = true
    log("Cell fixed %s", tostring(cell.editorName))
end

function this.fixPlayerInventory(updateModels)
    local player = tes3.mobilePlayer
    if player then
        for stack, item, count, itemData in this.iterItems(player.inventory) do
            this.fixItemData(itemData, item)
        end
        if updateModels then
            tes3.player:updateEquipment()
            tes3.updateInventoryGUI{ reference = tes3.player }
        end
        local objTypes = {[tes3.objectType.armor] = 10, [tes3.objectType.clothing] = 9, [tes3.objectType.weapon] = 13}
        for objType, maxId in pairs(objTypes) do
            for i = 0, maxId do
                local equipped = tes3.getEquippedItem{actor = player, slot = objType ~= tes3.objectType.weapon and i or nil,
                    type = objType == tes3.objectType.weapon and i or nil}
                if equipped and equipped.object and equipped.itemData then
                    local id = equipped.object.id
                    local itData = {charge = equipped.itemData.charge, condition = equipped.itemData.condition}
                    player:unequip{item = equipped.object, itemData = equipped.itemData}
                    local found = false
                    for stack, item, count, itemData in this.iterItems(player.inventory) do
                        if item.id == id and itemData and itemData.charge == itData.charge and itemData.condition == itData.condition then
                            found = true
                            player:equip{item = tes3.getObject(id), itemData = itemData}
                        end
                    end
                    if not found then
                        player:equip{item = tes3.getObject(id)}
                    end
                end
            end
        end
        log("Player inventory fixed")
    end
end

function this.isObjectFixRequired()
    if this.hasRandomizedMeshes() or this.config.item.unique then
        return true
    end
    return false
end

--thanks Hrnchamd#5205 from https://discord.com/channels/210394599246659585/381219559094616064/1088059018448211979
function this.fixPlayerWeight()
	local burden = tes3.getEffectMagnitude{reference = tes3.mobilePlayer, effect = tes3.effect.burden}
	local feather = tes3.getEffectMagnitude{reference = tes3.mobilePlayer, effect = tes3.effect.feather}
	local weight = tes3.player.object.inventory:calculateWeight() + burden - feather
	local oldWeight = tes3.mobilePlayer.encumbrance.currentRaw

	if (math.abs(oldWeight - weight) > 0.01) then
        tes3.mobilePlayer.encumbrance.current = weight
		-- tes3.setStatistic{reference = tes3.mobilePlayer, name = "encumbrance", current = weight}
	end
end

---@return string|nil, tes3.enchantmentType|nil #enchant Id and cast type
function this.setDummyEnchantment(item)
    if not item then return nil, nil end
    local id
    local castType
    if item.objectType == tes3.objectType.weapon and not item.isRanged then
        id = this.dummyStrikeEnchId
        castType = tes3.enchantmentType.onStrike
    else
        id = this.dummyConstEnchId
        castType = tes3.enchantmentType.constant
    end
    item.enchantment = tes3.getObject(id)
    return id, castType
end

return this