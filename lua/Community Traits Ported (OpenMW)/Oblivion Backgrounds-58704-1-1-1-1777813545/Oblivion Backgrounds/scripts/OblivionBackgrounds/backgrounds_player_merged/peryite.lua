local I = require("openmw.interfaces")
local self = require("openmw.self")
local core = require("openmw.core")

local traitType = require("scripts.OblivionBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "peryite",
    type = traitType,
    name = "Pestilent One",
    description = (
        "You were formed in the realm of Peryite, the Lord of Pestilence. " ..
        "Your pustulent youth has left you extremely vulnerable to disease " ..
        "and physically frail but, when diseased, you gain access to the Taskmaster's Command " ..
        "and you can conjure a blighted attack at will.\n" ..
        "\n" ..
        "-5 Strength and Endurance\n" ..
        "+100% Vulnerability to Common and Blight diseases\n" ..
        "> You start with a Command Humanoid and Command Creature spell\n" ..
        "> You start with a free Pestilence spell\n" ..
        "> These spells can only be cast if you're diseased"
    ),
    doOnce = function()
        -- local selfSkills = self.type.stats.skills
        local selfAttrs = self.type.stats.attributes
        local selfSpells = self.type.spells(self)

        selfAttrs.strength(self).base = selfAttrs.strength(self).base - 5
        selfAttrs.endurance(self).base = selfAttrs.endurance(self).base - 5

        selfSpells:add("lack_gg_PeryiteWeakness")
        selfSpells:add("lack_gg_PeryiteAttack")
        selfSpells:add("lack_gg_PeryiteTask")
    end,
    onLoad = function()
        local startKeys = {
            ["self start"] = true,
            ["touch start"] = true,
            ["target start"] = true,
        }
        local pestilenceSpells = {
            ["lack_gg_peryiteattack"] = true,
            ["lack_gg_peryitetask"] = true,
        }
        local selfSpells = self.type.spells(self)

        I.AnimationController.addTextKeyHandler('spellcast', function(groupname, key)
            if not startKeys[key] then return end

            local selectedSpell = self.type.getSelectedSpell(self)
            if not selectedSpell then return end

            local diseased = false
            for _, spell in ipairs(selfSpells) do
                if spell.type == core.magic.SPELL_TYPE.Disease
                    or spell.type == core.magic.SPELL_TYPE.Disease
                then
                    diseased = true
                    break
                end
            end

            if not diseased and pestilenceSpells[selectedSpell.id] then
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
                self:sendEvent(
                    "ShowMessage",
                    { message = "You cannot call on Peryite's power unless you are diseased." }
                )
            end
        end)
    end
}
