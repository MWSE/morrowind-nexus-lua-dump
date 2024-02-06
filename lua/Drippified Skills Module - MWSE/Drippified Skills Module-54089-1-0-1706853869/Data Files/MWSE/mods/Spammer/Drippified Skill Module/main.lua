local Drip = require("mer.drip")
local SkillsModule = require("SkillsModule")

local prefixes = {
    [5] = "Relaxed ",
    [10] = "Polished ",
    [15] = "Disciplined ",
    [20] = "Elegant "
}

event.register("simulate", function()
    local allSkills = table.values(SkillsModule.skills)
    if (not allSkills) or table.empty(allSkills) then return end
    table.sort(allSkills, function(a, b) return a.name < b.name end)
    for _, data in ipairs(allSkills) do
        for i = 5, 20, 5 do
            local id = data.id .. i
            if not Drip.Modifier.getById(id) then
                Drip.registerModifier {
                    id = id,
                    suffix = prefixes[i] .. data.name,
                    valueMulti = (1 + (i / 40)),
                    description = string.format("Increases %s skill by %d points.", data.name:lower(), i),
                    isValidObject = function(_, object)
                        return object.objectType == tes3.objectType.clothing
                    end
                }

                SkillsModule.registerFortifyEffect {
                    id = "drip_" .. id,
                    skill = data.id,
                    callback = function()
                        local equippedItems = tes3.mobilePlayer and tes3.mobilePlayer.object.equipment
                        if not equippedItems then return end
                        for _, stack in ipairs(equippedItems) do
                            if stack.object.objectType == tes3.objectType.clothing then
                                local modifiers = Drip.Modifier.getObjectModifiers(stack.object)
                                if not modifiers then return end
                                for _, modifier in ipairs(modifiers) do
                                    if modifier.suffix == (prefixes[i] .. data.name) then
                                        return i
                                    end
                                end
                            end
                        end
                    end
                }
            end
        end
    end
end)
--]]
