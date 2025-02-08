local common = require("mer.drip.common")
local config = common.config
local logger = common.createLogger("Loot")

---@class Drip.Loot.Data
---@field object? tes3object|tes3weapon|tes3armor|tes3clothing
---@field baseObject tes3object|tes3weapon|tes3armor|tes3clothing
---@field modifiers Drip.Modifier[]
---@field wild? boolean If not set, will be determined randomly

---@class Drip.Loot : Drip.Loot.Data
---@field object? tes3object|tes3weapon|tes3armor|tes3clothing
---@field modifiers table<number, Drip.Modifier.Data|string>
---@field wild boolean @If true, the loot will have wild effects
local Loot = {}

---@param lootData Drip.Loot.Data
function Loot:new(lootData)
    logger:debug("Creating new loot for %s", lootData.baseObject.name)
    local loot = setmetatable(lootData, self) --[[@as Drip.Loot]]
    self.__index = self
    return loot
end

function Loot:initialize()
    --Create the tes3object
    self.object = self.baseObject:createCopy{}
    if not self.object then return nil end

    self.object.modified = true
    --Remove any modifiers that don't share the same cast type as the first one
    local targetCastType = self.modifiers[1].castType or tes3.enchantmentType.constant
    local modifiers = {}
    for i, modifier in ipairs(self.modifiers) do
        logger:debug("modifier: %s", modifier.prefix or modifier.suffix)
        if (not self.modifiers[i].castType) or self.modifiers[i].castType == targetCastType then
            table.insert(modifiers, modifier)
        end
    end
    self.modifiers = modifiers
    self:applyModifications()
    self:applyMultipliers()

    local enchantment = Loot:makeComplexEnchantment(self.modifiers)
    if enchantment then
        self.object.enchantment = enchantment
        self:applyEnchantCapacityScaling()
        logger:debug("Checking for wild")
        if self.wild == nil and self:canHaveWild() and self:rollForWild() then
            self.wild = true
        end
        self:applyWild()
    end
    local name = self:getLootName{ wild = self.wild }
    if #name > 31 then
        logger:debug("Name '%s' exceeds 31 characters, cancelling Loot creation", name)
        return nil
    end
    self.object.name = name

    self:applyValueModifiers()

    logger:debug("Created new loot: %s", self.object.name)
    return self
end



function Loot:rollForWild()
    local roll = math.random(100)
    return roll <= common.config.mcm.wildChance
end

function Loot:canHaveWild()
    if #self:getLootName{ wild = true } > 31 then
        logger:debug("Name is too long with wild parameter")
        return false
    end

    if not self.object.enchantment then
        logger:debug("Object %s has no enchantment", self.object.name)
        return false
    end
    --Constant effects need min and max the same
    if self.object.enchantment.castType == tes3.enchantmentType.constant then
        logger:debug("enchantment is constant, can't be wild")
        return false
    end
    --Find an effect with min max
    for _, effect in ipairs(self.object.enchantment.effects) do
        if effect.min and effect.min > 0 then
            logger:debug("min: %s", effect.min)
            logger:debug("max: %s", effect.max)
            logger:debug("Found effect with magnitude on %s", self.object.name)
            return true
        end
    end
    logger:debug("No effects with magnitude on %s", self.object.name)
    return false
end

function Loot:applyWild()
    if not self.wild then return end
    if not self.object.enchantment then return false end
    logger:debug("Making %s Wild", self.object.name)
    --Wildify the effects
    for _, effect in ipairs(self.object.enchantment.effects) do
        local wildMax = math.ceil((effect.min + effect.max) * common.config.mcm.wildMultiplier)
        effect.min = 1
        effect.max = wildMax
    end
end

function Loot:applyValueModifiers()
    for _, modifier in ipairs(self.modifiers) do
        if modifier.value then
            local enchantCapacityMultiplier = self:getEnchantCapacityMultiplier()
            self.object.value = self.object.value + (modifier.value * enchantCapacityMultiplier)
        end
    end
    for _, modifier in ipairs(self.modifiers) do
        if modifier.valueMulti then
            self.object.value = self.object.value * modifier.valueMulti
        end
    end
    if self.wild then
        self.object.value = self.object.value * 1.5 + 50
    end
end

function Loot:applyModifications()
    for _, modifier in ipairs(self.modifiers) do
        if modifier.modifications then
            for field, modification in pairs(modifier.modifications) do
                if self.object[field] and type(self.object[field] == "number") then
                    local current = self.object[field]
                    local cap = current * 5
                    self.object[field] = math.clamp(self.object[field] + modification, 1, cap)
                end
            end
        end
    end
end

function Loot:getEnchantCapacityMultiplier()
    local enchantCapacity = math.min(self.baseObject.enchantCapacity, config.maxEnchantCapacty)
    local enchantCapacityEffect = math.remap(enchantCapacity, config.minEnchantCapacity, config.maxEnchantCapacty, 1, config.maxEnchantEffect)
    logger:debug("%s enchant capacity: %s, effect: %s", self.baseObject.name, enchantCapacity, enchantCapacityEffect)
    return enchantCapacityEffect
end

--[[
    For each effect in each modifier, scale the min and max values by the enchant capacity of the base object
]]
function Loot:applyEnchantCapacityScaling()
    local enchantCapacityEffect = self:getEnchantCapacityMultiplier()
    if self.object.enchantment then
        ---@param effect tes3effect
        for _, effect in ipairs(self.object.enchantment.effects) do
            if effect.min and effect.max and effect.min > 0 then
                logger:debug("new min: %s", effect.min * enchantCapacityEffect)
                effect.min = math.ceil(effect.min * enchantCapacityEffect)
                logger:debug("new max: %s", effect.max * enchantCapacityEffect)
                effect.max = math.ceil(effect.max * enchantCapacityEffect)
            end
            if effect.duration then
                effect.duration = math.ceil(effect.duration * enchantCapacityEffect)
            end
        end
    end
end

function Loot:applyMultipliers()
    for _, modifier in ipairs(self.modifiers) do
        if modifier.multipliers then
            for field, multiplier in pairs(modifier.multipliers) do
                if self.object[field] and type(self.object[field] == "number") then
                    local newValue = self.object[field] * multiplier
                    local rounding = config.multiplierFieldDecimals[field] or 0
                    newValue = math.round(newValue, rounding)
                    self.object[field] = newValue
                end
            end
        end
    end
end

---@param name string
function Loot:removeMaterialNames(name)
    local lowerName = name:lower()
    logger:trace("lowerName: %s", lowerName)
    --prefixes
    for _, material in ipairs(config.materialPrefixes) do
        if string.startswith(lowerName, (material .. " ")) then
            logger:trace("Removing material prefix: %s", material)
            return name:sub(#material + 2)
        end
    end
    --suffixes
    for _, material in ipairs(config.materialSuffixes) do
        if string.endswith(lowerName, material) then
            logger:trace("Removing material suffix: %s", material)
            return name:sub(1, #name - #material)
        end
    end

    return name
end

function Loot:getLootName(e)
    e = e or { wild = self.wild }
    logger:trace("Getting loot name")

    local maxLength = 31
    if e.wild then
        logger:trace("Creating name with wild prefix")
        maxLength = maxLength - string.len(" (д.)")
    end
	
	    -- Функция для перевода строки в нижний регистр
    local function toLowerCyrillic(str)
        local upperToLower = {
            ['А'] = 'а', ['Б'] = 'б', ['В'] = 'в', ['Г'] = 'г', ['Д'] = 'д',
            ['Е'] = 'е', ['Ё'] = 'ё', ['Ж'] = 'ж', ['З'] = 'з', ['И'] = 'и',
            ['Й'] = 'й', ['К'] = 'к', ['Л'] = 'л', ['М'] = 'м', ['Н'] = 'н',
            ['О'] = 'о', ['П'] = 'п', ['Р'] = 'р', ['С'] = 'с', ['Т'] = 'т',
            ['У'] = 'у', ['Ф'] = 'ф', ['Х'] = 'х', ['Ц'] = 'ц', ['Ч'] = 'ч',
            ['Ш'] = 'ш', ['Щ'] = 'щ', ['Ъ'] = 'ъ', ['Ы'] = 'ы', ['Ь'] = 'ь',
            ['Э'] = 'э', ['Ю'] = 'ю', ['Я'] = 'я'
        }

        local result = ""
        for i = 1, #str do
            local char = str:sub(i, i)
            result = result .. (upperToLower[char] or char:lower())
        end
        return result
    end
	
	-- Функция для перевода первой буквы строки в верхний регистр
    local function capitalizeFirstLetter(str)
        local lowerToUpper = {
            ['а'] = 'А', ['б'] = 'Б', ['в'] = 'В', ['г'] = 'Г', ['д'] = 'Д',
            ['е'] = 'Е', ['ё'] = 'Ё', ['ж'] = 'Ж', ['з'] = 'З', ['и'] = 'И',
            ['й'] = 'Й', ['к'] = 'К', ['л'] = 'Л', ['м'] = 'М', ['н'] = 'Н',
            ['о'] = 'О', ['п'] = 'П', ['р'] = 'Р', ['с'] = 'С', ['т'] = 'Т',
            ['у'] = 'У', ['ф'] = 'Ф', ['х'] = 'Х', ['ц'] = 'Ц', ['ч'] = 'Ч',
            ['ш'] = 'Ш', ['щ'] = 'Щ', ['ъ'] = 'Ъ', ['ы'] = 'Ы', ['ь'] = 'Ь',
            ['э'] = 'Э', ['ю'] = 'Ю', ['я'] = 'Я'
        }

        if #str == 0 then
            return str
        end

        local firstChar = str:sub(1, 1)
        firstChar = lowerToUpper[firstChar] or firstChar:upper()

        return firstChar .. str:sub(2)
    end

    local baseName = self.baseObject.name
    baseName = toLowerCyrillic(baseName)
	baseName = self:removeMaterialNames(baseName)
    local name
    local function appendPrefixSuffix()
        name = baseName
        for _, modifier in ipairs(self.modifiers) do
            if modifier.prefix then
                logger:trace("Appending prefix '%s'", modifier.prefix)
                name = string.format("%s%s", name, modifier.prefix)
                logger:trace("Prefixed Name: %s", name)
            end
        end
        for _, modifier in ipairs(self.modifiers) do
            if modifier.suffix then
                logger:trace("Appending suffix '%s'", modifier.suffix)
                name = string.format("%s%s", name, modifier.suffix)
                logger:trace("Suffixed Name: %s", name)
            end
        end
	end

    appendPrefixSuffix()

    if e.wild then
        name = string.format("%s (д.)", name)
    end

	name = capitalizeFirstLetter(name)
	
    logger:trace("Loot name: %s", name)
    return name
end

---@param effects Drip.Modifier.Effect[]
function Loot:mergeEffects(effects)
    --Compare effects in list to find duplicates
    local duplicates = {}
    for i, effectOuter in ipairs(effects) do
        for j, effectInner in ipairs(effects) do
            if j > i then --only look at effects after this one to avoid checking twice
                if effectOuter.id == effectInner.id then
                    if effectOuter.skill then
                        if effectOuter.skill == effectInner.skill then
                            table.insert(duplicates, {first = i, second = j})
                        end
                    end
                end
            end
        end
    end

    --Merge magnitudes of duplicates and remove
    for _, duplicate in ipairs(duplicates) do
        local effectOuter = effects[duplicate.first]
        local effectInner = effects[duplicate.second]
        effectOuter.min = effectOuter.min + effectInner.min
        effectOuter.max = effectOuter.max + effectInner.max
        table.remove(effects, duplicate.second)
    end
end

---@param modifiers Drip.Modifier[]
function Loot:buildEnchantmentEffects(modifiers)
    local effects = {}
    for _, modifier in ipairs(modifiers) do
        if modifier.effects then
            for _, effect in ipairs(modifier.effects) do
                table.insert(effects, effect)
            end
        end
    end
    logger:assert(#effects <= 8, "Too many effects combined!")
    return effects
end

function Loot:getEnchantmentValues(modifiers)
    local values = {
        chargeCost = 10,
        maxCharge = 100,
        castType = tes3.enchantmentType.onUse,
        effects = self:buildEnchantmentEffects(modifiers)
    }
    for _, modifier in ipairs(modifiers) do
        if modifier.chargeCost then
            values.chargeCost = values.chargeCost + modifier.chargeCost
        end
        if modifier.maxCharge then
            values.maxCharge = values.maxCharge + modifier.maxCharge
        end
        if modifier.castType then
            values.castType = modifier.castType or values.castType
        end
    end
    if #modifiers > 1 then
        values.chargeCost = values.chargeCost / #modifiers
        values.maxCharge = values.maxCharge / #modifiers
    end
    return values
end

---@return tes3enchantment|nil
function Loot:makeComplexEnchantment(modifiers)
    local enchantmentValues = self:getEnchantmentValues(modifiers)
    if #enchantmentValues.effects == 0 then return end
    logger:debug("castType: %s", enchantmentValues.castType)
    local enchantment = tes3.createObject{
        objectType = tes3.objectType.enchantment,
        castType = enchantmentValues.castType or tes3.enchantmentType.constant,
        effects = enchantmentValues.effects or {},
        maxCharge = enchantmentValues.maxCharge or 100,
        chargeCost = enchantmentValues.chargeCost or 10,
    }
    ---@cast enchantment tes3enchantment
    enchantment.modified = true
    return enchantment
end



---@param ownerReference tes3reference
---@param stack tes3itemStack
---@param itemData? tes3itemData
function Loot:replaceLootInInventory(ownerReference, stack, itemData)
    logger:debug("Replacing loot in inventory. Has itemdata? %s", itemData ~= nil)
    local count = 1
    --Enchant whole stack if its ammunition
    if self.object.objectType == tes3.objectType.ammunition then
        logger:debug("Enchanting whole stack of ammo")
        count = stack.count
    end

    logger:debug("count: %s", count)
    --Add loot to inventory
    tes3.addItem{
        reference = ownerReference,
        item = self.object, ---@diagnostic disable-line: assign-type-mismatch
        count = count,
        playSound = false,
    }
    -- if itemData then
    --     logger:debug("Copying item data")
    --     common.copyItemData{
    --         baseObject = self.baseObject,
    --         object = self.object,
    --         itemData = itemData
    --     }
    -- end

    if ownerReference.mobile then
        if ownerReference.object:hasItemEquipped(stack.object) then
            logger:debug("Has a mobile")
            ownerReference.mobile:unequip{ item = stack.object}
            logger:debug("Unequipping %s and equipping %s", stack.object.name, self.object.name)
            ownerReference.mobile:equip{ item = self.object }
            ownerReference:updateEquipment()
        end
    end

    --Remove the object from the inventory
    if count >= 0 then
        ---@diagnostic disable-next-line: deprecated
        mwscript.removeItem{
            reference = ownerReference,
            item = stack.object,
            count = count,
            playSound = false,
            itemData = itemData
        }
    else
        --use "addItem" to remove if count is negative
        ---@diagnostic disable-next-line: deprecated
        tes3.addItem{
            reference = ownerReference,
            item = stack.object,
            count = count,
            playSound = false,
        }
    end
    --register on player data
    logger:debug("Adding %s to generatedLoot list", self.object.id:lower())
    self:persist()
    --if original object had modifiers, add it to the list of generated loot
    if config.persistent.generatedLoot[self.baseObject.id:lower()] then
        logger:debug("Adding %s to generatedLoot list", self.baseObject.id:lower())
        local baseLootConfig = config.persistent.generatedLoot[self.baseObject.id:lower()]
        local newLootConfig = config.persistent.generatedLoot[self.object.id:lower()]
        for _, modifierId in ipairs(baseLootConfig.modifiers) do
            table.insert(newLootConfig.modifiers, modifierId)
        end
    end
end

function Loot:persist()
    local modifierIds = {}
    --store modified by string
    for _, modifier in ipairs(self.modifiers) do
        table.insert(modifierIds, modifier.id)
    end
    config.persistent.generatedLoot[self.object.id:lower()] = {
        modifiers = modifierIds,
    }
end


return Loot