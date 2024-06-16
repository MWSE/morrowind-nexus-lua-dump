require("Equipment and Items Requirements Overhaul.helpers.MCM") --EIRO MCM
local tables = require("Equipment and Items Requirements Overhaul.helpers.tables")
local mappers = require("Equipment and Items Requirements Overhaul.helpers.mappers")
local helpers = require("Equipment and Items Requirements Overhaul.helpers.helpers")
if not mappers or not mappers.attributeSkillMapping then
    error("Failed to load attributeSkillMapping")
end
-- Table to store item requirements
local itemRequirements = {}

--START QUICK FIX IMPORTS
local config = require("Equipment and Items Requirements Overhaul.config")
local formulaHelpers = require("Equipment and Items Requirements Overhaul.helpers.formulasHelpers")

local function getConfig()
    return mwse.loadConfig("Equipment_and_Items_Requirements_Overhaul_config", config)
end
local rFPN = formulaHelpers.rFPN
--END QUICK FIX IMPORTS

local objectTypeInfo = tables.objectTypeInfo
local armorClassInfo = tables.armorClassInfo
local attributeSkillMapping = mappers.attributeSkillMapping
local typeToFormula = mappers.typeToFormula

local function onEquip(e)
    local itemId = e.item.id
    local requirements = itemRequirements[itemId]

    if requirements then
        for attrName, requiredValue in pairs(requirements) do
            -- Retrieve the player's attribute value using the attributeSkillMapping function
            local playerAttribute = attributeSkillMapping[attrName] and attributeSkillMapping[attrName]() or 0
            local meetsRequirement = playerAttribute >= requiredValue

            if not meetsRequirement then
                tes3.messageBox("You do not meet the requirements to equip this item.")
                return false -- Block the equip action
            end
        end
    end
end
----
local function reqTooltip(e)
    local object = e.object
    local objectType = object.objectType

    -- Fetch the function based on the type name and execute it if available
    local attributes = {}
    local typeFormula
    if objectType == tes3.objectType.weapon or objectType == tes3.objectType.ammunition then
        typeFormula = typeToFormula[object.typeName]
    elseif objectType == tes3.objectType.armor then
        local armorClass = armorClassInfo[object.weightClass]
        if armorClass then
            typeFormula = typeToFormula[armorClass.name]
        end
    else
        local objectTypeMapped = objectTypeInfo[objectType]
        typeFormula = typeToFormula[objectTypeMapped]
    end

    if typeFormula then
        attributes = typeFormula(object)

        if e.object.enchantment then
            local enchantmentCost = helpers.getEffectiveEnchantmentCost(e.object) --e.object.enchantment.chargeCost
            attributes.Willpower = rFPN(math.ceil(120 / (1 + math.exp(-0.02 * (enchantmentCost - 100))) + 10) +
                getConfig().Attributes.willpower)
            attributes.Intelligence = rFPN(math.ceil(80 / (1 + math.exp(-0.02 * (enchantmentCost - 100))) + 10) +
                getConfig().Attributes.intelligence)
        end

        for attrName, attrValue in pairs(attributes) do
            helpers.createTooltipBlock(e, attrName, attrValue)
        end
    end

    itemRequirements[object.id] = attributes
end

--INIT-------------------------------
local function initialized()
    event.register("uiObjectTooltip", reqTooltip)
    event.register("equip", onEquip)
    print("EIRO - INITIALIZED")
end

event.register(tes3.event.initialized, initialized)
