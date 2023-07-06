local soulgemsIndicator = {}

local mod = "Soul Gems Indicator"
local author = "JosephMcKean"
local description = "2023 Winter Modjam Entry\n\n" .. "Two features of this mod:\n\n" ..
                    "- A widget next to the weapon and spell icons to show the lowest tier non-filled soul gem in your inventory when you have soultrap spell or soultrap enchanted weapon equipped.\n\n" ..
                    "- Filled soul gems in inventory will have the enchanted icon background."

local npcSoulTrap = include("Seph.npcSoulTrapping.npcSoulTrap")
local blackSoulGem = include("Seph.npcSoulTrapping.blackSoulGem")

local configPath = mod
local defaultConfig = { soulgemIcon = true, logLevel = "INFO", magicIcon = true }

---@class soulgemsIndicator.config
---@field logLevel mwseLoggerLogLevel
---@field magicIcon boolean
---@field soulgemIcon boolean
local config = mwse.loadConfig(configPath, defaultConfig)
local log = require("logging.logger").new({ name = mod, logLevel = config.logLevel })

soulgemsIndicator.soulgemFrame = nil ---@type tes3uiElement
soulgemsIndicator.soulgemBorder = nil ---@type tes3uiElement
soulgemsIndicator.soulgemImage = nil ---@type tes3uiElement

soulgemsIndicator.currentSoulgem = nil

--- This is a generic iterator function that is used
--- to loop over all the items in an inventory
---@param ref tes3reference
---@return fun(): tes3item|tes3misc, integer, tes3itemData|nil
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
			if count > 0 then coroutine.yield(item, count) end
		end
	end
	return coroutine.wrap(iterator)
end

---@return boolean
function soulgemsIndicator.checkSoultrapEquipped()
	if not config.soulgemIcon and soulgemsIndicator.soulgemFrame.visible then
		soulgemsIndicator.soulgemFrame.visible = false
		return false
	end
	if not tes3.mobilePlayer then return false end
	if tes3.mobilePlayer.readiedWeapon then
		local enchant = tes3.mobilePlayer.readiedWeapon.object.enchantment
		if enchant then
			for _, effect in ipairs(enchant.effects) do
				if effect.id == tes3.effect.soultrap then
					soulgemsIndicator.soulgemFrame.visible = true
					return true
				end
			end
		end
	end
	if tes3.mobilePlayer.currentSpell then
		for _, effect in ipairs(tes3.mobilePlayer.currentSpell.effects) do
			if effect.id == tes3.effect.soultrap then
				soulgemsIndicator.soulgemFrame.visible = true
				return true
			end
		end
	end
	soulgemsIndicator.soulgemFrame.visible = false
	return false
end

---@class soulgemsIndicator.data
---@field soulGemCapacity number
---@field icon string

---@param baseObject tes3object|tes3creature?
---@return soulgemsIndicator.data?
local function getSmallestFittingSoulGem(baseObject)
	local soul = baseObject and baseObject.soul or 0 ---@cast soul number
	local isNpcSoulTrapping = false
	if baseObject and baseObject.objectType == tes3.objectType.npc then
		if not npcSoulTrap then return nil end
		isNpcSoulTrapping = true
	end
	local smallestSoulGem = nil ---@type soulgemsIndicator.data
	local soulGems = {} ---@type soulgemsIndicator.data[]
	for item, _, itemData in iterItems(tes3.player) do
		if item.isSoulGem then
			---@cast item tes3misc
			log:trace("item %s is a soul gem", item.id)
			if not (itemData and itemData.soul) then
				log:trace("item %s is not filled", item.id)
				local blackGemRequired = npcSoulTrap.mod.config.current.blackSoulGem.required ---@type boolean
				if not (isNpcSoulTrapping and blackGemRequired and not blackSoulGem.isBlackSoulGem(item)) then
					table.bininsert(soulGems, { soulGemCapacity = item.soulGemCapacity, icon = item.icon }, function(a, b) return a.soulGemCapacity <= b.soulGemCapacity end)
				end
			end
		end
	end
	-- Find the smallest fitting soul gem
	for _, soulGem in ipairs(soulGems) do
		if soulGem.soulGemCapacity >= soul then
			log:trace("%s soul gem capacity >= %s soul", soulGem.icon, baseObject and baseObject.id)
			smallestSoulGem = soulGem
			return smallestSoulGem
		end
	end
	return nil
end

---@return boolean
function soulgemsIndicator.checkInventoryForSoulgems()
	if config.soulgemIcon then
		local soulgem
		local result = tes3.rayTest({ position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), ignore = { tes3.player }, maxDistance = tes3.getPlayerActivationDistance() })
		local reference = result and result.reference
		local baseObject = reference and reference.mobile and not reference.mobile.isDead and reference.baseObject ---@cast baseObject tes3object|tes3creature|any?
		soulgem = getSmallestFittingSoulGem(baseObject)
		if soulgem then
			log:trace("soulgem.icon = %s", soulgem.icon)
			soulgemsIndicator.soulgemFrame.visible = true
			soulgemsIndicator.soulgemImage.contentPath = "Icons\\" .. soulgem.icon
			return true
		else
			soulgemsIndicator.soulgemFrame.visible = false
			return false
		end
	end
	return false
end

---@param e uiActivatedEventData
local function createSoulgemRect(e)
	if not e.newlyCreated then return end
	local multiMenu = e.element

	local iconsLayout = multiMenu:findChild("MenuMulti_icons_layout")

	-- Create an icon that matches the weapon icon's look
	soulgemsIndicator.soulgemFrame = iconsLayout:createRect({ id = "MenuMulti_soulgem_layout" })
	soulgemsIndicator.soulgemFrame.visible = false
	soulgemsIndicator.soulgemFrame.width, soulgemsIndicator.soulgemFrame.height = 36, 36
	soulgemsIndicator.soulgemFrame.borderAllSides = 2
	soulgemsIndicator.soulgemFrame:setPropertyBool("use_global_alpha", true)

	soulgemsIndicator.soulgemBorder = soulgemsIndicator.soulgemFrame:createThinBorder({ id = "MenuMulti_soulgem_border" })
	soulgemsIndicator.soulgemBorder.width, soulgemsIndicator.soulgemBorder.height = 36, 36
	soulgemsIndicator.soulgemBorder.paddingAllSides = 2

	soulgemsIndicator.currentSoulgem = soulgemsIndicator.currentSoulgem or "misc_soulgem_petty"
	local soulgemImagePath = "icons\\m\\tx_soulgem_petty."
	local path = lfs.fileexists(soulgemImagePath .. "dds") and soulgemImagePath .. "dds" or soulgemImagePath .. "tga"
	soulgemsIndicator.soulgemImage = soulgemsIndicator.soulgemBorder:createImage({ id = "MenuMulti_soulgem_icon", path = path })
	soulgemsIndicator.soulgemImage.positionX, soulgemsIndicator.soulgemImage.positionY = 2, -2
	soulgemsIndicator.soulgemImage.width, soulgemsIndicator.soulgemImage.height = 32, 32

	iconsLayout:updateLayout()
end

local function loaded()
	timer.start({ iterations = -1, duration = 0.25, callback = function() if soulgemsIndicator.checkSoultrapEquipped() then soulgemsIndicator.checkInventoryForSoulgems() end end })
end

---@param e itemTileUpdatedEventData
local function soulgemTileUpdated(e)
	if config.magicIcon then
		if e.item.isSoulGem then
			if e.itemData and e.itemData.soul then
				local iconMagicPath = "Textures\\menu_icon_magic."
				local iconMagic = lfs.fileexists(iconMagicPath .. "dds") and iconMagicPath .. "dds" or iconMagicPath .. "tga"
				e.element.contentPath = iconMagic
			end
		end
	end
end

event.register("initialized", function()
	event.register("uiActivated", createSoulgemRect, { filter = "MenuMulti" })
	event.register("loaded", loaded)
	event.register("itemTileUpdated", soulgemTileUpdated)
	event.register("UIEXP:sandboxConsole", function(e) e.sandbox.soulgemsIndicator = soulgemsIndicator end)
end)

local function registerModConfig()
	local template = mwse.mcm.createTemplate({ name = mod })
	template:register()
	template:saveOnClose(mod, config)
	local page = template:createSideBarPage({ description = string.format("%s by %s\n\n%s", mod, author, description) })
	local category = page:createCategory(mod)
	category:createYesNoButton({
		label = "Empty Soul Gem indicator",
		description = "A widget next to the weapon and spell icons to show the lowest tier non-filled soul gem in your inventory when you have soultrap spell or soultrap enchanted weapon equipped.",
		variable = mwse.mcm.createTableVariable({ id = "soulgemIcon", table = config }),
	})
	category:createYesNoButton({
		label = "Filled Soul Gem indicator",
		description = "Filled soul gems in inventory will have the enchanted icon background",
		variable = mwse.mcm.createTableVariable({ id = "magicIcon", table = config }),
	})
	category:createDropdown{
		label = "Log Level",
		description = "Set the logging level",
		options = {
			{ label = "TRACE", value = "TRACE" },
			{ label = "DEBUG", value = "DEBUG" },
			{ label = "INFO", value = "INFO" },
			{ label = "ERROR", value = "ERROR" },
			{ label = "NONE", value = "NONE" },
		},
		variable = mwse.mcm.createTableVariable { id = "logLevel", table = config },
		callback = function(self) log:setLogLevel(self.variable.value) end,
	}
end
event.register("modConfigReady", registerModConfig)

return soulgemsIndicator
