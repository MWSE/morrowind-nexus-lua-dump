local common = require("mer.drip.common")
local config = common.config
local logger = common.createLogger("Loot")

---@type dripLoot
local Loot = {}



---@param lootData dripLootData
function Loot:new(lootData)
    logger:debug("Creating new loot for %s", lootData.baseObject.name)
    local loot = setmetatable(lootData, self)
    self.__index = self
    --Create the tes3object
    loot.object = loot.baseObject:createCopy{}
    if not loot.object then return nil end

    loot.object.modified = true
    --Remove any modifiers that don't share the same cast type as the first one
    local targetCastType = loot.modifiers[1].castType or tes3.enchantmentType.constant
    local modifiers = {}
    for i, modifier in ipairs(loot.modifiers) do
        logger:debug("modifier: %s", modifier.prefix or modifier.suffix)
        if (not loot.modifiers[i].castType) or loot.modifiers[i].castType == targetCastType then
            table.insert(modifiers, modifier)
        end
    end
    loot.modifiers = modifiers
    loot:applyModifications()
    loot:applyMultipliers()

    --Roll for wild

    --Try build name with wild parameter
    --If name too long, cancel wild



    loot.object.enchantment = Loot:makeComplexEnchantment(loot.modifiers)

    logger:debug("Checking for wild")
    if loot:canHaveWild() and loot:rollForWild() then
        loot:applyWild()
    end

    local name = loot:getLootName{ wild = loot.wild }
    if #name > 31 then
        logger:debug("Name '%s' excedes 31 characters, cancelling Loot creation", name)
        return nil
    end
    loot.object.name = name

    loot:applyValueModifiers()

    logger:debug("Created new loot: %s", loot.object.name)
    return loot
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
    if not self.object.enchantment then return false end
    logger:debug("Making %s Wild", self.object.name)
    --Wildify the effects
    for _, effect in ipairs(self.object.enchantment.effects) do
        local wildMax = math.ceil((effect.min + effect.max) * 1.5)
        effect.min = 1
        effect.max = wildMax
    end
    self.wild = true
end

function Loot:applyValueModifiers()
    for _, modifier in ipairs(self.modifiers) do
        if modifier.value then
            self.object.value = self.object.value + modifier.value
        end
    end
    for _, modifier in ipairs(self.modifiers) do
        if modifier.valueMulti then
            self.object.value = self.object.value * modifier.valueMulti
        end
    end
    if self.wild then
        self.object.value = self.object.value * 1.5
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

function Loot:applyMultipliers()
    for _, modifier in ipairs(self.modifiers) do
        if modifier.multipliers then
            for field, multiplier in pairs(modifier.multipliers) do
                if self.object[field] and type(self.object[field] == "number") then
                    self.object[field] = math.ceil(self.object[field] * multiplier)
                end
            end
        end
    end
end

function Loot:removeMaterialPrefix(name)
    local lowerName = name:lower()
    logger:trace("lowerName: %s", lowerName)
    for _, material in ipairs(config.materials) do
        if string.startswith(lowerName, (material .. " ")) then
            logger:trace("Removing material prefix: %s", material)
            return name:sub(#material + 2)
        end
    end

    return name
    -- local split = string.split(name, " ")
    -- local prefix = split[1]:lower()
    -- if config.materials[prefix] then
    --     return string.sub(name, string.len(prefix) + 2)
    -- else
    --     return name
    -- end
end

function Loot:getLootName(e)
    logger:trace("Getting loot name")

    local maxLength = 31
    if e.wild then
        logger:trace("Creating name with wild prefix")
        maxLength = maxLength - string.len("Wild ")
    end

    local baseName = self.baseObject.name
    local name
    local function appendPrefixSuffix()
        name = baseName
        for _, modifier in ipairs(self.modifiers) do
            if modifier.prefix then
                logger:trace("Appending prefix '%s'", modifier.prefix)
                name = string.format("%s %s", modifier.prefix, name)
                logger:trace("Prefixed Name: %s", name)
            end
            if modifier.suffix then
                logger:trace("Appending suffix '%s'", modifier.suffix)
                name = string.format("%s of %s%s",
                    name,
                    modifier.the and "the " or "",
                    modifier.suffix)
                logger:trace("Suffixed Name: %s", name)
            end
        end
    end
    local attempts = 0
    appendPrefixSuffix()
    --while attempts < 10 and #name > 31 do
    while attempts < 10 and #name > maxLength do
        baseName = self:removeMaterialPrefix(baseName)
        appendPrefixSuffix()
        attempts = attempts + 1
    end

    if e.wild then
        name = string.format("Wild %s", name)
    end

    logger:trace("Loot name: %s", name)
    return name
end

---@param effects DripModifierEffect[]
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

---@param modifiers DripModifier[]
function Loot:buildEnchantmentEffects(modifiers)
    local effects = {}
    for _, modifier in ipairs(modifiers) do
        if modifier.effects then
            for _, effect in ipairs(modifier.effects) do
                table.insert(effects, effect)
            end
        end
    end
    assert(#effects <= 8, "Too many effects combined!")
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
    enchantment.modified = true
    return enchantment
end

---@param ownerReference tes3reference
---@param stack tes3itemStack
function Loot:replaceLootInInventory(ownerReference, stack)
    local count = stack.count
    logger:debug("stack.count: %s", stack.count)
    --Add loot to inventory
    tes3.addItem{
        reference = ownerReference,
        item = self.object,
        count = count,
        playSound = false,
    }

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
    if stack.count >= 0 then
        mwscript.removeItem{
            reference = ownerReference,
            item = stack.object,
            count = stack.count,
            playSound = false,
        }
    else
        --use "addItem" to remove if count is negative
        mwscript.addItem{
            reference = ownerReference,
            item = stack.object,
            count = stack.count,
            playSound = false,
        }
    end
    --register on player data
    logger:debug("Adding %s to generatedLoot list", self.object.id:lower())
    self:persist()
end

function Loot:persist()
    config.persistent.generatedLoot[self.object.id:lower()] = {
        modifiers = self.modifiers,
    }
end


return Loot