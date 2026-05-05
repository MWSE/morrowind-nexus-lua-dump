local common = {}
common.isProgrammaticClick = false -- флаг программного клика мыши

function common.getItemData(itemId)
    if not itemId or not tes3.player then return nil end
    
    -- 1. Сначала проверяем экипированные предметы
    for _, stack in ipairs(tes3.player.object.equipment) do
        if stack and stack.object and stack.object.id == itemId then
            return stack.itemData
        end
    end
    
    -- 2. Если не экипирован, ищем в инвентаре
    local inventory = tes3.player.object.inventory
    if not inventory then return nil end
    
    local bestItemData = nil
    local hasDamagedItem = false
    
    for _, stack in pairs(inventory) do
        if stack.object and stack.object.id == itemId then
            -- Проверяем есть ли повреждённые/разряженные предметы
            if stack.variables and #stack.variables > 0 then
                hasDamagedItem = true
                bestItemData = stack.variables[1]  -- берём первый повреждённый
            end
        end
    end
    
    -- Если есть повреждённые предметы, возвращаем первый из них
    if hasDamagedItem then
        return bestItemData
    end
    
    -- 3. Если все предметы целые, возвращаем nil
    return nil
end

return common