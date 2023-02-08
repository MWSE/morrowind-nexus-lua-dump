local mod = "Unstable Soul Gems"
local author = "JosephMcKean"
local description = "2023 Winter Modjam Entry\n\n" .. "Two features of this mod:\n\n" ..
                    "- Filled soul gems in your inventory now have a low low chance of exploding because filled soul gems are not stable. The stronger the soul, the more likely it will explode.\n\n" ..
                    "- A widget next to the sneak icon to show the lowest tier non-filled soul gem in your inventory when you have soultrap spell or soultrap enchanted weapon equipped."

local configPath = mod
local defaultConfig = { soulgemsExplode = true, soulgemIcon = true, debug = false }
local config = mwse.loadConfig(configPath, defaultConfig)
local log = require("logging.logger").new({ name = mod, logLevel = "INFO" })

local soulgemFrame
local soulgemImage

local currentSoulgem = nil

--- This is a generic iterator function that is used
--- to loop over all the items in an inventory
---@param ref tes3reference
---@return fun(): tes3item, integer, tes3itemData|nil
local function iterItems(ref)
	local function iterator()
		for _, stack in pairs(ref.object.inventory) do
			---@cast stack tes3itemStack
			local item = stack.object

			-- Account for restocking items,
			-- since their count is negative
			local count = math.abs(stack.count)

			-- first yield stacks with custom data
			if stack.variables then
				for _, data in pairs(stack.variables) do
					if data then
						coroutine.yield(item, data.count, data)
						count = count - data.count
					end
				end
			end
			-- then yield all the remaining copies
			if count > 0 then
				coroutine.yield(item, count)
			end
		end
	end
	return coroutine.wrap(iterator)
end

local soulgems = {
	["misc_soulgem_petty"] = { tier = 1, path = "icons\\m\\tx_soulgem_petty.tga" },
	["misc_soulgem_lesser"] = { tier = 2, path = "icons\\m\\tx_soulgem_lesser.tga" },
	["misc_soulgem_common"] = { tier = 3, path = "icons\\m\\tx_soulgem_common.tga" },
	["misc_soulgem_greater"] = { tier = 4, path = "icons\\m\\tx_soulgem_greater.tga" },
	["misc_soulgem_grand"] = { tier = 5, path = "icons\\m\\tx_soulgem_grand.tga" },
	["misc_soulgem_azura"] = { tier = 6, path = "icons\\w\\tx_art_azura_star.tga" },
	["ab_misc_soulgemblack"] = { tier = 7, path = "icons\\oaab\\m\\soulgem_black.dds" },
}

local function isSoulgem(item)
	local soulgem = soulgems[item.id:lower()]
	if soulgem then
		return soulgem.tier, soulgem.path
	end
end

local function Calc_Explode_Chance(soul)
	if soul <= 50 then
		return 0
	elseif soul >= 1500 then
		return 50
	else
		local chance = (-0.0000238 * soul ^ 2 + 0.0713 * soul - 3.51) / 2
		return chance
	end
end

local function Under_Particular_Situation()
	return not config.soulgemsExplode or tes3.mobilePlayer.sleeping
end

local function Is_A_Filled_Soul_Gem(item, itemData)
	return soulgems[item.id:lower()] and itemData and itemData.soul
end

local function Explode(item, itemData, coefficient)
	tes3.cast({
		reference = tes3.player,
		target = tes3.player,
		spell = "force bolt",
		instant = true,
		bypassResistances = true,
	})
	tes3.mobilePlayer:applyDamage({ damage = coefficient * 2, resistAttribute = tes3.effectAttribute.resistMagic })
	tes3.removeItem({ reference = tes3.player, item = item, itemData = itemData })
	tes3.messageBox(string.format("%s exploded!", item.name .. " (" .. itemData.soul.name .. ")"))
end

-- Unstable Soul Gems
-- JosephMcKean

local function Filled_Soul_Gems_Are_Very_Unstable()
	if Under_Particular_Situation() then
		return
	end
	for item, _, itemData in iterItems(tes3.player) do
		if Is_A_Filled_Soul_Gem(item, itemData) then
			local coefficient = Calc_Explode_Chance(itemData.soul.soul)
			if math.random(100) < coefficient then
				Explode(item, itemData, coefficient)
				return
			end
		end
	end
end

local function checkSoultrapEquipped()
	if not config.soulgemIcon then
		soulgemFrame.visible = false
		return
	end
	if tes3.mobilePlayer then
		if tes3.mobilePlayer.readiedWeapon then
			local enchant = tes3.mobilePlayer.readiedWeapon.object.enchantment
			if enchant then
				if currentSoulgem then
					for _, effect in ipairs(enchant.effects) do
						if effect.id == tes3.effect.soultrap then
							soulgemFrame.visible = true
							return
						end
					end
				end
			end
		end
		if tes3.mobilePlayer.currentSpell then
			if currentSoulgem then
				for _, effect in ipairs(tes3.mobilePlayer.currentSpell.effects) do
					if effect.id == tes3.effect.soultrap then
						soulgemFrame.visible = true
						return
					end
				end
			end
		end
		soulgemFrame.visible = false
	end
end
local function checkInventoryForSoulgems()
	if config.soulgemIcon then
		local lowestTier = 7
		local cheapestSoulgem
		for item, _, itemData in iterItems(tes3.player) do
			local tier, path = isSoulgem(item)
			if tier then -- is soulgem
				local hasSoul = false
				if itemData and itemData.soul then
					hasSoul = true
				end
				if not hasSoul then
					if tier <= lowestTier then
						lowestTier = tier
						soulgemImage.contentPath = path
						cheapestSoulgem = item.id
					end
				end
			end
		end
		currentSoulgem = cheapestSoulgem
	end
end

local function createSoulgemIcon(e)
	if not e.newlyCreated then
		return
	end
	local multiMenu = e.element

	-- Find the UI element that holds the sneak icon indicator.
	local bottomLeftBar = multiMenu:findChild("MenuMulti_sneak_icon").parent

	-- Create an icon that matches the sneak icon's look.
	soulgemFrame = bottomLeftBar:createThinBorder({ id = "MenuMulti_Soulgem" })
	soulgemFrame.visible = false
	soulgemFrame.autoHeight = true
	soulgemFrame.autoWidth = true
	soulgemFrame.borderAllSides = 2

	local currentSoulgem = currentSoulgem or "misc_soulgem_petty"
	soulgemImage = soulgemFrame:createImage({ id = "MenuMulti_Soulgem_image", path = soulgems[currentSoulgem].path })
	soulgemImage.borderAllSides = 2
	soulgemImage.scaleMode = true
	soulgemImage.height = 32
	soulgemImage.width = 32
	soulgemImage.imageFilter = true

	bottomLeftBar:updateLayout()
end
event.register("uiActivated", createSoulgemIcon, { filter = "MenuMulti" })

event.register("loaded", function()
	for id, v in pairs(soulgems) do
		local soulgem = tes3.getObject(id)
		if soulgem then
			v.path = "icons\\" .. soulgem.icon
			log:debug("%s icon path: ", v.path)
		else
			log:debug("%s not found", id)
		end
	end
	timer.start({
		iterations = -1,
		duration = 0.5,
		callback = function()
			checkInventoryForSoulgems()
			checkSoultrapEquipped()
		end,
	})
	timer.start({
		iterations = -1,
		type = timer.game,
		duration = 1,
		callback = function()
			if config.soulgemsExplode then
				Filled_Soul_Gems_Are_Very_Unstable()
			end
		end,
	})
end)

local function registerModConfig()
	local template = mwse.mcm.createTemplate({ name = mod })
	template:register()
	template:saveOnClose(mod, config)
	local page = template:createSideBarPage({ description = string.format("%s by %s\n\n%s", mod, author, description) })
	local category = page:createCategory(mod)
	category:createYesNoButton({
		label = "Soul Gems Explode",
		variable = mwse.mcm.createTableVariable({ id = "soulgemsExplode", table = config }),
	})
	category:createYesNoButton({
		label = "Soul Gem indicator",
		variable = mwse.mcm.createTableVariable({ id = "soulgemIcon", table = config }),
	})
	category:createYesNoButton({
		label = "Set Log Level to DEBUG",
		variable = mwse.mcm.createTableVariable({ id = "debug", table = config }),
		callback = function(self)
			if self.variable.value then
				log:setLogLevel("DEBUG")
			else
				log:setLogLevel("INFO")
			end
		end,
	})
end
event.register("modConfigReady", registerModConfig)
