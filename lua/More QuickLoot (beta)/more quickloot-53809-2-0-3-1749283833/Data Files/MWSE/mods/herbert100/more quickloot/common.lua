-- this is my attempt at gradually decluttering `mod.lua`, so that it will eventually not be so painful to look at

-- local register_event = livecoding and livecoding.registerEvent or event.register
local register_event = event.register
local log = mwse.Logger.new()

local defns = require("herbert100.more quickloot.defns") ---@type herbert.MQL.defns

local cfg = require("herbert100.more quickloot.config") ---@type herbert.MQL.config

local EVENT_IDS = defns.EVENT_IDS




-- common utility functions used by the mod
---@class herbert.MQL.common
---@field clothing_slots_by_type {[herbert.MQL.defns.equipped_type]: {[tes3.clothingSlot]: true}}
---@field armor_slots_by_type {[herbert.MQL.defns.equipped_type]: {[tes3.armorSlot]: true}}
local common = {
   
	--- A table that maps a `tes3.scanCode` to a quickloot action.
	---@type {[tes3.scanCode]: herbert.MQL.ActionType}
	keymap = {};
	--- A table that maps a mousebutton to a quickloot action.
	---@type {[integer]: herbert.MQL.ActionType}
	mousemap = {};
}


--- registers an event if it should be registered, unregisters it otherwise.
-- you can pass an old priority or old filter to unregister events when settings have changed
---@param event_id tes3.event the event to register/unregister
---@param callback fun(e)
---@param register boolean If true, the event will be registered. If false, the event will be unregistered.
---@param filter integer?
---@param old_filter integer?
---@param priority integer? Priority of the event
---@return boolean something_changed whether an event was registered/unregistered
function common.upd_event_reg(event_id, callback, register, filter, old_filter, priority)
	if old_filter == nil then
		old_filter = filter
	elseif old_filter == false then	
		old_filter = nil
	end
    if old_filter then
        local old_options = {filter=old_filter}
        if event.isRegistered(event_id, callback, old_options) then
            event.unregister(event_id, callback, old_options)
        end
    end
    local options = (filter or priority) and {filter=filter, priority=priority} or nil

    local registered = event.isRegistered(event_id, callback, options)
    
    if register ~= false then
        if not registered then
			register_event(event_id, callback, options)
            return true
        end
    else
        if registered then 
            event.unregister(event_id, callback, options)
            return true
        end
    end
    return false
end


-- critical failure happens if you try to load buying game config before the game initializes
register_event("initialized", function(e)
	common.bg_cfg = include("buyingGame.config")
end, {doOnce=true, priority=-2000})


 -- checks if a container is scripted
--- @param ref tes3reference reference to a container
---@return boolean is_scripted
function common.is_container_scripted(ref)
	return ref:testActionFlag(tes3.actionFlag.useEnabled) == false
end


---@param equipped_cfg herbert.MQL.config.Container.equipped
function common.update_equipped_cfg(equipped_cfg)
	equipped_cfg.clothing_slots = {}
	equipped_cfg.weapon_types = {}
	equipped_cfg.armor_slots = {}

	local allow_weapons = equipped_cfg.allowed_type_defns[defns.equipped_types.weapons]
	local allow_armor = equipped_cfg.allowed_type_defns[defns.equipped_types.armor]
	local allow_clothing = equipped_cfg.allowed_type_defns[defns.equipped_types.clothing]
	local allow_jewelry = equipped_cfg.allowed_type_defns[defns.equipped_types.jewelry]
	local allow_accessories = equipped_cfg.allowed_type_defns[defns.equipped_types.accessories]

	-- weapons
	if allow_weapons then
		for _, weapon_type in pairs(tes3.weaponType) do
			equipped_cfg.weapon_types[weapon_type] = true
		end
	end
	-- armor
	if allow_armor then
		for _, armor_slot in pairs(tes3.armorSlot) do
			equipped_cfg.armor_slots[armor_slot] = true
		end
	end
	-- clothing 
	if allow_clothing then
		for _, clothing_slot in pairs(tes3.clothingSlot) do
			equipped_cfg.armor_slots[clothing_slot] = true
		end
	end
	-- jewlery
	if allow_jewelry then
		equipped_cfg.clothing_slots[tes3.clothingSlot.ring] = true
		equipped_cfg.clothing_slots[tes3.clothingSlot.amulet] = true
	end
	-- accessories 
	if allow_accessories then
		equipped_cfg.clothing_slots[tes3.clothingSlot.leftGlove] = true
		equipped_cfg.clothing_slots[tes3.clothingSlot.rightGlove] = true
		equipped_cfg.clothing_slots[tes3.clothingSlot.belt] = true
		equipped_cfg.armor_slots[tes3.armorSlot.leftGauntlet] = true
		equipped_cfg.armor_slots[tes3.armorSlot.rightGauntlet] = true
	end
    log("updated allowed clothing slots to %s", equipped_cfg.clothing_slots)

    log("updated allowed armor slots to %s", equipped_cfg.weapon_types)
end

do -- define function for taking all objects of a similar type

    common.take_nearby_A_list = { 
        [tes3.objectType.ingredient] = true, 
        [tes3.objectType.alchemy] = true, 
        [tes3.objectType.lockpick] = true, 
        [tes3.objectType.probe] = true, 
        [tes3.objectType.apparatus] = true, 
        [tes3.objectType.ammunition] = true, 
        [tes3.objectType.book] = true,
    }
    common.take_nearby_B_list = {
        [tes3.objectType.miscItem] = true,  
        [tes3.objectType.weapon] = true, 
        [tes3.objectType.clothing] = true, 
        [tes3.objectType.armor] = true, 
    }
    
---@param obj tes3clothing
local function logmsg_take_nearby(obj)
    return "targeting %s. obj_type = %s. Seeing if it's possible to grab everything.", 
        obj.name, table.find(tes3.objectType, obj.objectType)
end


--- takes all objects of a certain type
---@param target tes3reference target object. we'll look for items close to this object
function common.take_nearby_items(target)

     -- otherwise, take all the items, if we're allowed
        -- only take all stuff if the distance is bigger than 0
    if target == nil or (cfg.take_nearby_dist and cfg.take_nearby_dist <= 5) then return end

    local obj = target.object
    local obj_type = obj.objectType
	-- silence the type warnings
	---@cast obj tes3weapon|tes3misc

    log(logmsg_take_nearby, obj)

    local sg_check = false
    local name
    -- if it's a B_lister, needs to pass a name check, unless it's a soul gem
    if common.take_nearby_B_list[obj_type] then 
        if obj_type == tes3.objectType.miscItem and obj.isSoulGem then
            sg_check = true
        else
            name = obj.name
        end
    else
        -- if this object is not an A-lister or a B-lister, skip it
        if not common.take_nearby_A_list[obj_type] then return end
    end

    log("about to take all nearby items")

    local original_crime_victim = cfg.take_nearby_allow_theft and tes3.getOwner{reference=target} or nil

    tes3.playItemPickupSound{item=obj}

    -- used for filtering references
    local tpos = target.position
    local dist = cfg.take_nearby_dist
    local v_dist = cfg.advanced.v_dist
    local use_enabled_flag = tes3.actionFlag.useEnabled
    local activate_flag = tes3.actionFlag.onActivate
    for ref in tes3.player.cell:iterateReferences(obj_type, false) do
        -- reference checks
        if tpos:distanceXY(ref.position) > dist
        or tpos:heightDifference(ref.position) > v_dist
        or not ref:testActionFlag(use_enabled_flag)
        then goto next_ref end

        local obj2 = ref.object
		---@cast obj2 tes3weapon|tes3misc
        -- object specific checks
        if name then
            if obj2.name ~= name then goto next_ref end
        elseif sg_check then
            if not obj2.isSoulGem then goto next_ref end
        end

        if obj2.script then
            log("skipping %q because it had a script: %q", obj2, obj2.script)
            goto next_ref
        end
        
        local data = ref.itemData
        local crime_victim = tes3.getOwner{reference = ref}
        if crime_victim then
            if crime_victim ~= original_crime_victim then goto next_ref end
            tes3.triggerCrime{victim = crime_victim, value = obj2.value, type = tes3.crimeType.theft}
        end

        tes3.addItem{ reference=tes3.player, item=obj2, count=ref.stackSize,
            itemData=ref.stackSize == 1 and data or nil, updateGUI=false,  playSound=false,
        }
        -- tes3.gmst.site
        
        ref.itemData = nil
        ref:disable()
        -- ref:delete()
        -- tes3.player:activate(ref)
        -- local num = tes3.addItem{item=ref.object, reference=tes3.player, playSound=false, updateGUI=false, itemData=ref.itemData}
        ::next_ref::
    end
    tes3.removeEffects{reference=tes3.player, effect=tes3.effect.invisibility}
    tes3ui.forcePlayerInventoryUpdate()
end
end



local modifier_key, equip_modifier_key

local modifier_held = false ---@type boolean 
local equip_modifier_held = false ---@type boolean 

---@param e keyEventData
local function update_modifier_key_status(e)
	modifier_held = e.pressed
	event.trigger(EVENT_IDS.modifier_state_updated, {pressed = modifier_held})
end

---@param e keyEventData
local function update_equip_modifier_key_status(e)
	equip_modifier_held = e.pressed
	event.trigger(EVENT_IDS.equip_modifier_state_updated, {pressed = equip_modifier_held})

end

---@param params {keyCode: tes3.scanCode, mouseButton: integer}
---@param action herbert.MQL.ActionType
function common:update_single_keybinding(params, action)
	
	if params.keyCode then
		self.keymap[params.keyCode] = action 
	elseif params.mouseButton then
		self.mousemap[params.mouseButton] = action
	else
		error("no mouse or keycode provided for action".. table.find(defns.ActionType, action))
	end
end


function common.update_keybindings()
	local keys_cfg = cfg.keys

	common.upd_event_reg(
		"key", 
		update_modifier_key_status, 
		true, 
		cfg.keys.modifier.keyCode, 
		modifier_key
	)
	common.upd_event_reg(
        "key", 
        update_equip_modifier_key_status,
        true,
        cfg.keys.equip_modifier.keyCode,
        equip_modifier_key
	)

    equip_modifier_key = keys_cfg.equip_modifier.keyCode
    modifier_key = keys_cfg.modifier.keyCode

	

	
    
    -- custom
    -- log("custom key = %s", json.encode, keys.custom)
    log("custom key = %s", keys_cfg.custom)
	local ACTIONS = defns.ActionType

	local custom_action, activate_action
	if keys_cfg.use_activate_btn then
		activate_action, custom_action = ACTIONS.Take, ACTIONS.Open
	else
		activate_action, custom_action = ACTIONS.Open, ACTIONS.Take
	end
	common:update_single_keybinding(keys_cfg.custom, custom_action)
    
	log("take all key = %s", keys_cfg.take_all)
	common:update_single_keybinding(keys_cfg.take_all, ACTIONS.TakeAll)
	common:update_single_keybinding(keys_cfg.undo, ACTIONS.Undo)
	
    -- activate
    local activate_binding = tes3.getInputBinding(tes3.keybind.activate)
    if activate_binding.device == 0 then
        common.keymap[activate_binding.code] = activate_action
        log("activate keycode = %s", activate_binding.code)
    else
        common.mousemap[activate_binding.code] = activate_action
    end
end

register_event(defns.EVENT_IDS.config_updated, common.update_keybindings)
register_event(tes3.event.initialized, common.update_keybindings)



---@param e keyDownEventData
---@return herbert.MQL.Action?
function common.convert_keycode_to_action(e)

    local ty = common.keymap[e.keyCode]
    if not ty then return end

    if ty == 4 then
        local undo_cfg = cfg.keys.undo
        if undo_cfg.isAltDown ~= e.isAltDown 
        or undo_cfg.isControlDown ~= e.isControlDown
        or undo_cfg.isShiftDown ~= e.isShiftDown
        then return end
    end
	---@type herbert.MQL.Action
	return {
		equip_modifier_held = equip_modifier_held,
		modifier_held = modifier_held,
		ty = ty
	}

end

---@param e mouseButtonDownEventData
---@return herbert.MQL.Action?
function common.convert_mousebutton_to_action(e)
	---@type herbert.MQL.Action
	return {
		equip_modifier_held = equip_modifier_held,
		modifier_held = modifier_held,
		ty = common.mousemap[e.button]
	}
end


---@return boolean modifier_pressed
function common.is_modifier_held()
    return modifier_held
end
---@return boolean modifier_pressed
function common.is_equip_modifier_held()
    return equip_modifier_held
end

local BOOL_TO_NUMBER = {[false] = 0, [true] = 1}
--- Gets the `config.mi` index based on the given parameters as follows:
--- ```rs
--- modifier_pressed && take_all => 4,
--- modifier_pressed && !take_all => 3,
--- !modifier_pressed && take_all => 2,
--- !modifier_pressed && !take_all => 1,
--- ```
---@param take_all boolean Are we trying to take all items?
---@param modifier_pressed boolean Is the modifier key pressed?
---@return 1|2|3|4 cfg_index The config index to use.
function common.get_mi_index(take_all, modifier_pressed)
	return 1 + BOOL_TO_NUMBER[take_all] + 2 * BOOL_TO_NUMBER[modifier_pressed]
	--[[
	]]
    -- if modifier_pressed then
    --     if take_all then
    --         return 4
    --     else
    --         return 3
    --     end
    -- else
    --     if take_all then
    --         return 2
    --     else
    --         return 1
    --     end
    -- end
end


--- Wrapper for `tes3.transferItem`.
--- This wrapper tries to take items with item data and then without item data if necessary.
---@param from tes3reference the container to remove the items from
---@param to tes3reference the container to add the items to
---@param item herbert.MQL.Item.Physical the item to remove/transfer
---@param num integer the number of items to remove/transfer
---@param bulk boolean is this being called in a "take all" setting?
---@return integer num_transferred
function common.transfer_item(from, to, item, num, bulk)
    
    ---@type tes3.transferItem.params
    local tp = {
        from = from,
        to = to,
        item = item.object,
        count = num,
        itemData = item.data,
        reevaluateEquipment = false,
        playSound = not bulk,
        updateGUI = false,
    }

   
    local num_taken = tes3.transferItem(tp)
    log("took %i %s", num_taken, item)
    if num_taken ~= num then
        log("\tERROR: only took %i/%i of %s\n\ttrying again....", num_taken, num, item)
        tp.itemData = nil
        num_taken = num_taken + tes3.transferItem(tp)
        log("tried again. now took a total of %i %s", num_taken, item)
    end
    return num_taken
end

--- Wrapper for `tes3.removeItem`.
--- This wrapper tries to take items with item data and then without item data if necessary.
---@param from tes3reference the container to remove the items from
---@param item herbert.MQL.Item.Physical the item to remove/transfer
---@param num integer the number of items to remove/transfer
---@param bulk boolean is this being called in a "take all" setting?
---@return integer num_transferred
function common.remove_item(from, item, num, bulk)


    ---@type tes3.removeItem.params
    local tp = {
        reference = from,
        item = item.object,
        count = num,
        itemData = item.data,
        reevaluateEquipment = false,
        playSound = not bulk,
        updateGUI = false,
    }

   
    local num_taken = tes3.removeItem(tp)
    log("took %i %s", num_taken, item)
    if num_taken ~= num then
        log("\tERROR: only took %i/%i of %s\n\ttrying again....", num_taken, num, item)
        tp.itemData = nil
        num_taken = num_taken + tes3.removeItem(tp)
        log("tried again. now took a total of %i %s", num_taken, item)
    end
    return num_taken
end

---@param item herbert.MQL.Item.Physical
---@return number
function common.value_weight_ratio(item)
	local weight = item.object.weight
    if weight == 0 then
		-- 0 weight is really nice.
		-- We could return `math.huge` here.
		-- But this works better for sorting if we instead add a large number and then multiply
		-- the value by `item.count`.
       	return 10^12 + item.value * item.count
    end
    return item.value / weight
end

common.item_sorters = {

    --- compare two items based on their gold/weight ratios. used for sorting lists of items
    ---@param i1 herbert.MQL.Item.Physical
    ---@param i2 herbert.MQL.Item.Physical
    ---@return boolean -- `true` if `i1 < i2`; `false` otherwise. i.e., `true` means `i1` should appear before `i2`.
    value_weight_ratio = function(i1,i2)
        -- if i1.status ~= i2.status then return i1.status > i2.status end
        local i1ratio, i2ratio = common.value_weight_ratio(i1), common.value_weight_ratio(i2)
        
        -- higher ratio means show it earlier
        if i1ratio ~= i2ratio then
			 return i1ratio > i2ratio
		elseif i1.value ~= i2.value then
			 return i1.value > i2.value
		elseif i1.object.name ~= i2.object.name then
			 return i1.object.name < i2.object.name
		elseif i1.count ~= i2.count then
			 return i1.count < i2.count
		else
			return i1.value > i2.value
		end
    end,


    --- compare two items based on their gold values. used for sorting lists of items
    ---@generic Item : herbert.MQL.Item
    ---@param i1  herbert.MQL.Item.Physical
    ---@param i2  herbert.MQL.Item.Physical
    ---@return boolean -- `true` if `i1 < i2`; `false` otherwise. i.e., `true` means `i1` should appear before `i2`.
    value_comp = function(i1,i2)
        if i1.value ~= i2.value then 
			return i1.value > i2.value
		elseif i1.object.name ~= i2.object.name then 
			return i1.object.name < i2.object.name
		elseif i1.count ~= i2.count then 
			return i1.count < i2.count
		else
			return i1.object.weight < i2.object.weight
		end
    end,


    --- compare two items based on their weights. used for sorting lists of items.
    ---@generic Item : herbert.MQL.Item
    ---@param i1  herbert.MQL.Item.Physical
    ---@param i2  herbert.MQL.Item.Physical
    ---@return boolean -- `true` if `i1 < i2`; `false` otherwise. i.e., `true` means `i1` should appear before `i2`.
    weight_comp = function(i1,i2)
        -- compare values if they're different
        local w1, w2 = i1.object.weight, i2.object.weight
        if w1 ~= w2 then 
			return w1 < w2
		elseif i1.object.name ~= i2.object.name then 
			return i1.object.name < i2.object.name 
		elseif i1.count ~= i2.count then 
			return i1.count < i2.count
		else 
			return i1.value > i2.value
		end
	end
}

--- Adds items from the given reference to the given container.
---@param container herbert.MQL.Container.Physical
---@param box_ref tes3reference
function common.add_items_to_list(container, box_ref)
	local tbl_insert = table.insert
	box_ref:clone()
	local box_handle = tes3.makeSafeObjectHandle(box_ref)
    local items = container.items
    log("about to make items for %s", box_ref.object)
    for _, stack in pairs(box_ref.object.inventory) do 
        local obj, count = stack.object, math.abs(stack.count)
		log:trace("\tchecking if we can add %s (count = %s)", obj, count)
        if obj.canCarry == false or obj.value == nil then goto next_stack end
		---@cast obj -tes3leveledItem
		log:trace("\ttrying to add %s (id = %s), count = %s, value = %s", obj.name, obj.id, count, obj.value)

        count = math.abs(stack.count)
        -- first yield stacks with custom data
        if stack.variables then
            for _, data in pairs(stack.variables) do
				tbl_insert(items, {box_handle=box_handle, object=obj, data=data, count=1, value=tes3.getValue{item=obj, itemData=data}})
                count = count - 1
            end
        end
        -- if there are items to add, add them
        if count > 0 then
			tbl_insert(items, {box_handle=box_handle, object=obj, count=count, value=tes3.getValue{item=obj}})
        end
        ::next_stack::
    end
	---@diagnostic disable-next-line: invisible
	tbl_insert(container.relevant_handles, box_handle)
	-- if #items > num_at_start then
	-- end
end


function common.play_switch_sound()
	if cfg.UI.play_switch_sounds then
        tes3.playSound{sound = cfg.UI.play_switch_sounds, volume = 0.75}
    end
end



local interface = require("herbert100.more quickloot.containers.abstract.interface")
--- Makes sure the class in question actually implemented all of the functions it was supposed to.
--- The language server currently does not actually do this, so it must be done manually.
---@param cls herbert.MQL.Container
function common.assert_interface_is_implemented(cls)
	-- make sure the class has all the keys
	for k, defn in pairs(interface) do	
		assert(cls[k], string.format("Error: \"%s\" did not implement \"%s\"", cls.cls_name, k))
		assert(type(cls[k]) == type(defn),string.format("Error: cls.%s is the wrong type. It should be of type \"%s\"", k, type(defn)))
	end
end

---@param container herbert.MQL.Container
function common.at_least_one_item_valid(container)
	for _, item in ipairs(container.items) do
		if container:can_take_item(item) ~= -1 then
			return true
		end
	end
	return false
end

--- Makes sure a container isn't empty.
--- If it is empty, it fires the appropriate event.
---@param container herbert.MQL.Container
---@return boolean is_empty
function common.ensure_not_empty(container)
	for _, item in ipairs(container.items) do
		if container:can_take_item(item) ~= -1 then
			return false
		end
	end
	-- Container is empty, so fire the event.
	event.trigger(EVENT_IDS.container_empty, {container = container}, {filter = container.cls_name})
	return true
end

---@param ref tes3reference|false|nil Reference to reset the tooltip for. If `nil`, then the current player target will be used. If `false`, nothing will be used.
---@param container herbert.MQL.Container|nil The active container, if it exists.
function common.reset_tooltip(ref, container)
	if not cfg.UI.show_tooltips then
		-- nothing to do in this case
		return
	end
	if ref == nil then
		ref = tes3.getPlayerTarget()
	end
	if ref and ref.object then
		local container_ref = container and container.handle:getObject()
		if container_ref == ref then
			tes3ui.createTooltipMenu{object=ref.object, itemData=ref.itemData}
			return
		end
	end
	tes3ui.refreshTooltip()
end



do -- define function to check if a container is organic
    -- check if a container is organic
    local gh_config

    if cfg.compat.gh_current > defns.misc.gh.never then
        gh_config = include("graphicHerbalism.config") or mwse.loadConfig("graphicHerbalism", {blacklist = {}, whitelist={}})
    end

    --- this is a modified version of the `isHerb` function from `graphicHerbalism.main`, copied with permission
    -- we're assuming this is only called on references that aren't `nil`
    -- if the relevant settings are enabled, it will use Graphic Herbalism logic to detect whether something is a plant, in addition to our blacklist
    ---@param ref tes3reference
	---@param base_id string The lowercase id of `ref.baseObject`
    ---@return boolean result
    function common.is_organic(ref, base_id)
        if not ref.object.organic then 
			return false 
		end

        -- if everything organic is a plant, return `true` before doing anything further
        if cfg.organic.not_plants_src == defns.not_plants_src.everything_plant then 
			return true
		end

        -- at this point, we have `config.organic.not_plants_src > defns.not_plants_src.everything_plant`

        if cfg.blacklist.organic[base_id] then
			return false 
		end

        -- past this point, the `blacklist.organic` didn't catch it

        -- if the relevant config setting is enabled, we should ask Graphic Herbalism for its opinion
        if cfg.organic.not_plants_src == defns.not_plants_src.gh and gh_config then
            if gh_config.blacklist[base_id] then
				return false
			end
            if gh_config.whitelist[base_id] then
				return true
			end

            return (ref.object.script == nil)
        end
        -- past this point, Graphic Herbalism didn't catch it, so it's probably a plant

        return true
    end
end

do -- add services functionality

	---@class herbert.MQL.Serivces.register_service.params
	---@field cls herbert.MQL.Container The class to register.
	---@field display_name string The name to display to the user.
	---@field is_valid_for_service fun(ref: tes3reference): boolean A function that tests a new `cls` instance should be created for the specified refernce.
	---@field filter_contexts tes3.dialogueFilterContext[] The dialogue filter contexts affected by this service. Can be empty, but cannot be `nil`.

	---@class herbert.MQL.Serivces.registered_service
	---@field cls herbert.MQL.Container
	---@field display_name string The name to display to the user.
	---@field is_valid_for_service fun(ref: tes3reference): boolean

	---@type {[tes3.dialogueFilterContext]: true}
	local filter_contexts = {}


	---@type herbert.MQL.Serivces.registered_service[]
	local registered_services = {}

	common.services = {
		filter_contexts = filter_contexts,
		registered_services = registered_services
	}




	---Makes a timer for the given service.
	---@param container herbert.MQL.Container The services instance to make a timer for. 
	---@return mwseTimer
	function common.services.make_timer_for_service(container)
		return timer.start{duration = 0.1, iterations = -1, callback = function(e)
			local ref = container.handle:getObject()
			if ref == nil 
			or ref.isDead 
			or not tes3.mobilePlayer 
			then
				e.timer:cancel()
				event.trigger(EVENT_IDS.container_invalidated, {container = container}, {filter = container.cls_name})
			elseif tes3.mobilePlayer.isSneaking then
				e.timer:cancel()
				event.trigger(EVENT_IDS.container_invalidated, {container = container}, {filter = container.cls_name})
				if ref == tes3.getPlayerTarget() then
					timer.delayOneFrame(function()
						common.trigger_pick_container(ref)
					end)
				end
			end
		end}
	end



	---@param params herbert.MQL.Serivces.register_service.params 
	function common.services.register_service(params)
		assert(params ~= nil, "No parameters provided.")
		assert(params ~= common.services, "Parameters were invalid.")
		local cls = params.cls
		assert(cls ~= nil, "No service class provided.")
		assert(not rawequal(cls, common.services), "cls cannot be equal to Services")
		assert(cls.cls_name, "The service class must have a valid class name!")
		assert(params.is_valid_for_service ~= nil, "Error: the class must implement the `is_valid_target` function.")

		assert(params.display_name ~= nil, "No display name was given!")
		assert(type(params.display_name) == "string", "Display name must be a string!")
		-- make sure it wasn't already registered
		for _, reg in ipairs(registered_services) do
			if rawequal(reg.cls, cls) then
				error("This service has already been registered!")
			end
		end
		
		assert(params.filter_contexts ~= nil, "No filter contexts provided!!")

		-- make sure this is a service

		for _, context in ipairs(params.filter_contexts) do
			filter_contexts[context] = true
		end
		
		---@type herbert.MQL.Serivces.registered_service
		local service = {cls = cls, is_valid_for_service = params.is_valid_for_service, display_name = params.display_name}

		table.insert(registered_services, service)
	end




	---@param cls herbert.MQL.Container The class of a container. Note: This should not be an object!
	---@param ref tes3reference|false The reference to use when filtering the service. If no filter is desired, this should be `false`.
	---@return herbert.MQL.Serivces.registered_service? reg The registration information for the next service.
	function common.services.get_next_service(cls, ref)
		assert(cls, "Error: cls should never be nil!")

		local index
		for i, reg in ipairs(registered_services) do
			if reg.cls == cls then
				index = i
				break
			end
		end
		assert(index ~= nil, "Error: `cls` did not correspond to the CLASS of a registered service.")

		local next_index = index
		local num_registered = #registered_services

		while true do
			-- wrap and increment the index
			next_index = 1 + next_index % num_registered
			if next_index == index then
				log("no valid next service. returning nil")
				
				return
			end
			if ref == false or registered_services[next_index].is_valid_for_service(ref) then
				break
			end
		end
		log("returning next service = %s", registered_services[next_index])

		return registered_services[next_index]
	end

	---@param cls herbert.MQL.Container The active container class.
	---@param ref tes3reference
	function common.services.switch_to_next_service(cls, ref)
		local next_service = common.services.get_next_service(cls, ref)
		if next_service then
			log("got next service = %s.\n\ttriggering container pick event!")
			common.trigger_pick_container(ref, next_service.cls)
		end
	end

	-- sourced from "Hide the Skooma" by Necrolesian. credit to them for compiling this list.
	local SKOOMA_IDS = { 
		["2350820932343717228"] = true, 
		["27431251821030328588"] = true, 
		["745815156108126115"] = true, 
		["1094918899840230767"] = true, 
		["170686103927626649"] = true, 
		["437731057154051750"] = true, 
		["2456544071464426424"] = true, 
		["781926249198433643"] = true, 
		["27861296403221528233"] = true, 
		["287378702993122269"] = true, 
		["29036265711176618107"] = true, 
		["2821782961190224094"] = true, 
		["3576191201815529709"] = true, 
		["3034922702178419782"] = true, 
		["277125218205084722"] = true, 
		["2797025664259225507"] = true, 
	}
	common.services.SKOOMA_IDS = SKOOMA_IDS


	local services_cfg = cfg.services

	---@param e dialogueFilteredEventData
	register_event("dialogueFiltered", function (e)
		if services_cfg.allow_skooma 
		and filter_contexts[e.context] 
		and SKOOMA_IDS[e.info.id]
		then 
			log ("we're checking a service and got a skooma rejection")
			return false
		end
	end)

	---@param e herbert.MQL.events.pick_container
	register_event(EVENT_IDS.pick_container, function (e)
		if e.container_cls ~= nil or e.block == true -- if someone else already wants the event
		or e.is_organic or e.ref.isDead ~= false 	 -- if it's not a living person
		or cfg.blacklist.containers[e.base_id] 		 -- if it's blacklisted
		then 
			return 
		end
		log("picking new service!")
		log("\tregistered services = %s", function ()
			local out = {}
			for i, service in ipairs(registered_services) do
				out[i] = service.cls.cls_name
			end
			return out
		end)
		for _, reg in ipairs(registered_services) do
			log('checking "%s"', reg.display_name)
			if reg.is_valid_for_service(e.ref) then
				e.container_cls = reg.cls
				return
			end
		end
	end)

end


--- Triggers the event that picks a container class for a given reference.
--- This function will make sure `ref` is not blacklisted before firing the event.
--- Can be filtered by the object type of the reference.
--- @param ref tes3reference
---@param suggested_container herbert.MQL.Container? A suggestion about which container should be picked.
function common.trigger_pick_container(ref, suggested_container)

	local base_id = ref.baseObject.id:lower()

	-- blacklist check
	-- Note: the plants blacklist stuff is handled by the `is_organic` function.
	if cfg.blacklist.containers[base_id] then
		return
	end


	log("triggering pick container event with ref = %s", ref)
    ---@type herbert.MQL.events.pick_container
    local payload = {
        ref = ref,
        obj = ref.object,
        is_organic = common.is_organic(ref, base_id),
        block = false,
        claim = false,
        container_cls = suggested_container,
        scripted = (ref:testActionFlag(tes3.actionFlag.useEnabled) == false),
        base_id = base_id,
    }
    event.trigger(EVENT_IDS.pick_container, payload, {filter = ref.object.objectType})

	if payload.container_cls and not payload.block then
		event.trigger(EVENT_IDS.container_picked, payload, {filter = ref.object.objectType})
	end
end

local rational_names_common = include("RationalNames.common")

--- Gets the name of an item.
--- This function exists to ensure this mod plays nicely with Rational Names.
---@param item herbert.MQL.Item.Physical
---@return string
function common.get_item_name(item)
	return rational_names_common and rational_names_common.getDisplayName(item.object.id:lower())
		or item.object.name
end
return common