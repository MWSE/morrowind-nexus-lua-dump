local defns = require("herbert100.more quickloot.defns")
---@class MQL.config.Manager
---@field mi MQL.config.mi

---@class MQL.config.mi
---@field mode MQL.defns.mi|MQL.defns.mi_chance normal behavior
---@field mode_m MQL.defns.mi|MQL.defns.mi_chance   behavior when modifier key is held
---@field inv_take_all boolean should we invert behavior when taking all?
---@field min_chance number? minimum chance to tkae all
---@field min_ratio number? minimum ratio to take all
---@field max_total_weight number? maximum total weight to take all
-- old settings are commented out, and moved to the end, for historical preservation purposes





---@class MQL.config : MQL.config.Manager
---@field version number the veresion of the mod (as of the last time the config was saved)
local default = {

    -- =========================================================================
    -- GENERAL SETTINGS
    -- =========================================================================
    -- version = 0.75,
    -- log_level = 1,
    log_level = "INFO",


    take_nearby_dist = 600,
    take_nearby_allow_theft = true,

    -- these three are deprecated
    take_all_distance = 600,
    take_nearby = defns.take_nearby.use_context,    ---@type MQL.defns.take_nearby
    take_nearby_m = defns.take_nearby.never_steal,  ---@type MQL.defns.take_nearby
	


    -- should scripted containers be shown?
    show_scripted = defns.show_scripted.prefix,     ---@type MQL.defns.show_scripted
    

    -- key bindings
    -- -@type table<string, boolean|mwseKeyCombo>
    keys = {
        use_activate_btn = false,
        custom = { keyCode=tes3.scanCode.f, },
        take_all = { keyCode=tes3.scanCode.r, },
        -- changes how custom key, take_all, and activate function
        modifier = { keyCode=tes3.scanCode.lAlt },
        -- changes how custom key, take_all, and activate function
---@diagnostic disable-next-line: assign-type-mismatch
        undo = { keyCode=tes3.scanCode.z, isControlDown=true,isAltDown=false,isShiftDown=false, isSuperDown=false }, ---@type mwseKeyCombo
    },

    UI = {
        menu_x_pos = .8,
        menu_y_pos = .5,
        max_disp_items = 10,

        show_msgbox = true,
        show_lucky_msg = true,
        show_tooltips = true,
        show_name = true,
        show_controls = true,
        show_weight = true,
        show_gold = true,
        -- should we display extra controls?
        show_controls_m = true,

        -- only in supported menus
        enable_status_bar = true,

        -- how should items be sorted?
        sort_items = defns.sort_items.value_weight_ratio, ---@type MQL.defns.sort_items

        -- should we also sort by object type?
        sort_by_obj_type = true,

        ttip_collected_str = "(C)",

        ttip_mark_selected = true,

        -- update player inventory when quickloot menu is closed. can give performance boosts in some cases
        update_inv_on_close = false,
    },

    -- regular containers
    reg = {
        mi = {
            -- how should the mod handle you trying to take multiple items?
            mode = defns.mi.ratio_and_total_weight,    ---@type MQL.defns.mi
            -- how should the mod handle trying to take multiple items when the modifier key is held?
            mode_m = defns.mi.stack,    ---@type MQL.defns.mi
            -- only used for the `ratio` setting in `multiple_items`
            min_ratio = 25,                      ---@type number
    
            -- min_value = 10,
            -- only used for the `total_weight` setting in `multiple_items`
            max_total_weight = 15,                     ---@type number
    
            -- should the `take_all` key have opposite behavior from the `take` key?
            inv_take_all = false,
        },

        
        sn_dist = 200,
    
        sn_cf = defns.sn_cf.same_base_obj,            ---@type MQL.defns.sn_cf
        
        -- minimum gold/weight ratio before we take all
        take_all_min_ratio = 7.5,             
    },
                       

    
    
    
    
    -- =========================================================================
    -- MANAGER SPECIFIC SETTINGS
    -- =========================================================================
    ---@class MQL.config.Manager.Dead : MQL.config.Manager
    dead = { enable = true,
        dispose = defns.dispose.take_all, ---@type MQL.defns.dispose_dead
    },
    ---@class MQL.config.Manager.Dead : MQL.config.Manager
    inanimate = { enable = true,
        show_trapped = true,
        show_locked = false, -- use security skill to see inside locked contaienrs

        show_locked_min_security = 50,
        show_trapped_min_security = 35,

        ac = {
            open = defns.misc.ac.open.on_sight,     ---@type MQL.defns.misc.ac.open
            close = defns.misc.ac.close.use_ac_cfg, ---@type MQL.defns.misc.ac.close
            open_empty_on_sight = true,
            auto_close_if_empty = false,
        },

        
        -- minimum weight an item should have if we're to place it inside the container
        placing = {
            allow_books = false,
            allow_ingredients = true,
            reverse_sort = true,
            min_weight = 2,
        },
    },   

    ---@class MQL.config.Manager.Pickpocket : MQL.config.Manager.Chance
    pickpocket = { enable = true,

        mi = {
            -- how should the mod handle you trying to take multiple items?
            mode = defns.mi_chance.total_chance,    ---@type MQL.defns.mi_chance
        
            -- how should the mod handle trying to take multiple items when the modifier key is held?
            mode_m = defns.mi_chance.stack,                    ---@type MQL.defns.mi_chance

            -- only used for the `total_chance` setting in `multiple_items`
            min_chance = 50,

            -- should the `take_all` key have opposite behavior from the `take` key?
            inv_take_all = false,
        },
        ---@class MQL.config.equipped
        equipped = {
            weapons = false,
            armor = false,
            clothing = false,
            jewelry = true,
            accessories = true, -- belts, gloves, etc
            show = true, -- should equipped items be shown?
        },
       
        show_chances = defns.ui_show_chances.always,   ---@type MQL.defns.ui_show_chances
        show_chances_lvl = 50,                      ---@type integer level to show chances
        show_chances_100 = true,                      ---@type boolean should chances be shown if they're 100%

        determinism = false,
        determinism_cutoff = 70,

        -- in "Take All", only take items when your chance of success is at least this much
        take_all_min_chance = 50,
        
        show_detection_status = true,

        chance_mult = 1,

        min_chance = 5,
        max_chance = 100,

        detection_mult = 0.33,
        trigger_crime_undetected = true,

        

        
    },
    ---@class MQL.config.Manager.Organic : MQL.config.Manager.Chance
    organic = {
        enable = true,
        

        -- ---------------------------------------------------------------------
        -- VISUAL/COMPATIBILITY
        -- ---------------------------------------------------------------------
        -- should plants be changed when empty. if so, how?
        change_plants = defns.change_plants.none,      ---@type MQL.defns.change_plants
        not_plants_src = defns.not_plants_src.plant_list, ---@type MQL.defns.not_plants_src
        hide_on_empty = true, -- hide on empty containers

        
        -- ---------------------------------------------------------------------
        -- MULTIPLE ITEMS
        -- ---------------------------------------------------------------------
        mi = {
            -- how should the mod handle you trying to take multiple items?
            mode = defns.mi_chance.total_chance,    ---@type MQL.defns.mi_chance
        
            -- how should the mod handle trying to take multiple items when the modifier key is held?
            mode_m = defns.mi_chance.stack,                    ---@type MQL.defns.mi_chance

            -- only used for the `total_chance` setting in `multiple_items`
            min_chance = 50,

            -- should the `take_all` key have opposite behavior from the `take` key?
            inv_take_all = false,
        },

        show_chances = defns.ui_show_chances.lvl,   ---@type MQL.defns.ui_show_chances
        show_chances_lvl = 35,                      ---@type integer level to show chances
        show_chances_100 = true,                   ---@type boolean should chances be shown if they're 100%
        -- how should the mod handle you trying to take multiple items?
        -- multiple_items = defns.chance_mi.total_chance,    ---@type MQL.defns.chance_mi
       
        -- -- how should the mod handle trying to take multiple items when the modifier key is held?
        -- multiple_items_m = defns.mi_chance.stack,                    ---@type MQL.defns.chance_multiple_items

        -- -- only used for the `total_chance` setting in `multiple_items`
        -- mi_chance = 50,

        -- -- should the `take_all` key have opposite behavior from the `take` key?
        -- mi_inv_take_all = false,

        -- ---------------------------------------------------------------------
        -- XP
        -- ---------------------------------------------------------------------
        xp = {
            award = true,
            on_failure = true,
            max_lvl = 50,
        },
        -- ---------------------------------------------------------------------
        -- MISC
        -- ---------------------------------------------------------------------

        -- should a message be displayed when you fail to loot a plant?
        show_failure_msg = true,

        

        take_all_min_chance = 30,


        sn_dist = 300,
        sn_cf = defns.sn_cf.same_base_obj,            ---@type MQL.defns.sn_cf
        
        
        
        chance_mult = 1,
        min_chance = 15,
        max_chance = 100,

        -- currently not implemented anymore
        -- take_nearby = defns.take_nearby.use_context,    ---@type MQL.defns.take_nearby
        -- take_nearby_m = defns.take_nearby.never_steal,  ---@type MQL.defns.take_nearby
        -- sn_cf_take_all = defns.sn_cf.organic,         ---@type MQL.defns.sn_cf
        
        

    },
    ---@class MQL.config.Manager.Training : MQL.config.Manager
    training = {
        enable = true,
        max_lvl_is_weight = true,
    },
    ---@class MQL.config.Manager.Barter
    barter = {
        enable = true,
        
        -- should be start by buying, or start by selling?
        start_buying = true,
        switch_if_empty = true,

        equipped = {
            weapons = false,
            armor = false,
            clothing = false,
            jewelry = true,
            accessories = true, -- belts, gloves, etc
            show = true, -- should equipped items be shown?
        },

        -- should xp be given after successfully bartering? 
        award_xp = false,   -- this will be set to `true` the first time BXP is installed
        selling = {
            allow_books = true,
            allow_ingredients = true,
            reverse_sort = true,
            min_weight = 2,
        },
    },
    services = {
        enable = true,
        allow_skooma = true,
        
        default_service = defns.services.barter,    -- `services` to start at
    },
    

    blacklist = {
        containers = {},
        -- this blacklist used to be called `destroy_blacklist`
        organic = {
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

    advanced = {
        v_dist = 75,
        -- scroll wheel
        sw_claim = true,
        sw_priority = 400,
        -- arrow keys
        ak_claim = true,
        ak_priority = 400,

        -- other buttons
        activate_key_priority = 400,
        custom_priority = 400,
        take_all_priority = 400,


        -- other priority settings 
        activate_event_priority = 9999999,
        load_priority = 1000,
        menu_entered_priority = 1000,
        cell_changed_priority = 1000,
        simulate_priority = 10,
        dialogue_filtered_priority = 10,
    },

    -- this records various compatibility information
    compat = {

        ac = false, -- animated containers

        -- this records whether Graphic Herbalism was ever installed.
        -- used for changing config settings whenever GH is first installed
        gh_history = defns.misc.gh.never, ---@type MQL.defns.misc.gh 

        -- this records whether Graphic Herbalism is currently installed.
        -- used to properly load the GH blacklist, and make sure certain config settings aren't set improperly
        gh_current = defns.misc.gh.never, ---@type MQL.defns.misc.gh 

        -- is "Just the Tooltip" installed?
        ttip = false,

        -- is "Buying Game" installed?
        bg = false,

        bxp = false,
    },
    
}


local version_str = toml.loadMetadata("More QuickLoot").package.version
local major, minor, patch = table.unpack(string.split(version_str, "%."))
default.version = tonumber(major) + tonumber(minor)/10 + tonumber(patch)/100

-- update `defns.misc.version`
---@diagnostic disable-next-line: inject-field
defns.misc.version = default.version

---@class MQL.config.Manager.Chance : MQL.config.Manager
---@field take_all_min_chance   integer the minimum chance an item should have before we try to take it when the "Take All" key is pressed
---@field show_chances          MQL.defns.ui_show_chances
---@field show_chances_lvl      integer level to show chances
---@field show_chances_100      boolean should chances be shown if they're 100%


return default ---@type MQL.config