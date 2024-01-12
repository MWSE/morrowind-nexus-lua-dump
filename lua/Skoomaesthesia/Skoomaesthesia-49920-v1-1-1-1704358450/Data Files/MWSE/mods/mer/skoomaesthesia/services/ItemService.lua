local ItemService = {}
local common = require('mer.skoomaesthesia.common')
local logger = common.createLogger('ItemService')
local config = require('mer.skoomaesthesia.config')

---@return boolean
function ItemService.isSkooma(item)
    local isPotion = item.objectType == tes3.objectType.alchemy
    local skoomaInName = item.name ~= nil and item.name:lower():find('skooma') ~= nil
    local inConfig = config.skooma[item.id:lower()] ~= nil
    return (isPotion and skoomaInName) or inConfig
end

---@return boolean
function ItemService.isMoonSugar(item)
    local isIngredient = item.objectType == tes3.objectType.ingredient
    local moonSugarInName = item.name ~= nil and item.name:lower() == 'moon sugar'
    local inConfig = config.moonSugar[item.id:lower()] ~= nil
    return (isIngredient and moonSugarInName) or inConfig
end

---@return boolean
function ItemService.isPipe(item)
    local isApparatus = item.objectType == tes3.objectType.apparatus
    local pipeInName = item.name ~= nil and item.name:lower():find('skooma pipe') ~= nil
    local inConfig = config.pipes[item.id:lower()] ~= nil
    return (isApparatus and pipeInName) or inConfig
end

---@return boolean
function ItemService.playerHasSkooma()
    for _, itemStack in pairs(tes3.player.object.inventory) do
        if ItemService.isSkooma(itemStack.object) then
            return true
        end
    end
    return false
end

---@return boolean
function ItemService.playerHasMoonSugar()
    for _, itemStack in pairs(tes3.player.object.inventory) do
        if ItemService.isMoonSugar(itemStack.object) then
            return true
        end
    end
    return false
end

---@return boolean
function ItemService.playerHasPipe()
    for _, itemStack in pairs(tes3.player.object.inventory) do
        if ItemService.isPipe(itemStack.object) then
            return true
        end
    end
    return false
end

---@return string|nil
function ItemService.getMoonSugar()
    for _, itemStack in pairs(tes3.player.object.inventory) do
        if ItemService.isMoonSugar(itemStack.object) then
            return itemStack.object.id
        end
    end
end

return ItemService