local cfg = require("herbert100.hiss.config")
local log = mwse.Logger.new { includeTimestamp = true }
local common = require("herbert100.hiss.common") ---@type herbert.HISS.Common
local IDS = common.IDS
local MENU_NOTIFY_IDS = common.MENU_NOTIFY_IDS
local FIRST_BUTTON_IDS = common.FIRST_BUTTON_IDS

---@param data herbert.HISS.RegisterMenuButtonParams
local function update_menu_data_params(data)
	if cfg.esc_presses_close_button and not data.close_button then
		for _, button in ipairs(data.numbered_buttons) do
			if button.text == "Close" then
				data.close_button = button
				data.update_close_button_text = false
				break
			end
		end
	end
	if cfg.esc_presses_no_button and not data.close_button then
		for _, button in ipairs(data.numbered_buttons) do
			if button.text == "No" then
				data.close_button = button
				data.update_close_button_text = false
				break
			end
		end
	end
	-- account for config overrides
	if not cfg.update_button_text then
		data.update_close_button_text = false
		data.update_numbered_button_text = false
	end

	-- skip the next main menu open if there is a close button, and the options menu is not open
	data.skip_next_main_menu_open = data.close_button ~= nil and tes3ui.findMenu(IDS.MenuOptions) == nil
	return data
end

--- calls `common.register_key_select_events` on menu messages
---@param menu tes3uiElement?
---@return boolean
local function add_menu_message_buttons(menu)
	if not menu then return false end
	log("trying to add menu message buttons to %q", menu)

	---@type herbert.HISS.RegisterMenuButtonParams
	local data = { root = menu, numbered_buttons = {} }

	-- try to find the appropriate menu items, with increasing levels of desparation

	local contents = menu:getContentElement()
	data.close_button = contents:findChild(IDS.MenuMessage_CancelButton)
	log("close button = %q", data.close_button or "N/A")

	local first_btn = contents:findChild(IDS.MenuMessage_Button) or menu:findChild(IDS.MenuMessage_Button)
	if first_btn then
		log("found first button on first try!")
		data.numbered_buttons = first_btn.parent.children
		common.register_key_select_events(update_menu_data_params(data))
		return true
	end
	log("couldnt find close button on first try. trying again")


	local first_btn_parent = menu:findChild(IDS.MenuMessage_button_layout)
	if first_btn_parent and first_btn_parent.children then
		if cfg.make_top_to_bottom then
			first_btn_parent.flowDirection = tes3.flowDirection.topToBottom
		end
		data.numbered_buttons = first_btn_parent.children
		common.register_key_select_events(update_menu_data_params(data))
		return true
	end

	log("could not find first button on second try. checking manually....")

	---@type tes3uiElement?
	local option_btns_parent
	if data.close_button then
		for _, candidate in ipairs(contents.children) do
			local children = candidate.children

			log("checking candidate %q with num children = %s and children[1].name = %q",
				candidate.name, #children, children[1] and children[1].name
			)
			if #children > 0 and children[1].id == IDS.MenuMessage_Button then
				option_btns_parent = candidate
				break
			end
		end
		if option_btns_parent then
			if cfg.make_top_to_bottom then
				option_btns_parent.flowDirection = tes3.flowDirection.topToBottom
			end
			data.numbered_buttons = option_btns_parent.children
			common.register_key_select_events(update_menu_data_params(data))

			return true
		end
	end

	return false
end
--- Calls `add_menu_msg_btns` whenever `menuEnter` triggers for `MenuMessage`.
--- This is necessary because sometimes `uiActivated` does not trigger but `menuEnter` does.
---@param e menuEnterEventData
local function menu_enter(e)
	log:trace("entered menu %s", e)
	if not common.valid_ids[e.menu.id] then
		log:trace("\tinvalid element %q (id: %s)! returning", e.menu.name, e.menu.id)
		return
	end
	add_menu_message_buttons(e.menu)
end

---@param e uiActivatedEventData
local function ui_activated(e)
	log:trace("ui activated: %s", e)
	if not common.valid_ids[e.element.id] then
		log:trace("\tinvalid element %q (id: %s)! returning", e.element.name, e.element.id)
		return
	end
	log("menu activated! %q", e.element.name)

	local update_layout = false
	---@type herbert.HISS.RegisterMenuButtonParams
	local data = { root = e.element, numbered_buttons = {} }

	local menu = e.element
	local menu_id = menu.id


	-- handle `MenuMessage`
	if menu_id == IDS.MenuMessage then
		add_menu_message_buttons(menu)
		return
	end
	-- handle the various `MenuNotify`s.
	if MENU_NOTIFY_IDS[menu_id] then
		local submenu = menu:findChild(IDS.MenuMessage)
		log("submenu = %q", submenu or "N/A")
		if not add_menu_message_buttons(submenu) then
			-- keep trying every 0.05s until the menu shows up or we give up
			timer.start {
				duration = 0.05,
				iterations = 4,
				type = timer.real,
				callback = function(timer_data)
					if add_menu_message_buttons(tes3ui.findMenu(IDS.MenuMessage))
						or add_menu_message_buttons(tes3ui.getMenuOnTop():getTopLevelMenu():findChild(IDS.MenuMessage))
					then
						log("found menu message element in %s tries", timer_data.timer.iterations)
						timer_data.timer:cancel()
					end
				end,
			}
		end
		return
	end


	if FIRST_BUTTON_IDS[menu_id] then
		local first_button_id = FIRST_BUTTON_IDS[menu_id]

		log("\tmenu has a first_btn_id! its name is %q", FIRST_BUTTON_IDS[menu_id])
		local first_btn = menu:getContentElement():findChild(first_button_id)
		if not first_btn then
			log("\tcouldnt find button via id. trying again via its name")
			first_btn = menu:getContentElement():findChild(first_button_id)
		end
		if not first_btn then
			log("\tcouldnt find first button via name or id. explicitly checking every child.")
			---@param elem tes3uiElement
			for elem in table.traverse(menu.children, "children") do
				log("checking element %q (id = %q)", elem.name, elem.id)
				if elem.id == first_button_id then
					first_btn = elem
					log("found button!!!")
					break
				end
			end
		end
		if first_btn then
			log("found the first button!!!")
			data.numbered_buttons = first_btn.parent.children
		end
	elseif menu_id == IDS.MenuAttributes then
		data.numbered_buttons = (menu:getContentElement().children[2] or {}).children
		data.close_button = menu:findChild("MenuAttributes_Cancelbutton")
	elseif menu_id == IDS.MenuSpecialization then
		data.numbered_buttons = (menu:getContentElement().children[2] or {}).children
		data.close_button = menu:findChild("MenuSpecialization_Cancelbutton")
	elseif menu_id == IDS.MenuStatReview then
		---@type tes3uiElement?
		local bottom = menu:getContentElement().children[2]
		bottom = bottom and bottom:findChild(IDS.MenuStatReview_BackButton) or
			menu:findChild(IDS.MenuStatReview_BackButton)

		if bottom then
			for _, child in ipairs(bottom.parent.children) do
				table.insert(data.numbered_buttons, child)
			end
		end
		local left = menu:getContentElement():findChild(IDS.MenuStatReview_left_main)
		local edit_btns = left and left:findChild(IDS.MenuStatReview_race_layout) ---@type tes3uiElement?
		if edit_btns then
			edit_btns = edit_btns.parent
			for _, child in ipairs(edit_btns.children) do
				table.insert(data.numbered_buttons, child.children[1])
			end
		end
	elseif menu_id == IDS.MenuContents then
		local contents = menu:getContentElement()
		local takeall_button = contents:findChild(IDS.MenuContents_takeallbutton)
		if takeall_button then
			data.numbered_buttons = {
				takeall_button,
				takeall_button.parent:findChild(IDS.MenuContents_closebutton),
			}
		end
		local uiexp_filter_block = contents:findChild(IDS["UIEXP:ContentsMenu:FilterBlock"])
		if uiexp_filter_block then
			local weapon_filter = uiexp_filter_block:findChild(IDS["UIEXP:FilterButton:weapon"])
			if weapon_filter then
				weapon_filter.parent.autoWidth = true
				weapon_filter.parent.widthProportional = 1.0
				for _, child in ipairs(weapon_filter.parent.children) do
					table.insert(data.numbered_buttons, child)
				end
			end
		end
	elseif menu_id == IDS.MenuScroll then
		local contents = menu:getContentElement()
		data.numbered_buttons = {
			contents:findChild(IDS.MenuBook_PickupButton), -- yes, this is the correct id for scrolls.
			contents:findChild(IDS.MenuScroll_Close),
		}
		-- hardcoded because the "text" prompt is actually a picture
		if cfg.esc_presses_close_button then
			data.close_button = data.numbered_buttons[2]
			data.update_close_button_text = false
		end
	elseif menu_id == IDS.MenuBook then
		local contents = menu:getContentElement()
		data.numbered_buttons = {
			contents:findChild(IDS.MenuBook_button_take), -- yes, this is the correct id for books.
			contents:findChild(IDS.MenuBook_button_close),
			contents:findChild(IDS.MenuBook_button_prev),
			contents:findChild(IDS.MenuBook_button_next),
		}
		-- hardcoded because the "text" prompt is actually a picture
		if cfg.esc_presses_close_button then
			data.close_button = data.numbered_buttons[2]
			data.update_close_button_text = false
		end
	elseif menu_id == IDS.MenuLoad then
		local contents = menu:getContentElement()
		data.close_button = contents:findChild(IDS.MenuLoad_Okbutton)
		log("set close button to %s", data.close_button)
		if not data.close_button then
			data.close_button = contents.children[3] and contents.children[3].children[1]
			log("set close button to %s", data.close_button)
		end
	elseif menu_id == IDS.MenuSave then
		local contents = menu:getContentElement()
		data.close_button = contents:findChild(IDS.MenuSave_Cancelbutton)
	elseif menu_id == IDS.MenuMagicSelect then
		local contents = menu:getContentElement()
		data.close_button = contents:findChild(IDS.MenuMagicSelect_button_cancel)
	elseif menu_id == IDS.MenuInventorySelect then
		local contents = menu:getContentElement()
		data.close_button = contents:findChild(IDS.MenuInventorySelect_button_cancel)
	elseif common.PREFS_IDS[menu_id] then
		local contents = menu:getContentElement()
		local header_block = contents.children[1]
		header_block.autoWidth = true
		header_block.widthProportional = 1
		menu.autoWidth = true
		if header_block then
			update_layout = true
			data.numbered_buttons = header_block.children
		end
		if menu_id == IDS.MenuPrefs then
			data.close_button = contents:findChild(IDS.MenuPrefs_Okbutton)
			log:trace("set menu prefs close button to %s", data.close_button)
			if not data.close_button then
				log:trace("setting menu prefs close button manually", data.close_button)
				local elem = contents.children[#contents.children].children[4]
				data.close_button = elem and elem.children
			end
		else
			data.close_button = contents.children[#contents.children].children[1]
		end
	end
	if data.numbered_buttons then
		common.register_key_select_events(update_menu_data_params(data))
		if update_layout then
			menu:updateLayout()
		end
	end
end




local function initialized()
	-- this event is needed because sometiems `uiActivated` doesnt trigger
	-- this might happen when the menu gets opened while the game is paused
	common.register_event(tes3.event.menuEnter, menu_enter, { filter = "MenuMessage" })
	common.register_event(tes3.event.uiActivated, ui_activated)
	common.register_event(tes3.event.modConfigEntryClosed, common.update_valid_ids, { filter = log.modName })
	log:writeInitMessage()
end

if cfg.livecoding and tes3.isInitialized() then
	log("initializing!")
	initialized()
end

common.register_event(tes3.event.initialized, initialized)
