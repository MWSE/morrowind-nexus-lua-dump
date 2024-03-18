local log = Herbert_Logger()

local ot = tes3.objectType
local tools_set = {
    [ot.lockpick] = true, 
    [ot.probe] = true, 
    [ot.apparatus] = true, 
    [ot.repairItem] = true, 
    [ot.light] = true
}
local ot_spell, ot_enchantment = ot.spell, ot.enchantment

---@class herbert.QS.Item_Option.new_params
---@field item tes3weapon|tes3armor|tes3clothing|tes3spell|tes3lockpick|tes3light|tes3apparatus
---@field data tes3itemData?
---@field is_magic boolean? should this be equipped via the "equipMagic" method?

---@class herbert.QS.Item_Option : herbert.QS.Menu.Option, herbert.Class, herbert.QS.Item_Option.new_params
---@field type tes3.objectType
---@field condition number? current condition for this item (if it has one)
---@field max_condition number? max condition for this item (if it has one)
---@field count number? how many
---@field new fun(p: herbert.QS.Item_Option.new_params): herbert.QS.Item_Option
local Option = Herbert_Class.new{
    fields={
        {"item"},
        {"is_magic"},
        {"type"},
        {"data", tostring=function(v) return v and "yes" or "no" end},
        {"type", tostring=function(v) return table.find(ot, v) end},
        {"icon_path"},
    }, ---@param self herbert.QS.Item_Option
    post_init=function(self)
        self.name = self.name or self.item.name
        log:trace("initializing option for %q (id = %q, type = %q)", function() 
            return self.name, self.item.id, table.find(ot, self.item.objectType)
        end)
        self.type = self.item.objectType
        if self.type == ot_spell then
            self.is_magic = true
            self.icon_path = "icons\\" .. tes3.getMagicEffect(self.item.effects[1].id).bigIcon
            return
        elseif  self.type == ot_enchantment then
            self.icon_path = "icons\\" .. tes3.getMagicEffect(self.item.effects[1].id).bigIcon
            return
        end

        self.icon_path = "icons\\" .. self.item.icon

        if not tools_set[self.type] then return end
        
        local obj = self.item
        if obj.objectType == ot.light then
            self.condition = math.round(obj:getTimeLeft(self.data or tes3.player), 1) or obj.time
            self.max_condition = obj.time
        else
            self.condition = self.data and self.data.condition or obj.maxCondition
            self.max_condition = obj.maxCondition
        end
        if self.condition and self.max_condition then
            self.name = string.format("%s (%s/%s)", obj.name, self.condition, self.max_condition)
        end
    end
}


function Option:select()
    if self.is_magic then
        local success = tes3.mobilePlayer:equipMagic{
            source=self.item, 
            itemData=self.data, 
            equipItem=self.type ~= ot_spell
        }
        if not success then
            tes3.messageBox("You couldn't equip this %s.", table.find(ot, self.type))
        end
        return
    end
    if not tes3.mobilePlayer:equip{item=self.item, itemData=self.data} then
        tes3.messageBox("You couldn't equip this item.")
    end
end
---@param e tes3uiEventData
function Option:make_tooltip(e)
    if self.type == ot_spell then
        tes3ui.createTooltipMenu{spell=self.item}
    else
        tes3ui.createTooltipMenu{item=self.item, itemData=self.data}
    end
end

return Option