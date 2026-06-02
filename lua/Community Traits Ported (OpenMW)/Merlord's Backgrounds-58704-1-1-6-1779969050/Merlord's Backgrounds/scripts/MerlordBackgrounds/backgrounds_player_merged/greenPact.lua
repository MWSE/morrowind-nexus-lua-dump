local I = require("openmw.interfaces")
local self = require("openmw.self")
local core = require("openmw.core")

local traitType = require("scripts.MerlordBackgrounds.utils.traitTypes").background

local sdOverride = false

I.CharacterTraits.addTrait {
    id = "greenPact",
    type = traitType,
    name = "Green Pact",
    description = (
        "As a Bosmer, you have sworn an oath, known as the Green Pact, to the forest deity Y'ffre. " ..
        "One of the conditions of this pact states that you may only consume meat-based products." ..
        "\n" ..
        "\nRequirements: Wood Elves only."
    ),
    checkDisabled = function()
        ---@diagnostic disable-next-line: undefined-field
        return self.type.records[self.recordId].race ~= "wood elf"
    end,
    onLoad = function()
        if I.SunsDusk and I.SunsDusk.version >= 5 then
            -- SD overrides the behavior
            sdOverride = true
        else
            core.sendGlobalEvent("MerlordsTraits_registerGreenPact", self.id)
        end
    end,
}

local function onConsume(item)
    if not sdOverride then return end
    local res, typ = I.SunsDusk.isConsumable(item)
    if typ == "cooked" or typ == "database" and not res.isGreenPact then
        local sd = I.SunsDusk.getSaveData()
        if sd.m_hunger then
            sd.m_hunger.hunger = sd.m_hunger.hunger + res.foodValue * 1.5
            sd.m_hunger.foodProfiles["broken pact"] = 180
            I.SunsDusk.refreshNeeds("hunger")
            self:sendEvent("ShowMessage", { message = "The Green Pact prohibits you from eating this." })
        end
    end
end

return {
    engineHandlers = {
        onConsume = onConsume,
    },
}
