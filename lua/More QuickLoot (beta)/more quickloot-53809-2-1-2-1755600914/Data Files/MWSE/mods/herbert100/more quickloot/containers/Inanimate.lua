local log = mwse.Logger.new()
local Physical_Container = require("herbert100.more quickloot.containers.abstract.physical") ---@type herbert.MQL.Container.Physical
local cfg = require("herbert100.more quickloot.config") ---@type herbert.MQL.config
local defns = require("herbert100.more quickloot.defns") ---@type herbert.MQL.defns
local fmt = string.format
local common = require('herbert100.more quickloot.common')

local EVENT_IDS = defns.EVENT_IDS

local register_event = common.register_event

local ac_defns = defns.misc.ac

---@type herbert.AC.interop
local ac_interop

register_event(tes3.event.initialized, function(e)
	if tes3.isLuaModActive("herbert100.animated containers") then
		ac_interop = include("herbert100.animated containers.interop")
	end
end)

local ac_cfg = cfg.inanimate.ac

---@param ref tes3reference
---@return boolean
local function contents_of_ref_hidden(ref)
	if not ref.lockNode then return false end

	local cf = cfg.inanimate

	local security_lvl = tes3.mobilePlayer.security.current

	if not cf.show_locked and ref.lockNode.locked then
		if security_lvl < cf.show_locked_min_security
			or (security_lvl - security_lvl % 25) < ref.lockNode.level
		then
			return true
		end
	end

	if not cf.show_trapped and ref.lockNode.trap then
		if security_lvl < cf.show_trapped_min_security then
			return true
		end
	end


	return false
end




-- =============================================================================
-- INANIMATE MANAGER
-- =============================================================================

-- the container that will be used on inanimate objects, such as chests and barrels.
-- it will basically function the same way as the `base` container, but it will now take into account whether containers are "locked" or "trapped"
-- this should take into account things being locked or trapped.
-- -@class herbert.MQL.Container.Inanimate : herbert.MQL.Container.Physical
---@class herbert.MQL.Container.Inanimate : herbert.MQL.Container.Physical
---@field taking boolean? are we taking items or placing items?
---@field lock_lvl integer|false is the container currently locked? if so, what level is the lock?
---@field trap tes3spell|false records any trap that may be on the container
---@field ac_ever_opened boolean whether we ever opened this animated container. this is so that we dont open it more than once
local Inanimate = { cls_name = "Inanimate" }

local meta = { __index = Inanimate, __tostring = Physical_Container.__tostring }

function Inanimate.new(ref)
	ref:clone()
	---@type herbert.MQL.Container.Inanimate
	local obj = setmetatable({
		handle = tes3.makeSafeObjectHandle(ref),
		items = {},
		history = {},
		relevant_handles = {},
		disabled = false,
		taking = true,
		lock_lvl = false,
		trap = false,
		ac_ever_opened = ac_interop and ac_interop.get_container_state(ref) >= 3
	}, meta)

	-- local owner = tes3.getOwner{reference = ref}
	-- if owner then
	-- 	if not owner.playerJoined
	-- 	or owner.playerExpelled
	-- 	or ref.attachments.variables.requirement > owner.playerRank
	-- 	then
	-- 		-- log("set owner to %s. \n\thasOwnershipAccess = %s", owner, tes3.hasOwnershipAccess{target=ref})
	-- 		obj.owner = owner
	-- 	end
	-- end

	log("checking ownership access for %s", ref.object)
	if tes3.hasOwnershipAccess { target = ref } then
		log("\thave access!\n\n")
	else
		obj.owner = tes3.getOwner { reference = ref }
		log("\tno access! set obj.owner = %s\n\n", obj.owner)
	end
	obj:enable(ref)
	obj:make_items()

	return obj
end

---@param ref tes3reference
---@return -1|0|1 result If -1, don't enable. if 0, enable but hide contents. if 1, enable and show contents
---@return string? contents hidden reason. The reason why the contents should be hidden. This should only be erturned if the first return result is `0`.
function Inanimate:can_enable(ref)
	-- if ref ~= nil and self.handle:getObject() == ref then
	-- 	return contents_of_ref_hidden(ref) and 0 or 1
	-- end
	log("checking if we can enable this container for %s\n\trelevant handles = %s\n\thandle: %s", ref,
		self.relevant_handles, self.handle)
	for _, handle in ipairs(self.relevant_handles) do
		log:trace("\tcomparing %s with %s....\n\t\tequal? %s", handle, ref, handle:getObject() == ref)
		if handle:getObject() == ref then
			log("\treturning....%s", contents_of_ref_hidden(ref) and 0 or 1)

			if contents_of_ref_hidden(ref) then
				return 0
			end
			-- make sure at least one item can be shown.
			if common.at_least_one_item_valid(self) then
				return 1
			end
			return 0, "Empty!"
		end
	end
	log("\treturning....%s", -1)

	return -1
end

--- makes the container update the status of the container it's managing. this is useful to checking if the container is empty, locked, etc
--- this will also end up getting called after an item is taken, because the target will temporarily be set to `nil`
---@param ref tes3reference
function Inanimate:enable(ref)
	self.disabled = false

	log("updating container state")




	local lock_node = ref.lockNode

	if lock_node then
		self.trap = lock_node.trap
		self.lock_lvl = lock_node.locked and lock_node.level or false
	else
		self.trap = false
		self.lock_lvl = false
	end
	-- if animated containers is installed, try to open the container
	if ac_interop then
		-- if the target changed, close the previous container and open the new one
		local old_ref = self.handle:getObject()
		if old_ref ~= nil and old_ref ~= ref then
			self:ac_try_to_close(old_ref)
		end
		-- make sure the animated containers config lets us open this container
		-- and that there are no traps or locks
		if not self.ac_ever_opened and ac_cfg.open >= ac_defns.open.on_sight and not self.trap and not self.lock_lvl then
			log("trying to AC open container with level: %s", ac_defns.open.on_sight)
			-- politely ask animated containers to open the container
			self.ac_ever_opened = ac_interop.try_to_open(ref)
		end
	end

	self.handle = tes3.makeSafeObjectHandle(ref)
	log("updated lock info! trap = %s, lock_lvl = %s", self.trap, self.lock_lvl)
end

---@param selected_item herbert.MQL.Item.Physical? Item to do the action on
---@param action herbert.MQL.Action
---@return boolean successful
function Inanimate:do_action(selected_item, action)
	log("doing inanimate container action! action = %s", action)
	if self.lock_lvl then
		tes3.messageBox "This container is locked!"
		return false
	end

	local ty = action.ty

	if self.trap then
		if ty >= 3 then
			tes3.messageBox "This container is trapped!"
			return false
		end
		-- remove the trap
		local ref = self.handle:getObject() ---@type tes3reference
		local lock_node = ref.lockNode
		tes3.cast { reference = ref, target = tes3.player, spell = self.trap }
		lock_node.trap = nil
		self.trap = false
		event.trigger(EVENT_IDS.title_updated, { container = self }, { filter = self.cls_name })
		return true
	end



	local ref = self.handle:getObject()

	if ty == 1 then -- take one
		if not selected_item then
			tes3.messageBox "There is nothing to take!"
			return false
		end
		if cfg.sneak_to_steal and self.owner and not tes3.mobilePlayer.isSneaking then
			tes3.messageBox "You aren't sneaking!"
			return false
		end

		local res, err_code = self:can_take_item(selected_item)
		if res == 0 then
			if err_code then
				if err_code == defns.can_take_err_codes.TRAPPED then
					tes3.messageBox("This container is trapped!")
				elseif err_code == defns.can_take_err_codes.LOCKED then
					tes3.messageBox("This container is locked!")
				else
					log:error("unsuported error code received: %s", err_code)
				end
			end
			return false
		elseif res == -1 then
			return false
		else
			local to_take = self:get_num_to_take(selected_item, false, action.modifier_held)
			local taken = self:take_item(selected_item, to_take, false)

			if taken > 0 and action.equip_modifier_held then
				tes3ui.forcePlayerInventoryUpdate()
				local result = tes3.mobilePlayer:equip { item = selected_item.object, itemData = selected_item.data }
				log("tried to equip %s using method. result = %s", selected_item, result)
			end
			log("took %s %s", taken, selected_item.object.name)
			log("\tamount remaining: %s", selected_item.count)
			local severity = (selected_item.count == 0) and 2 or 1
			log("\tcalling items changed event with severity = %s", severity)
			event.trigger(
				EVENT_IDS.container_items_changed,
				{ container = self, severity = severity }, -- payload
				{ filter = self.cls_name }
			)


			common.ensure_not_empty(self)

			return taken > 0
		end
	elseif ty == 2 then -- take all
		if not selected_item then
			tes3.messageBox "There is nothing to take!"
			return false
		end

		if cfg.sneak_to_steal and self.owner and not tes3.mobilePlayer.isSneaking then
			tes3.messageBox "You aren't sneaking!"
			return false
		end


		local total_taken = 0
		local min_ratio = cfg.reg.take_all_min_ratio
		for _, item in ipairs(self.items) do
			if self:can_take_item(item) == 1
				and min_ratio == 0 or common.value_weight_ratio(item) > min_ratio
			then
				local num = self:get_num_to_take(item, true, action.modifier_held)
				if num > 0 then
					total_taken = total_taken + self:take_item(item, num, true)
				end
			end
		end
		if total_taken > 0 then
			tes3.playItemPickupSound { item = selected_item.object, pickup = true }
			event.trigger(
				EVENT_IDS.container_items_changed,
				{ container = self, severity = 2 },
				{ filter = self.cls_name }
			)
		end
		if cfg.UI.show_msgbox then
			local msg = total_taken == 0 and "There was nothing you wanted to take."
				or fmt("You took %i items.", total_taken)
			tes3.messageBox(msg)
		end

		common.ensure_not_empty(self)

		return true
	elseif ty == 3 then -- open
		if action.modifier_held then
			log("remaking items and switching modes")
			common.play_switch_sound()
			self.taking = not self.taking
			self:make_items()
			event.trigger(EVENT_IDS.title_updated, { container = self }, { filter = self.cls_name })
		else
			if ac_interop then
				ac_interop.skip_next_activation()
			end
			tes3.player:activate(ref)
		end

		return true
	else -- undo
		-- nothing to undo
		if #self.history == 0 then
			return true
		end

		local entry = self.history[#self.history] -- takes the last one
		local item = entry.item

		-- try to actually return it, and keep track of how many were actually returned
		local to = item.box_handle:getObject()
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
			EVENT_IDS.container_item_returned,
			{ container = self, item = item, num_returned = num_returned },
			{ filter = self.cls_name }
		)

		return true
	end
end

--- Gets the action labels, depending on the context
---@param item herbert.MQL.Item.Physical? The item to generate action names for.
---@param modifier_held boolean Is the modifier key pressed?
---@param equip_modifier_held boolean Is the equip modifier key pressed?
---@return string[]
function Inanimate:get_action_names(item, modifier_held, equip_modifier_held)
	local take_verb, take_all_verb

	if equip_modifier_held then
		take_verb = "Equip"

		if cfg.reg.equip_modifier_take_all_enabled then
			take_all_verb = "Equip"
		else
			take_all_verb = not self.taking and "Store" or self.owner and "Steal" or "Take"
		end
	else
		take_verb = not self.taking and "Store" or self.owner and "Steal" or "Take"
		take_all_verb = take_verb
	end
	local count
	if item and self:can_take_item(item) == 1 then
		count = self:get_num_to_take(item, false, modifier_held)
	end

	local take_label = count and fmt("%s %s", take_verb, count) or take_verb
	local take_all_label = take_all_verb .. " All"
	local open_label = modifier_held and "Switch" or "Open"

	return { take_label, take_all_label, open_label }
end

---@protected
---@param item herbert.MQL.Item.Physical the item to take
---@param num_to_take integer mode we're taking the item in
---@param bulk boolean are we taking a bunch of things?
---@return integer num_taken
---@return string? reason
function Inanimate:take_item(item, num_to_take, bulk)
	log("about to take %s", item)

	local from, to
	if self.taking then
		from, to = item.box_handle:getObject(), tes3.player
	else
		from, to = tes3.player, item.box_handle:getObject()
	end
	local num_taken = common.transfer_item(from, to, item, num_to_take, bulk)
	if num_taken == 0 then
		log:error("tried to take %s %s, but couldn't", num_to_take, item)
	end
	-- do the crime
	if self.owner then
		if self.taking then
			tes3.triggerCrime { type = tes3.crimeType.theft, victim = self.owner, value = item.value * num_taken }
			tes3.setItemIsStolen { item = item.object, from = self.owner }
		else
			tes3.triggerCrime { type = tes3.crimeType.trespass, victim = self.owner }
		end
	end

	item.count = item.count - num_taken
	table.insert(self.history, { item = item, num_removed = num_taken })

	log("took %s %s", num_taken, item)

	return num_taken
end

function Inanimate:make_items()
	log("calling internal make items function. self = %s", self)
	if self.disabled then return end
	self.history = {}
	self.items = {}
	self.history = {}
	self.relevant_handles = {}


	if self.taking then -- if we are taking items from the container
		-- add the stuff from the primary container
		local ref = self.handle:getObject()
		log("making items for %s!", ref)

		if not ref then return end
		log:trace("adding items from the container we are looking at. its items are: %s", function()
			local ids = {}
			for _, item in pairs(ref.object.inventory) do
				table.insert(ids, item.object.id)
			end
			return inspect.inspect(ids)
		end)
		common.add_items_to_list(self, ref)
		local max_distance = cfg.reg.sn_dist

		if max_distance > 0.2 then
			log:trace("\tsearching nearby containers")

			local pos = ref.position
			local owner = self.owner

			local root_id = ref.baseObject.id:lower()

			-- numbers can determine what the container looks like, so it's good to filter by the numbers
			local first_num_start = root_id:find("_?%d")

			if first_num_start then
				root_id = root_id:sub(1, first_num_start - 1)
			end
			local root_id_len = root_id:len()

			local player_ref = tes3.player
			local test_los = cfg.reg.sn_test_line_of_sight

			for container_ref in tes3.player.cell:iterateReferences(tes3.objectType.container) do
				-- distance check
				local container_pos = container_ref.position
				if pos:distanceXY(container_pos) > max_distance or pos:heightDifference(container_ref.position) > max_distance then
					goto next_container
				end
				log:trace("\t\tchecking if we can add items from %s", container_ref)

				-- do the owned by check and scripted container check
				if owner and owner ~= tes3.getOwner { reference = container_ref } -- owned item check
					or container_ref:testActionFlag(tes3.actionFlag.useEnabled) == false -- skip scripted
					or container_ref == ref                                -- dont add the same container twice
					or container_ref.baseObject.id:sub(1, root_id_len):lower() ~= root_id -- make sure the object IDs are similar
					or contents_of_ref_hidden(container_ref)
				then
					goto next_container
				end

				if test_los and not tes3.testLineOfSight { reference1 = player_ref, reference2 = container_ref } then
					log("there's no line of sight between the player and %s", container_ref)
					goto next_container
				end
				log:trace("\t\t\twe can add items from %s!", container_ref)
				-- shoot out a line from the current position, pointed at the prospective container
				-- and then see if it hits any walls. if it does, then dont add the items

				log:trace("\t\t\t%s passed all checks", container_ref.object.name)

				common.add_items_to_list(self, container_ref)
				::next_container::
			end
		end

		log("made items: %s", self.items)
	else -- we are placing things into the container
		table.insert(self.relevant_handles, self.handle)
		local banned_types = {
			[tes3.objectType.book] = not cfg.inanimate.placing.allow_books,
			[tes3.objectType.ingredient] = not cfg.inanimate.placing.allow_ingredients,
		}
		local equipped_datas = {}
		for i, stack in ipairs(tes3.player.object.equipment) do
			equipped_datas[i] = stack.itemData
		end

		local tbl_insert = table.insert
		local items = self.items

		local pr_handle = tes3.makeSafeObjectHandle(tes3.player)
		log("making items for %s!", pr_handle)

		local min_weight = cfg.inanimate.placing.min_weight

		for _, stack in ipairs(tes3.player.object.inventory.items) do
			local obj, count = stack.object, stack.count
			---@cast obj -tes3leveledItem
			if banned_types[obj.objectType] or obj.isGold or obj.weight < min_weight then
				goto next_stack
			end

			for _, data in ipairs(stack.variables or {}) do
				count = count - 1
				local index = table.find(equipped_datas, data)
				if index then
					equipped_datas[index] = nil
				else
					tbl_insert(items,
						{ box_handle = pr_handle, object = obj, data = data, count = 1, value = tes3.getValue { item = obj, itemData = data } })
				end
			end
			if count > 0 then
				tbl_insert(items,
					{ box_handle = pr_handle, object = obj, count = count, value = tes3.getValue { item = obj } })
			end
			::next_stack::
		end
	end

	do -- sort items
		local sort_items = cfg.UI.sort_items
		if sort_items == defns.sort_items.dont then return end

		local comp

		if sort_items == defns.sort_items.weight then
			comp = common.item_sorters.weight_comp
			-- all other sorting methods depend on item price, so we shouldn't do them
			-- if we don't know the price of stuff
		elseif common.bg_cfg and tes3.mobilePlayer.mercantile.current < common.bg_cfg.knowsPrice then
			return
		elseif sort_items == defns.sort_items.value_weight_ratio then
			comp = common.item_sorters.value_weight_ratio
		else
			comp = common.item_sorters.value_comp
		end

		if not self.taking or not cfg.inanimate.placing.reverse_sort then
			local old_comp = comp
			comp = function(a, b) return old_comp(b, a) end
		end
		table.sort(self.items, comp)
	end

	event.trigger(
		EVENT_IDS.container_items_changed,
		{ container = self, severity = 2 },
		{ filter = self.cls_name }
	)
end

--- Animated Containers compatibility.
--- Tries to close the container if possible.
--- This method assumes that AC interop is enabled
---@param ref tes3reference
function Inanimate:ac_try_to_close(ref)
	-- bail if the reference doesnt exist, or we should never close containers,
	-- or the container is empty and we aren't supposed to close empty containers
	if not ref
		or ac_cfg.close == ac_defns.close.never
		or not ac_cfg.auto_close_if_empty and #ref.object.inventory.items == 0
	then
		return
	end

	local use_cfg = (ac_cfg.close == ac_defns.close.use_ac_cfg)
	log("trying to close container with use_cfg = %s. container = %s", use_cfg, ref)

	ac_interop.try_to_close(ref, use_cfg)
	self.ac_ever_opened = false
end

---Checks if the item at the given index can be taken
---@param item herbert.MQL.Item.Physical
---@return -1|0|1 val Whether we can take the item
---@return herbert.MQL.defns.can_take_err_code? err_code Only returned if `val == 0`. This provides information about why an item should be greyed out.
function Inanimate:can_take_item(item)
	-- check if container is locked / trapped
	if item.count <= 0 then
		return -1
	end

	local box = item.box_handle:getObject()
	if box.lockNode then
		if box.lockNode.trap then
			return 0, defns.can_take_err_codes.TRAPPED
		end
		if box.lockNode.locked then
			return 0, defns.can_take_err_codes.LOCKED
		end
	end
	if not self.taking then
		local container = self.handle:getObject().object
		local cur_weight = container.inventory:calculateWeight()
		log("container: %s. container.capacity: %s.", container, container.capacity)
		local remaining_capacity = container.capacity - cur_weight
		-- local remaining_capacity = tes3container.capacity - cur_weight
		if item.object.weight > remaining_capacity then
			return 0, defns.can_take_err_codes.DOESNT_FIT
		end
	end
	return 1
end

--- Checks if a tooltip can be made for this item.
---@param self herbert.MQL.Container.Physical
---@param _item herbert.MQL.Item
---@return boolean
function Inanimate:can_make_item_tooltip(_item)
	if self.disabled or not cfg.UI.show_tooltips then
		return false
	end
	local ref = self.handle:getObject()
	if ref and not contents_of_ref_hidden(self.handle:getObject()) then
		return true
	end
	return false
end

function Inanimate:get_num_to_take(item, bulk, modifier_pressed)
	log("getting num to take with %s %s %s", item, bulk, modifier_pressed)
	local amount = Physical_Container.get_num_to_take(self, item, bulk, modifier_pressed)

	if not self.taking and amount > 1 then
		local container = self.handle:getObject().object
		local cur_weight = container.inventory:calculateWeight()
		local max_to_place = math.floor((container.capacity - cur_weight) / item.object.weight)
		amount = math.min(max_to_place, amount)
	end
	return amount
end

---@return string[] label
function Inanimate:get_subtitles()
	return {
		self.owner and fmt("Owned by: %s", self.owner.name) or nil,
		self.lock_lvl and fmt("Lock level: %s", self.lock_lvl) or nil,
		self.trap and "Trapped" or nil
	}
end

function Inanimate:get_status_bar_text()
	if not self.taking then
		return "Storing Items."
	end
end

function Inanimate:disable()
	self.disabled = true
end

function Inanimate:destruct()
	log:trace("container is self destructing for some reason.")
	if #self.history > 0 then
		tes3ui.forcePlayerInventoryUpdate()
	end
	if ac_interop then
		local ref = self.handle:getObject()
		if ref then
			self:ac_try_to_close(ref)
		end
	end
end

---@param e herbert.MQL.events.pick_container
register_event(defns.EVENT_IDS.pick_container, function(e)
	if not cfg.inanimate.enable then return end

	if e.container_cls ~= nil
		or e.block
		or e.is_organic
		or e.scripted
		or e.ref.isDead ~= nil
		or not tes3.mobilePlayer or tes3.mobilePlayer.attackDisabled
	then
		return
	end

	e.container_cls = Inanimate
	log("setting container class to inanimate!")
end, { filter = tes3.objectType.container })


Inanimate.get_title = Physical_Container.get_title
Inanimate.format_item_name = Physical_Container.format_item_name
Inanimate.format_item_value = Physical_Container.format_item_value
Inanimate.format_item_weight = Physical_Container.format_item_weight
Inanimate.make_item_tooltip = Physical_Container.make_item_tooltip
Inanimate.get_item_bg_color = Physical_Container.get_item_bg_color
Inanimate.get_item_icon_path = Physical_Container.get_item_icon_path


common.assert_interface_is_implemented(Inanimate)



return Inanimate
