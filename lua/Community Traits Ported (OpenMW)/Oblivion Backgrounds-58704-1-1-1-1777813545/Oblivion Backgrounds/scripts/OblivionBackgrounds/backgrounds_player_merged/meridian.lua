local I = require("openmw.interfaces")
local self = require("openmw.self")
local core = require("openmw.core")

local traitType = require("scripts.OblivionBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "meridian",
    type = traitType,
    name = "Child of Light",
    description = (
        "Much of your life was spent in Meridia's Colored Rooms. " ..
        "Even now you can command the pure light of your home plane, " ..
        "and you can purify the tainted for a time, but you cannot tolerate necromancy, " ..
        "and the brilliant will of the Lady of Light has diminished your own.\n" ..
        "\n" ..
        "-20 Willpower\n" ..
        "> You start with a free Light and Turn Undead spell\n" ..
        "> You start with a powerful Command Humanoid power\n" ..
        "> You cannot summon undead creatures"
    ),
    doOnce = function()
        -- local selfSkills = self.type.stats.skills
        local selfAttrs = self.type.stats.attributes
        local selfSpells = self.type.spells(self)

        selfAttrs.willpower(self).base = selfAttrs.willpower(self).base - 20

        selfSpells:add("lack_gg_ColoredLights")
        selfSpells:add("lack_gg_GlisterWitch")
    end,
    onLoad = function()
        local effects = core.magic.EFFECT_TYPE
        local undeadEffects = {
            [effects.SummonAncestralGhost] = true,
            [effects.SummonBonelord] = true,
            [effects.SummonBonewalker] = true,
            [effects.SummonBonewolf] = true,
            [effects.SummonGreaterBonewalker] = true,
            [effects.SummonSkeletalMinion] = true,
        }
        local startKeys = {
            ["self start"] = true,
            ["touch start"] = true,
            ["target start"] = true,
        }

        I.AnimationController.addTextKeyHandler('spellcast', function(groupname, key)
            if not startKeys[key] then return end

            local selectedSpell = self.type.getSelectedSpell(self)
            if not selectedSpell then return end

            for _, effect in ipairs(selectedSpell.effects) do
                if undeadEffects[effect.id] then
                    local activeSpells = self.type.activeSpells(self)
                    activeSpells:add {
                        id = "lack_gg_spellDisabled",
                        ---@diagnostic disable-next-line: assign-type-mismatch
                        effects = { 0 },
                        ignoreResistances = true,
                        ignoreSpellAbsorption = true,
                        ignoreReflect = true,
                        quiet = true,
                    }
                    return
                end
            end
        end)
    end
}
