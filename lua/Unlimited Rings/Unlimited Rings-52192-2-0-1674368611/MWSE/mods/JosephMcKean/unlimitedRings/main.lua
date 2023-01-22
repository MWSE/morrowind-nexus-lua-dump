local mod = "Unlimited Rings"
local author = "JosephMcKean"
local description = "Allows unlimited amount of rings equipped.\n\n" .. "Thanks Hrnchamd."

local configPath = mod
local defaultConfig = {
	modEnabled = true,
	limitedRings = false,
	maxRingCount = 10,
	unequipMethod = "vanilla",
	logLevel = "INFO",
}
local config = mwse.loadConfig(configPath, defaultConfig)

local log = require("logging.logger").new({ name = mod })

---@param e equipEventData
local function unequipRing(e)
	---@param maxRingCount number?
	---@return boolean?
	local function isValid(maxRingCount)
		return maxRingCount and (maxRingCount > 0)
	end
	---@param item tes3item|tes3clothing
	---@return boolean
	local function isRing(item)
		return (item.objectType == tes3.objectType.clothing) and (item.slot == tes3.clothingSlot.ring)
	end
	---@param ring tes3item|tes3clothing
	---@return number
	local function getTier(ring)
		if not ring.enchantment then
			return 1
		end
		return ring.enchantment.castType -- 2 for onUse, 3 for constant
	end
	---@param ref tes3reference
	local function getRingsEquipped(ref)
		log:debug("Scanning %s equipment", ref.id)
		local numRingsEquipped = 0
		local ringToUnequip
		local ringToUnequipItemData
		local lowestTier = 3
		local lowestValue = math.fhuge
		local lowestCharge = math.fhuge -- no enchant: -1, OU: interger, CE: 0 
		for _, equipmentStack in ipairs(ref.object.equipment) do
			if isRing(equipmentStack.object) then
				log:debug("%s is a ring equipped", equipmentStack.object.id)
				numRingsEquipped = numRingsEquipped + 1
				if config.unequipMethod == "abot" then
					local ring = equipmentStack.object
					local tier = getTier(ring)
					if tier < lowestTier then
						lowestTier = tier
						lowestValue = ring.value
						ringToUnequip = ring
						log:debug("%s has the lowest tier (%s) so far", ring.id, tier)
					elseif tier == lowestTier then
						if ring.value < lowestValue then
							lowestValue = ring.value
							lowestCharge = equipmentStack.itemData.charge
							ringToUnequip = ring
						elseif ring.value == lowestValue then
							if tier == 2 then
								if equipmentStack.itemData.charge <= lowestCharge then
									lowestCharge = equipmentStack.itemData.charge
									ringToUnequip = ring
									ringToUnequipItemData = equipmentStack.itemData
									log:debug("%s has the lowest charge (%s) among On Use rings so far", ring.id, lowestCharge)
								end
							end
						end
					end
				end
			end
		end
		log:debug("Finished scanning %s equipment, number of rings equipped is %s, %s%s", ref.id, numRingsEquipped,
		          ringToUnequip and ("ring to unequip is " .. ringToUnequip.id) or "",
		          ringToUnequipItemData and (", of charge" .. ringToUnequipItemData.charge) or "")
		return numRingsEquipped, ringToUnequip, ringToUnequipItemData
	end

	if config.limitedRings then
		local maxRingCount = tonumber(config.maxRingCount)
		if not isValid(maxRingCount) then
			log:info("Number of Limited Rings invalid. Please change it in Mod Config Menu.")
			maxRingCount = defaultConfig.maxRingCount
		end
		if isRing(e.item) then
			local numRingsEquipped, _, _ = getRingsEquipped(e.reference)
			while numRingsEquipped >= maxRingCount do
				if config.unequipMethod == "vanilla" then
					local itemUnequipped = tes3.mobilePlayer:unequip({
						type = tes3.objectType.clothing,
						clothingSlot = tes3.clothingSlot.ring,
					})
					log:debug("%s", itemUnequipped and "Unequip a ring using vanilla method" or
					          "Failed to unequip a ring using vanilla method")
					--[[elseif config.unequipMethod == "abot" then
					if ringItemData then
						log:debug("Unequip %s of charge %s", ringToUnequip.id, ringItemData.charge)
						tes3.mobilePlayer:unequip({ item = ringToUnequip, itemData = ringItemData })
					else
						log:debug("Unequip %s using Smart Rings method", ringToUnequip.id)
						tes3.mobilePlayer:unequip({ item = ringToUnequip })
					end]]
				end
				numRingsEquipped, _, _ = getRingsEquipped(e.reference)
			end
		end
	end
end

-- Thanks Hrnchamd
event.register("initialized", function()
	if config.modEnabled then
		mwse.memory.writeBytes({ address = 0x495553, bytes = { 0x90, 0xE9 } })
		mwse.memory.writeBytes({ address = 0x495A42, bytes = { 0x90, 0xE9 } })
		event.register("equip", unequipRing)
	end
end)

local function registerModConfig()
	local template = mwse.mcm.createTemplate({
		name = mod,
		headerImagePath = "MWSE/mods/JosephMcKean/unlimitedRings/headerImage.tga",
	})
	template:saveOnClose(mod, config)
	local page = template:createSideBarPage({ description = string.format("%s by %s\n\n%s", mod, author, description) })
	local category = page:createCategory(mod)
	category:createYesNoButton({
		label = "Mod Enabled",
		description = "Enable and disable the mod. Requires to restart the game" .. "(Default: Yes)",
		restartRequired = true,
		variable = mwse.mcm.createTableVariable({ id = "modEnabled", table = config }),
	})
	category:createYesNoButton({
		label = "Limited Rings",
		description = "No to unlock unlimited power.\n\n" .. "Yes to limit the number of rings actors can equip" ..
		"(Default: No)",
		variable = mwse.mcm.createTableVariable({ id = "limitedRings", table = config }),
	})
	category:createTextField({
		label = "Number of Limited Rings",
		description = "IGNORED if Limited Rings option is set to No.\n\n" ..
		"The maximum number of rings an actor can equip.\n\n" .. "The default value will be used if the input is invalid.\n\n" ..
		"(Default: 10)",
		variable = mwse.mcm.createTableVariable({ id = "maxRingCount", table = config, numbersOnly = true }),
	})
	category:createDropdown({
		label = "Unequip rings method",
		description = "IGNORED if Limited Rings option is set to No.\n\n" ..
		"When you equip a ring and the number of rings equipped is no less than the maximum allowed, a chosen method will determine which equipped ring will be unequipped.\n\n" ..
		"Default: Vanilla\n\n" ..
		"Vanilla: Using the order you equipped rings to unequip. So if you equip rings in order A-B-C, the unequip order will also be A-B-C.\n\n" -- .."abot's Smart Rings Tweaked: Rings are tiered (1 = No Enchantment, 2 = On Use, 3 = Constant Effect). A lower tier ring will be unequipped first. So if you have maximum three rings equipped (CE, CE, OU), the On Use ring will be unequipped first."
		,
		options = {
			{ label = "Vanilla", value = "vanilla" }, -- , { label = "abot's Smart Rings Tweaked", value = "abot" } 
		},
		variable = mwse.mcm.createTableVariable { id = "unequipMethod", table = config },
	})
	category:createDropdown({
		label = "Log Level",
		options = { { label = "INFO", value = "INFO" }, { label = "DEBUG", value = "DEBUG" } },
		variable = mwse.mcm.createTableVariable { id = "logLevel", table = config },
		callback = function(self)
			log:setLogLevel(self.variable.value)
		end,
	})
	mwse.mcm.register(template)
end
event.register("modConfigReady", registerModConfig)
