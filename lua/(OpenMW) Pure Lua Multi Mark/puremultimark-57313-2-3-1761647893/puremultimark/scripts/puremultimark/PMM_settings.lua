local I = require('openmw.interfaces')

settings = {
    key = 'Settings'..MODNAME,
    page = MODNAME,
    l10n = "none",
    name = MODNAME,
	description = "",
    permanentStorage = true,
    settings = {
		{
			key = "MARKS_BASELINE",
			name = "Base amount of marks",
			description = "the menu won't show up if you only have 1 mark",
			renderer = "number",
			default = 1,
			argument = {
				min = -1000,
				max = 100000,
			},
		},
		{
			key = "SKILL_STEP",
			name = "Skill Rating per extra mark",
			description = "mysticism + 0.2*int",
			renderer = "number",
			default = 20,
			argument = {
				min = 1,
				max = 100000,
			},
		},
		{
			key = "FONT_SIZE",
			name = "Font Size",
			description = "",
			renderer = "number",
			default = 23,
			argument = {
				min = 1,
				max = 100000,
			},
		},
		{
			key = "WIDTH_MULT",
			name = "Window Width Mult",
			description = "",
			renderer = "number",
			default = 1,
			argument = {
				min = 1,
				max = 100000,
			},
		},
		{
			key = "LINE_HEIGHT",
			name = "Line Height",
			description = "",
			renderer = "number",
			default = 0.9,
			argument = {
				min = 0.1,
				max = 1,
			},
		},
		{
			key = "QSC_FIX",
			name = "Quick Spell Casting Fix",
			description = "If the x button (to cancel) freezes your character, this workaround is for you",
			renderer = "checkbox",
			default = true
		},
		{
			key = "SORT_DIRECTION",
			name = "Sort Direction",
			description = "Sort values by moving them up or down?",
			default = "Up", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none", 
				items = {"Up", "Down"}
			},
		},
		{
			key = "RENAME_ICON",
			name = "Rename icon",
			description = "",
			default = "Pen+Paper", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none", 
				items = {"Paragraph", "Quill_1", "Quill_2", "Pen", "Pen+Paper"}
			},
		},
		{
			key = "TEXT_ALIGNMENT",
			name = "Text Alignment",
			description = "",
			default = "Center", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none", 
				items = {"Start", "Center", "End"}
			},
		},
		{
			key = "LIST_ENTRIES",
			name = "List entries",
			description = "",
			renderer = "number",
			default = 15,
			argument = {
				min = 3,
				max = 100000,
			},
		},
		{
			key = "CONTROLLER_MODE",
			name = "Controller Mode",
			description = "Prevents windows coming up when recalling",
			renderer = "checkbox",
			default = false,
		},
	}
}

local updateSettings = function (_,setting)
	LIST_ENTRIES = playerSection:get("LIST_ENTRIES")
	if setting == "QSC_FIX" then return end
	if renameDialog then --prevents this getting called before the rest is initialized
		local layerId = ui.layers.indexOf("HUD")
		local screenSize = ui.layers[layerId].size
		windowPos = v2(-screenSize.x/3,0)
		DEMO_MODE = true
		if #saveData.locations == 0 then
			saveData.locations[1] = {name = "DEMO LOCATION"}
			saveData.locations[2] = {name = "DEMO LOCATION 2"}
			saveData.locations[3] = {name = "DEMO LOCATION 3"}
			saveData.locations[4] = {name = "DEMO LOCATION 4"}
			require("scripts.puremultimark.PMM_markWindow")
			saveData.locations[1] = nil
			saveData.locations[2] = nil
			saveData.locations[3] = nil
			saveData.locations[4] = nil
		else
			require("scripts.puremultimark.PMM_markWindow")
		end
	end
end
playerSection:subscribe(async:callback(updateSettings))


I.Settings.registerGroup(settings)

I.Settings.registerPage {
    key = MODNAME,
    l10n = "none",
    name = MODNAME,
    description = ""
}