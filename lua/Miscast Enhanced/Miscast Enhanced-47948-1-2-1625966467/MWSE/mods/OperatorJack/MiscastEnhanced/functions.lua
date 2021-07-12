local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
local config = require("OperatorJack.MiscastEnhanced.config")

local schoolHandlers = {}
local effectHandlers = {}

local potions = {
    ["OJ_MIS_InverseEffectPotion"] = "OJ_MIS_InverseEffectPotion",
    ["OJ_MIS_StandardEffectPotion"] = "OJ_MIS_StandardEffectPotion",
    ["OJ_MIS_BoundItemEffectPotion"] = "OJ_MIS_BoundItemEffectPotion"
}

local locations = {}
local function onInit()
    for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
        if (cell.isInterior == false) then
            locations[#locations + 1] = cell
        end
    end
end
event.register("initialized", onInit)

local functions = {}
functions.isDebug = function()
    return config.debugMode == true
end

functions.gatedMessageBox = function(message)
    if (config.showMessages == true) then
        tes3.messageBox(message)
    end
end
functions.getRandomLocation = function()
    local cell = locations[math.random(#locations)]
    local position = {
        (cell.gridX * 2 + 1) * 4096,
        (cell.gridY * 2 + 1) * 4096,
        0
    }
    return cell, position
end
functions.getModifier = function()
    return math.random(25, 50) / 100
end
functions.getModifiedMagnitudeFromEffect = function(effect)
    if (effect.max == 0) then
        return 0
    end
    local baseMagnitude = math.random(effect.min, effect.max)
    return math.ceil(baseMagnitude * functions.getModifier())
end
functions.getModifiedDurationFromEffect = function(effect)
    if (effect.duration == 0) then
        return 0
    end
    local duration =  math.ceil(math.random(1, effect.duration) * functions.getModifier())
    if (duration < 3) then
        duration = 3
    end
    return duration
end
functions.getModifiedRadiusFromEffect = function(effect)
    if (effect.radius == 0) then
        return 0
    end
    return math.ceil(math.random(1, effect.radius) * functions.getModifier())
end
functions.getInvertedRangeTypeFromEffect = function(effect)
    if (effect.rangeType == tes3.effectRange.self) then
        return tes3.effectRange.target
    end
    return tes3.effectRange.self
end
functions.getInvertedAttributesFromEffect
 = function(effect)
    local magnitude = functions.getModifiedMagnitudeFromEffect(effect)
    local duration = functions.getModifiedDurationFromEffect(effect)
    local radius = functions.getModifiedRadiusFromEffect(effect)
    local rangeType = functions.getInvertedRangeTypeFromEffect(effect)
    return magnitude, duration, radius, rangeType
end
functions.getStandardAttributesFromEffect
 = function(effect)
    local magnitude = functions.getModifiedMagnitudeFromEffect(effect)
    local duration = functions.getModifiedDurationFromEffect(effect)
    local radius = functions.getModifiedRadiusFromEffect(effect)
    local rangeType = effect.rangeType
    return magnitude, duration, radius, rangeType
end

functions.handlers = {}
functions.handlers.genericInverseEffectHandler = function(params)
    local effectIdToUse = params.effectIdToUse
    local magnitude, duration, radius, rangeType = functions.getInvertedAttributesFromEffect(params.effect)

    local potion = framework.alchemy.createBasicPotion({
        id = potions.OJ_MIS_InverseEffectPotion,
        name = "Miscast",

        effect = effectIdToUse,
        min = magnitude,
        max = magnitude,
        duration = duration,
        radius = radius,
        range = rangeType,

        skill = params.effect.skill,
        attribute = params.effect.attribute
    })

    tes3.applyMagicSource({
        reference = params.reference,
        source = potion,
        castChance = 100,
    })
end
functions.handlers.genericStandardEffectHandler = function(params)
    local effectIdToUse = params.effectIdToUse
    local magnitude, duration, radius, rangeType = functions.getStandardAttributesFromEffect(params.effect)

    local potion = framework.alchemy.createBasicPotion({
        id = potions.OJ_MIS_StandardEffectPotion,
        name = "Miscast",

        effect = effectIdToUse,
        min = magnitude,
        max = magnitude,
        duration = duration,
        radius = radius,
        range = rangeType,

        skill = params.effect.skill,
        attribute = params.effect.attribute
    })

    tes3.applyMagicSource({
        reference = params.reference,
        source = potion,
        castChance = 100,
    })
end
functions.handlers.genericSummoningEffectHandler = function(params)
    local creatureIdToUse = params.creatureIdToUse
    local duration = functions.getModifiedDurationFromEffect(params.effect)

    if (duration < 5) then
        duration = 5
    end

    local caster = params.reference
    local cell = caster.cell

    local e = caster.orientation
    local m = tes3matrix33.new()
    m:fromEulerXYZ(e.x, e.y, e.z)
    local vector = m:transpose().y
    local orientation = caster.orientation
    local position = caster.position - (vector * 10)

    local creature = tes3.createReference({
        object = creatureIdToUse,
        cell = cell,
        orientation = orientation,
        position = position
    })
    creature.modified = false

    mwscript.startCombat({
        reference = creature,
        target = caster
    })

    timer.start({
        duration = duration,
        callback = function()
            creature:disable()
            timer.delayOneFrame({
                callback = function()
                    creature.deleted = true
                end
            })
        end
    })
end
functions.handlers.genericBoundItemHandler = function(params)
    local magnitude, duration, radius, rangeType = functions.getStandardAttributesFromEffect(params.effect)
    local drainMagnitudeMin = math.floor(duration / 20)
    local drainMagnitudeMax = math.floor(duration / 10)
    if (drainMagnitudeMin < 5) then drainMagnitudeMin = 5 end
    if (drainMagnitudeMax < 10) then drainMagnitudeMax = 10 end

    local potion = framework.alchemy.createComplexPotion({
        id = potions.OJ_MIS_BoundItemEffectPotion,
        name = "Miscast",
        effects = {
            [1] = {
                id = params.effect.id,
                min = magnitude,
                max = magnitude,
                duration = duration,
                radius = radius,
                range = rangeType
            },
            [2] = {
                id = tes3.effect.damageHealth,
                min = drainMagnitudeMin,
                max = drainMagnitudeMax,
                duration = duration,
                radius = radius,
                range = tes3.effectRange.self
            }
        }
    })

    tes3.applyMagicSource({
        reference = params.reference,
        source = potion,
        castChance = 100,
    })
end
functions.handlers.genericCureEffectHandler = function(params)
    local effectIdToUse = params.effectIdToUse
    local radius = functions.getModifiedRadiusFromEffect(params.effect)
    local rangeType = params.effect.rangeType
    local magnitude = math.random(80, 100)
    local duration = math.random(30,60)

    local potion = framework.alchemy.createBasicPotion({
        id = potions.OJ_MIS_StandardEffectPotion,
        name = "Miscast",

        effect = effectIdToUse,
        min = magnitude,
        max = magnitude,
        duration = duration,
        radius = radius,
        range = rangeType
    })

    tes3.applyMagicSource({
        reference = params.reference,
        source = potion,
        castChance = 100,
    })
end
functions.handlers.genericTeleportEffectHandler = function(params)
    local cell, position = functions.getRandomLocation()
    tes3.positionCell({
        reference = params.reference,
        cell = cell,
        position = position
    })
end
functions.handlers.genericAreaEffectHandler = function(params)
    local distance = params.distance
    local actors = framework.functions.getActorsNearTargetPosition(params.reference.cell, params.reference.position, distance)

    for _, actor in pairs(actors) do
        functions.handlers.genericStandardEffectHandler({
            effectIdToUse = params.effectIdToUse,
            effect = params.effect,
            reference = actor
        })
    end
end

functions.getSchoolHandler = function(schoolId)
    return schoolHandlers[schoolId]
end

functions.setSchoolHandler = function(schoolId, handler)
    if (schoolHandlers[schoolId]) then
        mwse.log("[Miscast Enhanced] Warning! School handler already exists. Subsequent school handlers will not be used. School ID %s.", schoolId)
        return false
    end

    schoolHandlers[schoolId] = handler
    return true
end

functions.getEffectHandler = function(effectId)
    return effectHandlers[effectId]
end

functions.setEffectHandler = function(effectId, handler)
    if (effectHandlers[effectId]) then
        mwse.log("[Miscast Enhanced] Warning! Effect handler already exists. Subsequent effect handlers will not be used. Effect ID %s.", effectId)
        return false
    end

    effectHandlers[effectId] = handler
    return true
end
return functions