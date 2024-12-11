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
---@field id string A unique id for the modifier. If not provided, one will be generated from the prefix or suffix.
---@field prefix? string The prefix appended to the loot name. A modifier should have at least a prefix or a suffix.
---@field suffix? string The suffix appended to the loot name. A modifier should have at least a prefix or a suffix.
---@field castType? number **Required** The cast type of the enchantment. Use tes3.enchantmentType mapping.
---@field chargeCost? number The cost of the enchantment. Required when castType is not constant.
---@field maxCharge? number The maximum charge of the enchantment. Required when castType is not constant.
---@field effects? table<Drip.Modifier.Effect> **Required** The effects to be enchanted onto the loot.
---@field isValidObject? fun(self: Drip.Modifier, object: tes3object): boolean A function that returns true if the modifier is valid for the given object.
---@field validObjectTypes? table<number, boolean> A list of objectTypes that can have this modifier. use tes3.objectType mapping as the key and set value to true. e.g "[tes3.objectType.weapon] = true"
---@field validWeaponTypes? table<number, boolean> A list of weaponTypes that can have this modifier. use tes3.weaponType mapping as the key and set value to true. e.g "[tes3.weaponType.shortBlade] = true"
---@field validWeightClasses? table<number, boolean> A list of armor weight classes that can have this modifier. use tes3.armorWeightClass mapping as the key and set value to true. e.g "[tes3.armorWeightClass.heavy] = true"
---@field validArmorSlots? table<number, boolean> A list of armor slots that can have this modifier. use tes3.armorSlot mapping as the key and set value to true. e.g "[tes3.armorSlot.helmet] = true"\
---@field validClothingSlots? table<number, boolean> A list of clothing slots that can have this modifier. use tes3.clothingSlot mapping as the key and set value to true. e.g "[tes3.clothingSlot.amulet] = true"
---@field icon? string The path to a custom icon
---@field description? string A a description of the effect.
---@field valueMulti? number The multiplier for the value of the loot. e.g 1.5 will increase the value by 50%
---@field value? number Adds a flat value to the loot value.
---@field multipliers? table A list of object fields that will be multiplied by the value
---@field modifications? table A list of object fields that will be modified by the value


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
---@return Drip.Modifier?
function Modifier:new(data)
    if data == nil then return end
    local isValid, errorMsg = Modifier.validate(data)
    if not isValid then
        logger:debug("Invalid modifier data: %s", errorMsg)
        return nil
    end
    if not data.id then
        logger:warn("Modifier has no id. Generating from prefix or suffix")
        data.id = data.prefix or data.suffix
    end
    local modifier = setmetatable(data, self)
    self.__index = self
    return modifier
end

--- Register a Modifier
---@param modifierData Drip.Modifier.Data
function Modifier.register(modifierData)
    local modifier = Modifier:new(modifierData)
    if not modifier then
        logger:trace("Invalid modifier data")
        return
    end
    if modifier.prefix then
        logger:trace("Registering as prefix %s", modifier.prefix)
        modifierConfig.prefixes[modifier.id] = modifier
    elseif modifier.suffix then
        logger:trace("Registering as suffix %s", modifier.suffix)
        modifierConfig.suffixes[modifier.id] = modifier
    else
        logger:trace("Invalid modifier data: no prefix or suffix provided")
        return
    end
    logger:debug("Registering modifier %s", modifier.id)
end

---Get a Modifier by its ID
---@param id string
---@return Drip.Modifier?
function Modifier.getById(id)
    return modifierConfig.prefixes[id] or modifierConfig.suffixes[id]
end

---Get the list of modifiers that an object has
---@param object tes3object|tes3misc
---@return Drip.Modifier[]
function Modifier.getObjectModifiers(object)
    local modifiers = {}
    local id = object and object.id:lower()
    local data = common.config.persistent.generatedLoot[id]
    if data and data.modifiers then
        for _, modifierData in ipairs(data.modifiers) do
            local modifier
            if type(modifierData) == "string" then
                modifier = Modifier.getById(modifierData)
            else
                modifier = Modifier:new(modifierData)
            end
            if modifier then
                table.insert(modifiers, modifier)
            end
        end
    end
    return modifiers
end

---Validate Modifier data
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
        isValidObject =  "function",
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

---Get a random modifier from the given list
---@param object tes3object|tes3misc The object to check if the modifier is valid for
---@param list? table<string, Drip.Modifier[]> The list of modifiers to choose from. Defaults to randomly picking from prefixes or suffixes
---@return Drip.Modifier?
function Modifier.getRandomModifier(object, list)
    ---@type table<string, Drip.Modifier[]>
    list = list or math.random() < 0.5 and modifierConfig.prefixes or modifierConfig.suffixes
    local attempts = 0
    local MAX_ATTEMPTS = 100
    local modifier
    while attempts < MAX_ATTEMPTS do
        modifier = table.choice(list)
        if modifier and modifier:validForObject(object) then
            return modifier
        end
        attempts = attempts + 1
    end
    logger:trace("Failed to find a modifier for %s", object.name)
end


---Roll for the first Modifier of an obect
---@param object tes3object|tes3misc
---@return Drip.Modifier?
function Modifier.getFirstModifier(object)
    if math.random(100) <= common.config.mcm.modifierChance then
        local list = math.random() < 0.5 and modifierConfig.prefixes or modifierConfig.suffixes
        return Modifier.getRandomModifier(object, list)
    end
end

---Roll for the second Modifier of an obect
---@param object tes3object|tes3misc
---@return Drip.Modifier?
function Modifier.getSecondModifier(object, firstModifier)
    local secondModifier
    --If first modifier was wild, guarantee a second.
    if firstModifier.wild or math.random(100) < common.config.mcm.secondaryModifierChance then
        local list = firstModifier.prefix and modifierConfig.suffixes or modifierConfig.prefixes
        secondModifier = Modifier.getRandomModifier(object, list)
    end
    return secondModifier
end


---Generate a random set of modifiers for the given object
---@param object tes3object|tes3misc
---@return Drip.Modifier[]?
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
    local secondModifier = Modifier.getSecondModifier(object, firstModifier)
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

---Check if the modifier is valid for the given object
---@param object tes3object|tes3weapon|tes3armor
---@return boolean
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

    --callback filter
    if self.isValidObject then
        logger:trace("has isValidObject")
        if not self:isValidObject(object) then
            logger:trace("%s isValidObject returned false", object.name)
            return false
        end
    end

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