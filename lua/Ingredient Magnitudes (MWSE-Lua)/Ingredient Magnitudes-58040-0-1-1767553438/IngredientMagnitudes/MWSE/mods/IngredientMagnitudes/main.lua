local function getIngredientMultiplier(value)
    if value <= 1 then
        return 0.5
    end
    if value <= 20 then
        return 0.5 + (value - 1) * (0.5 / 19)
    elseif value <= 300 then
        return 1.0 + (value - 20) * (2.0 / 280)
    else
        return 3.0
    end
end

--- @param e potionBrewedEventData
local function onPotionBrewed(e)
    local potion = e.object
    local ingredients = e.ingredients

    for _, effect in ipairs(potion.effects) do
        if effect.id ~= -1 then
            local maxMultiplier = 1.0

            for _, ingredient in ipairs(ingredients) do
                for i = 1, 4 do
                    if ingredient.effects[i] == effect.id then
                        local m = getIngredientMultiplier(ingredient.value)
                        if m > maxMultiplier then
                            maxMultiplier = m
                        end
                    end
                end
            end

            effect.min = math.max(1, math.floor(effect.min * maxMultiplier))
            effect.max = math.max(1, math.floor(effect.max * maxMultiplier))
            effect.duration = math.max(1, math.floor(effect.duration * maxMultiplier))
        end
    end
end

event.register(tes3.event.potionBrewed, onPotionBrewed)

event.register("initialized", function()
    print("[IngredientMagnitudes] Rare ingredient scaling initialized.")
end)
