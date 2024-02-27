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
---@param obj tes3misc
local function safe_name(obj)
    if obj then
        return string.format("%s (id=%q)", obj.name, obj.id)
    end
    return "N/A"
end


-- -@field ui_status MQL.defns.item_ui_status? the UI status of this `Item`
local bgcfg

-- critical failure happens if you try to load buying game config before the game initializes
event.register("initialized", function(e)
    bgcfg = include("buyingGame.config")
end)

---@param data tes3itemData
---@return string
local function itemdata_tostring(data)
    if not data then return  tostring(data) end

    return json.encode{charge=data.charge, condition=data.condition, soul=data.soul, owner=data.owner,count=data.count}

    -- if not data then return  tostring(data) end
    -- return require("inspect"){
    --     charge=tostring(data.charge),
    --     condition=tostring(data.condition),
    --     context=tostring(data.context),
    --     count=tostring(data.count),
    --     data=tostring(data.data),
    --     owner=tostring(data.owner),
    --     requirement=tostring(data.requirement),
    --     script=tostring(data.script),
    --     scriptVariables=tostring(data.scriptVariables),
    --     soul=tostring(data.soul),
    --     tempData=tostring(data.tempData),
    --     timeLeft=tostring(data.timeLeft),
    -- }
end
---@class MQL.Item.new_params
---@field object any the object that this item is representing
---@field status MQL.defns.item_status? the status of this `Item`
---@field data tes3itemData? any `itemData` the object may have
---@field count integer? how many of the object are there (in total). default = 1
---@field value integer? the value of this item stack, i.e., `object.value`
---@field weight integer? the  weight of this item stack, i.e., `object.weight`
---@field from tes3reference the container this item is in
---@field to tes3reference the container this item wants to be in
---@field related_ref tes3reference? a reference related to this item. could be the owner of the item, the place to transfer the item to, or the merchant if bartering.
---@field unavailable_reason MQL.defns.unavailable_reason? why is the item unavailable

-- an abstract `Item` class
---@class MQL.Item : herbert.Class, MQL.Item.new_params
---@field new nil|fun(p:MQL.Item.new_params):MQL.Item make a new item
local Item = Class.new{name="Abstract Item",
    fields={
        {"from", tostring=safe_obj_name},
        {"to", tostring=safe_obj_name},
        {"related_ref", tostring=safe_obj_name},
        {"object", tostring=safe_name},
        {"status", tostring=generators.table_find(defns.item_status), default=is_ok},
        {"unavailable_reason", tostring=generators.table_find(defns.unavailable_reason)},
        {"data", tostring=itemdata_tostring},
        {"value"},
        {"count", default=1},
        {"weight"},
    },
    obj_metatable = { __eq = function(i1,i2) return i1.object == i2.object end, },
    ---@param self MQL.Item
    post_init = function(self)
        log:trace("new item made: %s", self)
    end
}


function Item:make_tooltip()
    tes3ui.createTooltipMenu{item=self.object, itemData=self.data}
end

function Item:can_take() return self.status == is_ok and self.count > 0 end

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





--- get the value of this item
---@param full_stack boolean should we get the value of the full stack?
---@return number value the value of this item
function Item:get_value(full_stack)
    return full_stack and (self.count * self.value) or self.value
end

function Item:get_weight(full_stack)
    return full_stack and (self.weight * self.count) or self.weight    
end


function Item:update_status()
    if self.count > 0 then
        if self.status == is_empty then
            self.status = is_ok
        end
    else
        if self.status == is_ok then
            self.status = is_empty
        end
    end
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
        if bgcfg and tes3.mobilePlayer and tes3.mobilePlayer.mercantile.current < bgcfg.knowsPrice then
            return "?"
        end
        local value = self.weight == 0 and (self.value * self.count) or self.value

        if value == 0 then 
            return '-'
        elseif value < 1000 then 
            return tostring(math.round(value,1))
        else
            return string.format("%sk", math.round(value/1000, 2))
        end
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
---@field new fun(p:MQL.Item.new_params): MQL.Item.Physical
---@field object tes3item|tes3alchemy|tes3weapon|tes3misc the actual item in the inventory
local Physical_Item = Class.new{name="Physical Item", parents={Item},
    fields = {
        {"related_ref"}, 
        {"weight", factory=function(self) return self.object.weight end}, 
        {"value", factory=function(self) 
            return tes3.getValue{item=self.object, itemData=self.data} 
            -- return tes3.getValue{item=self.object} 
        end}, 
    },

}

--- generate the label that should show up in the `UI`
---@param self MQL.Item.Physical
---@return string label
function Physical_Item:get_name_label()
    local suffix

    if self.count > 1 then
        suffix = self.count
    elseif self.data and self.data.soul then
        suffix = self.data.soul.name
    end
    
    if config.compat.ttip and tes3.player.itemData.data.rev_TTIP.items[self.object.id] then
        if suffix then
            return string.format("%s %s (%s)", config.UI.ttip_collected_str, self.object.name, suffix)
        else
            return string.format("%s %s", config.UI.ttip_collected_str, self.object.name)
        end

    elseif suffix then
        return string.format("%s (%s)", self.object.name, suffix)
    else
        return self.object.name
    end

end

function Physical_Item:get_icon_path() return "icons\\" .. self.object.icon end


local function debug_count_mismatch(self, num, num_taken)
    log:trace("seeing if a copy of this item with the specified item data exists in the container....")
    for _, stack in pairs(self.from.object.inventory) do
        if stack.object ~= self.object then goto next_stack end
        log:trace("found an instance of %q inside this container! checking its item data...", self.object)
        if not stack.variables then
            log:trace("the copy of %q inside the container has no item data, but the saved copy of it does...", self.object)
            return
        end
        for _, data in pairs(stack.variables) do
            if data == self.data then
                log:trace("found exact same item data on a copy of %q inside this container", stack.object)
                return
            end
        end
        log:trace("could not any copy of this item data inside the container.")
        if stack.variables[1] then
            local data = stack.variables[1]
            if data.context and self.data.context then
                log:trace("is the context of the new item data the same as the old one? %s", data.context == self.data.context)
            end
            log:trace("found a different item data for this object: %s", itemdata_tostring(data))
        end
        if true then return end
        ::next_stack::
    end
end

--- transfers an item
---@param num integer number of items to transfer
---@param update_stuff boolean? play sounds and update GUI?
---@param reverse boolean? if true, then the roles of `from` and `to` will be reversed
function Physical_Item:transfer(num, update_stuff, reverse)
    ---@type tes3.transferItem.params
    local params = {
        from=self.from, to=self.to, item=self.object, 
        count=num, itemData=self.data,
        playSound=update_stuff, updateGUI=update_stuff and not config.UI.update_inv_on_close,
        reevaluateEquipment = false
    }
    if reverse then
        params.from, params.to = self.to, self.from
    end
    local num_taken = tes3.transferItem(params)
    log("took %i %s", num_taken, self)
    if num_taken ~= num then
        log("\tERROR: only took %i/%i of %s\n\ttrying again....", num_taken, num, self)
        if log.level == 5 and self.data then
           debug_count_mismatch(self, num, num_taken)
        end
        params.itemData = nil
        num_taken = tes3.transferItem(params) +  num_taken
        log("tried again. now took a total of %i %s", num_taken, self)
    end

    return num_taken
end

-- take items from the container
---@param full_stack boolean? should the full stack be taken?
---@param update_stuff boolean? are several items being taken?
---@param check_capacity boolean? take container capacity into account?
---@return integer num_taken the amount of things taken, or false if we couldnt take anything
function Physical_Item:take(full_stack, update_stuff, check_capacity)
    -- if its not going to the player
    log("trying to take %s\n\tfull_stack = %s", self, full_stack)
    if check_capacity then
        -- container were putting ourselves in
        local cobj = self.to.object

        -- weight of this item
        local item_weight = self:get_weight(full_stack)

        -- current weight of the container we want to enter
        local container_weight = cobj.inventory:calculateWeight()

        if item_weight + container_weight > cobj.capacity then
            tes3.messageBox("This item won't fit inside this container")
            return 0
        end
    end

    local num_taken = self:transfer(full_stack and self.count or 1, update_stuff)
    if num_taken > 0 then
        self.count = self.count - num_taken
        self:update_status()
    end

    return num_taken
end


-- return these items to the container they were taken from
---@param update_stuff boolean? should we play sounds?
---@param num integer the number of items to return to the container
---@return integer num_returned how many items were put back
function Physical_Item:put_back(num, update_stuff)
    self.count = self.count + num
    local num_returned = self:transfer(num, update_stuff, true)
    if num_returned > 0 then
        self.count = self.count + num_returned
        self:update_status()
    end
    return num_returned
end

-- take items from the container
---@param full_stack boolean? should the full stack be taken?
---@param update_stuff boolean? should we play sounds?
---@return integer num_taken the amount of things taken, or false if we couldnt take anything
function Physical_Item:remove_from_container(full_stack, update_stuff)
    local num_to_remove = full_stack and self.count or 1

    local num_removed = tes3.removeItem{reference=self.from, item=self.object, 
        count=num_to_remove, itemData=self.data,
        playSound=update_stuff, updateGUI=update_stuff and not config.UI.update_inv_on_close,
        reevaluateEquipment=false,
    }
    if num_removed == 0 then
        num_removed = tes3.removeItem{reference=self.from, item=self.object, count=num_to_remove,
            playSound=update_stuff, updateGUI=update_stuff and not config.UI.update_inv_on_close,
            reevaluateEquipment=false
        }
    end
    if num_removed > 0 then
        self.count = self.count - num_removed
        self:update_status()
    end
    return num_removed
end


---@class MQL.Item.Chance.new_params : MQL.Item.new_params
---@field chance integer number between 0 and 100 that coressponds to the percentage chance of successfully taking one item
---@field show_chance boolean? should the chance be displayed.

---@class MQL.Item.Chance : MQL.Item.Physical, MQL.Item.Chance.new_params
---@field new fun(p:MQL.Item.Chance.new_params):MQL.Item.Chance make a new object
local Chance_Item = Class.new{name="Chance Item", parents = {Physical_Item},
    fields={
        {"chance"}
    }
}

function Chance_Item:make_unavailable_msgbox()
    if self.unavailable_reason == defns.unavailable_reason.chance_sucks then
        tes3.messageBox("This item is beyond your skill level.")
    else
        Physical_Item.make_unavailable_msgbox(self)
    end
end

function Chance_Item:get_chance(full_stack)
    if full_stack and self.count > 1 then
        return math.clamp(self.chance^self.count, 0, 1)
    else
        return self.chance
    end
end

function Chance_Item:get_name_label()

    local name = Physical_Item.get_name_label(self)

    -- if the take chance doesnt exist, or if we cant loot the item
    if self.show_chance == false or self.status < is_ok then 
        return name
    end

    local total_chance = self:get_chance(true)

    if self.chance == total_chance or self.weight == 0 then
        return string.format("%s - %i%%", name, math.floor(100 * total_chance))
    end
    return string.format("%s - %i%% (%i%%)", name, math.floor(100 * self.chance), math.floor(100 * total_chance))

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

function Training_Item:make_tooltip()
    tes3ui.createTooltipMenu{skill=self.skill}
end

---@param self MQL.Item.Training
function Training_Item:update()
    self.value = tes3.calculatePrice{training=true, merchant=self.from.mobile, skill=self.skill_id}

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
        tes3.messageBox("There is nothing that %s can teach you.", self.from.object.name)
    end
end


---@class MQL.Item.Barter : MQL.Item.Physical
local Barter_Item = Class.new{name="Barter Item", parents={Physical_Item},

    ---@param self MQL.Item.Barter
    init = function(self)
        local selling = self.from ~= tes3.player

        -- check if the item is unavailable. if the item is unavailable, then we shouldn't know its price
        local mref = self.related_ref ---@type tes3reference
        if selling and self.status == is_ok then

            -- check if the item is stolen
            if table.find(self.object.stolenList, mref.baseObject) then
                log("found a stolen object! %s was stolen from %s", self.object.name, mref.object.name)
                self.status = is_unavailable
                self.unavailable_reason = defns.unavailable_reason.stolen

            -- if the item isnt stolen, buying game is installed, and the merchant doesnt have 0 alarm
            elseif bgcfg and mref.mobile.alarm ~= 0 and bgcfg.forbidden[self.object.id] then
                if not bgcfg.smuggler[mref.baseObject.id:lower()] then
                    self.status = is_unavailable
                    self.unavailable_reason = defns.unavailable_reason.contraband
                end
            end
        end
        
        if self.status == is_ok then
            self.value = tes3.calculatePrice{object=self.object, itemData = self.data, 
                merchant=mref.mobile, bartering=true, selling=selling,
            }
        else
            self.value = 0
        end

        -- dont show the item if we're selling and it has 0 value
        if selling and self.value == 0 then
            self.status = is_deleted
        end
        log:trace("init: made item %s", self)
    end,
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
        if self.from == tes3.player then
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