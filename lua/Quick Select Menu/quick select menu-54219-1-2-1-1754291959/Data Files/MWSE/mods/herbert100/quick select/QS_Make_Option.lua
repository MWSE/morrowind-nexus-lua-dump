local log = mwse.Logger.new()
local common = require("herbert100.quick select.common") ---@type herbert.QS.common

---@class herbert.QS.Make_Option.new_params
---@field item tes3item|tes3weapon|tes3spell? the item to replace
---@field is_magic boolean? is this a magic item?
---@field inv_select_callback fun(p: tes3ui.showInventorySelectMenu.callbackParams)
---@field magic_select_callback fun(p: tes3ui.showMagicSelectMenu.callbackParams)

---@class herbert.QS.Make_Option : herbert.QS.Menu.Option, herbert.Class, herbert.QS.Make_Option.new_params
---@field new fun(p:herbert.QS.Make_Option.new_params): herbert.QS.Make_Option
---@field make_tooltip nil|false|fun(self: herbert.QS.Menu.Option, e: tes3uiEventData) method that makes a tooltip, or nil, or false
local QS_Make_Option = Herbert_Class.new{
fields={
    {"item"},
    {"is_magic"},
},
---@param self herbert.QS.Make_Option
post_init=function(self)
    local obj = self.item
    if obj then
        self.name = "Replace " .. obj.name
        if obj.objectType == tes3.objectType.spell then
            self.icon_path = "icons\\" .. tes3.getMagicEffect(obj.effects[1].id).bigIcon
        else
            self.icon_path = "icons\\" .. obj.icon
        end
        log:trace("making an option to replace %s", obj.name)
    else
        self.make_tooltip = false
        log:trace("making an option to pick a new item")
    end
    self.name = self.name or "Pick a new item"
end}




---@class herbert.QS.make_magic_select_button.params
---@field title string
---@field allow_enchanted boolean?
---@field allow_powers boolean?
---@field allow_spells boolean?

---@param p herbert.QS.make_magic_select_button.params
---@return tes3ui.showMessageMenu.params.button
function QS_Make_Option:make_magic_select_button(p)
    ---@type tes3ui.showMessageMenu.params.button
    return {text=p.title, 
        callback=function()
            -- event.unregister(tes3.event.keyDown, close_menu_with_esc_key, {filter=tes3.scanCode.esc})
            tes3ui.showMagicSelectMenu{
                title=p.title, 
                selectEnchanted=p.allow_enchanted ~= false,
                selectPowers=p.allow_powers == true,
                selectSpells=p.allow_spells ~= false,
                callback=self.magic_select_callback
            }
        end
    }
end

---@class herbert.QS.make_inv_select_button.params
---@field title string
---@field hide_ui_exp_filter_icons boolean?
---@field sort_options (nil|fun(tes3object, tes3object): boolean)
---@field filter tes3.objectType|number|table|false|nil|(fun(p:tes3ui.showInventorySelectMenu.filterParams): boolean)

-- wrapper for my other wrapper for the UI wrapper. what am i even doing
---@param self herbert.QS.Make_Option
---@param p herbert.QS.make_inv_select_button.params
---@return tes3ui.showMessageMenu.params.button
function QS_Make_Option:make_inventory_select_button(p)
    ---@type tes3ui.showMessageMenu.params.button
    local btn = {text=p.title, 
        callback=function() 
            common.show_inventory_select_menu{
                title=p.title, 
                filter=p.filter,
                sort_options=p.sort_options, 
                hide_ui_exp_filter_icons=p.hide_ui_exp_filter_icons,
                callback=self.inv_select_callback
            } 
        end,
    }
    return btn
end


function QS_Make_Option:select()
    ---@type tes3ui.showMessageMenu.params.button[]

    tes3ui.showMessageMenu{cancels=true, buttons={
        self:make_magic_select_button{title="Spells & Magic Items", 
            allow_enchanted=true, allow_powers=true, allow_spells=true
        },
        self:make_magic_select_button{title="Magic Items", 
            allow_enchanted=true, allow_powers=false, allow_spells=false
        },
        
        self:make_inventory_select_button{title="All Items"},

        self:make_inventory_select_button{title="Weapons", 
            filter=tes3.objectType.weapon, 
            hide_filter_icons=true,
            sort_options=common.make_sorters.weapon()
        },
        self:make_inventory_select_button{title="Armor & Clothing", 
            filter={tes3.objectType.clothing, tes3.objectType.armor}, 
            hide_filter_icons=true,
            sort_options=common.make_sorters.clothing_or_armor()
        },
        self:make_inventory_select_button{title="Tools",
            filter=common.tools, 
            hide_filter_icons=true,
            sort_options=common.make_sorters.tools()
        },
    }}
end

function QS_Make_Option:make_tooltip(e)
    if not self.item then return end 
    if self.item.objectType == tes3.objectType.spell then
        tes3ui.createTooltipMenu{spell=self.item}
    else
        tes3ui.createTooltipMenu{item=self.item}
    end
end

return QS_Make_Option
