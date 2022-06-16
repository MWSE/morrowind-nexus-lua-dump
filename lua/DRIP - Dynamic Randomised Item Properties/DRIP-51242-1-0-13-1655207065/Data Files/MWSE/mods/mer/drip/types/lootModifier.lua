---@meta

---@class DripModifierEffect
---@field id string The effect id. Use tes3.effect mapping.
---@field duration number The duration of the effect.
---@field min number The minimum magnitude of the effect.
---@field max number The maximum magnitude of the effect.
---@field rangeType number The range type derived from tes3.effectRange
---@field attribute number The attribute id. Use tes3.attribute mapping.
---@field skill number The skill id. Use tes3.skill mapping.

---@class DripModifierData
---@field prefix string The prefix appended to the loot name. A modifier should have at least a prefix or a suffix.
---@field suffix string The suffix appended to the loot name. A modifier should have at least a prefix or a suffix.
---@field castType number **Required** The cast type of the enchantment. Use tes3.enchantmentType mapping.
---@field chargeCost number The cost of the enchantment. Required when castType is not constant.
---@field maxCharge number The maximum charge of the enchantment. Required when castType is not constant.
---@field effects table<DripModifierEffect> **Required** The effects to be enchanted onto the loot.
---@field validObjectTypes table<number, boolean> A list of objectTypes that can have this modifier. use tes3.objectType mapping as the key and set value to true. e.g "[tes3.objectType.weapon] = true"
---@field validWeaponTypes table<number, boolean> A list of weaponTypes that can have this modifier. use tes3.weaponType mapping as the key and set value to true. e.g "[tes3.weaponType.shortBlade] = true"
---@field validWeightClasses table<number, boolean> A list of armor weight classes that can have this modifier. use tes3.armorWeightClass mapping as the key and set value to true. e.g "[tes3.armorWeightClass.heavy] = true"
---@field validArmorSlots table<number, boolean> A list of armor slots that can have this modifier. use tes3.armorSlot mapping as the key and set value to true. e.g "[tes3.armorSlot.helmet] = true"\
---@field validClothingSlots table<number, boolean> A list of clothing slots that can have this modifier. use tes3.clothingSlot mapping as the key and set value to true. e.g "[tes3.clothingSlot.amulet] = true"
---@field icon string The path to a custom icon
---@field description string A a description of the effect.
DripModifierData = {}

---@class DripModifier
---@field prefix string The prefix appended to the loot name. A modifier should have at least a prefix or a suffix.
---@field suffix string The suffix appended to the loot name. A modifier should have at least a prefix or a suffix.
---@field castType number **Required** The cast type of the enchantment. Use tes3.enchantmentType mapping.
---@field rangeType number **Required** The range type of the enchantment. Use tes3.effectRange mapping.
---@field chargeCost number The cost of the enchantment. Required when castType is not constant.
---@field maxCharge number The maximum charge of the enchantment. Required when castType is not constant.
---@field effects table<DripModifierEffect> **Required** The effects to be enchanted onto the loot.
---@field validObjectTypes table<number, boolean> A list of objectTypes that can have this modifier. use tes3.objectType mapping as the key and set value to true. e.g "[tes3.objectType.weapon] = true"
---@field validWeaponTypes table<number, boolean> A list of weaponTypes that can have this modifier. use tes3.weaponType mapping as the key and set value to true. e.g "[tes3.weaponType.shortBlade] = true"
---@field validWeightClasses table<number, boolean> A list of armor weight classes that can have this modifier. use tes3.armorWeightClass mapping as the key and set value to true. e.g "[tes3.armorWeightClass.heavy] = true"
---@field validArmorSlots table<number, boolean> A list of armor slots that can have this modifier. use tes3.armorSlot mapping as the key and set value to true. e.g "[tes3.armorSlot.helmet] = true"\
---@field validClothingSlots table<number, boolean> A list of clothing slots that can have this modifier. use tes3.clothingSlot mapping as the key and set value to true. e.g "[tes3.clothingSlot.amulet] = true"
---@field icon string The path to a custom icon
---@field description string A a description of the effect.
---@field multipliers table A list of object fields that will be multiplied by the value
---@field modifications table A list of object fields that will be modified by the value
DripModifier = {}

---@param data DripModifierData
function DripModifier:new(data) end
---@param object tes3weapon | tes3clothing | tes3armor
function DripModifier:validForObject(object) end

---@param object tes3weapon | tes3clothing | tes3armor
---@param list DripModifierData[]
function DripModifier:getRandomModifier(object, list) end