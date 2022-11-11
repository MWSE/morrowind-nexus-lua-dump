--[[
Rings are given enchanting tiers
(1 = No Enchantment, 2 = On Use Enchantment, 3 = Constant Enchantment).
When you have the maximum number of rings already equipped and you equip another ring,
a lower tier ring will be unequipped if available to avoid the risk of unequipping a higher tier ring.
]]

local author = 'abot'
local modName = 'Smart Rings'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local defaultConfig = {
disabled = false,
logLevel = 0,
}

--[[local function logConfig(config, options)
	mwse.log(json.encode(config, options))
end]]

local config = mwse.loadConfig(configName, defaultConfig)

 -- updated in modConfigReady()
local disabled = config.disabled
local logLevel = config.logLevel

local tes3_objectType_clothing = tes3.objectType.clothing
local tes3_clothingSlot_ring = tes3.clothingSlot.ring
local tes3_enchantmentType_constant = tes3.enchantmentType.constant
---local tes3_enchantmentType_onUse = tes3.enchantmentType.onUse

local castTypes = table.invert(tes3.enchantmentType)

 -- set in loaded()
local player, mobilePlayer

-- set in modConfigReady()
local maxEquippedRings = 2
---local inputController

local function getTier(ench)
	local castType = ench.castType
	local result = 1
	if ench then
		if castType then
			if castType == tes3_enchantmentType_constant then
				result = 3
			else
				result = 2
			end
		end
	end
	if logLevel > 0 then
		local castTypeString = ''
		if castType then
			castTypeString = string.format(' ench.castType = %s (%s)', castType, castTypes[castType])
		end
		mwse.log('%s: getTier()%s tier = %s', modPrefix, castTypeString, result)
	end
	return result
end

local function getRingsData(tier)
	local obj, ringToUnequip
	local numEquippedRings = 0
	for _, stack in pairs(player.object.equipment) do
		obj = stack.object
		if obj.objectType == tes3_objectType_clothing then
			if obj.slot == tes3_clothingSlot_ring then
				if logLevel > 1 then
					mwse.log('%s: getRingsData(%s) obj.id = %s', modPrefix, tier, obj.id)
				end
				numEquippedRings = numEquippedRings + 1
				if not ringToUnequip then
					if getTier(obj.enchantment) <= tier then
						ringToUnequip = obj.id:lower()
						if logLevel > 1 then
							mwse.log('%s: getRingsData(%s) ringToUnequip = %s', modPrefix, tier, ringToUnequip)
						end
					end
				end
			end
		end
	end
	if logLevel > 0 then
		mwse.log('\n%s: getRingsData(%s) numEquippedRings = %s, ringToUnequip = %s', modPrefix, tier, numEquippedRings, ringToUnequip)
	end
	return numEquippedRings, ringToUnequip
end

---local skipOnce = false


--[[
local GUI_ID_MenuInventory = tes3ui.registerID('MenuInventory')
local function updateInventory()
	local menu = tes3ui.findMenu(GUI_ID_MenuInventory)
	if menu then
		menu:updateLayout()
		tes3ui.updateInventoryTiles()
	end
	tes3.updateInventoryGUI({reference = player})
end]]

local function equip(e)
	if disabled then
		return
	end
	--[[if skipOnce then
		skipOnce = false
		return
	end]]
	if not (e.reference == player) then
		return
	end
	local obj = e.item
	if not (obj.objectType == tes3_objectType_clothing) then
		return
	end
	local objSlot = obj.slot
	if not objSlot then
		assert(objSlot)
		return
	end
	if not (objSlot == tes3_clothingSlot_ring) then
		return
	end
	local ench = obj.enchantment
	if ench then
		if ench.castType == tes3_enchantmentType_constant then
			return
		end
	end

	local ringId = obj.id:lower()

	if logLevel > 0 then
		mwse.log('\n%s: equip() "%s" "%s"', modPrefix, ringId, obj.name)
	end

	local tier = getTier(ench)
	local numEquippedRings, ringToUnequip = getRingsData(tier)
	if numEquippedRings < maxEquippedRings then
		if logLevel > 1 then
			mwse.log('%s: equip(e) numEquippedRings (%s) < maxEquippedRings (%s), skip', modPrefix, numEquippedRings, maxEquippedRings)
		end
		return
	end
	if not ringToUnequip then
		return
	end
	if ringId == ringToUnequip then
		return
	end
	if logLevel > 0 then
		mwse.log('%s: equip(e) tier = %s, mobilePlayer:unequip({item = "%s"})', modPrefix, tier, ringToUnequip)
	end
	----local menuMode = tes3ui.menuMode()
	---if menuMode then
		---updateInventory()
	---end
	---updateInventory()

	-- add/remove an object to avoid inventory glitches
	---tes3.AddItem({reference = player, item = 'Misc_Quill', count = 1}) -- nope, buggy
---@diagnostic disable-next-line: deprecated
	mwscript.addItem({ reference = player, item = 'Misc_Quill', count = 1 })
	tes3.removeItem({reference = player, item = 'Misc_Quill', count = 1})

	mobilePlayer:unequip({item = ringToUnequip})
	---timer.start({duration = 0.3, type = timer.real,	callback = updateInventory})
end

local function loaded()
	player = tes3.player
	mobilePlayer = tes3.mobilePlayer
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end

local function modConfigReady()

	maxEquippedRings = 2
	if tes3.hasCodePatchFeature(tes3.codePatchFeature.onUseRingExtraSlot) then
		maxEquippedRings = 3
		if logLevel > 0 then
			mwse.log('%s Code Patch onUseRingExtraSlot option detected', modPrefix)
		end
	end

	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		disabled = config.disabled
		logLevel = config.logLevel
		mwse.saveConfig(configName, config, {indent = false})
	end

	local preferences = template:createSideBarPage({
		label='Preferences',
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.0
			self.elements.sideToSideBlock.children[2].widthProportional = 1.0
		end
	})

	local sidebar = preferences.sidebar
	sidebar:createInfo({text =
[[Rings are given enchanting tiers
(1 = No Enchantment, 2 = On Use Enchantment, 3 = Constant Enchantment).
When you have the maximum number of rings already equipped and you equip another ring,
a lower tier ring will be unequipped if available to avoid the risk of unequipping a higher tier ring.]]})

	local controls = preferences:createCategory({label = ""})

	controls:createYesNoButton({
		label = 'Disabled',
		description = 'A toggle to enable/disable the mod effects. Default: No.',
		variable = createConfigVariable('disabled')
	})
	controls:createDropdown({
		label = "Logging level:",
		options = {
			{ label = "0. Minimum", value = 0 },
			{ label = "1. Low", value = 1 },
			{ label = "2. Medium", value = 2 },
		},
		variable = createConfigVariable("logLevel"),
		description = "Default: 0. Minimum."
	})

	mwse.mcm.register(template)

	event.register('equip', equip)
	event.register('loaded', loaded)
end
event.register('modConfigReady', modConfigReady)
