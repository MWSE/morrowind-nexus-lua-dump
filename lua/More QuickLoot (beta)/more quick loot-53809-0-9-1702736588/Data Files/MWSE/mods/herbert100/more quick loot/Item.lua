local Class = require("herbert100.Class")
local log = require("herbert100.Logger")(require("herbert100.more quick loot.defns"))

---@class MQL.Item : Class
---@field icon_path string the path to this items icon
---@field count integer how many of the object are there
---@field label string the label to show 
---@field object tes3item|tes3alchemy|tes3weapon the actual item in the inventory
---@field total_value integer the total value of this item stack, eg `count` * `item.value`
---@field total_weight integer the total weight of this item stack, eg `item.weight` * `item.value`
local Item = Class.new({name="Item",
    converters = {count = math.abs},
    post_init = function(self)
        self.icon_path = "icons\\" .. self.object.icon
        
        self:update_totals()
        self:make_label()

        if log.level > 2 then
            log:trace("ITEM: new item made: " .. tostring(self))
        end
    end
})
--- will generate and set this items label
---@param self MQL.Item
function Item:make_label()
    if self.count > 1 then 
        self.label = ("%s (%i)"):format(self.object.name, self.count)
    else
        self.label = self.object.name
    end
end

function Item:update_totals()
    self.total_value = self.count * self.object.value
    self.total_weight = self.count * self.object.weight
end

function Item:remove_one()
    self.count = self.count - 1
    
    self:update_totals()
    self:make_label()
end

---@class MQL.Item.Chance : MQL.Item
---@field take_chance integer number between 0 and 100 that coressponds to the percentage chance of successfully taking one item
---@field total_take_chance integer number between 0 and 100 that coressponds to the percentage chance of successfully taking the whole stack
local Chance_Item = Class.new{name="Chance Item", parents = {Item}}


function Chance_Item:update_totals()
    self.total_value = self.count * self.object.value
    self.total_weight = self.count * self.object.weight

    if self.total_weight < 0.0001 then
        self.total_take_chance = self.take_chance
    else
        self.total_take_chance = math.clamp(self.take_chance * self.count, 0, 100)
    end
end

function Chance_Item:make_label()
    if self.take_chance == nil then 
        Item.make_label(self)
    elseif self.count > 1 then
        if self.take_chance ~= self.total_take_chance then
            self.label = ("%s (%i) - %i%% (%i%%)"):format(self.object.name, self.count, self.take_chance, self.total_take_chance)
        else
            self.label = ("%s (%i) - %i%%"):format(self.object.name, self.count, self.take_chance)
        end
    else
        self.label = ("%s - %i%%"):format(self.object.name, self.take_chance)
    end
end


---@class MQL.Item.Training : Class
---@field skill_id tes3.skill the `id` of the skill
---@field max_lvl integer the highest value this skill can be trained to
---@field name string the name of the skill
---@field cost integer the cost of training this skill
---@field icon_path string path to this skills icon
---@field amount number the amount of times this skill is going to be trained
local Training_Item = Class.new{name="Train Item", 
    post_init = function (self)
        self.amount = 1
        local skill = tes3.getSkill(self.skill_id)
        self.name = skill.name
        -- self.icon = skill.iconPath
        self.icon_path = skill.iconPath

        self:make_label()
    end,
}

function Training_Item:make_label()
    if self.cost ~= nil then
        local player_skill_lvl = tes3.mobilePlayer:getSkillStatistic(self.skill_id).base
        self.label = ("%s (%i) - %i gold"):format(self.name, player_skill_lvl, self.cost * self.amount)
        -- if self.amount > 1 then 
        -- else
        --     self.label = ("%s - %i gold"):format(self.name, self.cost)
        -- end
    end
end



--[[

---@class MQL.Item.Barter : Class
---@field cost integer the cost of training this skill
---@field icon_path string path to this skills icon
---@field amount number the amount of times this skill is going to be trained
local Barter_Item = Class.new{name="Barter Item", parents={Item},
    post_init = function (self)
        self.amount = 1
        local skill = tes3.getSkill(self.skill_id)
        self.name = skill.name
        -- self.icon = skill.iconPath
        self.icon_path = skill.iconPath

        self:make_label()
    end,
}

function Barter_Item:make_label()
    if self.cost ~= nil then
        local player_skill_lvl = tes3.mobilePlayer:getSkillStatistic(self.skill_id).base
        self.label = ("%s (%i) - %i gold"):format(self.name, player_skill_lvl, self.cost * self.amount)
        -- if self.amount > 1 then 
        -- else
        --     self.label = ("%s - %i gold"):format(self.name, self.cost)
        -- end
    end
end
]]
return {
    Generic = Item, 
    Chance = Chance_Item, 
    Training = Training_Item
}