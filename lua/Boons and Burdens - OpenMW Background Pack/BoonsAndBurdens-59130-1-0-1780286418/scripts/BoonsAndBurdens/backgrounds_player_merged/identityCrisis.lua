---@omw-context player
---@diagnostic disable: assign-type-mismatch
---@diagnostic disable: undefined-field
local I = require("openmw.interfaces")
local self = require("openmw.self")

local bgPicked = false

I.CharacterTraits.addTrait {
    id = "BaB_identityCrisis",
    type = "background",
    name = "Identity Crisis",
    description = (
        "Something happened - you have never been entirely clear on what. " ..
        "The person you were before it and the person you became after share " ..
        "the same memories, the same face, the same instincts. " ..
        "Just not, apparently, the same arrangement. You know exactly who you are. " ..
        "You are simply not certain which parts of you are supposed to go where.\n" ..
        "\n" ..
        "> All your skill and attribute levels are shuffled"
    ),
    doOnce = function()
        bgPicked = true
    end,
}

return {
    eventHandlers = {
        CharacterTraits_allTraitsPicked = function()
            if bgPicked then
                local function shuffle(list)
                    for i = #list, 2, -1 do
                        local j = math.random(i)
                        list[i], list[j] = list[j], list[i]
                    end
                end

                local accessors = {}

                for _, getter in pairs(self.type.stats.skills) do
                    accessors[#accessors + 1] = {
                        get = function() return getter(self).base end,
                        set = function(v) getter(self).base = v end,
                    }
                end
                for _, getter in pairs(self.type.stats.attributes) do
                    accessors[#accessors + 1] = {
                        get = function() return getter(self).base end,
                        set = function(v) getter(self).base = v end,
                    }
                end
                if I.SkillFramework and I.SkillFramework.getSkillRecords then
                    for id in pairs(I.SkillFramework.getSkillRecords()) do
                        accessors[#accessors + 1] = {
                            get = function() return I.SkillFramework.getSkillStat(id).base end,
                            set = function(v) I.SkillFramework.getSkillStat(id).base = v end,
                        }
                    end
                end

                local values = {}
                for i, a in ipairs(accessors) do values[i] = a.get() end
                shuffle(values)
                for i, a in ipairs(accessors) do a.set(values[i]) end
            end
        end,
    }
}
