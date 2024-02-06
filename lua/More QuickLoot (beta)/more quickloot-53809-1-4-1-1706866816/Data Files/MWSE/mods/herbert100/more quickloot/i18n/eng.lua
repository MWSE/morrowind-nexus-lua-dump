return {
    -- =========================================================================
    -- STRINGS USED BY MANAGERS
    -- =========================================================================
    looted = {
        -- shown when you press take all and no items are taken
        take_all_no_items_taken = "There is nothing for you to take.",
        take_all_no_items_taken_nonempty = "There is nothing you wish to take.",

        -- ---------------------------------------------------------------------
        -- REGULAR CONTAINERS
        -- ---------------------------------------------------------------------
        regular = { -- 0 is failure message
            zero = "You failed to loot anything.",
            one = "You looted 1 %{item}",
            other = "You looted %{count} %{item}",
        },

        regular_all_none_left = "You looted all items",
        regular_all_some_left = "You looted all desired items",
        
        -- ---------------------------------------------------------------------
        -- ORGANIC CONTAINERS
        -- ---------------------------------------------------------------------
        organic = { -- 0 is failure message
            zero = "You failed to harvest anything of value.",
            one = "You harvested 1 %{item}.",
            other = "You harvested %{count} %{item}.",
        },
        organic_failure = "You failed to harvest anything of value.",
        organic_all_none_left = "You harvested all nearby plants.",
        organic_all_some_left = "You harvested all desired plants.",

        -- ---------------------------------------------------------------------
        -- PICKPOCKET
        -- ---------------------------------------------------------------------
        pickpocket = {
            zero = "You failed to steal anything.",
            one = "You stole 1 %{item}.",
            other = "You stole %{count} %{item}.",
        },
        pickpocket_failure = "You failed to steal anything.",

        pickpocket_all_none_left = "You stole all items",
        pickpocket_all_some_left = "You stole all desired items",

        -- ---------------------------------------------------------------------
        -- BARTERING
        -- ---------------------------------------------------------------------
        barter = { -- verb is either "bought" or "sold"
            one = "You %{verb} 1 item for %{gold} gold",
            other = "You %{verb} %{count} items for %{gold} gold",
        },
        
    },


    -- =========================================================================
    -- MCM labels and descriptions.
    -- =========================================================================

    -- the structure of this table exactly matches the `layout` table in the `mcm` file
    mcm = {
        -- =====================================================================
        -- MAIN PAGE
        -- =====================================================================
        main = {
            label = "General",
            description="These settings affect most of the QuickLoot components.",
            show_scripted = {
                label = "How should QuickLoot handle scripted containers?",
                description = "Many containers have scripts on them that utilize the onActivate function to determine when the \z
                    player triggers them. In many cases you will be fine, in some rare cases you will break the script. Activating \z
                    a chest manually will trigger the script normally.\n\n\z
                    If the \"prefix container names\" option is selected, the string \"(*)\" will be placed infront of scripted containers.\z
                    ",
            },
            take_nearby = {
                label = "Take nearby items",
                description = "When a QuickLoot menu isn't active and you're looking at an ordinary item out in the world, you'll be able to \z
                take all similar nearby items by pressing the \"Take All\" key. These settings control this feature.",
                take_nearby_dist = {
                    label = "Take nearby distance",
                    description = "Objects within this distance will be taken when the 'Take all' key is pressed on an object of the same type.\n\n\z
                    Setting it to 0 will disable this feature.\n\n\z
                    The distance is specified using game units. Here are some approximate conversions:\n\n\z
                    1 foot = 22 game units (approximately).\n\n\z
                    1 meter = 72 game units (approximately).\n\n\z
                    ",
                },
    
                take_nearby_allow_theft = {
                    label = "Allow stealing nearby items?",
                    description = "If this setting is disabled, you will never steal nearby items.\n\n\z
                        \z
                        If enabled, then you will sometimes steal nearby items. \z
                        Nearby items will only be stolen if they're owned by the same person that owns the item you're currently looking at.\z
                    ",
                },
            },
            
                                
            take_nearby_m = {
                label = "Take nearby: how to handle theft (modifier key)?",
                description = 'When you press the "Take All" key to take nearby items WHILE holding the modifier key, how should the mod decide whether to also take stolen items?\n\n\t\z
                1) Never steal: owned items will never be taken.\n\t\z
                2) Use context: If you\'re pressing the "Take All" key while looking at an owned item, then other nearby owned will be taken. If you aren\'t looking at an owned item, then nearby owned items will not be taken.\n\t\z
                3) Always steal: owned items will always be taken.\n\t\z
                \z
                ',
            },

            blacklist = {
                label="Blacklist settings.",
                description="These settings control certain parts of the \"Blacklist\" and \"Plants Blacklist\" pages.\n\n\z
                I would've liked to put them there, but I didn't know how. Hopefully they will be put there in the future.",

                reset_containers = {
                    label="Reset \"Blacklist\" to default",
                    description="Currently, the \"default\" is to have nothing blacklisted, so this button basically will only deleted everything in the blacklist.\n\n\z
                    The \"Plants Blacklist\" has a few things in it, so you can always reset \"Blacklist\" to default (empty), and then use the other button to add the  \"Plants Blacklist\" settings.",
                },

                import_organic = {
                    label="Add entries from \"Plants Blacklist\" to \"Blacklist\"",
                    description = "Clicking this button will add everything from the \"Plants Blacklist\" to the \"Blacklist\"",
                },

                reset_organic = {
                    label="Reset \"Plants Blacklist\" to default", 
                    description="This will reset the \"Plants Blacklist\" to its factory setting.",
                },

                import_containers = {
                    label="Add entries from \"Blacklist\" to \"Plants Blacklist\".", 
                    description = "Clicking this button will add everything from the \"Plants Blacklist\" to the \"Blacklist\"",
                },
                
            },

            -- -----------------------------------------------------------------
            -- KEYBIND SETTINGS (category)
            -- -----------------------------------------------------------------
            keys = {
                label = "Keybindings",
                description="This setting lets you configure the various keybindings of this mod.",
                use_activate_btn = {
                    label = "Loot with activate key",
                    description = 'If enabled, you will loot items with the "Activate" key and open containers with the "Custom" key.\n\n\z
                        If disabled, you will loot containers with the "Custom" key and open them with the "Activate" key.',
                },
                custom = {
                    label = "Custom key (Take or Open)",
                    description = 'The function of this key depends on the previous setting ("Loot with activate key").\n\n\z
                        If that setting is enabled, you will "Take" items with the "Activate" key and "Open" containers with this key.\n\n\z
                        If that setting is disabled, you will "Take" items with this key and "Open" containers with the "Activate" key.',
                },
                take_all = {
                    label = "Take All Items",
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
                },
                modifier = {
                    label="Modifier Key",
                    description="The modifier key will alter the behavior of certain keys while held. \n\n\z
                        This is used to modify how many items are taken by the \"Take\" and \"Take All\" keys (see the \"Regular Containers\", \"Pickpocket\" and \"Plant/Organic\" tabs). \z
                        It is also used in Barter menus.\z
                    ",
                },
                undo = {
                    label="Undo key",
                    description="This key will be used to undo taking items from certain types of containers, effectively placing them back in the container you found them. \n\n\z
                        \z
                        NOTE: You can't undo training skills. Also, pressing this key won't \"undo\" any crimes you've commited. (People will still be mad you took it in the first place.)\z
                    ",
                },
            },
        },

        
        -- =====================================================================
        -- UI SETTINGS (page)
        -- =====================================================================
        UI = {
            label="UI Settings",
            description="These settings control various aspects of the UI.",

            size_and_positioning = {
                label="Size and positioning", 
                description="These settings control how many items are displayed in QuickLoot menus, as well as where on the screen the QuickLoot menus should appear.",
                
                menu_x_pos = {
                    label = "Menu X position",
                    description = "Higher values will position the menu closer to the right side of the screen."
                },
                menu_y_pos = {
                    label = "Menu Y position",
                    description = "Higher values will position the menu closer to the bottom side of the screen."
                },
                max_disp_items = {
                    label ="Number of items to display",
                    description = "This will control how many items are show in the popup inventory. At most 2 more items than this number will be shown (if the container is large).",    
                },
            },
            
            -- -----------------------------------------------------------------------------
            -- MISC SETTINGS (category)
            -- -----------------------------------------------------------------------------
            misc = {
                label="Miscellaneous Settings",
                description="These settings control various things that are hard to group into other categories. e.g, how items are sorted, whether to display messages, etc.",
            
                show_msgbox = {
                    label = "Display messagebox on loot",
                    description = "Show a default Morrowind messagebox whenever you loot an item.",
                },
                show_lucky_msg = {
                    label = "Show lucky messages", 
                    description = "Whenever you're about to fail a check to harvest a plant or pick someones pocket, you have a chance of getting lucky \z
                        (based on your current Luck). If you get lucky, the check will succeed instead of fail.\n\n\z
                        Enabling this setting will allow you to see when you were saved by your Luck.\n\n\z
                        Disabling this setting will still allow you to get lucky, but you won't know when it happens.",
                },
                sort_items = {
                    label="How should items be sorted?",
                    description="Should items in QuickLoot containers be sorted? If so, how?\n\n\z
                        Note: If Buying Game is installed and your mercentile skill currently prevents you from knowing item prices, then \z
                        the \"value/weight\" or \"value\" options won't take effect until your mercentile skill improves.    \z
                    ",
                },
                sort_by_obj_type = {
                    label="Should items also be sorted by object type?",
                    description="This setting requires a sorting option to be chosen in the previous setting.\n\n\z
                        If enabled, items of the same object type will be grouped together. \z
                        For example, all potions will be grouped together, but those will the highest value/weight ratio will appear first.\z
                    ",
                },
                update_inv_on_close = {
                    label="Update inventory on menu close?",
                    description="If your inventory is quite large, you may notice the game slows down a bit when picking up/moving items (both within QuickLoot menus and in normal menus). This happens when the inventory UI updates.\n\z
                    This option seeks to smooth things out a bit by only updating your inventory when pressing the \"Take All\" key, or when QuickLoot menus are closed.",
                },
            },
            -- -----------------------------------------------------------------------------
            -- TOGGLE SETTINGS (category)
            -- -----------------------------------------------------------------------------
            toggle = {
                label="Enable/disable UI elements",
                description="These settings allow you to toggle the visibility of certain components of the QuickLoot UI.",
            
                show_name = {
                    label = "Show container name",
                    description = "If enabled, the name of the active container will be shown at the top of the UI.",
                },
                show_controls = {
                    label = "Show controls",
                    description = "If enabled, the controls for the active menu will be displayed in the UI.\n\n\z
                        This can be useful since the controls vary based on the active container, and based on the status of that container.\z
                    ",
                },

                show_modified_controls = {
                    label="Show additional controls",
                    description='The barter menu makes heavy use of the modifier keys. If this setting is enabled, the actions that occur when the modifier keys are held will appear below the normal button prompts.\n\n\z
                        \z
                        For example, the lable (Switch Mode) will appear under the "Take All" key, and (Stack) will appear under the "Take" key. The (Stack) message indicates that the whole stack will be bought.\n\n\z
                        \z
                        Note: This setting requires the "Show controls" setting to also be enabled.\z
                    ',
                },
                
                enable_status_bar = {
                    label="Enable status bar",
                    description='The status bar is displayed right above control prompts. \z
                        It displays additional information for certain containers, such as who owns a container, \z
                        or how much gold you have (when in a Services menu).\z
                    ',
                },
            },
            -- -----------------------------------------------------------------
            -- JUST THE TOOLTIP COMPAT SETTINGS (category)
            -- -----------------------------------------------------------------
            ttip = {
                label='"Just the Tooltip" compatibility settings',
                description='These settings allow this mod to communicate with "Just The Tooltip" about which items have been \"Collected\".\n\n\z
                    \z
                    The "Just the Tooltip" mod is required for these options to work, and these settings only appear when that mod is installed.\z
                ',
            
                ttip_collected_str = {
                    label="\"Collected\" prefix",
                    description='Items marked as "Collected" will have their names prefixed by this string.\n\n\z
                        \z
                        For example, if this string is set to "(C)", and you\'ve marked a "Spoon" as "Collected", then any spoons that show up in QuickLoot menus will show up as "(C) Spoon".\n\n\z
                        \z
                    ',
                },
                ttip_mark_selected = {
                    label='Use the "Collection" key in QuickLoot menus?',
                    description='This setting allows the "Collection Marking" keybind to be used within QuickLoot menus. \z
                        If enabled, then pressing the "Collection Marking" key will mark the currently selected item as "Collected".\n\n\z
                        \z
                        If disabled, then pressing the "Collection Marking" with a QuickLoot menu open will instead mark the container. \z
                    ',
                },
            },
            


        },
        -- =====================================================================
        -- REGULAR CONTAINER SETTINGS (page)
        -- =====================================================================
        reg = {
            label = "Regular Containers", 
            description="These settings control the behavior of the QuickLoot menu that pops up on 'regular' containers. (e.g. chests, drawers, dead things.)",
        
            sn_dist = {
                label="Group nearby container contents: distance",
                description="By default, nearby containers with the same names will have their contents grouped together. Gone are the days of scouring through each individual sack to pick up ingredients.\n\n\z
                    This setting lets you specify how close containers have to be in order for their contents to be grouped together.\n\n\z
                    Setting this to 0 will disable searching for all nearby containers.\n\n\z
                    The distance is specified using game units. Here are some approximate conversions:\n\n\z
                    1 foot = 22 game units (approximately).\n\n\z
                    1 meter = 72 game units (approximately).\n\n\z",
            },
            take_all_min_ratio = {
                label="Take All: minimum gold/weight ratio",
                description="When the \"Take All\" key is pressed, only items with a gold/weight ratio above this number will be taken. Leave those cups and goblets behind!\n\n\z
                \z
                Setting to 0 will disable this setting.",
            },

            mi = {
                label="Item Stack Settings",
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
                
                mode = {
                    label="Take one item or whole stack?",
                    description = 'This setting controls the behavior of the mod when multiple items are in an item stack while NOT holding the modifier key. \z
                        For example, when the \"Take\" key is pressed on \"Kwama Eggs (5)\", should we take one egg or five?\n\n\z
                    ',
                },
                mode_m = {
                    label="Take one item or whole stack (modifier key)?",
                    description = 'This setting controls the behavior of the mod when multiple items are in an item stack while holding the modifier key. \z
                        For example, when the \"Take\" key is pressed on \"Kwama Eggs (5)\", should we take one egg or five?\n\n\z
                    ',
                },
                inv_take_all = {
                    label="Invert behavior for \"Take All\" key?",
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
                },
                min_ratio = {
                    label="Minimum Gold/weight ratio",
                    description="This setting is only used if \"How to decide?\" is set to an option that takes gold/weight ratio into account. (i.e., options 3, 5, or 6.)\z
                        If the gold/weight ratio of an item is under this amount, then only one item will be taken. \z
                        Otherwise, the whole stack will be taken.",
                },
                max_total_weight = {
                    label="Maximum total weight",
                    description="This setting is only used if \"How to decide?\" is set to an option that takes total weight into account. (i.e., options 4, 5, or 6.).\z
                        If the total weight of all items in a stack exceeds this number, only one item will be taken. \z
                        Otherwise, the whole stack will be taken.",
                },
            },

            -- =============================================================================
            -- DEAD SETTINGS (category)
            -- =============================================================================
            dead = {
                label = "Dead creatures/NPCs",
                description = "These settings govern what happens when looting dead creatures/NPCs",
                enable = {
                    label = "Enable",
                    description = "If enabled, a QuickLoot menu will appear when looking at dead creatures/NPCs.",
                },
                dispose = {
                    label="Dispose of empty creatures",
                    description="This setting determines what happens to dead creatures/NPCs once they become empty.\n\z
                        The options are:\n\n\t\z
                            \z
                            1) Don't allow QuickLoot to dispose of anything. \n\t\z 
                            2) If a creature is empty, replace the 'Take All' button with a 'Dispose' button.\n\t\z
                            3) Automatically dispose of a dead creature as soon as you look at it.\n\t\z 
                        ",
                },
            },

            -- =====================================================================
            -- INANIMATE SETTINGS (category)
            -- =====================================================================
            inanimate = {
                label="Inanimate Containers",
                description="These are things like barrels, chests, etc.",

                enable = {
                    label = "Enable",
                    description = "If enabled, the QuickLoot menu will show up when looking at barrels, chests, etc.",
                },
                

                ac = {
                    label = "Animated Containers Settings",
                    description = "These let you customize how this mod interacts with Animated Containers.\n\n\z
                        Note: Both \"Morrowind Containers Animated\" and \"Animated Containers Rewritten\" are required to use these settings.",
                   
                    open = {
                        label = "When should this mod play open animations?",
                        description = "This setting determines when the container opening animations play."
                    },
                    close = {
                        label = "When should this mod play close animations?",
                        description = "This setting determines when the container closing animations play."
                    },

                    open_empty_on_sight = {
                        label = "Open empty containers on sight?",
                        description = "This setting only takes effect if \"When should this mod play open animations?\" is set to \"When the menu appears\".\n\n\z
                            If enabled, then the animation will play for empty containers. If disabled, then no animation will play for empty containers."
                    },

                    auto_close_if_empty = {
                        label = "Automatically close empty containers?",
                        description = "If false, then this mod won't automatically close containers if they're empty.\n\n\z
                            This setting only takes effect if \"When should this mod play close animations?\" is not \"Never\".\n\n\z
                            Note: This mod will check whether an individual container is empty when deciding whether to close it or not. \z
                            If the \"group contents of nearby containers\" feature is enabled, then you may encounter situations where the QuickLoot menu of a container is not empty, \z
                            but the container itself is empty. In those situations, this setting will result in the containers not being closed."
                    },
                },
                
                -- -------------------------------------------------------------
                -- PLACING ITEM SETTINGS (subcategory)
                -- -------------------------------------------------------------
                placing = {
                    label = "Placing Items",
                    description="These settings affect the behavior of QuickLoot menus when placing items in containers.",

                    
                    allow_books = {
                        label="Allow books?", 
                        description="Should books be included in the \"Placing Items\" menu? This is disabled by default to minimize the chance of placing important quest items inside containers.",
                    },
                    allow_ingredients = {
                        label="Allow ingredients?", 
                        description="Should books be included in the \"Placing Items\" menu? This is disabled by default to minimize the chance of placing important quest items inside containers.",
                    },
                    reverse_sort = {
                        label = "Sort in reverse order?",
                        description = "If enabled, menus will be sorted in reverse order when placing items inside a container.\n\n\z
                            \z
                            For example, if QuickLoot menus are sorted by item weight (i.e. lightest items first), then heaviest items will be displayed first when placing items."
                    },
                    min_weight = {
                        label="Minimum weight",
                        description="When placing items into a container, only items with a weight above this number will be shown.",
                    },
                },
                -- -------------------------------------------------------------
                -- LOCKED OR TRAPPED SETTINGS (subcategory)
                -- -------------------------------------------------------------
                locked_or_trapped = {
                    label = "Locked or Trapped containers",
                    description="These settings affect the behavior of QuickLoot menus on locked/trapped containers.",
                    show_locked = {
                        label="Peek into locked containers?",
                        description="If this setting is enabled, and if your security skill is high enough, you'll be able to see inside of locked containers.\n\n\z
                            \z
                            This works as follows. Once your security reaches a minimum value (specified by the next setting), you'll be able to see the contents of locked containers if the lock level is below your current security level.\n\n\z
                            \z
                            This works using multiples of 25, so a security level of 25 will let you see any container under level 25, while a security level of 50 will let you see the contents of a container under level 50.\n\n\z
                            If your security is below the minimum value, you won't be able to see inside locked containers.\z
                        ",
                    },
                    show_locked_min_security = {
                        label="Locked containers: minimum security level",
                        description="If this setting is enabled, and if your security skill is high enough, you'll be able to see inside locked containers.\n\n\z
                            \z
                            This works as follows. Once your security reaches a minimum value (specified by this setting), you'll be able to see the contents of locked containers if the lock level is below your current security level.\n\n\z
                            \z
                            This works using multiples of 25, so a security level of 25 will let you see any container under level 25, while a security level of 50 will let you see the contents of a container under level 50.\n\n\z
                            If your security is below the minimum value, you won't be able to see inside locked containers.\z
                        ",
                    },
                    show_trapped = {
                        label = "Peek into trapped containers?", 
                        description = "If enabled, the contents of trapped containers will be shown, so long as your security is above a minimum value.\n\n\z
                            If disabled, you won't be able to see the contents of a trapped container until the trap is removed.",
                    
                    },
                    show_trapped_min_security = {
                        label="Trapped containers: minimum security level", 
                        description="If the previous setting is enabled, and if your security is above this level, you'll be able to peek inside trapped containers",
                    
                    },
                },
            },
        },

        -- =====================================================================
        -- ORGANIC SETTINGS (category)
        -- =====================================================================
        organic = {
            label="Plant/Organic",
            description = "An organic container is any container that respawns. This means that things like guild chests, Fargoth's hiding place, and some TR containers are treated by Morrowind in the same way as plants.\n\z
                This page lets you control how the mod behaves with respect to this type of container.\n\n\z
                The \"Which Organic Containers are not plants?\" setting lets you specify a list of containers that aren't plants. These containers will be treated by the mod as if they were inanimate objects.\n\n\z
                \z
                This means it's possible to disable the \"Organic\" portion of this mod and still have QuickLoot menus show up for things like guild chests.\n\z
                If Graphic Herbalism is installed, it's recommended that you select \"Graphic Herbalism\" for this option; this will consult Graphic Herbalism for its opinions on which containers are plants.\z
            ",

            enable = {
                label = "Enable",
                description = "If enabled, the QuickLoot menu will show up when looking at plants, and certain other organic containers (as specified by config settings).",
            },
            -- -----------------------------------------------------------------
            -- VISUAL/COMPATIBILITY SETTINGS (category)
            -- -----------------------------------------------------------------
            visual = {
                label="Visual/Compatibility Settings",
                description = "An organic container is any container that respawns. This means that things like guild chests, Fargoth's hiding place, and some TR containers are treated by Morrowind in the same way as plants.\n\z
                    This page lets you control how the mod behaves with respect to this type of container.\n\n\z
                    The \"Which Organic Containers are not plants?\" setting lets you specify a list of containers that aren't plants. These containers will be treated by the mod as if they were inanimate objects.\n\n\z
                    \z
                    This means it's possible to disable the \"Organic\" portion of this mod and still have QuickLoot menus show up for things like guild chests.\n\z
                    If Graphic Herbalism is installed, it's recommended that you select \"Graphic Herbalism\" for this option; this will consult Graphic Herbalism for its opinions on which containers are plants.\z
                ",
            
                change_plants = {
                    label="Change plants after looting",
                    description="This setting determines what happens to plants once they become empty.\n\z
                        The options are:\n\n\t\z
                            \z
                            1) Don't change plants: plants will not be altered in any way after looting. \n\t\z 
                            2) Use Graphic Herbalism: The plants will be altered by Graphic Herbalism. (This option requires Graphic Herbalism to be installed.)\n\t\z
                            3) Destroy Plants: Plants will be destroyed after they've been looted.\z 
                        ",
                },
                not_plants_src = {
                    label="Which organic containers are not plants?",
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
                    
                },
                hide_on_empty = {
                    label = "Hide menu when plant is empty",
                    description= "If \"Yes\", the QuickLoot menu will be hidden when looking at empty plants.\n\n\z
                        If \"No\", A QuickLoot menu will be shown, indicating that the plant is empty.\n\n\z
                        In either case, it's still possible to harvest nearby plants by pressing the \"Take All\" key.",
                },

            },
            -- -----------------------------------------------------------------
            -- MULTIPLE ITEMS SETTINGS (category)
            -- -----------------------------------------------------------------
            mi = {
                label="Item Stack Settings",
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
                mode = {
                    label="Take one item or whole stack?",
                    description="This setting determines how to decide when NOT holding the modifier key",
                },
                mode_m = {
                    label="Take one item or whole stack (modifier key)?",
                    description="This setting determines how to decide when holding the modifier key",
                },
                inv_take_all = {
                    label="Invert behavior for \"Take All\" key?",
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
                },
                min_chance = {
                    label="Item stack: Minimum total chance: %%s%%%%",
                    description="This setting is only used if \"How to handle multiple items?\" is set to \"total chance\". \z
                        If the chance of harvesting all items in the stack is under this amount, then only one item will be taken. \z
                        Otherwise, the whole stack will be taken.",
                },

            },
            -- -----------------------------------------------------------------
            -- XP SETTINGS (category)
            -- -----------------------------------------------------------------
            xp = {
                label = "XP Settings",
                description = "These settings modify when XP is awarded to the player for harvesting plants.\n\n\z
                    All XP settings will only take effect if \"Award XP?\" is enabled.\z
                ",
            
                award = {
                    label="Award XP?",
                    description="If enabled, you wil gain a small amount of XP for successfully harvesting a plant. The amount depends on the value of the plant."
                },
                max_lvl = {
                    label = "Max level to award XP?",
                    description = "If set to 5 or less, you will gain XP at all levels. If set to a number higher than 5, you will only gain XP while below that level."
                },
                on_failure = {
                    label = "Award (reduced) XP on failure?",
                    description = "If enabled, then when you fail to harvest a plant, you will receive a quarter of the XP you would receive if you were to succeed.\n\n\z
                        i.e., if you would get 1 XP for suceeding, you will get 0.25 XP for failing."
                },
            },

            -- -----------------------------------------------------------------
            -- MISC SETTINGS (category)
            -- -----------------------------------------------------------------
            misc = {
                label="Other Organic Container Settings",
                description = "An organic container is any container that respawns. This means that things like guild chests, Fargoth's hiding place, and some TR containers are treated by Morrowind in the same way as plants.\n\z
                    This page lets you control how the mod behaves with respect to this type of container.\n\n\z
                    The \"Which Organic Containers are not plants?\" setting lets you specify a list of containers that aren't plants. These containers will be treated by the mod as if they were inanimate objects.\n\n\z
                    \z
                    This means it's possible to disable the \"Organic\" portion of this mod and still have QuickLoot menus show up for things like guild chests.\n\z
                    If Graphic Herbalism is installed, it's recommended that you select \"Graphic Herbalism\" for this option; this will consult Graphic Herbalism for its opinions on which containers are plants.\z
                ",
            
                sn_cf = {
                    label="Which nearby plants should be included?",
                    description='This lets you specify which types of nearby plants to include in organic QuickLoot menus. The options are:\n\n\z
                    \z
                    1) Same plants: Nearby plants will be included only if they\'re the same type of plant as the one you\'re currently looking at.\n\n\z
                    \z
                    1) All plants: all nearby plants will be shown in organic QuickLoot menus.\z
                    ',
                },
                    
                
                sn_dist = {
                    label="How close should nearby plants be?", 
                    description="If set to 0, this will disable searching for all nearby plants.\n\n\z
                    The distance is specified using game units. Here are some approximate conversions:\n\n\z
                    1 foot = 22 game units (approximately).\n\n\z
                    1 meter = 72 game units (approximately).\n\n\z",
                },
                                    
                show_failure_msg = {
                    label="Show message on unsuccessful harvest?",
                    description="If enabled, then a message will appear whenever you fail to harvest a plant, as in the base game.",
                },


                show_chances = { label = "Should harvesting chances be shown?",
                    description="The \"Decide based on Security level\" option means that chances will be shown if your Alchemy level is above a specified value, \z
                        and chances will not be shown if your Alchemy level is under that value.\z
                        \z
                    ",
                },
                show_chances_lvl = { label = "Show chances: minimum Alchemy level",
                    description="This setting only takes effect if the last option is set to \"Decide based on Alchemy level\". \z
                        This setting determines the minimum Alchemy you should have in order to see your chances of successfully taking an item.\z
                    ",
                },

                show_chances_100 = { label = "Show chance even if it's 100%%",
                    description="This is purely cosmetic. Should your harvesting chance be shown even if it's 100%%?\n\n\z
                        \z
                        This setting will only take effect if the harvesting chance would otherwise be displayed.\z
                    ",
                },


                                    
                take_nearby = {
                    label = "Take nearby: how to handle theft?",
                    description = 'When you press the "Take All" key to take nearby items, how should the mod decide whether to also take stolen items?\n\n\t\z
                    1) Never steal: owned items will never be taken.\n\t\z
                    2) Use context: If you\'re pressing the "Take All" key while looking at an owned item, then other nearby owned will be taken. If you aren\'t looking at an owned item, then nearby owned items will not be taken.\n\t\z
                    3) Always steal: owned items will always be taken.\n\t\z
                    \z
                    ',
                },
                                    
                take_nearby_m = {
                    label = "Take nearby: how to handle theft (modifier key)?",
                    description = 'When you press the "Take All" key to take nearby items WHILE holding the modifier key, how should the mod decide whether to also take stolen items?\n\n\t\z
                    1) Never steal: owned items will never be taken.\n\t\z
                    2) Use context: If you\'re pressing the "Take All" key while looking at an owned item, then other nearby owned will be taken. If you aren\'t looking at an owned item, then nearby owned items will not be taken.\n\t\z
                    3) Always steal: owned items will always be taken.\n\t\z
                    \z
                    ',
                },
                -- -------------------------------------------------------------
                -- XP SETTINGS (subcategory)
                -- -------------------------------------------------------------            
                
                take_all_min_chance = {
                    label="Harvest All: Skip items with chance less than: %%s%%%%", id="take_all_min_chance",
                    description="When the \"Harvest All\" key is pressed, you will only attempt to harvest an ingredient if the chance of success \z
                        is greater than the value shown in the slider.\n\n\z
                        Setting this to 0 will result in no items being skipped.",
                },

                chance_mult = {
                    label = "Take chance multiplier: ", 
                    description = "This will multiply the chance you have of successfully taking a plant.", 
                },

                min_chance = {
                    label = "Minimum take chance: %%s%%%%",
                    description = "This will determine the minimum chance you have of taking a plant.\n\nDepending on your alchemy skill, the actual chance may be higher than this.",
                },

                max_chance = {
                    label = "Maximum take chance: %%s%%%%",
                    description = "This will determine the maximum chance you have of taking a plant.\n\nDepending on your alchemy skill, the actual chance may be lower than this.",
                },
            },
        },


        -- =============================================================================
        -- PICKPOCKET SETTINGS (page)
        -- =============================================================================
        pickpocket = {
            label="Pickpocket",
            description = "This controls the behavior of QuickLoot menus that appear when pickpocketing.",

            enable = {
                label = "Enable",
                description = "If enabled, a QuickLoot menu will appear when you are crouched and looking at an alive NPC.",
            },
            -- -----------------------------------------------------------------
            -- MULTIPLE ITEMS SETTINGS (category)
            -- -----------------------------------------------------------------
            mi = {
                label="Item Stack Settings",
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
            
                mode = {
                    label="Take one item or whole stack?",
                    description="This setting determines how to decide when NOT holding the modifier key",
                },
                mode_m = {
                    label="Take one item or whole stack (modifier key)?",
                    description="This setting determines how to decide when holding the modifier key",
                },
                inv_take_all = {
                    label="Invert behavior for \"Take All\" key?",
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
                },
                min_chance = {
                    label="Item stack: Minimum total chance: %%s%%%%",
                    description="This setting is only used if \"How to handle multiple items?\" is set to \"total chance\". \z
                        If the chance of harvesting all items in the stack is under this amount, then only one item will be taken. \z
                        Otherwise, the whole stack will be taken.",
                },
            },
            -- -------------------------------------------------------------
            -- EQUIPPED ITEMS SETTINGS (category)
            -- -------------------------------------------------------------
            equipped = {
                label="Equipped item settings",
                description="These settings allow you to control what kinds of equipped items can be pickpocketed.\n\n\z
                    \z
                    If stealing a certain kind of equipped item is not allowed, then it won't show up in the pickpocketing menu.\n\n\z
                    These settings should be functional now. Hopefully it was worth the wait. \z
                ",
            
                weapons = { 
                    label = "Allow stealing equipped weapons?", 
                    description = "Should it be possible to steal this type of equipped item?"
                },
                armor = { 
                    label = "Allow stealing equipped armor?", 
                    description = "Should it be possible to steal this type of equipped item?"
                },
                clothing = { 
                    label = "Allow stealing equipped clothing?",
                    description = "Should it be possible to steal this type of equipped item?"
                },
                jewelry = { 
                    label = "Allow stealing equipped jewelry?",
                    description = "Should it be possible to steal this type of equipped item?"
                },
                accessories = { 
                    label = "Allow pickpocketing equipped gloves/belts?",
                    description = "Should it be possible to steal this type of equipped item?"
                },

                show = { 
                    label = "Show unlootable equipped items?",
                    description="This setting only affects equipped items that can't be pickpocketed. (For example, if you allow pickpocketing equipped weapons, then this setting won't affect weapons.)\n\n\z
                        If enabled, then equipped items will be greyed out, but still shown. If disabled, equipped items will not be shown at all. \z
                    ",
                },
            },
            -- -----------------------------------------------------------------
            -- MISC SETTINGS (category)
            -- -----------------------------------------------------------------
            misc = {
                label="Other Pickpocket Settings",
                description = "These are settings that don't fit neatly into other categories",
                               

                show_chances = { label = "Should pickpocketing chances be shown?",
                    description="The \"Decide based on Security level\" option means that chances will be shown if your security level is above a specified value, \z
                        and chances will not be shown if your Security level is under that value.\n\n\z
                        \z
                        Chances will never be shown if using \"Determinism mode\" (as the chances are always 0 or 100).\z
                    ",
                },
                show_chances_lvl = { label = "Show chances: minimum Security level",
                    description="This setting only takes effect if the last option is set to \"Decide based on Security level\". \z
                    This setting determines the minimum Security you should have in order to see your chances of successfully taking an item.\n\n\z
                    \z
                    Chances will never be shown if using \"Determinism mode\" (as the chances are always 0 or 100).\z",
                },

                show_chances_100 = { label = "Show chance even if it's 100%%",
                    description="This is purely cosmetic. Should your pickpocketing chance be shown even if it's 100%%?\n\n\z
                    \z
                    This setting will only take effect if the pickpocketing chance would otherwise be displayed.\n\n\z
                    \z
                    Chances will never be shown if using \"Determinism mode\" (as the chances are always 0 or 100).\z",
                },

                determinism = {label = "Enable Determinism mode?",
                    description = "This setting is inspired by mort's Pickpocket mod and the \"Magicka of the Third Era\" mod. It works as follows:\n\n\z
                        Your chances of pickpocketing an item will always be 0 or 100.\n\n\z
                        If your chance of pickpocketing an item would be above 70%% (using the mod's normal calculations), then your chance will instead be 100%%.\n\n\z
                        If your chance of pickpocketing an item would be below 70%% (using the mod's normal calculations), then your chance will instead be 0%%.\n\n\z
                        \z
                        The next setting will allow you to chance the cutoff point from 70%% (the default) to some other number."
                },
                determinism_cutoff = {label = "Determinism cuttoff percentage: %%s%%%%",
                    description = "This setting only takes effect if \"Determinism mode\" is enabled.\n\n\z
                        If your chances of pickpocketing an item would be above this number (using the mods normal calculations), then your chance will instead be 100%%.\n\n\z
                        If your chances of pickpocketing an item would be below this number (using the mods normal calculations), then your chance will instead be 0%%.\n\n\z
                        \z
                    ",
                },


                take_all_min_chance = {
                    label="Take All: Skip items with chance less than: %%s%%%%",
                    description="When the \"Take All\" key is pressed, you will only attempt to pickpocket an item if the chance of success \z
                        is greater than the value shown in the slider.\n\n\z
                        Setting this to 0 will result in no items being skipped.",
                },

                show_detection_status = { label = "Show detection status",
                    description = "If enabled, the QuickLoot menu will show whether the person you're pickpocketing has detected you.",
                },

                chance_mult = { label = "Take chance multiplier",
                    description = "This will multiply the chance you have of successfully stealing something.",
                },
                min_chance = { label = "Minimum take chance: %%s%%%%",
                    description = "This will determine the minimum chance you have of stealing something.\n\nDepending on your skill level, the actual chance may be higher than this.",
                },
                max_chance = { label = "Maximum take chance: %%s%%%%",
                    description = "This will determine the maximum chance you have of stealing something.\n\nDepending on your skill level, the actual chance may be lower than this.",
                },

                detection_mult = { label = "Detection modifier: ",
                    description = "Your chance to steal something will be multiplied by this number if you are detected.",
                },

                trigger_crime_undetected = { label = "Trigger a crime when undetected?", 
                    description = "If true, a crime will be triggered after you successfully pickpocket someone, even if the person you're pickpocketing didn't detect you.\z
                    This means that you could still be caught by another witness who sees the theft. If no one saw the crime, then you will not be caught.\n\n\z
                    If false, then no crime will be reported after a successful pickpocket, so long as the person you're stealing from isn't detecting you.",
                },
                

            },
        },

        -- =====================================================================
        -- SERVICES (page)
        -- =====================================================================
        services = {
            label="Services",
            description = "This controls the behavior of Services menus. (currently Barter and Training menus.)",

            enable = {
                label = "Enable services menus",
                description="This setting is required for barter and training menus to appear."
            },

            allow_skooma = { 
                label = "Allow services when you have Skooma?",
                description='If true, you\'ll be able to train even if you have Skooma and the trainer doesn\'t like that.\n\n\z
                \z
                Credit to Necrolesian for their "Hide The Skooma" mod, which this setting is based off of.\n\n\z
                \z
                Note: This setting only takes effect when checking to create a QuickLoot menu. You will still need the "Hide The Skooma" mod \z
                for that functionality within dialogue menus.',
            },
            default_service = {
                label="Preferred Service",
                description='This lets you set the service you\'d like to start in. This only applies to NPCs that offer multiple services.\n\n\z
                    If an NPC does not offer the specified service, then the next valid service will be selected.\z
                ',
            },
        
            -- ---------------------------------------------------------------------
            -- TRAINING (category)
            -- ---------------------------------------------------------------------
            training = {
                label="Training Settings",
                description="These menus appear when looking at trainers.",

                enable = {
                    label = "Enable training menus", 
                    description="Should QuickLoot menus appear when looking at trainers?"
                },

                max_lvl_is_weight = {
                    label = "Display maximum training level?",
                    description="This setting is a bit awkward at the moment. If enabled, the training menu will show the maximum level a trainer can train a skill to.\z
                    However, this will be shown in the \"item weight\" section, underneath an anvil. Not my best piece of UI work.\z
                    If anyone knows a better icon to use for this, please let me know.\z
                ",
                },

            },

            -- ---------------------------------------------------------------------
            -- BARTER SETTINGS (category)
            -- ---------------------------------------------------------------------
            barter = {
                label = "Barter", 
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
            
                enable = {
                    label = "Enable", 
                    description = "If enabled, the QuickLoot menu will show up when looking at NPCs that can barter.",
                },
                start_buying = {
                    label="Default to \"Buy\" menu or \"Sell\" menu?",
                    description='This lets you decide whether the "Buy" menu or the "Sell" menu should appear when you first look at an NPC.\n\n\z
                        You can still switch between "Buy" and "Sell" mode by holding the modifier key and pressing "Take All"\z
                    ',
                },
                switch_if_empty = {
                    label="Switch default menu if empty?",
                    description='If the preferred barter menu (specified by previous setting) is empty, should we switch menus?\n\n\z
                        This setting only takes effect the first time the barter menu is opened (which can also happen when switching services).',
                },
                award_xp = {
                    label = "Award XP?",
                    description = "If enabled, XP is rewarded for successfully bartering using QuickLoot menus.\n\n Requires the \"Barter XP Overhaul\" mod.",
                    
                },
                selling = {
                    label = "Selling Items",
                    description = "These settings control which items are shown when selling items, as well as how the inventory in sorted when selling items.\n\n\z
                        \z
                        You can use these settings to cut down on which items get shown, helping to minimize the amount of scrolling you have to do.\z
                    ",
                    reverse_sort = {
                        label = "Sort in reverse order when selling?",
                        description = "If enabled, menus will be sorted in reverse order when selling.\n\n\z
                            \z
                            For example, if QuickLoot menus are sorted by item weight (i.e. lightest items first), then heaviest items will be displayed first when selling."
                    },

                    allow_books = {
                        label = "Allow selling books?",
                        description = "This may help declutter the barter menu when you're selling things.",
                    },
                    allow_ingredients = {
                        label = "Allow selling ingredients?",
                        description = "This may help declutter the barter menu when you're selling things.",
                    },
                    min_weight = {
                        label="Minimum item weight",
                        description="Only items with a weight greater than this number will be shown in selling menus.",
                    },
                },
                -- -------------------------------------------------------------
                -- EQUIPPED ITEM SETTINGS (subcategory)
                -- -------------------------------------------------------------
                equipped ={
                    label="Equipped item settings",
                    description="These options were pretty easy to implement after adding them to the \"Pickpocket\" menu so I thought why not? \z
                        Maybe your character is really persuasive or something.\n\n\z
                        NOTE: These settings are a double-edged sword. You can buy items that NPCs have equipped, but NPCs can also buy items you have equipped.\z
                    ",

                    weapons = { 
                        label = "Allow bartering equipped weapons?", 
                        description = "Should it be possible to barter this type of equipped item?"
                    },
                    armor = { 
                        label = "Allow bartering equipped armor?", 
                        description = "Should it be possible to barter this type of equipped item?"
                    },
                    clothing = { 
                        label = "Allow bartering equipped clothing?",
                        description = "Should it be possible to barter this type of equipped item?"
                    },
                    jewelry = { 
                        label = "Allow bartering equipped jewelry?",
                        description = "Should it be possible to barter this type of equipped item?"
                    },
                    accessories = { 
                        label = "Allow pickpocketing equipped gloves/belts?",
                        description = "Should it be possible to barter this type of equipped item?"
                    },

                    show = {
                        label = "Show unlootable equipped items?",
                        description="This setting only affects equipped items that can't be bartered. (For example, if you allow bartering equipped weapons, then this setting won't affect weapons.)\n\n\z
                            If enabled, then equipped items will be greyed out, but still shown. If disabled, equipped items will not be shown at all. \z
                        ",
                    },
                },
            },
        },
        -- =====================================================================
        -- BLACKLIST (filter page)
        -- =====================================================================
        blacklist_containers = {
            label = "Blacklist",
            description = "All QuickLoot components will be disabled for any of the containers included in this blacklist.",
        },
        -- =====================================================================
        -- PLANTS BLACKLIST (filter page)
        -- =====================================================================
        blacklist_organic = {
            label = "Plants Blacklist",
            description = "This is a list of containers that shouldn't be treated as plants. Things in this blacklist won't be destroyed by the \"Destroy Plants\" Setting. \z
                Also, if \"Which organic containers aren't plants\" is set to \"Plants Blacklist\", then the containers in this list won't be treated as plants by QuickLoot. Those containers will instead use the \"Inanimate\" QuickLoot menu.\n\n\z
            ",
        },
        -- =====================================================================
        -- ADVANCED SETTINGS (page)
        -- =====================================================================
        advanced = {
            label = "Advanced Settings", 
            description="More advanced/niche settings are placed here.\n\n\z
                WARNING: it is very easy to break this mod by messing with the compatibility settings below. If you do end up breaking it, you can fix the mod by clicking the  \"Reset to default\" button.",
            
            v_dist = {
                label="Search nearby containers: vertical distance",
                description="The \"Search nearby containers\" feature (used by regular containers and organic containers) uses a \"cylindric\" metric when computing distance.\n\n\z
                    Basically, we make a cylinder a big cylinder around the container we're looking at, and then see which other containers lie inside that cylinder.\n\n\z
                    The \"distance\" settings in the other pages specify the \"radius\" of the cylinder, while this setting specifies the \"height\" of the cylinder.\n\n\z
                    We use a cylindric metric for two reasons:\n\z
                    \t1) it minimizes the chances of taking items on different floors when indoors (in theory anyway)\n\z
                    \t2) it plays more nicely with shelves and such.\z
                ",
            },
            compat = {
                label="Compatibility Settings",
                description="These settings can be safely ignored by most people using the mod. They exist in the hopes of offering easy solutions to some compatibility conflicts.\n\n\z
                    Pretty much all of these settings require a restart to take effect, since I'm expecting them to be used very rarely.\n\n\z
                    WARNING: It's highly recommended you don't change these settings unless you know what you're doing. Certain configurations of these settings can break the mod. If this happens, click the \"Reset to default\" button and everything should be fixed after the game is restarted.\z
                ",
                

                sw_claim = {
                    label="Scrollwheel: claim events when menu active",
                    description='If true, then any mods with lower priority scrollwheel events WILL NOT react to the scrollwheel being used while a QuickLoot menu is open.\n\n\z
                        \z
                        If false, then any mods with lower priority scrollwheel events WILL react to the scrollwheel being used while a QuickLoot menu is open.\n\n\z
                        \z
                        Note: This settings only matters while a QuickLoot menu is active. If no QuickLoot menu is active, then other mods will function normally regardless of what this is set to.\z
                    ',
                },
                sw_priority = {
                    label="Scrollwheel: event priority",
        
                    description='This setting determines the priority of the event that fires whenever your mouse is scrolled. Things with higher numbers happen earlier.\n\n\z
                        \z
                        If you\'re trying to make this mod react to the mouse being scrolled BEFORE another mod, this value should be HIGHER than the value used by the other mod.\n\n\z
                        \z
                        If you\'re trying to make this mod react to the mouse being scrolled AFTER another mod, this value should be LOWER than the value used by the other mod.\n\n\z
                        \z
                    ',
                },
                ak_claim = {
                    label="Arrow keys: claim events when menu active",
                    description='If true, then any mods with lower priority arrow key events WILL NOT react to the arrow key being used while a QuickLoot menu is open.\n\n\z
                            \z
                            If false, then any mods with lower priority arrow key events WILL react to the arrow key being used while a QuickLoot menu is open.\n\n\z
                            \z
                            Note: This settings only matters while a QuickLoot menu is active. If no QuickLoot menu is active, then other mods will function normally regardless of what this is set to.\z
                        ',
                },
                ak_priority = {
                    label="Arrow keys: event priority",
                    description='This setting determines the priority of the event that fires whenever the up/down arrow keys are pressed. Things with higher numbers happen earlier.\n\n\z
                        \z
                        If you\'re trying to make this mod react to arrow keys being pressed BEFORE another mod, this value should be HIGHER than the value used by the other mod.\n\n\z
                        \z
                        If you\'re trying to make this mod react to arrow keys being pressed AFTER another mod, this value should be LOWER than the value used by the other mod.\n\n\z
                        \z
                    ',
                },
                custom_priority = {
                    label="Custom key: event priority",
                    description='This setting determines the priority of the event that fires whenever the "Custom" key is pressed. Things with higher numbers happen earlier.\n\n\z
                        \z
                        If you\'re trying to make this mod react to this key being pressed BEFORE another mod, this value should be HIGHER than the value used by the other mod.\n\n\z
                        \z
                        If you\'re trying to make this mod react to this key being pressed AFTER another mod, this value should be LOWER than the value used by the other mod.\n\n\z
                        \z
                    ',
                },
                take_all_priority = {
                    label="Take All key: event priority",
                    description='This setting determines the priority of the event that fires whenever the "Take All" key is pressed. Things with higher numbers happen earlier.\n\n\z
                        \z
                        If you\'re trying to make this mod react to this key being pressed BEFORE another mod, this value should be HIGHER than the value used by the other mod.\n\n\z
                        \z
                        If you\'re trying to make this mod react to this key being pressed AFTER another mod, this value should be LOWER than the value used by the other mod.\n\n\z
                        \z
                    ',
                },
                activate_key_priority = {
                    label="Activate key: event priority",
                    description='This setting determines the priority of the event that fires whenever the "Activate" key is pressed. Things with higher numbers happen earlier.\n\n\z
                        \z
                        Note: This is different from the event that fires when you actually activate something, which is what most mods use.',
                },
                activate_event_priority = {
                    label="Activate event: event priority",
                    description='This setting determines the priority of the event that fires whenever the "Activate" key is pressed. Things with higher numbers happen earlier.\n\n\z
                        \z
                        This event is responsible for blocking activations when they aren\'t supposed to happen. (e.g., when you loot with the activate key or press the custom key to open a container.)\n\n\z
                        \z
                        Note: no actual looting/decision logic happens in the "activate" event, it all happens when the activate key is pressed.\z
                    ',
                },
                menu_entered_priority = {
                    label="menuEntered: event priority",
                    description='Whenever a menu is entered, this mod will destroy any active QuickLoot menus. This is to prevent softlocks/crashes.\n\n\z
                        Nothing else is done when a menu is opened. This event is not claimed, blocked, or modified in any way.',
                },
                load_priority = {label="load: event priority",
                    description='Whenever a save is about to be loaded, this mod will destroy any active QuickLoot menus. This is to prevent softlocks/crashes.\n\n\z
                        Nothing else is done when a save is about to loaded. This event is not claimed, blocked, or modified in any way.\n\n\z
                        \z
                        This defaults to a very high value because certain mods need to claim the "load" event in order to function properly.\z
                        This usually happens when a mod is changing what happens during the event (e.g. which save to load). \z
                        It\'s recommended you keep this setting at a high value because this mod is only using the event as an indication that the QuickLoot menu shouldn\'t be open anymore.\z
                    ',
                },
                simulate_priority = {label="simulate: event priority",
                    description='The "simulate" event triggers every frame (for our purposes). This mod is very weary of using the "simulate" event and tries to do so only when absolutely necessary.\n\n\z
                        \z         
                        Currently, these are the ways "simulate" events are used:\n\z
                        1) When using training/bartering menus: used to destroy the menu whenever you start sneaking or the NPC dies.\n\z
                        2) When pickpocketing: used to update pickpocketing chances when your detection status changes, and to destroy the menu whenever you stop sneaking or the NPC dies.\n\z
                        3) When looking at a living NPC with no training/bartering menus and not sneaking: used to create a pickpocketing event when you start sneaking.\n\n\z
                        \z
                        In all cases, the "simulate" event is unregistered as soon as possible. For example, when the Pickpocketing menu gets destroyed, we unregister the "simulate" event and stop checking things every frame.\n\n\z
                        \z
                        If certain mods claim and block the "simulate" event, there could be compatibility problems. In that case, it\'s recommended you increase the priority of this event.\z
                    ',
                },
                dialogue_filtered_priority = {
                    label="dialogueFiltered: event priority",
                    description='This event triggers when a dialogue event has been selected, or when checking to see if a merchant offers certain services.\n\n\z
                        \z
                        This mod will only utilize this event if an "Allow skooma" option is selected. If either of those settings is selected, this mod will trigger on a dialogue event, and see if we\'re currently trying to create a new QuickLoot menu. \z 
                        If we\'re trying to create a new QuickLoot menu, it will filter out Skooma rejections, and block other mods from acting on them.\n\n\z
                        \z
                        It\'s recommended that you set this to at least 1, in order to block the "Hide The Skooma" mod from activating when trying to create a QuickLoot menu.\z
                        This is because "Hide The Skooma" is intended to only fire in dialogue windows, and things can get a bit weird if it fires outside of a dialogue menu.\z
                    ',
                },
                reset = {
                    label="Reset advanced settings to default",
                    description='Pressing this button will reset all "Advanced settings" to their default value.\n\n\z
                    Other settings will not be affected. i.e., settings on other pages of the MCM will not be changed.\z
                    ',
                },
            },
        },
    }, -- end MCM   
}