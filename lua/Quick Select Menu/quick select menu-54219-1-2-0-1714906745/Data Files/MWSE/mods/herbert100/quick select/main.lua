local log = Herbert_Logger.new{include_timestamp=true}
local hlib = require("herbert100")

local cfg = hlib.import("config") ---@type herbert.QS.config
local Menu = hlib.dofile("QS_Menu") ---@type herbert.QS.Menu
local Option = hlib.import("QS_Option") ---@type herbert.QS.Item_Option
local Player_Data_Tab = hlib.import("QS_Player_Data_Tab") ---@type herbert.QS.Player_Data_Tab
local get_options = hlib.import("get_options") ---@type herbert.QS.get_options
local fmt = string.format
local metadata = (hlib.get_mod_info() or {}).metadata


---@alias herbert.QS.saved_option {[1]: string, [2]: boolean}


-- -@class herbert.QS.saved_option
-- -@field id string
-- -@field is_magic boolean?

---@class herbert.QS.player_data
---@field custom_tabs herbert.QS.saved_option[][] for each `tab_index`, it contains an array of tuples. the first index of each tuple is the item id, the second index is whether that item is a magic item
---@field tab_index integer the last activate tab index
---@field recent_item_ids string[] stores item ids of recently used items
---@field version string?
local default_player_data = {
    custom_tabs = {},
    tab_index=1,
    recent_item_ids={},
    version=metadata and metadata.package and metadata.package.version
}

for i = 1, #cfg.tabs.custom do
    default_player_data.custom_tabs[i] = {}
end

local player_data ---@type herbert.QS.player_data?
local recent_item_ids ---@type string[]

local function custom_tabs_tostring(custom_tabs)
    return table.concat(hlib.tbl_ext.map2(custom_tabs, function(i, tab)
        return fmt("%i) %s", i, json.encode(tab))
    end), "\n\t")
end
local function sanitize_player_data()
    ---@diagnostic disable-next-line: cast-local-type
    recent_item_ids = nil
    player_data = hlib.load_player_data("herbert_QS", default_player_data)
    if not player_data then 
        log:error("could not load player data!")
        return 
    end

    recent_item_ids = player_data.recent_item_ids

    if player_data.version ~= nil then
        log("player data was loaded successfully")
        log:trace("player_data = %s", json.encode, player_data, {indent=true})
        -- log:trace("custom tabs are: \n\t%s", custom_tabs_tostring, player_data.custom_tabs)
        return
    end
    log("updating player data from previous version")
    local custom_tabs = player_data.custom_tabs

    for i, tab in ipairs(player_data.custom_tabs) do
    -- for i = 1, #cfg.tabs.custom do
        -- local tab = custom_tabs[i]
        local old_keys = {}
        for j, v in pairs(tab) do
            if type(v) == "string" then
                log("custom_tabs[%i][%i] == %s is a string. queuing it to be updated", i, j, v)
                table.insert(old_keys, j)
            elseif type(v) == "table" and #v == 0 then
                log("custom_tabs[%i][%i] == %s was a table with len 0. updating it.", function()
                    return i, j, json.encode(v)
                end)
                v[1] = v.id
                v[2] = v.is_magic
                ---@diagnostic disable-next-line: inject-field
                v.id, v.is_magic = nil, nil
            end
        end
        for _, j in pairs(old_keys) do
            log("custom_tabs[%i][%i] == %s is a string. updating it", i, j, tab[j])

            ---@diagnostic disable-next-line: param-type-mismatch
            local obj = tes3.getObject(tab[j])
            local is_magic = obj and obj.objectType == tes3.objectType.spell or nil
            
            ---@diagnostic disable-next-line: assign-type-mismatch
            tab[j] = {tab[j], is_magic}
        end
    end
    log("updated player data. tabs are now: \n\t%s", custom_tabs_tostring, custom_tabs)
    if metadata then
        player_data.version = metadata.package.version
    end
end




local qs_menu ---@type herbert.QS.Menu?




-- local equipped_id ---@type string




---@param item tes3item|tes3spell
local function update_recently_equipped(item)
    if not recent_item_ids then
        log("recent item ids was nil, aborting")
        return
    end
    local id = item.id

    local prev_index = table.find(recent_item_ids, id)
    if prev_index then
        log("found %q at recent_item_ids[%i]. removing it...", item.name, prev_index)
        table.remove(recent_item_ids, prev_index)
    end

    log("inserting recently equipped item %q (id=%q)", item.name, id)
    table.insert(recent_item_ids, 1, id)

    for i = cfg.num_options + 1, #recent_item_ids do
        recent_item_ids[i] = nil
    end
    log("have %i recently equipped items: %s", function()
        return #recent_item_ids, json.encode(recent_item_ids)
    end)


end

---@param e equippedEventData
local function equipped(e)
    if e.reference == tes3.player then
        log("%q has equipped an item!", e.actor.name)
        update_recently_equipped(e.item)
    end
end
---@param e magicSelectionChangedEventData
local function magic_selection_changed(e)
    log("magic selection changed!")
    local obj = e.item or e.source
    if not obj then return end


    log("now have %q equipped", obj)
    update_recently_equipped(obj)
end



local function make_recents_options()
    local options = {}
    local obj
    for i, id in ipairs(recent_item_ids) do
        obj = tes3.getObject(id)
        if obj then
            table.insert(options, Option.new{item=obj})
        else
            log:error("recently_equipped[%i] = %q was nil!!!", i, id)
        end
    end
    return options

end


local function special_button_held(getting)
    if cfg.toggle_mode and qs_menu then
        qs_menu:destroy()
        qs_menu = nil
        return
    end
    if tes3.menuMode() then return end
    local data = tes3.player.data.herbert_QS
    local tabs_cfg = cfg.tabs

    local tabs = {}
    for i, custom_tab in ipairs(tabs_cfg.custom) do
        if custom_tab.enable then
            table.insert(tabs, Player_Data_Tab.new(i, getting))
        end
    end
    if getting then
        local auto_gen = tabs_cfg.auto_gen
        if auto_gen.tools.enable then
            table.insert(tabs, {name=auto_gen.tools.name, color=auto_gen.tools.color, get_options=get_options.tools})
        end
        if auto_gen.soul_gems.enable then
            table.insert(tabs, {name=auto_gen.soul_gems.name, color=auto_gen.soul_gems.color, get_options=get_options.soul_gems})
        end
        if auto_gen.recent.enable then
            table.insert(tabs, {name=auto_gen.recent.name, color=auto_gen.recent.color, get_options=make_recents_options})
        end
        -- if auto_gen.on_use.enable then
        --     table.insert(tabs, {name=auto_gen.on_use.name, color=auto_gen.on_use.color, get_options=get_options.on_use_enchants})
        -- end
    end
    if cfg.list_mode then
        qs_menu = Menu.new{tabs=tabs, tab_index=data.tab_index, num_rows=cfg.num_options, num_cols=1}
    else
        qs_menu = Menu.new{tabs=tabs, tab_index=data.tab_index}
    end
end


local function special_button_released()
    if cfg.toggle_mode then return end

    if tes3.menuMode() and qs_menu then 
        qs_menu:destroy()
        -- if qs_menu.tab_index then 
        --     player_data.tab_index = qs_menu.tab_index 
        -- end
        qs_menu = nil
    end
end

---@param e keyDownEventData
local function key_pressed(e)
    if e.keyCode == cfg.key.keyCode then 
        special_button_held(not e.isAltDown)
    end
    -- qs_menu = QS_Menu.new{tab_names=tab_names, tab_index=data.tab_index, get_options=opts_fun}
end

---@param e keyUpEventData
local function key_released(e)
    if e.keyCode == cfg.key.keyCode then
        special_button_released()
    end
end


---@param e mouseButtonDownEventData
local function mouse_down(e)
    if e.button == cfg.key.mouseButton then
        special_button_held(not e.isAltDown)
    end
end

---@param e mouseButtonUpEventData
local function mouse_up(e)
    if e.button == cfg.key.mouseButton then
        special_button_released()
    end
end






local function loaded()
    sanitize_player_data()
end

local function initialized()
    event.register(tes3.event.keyDown, key_pressed)
    event.register(tes3.event.keyUp, key_released)
    event.register(tes3.event.mouseButtonDown, mouse_down)
    event.register(tes3.event.mouseButtonUp, mouse_up)
    event.register(tes3.event.loaded, loaded)
    event.register(tes3.event.equipped, equipped)
    event.register(tes3.event.magicSelectionChanged, magic_selection_changed)


    ---@param e herbert.QS.Menu.tab_selected.event_data
    event.register("herbert:QS:tab_selected", function (e)
        if qs_menu == e.menu then
            player_data.tab_index = e.tab_index
        end
    end)

    
    log:write_init_message()
end

event.register(tes3.event.initialized, initialized)



local underline_rect_id = tes3ui.registerID("herbert:QS:MCM:underline_rect")
local bg_leave_rect_id = tes3ui.registerID("herbert:QS:MCM:bg_leave_rect")
local bg_over_rect_id = tes3ui.registerID("herbert:QS:MCM:bg_over_rect")
---@param self mwseMCMDecimalSlider
local function color_slider_callback(self)
    local color_cfg = self.variable.table

    local label_block = self.parentComponent.elements.labelBlock
    if not label_block then
        log("couldn't find label block!")
        return
    end
    local underline_rect = label_block:findChild(underline_rect_id)
    if underline_rect then
        underline_rect.color = color_cfg
        underline_rect:updateLayout()
    else
        log("error! color rectangle was not created")
    end
    local bg_over_rect = label_block:findChild(bg_over_rect_id)
    if bg_over_rect then
        bg_over_rect.parent.alpha = cfg.option_bg_alpha
        bg_over_rect.alpha = cfg.option_over_alpha
        bg_over_rect.color = color_cfg
        bg_over_rect:getTopLevelMenu():updateLayout()
    else
        log("error! color rectangle was not created")
    end
    local bg_leave_rect = label_block:findChild(bg_leave_rect_id)
    if bg_leave_rect then
        bg_leave_rect.parent.alpha = cfg.option_bg_alpha
        bg_leave_rect.alpha = cfg.option_leave_alpha
        bg_leave_rect.color = color_cfg
        bg_leave_rect:getTopLevelMenu():updateLayout()
    else
        log("error! color rectangle was not created")
    end
end

---@param self mwseMCMCategory
local function color_category_post_create(self)
    log("creating color rectangle for %s", self.label)
    local label_block = self.elements.labelBlock
    if not label_block then
        log:error("couldn't find label block when making mcm color palletes")
        return 
    end

    local color_cfg

    for _, comp in pairs(self.components) do
        if comp.componentType == "Setting" then
            color_cfg = comp.variable.table
            if color_cfg then break end
        end
    end

    label_block.flowDirection = tes3.flowDirection.leftToRight
    label_block.childAlignY = 0.5

    do -- underline_rect 
        local underline_rect = label_block:createRect{color=color_cfg, id=underline_rect_id}
        underline_rect.widthProportional = 1.0
        underline_rect.heightProportional = 0.75
        underline_rect.borderLeft = 12
        underline_rect.borderRight = 2
    end

    do -- over_rect
        local bg_rect_container = label_block:createRect{color={0, 0, 0}}
        bg_rect_container.widthProportional = 1.0
        bg_rect_container.heightProportional = 0.75
        bg_rect_container.borderLeft = 2
        bg_rect_container.borderRight = 2
        bg_rect_container.alpha = cfg.option_bg_alpha

        local bg_over_rect = bg_rect_container:createRect{color=color_cfg, id=bg_over_rect_id}
        bg_over_rect.widthProportional = 1.0
        bg_over_rect.heightProportional = 1.0
        bg_over_rect.alpha = cfg.option_over_alpha
    end
    do -- leave_rect 
        local bg_rect_container = label_block:createRect{color={0, 0, 0}}
        bg_rect_container.widthProportional = 1.0
        bg_rect_container.heightProportional = 0.75
        bg_rect_container.borderLeft = 2
        bg_rect_container.borderRight = 12
        bg_rect_container.alpha = cfg.option_bg_alpha

        local bg_leave_rect = bg_rect_container:createRect{color=color_cfg, id=bg_leave_rect_id}
        bg_leave_rect.widthProportional = 1.0
        bg_leave_rect.heightProportional = 1.0
        bg_leave_rect.alpha = cfg.option_leave_alpha
    end

end

event.register("modConfigReady", function (e)
    ---@type herbert.MCM
    local MCM = require("herbert100.MCM").new()


    MCM:register()
    local page = MCM:new_sidebar_page{label="General Settings", desc="This mod adds a \"quick select\" menu. \z
            The quick select menu has several tabs that each have various items and spells.\n\n\z
            \z
            There are two types of tabs: \"custom tabs\" and \"autogenerated tabs\". \n\n\z
            \z
            \"Custom tabs\" work like the \"quick key\" system: you pick which item goes in which slot.\n\z
            You can add items to \"custom tabs\" by holding ALT and pressing the \"special key\".\n\n\z
            \"Autogenerated tabs\" generate their contents automatically based on your character's current inventory. \z
            For example, the \"Soul gems\" tab keeps an up-to-date list of all the filled soul gems you have.\n\n\z
            \z
            In every tab, you can select items by typing the number listed in the top left corner.\n\z
            This also works for double digit numbers, you'll just need to be a bit speedy when typing in the number. \z
            (e.g., typing \"15\" will select the 15th option.)\n\n\z
            You can customize the colors of each tab in the relevant page of this mod's MCM. \z
            You can activate/deactive up to 10 custom tabs and rename them to whatever you want.\n\n\z
            All settings take effect the next time the quick select menu is opened.\z
        "}
    
    
    local key_cat = page:new_category{label="Keybind settings", desc=page.component.description }
    
    key_cat.component:createKeyBinder{label="Special key (opens menu)", description="Pressing this key opens the quick select menu.\n\n\z
        Hold down ALT while pressing this key to change your favorited items.",
        variable=mwse.mcm.createTableVariable{id="key", table=cfg},
        allowMouse=true
    }

    key_cat:new_button{label="Special key toggles menu.", id="toggle_mode",
    desc="If this setting is enabled, then releasing the special key won't close the menu. i.e., you press the key once to open the menu, then press it again to close the menu.\n\n\z
        If this is disabled, then the menu will be closed as soon as you let go of the key.\n\n\z
        \z
        Regardless of which option you pick, clicking on an item or typing in a number will automatically close the menu.\z
    "}

    key_cat:new_button{id="select_on_key_release", label="Select option on key release?", 
        desc='If enabled, you will select whichever item your cursor is ontop of as soon as you close the menu. If this is disabled, \z
        you will have to click on an item to select it.\n\n\z
        This setting does not affect the behavior of the menu when you select items by typing in the corresponding number.\z
        '
    }
    -- If enabled, the menu will be closed as soon as you stop holding down the special key.\n\n\z
    -- If this is disabled, then you can toggle the visibility of the menu 

    local ui_cat = page:new_category{label="UI settings", desc=page.component.description }
    
    local show_icons_opt = ui_cat:new_button{id="show_icons", label="Show icons?", desc="Show icons?" }
    local list_mode_opt = ui_cat:new_button{id="list_mode", label="List mode?", 
        desc="Show options in a list instead of as a grid.",
    }


    ui_cat:new_pslider{id="x_pos", label="Menu X Position", desc="X Position of the menu." }
    ui_cat:new_pslider{id="y_pos", label="Menu Y Position", desc="Y Position of the menu." }

    local function update_num_options()
        cfg.num_options = cfg.list_mode and cfg.num_rows or (cfg.num_rows * cfg.num_cols) 
    end

    local nrows_opt = ui_cat:new_slider{id="num_rows", label="Number of rows",
        min=1, max=50, jump=2, callback=update_num_options,
        desc="Quick select menus will have this many rows."
    }

    local ncols_opt = ui_cat:new_slider{id="num_cols", label="Number of columns",
        min=1, max=15, jump=3, callback=update_num_options,
        desc="Quick select menus will have this many columns."
    }
    function ui_cat.component:postCreate()
        ncols_opt.elements.outerContainer.visible = not cfg.list_mode
    end
    
    function list_mode_opt:callback()

        if cfg.list_mode then
            nrows_opt.max = 50
            cfg.show_icons = false
            cfg.num_rows = cfg.num_options
        else
            cfg.show_icons = true
            -- reduce the number of rows that are displayed
            local ncols = cfg.num_cols
            local max = 25
            nrows_opt.max = max
            local nrows = math.round(cfg.num_options / ncols)

            while nrows < max and nrows * ncols < cfg.num_options - 5 do
                nrows = nrows + 1
            end
            cfg.num_rows = math.clamp(nrows , nrows_opt.min, nrows_opt.max)
        end
        ncols_opt.elements.outerContainer.visible = not cfg.list_mode

        cfg.num_rows = math.clamp(cfg.num_rows, nrows_opt.min, nrows_opt.max)
        nrows_opt:updateWidgetValue()
        nrows_opt:updateValueLabel()
        show_icons_opt:update()
        update_num_options()
    end
    

    ui_cat:new_pslider{id="root_ui_scale", label="UI scale", 
        desc='This setting affects the percentage of your screen that the UI will occupy. If set to 100%%, then the UI will occupy 100%% of your screen when active. \z
        The UI will take up this percentage of your screen.\n\n\z
        \z
        This will take effect the next time a quick select menu is opened.\n\n\z
        This does not affect the size of any text that appears in the UI.\z
    '
    }

    ui_cat:new_pslider{id="root_ui_x_scale", label="UI horizontal scale", 
        desc='Affects the horizontal scaling of the UI. This works in conjunction with the "UI Scale" setting. Setting both the horizontal and vertical scaling to 50%% will accomplish the same thing as setting the "UI scale" to 50%%.\n\n\z
        \z
        You might want to lower this if you\'re using an ultrawide monitor.\n\n\z
        This will take effect the next time a quick select menu is opened.\n\n\z
        This does not affect the size of any text that appears in the UI.\z
    '
    }

    ui_cat:new_pslider{id="root_ui_y_scale", label="UI vertical scale", 
        desc='Affects the vertical scaling of the UI. This works in conjunction with the "UI Scale" setting. Setting both the horizontal and vertical scaling to 50%% will accomplish the same thing as setting the "UI scale" to 50%%.\n\n\z
        \z
        This will take effect the next time a quick select menu is opened.\n\n\z
        This does not affect the size of any text that appears in the UI.\z
    '
    }

    local adv = page:new_category{label="Niche settings", desc="These settings let you fine-tune the behavior of the mod, but they're fairly niche."}

    adv:new_textfield{label="UI: Spacing between rows", id="border_rows", numeric=true, desc="This setting lets you specify how much empty space should appear between rows. Default: 2."}
    adv:new_textfield{label="UI: Spacing between columns", id="border_cols", numeric=true, desc="This setting lets you specify how much empty space should appear between columns. Default: 2."}
    adv:new_pslider{label="UI: opacity of item background", id="option_bg_alpha",
        desc="The option tiles are given a black background to darken the colors and make the white text easier to read. \z
        This settings lets you control the opacity of the black background. Setting this to 0% will disable it."}
    adv:new_pslider{label="UI: opacity of unhighlighted item background", id="option_leave_alpha",
        desc="This lets you control the opacity of the color part of the item tile background when a tile is not highlighted."
    }
    adv:new_pslider{label="UI: opacity of highlighted item background", id="option_over_alpha",
        desc="This lets you control the opacity of the color part of the item tile background when a tile is highlighted."
    }

    adv:new_slider{label="Ignore consecutive mouse scrolls for: %s seconds.", id="mouse_scroll_block_time",
        desc="This setting exists to make mouse scrolling less chaotic. \z
            After you scroll the mouse, all scrollwheel inputs are ignored for this many seconds. Default: 0.07 seconds.\z ",
        min=0, max=0.4, dp=2, step=0.01
    }
    adv:new_slider{label="Big number time window: %s seconds.", id="big_number_time",
        desc='This setting dictates how long the mod should wait for you to type in a big number, where "big number" means anything greater than 9. \z
            The timer starts as soon as you type in a number. It will then wait this many seconds for you to finish typing in a number before closing the menu. \z
            This is to allow numbers greater than 9 to be typed in. (.e.g, how long should the mod wait for you to type in "15" to select the 15th item?\n\n\z
            This setting only takes effect if it\'s possible you could be trying to type a multi-digit number. For example, if there are 15 items, \z
            then the mod won\'t wait for a second digit when you type "2".\n\n\z
            Default: 0.4 seconds.\z
        ',
        min=0, max=1.5, dp=2,  step=0.05
    }

    

    adv:add_log_settings()

    ---@param p {label: string, desc: string, config: herbert.QS.config.tab_setting, incl_name: boolean?, parent_comp: herbert.MCM.Setting_Creator}
    ---@return herbert.MCM.Setting_Creator
    local function make_tab_options(p)
        local cat = p.parent_comp:new_category{label=p.label, config=p.config, desc=p.desc}
        cat:new_button{label="Enable?", id="enable", desc="If true, this tab will be visible in quick select menus."}
        if p.incl_name ~= false then
            cat:new_textfield{label="Name", id="name", numeric=false,
                desc="This setting controls the name of the tab in quick select.",
            }
        end
        local color_opts = cat:new_category{label="Color", config=p.config.color,
            desc="These settings let you change the colors of this tab by adjusting the RGB values.\n\n\z
                The three color blocks offer approximations of what this color will look like in different parts of the quick select menu.\n\n\z
                Left block: Tab underline (appears underneath the name of the tab)\n\n\z
                Middle block: Background of items when highlighted (i.e. your mouse is over the block).\n\n\z
                Right block: Background of items when not highlighted.\n\n\z
                Each of these blocks update as soon as you finish moving a slider.\n\n\z
                These blocks are only approximations though, since the background of the MCM affects how the colors are presented.\z
            ",
        }
        
        color_opts.component.postCreate = color_category_post_create
        for i, c in ipairs{"red", "green", "blue"} do
            color_opts:new_pslider{label=c, id=i, dp=1, callback=color_slider_callback}
            -- update the color blocks when the last slider is created
        end
        return cat
    end
    -- =========================================================================
    -- CUSTOM TABS
    -- =========================================================================



    local custom_tabs = MCM:new_sidebar_page{label="Custom Tabs", config=cfg.tabs.custom,
        desc="\"Custom tabs\" work simiilar to the quick keys system: pick the items yourself and easily access them later.\n\n\z
            \z
            You're allowed to have up to 10 custom tabs. You can name them and color code them however you like. Custom tabs can be a nice way to organize the quick select menu. \z
            For example, with dedicated \"Spells\", \"Weapons\", \"Armor\"  (etc.) tabs.\n\n\z
            \z
            By default, you're given two custom tabs: a \"Favorites\" tab and a \"More Favorites\" tab. \z
            But nothing is special about those names, feel free to change them as you wish.\n\n\z
            \z
            To edit the items inside a custom tab, hold down ALT while pressing the quick select key.\z
        "
    }
    

    for i=1, #cfg.tabs.custom do
        make_tab_options{label="Custom tab " .. i, config=cfg.tabs.custom[i],  parent_comp=custom_tabs,
            desc="Custom tabs work similar to the quick keys system: pick the items yourself and easily access them later.\n\n\z
                You can have up to 10 custom tabs, but you're only given 2 by default. You can change their names and colors as you see fit.\z
            "
        }
    end


    local auto_tabs = MCM:new_sidebar_page{label="Autogenerated Tabs", config=cfg.tabs,
        desc="This page lets you toggle which autogenerated tabs appear, as well as change their colors.\n\n\z
            An autogenerated tab is one in which the contents are generated automatically, based on your character's statistics and inventory.\n\n\z
            For example, the \"Tools\" tab lets you quickly access the different tools you have at your disposal, without needing to manually swap out tools when the old ones break.\z
        "
    }

    do -- tools tab    
        local tools_cat = make_tab_options{label="Tools tab", config=cfg.tabs.auto_gen.tools, incl_name=false, parent_comp=auto_tabs,
            desc='The "tools" tab will list some of the tools in your inventory. This includes:\n\n\z
            \z
            1) Your best mortar and pestle\n\n\z
            2) A few of your lockpicks, starting with the best and ending with the worst.\n\n\z
            3) Your best probe and your worst probe.\n\n\z
            4) A few of your repair tools, starting with the best and ending with the worst.\n\n\z
            5) A collection of your best/worst lights.\n\n\z
            \z
            If there\'s room at the end, a few "tool-like" spells will also be included, such as "open" and "telekensis".\n\n\z
            \z
            The contents of this menu are generated automatically each time it\'s opened.\z
        '
        }
        local max_to_show = cfg.tabs.auto_gen.tools.max_to_show
        local OT = tes3.objectType
        for _, tool_type in ipairs(require("herbert100.quick select.common").tools) do
            ---@type string
            local name = tool_type == OT.apparatus and "mortar and pestle" or table.find(OT, tool_type)     
                or "????"

            name = name:gsub("(%u)", function(s) return " " .. s:lower() end)

            tools_cat:new_slider{label=fmt("Maximum number of %ss to show", name), 
                id=tool_type, config=max_to_show, 
                min=0,
                max=tool_type == tes3.objectType.alchemy and 3 or 10,
                desc=fmt("Controls the maximum number of %ss that can show up in the Tools tab.\n\n\z
                    If set to 0, no tools of this type will be shown.\n\n\z
                    If set to 1, only the best tool will be shown.\n\n\z
                    If set to something bigger than 1, then you'll get a cross section of your inventory. i.e., \z
                        if set to 2, you'll see the best and worst options. If set to 3, you'll see the best option, \z
                        the middle option, and the worst option. \z
                        And so on.", 
                    name
                ),
            }
            
        end
        tools_cat:new_button{label="Include utility spells?", id="include_spells",
            desc='If enabled, then some "utility spells" will be included at the end of the tools tab, if there\'s room.\n\n\z
                "Utility" spells include things like "open", "telekinesis", "water walking", "water breathing", and "charm".',
        }
        tools_cat:new_button{label='Include equipped "on use" enchanted items?', id="include_on_use",
            desc='If enabled, then equipped "on use" enchanted items (e.g. Fargoth\'s ring) will be shown in the Tools tab, \z
                if there\'s room. Selecting an "on use" item from the Quick Select menu will equip the spell.\z
            ',
        }
    end

    -- tools_cat:new_slider{label="Maximum number of probes to show", id="max_probes", max=10}
    -- tools_cat:new_slider{label="Maximum number of repair tools to show", id="max_repair_tools", max=10}
    -- tools_cat:new_slider{label="Maximum number of lights to show", id="max_lights", max=10}
    make_tab_options{label="Soul gems tab", config=cfg.tabs.auto_gen.soul_gems, incl_name=false,  parent_comp=auto_tabs,
        desc='The "soul gems" tab will list all of your filled soul gems, allowing you to easily enchant/recharge items.\n\n\z
        \z
        The contents of this menu are generated automatically each time it\'s opened.\z
    '}
    make_tab_options{label='Recent items tab', config=cfg.tabs.auto_gen.recent, incl_name=false, parent_comp=auto_tabs,
        desc='The "recent items" tab will keep a list of all your recently used weapons/spells.\n\n\z
        \z
        The contents of this menu are generated automatically each time it\'s opened.\z
    '
    }
    -- make_tab_options{label='On Use enchantments tab', config=cfg.tabs.auto_gen.on_use, incl_name=false, parent_comp=auto_tabs,
    --     desc='This will display a list of all magic effects that come from on use enchantments you have equipped.\n\n\z
    --     \z
    --     The contents of this menu are generated automatically each time it\'s opened.\z
    -- '
    -- }

    


end)
