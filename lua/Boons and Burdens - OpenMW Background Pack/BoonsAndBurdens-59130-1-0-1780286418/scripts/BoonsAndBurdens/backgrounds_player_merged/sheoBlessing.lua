---@omw-context player
---@diagnostic disable: undefined-field
local I = require("openmw.interfaces")
local self = require("openmw.self")

local bgPicked = false

I.CharacterTraits.addTrait {
    id = "BaB_sheoblesing",
    type = "background",
    name = "Blessed by Sheogorath",
    description = (
        "You prayed at the wrong shrine. Or perhaps the right one - " ..
        "it is genuinely difficult to say with him. He answered regardless. " ..
        "What you were before that day and what you became after are " ..
        "questions you have long since stopped trying to answer.\n" ..
        "\n" ..
        "> All your skills and attributes are randomized from 0 to 100"
    ),
    doOnce = function()
        bgPicked = true
    end,
}

return {
    eventHandlers = {
        CharacterTraits_allTraitsPicked = function()
            if bgPicked then
                for _, getter in pairs(self.type.stats.skills) do
                    local skill = getter(self)
                    skill.base = math.random(0, 100)
                end
                for _, getter in pairs(self.type.stats.attributes) do
                    local attr = getter(self)
                    attr.base = math.random(0, 100)
                end
                if I.SkillFramework and I.SkillFramework.getSkillRecords then
                    for id, _ in pairs(I.SkillFramework.getSkillRecords()) do
                        local skill = I.SkillFramework.getSkillStat(id)
                        skill.base = math.random(0, 100)
                    end
                end
            end
        end,
    }
}
