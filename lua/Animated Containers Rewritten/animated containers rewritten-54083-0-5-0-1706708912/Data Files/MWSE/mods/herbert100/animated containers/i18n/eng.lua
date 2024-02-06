return {
    MCM = {
        main_page = {
            label="Settings", 
		    desc="Here you will find various settings for the Animated Containers mod.",

            activate_on_open = {
                label="Show loot menu after animation finishes?",
                desc="If true, then the standard container looting menu will open after the container opening animation finishes.\n\n\z
                    WARNING: it will be very hard to loot containers if this setting is disabled \z
                    AND \"Close containers with 'Activate' key?\" is enabled."
            },

            auto_close = {
                label="Automatically close containers?",
                desc = "If enabled, then the close animations will play automatically, whenever appropriate.\n\n\z
                    \z
                    Note: other mods can extend the functionality of this setting. \z
                    For example, this setting can allow QuickLoot to close containers whenever the QuickLoot menu disappears.\n\n\z
                    \z
                    This mod (Animated Containers) will only use this setting for the following purpose: \z
                    closing containers after you loot them, provided the \"Show loot menu after animation finishes?\" setting is enabled.\z
                ",
            },
            stay_open_between_loads = {
                label="Remember container status between loads/cell changes?",
                desc="If true, containers will be kept open when reloading saves/changing cells.\n\n\z
                    If false, all containers will be closed after reloading a save/changing cells."
            },
            play_sound = {label="Play sounds?", desc="If enabled, sounds will be played when opening/closing containers."},

            activate_to_close = {
                label="Close containers with \"Activate\" key?",
                desc="If true, then you will be able to close looted containers by activating them.\n\n\z
                    \z
                    WARNING: Looting containers will be very hard if this setting is enabled \z
                    and \"Show loot menu after animation finishes?\" is disabled."
            },

            open_wait_percent = {
                label="Open after %%s%%%% of the animation plays.", 
                desc="This setting only takes effect if the \"Show loot menu after animation finishes?\" setting is enabled.\n\n\z
                \z
                This setting will let you specify what percentage of the open animation should play before a container's inventory is shown.\n\n\z
                \z
                If set to 0%%, the menu will open immediatley. If 50%%, the menu will appear after half of the animation plays. \z
                If 100%%, the menu will appear after the animation finishes. (Other percentages are also allowed.)"
            },

        },
        advanced = {
            label="Advanced", 
            desc = "Here you will find advanced settings. These mainly have to do with collision and logging options.",

            activate_event_priority = {
                label="Activate: event priority", 
                desc="This setting lets you change the priority of the event that happens when you activate containers.\n\n\z
                If you're experiencing compatibility problems with opening/closing containers when activating them, this setting could help to fix those. Or not.\n\n\z
                This setting also has great potential to mess things up. You've been warned.\n\n\z
                Default value: 301 (because Graphic Herbalism has a priority of 300).",
            },

            collision = {
                label="Collision Detection Settings", 
				desc = "These settings control how the mod detects when objects are ontop of containers. This is still a work in progress and needs some tweaking. \n\n\z
					In the meantime, these settings can be a nice way to fine-tune the collision detection used by this mod.",
                

                initial_raytest_max_dist = {
                    label = "Initial container raytest max distance",
                    desc = "Before doing anything else, a ray is fired up from the center of the container to see if anything is directly ontop of it.\n\n\z
                        This setting lets you customize how much distance should be between this object and an object detected above it."
                },
                obj_raytest_max_dist = {
                    label="Object raytest max distance", 
                    desc = "After all other tests have passed, a ray is fired down from an object this mod thinks is likely to be ontop of a container. This setting determines the maximum distance of that ray test. \n\n\z
                    Note: The distance is offset by the bounding box of the item being tested, so that this setting behaves more consistently with small/large objects."
                },
                
                check = {
                    label="Check for collisions.",
                    desc="Enabling this will make the mod check for collisions before opening containers. (To make sure you don't open a barrel that has a plant ontop of it, for example.)\n\n\z
                        If disabled, this mod won't check for collisions (you may notice some containers opening when they're \"not supposed to\").\n\n\z
                        \z
                        Checking for colllision is a bit involved so you may notice a performance bump in some places, but it's relatively unlikely. \z
                        Also, each container only checks for collisions once. \z
                        (You can change this in the Advanced Settings page.)"
                },

                reset_on_load = {
                    label="Reset collision information on load/cell change.",
                    desc="If enabled, collision information will be reset when loading/changing cells. \z
                        Currently, collision information is only stored if the a container is blocked by an immovable object, or not blocked by any objects. So, not much should change between loads/cell changes.\n\n\z
                        Disabling this setting will mean that container collision information gets reset whenever you load a save/change cells."
                },

                max_degree = {
                    label="Max angle: %%s degrees", 
                    desc="This setting may be a bit confusing. \z
                        But basically, part of the collision detections involve determining whether objects are actually ontop of containers.\n\n\z
                        This is done by drawing a line from the center of the container to the center of the object being checked. This line should be pointing \"almost\" directly upwards. \z
                        To make sure this line is pointing almost directly upwards, we look at the angle formed by this line and a line pointing directly upwards. This angle shouldn't be too big, and this setting lets you specify how small it has to be.\n\n\z
                        Setting this too high will result in objects next to the container being marked as colliding with the container.\n\z
                        Setting this too low will result in certain objects ontop of the container not being detected (if those objects are too close to the edge of the container).\z
                    "
                },
                max_xy_dist = {
                    label="Max xy-distance to use", 
				    desc="The xy-distance between objects and the center of the container should be less than or equal to this number.\n\n\z
					    (The xy-distance is given by taking the distance only between xy-coordinates, i.e., taking the distance of (x1,y1,0) and (x2,y2,0).)"
                },

                max_z_dist = {
                    label="Max z-distance to use", 
				    desc="The z-distance between objects should be less than this number."
                },

                bounding_box = {
                    label="Bounding Box Settings",
                    desc = "Another part of checking collision is making sure the bounding boxes aren't intersecting. But before doing so, this mod tweaks the bounding box of the container before using it in calculations.\n\n\z
                        This is to accomodate for the container potentially getting bigger as a result of opening, and also so that we can ignore collisions that might happen at the \"bottom\" of the container. \z
                        (If something is too close to the side of a barrel, that won't stop you from opening the barrel.)",

                    bb_check = { label="Check bounding box collision", desc="Should bounding boxes be tested for collision?" },
                    bb_xy_scale = { label="xy-scale", desc="How much should we scale the x and y coordinates of the bounding box?" },

                    bb_z_top_scale = {
                        label="z-scale",
                        desc="How much should we scale the top of the bounding box? This should probably be a bit bigger than 1, \z
                            so we can properly account for the container opening."
                    },
                    bb_z_ignore_bottom_percent = {
                        label="Ignore bottom %%s%%%% of box.", 
                        desc="This setting lets you determine how much of the \"bottom\" part of the bounding box should be ignored. \z
                            This is so that we don't erroneously detect \"collisions\" that might be caused by objects on the floor next to a chest, for example."
                    
                    },
                    bb_other_max_diagonal = {
                        label="Don't check collision on objects with diagional length bigger than .", 
                        desc="Objects with really big bounding boxes \"tend\" to be hollow (such as rooms, tents, etc). This setting lets you determine which objects are too big to be checked for.\n\n\z
                            Set to 0 to check collision regardless of bounding box size."
                    },


                },
            },


            log = {
                label="Log Settings", 
				desc="These let you prevent some repetitive information from being logged on every launch.\n\n\z
					This can be helpful when debugging if you want to declutter the logs. The log level each message is printed at is indicated in the name of each setting. \n\n\z
					These settings will only take effect if the log level is higher than the level indicated in the relevant setting.\n\n\z
					For example, changing the value of a \"TRACE\" option won't do anything unless the current logging level is set to trace.",

                log_replace_table = {
                     label="TRACE: Print a message containing the table of meshes to replace?", 
                     desc="Happens during startup."
                },
                log_every_replacement = {
                     label="TRACE: print a message for every mesh that gets replaced?", 
                     desc="Happens during startup. This will result in a lot of messages."
                },
                log_add_interop_data = {
                     label="TRACE: print interop data being added.", 
                     desc="Happens during startup."
                },
		
            },
        }
    }
}