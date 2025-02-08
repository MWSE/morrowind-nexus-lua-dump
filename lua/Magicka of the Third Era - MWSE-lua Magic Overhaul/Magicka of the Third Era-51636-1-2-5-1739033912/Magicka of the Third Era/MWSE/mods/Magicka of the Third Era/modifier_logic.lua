local this = {}

function this.process_modifiers(effect_array, cost_array, modifier_list)
    local modifier_changes = {difficulty = 1, cost = 1}

    if contains_value(modifier_list, 3401) then
        print("[ModLogic] Blood Magic Found!")
        local blood_magic = 0
        for i, effect in ipairs(effect_array) do
            if effect.id == 3401 then
                 blood_magic = blood_magic + effect.max
            end
        end
        print(blood_magic)
        modifier_changes.difficulty = modifier_changes.difficulty * (1 - blood_magic * 0.01)
    end


    return modifier_changes
end



function contains_value(list, value)
    for index, val in ipairs(list) do
      if val == value then
        return true
      end
    end
    return false
end

return this