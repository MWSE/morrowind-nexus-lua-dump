--[[
	Mod: Craftable Bandage
	Author: Amalie
	
	This mod allows you to craft OAAB bandages with novice bushcrafting skill.
	It serves as an alternative to alchemy and restoration.
]] --
local ashfall = include("mer.ashfall.interop")
local CraftingFramework = include("CraftingFramework")
local skillModule = include("OtherSkills.skillModule")
local logging = require("logging.logger")

local configPath = "Craftable Bandage"
local defaultConfig = { enabled = true, logLevel = "INFO" }
local config = mwse.loadConfig(configPath, defaultConfig)

---@type mwseLogger
local log = logging.new({
	name = "Craftable Bandage",
	logLevel = config.logLevel,
})

local bandageId = "AB_alc_Healbandage02"
local bandageEffect = "Bandage"

--- @param e CraftingFramework.MenuActivator.RegisteredEvent
local function registerBushcraftingRecipe(e)
	local bushcraftingActivator = e.menuActivator
	--- @type CraftingFramework.Recipe.data
	local recipe = {
		id = bandageId,
		craftableId = bandageId,
		description = "Simple cloth bandages for the dressing of wounds.",
		materials = { { material = "fabric", count = 1 } },
		skillRequirements = { ashfall.bushcrafting.survivalTiers.novice },
		soundType = "fabric",
		category = "Other",
	}
	local recipes = { recipe }
	bushcraftingActivator:registerRecipes(recipes)
	log:debug("Registered bandage recipe")
end

---@param ref tes3reference
---@return integer duration
local function getEffectDuration(ref)
	local duration
	if ref == tes3.player then
		local skillLevel = skillModule.getSkill("Ashfall:Survival").value
		duration = math.clamp(skillLevel, 20, 40)
		return duration
	else
		return 30
	end
end

---@param e equipEventData
local function bandageEquipEvent(e)
	if (e.item.id:find("^AB_alc_HealBandage")) then
		local duration = getEffectDuration(e.reference)
		tes3.applyMagicSource({
			reference = e.reference,
			name = bandageEffect,
			effects = {
				{
					id = tes3.effect.restoreHealth,
					duration = duration,
					min = 1,
					max = 1,
				},
			},
		})
		timer.delayOneFrame(function()
			tes3.removeItem({
				reference = e.reference,
				item = e.item,
				playSound = false,
			})
		end, timer.real)
		if e.reference == tes3.player then
			tes3.messageBox("Bandage applied")
		end
		return false
	end
end

---@param e damagedEventData|damagedHandToHandEventData
local function removeBandageHealing(e)
	local activeMagicEffectList = e.reference.mobile
	                              .activeMagicEffectList
	for _, activeMagicEffect in ipairs(activeMagicEffectList) do
		if activeMagicEffect.instance.source.name == bandageEffect then
			activeMagicEffect.effectInstance.timeActive =
			activeMagicEffect.duration
		end
	end
end

--- @param e initializedEventData
local function initializedCallback(e)
	if not config.enabled then
		return
	end
	event.register("Ashfall:ActivateBushcrafting:Registered",
	               registerBushcraftingRecipe)
	event.register("OAAB:equip", bandageEquipEvent)
	event.register("damaged", removeBandageHealing)
	event.register("damagedHandToHand", removeBandageHealing)
	log:info("Initialized")
end
event.register(tes3.event.initialized, initializedCallback) -- before crafting framework

local function onModConfigReady()
	local template = mwse.mcm.createTemplate(
	                 { name = "Craftable Bandage" })
	template:saveOnClose("Craftable Bandage", config)
	template:register()

	local settings = template:createSideBarPage({ label = "Settings" })
	settings.sidebar:createInfo({
		-- This text will be on the right-hand side block
		text = "Craftable Bandage\n\nCreated by Amalie.\n\n" ..
		"This mod allows you to craft OAAB bandages with novice bushcrafting skill." ..
		"It serves as an alternative to alchemy and restoration",
	})

	settings:createOnOffButton({
		label = "Enable Mod",
		variable = mwse.mcm.createTableVariable({
			id = "enabled",
			table = config,
			restartRequired = true,
		}),
	})
	settings:createDropdown({
		label = "Log Level",
		options = {
			{ label = "TRACE", value = "TRACE" },
			{ label = "DEBUG", value = "DEBUG" },
			{ label = "INFO", value = "INFO" },
		},
		variable = mwse.mcm.createTableVariable({
			id = "logLevel",
			table = config,
		}),
		callback = function(self)
			log:setLogLevel(self.variable.value)
		end,
	})
end

event.register(tes3.event.modConfigReady, onModConfigReady)
