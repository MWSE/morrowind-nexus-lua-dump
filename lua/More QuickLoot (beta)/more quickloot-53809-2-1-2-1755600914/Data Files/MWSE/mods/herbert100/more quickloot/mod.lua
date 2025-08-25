--[[
    More QuickLoot. An updated QuickLoot mod based on the original QuickLoot mod by mort.
    Version 1.2
    Author: herbert100

    Original QuickLoot author: mort
]] --


local defns = require("herbert100.more quickloot.defns") ---@type herbert.MQL.defns
local cfg = require("herbert100.more quickloot.config")
local common = require("herbert100.more quickloot.common") ---@type herbert.MQL.common
local GUI = require("herbert100.more quickloot.GUI") ---@type herbert.MQL.GUI
-- load up all the containers
include("herbert100.more quickloot.containers")

local register_event = common.register_event
local log = mwse.Logger.new()

local active_gui ---@type herbert.MQL.GUI?
local undo = cfg.keys.undo ---@type mwseKeyCombo

--- mark/unmark an item as collected through TTIP
---@param e keyDownEventData
local function ttip_mark_selected_as_collected(e)
	if active_gui == nil then
		return
	end
	local container = active_gui.container
	-- local container =
	if container == nil or container.disabled then
		return
	end
	local item = active_gui:get_selected_item()
	---@cast item herbert.MQL.Item.Physical

	if not item or not item.object then
		return
	end

	local item_id = item.object.id

	local ttip_collected_tbl = tes3.player.itemData.data.rev_TTIP.items

	-- unmark an item if it has already been marked. otherwise, mark it
	if ttip_collected_tbl[item_id] == true then
		tes3.messageBox "Item unmarked"
		ttip_collected_tbl[item_id] = nil
	else
		tes3.messageBox "Item marked"
		ttip_collected_tbl[item_id] = true
	end

	active_gui:update_item_display(1)

	e.claim = true

	return
end


local function update_keybindings()
	undo.isAltDown = undo.isAltDown or false
	undo.isShiftDown = undo.isShiftDown or false
	undo.isControlDown = undo.isControlDown or false
	undo.isSuperDown = undo.isSuperDown or false

	-- update TTIP key bind events
	if cfg.compat.ttip then
		log("updating ttip settings")
		local ttip_config = include("rev_TTIP.config")
		common.upd_event_reg(
			"keyDown",
			ttip_mark_selected_as_collected,
			cfg.UI.ttip_mark_selected,
			ttip_config.collect.keyCode,
			nil,
			1
		)
	end
end



-- ---@param e uiObjectTooltipEventData
-- function event_callbacks.ui_object_tooltip(e)
--     -- if e.reference and e.reference.isDead ~= false and this.choose_nonliving_container(e.reference) then
--     --     e.tooltip.visible = false
--     --     e.claim = true
--     -- end
-- end



local function config_updated_callback()
	log("config updated!")
	common.update_equipped_cfg(cfg.pickpocket.equipped)
	common.update_equipped_cfg(cfg.barter.equipped)
	update_keybindings()
end


log("starting file")


local function kill_gui()
	if active_gui then
		log "killing old GUI."
		local old_gui = active_gui
		old_gui:destroy()
		active_gui = nil
	end
end

local function kill_container()
	if active_gui then
		log "killing old GUI container."
		active_gui:kill_container()
		active_gui:hide()
	end
end


--- Tries to make a tooltip for the given container, if possible.
---@param container herbert.MQL.Container
---@param item herbert.MQL.Item?
local function try_make_tooltip(container, item)
	if container and item and container:can_make_item_tooltip(item) then
		container:make_item_tooltip(item)
	end
end


---@param action herbert.MQL.Action
---@return boolean? successful Will be `nil` if we couldn't do an action to begin with.
--- Otherwise will be the return result of `Container:do_action`
local function do_container_action(action)
	if active_gui == nil or active_gui.container == nil or active_gui.container.disabled then
		if action.ty == defns.ActionType.TakeAll then
			local target = tes3.getPlayerTarget()
			if target then
				common.take_nearby_items(target)
			end
		end
		return
	end


	local item = active_gui:get_selected_item()

	local successful = active_gui.container:do_action(item, action)
	log("did action %s\n\t\z
        item = %s\n\t\z
        successful? = %s",
		action,
		item,
		successful
	)

	if active_gui then
		active_gui:update_action_labels()
	end
	return successful
end
---@param wrap_index boolean
---@return boolean should_claim True if the event should be claimed.
local function scroll_down(wrap_index)
	if not active_gui then return false end
	local container = active_gui.container
	if container == nil or container.disabled then
		return false
	end

	return active_gui:next_index(wrap_index) or false
end


---@param wrap_index boolean
local function scroll_up(wrap_index)
	if not active_gui then return false end
	local container = active_gui.container
	if not container then return false end

	return not container.disabled and active_gui:prev_index(wrap_index)
		or false
end


-- =============================================================================
-- CUSTOM EVENTS
-- =============================================================================





local function gui_destroyed_callback()
	active_gui = nil
	common.reset_tooltip()
end

---@param e herbert.MQL.events.Container.item_returned
local function item_returned_callback(e)
	if active_gui and active_gui.container == e.container then
		local index = table.find(active_gui.container.items, e.item)
		if index then
			-- active_gui.ui_base.visible = true
			-- active_gui.container_contents_blk.visible = false
			active_gui:update_gui_visibility()
			active_gui:set_index(index)
			active_gui:update_action_labels()
		end
	end
end


---@param e herbert.MQL.events.Container.items_changed
local function container_items_changed_callback(e)
	if active_gui and active_gui.container == e.container then
		active_gui:update_item_display(e.severity)
	end
end


---@param e herbert.MQL.events.Container.title_updated
local function title_updated_callback(e)
	if active_gui and active_gui.container == e.container then
		active_gui:update_title_blk()
	end
end


---@param e herbert.MQL.events.modifier_state_updated
local function modifier_state_updated_callback(e)
	if active_gui then
		active_gui:update_item_display(2)
		active_gui:update_action_labels()
		-- active_gui:update_modified_action_labels()
		-- gui:quick_update()
	end
end
---@param e herbert.MQL.events.modifier_state_updated
local function equip_modifier_state_updated_callback(e)
	if active_gui then
		active_gui:update_action_labels()
	end
end

---@param e herbert.MQL.events.item_selected
local function item_selected_callback(e)
	if active_gui then active_gui:update_action_labels() end
	try_make_tooltip(e.container, e.item)
end


-- =============================================================================
-- DEFAULT EVENTS
-- =============================================================================

--- Controls whether the next activation event should be blocked.
--- This is set to true whenever the player does a successul quickloot action
--- using the same key that's bound to the activate event.
local block_activate = false


---@param e keyDownEventData
local function key_down(e)
	local action = common.convert_keycode_to_action(e)
	if action then
		local success = do_container_action(action)
		log("action success? %s", success)
		if success then
			local activate_binding = tes3.getInputBinding(tes3.keybind.activate)
			if activate_binding.device == 0 and activate_binding.code == e.keyCode then
				log("blocking next activate!")
				block_activate = true
			end
		end
	end
end




---@param e mouseButtonDownEventData
local function mouse_down(e)
	local action = common.convert_mousebutton_to_action(e)
	if action then
		local success = do_container_action(action)
		log("action success? %s", success)
		if success then
			local activate_binding = tes3.getInputBinding(tes3.keybind.activate)
			if activate_binding.device == 1 and activate_binding.code == e.button then
				log("blocking next activate!")
				block_activate = true
			end
		end
	end
end

---@param e activateEventData
local function activate_callback(e)
	if block_activate then
		e.block = true
		block_activate = false
	end
end




--- updates the currently active container, possible making a new one or destroying the current one
-- also updates `this.target`, to ensure `this.target` is always referring to what the player is currently looking at
---@param e activationTargetChangedEventData equal to `tes3reference|nil` if called by `activation_target_changed`, otherwise `false`
local function activation_target_changed_callback(e)
	local new_ref = e.current

	log("activation target changed. now looking at %s", new_ref)

	-- this is as good a time as any to reset it
	block_activate = false


	if active_gui and active_gui.container then
		local container = active_gui.container
		---@cast container -nil

		local old_ref = container.handle:getObject()
		if old_ref == nil then
			log("container reference was nil. reseting...\n\tgui = %s", active_gui)
			kill_container()
		elseif new_ref == nil then
			if not container.disabled then
				common.reset_tooltip(false, container)
				container:disable()
				active_gui:hide()
			end

			-- past this point, both `new_ref` and `old_ref` are valid
		elseif container:can_enable(new_ref) == -1 then -- if the new ref isnt valid for the active container,
			log("container %s cannot be enabled for %s.", container, new_ref)

			if not container.disabled then
				common.reset_tooltip(new_ref, container)
				container:disable()
				active_gui:hide()
			end
		else -- both refs are valid, and the container can be activated for the new reference
			local payload = event.trigger(
				defns.EVENT_IDS.reactivate_container,
				{ container = container, block = false, claim = false },
				{ filter = container.cls_name }
			)
			if not payload.block then
				log("enabling container")

				container:enable(new_ref)
				active_gui:update_gui_visibility()
				active_gui:update_title_blk()
				active_gui:update_action_labels()
				-- active_gui:update_modified_action_labels()
				try_make_tooltip(container, active_gui:get_selected_item())

				return
			end
		end
	end

	if new_ref ~= nil then
		log("triggering pick container event with new_ref = %s", new_ref)
		common.trigger_pick_container(new_ref)
	end
end

---@type fun(): integer
local gettime = require("socket").gettime

---@param e herbert.MQL.events.container_picked
local function container_picked_callback(e)
	log("container picked! it is %s", e.container_cls.cls_name)

	kill_container()
	local container = e.container_cls.new(e.ref)
	if not active_gui then
		active_gui = GUI.new()
		log("remade gui!")
	end

	local start = gettime()
	active_gui:set_container(container)

	local set_container = gettime()
	active_gui:update_gui_visibility()

	active_gui:update_title_blk()
	active_gui:update_status_bar_text()
	active_gui:update_action_labels()
	-- active_gui:update_modified_action_labels()

	local updates = gettime()

	-- active_gui:recompute_visible_items()

	local recompute_visible_items = gettime()

	active_gui:update_item_display(2)

	try_make_tooltip(container, active_gui:get_selected_item())

	local update_visible_item_display = gettime()

	local end_ = update_visible_item_display

	log([[made new container %s for %s.
			set_container: %s
			updates: %s
			recompute_visible_items: %s
			update_visible_item_display: %s
			---------------
			total: %s
		]],
		e.container_cls.cls_name, e.base_id,
		set_container - start,
		updates - set_container,
		recompute_visible_items - updates,
		update_visible_item_display - recompute_visible_items,
		end_ - start
	)
end


---@param e herbert.MQL.events.Container.empty
local function container_empty_callback(e)
	if active_gui then
		active_gui:update_gui_visibility()
		common.reset_tooltip(e.container.handle:getObject(), e.container)
	end
end
---@param e herbert.MQL.events.Container.empty
local function container_status_text_updated_callback(e)
	if active_gui then
		active_gui:update_status_bar_text()
	end
end

---@param e keyDownEventData
local function arrow_key_scroll_down(e)
	e.claim = scroll_down(true) and cfg.advanced.ak_claim
end

---@param e keyDownEventData
local function arrow_key_scroll_up(e)
	e.claim = scroll_up(true) and cfg.advanced.ak_claim
end

-- Called when the mouse wheel scroll is used. Changes the selection.
---@param e mouseWheelEventData
local function mouse_wheel_scroll(e)
	local successful
	if e.delta > 0 then
		successful = scroll_up(false)
	else
		successful = scroll_down(false)
	end
	e.claim = successful and cfg.advanced.sw_claim
end


local function initialized()
	register_event(tes3.event.activationTargetChanged, activation_target_changed_callback)

	-- KEY PRESS CALLBACKS
	register_event(tes3.event.activate, activate_callback)
	register_event(tes3.event.mouseButtonDown, mouse_down, { priority = cfg.advanced.mousedown_priority })
	register_event(tes3.event.keyDown, key_down, { priority = cfg.advanced.keydown_priority })
	register_event(tes3.event.keyDown, arrow_key_scroll_up, { filter = tes3.scanCode.keyUp })
	register_event(tes3.event.keyDown, arrow_key_scroll_down, { filter = tes3.scanCode.keyDown })
	register_event(tes3.event.mouseWheel, mouse_wheel_scroll)

	-- DESTROY MENU WHEN STUFF HAPPENS
	register_event(tes3.event.load, kill_gui, { priority = cfg.advanced.load_priority })
	register_event(tes3.event.cellChanged, kill_gui, { priority = cfg.advanced.cell_changed_priority })
	register_event(tes3.event.menuEnter, kill_gui, { priority = cfg.advanced.menu_entered_priority })
	register_event(tes3.event.uiActivated, kill_gui,
		{ filter = "MenuInventory", priority = cfg.advanced.menu_entered_priority })



	-- CUSTOM EVENT CALLBACKS
	register_event(defns.EVENT_IDS.item_selected, item_selected_callback)
	register_event(defns.EVENT_IDS.equip_modifier_state_updated, equip_modifier_state_updated_callback)
	register_event(defns.EVENT_IDS.modifier_state_updated, modifier_state_updated_callback)
	---@param e herbert.MQL.events.Container.invalidated
	register_event(defns.EVENT_IDS.container_invalidated, function(e)
		common.reset_tooltip(nil, e.container)
		log("container invalidated! %s", e)
		kill_container()
	end)

	register_event(defns.EVENT_IDS.container_items_changed, container_items_changed_callback)
	register_event(defns.EVENT_IDS.title_updated, title_updated_callback)
	register_event(defns.EVENT_IDS.container_item_returned, item_returned_callback, { priority = math.huge })

	register_event(defns.EVENT_IDS.container_empty, container_empty_callback)
	register_event(defns.EVENT_IDS.gui_destroyed, gui_destroyed_callback)

	register_event(defns.EVENT_IDS.container_picked, container_picked_callback)
	register_event(defns.EVENT_IDS.container_status_text_updated, container_status_text_updated_callback)

	register_event(defns.EVENT_IDS.config_updated, config_updated_callback)
	config_updated_callback()

	log:writeInitMessage()
end


register_event(tes3.event.initialized, initialized, { doOnce = true })
