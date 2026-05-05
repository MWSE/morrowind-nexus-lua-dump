---@type levelingWizardStaffConfig
local defaultConfig = {
	-- ###
	modStartRequiresWizardRank = true,
	modStartRequiredPlayerLevel = 5,
	levelUpMagickaBase = 1000,
	levelUpMagickaAtTargetLevel = 40000,
	targetLevel = 15,
	useDiminishingReturns = true,
	diminishingReturnHalfThreshold = 500,
}

-- The name of the config json file of your mod.
-- This is used to save/load your config, so that changes persist
-- between game launches.
local configPath = "LevelingWizardStaff"

-- Loaded config, taking into account any setting changes made by the user.
lws.Config = mwse.loadConfig(configPath, defaultConfig)

-- When the mod config menu is ready to start accepting registrations,
-- register this mod.
local function registerModConfig()
	-- Create the top level component Template.
	-- This is basically a box that holds all the other parts of the menu.
	local template = mwse.mcm.createTemplate({
		-- This will be displayed in the mod list on the lefthand pane.
		name = "Leveling Wizard Staff",
		-- This makes all settings update the values stored in this table.
		config = lws.Config,
		defaultConfig = defaultConfig,
	})

	-- This tells MWSE to add this config menu to the list.
	template:register()

	-- Saves the config to a file whenever the menu is closed.
	template:saveOnClose(configPath, lws.Config)

	-- Create a simple container Page under Template.
	local settingsPage = template:createSideBarPage({ label = "Leveling Wizard Staff Settings" })

	local staffDataCategory = settingsPage:createCategory({ label = "Staff Infos", inGameOnly = true })

	---@type mwseMCMPlayerData
	local progressionVariable = mwse.mcm.createPlayerData({ path = "levelingWizardStaff", id = "progression", defaultSetting = lws.progression.initial })
	local staffAcquiredInfo = staffDataCategory:createActiveInfo({ label = "Wizard Staff acquired?", text = "...", description = "Whether or not this character has already acquired the Leveling Wizard Staff added by this mod.", variable = progressionVariable, inGameOnly = true })
	staffAcquiredInfo.convertToLabelValue = function(_, variableValue)
		if variableValue ~= nil and variableValue >= lws.progression.staffReceived then
			return tes3.findGMST(tes3.gmst.sYes).value
		else
			return tes3.findGMST(tes3.gmst.sNo).value
		end
	end

	---@type mwseMCMPlayerData
	local staffLevelVariable = mwse.mcm.createPlayerData({ path = "levelingWizardStaff", id = "staffLevel", defaultSetting = -1 })
	staffDataCategory:createActiveInfo({ label = "Staff Level", text = "...", description = "The current level of the Leveling Wizard Staff added by this mod.", variable = staffLevelVariable, inGameOnly = true })

	---@type mwseMCMPlayerData
	local staffMagickaVariable = mwse.mcm.createPlayerData({ path = "levelingWizardStaff", id = "staffMagickaAccumulated", defaultSetting = 0 })
	local staffMagickaInfo = staffDataCategory:createActiveInfo({ label = "Staff Magicka Accumulated", text = "...", description = "How much Magicka the Leveling Wizard Staff has accumulated and how much is needed for the next Level-Up.", variable = staffMagickaVariable, inGameOnly = true })
	staffMagickaInfo.convertToLabelValue = function(_, variableValue)
		local modData = lws.GetModData()
		if variableValue == nil or modData == nil then
			return "0 / 0"
		else
			local nextStaffLevel = modData.staffLevel + 1
			return variableValue .. " / " .. lws.CalculateMagickaForLevelUp(nextStaffLevel)
		end
	end

	local modStartCategory = settingsPage:createCategory({ label = "Mod Start" })

	modStartCategory:createYesNoButton({ label = "Requires Mages Guild 'Wizard' rank", config = lws.Config, configKey = "modStartRequiresWizardRank", description = "Whether or not the faction rank of 'Wizard' in the Mages Guild is required for the initial dream that allows you to acquire your Wizard Staff.\n\nThis requirement is active by default, because the lore described in the dream references it, but if you truly don't like it, you can disable it here.", showDefaultSetting = true })
	modStartCategory:createSlider({ label = "Required Player Level", min = 0, max = 30, config = lws.Config, configKey = "modStartRequiredPlayerLevel", description = "What minimum player level is required for the initial dream that allows you to acquire your Wizard Staff.", showDefaultSetting = true })

	local levelingUpCategory = settingsPage:createCategory({ label = "Leveling Up" })

	levelingUpCategory:createSlider({ label = "Base Magicka Required", min = 1, max = 10000, config = lws.Config, configKey = "levelUpMagickaBase", description = "Base value for how much accumulated Magicka is required for a Level-Up of the Wizard Staff.\n\nThe accumulated Magicka required for a Level-Up scales up pretty quickly from 'Base Magicka Required' towards 'Magicka Required at Target Level' as the staffs level approaches the 'Target Level' and continues growing linearly after that.", showDefaultSetting = true })
	levelingUpCategory:createSlider({ label = "Magicka Required at Target Level", min = 1, max = 100000, config = lws.Config, configKey = "levelUpMagickaAtTargetLevel", description = "The staffs Level-Up to level 'Target Level' requires this much accumulated Magicka.\n\nThe accumulated Magicka required for a Level-Up scales up pretty quickly from 'Base Magicka Required' towards 'Magicka Required at Target Level' as the staffs level approaches the 'Target Level' and continues growing linearly after that.", showDefaultSetting = true })
	levelingUpCategory:createSlider({ label = "Target Level", min = 1, max = 30, config = lws.Config, configKey = "targetLevel", description = "The staff level for which the 'Magicka Required at Target Level' is configured.\n\nThe accumulated Magicka required for a Level-Up scales up pretty quickly from 'Base Magicka Required' towards 'Magicka Required at Target Level' as the staffs level approaches the 'Target Level' and continues growing linearly after that.", showDefaultSetting = true })
	levelingUpCategory:createYesNoButton({ label = "Use Diminishing Returns for spent Magicka", config = lws.Config, configKey = "useDiminishingReturns", description = "When this option is enabled, a diminshing returns formula is applied to the Magicka spent on successful spells before adding it to the accumulated Magicka for leveling up the staff. The purpose is to discourage players from instantly buring their entire Magicka reserves on one single giant spell to get their staff to level up faster, and instead encourage frequent use of more normal spells.", showDefaultSetting = true })
	levelingUpCategory:createSlider({ label = "Diminishing Returns Half Threshold", min = 1, max = 1000, config = lws.Config, configKey = "diminishingReturnHalfThreshold", description = "If 'Use Diminishing Returns for spent Magicka' is active, this value configures the Magicka-cost threshold where only half of the Magicka is added to the accumulated Magicka for leveling up the staff. Cheaper spells add a higher fraction of their costs (approaching 100% for pretty cheap spells) and more expensive ones add a lower fraction (though in total a more expensive spell will always add more Magicka than a cheaper one, just at a far less efficient rate).", showDefaultSetting = true })
end

event.register(tes3.event.modConfigReady, registerModConfig)
