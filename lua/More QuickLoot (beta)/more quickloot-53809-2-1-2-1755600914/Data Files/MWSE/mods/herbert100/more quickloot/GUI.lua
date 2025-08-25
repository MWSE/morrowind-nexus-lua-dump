local log = mwse.Logger.new()

local common = require('herbert100.more quickloot.common')

local register_event = common.register_event

local defns = require("herbert100.more quickloot.defns")
local fmt = string.format
-- only care about the UI part of the config
local UI_cfg = require("herbert100.more quickloot.config").UI
local cfg = require("herbert100.more quickloot.config")


log("reloaded GUI")

---@type {[string]: number[]}
local COLORS = {}

---@enum herbert.MQL.GUI.uid
local uids = {
	base = tes3ui.registerID "MQL:Menu",
	columns_container = tes3ui.registerID "MQL:columns_cont",
	columns_blk = tes3ui.registerID "MQL:columns_blk",

	icons_col = tes3ui.registerID "MQL:icons_col",
	names_col = tes3ui.registerID "MQL:names_col",
	weights_col = tes3ui.registerID "MQL:weights_col",
	values_col = tes3ui.registerID "MQL:values_col",
	icons_col_outer = tes3ui.registerID "MQL:icons_col_outer",
	names_col_outer = tes3ui.registerID "MQL:names_col_outer",
	weights_col_outer = tes3ui.registerID "MQL:weights_col_outer",
	values_col_outer = tes3ui.registerID "MQL:values_col_outer",

	title_blk = tes3ui.registerID "MQL:title_blk",
	subtitle_blk = tes3ui.registerID "MQL:subtitle_blk",
	actions_cont = tes3ui.registerID "MQL:actions_cont",
	actions_blk = tes3ui.registerID "MQL:actions_blk",
	-- m_actions_blk = tes3ui.registerID "MQL:m_actions_blk",
	status_blk = tes3ui.registerID "MQL:status_blk",
}

--- registers the UIIDs
register_event("initialized", function()
	COLORS = {
		unavailable = tes3ui.getPalette(tes3.palette.journalFinishedQuestOverColor),
		unavailable_selected = tes3ui.getPalette(tes3.palette.activeOverColor),

		ok = tes3ui.getPalette(tes3.palette.bigNormalColor),
		ok_selected = tes3ui.getPalette(tes3.palette.activeColor),

		-- stat = tes3ui.getPalette(tes3.palette.disabledColor),

		controls = tes3ui.getPalette(tes3.palette.disabledColor),
		-- controls = {0.5, 0.5, 0.2},

		status = tes3ui.getPalette(tes3.palette.notifyColor),
		title = tes3ui.getPalette(tes3.palette.headerColor),
		empty = tes3ui.getPalette(tes3.palette.healthColor),
		white = tes3ui.getPalette(tes3.palette.whiteColor),
	}
end, { doOnce = true })

local TINY_ICON_SIZE = 16
-- local ICON_SIZE = 35
local ICON_SIZE = 40
local ROW_SEP = 5

-- minimum spacing between control labels
local CONTROL_LABELS_MIN_SEP = 30

-- minimum spacing between modified control labels
local M_ACTION_LABELS_MIN_SEP = 60

-- spacing used by the message block (that holds red text)
local MESSAGE_BLK_BORDER_ALL_SIDES = 10


-- spacing between the header of a column and the actual items in that column
local HEADER_BORDER_BOTTOM = 15

-- -@class herbert.MQL.GUI.status_text_params
-- -@field text string? the text to show
-- -@field justify tes3.justifyText? any `justifyText` parameters
-- -@field wrap boolean? should the text be wrapped?








-- =============================================================================
-- GUI
-- =============================================================================


--- Internal function that makes a column in the UI
---@protected
---@param self herbert.MQL.GUI
---@param columns_blk tes3uiElement
---@param icon_path string? The icon path to use in the header of this column.
---@param actual_dots boolean Should dots be printed in the dot block? If false, then the dots text will be empty.
---@param uid_inner herbert.MQL.GUI.uid? The UID of the inner column.
---@param uid_outer herbert.MQL.GUI.uid? The UID of the outer column.
---@return tes3uiElement
local function make_column(self, columns_blk, icon_path, actual_dots, uid_inner, uid_outer)
	local col_container = columns_blk:createBlock { id = uid_outer }
	col_container.flowDirection = tes3.flowDirection.topToBottom
	col_container.heightProportional = 1
	col_container.childAlignX = 0.5
	col_container.childAlignY = 0.5
	col_container.autoWidth = true
	col_container.autoHeight = true
	col_container.borderRight = 20

	---@type tes3uiElement
	local header -- handle the case when there's no icon path, or the icon file doesn't exist
	if icon_path then
		local status, elem = pcall(tes3uiElement.createImage, col_container, { path = icon_path })
		if status then header = elem end
	end
	header = header or col_container:createLabel { text = "" }
	header.borderBottom = HEADER_BORDER_BOTTOM
	header.width = TINY_ICON_SIZE
	header.height = TINY_ICON_SIZE

	local first_dots = col_container:createLabel { text = "" }
	first_dots.borderBottom = 20
	first_dots.visible = false
	table.insert(self.first_dots_labels, first_dots)



	local col_blk = col_container:createBlock { id = uid_inner }
	col_blk.heightProportional = 1
	col_blk.widthProportional = 1
	col_blk.autoWidth = true
	col_blk.autoHeight = true
	col_blk.flowDirection = tes3.flowDirection.topToBottom

	col_blk.childAlignX = 0.5
	col_blk.childAlignY = 0.5

	local last_dots = col_container:createLabel { text = "" }
	last_dots.visible = false
	table.insert(self.last_dots_labels, last_dots)


	return col_blk
end





--[[##GUI
roughly speaking, the GUI should have no idea what's going on.
it should only do as it's told. i.e., its behavior should be completely determined by a `Container`.
A `Container` is always responsible for:
1) setting the name label
2) specifying the control labels
3) saying which items can be displayed
4) determining what happens when the player tries to take items/talk to the container
5) saying when things should be removed from a container.

The `GUI` is only responsible for:
1) keeping track of what item is currently selected.
2) Displaying things to the player, based on what the container says should be displayed.
]]
---@class herbert.MQL.GUI : herbert.Class
---@field name string
---@field container herbert.MQL.Container|nil
---@field ui_index integer the index of the selected item
---@field actions_blk tes3uiElement the block on the bottom that will hold the controls
-- -@field m_actions_blk tes3uiElement the block on the bottom that will hold the controls
---@field visible_indices integer[]
---
--- E.g., icon path, name, value, weight. The parent of each element will also hodl the label of the column,
-- and the "dot labels" that appear for each column
---@field columns_blk tes3uiElement holds all the columns
---@field container_contents_blk tes3uiElement holds all the columns
---@field message_blk tes3uiElement place where blocked messages get shown
---@field ui_base tes3uiElement the panel that all UI elements live inside of
---@field first_dots_labels tes3uiElement[] the "..." label that may appear at the beginning of a list. There's one for each column.
---@field last_dots_labels tes3uiElement[] the "..." label that may appear at the end of a list. There's one for each column.
---@field blocked boolean `true` if the UI is not showing the items of a container and instead showing some other message. (e.g., it's showing "Empty")
---@field status_blk tes3uiElement? the status bar, if it exists
---@field status_label tes3uiElement? the status label, if it exists
---
---@field icons_col tes3uiElement
---@field names_col tes3uiElement
---@field values_col tes3uiElement
---@field weights_col tes3uiElement
---@field title tes3uiElement
---@field subtitle_blk tes3uiElement
local GUI = {}

local meta = { __index = GUI }


local KEY_NAMES = {}



local function update_key_names()
	for keycode, action_index in pairs(common.keymap) do
		if keycode == tes3.scanCode.space then
			KEY_NAMES[action_index] = "SPC"
		else
			KEY_NAMES[action_index] = tes3.getKeyName(keycode)
		end
	end
	for mouse_button, action_index in pairs(common.mousemap) do
		KEY_NAMES[action_index] = "M" .. mouse_button
	end
end

register_event(tes3.event.menuEnter, update_key_names, { priority = cfg.advanced.menu_entered_priority })
register_event(tes3.event.loaded, update_key_names)

--- make a new one
---@return herbert.MQL.GUI
function GUI.new()
	local self = setmetatable({
		visible_indices = {},
	}, meta)

	-- now make the UI
	log("about to create base_UI.")
	-- items = items
	local root = tes3ui.createMenu { id = uids.base, fixedFrame = true }
	-- root:destroyChildren()
	self.ui_base = root
	-- self.ui_base = tes3ui.createMenu({id = UIIDs.base, })
	root.absolutePosAlignX = UI_cfg.menu_x_pos
	root.absolutePosAlignY = UI_cfg.menu_y_pos
	root.childAlignX = 0.5
	root.childAlignY = 0.5
	root.autoWidth = true
	root.autoHeight = true
	root.minWidth = 200
	root.minHeight = 200

	root.flowDirection = tes3.flowDirection.topToBottom

	root:register(tes3.uiEvent.destroy, function(e)
		if self.container then
			self.container:destruct()
		end
		self.ui_base = nil
		event.trigger(defns.EVENT_IDS.gui_destroyed, { gui = self }, {})
		log('fired gui destroyed event')
		e.source:forwardEvent(e)
	end)

	local main_blk = root:createBlock()
	main_blk.childAlignX = 0.5
	main_blk.childAlignY = 0.5
	main_blk.autoWidth = true
	main_blk.autoHeight = true
	main_blk.heightProportional = 1
	main_blk.widthProportional = 1
	main_blk.flowDirection = tes3.flowDirection.topToBottom
	main_blk.paddingAllSides = 3



	do -- make title block
		local title_blk = main_blk:createBlock { id = uids.title_blk }
		title_blk.flowDirection = tes3.flowDirection.topToBottom
		title_blk.widthProportional = 1
		title_blk.autoWidth = true
		title_blk.autoHeight = true
		title_blk.childAlignX = 0.5

		self.title = title_blk:createLabel { text = " " }
		self.title.color = COLORS.title

		local subtitle_blk = title_blk:createBlock { id = uids.subtitle_blk }
		subtitle_blk.borderTop = 5
		subtitle_blk.borderBottom = 5
		self.subtitle_blk = subtitle_blk
		subtitle_blk.flowDirection = tes3.flowDirection.topToBottom
		subtitle_blk.widthProportional = 1
		subtitle_blk.autoWidth = true
		subtitle_blk.autoHeight = true
		subtitle_blk.childAlignX = 0.5

		title_blk:createDivider()

		self:update_title_blk()
	end

	do -- make columns
		local container_contents_blk = main_blk:createBlock { id = uids.columns_container }
		self.container_contents_blk = container_contents_blk
		container_contents_blk.flowDirection = tes3.flowDirection.topToBottom
		if UI_cfg.columns_layout ~= 2 then
			container_contents_blk.widthProportional = 1 -- disabling this will center the component
		end
		container_contents_blk.autoWidth = true
		container_contents_blk.autoHeight = true
		container_contents_blk.borderAllSides = 10
		container_contents_blk.childAlignX = 0.5 -- TESTING
		container_contents_blk.borderTop = 0

		local columns_blk = container_contents_blk:createBlock { id = uids.columns_blk }
		columns_blk.autoWidth = true
		-- columns_blk.widthProportional = 1 -- TESTING
		columns_blk.autoHeight = true
		columns_blk.flowDirection = tes3.flowDirection.leftToRight
		columns_blk.heightProportional = 1.0

		self.first_dots_labels = {}
		self.last_dots_labels = {}


		self.icons_col = make_column(self, columns_blk, nil, false, uids.icons_col, uids.icons_col_outer)
		-- .parent.childOffsetY = ICON_SIZE / 4
		self.icons_col.parent.childOffsetY = (ICON_SIZE - 18) / 2

		self.names_col = make_column(self, columns_blk, nil, true, uids.names_col, uids.names_col_outer)
		self.names_col.childAlignX = 0.0
		self.first_dots_labels[2].text = ". . ."
		self.first_dots_labels[2].color = COLORS.white
		self.last_dots_labels[2].text = ". . ."
		self.last_dots_labels[2].color = COLORS.white

		-- values column
		self.values_col = make_column(self, columns_blk, "icons/gold.tga", false, uids.values_col, uids.values_col_outer)
		self.weights_col = make_column(self, columns_blk, "icons/weight.tga", false, uids.weights_col,
			uids.weights_col_outer)
	end

	local message_blk = main_blk:createBlock()
	self.message_blk = message_blk
	message_blk.borderAllSides = 10
	message_blk.flowDirection = tes3.flowDirection.topToBottom
	message_blk.widthProportional = 1
	message_blk.childAlignX = 0.5
	message_blk.autoHeight = true
	message_blk.autoWidth = true
	message_blk.visible = false

	do -- make status block
		local status_blk = main_blk:createBlock { id = uids.status_blk }

		self.status_blk = status_blk
		status_blk.widthProportional = 1
		status_blk.childAlignX = 0.5
		status_blk.autoHeight = true
		status_blk.autoWidth = true
		status_blk.borderBottom = 10
		status_blk.childAlignY = 0.5

		status_blk.flowDirection = tes3.flowDirection.topToBottom

		local divier = status_blk:createDivider()
		divier.borderBottom = 10

		local status_label = status_blk:createLabel({ text = "" })
		self.status_label = status_label
		status_label.color = COLORS.status
		-- status_label.wrapText = true
		status_label.borderTop = 5
		if not UI_cfg.enable_status_bar then
			-- status_label.visible = false
			status_blk.visible = false
		end
	end

	do -- make action labels block
		local actions_cont = main_blk:createBlock { id = uids.actions_cont }
		-- controls_container.borderBottom = 20
		actions_cont.widthProportional = 1
		actions_cont.autoHeight = true
		actions_cont.autoWidth = true
		actions_cont.flowDirection = tes3.flowDirection.topToBottom


		actions_cont:createDivider()


		local actions_blk = actions_cont:createBlock { id = uids.actions_blk }
		self.actions_blk = actions_blk
		-- controls_blk.borderBottom = 20
		actions_blk.widthProportional = 1
		actions_blk.autoHeight = true
		actions_blk.autoWidth = true
		actions_blk.childAlignX = 0.5
		actions_blk.flowDirection = tes3.flowDirection.leftToRight

		actions_blk.visible = UI_cfg.show_controls

		for i = 1, 3 do
			local lbl = actions_blk:createLabel { text = "" }
			lbl.absolutePosAlignX = (i - 1) / 2
			lbl.color = COLORS.controls
			lbl.alpha = 0.9
		end
	end

	self.ui_base:updateLayout()
	self:make_items_skeleton()

	return self
end

function GUI:kill_container()
	local container = self.container
	if container then
		container:destruct()
		self.container = nil
		self.visible_indices = {}
		self.ui_index = 1
		-- self:recompute_visible_items(-1)
	end
end

---@param container herbert.MQL.Container
function GUI:set_container(container)
	self:kill_container()
	self.container = container
	self.visible_indices = {}
	self.ui_index = 1
end

-- =============================================================================
-- INTERNAL METHODS THAT UPDATE THE UI
-- =============================================================================

---@protected
-- You may want to update the UI after using this.
function GUI:show_contents()
	self.container_contents_blk.visible = true
	self.message_blk.visible = false
end

---@return herbert.MQL.Item? item
function GUI:get_selected_item()
	return self.container.items[self.visible_indices[self.ui_index]]
end

--- This method recomputes the list of visible items.
--- It does not make any changes to the UI.
---@protected
---@param start_index integer|nil The newly selected index. Must be a valid index. This refers to an item, not a visible index
function GUI:recompute_visible_indices(start_index)
	log:trace("remaking visible indices...")

	local num_to_show = #self.icons_col.children

	--- This is an item index that's close to `start_index` and is guaranteed
	--- to point to an item that's being displayed.
	--- If `items[start_index]` can be displayed, then `valid_start_idx == start_index`
	---@type integer
	local valid_start_idx

	start_index = start_index or self.visible_indices[self.ui_index] or 1

	---@type integer[]
	local visible_indices = {}

	self.visible_indices = visible_indices

	local container = self.container

	if container == nil then
		log:error("tried to recompute visible items when container was nil!")
		return
	end
	local items = container.items

	if #items == 0 then
		return
	end

	local num_to_show_before = math.floor(0.5 * (num_to_show - 1))

	local tbl_insert = table.insert

	local prev_index = start_index - 1

	while prev_index >= 1 and #visible_indices < num_to_show_before do
		if container:can_take_item(items[prev_index]) ~= -1 then
			tbl_insert(visible_indices, prev_index)
		end
		prev_index = prev_index - 1
	end

	log:trace("\tadded indices before item: %s", visible_indices)

	-- make sure the start index is a valid item
	if items[start_index] and container:can_take_item(items[start_index]) ~= -1 then
		tbl_insert(visible_indices, start_index)
		-- update the valid start index
		valid_start_idx = start_index
	end

	local next_index = start_index + 1
	local num_items = #items

	while next_index <= num_items and #visible_indices < num_to_show do
		if container:can_take_item(items[next_index]) ~= -1 then
			tbl_insert(visible_indices, next_index)
		end
		next_index = next_index + 1
	end

	log:trace("\tadded indices after item: %s", visible_indices)
	log:trace("\tgoing back and seeing if we missed any indices before the current index....")

	while prev_index >= 1 and #visible_indices < num_to_show do
		if container:can_take_item(items[prev_index]) ~= -1 then
			tbl_insert(visible_indices, prev_index)
		end
		prev_index = prev_index - 1
	end

	-- Make `valid_start_idx` point to the index of the first visible item or just make it the number 1
	-- Note that by construction, `visible_indices[1]` will either be:
	-- a) The first index that's less than `start_index` and points to a visible item.
	-- b) The first index that's bigger than `start_index` and points to a visible item.
	if valid_start_idx == nil then
		valid_start_idx = visible_indices[1] or 1
	end

	-- Sort the indices.
	-- This is necessary because we added `prev_index` in reverse order lots of times,
	-- and then possibly added `prev_index` again after adding `next_index`.
	table.sort(visible_indices)

	do -- update the UI index
		local ui_index = 1
		-- Set the ui_index to be the closest thing to `valid_start_idx`
		while visible_indices[ui_index + 1] and visible_indices[ui_index + 1] <= valid_start_idx do
			ui_index = ui_index + 1
		end
		self.ui_index = ui_index
	end

	-- log:trace("toggling first dots visibility. visible? %s", not reached_start)
	-- prev_index will be one lower than the smallest index of all the visible items
	-- so if prev_index == 1, then the first item is not visible.
	-- A similar thing is true for the last dots labels.
	for i = 1, 4 do
		self.first_dots_labels[i].visible = prev_index >= 1
		self.last_dots_labels[i].visible = next_index < num_items
	end

	log:trace("set visible indices = %s", visible_indices)
end

-- =============================================================================
-- PUBLIC METHODS THAT UPDATE THE GUI
-- =============================================================================



-- hide the UI
function GUI:hide()
	self.ui_base.visible = false
end

-- show the UI
function GUI:show()
	self.ui_base.visible = true
end

---@param item_index integer The index of the item to select in the UI
function GUI:set_index(item_index)
	local container = self.container
	if container == nil then
		return false
	end
	local item = container.items[item_index]
	if item == nil or container:can_take_item(item) == -1 then
		return false
	end
	log("setting index to %s. item = %s", item_index, item)
	self:recompute_visible_indices(item_index)
	self:update_visible_item_display_internal()

	event.trigger(defns.EVENT_IDS.item_selected, { container = container, gui = self, item = item },
		{ filter = container.cls_name })

	return true
end

-- =============================================================================
-- PUBLIC METHODS THAT UPDATE INFORMATION IN THE GUI
-- =============================================================================

--- Advances the UI to the next available item.
---@param wrap_index boolean Should we wrap the index if we reach the end?
function GUI:next_index(wrap_index)
	local next = self.visible_indices[self.ui_index + 1]

	if next and self:set_index(next) then
		return true
	elseif self.container and wrap_index then
		for i = 1, #self.container.items do
			if self:set_index(i) then
				return true
			end
		end
	end

	return false
end

--- Selects the previous item.
---@param wrap_index boolean Should we wrap the index if we reach the end?
function GUI:prev_index(wrap_index)
	local prev = self.visible_indices[self.ui_index - 1]

	if prev and self:set_index(prev) then
		return true
	elseif self.container and wrap_index then
		for i = #self.container.items, 1, -1 do
			if self:set_index(i) then
				return true
			end
		end
	end

	return false
end

--- Update the information of all visible items, without checking if they need to be recalculated.
--- This updates the name, value, etc, to reflect things like the count increasing/decreasing, or the amount of gold increasing/decreasing.
--- This does not change which items are currently visible.
---@protected
function GUI:update_visible_item_display_internal()
	log("updating information of all items...")

	local container = self.container
	if not container then
		log:error("tried to update items when container was nil!")
		return
	end
	local items = container.items

	local is_modifier_held = common.is_modifier_held()
	local icons = self.icons_col.children
	local names = self.names_col.children
	local values = self.values_col.children
	local weights = self.weights_col.children

	local num_cols = #icons

	for i, item_index in ipairs(self.visible_indices) do
		local item = items[item_index]
		local can_take = container:can_take_item(item)

		local is_selected = i == self.ui_index
		local color

		if can_take == 1 then
			color = is_selected and COLORS.ok_selected or COLORS.ok
		elseif can_take == 0 then
			color = is_selected and COLORS.unavailable_selected or COLORS.unavailable
		else
			log:error("item should not be shown in the menu, but update_information_of_all_items was called.\n\t\z
				item = %s\n%s", function() return item, log.level == 5 and debug.traceback() or "" end)
			color = is_selected and COLORS.unavailable_selected or COLORS.unavailable
		end

		local num_to_take = container:get_num_to_take(item, not is_selected, is_modifier_held)

		icons[i].visible = true
		icons[i].children[2].contentPath = container:get_item_icon_path(item)

		local bg_color = container:get_item_bg_color(item)
		if bg_color then
			icons[i].children[1].color = bg_color
			icons[i].children[1].visible = true
		else
			icons[i].children[1].visible = false
		end

		names[i].visible = true
		names[i].color = color
		names[i].text = container:format_item_name(item, num_to_take)

		values[i].visible = true
		values[i].color = color
		values[i].text = container:format_item_value(item, num_to_take)

		weights[i].visible = true
		weights[i].color = color
		weights[i].text = container:format_item_weight(item, num_to_take)
	end

	-- hide the remaining items
	for i = #self.visible_indices + 1, num_cols do
		icons[i].visible = false
		names[i].visible = false
		values[i].visible = false
		weights[i].visible = false
	end
end

--- Updates the part of the GUI that shows items.
--- This involves making sure that the currently selected item is valid (and changing the index if not)
--- and updating the information displayed for each item (name, count, weight, icon, and value).
--- If `only_selected == true`, then if the currently selected item is valid, only that item will be updated.
---@param severity herbert.MQL.events.Container.items_changed.severity
function GUI:update_item_display(severity)
	-- make sure the currently selected item is valid

	local container = self.container
	if not container then
		return
	end
	local ui_index = self.ui_index
	local selected_item = container.items[self.visible_indices[ui_index]]


	if selected_item and self.container:can_take_item(selected_item) ~= -1 then
		if severity == 1 then
			local num_to_take = container:get_num_to_take(selected_item, false, common.is_modifier_held())
			self.names_col.children[ui_index].text = container:format_item_name(selected_item, num_to_take)
			self.values_col.children[ui_index].text = container:format_item_value(selected_item, num_to_take)
			self.weights_col.children[ui_index].text = container:format_item_weight(selected_item, num_to_take)
		else
			-- it's possible that other indices got messed up
			self:recompute_visible_indices(self.visible_indices[ui_index])
			self:update_visible_item_display_internal()
		end

		return
	end

	local next = self.visible_indices[ui_index + 1]
	if next and self:set_index(next) then
		return true
	end
	local prev = self.visible_indices[ui_index - 1]
	if prev and self:set_index(prev) then
		return true
	end
	self:recompute_visible_indices()
	self:update_visible_item_display_internal()
end

local BG_SIZE = ICON_SIZE - 4
local ACTUAL_ICON_SIZE = ICON_SIZE - 4

function GUI:make_items_skeleton()
	self.ui_index = 0

	local total_num_to_show = UI_cfg.max_disp_items

	self.icons_col:destroyChildren()
	self.names_col:destroyChildren()
	self.values_col:destroyChildren()
	self.weights_col:destroyChildren()

	local icons_col = self.icons_col
	local names_col = self.names_col
	local values_col = self.values_col
	local weights_col = self.weights_col

	for _ = 1, total_num_to_show do
		do -- make icon
			local icon_blk = icons_col:createBlock()
			icon_blk.width = ICON_SIZE
			icon_blk.borderBottom = ROW_SEP
			icon_blk.height = ICON_SIZE
			icon_blk.paddingAllSides = 2
			icon_blk.childAlignX = 0.5
			icon_blk.childAlignY = 0.5
			--  local bg_color = container:get_item_bg_color(item)
			-- bg_color = table.choice(school_colors)
			local icon_swirl = icon_blk:createImage { path = "textures/menu_icon_magic.tga" }
			icon_swirl.width = BG_SIZE
			icon_swirl.height = BG_SIZE
			icon_swirl.alpha = 1
			--  icon_swirl.color = bg_color
			icon_swirl.imageScaleX = 0.8
			icon_swirl.imageScaleY = 0.8
			-- icon_swirl.scaleMode = true
			icon_swirl.absolutePosAlignX = 0.7
			icon_swirl.absolutePosAlignY = 0.7

			local icon = icon_blk:createImage()
			icon.width = ACTUAL_ICON_SIZE
			icon.height = ACTUAL_ICON_SIZE
			icon.borderBottom = ROW_SEP
			icon.scaleMode = true

			icon_blk.visible = false
		end


		local lbl

		lbl = names_col:createLabel()
		lbl.height = ICON_SIZE
		lbl.minHeight = ICON_SIZE
		lbl.borderBottom = ROW_SEP
		lbl.visible = false

		lbl = values_col:createLabel()
		lbl.height = ICON_SIZE
		lbl.minHeight = ICON_SIZE
		lbl.borderBottom = ROW_SEP
		lbl.visible = false

		lbl = weights_col:createLabel()
		lbl.height = ICON_SIZE
		lbl.minHeight = ICON_SIZE
		lbl.borderBottom = ROW_SEP
		lbl.visible = false
	end
end

function GUI:update_title_blk()
	local subtitle_blk = self.subtitle_blk
	subtitle_blk:destroyChildren()

	if not self.container then
		self.title.text = ""
		return
	end

	self.title.text = self.container:get_title()
	subtitle_blk:destroyChildren()
	local subtitle_txts = self.container:get_subtitles()
	log("got subtitles = %s", subtitle_txts)
	for _, subtitle_txt in ipairs(subtitle_txts or {}) do
		subtitle_blk:createLabel { text = subtitle_txt }
	end
end

--- Updates the action labels for the GUI.
---@param item herbert.MQL.Item? The item to update the action labels for. Default: the currently selected item.
function GUI:update_action_labels(item)
	if not self.container or not UI_cfg.show_controls then
		return
	end
	if item == nil then
		item = self:get_selected_item()
	end

	local controls_blk = self.actions_blk
	local action_names = self.container:get_action_names(item, common.is_modifier_held(), common.is_equip_modifier_held())
	if not action_names then
		return
	end
	-- self.controls_container.visible = (next(action_names) ~= nil)

	for i, lbl in ipairs(controls_blk.children) do
		local action_name = action_names[i]
		lbl.text = action_name and fmt("%s) %s", KEY_NAMES[i], action_name) or ""
	end
	controls_blk:updateLayout()

	-- controls_blk:updateLayout()
	local min_width = CONTROL_LABELS_MIN_SEP
	for _, lbl in ipairs(controls_blk.children) do
		min_width = min_width + lbl.width
	end

	controls_blk.minWidth = min_width
	if UI_cfg.columns_layout == 3 then
		-- the math.max ensures that the menu won't shrink again after its been expanded
		self.names_col.minWidth = math.max(self.names_col.minWidth or 0, min_width - 3 * (ICON_SIZE + 10))
	end
end

function GUI:hide_contents(msg)
	self.ui_base.visible = true
	-- hide the contents
	self.container_contents_blk.visible = false
	local msg_blk = self.message_blk
	msg_blk.visible = true
	msg_blk:destroyChildren()
	local lbl = msg_blk:createLabel { text = msg or "You can't see inside of this container." }
	lbl.color = COLORS.empty
	lbl.borderBottom = 10
	lbl.borderTop = 10
	lbl:getTopLevelMenu():updateLayout()
	-- self.ui_base:updateLayout()
end

function GUI:update_status_bar_text()
	local text, color = self.container:get_status_bar_text()
	-- local should_update = false
	if not text then
		self.status_blk.visible = false
	elseif UI_cfg.enable_status_bar then
		log("setting text to %s and color to %s", text, color)
		self.status_label.text = tostring(text)
		self.status_label.color = color or COLORS.status

		self.status_blk.visible = true
	end
end

--- Performs a quick update of the UI.
--- This updates the action labels and item amounts
--- But it does not remake items or anything of that nature.
function GUI:update_gui_visibility()
	local container = self.container
	if not container then
		log:error("tried to update when container was nil!")
		self:hide()
		return
	end

	log("doing a quick update!")
	local status, reason = container:can_enable(container.handle:getObject())
	if status == -1 then
		self:hide()
		return
	end
	self:show()
	if status == 0 then
		self:hide_contents(reason)
	else
		self:show_contents()
	end
end

-- =============================================================================
-- HIDE OR DESTROY THE GUI
-- =============================================================================



-- destroy this GUI and all its related data
function GUI:destroy()
	if self.ui_base == nil then return end
	log:trace("destroying menu :(")
	self.ui_base:destroy()
	self.ui_base = nil
end

function GUI.find_menu()
	return tes3ui.findMenu(uids.base)
end

return GUI
