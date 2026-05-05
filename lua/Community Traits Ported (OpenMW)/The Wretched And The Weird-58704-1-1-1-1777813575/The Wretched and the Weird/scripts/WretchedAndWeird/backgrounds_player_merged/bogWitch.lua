---@diagnostic disable: assign-type-mismatch
local I = require("openmw.interfaces")
local self = require("openmw.self")
local core = require("openmw.core")

local traitType = require("scripts.WretchedAndWeird.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "bogWitch",
    type = traitType,
    name = "Bog Witch",
    description = (
        "Eye of newt and toe of frog, wool of bat and tongue of dog! You are a mysterious bog witch. " ..
        "Your brews are the stuff of legend, and you are a master of a swampy sort of magic. " ..
        "However, a lifetime of breathing swamp gas has left you somewhat frail, and people seem unnerved by your tendency to cackle.\n" ..
        "\n" ..
        "+10 Alchemy\n" ..
        "-10 Endurance and Personality\n" ..
        "> Spells using only poison-related effects recoup half their magicka cost when cast"
    ),
    doOnce = function()
        local selfSkills = self.type.stats.skills
        local selfAttrs = self.type.stats.attributes
        local selfSpells = self.type.spells(self)

        selfSkills.alchemy(self).base = selfSkills.alchemy(self).base + 10

        selfAttrs.endurance(self).base = selfAttrs.endurance(self).base - 10
        selfAttrs.personality(self).base = selfAttrs.personality(self).base - 10

        selfSpells:add("poison")

        local startingItems = {}
        if core.contentFiles.has("Tamriel_Data.esm") then
            startingItems[#startingItems + 1] = {
                player = self,
                itemId = "T_Bre_Ep_HatWizard_01",
                count = 1,
                autoEquip = true,
            }
            startingItems[#startingItems + 1] = {
                player = self,
                itemId = "T_Bre_Ep_RobeWizard_01",
                count = 1,
                autoEquip = true,
            }
        else
            startingItems[#startingItems + 1] = {
                player = self,
                itemId = "lack_ww_WitchHat",
                count = 1,
                autoEquip = true,
            }
        end
        core.sendGlobalEvent(
            "WretchedAndWeird_addItems",
            startingItems
        )
    end,
    onLoad = function()
        local selfMagicka = self.type.stats.dynamic.magicka(self)
        local startKeys = {
            ["self start"] = true,
            ["touch start"] = true,
            ["target start"] = true,
        }
        local stopKeys = {
            ["self stop"] = true,
            ["touch stop"] = true,
            ["target stop"] = true,
        }
        local poisonEffects = {
            [core.magic.EFFECT_TYPE.Poison] = true,
            [core.magic.EFFECT_TYPE.CurePoison] = true,
            [core.magic.EFFECT_TYPE.ResistPoison] = true,
            [core.magic.EFFECT_TYPE.WeaknessToPoison] = true,
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
                if not selectedSpell or selectedSpell.type ~= core.magic.SPELL_TYPE.Spell then return end

                for _, effect in ipairs(selectedSpell.effects) do
                    if not poisonEffects[effect.id] then
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
