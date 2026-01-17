local log = mwse.Logger.new()
local Option = require("herbert100.quick select.QS_Option")
local Make_Option = require("herbert100.quick select.QS_Make_Option")
local cfg = require("herbert100.quick select.config")


---@class herbert.QS.Player_Data_Tab : herbert.QS.Menu.Tab, herbert.Class
---@field getting boolean are we getting values or setting them?
---@field tab_index integer index of the player data tab
---@field new fun(tab_index: integer, getting: boolean?): herbert.QS.Player_Data_Tab
local Player_Data_Tab = Herbert_Class.new{
    fields={
        {"name"},
        {"color", tostring=json.encode},
        {"options", tostring=Herbert_Class_utils.premade.array_tostring},
        {"tab_index"},
        {"getting", default=true},
    },
    new_obj_func="no_obj_data_table",
    init=function (self, tab_index, getting)
        self.options = {}
        self.tab_index = tab_index
        self.getting = getting
        self.name = cfg.tabs.custom[self.tab_index].name
        self.color = cfg.tabs.custom[self.tab_index].color
    end
}
-- wrapper for a wrapper for a wrapper for a
local function make_inv_select_callback(tab, tab_index)
    return function (p)
        local obj = p.item
        if obj then
            tes3.messageBox("You picked %s.", obj.name)
            tab[tab_index] = {obj.id}
        else
            tes3.messageBox("You picked nothing.")
        end
        tes3ui.leaveMenuMode()
    end
end

local function make_magic_select_callack(tab, tab_index)
    return function (p)
        local obj = p.item or p.spell
        if obj then
            tes3.messageBox("You picked %s.", obj.name)
            tab[tab_index] = {obj.id, true}
        else
            tes3.messageBox("You picked nothing.")
        end
        tes3ui.leaveMenuMode()
    end
end

function Player_Data_Tab:get_options()
    local data = tes3.player.data.herbert_QS ---@type herbert.QS.player_data
    local tab = data.custom_tabs[self.tab_index]
    local options = {}
    log:trace("making custom tab %i", self.tab_index)
    if self.getting then
        for j, option_data in pairs(tab) do
            log:trace("making option %i: %s", function()
                return j, json.encode(option_data)
            end)
            options[j] = Option.new{item=tes3.getObject(option_data[1]), is_magic=option_data[2]}
        end
        return options
    end
    for j=1, cfg.num_options do

        local option_data = tab[j]

        options[j] = Make_Option.new{
            item = option_data and tes3.getObject(option_data[1]), 
            is_magic = option_data and option_data[2],
            inv_select_callback=make_inv_select_callback(tab, j),
            magic_select_callback=make_magic_select_callack(tab, j),
        }
    end
    return options
end

function Player_Data_Tab:change_mode()
    self.getting = not self.getting
end

return Player_Data_Tab