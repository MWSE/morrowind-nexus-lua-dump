local defns = require("herbert100.more quick loot.defns")
---@class MQL.config.Manager
---@field multiple_items MQL.defns.multiple_items how should the mod handle you trying to take multiple items?
---@field multiple_items_m MQL.defns.multiple_items how should the mod handle you trying to take multiple items (AND HOLDING MODIFIER KEY)?
---@field mi_inv_take_all boolean should the `take_all` key have opposite behavior from the `take` key?

-- old settings are commented out, and moved to the end, for historical preservation purposes

---@class MQL.config : MQL.config.Manager
---@field version number the veresion of the mod (as of the last time the config was saved)
local default = {

    -- =========================================================================
    -- GENERAL SETTINGS
    -- =========================================================================
    -- version = 0.75,
    log_level = 1,
    take_all_distance = 600,
	
    -- should scripted containers be shown?
    show_scripted = defns.show_scripted.prefix,     ---@type MQL.defns.show_scripted
    -- how should the mod handle you trying to take multiple items?
    multiple_items = defns.multiple_items.ratio_and_total_weight,    ---@type MQL.defns.multiple_items
    -- how should the mod handle trying to take multiple items when the modifier key is held?
    multiple_items_m = defns.multiple_items.stack,    ---@type MQL.defns.multiple_items
    -- only used for the `ratio` setting in `multiple_items`
    mi_ratio = 25,                      ---@type number

    -- only used for the `total_weight` setting in `multiple_items`
    mi_tweight = 15,                     ---@type number

    -- should the `take_all` key have opposite behavior from the `take` key?
    mi_inv_take_all = false,

    -- this records compatibility settings
    compat = {
        -- this records whether Graphic Herbalism was ever installed.
        -- used for changing config settings whenever GH is first installed
        gh_history = defns.gh_status.never, ---@type MQL.defns.gh_status 

        -- this records whether Graphic Herbalism is currently installed.
        -- used to properly load the GH blacklist, and make sure certain config settings aren't set improperly
        gh_current = defns.gh_status.never, ---@type MQL.defns.gh_status 
    },
    UI = {
        menu_x_pos = .8,
        menu_y_pos = .5,
        max_disp_items = 10,
        show_msgbox = false,
        show_lucky_msg = true,
        show_tooltips = true,
        show_name = true,
        show_controls = true,
    },
    
    -- key bindings
    -- -@type table<string, boolean|mwseKeyCombo>
    keys = {
        use_interact_btn = true,
        custom = {
            keyCode=tes3.scanCode.f,
            isShiftDown = false,
            isAltDown = false,
            isControlDown = false,
        },
        take_all = {
            keyCode=tes3.scanCode.r,
            isShiftDown = false,
            isAltDown = false,
            isControlDown = false,
        },
        -- changes how custom key, take_all, and interact function
        modifier = {
            keyCode=tes3.scanCode.lAlt
        },
    },
    blacklist = {
        --[[
        -- vanilla content
        ["barrel_01_ahnassi_drink"] = true,
        ["barrel_01_ahnassi_food"] = true,
        ["com_chest_02_mg_supply"] = true,
        ["com_chest_02_fg_supply"] = true,
        -- tamriel rebuilt
        ["t_mwcom_furn_ch2fguild"] = true,
        ["t_mwcom_furn_ch2mguild"] = true,
        ["tr_com_sack_02_i501_mry"] = true,
        ["tr_i3-295-de_p_drinks"] = true,
        ["tr_i3-672_de_rm_deskalc"] = true,
        ["tr_m2_com_sack_i501_bg"] = true,
        ["tr_m2_com_sack_i501_sl"] = true,
        ["tr_m2_com_sack_i501_ww"] = true,
        ["tr_m2_q_27_fgchest"] = true,
        ["tr_m2_q_29_fgchest"] = true,
        ["tr_m3_i395_sack_local1"] = true,
        ["tr_m3_ingchest_i3-390-i"] = true,
        ["tr_m3_oe_anjzhirra_sack"] = true,
        ["tr_m3_soil_i3-390-ind"] = true,
        ]]
    },
    --[[-------------------------------------------------------------------------
    -- OLD SETTINGS (kept for historical reasons)
    -- -------------------------------------------------------------------------

    max_disp_items = 10,
    quick_loot = {
        enable = true,
        hide_trapped = true,
        hide_tooltips = true,
        hide_scripted = false,
        show_msgbox = false,
    },
    menu_x_pos = .8,
	menu_y_pos = .5,
    show_lucky_msg = true,
    
    organic = {
        destroy_plants = true,
        show_msgbox = false,
        destroy_blacklist = {}
    }
    ]]

    -- =========================================================================
    -- MANAGER SPECIFIC SETTINGS
    -- =========================================================================
    ---@class MQL.config.Manager.Dead : MQL.config.Manager
    dead = {
        enable = true,
        dispose = defns.dispose.take_all, ---@type MQL.defns.dispose_dead
    },
    ---@class MQL.config.Manager.Dead : MQL.config.Manager
    inanimate = {
        enable = true,
        show_trapped = false,
    },   

    ---@class MQL.config.Manager.Pickpocket : MQL.config.Manager.Chance
    pickpocket = {
        enable = true,

        -- how should the mod handle you trying to take multiple items?
        multiple_items = defns.chance_multiple_items.total_chance_and_regular,  ---@type MQL.defns.chance_multiple_items

        -- how should the mod handle trying to take multiple items when the modifier key is held?
        multiple_items_m = defns.chance_multiple_items.total_chance_and_regular,                   ---@type MQL.defns.chance_multiple_items

        -- only used for the `total_chance` setting in `multiple_items`
        mi_chance = 50,


        -- should the `take_all` key have opposite behavior from the `take` key?
        mi_inv_take_all = false,

        -- in "Take All", only take items when your chance of success is at least this much
        take_all_min_chance = 50,

        chance_mult = 1,
        min_chance = 5,
        max_chance = 100,
        detection_mult = 0.33,
        show_detection_status = true,
        trigger_crime_undetected = true,
        allow_equipped_weapons = false,
        allow_equipped_armor = false,

        
    },
    ---@class MQL.config.Manager.Organic : MQL.config.Manager.Chance
    organic = {
        enable = true,

       -- how should the mod handle you trying to take multiple items?
       multiple_items = defns.chance_multiple_items.total_chance,    ---@type MQL.defns.chance_multiple_items
       
       -- how should the mod handle trying to take multiple items when the modifier key is held?
       multiple_items_m = defns.chance_multiple_items.stack,                    ---@type MQL.defns.chance_multiple_items

        -- only used for the `total_chance` setting in `multiple_items`
        mi_chance = 50,


        -- should the `take_all` key have opposite behavior from the `take` key?
        mi_inv_take_all = false,

        take_all_min_chance = 30,

        -- should plants be changed when empty. if so, how?
        change_plants = defns.change_plants.none,      ---@type MQL.defns.change_plants
        hide_on_empty = true, -- hide on empty containers
        chance_mult = 1,
        min_chance = 35,
        max_chance = 100,
        not_plants_src = defns.not_plants_src.plant_list, ---@type MQL.defns.not_plants_src

        -- this blacklist used to be called `destroy_blacklist`
        plants_blacklist = {
            -- vanilla stuff
            ["barrel_01_ahnassi_drink"] = true,
            ["barrel_01_ahnassi_food"] = true,
            ["com_chest_02_mg_supply"] = true,
            ["com_chest_02_fg_supply"] = true,
            
            -- tamriel rebuilt
            ["t_mwcom_furn_ch2fguild"] = true,
            ["t_mwcom_furn_ch2mguild"] = true,
            ["tr_com_sack_02_i501_mry"] = true,
            ["tr_i3-295-de_p_drinks"] = true,
            ["tr_i3-672_de_rm_deskalc"] = true,
            ["tr_m2_com_sack_i501_bg"] = true,
            ["tr_m2_com_sack_i501_sl"] = true,
            ["tr_m2_com_sack_i501_ww"] = true,
            ["tr_m2_q_27_fgchest"] = true,
            ["tr_m2_q_29_fgchest"] = true,
            ["tr_m3_i395_sack_local1"] = true,
            ["tr_m3_ingchest_i3-390-i"] = true,
            ["tr_m3_oe_anjzhirra_sack"] = true,
            ["tr_m3_soil_i3-390-ind"] = true,

            -- unique items
            ["urn_ash_lyngas00_unique"] = true,
            ["bottle_unique"] = true,
            ["urn_ash_brinne00_unique"] = true,
            ["de_r_chest_irano_unique"] = true,
            ["com_chest_tohan_unique"] = true,
            ["flora_treestump_unique"] = true,
            ["chest_clawfang_unique"] = true,
            ["urn_ash_nan00_unique"] = true,
            ["crate_02_mead_unique"] = true,
        }, ---@type table<string, boolean>

    },
    ---@class MQL.config.Manager.Training : MQL.config.Manager
    training = {
        enable = true,
    }
}



---@class MQL.config.Manager.Chance : MQL.config.Manager
---@field multiple_items MQL.defns.chance_multiple_items the multiple items setting
---@field multiple_items_m MQL.defns.chance_multiple_items the multiple items setting used when the modifier key is held
---@field mi_chance MQL.defns.chance_multiple_items minimum take chance for success
---@field take_all_min_chance integer the minimum chance an item should have before we try to take it when the "Take All" key is pressed



return default ---@type MQL.config