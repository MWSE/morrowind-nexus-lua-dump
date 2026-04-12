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

--------------------------------------------------------------- Skill Uncapper ---------------------------------------------------------------

tempKey = "SkillUncapper"
settingsTemplate[tempKey] = {
	key = 'SettingsPlayer'..MOD_NAME..tempKey,
	page = MOD_NAME,
	l10n = "none",
	name = L("Group.SkillUncapper", "Skill Uncapper").."                                             ",
	description = L("Group.SkillUncapperDesc", "You can set custom caps for each skill and attribute in Uncapper_capTable.lua"),
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "enableSkillUncapper",
			name = L("enableSkillUncapper.name", "Skill Uncapper"),
			description = L("enableSkillUncapper.desc", "Skills can be leveled higher than 100."),
			default = true,
			renderer = "checkbox",
			argument = {},
		},
		{
			key = "skillHardCap",
			name = L("skillHardCap.name", "Skill Hard Cap"),
			description = L("skillHardCap.desc",
				"Absolute maximum skill level.\n"
				.. "Ignored if cap table is locked in code."),
			default = 200,
			renderer = RENDERER_SLIDER,
			argument = {
				min = 100,
				max = 1000,
				step = 10,
				default = 200,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
				minLabel = "100",
				maxLabel = "1000",
				centerLabel = "Hard Cap",
				width = 150,
				thickness = 15,
			},
		},
		{
			key = "skillSoftCap",
			name = L("skillSoftCap.name", "Skill Soft Cap"),
			description = L("skillSoftCap.desc",
				"At this skill level, the XP penalty multiplier kicks in.\n"
				.. "Ignored if cap table is locked in code."),
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
				centerLabel = "Soft Cap",
				width = 150,
				thickness = 15,
			},
		},
		{
			key = "skillXPMultAtSoftCap",
			name = L("skillXPMultAtSoftCap.name", "XP Mult at Soft Cap (%)"),
			description = L("skillXPMultAtSoftCap.desc",
				"XP gain multiplier applied at and above the soft cap.\n"
				.. "50% = half XP.\n"
				.. "Ignored if cap table is locked in code."),
			default = 50,
			renderer = RENDERER_SLIDER,
			argument = {
				min = 0,
				max = 200,
				step = 5,
				default = 50,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
				minLabel = "0%",
				maxLabel = "200%",
				centerLabel = "XP Mult",
				width = 150,
				thickness = 15,
				unit = "%",
			},
		},
	},
}
percentKeys["skillXPMultAtSoftCap"] = true

if SHOW_LEGACY_OPTION then
	table.insert(settingsTemplate[tempKey].settings, 2, {
		key = "skillUncapperMode",
		name = L("skillUncapperMode.name", "Skill Uncapper Mode"),
		description = L("skillUncapperMode.desc",
			"Override: Replaces the engine's skill cap check directly.\n"
			.. "Legacy: Temporarily reduces skills before book reads "
			.. "and manually handles progression past 100 (old MBSP method)."),
		default = "Override",
		renderer = "select",
		argument = {
			disabled = false,
			l10n = "none",
			items = {"Override", "Legacy"},
		},
	})
end


--------------------------------------------------------------- Attribute Uncapper ---------------------------------------------------------------

tempKey = "AttributeUncapper"
settingsTemplate[tempKey] = {
	key = 'SettingsPlayer'..MOD_NAME..tempKey,
	page = MOD_NAME,
	l10n = "none",
	name = L("Group.AttributeUncapper", "Attribute Uncapper").."                                             ",
	description = L("Group.AttributeUncapperDesc", "You can set custom caps for each skill and attribute in Uncapper_capTable.lua"),
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "AttributeUncapper",
			name = L("AttributeUncapper.name", "Attribute Uncapper"),
			description = L("AttributeUncapper.desc", "Attributes can be leveled past 100"),
			default = true,
			renderer = "checkbox",
			argument = {},
		},
		{
			key = "attributeUncapperMode",
			name = L("attributeUncapperMode.name", "Attribute Uncapper Mode"),
			description = L("attributeUncapperMode.desc",
				"TemporaryCap: Temporarily cap attributes before the vanilla level up screen.\n"
				.. "CustomUI: Replace the level up screen with a custom one."),
			default = "CustomUI",
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none",
				items = {"TemporaryCap", "CustomUI"},
			},
		},
		{
			key = "attrHardCap",
			name = L("attrHardCap.name", "Attribute Hard Cap"),
			description = L("attrHardCap.desc",
				"Absolute maximum attribute level."),
			default = 200,
			renderer = RENDERER_SLIDER,
			argument = {
				min = 100,
				max = 1000,
				step = 10,
				default = 200,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
				minLabel = "Lvl 100",
				maxLabel = "Lvl 1000",
				centerLabel = "Hard Cap",
				width = 150,
				thickness = 15,
			},
		},
		{
			key = "attrSoftCap",
			name = L("attrSoftCap.name", "Attribute Soft Cap"),
			description = L("attrSoftCap.desc",
				"At this attribute level, gains per level are restricted.\n"
				.. "Values below 100 only work in CustomUI Mode."),
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
				centerLabel = "Soft Cap",
				width = 150,
				thickness = 15,
			},
		},
		{
			key = "attrMaxGainsPerLevel",
			name = L("attrMaxGainsPerLevel.name", "Max Gains Per Level"),
			description = L("attrMaxGainsPerLevel.desc",
				"Maximum attribute increase per level up once above the soft cap."),
			default = 3,
			renderer = RENDERER_SLIDER,
			argument = {
				min = 1,
				max = 5,
				step = 1,
				default = 3,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
				minLabel = "1x",
				maxLabel = "5x",
				centerLabel = "Max Gain",
				width = 150,
				thickness = 15,
				unit = "x",
			},
		},
		{
			key = "attrNeededSkillIncMult",
			name = L("attrNeededSkillIncMult.name", "Needed Skill Increases Mult"),
			description = L("attrNeededSkillIncMult.desc",
				"Above the soft cap, you need this many times as many skill increases\n"
				.. "1 = no change, 2 = double."),
			default = 1.5,
			renderer = RENDERER_SLIDER,
			argument = {
				min = 1,
				max = 2,
				step = 0.1,
				default = 1.5,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
				minLabel = "1x",
				maxLabel = "2x",
				centerLabel = "Inc Mult",
				width = 150,
				thickness = 15,
				unit = "x",
			},
		},
		{
			key = "HarderEndurance",
			name = L("HarderEndurance.name", "Harder Endurance"),
			description = L("HarderEndurance.desc", "- Moves the soft cap closer to 100\n- Halves the Max Gains Per Level\n- Multiplies the Needed Skill Increases by 1.5x"),
			default = true,
			renderer = "checkbox",
			argument = {},
		},
		{
			key = "luckGains",
			name = L("luckGains.name", "Luck Gains"),
			description = L("luckGains.desc",
				"Custom luck multiplier on the levelup screen\n"
				.. "If you set this to 1+, then you..\n"
				.. "- can spend multiple coins into luck\n"
				.. "- always get 3 levelup coins, even if all attributes are maxed"),
			default = 1,
			renderer = RENDERER_SLIDER,
			argument = {
				min = 0,
				max = 5,
				step = 1,
				default = 1,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
				minLabel = "Vanilla",
				maxLabel = "x5",
				centerLabel = "Luck Gains",
				width = 150,
				thickness = 15,
				unit = "x",
			},
		},
	},
}

--------------------------------------------------------------- Master XP Settings ---------------------------------------------------------------

tempKey = "MasterXP"
settingsTemplate[tempKey] = {
	key = 'SettingsPlayer'..MOD_NAME..tempKey,
	page = MOD_NAME,
	l10n = "none",
	name = L("Group.MasterXP", "Master XP Settings").."                                             ",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "enableXPMult",
			name = L("enableXPMult.name", "Enable Skill XP Multipliers"),
			description = L("enableXPMult.desc",
				"If disabled, the global multiplier setting below "
				.. "and all per-skill settings are ignored"),
			default = true,
			renderer = "checkbox",
		},
		{
			key = "globalXPMult",
			name = L("globalXPMult.name", "Global XP Multiplier (%)"),
			description = L("globalXPMult.desc",
				"Multiplies all skill XP gained.\n"
				.. "Applied on top of the per-skill settings.\n"
				.. "If using a mod like Reading is Good, reducing this is recommended."),
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
				centerLabel = "Global XP",
				width = 150,
				thickness = 15,
				unit = "%",
			},
		},
		{
			key = "CATCH_UP_SPEED",
			name = L("CATCH_UP_SPEED.name", "Catch Up Speed (%)"),
			description = L("CATCH_UP_SPEED.desc",
				"The experience multiplier for skills that are below 2x your player level "
				.. "(ramps up gradually).\n\n"
				.. "For example, at player level 30 your skills are expected to be at 60.\n"
				.. "This setting will help other skills catch up to that."),
			default = 150,
			renderer = RENDERER_SLIDER,
			argument = {
				min = 50,
				max = 1000,
				step = 10,
				default = 150,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
				minLabel = "50%",
				maxLabel = "1000%",
				centerLabel = "Catch up XP",
				width = 150,
				thickness = 15,
				unit = "%",
			},
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
percentKeys["CATCH_UP_SPEED"] = true
percentKeys["globalXPMult"] = true

--------------------------------------------------------------- Skill XP Multipliers ---------------------------------------------------------------

local skillMultipliers = {
	combat = {
		{"armorer",     100},
		{"athletics",    90},
		{"axe",          90},
		{"block",       100},
		{"bluntweapon",  90},
		{"heavyarmor",  120},
		{"longblade",    90},
		{"mediumarmor", 110},
		{"spear",        90},
	},
	magic = {
		{"alchemy",     100},
		{"alteration",  140},
		{"conjuration", 150},
		{"destruction",  90},
		{"enchant",     110},
		{"illusion",    150},
		{"mysticism",   150},
		{"restoration", 100},
		{"unarmored",   130},
	},
	stealth = {
		{"acrobatics",   80},
		{"handtohand",   90},
		{"lightarmor",  110},
		{"marksman",     90},
		{"mercantile",  100},
		{"security",    110},
		{"shortblade",   90},
		{"sneak",       160},
		{"speechcraft", 110},
	},
}

local specNames = {
	combat  = L("Group.CombatXP",  "Combat Skill XP"),
	magic   = L("Group.MagicXP",   "Magic Skill XP"),
	stealth = L("Group.StealthXP", "Stealth Skill XP"),
}

local specOrder = {"combat", "magic", "stealth"}

for _, spec in ipairs(specOrder) do
	tempKey = "SkillXP_"..spec
	settingsTemplate[tempKey] = {
		key = 'SettingsPlayer'..MOD_NAME..tempKey,
		page = MOD_NAME,
		l10n = "none",
		name = specNames[spec].."                                             ",
		permanentStorage = true,
		order = getOrder(),
		settings = {},
	}
	local skills = skillMultipliers[spec]

	for _, entry in ipairs(skills) do
		local skill, pct = entry[1], entry[2]
		local displayName = statNames[skill]
		if not displayName then
			print("WARNING: SKILL NOT FOUND", skill)
		else
			local settingKey = "SKILL_MULT_"..skill
			table.insert(settingsTemplate[tempKey].settings, {
				key = settingKey,
				name = L(settingKey..".name", displayName.." XP (%)"),
				description = "",
				default = pct,
				renderer = RENDERER_SLIDER,
				argument = {
					min = 0,
					max = 500,
					step = 5,
					default = pct,
					showDefaultMark = true,
					showResetButton = false,
					bottomRow = false,
					minLabel = "0%",
					maxLabel = "500%",
					centerLabel = displayName,
					labelSize = 14,
					width = 150,
					thickness = 15,
					unit = "%",
				},
			})
			percentKeys[settingKey] = true
		end
	end
end

--------------------------------------------------------------- Register ---------------------------------------------------------------

for _, template in pairs(settingsTemplate) do
	I.Settings.registerGroup(template)
end

I.Settings.registerPage {
	key = MOD_NAME,
	l10n = "none",
	name = "Uncapper",
	description = L("Page.desc",
		"Skill & Attribute Uncapper with XP Multipliers"),
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
	if SHOW_LEGACY_OPTION then
		USING_LEGACY_UNCAPPER = S_skillUncapperMode == "Legacy"
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
	local enableXPMult = S_enableXPMult

	-- skill uncapper
	if SHOW_LEGACY_OPTION then
		setDisabled("skillUncapperMode", not S_enableSkillUncapper)
	end

	-- skill cap settings
	setDisabled("skillSoftCap", not S_enableSkillUncapper or LOCK_CAP_TABLE)
	setDisabled("skillXPMultAtSoftCap", not S_enableSkillUncapper or LOCK_CAP_TABLE)
	setDisabled("skillHardCap", not S_enableSkillUncapper or LOCK_CAP_TABLE)

	-- attribute uncapper
	setDisabled("attributeUncapperMode", not S_AttributeUncapper)

	-- attribute cap settings
	setDisabled("attrSoftCap", not S_AttributeUncapper or LOCK_CAP_TABLE)
	setDisabled("attrMaxGainsPerLevel", not S_AttributeUncapper or LOCK_CAP_TABLE)
	setDisabled("attrNeededSkillIncMult", not S_AttributeUncapper or LOCK_CAP_TABLE)
	setDisabled("attrHardCap", not S_AttributeUncapper or LOCK_CAP_TABLE)
	setDisabled("luckGains", S_attributeUncapperMode ~= 'CustomUI')

	-- xp multipliers
	setDisabled("globalXPMult", not enableXPMult)
	setDisabled("CATCH_UP_SPEED", not enableXPMult)

	for _, spec in ipairs(specOrder) do
		local skills = skillMultipliers[spec]
		for _, entry in ipairs(skills) do
			setDisabled("SKILL_MULT_"..entry[1], not enableXPMult)
		end
	end
end

updateDisabledStates()

--------------------------------------------------------------- Cap setting keys ---------------------------------------------------------------

local capSettingKeys = {
	skillSoftCap = true,
	skillXPMultAtSoftCap = true,
	skillHardCap = true,
	attrSoftCap = true,
	attrMaxGainsPerLevel = true,
	attrNeededSkillIncMult = true,
	attrHardCap = true,
	HarderEndurance = true,
}
applyCapsFromSettings()
--------------------------------------------------------------- Subscribe to changes ---------------------------------------------------------------

for _, template in pairs(settingsTemplate) do
	local section = storage.playerSection(template.key)
	section:subscribe(async:callback(function(_, setting)
		local val = section:get(setting)
		if percentKeys[setting] then
			val = val / 100
		end
		_G["S_" .. setting] = val
		if S_AttributeUncapper and S_attributeUncapperMode == 'CustomUI' then
			ui._setWindowDisabled('LevelUpDialog', true)
		else
			ui._setWindowDisabled('LevelUpDialog', false)
		end
		if setting == "enableXPMult"
		or setting == "AttributeUncapper"
		or setting == "attributeUncapperMode"
		or setting == "enableSkillUncapper"
		or setting == "skillUncapperMode" then
			if SHOW_LEGACY_OPTION then
				USING_LEGACY_UNCAPPER = S_skillUncapperMode == "Legacy"
			end
			updateDisabledStates()
		end
		if capSettingKeys[setting] then
			applyCapsFromSettings()
		end
		if registerSkillLevelUp then registerSkillLevelUp() end
		if registerSkillUsed then registerSkillUsed() end
	end))
end