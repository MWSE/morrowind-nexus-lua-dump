local storage = require('openmw.storage')
local async = require('openmw.async')

local RENDERER_SLIDER = "SuperSlider3"

if not L then
	L = function(key, fallback) return fallback end
end

local orderCounter = 0
local function getOrder()
	orderCounter = orderCounter + 1
	return orderCounter
end

local tempKey
local settingsTemplate = {}

local percentKeys = {}

--------------------------------------------------------------- Experience ---------------------------------------------------------------

tempKey = "Experience"
settingsTemplate[tempKey] = {
	key = 'SettingsPlayer'..MOD_NAME..tempKey,
	page = MOD_NAME,
	l10n = "none",
	name = L("Group.Experience", "Experience").."                                             ",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "magickaXPMult",
			name = L("magickaXPMult.name", "Magicka XP Multiplier"),
			description = L("magickaXPMult.desc",
				"Multiply magicka cost to calculate xp per spell cast\n"
				.. "Ignores Refunds\n"
				.. "Vanilla XP get halfed when this is on (=1.5 Base XP)\n"
				.. "Set to 0 to disable feature for better compatibility"),
			default = 0.1,
			renderer = RENDERER_SLIDER,
			argument = {
				min = 0,
				max = 1,
				step = 0.01,
				default = 0.1,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
				minLabel = L("label.Off", "Off"),
				maxLabel = "1 XP",
				centerLabel = "XP/Magicka",
				width = 150,
				thickness = 15,
				unit = " XP",
			},
		},
	},
}

--------------------------------------------------------------- Magicka Refund ---------------------------------------------------------------

tempKey = "Refund"
settingsTemplate[tempKey] = {
	key = 'SettingsPlayer'..MOD_NAME..tempKey,
	page = MOD_NAME,
	l10n = "none",
	name = L("Group.Refund", "Magicka Refund").."                                             ",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "refundMode",
			name = L("refundMode.name", "Refund Mode"),
			description = L("refundMode.desc",
				"Refund magicka after successful casts or "
				.. "(EXPERIMENTAL) before spending the magicka"),
			default = "Refund",
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none",
				items = {"Disabled", "Refund", "EXPERIMENTAL"},
			},
		},
		{
			key = "refundStart",
			name = L("refundStart.name", "Skill Requirement"),
			description = L("refundStart.desc",
				"Before this skill level, you won't get any Magicka Refunds.\n\n"
				.. "This value is also subtracted from your effective level for the refund formula"),
			default = 35,
			renderer = RENDERER_SLIDER,
			argument = {
				min = 1,
				max = 200,
				step = 1,
				default = 35,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
				minLabel = "1",
				maxLabel = "200",
				centerLabel = "Min Level",
				width = 150,
				thickness = 15,
			},
		},
		{
			key = "refundMult",
			name = L("refundMult.name", "Magicka Cost Scaling (%)"),
			description = L("refundMult.desc",
				"How much a spell costs is multiplied by this setting every [x] levels (set below)"),
			default = 50,
			renderer = RENDERER_SLIDER,
			argument = {
				min = 1,
				max = 200,
				step = 1,
				default = 50,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
				minLabel = "1%",
				maxLabel = "200%",
				centerLabel = "Cost Mult/Step",
				width = 150,
				thickness = 15,
				unit = "%",
			},
		},
		{
			key = "levelScaling",
			name = L("levelScaling.name", "Level Scaling"),
			description = L("levelScaling.desc",
				"How many levels for your spell cost to be multiplied by the above setting.\n\n"
				.. "At default settings (100 / 50%), a spell costs 50% of its magicka at a skill of 100"),
			default = 100,
			renderer = RENDERER_SLIDER,
			argument = {
				min = 1,
				max = 500,
				step = 5,
				default = 100,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
				minLabel = "1",
				maxLabel = "500",
				centerLabel = "Levels = 1 Step",
				width = 150,
				thickness = 15,
				unit = " levels",
			},
		},
		{
			key = "negativeRefunds",
			name = L("negativeRefunds.name", "Increased Magicka Cost"),
			description = L("negativeRefunds.desc",
				"If your magic skill is lower than the Skill Requirement set above,\n"
				.. "spells can have an increased magicka cost.\n"
				.. "Requires the EXPERIMENTAL refund mode\n\n"
				.. "e.g. 50%^(-25/100) = 119%"),
			default = false,
			renderer = "checkbox",
			argument = {},
		},
		{
			key = "spellCostMultiplier",
			name = L("spellCostMultiplier.name", "Spell Cost Multiplier (%)"),
			description = L("spellCostMultiplier.desc",
				"Requires Negative Refunds + EXPERIMENTAL mode\n"
				.. "Multiplier for increasing or decreasing how much magicka\n"
				.. "a spell costs after the exponential refund formula"),
			default = 100,
			renderer = RENDERER_SLIDER,
			argument = {
				min = 0,
				max = 500,
				step = 5,
				default = 100,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
				minLabel = "0%",
				maxLabel = "500%",
				centerLabel = "Cost Mult",
				width = 150,
				thickness = 15,
				unit = "%",
			},
		},
		{
			key = "spellCostOffset",
			name = L("spellCostOffset.name", "Spell Cost Offset (%)"),
			description = L("spellCostOffset.desc",
				"Requires Negative Refunds + EXPERIMENTAL mode\n"
				.. "Add or subtract magicka from the base spell to what you actually cast"),
			default = 0,
			renderer = RENDERER_SLIDER,
			argument = {
				min = -100,
				max = 100,
				step = 5,
				default = 0,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
				minLabel = "-100%",
				maxLabel = "+100%",
				centerLabel = "Cost Offset",
				width = 150,
				thickness = 15,
				unit = "%",
			},
		},
	},
}
percentKeys["refundMult"] = true
percentKeys["spellCostMultiplier"] = true
percentKeys["spellCostOffset"] = true

--------------------------------------------------------------- Experimental ---------------------------------------------------------------

tempKey = "Experimental"
settingsTemplate[tempKey] = {
	key = 'SettingsPlayer'..MOD_NAME..tempKey,
	page = MOD_NAME,
	l10n = "none",
	name = L("Group.Experimental", "Experimental").."                                             ",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "rapidfire",
			name = L("rapidfire.name", "Rapidfire Casting"),
			description = L("rapidfire.desc",
				"Allows you to cast spells in rapid succession by holding the button"),
			default = false,
			renderer = "checkbox",
			argument = {},
		},
		{
			key = "PrintDebug",
			name = L("PrintDebug.name", "Print Debug Messages"),
			description = L("PrintDebug.desc", "Prints debug info into the console"),
			default = false,
			renderer = "checkbox",
			argument = {},
		},
	},
}

--------------------------------------------------------------- Register ---------------------------------------------------------------

for _, template in pairs(settingsTemplate) do
	I.Settings.registerGroup(template)
end

I.Settings.registerPage {
	key = MOD_NAME,
	l10n = "none",
	name = "MBSP",
	description = L("Page.desc",
		"Magicka Based Skill Progression"),
}

--------------------------------------------------------------- Reading settings ---------------------------------------------------------------

function readAllSettings()
	for _, template in pairs(settingsTemplate) do
		local section = storage.playerSection(template.key)
		for _, entry in pairs(template.settings) do
			local val = section:get(entry.key)
			if val == nil then
				val = entry.default
			end
			if percentKeys[entry.key] then
				val = val / 100
			end
			_G["S_" .. entry.key] = val
		end
	end
end

readAllSettings()

--------------------------------------------------------------- Greying out inactive settings ---------------------------------------------------------------

local settingInfo = {}
for _, template in pairs(settingsTemplate) do
	for _, entry in pairs(template.settings) do
		settingInfo[entry.key] = {
			groupKey = template.key,
			argument = entry.argument,
			renderer = entry.renderer,
		}
	end
end

local function setDisabled(settingKey, disabled)
	local info = settingInfo[settingKey]
	if not info then return end
	local arg = info.argument or {}
	if (arg.disabled or false) == disabled then return end
	arg.disabled = disabled
	I.Settings.updateRendererArgument(info.groupKey, settingKey, arg)
end

function updateDisabledStates()
	local refundMode = S_refundMode
	local negativeRefunds = S_negativeRefunds

	local refundDisabled = (refundMode == "Disabled")
	local notExperimental = (refundMode ~= "EXPERIMENTAL")
	local noNegative = (not negativeRefunds) or notExperimental

	setDisabled("refundStart", refundDisabled)
	setDisabled("refundMult", refundDisabled)
	setDisabled("levelScaling", refundDisabled)
	setDisabled("negativeRefunds", refundDisabled or notExperimental)
	setDisabled("spellCostMultiplier", refundDisabled or noNegative)
	setDisabled("spellCostOffset", refundDisabled or noNegative)
end

updateDisabledStates()

--------------------------------------------------------------- Subscribe to changes ---------------------------------------------------------------

for _, template in pairs(settingsTemplate) do
	local section = storage.playerSection(template.key)
	section:subscribe(async:callback(function(_, setting)
		local val = section:get(setting)
		if percentKeys[setting] then
			val = val / 100
		end
		_G["S_" .. setting] = val
		if setting == "refundMode" or setting == "negativeRefunds" then
			updateDisabledStates()
		end
		if registerAnimation then registerAnimation() end
		if registerUse then registerUse() end
		if registerSkillUsed then registerSkillUsed() end
	end))
end