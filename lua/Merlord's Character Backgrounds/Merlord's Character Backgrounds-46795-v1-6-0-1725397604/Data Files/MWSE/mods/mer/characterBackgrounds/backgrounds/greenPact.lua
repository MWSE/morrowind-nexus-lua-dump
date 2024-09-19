local config = require('mer.characterBackgrounds.config')
local function getData()
    local data = tes3.player.data.merBackgrounds or {}
    return data
end

local meatPatterns = {
    "meat",
    "cuttle",
    "egg",
    "skin",
    "hide",
    "jerky",
    "bone",
    "blood",
    "fish",
    "scales",
    "scrib",
    "shalk",
    "leather",
    "pelt",
    "flesh",
    "brain",
    "_ear",
    "eye",
    "heart",
    "tail",
    "tongue",
    "morsel",
    "_ingcrea"
}

local function hasMeatyName(id)
    for _, pattern in ipairs(meatPatterns) do
        if string.find(id, pattern) then
            return true
        end
    end
end

return {
    id = "greenPact",
    name = "Green Pact",
    description = (
        "As a Bosmer, you have sworn an oath, known as the Green Pact, to the forest deity Y'ffre. " ..
        "One of the conditions of this pact states that you may only consume meat-based products." ..
        "\n\nRequirements: Wood Elves only."
    ),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Wood Elf"
    end,
    callback = function()

        local function checkIsMeat(e)
            local data = getData()
            if data.currentBackground ~= "greenPact" then return end

            if e.item.objectType == tes3.objectType.ingredient then
                local id = string.lower(e.item.id)
                if not hasMeatyName(id) then
                    if not config.mcm.greenPactAllowed[id] then
                        tes3.messageBox("The Green Pact prohibits you from eating this.")
                        return false
                    end
                end
            end
        end
        event.unregister("equip", checkIsMeat )
        event.register("equip", checkIsMeat )
    end
}