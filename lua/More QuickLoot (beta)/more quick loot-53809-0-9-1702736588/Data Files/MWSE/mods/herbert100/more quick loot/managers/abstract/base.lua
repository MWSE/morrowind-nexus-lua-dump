
local hlib = require("herbert100")

local Class, table_concat  = hlib.Class, hlib.table_concat
local defns = require("herbert100.more quick loot.defns")
local log = hlib.Logger(defns)

local config = require("herbert100.more quick loot.config")
local GUI = require("herbert100.more quick loot.GUI")
local Item = require("herbert100.more quick loot.Item").Generic


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
---@class MQL.Manager : Class
---@field ref tes3reference?            the reference of the container currently being looted, or `nil` if nothing is being looted. could be a reference to an NPC, creature, or container.
---@field items MQL.Item[]              a list of items in the container
---@field gui MQL.GUI                   the GUI being managed
---@field loot_verb string              the verb thats used in messageboxes when something is looted (eg "Looted", "Harvested", "Stole")
---@field config MQL.config.Manager?    the part of the config file that's relevant for this Manager
---@field cant_loot MQL.defns.cant_loot? records whether we can loot the container, and why we cant loot it.
---@field on_simulate fun(self)?         a function to run every frame while this manager is active, or `nil`
--
---@field stealing_from (tes3faction|tes3npc)?      the faction/NPC were stealing from, if applicable
---@field cant_loot_actions table<MQL.defns.cant_loot, fun(self:MQL.Manager)>  what we should do based on the current can't loot status
local Manager = Class({name="Quick Loot Manager", new_obj_func ="no_obj_data_table",

    --- make a new manager 
    ---@param self MQL.Manager the manager to make
    ---@param ref tes3reference reference of the container thats being looted
    ---@param name_prefix string? any prefix to place before the name
    init = function(self, ref, name_prefix)
        self.ref = ref
        -- Clone the object if necessary.
        self.ref:clone()


        self:_update_stealing_info()

        self:_initialize()

        self.items = {}

        self:_make_items()

        local container_name = self:_get_container_label()
        if name_prefix then 
            container_name = name_prefix .. container_name
        end

        local key_btn_info = self:_get_key_btn_info()
        
        self.gui = GUI(container_name, key_btn_info)

        self:update_container_status()
    end,

},{loot_verb = "Looted"}) -- base manager uses the general config

Manager.config = config

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
    function Manager:_update_stealing_info()
        local owner = tes3.getOwner{reference=self.ref}

        if owner and (not owner.playerJoined or self.ref.attachments.variables.requirement > owner.playerRank) then
            self.stealing_from = owner
        end
    end

    --- any initialization that should be done before objects are made
    function Manager:_initialize() end 

    --- make the `key_btn_info` used by the GUI.
    ---@param self MQL.Manager
    ---@return MQL.GUI.key_btn_info
    function Manager:_get_key_btn_info()
        if self.stealing_from ~= nil then
            return {
                take = {label = "Steal", pos = 0.05},
                take_all = {label = "Steal All", pos = 0.5},
                open = {label="Open", pos = 0.95}
            }
        end
        return {
            take = {label = "Take", pos = 0.05},
            take_all = {label = "Take All", pos = 0.5},
            open = {label="Open", pos = 0.95}
        }
    end



    --- makes the label string for this container
    ---@return string label
    function Manager:_get_container_label()
        if self.stealing_from ~= nil then 
            return string.format("%s (owned by %s)", self.ref.object.name, self.stealing_from.name)
        else
            return self.ref.object.name
        end
    end

    --- make the list of `items` that are going to be managed
    function Manager:_make_items()
        for i,v in ipairs(self.ref.object.inventory.items) do
            self.items[i] = Item{object = v.object, count = v.count} ---@type MQL.Item
        end
    end

end
-- disable the manager. useful for hiding it and blocking its functionality without destroying it. it can be re-enabled by using the `update_container_status` method.
function Manager:disable()
    self.cant_loot = defns.cant_loot.disabled
    self.gui:hide()
end

--- this deletes the container being managed. currently used to "Dispose" and "Destroy plants" 
function Manager:destroy_container()
    self.ref:delete()
    -- self.gui:destroy()
end


--- makes the manager update the status of the container it's managing. this is useful to checking if the container is empty, locked, etc
-- this will end up getting called after an item is taken, because the target will temporarily be set to `nil`
function Manager:update_container_status()
    if log > 1 then log:debug("BASE: updating container status") end

    if self.ref == nil then
        self.cant_loot = defns.cant_loot.no_target
    -- if the container is scripted, and if we're not allowing scripted containers,
    elseif self.ref:testActionFlag(tes3.actionFlag.useEnabled) == false
        and config.show_scripted == defns.show_scripted.dont 
    then
    -- elseif self.ref:testActionFlag(tes3.actionFlag.onActivate) and config.show_scripted == defns.show_scripted.dont then
    
        self.cant_loot = defns.cant_loot.cant_see


    else
        local additional_obstacle_found = self:_do_additional_cant_loot_checks()


        -- no additional obstacles were found, so keep looking for obstacles
        if not additional_obstacle_found then
            if #self.items == 0  then
                self.cant_loot = defns.cant_loot.empty
            else
                -- there were no obstacles
                self.cant_loot = nil
            end
        end
    end


    if self.cant_loot ~= nil then 
        self:do_cant_loot_action()
        -- self.cant_loot_actions[self.cant_loot](self)
    else
        if log > 1 then log:debug("BASE: no obstacles found. inventory_size: " .. #self.ref.object.inventory)  end
        self.gui:show()

        if self.gui.blocked then
            self.gui:make_container_items(self.items)
        end
        
    end
end

--- do manager specific checks to see if you can't loot something
---@return boolean obstacle_found `true` if an obstacle was found, `false` otherwise.
function Manager:_do_additional_cant_loot_checks() return false end



function Manager:do_cant_loot_action()
    if log > 1 then 
        log("BASE: about to do a cant loot action, with self.cant_loot = " .. self.cant_loot)
    end
    self.cant_loot_actions[self.cant_loot](self)
end


Manager.cant_loot_actions = {
    [1] = function(self) self.gui:hide() end,
    [2] = function(self) self.gui:block_and_show_msg("You can't see inside this container.") end,
    [3] = function(self) self.gui:block_and_show_msg("Empty") end,

}
-- make it so that cant_loot_actions can be concatenated, and it returns the concatenated table, with its metatable set to allow 
-- concatenation
setmetatable(Manager.cant_loot_actions, {
    __concat = function(cant_loot_actions, subcls_cant_loot_actions)
        return setmetatable(table_concat(cant_loot_actions, subcls_cant_loot_actions), getmetatable(cant_loot_actions))
    end
})


--- get the number of items that should be taken, based on current config settings.
--- should only be called if `item.count > 1`
---@param item MQL.Item the item to take
---@param modifier_pressed boolean? is the modifier key pressed?
---@return integer count, boolean take_stack  how many to take, and if we're taking all
function Manager:get_num_to_take(item, modifier_pressed)

    -- if the weight of the object is 0 (e.g. it's "Gold"), then we should always take it
    if item.total_weight == 0 then
        return item.count, true
    end

    -- our setting, since it's going to be checked a bunch.
    -- we'll use the `multiple_items` setting if the modifier IS NOT being pressed
    -- and the `multiple_items_m` setting if the modifier key IS being pressed.
    local mi
    do -- set `mi`
        if modifier_pressed then 
            -- log "BASE: modifier key IS being held, so using mi_m"
            mi = config.multiple_items_m
        else
            -- log "BASE: modifier key IS NOT being held, so using mi"
            mi = config.multiple_items
        end
    end


    -- TAKE STACK
    if mi == defns.multiple_items.stack then return item.count, true

    -- TAKE ONE
    elseif mi == defns.multiple_items.one then return 1, false

    -- now we do the hard part

    -- PAST THIS POINT, THE FAIL CONDITION WILL BE TO TAKE 1 ITEM


    -- RATIO OR WEIGHT
    elseif mi == defns.multiple_items.ratio_or_total_weight then
        -- log "BASE: mi is 'ratio' OR 'total_weight'"
        if item.total_value / item.total_weight >= config.mi_ratio or item.total_weight <= config.mi_tweight then
            log "BASE: ratio condition OR total weight condition passed, so taking stack"
            return item.count, true
        end
        log "BASE: both conditions failed, so taking 1"
    

    -- RATIO
    elseif mi == defns.multiple_items.ratio then
        -- log "BASE: mi is 'ratio'"
        if item.total_value / item.total_weight >= config.mi_ratio then
            log "BASE: ratio check passed, so taking stack"
            return item.count, true
        end
        -- log "BASE: ratio check failed, so taking 1"
        

    -- WEIGHT
    elseif mi == defns.multiple_items.total_weight then
        -- log "BASE: mi is 'total_weight'"
        if item.total_weight <= config.mi_tweight then 
            -- log "BASE: weight check passed, so taking stack"
            return item.count, true
        end
        -- log "BASE: weight check failed, so taking 1"


    -- RATIO AND WEIGHT
    elseif mi == defns.multiple_items.ratio_and_total_weight then
        -- log "BASE: mi is 'ratio' AND 'total_weight'"
        if item.total_weight <= config.mi_tweight and item.total_value / item.total_weight >= config.mi_ratio then
            return item.count, true
        end
    end
 
    if log.level > 1 then log "BASE: some `multiple_items` check failed. only taking one item." end
    return 1, false
end

--- takes the currently activated item. also checks if the item can be looted, and if we're currently in a menu.
---@param modifier_pressed boolean? is the modifier key pressed?
---@return boolean item_taken `true` if the item was taken successfully (or a trap was activated), `false` otherwise.
function Manager:take_item(modifier_pressed)
    if self.cant_loot ~= nil then return false end

    -- past this point, we can loot normally. 
    local i = self.gui.index
    local item = self.items[i]

    -- how many items to take, and if that's all the items
    -- we'll start out by saying that we're only taking one item, and that's all the items
    -- if there's more than one item to take, we'll update this accordingly
    local count, take_stack = 1, true

    if item.count > 1 then
        if log.level > 1 then log(("BASE: calculating how many items to take with\n\t\z
                count            = %i\n\t\z
                config.mi        = %i\n\t\z
                config.mi_m      = %i\n\t\z
                modifier_pressed = %s\n\t\z
                "):format(
                item.count, config.multiple_items, config.multiple_items_m, tostring(modifier_pressed)
            ))
        end
        count, take_stack = self:get_num_to_take(item, modifier_pressed)
    end
    do -- actually take the item
        -- get the amount of items to take 
        
        
        -- make holding down ALT only take one item
        
        tes3.transferItem{from = self.ref, to = tes3.player, item = item.object, count = count, }

        if self.stealing_from then 
            if take_stack then 
                tes3.triggerCrime{type = 5, victim = self.stealing_from, value = item.total_value}
            else
                tes3.triggerCrime{type = 5, victim = self.stealing_from, value = item.object.value}
            end
        end

        if config.UI.show_msgbox then
            tes3.messageBox{ message = table.concat({self.loot_verb, count, item.object.name}," ")}
        end

        if log > 1 then log(table.concat({"BASE:",self.loot_verb, count, item.object.name, "take_stack =", tostring(take_stack)}," ")) end
    end
    -- if we're taking everything
    if take_stack then 
        -- delete the item from the list of items.
        table.remove(self.items, i)

        -- check if the container is now empty
        if #self.items == 0 then
            --if it is, set the `cant_loot` status to empty and do the appropriate action
            self.cant_loot = defns.cant_loot.empty
            self:do_cant_loot_action()
            -- self.gui:block_and_show_msg("Empty")
        else
            -- container is not empty, so just delete the currently selected item from the `gui`.
            self.gui:delete_selected_item()
        end
    else
        -- we're only taking one thing, so update the count and the label.
        item:remove_one()
        self.gui:update_item_labels{[i]=item.label}
    end
    return true
end



-- Takes all items from the current target.
---@param modifier_pressed boolean? is the modifier key pressed?
---@return boolean looted_successfully `true` if the container was looted successfully, false otherwise
function Manager:take_all_items(modifier_pressed)
    if self.cant_loot then return false end
    -- play the sound once
    tes3.playItemPickupSound {item = self.items[1].object, pickup = true }

    -- if we should invert modifier key behavior when taking all, do that
    if self.config.mi_inv_take_all then
        modifier_pressed = not modifier_pressed
    end
    local remaining_items = {}
    local total_crime = 0
    for _, item in ipairs(self.items) do
        -- if the item wasn't removed, add it to the list of unremoved items

        do -- actually take the items
            local count, take_stack = 1, true
            if item.count > 1 then
                count, take_stack = self:get_num_to_take(item, modifier_pressed)

                -- if we're taking everything
                if take_stack then
                    total_crime = total_crime + item.total_value
                else
                    -- we're taking one item from the stack, and leaving the rest behind
                    total_crime =total_crime + item.object.value

                    -- remove one item
                    item:remove_one()
                    remaining_items[#remaining_items+1] = item
                end
            else
                -- there's only one item, and we're taking it
                total_crime = total_crime + item.object.value
            end

            tes3.transferItem{from = self.ref, to = tes3.player, 
                item = item.object, count = count, playSound=false, updateGUI = false
             }
        end
    end

    -- we've now finished iterating through the container and taking all the items we wanted to take

    -- do the crime if we're stealing
    if self.stealing_from then
        tes3.triggerCrime{type = 5, victim = self.stealing_from, value = total_crime}
    end

    
    -- update the items in the `Manager` and in the `GUI`
    self.items = remaining_items
    self.gui:make_container_items(self.items) -- update the items in the GUI

    -- update the items in the player's inventory
    tes3ui.forcePlayerInventoryUpdate()

    -- if there are items remaining
    if #self.items > 0 then
        if config.UI.show_msgbox then tes3.messageBox(self.loot_verb .. " all desired items.") end
        if log > 1  then log:debug("BASE: " .. self.loot_verb .. " all items.") end

        -- update the status of the container
        self:update_container_status()
    else
        -- there are no items remaining
        if config.UI.show_msgbox then tes3.messageBox(self.loot_verb .. "all items.") end
        if log > 1  then log:debug("BASE: " .. self.loot_verb .. " all desired items.") end

        -- mark the container empty
        self.cant_loot = defns.cant_loot.empty
        self:do_cant_loot_action()
    end
    return true
end


function Manager:self_destruct()
    if log > 2 then log:trace("BASE: manager is self destructing for some reason.") end
    self.gui:destroy()
    -- self = nil
end





return Manager