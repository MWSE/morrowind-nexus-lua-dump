local I = require("openmw.interfaces")
local self = require("openmw.self")
local core = require("openmw.core")

local traitType = require("scripts.MerlordBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "framed",
    type = traitType,
    name = "Framed",
    description = (
        "You got on the wrong side of some people in very powerful positions. " ..
        "Every once in a while, you will get a price on your head for a crime you did not commit. " ..
        "Your life on the run has given you a talent for guile and stealth\n" ..
        "\n" ..
        "+10 to all Steath skills\n" ..
        "> Once in a while you will get a bounty for a crime you did not commit."
    ),
    doOnce = function()
        local skills = self.type.stats.skills
        skills.acrobatics(self).base = skills.acrobatics(self).base + 10
        skills.security(self).base = skills.security(self).base + 10
        skills.sneak(self).base = skills.sneak(self).base + 10
        skills.lightarmor(self).base = skills.lightarmor(self).base + 10
        skills.marksman(self).base = skills.marksman(self).base + 10
        skills.shortblade(self).base = skills.shortblade(self).base + 10
        skills.handtohand(self).base = skills.handtohand(self).base + 10
        skills.mercantile(self).base = skills.mercantile(self).base + 10
        skills.speechcraft(self).base = skills.speechcraft(self).base + 10
    end,
    onLoad = function()
        core.sendGlobalEvent("MerlordsTraits_registerFramed", self)
    end,
}
