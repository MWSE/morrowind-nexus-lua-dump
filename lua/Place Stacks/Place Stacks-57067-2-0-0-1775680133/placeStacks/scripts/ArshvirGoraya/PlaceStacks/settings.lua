local settings = I.Settings

local l10n = Keys.CONSTANT_KEYS.L10n

settings.registerPage({
	key = Keys.CONSTANT_KEYS.SettingsPageName,
	l10n = l10n,
	name = Keys.LOCALIZED_KEYS.ModName,
	description = Keys.LOCALIZED_KEYS.ModDescription,
})

---@class SettingsCommonBehavior
---@field AutoClose string
---@field Modifier string

---@class SettingsStackAction
---@field KeyBind string
---@field TransferOrder string
---@field ModifierSetting string
---@field NotifyCountTransferred boolean
---@field NotifyValueTransferred boolean
---@field NotifyWeightTransferred boolean
---@field NotifyTypesNotAllTransferred boolean

---@class SettingsTakeStacks: SettingsStackAction
---@field AllowOverEncumbrance boolean

---@class SettingsPlaceStacks: SettingsStackAction
---@field HoldMS number
---@field DepositEquipped boolean
---@field DepositMoney boolean

local settingsDefinitions = {
	settingsCommonBehavior = {
		key = Keys.CONSTANT_KEYS.Sections.CommonBehavior,
		page = Keys.CONSTANT_KEYS.SettingsPageName,
		l10n = l10n,
		name = Keys.LOCALIZED_KEYS.Sections.CommonBehavior.Name,
		description = Keys.LOCALIZED_KEYS.Sections.CommonBehavior.Description,
		permanentStorage = true, -- false = placed in individual saves
		settings = {
			---@class SettingSelectDefinition
			---@field key string
			---@field name string
			---@field description string
			---@field default string
			---@field renderer string
			---@field argument {items: string[], l10n: string}
			{
				key = Keys.CONSTANT_KEYS.CommonBehavior.AutoCloseKey,
				name = Keys.LOCALIZED_KEYS.Settings.AutoClose.Name,
				description = Keys.LOCALIZED_KEYS.Settings.AutoClose.Description,
				default = Keys.LOCALIZED_KEYS.Options.AutoClose.Never,
				renderer = "select",
				argument = {
					items = Keys.LOCALIZED_KEYS.Settings.AutoClose.List,
					l10n = l10n,
				},
			},
			{
				key = Keys.CONSTANT_KEYS.CommonBehavior.ModifierKey,
				name = Keys.LOCALIZED_KEYS.Settings.Modifier.Name,
				description = Keys.LOCALIZED_KEYS.Settings.Modifier.Description,
				default = Keys.LOCALIZED_KEYS.Options.Modifier.Shift,
				renderer = "select",
				argument = {
					items = Keys.LOCALIZED_KEYS.Settings.Modifier.List,
					l10n = l10n,
				},
			},
		},
	},

	settingsTakeStacks = {
		key = Keys.CONSTANT_KEYS.Sections.TakeStacks,
		page = Keys.CONSTANT_KEYS.SettingsPageName,
		l10n = l10n,
		name = Keys.LOCALIZED_KEYS.Sections.TakeStacks.Name,
		description = Keys.LOCALIZED_KEYS.Sections.TakeStacks.Description,
		permanentStorage = true,
		settings = {
			{
				key = Keys.CONSTANT_KEYS.TakeStacks.KeyBind,
				name = Keys.LOCALIZED_KEYS.Settings.TakeStacksKeyBind.Name,
				description = Keys.LOCALIZED_KEYS.Settings.TakeStacksKeyBind.Description,
				default = "T", -- openMW doesn't set the default as of 0.49... so players will have to set it in game manually.
				renderer = "inputBinding",
				argument = {
					name = Keys.LOCALIZED_KEYS.Settings.TakeStacksKeyBind.Name,
					key = Keys.CONSTANT_KEYS.CustomInputs.TakeStacks,
					type = "action",
				},
			},
			{
				key = Keys.CONSTANT_KEYS.CommonSettings.TransferOrder,
				name = Keys.LOCALIZED_KEYS.Settings.TransferOrder.Take.Name,
				description = Keys.LOCALIZED_KEYS.Settings.TransferOrder.Take.Description,
				default = Keys.LOCALIZED_KEYS.Options.TransferOrder.ValuableByWeight,
				renderer = "select",
				argument = {
					items = Keys.LOCALIZED_KEYS.Settings.TransferOrder.List,
					l10n = l10n,
				},
			},
			{
				key = Keys.CONSTANT_KEYS.TakeStacks.AllowOverEncumbrance,
				name = Keys.LOCALIZED_KEYS.Settings.AllowOverEncumber.Name,
				description = Keys.LOCALIZED_KEYS.Settings.AllowOverEncumber.Description,
				default = false,
				renderer = "checkbox",
			},
			{
				key = Keys.CONSTANT_KEYS.CommonSettings.ModifierSetting,
				name = Keys.LOCALIZED_KEYS.Settings.ModifierSetting.Name,
				description = Keys.LOCALIZED_KEYS.Settings.ModifierSetting.Description,
				default = Keys.LOCALIZED_KEYS.Options.ModifierSetting.Default,
				renderer = "select",
				argument = {
					items = Keys.LOCALIZED_KEYS.Settings.ModifierSetting.List,
					l10n = l10n,
				},
			},
			{
				key = Keys.CONSTANT_KEYS.CommonSettings.NotifyCountTransferred,
				name = Keys.LOCALIZED_KEYS.Settings.NotifyCountTransferred.Take.Name,
				description = Keys.LOCALIZED_KEYS.Settings.NotifyCountTransferred.Take.Description,
				default = true,
				renderer = "checkbox",
			},
			{
				key = Keys.CONSTANT_KEYS.CommonSettings.NotifyValueTransferred,
				name = Keys.LOCALIZED_KEYS.Settings.NotifyValueTransferred.Take.Name,
				description = Keys.LOCALIZED_KEYS.Settings.NotifyValueTransferred.Take.Description,
				default = true,
				renderer = "checkbox",
			},
			{
				key = Keys.CONSTANT_KEYS.CommonSettings.NotifyWeightTransferred,
				name = Keys.LOCALIZED_KEYS.Settings.NotifyWeightTransferred.Take.Name,
				description = Keys.LOCALIZED_KEYS.Settings.NotifyWeightTransferred.Take.Description,
				default = true,
				renderer = "checkbox",
			},
			{
				key = Keys.CONSTANT_KEYS.CommonSettings.NotifyTypesNotAllTransferred,
				name = Keys.LOCALIZED_KEYS.Settings.NotifyTypesNotAllTransferred.Take.Name,
				description = Keys.LOCALIZED_KEYS.Settings.NotifyTypesNotAllTransferred.Take.Description,
				default = true,
				renderer = "checkbox",
			},
		},
	},

	settingsPlaceStacks = {
		key = Keys.CONSTANT_KEYS.Sections.PlaceStacks,
		page = Keys.CONSTANT_KEYS.SettingsPageName,
		l10n = l10n,
		name = Keys.LOCALIZED_KEYS.Sections.PlaceStacks.Name,
		description = Keys.LOCALIZED_KEYS.Sections.PlaceStacks.Description,
		permanentStorage = true,
		settings = {
			{
				key = Keys.CONSTANT_KEYS.PlaceStacks.KeyBind,
				name = Keys.LOCALIZED_KEYS.Settings.PlaceStacksKeyBind.Name,
				description = Keys.LOCALIZED_KEYS.Settings.PlaceStacksKeyBind.Description,
				default = "G",
				renderer = "inputBinding",
				argument = {
					name = Keys.LOCALIZED_KEYS.Settings.PlaceStacksKeyBind.Name,
					key = Keys.CONSTANT_KEYS.CustomInputs.PlaceStacks,
					type = "action",
				},
			},
			{
				key = Keys.CONSTANT_KEYS.PlaceStacks.HoldMS,
				name = Keys.LOCALIZED_KEYS.Settings.HoldMS.Name,
				description = Keys.LOCALIZED_KEYS.Settings.HoldMS.Description,
				default = 250,
				renderer = "number",
				argument = {
					integer = true, -- only allow integers,
					min = 0,
					max = 3000,
				},
			},
			{
				key = Keys.CONSTANT_KEYS.CommonSettings.TransferOrder,
				name = Keys.LOCALIZED_KEYS.Settings.TransferOrder.Place.Name,
				description = Keys.LOCALIZED_KEYS.Settings.TransferOrder.Place.Description,
				default = Keys.LOCALIZED_KEYS.Options.TransferOrder.Heaviest,
				renderer = "select",
				argument = {
					items = Keys.LOCALIZED_KEYS.Settings.TransferOrder.List,
					l10n = l10n,
				},
			},
			{
				key = Keys.CONSTANT_KEYS.PlaceStacks.DepositEquipped,
				name = Keys.LOCALIZED_KEYS.Settings.DepositEquipped.Name,
				description = Keys.LOCALIZED_KEYS.Settings.DepositEquipped.Description,
				default = false,
				renderer = "checkbox",
			},
			{
				key = Keys.CONSTANT_KEYS.PlaceStacks.DepositMoney,
				name = Keys.LOCALIZED_KEYS.Settings.DepositMoney.Name,
				description = Keys.LOCALIZED_KEYS.Settings.DepositMoney.Description,
				default = false,
				renderer = "checkbox",
			},
			{
				key = Keys.CONSTANT_KEYS.CommonSettings.ModifierSetting,
				name = Keys.LOCALIZED_KEYS.Settings.ModifierSetting.Name,
				description = Keys.LOCALIZED_KEYS.Settings.ModifierSetting.Description,
				default = Keys.LOCALIZED_KEYS.Options.ModifierSetting.Default,
				renderer = "select",
				argument = {
					items = Keys.LOCALIZED_KEYS.Settings.ModifierSetting.List,
					l10n = l10n,
				},
			},
			--
			{
				key = Keys.CONSTANT_KEYS.CommonSettings.NotifyCountTransferred,
				name = Keys.LOCALIZED_KEYS.Settings.NotifyCountTransferred.Place.Name,
				description = Keys.LOCALIZED_KEYS.Settings.NotifyCountTransferred.Place.Description,
				default = true,
				renderer = "checkbox",
			},
			{
				key = Keys.CONSTANT_KEYS.CommonSettings.NotifyValueTransferred,
				name = Keys.LOCALIZED_KEYS.Settings.NotifyValueTransferred.Place.Name,
				description = Keys.LOCALIZED_KEYS.Settings.NotifyValueTransferred.Place.Description,
				default = true,
				renderer = "checkbox",
			},
			{
				key = Keys.CONSTANT_KEYS.CommonSettings.NotifyWeightTransferred,
				name = Keys.LOCALIZED_KEYS.Settings.NotifyWeightTransferred.Place.Name,
				description = Keys.LOCALIZED_KEYS.Settings.NotifyWeightTransferred.Place.Description,
				default = true,
				renderer = "checkbox",
			},
			{
				key = Keys.CONSTANT_KEYS.CommonSettings.NotifyTypesNotAllTransferred,
				name = Keys.LOCALIZED_KEYS.Settings.NotifyTypesNotAllTransferred.Place.Name,
				description = Keys.LOCALIZED_KEYS.Settings.NotifyTypesNotAllTransferred.Place.Description,
				default = true,
				renderer = "checkbox",
			},
		},
	},
}

-- Custom Inputs:
Input.registerAction({
	key = Keys.CONSTANT_KEYS.CustomInputs.TakeStacks,
	type = Input.ACTION_TYPE.Boolean,
	l10n = l10n,
	name = Keys.LOCALIZED_KEYS.Settings.TakeStacksKeyBind.Name,
	description = Keys.LOCALIZED_KEYS.Settings.TakeStacksKeyBind.KeyDescription,
	defaultValue = false,
})
Input.registerAction({
	key = Keys.CONSTANT_KEYS.CustomInputs.PlaceStacks,
	type = Input.ACTION_TYPE.Boolean,
	l10n = l10n,
	name = Keys.LOCALIZED_KEYS.Settings.PlaceStacksKeyBind.Name,
	description = Keys.LOCALIZED_KEYS.Settings.PlaceStacksKeyBind.KeyDescription,
	defaultValue = false,
})

--

-- register order != the way it appears in the settings page.
settings.registerGroup(settingsDefinitions.settingsTakeStacks)
settings.registerGroup(settingsDefinitions.settingsPlaceStacks)
settings.registerGroup(settingsDefinitions.settingsCommonBehavior)

local M = {}

local tableSettings = {}

local function settingsChanged(sectionKey, settingKey)
	if DB.logging then
		local resetAll = settingKey == nil
		if resetAll then -- 0.49: should be true if hit "reset" but this is never true.
			DB.log("RESET ALL")
		end
		DB.log(
			"settings changed: " .. sectionKey,
			settingKey .. ": " .. tostring(Storage.playerSection(sectionKey):get(settingKey))
		)
	end
	local storageSection = Storage.playerSection(sectionKey)
	tableSettings[sectionKey][settingKey] = storageSection:get(settingKey)
end

local function getSettingSectionAsTable(settingSection, storageSection)
	local tbl = {}
	for _, v in pairs(settingSection.settings) do
		tbl[v.key] = storageSection:get(v.key)
	end
	return tbl
end

-- necessary if you want to send setting sections across global/local scripts
M.subscribeAndBuildTableSettings = function(async)
	tableSettings = {}
	for _, section in pairs(settingsDefinitions) do
		local storageSection = Storage.playerSection(section.key)
		-- Convert settings to tables when changed (so they can pass in events to global script -> which cant access playersection storage)
		-- can use storageSection:asTable() but that will include keys that may be in older versions of the mod! So potentially bigger table which i don't like
		tableSettings[section.key] = getSettingSectionAsTable(settingsDefinitions[section.key], storageSection)
		-- DB.log("table section: ", tableSettings[section.key])
		-- DB.log("table section alternative: ", storageSection:asTable())

		-- Subscribe to changed to settings (to update the tables)
		storageSection:subscribe(async:callback(settingsChanged))
	end
	-- DB.printTable(tableSettings, 2)
	return tableSettings
end

local function validateSectionsSelectSettings(ui, storageSection, settingsDefinitionSection, sectionName)
	for _, s in ipairs(settingsDefinitionSection.settings) do
		---@cast s SettingSelectDefinition
		if s.renderer == "select" then
			if not Helpers.listHasValue(s.argument.items, storageSection:get(s.key)) then
				storageSection:set(s.key, s.default)
				--
				local warningString = "Place Stacks Warning: "
					.. s.name
					.. " reset to default ("
					.. s.default
					.. ") in section "
					.. sectionName

				DB.log("attempt to warn print")
				ui.showMessage(warningString)
				Helpers.warningPrint(warningString)
			end
		end
	end
end

function M.validateAllSelectSettings(ui)
	for key, _ in pairs(Keys.CONSTANT_KEYS.Sections) do
		validateSectionsSelectSettings(
			ui,
			Storage.playerSection(Keys.CONSTANT_KEYS.Sections[key]),
			settingsDefinitions["settings" .. key],
			Keys.LOCALIZED_KEYS.Sections[key].Name
		)
	end
	-- validateSectionsSelectSettings(
	-- 	ui,
	-- 	Storage.playerSection(Keys.CONSTANT_KEYS.Sections.CommonBehavior),
	-- 	settingsDefinitions.settingsCommonBehavior
	-- )
	-- validateSectionsSelectSettings(
	-- 	ui,
	-- 	Storage.playerSection(Keys.CONSTANT_KEYS.Sections.TakeStacks),
	-- 	settingsDefinitions.settingsTakeStacks
	-- )
	-- validateSectionsSelectSettings(
	-- 	ui,
	-- 	Storage.playerSection(Keys.CONSTANT_KEYS.Sections.PlaceStacks),
	-- 	settingsDefinitions.settingsPlaceStacks
	-- )
end

return M
