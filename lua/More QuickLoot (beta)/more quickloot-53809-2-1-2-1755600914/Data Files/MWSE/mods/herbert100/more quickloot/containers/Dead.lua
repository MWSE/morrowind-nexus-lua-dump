local Physical_Container = require("herbert100.more quickloot.containers.abstract.physical")
local cfg = require("herbert100.more quickloot.config")
local defns = require("herbert100.more quickloot.defns")
local common = require("herbert100.more quickloot.common")

local register_event = common.register_event


local EVENT_IDS = defns.EVENT_IDS
local log = mwse.Logger.new()
-- this container will be called on dead things. it will allow dead creates to be disposed, based on config settings.
-- -@class herbert.MQL.Container.Dead
---@class herbert.MQL.Container.Dead : herbert.MQL.Container.Physical
local Dead = { cls_name = "Dead" }


local meta = { __index = Dead, __tostring = Physical_Container.__tostring }

---make a new one
---@param ref tes3reference
---@return herbert.MQL.Container.Dead
function Dead.new(ref)
	---@type herbert.MQL.Container.Dead
	local obj = setmetatable({
		handle = tes3.makeSafeObjectHandle(ref),
		items = {},
		history = {},
		relevant_handles = {},
		disabled = false,
	}, meta)


	obj:make_items()

	return obj
end

---@param selected_item herbert.MQL.Item.Physical? Item to do the action on
---@param action herbert.MQL.Action
---@return boolean successful
function Dead:do_action(selected_item, action)
	local ref = self.handle:getObject()
	if not ref then return false end
	local ty = action.ty
	if ty == 1 then -- take one
		if not selected_item then
			tes3.messageBox "There is nothing to take!"
			return false
		end

		local res = self:can_take_item(selected_item)
		if self:can_take_item(selected_item) ~= 1 then
			return res == 0
		end

		local to_take = self:get_num_to_take(selected_item, false, action.modifier_held)
		local taken = self:take_item(selected_item, to_take, false)
		log("took %s %s", taken, selected_item.object.name)
		log("\tamount remaining: %s", selected_item.count)

		if taken > 0 and action.equip_modifier_held then
			tes3ui.forcePlayerInventoryUpdate()
			local result = tes3.mobilePlayer:equip { item = selected_item.object, itemData = selected_item.data }
			log("tried to equip %s. result = %s", selected_item, result)
		end

		tes3.playItemPickupSound { item = selected_item.object, pickup = true }

		common.ensure_not_empty(self)

		local severity = (selected_item.count == 0) and 2 or 1
		log("\tcalling items changed event with severity = %s", severity)
		event.trigger(
			EVENT_IDS.container_items_changed,
			{ container = self, severity = severity },
			{ filter = self.cls_name }
		)

		return taken > 0
	elseif ty == 2 then -- take all
		-- if there's no item or we can't take the item
		if selected_item == nil or self:can_take_item(selected_item) == -1 then
			-- see if the config settings allow disabling NPCs when the inventory is empty
			if not cfg.dead.dispose or common.at_least_one_item_valid(self) then
				return false
			end


			-- make sure this reference is managed by this container, and then disable it.
			local player_target = tes3.getPlayerTarget()
			if player_target then
				-- check if its equal to the one we already have.
				if player_target == ref then
					log("disabling player target, which aligned with the active handle.")
					player_target:disable()
				else
					for _, handle in ipairs(self.relevant_handles) do
						if handle:getObject() == player_target then
							player_target:disable()
							break
						end
					end
				end
			end

			return true
		end



		local total_taken = 0
		local min_ratio = cfg.reg.take_all_min_ratio
		log("min ratio = %s", min_ratio)
		for _, item in ipairs(self.items) do
			if self:can_take_item(item) == 1
				and min_ratio == 0 or common.value_weight_ratio(item) >= min_ratio
			then
				local num = self:get_num_to_take(item, true, action.modifier_held)
				if num > 0 then
					total_taken = total_taken + self:take_item(item, num, true)
				end
			end
		end

		if total_taken > 0 then
			tes3.playItemPickupSound { item = selected_item.object, pickup = true }
			common.ensure_not_empty(self)

			event.trigger(
				EVENT_IDS.container_items_changed,
				{ container = self, severity = 2 },
				{ filter = self.cls_name }
			)
		end
		if cfg.UI.show_msgbox then
			local msg = total_taken == 0 and "There was nothing you wanted to take."
				or string.format("You took %i items.", total_taken)
			tes3.messageBox(msg)
		end

		return true
	elseif ty == 3 then -- open
		tes3.player:activate(ref)
		return true
	else -- undo
		-- nothing to undo
		if #self.history == 0 then
			return true
		end

		local entry = self.history[#self.history] -- takes the last one
		local item = entry.item

		-- try to actually return it, and keep track of how many were actually returned
		---@type tes3reference?
		local to = item.box_handle:getObject()

		if to == nil then
			table.remove(self.history, #self.history)
			log:error("tried to return items to a referene that doesn't exist!")
			return false
		end
		if to.disabled then
			to:enable()
			-- table.remove(self.history, #self.history)
			log("tried to return an item to a container that was disabled! enabling it...")
			-- return true
		end
		local num_returned = common.transfer_item(tes3.player, to, item, entry.num_removed, false)

		-- stop now if nothing actually got returned
		if num_returned == 0 then
			log:error("tried to return %s but couldn't!\n\thistory: %s", item, entry)
			return true
		end

		-- only delete the history if all the items were returned
		if num_returned < entry.num_removed then
			entry.num_removed = entry.num_removed - num_returned
		else
			table.remove(self.history, #self.history)
		end
		-- update the item count to reflect the newly returned items
		item.count = item.count + num_returned


		-- let everyone know we returned an item
		event.trigger(
			defns.EVENT_IDS.container_item_returned,
			{ container = self, item = item, num_returned = num_returned, claim = false },
			{ filter = self.cls_name }
		)
		return true
	end
end

--- Gets the action labels, depending on the context
---@param item herbert.MQL.Item.Physical? The item to generate action names for.
---@param modifier_pressed boolean Is the modifier key pressed?
---@param equip_modifier_held boolean Is the equip modifier key pressed?
---@return string[]
function Dead:get_action_names(item, modifier_pressed, equip_modifier_held)
	local action_names = Physical_Container.get_action_names(self, item, modifier_pressed, equip_modifier_held)

	if cfg.dead.dispose and not common.at_least_one_item_valid(self) then
		action_names[2] = "Dispose"
	end

	return action_names
end

function Dead:make_items()
	self.history = {}
	self.items = {}
	self.relevant_handles = {}
	if self.disabled then return end

	local this_ref = self.handle:getObject()
	if not this_ref then return end
	common.add_items_to_list(self, this_ref)

	if cfg.reg.sn_cf == defns.sn_cf.no_other_containers then return end
	local MAX_DISTANCE = cfg.reg.sn_dist

	if MAX_DISTANCE <= 5 then return end

	local MAX_V_DISTANCE = cfg.advanced.v_dist
	local this_pos = this_ref.position

	---@type tes3.creatureType|nil
	local creature_type = cfg.dead.sn_pool_by_creature_type and this_ref.object.type or nil


	local player_ref = tes3.player
	local test_los = cfg.reg.sn_test_line_of_sight

	for ref in tes3.player.cell:iterateReferences(this_ref.object.objectType) do
		if not ref.isDead then
			goto next_ref
		end

		local pos = ref.position

		if this_pos:distanceXY(pos) > MAX_DISTANCE
			or this_pos:heightDifference(pos) > MAX_V_DISTANCE
		then
			goto next_ref
		end

		if creature_type ~= nil and ref.object.type ~= creature_type then
			goto next_ref
		end

		if test_los and not tes3.testLineOfSight { reference1 = player_ref, reference2 = ref } then
			log("there's no line of sight between the player and %s", ref)
			goto next_ref
		end
		if ref == this_ref then
			goto next_ref
		end

		ref:clone()
		common.add_items_to_list(self, ref)
		::next_ref::
	end

	do -- sort the items
		local sort_items = cfg.UI.sort_items
		if sort_items == defns.sort_items.dont then return end

		if sort_items == defns.sort_items.weight then
			table.sort(self.items, common.item_sorters.weight_comp)
			return
		end

		if cfg.compat.bg and tes3.mobilePlayer.mercantile.current < common.bg_cfg.knowsPrice then
			return
		end

		if sort_items == defns.sort_items.value_weight_ratio then
			table.sort(self.items, common.item_sorters.value_weight_ratio)
		else
			table.sort(self.items, common.item_sorters.value_comp)
		end
	end

	event.trigger(
		EVENT_IDS.container_items_changed,
		{ container = self, severity = 2 },
		{ filter = self.cls_name }
	)
end

---@param e herbert.MQL.events.pick_container
local function pick_dead_container(e)
	if not cfg.dead.enable
		or e.claim or e.container_cls or e.is_organic
		or not tes3.mobilePlayer or tes3.mobilePlayer.attackDisabled
		or e.ref.isDead ~= true
	then
		return
	end

	e.container_cls = Dead
end


register_event(defns.EVENT_IDS.pick_container, pick_dead_container, { filter = tes3.objectType.npc })
register_event(defns.EVENT_IDS.pick_container, pick_dead_container, { filter = tes3.objectType.creature })


-- override
Dead.can_enable = Physical_Container.can_enable
Dead.enable = Physical_Container.enable
Dead.disable = Physical_Container.disable
Dead.destruct = Physical_Container.destruct
Dead.get_num_to_take = Physical_Container.get_num_to_take
Dead.get_title = Physical_Container.get_title
Dead.get_subtitles = Physical_Container.get_subtitles
Dead.get_status_bar_text = Physical_Container.get_status_bar_text
Dead.take_item = Physical_Container.take_item
Dead.can_take_item = Physical_Container.can_take_item
Dead.format_item_name = Physical_Container.format_item_name
Dead.format_item_value = Physical_Container.format_item_value
Dead.format_item_weight = Physical_Container.format_item_weight
Dead.can_make_item_tooltip = Physical_Container.can_make_item_tooltip
Dead.make_item_tooltip = Physical_Container.make_item_tooltip
Dead.get_item_bg_color = Physical_Container.get_item_bg_color
Dead.get_item_icon_path = Physical_Container.get_item_icon_path



common.assert_interface_is_implemented(Dead)



return Dead
