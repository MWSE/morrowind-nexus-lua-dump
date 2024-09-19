--[[

Mod: Scrollable Weapons and Spells
Author:Nitro

--]]

local aux_util = require("openmw_aux.util")
local core = require("openmw.core")
local self = require("openmw.self")
local storage = require("openmw.storage")
local types = require("openmw.types")
local ui = require("openmw.ui")
local ambient = require("openmw.ambient")
local input = require("openmw.input")

local modInfo = require("Scripts.ScrollHotKeyCombo.modInfo")

local playerSettings = storage.playerSection("SettingsPlayer" .. modInfo.name)
local userInterfaceSettings = storage.playerSection("SettingsPlayer" .. modInfo.name .. "UI")
local controlsSettings = storage.playerSection("SettingsPlayer" .. modInfo.name .. "Controls")
local gameplaySettings = storage.playerSection("SettingsPlayer" .. modInfo.name .. "Gameplay")

local Actor = types.Actor
local Armor = types.Armor
local Item = types.Item
local Weapon = types.Weapon
local Clothing = types.Clothing
local Book = types.Book
local SLOT_CARRIED_RIGHT = Actor.EQUIPMENT_SLOT.CarriedRight


local weaponHotKeyPressed = false
local spellHotKeyPressed = false

local debug = true
local function d_message(msg)
	if not debug then return end

	ui.showMessage(tostring(msg))
end

local function d_print(fname, msg)
	if not debug then return end

	if fname == nil then
		fname = "\x1b[35mnil"
	end

	if msg == nil then
		msg = "\x1b[35mnil"
	end

	print("\n\t\x1b[33;3m" .. tostring(fname) .. "\n\t\t\x1b[33;3m" .. tostring(msg) .. "\n\x1b[39m")
end

local WEAPON_TYPES_TWO_HANDED = {
	[Weapon.TYPE.LongBladeTwoHand] = true,
	[Weapon.TYPE.BluntTwoClose] = true,
	[Weapon.TYPE.BluntTwoWide] = true,
	[Weapon.TYPE.SpearTwoWide] = true,
	[Weapon.TYPE.AxeTwoHand] = true,
	[Weapon.TYPE.MarksmanBow] = true,
	[Weapon.TYPE.MarksmanCrossbow] = true,
}

local trinkets = {
	[Clothing.TYPE.Amulet] = true,
	[Clothing.TYPE.Ring] = true,
}

local WEAPON_SOUNDS = {
    [Weapon.TYPE.AxeOneHand] = "Item Weapon Blunt Up",
    [Weapon.TYPE.AxeTwoHand] = "Item Weapon Blunt Up",
    [Weapon.TYPE.BluntOneHand] = "Item Weapon Blunt Up",
    [Weapon.TYPE.BluntTwoClose] = "Item Weapon Blunt Up",
    [Weapon.TYPE.BluntTwoWide] = "Item Weapon Blunt Up",
    [Weapon.TYPE.LongBladeOneHand] = "Item Weapon Longblade Up",
    [Weapon.TYPE.LongBladeTwoHand] = "Item Weapon Longblade Up",
    [Weapon.TYPE.MarksmanBow] = "Item Weapon Bow Up",
    [Weapon.TYPE.MarksmanCrossbow] = "Item Weapon Bow Up",
    [Weapon.TYPE.MarksmanThrown] = "Item Weapon Blunt Up",
    [Weapon.TYPE.ShortBladeOneHand] = "Item Weapon Shortblade Up",
    [Weapon.TYPE.SpearTwoWide] = "Item Weapon Spear Up",
}

local function isTrinket(clothing)
	return (clothing)
		and (Clothing.objectIsInstance(clothing))
		and (trinkets[Clothing.record(clothing).type])
end

local function isScroll(book)
	return (book)
		and (Book.objectIsInstance(book))
end

local function message(msg, _)
	if (userInterfaceSettings:get("showMessages")) then ui.showMessage(msg) end
end

--Function which returns the weapon id when provided a weapon object
local function weapID(weapon)
	if weapon and Weapon.objectIsInstance(weapon) then -- not sure what this really does
    return Weapon.record(weapon).id -- Use the weapon's unique ID
	end
end

local function spellID(spell)
	if spell and spell.type then
		return spell.id
	end
end

local function enchantedID(enchantedItem)
	--enchantedItem should be of the form: item.type.records[item.recordId].enchant
	return core.magic.enchantments.records[enchantedItem]
end

local function getEnchantment(id) --
    return core.magic.enchantments.records[id]
end


--Finds the enchantment
local function FindEnchantment(item)
	--Added or item.type == 0 for spells
	--Added or item.type == 5 for powers
    if (item == nil or item.type == nil or item.type == 0 or item.type == 5 or item.type.records[item.recordId] == nil or item.type.records[item.recordId].enchant == nil or item.type.records[item.recordId].enchant == "") then
        return nil
    end
    return getEnchantment(item.type.records[item.recordId].enchant)
end

--my new sorting function:
local function sortWeapons(weaponListToSort, sortDirection, debug)
	-- Step 1: Create a new table with weapon names and their corresponding objects
	local weaponsWithNames = {}
	local getSort = sortDirection
	for _, weapon in pairs(weaponListToSort) do
		local weaponName = Weapon.record(weapon).name
		table.insert(weaponsWithNames, { weapon = weapon, name = weaponName })
	end

	-- Step 2: Define a comparison function for sorting
	local function compareWeapons(a, b)
		if getSort == 'descend' or getSort == 2 then --User input of either ascend or 1 or nil returns alphabetical sort
			return a.name > b.name
		else
			return a.name < b.name
		end
	end

	-- Step 3: Sort the table based on weapon names
	table.sort(weaponsWithNames, compareWeapons)

	-- Step 4: Extract the sorted weapon objects if needed
	local sortedWeapons = {}
	for i, weaponData in ipairs(weaponsWithNames) do
		table.insert(sortedWeapons, weaponData.weapon)
	end

	if debug then
		-- Print sorted weapon names for verification
		for i, weapon in ipairs(sortedWeapons) do
			print("Sorted Weapon:", Weapon.record(weapon).name)
		end
	end

	return sortedWeapons
end

local function equip(slot, object)
    local equipment = Actor.equipment(self)
    equipment[slot] = object
    Actor.setEquipment(self, equipment)
	--the following line plays the proper sound when weapon is equipped
	ambient.playSound(WEAPON_SOUNDS[Weapon.record(object).type])
end

local function equipSpell(object, debug)
	--local mySpell = object
	--non valid object types return 0!!
	if debug then
		print("object:", object, "type:", object.type ,"record:", (object.type ~= 0) and object.type.record(object))
		print(types[tostring(object.type)]) --returns nil if not a valid object.type
	end

	local record = types[tostring(object.type)] and types[tostring(object.type)].record(object) or nil

	if (record and record.enchant) then
		Actor.setSelectedEnchantedItem(self, object)
	else
		--running into an issue where I cannot setSelectedSpell when an echanteditem is selected..
		Actor.setSelectedSpell(self, object)
	end
end

local function NextItem(itemList, getCurrent, equipItem, isSpell, debug)
    local currentItem, currentEnchItem = getCurrent()
    local foundEquipped = false
    local repeatItems = {}
	local prevItem

    if debug then
        print("Current item:", currentItem and currentItem or currentEnchItem)
    end

    if not itemList then return end
    for _, item in pairs(itemList) do
        local key = isSpell and tostring(item) or weapID(item)
		if debug then
			print("Current key:", key)
		end
        if foundEquipped then
            if not repeatItems[key] then
				if debug then
					print("Attempting to Equip Item...", key)
					print("enchID:", FindEnchantment(prevItem), "item.type:", item.type)
				end
				if isSpell and FindEnchantment(prevItem) ~= nil and (item.type == 0 or item.type == 5) then --item.type = 0 means its a spell. 
					Actor.clearSelectedCastable(self)
					equipItem(item)
					return
				else
					equipItem(item)
					return
				end
            end
        elseif key == (isSpell and tostring(currentItem) or weapID(currentItem)) or key == (isSpell and tostring(currentEnchItem) or weapID(currentItem)) then
            foundEquipped = true
			prevItem = item
			--print("PreviousItemType:",prevItem.type)
        end
        repeatItems[key] = true
    end

    for _, item in pairs(itemList) do
        local key = isSpell and tostring(item) or weapID(item)
        if repeatItems[key] then
			if isSpell then
				Actor.clearSelectedCastable(self)
				equipItem(item)
				return
			else
				equipItem(item)
				return
			end
        end
    end
end

local function NextSpell(spellList, debug)
    local getCurrentSpell = function() return Actor.getSelectedSpell(self), Actor.getSelectedEnchantedItem(self) end
    local equipMySpell = function(spell) equipSpell(spell) end
    NextItem(spellList, getCurrentSpell, equipMySpell, true, debug)
end

local function NextWeapon(meleeWeapons, debug)
    local getCurrentWeapon = function() return Actor.equipment(self)[SLOT_CARRIED_RIGHT] end
    local equipWeapon = function(weapon) equip(SLOT_CARRIED_RIGHT, weapon) end
    NextItem(meleeWeapons, getCurrentWeapon, equipWeapon, false, debug)
end

--Function that sorts all weapons obtained from player and filters out arrows
local function getNonArrowWeapons(weaponList, debug)
		-- Color codes for formatting
		local colorReset = "\x1b[0m"
		local colorIndex = "\x1b[33m"  -- Yellow for index
		local colorObject = "\x1b[35m" -- Purple for object
		local colorType = "\x1b[36m"   -- Cyan for type
		local nonArrows = {}
		local ldebug
		if debug then
			ldebug = true
		else
			ldebug = false
		end
		for i, weapon in ipairs(weaponList) do
			local weaponRecord = Weapon.record(weapon)
			local weaponType = weaponRecord and weaponRecord.type or "Unknown"
			local weapon_ID = weaponRecord.id
			--Weapon type 12 is arrows
			if weaponType ~= 12 then
				if ldebug then
					print(colorIndex .. "[" .. i .. "]" .. colorReset .. " = " .. colorObject .. tostring(weapon) .. colorReset .. " (" .. colorType .. Weapon.record(weapon).name .. colorReset .. "), " 
								.. Weapon.record(weapon).type .. " || " .. weapon_ID)
				end
				nonArrows[i] = weapon
			end
		end
	return nonArrows
end

local function getEnchantItems(object, filterFunc)
	local enchItems = {}
	for k, v in pairs(object) do  --object[k] == v; k is just the index when used in this context
		local mytype = v.type
		if mytype then
			local recordType = types[tostring(mytype)] -- may be able to get away with just straight passing myType to record(v) need to test
			if (recordType == Armor or recordType == Clothing or recordType == Weapon or recordType == types.Book) then
				local record = recordType.record(v)
				local ench = record.enchant and	core.magic.enchantments.records[record.enchant] or "No Enchantment"
				--print("\nID:",record.id,"\nNAME:", record.name, "\nEnchant:", record.enchant,
					--"\ngetEnchantment:", ench, "\nEnchantment Type:", ench.type)
				if ench.type == core.magic.ENCHANTMENT_TYPE.CastOnUse or ench.type == core.magic.ENCHANTMENT_TYPE.CastOnce then
					local enchName = record.name
					if not filterFunc or filterFunc(v)then
						table.insert(enchItems, {obj = v, name = enchName})
					end
				end
			end
		end
	end

	table.sort(enchItems, function(a, b) return a.name < b.name end)
    -- Remove the 'name' field after sorting
    -- Flatten the table to only include objects
    local flattenedItems = {}
    for _, item in ipairs(enchItems) do
        --print("FlattenedItems:",item.obj)
		table.insert(flattenedItems, item.obj)
    end

    return flattenedItems
end

local function getSpellsAndPowers(totalSpells)
	if totalSpells == nil then return end
	local allSpells = totalSpells
	local spells = {}
	local powers = {}
	-- Assume allSpells is a table containing the actor's spells
	for _, spell in pairs(allSpells) do
		if spell.type == core.magic.SPELL_TYPE.Spell then
			table.insert(spells, spell)
		elseif spell.type == core.magic.SPELL_TYPE.Power then
			table.insert(powers, spell)
		end
	end

	-- Sort spells and powers based on their name
	table.sort(spells, function(a, b) return a.name < b.name end)
	table.sort(powers, function(a, b) return a.name < b.name end)

	return spells, powers
end

local function reverseTable(t)
    local reversed = {}
    for i = #t, 1, -1 do
        table.insert(reversed, t[i])
    end
    return reversed
end

local function onKeyPress(key)
	--need to set up a few logicals to pickup the weapon, spell, or enchanted item hotkey.
	--can extend the hot key to differentiate between scrolls, enchanted items, spells
	--can add option to disregard non-ring or neck piece items
	--Need to have option to have Default Behavior, e.g. 1 hotkey for all spells, powers, and enchanted items
	local WEAPSCROLL_HOTKEY = controlsSettings:get("nextWeaponHotKey")
	local SPELLSCROLL_HOTKEY = controlsSettings:get("nextSpellHotKey")
	if (not playerSettings:get("modEnable")) or ((key.code ~= WEAPSCROLL_HOTKEY) and (key.code ~= SPELLSCROLL_HOTKEY)) or core.isWorldPaused()  then return end

	if  (key.code == WEAPSCROLL_HOTKEY) then
		weaponHotKeyPressed = true
	end
	if (key.code == SPELLSCROLL_HOTKEY) then
		spellHotKeyPressed = true
	end

end

local function onKeyRelease(key)
    local WEAPSCROLL_HOTKEY = controlsSettings:get("nextWeaponHotKey")
	local SPELLSCROLL_HOTKEY = controlsSettings:get("nextSpellHotKey")
	if (not playerSettings:get("modEnable")) or ((key.code ~= WEAPSCROLL_HOTKEY) and (key.code ~= SPELLSCROLL_HOTKEY)) or core.isWorldPaused() then return end

	if key.code == WEAPSCROLL_HOTKEY then
		weaponHotKeyPressed = false
	elseif key.code == SPELLSCROLL_HOTKEY then
		spellHotKeyPressed = false
	end
end

local function onMouseWheel(vertical, horizontal)
	local vert = vertical

	if weaponHotKeyPressed and not input.isActionPressed(input.ACTION.Use) then
		local weaponList = Actor.inventory(self):getAll(Weapon)
		local myWeapons = getNonArrowWeapons(weaponList)
		local test = false

        if vert > 0 then
			local fwdSortedWeapons = sortWeapons(myWeapons, _, test) or "noDataYet"
            NextWeapon(fwdSortedWeapons, test) -- Call your function to switch to the next weapon
        elseif vert < 0 then
			local revSortedWeapons = sortWeapons(myWeapons, 2, test) or "noDataYet"
            NextWeapon(revSortedWeapons, test) -- Call your function to switch to the previous weapon
        end
    end

	if spellHotKeyPressed and not input.isActionPressed(input.ACTION.Use) then
		local allSpells = Actor.spells(self)
		local spells, powers = getSpellsAndPowers(allSpells)
		local invItems = Actor.inventory(self):getAll()
		local enchantedItemsFromInv = getEnchantItems(invItems)
		local enchantedTrinkets = getEnchantItems(invItems, isTrinket)
		local noScrolls = getEnchantItems(invItems, function(item) return not isScroll(item) end)
		local combinedList = {}
		local EnchantState = gameplaySettings:get("enchantSelect")
		local trinketState = gameplaySettings:get("trinketsOnly")
		local scrollState = gameplaySettings:get("excludeScrolls")

		--Logic that combines powers, spells and enchanted items
		if powers ~= nil and gameplaySettings:get("powerSelect") then
			for _, power in pairs(powers) do
				table.insert(combinedList, power)
			end
		end
		if spells ~= nil and gameplaySettings:get("spellSelect") then
			for _, spell in pairs(spells) do
				table.insert(combinedList, spell)
			end
		end

		if EnchantState and scrollState and not trinketState then
			-- Copy elements from enchantedItemsFromInv to combined
			for _, item in pairs(noScrolls) do
				table.insert(combinedList, item)
			end
		elseif EnchantState and trinketState then
			for _, item in pairs(enchantedTrinkets) do
				--print(item)
				table.insert(combinedList, item)
			end
		elseif EnchantState and not trinketState then
			for _, item in pairs(enchantedItemsFromInv) do
				table.insert(combinedList, item)
			end
		end

		local rev = reverseTable(combinedList)
        if vert > 0 then
			--NextSpell is working, need to adopt it to enchanted items
			NextSpell(combinedList)
        elseif vert < 0 then
			--pass reversed list of spells to NextSpell
			NextSpell(rev)
        end
    end
end

return {
	engineHandlers = {
		onKeyPress = onKeyPress,
		onKeyRelease = onKeyRelease,
		onMouseWheel = onMouseWheel,
	}
}
