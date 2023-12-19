local Class = require("herbert100.Class")
local defns = require("herbert100.more quick loot.defns")
local log = require("herbert100.Logger")(defns)

local config = require("herbert100.more quick loot.config") ---@type MQL.config

local base = require("herbert100.more quick loot.managers.abstract.base") ---@type MQL.Manager
local Chance_Item = require("herbert100.more quick loot.Item").Chance


--[[## Chance Manager
This manager is subclassed whenever creating a manager in which items have "take chances", i.e.
each item has a chance of being taken successfully, or unsuccessfully.
]]
---@class MQL.Manager.Chance : MQL.Manager
---@field cant_loot MQL.defns.cant_loot? if not `nil`, it explains why this manager cant loot
---@field items MQL.Item.Chance[] the items being managed
---@field config MQL.config.Manager.Chance
local Chance = Class({name="Chance Manager", parents={base}})

function Chance:_make_items() 
    for i,v in ipairs(self.ref.object.inventory.items) do
        self.items[i] = Chance_Item{
            object=v.object, 
            count=v.count,
            take_chance = self:calc_item_chance(v.object)
        } ---@type MQL.Item.Chance
    end
end


function Chance:update_item_chances()
    local new_labels = {}
    for index, item in ipairs(self.items) do
        item.take_chance = self:calc_item_chance(item.object)
        item:update_totals()
        item:make_label()
        new_labels[index] = item.label
    end
    self.gui:update_item_labels(new_labels)
end

--- calculate the chance of successfully taking this item. this is called before the UI is created.
---@param item tes3item
---@return integer take_chance the chance of successfully taking one copy of this item. should be a number between 0 and 100
function Chance:calc_item_chance(item) return 100 end


--- this is called whenever the player tries to take an object and fails. 
---@param item MQL.Item.Chance the item the player failed to take
---@param count integer? how many items the player tried to take
---@return boolean got_lucky if `true`, the player got lucky and they will successfully take the item. if `false`, they didn't get lucky and will fail to take the item.
function Chance:luck_override(item, count)
    return tes3.mobilePlayer.luck.current >= 260 or math.random(100) <= 0.5 * (tes3.mobilePlayer.luck.current - 30)
end

--[[
--- this function is called whenever `item` is taken successfully
---@param item MQL.Item.Chance
---@param count integer the number of items to take
---@param take_stack boolean if this is the whole stack of items
---@param only_one boolean `true` if only one item is being taken, `false` if called from `take_all`
---@return boolean item_removed `true` if the item was removed, `false` otherwise.
function Chance:on_successful_take(item, count, take_stack, only_one) return false end
]]


--- this function is called whenever `item` is taken successfully
---@param item MQL.Item.Chance
---@param count integer the number of items to take
---@param only_one boolean `true` if only one item is being taken, `false` if called from `take_all`
---@return boolean item_removed `true` if the item was removed, `false` otherwise.
function Chance:on_successful_take(item, count, only_one) return false end


--- this function is called whenever `item` is taken not taken successfully
---@param item MQL.Item.Chance
---@param count integer the number of items to take
---@param only_one boolean `true` if only one item is being taken, `false` if called from `take_all`
---@return boolean item_removed `true` if the item was removed, `false` otherwise.
function Chance:on_unsuccessful_take(item, count, only_one) return false end




--- get the number of items to take
---@param item MQL.Item.Chance the item to take
---@param modifier_pressed boolean? is the modifier key pressed?
---@return integer count, boolean taking_all the number of things to take, and if this is all of them
function Chance:get_num_to_take(item, modifier_pressed)
    -- pull the `multiple_items` setting from the appropriate config file
    local mi    ---@type MQL.defns.chance_multiple_items
    if modifier_pressed then
        mi = self.config.multiple_items_m ---@type MQL.defns.chance_multiple_items
    else
        mi = self.config.multiple_items ---@type MQL.defns.chance_multiple_items
    end

    if mi == defns.chance_multiple_items.stack then
        return item.count, true

    elseif mi == defns.chance_multiple_items.total_chance then
        if item.total_take_chance >= self.config.mi_chance then
            return item.count, true
        end

    -- if we're to use the regular logic, do that 
    elseif mi == defns.chance_multiple_items.regular then
        return base.get_num_to_take(self, item, modifier_pressed)

    -- if we do total chance and regular
    elseif mi ==defns.chance_multiple_items.total_chance_and_regular then
        if item.total_take_chance >= self.config.mi_chance then
            -- first check that the total chance is good, then return whatever the regular calculation gives us
            return base.get_num_to_take(self, item, modifier_pressed)
        end
    end
    return 1, false
end


--- takes the currently activated item. also checks if the item can be looted, and if we're currently in a menu.
---@param self MQL.Manager.Chance
---@param modifier_pressed boolean? is the modifier key pressed?
---@return boolean item_taken `true` if the item was taken successfully (or a trap was activated), `false` otherwise.
function Chance:take_item(modifier_pressed)
    if self.cant_loot ~= nil then return false end

    -- past this point, we can loot normally. 

    local i = self.gui.index
    local item = self.items[i]

    local item_removed, chance, count, take_stack
    
    -- = item.take_chance

    if item.count > 1 then 
        count, take_stack = self:get_num_to_take(item, modifier_pressed)
        if take_stack then
            chance = item.total_take_chance
        else
            chance = item.take_chance
        end
    else
        count, take_stack = 1, true
        chance = item.take_chance
    end

    -- check if you succeed at taking the item
    if chance >= 100 or math.random(100) <= chance then 
        item_removed = self:on_successful_take(item, count, true)

    -- if you fail, do a luck throw
    elseif self:luck_override(item, count) then
        if config.UI.show_lucky_msg then
            tes3.messageBox{message="You got lucky."}
        end
        item_removed = self:on_successful_take(item, count, true)
    else
        -- you failed and got unlucky, time to pay the price.
        item_removed = self:on_unsuccessful_take(item, count, true)
    end

    -- if the item was removed, do the usual stuff.
    if item_removed then
        if take_stack then 
            -- delete the item from the list of items and from the GUI
            table.remove(self.items, i)
            self.gui:delete_selected_item()
            if #self.items == 0 then
                self.cant_loot = defns.cant_loot.empty
                self:do_cant_loot_action()
            end
        else
            item:remove_one()
            self.gui:update_item_labels{[i]=item.label}
        end
    end
    

    return true
end


-- Takes all items from the current target.
---@param modifier_pressed boolean? is the modifier key pressed?
---@return boolean looted_successfully `true` if the container was looted successfully, false otherwise
function Chance:take_all_items(modifier_pressed)
    if self.cant_loot then return false end

    -- play the sound once
    tes3.playItemPickupSound { item = self.items[1].object, pickup = true }
    
    local remaining_items = {} -- will keep track of what wasn't taken

    local count, take_stack, chance, item_removed
    for _, item in ipairs(self.items) do
        -- skip this item if it's minimum chance is too low.
        if item.take_chance < self.config.take_all_min_chance then goto continue end
        
        if item.count > 1 then 
            count, take_stack = self:get_num_to_take(item, modifier_pressed)
            if take_stack then
                chance = item.total_take_chance
            else
                chance = item.take_chance
            end
        else
            count, take_stack = 1, true
            chance = item.take_chance
        end


            -- check if you succeed at taking the item
        if chance >= 100 or math.random(100) <= chance then 
            item_removed = self:on_successful_take(item, count, false)

        -- if you fail, do a luck throw
        elseif self:luck_override(item, count) then 
            if config.UI.show_lucky_msg then 
                tes3.messageBox{message="You got lucky."}
            end
            item_removed = self:on_successful_take(item, count, false)
        else
            -- you failed and got unlucky, time to pay the price.
            item_removed = self:on_unsuccessful_take(item, count, false)
        end

        if not item_removed then 
            remaining_items[#remaining_items+1] = item
        else 
            -- if the item was removed, but the whole stack wasn't taken
            if not take_stack then
                item:remove_one()
                remaining_items[#remaining_items+1] = item
            end
        end
        ::continue::
    end
    
    -- force the players inventory to update 
    tes3ui.forcePlayerInventoryUpdate()

    -- remake the container
    self.items = remaining_items
    self.gui:make_container_items(self.items)
    
    -- show the appopriate messages, and update the container status
    if #remaining_items > 0 then
        if config.UI.show_msgbox then tes3.messageBox(self.loot_verb .. " all desired items.") end
        if log > 1  then log:debug("CHANCE: " .. self.loot_verb .. " all desired items.") end

        self:update_container_status()
    else
        if config.UI.show_msgbox then tes3.messageBox(self.loot_verb .. " all items.") end
        if log > 1  then log:debug("CHANCE: " .. self.loot_verb .. " all items.") end

        self.cant_loot = defns.cant_loot.empty
        self:do_cant_loot_action()
    end
    return true
end


return Chance