-- PS_p.lua --
-- Pretty Stats — Parent Player Script --
-- OpenMW 50 --

local async   = require('openmw.async')
local storage = require('openmw.storage')
local I       = require('openmw.interfaces')
local types       = require('openmw.types')
local self       = require('openmw.self')

local MODNAME = "PrettyStats"

-------------------------------------------------
-- Settings Template
-------------------------------------------------
local settingsTemplate = {}

settingsTemplate["General"] = {
	key = "SettingsPrettyStats",
	page = MODNAME,
	l10n = "none",
	name = "General",
	permanentStorage = true,
	order = 1,
	settings = {
		{
			key = "PS_enabled",
			name = "Enable Pretty Stats",
			description = "Show popups when attributes or skills change.",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "PS_showAttributes",
			name = "Show attribute changes",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "PS_showSkills",
			name = "Show skill changes",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "PS_spellMode",
			name = "Spell effect handling",
			description = "How stat changes from active spells (Fortify/Drain) are displayed.\nMerge: spell changes are combined with all other changes.\nFilter: spell changes are hidden entirely.\nDistinct: spell changes are shown with a separate background texture.",
			renderer = "select",
			default = "Distinct",
			argument = {
				disabled = false,
				l10n = "none",
				items = { "Merge", "Filter", "Distinct" },
			},
		},
	},
}

settingsTemplate["Scaling"] = {
	key = "SettingsScalingPrettyStats",
	page = MODNAME,
	l10n = "none",
	name = "Scaling & Position",
	permanentStorage = false,
	order = 2,
	settings = {
		{
			key = "PS_fontScale",
			name = "Font Size",
			renderer = "number",
			default = 18,
			argument = { min = 8, max = 32, integer = true },
		},
		{
			key = "PS_posX",
			name = "Horizontal Position",
			description = "0.0 = Left, 1.0 = Right",
			renderer = "number",
			default = 0,
			argument = { min = 0.0, max = 1.0 },
		},
		{
			key = "PS_posY",
			name = "Vertical Position",
			description = "0.0 = Top, 1.0 = Bottom",
			renderer = "number",
			default = 0.15,
			argument = { min = 0.0, max = 1.0 },
		},
		{
			key = "PS_showBackground",
			name = "Show background",
			description = "Show the color coded background",
			renderer = "checkbox",
			default = true,
		},
	},
}

settingsTemplate["Behavior"] = {
	key = "SettingsBehaviorPrettyStats",
	page = MODNAME,
	l10n = "none",
	name = "Behavior",
	permanentStorage = true,
	order = 3,
	settings = {
		{
			key = "PS_maxOnScreen",
			name = "Max popups on screen",
			description = "The conveyor might keep additional rows if they have remaining life time",
			renderer = "number",
			default = 10,
			argument = { min = 1, max = 300, integer = true },
		},
		{
			key = "PS_rowLifetime",
			name = "Row life time",
			description = "Minimum seconds each row stays visible.\nGets reset after a merge",
			renderer = "number",
			default = 5.0,
			argument = { min = 0.1, max = 100.0 },
		},
		{
			key = "PS_forceConveyorEnd",
			name = "Conveyor ignores life time",
			description = "Ignores remaining lifetime when a row reaches the end of the conveyor, unless it got merged",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "PS_holdtime",
			name = "Conveyor Hold Time",
			description = "Seconds the conveyor stays static before starting to move rows up",
			renderer = "number",
			default = 2.0,
			argument = { min = 0 },
		},
		{
			key = "PS_conveyorSpeed",
			name = "Conveyor scroll speed",
			description = "How fast rows scroll when the queue is backed up.",
			renderer = "number",
			default = 8,
			argument = { min = 0.2, max = 50.0 },
		},
		{
			key = "PS_spacing",
			name = "Popup spacing",
			renderer = "number",
			default = 26,
			argument = { min = 20, max = 80, integer = true },
		},
		{
			key = "PS_fadeDuration",
			name = "Fade out duration",
			renderer = "number",
			default = 0.5,
			argument = { min = 0.1, max = 5.0 },
		},
		{
			key = "PS_fadeInDuration",
			name = "Fade in duration",
			renderer = "number",
			default = 0.2,
			argument = { min = 0 },
		},
		{
			key = "PS_slideSpeed",
			name = "Slide in speed",
			renderer = "number",
			default = 10.0,
			argument = { min = 0.1 },
		},
		--{
		--	key = "PS_spellScanInterval",
		--	name = "Spell scan interval",
		--	description = "Additional scanning of spells even when stats haven't changed, covering some unrealistic edge cases",
		--	renderer = "number",
		--	default = 0.5,
		--	argument = { min = 0.1, max = 5.0 },
		--},
		{
			key = "PS_scanFrames",
			name = "Scan throttle",
			description = "Spread stat scanning over N frames",
			renderer = "number",
			default = 3,
			argument = { min = 1, max = 5, integer = true },
		},
		{
			key = "PS_showZeroRows",
			name = "Show cancelled rows (0, 0, 0) (only affects queue)",
			renderer = "checkbox",
			default = false,
		},
	},
}

-------------------------------------------------
-- Register
-------------------------------------------------
I.Settings.registerPage {
	key = MODNAME,
	l10n = "none",
	name = "Pretty Stats",
	description = "Visual popups for attribute and skill changes.",
}

for _, template in pairs(settingsTemplate) do
	I.Settings.registerGroup(template)
end

-------------------------------------------------
-- Read all into _G
-------------------------------------------------
local function readAllSettings()
	for _, template in pairs(settingsTemplate) do
		local settingsSection = storage.playerSection(template.key)
		for _, entry in pairs(template.settings) do
			local val = settingsSection:get(entry.key)
			if val == nil then val = entry.default end
			_G[entry.key] = val
		end
	end
	PS_uiScaleFactor = storage.globalSection("SettingsGUI"):get("scaling factor") or 1.0
	-- Derive internal flags from the unified spell mode setting
	local mode = _G.PS_spellMode or "Filter"
	_G.PS_ignoreActiveSpells = (mode == "Filter")
	_G.PS_spellTexture       = (mode == "Distinct")
end

-------------------------------------------------
-- Subscribe to changes
-------------------------------------------------
for _, template in pairs(settingsTemplate) do
	local settingsSection = storage.playerSection(template.key)
	settingsSection:subscribe(async:callback(function(_, setting)
		_G[setting] = settingsSection:get(setting)
		if setting == "PS_spellMode" then
			_G.PS_ignoreActiveSpells = (_G.PS_spellMode == "Filter")
			_G.PS_spellTexture      = (_G.PS_spellMode == "Distinct")
			if _G.PS_syncSpellTimer then _G.PS_syncSpellTimer() end
		end
	end))
end

storage.globalSection("SettingsGUI"):subscribe(async:callback(function(_, key)
	if not key or key == "scaling factor" then
		PS_uiScaleFactor = storage.globalSection("SettingsGUI"):get("scaling factor") or 1.0
	end
end))

-------------------------------------------------
-- Init
-------------------------------------------------
readAllSettings()

-------------------------------------------------
-- Require child script
-------------------------------------------------
local stats = require('scripts.prettyStats.pretty_stats')
local statsHandlers = stats.engineHandlers

-------------------------------------------------
-- Combined engine handlers
-------------------------------------------------

return {
	engineHandlers = {
		onInit = function(data)
			if statsHandlers.onInit then statsHandlers.onInit(data) end
		end,

		onLoad = function(data)
			if statsHandlers.onLoad then statsHandlers.onLoad(data) end
		end,

		onSave = function()
			local saveData = {}
			if statsHandlers.onSave then saveData.stats = statsHandlers.onSave() end
			return saveData
		end,

		onFrame = function(dt)
			if statsHandlers.onFrame then statsHandlers.onFrame(dt) end
		end,
	},
}