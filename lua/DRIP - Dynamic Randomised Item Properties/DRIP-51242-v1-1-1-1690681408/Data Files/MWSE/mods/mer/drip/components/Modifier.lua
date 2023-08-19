local common = require("mer.drip.common")
local modifierConfig = common.config.modifiers
local logger = common.createLogger("Modifier")

---@class Drip.Modifier.Effect
---@field id string The effect id. Use tes3.effect mapping.
---@field duration number The duration of the effect.
---@field min number The minimum magnitude of the effect.
---@field max number The maximum magnitude of the effect.
---@field rangeType number The range type derived from tes3.effectRange
---@field attribute number The attribute id. Use tes3.attribute mapping.
---@field skill number The skill id. Use tes3.skill mapping.

---@class Drip.Modifier.Data
---@field prefix string The prefix appended to the loot name. A modifier should have at least a prefix or a suffix.
---@field suffix string The suffix appended to the loot name. A modifier should have at least a prefix or a suffix.
---@field castType number **Required** The cast type of the enchantment. Use tes3.enchantmentType mapping.
---@field chargeCost number The cost of the enchantment. Required when castType is not constant.
---@field maxCharge number The maximum charge of the enchantment. Required when castType is not constant.
---@field effects table<Drip.Modifier.Effect> **Required** The effects to be enchanted onto the loot.
---@field validObjectTypes table<number, boolean> A list of objectTypes that can have this modifier. use tes3.objectType mapping as the key and set value to true. e.g "[tes3.objectType.weapon] = true"
---@field validWeaponTypes table<number, boolean> A list of weaponTypes that can have this modifier. use tes3.weaponType mapping as the key and set value to true. e.g "[tes3.weaponType.shortBlade] = true"
---@field validWeightClasses table<number, boolean> A list of armor weight classes that can have this modifier. use tes3.armorWeightClass mapping as the key and set value to true. e.g "[tes3.armorWeightClass.heavy] = true"
---@field validArmorSlots table<number, boolean> A list of armor slots that can have this modifier. use tes3.armorSlot mapping as the key and set value to true. e.g "[tes3.armorSlot.helmet] = true"\
---@field validClothingSlots table<number, boolean> A list of clothing slots that can have this modifier. use tes3.clothingSlot mapping as the key and set value to true. e.g "[tes3.clothingSlot.amulet] = true"
---@field icon string The path to a custom icon
---@field description string A a description of the effect.
---@field valueMulti number The multiplier for the value of the loot. e.g 1.5 will increase the value by 50%
---@field value number Adds a flat value to the loot value.
---@field multipliers table A list of object fields that will be multiplied by the value
---@field modifications table A list of object fields that will be modified by the value

---@class Drip.Modifier : Drip.Modifier.Data
local Modifier = {
    ---@type boolean Whether this modifier is a wild modifier
    wild = nil
}

---------------------------------------------------
-- Static Methods
---------------------------------------------------

--Constructor
---@param data Drip.Modifier.Data
function Modifier:new(data)
    local isValid, errorMsg = Modifier.validate(data)
    if not isValid then
        logger:debug("Invalid modifier data: %s", errorMsg)
        return nil
    end
    if data == nil then return end
    local modifier = setmetatable(data, self)
    self.__index = self

    return modifier
end

function Modifier.validate(modifierData)
    if not modifierData then return nil end
    local dripModifierFields = {
        prefix =  "string",
        suffix =  "string",
        castType =  "number",
        rangeType =  "number",
        chargeCost =  "number",
        maxCharge =  "number",
        effects =  "table",
        validObjectTypes =  "table",
        validWeaponTypes =  "table",
        validWeightClasses =  "table",
        validArmorSlots =  "table",
        validClothingSlots =  "table",
    }

    for k, v in pairs(dripModifierFields) do
        if modifierData[k] then
            if not type(modifierData[k]) == v then
                return false, string.format("Modifier field '" .. k .. "' must be of type " .. v)
            end
        end
    end
    if not (modifierData.prefix or modifierData.suffix) then
        return false, "Modifier must have either a prefix or a suffix"
    end
    return true
end

function Modifier.getRandomModifier(object, list)
    list = list or math.random() < 0.5 and modifierConfig.prefixes or modifierConfig.suffixes
    local attempts = 0
    local MAX_ATTEMPTS = 100
    local modifier
    while attempts < MAX_ATTEMPTS do
        modifier = Modifier:new(table.choice(list))
        if modifier and modifier:validForObject(object) then
            return modifier
        end
        attempts = attempts + 1
    end
    logger:trace("Failed to find a modifier for %s", object.name)
end


function Modifier.getFirstModifier(object)
    if math.random(100) <= common.config.mcm.modifierChance then
        local list = math.random() < 0.5 and modifierConfig.prefixes or modifierConfig.suffixes
        return Modifier.getRandomModifier(object, list)
    end
end

--[[
    Generate a random set of modifiers for the given object
]]
function Modifier.rollForModifiers(object)
    --Roll for fist modifier, and if it succeeds, roll for second modifier
    --First modifier has 50/50 chance of being prefix or suffix
    local modifiers = {}

    logger:trace("Object: %s", object.name)

    local firstModifier = Modifier.getFirstModifier(object)
    if not firstModifier then
        return
    end
    table.insert(modifiers, firstModifier)
    local secondModifier
    --If first modifier was wild, guarantee a second.
    --If wild is the second modifier, we already have another to apply the wild to
    if firstModifier.wild or math.random(100) < common.config.mcm.secondaryModifierChance then
        if firstModifier.prefix then
            secondModifier = Modifier.getRandomModifier(object, modifierConfig.suffixes)
        else
            secondModifier = Modifier.getRandomModifier(object, modifierConfig.prefixes)
        end
    end
    if secondModifier then
        table.insert(modifiers, secondModifier)
    end

    if #modifiers > 0 then
        return modifiers
    end
end

---------------------------------------------------
-- Instance Methods
---------------------------------------------------

function Modifier:validForObject(object)
    logger:trace("Checking if modifier is valid for object %s", object.id)

    logger:trace("self.prefix: %s", self.prefix)
    logger:trace("self.suffix: %s", self.suffix)
    logger:trace("self.castType: %s", self.castType)

    --Check invalid cast type and object type combinations
    if self.castType then
        local objIsWeapon = object.objectType == tes3.objectType.weapon
             or object.objectType == tes3.objectType.ammunition
        --Thrown weapons/ammo can't have Constant Effect
        local ammoTypes = {
            [tes3.weaponType.arrow] = true,
            [tes3.weaponType.bolt] = true,
            [tes3.weaponType.marksmanThrown] = true
        }
        local isAmmo = objIsWeapon and ammoTypes[object.type]
        local enchantIsConstant = self.castType == tes3.enchantmentType.constant
        if enchantIsConstant and isAmmo then
            logger:trace("Modifier is a constant effect, but object is a thrown weapon")
            return false
        end
        local enchentIsOnStrike = self.castType == tes3.enchantmentType.onStrike
        if enchentIsOnStrike and not objIsWeapon then
            logger:trace("Modifier is an onStrike effect, but object is not a weapon")
            return false
        end
    end

    --Modifier specific filters

    --Object type
    if self.validObjectTypes then
        logger:trace("has validObjectTypes")
        if not self.validObjectTypes[object.objectType] then
            logger:trace("%s objectType is invalid", object.name)
            return false
        end
    end
    ---Weapon Type
    if self.validWeaponTypes and object.objectType == tes3.objectType.weapon then
        logger:trace("has validWeaponTypes")
        if not self.validWeaponTypes[object.type] then
            logger:trace("%s weaponType is invalid", object.name)
            return false
        end
    end
    --Weight class
    if self.validWeightClasses and object.objectType == tes3.objectType.armor then
        logger:trace("has validWeightClasses")
        if not self.validWeightClasses[object.weightClass] then
            logger:trace("%s objectWeightclass is invalid", object.name)
            return false
        end
    end
    --Armor Slots
    if self.validArmorSlots and object.objectType == tes3.objectType.armor then
        logger:trace("has validArmorSlots")
        if not self.validArmorSlots[object.slot] then
            logger:trace("%s armorSlot is invalid", object.name)
            return false
        end
    end
    --Clothing Slots
    if self.validClothingSlots and object.objectType == tes3.objectType.clothing then
        logger:trace("has validClothingSlots")
        if not self.validClothingSlots[object.slot] then
            logger:trace("%s clothingSlot not invalid", object.name)
            return false
        end
    end

    --Check check multiplier fields exist on object
    if self.multipliers then
        for k, v in pairs(self.multipliers) do
            if not object[k] then
                logger:error("%s does not have a multiplier field %s", object.name, k)
                return false
            end
        end
    end

    ---Check modification fields exist on object
    if self.modifications then
        for k, v in pairs(self.modifications) do
            if not object[k] then
                logger:error("%s does not have a modification field %s", object.name, k)
                return false
            end
        end
    end

    return true
end

return Modifier