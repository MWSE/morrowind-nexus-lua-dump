local Class= require("herbert100.Class")
local defns = require "herbert100.more quickloot.defns"
-- living manager, ensures that `Services` will die as soon as we start sneaking or the target becomes nil
local Living = require("herbert100.more quickloot.managers.abstract.Living")
local Items = require("herbert100.more quickloot.Item")
local config = require "herbert100.more quickloot.config"
local Training_Item, Barter_Item = Items.Training, Items.Barter
local log = require("herbert100").Logger("More QuickLoot/Services")


local award_xp = config.compat.bxp and include("herbert100.barter xp overhaul.mod").award_barter_xp or nil


---@class MQL.Manager.Services : MQL.Managers.Living
---@field disposition integer the disposition of the seller
---@field items MQL.Item.Training[]|MQL.Item.Barter[] the skills that can be trained
---@field current_service MQL.defns.services the mode of service we're in 
---@field gold_stack integer the amount of gold
---@field item_stack MQL.Manager.stack_info[]
---@field is_buying boolean are we currently buying? if false, we are selling
---@field allowed_barter_obj_types table<tes3.objectType, boolean>
local Services = Class.new({name="Services Manager", parents={Living},
    -- after we've successfully made the menu, see if we should switch barter modes
    post_init = function (self)
        if config.barter.switch_if_empty and self.current_service == defns.services.barter and self.cant_loot == defns.cant_loot.empty then
            log("%s menu was empty, switching to %s menu", function () if self.is_buying then return "buying", "selling" else return "selling", "buying" end end)
            self:change_barter_mode()
        end
    end
}, {i18n_index = "looted.barter"})

-- initialize object
function Services:_initialize()
    self.allowed_services, self.allowed_barter_obj_types = self.get_allowed_services(self.ref)

    log("allowed services: %s", json.encode(self.allowed_services))

    self.current_service = config.services.default_service
    self:update_current_service()
end


--- get a `Set` of services that this `ref` provides
---@param ref tes3reference
---@return MQL.defns.services[] allowed_services
---@return  table<tes3.objectType, boolean>? allowed_barter_obj_types the types of bartering that are allowed, if bartering is allowed
function Services.get_allowed_services(ref)
    local allowed_services = {}
    local ai = ref.object.aiConfig

    local allowed_barter_obj_types
    -- see if we should barter
    if config.barter.enable then
        allowed_barter_obj_types = {
            [tes3.objectType.alchemy] = ai.bartersAlchemy or nil, 
            [tes3.objectType.armor] = ai.bartersArmor or nil, 
            [tes3.objectType.apparatus] = ai.bartersApparatus or nil, 
            [tes3.objectType.book] = ai.bartersBooks or nil, 
            [tes3.objectType.clothing] = ai.bartersClothing or nil, 
            [tes3.objectType.enchantment] = ai.bartersEnchantedItems or nil, 
            [tes3.objectType.ingredient] = ai.bartersIngredients or nil, 
            [tes3.objectType.light] = ai.bartersLights or nil, 
            [tes3.objectType.lockpick] = ai.bartersLockpicks or nil, 
            [tes3.objectType.miscItem] = ai.bartersMiscItems or nil, 
            [tes3.objectType.probe] = ai.bartersProbes or nil, 
            [tes3.objectType.repairItem] = ai.bartersRepairTools or nil, 
            [tes3.objectType.weapon] = ai.bartersWeapons or nil, 
        }
        -- if its not empty,
        if next(allowed_barter_obj_types) ~= nil then
            table.insert(allowed_services, defns.services.barter)
        else
            allowed_barter_obj_types = nil
        end
    end
    -- see if we should train
    if config.training.enable and ai.offersTraining then
        log("%s offers training", ref.object.name)
        table.insert(allowed_services, defns.services.training)
    end
    log("returning allowed_services: %s, allowed_barter_obj_types: %s", function ()
        return json.encode(allowed_services), json.encode(allowed_barter_obj_types)
    end)
    return allowed_services, allowed_barter_obj_types
end

--- see if this merchant allows any enabled services
---@param ref tes3reference
---@return boolean
function Services.allows_services(ref)
    -- check if the set of allowed services is nonempty
    return #Services.get_allowed_services(ref) > 0
end

-- switch services
function Services:modified_open()
    -- allow changing services if we can loot or if the reason is that the menu is empty
    -- (if we didn't allow this when the menu is empty, we wouldnt be able to train/sell after buying a merchaants inventory)
    if self.cant_loot == nil or self.cant_loot == defns.cant_loot.empty then
        log("changing current service")

        if #self.allowed_services > 1 then
            self:update_current_service(true)
        end

        return true
    end
    return false
end

--- updates the current service, making sure that it's valid. if `find_next == true`, it will try to find the next valid serivce
---@param find_next boolean? should we try to find the next current service?
function Services:update_current_service(find_next)

    -- if `find_next == true`, or if the service is invalid, keep changing the service until we find a valid one
    if find_next or not table.contains(self.allowed_services, self.current_service) then
        repeat
            self.current_service = (self.current_service + 1) % defns.misc.services_quotient
        until table.contains(self.allowed_services, self.current_service)
    end
    
    -- initialize the current service
    if self.current_service == defns.services.barter then
        self.item_stack = {}
        self.gold_stack = 0
        self.is_buying = config.barter.start_buying
    end
    -- if we're supposed to find the next one, we should remake the items and update the status labl
    if find_next then
        self:remake_items()
        self:update_status_label()
        self.gui:set_control_labels(self:_get_key_btn_labels())
        self.gui:set_control_m_labels(self:_get_key_btn_m_labels())
    end
    -- if we're bartering and the inventory is empty, switch modes
    if config.barter.switch_if_empty and self.current_service == defns.services.barter and self.cant_loot == defns.cant_loot.empty then
        log("%s menu was empty, switching to %s menu", function ()
            if self.is_buying then return "buying", "selling" else return "selling", "buying" end
        end)
        self:change_barter_mode()
    end
end



-- sort `self.items`, taking into account current config settings.
-- if bartering, we don't take into account buying game since we're only using the prices the merchant told us
-- if training, we sort skills alphabetically
function Services:_sort_items()
    local comp
    if self.current_service == defns.services.barter then

        local sort_items = config.UI.sort_items

        if sort_items == defns.sort_items.value_weight_ratio then
            comp = Barter_Item.value_weight_comp
        elseif sort_items == defns.sort_items.value then
            comp = Barter_Item.value_comp
        elseif sort_items == defns.sort_items.weight then
            comp = Barter_Item.weight_comp
        end
        -- if a sort function is defined and we're selling, sort in reverse order
        if comp and not self.is_buying and config.barter.selling.reverse_sort then
            local old_comp = comp
            comp = function(a,b) return old_comp(b,a) end
        end
    elseif self.current_service == defns.services.training then
        comp = function(i1,i2) 
            return tes3.getSkillName(i1.skill_id) < tes3.getSkillName(i2.skill_id)
        end
    end

    if comp then
        table.sort(self.items, comp)
    end
end

do -- UI functionality

    function Services:do_cant_loot_action()
        if self.cant_loot ~= defns.cant_loot.empty then Living.do_cant_loot_action(self); return end

        if self.current_service == defns.services.barter then
            if self.is_buying then
                self.gui:block_and_show_msg("Nothing left to buy")
            else
                self.gui:block_and_show_msg("Nothing left to sell")
            end
        else
            self.gui:block_and_show_msg("Empty")
        end

        if self.inventory_outdated and config.UI.update_inv_on_close then
            tes3ui.forcePlayerInventoryUpdate()
            self.inventory_outdated = false
        end
    end

     ---@param self MQL.Manager.Services
     function Services:_get_container_label()
        local service_name
        if self.current_service == defns.services.training then
            service_name = "training"
        elseif self.current_service == defns.services.barter then
            if self.is_buying then service_name = "buying" else service_name = "selling" end
        end
        return string.format("%s (%s)", self.ref.object.name, service_name)
    end


    function Services:_get_status_text()
        if self.current_service == defns.services.barter then
        -- gold gets removed from player if buying, added to player if selling
            local signed_gold = self:get_signed_gold()
            return string.format("YOUR GOLD: %s | SELLER GOLD: %s", tes3.getPlayerGold() - signed_gold, self.ref.mobile.barterGold + signed_gold)

        elseif self.current_service == defns.services.training then
            return string.format("YOUR GOLD: %s", tes3.getPlayerGold())
        end
    end

    function Services:_get_key_btn_labels()
        if self.current_service == defns.services.barter then
            return { take = (self.is_buying and "Buy") or "Sell", take_all = "Confirm", open = "Talk", }
        else
            return { take = "-", open = "Talk", take_all = "Train" }
        end
    end

    function Services:_get_key_btn_info()
        local key_btn_labels = self:_get_key_btn_labels()
        return {
            take = {label = key_btn_labels.take, pos = 0.05},
            take_all = {label = key_btn_labels.take_all, pos = 0.5},
            open = {label = key_btn_labels.open, pos = 0.95},
        }
    end

    function Services:_get_key_btn_m_labels()
        if self.current_service == defns.services.barter then
            return { take = "Stack", take_all = "Switch Mode", open = "Next", }
        elseif self.current_service == defns.services.training then
            return { take = false, take_all = false, open = "Next", }
        end

    end
    function Services:_get_key_btn_m_info()
        local key_btn_m_labels = self:_get_key_btn_m_labels()
        return {
            take = {label = key_btn_m_labels.take, pos = 0.05},
            take_all = {label = key_btn_m_labels.take_all, pos = 0.5},
            open = {label = key_btn_m_labels.open, pos = 0.95},
        }

    end
end

do -- delegate to children
    function Services:_make_items()
        if self.current_service == defns.services.training then
            self:_make_items_training()
        elseif self.current_service == defns.services.barter then
            self:_make_items_barter()
        end
    end


    ---@return boolean? should_block should the event be blocked?
    function Services:take_item(modifier_pressed)
        if self.current_service == defns.services.training then
            return self.cant_loot == nil -- block the event only if we can loot
        elseif self.current_service == defns.services.barter then
            return self:take_item_barter(modifier_pressed)
        end
    end

    ---@return boolean? should_block should the event be blocked?
    function Services:take_all_items(modifier_pressed)
        if self.current_service == defns.services.training then
            return self:take_all_items_training(modifier_pressed)
        elseif self.current_service == defns.services.barter then
            return self:take_all_items_barter(modifier_pressed)
        end
    end

    function Services:undo()
        if self.current_service == defns.services.barter then
            return self:undo_barter()
        else
            return false
        end
    end

    

end

do -- training functionality

    function Services:_make_items_training()
        -- special thanks to Hrnchamd for telling me how to determine which skills NPCs offer training in
    
        -- get the three highest skills. start each value off at an impossibly low value, just so we can compare them
        local first, second, third = -100, - 100, -100
        local first_id, second_id, third_id
        -- local skills = table_concat(self.ref.object.skills, {})
        log:trace("printing %s's skills.", self.ref.object.name) 
        for id, value in ipairs(self.ref.object.skills) do
            id = id - 1
            log:trace("%12s: %i", function() return tes3.getSkillName(id), value end)
            
            -- if value is bigger than first, bump up second and third, then update first
            if first < value then
                third_id, third = second_id, second
                second_id, second = first_id, first
                first_id, first = id, value
            elseif second < value then 
                third_id, third = second_id, second
                second_id, second = id, value
            elseif third < value then 
                third_id, third = id, value
            end
    
        end
        log(" %s's highest skills are:\n\t\z
                %s: %i\n\t\z
                %s: %i\n\t\z
                %s: %i\n\t\z
                ", function() return self.ref.object.name,
                    tes3.getSkillName(first_id), first,
                    tes3.getSkillName(second_id), second,
                    tes3.getSkillName(third_id), third
                end
            )
    
    
        -- i could probably write this in a for loop, but it's nice to take a break from for loops every once in a while
    
        self.items[1] = Training_Item{ref=self.ref, skill_id = first_id,  max_lvl = first,  merchant=self.ref.mobile, }
        self.items[2] = Training_Item{ref=self.ref, skill_id = second_id, max_lvl = second, merchant=self.ref.mobile, }
        self.items[3] = Training_Item{ref=self.ref, skill_id = third_id,  max_lvl = third,  merchant=self.ref.mobile, }
    
    end
    function Services:take_all_items_training(modifier_pressed)
        if modifier_pressed then return true end
        local item = self.items[self.index]
        log("trying to train %s", function () return tes3.getSkillName(item.skill_id) end)
        
        if item.status == defns.item_status.ok then
            -- special thanks to Hrnchamd for telling me how to remove gold from the player's inventory
            tes3.payMerchant{ merchant=self.ref.mobile, cost=item.value}
            tes3.playSound{ reference = tes3.player, sound = "Item Gold Down"}

            self.gui:set_status_label(self:_get_status_text())

            --do this after returning so we make sure the menu gets blocked. the player probably wont notice the delay.
            timer.delayOneFrame(function () 
                tes3.mobilePlayer:progressSkillToNextLevel(item.skill_id)
                item:update()
                self.gui:update_item_labels(self.index)  
            end)
            
        elseif item.status == defns.item_status.unavailable then
            tes3.messageBox(item.unavailable_reason)
        end
        return true
    end

end

do -- barter functionality
    
    
    --- change the current `barter_mode`
    function Services:change_barter_mode()
        self.is_buying = not self.is_buying
    
        self:remake_items()
        self.gui:set_control_labels(self:_get_key_btn_labels())
        self:update_status_label()
    end
    
    -- the amount of gold that should be added to the merchants gold reserves
    -- should be positive when buying and negative when selling
    function Services:get_signed_gold() return (self.is_buying and self.gold_stack) or -self.gold_stack end

    
    function Services:_make_items_barter()
        self.item_stack = {}
        self.gold_stack = 0
        self.items = {}
        
        local ref, check_stolen_from, obj_filter
        if self.is_buying then
            ref = self.ref
            obj_filter = function (obj) return self.allowed_barter_obj_types[obj.objectType] end
        else
            ref = tes3.player
            check_stolen_from = self.ref.object
            local scfg = config.barter.selling
            local book, ingredient = tes3.objectType.book, tes3.objectType.ingredient
            obj_filter = function (obj)
                return self.allowed_barter_obj_types[obj.objectType]
                    and (scfg.allow_books or obj.objectType ~= book)
                    and (scfg.allow_ingredients or obj.objectType ~= ingredient)
                    and obj.weight >= scfg.min_weight
            end
        end
    
        ---@type MQL.Item.iter_container.params
        local iter_params = { ref = ref, check_equipped = true,
            search_nearby = { owned_by={self.ref.baseObject, self.ref.object} },
            check_stolen_from = check_stolen_from,
            obj_filter = obj_filter,
            extra_object_vals={merchant=self.ref.mobile},
        }
        local i = 0
        for item in Barter_Item:iter_container(iter_params) do
            i = i + 1
            ---@cast item MQL.Item.Barter
            self.items[i] = item
            self:do_equipped_check(item)
        end
    end
    
    function Services:take_item_barter(modifier_pressed)
        if self.cant_loot then return false end
    
        local gold, item_value, num_taken
        local item = self.items[self.index] ---@type MQL.Item.Barter

        if item.status == defns.item_status.unavailable then
            tes3.messageBox(item.unavailable_reason)
            return true
        end
    
        if self.is_buying then
            gold  = tes3.getPlayerGold() - self.gold_stack
        else
            gold = self.ref.mobile.barterGold - self.gold_stack
        end
    

        if modifier_pressed then
            item_value = item.total_value
        else
            item_value = item.value
        end
        
        -- dont do anything if we dont have enough gold (or the seller doesnt have enough gold)
        if item_value > gold then tes3.messageBox "Too expensive."; return true end

        num_taken = item:take(modifier_pressed, false)

        if num_taken then 
            tes3.playItemPickupSound{item=item.object, pickup=self.is_buying}

            self.item_stack[#self.item_stack+1] = {index=self.index, num_removed=num_taken, value= item_value}
            log:trace("item added to item_stack. the item stack is now:\n\t%s", function() return json.encode(self.item_stack) end)
            -- table.insert(self.item_stack, {index=self.index, num_removed=num_taken, value= item_value})
            self.gold_stack = self.gold_stack + item_value

            self.gui:update_item_name_label(self.index)
            self:update_index()
            
            self:update_status_label()
        end
        return true
    end
    
    
    
    function Services:take_all_items_barter(modifier_pressed)
        if self.cant_loot and self.cant_loot ~= defns.cant_loot.empty then return false end

    
        if modifier_pressed then 
            self:change_barter_mode()
            return true 
        end

        if #self.item_stack == 0 then return true end
    
        local mob = self.ref.mobile; if mob == nil then return end -- get rid of the yellow squigglies
        
        local sound, verb
        if self.is_buying then  -- buying     
            sound, verb = "Item Gold Down", "bought"
            for _, stack in ipairs(self.item_stack) do
                local item = self.items[stack.index]
                log:trace("%s %s", verb, item)
                -- from item container, to player
                tes3.transferItem{from=item.ref, to=tes3.player, item=item.object, count=stack.num_removed,
                    updateGUI=false,playSound=false
                }
            end
        else -- selling
            sound, verb = "Item Gold Up", "sold"
            for _, stack in ipairs(self.item_stack) do
                local item = self.items[stack.index]
                log:trace("%s %s", verb, item)
                -- from player, to merchant
                tes3.transferItem{from=tes3.player, to=self.ref, item=item.object, count=stack.num_removed,
                    updateGUI=false,playSound=false
                }
            end
        end
        


        tes3.payMerchant{merchant=self.ref.mobile,cost=self:get_signed_gold()}
        tes3.playSound{reference = tes3.player, sound = sound}

        -- award xp for the sale, if appropriate 
        if config.barter.award_xp and award_xp then
            log("trying to give the player some barter xp.")
            award_xp(self.gold_stack)
        end
        tes3ui.forcePlayerInventoryUpdate()

        -- display the message, then reset the gold_stack and item_stack
        self:make_i18n_msgbox("looted.barter", {verb=verb, count=#self.item_stack,gold=self.gold_stack})   
        -- reset the gold and item stacks
        self.gold_stack = 0
        self.item_stack = {}
        return true
    end

    -- undo buying/selling the last item
    ---@return boolean successful
    function Services:undo_barter()
        -- if there's a reason we cant loot, and if that reason is something other than being empty
        if self.cant_loot ~= nil and self.cant_loot ~= defns.cant_loot.empty then 
            return false
        elseif #self.item_stack == 0 then
            return self.cant_loot == nil -- return true if we can loot, false otherwise
        end
 
        ---@type MQL.Manager.stack_info
        local stack = table.remove(self.item_stack) -- removes last element and returns it
    
        local item = self.items[stack.index]
    

        if item.count == 0 then self.num_items = self.num_items + 1 end
    
        item:add_to_count(stack.num_removed)
        -- update the label of the item (to reflect its count increasing)
        self.gui:update_item_name_label(stack.index)
        -- set the index to the readded item
        self:set_index(stack.index, true)

        -- put the item back if we're undoing a purchase, pick the item back up if we're undoing a sale
        tes3.playItemPickupSound{item=item.object,pickup=not self.is_buying}
    
        if self.cant_loot == defns.cant_loot.empty then
            self:update()
        end
        
        self.gold_stack = self.gold_stack - stack.value
    
        self:update_status_label()
    
        return true
    end
end


return Services ---@type MQL.Manager.Services