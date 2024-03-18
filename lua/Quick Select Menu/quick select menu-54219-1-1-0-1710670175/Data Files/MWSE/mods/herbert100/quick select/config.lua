---@class herbert.QS.config.tab_setting
---@field enable boolean should this tab be shown in the canonical quick select menu?
---@field name string name this tab should have in the canonical quick select menu
---@field color {[1|2|3]: number} the RGB values corresponding to the color this tab should use in the canonical quick select menu

---@class herbert.QS.config
local default = {
    root_ui_scale = 0.95,
    root_ui_x_scale = 1.0,
    root_ui_y_scale = 1.0,
    num_rows = 4,
    num_cols = 6,

    border_rows = 2,
    border_cols = 2,
    option_bg_alpha = 0.45,
    option_over_alpha = 0.5,
    option_leave_alpha = 0.2,


    big_number_time = 0.4,

    toggle_mode = false,

    -- make_sg_tab = true,
    -- make_recents_tab = true,
    -- make_tools_tab = true,
    select_on_key_release = false,
    mouse_scroll_block_time = 0.07,
    ---@diagnostic disable-next-line: assign-type-mismatch
    key = { keyCode = tes3.scanCode.g }, ---@type mwseKeyMouseCombo

    tabs = {
        ---@type herbert.QS.config.tab_setting[]
        custom = {
            [1] = {enable=true,     name="Favorites",       color={0.40, 1.00, 0.35}},
            [2] = {enable=false,    name="More Favorites",  color={0.93, 0.51, 0.05}}, -- {238/256, 130/256, 013/256}
            [3] = {enable=false,    name="Spells",          color={0.20, 0.50, 1.00}},
            [4] = {enable=false,    name="Weapons",         color={0.90, 0.35, 0.20}},
            [5] = {enable=false,    name="Armor",           color={0.00, 0.90, 0.60}},
        },


        -- -@type table<string, herbert.QS.config.tab_setting>
        auto_gen = {
            -- -@type herbert.QS.config.tab_setting
            tools = {enable=true, name="Tools",    color={0.30, 0.70, 1.0},
                max_to_show = {
                    [tes3.objectType.apparatus] = 1,
                    [tes3.objectType.lockpick] = 4,
                    [tes3.objectType.probe] = 2,
                    [tes3.objectType.repairItem] = 2,
                    [tes3.objectType.light] = 3,
                },
                include_spells = true,
                include_on_use = true,
            },      
            ---@type herbert.QS.config.tab_setting
            soul_gems = {enable=false, name = "Soul gems", color={0.4, 0.2, 0.9}},
  
            ---@type herbert.QS.config.tab_setting
            recent = {enable=true, name="Recent",  color={1.00, 0.15, 0.4}},

            -- ---@type herbert.QS.config.tab_setting
            -- on_use = {enable=true, name="On Use",  color={1.00, 0.15, 0.4}},
        },
        
    }
}

-- randomly generate the remaining tabs
for i=1, 10 do
    if not default.tabs.custom[i] then
        local color = {}
        for j = 1, 3 do color[j] = math.round(math.random(), 2) end

        default.tabs.custom[i] = {enable=false, name="Custom " .. i, color=color}
    end
end

local modname = require("herbert100").get_active_mod_info(-1).metadata.package.name

---@type herbert.QS.config
local cfg = mwse.loadConfig(modname, default)

return cfg