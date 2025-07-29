local log = require("OperatorJack.MagickaExpanded.utils.logger")

local this = {}

this.doesIconExist = function(path) return tes3.getFileExists("icons\\" .. path) end

this.checkParams = function(params)
    if (params.icon and this.doesIconExist(params.icon) == false) then
        log:error(
            "Effect disabled. Icon does not exist for effect, path: " .. params.name .. ", " ..
                params.icon)
        return false
    end
    if (params.icon and string.len(params.icon) > 32) then
        log:error("Effect disabled. Icon path longer than 32 characters for effect, path: " ..
                      params.name .. ", " .. params.icon)
        return false
    end
    return true
end

---@type tes3spell[]
this.spells = {}

---@type tes3spell[]
this.distribution = {}

---@type tes3alchemy[]
this.potions = {}

---@type tes3enchantment[]
this.enchantments = {}

---@type { [string]: boolean}
this.boundItemsByObject = {}

---@type { [string]: tes3weapon} Key-value table of weapons, where key is the related effect ID and value is the weapon.
this.boundWeapons = {}

---@type { [string]: tes3armor} Key-value table of armors, where key is the related effect ID and value is the armor.
this.boundArmors = {}

--[[Adds the spell the the MagickaExpanded tracking list for the given effect.]]
---@param spell tes3spell
this.addSpellToSpellsList = function(spell) table.insert(this.spells, spell) end

--[[Adds the spell the the MagickaExpanded spell distribution list for the spell. Spells in this list are automatically distributed to NPCs at random.]]
---@param spell tes3spell
this.addSpellToDistributionList = function(spell) table.insert(this.distribution, spell) end

this.addTestSpellsToPlayer = function()
    for i = 1, #this.spells do
        local spell = this.spells[i]
        if (spell.castType ~= tes3.spellType.disease) then
            tes3.addSpell({reference = tes3.player, spell = spell, updateGUI = false})
        end
    end
    tes3.updateMagicGUI({reference = tes3.player})
end

--[[Adds the potion the the MagickaExpanded tracking list for the given effect.]]
---@param potion tes3alchemy 
this.addPotionToPotionsList = function(potion) table.insert(this.potions, potion) end

--[[Adds the enchantment the the MagickaExpanded tracking list for the given effect.]]
---@param enchantment tes3enchantment 
this.addEnchantmentToEnchantmentsList = function(enchantment)
    table.insert(this.enchantments, enchantment)
end

--[[Adds the bound weapon the the MagickaExpanded tracking list for the given effect.]]
---@param effectId string The effect ID 
---@param weapons string[] List of Armor Ids used by the effect. Maximum of two.
this.addBoundWeaponToBoundWeaponsList = function(effectId, weapons)
    if (#weapons > 2) then
        log:error("Invalid number of weapons for effect id: %s, count: %s", effectId, #weapons)
        return
    end
    this.boundWeapons[effectId] = weapons
    for _, value in ipairs(weapons) do this.boundItemsByObject[value] = true end
end

--[[Adds the bound armor the the MagickaExpanded tracking list for the given effect.]]
---@param effectId string The effect ID 
---@param armors string[] List of Armor Ids used by the effect. Maximum of two.
this.addBoundArmorToBoundArmorsList = function(effectId, armors)
    if (#armors > 2) then
        log:error("Invalid number of armors for effect id: %s, count: %s", effectId, #weapons)
        return
    end
    this.boundArmors[effectId] = armors
    for _, value in ipairs(armors) do this.boundItemsByObject[value] = true end
end

--[[ Checks if the reference object has the given spell ID.]]
---@param reference tes3reference
---@param spellId string
---@return boolean
this.hasSpell = function(reference, spellId)
    if (reference.object.spells:contains(spellId)) then return true end
    return false
end

return this
