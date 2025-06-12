local defns = require("herbert100.more quickloot.defns")

local common = require("herbert100.more quickloot.common")

local cfg = require("herbert100.more quickloot.config")

local EVENT_IDS = defns.EVENT_IDS
local fmt = string.format

local log = mwse.Logger.new()
local mi_cfg = cfg.reg.mi
local UI_cfg = cfg.UI ---@type herbert.MQL.config.UI

---@type table<tes3.magicSchool, number[]>
local SCHOOL_COLORS = {
	[tes3.magicSchool.alteration]={152 / 255; 78 / 255; 179 / 255};
	[tes3.magicSchool.conjuration]={198 / 255; 191 / 255; 139 / 255};
	[tes3.magicSchool.destruction]={174 / 255; 53 / 255; 48 / 255};
	[tes3.magicSchool.illusion]={228 / 255; 254 / 255; 228 / 255};
	[tes3.magicSchool.mysticism]={110 / 255; 87 / 255; 117 / 255};
	[tes3.magicSchool.restoration]={119 / 255; 131 / 255; 182 / 255};
}

--[[## Base Container
This is prototypical example of a container that stores physical objects.
Roughly all containers (except for the Training menu) utilize some of the behavior specified here.
All inheritance is explicitly opt-in. And this is the only file that other containers inherit functionality from.
The definitions in this file should be seen as sensible default implementations of various parts of the 
Container interface.
That being said, most other containers will deviate from this funcitonality in some way.
]]
---@class herbert.MQL.Container.Physical : herbert.MQL.Container
---@field history herbert.MQL.Container.history.entry<herbert.MQL.Item.Physical>[] stack of items that are being bought
---@field items herbert.MQL.Item.Physical[]            a list of items in the container
---@field private relevant_handles mwseSafeObjectHandle[]  A list of safe handles being managed by this container.
--- This is used to help synchronize the inventories of multiple containers.
---@field owner tes3npc|tes3faction|nil
local Physical_Container = {cls_name="Physical"; disabled=false}

---Checks if the item at the given index can be taken
---@param item herbert.MQL.Item.Physical
---@return -1|0|1 val Whether we can take the item
---@return herbert.MQL.defns.can_take_err_code? err_code Only returned if `val == 0`. This provides information about why an item should be greyed out.
function Physical_Container:can_take_item(item)
	-- check if container is locked / trapped
	if item.count == 0 then
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
	return 1
end


function Physical_Container:make_items()
	self.history = {}
	self.items = {}
	self.relevant_handles = {}

	if self.disabled then
		return
	end
	log("calling internal make items function. self = %s", self)

	do -- sort the items
		local sort_items = UI_cfg.sort_items
		if sort_items == defns.sort_items.dont then
			return
		end

		if sort_items == defns.sort_items.weight then
			table.sort(self.items, common.item_sorters.weight_comp)
			return
		end

		if cfg.compat.bg and tes3.mobilePlayer.mercantile.current
		< common.bg_cfg.knowsPrice then
			return
		end

		if sort_items == defns.sort_items.value_weight_ratio then
			table.sort(self.items, common.item_sorters.value_weight_ratio)
		else
			table.sort(self.items, common.item_sorters.value_comp)
		end
	end

	event.trigger(EVENT_IDS.container_items_changed, {container=self; severity=2},
	              {filter=self.cls_name})

end


--- Gets the action labels, depending on the context
---@param item herbert.MQL.Item.Physical? The item to generate action names for.
---@param modifier_pressed boolean Is the modifier key pressed?
---@return string[]
function Physical_Container:get_action_names(item, modifier_pressed, equip_modifier_held)

	local take_verb, take_all_verb

	if equip_modifier_held then
		take_verb = "Equip"

		if cfg.reg.equip_modifier_take_all_enabled then
			take_all_verb = "Equip"
		else
			take_all_verb = self.owner and "Steal" or "Take"
		end
	else
		take_verb = self.owner and "Steal" or "Take"
		take_all_verb = take_verb
	end
	local count
	if item and self:can_take_item(item) == 1 then
		count = self:get_num_to_take(item, false, modifier_pressed)
	end

	return {
		count and (count > 0) and fmt("%s %s", take_verb, count) or take_verb;
		take_all_verb .. " All";
		"Open";
	}
end


function Physical_Container:get_status_bar_text()
	if self.owner then
		return string.format("Owned by %s", self.owner.name)
	end
end


-- Should this container be re-enabled for this reference?

---@param ref tes3reference
---@return -1|0|1 result If -1, don't enable. if 0, enable but hide contents. if 1, enable and show contents
---@return string? contents hidden reason. The reason why the contents should be hidden. This should only be erturned if the first return result is `0`.
function Physical_Container:can_enable(ref)
	-- make sure that we find a matching reference
	for _, handle in ipairs(self.relevant_handles) do
		if handle:getObject() == ref then
			-- hide the contents if empty
			if common.at_least_one_item_valid(self) then
				return 1
			else
				return 0, "Empty!"
			end
		end
	end
	return -1
end


--- Enable the container for a particular reference.
---@param ref tes3reference
function Physical_Container:enable(ref)
	self.handle = tes3.makeSafeObjectHandle(ref)
	self.disabled = false
end


--- Disables the container
function Physical_Container:disable()
	self.disabled = true
end


function Physical_Container:destruct()
	log:trace("container is self destructing for some reason.")
	if #self.history > 0 then
		tes3ui.forcePlayerInventoryUpdate()
	end
end


--- BUG: CHANGES DONT UPDATE WHEN MCM CLOSES

--- get the number of items that should be taken, based on current config settings.
--- should only be called if `item.count > 1`

---@param item herbert.MQL.Item.Physical the item to take
---@param bulk boolean are we doing a batch take?
---@param modifier_pressed boolean is the modifier key pressed?
---@return integer num_to_take
function Physical_Container:get_num_to_take(item, bulk, modifier_pressed)
	-- log:trace("calculating num to take\n\t\z
	-- 	item:     %s\n\t\z
	-- 	bulk:     %s\n\t\z
	-- 	mpressed: %s", 
	-- 	item, bulk, modifier_pressed
	-- )
	if item.count <= 1 then
		return item.count
	end
	local weight = item.object.weight
	if weight <= 0 then
		return item.count
	end

	---@type herbert.MQL.defns.mi
	local mode = mi_cfg[common.get_mi_index(bulk, modifier_pressed)]

	-- log:trace("\tmode = %s", table.find, defns.mi, mode)
	if mode == defns.mi.one or mode == defns.mi.ratio
	and common.value_weight_ratio(item) < cfg.reg.mi.min_ratio then
		return 1
	end

	local num = item.count

	if mi_cfg.max_total_weight > 0 then
		local y = math.floor(mi_cfg.max_total_weight / weight)
		num = math.clamp(y, 1, item.count)
	end
	return num
end


--- This is responsible for controlling all behavior that happens when a button is pressed

---@param selected_item herbert.MQL.Item.Physical? Item to do the action on
---@param action herbert.MQL.Action
---@return boolean successful
function Physical_Container:do_action(selected_item, action)
	local ref = self.handle:getObject()
	if not ref then
		return false
	end
	local ty = action.ty

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
			local to_take = self:get_num_to_take(selected_item, false,
			                                     action.modifier_held)
			local taken = self:take_item(selected_item, to_take, false)
			log("took %s %s", taken, selected_item.object.name)
			log("\tamount remaining: %s", selected_item.count)
			local severity = (selected_item.count == 0) and 2 or 1
			log("\tcalling items changed event with severity = %s", severity)

			common.ensure_not_empty(self)
			event.trigger(EVENT_IDS.container_items_changed,
			              {container=self; severity=severity}, {filter=self.cls_name})

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
		for _, item in ipairs(self.items) do
			if self:can_take_item(item) == 1 then
				local num = self:get_num_to_take(item, true, action.modifier_held)
				if num > 0 then
					total_taken = total_taken + self:take_item(item, num, true)
				end
			end
		end
		if total_taken > 0 then
			tes3.playItemPickupSound {item=selected_item.object; pickup=true}
			event.trigger(EVENT_IDS.container_items_changed,
			              {container=self; severity=2}, {filter=self.cls_name})
		end
		if cfg.UI.show_msgbox then
			local msg = total_taken == 0 and "There was nothing you wanted to take."
			            or fmt("You took %i items.", total_taken)
			tes3.messageBox(msg)
		end

		common.ensure_not_empty(self)

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
		local to = item.box_handle:getObject()
		local num_returned = common.transfer_item(tes3.player, to, item,
		                                          entry.num_removed, false)

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
		event.trigger(EVENT_IDS.container_item_returned,
		              {container=self; item=item; num_returned=num_returned},
		              {filter=self.cls_name})

		return true

	end

end


-- =============================================================================
-- ITEM METHODS
-- =============================================================================

--- Takes an item.
--- This method assumes that the item can be taken. and that `num_to_take` is a positive integer.

---@param item herbert.MQL.Item.Physical the item to take
---@param num_to_take integer The number of items being taken. This must be a positive integer.
---@param bulk boolean are we taking a bunch of things?
---@return integer num_taken the number of things that were actually taken.
function Physical_Container:take_item(item, num_to_take, bulk)
	log("about to take %s", item)

	local item_ref = item.box_handle:getObject()
	if not item_ref then
		log:error("Tried to take an item with an invalid container reference!")
		return 0
	end
	local num_taken
	do -- container specific stuff
		num_taken = common.transfer_item(item_ref, tes3.player, item, num_to_take,
		                                 bulk)
		if num_taken == 0 then
			log:error("tried to take %s %s, but couldn't", num_to_take, item)
		end
		if self.owner then
			tes3.triggerCrime {
				type=tes3.crimeType.theft;
				victim=self.owner;
				value=item.value * num_taken;
			}
		end
	end

	log("took %s %s", num_taken, item)

	item.count = item.count - num_taken
	table.insert(self.history, {item=item; num_removed=num_taken})

	return num_taken
end


-- =============================================================================
-- ITEM UI METHODS
-- =============================================================================

local rational_names = include("RationalNames.common")
---gets the label of the item

---@param item herbert.MQL.Item.Physical
---@param num integer
---@return string
function Physical_Container:format_item_name(item, num)
	local name = item.object.name
	-- compatibility with rational names
	if rational_names then
		name = rational_names.getDisplayName(item.object.id:lower()) or name
	end

	if item.count ~= 1 then
		if num and num ~= item.count then
			name = fmt("%s (%s / %s)", name, num, item.count)
		else
			name = fmt("%s (%s)", name, item.count)
		end
	elseif item.data and item.data.soul then
		name = fmt("%s (%s)", name, item.data.soul.name)
	end

	if cfg.compat.ttip and item.object
	and tes3.player.itemData.data.rev_TTIP.items[item.object.id] then
		name = fmt("%s %s", cfg.UI.ttip_collected_str, name)
	end
	return name
end


---Gets the value of the item
---@param item herbert.MQL.Item.Physical
---@param num integer
---@return string
function Physical_Container:format_item_value(item, num)
	if common.bg_cfg and tes3.mobilePlayer.mercantile.current
	< common.bg_cfg.knowsPrice then
		return "?"
	end
	local value = item.value * num
	return value == 0 and '-' or value < 1000 and tostring(math.round(value, 1))
	       or fmt("%sk", math.round(value / 1000, 2))
end


local WEIGHT_FMT_STR = tes3.hasCodePatchFeature(
                       tes3.codePatchFeature.displayMoreAccurateItemWeight)
                       and "%.2f" or "%.1f"

---@param item herbert.MQL.Item.Physical The index of the item
function Physical_Container:format_item_weight(item, num)

	local weight = item.object.weight
	return weight == 0 and '-' or fmt(WEIGHT_FMT_STR, weight * num)
end


--- Checks if a tooltip can be made for this item.

---@param _item herbert.MQL.Item 
---@return boolean
function Physical_Container:can_make_item_tooltip(_item)
	return not self.disabled and cfg.UI.show_tooltips
end


--- Tries to make a tooltip for the icon.

---@param item herbert.MQL.Item.Physical The index of the item
---@return tes3uiElement? tooltip
function Physical_Container:make_item_tooltip(item)
	local obj = item.object
	log('making tooltip for %s', obj)
	if not obj then
		return
	end
	local tt = tes3ui.createTooltipMenu {item=item.object; itemData=item.data}
	if not tt then
		return
	end

	log('making tooltip for %s', obj)
	log("tooltip id: %s", tt.id)
	-- log('\ttt: %s. tt.parent = %s', tt.children, tt.parent.children)

	if not obj.icon then
		return
	end

	local main = tt.children[1]

	if UI_cfg.show_tooltips_icon == 0 then
		return
	end

	local ICON_SIZE = 40
	local BG_SIZE = 35

	local icon_blk = main:createBlock()
	do -- format icon block
		icon_blk.width = ICON_SIZE
		icon_blk.height = ICON_SIZE
		icon_blk.paddingAllSides = 2
		icon_blk.childAlignX = 0.5
		icon_blk.childAlignY = 0.5
	end
	local bg_color = self:get_item_bg_color(item)

	if bg_color then -- make and format icon background
		local icon_swirl = icon_blk:createImage{path="textures/menu_icon_magic.tga"}
		icon_swirl.width = BG_SIZE
		icon_swirl.height = BG_SIZE
		icon_swirl.alpha = 1
		icon_swirl.color = bg_color
		icon_swirl.imageScaleX = 0.8
		icon_swirl.imageScaleY = 0.8
		-- icon_swirl.scaleMode = true
		icon_swirl.absolutePosAlignX = 0.7
		icon_swirl.absolutePosAlignY = 0.7
	end

	local icon = icon_blk:createImage{path="icons\\" .. obj.icon}
	icon.width = ICON_SIZE
	icon.height = ICON_SIZE
	icon.scaleMode = true

	-- update the layout and make `icon_blk` the first item
	main:updateLayout()
	if UI_cfg.show_tooltips_icon == 2 then
		main:reorderChildren(0, icon_blk, 1)
	end
	tt:updateLayout()
end


---@param item herbert.MQL.Item.Physical The index of the item
---@return number[]?
function Physical_Container:get_item_bg_color(item)

	local enchantment = item.object.enchantment
	return enchantment and enchantment.effects[1]
	       and SCHOOL_COLORS[enchantment.effects[1].object.school]
end


---@param item herbert.MQL.Item.Physical The index of the item
function Physical_Container:get_item_icon_path(item)
	return "icons\\" .. item.object.icon
end


--- Name of the container. appears at the top of the GUI.

---@return string[]? label
function Physical_Container:get_subtitles()
end


-- Labels that appear undearneath the regular action labels in the GUI

--- Name of the container. appears at the top of the GUI.

---@return string label
function Physical_Container:get_title()

	local ref = self.handle:getObject()
	if not ref then
		return "ERROR"
	end

	if cfg.show_scripted == defns.show_scripted.prefix
	and not ref:testActionFlag(tes3.actionFlag.useEnabled) then
		return "(*) " .. ref.object.name
	end
	return ref.object.name
end


local INSPECT_PARAMS = {
	newline=' ';
	indent='';
	process=function(item, path)
		if path[#path] == inspect.METATABLE then
			-- ignore metatables
		else
			-- sol types have this magic property we can (ab)use
			local _, subtype = type(item)
			if subtype then
				return fmt('%s("%s")', subtype, item)
			else
				local mt = getmetatable(item)
				if mt and mt.__tostring then
					return tostring(item)
				else
					return item
				end
			end
		end
	end
;
}
---@type metatable
local meta = {
	__index=Physical_Container;

	---@param self herbert.MQL.Container.Physical
	__tostring=function(self)
		local field_strs = {}
		for k, v in pairs(self) do
			if k ~= "items" then
				table.insert(field_strs,
				             fmt("%s = %s", k, inspect.inspect(v, INSPECT_PARAMS)))
			end
		end
		local item_strs = {}
		for i, item in ipairs(self.items) do
			local box_handle_str
			local box_ref = item.box_handle:getObject()
			if box_ref and box_ref.object then
				local _, ty = type(box_ref.object)
				box_handle_str = fmt('%s("%s")', ty, box_ref.object)
			else
				box_handle_str = "nil"
			end
			item_strs[i] = fmt("{name = %s, count = %s, value = %s, box_handle = %s}",
			                   item.object.name, item.count, item.value, box_handle_str)
		end
		field_strs[#field_strs + 1] = fmt("items = [\n\t\t%s\n\t]",
		                                  table.concat(item_strs, "\n\t\t"))

		return fmt("%s(\n\t%s\n)", self.cls_name, table.concat(field_strs, "\n\t"))
	end
;
}
-- make it accessible to anybodoy else who might want it.
-- Note: This is not necessary for the metamethod to work.
Physical_Container.__tostring = meta.__tostring

---make a new one 
---@param ref tes3reference
---@return herbert.MQL.Container.Physical
function Physical_Container.new(ref)

	---@type herbert.MQL.Container.Physical
	local obj = setmetatable({
		handle=tes3.makeSafeObjectHandle(ref);
		relevant_handles={};
		items={};
		history={};
		disabled=false;
		-- owner = tes3.hasOwnershipAccess{target=ref} and tes3.getOwner{reference = ref} or nil
	}, meta)

	log("checking ownership access for %s", ref.object)
	if tes3.hasOwnershipAccess {target=ref} then
		log("\thave access!\n\n")
	else
		obj.owner = tes3.getOwner {reference=ref}
		log("\tno access! set obj.owner = %s\n\n", obj.owner)
	end

	obj:make_items()

	return obj
end


-- i really wish the LuaLS type system would do this for me

common.assert_interface_is_implemented(Physical_Container)

return Physical_Container
