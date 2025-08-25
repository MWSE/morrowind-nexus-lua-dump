local fmt = string.format
-- living container, ensures that `Services` will die as soon as we start sneaking or the target becomes nil
local Physical_Container = require("herbert100.more quickloot.containers.abstract.Physical")
local config = require "herbert100.more quickloot.config"
local log = mwse.Logger.new()


local defns = require "herbert100.more quickloot.defns"
local ERR_CODES = defns.can_take_err_codes

---@type nil|fun(sale_value: integer, offer: integer?)
local award_xp = config.compat.bxp and include("herbert100.barter xp overhaul.mod").award_barter_xp or nil
local common = require("herbert100.more quickloot.common")

-- local bit = require("bit")



local tbl_insert = table.insert


---@type table<tes3.objectType, integer>
local OBJ_TYPE_TO_MERCHANT_FLAG = {
	[tes3.objectType.weapon] = 0x1,
	[tes3.objectType.armor] = 0x2,
	[tes3.objectType.clothing] = 0x4,
	[tes3.objectType.book] = 0x8,
	[tes3.objectType.ingredient] = 0x10,
	[tes3.objectType.lockpick] = 0x20,
	[tes3.objectType.probe] = 0x40,
	[tes3.objectType.light] = 0x80,
	[tes3.objectType.apparatus] = 0x100,
	[tes3.objectType.repairItem] = 0x200,
	[tes3.objectType.miscItem] = 0x400,
	[tes3.objectType.enchantment] = 0x1000,
	[tes3.objectType.alchemy] = 0x2000,
}

-- local BARTER_FLAG = bit.bor(table.unpack(table.values(OBJ_TYPE_TO_MERCHANT_FLAG)))


---@class herbert.MQL.Container.Barter : herbert.MQL.Container.Physical
---@field items herbert.MQL.Item.Physical[]
---@field history herbert.MQL.Container.history.entry<herbert.MQL.Item.Physical>[]
---@field allowed_obj_types table<tes3.objectType, boolean>
---@field gold_stack integer
---@field is_buying boolean
---@field timer mwseTimer Routinely checks to see if this container should be closed.
---@field merchant_isnt_smuggler boolean
local Barter = { cls_name = "Barter" }

local meta = { __index = Barter, __tostring = Physical_Container.__tostring }

---comments
---@param ref tes3reference
---@return herbert.MQL.Container.Barter
function Barter.new(ref)
	---@type herbert.MQL.Container.Barter
	local obj = setmetatable({
		handle = tes3.makeSafeObjectHandle(ref),
		items = {},
		history = {},
		relevant_handles = {},
		disabled = false,
		gold_stack = 0,
		is_buying = config.barter.start_buying,
		allowed_obj_types = {},
		-- if buying game isn't installed, then, in a sense, every merchant is a smuggler.
		-- if the merchant has 0 alarm, then they're functionally a smuggler
		merchant_isnt_smuggler = common.bg_cfg and not common.bg_cfg.smuggler[ref.baseObject.id:lower()] and
			ref.mobile.alarm ~= 0
	}, meta)

	obj.timer = common.services.make_timer_for_service(obj)

	local merchant_flags = ref.object.aiConfig.merchantFlags
	for obj_type, flag in pairs(OBJ_TYPE_TO_MERCHANT_FLAG) do
		obj.allowed_obj_types[obj_type] = (bit.band(flag, merchant_flags) ~= 0)
	end

	obj:make_items()

	return obj
end

function Barter:destruct()
	self.timer:cancel()
end

function Barter:update_item_prices()
	local merchant = self.handle:getObject().mobile
	---@cast merchant tes3mobileNPC
	for _, item in ipairs(self.items) do
		item.value = tes3.calculatePrice { merchant = merchant, bartering = true, buying = self.is_buying, object = item.object, itemData = item.data }
	end
end

function Barter:can_enable(ref)
	if ref ~= self.handle:getObject() then
		return -1
	end
	-- make sure at least one item can be shown.
	if common.at_least_one_item_valid(self) then
		return 1
	else
		return 0, "Empty!"
	end
end

function Barter:enable(ref)
	self.disabled = false
end

function Barter:disable()
	self.disabled = true
end

function Barter:get_subtitles()
	local ref = self.handle:getObject()
	local disposition = ref.object.disposition or ref.object.baseDisposition or ref.baseObject.baseDisposition

	return {
		self.is_buying and "You are Buying" or "You are Selling",
		disposition and "Disposition: " .. disposition or nil
	}
end

function Barter:get_status_bar_text()
	local signed_stack = self.is_buying and self.gold_stack or -self.gold_stack
	local ref = self.handle:getObject()
	local cart_size = 0
	for _, entry in ipairs(self.history) do
		cart_size = cart_size + entry.num_removed
	end
	local cart_gold_value = ""
	if config.barter.show_cart_gold_value then
		cart_gold_value = fmt(" (%s Gold)", self.gold_stack)
	end
	return fmt("Your Gold: %s  |  %s's Gold: %s\nCart Size: %s Item%s%s",
		tes3.getPlayerGold() - signed_stack,
		ref.object.name,
		ref.mobile.barterGold + signed_stack,
		cart_size,
		cart_size == 1 and "" or "s",
		cart_gold_value
	)
end

function Barter:get_buyer_gold()
	local raw_gold = self.is_buying and tes3.getPlayerGold() or self.handle:getObject().mobile.barterGold
	return raw_gold - self.gold_stack
end

--- internal mechanism for takign a certain number of copies of an item
function Barter:undo()
	if #self.history == 0 then return end


	local entry = table.remove(self.history, #self.history)
	local item = entry.item
	local num_removed = entry.num_removed

	-- update the item count to reflect the newly returned items
	item.count = item.count + num_removed

	-- add some gold, and update item statuses to reflect our new gold
	self.gold_stack = self.gold_stack - item.value * num_removed

	-- let everyone know we returned an item
	event.trigger(
		defns.EVENT_IDS.container_item_returned,
		{ container = self, item = item, num_returned = num_removed, claim = false },
		{ filter = self.cls_name }
	)
end

--- Determines how many of a given item should be taken.
--- should only be called if `item.count >= 1` and we can take the item
---@param item herbert.MQL.Item the item to take
---@param _ false are we doing a batch take? (this is impossible in the current implementation)
---@param modifier_pressed boolean is the modifier key pressed?
---@return integer num_to_take
function Barter:get_num_to_take(item, _, modifier_pressed)
	if modifier_pressed then -- try to take as many as we can
		local amount = math.floor(self:get_buyer_gold() / item.value)
		return math.clamp(amount, 1, item.count)
	else -- modifier key isn't pressed, so only try to take one
		return 1
	end
end

---Dislpays a tes3messagebox with a message corresponding to an error code
---@param obj herbert.MQL.Container.Barter
---@param err_code herbert.MQL.defns.can_take_err_code?
local function display_err_msg(obj, err_code)
	if not err_code then return end
	-- check if the item is equipped
	if err_code == ERR_CODES.EQUIPPED then
		tes3.messageBox "This item is equipped!"
	elseif err_code == ERR_CODES.CONTRABAND then
		tes3.messageBox "This item is contraband!"
	elseif err_code == ERR_CODES.STOLEN then
		tes3.messageBox "This item is stolen!"
	elseif err_code == ERR_CODES.NOT_ENOUGH_GOLD then
		if obj.is_buying then
			tes3.messageBox "You don't have enough gold!"
		else
			tes3.messageBox(fmt("%s doesn't have enough gold!", obj.handle:getObject().object.name))
		end
	end
end

--- Takes an item.
--- This method assumes that the item can be taken. and that `num_to_take` is a positive integer.
---@param item herbert.MQL.Item the item to take
---@param num_to_take integer The number of items being taken. This must be a positive integer.
---@param bulk boolean are we taking a bunch of things?
---@return integer num_taken the number of things that were actually taken.
function Barter:take_item(item, num_to_take, bulk)
	self.gold_stack = self.gold_stack + item.value * num_to_take
	log("added %s %s to the cart", num_to_take, item)

	item.count = item.count - num_to_take
	table.insert(self.history, { item = item, num_removed = num_to_take })

	return num_to_take
end

---@param selected_item herbert.MQL.Item.Physical?
---@param action herbert.MQL.Action
---@return boolean
function Barter:do_action(selected_item, action)
	local ref = self.handle:getObject()
	local ty = action.ty
	if not ref then
		tes3.messageBox "Couldn't find merchant!"
		return false
	end


	if ty == 1 then -- take one
		if not selected_item then
			tes3.messageBox(self.is_buying and "Nothing to buy!" or "Nothing to sell!")
			return false
		end
		local res, err_code = self:can_take_item(selected_item)
		if res ~= 1 then
			display_err_msg(self, err_code)
			return true
		end
		local num_to_take = self:get_num_to_take(selected_item, false, action.modifier_held)
		if num_to_take == 0 then
			return false
		end

		self:take_item(selected_item, num_to_take, action.modifier_held)
		local severity = (selected_item.count == 0) and 2 or 1
		event.trigger(
			defns.EVENT_IDS.container_items_changed,
			{ container = self, severity = severity }, -- payload
			{ filter = self.cls_name }
		)
		event.trigger(
			defns.EVENT_IDS.container_status_text_updated,
			{ container = self }, -- payload
			{ filter = self.cls_name }
		)

		return true
	elseif ty == 2 then -- take all
		log("doing take all with modifier pressed = %s", action.modifier_held)
		if action.modifier_held then
			self.is_buying = not self.is_buying
			self:make_items()
			event.trigger(
				defns.EVENT_IDS.title_updated,
				{ container = self }, -- payload
				{ filter = self.cls_name }
			)

			return true
		end

		if not selected_item then
			tes3.messageBox(self.is_buying and "Nothing to buy!" or "Nothing to sell!")
			return false
		end




		-- The totla amount of gold exchanged.
		-- This will always be less than or equal to `gold_stack`.
		-- It's computed separately because it's possible that there's an error buying/selling an item.
		-- And it would be bad to delete the player's hard earned gold without giving them an item in exchange.
		local total_cost = 0
		local pr = tes3.player
		local is_buying = self.is_buying

		-- TODO: make this setting also do the transfer/item price recalculation inplace
		-- also recalculate item values after buying/selling stuff
		local auto_minmax = config.barter.automate_disposition_minmaxing
		local total_taken = 0
		for _, entry in ipairs(self.history) do
			local item = entry.item
			local num_taken
			if is_buying then
				local from = item.box_handle:getObject()
				num_taken = common.transfer_item(from, pr, item, entry.num_removed, true)
				-- if num_taken > 0 and action.equip_modifier_held then
				-- 	tes3.equip { item = item.object, reference = tes3.player, itemData = item.data }
				-- end
			else
				num_taken = common.transfer_item(pr, ref, item, entry.num_removed, true)
			end
			-- update the count to reflect the actual number of items exchanged

			item.count = item.count + entry.num_removed - num_taken

			total_cost = total_cost + item.value * num_taken
			total_taken = total_taken + num_taken
		end

		self.gold_stack = 0
		self.history = {}
		if total_cost == 0 then
			return true
		end

		if award_xp ~= nil and config.barter.award_xp then
			award_xp(total_cost)
		end
		local merchant = ref.mobile --[[@as tes3mobileNPC]]
		if is_buying then
			tes3.payMerchant { merchant = merchant, cost = total_cost }
			tes3.playSound { sound = "Item Gold Down", reference = tes3.player }
		else
			tes3.payMerchant { merchant = merchant, cost = -total_cost }
			tes3.playSound { sound = "Item Gold Up", reference = tes3.player }
		end
		-- update the disposition
		local disposition_bonus = tes3.findGMST(tes3.gmst.iBarterSuccessDisposition).value --[[@as number]]

		if auto_minmax then
			disposition_bonus = disposition_bonus * total_taken
		end
		tes3.modDisposition { reference = ref, value = disposition_bonus }

		event.trigger(
			defns.EVENT_IDS.container_status_text_updated,
			{ container = self }, -- payload
			{ filter = self.cls_name }
		)
		event.trigger(
			defns.EVENT_IDS.title_updated,
			{ container = self }, -- payload
			{ filter = self.cls_name }
		)

		tes3ui.forcePlayerInventoryUpdate()

		return true
	elseif ty == 3 then -- open
		if action.modifier_held then
			common.services.switch_to_next_service(Barter, ref)
		else
			tes3.player:activate(ref)
		end

		return true
	else -- undo
		if #self.history == 0 then
			return true
		end


		local entry = table.remove(self.history, #self.history)
		local item = entry.item
		local num_removed = entry.num_removed

		-- update the item count to reflect the newly returned items
		item.count = item.count + num_removed

		-- add some gold, and update item statuses to reflect our new gold
		self.gold_stack = self.gold_stack - item.value * num_removed

		-- let everyone know we returned an item
		event.trigger(
			defns.EVENT_IDS.container_item_returned,
			{ container = self, item = item, num_returned = num_removed, claim = false },
			{ filter = self.cls_name }
		)
		-- update the status bar
		event.trigger(
			defns.EVENT_IDS.container_status_text_updated,
			{ container = self }, -- payload
			{ filter = self.cls_name }
		)
		return true
	end
end

local WEAPON, CLOTHING, ARMOR = tes3.objectType.weapon, tes3.objectType.clothing, tes3.objectType.armor

--- Add all the items from the merchants inventory (if buying) or the players inventory (if selling)
---@param self herbert.MQL.Container.Barter
local function add_npc_items(self)
	local is_selling = not self.is_buying

	local merchant_ref = self.handle:getObject()
	if not merchant_ref or not tes3.player then return end

	local seller_ref = is_selling and tes3.player or merchant_ref

	-- local seller_handle = tes3.makeSafeObjectHandle(seller_ref)


	local allowed_types = self.allowed_obj_types

	if is_selling then
		allowed_types = table.copy(allowed_types)

		allowed_types[tes3.objectType.book] = allowed_types[tes3.objectType.book] and config.barter.selling.allow_books
		allowed_types[tes3.objectType.ingredient] = allowed_types[tes3.objectType.ingredient] and
			config.barter.selling.allow_ingredients
	end

	local equipped_cfg = config.barter.equipped
	local weapon_types = equipped_cfg.weapon_types
	local armor_slots = equipped_cfg.armor_slots
	local clothing_slots = equipped_cfg.clothing_slots
	local show_unavailable = equipped_cfg.show_unavailable

	-- This is passed to `tes3.calculatePrice`.
	local merchant = merchant_ref.mobile --[[@as tes3mobileNPC]]
	if not merchant then return end



	local equipped_array = {}
	for _, stack in ipairs(seller_ref.object.equipment) do
		table.insert(equipped_array, stack.itemData)
	end

	---@type herbert.MQL.Item.Physical[]
	local items = self.items
	---@cast items herbert.MQL.Item.Physical[]

	local handle = tes3.makeSafeObjectHandle(seller_ref)

	for _, stack in ipairs(seller_ref.object.inventory.items) do
		local obj, count = stack.object, stack.count
		local obj_type = obj.objectType

		if obj.isGold or obj.isKey or not allowed_types[obj_type] then
			goto next_stack
		end

		-- log("trying to add %s", obj.id)
		-- log:trace("\tselling: %s", is_selling)
		-- log:trace("\tvalue: %s", tes3.getValue{item=obj})
		-- log:trace("\tprice: %s", tes3.calculatePrice{object=obj, count=count, bartering=true, selling=is_selling, merchant=merchant})
		-- log:trace("\tprice: %s", tes3.calculatePrice{object=obj, merchant=merchant, bartering=true,buying=not is_selling})

		for _, data in ipairs(stack.variables or {}) do
			count = count - 1
			local equipped_index = table.find(equipped_array, data)
			-- happy path
			if not equipped_index then
				tbl_insert(items, {
					object = obj,
					box_handle = handle,
					data = data,
					count = 1,
					value = tes3.calculatePrice { object = obj, itemData = data, bartering = true, selling = is_selling, merchant = merchant }
				})
			else
				-- log("found equipped item! %s", obj.name)
				equipped_array[equipped_index] = nil
				local giveit = false
				if is_selling then
					-- do nothing
				elseif obj_type == WEAPON then ---@cast obj tes3weapon
					giveit = weapon_types[obj.type]
				elseif obj_type == ARMOR then ---@cast obj tes3armor
					giveit = armor_slots[obj.slot]
				elseif obj_type == CLOTHING then ---@cast obj tes3clothing
					giveit = clothing_slots[obj.slot]
				end
				if giveit == true then
					-- add the item, but dont mark it as equipped
					tbl_insert(items, {
						object = obj,
						box_handle = handle,
						data = data,
						count = 1,
						value = tes3.calculatePrice { object = obj, itemData = data, bartering = true, merchant = merchant, selling = is_selling }
					})
				elseif show_unavailable then
					-- add the item, but mark it as equipped
					tbl_insert(items, {
						object = obj,
						box_handle = handle,
						data = data,
						equipped = true,
						count = 1,
						-- only compute the value if we are selling
						value = is_selling and
							tes3.calculatePrice { object = obj, itemData = data, bartering = true, merchant = merchant, selling = is_selling }
							or 0
					})
				end
			end
		end
		if count > 0 then
			tbl_insert(items, {
				object = obj,
				box_handle = handle,
				count = count,
				value = tes3.calculatePrice { object = obj, count = count, bartering = true, selling = is_selling, merchant = merchant }
			})
		end
		::next_stack::
	end
end

-- add_npc_items = hlib.timeit(add_npc_items, "add_npc_items")

-- local gettime = require "socket".gettime
function Barter:make_items()
	-- local start = gettime()
	self.gold_stack = 0
	self.history = {}
	self.items = {}
	log("making barter items")

	local ref = self.handle:getObject()
	if not ref then return end

	add_npc_items(self)

	-- if we're buying stuff, add in the items stored in nearby containers
	-- this is necessary because NPCs dont always store their entire shop inventory on their person.
	if self.is_buying then
		local allowed_types = self.allowed_obj_types

		local items = self.items

		local merchant_bobj = ref.baseObject
		local merchant_mob = ref.mobile --[[@as tes3mobileNPC]]

		for c_ref in tes3.player.cell:iterateReferences(tes3.objectType.container, false) do
			if tes3.getOwner { reference = c_ref } ~= merchant_bobj then
				goto next_ref
			end
			c_ref:clone()
			local handle = tes3.makeSafeObjectHandle(c_ref)

			for _, stack in ipairs(c_ref.object.inventory.items) do
				local obj, count = stack.object, stack.count
				-- log("trying to add %s", obj.id)
				-- log:trace("\tselling: %s", false)
				-- log:trace("\tvalue: %s", tes3.getValue{item=obj})
				-- log:trace("\tprice: %s", tes3.calculatePrice{object=obj, count=count, bartering=true, buying=true, merchant=merchant_mob})
				-- log:trace("\tprice: %s", tes3.calculatePrice{object=obj, merchant=merchant_mob, bartering=true,buying=true})
				if not allowed_types[obj.objectType] or obj.isGold then
					-- log("skipping %s because it isn't an allowed type", obj)
					goto next_stack
				end


				for _, data in ipairs(stack.variables or {}) do
					count = count - 1
					tbl_insert(items, {
						object = obj,
						box_handle = handle,
						count = 1,
						data = data,
						value = tes3.calculatePrice {
							merchant = merchant_mob,
							bartering = true,
							buying = true,
							itemData = data,
							object = obj,
						}
					})
				end
				if count > 0 then
					tbl_insert(items, {
						object = obj,
						box_handle = handle,
						count = count,
						value = tes3.calculatePrice {
							merchant = merchant_mob,
							bartering = true,
							buying = true,
							object = obj,
						}
					})
				end
				::next_stack::
			end
			::next_ref::
		end
	end

	-- local end_ = gettime()
	-- log("barter.make_items: internal item making took %s", end_ - start)

	do -- sort the items
		local sort_items = config.UI.sort_items
		if sort_items == defns.sort_items.dont then return end

		if sort_items == defns.sort_items.weight then
			table.sort(self.items, common.item_sorters.weight_comp)
			return
		end

		if config.compat.bg and tes3.mobilePlayer.mercantile.current < common.bg_cfg.knowsPrice then
			return
		end

		if sort_items == defns.sort_items.value_weight_ratio then
			table.sort(self.items, common.item_sorters.value_weight_ratio)
		else
			table.sort(self.items, common.item_sorters.value_comp)
		end
	end
	event.trigger(
		defns.EVENT_IDS.container_items_changed,
		{ container = self, severity = 2 }, -- payload
		{ filter = self.cls_name }
	)


	-- local end2 = gettime()
	-- log("barter.make_items: everythign else took %s", end2 - end_)
end

--- Gets the action labels, depending on the context
---@param item herbert.MQL.Item? The item to generate action names for.
---@param modifier_pressed boolean Is the modifier key pressed?
---@return string[]
function Barter:get_action_names(item, modifier_pressed, equip_modifier_held)
	local num_to_take = item and self:get_num_to_take(item, false, modifier_pressed) or 0
	local take_label
	if self.is_buying then
		take_label = num_to_take > 0 and fmt("Buy %s", num_to_take) or "Buy"
	else
		take_label = num_to_take > 0 and fmt("Sell %s", num_to_take) or "Sell"
	end
	if modifier_pressed then
		local next_service = common.services.get_next_service(Barter, assert(self.handle:getObject()))
		return {
			take_label,
			self.is_buying and "Start Selling" or "Start Buying",
			next_service and next_service.display_name or false
		}
	else
		return {
			take_label,
			"Confirm",
			"Talk"
		}
	end
end

-- =============================================================================
-- ITEM METHODS
-- =============================================================================

---Checks if the item at the given index can be taken
---@param item herbert.MQL.Item.Physical
---@return -1|0|1 val Whether we can take the item
---@return herbert.MQL.defns.can_take_err_code? err_code Only returned if `val == 0`. This provides information about why an item should be greyed out.
function Barter:can_take_item(item)
	-- check if the item is equipped
	if item.count <= 0 then
		return -1
	elseif item.equipped then
		return 0, ERR_CODES.EQUIPPED
	elseif self.merchant_isnt_smuggler and common.bg_cfg.forbidden[item.object.id] then
		return 0, ERR_CODES.CONTRABAND
	elseif table.find(item.object.stolenList, self.handle:getObject().baseObject) then
		log("found a stolen object! %s was stolen from %s",
			item.object.name, self.handle:getObject().baseObject.name
		)
		return 0, ERR_CODES.STOLEN
	elseif item.value > self:get_buyer_gold() then
		if self.is_buying then
			return 0, ERR_CODES.NOT_ENOUGH_GOLD
		else
			return 0, ERR_CODES.NOT_ENOUGH_GOLD
		end
	end

	return 1
end

-- -----------------------------------------------------------------------------
-- ITEM UI METHODS
-- -----------------------------------------------------------------------------


---Gets the value of the item
---@param item herbert.MQL.Item.Physical
---@param num integer
---@return string
function Barter:format_item_value(item, num)
	local res, err_code = self:can_take_item(item)
	if err_code then
		log("formatting value of %s.\n\tcan_take returned %s, %s",
			item, res, table.find, ERR_CODES, err_code
		)
	end
	-- hide the price if the item cannot be bought (unless the reason is that we dont have enough gold)
	if res ~= 1 and err_code ~= ERR_CODES.NOT_ENOUGH_GOLD then
		return '?'
	end
	local value = item.value * num
	return value < 1000 and tostring(math.round(value, 1))
		or (math.round(value / 1000, 2) .. "k")
end

function Barter:get_title()
	local ref = assert(self.handle:getObject())
	return ref.object.name
end

Barter.format_item_name = Physical_Container.format_item_name
Barter.format_item_weight = Physical_Container.format_item_weight
Barter.get_item_bg_color = Physical_Container.get_item_bg_color
Barter.get_item_icon_path = Physical_Container.get_item_icon_path
-- Barter.get_title = Physical_Container.get_title

Barter.can_make_item_tooltip = Physical_Container.can_make_item_tooltip
Barter.make_item_tooltip = Physical_Container.make_item_tooltip




common.services.register_service {
	cls = Barter,
	display_name = "Bartering",
	filter_contexts = { tes3.dialogueFilterContext.serviceBarter },
	is_valid_for_service = function(ref)
		return config.barter.enable
			and ref.object.aiConfig.offersBartering
			and tes3.mobilePlayer and not tes3.mobilePlayer.attackDisabled
			and tes3.checkMerchantOffersService { reference = ref, context = tes3.dialogueFilterContext.serviceBarter }
			or false
	end
}



common.assert_interface_is_implemented(Barter)


-- Barter.make_items = hlib.timeit(Barter.make_items, "Barter.make_items")
-- Barter.new = hlib.timeit(Barter.new, "Barter.new")
return Barter
