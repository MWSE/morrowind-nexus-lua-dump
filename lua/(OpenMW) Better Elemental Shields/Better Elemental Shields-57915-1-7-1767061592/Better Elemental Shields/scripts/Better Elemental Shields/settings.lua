MODNAME = "Better Elemental Shields"

local tempKey
local orderCounter = 0
local function getOrder()
	orderCounter = orderCounter + 1
	return orderCounter
end


local settingsTemplate = {}

tempKey = "General"
settingsTemplate[tempKey] = {
	key = 'SettingsPlayer'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = tempKey.."                                                  ",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "ENABLED",
			name = "Enabled",
			description = "Allows disabling the mod entirely",
			renderer = "checkbox",
			default = true,
		},
		
	},
}
tempKey = "VFX"
settingsTemplate[tempKey] = {
	key = 'SettingsPlayer'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = tempKey.."                                                  ",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "SHOW_SHIELD_VFX",
			name = "Show elemental shield VFX",
			description = "Filtered by duration and magnitude settings below",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "SHOW_BARRIER_VFX",
			name = "Show physical shield VFX",
			description = "Filtered by duration and magnitude settings below",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "MIN_MAGNITUDE",
			name = "Min magnitude",
			description = "Minimum magnitude for the VFX to show",
			renderer = "number",
			default = 3,
			integer = true
		},
		{
			key = "MAX_DURATION",
			name = "Max duration",
			description = "Maximum duration for the shield's visual effect to show\nSet to 9999 to show VFX of permanent effects",
			renderer = "number",
			default = 120,
			integer = true
		},
		
	},
}
tempKey = "Balance"
settingsTemplate[tempKey] = {
	key = 'SettingsPlayer'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = tempKey.."                                                  ",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "RADIUS",
			name = "Radius (in ft.)",
			description = "when 'On Nearby' is enabled",
			renderer = "number",
			default = 10,
		},
		{
			key = "SHIELD_MULT",
			name = "Armor multiplier",
			description = "Bonus armor from active shields (caps at 20)",
			renderer = "number",
			default = 0.3,
		},
		{
			key = "ELEMENT_CASTCHANCE_BONUS",
			name = "Elemental attunement",
			description = "Sound bonus when selected spell matches active shield element (multiplied by shield magnitude, caps at 20)",
			renderer = "number",
			default = 0.8,
		},
	},
}
if core.API_REVISION >= 97 then --if I.Combat then
	table.insert(settingsTemplate[tempKey].settings, 1, {
		key = "DAMAGE_RANGED_ATTACKERS",
		name = "Damage ranged attackers?",
		description = "if On Hit / On Attack is enabled",
		renderer = "checkbox",
		default = true,
	})
	table.insert(settingsTemplate[tempKey].settings, 1, {
		key = "BEHAVIOUR",
		name = "Behaviour",
		description = "On successful hits? Or every Attack? Or passively on nearby enemies?",
		default = "On Hit", 
		renderer = "select",
		argument = {
			disabled = false,
			l10n = "none", 
			items = {"On Hit", "On Attack", "On Nearby"}
		},
	})
else
	BEHAVIOUR = "On Nearby"
end


tempKey = "Fire"
settingsTemplate[tempKey] = {
	key = 'SettingsPlayer'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = tempKey.."                                                  ",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "FIRE_DAMAGE_MULT",
			name = "Fire Damage Mult",
			description = "times magnitude",
			renderer = "number",
			default = 0.6,
			argument = {
				min = 0,
				max = 100,
			},
		},
		{
			key = "FIRE_WEAK_MULT",
			name = "Fire Physical Weakness",
			description = "Points of armor removed from the target per magnitude",
			renderer = "number",
			default = 0.4,
		},
		{
			key = "FIRE_LIGHT",
			name = "Emit light",
			description = "when the VFX is shown",
			renderer = "checkbox",
			default = true,
		},
	}
}
tempKey = "Frost"
settingsTemplate[tempKey] = {
	key = 'SettingsPlayer'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = tempKey.."                                                  ",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "FROST_DAMAGE_MULT",
			name = "Frost Damage Mult",
			description = "times magnitude",
			renderer = "number",
			default = 0.5,
		},
		{
			key = "FROST_SLOW_HALF",
			name = "Frost Slow Halfpoint",
			description = "Magnitude needed to halve enemy speed (stacks)\n0=disable",
			renderer = "number",
			default = 15,
			integer = true,
		},
	}
}

tempKey = "Lightning"
settingsTemplate[tempKey] = {
	key = 'SettingsPlayer'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = tempKey.."                                                  ",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "LIGHTNING_DAMAGE_MULT",
			name = "Shock Damage Mult",
			description = "times magnitude",
			renderer = "number",
			default = 0.5,
		},
		{
			key = "LIGHTNING_RADIUS_MULT",
			name = "Shock Radius Mult",
			description = "when 'On Nearby' is enabled (multiplied by base radius)",
			renderer = "number",
			default = 1.5,
		},
		{
			key = "LIGHTNING_STUN_MULT",
			name = "Stun chance per magnitude",
			description = "Percentage chance to knockdown per point of shield magnitude",
			renderer = "number",
			default = 0.33,
		},
	}
}


tempKey = "NPCs and Creatures"
settingsTemplate[tempKey] = {
	key = 'SettingsPlayer'..MODNAME..tempKey,
	page = MODNAME,
	l10n = "none",
	name = tempKey.."                                                  ",
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "ACTORS_HAVE_AURA",
			name = "Actors have damaging aura",
			description = "Enemies with elemental shields can damage you when nearby",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "ACTORS_DAMAGE_MULT",
			name = "Actor Damage mult",
			description = "",
			renderer = "number",
			default = 0.2,
		},
		{
			key = "ACTORS_RADIUS",
			name = "Actor Radius (in ft.)",
			description = "",
			renderer = "number",
			default = 10,
		},
	},
}

if world then
	for id, template in pairs(settingsTemplate) do
		I.Settings.registerGroup(template)
	end
else
	I.Settings.registerPage {
		key = MODNAME,
		l10n = "none",
		name = "Better Elemental Shields",
		description = ""
	}
end


function readAllSettings()
	for _, template in pairs(settingsTemplate) do
		local settingsSection = storage.globalSection(template.key)
		for i, entry in pairs(template.settings) do
			local newValue = settingsSection:get(entry.key)
			if newValue == nil then
				newValue = entry.default
			end
			_G[entry.key] = newValue
		end
	end
end

readAllSettings()

-- ────────────────────────────────────────────────────────────────────────── Settings Event ──────────────────────────────────────────────────────────────────────────
for _, template in pairs(settingsTemplate) do
	local sectionName = template.key
	local settingsSection = storage.globalSection(template.key)
	settingsSection:subscribe(async:callback(function (_,setting)
		local oldValue = _G[setting]
		_G[setting] = settingsSection:get(setting)
	end))
end