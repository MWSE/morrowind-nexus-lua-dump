
local defns = require("herbert100.more quickloot.defns")
local config = require("herbert100.more quickloot.config")
local GUI = require("herbert100.more quickloot.GUI")
local Physical_Item = require("herbert100.more quickloot.Item").Physical

local i18n = mwse.loadTranslations("herbert100.more quickloot")

local hlib = require("herbert100")
local Class = hlib.Class
local utils = require("herbert100.Class.utils")
local log = hlib.Logger("More QuickLoot/base") ---@type herbert.Logger
local mi_cfg = config.reg.mi
local UI_cfg = config.UI
local M_events = defns.events.Manager

---@class MQL.Manager.stack_info
---@field index integer the index the item occupies
---@field num_removed integer the number of items removed
---@field value integer the value of the items in the sack


--[[## Base Manager
This is the core of every QuickLoot menu that appears. It determines all logic surrounding
1) What items appear
2) How the controls are labeled
3) What happens when the player tries to take an item, and how this is affected by the current state of the container.
4) How the name label of the container is formatted.
5) When the container should be destroyed (if applicable).

The `Manager` **does not** justify its own existence. The `main.lua` file is entirely responsible for determining 
when a `Manager` should and shouldn't be active, with **one exception**: the `on_simulate` function.

Certain `Manager`s will have an `on_simulate` function defined. It works as follows:
- Whenever `main.lua` creates a new `Manager`, it checks whether an `on_simulate` function exists.
- If `on_simulate` exists, then that function will be registered to the `simulate` event for every frame that `Manager` is active.
- `on_simulate` should return a `boolean`, called `keep_going`. 
- returning `false` indicates that the `Manager` should be destroyed. And in this event, `main.lua` will try to create a new `Manager` if possible.
- returning `true` signifies that the `on_simulate` function should keep running every frame (for the mean-time).

**NOTE:** `on_simulate` will also get deregistered if `main.lua` decides to kill the `Manager` for whatever reason.

The `on_simulate` function is supposed to allow `Manager`s to perform on-the-fly updates, and make context-specific judgements on whether their state is still valid.
- Here, `context-specific` means things that can change without the player looking at another activation target/opening a menu first.
- The main example is Pickpocketing, where `on_simulate` does the following:
    - ask `main.lua` to delete the `Pickpocket` manager whenever the player uncrouches
    - update the "take chances" whenever the player's detection status changes.
]]
---@class MQL.Manager : herbert.Class
---@field ref tes3reference            the reference of the container currently being looted, or `nil` if nothing is being looted. could be a reference to an NPC, creature, or container.
---@field items MQL.Item[]              a list of items in the container
---@field item_stack MQL.Manager.stack_info[] a stack of items that are being bought
---@field gui MQL.GUI                   the GUI being managed
---@field i18n_index string              the i18n index to use
---@field cant_loot MQL.defns.cant_loot? records whether we can loot the container, and why we cant loot it.
---@field on_simulate fun(self)?         a function to run every frame while this manager is active, or `nil`
---@field num_items integer the number of active items
---@field item_type MQL.Item the type of item being managed by this manager
---
---@field stealing_from (tes3faction|tes3npc)?      the faction/NPC were stealing from, if applicable
---@field ref_handle mwseSafeObjectHandle
---@field index integer the index of the currently selected item
---@field new fun(ref: tes3reference): MQL.Manager
local Manager = Class.new{name="Quick Loot Manager", new_obj_func ="no_obj_data_table",

    fields = {
        {"ref"},
        {"stealing_from"},
        {"cant_loot", tostring=utils.generators.table_find(defns.cant_loot)},
        {"index"},
        {"num_items", },
        {"items", tostring=utils.premade.array_tostring},

        {"ref_handle", factory = function(self) return tes3.makeSafeObjectHandle(self.ref) end},
        {"i18n_index", tostring=false, default="looted.regular"},
        {"item_type", tostring=false, default=Physical_Item},
        ---@param self MQL.Manager
        {"gui", factory=function(self)
            return GUI.new{
                name = self:_get_container_label(),
                key_labels = self:get_keylabels(),
                m_key_labels = self:get_m_keylabels(),
                status_text = self:_get_status_text(),
            }
        end}
    },
    --- make a new manager 
    ---@param self MQL.Manager the manager to make
    ---@param ref tes3reference reference of the container thats being looted
    init = function(self, ref)
        ref:clone()
        self.ref = ref
        self:_update_stealing_from()
    end,

    ---@param self MQL.Manager
    post_init = function (self)
        self:make_items()
        self:update(true)
    end

}




-- -----------------------------------------------------------------------------
-- SECRET METHODS. 
-- -----------------------------------------------------------------------------
do
    --[[ these are usually only called during object creation, and probably won't need to be changed very much
    they're responsible for:
    - checking who we're stealing from
    - initializing the object (this is where any initial computations should be done. currently used by `Pickpocket` and `Organic`)
    - making the list of items being managed (or skills, in the case of the `Training` manager)
    - generating the name that will appear on the container
    - generating the button prompts on the GUI
    ]]

    --- set internal information about any theft that's happening. updates the `stealing_from` field.
    ---@param self MQL.Manager
    function Manager:_update_stealing_from()
        local owner = tes3.getOwner{reference=self.ref}

        if owner and (not owner.playerJoined or self.ref.attachments.variables.requirement > owner.playerRank) then
            self.stealing_from = owner
        end
    end
    ---@return MQL.GUI.Key_Label.keybinds?
    function Manager:get_keylabels()
        if self.stealing_from then
            return {open="Open", take="Steal", take_all="Steal All"}
        end
        return {open="Open", take="Take", take_all="Take All"}
    end

    ---@return MQL.GUI.Key_Label.keybinds?
    function Manager:get_m_keylabels() end




    
    function Manager:_get_status_text()
        if self.stealing_from then
            return string.format("Owned by %s", self.stealing_from.name)
        end
    end


    --- makes the label string for this container
    ---@return string label
    function Manager:_get_container_label()
        if config.show_scripted == defns.show_scripted.prefix then
            if  (self.ref:testActionFlag(tes3.actionFlag.useEnabled) == false) then
                return "(*) " .. self.ref.object.name 
            end
        end
        return self.ref.object.name 
    end

    --- make the list of `items` that are going to be managed
    function Manager:_make_items()
        self:add_items()
        local p = {owner=self.stealing_from, dist=config.reg.sn_dist, container_filter=config.reg.sn_cf}
        self:add_nearby_items(p)
    end
end
-- disable the manager. useful for hiding it and blocking its functionality without destroying it. it can be re-enabled by using the `update_container_status` method.
function Manager:disable()
    self.cant_loot = defns.cant_loot.disabled
    if self.inventory_outdated and UI_cfg.update_inv_on_close then
        tes3ui.forcePlayerInventoryUpdate()
        self.inventory_outdated = false
    end
    self.gui:hide()
end


-- update the `cant_loot` status
function Manager:update_cant_loot()

    -- check if the target actually exists
    if self.ref == nil then
        self.cant_loot = defns.cant_loot.no_target
    -- scripted container check
    elseif config.show_scripted == defns.show_scripted.dont and self.ref:testActionFlag(tes3.actionFlag.useEnabled) == false then
        self.cant_loot = defns.cant_loot.cant_see

    -- check if the container is empty
    elseif self.num_items == 0 then
        self.cant_loot = defns.cant_loot.empty
    -- otherwise, clear the `cant_loot` flag
    else
        self.cant_loot = nil
    end
end

--- makes the manager update the status of the container it's managing. this is useful to checking if the container is empty, locked, etc
-- this will end up getting called after an item is taken, because the target will temporarily be set to `nil`
function Manager:update(force_remake_items)
    log:debug("updating container status")

    self:update_cant_loot()

    if self.cant_loot then
        self:do_cant_loot_action()
    else
        self.gui:show()
        -- if blocked, remake the items in the UI and set the index
        if self.gui.blocked or force_remake_items then
            self:remake_GUI_items()
            -- self:set_index(self.index, true)
        end
    end
end

function Manager:update_GUI_label()
    self.gui:set_name_label(self:_get_container_label())
end

function Manager:remake_GUI_items()
    self.gui:make_item_blocks(self.items)
    self.index = 0
    self:increment_index(true)
end


function Manager:do_cant_loot_action()
    log("about to do a can't loot action, with self.cant_loot = %s", self.cant_loot)
    -- no target
    if self.cant_loot == defns.cant_loot.no_target then
        self.gui:hide()
    -- scripted container
    elseif self.cant_loot == defns.cant_loot.cant_see then
        self.gui:block_and_show_msg("You can't see inside this container.")
    -- empty
    elseif self.cant_loot == defns.cant_loot.empty then
        self.gui:block_and_show_msg("Empty") 
        if self.inventory_outdated and UI_cfg.update_inv_on_close then
            tes3ui.forcePlayerInventoryUpdate()
            self.inventory_outdated = false
        end
    end
end

local function logmsg_should_take_stack(item, modifier_pressed) return
    [[calculating how many copies to take of %s
    user setting = %q. modifier held? %s]],
    item, table.find(defns.mi, modifier_pressed and mi_cfg.mode_m or mi_cfg.mode), modifier_pressed
end

--- get the number of items that should be taken, based on current config settings.
--- should only be called if `item.count > 1`
---@param item MQL.Item the item to take
---@param modifier_pressed boolean? is the modifier key pressed?
---@return boolean take_stack whether we should take the whoel stack
function Manager:should_take_stack(item, modifier_pressed)
    log(logmsg_should_take_stack, item, modifier_pressed)
    -- if the weight of the object is 0 (e.g. it's "Gold"), then we should always take it
    if item.weight == 0 or item.count == 1  then return true end

    -- our setting, since it's going to be checked a bunch.
    -- we'll use the `multiple_items` setting if the modifier IS NOT being pressed
    -- and the `multiple_items_m` setting if the modifier key IS being pressed.
    local mi = modifier_pressed and mi_cfg.mode_m or mi_cfg.mode


    -- TAKE STACK
    if mi == defns.mi.stack then return true end

    -- TAKE ONE
    if mi == defns.mi.one then return false end


    -- RATIO OR WEIGHT
    if mi == defns.mi.ratio_or_total_weight then
        -- log "mi is 'ratio' OR 'total_weight'"
       return item.value / item.weight >= mi_cfg.min_ratio or item:total_weight() <= mi_cfg.max_total_weight
    

    -- RATIO
    elseif mi == defns.mi.ratio then
        -- log "mi is 'ratio'"
        return item.value / item.weight >= mi_cfg.min_ratio 

    -- WEIGHT
    elseif mi == defns.mi.total_weight then
        return item:total_weight() <= mi_cfg.max_total_weight 

    -- RATIO AND WEIGHT
    elseif mi == defns.mi.ratio_and_total_weight then
        -- log "mi is 'ratio' AND 'total_weight'"
        return item:total_weight() <= mi_cfg.max_total_weight and item.value / item.weight >= mi_cfg.min_ratio
    end
 
    log "some `multiple_items` check failed. only taking one item."
    return false
end

--- make a loot messagebox
---@param item MQL.Item the item being taken. if `nil`, then we assume all items are taken
---@param count integer the number of items taken. only applies if `item ~= nil`. Default: `1`
function Manager:make_msgbox(item, count)
    log("Successfully took %s", item)
    if UI_cfg.show_msgbox then
        tes3.messageBox(i18n(self.i18n_index, {count=count,item=item.object.name}))
    end
end

function Manager:make_i18n_msgbox(key, params, force_override)
    if UI_cfg.show_msgbox or force_override then
        tes3.messageBox(i18n(key, params))
    end
end

--- make a loot messagebox
function Manager:make_take_all_msgbox()
    if UI_cfg.show_msgbox then
        log("making take all msgbox with self.num_items=%s",self.num_items)
        if self.num_items > 0 then
            tes3.messageBox(i18n(self.i18n_index .. "_all_some_left"))
        else
            tes3.messageBox(i18n(self.i18n_index .. "_all_none_left"))
        end
    end
end

function Manager:none_taken_msgbox()
    if UI_cfg.show_msgbox then
        if self.num_items > 0 then
            tes3.messageBox(i18n("looted.take_all_no_items_taken_nonempty"))
        else
            tes3.messageBox(i18n("looted.take_all_no_items_taken"))
        end
    end
end

--- takes the currently activated item. also checks if the item can be looted, and if we're currently in a menu.
---@param modifier_pressed boolean? is the modifier key pressed?
---@return boolean should_block `true` if we should claim ownership of the event.
function Manager:take_item(modifier_pressed)
    if self.cant_loot ~= nil then return false end

    -- past this point, we can loot normally. 

    ---@diagnostic disable-next-line: assign-type-mismatch
    local item = self.items[self.index] ---@type MQL.Item.Physical

    log("trying to take %s", item)
    if item.status < defns.item_status.ok then
        if item.unavailable_reason then
            item:make_unavailable_msgbox()
        end
        self:update_index()
        return true
    end

    -- get the amount of items to take 
    local full_stack = self:should_take_stack(item, modifier_pressed)
    

    local num_taken = item:take(full_stack, true)

    if num_taken == 0 then return true end

    -- log("successfully took %s", item)
    -- at this point we know the item wasn't empty prior to looting

    local item_value = item.value * num_taken

    self:do_crime(item_value)

    -- add it to the item stack
    table.insert(self.item_stack, {index=self.index,num_removed=num_taken,value=item_value})
    
    self.inventory_outdated = true
    self:make_msgbox(item,num_taken)
    self.gui:update_item_name_label(self.index)

    -- if the item is now empty, update the number of items
    if item.status == defns.item_status.empty then self.num_items = self.num_items - 1 end

    self:update_index()

    return true
end

--- do the crime that happens when this amount of item is taken
---@param crime_value integer how much the crime is worth
function Manager:do_crime(crime_value)
    if self.stealing_from ~= nil then
        tes3.triggerCrime{type=tes3.crimeType.theft, value = crime_value, victim=self.stealing_from}
    end
end

---@param item MQL.Item.Physical
function Manager:take_all_item_check(item) return item:get_value_weight_ratio() >= config.reg.take_all_min_ratio end

-- Takes all items from the current target.
---@param modifier_pressed boolean? is the modifier key pressed?
---@return boolean looted_successfully `true` if the container was looted successfully, false otherwise
function Manager:take_all_items(modifier_pressed)
    if self.cant_loot then return false end
    -- play the sound once

    tes3.playSound{sound="Item Misc Up", reference=tes3.player}
    log("taking all. modkey pressed? %s", modifier_pressed)
    -- if we should invert modifier key behavior when taking all, do that
    if mi_cfg.inv_take_all then
        modifier_pressed = not modifier_pressed
    end

    local num_taken, item_value
    local total_crime = 0
    local took_an_item = false -- if we took at least one item
    for _, item in ipairs(self.items) do
        ---@cast item MQL.Item.Physical
        if item:can_take() and self:take_all_item_check(item) then

            local take_stack = self:should_take_stack(item, modifier_pressed)

            num_taken = item:take(take_stack, false)

            if num_taken > 0 then
                took_an_item = true
                item_value = item.value * num_taken
                total_crime = total_crime + item_value
                table.insert(self.item_stack, {index=self.index, num_removed=num_taken,value=item_value})
                if item.status == defns.item_status.empty then
                    self.num_items = self.num_items - 1
                end
                log("take all: took %s", item)
            end
        else
            log("take all: skipping %s", item)
        end

    end 
    -- stop here if we didnt actually take anything
    if not took_an_item then 
        self:none_taken_msgbox()
        return true
    end

    -- we've now finished iterating through the container and taking all the items we wanted to take

    -- do the crime if we're stealing
    self:do_crime(total_crime)
    
    self:make_take_all_msgbox()

    -- update the items in the player's inventory
    tes3ui.forcePlayerInventoryUpdate()
    self.inventory_outdated = false

    -- update GUI and the current index
    self.gui:update_all_item_labels(true)
    if not self:update_index() then
        self.gui:update_visible_items(self.index)
    end

    return true
end


function Manager:self_destruct()
    log:trace("manager is self destructing for some reason.")
    self.gui:destroy()
    -- update the inventory if we took an item
    if self.inventory_outdated and UI_cfg.update_inv_on_close then 
        self.inventory_outdated = false
        tes3ui.forcePlayerInventoryUpdate()
    end
    -- self = nil
end



-- sort `self.items`, taking into account current config settings
function Manager:_sort_items()
    local sort_items = UI_cfg.sort_items
    if sort_items == defns.sort_items.dont then return end

    if sort_items == defns.sort_items.weight then
        table.sort(self.items, Physical_Item.weight_comp)
        return
    end

    if config.compat.bg and tes3.mobilePlayer.mercantile.current < include("buyingGame.common").config.knowsPrice then 
        return
    end

    if sort_items == defns.sort_items.value_weight_ratio then
        table.sort(self.items, Physical_Item.value_weight_comp)
    else
        table.sort(self.items, Physical_Item.value_comp)
    end
    

end

function Manager:update_num_items()
    self.num_items = #self.items
    for _, item in ipairs(self.items) do
        if item.status < defns.item_status.unavailable then
            self.num_items = self.num_items - 1
        end
    end
end

--- makes the items. GUI will need to be udpated after this
function Manager:make_items()
    self.item_stack = {}
    self.items = {}
    self:_make_items()

    self:update_num_items()

    self.inventory_outdated = false
    self:_sort_items()

    if log >= log.LEVEL.TRACE then
        log:trace "remade items. printing them..."
        for i,v in ipairs(self.items) do
            log:trace("%i: %s", i, v)
        end
    end
end

--- happens when the modifier key is held and the open button is pressed
---@return boolean should_block if true, the event should be blocked.
function Manager:undo()
    -- if the container is empty, you can still put stuff back
    if #self.item_stack == 0 then return false end
    if self.cant_loot and self.cant_loot ~= defns.cant_loot.empty then return false end 
        
        
    ---@type MQL.Manager.stack_info
    local stack = table.remove(self.item_stack) -- removes last element and returns it
    local item = self.items[stack.index]
    if stack.num_removed <= 0 then
        log:error("item is on the stack with 0 count: %s", item)
        return true end
    if item.count == 0 then
        self.num_items = self.num_items + 1
    end

    if item:is_instance_of(Physical_Item) then
        ---@cast item MQL.Item.Physical
        item:put_back(stack.num_removed, true)
    else
        item.count = item.count + stack.num_removed
    end
    

    -- if this was the last item, update the GUI
    if self.cant_loot == defns.cant_loot.empty then
        self:update()
    else
        -- otherwise, update the item label (to recompute its `count`), and then set the index to be the newly readded item
        self.gui:update_item_name_label(stack.index)
        self:set_index(stack.index, true)
    end
    

        
        
        
    return true
end



--- update the index of the currently selected item
---@param index integer the new indexed
---@param force_gui_update boolean? should the `GUI` be forced to update?
---@return boolean successful if the index was updated successfully
function Manager:set_index(index, force_gui_update)
    log("calling set_index(%i). self.index == %s", index, self.index)
    if self.cant_loot then return false end

    local item = self.items[index]

    if item == nil or item.status < defns.item_status.unavailable then return false end

    if index ~= self.index then
        event.trigger(M_events.item_selected, {index=index, item=item})
        self.gui:update_visible_items(index)
    elseif force_gui_update then
        self.gui:update_visible_items(index)
    end

    self.index = index
    
    return true
end

-- checks if the currently selected index is valid
function Manager:is_current_index_valid()
    return self.cant_loot == nil and self.items[self.index] and self.items[self.index].status >= defns.item_status.unavailable
end

function Manager:update_status_label() self.gui:set_status_label(self:_get_status_text()) end

--- checks if the current index is valid. if not, will set to next best index.
---@return boolean gui_updated
function Manager:update_index()
    -- dont do anything if the current index is okay
    if self.items[self.index].status >= defns.item_status.unavailable then return false end

    -- if its empty, make the container as empty
    if self.num_items == 0 then
        self.cant_loot = defns.cant_loot.empty
        self:do_cant_loot_action()
        return true
    else
        -- the current index is bad, and the container isnt empty
        -- try to increment the index, and if that fails, try to decrement it
        if self:increment_index(true) then
            return true
        else
            return self:decrement_index(true)
        end
    end
end

---@param force_gui_update boolean? should the `GUI` be forced to update?
function Manager:increment_index(force_gui_update)
    if self.cant_loot then return false end
    log "incrementing index"

    local item, index = nil, self.index---@type MQL.Item

    while true do
        index = index + 1
        item = self.items[index]
        if item == nil then return false end

        if item.status >= defns.item_status.unavailable then
            return self:set_index(index, force_gui_update)
        end
    end
end
---@param force_gui_update boolean? should the `GUI` be forced to update?
function Manager:decrement_index(force_gui_update)
    if self.cant_loot then return false end

    local item, index = nil, self.index---@type MQL.Item
    while true do
        index = index - 1
        item = self.items[index]
        if item == nil then return false end

        if item.status >= defns.item_status.unavailable then
            return self:set_index(index,force_gui_update)
        end
    end
end

--- do a modified open action
---@return boolean successful
function Manager:modified_open() return false end


--- mark/unmark an item as collected through TTIP
---@return boolean successful if we did it successfully
function Manager:ttip_mark_selected_as_collected()
    if not config.compat.ttip or self.cant_loot then return false end

    local item = self.items[self.index]

    if not item:is_instance_of(Physical_Item) then return false end

    local id, ttip_collected_tbl = item.object.id, tes3.player.itemData.data.rev_TTIP.items

    -- unmark an item if it has already been marked. otherwise, mark it
    if ttip_collected_tbl[id] == true then
        tes3.messageBox "Item unmarked"
        ttip_collected_tbl[id] = nil
    else
        tes3.messageBox "Item marked"
        ttip_collected_tbl[id] = true
    end

    self.gui:update_item_name_label(self.index)

    return true
end

--- gets the currently selected item
---@return MQL.Item?
function Manager:get_current_item()
    if self:is_current_index_valid() then
        return self.items[self.index]
    end
end



-- =============================================================================
-- ADD ITEMS
-- =============================================================================

---@alias MQL.Manager.obj_filter_fun fun(obj: tes3item|tes3ingredient|tes3misc): boolean, MQL.defns.item_status?, MQL.defns.unavailable_reason?


---@class MQL.Manager.add_items.params
---@field ref tes3reference? the reference of the structure that owns this item
---@field to tes3reference? the reference of the structure that wants to own this item
---@field related_ref tes3reference? the reference of the structure that owns this item
---@field obj_filter MQL.Manager.obj_filter_fun? 
--- if provided, this function should return `true` if the item should be yielded, and then it should return the status of the item and any reason it might be unavailable


-- adds the items from `ref`
---@param from tes3reference? the reference of the structure that owns this item
---@param to tes3reference? the reference of the structure that wants to own this item
---@param relref tes3reference? the reference of the structure that owns this item
---@param obj_filter MQL.Manager.obj_filter_fun? 
function Manager:add_items(from, to, obj_filter, relref)
    from = from or self.ref
    to = to or tes3.player

    local cls = self.item_type
    local obj, count
    log("adding items to %s\n\tfrom = %q, to = %q, related_ref = %q", self, from, to, relref)
    for _, stack in pairs(from.object.inventory.items) do ---@cast stack tes3itemStack
        obj = stack.object
        
        if obj.canCarry == false then goto next_stack end

        local yield, status, reason = true, nil, nil

        if obj_filter ~= nil then
            yield, status, reason = obj_filter(stack.object)
            if not yield then goto next_stack end
        end
        -- Account for restocking items,
        -- since their count is negative
        count = math.abs(stack.count)
        
        -- first yield stacks with custom data
        if stack.variables then
            log:trace("checking variables for stack of %q", obj.name)
            for _, data in pairs(stack.variables) do
                count = count - data.count
                table.insert(self.items, cls.new{from=from, to=to, object=obj, related_ref=relref,
                    data=data, count=data.count, status=status, unavailable_reason=reason
                })
            end
        end
        -- if there are items to add, add them
        if count > 0 then
            table.insert(self.items, cls.new{from=from, to=to, object=obj, related_ref=relref, 
                count=count, status=status, unavailable_reason=reason
            })
        end
        ::next_stack::
    end
end


---@class MQL.Manager.add_nearby_items.params : MQL.Manager.add_items.params
---@field dist nil|number               if provided, only things within this distance will be included
---@field container_filter MQL.defns.sn_cf?
---@field owner nil|tes3object        lets you specify the owner of an object. 
--- if `nil`, objects will be required to be unowned. if `false`, owners wont be checked. if a `tes3object`, then objects will be required to be owned by that object.
---@field check_locked boolean? should we care about containers being locked? default: true 

---@param p MQL.Manager.add_nearby_items.params
function Manager:add_nearby_items(p)
    -- only search nearby nearby containers if `search_nearby ~= nil`

    -- if we're not actually supposed to iterate this container, then return an empty iterator
    if (p.dist and p.dist <= 5) or p.container_filter == defns.sn_cf.no_other_containers then 
        return
    end

    log:trace("searching nearby containers")
    
    local ref = p.ref or self.ref
    local to = p.to or tes3.player

    -- container info
    local owner, pos = p.owner, ref.position
    local name = ref.object.name

    local dist, v_dist = p.dist, config.advanced.v_dist
    -- if we should iterate scripted scripted containers
    local allow_scripted = config.show_scripted == defns.show_scripted.no_prefix
    
    -- if we should only iterate containers that have the same base object
    local check_bobj = p.container_filter == defns.sn_cf.same_base_obj

    -- if we should only iterate organic containers
    local check_org = p.container_filter == defns.sn_cf.organic  -- info about which types of containers to filter

    local abs = math.abs
    local relref, obj_filter = p.related_ref, p.obj_filter
    for from in tes3.player.cell:iterateReferences(tes3.objectType.container) do
        if ref.lockNode then goto next_container end
        -- distance check
        if dist ~= nil then
            if pos:distanceXY(from.position) > dist or pos:heightDifference(from.position) > v_dist then goto next_container end
        end
        
        -- container filter check
        if check_bobj then
            if name ~= from.object.name then goto next_container end

        elseif check_org then
            if not from.object.organic then goto next_container end
        end
        
        -- do the owned by check and scripted container check
        if owner ~= false and owner ~= tes3.getOwner{reference=from}
        or allow_scripted == false and from:testActionFlag(tes3.actionFlag.useEnabled) == false
        then goto next_container end

        -- dont repeat the container
        if from == ref then goto next_container end

        log:trace("%s passed all checks", from.object.name)

        from:clone()
        
        self:add_items(from, to, obj_filter, relref)

        ::next_container::
    end
end

function Manager:make_item_tooltip()
    local item = self:get_current_item()
    if item then
        tes3ui.createTooltipMenu{item=item.object, itemData=item.data}
    end
end

function Manager:play_switch_sound()
    if UI_cfg.play_switch_sounds then
        tes3.playSound{sound=UI_cfg.play_switch_sounds, volume=0.75}
    end
end

return Manager