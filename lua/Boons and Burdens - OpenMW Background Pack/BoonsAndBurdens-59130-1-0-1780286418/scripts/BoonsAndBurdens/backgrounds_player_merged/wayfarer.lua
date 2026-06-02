---@omw-context player
---@diagnostic disable: undefined-field
local I = require("openmw.interfaces")
local self = require("openmw.self")

I.CharacterTraits.addTrait({
    id = "BaB_wayfarer",
    type = "background",
    name = "Wayfarer",
    description = (
        "You never had a master to learn from, a forge to work at, or the right tools for the job. " ..
        "What you had was the road, and the road taught you what it could. " ..
        "Your gear has never been pretty work, but it holds - it has always held. " ..
        "Settlements and the people in them came less naturally, and the years away have not helped.\n" ..
        "\n" ..
        "+10 Armorer and Athletics\n" ..
        "+5 Spear and Marksman\n" ..
        "-15 Mercantile and Speechcraft"
    ),
    doOnce = function()
        local skills = self.type.stats.skills

        skills.armorer(self).base = skills.armorer(self).base + 10
        skills.athletics(self).base = skills.athletics(self).base + 10
        skills.spear(self).base = skills.spear(self).base + 5
        skills.marksman(self).base = skills.marksman(self).base + 5

        skills.mercantile(self).base = skills.mercantile(self).base - 15
        skills.speechcraft(self).base = skills.speechcraft(self).base - 15
    end,
})
