local RENDERER_SLIDER = "SuperSlider3"     -- alt: "number"

-- pad to a fixed length so every group header takes the same column width
local function padName(name)
	return name .. string.rep(" ", math.max(0, 60 - #name))
end

local orderCounter = 0
local function getOrder()
	orderCounter = orderCounter + 1
	return orderCounter
end

local settingsTemplate = {}

------------------------- GENERAL -------------------------
local tempKey = "General"
settingsTemplate[tempKey] = {
	key = "Settings" .. MODNAME .. tempKey,
	page = MODNAME,
	l10n = "none",
	name = padName(tempKey),
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "Enabled",
			name = "Enabled",
			description = "Toggle the haste effect on or off for the player",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "NpcHaste",
			name = "Apply to NPCs",
			description = "Also apply haste to NPC animations.\nNPCs use their own weapon skill, magic skill, and Speed attribute.",
			renderer = "checkbox",
			default = false,
		},
	},
}

------------------------- BASE SPEED -------------------------
tempKey = "Base Speed"
settingsTemplate[tempKey] = {
	key = "Settings" .. MODNAME .. tempKey,
	page = MODNAME,
	l10n = "none",
	name = padName(tempKey),
	permanentStorage = true,
	description = "Baseline animation speed before any haste modifiers.\nfinal = (base + skillMod + speedMod - costMod) * recordSpeed",
	order = getOrder(),
	settings = {
		{
			key = "BaseWeaponSpeed",
			name = "Weapon base speed",
			description = "Baseline animation speed in weapon stance",
			renderer = RENDERER_SLIDER,
			default = 1.0,
			argument = {
				min = 0.25,
				max = 2.0,
				step = 0.05,
				default = 1.0,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Slow",
				maxLabel = "Fast",
				width = 150,
				thickness = 15,
				bottomRow = true,
			},
		},
		{
			key = "BaseMagicSpeed",
			name = "Magic base speed",
			description = "Baseline animation speed in spell stance",
			renderer = RENDERER_SLIDER,
			default = 1.0,
			argument = {
				min = 0.25,
				max = 2.0,
				step = 0.05,
				default = 1.0,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Slow",
				maxLabel = "Fast",
				width = 150,
				thickness = 15,
				bottomRow = true,
			},
		},
	},
}

------------------------- WEAPON SKILL -------------------------
tempKey = "Weapon Skill"
settingsTemplate[tempKey] = {
	key = "Settings" .. MODNAME .. tempKey,
	page = MODNAME,
	l10n = "none",
	name = padName(tempKey),
	permanentStorage = true,
	description = "Haste from weapon skill while in weapon stance.\n(skill - min) ^ exp * haste",
	order = getOrder(),
	settings = {
		{
			key = "MinWeaponSkill",
			name = "Minimum weapon skill",
			description = "Below this skill level no haste bonus applies\n(skill - MIN) ^ exp * haste",
			renderer = RENDERER_SLIDER,
			default = 30,
			argument = {
				min = 0,
				max = 200,
				step = 1,
				default = 30,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Always",
				maxLabel = "Never",
				width = 150,
				thickness = 15,
				bottomRow = true,
			},
		},
		{
			key = "WeaponSkillExponent",
			name = "Weapon skill exponent",
			description = "Exponential scaling for skill level\n(skill - min) ^ EXP * haste",
			renderer = RENDERER_SLIDER,
			default = 1.05,
			argument = {
				min = 0.5,
				max = 2.0,
				step = 0.01,
				default = 1.05,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Flat",
				maxLabel = "Steep",
				width = 150,
				thickness = 15,
				bottomRow = true,
			},
		},
		{
			key = "HastePerWeaponSkill",
			name = "Haste per weapon skill",
			description = "Percent speed increase per calculated skill point\n(skill - min) ^ exp * HASTE",
			renderer = RENDERER_SLIDER,
			default = 0.25,
			argument = {
				min = 0,
				max = 2,
				step = 0.05,
				default = 0.25,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "None",
				maxLabel = "Strong",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "%",
			},
		},
	},
}

------------------------- MAGIC SKILL -------------------------
tempKey = "Magic Skill"
settingsTemplate[tempKey] = {
	key = "Settings" .. MODNAME .. tempKey,
	page = MODNAME,
	l10n = "none",
	name = padName(tempKey),
	permanentStorage = true,
	description = "Haste from magic skill while in spell stance.\nThe relevant skill is the weighted average of the spell's effect schools.",
	order = getOrder(),
	settings = {
		{
			key = "MinMagicSkill",
			name = "Minimum magic skill",
			description = "Below this skill level no haste bonus applies\n(skill - MIN) ^ exp * haste",
			renderer = RENDERER_SLIDER,
			default = 30,
			argument = {
				min = 0,
				max = 200,
				step = 1,
				default = 30,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Always",
				maxLabel = "Never",
				width = 150,
				thickness = 15,
				bottomRow = true,
			},
		},
		{
			key = "MagicSkillExponent",
			name = "Magic skill exponent",
			description = "Exponential scaling for skill level\n(skill - min) ^ EXP * haste",
			renderer = RENDERER_SLIDER,
			default = 1.05,
			argument = {
				min = 0.5,
				max = 2.0,
				step = 0.01,
				default = 1.05,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Flat",
				maxLabel = "Steep",
				width = 150,
				thickness = 15,
				bottomRow = true,
			},
		},
		{
			key = "HastePerMagicSkill",
			name = "Haste per magic skill",
			description = "Percent speed increase per calculated skill point\n(skill - min) ^ exp * HASTE",
			renderer = RENDERER_SLIDER,
			default = 0.3,
			argument = {
				min = 0,
				max = 2,
				step = 0.05,
				default = 0.3,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "None",
				maxLabel = "Strong",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "%",
			},
		},
	},
}
------------------------- SPELL COST -------------------------
tempKey = "Spell Cost"
settingsTemplate[tempKey] = {
	key = "Settings" .. MODNAME .. tempKey,
	page = MODNAME,
	l10n = "none",
	name = padName(tempKey),
	permanentStorage = true,
	description = "Slowdown from the spell's magicka cost while in spell stance.\n(cost - min) ^ exp * slow, subtracted from the haste.",
	order = getOrder(),
	settings = {
		{
			key = "MinSpellCost",
			name = "Minimum spell cost",
			description = "Below this magicka cost no slowdown applies\n(cost - MIN) ^ exp * slow",
			renderer = RENDERER_SLIDER,
			default = 5,
			argument = {
				min = 0,
				max = 200,
				step = 1,
				default = 5,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Always",
				maxLabel = "Never",
				width = 150,
				thickness = 15,
				bottomRow = true,
			},
		},
		{
			key = "SpellCostExponent",
			name = "Spell cost exponent",
			description = "Exponential scaling for magicka cost\n(cost - min) ^ EXP * slow",
			renderer = RENDERER_SLIDER,
			default = 1.05,
			argument = {
				min = 0.5,
				max = 2.0,
				step = 0.01,
				default = 1.05,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Flat",
				maxLabel = "Steep",
				width = 150,
				thickness = 15,
				bottomRow = true,
			},
		},
		{
			key = "SlowPerSpellCost",
			name = "Slow per spell cost",
			description = "Percent speed decrease per calculated cost point\n(cost - min) ^ exp * SLOW",
			renderer = RENDERER_SLIDER,
			default = 0.5,
			argument = {
				min = 0,
				max = 2,
				step = 0.05,
				default = 0.5,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "None",
				maxLabel = "Strong",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "%",
			},
		},
	},
}
------------------------- SPEED ATTRIBUTE -------------------------
tempKey = "Speed Attribute"
settingsTemplate[tempKey] = {
	key = "Settings" .. MODNAME .. tempKey,
	page = MODNAME,
	l10n = "none",
	name = padName(tempKey),
	permanentStorage = true,
	description = "Haste from the Speed attribute. Always applied regardless of stance.",
	order = getOrder(),
	settings = {
		{
			key = "MinLevel",
			name = "Minimum speed attribute",
			description = "Below this attribute value no haste bonus applies\n(speed - MIN) ^ exp * haste",
			renderer = RENDERER_SLIDER,
			default = 35,
			argument = {
				min = 0,
				max = 200,
				step = 1,
				default = 35,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Always",
				maxLabel = "Never",
				width = 150,
				thickness = 15,
				bottomRow = true,
			},
		},
		{
			key = "LevelExponent",
			name = "Speed exponent",
			description = "Exponential scaling for the speed attribute\n(speed - min) ^ EXP * haste",
			renderer = RENDERER_SLIDER,
			default = 1.05,
			argument = {
				min = 0.5,
				max = 2.0,
				step = 0.01,
				default = 1.05,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "Flat",
				maxLabel = "Steep",
				width = 150,
				thickness = 15,
				bottomRow = true,
			},
		},
		{
			key = "HastePerLevel",
			name = "Haste per speed point",
			description = "Percent speed increase per calculated attribute point\n(speed - min) ^ exp * HASTE",
			renderer = RENDERER_SLIDER,
			default = 0.45,
			argument = {
				min = 0,
				max = 2,
				step = 0.05,
				default = 0.45,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = "None",
				maxLabel = "Strong",
				width = 150,
				thickness = 15,
				bottomRow = true,
				unit = "%",
			},
		},
	},
}

------------------------- REGISTRATION -------------------------
-- world is only defined in the global script context
if world then
	for _, template in pairs(settingsTemplate) do
		I.Settings.registerGroup(template)
	end
else
	I.Settings.registerPage {
		key = MODNAME,
		l10n = "none",
		name = "SpeedHaste",
		description = "Scales attack and spellcast animation speed with weapon skill, magic skill, and the Speed attribute. Expensive spells cast slower.\n\nFormula per source: (stat - min) ^ exponent * haste / 100\nFinal animation speed = (base + weaponMod + magicMod + speedMod - costMod) * recordSpeed",
	}
end

------------------------- READ + SUBSCRIBE -------------------------
-- read all settings into S_ globals
local function readAllSettings()
	for _, template in pairs(settingsTemplate) do
		local settingsSection = storage.globalSection(template.key)
		for _, entry in pairs(template.settings) do
			local newValue = settingsSection:get(entry.key)
			if newValue == nil then
				newValue = entry.default
			end
			_G["S_" .. entry.key] = newValue
		end
	end
end

readAllSettings()

-- live updates on change
for _, template in pairs(settingsTemplate) do
	local settingsSection = storage.globalSection(template.key)
	settingsSection:subscribe(async:callback(function(_, setting)
		_G["S_" .. setting] = settingsSection:get(setting)
		-- global-only: keep npc hooks and their settings in sync
		if world then
			if setting == "NpcHaste" then
				if F_rebuildHooks then F_rebuildHooks() end
			else
				if F_broadcastSettings then F_broadcastSettings() end
			end
		end
	end))
end
