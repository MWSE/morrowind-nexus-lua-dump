local this = {}

this.doesIconExist = function(path)
	return tes3.getFileExists("icons\\" .. path)
end

this.checkParams = function(params)
	if (params.icon and this.doesIconExist(params.icon) == false) then
		this.error("Effect disabled. Icon does not exist for effect, path: " .. params.name .. ", " .. params.icon)
		return false
    end
    if (params.icon and string.len(params.icon) > 32) then
		this.error("Effect disabled. Icon path longer than 32 characters for effect, path: " .. params.name .. ", " .. params.icon)
		return false
    end
    return true
end

this.info = function (message)
    local prepend = '[Magicka Expanded: INFO] '
    mwse.log(prepend .. message)
end

this.debug = function (message)
    local prepend = '[Magicka Expanded: DEBUG] '
    mwse.log(prepend .. message)
end

this.error = function (message)
    local prepend = '[Magicka Expanded: ERROR] '
    mwse.log(prepend .. message)
end

this.spells = {}
this.potions = {}
this.enchantments = {}

this.boundWeapons = {}
this.boundArmors = {}

this.addSpellToSpellsList = function(spell)
	table.insert(this.spells, spell)
end

this.addTestSpellsToPlayer = function()
    for i = 1,#this.spells do
        local spell = this.spells[i]
		mwscript.addSpell({reference = tes3.player, spell = spell})
	end
end

this.addPotionToPotionsList = function(potion)
	table.insert(this.potions, potion)
end

this.addEnchantmentToEnchantmentsList = function(enchantment)
	table.insert(this.enchantments, enchantment)
end

this.addBoundWeaponToBoundWeaponsList = function(effectId, weaponId)
    this.boundWeapons[effectId] = weaponId
end

this.addBoundArmorToBoundArmorsList = function(effectId, armorId)
    this.boundArmors[effectId] = armorId
end

this.hasSpell = function(reference, spellId)
    if (reference.object.spells:contains(spellId)) then
        return true
    end
    return false
end

return this