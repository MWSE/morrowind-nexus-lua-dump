require("diject.remains_of_the_fallen.libs.types")

local this = {}

local negativeTypes = {"weight"}
local positiveTypes = {"enchantCapacity", "armorRating", "maxCondition", "quality"}
local minMaxTypes = {"chop", "slash", "thrust"}


local function multiplyEffects(effects, mul)
    for _, effect in pairs(effects) do
        local effectData = {}
        if effect.id == -1 then break end
        effect.min = effect.min * mul
        effect.max = effect.max * mul
        effect.duration = effect.duration * mul
        effect.radius = effect.radius * mul
    end
end

local function multiplyEnchantment(enchantment, mul)
    if mul ~= 0 then
        enchantment.chargeCost = enchantment.chargeCost / mul
    end
    multiplyEffects(enchantment.effects, mul)
end

---@class rotf.item.decreaseItemStats.params
---@field multiplier number|nil
---@field valueMul number|nil

---@param object any
---@param params rotf.item.decreaseItemStats.params|nil
function this.multiplyItemStats(object, params)
    if not params then params = {} end
    local valueMul = params.valueMul or 1
    local mul = params.multiplier or 1
    if object.value then object.value = object.value * valueMul end
    for _, fieldName in pairs(minMaxTypes) do
        local minName = fieldName.."Min"
        if object[minName] then
            object[minName] = object[minName] * mul
            local maxName = fieldName.."Max"
            object[maxName] = object[maxName] * mul
        end
    end
    for _, fieldName in pairs(negativeTypes) do
        if object[fieldName] and mul ~= 0 then
            object[fieldName] = object[fieldName] / mul
        end
    end
    for _, fieldName in pairs(positiveTypes) do
        if object[fieldName] then
            object[fieldName] = object[fieldName] * mul
        end
    end
    if object.effects then
        multiplyEffects(object.effects, mul)
    end
    if object.enchantment then
        multiplyEnchantment(object.enchantment, mul)
    end
end

return this