local log = mwse.Logger.new()
local defns = require("herbert100.more quickloot.defns")
local cfg = require("herbert100.more quickloot.config")
local pp_cfg = cfg.pickpocket
local Physical_Container = require("herbert100.more quickloot.containers.abstract.Physical")
local EVENT_IDS = defns.EVENT_IDS
local common = require("herbert100.more quickloot.common")


local register_event = common.register_event
---@generic V
---@type fun(arr: V[], val: V, pos: integer?)
local tbl_insert = table.insert

local fmt = string.format

---@class herbert.MQL.Container.Pickpocket : herbert.MQL.Container.Physical
---@field items herbert.MQL.Item.Physical[]  the base chance you have of stealing an item
---@field private timer mwseTimer
---@field is_detected boolean whether or not the player was detected last frame
local Pickpocket = { cls_name = "Pickpocket" }

local meta = { __index = Pickpocket, __tostring = Physical_Container.__tostring }

---make a new one
---@param ref tes3reference
---@return herbert.MQL.Container.Pickpocket
function Pickpocket.new(ref)
	ref:clone()
	---@type herbert.MQL.Container.Pickpocket
	local obj = setmetatable({
		handle = tes3.makeSafeObjectHandle(ref),
		items = {},
		history = {},
		relevant_handles = {},
		is_detected = ref.mobile.isPlayerDetected,
		owner = ref.mobile,
		disabled = false,
		taking = true,
	}, meta)

	obj.timer = timer.start { duration = 0.1, iterations = -1, callback = function(e)
		-- shadow the variable from the outer scope to make sure it's still valid when the timer callback happens
		local ref = obj.handle:getObject()
		if ref == nil
			or ref.isDead
			or not tes3.mobilePlayer
		then
			e.timer:cancel()
			event.trigger(EVENT_IDS.container_invalidated, { container = obj }, { filter = obj.cls_name })
		elseif not tes3.mobilePlayer.isSneaking then
			e.timer:cancel()
			event.trigger(EVENT_IDS.container_invalidated, { container = obj }, { filter = obj.cls_name })
			if ref == tes3.getPlayerTarget() then
				timer.delayOneFrame(function()
					common.trigger_pick_container(ref)
				end)
			end
		else
			local new_is_detected = ref.mobile.isPlayerDetected
			if new_is_detected ~= obj.is_detected then
				obj.is_detected = new_is_detected
				event.trigger(EVENT_IDS.container_items_changed, { container = obj, severity = 2 },
					{ filter = obj.cls_name })
				event.trigger(EVENT_IDS.container_status_text_updated, { container = obj }, { filter = obj.cls_name })
			end
		end
	end }

	obj:make_items()

	return obj
end

function Pickpocket:destruct()
	self.timer:cancel()
	log:trace("container is self destructing for some reason.")
	if #self.history > 0 then
		tes3ui.forcePlayerInventoryUpdate()
	end
end

function Pickpocket:can_enable(ref)
	if ref ~= self.handle:getObject()
		or tes3.mobilePlayer == nil
		or not tes3.mobilePlayer.isSneaking
	then
		return -1
	end

	-- make sure at least one item can be shown.
	if common.at_least_one_item_valid(self) then
		return 1
	else
		return 0, "Empty!"
	end
end

function Pickpocket:enable(ref)
	self.disabled = false
end

function Pickpocket:disable()
	self.disabled = true
end

local WEAPON, CLOTHING, ARMOR = tes3.objectType.weapon, tes3.objectType.clothing, tes3.objectType.armor

function Pickpocket:make_items()
	self.items = {}
	log("making pickpocket items")
	local ref = self.handle:getObject()
	if not ref then return end

	local items = self.items

	local equipped_datas = {} ---@type tes3itemData[]
	for _, stack in pairs(ref.object.equipment) do
		tbl_insert(equipped_datas, stack.itemData)
		-- log("found equipped item! \"%s\".", stack.object.name )
	end

	local equipped_cfg = pp_cfg.equipped
	local weapon_types = equipped_cfg.weapon_types
	local armor_slots = equipped_cfg.armor_slots
	local clothing_slots = equipped_cfg.clothing_slots
	local show_unavailable = equipped_cfg.show_unavailable

	log("making items")
	local handle = self.handle
	for _, stack in ipairs(ref.object.inventory.items) do
		local obj = stack.object
		log:trace("\tchecking if %s can be added", obj.name)

		if obj.canCarry == false then goto next_stack end

		-- log("\tadding \"%s\"", obj.name)
		local count = stack.count

		-- first yield stacks with custom data
		for _, data in pairs(stack.variables or {}) do
			---@type integer?
			local equipped_index
			for i, v in pairs(equipped_datas) do
				if v == data then
					equipped_index = i
					break
				end
			end

			if equipped_index == nil then
				tbl_insert(items,
					{ object = obj, box_handle = handle, data = data, count = 1, value = tes3.getValue { item = obj, itemData = data } })
			else
				-- remove it to make the search a little bit faster next time
				-- `find` uses pairs, so we don't need to worry about a broken array
				equipped_datas[equipped_index] = nil
				-- log("found equipped item! %s", obj.name)

				local giveit
				local obj_type = obj.objectType
				if obj_type == WEAPON then ---@cast obj tes3weapon
					giveit = weapon_types[obj.type]
				elseif obj_type == ARMOR then ---@cast obj tes3armor
					giveit = armor_slots[obj.slot]
				elseif obj_type == CLOTHING then ---@cast obj tes3clothing
					giveit = clothing_slots[obj.slot]
				end

				if giveit then
					tbl_insert(items,
						{ object = obj, box_handle = handle, data = data, count = 1, value = tes3.getValue { item = obj, itemData = data } })
				elseif show_unavailable then
					tbl_insert(items,
						{
							object = obj,
							box_handle = handle,
							data = data,
							equipped = true,
							count = 1,
							value = tes3
								.getValue { item = obj, itemData = data }
						})
				end
			end
			count = count - 1
		end
		-- if there are items to add, add them
		if count > 0 then
			tbl_insert(items, { object = obj, box_handle = handle, count = count, value = tes3.getValue { item = obj } })
		end
		::next_stack::
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

local mi_defns = defns.mi
local mi_cfg = pp_cfg.mi

--- get the number of items that should be taken, based on current config settings.
--- should only be called if `item.count > 1`
---@param item herbert.MQL.Item.Physical the item to take
---@param bulk boolean are we doing a batch take?
---@param modifier_pressed boolean is the modifier key pressed?
---@return integer num_to_take
function Pickpocket:get_num_to_take(item, bulk, modifier_pressed)
	if item.count <= 1 then
		return item.count
	end
	local weight = item.object.weight
	if weight <= 0 then
		return item.count
	end
	---@type herbert.MQL.defns.mi
	local mode = pp_cfg.mi[common.get_mi_index(bulk, modifier_pressed)]


	if mode == mi_defns.one
		or mode == mi_defns.ratio and common.value_weight_ratio(item) < mi_cfg.min_ratio
	then
		return 1
	end

	log("\tcalculating num to take for %s", item)

	local num_to_take = 1
	local max_wgt = mi_cfg.max_total_weight
	if max_wgt / weight >= 2 then
		log("\t\tcalculating weight constraint", item)
		num_to_take = math.floor(max_wgt / weight)

		-- need biggest integer `num` so that max_wgt > num * weight
		--              ~>   max_wgt / weight > num
		log("\t\t\tnum_to_take= %s", num_to_take)
	end

	local min_chance = mi_cfg.min_chance
	if min_chance < 1 then
		local chance = self:get_item_chance(item, 1)
		if chance > 0 and min_chance > 0 then
			log("\t\tcalculating chance constraint", item)
			-- need smallest `num` so that `chance ^ num > min_chance`
			--              ~>                      `num > log(min_chance, chance)`
			local y = math.floor(math.log(min_chance) / math.log(chance))
			if y >= num_to_take then
				num_to_take = y
			end

			-- log("\t\t\ty= %s", y)
			-- bounds:push(math.floor(y))
		end
	end

	return math.clamp(num_to_take, 1, item.count)
end

local DETECTED_COLOR ---@type number[]
local UNDETECTED_COLOR ---@type number[]

register_event(tes3.event.initialized, function(e)
	DETECTED_COLOR = tes3ui.getPalette(tes3.palette.negativeColor)
	UNDETECTED_COLOR = tes3ui.getPalette(tes3.palette.positiveColor)
end)

---@return string|nil text
---@return number[]|nil color
function Pickpocket:get_status_bar_text()
	if pp_cfg.show_detection_status then
		if self.is_detected then
			return "DETECTED", DETECTED_COLOR
		else
			return "UNDETECTED", UNDETECTED_COLOR
		end
	end
end

---@param item herbert.MQL.Item.Physical
---@param successes integer
---@param failures integer
function Pickpocket:award_xp(item, successes, failures)
	local value = item.value * (successes + 0.25 * failures)

	local t = math.clamp(math.sqrt(value) / 50, 0, 1) -- max xp given to items worth 2,500 gold
	local xp = math.lerp(t, 0.1, 2)
	tes3.mobilePlayer:exerciseSkill(tes3.skill.security, xp)
	tes3.mobilePlayer:exerciseSkill(tes3.skill.sneak, xp)
end

local CRIME_TYPE = tes3.crimeType.pickpocket


--- takes the currently activated item. also checks if the item can be looted, and if we're currently in a menu.
---@param item herbert.MQL.Item.Physical the item to take
---@param num_to_take integer mode we're taking the item in
---@param bulk boolean are we taking a bunch of things?
---@return integer num_taken
function Pickpocket:take_item(item, num_to_take, bulk)
	log("about to take %s", item)

	local item_ref = item.box_handle:getObject()
	if not item_ref then
		tes3.messageBox "Item doesn't exist!"
		return 0
	end

	local chance = self:get_item_chance(item, num_to_take)
	local lucky = false
	local successes = 0

	if chance >= 1 then
		successes = num_to_take
		-- luck override
	elseif tes3.mobilePlayer.luck.current >= 260
		or math.random(100) <= 0.5 * (tes3.mobilePlayer.luck.current - 30) then
		successes = num_to_take
		lucky = true
	elseif item.object.weight == 0 then
		if math.random() <= chance then
			successes = num_to_take
		end
	else
		if num_to_take ~= 1 then
			-- make sure this is the chance to take a single item
			chance = self:get_item_chance(item, 1)
		end
		for _ = 1, num_to_take do
			-- lets see how many we can take in a row
			if math.random() <= chance then
				successes = successes + 1
			else
				break
			end
		end
	end

	local failures = num_to_take - successes
	local owner = self.owner

	if successes > 0 then
		successes = common.transfer_item(item_ref, tes3.player, item, successes, bulk)

		log('\tsuccessfully took %s "%s". deleting them', successes, item.object.name)
		tes3.setItemIsStolen { item = item.object, from = item_ref.object }
	end
	-- show the UI messages if appropriate
	if not bulk then
		if successes > 0 and cfg.UI.show_msgbox then
			if failures > 0 then
				tes3.messageBox("You stole %s out of %s %s.", successes, failures + successes, common.get_item_name(item))
			else
				tes3.messageBox("You stole %s %s.", successes, common.get_item_name(item))
			end
		elseif failures > 0 and cfg.UI.show_failure_msg then
			tes3.messageBox("You failed to steal %s %s.", failures, common.get_item_name(item))
		end
		if lucky and cfg.UI.show_lucky_msg then
			tes3.messageBox "You got lucky!"
		end
	end

	local theft_value = item.value * (successes + failures)

	if failures > 0 then
		tes3.triggerCrime { type = CRIME_TYPE, victim = owner, value = theft_value, forceDetection = true }
	elseif successes > 0 and (not self.is_detected or pp_cfg.trigger_crime_undetected) then
		tes3.triggerCrime { type = CRIME_TYPE, victim = owner, value = theft_value }
	end

	self:award_xp(item, successes, failures)

	log("took %s/%s %s", successes, successes + failures, item)

	item.count = item.count - successes
	table.insert(self.history, { item = item, num_removed = successes })

	return successes
end

---@param e herbert.MQL.events.pick_container
register_event(defns.EVENT_IDS.pick_container, function(e)
	-- make sure the pickpocket module is enabled
	if not pp_cfg.enable
		or not tes3.mobilePlayer
		or tes3.mobilePlayer.attackDisabled
		or e.container_cls or e.claim or e.is_organic or e.ref.isDead ~= false
	then
		return
	end
	if tes3.mobilePlayer.isSneaking then
		e.container_cls = Pickpocket
		return
	end

	local handle = tes3.makeSafeObjectHandle(e.ref)
	if not handle then return end
	-- if the player isn't sneaking, start a timer that monitors their behavior
	timer.start { duration = 0.1, iterations = -1, callback = function(timer_data)
		local ref = handle:getObject()

		if ref == nil then
			log("canceling the timer because the handle is invalid")
			timer_data.timer:cancel()
		elseif ref ~= tes3.getPlayerTarget() then
			log("canceling the timer because the references dont match")
			timer_data.timer:cancel()
		elseif tes3.mobilePlayer.isSneaking then
			timer_data.timer:cancel()
			log("triggering picked item event for %s", ref)
			common.trigger_pick_container(ref, Pickpocket)
		end
	end }
end, { filter = tes3.objectType.npc, priority = -10 })


-- =============================================================================
-- ITEM CONTROL METHODS
-- =============================================================================



---@protected
--- calculate the chance of successfully taking this item. this is called before the UI is created.
---@param item tes3item|herbert.MQL.Item.Physical
---@return number take_chance the chance of successfully taking one copy of this item. should be a number between 0 and 1
function Pickpocket:get_item_chance(item, num)
	local mp = tes3.mobilePlayer

	local value = item.object.value
	local weight = item.object.weight
	if weight == 0 then
		value = value * num
		num = 1
	end

	local base_chance = 2.00 * math.max(0, mp.agility.current)
		+ 1.00 * math.max(0, mp.security.current)
		+ 0.50 * math.max(0, mp.sneak.current)
	local s = math.max(0, mp.sneak.current)
	local penalty_mult = 0.2 + 0.8 * 2 ^ (-(0.0002 * s ^ 2 + 0.009 * s))

	local penalty = 0.05 * weight + 0.03 * math.log(math.max(1, value)) ^ 1.5

	local chance = pp_cfg.chance_mult * 0.01 * (base_chance - penalty_mult * penalty)

	chance = chance ^ num


	if self.is_detected then
		-- log "we're detected, so applying the detection multiplier"
		chance = chance * pp_cfg.detection_mult
	end

	if pp_cfg.determinism and pp_cfg.determinism_cutoff <= chance then
		return 1
	else
		return math.clamp(chance, pp_cfg.min_chance, pp_cfg.max_chance)
	end
end

---Checks if the item at the given index can be taken
---@param item herbert.MQL.Item.Physical
---@return -1|0|1 val Whether we can take the item
---@return herbert.MQL.defns.can_take_err_code? err_code Only returned if `val == 0`. This provides information about why an item should be greyed out.
function Pickpocket:can_take_item(item)
	-- check if container is locked / trapped
	-- local box = item.box_handle:getObject()
	if item.count <= 0 then
		return -1
	elseif item.equipped then
		return 0, defns.can_take_err_codes.EQUIPPED
	else
		return 1
	end
end

-- -----------------------------------------------------------------------------
-- ITEM UI METHODS
-- -----------------------------------------------------------------------------


---gets the label of the item
---@param item herbert.MQL.Item.Physical
---@param num integer
---@return string
function Pickpocket:format_item_name(item, num)
	if pp_cfg.show_chances == defns.ui_show_chances.always
		or pp_cfg.show_chances == defns.ui_show_chances.lvl
		and tes3.mobilePlayer:getSkillValue(tes3.skill.security) > pp_cfg.show_chances_lvl
	then
		local chance = self:get_item_chance(item, num)
		if chance < 1 or pp_cfg.show_chances_100 then
			return string.format("%s - %d%%", Physical_Container.format_item_name(self, item, num), 100 * chance)
		end
	end
	return Physical_Container.format_item_name(self, item, num)
end

--- This is responsible for controlling all behavior that happens when a button is pressed
---@param selected_item herbert.MQL.Item.Physical? Item to do the action on
---@param action herbert.MQL.Action
---@return boolean successful
function Pickpocket:do_action(selected_item, action)
	local ref = self.handle:getObject()
	if not ref then return false end

	if action.ty == 1 then -- take one
		if not selected_item then
			tes3.messageBox "There is nothing to take!"
			return false
		end

		local res, err_code = self:can_take_item(selected_item)
		if res == 0 then
			tes3.messageBox("This item is equipped!")
			return false
		elseif res == -1 then
			return false
		else
			local to_take = self:get_num_to_take(selected_item, false, action.modifier_held)
			local taken = self:take_item(selected_item, to_take, false)

			if taken > 0 and action.equip_modifier_held then
				tes3ui.forcePlayerInventoryUpdate()
				local result = tes3.equip { reference = tes3.player, item = selected_item.object, itemData = selected_item.data }
				log("tried to equip %s. result = %s", selected_item, result)
			end
			log("took %s %s", taken, selected_item.object.name)
			log("\tamount remaining: %s", selected_item.count)
			local severity = (selected_item.count == 0) and 2 or 1
			log("\tcalling items changed event with severity = %s", severity)
			event.trigger(
				EVENT_IDS.container_items_changed,
				{ container = self, severity = severity },
				{ filter = self.cls_name }
			)

			return taken > 0
		end
	elseif action.ty == 2 then -- take all
		if not selected_item then
			tes3.messageBox "There is nothing to take!"
			return false
		end

		local total_taken = 0
		for _, item in ipairs(self.items) do
			if self:can_take_item(item) == 1 then
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

		return true
	elseif action.ty == 3 then -- open
		tes3.player:activate(ref)
		return true
	else -- undo
		tes3.messageBox("Some things cannot be undone.")
		return true
	end
end

Pickpocket.get_action_names = Physical_Container.get_action_names
Pickpocket.get_title = Physical_Container.get_title
Pickpocket.get_subtitles = Physical_Container.get_subtitles
Pickpocket.format_item_value = Physical_Container.format_item_value
Pickpocket.format_item_weight = Physical_Container.format_item_weight
Pickpocket.can_make_item_tooltip = Physical_Container.can_make_item_tooltip
Pickpocket.make_item_tooltip = Physical_Container.make_item_tooltip
Pickpocket.get_item_bg_color = Physical_Container.get_item_bg_color
Pickpocket.get_item_icon_path = Physical_Container.get_item_icon_path


common.assert_interface_is_implemented(Pickpocket)


return Pickpocket
