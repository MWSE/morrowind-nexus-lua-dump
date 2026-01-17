local log = mwse.Logger.new { includeTimestamp = true }
local hlib = require("herbert100")

local cfg = require("herbert100.quick select.config")
local Menu = require("herbert100.quick select.QS_Menu")
local Option = require("herbert100.quick select.QS_Option")
local Player_Data_Tab = require("herbert100.quick select.QS_Player_Data_Tab")
local get_options = require("herbert100.quick select.get_options")
local fmt = string.format
local metadata = (hlib.get_mod_info() or {}).metadata


---@alias herbert.QS.saved_option {[1]: string, [2]: boolean}


local register_event = cfg.livecoding and livecoding and livecoding.registerEvent or event.register

-- -@class herbert.QS.saved_option
-- -@field id string
-- -@field is_magic boolean?

---@class herbert.QS.player_data
---@field custom_tabs herbert.QS.saved_option[][] for each `tab_index`, it contains an array of tuples. the first index of each tuple is the item id, the second index is whether that item is a magic item
---@field tab_index integer the last activate tab index
---@field recent_item_ids string[] stores item ids of recently used items
---@field version string?
local default_player_data = {
	custom_tabs = {},
	tab_index = 1,
	recent_item_ids = {},
	version = metadata and metadata.package and metadata.package.version
}

for i = 1, #cfg.tabs.custom do
	default_player_data.custom_tabs[i] = {}
end

local player_data ---@type herbert.QS.player_data?
local recent_item_ids ---@type string[]

local function custom_tabs_tostring(custom_tabs)
	return table.concat(hlib.tbl_ext.map2(custom_tabs, function(i, tab)
		return fmt("%i) %s", i, json.encode(tab))
	end), "\n\t")
end
local function sanitize_player_data()
	---@diagnostic disable-next-line: cast-local-type
	recent_item_ids = nil
	player_data = hlib.load_player_data("herbert_QS", default_player_data)
	if not player_data then
		log:error("could not load player data!")
		return
	end

	recent_item_ids = player_data.recent_item_ids

	local custom_tabs = player_data.custom_tabs

	for i, tab in ipairs(player_data.custom_tabs) do
		local tab_copy = table.copy(tab)



		for j, v in pairs(tab_copy) do
			local new_j = j
			if type(j) == "string" then
				new_j = tonumber(j)
				log("found string index %s", j)
				tab[new_j] = v
			end
			if type(v) == "string" then
				log("custom_tabs[%i][%i] == %s is a string. updating it", i, j, v)
				---@diagnostic disable-next-line: param-type-mismatch
				local obj = tes3.getObject(tab[j])
				local is_magic = obj and obj.objectType == tes3.objectType.spell or nil
				---@diagnostic disable-next-line: assign-type-mismatch
				tab[new_j] = { tab[j], is_magic }
			elseif type(v) == "table" and #v == 0 then
				log("custom_tabs[%i][%i] == %s was a table with len 0. updating it.", i, j, v)
				v[1] = v.id
				v[2] = v.is_magic
				---@diagnostic disable-next-line: inject-field
				v.id, v.is_magic = nil, nil
			end
		end
	end
	log("updated player data. tabs are now: \n\t%s", custom_tabs_tostring, custom_tabs)

	if metadata then
		player_data.version = metadata.package.version
	end
end




local qs_menu ---@type herbert.QS.Menu?




-- local equipped_id ---@type string




---@param item tes3item|tes3spell
local function update_recently_equipped(item)
	if not recent_item_ids then
		log("recent item ids was nil, aborting")
		return
	end
	local id = item.id

	local prev_index = table.find(recent_item_ids, id)
	if prev_index then
		log("found %q at recent_item_ids[%i]. removing it...", item.name, prev_index)
		table.remove(recent_item_ids, prev_index)
	end

	log("inserting recently equipped item %q (id=%q)", item.name, id)
	table.insert(recent_item_ids, 1, id)

	for i = cfg.num_options + 1, #recent_item_ids do
		recent_item_ids[i] = nil
	end
	log("have %i recently equipped items: %s", function()
		return #recent_item_ids, json.encode(recent_item_ids)
	end)
end

---@param e equippedEventData
local function equipped(e)
	if e.reference == tes3.player then
		log("%q has equipped an item!", e.actor.name)
		update_recently_equipped(e.item)
	end
end
---@param e magicSelectionChangedEventData
local function magic_selection_changed(e)
	log("magic selection changed!")
	local obj = e.item or e.source
	if not obj then return end


	log("now have %q equipped", obj)
	update_recently_equipped(obj)
end



local function make_recents_options()
	local options = {}
	local obj
	for i, id in ipairs(recent_item_ids) do
		obj = tes3.getObject(id)
		if obj then
			table.insert(options, Option.new { item = obj })
		else
			log:error("recently_equipped[%i] = %q was nil!!!", i, id)
		end
	end
	return options
end


local function special_button_held(getting)
	if cfg.toggle_mode and qs_menu then
		qs_menu:destroy()
		qs_menu = nil
		return
	end
	if tes3.menuMode() then return end
	local data = tes3.player.data.herbert_QS
	local tabs_cfg = cfg.tabs

	local tabs = {}
	for i, custom_tab in ipairs(tabs_cfg.custom) do
		if custom_tab.enable then
			table.insert(tabs, Player_Data_Tab.new(i, getting))
		end
	end
	if getting then
		local auto_gen = tabs_cfg.auto_gen
		if auto_gen.tools.enable then
			table.insert(tabs, {
				name = auto_gen.tools.name,
				color = auto_gen.tools.color,
				get_options = get_options
					.tools
			})
		end
		if auto_gen.soul_gems.enable then
			table.insert(tabs,
				{ name = auto_gen.soul_gems.name, color = auto_gen.soul_gems.color, get_options = get_options.soul_gems })
		end
		if auto_gen.recent.enable then
			table.insert(tabs, {
				name = auto_gen.recent.name,
				color = auto_gen.recent.color,
				get_options =
					make_recents_options
			})
		end
		-- if auto_gen.on_use.enable then
		--     table.insert(tabs, {name=auto_gen.on_use.name, color=auto_gen.on_use.color, get_options=get_options.on_use_enchants})
		-- end
	end
	if cfg.list_mode then
		qs_menu = Menu.new { tabs = tabs, tab_index = data.tab_index, num_rows = cfg.num_options, num_cols = 1 }
	else
		qs_menu = Menu.new { tabs = tabs, tab_index = data.tab_index }
	end
end


local function special_button_released()
	if cfg.toggle_mode then return end

	if tes3.menuMode() and qs_menu then
		qs_menu:destroy()
		-- if qs_menu.tab_index then
		--     player_data.tab_index = qs_menu.tab_index
		-- end
		qs_menu = nil
	end
end

---@param e keyDownEventData
local function key_pressed(e)
	if e.keyCode == cfg.key.keyCode then
		special_button_held(not e.isAltDown)
	end
	-- qs_menu = QS_Menu.new{tab_names=tab_names, tab_index=data.tab_index, get_options=opts_fun}
end

---@param e keyUpEventData
local function key_released(e)
	if e.keyCode == cfg.key.keyCode then
		special_button_released()
	end
end


---@param e mouseButtonDownEventData
local function mouse_down(e)
	if e.button == cfg.key.mouseButton then
		special_button_held(not e.isAltDown)
	end
end

---@param e mouseButtonUpEventData
local function mouse_up(e)
	if e.button == cfg.key.mouseButton then
		special_button_released()
	end
end






local function loaded()
	sanitize_player_data()
end

local function initialized()
	register_event(tes3.event.keyDown, key_pressed)
	register_event(tes3.event.keyUp, key_released)
	register_event(tes3.event.mouseButtonDown, mouse_down)
	register_event(tes3.event.mouseButtonUp, mouse_up)
	register_event(tes3.event.loaded, loaded)
	register_event(tes3.event.equipped, equipped)
	register_event(tes3.event.magicSelectionChanged, magic_selection_changed)


	---@param e herbert.QS.Menu.tab_selected.event_data
	register_event("herbert:QS:tab_selected", function(e)
		if qs_menu == e.menu then
			player_data.tab_index = e.tab_index
		end
	end)


	log:writeInitMessage()
end
if livecoding and tes3.isInitialized() then
	initialized()
end
register_event(tes3.event.initialized, initialized)
