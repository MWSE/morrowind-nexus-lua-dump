local I = require("openmw.interfaces")
local self = require("openmw.self")

local traitType = require("scripts.WretchedAndWeird.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "deprived",
    type = traitType,
    name = "Deprived",
    description = (
        "Poverty and deprivation have been your lifelong companions. " ..
        "You have no possessions, and the years of want have weakened you greatly.\n" ..
        "\n" ..
        "> All skills and attributes reduced by 10"
    ),
    doOnce = function()
        local selfSkills = self.type.stats.skills
        local selfAttrs = self.type.stats.attributes
        local skills = {
            acrobatics  = selfSkills.acrobatics(self),
            alchemy     = selfSkills.alchemy(self),
            alteration  = selfSkills.alteration(self),
            armorer     = selfSkills.armorer(self),
            athletics   = selfSkills.athletics(self),
            axe         = selfSkills.axe(self),
            block       = selfSkills.block(self),
            bluntWeapon = selfSkills.bluntweapon(self),
            conjuration = selfSkills.conjuration(self),
            destruction = selfSkills.destruction(self),
            enchant     = selfSkills.enchant(self),
            handToHand  = selfSkills.handtohand(self),
            heavyArmor  = selfSkills.heavyarmor(self),
            illusion    = selfSkills.illusion(self),
            lightArmor  = selfSkills.lightarmor(self),
            longBlade   = selfSkills.longblade(self),
            marksman    = selfSkills.marksman(self),
            mediumArmor = selfSkills.mediumarmor(self),
            mercantile  = selfSkills.mercantile(self),
            mysticism   = selfSkills.mysticism(self),
            restoration = selfSkills.restoration(self),
            security    = selfSkills.security(self),
            shortBlade  = selfSkills.shortblade(self),
            sneak       = selfSkills.sneak(self),
            spear       = selfSkills.spear(self),
            speechcraft = selfSkills.speechcraft(self),
            unarmored   = selfSkills.unarmored(self),
        }
        local attrs = {
            agility      = selfAttrs.agility(self),
            endurance    = selfAttrs.endurance(self),
            intelligence = selfAttrs.intelligence(self),
            luck         = selfAttrs.luck(self),
            personality  = selfAttrs.personality(self),
            speed        = selfAttrs.speed(self),
            strength     = selfAttrs.strength(self),
            willpower    = selfAttrs.willpower(self),
        }

        for _, skill in pairs(skills) do
            skill.base = skill.base - 10
        end
        for _, attr in pairs(attrs) do
            attr.base = attr.base - 10
        end
    end,
}
