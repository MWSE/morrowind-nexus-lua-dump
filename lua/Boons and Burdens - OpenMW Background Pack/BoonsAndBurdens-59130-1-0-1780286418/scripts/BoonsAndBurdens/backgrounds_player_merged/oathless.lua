---@omw-context player
---@diagnostic disable: assign-type-mismatch
---@diagnostic disable: undefined-field
local I = require("openmw.interfaces")
local self = require("openmw.self")
local core = require("openmw.core")

I.CharacterTraits.addTrait {
    id = "BaB_oathless",
    type = "background",
    name = "Oathless",
    description = (
        "You never learned the full rites. Whether the training was cut short, " ..
        "the teacher unreliable, or the patience simply not there, the oaths " ..
        "were never spoken in full - and the Daedra you call upon have always known it. " ..
        "They answer readily enough; the price is low, the contract thin. " ..
        "What crosses the veil in response arrives incomplete, half-formed, " ..
        "its strength spent somewhere in the passage. You have made your peace with it.\n" ..
        "\n" ..
        "+10 Conjuration and Intelligence\n" ..
        "-10 Willpower\n" ..
        "> Summon spells refund you 66% of their cost\n" ..
        "> Your summons spawn with only 50% of health"
    ),
    doOnce = function()
        local conj = self.type.stats.skills.conjuration(self)
        conj.base = conj.base + 10
        local int = self.type.stats.attributes.intelligence(self)
        int.base = int.base + 10
        local will = self.type.stats.attributes.willpower(self)
        will.base = will.base - 10
    end,
    onLoad = function()
        core.sendGlobalEvent("BoonsAndBurdens_registerHedgeConjurer", self)

        local stopKeys = {
            ["self stop"] = true,
            ["touch stop"] = true,
            ["target stop"] = true,
        }
        local startKeys = {
            ["self start"] = true,
            ["touch start"] = true,
            ["target start"] = true,
        }
        local summonEffects = {
            [core.magic.EFFECT_TYPE.SummonAncestralGhost]    = true,
            [core.magic.EFFECT_TYPE.SummonBear]              = true,
            [core.magic.EFFECT_TYPE.SummonBonelord]          = true,
            [core.magic.EFFECT_TYPE.SummonBonewalker]        = true,
            [core.magic.EFFECT_TYPE.SummonBonewolf]          = true,
            [core.magic.EFFECT_TYPE.SummonCenturionSphere]   = true,
            [core.magic.EFFECT_TYPE.SummonClannfear]         = true,
            [core.magic.EFFECT_TYPE.SummonDaedroth]          = true,
            [core.magic.EFFECT_TYPE.SummonDremora]           = true,
            [core.magic.EFFECT_TYPE.SummonFabricant]         = true,
            [core.magic.EFFECT_TYPE.SummonFlameAtronach]     = true,
            [core.magic.EFFECT_TYPE.SummonFrostAtronach]     = true,
            [core.magic.EFFECT_TYPE.SummonGoldenSaint]       = true,
            [core.magic.EFFECT_TYPE.SummonGreaterBonewalker] = true,
            [core.magic.EFFECT_TYPE.SummonHunger]            = true,
            [core.magic.EFFECT_TYPE.SummonScamp]             = true,
            [core.magic.EFFECT_TYPE.SummonSkeletalMinion]    = true,
            [core.magic.EFFECT_TYPE.SummonStormAtronach]     = true,
            [core.magic.EFFECT_TYPE.SummonWingedTwilight]    = true,
            [core.magic.EFFECT_TYPE.SummonWolf]              = true,
        }
        local selfMagicka = self.type.stats.dynamic.magicka(self)
        local conjuration = self.type.stats.skills.conjuration(self)
        local lastConjLevel = conjuration.base
        local lastConjProgress = conjuration.progress

        local function getBaseSpellCost(spellId, isEnchant)
            local cost = 0

            local spellRecord
            if isEnchant then
                spellRecord = core.magic.enchantments.records[spellId]
            else
                spellRecord = core.magic.spells.records[spellId]
            end
            if not spellRecord then return cost end

            if not spellRecord.autocalcFlag then
                return spellRecord.cost
            end

            for _, effect in ipairs(spellRecord.effects) do
                local minMagnitude, maxMagnitude = 1, 1
                local baseEffect = effect.effect

                if baseEffect.hasMagnitude then
                    minMagnitude = effect.magnitudeMin
                    maxMagnitude = effect.magnitudeMax
                end
                if not isEnchant then
                    minMagnitude = math.max(1, minMagnitude)
                    maxMagnitude = math.max(1, maxMagnitude)
                end

                local x = baseEffect.hasDuration and effect.duration or 1
                if not baseEffect.isAppliedOnce then
                    x = math.max(x, 1)
                end
                x = x * 0.1 * baseEffect.baseCost
                x = x * 0.5 * (effect.magnitudeMin + effect.magnitudeMax)
                x = x + 0.05 * baseEffect.baseCost * effect.area
                if effect.range == core.magic.RANGE.Target then
                    x = x * 1.5
                end
                x = x * core.getGMST('fEffectCostMult')
                x = math.max(0, x)

                cost = cost + x
            end

            return cost
        end

        I.AnimationController.addTextKeyHandler('spellcast', function(groupname, key)
            if startKeys[key] then
                lastConjLevel = conjuration.base
                lastConjProgress = conjuration.progress
            elseif stopKeys[key] then
                local selectedSpell = self.type.getSelectedSpell(self)
                if not selectedSpell or selectedSpell.type ~= core.magic.SPELL_TYPE.Spell then return end

                for _, effect in ipairs(selectedSpell.effects) do
                    if not summonEffects[effect.id] then
                        return
                    end
                end

                if conjuration.base > lastConjLevel or conjuration.progress > lastConjProgress then
                    lastConjLevel = conjuration.base
                    lastConjProgress = conjuration.progress
                    selfMagicka.current = math.min(
                        selfMagicka.base + selfMagicka.modifier,
                        selfMagicka.current + getBaseSpellCost(selectedSpell.id, false) * .66
                    )
                end
            end
        end)
    end
}
