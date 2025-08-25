
local log = mwse.Logger.new{abbreviateHeader = true}
include("herbert100.livecoding.livecoding")

local common = require("herbert100.more quickloot.common") ---@type herbert.MQL.common


-- run the actual mod
-- this is stored in a separate file to make livecoding easier.
require("herbert100.more quickloot.mod")


local mod_name = "More QuickLoot"

local cfg = require("herbert100.more quickloot.config")

local default_config = require("herbert100.more quickloot.config.default")
local defns = require("herbert100.more quickloot.defns")

-- make the MCM
event.register("modConfigReady", function()
    -- these tables are used by multiple settings, so they're defined up here
    local mi_options = {
        {label = "1) Always take 1.", value = defns.mi.one },
        {label = "2) Always take Stack.", value = defns.mi.stack },
        {label = "3) Decide by gold/weight ratio.", value = defns.mi.ratio },
    }

    local function mousekey_callback(self)
        if self.variable.value.mouseWheel then
            tes3.messageBox("[%s] Error: You can't bind this to the mousewheel.", mod_name)
            table.copy(self.variable.defaultSetting, self.variable.value)
        end
    end
    local template = mwse.mcm.createTemplate{
		label = mod_name,
        config = cfg,
        defaultConfig = default_config,
        showDefaultSetting = true,
        onClose = function()
			local FORMAT_OPTIONS = {
				indent=true,
					keyorder = { "version",
						"take_nearby_dist", "show_scripted", "keys",
						-- pages/big categories
						"UI", "reg", "dead", "inanimate", "organic", "pickpocket", "services", "training", "barter", "blacklist", "advanced", "compat",
						-- important settings/small categories
						"enable", "mi", "xp", "mode", "mode_m", "default_service",
					},
			}
			mwse.saveConfig(mod_name, cfg, FORMAT_OPTIONS)
            event.trigger(defns.EVENT_IDS.config_updated, {})
        end
	}

    template:register()

    ---@param self mwseMCMSlider
    local function DistanceSlider_ConvertToLabelValue(self, variableValue)
        variableValue = variableValue or self.variable.defaultSetting
        local feet = variableValue / 22.1
        local meters = 0.3048 * feet
        return string.format("%.1f ft (%.2f m)", feet, meters)
    end
    -- =========================================================================
    -- MAIN PAGE
    -- =========================================================================
    do
        local main = template:createFilterPage{label="General", description="These settings affect most of the QuickLoot components."}
        main:createDropdown{configKey = "show_scripted", label = "How should QuickLoot handle scripted containers?",
            options = {
                {label = "1) Disable QuickLoot for scripted containers",            value = defns.show_scripted.dont},
                {label = "2) Enable QuickLoot, but prefix container names.",        value = defns.show_scripted.prefix},
                {label = "3) Enable QuickLoot, and don't prefix container names.",  value = defns.show_scripted.no_prefix},
            },
            description = "Many containers have scripts on them that utilize the onActivate function to determine when the \z
                player triggers them. In many cases you will be fine, in some rare cases you will break the script. Activating \z
                a chest manually will trigger the script normally.\n\n\z
                If the \"prefix container names\" option is selected, the string \"(*)\" will be placed infront of scripted containers.\z
                ",
        }
        -- ---------------------------------------------------------------------
        -- TAKE NEARBY SETTINGS
        -- ---------------------------------------------------------------------
        do
            local take_nearby = main:createCategory{label = "Take nearby items",
                description = "When a QuickLoot menu isn't active and you're looking at an ordinary item out in the world, you'll be able to \z
                take all similar nearby items by pressing the \"Take All\" key. These settings control this feature.",
            }
            take_nearby:createSlider{configKey = "take_nearby_dist", label = "Take nearby distance",
                convertToLabelValue=DistanceSlider_ConvertToLabelValue,
                description = "Objects within this distance will be taken when the 'Take all' key is pressed on an object of the same type.\n\n\z
                    Setting it to 0 will disable this feature.\n\n\z
                    The distance is specified using feet/meters.",
            }
            take_nearby:createYesNoButton{configKey="take_nearby_allow_theft", label = "Allow stealing nearby items?",
                description = "If this setting is disabled, you will never steal nearby items.\n\n\z
                    \z
                    If enabled, then you will sometimes steal nearby items. \z
                    Nearby items will only be stolen if they're owned by the same person that owns the item you're currently looking at.\z
                ",
            }
        end
        -- ---------------------------------------------------------------------
        -- KEYBIND SETTINGS
        -- ---------------------------------------------------------------------
        do
            local keys = main:createCategory{configKey = "keys", label = "Keybindings"}
            keys:createYesNoButton{configKey = "use_activate_btn", label = "Loot with activate key",
                description = 'If enabled, you will loot items with the "Activate" key and open containers with the "Custom" key.\n\n\z
                    If disabled, you will loot containers with the "Custom" key and open them with the "Activate" key.',
            }
            keys:createKeyBinder{configKey = "custom",  label = "Custom key (Take or Open)",
                callback=mousekey_callback, allowCombinations=false, allowMouse=true,
                description = 'The function of this key depends on the previous setting ("Loot with activate key").\n\n\z
                    If that setting is enabled, you will "Take" items with the "Activate" key and "Open" containers with this key.\n\n\z
                    If that setting is disabled, you will "Take" items with this key and "Open" containers with the "Activate" key.',

            }
            keys:createKeyBinder{configKey = "take_all", label = "Take All Items",
                allowCombinations=false, allowMouse=true, callback=mousekey_callback,
                description ='Pressing this key while looking at a container will do one of four things (if possible):\n\n\z
                    \z
                    1) loot all the items if looking at a container\n\n\z
                    \z
                    2) pickpocket all items if pickpocketing someone\n\n\z
                    \z
                    3) harvest all nearby plants if looking at a plant\n\n\z
                    \z
                    4) pick up all nearby items of a similar type if looking at an item (e.g. all nearby alchemy ingredients if looking at an ingredient, all nearby potions if looking at a potion, etc).\z
                ',
            }
            keys:createKeyBinder{configKey = "modifier", label="Modifier Key",
                allowCombinations=false,
                description="The modifier key will alter the behavior of certain keys while held. \n\n\z
                    This is used to modify how many items are taken by the \"Take\" and \"Take All\" keys (see the \"Regular Containers\", \"Pickpocket\" and \"Plant/Organic\" tabs). \z
                    It is also used in Barter menus.\z
                ",
            }

            keys:createKeyBinder{configKey = "undo", label="Undo key",
                allowCombinations=true,
                description="This key will be used to undo taking items from certain types of containers, effectively placing them back in the container you found them. \n\n\z
                    \z
                    NOTE: You can't undo training skills. Also, pressing this key won't \"undo\" any crimes you've commited. (People will still be mad you took it in the first place.)\z
                ",
			}

			keys:createKeyBinder{configKey = "equip_modifier", label="Equip modifier key",
				allowCombinations=true,
				description="If this key is held, taken items will be equipped instead of just added to your inventory. \z
					Your mileage may vary when holding this key and pressing \"Take All\".",
			}




        end
        -- add log settings
        main:createLogLevelOptions{
            configKey = "log_level"
        }
        -- main:createDropdown{
		-- 	label = "Log Level",
		-- 	description = "\z
        --         Change the current logging settings. You can probably ignore this setting. A value of 'PROBLEMS' or 'INFO' is recommended, \n\z
        --         unless you're troubleshooting something. Each setting includes all the log messages of the previous setting. Here is an \z
        --         explanation of the options:\n\n\t\z
        --         \z
        --         NONE: Absolutely nothing will be printed to the log.\n\n\t\z
        --         \z
        --         ERROR: Error messages will be printed to the log.\n\n\t\z
        --         \z
        --         WARN: Warning messages will be printed to the log.\n\n\t\z
        --         \z
        --         INFO: Some basic behavior of the mod will be logged, but nothing extreme.\n\n\t\z
        --         \z
        --         DEBUG: A lot of the inner workings will be logged. You may notice a decrease in performance.\n\n\t\z
        --         \z
        --         TRACE: Even more internal workings will be logged. The log file may be hard to read, unless you have a specific thing you're looking for.\z
        --         \z
        --     ",
		-- 	configKey = "log_level",
		-- 	options = {
        --         {label = "NONE", value = mwse.logLevel.none},
        --         {label = "ERROR", value = mwse.logLevel.error},
        --         {label = "WARN", value = mwse.logLevel.warn},
        --         {label = "INFO", value = mwse.logLevel.info},
        --         {label = "DEBUG", value = mwse.logLevel.debug},
        --         {label = "TRACE", value = mwse.logLevel.trace},
        --     },
		-- 	converter = function(new_value)
        --         log.level = new_value
		-- 		log("updated log level to %s", log:getLevelString())
		-- 		return new_value
		-- 	end
		-- }
    end
    do -- ui page
        local ui = template:createFilterPage{label = "UI", configKey="UI", description="These settings control various aspects of the UI.",}

        -- ---------------------------------------------------------------------
        -- SIZE AND POSITIONING
        -- ---------------------------------------------------------------------
        do
            local size_and_positioning = ui:createCategory{
                label="Size and positioning",
                description="These settings control how many items are displayed in QuickLoot menus, as well as where on the screen the QuickLoot menus should appear.",
            }

            size_and_positioning:createPercentageSlider{configKey = "menu_x_pos", label = "Menu X position",
                description = "Higher values will position the menu closer to the right side of the screen."
            }
            size_and_positioning:createPercentageSlider{configKey = "menu_y_pos", label = "Menu Y position",
                description = "Higher values will position the menu closer to the bottom of the screen."
            }
            size_and_positioning:createSlider{configKey = "max_disp_items", label ="Number of items to display",
                description = "This will control how many items are show in the popup inventory. At most 2 more items than this number will be shown (if the container is large).",
            }

            size_and_positioning:createDropdown{configKey="columns_layout", label = "How to adjust row size in the menu",
                description = "Sometimes, the actual rows of items aren't the widest part of the UI. \z
                    This setting lets you control how the size of the  item rows is calculated in that scenario.\n\n\z
                    \z
                    The options are:\n\z
                    1) Don't autosize, don't center. This means the rows will be left justified, and might not reach the right side of the menu.\n\n\z
                    \z
                    2) Don't autosize, but center. This means the rows will be centered, but might not span the full width of the menu.\n\n\z
                    \z
                    3) Automatically adjust row size. The rows will span the full width of the menu, but this might result in the names of items being a bit further apart from their gold values and weights.\n\n\z
                    \z
                    All of the columns will still be aligned, regardless of which option is chosen.",
                options = {
                    {label = "1) Don't autosize, don't center", value = 1},
                    {label = "2) Don't autosize, but center", value = 2},
                    {label = "3) Automatically adjust row size", value = 3},
                }
            }
        end
        -- ---------------------------------------------------------------------
        -- MISC
        -- ---------------------------------------------------------------------
        do

            local misc = ui:createCategory{label="Miscellaneous Settings",
                description="These settings control various things that are hard to group into other categories. e.g, how items are sorted, whether to display messages, etc.",
            }

            misc:createYesNoButton{configKey="show_tooltips", label = "Show item tooltips?",
                description = 'If enabled, then QuickLoot menus will show tooltips for selected items.\n\n\z
					This setting should be compatible with mods that alter tooltips.\n\n\z
                    \z
                    "Show item tooltips" should be compatible with msot mods that alter tooltips. In order to enable compatibility with "Tooltips Complete", you should disable the "Show Tooltips Only in Menus" setting in the "Tooltips Complete" MCM.',
            }
            misc:createDropdown{configKey="show_tooltips_icon", label = "Show item icon in tooltips?",
                description = 'This setting requires the previous setting to be set to "Show item tooltips".\n\n\z
				The goal of this setting is to make the QuickLoot item tooltips more aligned with the tooltips in the vanilla game.\n\n\z
                    \z
                    The options are:\n\z
                    \t"Show icons at the top": Item icons will be shown above the item.\n\z\z
                    \z
                    \t"Show icons at the bottom.": Item icons will be shown below the item. (This is likely to be more compatible with other mods that alter item tooltips.)\n\z\z
                    \z
                    \t"Don\'t show item icons": Tooltips for item icons will not be shown in the item tooltips.\z
                ',
                ---|0 Do not show an icon
				---|1 Show an icon, but show it below the tooltip (for compatibility)
				---|2 Show an icon above the tooltip.
                options={
                    {label = "Show icons at the top", value = 2},
					{label = "Show icons at the bottom", value = 1},
                    {label = "Don\'t show item icons",     value = 0},
                }
            }
            misc:createYesNoButton{configKey="show_msgbox", label = "Display messagebox on loot",
                description = "Show a default Morrowind messagebox whenever you loot an item.",
            }
            misc:createDropdown{configKey="play_switch_sounds", label = "Sound to play when switching menu modes",
                description = "You can choose which sound plays when switching between looting/storing, between training/bartering, and between buying/selling.\n\n\z
                    \z
                    If \"None\" is selected, then no sounds will be played.",

                options={
                    -- {"Default menu sound", "Fx\\menu_click.wav"},
                    -- {"Page turned", "Fx\\item\\bookpag1.wav"},
                    {label="Default menu sound", value="menu click"},
                    {label="Page turned", value="book page"},
                    {label="None", value=false},
                },
                callback=function(self)
                    local sound = self.variable and self.variable.value
                    log("in %q callback with sound = %q", self.variable and self.variable.id, sound)
                    if sound and sound ~= "menu click" then
                        timer.start{duration=0.1, type=timer.real, callback=function() tes3.playSound{sound=sound} end}
                    end
                end
            }
            misc:createYesNoButton{configKey="show_lucky_msg", label = "Show lucky messages",
                description = "Whenever you're about to fail a check to harvest a plant or pick someones pocket, you have a chance of getting lucky \z
                    (based on your current Luck). If you get lucky, the check will succeed instead of fail.\n\n\z
                    Enabling this setting will allow you to see when you were saved by your Luck.\n\n\z
                    Disabling this setting will still allow you to get lucky, but you won't know when it happens.",
            }
            misc:createDropdown{configKey="sort_items", label="How should items be sorted?",
                description="Should items in QuickLoot containers be sorted? If so, how?\n\n\z
                    Note: If Buying Game is installed and your mercentile skill currently prevents you from knowing item prices, then \z
                    the \"value/weight\" or \"value\" options won't take effect until your mercentile skill improves.    \z
                ",
                options={
                    {label = "Don't sort items",                value = defns.sort_items.dont},
                    {label = "Sort by item value/weight ratio", value = defns.sort_items.value_weight_ratio},
                    {label = "Sort by item value",              value = defns.sort_items.value},
                    {label = "Sort by item weight",             value = defns.sort_items.weight},
                }
            }
            -- misc:createYesNoButton{configKey="sort_by_obj_type", label="Should items also be sorted by object type?",
            --     description="This setting requires a sorting option to be chosen in the previous setting.\n\n\z
            --         If enabled, items of the same object type will be grouped together. \z
            --         For example, all potions will be grouped together, but those will the highest value/weight ratio will appear first.\z
            --     ",
            -- }
            -- misc:createYesNoButton{configKey="update_inv_on_close",   label="Update inventory on menu close?",
            --     description="If your inventory is quite large, you may notice the game slows down a bit when picking up/moving items (both within QuickLoot menus and in normal menus). This happens when the inventory UI updates.\n\z
            --     This option seeks to smooth things out a bit by only updating your inventory when pressing the \"Take All\" key, or when QuickLoot menus are closed.",
            -- }
        end
        -- ---------------------------------------------------------------------
        -- TOGGLE UI VISIBILITY
        -- ---------------------------------------------------------------------
        do
            local toggle = ui:createCategory{configKey = "toggle", label="Enable/disable UI elements",
                description="These settings allow you to toggle the visibility of certain components of the QuickLoot UI.",
            }
            toggle:createYesNoButton{configKey = "show_controls",
                label = "Show controls",
                description = "If enabled, the controls for the active menu will be displayed in the UI.\n\n\z
                    This can be useful since the controls vary based on the active container, and based on the status of that container.\z
                ",
            }
            toggle:createYesNoButton{configKey = "show_modified_controls",
                label="Show additional controls",
                description='The barter menu makes heavy use of the modifier keys. If this setting is enabled, the actions that occur when the modifier keys are held will appear below the normal button prompts.\n\n\z
                    \z
                    For example, the lable (Switch Mode) will appear under the "Take All" key, and (Stack) will appear under the "Take" key. The (Stack) message indicates that the whole stack will be bought.\n\n\z
                    \z
                    Note: This setting requires the "Show controls" setting to also be enabled.\z
                ',
            }

            toggle:createYesNoButton{configKey = "enable_status_bar",
                label="Enable status bar",
                description='The status bar is displayed right above control prompts. \z
                    It displays additional information for certain containers, such as who owns a container, \z
                    or how much gold you have (when in a Services menu).\z
                ',
            }

        end
        -- ---------------------------------------------------------------------
        -- JUST THE TOOLTIP COMPATIBILITY
        -- ---------------------------------------------------------------------
        if cfg.compat.ttip then

            local ttip = ui:createCategory{label='"Just the Tooltip" compatibility settings',
                description='These settings allow this mod to communicate with "Just The Tooltip" about which items have been \"Collected\".\n\n\z
                    \z
                    The "Just the Tooltip" mod is required for these options to work, and these settings only appear when that mod is installed.\z
                ',
            }
                ttip:createTextField{configKey = "ttip_collected_str", label="\"Collected\" prefix",
                    description='Items marked as "Collected" will have their names prefixed by this string.\n\n\z
                        \z
                        For example, if this string is set to "(C)", and you\'ve marked a "Spoon" as "Collected", then any spoons that show up in QuickLoot menus will show up as "(C) Spoon".\n\n\z
                        \z
                    ',
                }
                ttip:createYesNoButton{configKey = "ttip_mark_selected", label='Use the "Collection" key in QuickLoot menus?',
                    description='This setting allows the "Collection Marking" keybind to be used within QuickLoot menus. \z
                        If enabled, then pressing the "Collection Marking" key will mark the currently selected item as "Collected".\n\n\z
                        \z
                        If disabled, then pressing the "Collection Marking" with a QuickLoot menu open will instead mark the container. \z
                    ',
                }
        end

    end
    ---@param self mwseMCMDropdown|mwseMCMSlider
    local function update_outer_slider_vis(self)
        local slider = self.parentComponent.components[3]
        if not slider then return end
        local mi_cfg = self.variable.table
        local vis = false
        for i = 1, 4 do
            if mi_cfg[i] == defns.mi.ratio then
                vis = true
                break
            end
        end
        if slider.elements then
            slider.elements.outerContainer.visible = vis
        end
    end

    ---@param cat mwseMCMCategory
    local function make_mi_options(cat)
        local mi = cat:createCategory{configKey = "mi",
            label="Item Stack Settings",
            description = "These settings are responsible for deciding how the mod should behave when you try to take a stack of items using the \"Take\" or \"Take All\" keys. \z
            For example, when the \"Take\" key is pressed on \"Kwama Eggs (5)\", should we take one egg or five?\n\n\z
            \z
            These are the options, governing what happens each time the \"Take\" or \"Take All\" keys are pressed:\n\n\t\z
                1) Always take 1: you will always take only one.\n\n\t\z
                2) Always take stack: you will always take the whole stack of items. \n\n\t\z
                3) Decide by gold/weight ratio: if the gold/weight ratio is above a specified minimum, take the whole stack. Otherwise, take only one.\n\n\t\z
                \z
                NOTE: If an item's weight is 0 (e.g. \"Gold\"), the whole stack will be taken, regardless of which option is chosen.\z
            "
        }
        for _, take_all in ipairs{false, true} do
            local subcat = mi:createCategory{label = take_all and "Take All" or "Take"}
            for _, modifier_pressed in ipairs{false, true} do
                local subtitle = modifier_pressed and "Modifier Key held" or "Normal"
                subcat:createDropdown{
                    label = string.format("%s: %s", subcat.label, subtitle),
                    options = mi_options,
                    configKey = common.get_mi_index(take_all, modifier_pressed),
                    callback = update_outer_slider_vis,
                    description = 'This setting controls the behavior of the mod when multiple items are in an item stack. \z
                        For example, when the \"Take\" key is pressed on \"Kwama Eggs (5)\", should we take one egg or five?\n\n\z
                    ',
                }

            end
        end
        mi:createSlider{configKey = "min_ratio", label="Minimum Gold/weight ratio",
            description="This setting is only used if \"How to decide?\" is set to option 3.\z
                If the gold/weight ratio of an item is under this amount, then only one item will be taken. \z
                Otherwise, the whole stack will be taken.",
            decimalPlaces = 1,
            postCreate = update_outer_slider_vis,
        }

        mi:createSlider{configKey = "max_total_weight", label="Item stacks: Maximum total weight",
            description="This setting makes sure that whenever taking a stack of items, the total weight of the items taken will be less than this number.\n\n\z
                For example, if this is set to 50 and you try to take 600 arrows (each of which weighs 0.1 pounds), then you'll end up taking 500 arrows instead.\n\n\z
                Set to 0% to disable.",
            max = 150,
        }
        ---@diagnostic disable-next-line: undefined-field
        if mi.config.min_chance ~= nil then
            mi:createPercentageSlider{configKey = "min_chance", label="Item stacks: Minimum chance",
                description="This setting makes sure that whenever taking a stack of items, the minimum chance of taking everything will be above this number.\n\n\z
                For example, let's say you're trying to pickpocket a stack of 30 Kwama eggs, and you have a 95% chance of taking each egg.\n\z
                    Then you have a 21% chance of taking all 30 eggs.\n\z
                    If this setting is set to 50%, then you'll only try to steal 13 out of the 30 Kwama eggs, because you have a 51% chance of taking 13 eggs.\n\n\z
                \z
                Set to 0% to disable.",
            }

        end
        return cat
    end

    -- =========================================================================
    -- REGULAR CONTAINERS (page)
    -- =========================================================================
    do
        local reg = template:createFilterPage{configKey="reg", label = "Regular Containers",
            description="These settings control the behavior of the QuickLoot menu that pops up on 'regular' containers. (e.g. chests, drawers, dead things.)",
        }

		reg:createYesNoButton{configKey = "equip_modifier_take_all_enabled", label="Take All: Allow \"Equip\" modifier",
			description="If this is enabled, the \"Equip\" modifier key can be used when taking all items, rather than only when taking a single item.",
		}

        reg:createSlider{ configKey="sn_dist", label="Pool container contents: within %s",
            description="By default, nearby containers with the same names will have their contents grouped together. Gone are the days of scouring through each individual sack to pick up ingredients.\n\n\z
                This setting lets you specify how close containers have to be in order for their contents to be grouped together.\n\n\z
                Setting this to 0 will disable searching for all nearby containers.\n\n\z
                The distance is specified using feet/meters.",
            min=0, max=22.1*40, step=22.1, decimalPlaces=1, convertToLabelValue=DistanceSlider_ConvertToLabelValue,
        }
        reg:createYesNoButton{ configKey="sn_test_line_of_sight", label="Pool container contents: test line of sight",
            description="If enabled, this mod will check to see if you can see a container before pooling its contents with other containers. \n\n\z
			\z
			This is to prevent things like in containers in different rooms might have their contents combined in the QuickLoot menus.\n\n\z
			\z
			Note: This setting isn't perfect and can end up blocking containers that are partially obscured. \z
			(E.g., if a sack is under a table, then its contents may not be combined with nearby containers.)\z
			",
        }
        reg:createSlider{configKey="take_all_min_ratio", label="Take All: minimum gold/weight ratio",
            description="When the \"Take All\" key is pressed, only items with a gold/weight ratio above this number will be taken. Leave those cups and goblets behind!\n\n\z
                \z
                Setting to 0 will disable this setting.",
            min=0, max=50,decimalPlaces=1, step=0.2, jump=1,
        }

        -- ---------------------------------------------------------------------
        -- MULTIPLE ITEM SETTINGS (category)
        -- ---------------------------------------------------------------------
        make_mi_options(reg)
        -- ---------------------------------------------------------------------
        -- DEAD SETTINGS (category)
        -- ---------------------------------------------------------------------
        do
            local dead = reg:createCategory{label = "Dead creatures/NPCs",
                config = cfg.dead, defaultConfig=default_config.dead,
                description = "These settings govern what happens when looting dead creatures/NPCs",
            }
            dead:createYesNoButton{configKey = "enable", label = "Enable",
                description = "If enabled, a QuickLoot menu will appear when looking at dead creatures/NPCs.",
            }
            dead:createYesNoButton{configKey="dispose", label="Replace \"Take All\" prompt with \"Dispose\" when empty?",
                description="If enabled, you can dispose of empty dead creatures by pressing the Take All button whenever their inventories are empty.",
            }

            dead:createYesNoButton{configKey="sn_pool_by_creature_type", label="Pool contents by creature type?",
                description="If enabled, container contents will only be pooled if their creature types match. \z
					(e.g., humanoids with humanoids and daedra with daedra).\n\n\z
					If disabled, then the items from all nearby dead creatures will be shown in a single QuickLoot menu.",
            }

        end
        -- ---------------------------------------------------------------------
        -- INANIMATE SETTINGS (category)
        -- ---------------------------------------------------------------------
        do
            local inanimate = reg:createCategory{label="Inanimate Containers",
                config = cfg.inanimate, defaultConfig=default_config.inanimate,
                description="These are things like barrels, chests, etc.",
            }
            inanimate:createYesNoButton{configKey="enable", label="Enable",
                description="If enabled, a quickloot menu will be displayed for inanimate containers, such as barrels, chests, sacks, and so on.",
            }

            -- -----------------------------------------------------------------
            -- ANIMATED CONTAINERS
            -- -----------------------------------------------------------------
            if cfg.compat.ac then
                local ac = inanimate:createCategory{configKey="ac",
                    label = "Animated Containers Settings",
                    description = "These let you customize how this mod interacts with Animated Containers.\n\n\z
                        Note: Both \"Morrowind Containers Animated\" and \"Animated Containers Rewritten\" are required to use these settings.",
                }
                ac:createDropdown{configKey="open", label = "When should this mod play open animations?",
                    description = "This setting determines when the container opening animations play.",
                    options={
                        {label = "Never", value = defns.misc.ac.open.never},
                        {label = "After taking an item", value = defns.misc.ac.open.item_taken},
                        {label = "When the menu appears", value = defns.misc.ac.open.on_sight},
                    }
                }
                ac:createDropdown{configKey="close", label = "When should this mod play close animations?",
                    description = "This setting determines when the container closing animations play.",
                    options={
                        {label = "Never play close animations", value = defns.misc.ac.close.never},
                        {label = "Use Animated Containers settings", value = defns.misc.ac.close.use_ac_cfg},
                        {label = "Always play close animations", value = defns.misc.ac.close.always},
                    }
                }
                -- ac:createYesNoButton{configKey="open_empty_on_sight",label = "Open empty containers on sight?",
                -- description = "This setting only takes effect if \"When should this mod play open animations?\" is set to \"When the menu appears\".\n\n\z
                --     If enabled, then the animation will play for empty containers. If disabled, then no animation will play for empty containers."

                -- }
                ac:createYesNoButton{configKey="auto_close_if_empty",label = "Automatically close empty containers?",
                description = "If false, then this mod won't automatically close containers if they're empty.\n\n\z
                    This setting only takes effect if \"When should this mod play close animations?\" is not \"Never\".\n\n\z
                    Note: This mod will check whether an individual container is empty when deciding whether to close it or not. \z
                    If the \"group contents of nearby containers\" feature is enabled, then you may encounter situations where the QuickLoot menu of a container is not empty, \z
                    but the container itself is empty. In those situations, this setting will result in the containers not being closed."

                }
            end

            -- -----------------------------------------------------------------
            -- PLACING ITEMS
            -- -----------------------------------------------------------------
            do
                local placing = inanimate:createCategory{configKey="placing", label = "Placing Items",
                    description="These settings affect the behavior of QuickLoot menus when placing items in containers.",
                }

                placing:createYesNoButton{configKey="reverse_sort", label = "Sort in reverse order?",
                    description = "If enabled, menus will be sorted in reverse order when placing items inside a container.\n\n\z
                        \z
                        For example, if QuickLoot menus are sorted by item weight (i.e. lightest items first), then heaviest items will be displayed first when placing items."
                }
                placing:createYesNoButton{configKey="allow_books", label="Allow books?",
                    description="Should books be included in the \"Placing Items\" menu? This is disabled by default to minimize the chance of placing important quest items inside containers.",
                }
                placing:createYesNoButton{configKey="allow_ingredients", label="Allow ingredients?",
                    description="Should books be included in the \"Placing Items\" menu? This is disabled by default to minimize the chance of placing important quest items inside containers.",
                }
                placing:createSlider{configKey="min_weight", label="Minimum weight",
                    description="When placing items into a container, only items with a weight above this number will be shown.",
                    decimalPlaces=1, max=20
                }
            end
            -- -----------------------------------------------------------------
            -- LOCKED/TRAPPED CONTAINERS
            -- -----------------------------------------------------------------
            do
                local ln = inanimate:createCategory{label = "Locked or Trapped containers",
                    description="These settings affect the behavior of QuickLoot menus on locked/trapped containers.",
                }
                ln:createYesNoButton{configKey="show_locked",label="Peek into locked containers?",
                    description="If this setting is enabled, and if your security skill is high enough, you'll be able to see inside of locked containers.\n\n\z
                        \z
                        This works as follows. Once your security reaches a minimum value (specified by the next setting), you'll be able to see the contents of locked containers if the lock level is below your current security level.\n\n\z
                        \z
                        This works using multiples of 25, so a security level of 25 will let you see any container under level 25, while a security level of 50 will let you see the contents of a container under level 50.\n\n\z
                        If your security is below the minimum value, you won't be able to see inside locked containers.\z
                    ",
                }
                ln:createSlider{configKey="show_locked_min_security", label="Locked containers: minimum security level",
                    description="If this setting is enabled, and if your security skill is high enough, you'll be able to see inside locked containers.\n\n\z
                        \z
                        This works as follows. Once your security reaches a minimum value (specified by this setting), you'll be able to see the contents of locked containers if the lock level is below your current security level.\n\n\z
                        \z
                        This works using multiples of 25, so a security level of 25 will let you see any container under level 25, while a security level of 50 will let you see the contents of a container under level 50.\n\n\z
                        If your security is below the minimum value, you won't be able to see inside locked containers.\z
                    ",
                }
                ln:createYesNoButton{configKey="show_trapped", label = "Peek into trapped containers?",
                    description = "If enabled, the contents of trapped containers will be shown, so long as your security is above a minimum value.\n\n\z
                        If disabled, you won't be able to see the contents of a trapped container until the trap is removed.",
                }
                ln:createSlider{configKey="show_trapped_min_security",label="Trapped containers: minimum security level",
                    description="If the previous setting is enabled, and if your security is above this level, you'll be able to peek inside trapped containers",
                }
            end

        end
    end
    -- =====================================================================
    -- ORGANIC SETTINGS (page)
    -- =====================================================================
    do
        local organic = template:createFilterPage{configKey = "organic", label="Plant/Organic",
            description = "An organic container is any container that respawns. This means that things like guild chests, Fargoth's hiding place, and some TR containers are treated by Morrowind in the same way as plants.\n\z
                This page lets you control how the mod behaves with respect to this type of container.\n\n\z
                The \"Which Organic Containers are not plants?\" setting lets you specify a list of containers that aren't plants. These containers will be treated by the mod as if they were inanimate objects.\n\n\z
                \z
                This means it's possible to disable the \"Organic\" portion of this mod and still have QuickLoot menus show up for things like guild chests.\n\z
                If Graphic Herbalism is installed, it's recommended that you select \"Graphic Herbalism\" for this option; this will consult Graphic Herbalism for its opinions on which containers are plants.\z
            ",
        }
        organic:createYesNoButton{configKey = "enable", label = "Enable",
            description = "If enabled, the QuickLoot menu will show up when looking at plants, and certain other organic containers (as specified by config settings).",
        }
        do -- visual settings
            -- -----------------------------------------------------------------
            -- VISUAL/COMPATIBILITY SETTINGS (category)
            -- -----------------------------------------------------------------
            local visual = organic:createCategory{configKey="visual", label="Visual/Compatibility Settings",
                description = "An organic container is any container that respawns. This means that things like guild chests, Fargoth's hiding place, and some TR containers are treated by Morrowind in the same way as plants.\n\z
                    This page lets you control how the mod behaves with respect to this type of container.\n\n\z
                    The \"Which Organic Containers are not plants?\" setting lets you specify a list of containers that aren't plants. These containers will be treated by the mod as if they were inanimate objects.\n\n\z
                    \z
                    This means it's possible to disable the \"Organic\" portion of this mod and still have QuickLoot menus show up for things like guild chests.\n\z
                    If Graphic Herbalism is installed, it's recommended that you select \"Graphic Herbalism\" for this option; this will consult Graphic Herbalism for its opinions on which containers are plants.\z
                ",
            }
            visual:createDropdown{configKey="change_plants", label="Change plants after looting",
                description="This setting determines what happens to plants once they become empty.\n\z
                    The options are:\n\n\t\z
                        \z
                        1) Don't change plants: plants will not be altered in any way after looting. \n\t\z
                        2) Use Graphic Herbalism: The plants will be altered by Graphic Herbalism. (This option requires Graphic Herbalism to be installed.)\n\t\z
                        3) Destroy Plants: Plants will be destroyed after they've been looted.\z
                    ",
                options={
                    {label = "1) Don't change plants", value = defns.change_plants.none},
                    {label = "2) Use Graphic Herbalism", value = defns.change_plants.gh},
                    {label = "3) Destroy plants", value = defns.change_plants.destroy},
                },
                callback=function (self)
                    if cfg.compat.gh_current < defns.misc.gh.installed then
                        tes3.messageBox("Error: Graphic Herbalism must be installed. Resetting to default value.")
                        self.variable.value = defns.change_plants.none
                    end
                end,
            }

            visual:createDropdown{configKey="not_plants_src", label="Which organic containers are not plants?",
                description="Quite a few organic containers are not plants. This setting helps the mod determine which plants containers shouldn't be treated as plants.\n\n\z
                    \z
                    Instead of using the \"Organic\" QuickLoot menu, the containers specified here will use the \"Inanimate\" QuickLoot menu.\n\z
                    The options are:\n\n\t\z
                        \z
                        1) Treat all organic containers as plants. \n\n\t\z
                        2) Use \"Plants Blacklist\": The \"Plants Blacklist\" page will determine which organic containers are not plants.\n\n\t\z
                        3) Use Graphic Herbalism Blacklist: The current \"Plants Blacklist\" AND the blacklist in the Graphic Herbalism MCM will be used to discern which organic containers are not plants. (Requires GH to be currently installed, or previously installed.) \n\n\t\z
                    \n\n\z
                    If Graphic Herbalism is installed, it is recommened you select \"Use Graphic Herbalism blacklist\". This is because Graphic Herbalism tries to autodetect which containers aren't plants, and updates its blacklist based on your currently installed mods.",
                options={
                    {label = "1) All organic containers are plants", value = defns.not_plants_src.everything_plant},
                    {label = "2) Use \"Plants Blacklist\"", value = defns.not_plants_src.plant_list},
                    {label = "3) Use Graphic Herbalism blacklist", value = defns.not_plants_src.gh},
                },
                callback= function (self)
                    -- if graphic herbalism is currently installed, or if graphic herbalism has never been installed
                    if cfg.compat.gh_current < defns.misc.gh.previously then
                        tes3.messageBox("Error: Graphic Herbalism has never been installed. Resetting to default value.")
                        self.variable.value = defns.not_plants_src.plant_list
                    end
                end,
            }
            visual:createYesNoButton{configKey="hide_on_empty", label = "Hide menu when plant is empty",
                description= "If \"Yes\", the QuickLoot menu will be hidden when looking at empty plants.\n\n\z
                    If \"No\", A QuickLoot menu will be shown, indicating that the plant is empty.\n\n\z
                    In either case, it's still possible to harvest nearby plants by pressing the \"Take All\" key.",
            }
        end
        -- -----------------------------------------------------------------
        -- MULTIPLE ITEMS SETTINGS (category)
        -- -----------------------------------------------------------------
        do -- multiple items
            local mi = make_mi_options(organic)
            mi:createPercentageSlider{configKey="min_chance", label="Item stack: Minimum total chance",
                description="This setting is only used if \"How to handle multiple items?\" is set to \"total chance\". \z
                    If the chance of harvesting all items in the stack is under this amount, then only one item will be taken. \z
                    Otherwise, the whole stack will be taken.",
            }
        end
        -- -----------------------------------------------------------------
        -- XP SETTINGS (category)
        -- -----------------------------------------------------------------
        do
            local xp = organic:createCategory{configKey="xp", label = "XP Settings",
                description = "These settings modify when XP is awarded to the player for harvesting plants.\n\n\z
                    All XP settings will only take effect if \"Award XP?\" is enabled.\z
                ",
            }
            xp:createYesNoButton{configKey="award", label="Award XP?",
                description="If enabled, you wil gain a small amount of XP for successfully harvesting a plant. The amount depends on the value of the plant."
            }
            xp:createSlider{configKey="max_lvl", label = "Max level to award XP?",
                description = "If set to 5 or less, you will gain XP at all levels. If set to a number higher than 5, you will only gain XP while below that level."
            }
            xp:createYesNoButton{configKey="on_failure", label = "Award (reduced) XP on failure?",
                description = "If enabled, then when you fail to harvest a plant, you will receive a quarter of the XP you would receive if you were to succeed.\n\n\z
                    i.e., if you would get 1 XP for suceeding, you will get 0.25 XP for failing."
            }
        end

        -- -----------------------------------------------------------------
        -- MISC SETTINGS (category)
        -- -----------------------------------------------------------------
        do
            local misc = organic:createCategory{label="Other Organic Container Settings",
                description = "An organic container is any container that respawns. This means that things like guild chests, Fargoth's hiding place, and some TR containers are treated by Morrowind in the same way as plants.\n\z
                    This page lets you control how the mod behaves with respect to this type of container.\n\n\z
                    The \"Which Organic Containers are not plants?\" setting lets you specify a list of containers that aren't plants. These containers will be treated by the mod as if they were inanimate objects.\n\n\z
                    \z
                    This means it's possible to disable the \"Organic\" portion of this mod and still have QuickLoot menus show up for things like guild chests.\n\z
                    If Graphic Herbalism is installed, it's recommended that you select \"Graphic Herbalism\" for this option; this will consult Graphic Herbalism for its opinions on which containers are plants.\z
                ",
            }

            misc:createDropdown{configKey="sn_cf", label="Which nearby plants should be included?",
                description='This lets you specify which types of nearby plants to include in organic QuickLoot menus. The options are:\n\n\z
                \z
                1) Same plants: Nearby plants will be included only if they\'re the same type of plant as the one you\'re currently looking at.\n\n\z
                \z
                1) All plants: all nearby plants will be shown in organic QuickLoot menus.\z
                ',
                options = {
                    {label = "Same plants", value = 1},
                    {label = "All plants", value = 2},
                }
            }


            misc:createSlider{configKey="sn_dist", label="Group nearby plants distance",
                description="If set to 0, this will disable searching for all nearby plants.\n\n\z
                The distance is specified using feet/meters.",
                convertToLabelValue = DistanceSlider_ConvertToLabelValue, min=0, max=22.1*40, step=22.1, decimalPlaces=1
            }

            misc:createYesNoButton{configKey="show_failure_msg", label="Show message on unsuccessful harvest?",
                description="If enabled, then a message will appear whenever you fail to harvest a plant, as in the base game.",
            }
            misc:createDropdown{configKey="show_chances", label = "Should harvesting chances be shown?",
            description="The \"Decide based on Alchemy level\" option means that chances will be shown if your Alchemy level is above a specified value, \z
                    and chances will not be shown if your Alchemy level is under that value.\z
                    \z
                ",
                options = {
                    {label = "Never show chances", value = defns.ui_show_chances.never},
                    {label = "Decide based on Alchemy level", value = defns.ui_show_chances.lvl},
                    {label = "Always show chances", value = defns.ui_show_chances.always},
                }
            }
            misc:createSlider{configKey="show_chances_lvl",  label = "Show chances: minimum Alchemy level",
                description="This setting only takes effect if the last option is set to \"Decide based on Alchemy level\". \z
                    This setting determines the minimum Alchemy you should have in order to see your chances of successfully taking an item.\z
                ",
            }

            misc:createYesNoButton{configKey="show_chances_100", label = "Show chance even if it's 100%%",
                description="This is purely cosmetic. Should your harvesting chance be shown even if it's 100%%?\n\n\z
                    \z
                    This setting will only take effect if the harvesting chance would otherwise be displayed.\z
                ",
            }


            misc:createPercentageSlider{configKey="chance_mult", label = "Take chance multiplier: ",
                description = "This will multiply the chance you have of successfully taking a plant.",
                max=5,min=0.1,
            }

            misc:createPercentageSlider{configKey="min_chance", label = "Minimum take chance",
                description = "This will determine the minimum chance you have of taking a plant.\n\nDepending on your alchemy skill, the actual chance may be higher than this.",
            }

            misc:createPercentageSlider{configKey="max_chance", label = "Maximum take chance",
                description = "This will determine the maximum chance you have of taking a plant.\n\nDepending on your alchemy skill, the actual chance may be lower than this.",
            }
        end
    end
    -- =============================================================================
    -- PICKPOCKET SETTINGS (page)
    -- =============================================================================
    do
        local pickpocket = template:createFilterPage{configKey = "pickpocket", label="Pickpocket",
                description = "This controls the behavior of QuickLoot menus that appear when pickpocketing.",
        }
        pickpocket:createYesNoButton{ configKey = "enable", label = "Enable",
            description = "If enabled, a QuickLoot menu will appear when you are crouched and looking at an alive NPC.",
        }
        -- -----------------------------------------------------------------
        -- MULTIPLE ITEMS SETTINGS (category)
        -- -----------------------------------------------------------------
        do -- multiple items
            local mi = make_mi_options(pickpocket)
            mi:createPercentageSlider{configKey="min_chance", label="Item stack: Minimum total chance",
                description="This setting is only used if \"How to handle multiple items?\" is set to \"total chance\". \z
                    If the chance of harvesting all items in the stack is under this amount, then only one item will be taken. \z
                    Otherwise, the whole stack will be taken.",
            }
        end
        -- -------------------------------------------------------------
        -- EQUIPPED ITEMS SETTINGS (category)
        -- -------------------------------------------------------------
        do
            local equipped = pickpocket:createCategory{configKey="equipped", label="Equipped item settings",
                description="These settings allow you to control what kinds of equipped items can be pickpocketed.\n\n\z
                    \z
                    If stealing a certain kind of equipped item is not allowed, then it won't show up in the pickpocketing menu.\n\n\z
                    These settings should be functional now. Hopefully it was worth the wait. \z
                ",
            }
            do -- types
                local types = equipped:createCategory{configKey="allowed_type_defns", label="Types of equipped items that can be pickpocketed"}

                types:createYesNoButton{configKey=defns.equipped_types.weapons, label = "Allow stealing equipped weapons?",
                    description = "Should it be possible to steal this type of equipped item?"
                }
                types:createYesNoButton{configKey=defns.equipped_types.armor, label = "Allow stealing equipped armor?",
                    description = "Should it be possible to steal this type of equipped item?"
                }
                types:createYesNoButton{configKey=defns.equipped_types.clothing, label = "Allow stealing equipped clothing?",
                    description = "Should it be possible to steal this type of equipped item?"
                }
                types:createYesNoButton{configKey=defns.equipped_types.jewelry, label = "Allow stealing equipped jewelry?",
                    description = "Should it be possible to steal this type of equipped item?"
                }
                types:createYesNoButton{configKey=defns.equipped_types.accessories, label = "Allow pickpocketing equipped gloves/belts?",
                    description = "Should it be possible to steal this type of equipped item?"
                }
            end

            equipped:createYesNoButton{configKey="show_unavailable", label = "Show unlootable equipped items?",
                description="This setting only affects equipped items that can't be pickpocketed. (For example, if you allow pickpocketing equipped weapons, then this setting won't affect weapons.)\n\n\z
                    If enabled, then equipped items will be greyed out, but still shown. If disabled, equipped items will not be shown at all. \z
                ",
            }
        end
        -- -----------------------------------------------------------------
        -- MISC SETTINGS (category)
        -- -----------------------------------------------------------------
        do
            local misc = pickpocket:createCategory{
                label="Other Pickpocket Settings",
                description = "These are settings that don't fit neatly into other categories",
            }

            misc:createYesNoButton{configKey="show_chances", label = "Should pickpocketing chances be shown?",
                description="The \"Decide based on Security level\" option means that chances will be shown if your security level is above a specified value, \z
                    and chances will not be shown if your Security level is under that value.\n\n\z
                    \z
                    Chances will never be shown if using \"Determinism mode\" (as the chances are always 0 or 100).\z
                ",
            }
            misc:createSlider{configKey="show_chances_lvl", label = "Show chances: minimum Security level",
                description="This setting only takes effect if the last option is set to \"Decide based on Security level\". \z
                This setting determines the minimum Security you should have in order to see your chances of successfully taking an item.\n\n\z
                \z
                Chances will never be shown if using \"Determinism mode\" (as the chances are always 0 or 100).\z",
            }

            misc:createYesNoButton{configKey="show_chances_100", label = "Show chance even if it's 100%%",
                description="This is purely cosmetic. Should your pickpocketing chance be shown even if it's 100%%?\n\n\z
                \z
                This setting will only take effect if the pickpocketing chance would otherwise be displayed.\n\n\z
                \z
                Chances will never be shown if using \"Determinism mode\" (as the chances are always 0 or 100).\z",
            }

            misc:createYesNoButton{configKey="determinism", label = "Enable Determinism mode?",
                description = "This setting is inspired by mort's Pickpocket mod and the \"Magicka of the Third Era\" mod. It works as follows:\n\n\z
                    Your chances of pickpocketing an item will always be 0 or 100.\n\n\z
                    If your chance of pickpocketing an item would be above 70%% (using the mod's normal calculations), then your chance will instead be 100%%.\n\n\z
                    If your chance of pickpocketing an item would be below 70%% (using the mod's normal calculations), then your chance will instead be 0%%.\n\n\z
                    \z
                    The next setting will allow you to chance the cutoff point from 70%% (the default) to some other number."
            }
            misc:createPercentageSlider{configKey="determinism_cutoff", label = "Determinism cuttoff percentage",
                description = "This setting only takes effect if \"Determinism mode\" is enabled.\n\n\z
                    If your chances of pickpocketing an item would be above this number (using the mods normal calculations), then your chance will instead be 100%%.\n\n\z
                    If your chances of pickpocketing an item would be below this number (using the mods normal calculations), then your chance will instead be 0%%.\n\n\z
                    \z
                ",
                min = 0.5,
            }


            misc:createYesNoButton{configKey="show_detection_status", label = "Show detection status",
                description = "If enabled, the QuickLoot menu will show whether the person you're pickpocketing has detected you.",
            }

            misc:createPercentageSlider{configKey="chance_mult", label = "Take chance multiplier",
                description = "This will multiply the chance you have of successfully stealing something.",
                decimalPlaces=1,max=5, min=0.1,
            }
            misc:createPercentageSlider{configKey="min_chance", label = "Minimum take chance",
                description = "This will determine the minimum chance you have of stealing something.\n\nDepending on your skill level, the actual chance may be higher than this.",
            }
            misc:createPercentageSlider{configKey="max_chance", label = "Maximum take chance",
                description = "This will determine the maximum chance you have of stealing something.\n\nDepending on your skill level, the actual chance may be lower than this.",
            }

            misc:createPercentageSlider{configKey="detection_mult", label = "Detection modifier",
                description = "Your chance to steal something will be multiplied by this number if you are detected.",
                decimalPlaces=1,max=5,min=0.1,
            }

            misc:createYesNoButton{configKey="trigger_crime_undetected", label = "Trigger a crime when undetected?",
                description = "If true, a crime will be triggered after you successfully pickpocket someone, even if the person you're pickpocketing didn't detect you.\z
                This means that you could still be caught by another witness who sees the theft. If no one saw the crime, then you will not be caught.\n\n\z
                If false, then no crime will be reported after a successful pickpocket, so long as the person you're stealing from isn't detecting you.",
            }
        end
    end

    -- =====================================================================
    -- SERVICES (page)
    -- =====================================================================
    do
        -- local services = template:createFilterPage{configKey="services",
        --     label="Services",
        --     description = "This controls the behavior of Services menus. (currently Barter and Training menus.)",
        -- }

            -- enable = {
            --     label = "Enable services menus",
            --     description="This setting is required for barter and training menus to appear."
            -- },
            -- allow_skooma = {
            --     label = "Allow services when you have Skooma?",
            --     description='If true, you\'ll be able to train even if you have Skooma and the trainer doesn\'t like that.\n\n\z
            --     \z
            --     Credit to Necrolesian for their "Hide The Skooma" mod, which this setting is based off of.\n\n\z
            --     \z
            --     Note: This setting only takes effect when checking to create a QuickLoot menu. You will still need the "Hide The Skooma" mod \z
            --     for that functionality within dialogue menus.',
            -- },
            -- default_service = {
            --     label="Preferred Service",
            --     description='This lets you set the service you\'d like to start in. This only applies to NPCs that offer multiple services.\n\n\z
            --         If an NPC does not offer the specified service, then the next valid service will be selected.\z
            --     ',
            -- },
    end
    -- =========================================================================
    -- TRAINING (page)
    -- =========================================================================
    do
        local training = template:createFilterPage{configKey="training", label="Training ",
            description="These menus appear when looking at trainers.",
        }
        training:createYesNoButton{configKey="enable", label = "Enable training menus",
            description="Should QuickLoot menus appear when looking at trainers?"
        }
        training:createYesNoButton{configKey="max_lvl_is_weight", label = "Display maximum training level?",
            description="This setting is a bit awkward at the moment. If enabled, the training menu will show the maximum level a trainer can train a skill to.\z
                However, this will be shown in the \"item weight\" section, underneath an anvil. Not my best piece of UI work.\z
                If anyone knows a better icon to use for this, please let me know.\z
            ",
        }

    end

    -- =========================================================================
    -- BARTER (page)
    -- =========================================================================
    do
        local barter = template:createFilterPage{configKey="barter", label = "Barter",
            showReset = true,
            description='These settings control the behavior of the QuickLoot menu that appears when bartering.\n\n\z
                \z
                There are two modes: buying and selling. You can switch between them by holding the modifier key and pressing the "Take All" button.\n\n\z
                \z
                Note: Whenever an item is bought/sold, it is "put in a basket". You must press the "Take All" key to confirm the transaction and finish buying/selling.\n\n\z
                \z
                If you want to undo buying/selling an item, you can hold the modifier key and press the "Open" key.\n\n\z
                \z
                \tBuying: This menu will show all items the merchant is currently selling. Items will be sorted so that items with higher gold/weight ratios appear earlier in the list.\n\n\z
                \z
                \tSelling: This menu will show all the items the merchant can buy from you. Items will be sorted so that those with lower gold/weight ratios appear earlier in the list.\n\n\z
                \z
                Note: When selling, only the items the merchant can afford will be shown. For example, if a merchant has 400 gold, items worth more than 400 gold won\'t be shown.\z
            ',
        }

        barter:createYesNoButton{configKey="enable", label = "Enable",
            description = "If enabled, the QuickLoot menu will show up when looking at NPCs that can barter.",
        }
        barter:createYesNoButton{configKey="start_buying", label="Default to \"Buy\" menu or \"Sell\" menu?",
            description='This lets you decide whether the "Buy" menu or the "Sell" menu should appear when you first look at an NPC.\n\n\z
                You can still switch between "Buy" and "Sell" mode by holding the modifier key and pressing "Take All"\z
            ',
        }
        barter:createYesNoButton{configKey="show_cart_gold_value", label="Show gold value of items in cart",
            description="If enabled, the total gold value of all items in cart will be shown.\n\n\z
                Note that the displayed gold values of the buyer and seller are already updated to show what they \z
                will be after the transaction is finalized."
        }
        -- barter:createYesNoButton{configKey="switch_if_empty", label="Switch default menu if empty?",
        --     description='If the preferred barter menu (specified by previous setting) is empty, should we switch menus?\n\n\z
        --         This setting only takes effect the first time the barter menu is opened (which can also happen when switching services).',
        -- }
        barter:createYesNoButton{configKey="award_xp", label = "Award XP?",
            description = "If enabled, XP is rewarded for successfully bartering using QuickLoot menus.\n\n Requires the \"Barter XP Overhaul\" mod.",
        }
        barter:createYesNoButton{configKey="automate_disposition_minmaxing", label = "Automate Disposition Minmaxing",
            description = "In the base game, your disposition increases by 1 point for each transaction performed.\z
				This means that if you want to minmax your disposition with a merchant, it's better to buy/sell a single item at a time.\n\z
				\n\z
				If this setting is enabled, your disposition will increase by 1 point per item bought/sold. \z
				In other words, there will no longer be any benefit to buying/selling one item at a time.\z
				",
        }
        do -- selling settings
            local selling = barter:createCategory{configKey="selling", label = "Selling Items",
                description = "These settings control which items are shown when selling items, as well as how the inventory in sorted when selling items.\n\n\z
                    \z
                    You can use these settings to cut down on which items get shown, helping to minimize the amount of scrolling you have to do.\z
                ",
            }
            selling:createYesNoButton{configKey="reverse_sort", label = "Sort in reverse order when selling?",
                description = "If enabled, menus will be sorted in reverse order when selling.\n\n\z
                    \z
                    For example, if QuickLoot menus are sorted by item weight (i.e. lightest items first), then heaviest items will be displayed first when selling."
            }
            selling:createYesNoButton{configKey="allow_books", label = "Allow selling books?",
                description = "This may help declutter the barter menu when you're selling things.",
            }
            selling:createYesNoButton{configKey="allow_ingredients", label = "Allow selling ingredients?",
                description = "This may help declutter the barter menu when you're selling things.",
            }
			selling:createSlider{configKey="min_weight", label="Minimum weight",
                    description="When selling, only items with a weight above this number will be shown.",
                    decimalPlaces=1, max=20
                }
        end
        -- -------------------------------------------------------------
        -- EQUIPPED ITEM SETTINGS (subcategory)
        -- -------------------------------------------------------------
        do
            local equipped = barter:createCategory{configKey="equipped", label="Equipped item settings",
                description="These options were pretty easy to implement after adding them to the \"Pickpocket\" menu so I thought why not? \z
                    Maybe your character is really persuasive or something.\n\n\z
                    NOTE: These settings are a double-edged sword. You can buy items that NPCs have equipped, but NPCs can also buy items you have equipped.\z
                ",
            }
            do -- types
                local types = equipped:createCategory{configKey="allowed_type_defns", label="Types of equipped items that can be bartered"}

                types:createYesNoButton{configKey=defns.equipped_types.weapons, label = "Allow bartering equipped weapons?",
                    description = "Should it be possible to barter this type of equipped item?"
                }
                types:createYesNoButton{configKey=defns.equipped_types.armor, label = "Allow bartering equipped armor?",
                    description = "Should it be possible to barter this type of equipped item?"
                }
                types:createYesNoButton{configKey=defns.equipped_types.clothing, label = "Allow bartering equipped clothing?",
                    description = "Should it be possible to barter this type of equipped item?"
                }
                types:createYesNoButton{configKey=defns.equipped_types.jewelry, label = "Allow bartering equipped jewelry?",
                    description = "Should it be possible to barter this type of equipped item?"
                }
                types:createYesNoButton{configKey=defns.equipped_types.accessories, label = "Allow bartering equipped gloves/belts?",
                    description = "Should it be possible to barter this type of equipped item?"
                }
            end

            equipped:createYesNoButton{configKey="show_unavailable", label = "Show unbarterable equipped items?",
                description="This setting only affects equipped items that can't be bartered. (For example, if you allow bartering equipped weapons, then this setting won't affect weapons.)\n\n\z
                    If enabled, then equipped items will be greyed out, but still shown. If disabled, equipped items will not be shown at all. \z
                ",
            }
        end
    end


    -- take from the original QuickLoot mod, and very slightly altered
    local function get_containers()
        local added = {}
        for obj in tes3.iterateObjects(tes3.objectType.container) do
            ---@diagnostic disable-next-line: undefined-field
            if obj.script ~= nil then
                added[obj.id:lower()] = true
            end
        end
        return table.keys(added, function(a, b) return a:lower() < b:lower() end)
    end

    -- =====================================================================
    -- BLACKLIST (filter page)
    -- =====================================================================
    template:createExclusionsPage{ label = "Blacklist",
        description = "All QuickLoot components will be disabled for any of the containers included in this blacklist.",
        leftListLabel = "Blacklist", rightListLabel = "Containers",
        filters = {{label="Containers", callback = get_containers}},
        variable = mwse.mcm.createTableVariable{
            id = "containers",
            table = cfg.blacklist,
            defaultSetting = default_config.blacklist.containers
        },
        showReset = true,
    }
    -- bl2page:createExclusionsList{
    --     filters = {{label="Containers", callback = get_containers}},
    --     variable = mwse.mcm.createTableVariable{
    --         id = "containers",
    --         table = cfg.blacklist,
    --         defaultSetting = default.blacklist.containers
    --     },
    --     -- showReset = true,
    -- }
    -- =====================================================================
    -- PLANTS BLACKLIST (filter page)
    -- =====================================================================
    template:createExclusionsPage{ label = "Plants Blacklist",
        description = "This is a list of containers that shouldn't be treated as plants. Things in this blacklist won't be destroyed by the \"Destroy Plants\" Setting. \z
            Also, if \"Which organic containers aren't plants\" is set to \"Plants Blacklist\", then the containers in this list won't be treated as plants by QuickLoot. Those containers will instead use the \"Inanimate\" QuickLoot menu.\n\n\z
        ",
        leftListLabel = "Blacklist", rightListLabel = "Containers",
        filters = {{label="Containers", callback = get_containers}},
        variable = mwse.mcm.createTableVariable{
            id="organic",
            table = cfg.blacklist,
            defaultSetting = default_config.blacklist.organic
        },
        showReset = true,

    }

    -- =========================================================================
    -- ADVANCED SETTINGS (page)
    -- =========================================================================
    do -- advanced
        local advanced = template:createFilterPage{configKey="advanced", label = "Advanced Settings",
            description="More advanced/niche settings are placed here.\n\n\z
                WARNING: it is very easy to break this mod by messing with the compatibility settings below. If you do end up breaking it, you can fix the mod by clicking the  \"Reset to default\" button.",
        }
        advanced:createYesNoButton{configKey="v_dist", label="Search nearby containers: vertical distance",
            description="The \"Search nearby containers\" feature (used by regular containers and organic containers) uses a \"cylindric\" metric when computing distance.\n\n\z
                Basically, we make a cylinder a big cylinder around the container we're looking at, and then see which other containers lie inside that cylinder.\n\n\z
                The \"distance\" settings in the other pages specify the \"radius\" of the cylinder, while this setting specifies the \"height\" of the cylinder.\n\n\z
                We use a cylindric metric for two reasons:\n\z
                \t1) it minimizes the chances of taking items on different floors when indoors (in theory anyway)\n\z
                \t2) it plays more nicely with shelves and such.\z
            ",
        }
        -- ---------------------------------------------------------------------
        -- EVENT PRIORITIES
        -- ---------------------------------------------------------------------
        do
            local compat = advanced:createCategory{configKey='compat', label = "Advanced Settings",

                description="These settings can be safely ignored by most people using the mod. They exist in the hopes of offering easy solutions to some compatibility conflicts.\n\n\z
                    Pretty much all of these settings require a restart to take effect, since I'm expecting them to be used very rarely.\n\n\z
                    WARNING: It's highly recommended you don't change these settings unless you know what you're doing. Certain configurations of these settings can break the mod. If this happens, click the \"Reset to default\" button and everything should be fixed after the game is restarted.\z
                ",
            }


            compat:createTextField{configKey="sw_claim", label="Scrollwheel: claim events when menu active",
                numbersOnly=true, converter=tonumber,
                description='If true, then any mods with lower priority scrollwheel events WILL NOT react to the scrollwheel being used while a QuickLoot menu is open.\n\n\z
                    \z
                    If false, then any mods with lower priority scrollwheel events WILL react to the scrollwheel being used while a QuickLoot menu is open.\n\n\z
                    \z
                    Note: This settings only matters while a QuickLoot menu is active. If no QuickLoot menu is active, then other mods will function normally regardless of what this is set to.\z
                ',
            }
            compat:createTextField{configKey="sw_priority", label="Scrollwheel: event priority",
                numbersOnly=true, converter=tonumber,

                description='This setting determines the priority of the event that fires whenever your mouse is scrolled. Things with higher numbers happen earlier.\n\n\z
                    \z
                    If you\'re trying to make this mod react to the mouse being scrolled BEFORE another mod, this value should be HIGHER than the value used by the other mod.\n\n\z
                    \z
                    If you\'re trying to make this mod react to the mouse being scrolled AFTER another mod, this value should be LOWER than the value used by the other mod.\n\n\z
                    \z
                ',
            }
            compat:createTextField{configKey="ak_claim", label="Arrow keys: claim events when menu active",
                numbersOnly=true, converter=tonumber,
                description='If true, then any mods with lower priority arrow key events WILL NOT react to the arrow key being used while a QuickLoot menu is open.\n\n\z
                        \z
                        If false, then any mods with lower priority arrow key events WILL react to the arrow key being used while a QuickLoot menu is open.\n\n\z
                        \z
                        Note: This settings only matters while a QuickLoot menu is active. If no QuickLoot menu is active, then other mods will function normally regardless of what this is set to.\z
                    ',
            }
            compat:createTextField{configKey="ak_priority", label="Arrow keys: event priority",
                numbersOnly=true, converter=tonumber,
                description='This setting determines the priority of the event that fires whenever the up/down arrow keys are pressed. Things with higher numbers happen earlier.\n\n\z
                    \z
                    If you\'re trying to make this mod react to arrow keys being pressed BEFORE another mod, this value should be HIGHER than the value used by the other mod.\n\n\z
                    \z
                    If you\'re trying to make this mod react to arrow keys being pressed AFTER another mod, this value should be LOWER than the value used by the other mod.\n\n\z
                    \z
                ',
            }
            compat:createTextField{configKey="keydown_priority", label="keyDown event: priority",
                numbersOnly=true, converter=tonumber,
                description='This setting determines the priority of the event that fires whenever the "Take/Take All/Open" keys are pressed (when bound to something on the keyboard). \z
                Things with higher numbers happen earlier.\n\n\z
                    \z
                    If you\'re trying to make this mod react to this key being pressed BEFORE another mod, this value should be HIGHER than the value used by the other mod.\n\n\z
                    \z
                    If you\'re trying to make this mod react to this key being pressed AFTER another mod, this value should be LOWER than the value used by the other mod.\n\n\z
                    \z
                ',
            }
            compat:createTextField{configKey="mousedown_priority", label="mouseButtonDown event priority: event priority",
                numbersOnly=true, converter=tonumber,
                description='This setting determines the priority of the event that fires whenever the "Take/Take All/Open" keys are pressed (when bound to a mouse button). \z
                    Things with higher numbers happen earlier.\n\n\z
                    \z
                    If you\'re trying to make this mod react to this key being pressed BEFORE another mod, this value should be HIGHER than the value used by the other mod.\n\n\z
                    \z
                    If you\'re trying to make this mod react to this key being pressed AFTER another mod, this value should be LOWER than the value used by the other mod.\n\n\z
                    \z
                ',
            }
            compat:createTextField{configKey="take_all_priority", label="Take All key: event priority",
                numbersOnly=true, converter=tonumber,
                description='This setting determines the priority of the event that fires whenever the "Take All" key is pressed. Things with higher numbers happen earlier.\n\n\z
                    \z
                    If you\'re trying to make this mod react to this key being pressed BEFORE another mod, this value should be HIGHER than the value used by the other mod.\n\n\z
                    \z
                    If you\'re trying to make this mod react to this key being pressed AFTER another mod, this value should be LOWER than the value used by the other mod.\n\n\z
                    \z
                ',
            }
            compat:createTextField{configKey="activate_key_priority", label="Activate key: event priority",
                numbersOnly=true, converter=tonumber,
                description='This setting determines the priority of the event that fires whenever the "Activate" key is pressed. Things with higher numbers happen earlier.\n\n\z
                    \z
                    Note: This is different from the event that fires when you actually activate something, which is what most mods use.',
            }
            compat:createTextField{configKey="activate_event_priority", label="Activate event: event priority",
                numbersOnly=true, converter=tonumber,
                description='This setting determines the priority of the event that fires whenever the "Activate" key is pressed. Things with higher numbers happen earlier.\n\n\z
                    \z
                    This event is responsible for blocking activations when they aren\'t supposed to happen. (e.g., when you loot with the activate key or press the custom key to open a container.)\n\n\z
                    \z
                    Note: no actual looting/decision logic happens in the "activate" event, it all happens when the activate key is pressed.\z
                ',
            }
            compat:createTextField{configKey="menu_entered_priority", label="menuEntered: event priority",
                numbersOnly=true, converter=tonumber,
                description='Whenever a menu is entered, this mod will destroy any active QuickLoot menus. This is to prevent softlocks/crashes.\n\n\z
                    Nothing else is done when a menu is opened. This event is not claimed, blocked, or modified in any way.',
            }
            compat:createTextField{configKey="load_priority", label = "load: event priority",
                numbersOnly=true, converter=tonumber,
                description='Whenever a save is about to be loaded, this mod will destroy any active QuickLoot menus. This is to prevent softlocks/crashes.\n\n\z
                    Nothing else is done when a save is about to loaded. This event is not claimed, blocked, or modified in any way.\n\n\z
                    \z
                    This defaults to a very high value because certain mods need to claim the "load" event in order to function properly.\z
                    This usually happens when a mod is changing what happens during the event (e.g. which save to load). \z
                    It\'s recommended you keep this setting at a high value because this mod is only using the event as an indication that the QuickLoot menu shouldn\'t be open anymore.\z
                ',
            }
            -- compat:createTextField{configKey="simulate_priority",
            --     numbersOnly=true, converter=tonumber,
            --     description='The "simulate" event triggers every frame (for our purposes). This mod is very weary of using the "simulate" event and tries to do so only when absolutely necessary.\n\n\z
            --         \z
            --         Currently, these are the ways "simulate" events are used:\n\z
            --         1) When using training/bartering menus: used to destroy the menu whenever you start sneaking or the NPC dies.\n\z
            --         2) When pickpocketing: used to update pickpocketing chances when your detection status changes, and to destroy the menu whenever you stop sneaking or the NPC dies.\n\z
            --         3) When looking at a living NPC with no training/bartering menus and not sneaking: used to create a pickpocketing event when you start sneaking.\n\n\z
            --         \z
            --         In all cases, the "simulate" event is unregistered as soon as possible. For example, when the Pickpocketing menu gets destroyed, we unregister the "simulate" event and stop checking things every frame.\n\n\z
            --         \z
            --         If certain mods claim and block the "simulate" event, there could be compatibility problems. In that case, it\'s recommended you increase the priority of this event.\z
            --     ',
            -- }
            compat:createTextField{configKey="dialogue_filtered_priority", label="dialogueFiltered: event priority",
                numbersOnly=true, converter=tonumber,
                description='This event triggers when a dialogue event has been selected, or when checking to see if a merchant offers certain services.\n\n\z
                    \z
                    This mod will only utilize this event if an "Allow skooma" option is selected. If either of those settings is selected, this mod will trigger on a dialogue event, and see if we\'re currently trying to create a new QuickLoot menu. \z
                    If we\'re trying to create a new QuickLoot menu, it will filter out Skooma rejections, and block other mods from acting on them.\n\n\z
                    \z
                    It\'s recommended that you set this to at least 1, in order to block the "Hide The Skooma" mod from activating when trying to create a QuickLoot menu.\z
                    This is because "Hide The Skooma" is intended to only fire in dialogue windows, and things can get a bit weird if it fires outside of a dialogue menu.\z
                ',
            }
        end
        advanced:createButton{label="Reset advanced settings to default",
            description='Pressing this button will reset all "Advanced settings" to their default value.\n\n\z
            Other settings will not be affected. i.e., settings on other pages of the MCM will not be changed.\z
            ',
            callback=function ()
                table.copy(default_config.advanced, cfg.advanced)
                tes3.messageBox "Settings reset. You will have to restart the game for these changes to take effect."
            end
        }
    end
end, {doOnce=true})