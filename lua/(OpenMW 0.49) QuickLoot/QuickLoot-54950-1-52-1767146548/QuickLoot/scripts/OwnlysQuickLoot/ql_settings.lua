local function getColorFromGameSettings(colorTag)
    local result = core.getGMST(colorTag)
	if not result then
		return util.color.rgb(1,1,1)
	end
    local rgb = {}
    for color in string.gmatch(result, '(%d+)') do
        table.insert(rgb, tonumber(color))
    end
    if #rgb ~= 3 then
        print("UNEXPECTED COLOR: rgb of size=", #rgb)
        return util.color.rgb(1, 1, 1)
    end
    return util.color.rgb(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255)
end
-- Settings Migration
local legacySection = storage.playerSection('SettingsPlayer'..MODNAME)
if legacySection:get("FOOTER_HINTS") ==  "F / R" then
	legacySection:set("FOOTER_HINTS", "Symbolic")
end


local tempKey
local orderCounter = 0
local function getOrder()
	orderCounter = orderCounter + 1
	return orderCounter
end

local function boolDefault(value, default)
	if value == nil then return default end
	return value
end

local settingsTemplate = {}
-- change name maybe:
--cleanSettingsTemplate = settingsTemplate

tempKey = "General"
settingsTemplate[tempKey] = {
    key = 'SettingsPlayer'..MODNAME..tempKey,
    page = MODNAME,
    l10n = "none",
    name = tempKey.."                                                    ", -- "select" renderer fix
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "ENABLED",
			name = "Enabled",
			description = "Allows disabling the mod entirely",
			renderer = "checkbox",
			default = boolDefault(legacySection:get("ENABLED"), true),
		},
		{
			key = "CONTAINER_ANIMATION",
			name = "Container Animation",
			description = "For 'Animated Containers' \nCan make looting stuff on top of containers more difficult\nIf it doesn't work, your OpenMW version might not be recent enough",
			default = legacySection:get("CONTAINER_ANIMATION") or "immediately", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none", 
				items = {"off", "immediately", "on take", "disabled by shift"},
			},
		},
		{
			key = "PICKPOCKETING",
			name = "Enable Pickpocketing",
			description = "",
			renderer = "checkbox",
			default = boolDefault(legacySection:get("PICKPOCKETING"), true)
		},
	},
}

tempKey = "UI"
settingsTemplate[tempKey] = {
    key = 'SettingsPlayer'..MODNAME..tempKey,
    page = MODNAME,
    l10n = "none",
    name = tempKey,
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "WIDTH",
			name = "Width (%)",
			description = "of the ui element (1-100)",
			renderer = "number",
			default = legacySection:get("WIDTH") or 23,
			argument = {
				min = 1,
				max = 100,
			},
		},
		{
			key = "HEIGHT",
			name = "Height (%)",
			description = "of the ui element (1-100)",
			renderer = "number",
			default = legacySection:get("HEIGHT") or 35,
			argument = {
				min = 1,
				max = 100,
			},
		},
		{
			key = "X",
			name = "X Position (%)",
			description = "Location of the center (1-100)",
			renderer = "number",
			default = legacySection:get("X") or 71,
			argument = {
				min = 1,
				max = 100,
			},
		},
		{
			key = "Y",
			name = "Y Position (%)",
			description = "Location of the center (1-100)",
			renderer = "number",
			default = legacySection:get("Y") or 50,
			argument = {
				min = 1,
				max = 100,
			},
		},
		{
			key = "TEXTSIZEMULT",
			name = "Text Size Multiplier (%)",
			description = "1-200",
			renderer = "number",
			default = legacySection:get("textSizeMult") or 93,
			argument = {
				min = 1,
				max = 200,
			},
		},
		{
			key = "HEADER_FOOTER",
			name = "List Header/Footer",
			description = "Show list header/footer",
			default = legacySection:get("HEADER_FOOTER") or "show both", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none", 
				items = {"hide both", "show both", "all top", "all bottom", "only top", "only bottom"},
			},
		},
		{
			key = "FOOTER_HINTS",
			name = "Keybinding Hints",
			description = "Shows the keybinding hints for 'Take All' and 'Search'",
			default = legacySection:get("FOOTER_HINTS") or "Symbolic", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none", 
				items = {"Disabled", "Symbolic"}--, "F / R"},
			},
		},
		{
			key = "BORDER_STYLE",
			name = "Border Style",
			description = "",
			default = legacySection:get("BORDER_STYLE") or "thin", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none", 
				items = {"none", "thin", "normal", "thick", "verythick"}--,"stylized 1", "stylized 2", "stylized 3", "stylized 4"},
			},
		},
		{
			key = "BORDER_FIX",
			name = "Border Fix",
			description = "Use vanilla borders, so the equipped indicator doesnt turn invisible",
			renderer = "checkbox",
			default = boolDefault(legacySection:get("BORDER_FIX"), true)
		},
		{
			key = "FONT_TINT",
			name = "Font Color",
			description = "",
			disabled = false,
			default = legacySection:get("FONT_TINT") or getColorFromGameSettings("FontColor_color_normal"), --green
			renderer = "color",
		},
		{
			key = "ICON_TINT",
			name = "Icon Tint",
			description = "",
			disabled = false,
			default = legacySection:get("ICON_TINT") or getColorFromGameSettings("FontColor_color_normal_over"), --green
			renderer = "color",
		},
		{
			key = "HAND_SYMBOL",
			name = "Stealing Hand Symbol",
			description = "Enable the pink hand next to the red text when the container belongs to someone",
			renderer = "checkbox",
			default = boolDefault(legacySection:get("HAND_SYMBOL"), true)
		},
		{
			key = "TRANSPARENCY",
			name = "Transparency",
			description = "",
			renderer = "number",
			default = legacySection:get("TRANSPARENCY") or 0.4,
			argument = {
				min = 0,
				max = 1,
			},
		},
		{
			key = "FONT_FIX",
			name = "Fix buggy font",
			description = "If you see boxes or questionmarks where there should be numbers, enable this setting to disable reliance on the included font",
			renderer = "checkbox",
			default = boolDefault(legacySection:get("FONT_FIX"), true)
		},
	},
}

tempKey = "Sorting"
settingsTemplate[tempKey] = {
    key = 'SettingsPlayer'..MODNAME..tempKey,
    page = MODNAME,
    l10n = "none",
    name = tempKey,
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "CONTAINER_SORTING_STATS",
			name = "Item Sorting by Value / Weight",
			description = "Changes the order of icons in containers",
			default = legacySection:get("CONTAINER_SORTING_STATS") or "Best V/W", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none", 
				items = {"Vanilla", "Lowest Weight", "Highest Value", "Best V/W"},
			},
		},
		{
			key = "CONTAINER_SORTING_QUEST",
			name = "Sorting: Quest Items On Top",
			description = "Let me know if you find any that got falsely flagged as quest",
			renderer = "checkbox",
			default = boolDefault(legacySection:get("CONTAINER_SORTING_QUEST"), true)
		},
		{
			key = "CONTAINER_SORTING_CASH",
			name = "Sorting: Cash On Top",
			description = "",
			renderer = "checkbox",
			default = boolDefault(legacySection:get("CONTAINER_SORTING_CASH"), true)
		},
		{
			key = "CONTAINER_SORTING_KEYS",
			name = "Sorting: Keys On Top",
			description = "",
			renderer = "checkbox",
			default = boolDefault(legacySection:get("CONTAINER_SORTING_KEYS"), true)
		},
		{
			key = "CONTAINER_SORTING_LOCKPICKS",
			name = "Sorting: Lockpicks On Top",
			description = "",
			renderer = "checkbox",
			default = boolDefault(legacySection:get("CONTAINER_SORTING_LOCKPICKS"), true)
		},
		{
			key = "CONTAINER_SORTING_SOULGEMS",
			name = "Sorting: Soulgems On Top",
			description = "",
			renderer = "checkbox",
			default = boolDefault(legacySection:get("CONTAINER_SORTING_SOULGEMS"), true)
		},
		{
			key = "CONTAINER_SORTING_INGREDIENTS",
			name = "Sorting: Ingredients Below [x] Weight On Top",
			description = "0 = Disable",
			renderer = "number",
			default = legacySection:get("CONTAINER_SORTING_INGREDIENTS") or 1.5,
			argument = {
				min = 0,
				max = 200,
			},
		},
		{
			key = "CONTAINER_SORTING_REPAIR",
			name = "Sorting: Repair Tools On Top",
			description = "",
			renderer = "checkbox",
			default = boolDefault(legacySection:get("CONTAINER_SORTING_REPAIR"), true)
		},
	},
}

tempKey = "Columns"
settingsTemplate[tempKey] = {
    key = 'SettingsPlayer'..MODNAME..tempKey,
    page = MODNAME,
    l10n = "none",
    name = tempKey,
	permanentStorage = true,
	order = getOrder(),
	settings = {
				{
			key = "COLUMN_PICKPOCKET",
			name = "Show Pickpocket Column",
			description = "",
			renderer = "checkbox",
			default = boolDefault(legacySection:get("COLUMN_PICKPOCKET"), true)
		},
		{
			key = "COLUMN_WEIGHT",
			name = "Show Weight Column",
			description = "",
			renderer = "checkbox",
			default = boolDefault(legacySection:get("COLUMN_WEIGHT"), true)
		},
		{
			key = "COLUMN_WEIGHT_PICKPOCKETING",
			name = "Show Weight Column When Pickpocketing",
			description = "",
			renderer = "checkbox",
			default = boolDefault(legacySection:get("COLUMN_WEIGHT_PICKPOCKETING"), true)
		},
		{
			key = "COLUMN_VALUE",
			name = "Show Value Column",
			description = "",
			renderer = "checkbox",
			default = boolDefault(legacySection:get("COLUMN_VALUE"), true)
		},
		{
			key = "COLUMN_VALUE_PICKPOCKETING",
			name = "Show Value Column When Pickpocketing",
			description = "",
			renderer = "checkbox",
			default = boolDefault(legacySection:get("COLUMN_VALUE_PICKPOCKETING"), true)
		},
		{
			key = "COLUMN_WV",
			name = "Show V/W Column",
			description = "",
			renderer = "checkbox",
			default = boolDefault(legacySection:get("COLUMN_WV"), true)
		},
		{
			key = "COLUMN_WV_PICKPOCKETING",
			name = "Show V/W Column When Pickpocketing",
			description = "",
			renderer = "checkbox",
			default = boolDefault(legacySection:get("COLUMN_WV_PICKPOCKETING"), false)
		},
	},
}

tempKey = "Tooltip"
settingsTemplate[tempKey] = {
    key = 'SettingsPlayer'..MODNAME..tempKey,
    page = MODNAME,
    l10n = "none",
    name = tempKey,
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "TOOLTIP_MODE",
			name = "Tooltip position",
			description = "Doesn't work with the font fix below",
			default = legacySection:get("TOOLTIP_MODE") or "left", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none", 
				items = {"off", "left","left (fixed)", "left (fixed 2)", "left (fixed 3)", "right", "right (fixed)", "right (fixed 2)", "right (fixed 3)", "crosshair", "bottom", "top"}--,"stylized 1", "stylized 2", "stylized 3", "stylized 4"},
			},
		},
		{
			key = "TOOLTIP_MELEE_INFO",
			name = "Tooltip show melee info",
			description = "Turn on if 'Show melee info' is enabled in OpenMW engine settings",
			renderer = "checkbox",
			default = boolDefault(legacySection:get("TOOLTIP_MELEE_INFO"), false)
		},
		{
			key = "TOOLTIP_TEXT_ALIGNMENT",
			name = "Tooltip text alignment",
			description = "",
			default = legacySection:get("TOOLTIP_TEXT_ALIGNMENT") or "center", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none", 
				items = {"center", "left", "right"}--,"stylized 1", "stylized 2", "stylized 3", "stylized 4"},
			},
		},
		{
			key = "TOOLTIP_SHORT_TEXT",
			name = "Shorter tooltip texts",
			description = "Shortens effect texts",
			renderer = "checkbox",
			default = boolDefault(legacySection:get("TOOLTIP_SHORT_TEXT"), false)
		},
	},
}

tempKey = "Misc"
settingsTemplate[tempKey] = {
    key = 'SettingsPlayer'..MODNAME..tempKey,
    page = MODNAME,
    l10n = "none",
    name = tempKey,
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "READ_BOOKS",
			name = "Show read books",
			description = "Bookworm will highlight books that you have actually read (for 20 seconds)",
			default = legacySection:get("READ_BOOKS") or "read", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none", 
				items = {"off", "unread", "read", "bookworm", "bookworm unread"}--,"stylized 1", "stylized 2", "stylized 3", "stylized 4"},
			},
		},
		{
			key = "DISPOSE_CORPSE",
			name = "Dispose corpse Key",
			description = "",
			default = legacySection:get("DISPOSE_CORPSE") or "Shift + F", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none", 
				items = {"disabled", "Shift + F", "Jump"}--,"stylized 1", "stylized 2", "stylized 3", "stylized 4"},
			},
		},
		{
			key = "EXPERIMENTAL_LOOTING",
			name = "Experimental looting workaround",
			description = "If you have some ammo mod that keeps deleting your ammo for some reason",
			renderer = "checkbox",
			default = boolDefault(legacySection:get("EXPERIMENTAL_LOOTING"), false)
			
		},
		{
			key = "CAN_LOOT_DURING_DEATH_ANIMATION",
			name = "can loot during death animation",
			description = "It's currently not possible to check the values in the settings.cfg",
			renderer = "checkbox",
			default = boolDefault(legacySection:get("CAN_LOOT_DURING_DEATH_ANIMATION"), false)
		},
		{
			key = "RUN_SCRIPT_ONCE",
			name = "Run MWscripts only once",
			description = "After an mwscript was successfully activated (and the inventory flashed up for a second) don't run the script on this container again",
			renderer = "checkbox",
			default = boolDefault(legacySection:get("RUN_SCRIPT_ONCE"), true)
		},
		{
			key = "R_DEPOSIT2",
			name = "R switches to deposit",
			description = "Instead of opening the inventory, switch between deposit and withdraw with the ToggleSpell key\nShift + R always does the other thing",
			renderer = "select",
			default = "Yes",
			argument = {
				disabled = false,
				l10n = "none", 
				items = {"Yes", "No", "Only when pickpocketing"}
			},
		},
		{
			key = "SELECTIVE_DEPOSIT",
			name = "Shift + Deposit All Mode",
			description = "What to deposit when pressing shift+F in deposit mode\nIt always ignores equipped items",
			default = legacySection:get("SELECTIVE_DEPOSIT") or "ingredients", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none", 
				items = {"ingredients", "restack"},
			},
		},
	},
}

tempKey = "Performance"
settingsTemplate[tempKey] = {
    key = 'SettingsPlayer'..MODNAME..tempKey,
    page = MODNAME,
    l10n = "none",
    name = tempKey,
	permanentStorage = true,
	order = getOrder(),
	settings = {
		{
			key = "PERFORMANCE_MODE",
			name = "Raycast Performance Hit",
			description = "You really don't need to set it to desperate unless you're playing starwind on a gameboy",
			default = "Normal", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none", 
				items = {"Desperate", "Normal"},
			},
		},
	},
}


legacySection:reset()


I.Settings.registerPage {
    key = MODNAME,
    l10n = "none",
    name = "QuickLoot",
    description = "If you're aiming at a container, a preview will appear as soon as you change a setting"
}


for id, template in pairs(settingsTemplate) do
	I.Settings.registerGroup(template)
end

function readAllSettings()
	for _, template in pairs(settingsTemplate) do
		local settingsSection = storage.playerSection(template.key)
		for i, entry in pairs(template.settings) do
			_G[entry.key] = settingsSection:get(entry.key)
		end
	end
end

readAllSettings()

-- ────────────────────────────────────────────────────────────────────────── Settings Event ──────────────────────────────────────────────────────────────────────────

for _, template in pairs(settingsTemplate) do
	local sectionName = template.key
	local settingsSection = storage.playerSection(template.key)
	settingsSection:subscribe(async:callback(function (_,setting)
		local oldValue = _G[setting]
		readAllSettings()
		showInMainMenuOverride = true
		uiLoc = v2(X/100,Y/100)
		uiSize = v2(WIDTH/100,HEIGHT/100)
		closeHud()
		--core.sendGlobalEvent("OwnlysQuickLoot_playerToggledMod",{self,ENABLED})
		updateModEnabled()
		quickLootText = {
			props = {
				textColor = FONT_TINT,--util.color.rgba(1, 1, 1, 1),
				textShadow = true,
				textShadowColor = util.color.rgba(0,0,0,0.75),
				--textAlignV = ui.ALIGNMENT.Center,
				--textAlignH = ui.ALIGNMENT.Center,
			}
		}
		makeBorder = require("scripts.OwnlysQuickLoot.ql_makeborder")
	end))
end