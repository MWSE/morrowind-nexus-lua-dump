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

settings = {
    key = 'SettingsPlayer'..MODNAME,
    page = MODNAME,
    l10n = "QuickLoot",
    name = "QuickLoot",
	description = "",
    permanentStorage = true,
    settings = {
		{
			key = "ENABLED",
			name = "Enabled",
			description = "Allows disabling the mod entirely",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "CONTAINER_ANIMATION",
			name = "Container Animation",
			description = "For 'Animated Containers' \nCan make looting stuff on top of containers more difficult\nIf it doesn't work, your OpenMW version might not be recent enough",
			default = "immediately", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"off", "immediately", "on take", "disabled by shift"},
			},
		},
		{
			key = "WIDTH",
			name = "Width (%)",
			description = "of the ui element (1-100)",
			renderer = "number",
			default = 20,
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
			default = 30,
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
			default = 71,
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
			default = 50,
			argument = {
				min = 1,
				max = 100,
			},
		},
		{
			key = "textSizeMult",
			name = "textSizeMult (%)",
			description = "1-200",
			renderer = "number",
			default = 75,
			argument = {
				min = 1,
				max = 200,
			},
		},
		{
			key = "HEADER_FOOTER",
			name = "List Header/Footer",
			description = "Show list header/footer",
			default = "show both", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"hide both", "show both", "all top", "all bottom", "only top", "only bottom"},
			},
		},
		{
			key = "FOOTER_HINTS",
			name = "Keybinding Hints",
			description = "shows the keybinding hints for 'Take All' and 'Search'",
			default = "Symbolic", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"Disabled", "Symbolic", "F / R"},
			},
		},
		{
			key = "CONTAINER_SORTING_STATS",
			name = "Item Sorting by Value / Weight",
			description = "Changes the order of icons in containers",
			default = "Best V/W", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"Vanilla", "Lowest Weight", "Highest Value", "Best V/W"},
			},
		},
		{
			key = "CONTAINER_SORTING_QUEST",
			name = "Sorting: Quest Items On Top",
			description = "Let me know if you find any that got falsely flagged as quest",
			renderer = "checkbox",
			default = true
		},
		{
			key = "CONTAINER_SORTING_CASH",
			name = "Sorting: Cash On Top",
			description = "",
			renderer = "checkbox",
			default = true
		},
		{
			key = "CONTAINER_SORTING_KEYS",
			name = "Sorting: Keys On Top",
			description = "",
			renderer = "checkbox",
			default = true
		},
		{
			key = "CONTAINER_SORTING_LOCKPICKS",
			name = "Sorting: Lockpicks On Top",
			description = "",
			renderer = "checkbox",
			default = true
		},
		{
			key = "CONTAINER_SORTING_SOULGEMS",
			name = "Sorting: Soulgems On Top",
			description = "",
			renderer = "checkbox",
			default = true
		},
		{
			key = "CONTAINER_SORTING_INGREDIENTS",
			name = "Sorting: Ingredients Below [x] Weight On Top",
			description = "0 = Disable",
			renderer = "number",
			default = 1.5,
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
			default = true
		},
		
		{
			key = "COLUMN_PICKPOCKET",
			name = "Show Pickpocket Column",
			description = "",
			renderer = "checkbox",
			default = true
		},
		{
			key = "COLUMN_WEIGHT",
			name = "Show Weight Column",
			description = "",
			renderer = "checkbox",
			default = true
		},
		{
			key = "COLUMN_WEIGHT_PICKPOCKETING",
			name = "Show Weight Column When Pickpocketing",
			description = "",
			renderer = "checkbox",
			default = true
		},
		{
			key = "COLUMN_VALUE",
			name = "Show Value Column",
			description = "",
			renderer = "checkbox",
			default = true
		},
		{
			key = "COLUMN_VALUE_PICKPOCKETING",
			name = "Show Value Column When Pickpocketing",
			description = "",
			renderer = "checkbox",
			default = true
		},
		{
			key = "COLUMN_WV",
			name = "Show V/W Column",
			description = "",
			renderer = "checkbox",
			default = true
		},
		{
			key = "COLUMN_WV_PICKPOCKETING",
			name = "Show V/W Column When Pickpocketing",
			description = "",
			renderer = "checkbox",
			default = false
		},
		{
			key = "BORDER_STYLE",
			name = "Border style",
			description = "",
			default = "thin", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"none", "thin", "normal", "thick", "verythick"}--,"stylized 1", "stylized 2", "stylized 3", "stylized 4"},
			},
		},
		{
			key = "READ_BOOKS",
			name = "Show read books",
			description = "bookworm will highlight books that you have actually read (for 20 seconds)",
			default = "read", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"off", "unread", "read", "bookworm", "bookworm unread"}--,"stylized 1", "stylized 2", "stylized 3", "stylized 4"},
			},
		},
		{
			key = "FONT_TINT",
			name = "Font Color",
			description = "",
			disabled = false,
			default = getColorFromGameSettings("FontColor_color_normal"), --green
			renderer = "color",
		},
		{
			key = "ICON_TINT",
			name = "Icon Tint",
			description = "",
			disabled = false,
			default = getColorFromGameSettings("FontColor_color_normal_over"), --green
			renderer = "color",
		},
		{
			key = "FONT_FIX",
			name = "Fix buggy font",
			description = "If you see boxes or questionmarks where there should be numbers, enable this setting to disable reliance on the included font",
			renderer = "checkbox",
			default = true
		},
		{
			key = "HAND_SYMBOL",
			name = "Stealing Hand Symbol",
			description = "Enable the pink hand next to the red text when the container belongs to someone",
			renderer = "checkbox",
			default = true
		},
		{
			key = "TOOLTIP_MODE",
			name = "Tooltip position",
			description = "doesn't work with the font fix below",
			default = "left", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"off", "left","left (fixed)", "left (fixed 2)", "left (fixed 3)", "right", "right (fixed)", "right (fixed 2)", "right (fixed 3)", "crosshair", "bottom", "top"}--,"stylized 1", "stylized 2", "stylized 3", "stylized 4"},
			},
		},
		{
			key = "TOOLTIP_MELEE_INFO",
			name = "tooltip show melee info",
			description = "'show melee info' enabled in engine OpenMW settings",
			renderer = "checkbox",
			default = false
		},
		{
			key = "TOOLTIP_TEXT_ALIGNMENT",
			name = "Tooltip text alignment",
			description = "",
			default = "center", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"center", "left", "right"}--,"stylized 1", "stylized 2", "stylized 3", "stylized 4"},
			},
		},
		{
			key = "TOOLTIP_SHORT_TEXT",
			name = "shorter tooltip texts",
			description = "shortens effect texts",
			renderer = "checkbox",
			default = false
		},
		{
			key = "DISPOSE_CORPSE",
			name = "Dispose corpse Key",
			description = "",
			default = "Shift + F", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"disabled", "Shift + F", "Jump"}--,"stylized 1", "stylized 2", "stylized 3", "stylized 4"},
			},
		},
		{
			key = "TRANSPARENCY",
			name = "Transparency",
			description = "",
			renderer = "number",
			default = 0.4,
			argument = {
				min = 0,
				max = 1,
			},
		},
		{
			key = "PICKPOCKETING",
			name = "Enable Pickpocketing",
			description = "",
			renderer = "checkbox",
			default = true
		},
		{
			key = "EXPERIMENTAL_LOOTING",
			name = "Experimental looting workaround",
			description = "If you have some ammo mod that keeps deleting your ammo for some reason",
			renderer = "checkbox",
			default = false
			
		},
		{
			key = "CAN_LOOT_DURING_DEATH_ANIMATION",
			name = "can loot during death animation",
			description = "it's currently not possible to check the values in the settings.cfg",
			renderer = "checkbox",
			default = false
		},
		{
			key = "RUN_SCRIPT_ONCE",
			name = "Run MWscripts only once",
			description = "after an mwscript was successfully activated (and the inventory flashed up for a second) don't run the script on this container again",
			renderer = "checkbox",
			default = true
		},
		
		{
			key = "R_DEPOSIT",
			name = "R switches to deposit",
			description = "switch between deposit and withdraw with the ToggleSpell key\nWith 'Deposit All' it ignores equipped items. when using the 'Dispose corpse' mode, it only stacks items that the container has too.",
			renderer = "checkbox",
			default = true
		},
		
	}
}




local function updateSettings()
	showInMainMenuOverride = true
	uiLoc = v2(playerSection:get("X")/100,playerSection:get("Y")/100)
	uiSize = v2(playerSection:get("WIDTH")/100,playerSection:get("HEIGHT")/100)
	closeHud()
	--core.sendGlobalEvent("OwnlysQuickLoot_playerToggledMod",{self,playerSection:get("ENABLED")})
	updateModEnabled()
	quickLootText = {
	props = {
			textColor = playerSection:get("FONT_TINT"),--util.color.rgba(1, 1, 1, 1),
			textShadow = true,
			textShadowColor = util.color.rgba(0,0,0,0.75),
			--textAlignV = ui.ALIGNMENT.Center,
			--textAlignH = ui.ALIGNMENT.Center,
	}
}
	--calculateBarPositions()
	--if container then
	--	container:destroy()
	--end
	--container = nil
	----makeUI()
end


I.Settings.registerGroup(settings)


I.Settings.registerPage {
    key = MODNAME,
    l10n = "QuickLoot",
    name = "QuickLoot",
    description = "If you're aiming at a container, a preview will appear as soon as you change a setting"
}


playerSection:subscribe(async:callback(updateSettings))
return true