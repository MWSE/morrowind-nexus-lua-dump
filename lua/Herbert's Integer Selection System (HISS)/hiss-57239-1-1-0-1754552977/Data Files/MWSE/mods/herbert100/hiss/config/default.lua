local has_ui_expansion = tes3.isLuaModActive("UI Expansion")
---@class herbert.HISS.Config
local default = {
	log_level = mwse.logLevel.info,
	update_button_text = true,
	livecoding = false,
	make_top_to_bottom = false,
	esc_presses_no_button = false,
	esc_presses_close_button = false,
	--- Stores a set containing the names of all menus that the mod should be enabled for.
	--- This should not be used directly.
	--- Instead, use `common.valid_ids`, which stores the actual menu IDs that are valid.
	--- `common.valid_ids` gets updated every time the config is saved.
	valid_menu_names = {
		MenuMessage = true,
		MenuNotify1 = true,
		MenuNotify2 = true,
		MenuNotify3 = true,
		MenuClassChoice = true,
		MenuChooseClass = true,
		MenuBirthSign = true,
		MenuStatReview = true,
		MenuClassMessage = true,
		MenuRaceSex = true,
		perksMenu = true,
		MenuAttributes = true,
		MenuSpecialization = true,

		-- added in 1.1
		MenuLoad = true,
		MenuSave = true,
		MenuPrefs = true,
		MenuAudio = true,
		MenuCtrls = true,
		MenuVideo = true,

		MenuMagicSelect = true,
		MenuInventorySelect = true,

		MenuScroll = false,
		MenuBook = false,
		MenuContents = not has_ui_expansion,


	}
}

return default
