local I = require("openmw.interfaces")
local self = require("openmw.self")
local core = require("openmw.core")

local traitType = require("scripts.WretchedAndWeird.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "bloodMage",
    type = traitType,
    name = "Blood Mage",
    description = (
        "You are a diabolical Blood Mage. You've studied techniques to directly harm the life force of your victims " ..
        "rather than using elemental magic. " ..
        "Years of self-experimentation with your own blood has left you with some vulnerabilities, however.\n" ..
        "\n" ..
        "+20% Weakness to Magicka\n" ..
        "> Spells using only damage health effects recoup half their magicka cost when cast"
    ),
    doOnce = function()
        -- local selfSkills = self.type.stats.skills
        -- local selfAttrs = self.type.stats.attributes
        local selfSpells = self.type.spells(self)

        selfSpells:add("lack_ww_BloodMageWeaknesses")
        selfSpells:add("lack_ww_BloodBolt")
    end,
    onLoad = function()
        local selfMagicka = self.type.stats.dynamic.magicka(self)
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

        local destruction = self.type.stats.skills.destruction(self)
        local lastDestLevel = destruction.base
        local lastDestProgress = destruction.progress

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
                lastDestLevel = destruction.base
                lastDestProgress = destruction.progress
            elseif stopKeys[key] then
                local selectedSpell = self.type.getSelectedSpell(self)
                if not selectedSpell or selectedSpell ~= core.magic.SPELL_TYPE.Spell then return end

                for _, effect in ipairs(selectedSpell.effects) do
                    if effect.id ~= core.magic.EFFECT_TYPE.DamageHealth then
                        return
                    end
                end

                if destruction.base > lastDestLevel or destruction.progress > lastDestProgress then
                    lastDestLevel = destruction.base
                    lastDestProgress = destruction.progress
                    selfMagicka.current = math.min(
                        selfMagicka.base + selfMagicka.modifier,
                        selfMagicka.current + getBaseSpellCost(selectedSpell.id, false) / 2
                    )
                end
            end
        end)
    end
}
