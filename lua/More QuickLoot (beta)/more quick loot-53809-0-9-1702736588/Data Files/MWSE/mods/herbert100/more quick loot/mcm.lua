-- local EasyMCM = include("easyMCM.EasyMCM")
local defns = require("herbert100.more quick loot.defns")
local log = require("herbert100.Logger")(defns) ---@type Herbert_Logger
local mcm = {
    update = function() end,
}
local config = require("herbert100.more quick loot.config") ---@type MQL.config






function mcm.register()
    local template = mwse.mcm.createTemplate {name = "More QuickLoot"}

    --[[this is called whenever the MCM is closed. it will save the config to a JSON file, and 
        it will also update the calculation variables used by the mod.

        we can't use `saveOnClose` because that's just a wrapper for the `template.onClose` field. 
        in other words, using the `saveOnClose` method will overwrite the current `onClose` function, which will break MCM support.
    ]]
    template.onClose = function()
        -- log:setLogLevel(defns.log_levels[config.log_level])
        -- update the log before doing anything else
        -- this is our own internal bookkeeping
        -- this will be called in `main.lua`, whenever it needs access to updated values from the `config` table.
        mcm.update()

        -- everything was updated, now it's time to save the new settings to the JSON file.
        mwse.saveConfig(defns.mod_name, config)
    end


    do -- main page
        local main_page = template:createSideBarPage{label = "General"}
        main_page.sidebar:createInfo{text = "An updated version of mort's QuickLoot Mod.\n\n\z
        On this page you will find general settings. Settings for specific QuickLoot menus are found on other pages. \z
        There are also two blacklist pages."}

        do -- Sidebar Credits
            local credits = main_page.sidebar:createCategory{label = "Original Mod Credits:"}
            credits:createHyperlink({
                text = "mort - Creator of original mod.",
                url = "https://www.nexusmods.com/morrowind/users/4138441?tab=user+files"
            })
            credits:createHyperlink{
                text = "Svengineer99 - Original mod scripting help",
                url = "https://www.nexusmods.com/morrowind/users/1121630?tab=user+files"
            }
            credits:createHyperlink{
                text = "Greatness7 - Original mod scripting help (and MCM)",
                url = "https://www.nexusmods.com/users/64030?tab=user+files"
            }
            credits:createHyperlink{
                text = "Nullcascade - MWSE",
                url = "https://www.nexusmods.com/morrowind/users/26153919?tab=user+files"
            }
            credits:createHyperlink{
                text = "Hrnchamd - MWSE",
                url = "https://www.nexusmods.com/morrowind/users/843673?tab=user+files"
            }
            credits:createHyperlink{
                text = "PeteTheGoat - Extensive testing of original mod",
                url = "https://www.nexusmods.com/morrowind/users/25319994"
            }
        end
        main_page:createDropdown{
            label = "How should QuickLoot handle scripted containers?",
            description = "Many containers have scripts on them that utilize the onActivate function to determine when the \z
                player triggers them. In many cases you will be fine, in some rare cases you will break the script. Activating \z
                a chest manually will trigger the script normally.\n\n\z
                If the \"prefix container names\" option is selected, the string \"(*)\" will be placed infront of scripted containers.\z
                ",
            variable = mwse.mcm.createTableVariable { id = "show_scripted", table = config },
            options = {
                {label = "1) Disable QuickLoot for scripted containers", value=defns.show_scripted.dont},
                {label = "2) Enable QuickLoot, but prefix container names.", value=defns.show_scripted.prefix},
                {label = "3) Enable QuickLoot, and don't prefix container names.", value=defns.show_scripted.no_prefix},
            }
        }

        main_page:createSlider{ label = "Take all distance",
            description = "Objects within this distance will be taken when the 'Take all' key is pressed on an object of the same type.\n\nSetting it to 0 will disable this feature.",
            min=0, max = 2000,
            step = 50, jump = 100,
            variable = mwse.mcm.createTableVariable{id = "take_all_distance", table = config}
        }
        do -- make general UI settings
            local ui_settings = main_page:createCategory{label="General UI Settings"}

            ui_settings:createDecimalSlider{ label = "Popup inventory X position (higher = right)",
                variable = mwse.mcm.createTableVariable {id = "menu_x_pos", table = config.UI}
            }
            ui_settings:createDecimalSlider{ label = "Popup inventory Y position (higher = down)",
                variable = mwse.mcm.createTableVariable {id = "menu_y_pos", table = config.UI}
            }

            ui_settings:createSlider{ label = "Number of items to display by in popup inventory",
            description = "This will control how many items are show in the popup inventory. At most 2 more items than this number will be shown (if the container is large).",
                min = 4, max = 25, step = 1, jump = 3,
                variable = mwse.mcm.createTableVariable { id = "max_disp_items", table = config.UI }
            }
            
            ui_settings:createYesNoButton{
                label = "Display messagebox on loot",
                description = "Show a default Morrowind messagebox whenever you loot an item.",
                variable = mwse.mcm.createTableVariable { id = "show_msgbox", table = config.UI }
            }
            ui_settings:createYesNoButton{label = "Show lucky messages", 
                description = "Whenever you're about to fail a check to harvest a plant or pick someones pocket, you have a chance of getting lucky \z
                    (based on your current Luck). If you get lucky, the check will succeed instead of fail.\n\n\z
                    Enabling this setting will allow you to see when you were saved by your Luck.\n\n\z
                    Disabling this setting will still allow you to get lucky, but you won't know when it happens.",
                variable = mwse.mcm.createTableVariable{id = "show_lucky_msg", table = config.UI}
            }
            -- ui_settings:createYesNoButton{
            --     label = "Show vanilla container tooltips",
            --     description = "Show the default tooltips shown on containers. \n\n\z
            --     This setting is not yet implemented. Currently the mod functions as if this setting is always enabled.\z
            --     ",
            --     variable = mwse.mcm.createTableVariable {
            --         id = "show_tooltips",
            --         table = config.UI
            --     }
            -- }
            ui_settings:createYesNoButton{
                label = "Show container name",
                description = "If enabled, the name of the active container will be included in the UI, \z
                    along with any container-specific information.\z
                ",
                variable = mwse.mcm.createTableVariable {
                    id = "show_name",
                    table = config.UI
                }
            }
            ui_settings:createYesNoButton{
                label = "Show controls",
                description = "If enabled, the controls for the active menu will be displayed in the UI.\n\n\z
                    This can be useful since the controls vary based on the active container, and based on the status of that container.\z
                ",
                variable = mwse.mcm.createTableVariable {
                    id = "show_controls",
                    table = config.UI
                }
            }
            
        end

        do -- make keybind settings
            local keybinds = main_page:createCategory{label = "Keybindings"}
            local custom_key_setting

            local function update_custom_key_label()
                if custom_key_setting ~= nil then 
                    if config.keys.use_interact_btn then 
                        custom_key_setting.label = "Custom key (loot)"
                    else
                        custom_key_setting.label = "Custom key (open)"
                    end
                end
            end

            keybinds:createYesNoButton{
                label = "Loot with activate key.",
                description = "If enabled, you will loot items with the interact key and open containers with the custom key.\n\n\z
                        If disabled, you will loot containers with the custom key and open them with the interact key.",
                variable = mwse.mcm.createTableVariable { id = "use_interact_btn", table = config.keys },
                callback = update_custom_key_label,
            }
            custom_key_setting = keybinds:createKeyBinder{
                label = "Custom key",
                description = "The function of this key depends on the previous setting ('Loot with activate key').\n\n\z
                    If that setting is enabled, you will loot items with the interact key and open containers with this key.\n\n\z
                    If that setting is disabled, you will loot containers with this key and open containers with the interact key.",
                variable = mwse.mcm.createTableVariable { id = "custom", table = config.keys, 
                    defaultSetting = {keyCode = tes3.scanCode.f, isShiftDown = false, isAltDown = false, isControlDown = false}
                },
                callback = function(self)
                    if self.variable.value.keyCode == tes3.getInputBinding(tes3.keybind.activate).code then
                        tes3.messageBox{ message = "Error: This key cannot be set to the activate key. Resetting to default value." }
                        self.variable.value = self.variable.defaultSetting
                    end
                end
            }
            update_custom_key_label()

            


            keybinds:createKeyBinder{ label = "Take All Items",
            description = [[Pressing this key while looking at a container will do one of four things (if possible):
        1) loot all the items if looking at a container

        2) pickpocket all items if pickpocketing someone

        3) harvest all nearby plants if looking at a plant

        4) pick up all nearby items of a similar type if looking at an item (e.g. all nearby alchemy ingredients if looking at an ingredient, all nearby potions if looking at a potion, etc).]],
                variable = mwse.mcm.createTableVariable { id = "take_all", table = config.keys, }
            }

            keybinds:createKeyBinder{label="Modifier Key",
                description="The modifier key will alter the behavior of certain keys while held. \n\n\z
                    This is used to modify how many items are taken by the \"Take\" and \"Take All\" keys (see the \"Regular Containers\", \"Pickpocket\" and \"Plant/Organic\" tabs). \z
                    More behavior will likely be added in the future.",
                variable=mwse.mcm.createTableVariable{id="modifier",table=config.keys},
                allowCombinations=false
            }

        end
        
        do -- blacklist settings (i couldnt figure out how to put them on the blacklist page)
            local blacklist_settings = main_page:createCategory{label="Blacklist settings.",
                    description="These settings control certain parts of the \"Blacklist\" and \"Plants Blacklist\" pages.\n\n\z
                    I would've liked to put them there, but I didn't know how. Hopefully they will be put there in the future.",
            }
            blacklist_settings:createButton{label="Reset \"Blacklist\" to default",
                description="Currently, the \"default\" is to have nothing blacklisted, so this button basically will only deleted everything in the blacklist.\n\n\z
                The \"Plants Blacklist\" has a few things in it, so you can always reset \"Blacklist\" to default (empty), and then use the other button to add the  \"Plants Blacklist\" settings.",
                buttonText="Reset", 
                callback = function (self)
                    local existing_keys = {}
                    for k, _ in pairs(config.blacklist) do
                        existing_keys[#existing_keys+1] = k
                    end
                    for _, k in pairs(existing_keys) do
                        config.blacklist[k] = nil
                    end
                    local default_config = require("herbert100.more quick loot.config.default")
                    for k, v in pairs(default_config.blacklist) do
                        config.blacklist[k] = v
                    end
                end
            }
            blacklist_settings:createButton{label="Add entries from \"Plants Blacklist\" to \"Blacklist\"", 
                buttonText= "Import",
                callback = function (self)
                    for k,v in pairs(config.organic.plants_blacklist) do
                        if v == true then 
                            config.blacklist[k] = v
                        end
                    end
                end
            }
            blacklist_settings:createButton{label="Reset \"Plants Blacklist\" to default", 
                buttonText="Reset", 
                callback = function (self)
                    local existing_keys = {}
                    for k, _ in pairs(config.organic.plants_blacklist) do
                        existing_keys[#existing_keys+1] = k
                    end
                    for _, k in pairs(existing_keys) do
                        config.organic.plants_blacklist[k] = nil
                    end
                    local default_config = require("herbert100.more quick loot.config.default")
                    for k, v in pairs(default_config.organic.plants_blacklist) do
                        config.organic.plants_blacklist[k] = v
                    end
                end
            }
            blacklist_settings:createButton{label="Add entries from \"Blacklist\" to \"Plants Blacklist\".", 
                buttonText= "Import",
                callback = function (self)
                    for k,v in pairs(config.blacklist) do
                        if v == true then
                            config.organic.plants_blacklist[k] = v
                        end
                    end
                end
            }
        end
        
        log:add_to_MCM(main_page, config)
    end

    do -- regular container settings
        local regular_container_settings = template:createSideBarPage{label = "Regular Containers", 
            description="These settings control the behavior of the quick loot menu that pops up on 'regular' containers. (e.g. chests, drawers, dead things.)"
        }
        do -- settings for deciding when to take multiple items
            local multiple_item_settings = regular_container_settings:createCategory{label="Item Stack filters",
                description = "These settings are responsible for deciding how the mod should behave when you try to take a stack of items using the \"Take\" or \"Take All\" keys. \z
                For example, when the \"Take\" key is pressed on \"Kwama Eggs (5)\", should we take one egg or five?\n\n\z
                \z
                These are the options, governing what happens each time the \"Take\" or \"Take All\" keys are pressed:\n\n\t\z
                    1) Always take 1: you will always take only one.\n\n\t\z
                    2) Always take stack: you will always take the whole stack of items. \n\n\t\z
                    3) Decide by gold/weight ratio: if the gold/weight ratio is above a specified minimum, take the whole stack. Otherwise, take only one.\n\n\t\z
                    4) Decide by total weight: if the total weight is under a specified maximum, take the whole stack. Otherwise, take only one.\n\n\t\z
                    5) Decide by total weight AND gold/weight ratio: if the gold/weight ratio is above a specified minimum, AND the total weight is below a specified maximum, take the whole stack. Otherwise, take only one.\n\n\t\z
                    6) Decide by total weight OR gold/weight ratio: if the gold/weight ratio is above a specified minimum, OR the total weight is below a specified maximum, take the whole stack. Otherwise, take only one.\n\n\z
                    \z
                    NOTE: If an item's weight is 0 (e.g. \"Gold\"), the whole stack will be taken, regardless of which option is chosen.\z
                ",
            }
            multiple_item_settings:createDropdown{label="How to decide",
                -- description = 'This setting controls the behavior of the mod when multiple items are in an item stack while NOT holding the modifier key. \z
                --     For example, when the \"Take\" key is pressed on \"Kwama Eggs (5)\", should we take one egg or five?\n\n\z
                -- ',
                variable=mwse.mcm.createTableVariable{id="multiple_items", table=config},
                options=
                {
                    {label="1) Always take 1.", value=defns.multiple_items.one },
                    {label="2) Always take Stack.", value=defns.multiple_items.stack },
                    {label="3) Decide by gold/weight ratio.", value = defns.multiple_items.ratio },
                    {label="4) Decide by total weight.", value = defns.multiple_items.total_weight },
                    {label="5) Decide by total weight AND gold/weight ratio.", value = defns.multiple_items.ratio_and_total_weight },
                    {label="6) Decide by total weight OR gold/weight ratio.", value = defns.multiple_items.ratio_or_total_weight },
                },
            }
            multiple_item_settings:createDropdown{label="How to decide (when modifier key is held)",
                variable=mwse.mcm.createTableVariable{id="multiple_items_m", table=config},
                options=
                {
                    {label="1) Always take 1.", value=defns.multiple_items.one },
                    {label="2) Always take Stack.", value=defns.multiple_items.stack },
                    {label="3) Decide by gold/weight ratio.", value = defns.multiple_items.ratio },
                    {label="4) Decide by total weight.", value = defns.multiple_items.total_weight },
                    {label="5) Decide by total weight AND gold/weight ratio.", value = defns.multiple_items.ratio_and_total_weight },
                    {label="6) Decide by total weight OR gold/weight ratio.", value = defns.multiple_items.ratio_or_total_weight },
                },
            }
            multiple_item_settings:createYesNoButton{label="Invert behavior for \"Take All\" key?",
                description='If "Yes", then:\n\t\z
                        when NOT HOLDING the modifier key: the "Take All" key will use the option chosen in "How to decide (when modifier key is held)".\n\t\z
                        when HOLDING the modifier key: the "Take All" key will use the option chosen in "How to decide".\n\n\z
                    If "No", then: \n\t\z
                        when NOT HOLDING the modifier key: the "Take All" key will use the option chosen in "How to decide".\n\t\z
                        when HOLDING the modifier key: the "Take All" key will use the option chosen in "How to decide  (when modifier key is held)".\n\n\z\z
                        \"Take All\" key will use the same filter settings as the \"Take Key\". \z
                    \n\n\z
                    \z
                    Enabling this setting allows you to do things like: having the "Take All" key take the whole stack, even if "How to decide" is set to "always take 1". (This would be done by setting the "modifier" key behavior to "always take stack".)\n\n\z
                        By default, this setting is off, so that the "Take All" key uses the same filters as the "Take" key.\n\n\z
                    NOTE: This setting can be changed separately in the "Pickpocket" and "Plant/Organic" settings.\z
                ',
                variable=mwse.mcm.createTableVariable{id="mi_inv_take_all", table=config}
            }
            multiple_item_settings:createDecimalSlider{label="Minimum Gold/weight ratio",
                description="This setting is only used if \"How to decide?\" is set to an option that takes gold/weight ratio into account. (i.e., options 3, 5, or 6.)\z
                    If the gold/weight ratio of an item is under this amount, then only one item will be taken. \z
                    Otherwise, the whole stack will be taken.",
                variable= mwse.mcm.createTableVariable{id="mi_ratio", table=config},
                decimalPlaces=1,
                max=100,
                step=1,
                jump=5,
            }
            multiple_item_settings:createDecimalSlider{label="Maximum total weight",
                description="This setting is only used if \"How to decide?\" is set to an option that takes total weight into account. (i.e., options 4, 5, or 6.).\z
                    If the total weight of all items in a stack exceeds this number, only one item will be taken. \z
                    Otherwise, the whole stack will be taken.",
                variable= mwse.mcm.createTableVariable{id="mi_tweight", table=config},
                decimalPlaces=1,
                step=1, jump=5,
                max=150
            }
        end
        local dead_settings = regular_container_settings:createCategory{label="Dead creatures/NPCs"}
        dead_settings:createYesNoButton({
            label = "Enable",
            description = "If enabled, the quick loot menu will show up when looking at dead creatures/NPCs.",
            variable = mwse.mcm.createTableVariable { id = "enable", table = config.dead }
        })

        dead_settings:createDropdown{label="Dispose of empty creatures",
            description="This setting determines what happens to dead creatures/NPCs once they become empty.\n\z
                The options are:\n\n\t\z
                    \z
                    1) Don't allow QuickLoot to dispose of anything. \n\t\z 
                    2) If a creature is empty, replace the 'Take All' button with a 'Dispose' button.\n\t\z
                    3) Automatically dispose of a dead creature as soon as you look at it.\n\t\z 
                ",
            options={
                {label = "1) Don't do anything", value = defns.dispose.none},
                {label = "2) Use 'Take All' to dispose of empty creatures.", value = defns.dispose.take_all},
                {label = "3) Dispose dead creatures on sight.", value = defns.dispose.on_sight},
            },
            variable=mwse.mcm.createTableVariable{id="dispose", table=config.dead},
        }

        local inanimate_settings = regular_container_settings:createCategory{label="Inanimate Containers",description="These are things like barrels, chests, etc."}
        inanimate_settings:createYesNoButton({
            label = "Enable",
            description = "If enabled, the quick loot menu will show up when looking at barrels, chests, etc.",
            variable = mwse.mcm.createTableVariable { id = "enable", table = config.inanimate }
        })
        inanimate_settings:createYesNoButton{
            label = "Show items inside trapped containers",
            description = "If enabled, the contents of trapped containers will be shown.\n\n\z
                If disabled, you won't be able to see the contents of a trapped container until the trap is removed.",
            variable = mwse.mcm.createTableVariable { id = "show_trapped", table = config.inanimate }
        }
        
    end
    do -- make plant/organic settings 
        local organic_settings = template:createSideBarPage{label="Plant/Organic",
            description = "An organic container is any container that respawns. This means that things like guild chests, Fargoth's hiding place, and some TR containers are treated by Morrowind in the same way as plants.\n\z
                This page lets you control how the mod behaves with respect to this type of container.\n\n\z
                The \"Which Organic Containers are not plants?\" setting lets you specify a list of containers that aren't plants. These containers will be treated by the mod as if they were inanimate objects.\n\n\z
                \z
                This means it's possible to disable the \"Organic\" portion of this mod and still have QuickLoot menus show up for things like guild chests.\n\z
                If Graphic Herbalism is installed, it's recommended that you select \"Graphic Herbalism\" for this option; this will consult Graphic Herbalism for its opinions on which containers are plants.\z
            ",
        }
        organic_settings:createYesNoButton{ label = "Enable quick loot component: ",
            variable = mwse.mcm.createTableVariable { id = "enable", table = config.organic }
        }
        do -- visual and compatibility settings
            local compat_settings = organic_settings:createCategory{label="Visual and Compatibility Settings",
                description = "An organic container is any container that respawns. This means that things like guild chests, Fargoth's hiding place, and some TR containers are treated by Morrowind in the same way as plants.\n\z
                This page lets you control how the mod behaves with respect to this type of container.\n\n\z
                The \"Which Organic Containers are not plants?\" setting lets you specify a list of containers that aren't plants. These containers will be treated by the mod as if they were inanimate objects.\n\n\z
                \z
                This means it's possible to disable the \"Organic\" portion of this mod and still have QuickLoot menus show up for things like guild chests.\n\z
                If Graphic Herbalism is installed, it's recommended that you select \"Graphic Herbalism\" for this option; this will consult Graphic Herbalism for its opinions on which containers are plants.\z
            ",}
            compat_settings:createDropdown{label="Change plants after looting",
                description="This setting determines what happens to plants once they become empty.\n\z
                    The options are:\n\n\t\z
                        \z
                        1) Don't change plants: plants will not be altered in any way after looting. \n\t\z 
                        2) Use Graphic Herbalism: The plants will be altered by Graphic Herbalism. (This option requires Graphic Herbalism to be installed.)\n\t\z
                        3) Destroy Plants: Plants will be destroyed after they've been looted.\z 
                    ",
                options={
                    {label="1) Don't change plants", value = defns.change_plants.none},
                    {label="2) Use Graphic Herbalism", value = defns.change_plants.gh},
                    {label="3) Destroy plants", value = defns.change_plants.destroy},
                },
                variable=mwse.mcm.createTableVariable{id="change_plants", table=config.organic},
                callback= function (self)
                    if config.compat.gh_current < defns.gh_status.currently then
                        tes3.messageBox("Error: Graphic Herbalism must be installed. Resetting to default value.")
                        self.variable.value = defns.change_plants.none
                    end
                end,
            }
            compat_settings:createDropdown{label="Which organic containers are not plants?",
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
                    {label="1) All organic containers are plants", value = defns.not_plants_src.everything_plant},
                    {label="2) Use \"Plants Blacklist\"", value = defns.not_plants_src.plant_list},
                    {label="3) Use Graphic Herbalism blacklist", value = defns.not_plants_src.gh},
                },
                variable=mwse.mcm.createTableVariable{id="not_plants_src", table=config.organic},
                callback= function (self)
                    -- if graphic herbalism is currently installed, or if graphic herbalism has never been installed
                    if config.compat.gh_current < defns.gh_status.previously then
                        tes3.messageBox("Error: Graphic Herbalism has never been installed. Resetting to default value.")
                        self.variable.value = defns.not_plants_src.plant_list
                    end
                end,
            }
            compat_settings:createYesNoButton{ label = "Hide menu when plant is empty",
            description= "If \"Yes\", the QuickLoot menu will be hidden when looking at empty plants.\n\n\z
                If \"No\", A QuickLoot menu will be shown, indicating that the plant is empty.\n\n\z
                In either case, it's still possible to harvest nearby plants by pressing the \"Take All\" key.",
            variable = mwse.mcm.createTableVariable { id = "hide_on_empty", table = config.organic }
            }
        end

        do -- multiple item settings
            local multiple_item_settings = organic_settings:createCategory{label="How to handle object stacks",
                description = "These settings are responsible for deciding how the mod should behave when you try to take a stack of items using the \"Take\" or \"Take All\" keys. \z
                For example, when the \"Take\" key is pressed on \"Kwama Eggs (5)\", should we take one egg or five?\n\n\z
                \z
                These are the options, governing what happens each time the \"Take\" or \"Take All\" keys are pressed:\n\n\t\z
                    1) Always take 1: you will always take only one.\n\n\t\z
                    2) Always take stack: you will always take the whole stack of items. \n\n\t\z
                    3) Decide by total chance: if the chance of taking every item in the stack is above a specified minimum, take the whole stack. Otherwise, take only one.\n\n\t\z
                    4) Decide using settings for Regular containers: Use the option selected in the \"Regular Containers Tab\".\n\n\t\z
                    5) Decide by total chance AND Regular container setting: If the chance of taking every item in the stack is above a certain minimum, use the option selected in the \"Regular Containers Tab\". Otherwise, only take one.\n\n\t\z
                ", 
            }
            multiple_item_settings:createDropdown{label="How to decide?",
                variable=mwse.mcm.createTableVariable{id="multiple_items", table=config.organic},
                options = {
                    {label="1) Always take 1.", value=defns.chance_multiple_items.one },
                    {label="2) always take stack.", value=defns.chance_multiple_items.stack },
                    {label="3) Decide by total chance.", value = defns.chance_multiple_items.total_chance },
                    {label="4) Decide using settings for Regular containers.", value = defns.chance_multiple_items.regular },
                    {label="5) Decide by total chance AND Regular container setting.", value = defns.chance_multiple_items.total_chance_and_regular },
                },
            }
            multiple_item_settings:createDropdown{label="How to decide when the modifier key is held?",
                variable=mwse.mcm.createTableVariable{id="multiple_items_m", table=config.organic},
                options = {
                    {label="1) Always take 1.", value=defns.chance_multiple_items.one },
                    {label="2) always take stack.", value=defns.chance_multiple_items.stack },
                    {label="3) Decide by total chance.", value = defns.chance_multiple_items.total_chance },
                    {label="4) Decide using settings for Regular containers.", value = defns.chance_multiple_items.regular },
                    {label="5) Decide by total chance AND Regular container setting.", value = defns.chance_multiple_items.total_chance_and_regular },
                },
            }
            multiple_item_settings:createYesNoButton{label="Invert behavior for \"Take All\" key?",
                description='If "Yes", then:\n\t\z
                        when NOT HOLDING the modifier key: the "Take All" key will use the option chosen in "How to decide (when modifier key is held)".\n\t\z
                        when HOLDING the modifier key: the "Take All" key will use the option chosen in "How to decide".\n\n\z
                    If "No", then: \n\t\z
                        when NOT HOLDING the modifier key: the "Take All" key will use the option chosen in "How to decide".\n\t\z
                        when HOLDING the modifier key: the "Take All" key will use the option chosen in "How to decide  (when modifier key is held)".\n\n\z\z
                        \"Take All\" key will use the same filter settings as the \"Take Key\". \z
                    \n\n\z
                    \z
                    Enabling this setting allows you to do things like: having the "Take All" key take the whole stack, even if "How to decide" is set to "always take 1". (This would be done by setting the "modifier" key behavior to "always take stack".)\n\n\z
                        By default, this setting is off, so that the "Take All" key uses the same filters as the "Take" key.\n\n\z
                    NOTE: This setting can be changed separately in the "Regular containers" and "Pickpocket" settings.\z
                ',
                variable=mwse.mcm.createTableVariable{id="mi_inv_take_all", table=config.organic}
            }
            multiple_item_settings:createSlider{label="Minimum total chance: %s%%",
                description="This setting is only used if \"How to handle multiple items?\" is set to \"total chance\". \z
                    If the chance of harvesting all items in the stack is under this amount, then only one item will be taken. \z
                    Otherwise, the whole stack will be taken.",
                variable= mwse.mcm.createTableVariable{id="mi_chance", table=config.organic},
            }

        end
        
        do -- misc organic settings
            local other_settings = organic_settings:createCategory{label="Other Organic Container Settings",
                description = "An organic container is any container that respawns. This means that things like guild chests, Fargoth's hiding place, and some TR containers are treated by Morrowind in the same way as plants.\n\z
                This page lets you control how the mod behaves with respect to this type of container.\n\n\z
                The \"Which Organic Containers are not plants?\" setting lets you specify a list of containers that aren't plants. These containers will be treated by the mod as if they were inanimate objects.\n\n\z
                \z
                This means it's possible to disable the \"Organic\" portion of this mod and still have QuickLoot menus show up for things like guild chests.\n\z
                If Graphic Herbalism is installed, it's recommended that you select \"Graphic Herbalism\" for this option; this will consult Graphic Herbalism for its opinions on which containers are plants.\z
            ",}

            other_settings:createSlider{label="Harvest All: Skip items with chance less than: %s%%",
                description="When the \"Harvest All\" key is pressed, you will only attempt to harvest an ingredient if the chance of success \z
                    is greater than the value shown in the slider.\n\n\z
                    Setting this to 0 will result in no items being skipped.",
                variable= mwse.mcm.createTableVariable{id="take_all_min_chance", table=config.organic},
            }

            other_settings:createDecimalSlider{ label = "Take chance multiplier: ",
                description = "This will multiply the chance you have of successfully taking a plant.",
                variable = mwse.mcm.createTableVariable { id = "chance_mult", table = config.organic },
                decimalPlaces=1,max=5,min=0.1
            }

            other_settings:createSlider{ label = "Minimum take chance: %s%%",
                description = "This will determine the minimum chance you have of taking a plant.\n\nDepending on your alchemy skill, the actual chance may be higher than this.",
                variable = mwse.mcm.createTableVariable { id = "min_chance", table = config.organic },
                
            }

            other_settings:createSlider{ label = "Maximum take chance: %s%%",
                description = "This will determine the maximum chance you have of taking a plant.\n\nDepending on your alchemy skill, the actual chance may be lower than this.",
                variable = mwse.mcm.createTableVariable { id = "max_chance", table = config.organic },

            }
        end
    end
    do -- make pickpocket settings 
        local pickpocket_settings = template:createSideBarPage({label="Pickpocket",
            description = "This controls the behavior of the quick loot menu when pickpocketing.",
        })
        pickpocket_settings:createYesNoButton{ label = "Enable quick loot component: ",
            variable = mwse.mcm.createTableVariable { id = "enable", table = config.pickpocket }
        }

        do -- make multiple items settings

            local multiple_item_settings = pickpocket_settings:createCategory{label="How to handle object stacks",
                description = "These settings are responsible for deciding how the mod should behave when you try to take a stack of items using the \"Take\" or \"Take All\" keys. \z
                For example, when the \"Take\" key is pressed on \"Kwama Eggs (5)\", should we take one egg or five?\n\n\z
                \z
                These are the options, governing what happens each time the \"Take\" or \"Take All\" keys are pressed:\n\n\t\z
                    1) Always take 1: you will always take only one.\n\n\t\z
                    2) Always take stack: you will always take the whole stack of items. \n\n\t\z
                    3) Decide by total chance: if the chance of taking every item in the stack is above a specified minimum, take the whole stack. Otherwise, take only one.\n\n\t\z
                    4) Decide using settings for Regular containers: Use the option selected in the \"Regular Containers Tab\".\n\n\t\z
                    5) Decide by total chance AND Regular container setting: If the chance of taking every item in the stack is above a certain minimum, use the option selected in the \"Regular Containers Tab\". Otherwise, only take one.\n\n\t\z
                ", 
            }
            multiple_item_settings:createDropdown{label="How to decide?",
                -- description = 'This setting controls the behavior of the mod when multiple items are in an item stack while NOT holding the modifier key. \z
                --     For example, when the \"Take\" key is pressed on \"Kwama Eggs (5)\", should we take one egg or five?\n\n\z
                -- ',
                variable=mwse.mcm.createTableVariable{id="multiple_items", table=config.pickpocket},
                options = {
                    {label="1) Always take 1.", value=defns.chance_multiple_items.one },
                    {label="2) always take stack.", value=defns.chance_multiple_items.stack },
                    {label="3) Decide by total chance.", value = defns.chance_multiple_items.total_chance },
                    {label="4) Decide using settings for Regular containers.", value = defns.chance_multiple_items.regular },
                    {label="5) Decide by total chance AND Regular container setting.", value = defns.chance_multiple_items.total_chance_and_regular },
                },
            }
            multiple_item_settings:createDropdown{label="How to decide when the modifier key is held?",
                -- description = 'This setting controls the behavior of the mod when multiple items are in an item stack while holding the modifier key. \z
                --     For example, when the \"Take\" key is pressed on \"Kwama Eggs (5)\", should we take one egg or five?\n\n\z
                -- ',
                variable=mwse.mcm.createTableVariable{id="multiple_items_m", table=config.pickpocket},
                options = {
                    {label="1) Always take 1.", value=defns.chance_multiple_items.one },
                    {label="2) always take stack.", value=defns.chance_multiple_items.stack },
                    {label="3) Decide by total chance.", value = defns.chance_multiple_items.total_chance },
                    {label="4) Decide using settings for Regular containers.", value = defns.chance_multiple_items.regular },
                    {label="5) Decide by total chance AND Regular container setting.", value = defns.chance_multiple_items.total_chance_and_regular },
                },
            }
            multiple_item_settings:createSlider{label="Minimum total chance: %s%%",
                description="This setting is only used if \"How to handle multiple items?\" is set to \"total chance\". \z
                    If the chance of stealing all items in the stack is under this amount, then only one item will be taken. \z
                    Otherwise, the whole stack will be taken.",
                variable= mwse.mcm.createTableVariable{id="mi_chance", table=config.pickpocket},
            }
            multiple_item_settings:createYesNoButton{label="Invert behavior for \"Take All\" key?",
                description='If "Yes", then:\n\t\z
                        when NOT HOLDING the modifier key: the "Take All" key will use the option chosen in "How to decide (when modifier key is held)".\n\t\z
                        when HOLDING the modifier key: the "Take All" key will use the option chosen in "How to decide".\n\n\z
                    If "No", then: \n\t\z
                        when NOT HOLDING the modifier key: the "Take All" key will use the option chosen in "How to decide".\n\t\z
                        when HOLDING the modifier key: the "Take All" key will use the option chosen in "How to decide  (when modifier key is held)".\n\n\z\z
                        \"Take All\" key will use the same filter settings as the \"Take Key\". \z
                    \n\n\z
                    \z
                    Enabling this setting allows you to do things like: having the "Take All" key take the whole stack, even if "How to decide" is set to "always take 1". (This would be done by setting the "modifier" key behavior to "always take stack".)\n\n\z
                        By default, this setting is off, so that the "Take All" key uses the same filters as the "Take" key.\n\n\z
                    NOTE: This setting can be changed separately in the "Regular containers" and "Plant/Organic" settings.\z
                ',
                variable=mwse.mcm.createTableVariable{id="mi_inv_take_all", table=config.pickpocket}
            }
        end
        
        do -- other pickpocket settings
            local other_settings = pickpocket_settings:createCategory({label="Other Pickpocket Settings",
                description = "This controls the behavior of the quick loot menu when pickpocketing.",
            })
            other_settings:createSlider{label="Take All: Skip items with chance less than: %s%%",
                description="When the \"Take All\" key is pressed, you will only attempt to pickpocket an item if the chance of success \z
                    is greater than the value shown in the slider.\n\n\z
                    Setting this to 0 will result in no items being skipped.",
                variable= mwse.mcm.createTableVariable{id="take_all_min_chance", table=config.pickpocket},
            }

            other_settings:createYesNoButton{ label = "Show detection status: ",
                description = "If enabled, the QuickLoot menu will show whether the person you're pickpocketing has detected you.",
                variable = mwse.mcm.createTableVariable { id = "show_detection_status", table = config.pickpocket }
            }
            other_settings:createDecimalSlider{ label = "Take chance multiplier: ",
                description = "This will multiply the chance you have of successfully stealing something.",
                variable = mwse.mcm.createTableVariable { id = "chance_mult", table = config.pickpocket },
                decimalPlaces=1,max=5,min=0.1
            }
            other_settings:createSlider{ label = "Minimum take chance: %s%%",
                description = "This will determine the minimum chance you have of stealing something.\n\nDepending on your skill level, the actual chance may be higher than this.",
                variable = mwse.mcm.createTableVariable { id = "min_chance", table = config.pickpocket },
            }
            other_settings:createSlider{ label = "Maximum take chance: %s%%",
                description = "This will determine the maximum chance you have of stealing something.\n\nDepending on your skill level, the actual chance may be lower than this.",
                variable = mwse.mcm.createTableVariable { id = "max_chance", table = config.pickpocket },
            }
            other_settings:createDecimalSlider{ label = "Detection modifier: ",
                description = "Your chance to steal something will be multiplied by this number if you are detected.",
                variable = mwse.mcm.createTableVariable { id = "detection_mult", table = config.pickpocket },
                decimalPlaces=1,max=1,min=0
            }

            other_settings:createYesNoButton{ label = "Trigger a crime when undetected?", 
                description = "If true, a crime will be triggered after you successfully pickpocket someone, even if the person you're pickpocketing didn't detect you.\z
                This means that you could still be caught by another witness who sees the theft. If no one saw the crime, then you will not be caught.\n\n\z
                If false, then no crime will be reported after a successful pickpocket, so long as the person you're stealing from isn't detecting you.",
                variable = mwse.mcm.createTableVariable { id = "allow_equipped_weapons", table = config.pickpocket }
            }
            other_settings:createYesNoButton{ label = "Allow stealing equipped weapons?", description = "Not yet implemented.",
                variable = mwse.mcm.createTableVariable { id = "allow_equipped_weapons", table = config.pickpocket }
            }
            other_settings:createYesNoButton{ label = "Allow stealing equipped armor?", description = "Not yet implemented.",
            variable = mwse.mcm.createTableVariable { id = "allow_equipped_armor", table = config.pickpocket }
            }
        end
    end
    do -- training settings 
        local training_settings = template:createSideBarPage({label="Training",
            description = "This controls the behavior of the mod when looking at a trainer. More options coming soon, hopefully.",
        })
        training_settings:createYesNoButton{ label = "Enable quick loot component: ",
            variable = mwse.mcm.createTableVariable { id = "enable", table = config.training }
        }
    end
    
   
    do -- make blacklists

        -- take from the original QuickLoot mod, and very slightly altered
        local function get_containers()
            local list = {}
            local containers_added = {} ---@type table<string, boolean> this will stop duplicates from showing up (which can happen since we're putting things into lowercase)
            for obj in tes3.iterateObjects(tes3.objectType.container) do
                ---@diagnostic disable-next-line: undefined-field
                local id = (obj.baseObject or obj).id:lower()
                if not containers_added[id] then
                    list[#list+1] = id
                    containers_added[id] = true
                end
            end
            table.sort(list)
            return list
        end

        template:createExclusionsPage{
            label = "Blacklist",
            description = "All quickloot components will be disabled for any of the containers included in this blacklist.",
            leftListLabel = "Blacklist",
            rightListLabel = "Containers",
            variable = mwse.mcm.createTableVariable{ id = "blacklist", table = config, },
            filters = { {label="Containers", callback = get_containers}, },
        }
        
        template:createExclusionsPage{
            label = "Plants Blacklist",
            description = "This is a list of containers that shouldn't be treated as plants. Things in this blacklist won't be destroyed by the \"Destroy Plants\" Setting. \z
                Also, if \"Which organic containers aren't plants\" is set to \"Plants Blacklist\", then the containers in this list won't be treated as plants by QuickLoot. Those containers will instead use the \"Inanimate\" QuickLoot menu.\n\n\z
            ",
            leftListLabel = "blacklist",
            rightListLabel = "Containers",
            variable = mwse.mcm.createTableVariable{ id = "plants_blacklist", table = config.organic, },
            filters = { {label="Containers", callback = get_containers}, },
        }
    end

    template:register()

end
return mcm
