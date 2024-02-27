local Class= require("herbert100.Class")
local generators = require("herbert100.Class.utils").generators
local defns = require "herbert100.more quickloot.defns"

-- living manager, ensures that `Services` will die as soon as we start sneaking or the target becomes nil
local Living = require("herbert100.more quickloot.managers.abstract.Living")
local Items = require("herbert100.more quickloot.Item")
local config = require "herbert100.more quickloot.config"
local Training_Item, Barter_Item = Items.Training, Items.Barter
local log = require("herbert100").Logger("More QuickLoot/Services")

local super = Class.super ---@cast super fun(cls: MQL.Manager): MQL.Manager

local award_xp = config.compat.bxp and include("herbert100.barter xp overhaul.mod").award_barter_xp or nil


---@class MQL.Manager.Services : MQL.Managers.Living
---@field items MQL.Item.Training[]|MQL.Item.Barter[] the skills that can be trained
---@field current_service MQL.defns.services the mode of service we're in 
---@field allowed_services MQL.defns.services[]
---@field allowed_barter_obj_types table<tes3.objectType, boolean>
---@field gold_stack integer the amount of gold
---@field item_stack MQL.Manager.stack_info[]
---@field is_buying boolean are we currently buying? if false, we are selling
local Services = Class.new{name="Services Manager", parents={Living},
    fields = {
        {"i18n_index", default="looted.barter"},
        {"gold_stack",},
        {"current_service", tostring=generators.table_find(defns.services)},
        {"is_buying"},
        {"items"},
        {"item_stack"},
        {"allowed_barter_obj_types", tostring=function(v) return v and json.encode(v) or "N/A" end},
    },
    ---@param self MQL.Manager.Services
    ---@param ref tes3reference
    init = function(self, ref)
        self.ref = ref
        ref:clone()
        self.allowed_services, self.allowed_barter_obj_types = self.get_allowed_services(self.ref)

        local service = config.services.default_service

        if not self:is_service_valid(service) then
            service = self:get_next_valid_service(service)
        end
        self.current_service = service
        self:initialize_service()
    end,

    ---@param self MQL.Manager.Services
    post_init = function(self)
        Living.__secrets.post_init(self)
        self:do_empty_barter_check()
        self.gui.m_key_label:update_labels(self:get_m_keylabels(), true)
        self.gui.ui_base:updateLayout()
    end,
}

---@param service MQL.defns.services
function Services:is_service_valid(service)
    return table.contains(self.allowed_services, service)
end

---@param service MQL.defns.services
---@return MQL.defns.services
function Services:get_next_valid_service(service)
    log("getting next valid service with initial service: %s", service)
    repeat
        service = (service + 1) % defns.misc.services_quotient
        log("set service to %q. seeing if this is valid...", service)
    until self:is_service_valid(service)
    return service
end

-- initializes/resets the current service
function Services:initialize_service()
    log("initializing service: %s", function ()
        return table.find(defns.services, self.current_service)
    end)
    self.item_stack = {}
    self.gold_stack = 0
    if self.current_service == defns.services.barter then
        self.config = config.barter
        self.item_type = Barter_Item
        self.is_buying = config.barter.start_buying
    else
        self.item_type = Training_Item
        self.config = config.training
    -- elseif self.current_service == defns.services.training then
    end
end


-- goes to next service
function Services:change_service()
    log("trying to change current service")

    local next_service = self:get_next_valid_service(self.current_service)
    log("next valid service is %s", next_service)
    
    -- dont do anything if we wont actually change the service
    if self.current_service == next_service then return end

    self.current_service = next_service
    
    log("merchant had another available service.")
    self:initialize_service()

    self:make_items()

    self:update_GUI_label()
    self.gui.key_label:update_labels(self:get_keylabels())
    self.gui.m_key_label:update_labels(self:get_m_keylabels(), true)
    self:update_status_label()
    
    self:update(true)
    self:do_empty_barter_check()
end

local function logmsg_do_empty_barter_check(is_buying)
    local str = "%s menu was empty, switching to %s menu"
    if is_buying then
        return str, "buying", "selling"
    else
        return str, "selling", "buying"
    end
end

-- checks if we're bartering and the menu is empty
-- then switches barter modes if applicable
function Services:do_empty_barter_check()
    if config.barter.switch_if_empty 
    and self.current_service == defns.services.barter 
    and self.cant_loot == defns.cant_loot.empty 
    then
        log(logmsg_do_empty_barter_check, self.is_buying)
        self:change_barter_mode()
    end
end




-- switch services
function Services:modified_open()
    -- allow changing services if we can loot or if the reason is that the menu is empty
    -- (if we didn't allow this when the menu is empty, we wouldnt be able to train/sell after buying a merchaants inventory)
    if self.cant_loot == nil or self.cant_loot == defns.cant_loot.empty then
        -- only play sound when button is pushed
        self:play_switch_sound()
        self:change_service()
        return true
    end
    return false
end




-- sort `self.items`, taking into account current config settings.
-- if bartering, we don't take into account buying game since we're only using the prices the merchant told us
-- if training, we sort skills alphabetically
function Services:_sort_items()
    local comp
    if self.current_service == defns.services.barter then

        local sort_items = config.UI.sort_items
        local _comp
        if sort_items == defns.sort_items.value_weight_ratio then
            _comp = Barter_Item.value_weight_comp
        elseif sort_items == defns.sort_items.value then
            _comp = Barter_Item.value_comp
        elseif sort_items == defns.sort_items.weight then
            _comp = Barter_Item.weight_comp
        end
        if _comp then
            -- if  were selling and supposed to sort in reverse
            if not self.is_buying and config.barter.selling.reverse_sort then
                comp = function(a,b)
                    if a.status == b.status then return _comp(b,a) end
                    return a.status > b.status
                end
            else
                -- were buying or not supposed to sort in reverse. 
                -- we should put the stupid items at the bottom
                comp = function(a,b)
                    if a.status == b.status then return _comp(a,b) end
                    return a.status > b.status
                end
            end
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
        if self.cant_loot ~= defns.cant_loot.empty then super(self).do_cant_loot_action(self); return end

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

    function Services:get_keylabels()
        if self.current_service == defns.services.barter then
            return { take = (self.is_buying and "Buy") or "Sell", take_all = "Confirm", open = "Talk"}
        else
            return { take = false, open = "Talk", take_all = "Train" }
        end
    end

    function Services:get_m_keylabels()
        if self.current_service == defns.services.barter then
            return { take = "Stack", take_all = "Switch Mode", open = #self.allowed_services > 1 and  "Next Service"}
        else
            return { take = false, take_all = false, open = #self.allowed_services > 1 and  "Next Service"}
        end
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
    local function logmsg_make_items_training(ref, skills)
        local info = table.map(skills, function (_, v, ...)
            return string.format("%q: %s", tes3.getSkillName(v[1]), v[2])
        end)
        return "%s's highest skills are: {\n\t%s\n}", 
            ref.object.name, table.concat(info, "\n\t")

        -- for _, id in pairs(tes3.skill) do   
        --     info[]
        -- end
        -- local name_lens = {}
        -- for _, id in pairs(tes3.skill) do table.insert(name_lens, #tes3.skillName[id]) end
        -- local max_len = math.max(table.unpack(name_lens))

        -- local function get_formatted_skill_name(_, v)
        --     local name = tes3.getSkillName(v[1])
        --     local len = max_len - #name
        --     local rep = len < 2 and string.rep(" ", len) or string.rep(".", len)
        --     return string.format("%q:%s %02i", name, rep, v[2])
        -- end
        -- return table.concat(table.map(skills, get_formatted_skill_name), "\n\t")
    end
    function Services:_make_items_training()
        -- special thanks to Hrnchamd for telling me how to determine which skills NPCs offer training in
    
        -- get the three highest skills. start each value off at an impossibly low value, just so we can compare them

        ---@param skill tes3statisticSkill|tes3statistic
        local skills = table.map(self.ref.mobile.skills, function(i, skill) return {i-1, skill.base} end)
        table.sort(skills, function (a, b) return a[2] > b[2] end)
        log(logmsg_make_items_training, self.ref, skills)
        -- i could probably write this in a for loop, but it's nice to take a break from for loops every once in a while
        self.items = {
            Training_Item{from=self.ref, skill_id = skills[1][1], max_lvl = skills[1][2], merchant=self.ref.mobile},
            Training_Item{from=self.ref, skill_id = skills[2][1], max_lvl = skills[2][2], merchant=self.ref.mobile},
            Training_Item{from=self.ref, skill_id = skills[3][1], max_lvl = skills[3][2], merchant=self.ref.mobile},
        }
    end
    function Services:take_all_items_training(modifier_pressed)
        if self.cant_loot then return end
        if modifier_pressed then return true end
        local item = self.items[self.index]
        log("trying to train %s", function() return tes3.getSkillName(item.skill_id) end)
        
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
            item:make_unavailable_msgbox()
        end
        return true
    end

end

do -- barter functionality
    
    
    --- change the current `barter_mode`
    function Services:change_barter_mode()
        self.is_buying = not self.is_buying
        
        self:make_items()
        self:update_GUI_label()
        self:update_status_label()
        self.gui.key_label:update_labels(self:get_keylabels())
        self:update(true)
    end
    
    -- the amount of gold that should be added to the merchants gold reserves
    -- should be positive when buying and negative when selling
    function Services:get_signed_gold() return (self.is_buying and self.gold_stack) or -self.gold_stack end

    
    function Services:_make_items_barter()
        self.item_stack = {}
        self.gold_stack = 0
        self.items = {}

        -- =====================================================================
        -- ITERATE PLAYER OR MERCHANT
        -- =====================================================================
        

        if self.is_buying then
            local allowed_types = self.allowed_barter_obj_types
            self:add_npc_items{ ref=self.ref, to=tes3.player, related_ref=self.ref,
                equipped_cfg=config.barter.equipped,
                obj_filter = function(obj)
                    return allowed_types[obj.objectType] and not obj.isGold 
                end,
            }
            self:add_nearby_items{ ref=self.ref, to=tes3.player, related_ref=self.ref,
                owner=self.ref.baseObject,
                obj_filter=function(obj) return allowed_types[obj.objectType] and not obj.isGold end,
            }
        else
            local scfg = config.barter.selling
            local allowed_types = table.copy(self.allowed_barter_obj_types, {
                [tes3.objectType.book] = scfg.allow_books,
                [tes3.objectType.ingredient] = scfg.allow_ingredients,
            })
            
            self:add_npc_items{ ref=tes3.player, to=self.ref, related_ref=self.ref, 
                equipped_cfg=config.barter.equipped,
                obj_filter = function(obj) 
                    return allowed_types[obj.objectType] 
                        and not obj.isGold
                        and obj.weight >= scfg.min_weight
                        and obj.value > 0
                end,
            }
        end
    end
    
    function Services:take_item_barter(modifier_pressed)
        if self.cant_loot then return false end
    
        local item = self.items[self.index] ---@type MQL.Item.Barter

        if not item:can_take() then
            if item.status == defns.item_status.unavailable then
                item:make_unavailable_msgbox()
            end
            return true
        end
    
        local gold

        if self.is_buying then
            gold  = tes3.getPlayerGold() - self.gold_stack
        else
            gold = self.ref.mobile.barterGold - self.gold_stack
        end
    
        local value = item:get_value(modifier_pressed)
        
        -- dont do anything if we dont have enough gold (or the seller doesnt have enough gold)
        if value > gold then 
            tes3.messageBox("Too expensive.")
            return true 
        end

        local num_taken = modifier_pressed and item.count or 1

        if num_taken > 0 then
            item.count = item.count - num_taken
            item:update_status()
            tes3.playItemPickupSound{item=item.object, pickup=self.is_buying}

            self.item_stack[#self.item_stack+1] = {index=self.index, num_removed=num_taken, value=value}
            log:trace("item added to item_stack. the item stack is now:\n\t%s", json.encode, self.item_stack)
            -- table.insert(self.item_stack, {index=self.index, num_removed=num_taken, value= item_value})
            self.gold_stack = self.gold_stack + value

            self.gui:update_item_name_label(self.index)
            self:update_index()
            
            self:update_status_label()
        end
        return true
    end
    
    
    
    function Services:take_all_items_barter(modifier_pressed)
        if self.cant_loot and self.cant_loot ~= defns.cant_loot.empty then return false end

    
        if modifier_pressed then 
            -- only play sound when button gets pushed
            self:play_switch_sound()
            self:change_barter_mode()
            return true 
        end

        if #self.item_stack == 0 then return true end
    
        local mob = self.ref.mobile; if mob == nil then return end -- get rid of the yellow squigglies
        
        local sound, verb
        if self.is_buying then  -- buying     
            sound, verb = "Item Gold Down", "bought"
        else -- selling
            sound, verb = "Item Gold Up", "sold"
        end

        for _, stack in ipairs(self.item_stack) do
            local item = self.items[stack.index]
            log:trace("%s %s", verb, item)
            -- from player, to merchant
            local num_removed = item:transfer(stack.num_removed, false)
            if num_removed ~= stack.num_removed then
                log:error("wanted to buy %i copies of an item, but only bought %i. item: %s", stack.num_removed, num_removed, item)
                local diff = stack.num_removed - num_removed
                item.count = item.count + diff
                item:update_status()
                self.gold_stack = self.gold_stack - item.value * diff
            end
        end
        


        tes3.payMerchant{merchant=self.ref.mobile, cost=self:get_signed_gold()}
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
        log("undo key pressed")
        -- if there's a reason we cant loot, and if that reason is something other than being empty
        if self.cant_loot and self.cant_loot ~= defns.cant_loot.empty then 
            return false
        elseif #self.item_stack == 0 then
            log("item stack is empty, so returning")
            return self.cant_loot == nil -- return true if we can loot, false otherwise
        end
        
        ---@type MQL.Manager.stack_info
        local stack = table.remove(self.item_stack) -- removes last element and returns it
    
        local item = self.items[stack.index]
    

        if item.count == 0 then self.num_items = self.num_items + 1 end
        item.count = item.count + stack.num_removed
        item:update_status()
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

return Services ---@type MQL.Manager.Services