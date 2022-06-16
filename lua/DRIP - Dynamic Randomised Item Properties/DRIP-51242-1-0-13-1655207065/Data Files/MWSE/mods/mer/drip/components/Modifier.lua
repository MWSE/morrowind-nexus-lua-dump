local common = require("mer.drip.common")
local modifierConfig = common.config.modifiers
local logger = common.createLogger("Modifier")

---@type DripModifier
local Modifier = {}

function Modifier:validate(modifierData)
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

---@param data DripModifierData
function Modifier:new(data)
    local isValid, errorMsg = self:validate(data)
    if not isValid then
        logger:debug("Invalid modifier data: %s", errorMsg)
        return nil
    end
    if data == nil then return end
    local modifier = setmetatable(data, self)
    self.__index = self

    return modifier
end

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

function Modifier:getRandomModifier(object, list)
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

return Modifier