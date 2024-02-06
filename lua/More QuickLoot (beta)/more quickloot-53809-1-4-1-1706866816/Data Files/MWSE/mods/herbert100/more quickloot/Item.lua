local Class = require("herbert100.Class")
local generators = require("herbert100.Class.utils").generators
local defns = require("herbert100.more quickloot.defns")
local log = require("herbert100.Logger")("More QuickLoot/Item") ---@type herbert.Logger
local config = require "herbert100.more quickloot.config"

local is_empty = defns.item_status.empty
local is_deleted = defns.item_status.deleted
local is_unavailable = defns.item_status.unavailable
local is_unavailable_temp = defns.item_status.unavais_unavailable_temp
local is_ok = defns.item_status.ok

local function safe_obj_name(v) return v and v.object.name or "N/A" end
local function safe_name(v) return v and v.name or "N/A" end


-- -@field ui_status MQL.defns.item_ui_status? the UI status of this `Item`
local bgcfg

-- critical failure happens if you try to load buying game config before the game initializes
event.register("initialized", function (e)
    bgcfg = include("buyingGame.config")
end)


---@class MQL.Item.new_params
---@field object any the object that this item is representing
---@field status MQL.defns.item_status? the status of this `Item`
---@field count integer how many of the object are there (in total)
---@field value integer? the value of this item stack, i.e., `object.value`
---@field weight integer? the  weight of this item stack, i.e., `object.weight`
---@field ref tes3reference the container this item is in
---@field related_ref tes3reference? a reference related to this item. could be the owner of the item, the place to transfer the item to, or the merchant if bartering.
---@field unavailable_reason MQL.defns.unavailable_reason? why is the item unavailable

-- an abstract `Item` class
---@class MQL.Item : herbert.Class, MQL.Item.new_params
---@field new nil|fun(p:MQL.Item.new_params):MQL.Item make a new item
local Item = Class.new{name="Abstract Item",
    fields={
        {"object", tostring=safe_name},
        {"status", tostring=generators.table_find(defns.item_status), factory=function () return is_ok end},
        {"unavailable_reason", tostring=generators.table_find(defns.unavailable_reason)},
        {"value"},
        {"count", default=1},
        {"weight"},
        {"ref",tostring=safe_obj_name},
        {"related_ref",tostring=safe_obj_name},
    },
    obj_metatable = { __eq = function(i1,i2) return i1.object == i2.object end, },
    ---@param self MQL.Item
    post_init = function(self)
        log:trace("new item made: %s", self)
    end
}


function Item:get_value_weight_ratio()
    if self.weight == 0 then
       return self.value * self.count + 10^12 -- 0 weight is really nice
    end
    return self.value / self.weight
end

function Item:make_unavailable_msgbox()
    local s
    if self.unavailable_reason == defns.unavailable_reason.equipped then
        s = "This item is equipped!"
    elseif self.unavailable_reason == defns.unavailable_reason.stolen then
        s = "This item is stolen!"
    elseif self.unavailable_reason == defns.unavailable_reason.locked then
        s = "This container is locked!"
    else
        return
    end
    tes3.messageBox(s)
end

function Item:total_weight() return self.count * self.weight end



-- take the full stack of items
---@param full_stack boolean? should the full stack be taken?
---@param update_stuff boolean? should we update the inventory UI and play sounds?
---@return integer|false|nil num_taken the number of items taken, or `false` if we couldnt take an item
function Item:take(full_stack, update_stuff)
    if self.count <= 0 then
        log:error("tried to take an item when there were none left!"); return false
    elseif self.status ~= is_ok then
        
        if self.status == is_unavailable or self.status == is_unavailable_temp then
            self:make_unavailable_msgbox()
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

    if self.count == 0 then self.status = is_empty end
    return num_taken
end

--- get the value of this item
---@param full_stack boolean should we get the value of the full stack?
---@return number value the value of this item
function Item:get_value(full_stack)
    return full_stack and (self.count * self.value) or self.value
end

function Item:get_weight(full_stack)
    return full_stack and (self.weight * self.count) or self.weight    
end

--- add this many items to the count
---@param num integer the number of items to add, if this was successful
---@return boolean successful if we successfully added the items
function Item:add_to_count(num)
    if self.status == is_deleted then return false end

    self.count = self.count + num
    if self.count > 0 and self.status == is_empty then
        self.status = is_ok
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
        return self.weight == 0 and '-' 
            or tostring(math.round(self.weight, (self.weight < 10 and 2) or 1))
    end



    function Item:get_value_label()
        if bgcfg and tes3.mobilePlayer.mercantile.current < bgcfg.knowsPrice then
            return "?"
        end

        local value = self.weight == 0 and (self.value * self.count) or self.value

        if value == 0 then 
            return '-'
        elseif value < 1000 then 
            return tostring(math.round(value,1))
        else
            return string.format("%sk", math.round(value/1000,2) )
        end
    end
end

do -- iterators

---@alias MQL.Item.obj_filter_fun fun(obj: tes3item|tes3ingredient): boolean, MQL.defns.item_status?, MQL.defns.unavailable_reason?

---@class MQL.Item.iter_container.params
---@field ref tes3reference the reference of the container to iterate through
---@field equipped_filter MQL.Item.obj_filter_fun? a function that should be run on equipped objects. it should return `true` if the item should be shown, and false if it shouldnt' be shown
---@field related_ref tes3reference? the reference of the structure that owns this item
---@field obj_filter MQL.Item.obj_filter_fun? 
--- if provided, this function should return `true` if the item should be yielded, and then it should return the status of the item and any reason it might be unavailable


---@param p MQL.Item.iter_container.params
function Item:iter_container(p)
    return coroutine.wrap(function()
        local ref = p.ref
        ref:clone()

        local relref = p.related_ref or tes3.player
        local obj_filter = p.obj_filter
        local cls = self:get_class() ---@cast cls MQL.Item
        local equipped_filter = p.equipped_filter
        
        local equipped_count = {} ---@type table<tes3item, integer> a table recording how many copies of an item an npc has equipped
        
        if equipped_filter then
            for _, stack in pairs(ref.object.equipment) do
                local obj = stack.object
                local ec = equipped_count[obj]
                equipped_count[obj] = (ec and ec + 1) or 1
            end
        end
        
        local obj, count, ec

        for _, stack in ipairs(ref.object.inventory.items or ref.object.inventory) do ---@cast stack tes3itemStack
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
            if equipped_filter ~= nil and stack.variables then
                log:trace("checking variables for stack of %s", obj.name)
                for _, data in pairs(stack.variables) do
                    -- how many of these objects are equipped
                    ec = equipped_count[obj]
                    if ec == nil then goto next_data end

                    -- past this point, we know the item is equipped

                    count = count - data.count
                    if ec > data.count then
                        equipped_count[obj] = ec - data.count
                    else -- `item_equipped_count <= data.count`
                        equipped_count[obj] = nil
                    end

                    local dyield, dstatus, dreason = equipped_filter(obj)

                    if dyield then
                        coroutine.yield(cls.new({
                            ref=ref, object=obj, count=data.count, equipped=true, 
                            related_ref=relref, status=dstatus, unavailable_reason=dreason,
                        }))
                    end
                    
                    ::next_data::
                end
            end
            -- if there are items to add, add them
            if count > 0 then
                coroutine.yield(cls.new({ref=ref, object=obj, count=count, related_ref=relref, status=status,unavailable_reason=reason}))
            end
            ::next_stack::
        end
    end)
end

---@class MQL.Item.iter_nearby_containers.params : MQL.Item.iter_container.params
---@field allow_scripted nil|boolean    should scripted containers be allowed? Default: yes
---@field dist nil|number               if provided, only things within this distance will be included
---@field container_filter MQL.defns.sn_cf?
---@field owner nil|tes3object        lets you specify the owner of an object. 
--- if `nil`, objects will be required to be unowned. if `false`, owners wont be checked. if a `tes3object`, then objects will be required to be owned by that object.

---@param p MQL.Item.iter_nearby_containers.params?
function Item:iter_nearby_containers(p)
    -- only search nearby nearby containers if `search_nearby ~= nil`

    -- if we're not actually supposed to iterate this container, then return an empty iterator
    if p == nil or p.dist == 0 or p.container_filter == defns.sn_cf.no_other_containers then 
        return next, {}
    end

    log:trace("searching nearby containers")
    
    return coroutine.wrap(function ()
        local ref = p.ref
        -- item stuff
        local obj_filter, relref =  p.obj_filter, p.related_ref or tes3.player
        -- type of new object to create
        local cls = self:get_class() ---@cast cls MQL.Item
        -- container info
        local owner, pos, base_name = p.owner, ref.position, ref.baseObject.name or ref.object.name

        -- if we should only iterate containers within a certain distance (and vertical distance) of `ref`
        local d,vd = (p.dist and p.dist^2), config.advanced.v_dist                         
        
        -- if we should iterate scripted scripted containers
        local allow_scripted = p.allow_scripted
        
        -- if we should only iterate containers that have the same base object
        local check_bobj = p.container_filter == defns.sn_cf.same_base_obj

        -- if we should only iterate organic containers
        local check_org = p.container_filter == defns.sn_cf.organic  -- info about which types of containers to filter

        for cref in tes3.player.cell:iterateReferences(tes3.objectType.container) do   
            do -- check if we should skip this container
                -- dont repeat the container
                if cref == ref then goto next_container end
                -- distance check
                if d ~= nil then
                    local cpos = cref.position
                    -- use a "cylinder" distance metric. this will basically treat `ref` and `cref` as if they're on the same `z`-level (unless there's a crazy difference between the `z`-levels )
                    if (pos.x - cpos.x)^2 + (pos.y - cpos.y)^2 > d or math.abs(pos.z - cpos.z) > vd then goto next_container end
                end
                
                -- container filter check
                if check_bobj then
                    if base_name ~= cref.baseObject.name then goto next_container end

                elseif check_org then
                    if not cref.object.organic then goto next_container end
                end
                
                -- do the owned by check and scripted container check
                if owner ~= false and owner ~= tes3.getOwner{reference=cref}
                or allow_scripted == false and cref:testActionFlag(tes3.actionFlag.useEnabled) == false then goto next_container end

            end

            log:trace("%s passed all checks", cref.object.name)
            cref:clone()   
            
            -- now we actually iterate the container
            for _, stack in ipairs(cref.object.inventory.items or cref.object.inventory) do
                if stack.object.canCarry == false then goto next_stack end
                -- if there was a whitelist and we didnt meet the requirements
                if obj_filter ~= nil then
                    local yield, status, reason =  obj_filter(stack.object)
                    if yield then
                        coroutine.yield(cls.new({
                            ref=cref, object=stack.object, count=math.abs(stack.count), related_ref=relref, 
                            status=status, unavailable_reason=reason,
                        }))
                    end
                else
                    coroutine.yield(cls.new({ref=cref, object=stack.object, count=math.abs(stack.count), related_ref=relref}))
                end

                ::next_stack::
            end
            ::next_container::
        end
    end)
end

end

do -- sorting methods



--- compare two items based on their gold/weight ratios. used for sorting lists of items
---@param i1 MQL.Item
---@param i2 MQL.Item
---@return boolean -- `true` if `i1 < i2`; `false` otherwise. i.e., `true` means `i1` should appear before `i2`.
function Item.value_weight_comp(i1,i2)
    -- if i1.status ~= i2.status then return i1.status > i2.status end
    local i1ratio, i2ratio = i1:get_value_weight_ratio(), i2:get_value_weight_ratio()
    
    -- doing this because `table.sort` really wants a total ordering
    if i1ratio ~= i2ratio then return i1ratio > i2ratio end
    if i1.value ~= i2.value then return i1.value > i2.value end
    if i1.object.name ~= i2.object.name then return i1.object.name < i2.object.name end
    if i1.count ~= i2.count then return i1.count < i2.count end
    if i1.status ~= i2.status then return i1.status > i2.status end
    return i1.value > i2.value
end


--- compare two items based on their gold values. used for sorting lists of items
---@param i1 MQL.Item
---@param i2 MQL.Item
---@return boolean -- `true` if `i1 < i2`; `false` otherwise. i.e., `true` means `i1` should appear before `i2`.
function Item.value_comp(i1,i2)
    if i1.value ~= i2.value then return i1.value > i2.value end
    if i1.object.name ~= i2.object.name then return i1.object.name < i2.object.name end
    if i1.count ~= i2.count then return i1.count < i2.count end
    if i1.status ~= i2.status then return i1.status > i2.status end
    return i1.weight < i2.weight
end


--- compare two items based on their weights. used for sorting lists of items.
---@param i1 MQL.Item
---@param i2 MQL.Item
---@return boolean -- `true` if `i1 < i2`; `false` otherwise. i.e., `true` means `i1` should appear before `i2`.
function Item.weight_comp(i1,i2)
    -- compare values if they're different
    if i1.weight ~= i2.weight then return i1.weight < i2.weight end
    if i1.object.name ~= i2.object.name then return i1.object.name < i2.object.name end
    if i1.count ~= i2.count then return i1.count < i2.count end
    if i1.status ~= i2.status then return i1.status > i2.status end
    return i1.value > i2.value
end

end

-- =============================================================================
-- PHYSICAL ITEMS
-- =============================================================================


-- a physical item, used in bartering, looting, pickpocketing, etc
---@class MQL.Item.Physical : MQL.Item
---@field new fun(p:ItemInstance.new.params): MQL.Item.Physical
---@field object tes3item|tes3alchemy|tes3weapon the actual item in the inventory
local Physical_Item = Class.new{name="Physical Item", parents={Item},
    ---@param self MQL.Item.Physical
    post_init = function(self)
        if self.weight == nil       then self.weight = self.object.weight end
        if self.value == nil        then self.value = self.object.value end
        if self.related_ref == nil  then self.related_ref = tes3.player end
        
        log:trace("new item made: %s", self)
    end

}

--- generate the label that should show up in the `UI`
---@param self MQL.Item.Physical
---@return string label
function Physical_Item:get_name_label()
    -- if config.compat.ttip 
    -- and tes3.player.itemData 
    -- and tes3.player.itemData.data 
    -- and tes3.player.itemData.data.rev_TTIP.items[self.object.id] 
    -- then
    if config.compat.ttip and tes3.player.itemData.data.rev_TTIP.items[self.object.id] then
        if self.count == 1 then
            return string.format("%s %s", config.UI.ttip_collected_str, self.object.name)
        end
        return string.format("%s %s (%i)", config.UI.ttip_collected_str, self.object.name, self.count)
    end
    return self.count == 1 and self.object.name 
        or string.format("%s (%i)", self.object.name, self.count)
end

function Physical_Item:get_icon_path() return "icons\\" .. self.object.icon end







-- take items from the container
---@param full_stack boolean? should the full stack be taken?
---@param update_stuff boolean? are several items being taken?
---@return integer|false|nil num_taken the amount of things taken, or false if we couldnt take anything
function Physical_Item:take_from_container(full_stack, update_stuff)
    -- if its not going to the player
    if self.related_ref ~= tes3.player then 
        -- container were putting ourselves in
        local cobj = self.related_ref.object

        -- weight of this item
        local item_weight = self:get_weight(full_stack)

        -- current weight of the container we want to enter
        local container_weight = cobj.inventory:calculateWeight()

        if item_weight + container_weight > cobj.capacity then
            tes3.messageBox("This item won't fit inside this container")
            return false
        end
    end

    local num_taken = self:take(full_stack, update_stuff)
    if num_taken then
        tes3.transferItem{from=self.ref, to=self.related_ref, item = self.object, count=num_taken, 
            playSound=update_stuff, updateGUI=update_stuff and not config.UI.update_inv_on_close
        }
    end

    return num_taken
end



-- return these items to the container they were taken from
---@param update_stuff boolean? should we play sounds?
---@param num integer the number of items to return to the container
---@return boolean successful whether this was the last item removed, and the stack is now empty
function Physical_Item:return_to_container(num,update_stuff)
    if self.status ~= is_empty and self.status ~= is_ok then
        return false
    end
    self.count = self.count + num

    tes3.transferItem{to=self.ref, from=self.related_ref, item=self.object, count=num,
        playSound=update_stuff, updateGUI=update_stuff and not config.UI.update_inv_on_close
    }
    self.status = is_ok

    return true
end

-- take items from the container
---@param full_stack boolean? should the full stack be taken?
---@param update_stuff boolean? should we play sounds?
---@return integer|false|nil num_taken the amount of things taken, or false if we couldnt take anything
function Physical_Item:remove_from_container(full_stack, update_stuff)
    local num_taken = self:take(full_stack, update_stuff)

    if num_taken then
        tes3.removeItem{reference=self.ref, item=self.object, count=num_taken, 
            playSound=update_stuff, updateGUI=update_stuff and not config.UI.update_inv_on_close
        }
    end
    return num_taken
end


---@class MQL.Item.Chance.new_params
---@field chance integer number between 0 and 100 that coressponds to the percentage chance of successfully taking one item
---@field show_chance boolean? should the chance be displayed.

---@class MQL.Item.Chance : MQL.Item.Physical, MQL.Item.Chance.new_params
---@field new fun(p:MQL.Item.Chance.new_params):MQL.Item.Chance make a new object
local Chance_Item = Class.new{name="Chance Item", parents = {Physical_Item}, }

function Chance_Item:make_unavailable_msgbox()
    if self.unavailable_reason == defns.unavailable_reason.chance_sucks then
        tes3.messageBox("This item is beyond your skill level.")
    else
        Physical_Item.make_unavailable_msgbox(self)
    end
end

function Chance_Item:get_chance(full_stack)
    return full_stack and self.count > 1 and self.chance ~= 100 and math.clamp(math.floor((self.chance^self.count) / (100^(self.count-1))), 0, 100)
        or self.chance
end

function Chance_Item:get_name_label()
    -- if the take chance doesnt exist, or if we cant loot the item
    if self.show_chance == false or self.status < is_ok then 
        return Physical_Item.get_name_label(self) 
    end

    if self.count == 1 then 
        return string.format("%s - %i%%", self.object.name, self.chance) 
    end

    local total_chance = self:get_chance(true)
    -- from this point onwards,there are multiple items
    return self.chance == total_chance and string.format("%s (%i) - %i%%", self.object.name, self.count, self.chance)
        or string.format("%s (%i) - %i%% (%i%%)", self.object.name, self.count, self.chance, total_chance)

end
---@class MQL.Item.Training.new_params
---@field skill_id tes3.skill the `id` of the skill
---@field max_lvl integer the highest value this skill can be trained to

---@class MQL.Item.Training : MQL.Item, MQL.Item.Training.new_params
---@field value integer the cost of training this skill
---@field skill tes3skill the skill being trained
local Training_Item = Class.new{name="Training Item", parents={Item},
    fields = {
        {"skill", tostring=safe_name},
        {"skill_id",},
        {"max_lvl"},
        {"value"},
        {"weight",tostring=false, default=0},
        {"count",tostring=false}
    },
    post_init = function(self)
        self.skill = tes3.getSkill(self.skill_id)
        self:update()
    end,
}

---@param self MQL.Item.Training
function Training_Item:update()
    self.value = tes3.calculatePrice{training=true, merchant=self.ref.mobile, skill=self.skill_id}

    log("updating training item. new price: %s", self.value)

    local skill_base = tes3.mobilePlayer:getSkillStatistic(self.skill_id).base


    local related_attr_id = self.skill.attribute
    local attribute_lvl = tes3.mobilePlayer.attributes[related_attr_id+1].current -- using this instead of `base` bc trainers are ok with `fortify` spells

    log("seeing if %s can be trained. related attribute: %s", function ()
        return self.skill.name,  tes3.getAttributeName(related_attr_id)
    end)

    self.status = is_unavailable
    if tes3.getPlayerGold() < self.value then
        self.unavailable_reason = defns.unavailable_reason.too_expensive
    -- skill level must be `<= max_lvl` and also `< 100`. in order to receive training
    elseif skill_base > self.max_lvl or skill_base >= 100 then 
       self.unavailable_reason = defns.unavailable_reason.skill_too_high
    elseif attribute_lvl <= skill_base then
       self.unavailable_reason = defns.unavailable_reason.attr_too_low
    else
        self.status = is_ok
        self.unavailable_reason = nil
    end
end

function Training_Item:get_name_label()
    return string.format("%s (%i)", 
        self.skill.name, 
        tes3.mobilePlayer:getSkillStatistic(self.skill_id).base
    )
end

function Training_Item:get_icon_path() return tes3.getSkill(self.skill_id).iconPath end

function Training_Item:get_value_label()
    return self.value == 0 and '-' or tostring(self.value)
end

function Training_Item:get_weight_label() 
    return config.training.max_lvl_is_weight and tostring(self.max_lvl) or '-'
end

---@param self MQL.Item.Training
function Training_Item:make_unavailable_msgbox()
    if self.unavailable_reason == defns.unavailable_reason.too_expensive then
       tes3.messageBox("You don't have enough gold.")
    elseif self.unavailable_reason == defns.unavailable_reason.attr_too_low then
        tes3.messageBox("Your %s is too low.", tes3.getAttributeName(self.skill.attribute))
    elseif self.unavailable_reason == defns.unavailable_reason.skill_too_high then
        tes3.messageBox("There is nothing that %s can teach you.", self.ref.object.name)
    end
end


---@class MQL.Item.Barter : MQL.Item.Physical
local Barter_Item = Class.new{name="Barter Item", parents={Physical_Item},
    post_init = function (self)
        -- do the physical item post init, then make sure this item isn't stolen
        Physical_Item.__secrets.post_init(self)

        -- only do stuff if we can actually buy the item

        -- were going to want to calculate the price of the item
        local buying, selling
        if self.ref == tes3.player then
            selling = true
        else
            buying = true
        end

        -- check if the item is unavailable. if the item is unavailable, then we shouldn't know its price

        if selling and self.status == is_ok then
            -- check if the item is stolen
            if table.find(self.object.stolenList, self.related_ref.baseObject) then

                log("found a stolen object! %s was stolen from %s", self.object.name, self.related_ref.object.name)

                self.status = is_unavailable
                self.unavailable_reason = defns.unavailable_reason.stolen

            -- if the item isnt stolen, buying game is installed, and the merchant doesnt have 0 alarm
            else
                if bgcfg 
                and self.related_ref.mobile.alarm ~= 0
                and bgcfg.forbidden[self.object.id]
                and not bgcfg.smuggler[self.related_ref.baseObject.id:lower()]
                then
                    self.status = is_unavailable
                    self.unavailable_reason = defns.unavailable_reason.contraband
                end
            end
        end
        
        if self.status ~= is_ok then
            self.value = 0
            return
        end

        -- past this point, item status is okay, so we should find out what the price is
    
        self.value = tes3.calculatePrice{bartering=true, 
            buying=buying,
            selling=selling,
            merchant=self.related_ref.mobile, object= self.object, count=1,
        }

        -- dont show the item if we're selling and it has 0 value
        if selling and self.value == 0 then
            self.status = is_deleted
        end
    end
}

--- get the value label. we don't check for buying game compatibility since we're only using the prices the merchant told us
function Barter_Item:get_value_label()
    if self.value == 0 then return '-' end

    local value = self.weight == 0 and (self.value * self.count) or self.value

    if value < 1000 then 
        return tostring(math.round(value,1))
    else
        return string.format("%sk", math.round(value/1000,2) )
    end
end

---@param self MQL.Item.Barter
function Barter_Item:make_unavailable_msgbox()
    if self.unavailable_reason == defns.unavailable_reason.too_expensive then
        if self.ref == tes3.player then
            tes3.messageBox("You don't have enough gold.")
        else
            tes3.messageBox("%s doesn't have enough gold.", self.related_ref.object.name)
        end
    elseif self.unavailable_reason == defns.unavailable_reason.contraband then
        tes3.messageBox("This item is contraband!")
    else
        Item.make_unavailable_msgbox(self)
    end
end


return {
    Physical = Physical_Item, 
    Chance = Chance_Item, 
    Training = Training_Item,
    Barter = Barter_Item,
}