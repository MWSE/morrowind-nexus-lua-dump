local Class = require("herbert100.Class")
local defns = require("herbert100.more quickloot.defns")
local log = require("herbert100.Logger")("More QuickLoot/Item") ---@type herbert.Logger
local config = require "herbert100.more quickloot.config"






-- -@field ui_status MQL.defns.item_ui_status? the UI status of this `Item`




-- an abstract `Item` class
---@class MQL.Item : herbert.Class
---@field count integer how many of the object are there (in total)
---@field ref tes3reference the container this item is in
---@field value integer? the value of this item stack, i.e., `object.value`
---@field weight integer? the  weight of this item stack, i.e., `object.weight`
---@field status MQL.defns.item_status? the status of this `Item`
---@field unavailable_reason string? if this item is unavailable, this string should say why. 
---@field object any the object that this item is representing
---@field new nil|fun(obj:MQL.Item):MQL.Item make a new item
local Item = Class.new({name="Abstract Item",
    converters = {count = math.abs},
    obj_metatable = {
        -- we have to do contravariant stuff since we want bigger items to appear earlier. ugh, why cant everything be covariant
        __le = function(i1,i2) return i1:get_value_weight_ratio() >= i2:get_value_weight_ratio() end,

        ---@param i1 MQL.Item
        ---@param i2 MQL.Item
        __eq = function(i1,i2) return i1.object == i2.object end,
    },
    ---@param self MQL.Item
    post_init = function(self)
        do -- initialize nil values
            -- if self.ui_status == nil    then self.ui_status = defns.item_ui_status.hidden end
            if self.status == nil       then self.status = defns.item_status.ok end
        end
        self:update()
        log:trace("new item made: %s", self)
    end
})

function Item:get_value_weight_ratio()
    if self.weight == 0 then
       return self.total_value + 10^12 -- 0 weight is really nice
    end
    return self.value / self.weight
end


function Item:update()
    self.total_value = self.count * self.value
end

function Item:total_weight() return self.count * self.weight end



-- take the full stack of items
---@param full_stack boolean? should the full stack be taken?
---@param play_sound boolean? should we update the inventory UI and play sounds?
---@return integer|false|nil num_taken the number of items taken, or `false` if we couldnt take an item
function Item:take(full_stack, play_sound)
    if self.count <= 0 then
        log:error("tried to take an item when there were none left!"); return false
    elseif self.status ~= defns.item_status.ok then
        
        if self.status == defns.item_status.unavailable or self.status == defns.item_status.unavailable_temp then
            tes3.messageBox(self.unavailable_reason)
        else
            log:error("tried to take %s item: %s", function()
                return table.find(defns.item_status,self.status), self
            end)
        end
        return false
    end
    local num_taken
    if full_stack then
        num_taken = self.count
    else
        num_taken = 1
    end
    self.count = self.count - num_taken
    self:update()

    if self.count == 0 then self.status = defns.item_status.empty end
    return num_taken
end


--- add this many items to the count
---@param num integer the number of items to add, if this was successful
---@return boolean successful if we successfully added the items
function Item:add_to_count(num)
    if self.status == defns.item_status.deleted then return false end

    self.count = self.count + num
    self:update()
    if self.count > 0 and self.status == defns.item_status.empty then
        self.status = defns.item_status.ok
    end
    return true
end

do -- UI methods

    --- generate the label that should show up in the `UI`
    ---@param self MQL.Item
    ---@return string label
    function Item:get_name_label() return "ERROR" end

    function Item:get_icon_path() return "ERROR" end


    function Item:get_weight_label()
        if self.weight == 0 then return '-' end
        if self.weight < 10 then return tostring(math.round(self.weight,2)) end
        
        return tostring(math.round(self.weight,1)) 
    end



    function Item:get_value_label()
        if config.compat.bg then
            local bg_config = include("buyingGame.config")
            if tes3.mobilePlayer.mercantile.current < bg_config.knowsPrice then
                return "?"
            end
        end

        local value
        if self.weight == 0 then 
            value = self.total_value
        else
            value = self.value
        end
        if value == 0 then 
            return '-'
        elseif value < 1000 then 
            return tostring(math.round(value,1))
        else
            return string.format("%sk", math.round(value/1000,2) )
        end
    end
end

do -- iterator


local function add_extra_obj_vals(item,obj_vals)
    if not obj_vals then return end
    for k,v in pairs(obj_vals) do item[k] = v end
end

---@class MQL.Item.iter_container.params.search_nearby
---@field container_filter MQL.defns.sn_cf?
---@field owned_by nil|tes3object[]     only present containers owned by something in this list
---@field allow_scripted nil|boolean    should scripted containers be allowed?
---@field dist nil|number               if provided, only things within this distance will be included


---@class MQL.Item.iter_container.params
---@field ref tes3reference the reference of the container to iterate through
---@field check_equipped nil|boolean the filters for equipped items
---@field search_nearby nil|MQL.Item.iter_container.params.search_nearby how should we deal with nearby containers? Default: none
---@field extra_object_vals nil|table<string, any> extra arguments to pass to next objects
---@field obj_filter nil|fun(obj: tes3item): boolean if provided, objects will be skipped if this function returns false
---@field post_creation nil|fun(item: MQL.Item) something to do after items are created


--- This is a generic iterator function that is used
--- to loop over all the items in an inventory.
-- it was adapted from the MWSE documentation and modified for this mod.
-- it should probably not be a class method, and i dont really like that i made it a class method.
-- the plan is to refactor it out of `Living` later, once i know more about how it will be used, or if i think of a better place to put it.
---@param params MQL.Item.iter_container.params
---@return fun(): MQL.Item
function Item:iter_container(params)
    params = params or {}
    local ref = params.ref
    local equipped_count ---@type table<tes3item, integer>? a table recording how many copies of an item an npc has equipped
    if params.check_equipped then
        equipped_count = {}
        for _, stack in pairs(ref.object.equipment) do
            local obj = stack.object
            -- if its the first time finding this item, set the equipped count to 1; otherwise, increase it
            if equipped_count[obj] ==  nil then
                equipped_count[obj] = 1
            else
                equipped_count[obj] = equipped_count[obj] + 1
            end
        end
    end
    local extra_obj_vals
    if params.extra_object_vals and next(params.extra_object_vals) ~= nil then 
        extra_obj_vals = params.extra_object_vals
    end

    local obj_filter = params.obj_filter
    ref:clone()
    local function iterator()
        for _, stack in ipairs(ref.object.inventory.items or ref.object.inventory) do

            ---@cast stack tes3itemStack
            local obj = stack.object

            -- if there was a whitelist and we didnt meet the requirements
            if obj_filter and not obj_filter(obj) then goto next_stack end
            -- Account for restocking items,
            -- since their count is negative
            local count = math.abs(stack.count)

            -- first yield stacks with custom data
            if equipped_count and stack.variables  then
                log:trace("checking variables for stack of %s", obj.name)
                for _, data in pairs(stack.variables) do
                    if data  == nil then goto next_data end

                    -- how many of these objects are equipped
                    local item_equipped_count = equipped_count[obj]
                    if item_equipped_count == nil then goto next_data end

                    count = count - data.count
                    if item_equipped_count > data.count then
                        equipped_count[obj] = item_equipped_count - data.count
                    else -- `item_equipped_count <= data.count`
                        equipped_count[obj] = nil
                    end

                    ---@type MQL.Item.Physical
                    local item_params = {ref=ref, object=obj, count=data.count, equipped=true}
                    
                    add_extra_obj_vals(item_params, extra_obj_vals)
                    local item = self.new(item_params)

                    if params.post_creation then params.post_creation(item) end
                    if item.status ~= defns.item_status.deleted then
                        coroutine.yield(item)
                    end
                        
                    ::next_data::
                end
            end
            -- if there are items to add, add them
            if count > 0 then
                local item_params = {ref=ref, object=obj, count=count,} ---@type MQL.Item
                add_extra_obj_vals(item_params, extra_obj_vals)

                local item = self.new(item_params)

                if params.post_creation then
                    params.post_creation(item)
                end

                if item.status ~= defns.item_status.deleted then
                    coroutine.yield(item)
                end
            end
            ::next_stack::
        end
        -- only search nearby nearby containers if `search_nearby ~= nil`
        local sn = params.search_nearby
        if not sn then return end

        if sn.container_filter == defns.sn_cf.no_other_containers then return end

        if sn.dist == 0 then return end
        
        log:trace("searching nearby containers")
        local container_filter = sn.container_filter
        local owned_by = sn.owned_by

        -- the weird pattern is to remove trailing numbers from base object ids
        -- this is needed because plants that carry two ingredients have base id `plant_02`, while plants carrying one ingredient have base id `plant_01`
        -- local base_id = ref.baseObject.id:lower():gsub("_%d*", "")
        local base_name = ref.baseObject.name or ref.object.name
        local dist = sn.dist and sn.dist^2
        local v_dist = config.advanced.v_dist
        local ref_pos = (ref.mobile and ref.mobile.position) or ref.position
        for container_ref in tes3.player.cell:iterateReferences(tes3.objectType.container) do
            
            do -- see if we should skip this one

                -- dont repeat the container
                if container_ref == ref then goto next_container end
                -- scripted check
                if container_ref:testActionFlag(tes3.actionFlag.useEnabled) == false then goto next_container end

                -- obj_filter check
                local cref_owner = tes3.getOwner{reference=container_ref}
                if container_filter then
                    if container_filter == defns.sn_cf.same_base_obj then
                        if base_name ~= (container_ref.baseObject.name or container_ref.object.name) then goto next_container end

                    elseif container_filter == defns.sn_cf.organic then
                        if not container_ref.object.organic then goto next_container end
                    end
                end
                -- distance check
                if dist then
                    local cref_pos = (container_ref.mobile and container_ref.mobile.position) or container_ref.position
                    -- if abs(ref_pos.x - cref_pos.x) > dist or abs(ref_pos.y - cref_pos.y) > dist or abs(ref_pos.z - cref_pos.z) > dist then

                    -- use a "cylinder" distance metric. this will basically treat `ref` and `cref` as if they're on the same `z`-level (unless there's a crazy difference between the `z`-levels )
                    if (ref_pos.x - cref_pos.x)^2 + (ref_pos.y - cref_pos.y)^2 > dist or math.abs(ref_pos.z - cref_pos.z) > v_dist then 
                        goto next_container 
                    end
                end
                -- check owned by
                if owned_by then
                    if cref_owner == nil then 
                        -- if no one owns `cref`, then skip this container if we have a list of owners we should match
                        if next(owned_by) ~= nil then goto next_container end
                    else
                        -- if someone owns `cref`, and if that owner isnt in the allowed list, then skip
                        if not table.contains(owned_by, cref_owner) then goto next_container end
                    end
                end
            end
            log:trace("%s passed all checks", container_ref.object.name)
            container_ref:clone()   
            
            -- now we actually iterate the container
            for _,stack in ipairs(container_ref.object.inventory.items or container_ref.object.inventory) do
                -- if there was a whitelist and we didnt meet the requirements
                if obj_filter and not obj_filter(stack.object) then goto next_stack end


                local item_params = {ref=container_ref, object=stack.object, count=stack.count} ---@type MQL.Item
                
                add_extra_obj_vals(item_params, extra_obj_vals)

                local item = self.new(item_params)
                if params.post_creation then params.post_creation(item) end

                if item.status ~= defns.item_status.deleted then
                    coroutine.yield(item)
                end
                -- coroutine.yield(stack.object, stack.count, container_ref)
                ::next_stack::
            end
            ::next_container::
        end
    end
    return coroutine.wrap(iterator)
end

end

do -- sorting methods



--- compare two items based on their gold/weight ratios. used for sorting lists of items
---@param i1 MQL.Item
---@param i2 MQL.Item
---@return boolean -- `true` if `i1 < i2`; `false` otherwise. i.e., `true` means `i1` should appear before `i2`.
function Item.value_weight_comp(i1,i2)
    local i1ratio, i2ratio = i1:get_value_weight_ratio(), i2:get_value_weight_ratio()
    -- doing this because `table.sort` really wants a total ordering
    
    -- compare ratios if they're different
    if i1ratio ~= i2ratio then return i1ratio > i2ratio end -- higher ratios show up first

    -- compare `count` if the ratios are the same
    if i1.count ~= i2.count then return i1.count > i2.count end

    -- compare their names if ratios and count are the same
    return  i1.object.name > i2.object.name
end


--- compare two items based on their gold values. used for sorting lists of items
---@param i1 MQL.Item
---@param i2 MQL.Item
---@return boolean -- `true` if `i1 < i2`; `false` otherwise. i.e., `true` means `i1` should appear before `i2`.
function Item.value_comp(i1,i2)
    -- compare values if they're different
    if i1.value ~= i2.value then return i1.value > i2.value end -- higher value shows up first
    
    -- compare `count` if the values are the same
    if i1.count ~= i2.count then return i1.count > i2.count end

    -- compare their names if values and count are the same
    return  i1.object.name > i2.object.name
end


--- compare two items based on their weights. used for sorting lists of items.
---@param i1 MQL.Item
---@param i2 MQL.Item
---@return boolean -- `true` if `i1 < i2`; `false` otherwise. i.e., `true` means `i1` should appear before `i2`.
function Item.weight_comp(i1,i2)
    -- compare values if they're different
    if i1.weight ~= i2.weight then return i1.weight < i2.weight end -- smaller weight shows up first
    
    -- compare `count` if the values are the same
    if i1.count ~= i2.count then return i1.count > i2.count end

    -- compare their names if values and count are the same
    return  i1.object.name > i2.object.name
end

end

-- =============================================================================
-- PHYSICAL ITEMS
-- =============================================================================


-- a physical item, used in bartering, looting, pickpocketing, etc
---@class MQL.Item.Physical : MQL.Item
---@field equipped boolean? is the item equipped? if `nil`, we dont care
---@field equipped_slot tes3.clothingSlot? the slot a clothing item is equipped in, if applicable
---@field total_value integer? the total value of this item stack, eg `count` * `item.value`
---@field object tes3item|tes3alchemy|tes3weapon the actual item in the inventory
local Physical_Item = Class{name="Physical Item", parents={Item},
    ---@param self MQL.Item.Physical
    post_init = function(self)
        do -- initialize nil values
            if self.weight == nil       then self.weight = self.object.weight end
            if self.value == nil        then self.value = self.object.value end
            -- if self.ui_status == nil    then self.ui_status = defns.item_ui_status.hidden end
            if self.status == nil       then self.status = defns.item_status.ok end
        end
        if self.equipped then
            log("making new %s with equipped: %s.", self.__secrets.name, self.equipped)
            self.status = defns.item_status.unavailable
            self.unavailable_reason = "This item is equipped!"
        end

        self:update()

        log:trace("new item made: %s", self)
    end

}

--- generate the label that should show up in the `UI`
---@param self MQL.Item.Physical
---@return string label
function Physical_Item:get_name_label()
    if config.compat.ttip and tes3.player.itemData and tes3.player.itemData.data and tes3.player.itemData.data.rev_TTIP.items[self.object.id] then
        if self.count == 1 then
            return string.format("%s %s", config.UI.ttip_collected_str, self.object.name)
        end
        return string.format("%s %s (%i)", config.UI.ttip_collected_str, self.object.name, self.count)
    end
    if self.count == 1 then return self.object.name end

    return string.format("%s (%i)", self.object.name, self.count)
end

function Physical_Item:get_icon_path() return "icons\\" .. self.object.icon end







-- take items from the container
---@param full_stack boolean? should the full stack be taken?
---@param play_sound boolean? should we play sounds?
---@param to tes3reference? the container to put this item in. Default: `tes3.player`
---@return integer|false|nil num_taken the amount of things taken, or false if we couldnt take anything
function Physical_Item:take_from_container(full_stack, play_sound, to)
    to = to or tes3.player
    if to ~= tes3.player then   
        local weight = (full_stack and self:total_weight()) or self.weight
        if weight + to.object.inventory:calculateWeight() > to.object.capacity then
            tes3.messageBox("This item won't fit inside this container")
            return false
        end
    end

    local num_taken = self:take(full_stack, play_sound)
    if num_taken then

        tes3.transferItem{from=self.ref, to=to, item=self.object, count=num_taken, 
            playSound=play_sound, updateGUI=play_sound and not config.UI.update_inv_on_close
        }
    end

    return num_taken
end



-- return these items to the container they were taken from
---@param play_sound boolean? should we play sounds?
---@param num integer the number of items to return to the container
---@param from tes3reference? the container to take this item from. Default: `tes3.player`
---@return boolean successful whether this was the last item removed, and the stack is now empty
function Physical_Item:return_to_container(num,play_sound, from)
    if self.status ~= defns.item_status.empty and self.status ~= defns.item_status.ok then
        return false
    end
    self.count = self.count + num

    tes3.transferItem{to=self.ref, from=from or tes3.player, item=self.object, count=num,
        playSound=play_sound, updateGUI=play_sound and not config.UI.update_inv_on_close
    }
    self:update()

    self.status = defns.item_status.ok

    return true
end

-- take items from the container
---@param full_stack boolean? should the full stack be taken?
---@param play_sound boolean? should we play sounds?
---@return integer|false|nil num_taken the amount of things taken, or false if we couldnt take anything
function Physical_Item:remove_from_container(full_stack, play_sound)
    local num_taken = self:take(full_stack, play_sound)

    if not num_taken then return false end

    tes3.removeItem{reference=self.ref, item=self.object, count=num_taken, 
        playSound=play_sound, updateGUI=play_sound and not config.UI.update_inv_on_close
    }
    return num_taken
end


---@class MQL.Item.Chance : MQL.Item.Physical
---@field take_chance integer number between 0 and 100 that coressponds to the percentage chance of successfully taking one item
---@field total_take_chance integer number between 0 and 100 that coressponds to the percentage chance of successfully taking the whole stack
local Chance_Item = Class.new{name="Chance Item", parents = {Physical_Item}, }

function Chance_Item:update()
    self.total_value = self.count * self.value

    if self.take_chance == nil then return end

    if self.weight < 0.0001 then
        self.total_take_chance = self.take_chance
    else
        self.total_take_chance = math.clamp(
            math.floor(100 * ((self.take_chance/100)^self.count) ),
             0, 100
        )
    end
end

function Chance_Item:get_name_label()
    -- if the take chance doesnt exist, or if we cant loot the item
    if self.take_chance == nil or self.status < defns.item_status.ok then 
        return Physical_Item.get_name_label(self) 
    end

    if self.count == 1 then 
        return string.format("%s - %i%%", self.object.name, self.take_chance) 
    end

    -- from this point onwards,there are multiple items

    if self.take_chance == self.total_take_chance then
        return string.format("%s (%i) - %i%%", self.object.name, self.count, self.take_chance)
    end

    return string.format("%s (%i) - %i%% (%i%%)", self.object.name, self.count, self.take_chance, self.total_take_chance)


end

---@class MQL.Item.Services : MQL.Item
---@field merchant tes3mobileNPC the merchant we're buying this service from


---@class MQL.Item.Training : MQL.Item.Services
---@field skill_id tes3.skill the `id` of the skill
---@field max_lvl integer the highest value this skill can be trained to
---@field value integer the cost of training this skill
local Training_Item = Class({name="Training Item", parents={Item},
    obj_metatable={
        ---@param i1 MQL.Item.Training
        ---@param i2 MQL.Item.Training
        __lt=function(i1,i2) return i1.value > i2.value end,

        ---@param i1 MQL.Item.Training
        ---@param i2 MQL.Item.Training
        __le=function(i1,i2) return i1.value > i2.value end
    },
}, {count = 1, weight = 0})

---@param self MQL.Item.Training
function Training_Item:update()
    self.value = tes3.calculatePrice{training=true, merchant=self.merchant, skill=self.skill_id}
    self.total_value = self.value

    log("updating training item. new price: %s", self.value)



    local skill_base = tes3.mobilePlayer:getSkillStatistic(self.skill_id).base


    local related_attr_id = tes3.getSkill(self.skill_id).attribute
    local attribute_lvl = tes3.mobilePlayer.attributes[related_attr_id+1].current -- using this instead of `base` bc trainers are ok with `fortify` spells

    log("seeing if %s can be trained. related attribute: %s", function ()
        local skill = tes3.getSkill(self.skill_id)
        return skill.name,  tes3.getAttributeName(skill.attribute)
    end)

    self.status = defns.item_status.unavailable
    if tes3.getPlayerGold() < self.value then
        self.unavailable_reason = "You don't have enough gold to train this skill. :("
    -- skill level must be `<= max_lvl` and also `< 100`. in order to receive training
    elseif skill_base > self.max_lvl or skill_base >= 100 then 
       self.unavailable_reason = "Your skill level is too high."
    elseif attribute_lvl <= skill_base then
       self.unavailable_reason = string.format("Your %s is too low.", tes3.getAttributeName(related_attr_id))
    else
        self.status = defns.item_status.ok
        self.unavailable_reason = nil
    end
end

function Training_Item:get_name_label()
    if self.value == nil then return end

    local player_skill_lvl = tes3.mobilePlayer:getSkillStatistic(self.skill_id).base

    return string.format("%s (%i)", tes3.getSkillName(self.skill_id), player_skill_lvl)
end

function Training_Item:get_icon_path()
    return tes3.getSkill(self.skill_id).iconPath
end

function Training_Item:get_value_label()
    if self.value == 0 then return '-' end
    return tostring(self.value)
end

function Training_Item:get_weight_label() 
    if config.training.max_lvl_is_weight then
        return tostring(self.max_lvl)
    end
    return '-'
end



---@class MQL.Item.Barter : MQL.Item.Physical, MQL.Item.Services
---@field icon_path string path to this skills icon
---@field unavailable_reason string? the reason this item is unavailable, or nil
local Barter_Item = Class.new{name="Barter Item", parents={Physical_Item},
    post_init= function (self)
        -- do the physical item post init, then make sure this item isn't stolen
        Physical_Item.__secrets.post_init(self)
        if self.ref == tes3.player then  -- if we're selling
            if log.level > 4 and #self.object.stolenList > 0 then
                log:trace("checking to see if the item has been stolen.\n\t\z
                    merchant_obj_name: %s\n\t\z
                    merchant_bobj_name: %s\n\t\z
                    object: %s", 
                    self.merchant.object.name, self.merchant.reference.baseObject.name, self.object
                )
                log:trace "printing stolen list:"
                for _,bobj in ipairs(self.object.stolenList) do
                    log:trace("object.name: %s", bobj.name)
                end
            end

            -- check if the item is stolen
            if table.find(self.object.stolenList, self.merchant.reference.baseObject) then
                log("found a stolen object! %s was stolen from %s", self.object.name, self.merchant.object.name)
                self.status = defns.item_status.unavailable
                self.unavailable_reason = "This item is stolen!"
            -- if buying game is installed, check if the item is contraband
            elseif config.compat.bg then
                local bg_config = include("buyingGame.common").config
                local obj_id = self.object.id
                local merchant_id = self.merchant.reference.baseObject.id:lower()
                if bg_config.forbidden[obj_id] and not (bg_config.smuggler[merchant_id] or self.merchant.alarm == 0) then
                    self.status = defns.item_status.unavailable
                    self.unavailable_reason = "You can't sell contraband to this person!"
                end
            end
        end
    end
}



function Barter_Item:update()
    local buying, selling
    if self.ref == tes3.player then
        selling = true
    else
        buying = true
    end

    self.value = tes3.calculatePrice{bartering=true, buying = buying, selling= selling,
        merchant=self.merchant, object= self.object, count=1,
    }
    if self.count == 1 then 
        self.total_value = self.value
    else
        self.total_value = tes3.calculatePrice{bartering=true, buying = buying, selling= selling,
            merchant=self.merchant, object= self.object, count=self.count,
        }
    end

    -- dont show items if they're worth 0 gold
    if not buying and self.value == 0 then
        self.status = defns.item_status.deleted
    end
end

--- get the value label. we don't check for buying game compatibility since we're only using the prices the merchant told us
function Barter_Item:get_value_label()
    local value
    if self.weight == 0 then 
        value = self.total_value
    else
        value = self.value
    end
    if value == 0 then 
        return '-'
    elseif value < 1000 then 
        return tostring(math.round(value,1))
    else
        return string.format("%sk", math.round(value/1000,2) )
    end
end


return {
    Physical = Physical_Item, 
    Chance = Chance_Item, 
    Training = Training_Item,
    Barter = Barter_Item,
}