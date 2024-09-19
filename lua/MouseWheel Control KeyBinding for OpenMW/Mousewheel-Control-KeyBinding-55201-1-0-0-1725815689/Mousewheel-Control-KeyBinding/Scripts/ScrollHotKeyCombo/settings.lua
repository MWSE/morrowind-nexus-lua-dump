--[[

Mod: MultiKeyCombo
Author: Nitro

--]]

local async = require("openmw.async")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local input = require("openmw.input")
local ui = require("openmw.ui")

local modInfo = require("Scripts.ScrollHotKeyCombo.modInfo")

local pageDescription = "By Nitro\nv" .. modInfo.version .. "\n\nScrollable Magick and weapons. This mod allows" ..
						" mousewheel + KeyBind to scroll through weapons and spells." ..
						" The keybinds are userdefined, and there are several options to specify which spells to include in the spell selection."
local modEnableDescription = "This enables the mod or disables it."
local showMessagesDescription = "Enables UI messages to be shown for any cases which require it. (Currently none)"
local weaponHotkeyDescription = "This is the key to bind to a scrollable mousewheel input (e.g. key + MouseWheelUp) for weapon selection"
local spellHotkeyDescription = "This is the key to bind to a scrollable mousewheel input (e.g. key + MouseWheelUp) for spell selection"
local spellSelectDescription = "Include spells in spell selection:"
local powerSelectDescription = "Include powers in spell selection:"
local EnchItemSelectDescription = "Include Enchanted Items in Spell selection:"
local trinketsOnlyDescription = "This will limit the scrolled magic enchanted items to rings and amulets ONLY"
local spellScrollDescription = "This will exclude Spell Scrolls from the Spell List"

local function setting(key, renderer, argument, name, description, default)
	return {
		key = key,
		renderer = renderer,
		argument = argument,
		name = name,
		description = description,
		default = default,
	}
end

I.Settings.registerPage {
	key = modInfo.name,
	l10n = modInfo.name,
	name = "Mousewheel-Control-Keybinds",
	description = pageDescription
}

I.Settings.registerGroup {
	key = "SettingsPlayer" .. modInfo.name,
	page = modInfo.name,
	order = 0,
	l10n = modInfo.name,
	name = "General",
	permanentStorage = false,
	settings = {
		setting("modEnable", "checkbox", {}, "Enable Mod", modEnableDescription, true),
	}
}

I.Settings.registerGroup {
	key = "SettingsPlayer" .. modInfo.name .. "UI",
	page = modInfo.name,
	order = 1,
	l10n = modInfo.name,
	name = "UI",
	permanentStorage = false,
	settings = {
		setting("showMessages", "checkbox", {}, "Show Messages", showMessagesDescription, true),
	}
}

I.Settings.registerGroup {
	key = "SettingsPlayer" .. modInfo.name .. "Controls",
	page = modInfo.name,
	order = 2,
	l10n = modInfo.name,
	name = "Controls",
	permanentStorage = false,
	settings = {
		setting("nextWeaponHotKey", "nitroInputKeySelection", {}, "Weapon Scroll Key", weaponHotkeyDescription, input.KEY.X),
		setting("nextSpellHotKey", "nitroInputKeySelection", {}, "Spell Scroll Key", spellHotkeyDescription, input.KEY.Z),
	}
}


-- No need to even show this setting in 0.48
if (core.API_REVISION >= 31) then
	I.Settings.registerGroup {
		key = "SettingsPlayer" .. modInfo.name .. "Gameplay",
		page = modInfo.name,
		order = 3,
		l10n = modInfo.name,
		name = "Gameplay",
		permanentStorage = false,
		description = "The default behavior is to allow scrolling of powers, spells and enchanted items equivalent to base game.",
		settings = {
			setting("powerSelect", "checkbox", {}, "Powers", powerSelectDescription, true),
			setting("spellSelect", "checkbox", {}, "Spells", spellSelectDescription, true),
			setting("enchantSelect", "checkbox", {}, "Enchanted Items", EnchItemSelectDescription, true),
			setting("trinketsOnly", "checkbox", {}, "Limit enchanted item scrolling", trinketsOnlyDescription, false),
			setting("excludeScrolls", "checkbox", {}, "Exclude Spell Scrolls", spellScrollDescription, false),
		}
	}
end

--[[ for _, actionInfo in ipairs(actions) do
	--print(actionInfo)
	input.registerAction(actionInfo)
end ]]

print("[" .. modInfo.name .. "] Initialized v" .. modInfo.version)
