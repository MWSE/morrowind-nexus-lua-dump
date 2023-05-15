local this = {}

this.effectsData = {
    effect = {},
    byRange = {
        [tes3.effectRange.self] = {},
        [tes3.effectRange.target] = {},
        [tes3.effectRange.touch] = {},
    },
    forEnchant = {
        [tes3.effectRange.self] = {},
        [tes3.effectRange.target] = {},
        [tes3.effectRange.touch] = {},
        positive = {[tes3.effectRange.self] = {}, [tes3.effectRange.target] = {}, [tes3.effectRange.touch] = {}, hasDuration = {}, hasMagnitude = {}, selfMagnitude = {}},
        negative = {[tes3.effectRange.self] = {}, [tes3.effectRange.target] = {}, [tes3.effectRange.touch] = {}, hasDuration = {}, hasMagnitude = {}, selfMagnitude = {}}
    },
    forSpell = {
        [tes3.effectRange.self] = {},
        [tes3.effectRange.target] = {},
        [tes3.effectRange.touch] = {},
        positive = {[tes3.effectRange.self] = {}, [tes3.effectRange.target] = {}, [tes3.effectRange.touch] = {}, hasDuration = {}, hasMagnitude = {}, selfMagnitude = {}},
        negative = {[tes3.effectRange.self] = {}, [tes3.effectRange.target] = {}, [tes3.effectRange.touch] = {}, hasDuration = {}, hasMagnitude = {}, selfMagnitude = {}}
    },
    cost = {},
    skill = {},
    forbiddenForConstantType = {
        [14] = true,
        [15] = true,
        [16] = true,
        [18] = true,
        [22] = true,
        [23] = true,
        [24] = true,
        [25] = true,
        [26] = true,
        [27] = true,
        [132] = true,
        [133] = true,
        [135] = true,
    },
}

function this.init()
    local fillEffGroup = function(effect, group)
        if effect.canCastSelf then
            table.insert(group[tes3.effectRange.self], effect.id)
            if not effect.hasNoMagnitude then table.insert(group.selfMagnitude, effect.id) end
        end
        if effect.canCastTarget then table.insert(group[tes3.effectRange.target], effect.id) end
        if effect.canCastTouch then table.insert(group[tes3.effectRange.touch], effect.id) end
        if not effect.hasNoDuration then table.insert(group.hasDuration, effect.id) end
        if not effect.hasNoMagnitude then table.insert(group.hasMagnitude, effect.id) end
    end
    for id, effect in pairs(tes3.dataHandler.nonDynamicData.magicEffects) do
        this.effectsData.effect[effect.id] = effect
        this.effectsData.skill[effect.id] = effect.skill
        this.effectsData.cost[effect.id] = effect.baseMagickaCost
        if effect.canCastSelf then
            table.insert(this.effectsData.byRange[tes3.effectRange.self], effect.id)
            if effect.allowSpellmaking then table.insert(this.effectsData.forSpell[tes3.effectRange.self], effect.id) end
            if effect.allowEnchanting then table.insert(this.effectsData.forEnchant[tes3.effectRange.self], effect.id) end
        end
        if effect.canCastTouch then
            table.insert(this.effectsData.byRange[tes3.effectRange.touch], effect.id)
            if effect.allowSpellmaking then table.insert(this.effectsData.forSpell[tes3.effectRange.touch], effect.id) end
            if effect.allowEnchanting then table.insert(this.effectsData.forEnchant[tes3.effectRange.touch], effect.id) end
        end
        if effect.canCastTarget then
            table.insert(this.effectsData.byRange[tes3.effectRange.target], effect.id)
            if effect.allowSpellmaking then table.insert(this.effectsData.forSpell[tes3.effectRange.target], effect.id) end
            if effect.allowEnchanting then table.insert(this.effectsData.forEnchant[tes3.effectRange.target], effect.id) end
        end
        if effect.isHarmful then
            if not effect.appliesOnce then
                this.effectsData.forbiddenForConstantType[effect.id] = true
            end
            if effect.allowSpellmaking then
                fillEffGroup(effect, this.effectsData.forSpell.negative)
            end
            if effect.allowEnchanting then
                fillEffGroup(effect, this.effectsData.forEnchant.negative)
            end
        else
            if effect.allowSpellmaking then
                fillEffGroup(effect, this.effectsData.forSpell.positive)
            end
            if effect.allowEnchanting then
                fillEffGroup(effect, this.effectsData.forEnchant.positive)
            end
        end

    end
end

function this.calculateEffectCost(effect)
    local mul = effect.rangeType == tes3.effectRange.target and 1.5 or 1
    return mul * ((effect.min + effect.max) * (effect.duration + 1) + effect.radius) * (this.effectsData.cost[effect.id] or 1) / 40
end

function this.calculateEffectCostForConstant(effect)
    return ((effect.min + effect.max) * 100 + effect.radius) * (this.effectsData.cost[effect.id] or 1) / 40
end

return this