require("herbert100.animated containers.mod")
local common = require("herbert100.animated containers.common")
event.register("modConfigReady", function()
	local function dist_label_converter(self, value)
		local feet = value / 22.1
		local meters = 0.3048 * feet
		if self.decimalPlaces == 0 then
			return string.format("%i ft (%.2f m)", feet, meters)
		end
		return string.format(
			string.format("%%.%uf ft (%%.%uf m)", self.decimalPlaces, self.decimalPlaces + 2),
			feet, meters
		)
	end
	local config = require("herbert100.animated containers.config")
	local default = require("herbert100.animated containers.config.default")
	local template = mwse.mcm.createTemplate {
		label = "Animated Containers",
		config = config,
		defaultConfig = default,
		showDefaultSetting = true,
	}
	template:register()
	template:saveOnClose("Animated Containers", config)
	local page = template:createSideBarPage { label = "Settings" }
	page:createYesNoButton {
		label = "Show loot menu after animation finishes?",
		configKey = "activate_on_open",
		description = "If true, then the standard container looting menu will open after the container opening animation finishes.\n\n\z
			WARNING: it will be very hard to loot containers if this setting is disabled \z
			AND \"Close containers with 'Activate' key?\" is enabled.",
	}
	page:createDropdown {
		configKey = "auto_close",
		label = "Automatically close containers?",
		description = 'This setting governs whether containers should be closed automatically after being opened.\n\n\z
			\z
			The "Only if container has items" option will empty containers to be left open, while nonempty containers will be closed automatically.\n\n\z
			Note: other mods can extend the functionality of this setting. \z
			For example, this setting can allow QuickLoot to close containers whenever the QuickLoot menu disappears.\n\n\z
			\z
			This mod (Animated Containers) will only use this setting for the following purpose: \z
			closing containers after you loot them, provided the \"Show loot menu after animation finishes?\" setting is enabled.\z
		',
		options = {
			{ label = "Never.",                      value = 1 },
			{ label = "Only if container has items", value = 2 },
			{ label = "Always",                      value = 3 },
		},
	}
	page:createYesNoButton {
		configKey = "stay_open_between_loads",
		label = "Remember container status between loads/cell changes?",
		description = "If true, containers will be kept open when reloading saves/changing cells.\n\n\z
			If false, all containers will be closed after reloading a save/changing cells.",
	}
	page:createYesNoButton {
		configKey = "play_sound",
		label = "Play sounds?",
		description = "If enabled, sounds will be played when opening/closing containers.",
	}
	page:createYesNoButton {
		configKey = "activate_to_close",
		label = "Close containers with \"Activate\" key?",
		description = "If true, then you will be able to close looted containers by activating them.\n\n\z
				\z
				WARNING: Looting containers will be very hard if this setting is enabled \z
				and \"Show loot menu after animation finishes?\" is disabled.",
	}
	page:createYesNoButton {
		configKey = "check",
		config = config.collision,
		defaultConfig = default,
		label = "Check for collisions.",
		description = "Enabling this will make the mod check for collisions before opening containers. (To make sure you don't open a barrel that has a plant ontop of it, for example.)\n\n\z
			If disabled, this mod won't check for collisions (you may notice some containers opening when they're \"not supposed to\").\n\n\z
			\z
			Checking for colllision is a bit involved so you may notice a performance bump in some places, but it's relatively unlikely. \z
			Also, each container only checks for collisions once. \z
			(You can change this in the Advanced Settings page.)",
	}

	page:createPercentageSlider {
		configKey = "open_wait_percent",
		label = "Open after %s%% of the animation plays.",
		description = "This setting only takes effect if the \"Show loot menu after animation finishes?\" setting is enabled.\n\n\z
			\z
			This setting will let you specify what percentage of the open animation should play before a container's inventory is shown.\n\n\z
			\z
			If set to 0%%, the menu will open immediatley. If 50%%, the menu will appear after half of the animation plays. \z
			If 100%%, the menu will appear after the animation finishes. (Other percentages are also allowed.)",
	}

	page:createLogLevelOptions { configKey = "log_level" }

	do -- advanced settings
		local advanced = template:createSideBarPage {
			configKey = "advanced",
			label = "Advanced",
			description = "Here you will find advanced settings. These mainly have to do with collision detection.",
		}
		advanced:createTextField {
			configKey = "activate_event_priority",
			restartRequired = true,
			label = "Activate: event priority",
			description = "This setting lets you change the priority of the event that happens when you activate containers.\n\n\z
                If you're experiencing compatibility problems with opening/closing containers when activating them, this setting could help to fix those. Or not.\n\n\z
                This setting also has great potential to mess things up. You've been warned.\n\n\z
                Default value: 301 (because Graphic Herbalism has a priority of 300).",
		}

		do -- collision settings
			local collision = advanced:createCategory {
				configKey = "collision",
				label = "Collision Detection Settings",
				description = "These settings control how the mod detects when objects are ontop of containers. This is still a work in progress and needs some tweaking. \n\n\z
				In the meantime, these settings can be a nice way to fine-tune the collision detection used by this mod.",
			}

			collision:createYesNoButton { configKey = "check" }
			collision:createYesNoButton {
				configKey = "reset_on_load",
				label = "Reset collision information on load/cell change.",
				description = "If enabled, collision information will be reset when loading/changing cells. \z
                        Currently, collision information is only stored if the a container is blocked by an immovable object, or not blocked by any objects. So, not much should change between loads/cell changes.\n\n\z
                        Disabling this setting will mean that container collision information gets reset whenever you load a save/change cells.",
			}
			collision:createSlider {
				configKey = "max_degree",
				label = "Max angle: %%s degrees",
				description = "This setting may be a bit confusing. \z
                        But basically, part of the collision detections involve determining whether objects are actually ontop of containers.\n\n\z
                        This is done by drawing a line from the center of the container to the center of the object being checked. This line should be pointing \"almost\" directly upwards. \z
                        To make sure this line is pointing almost directly upwards, we look at the angle formed by this line and a line pointing directly upwards. This angle shouldn't be too big, and this setting lets you specify how small it has to be.\n\n\z
                        Setting this too high will result in objects next to the container being marked as colliding with the container.\n\z
                        Setting this too low will result in certain objects ontop of the container not being detected (if those objects are too close to the edge of the container).\z
                    ",
				max = 90,
				decimalPlaces = 1,
			}
			-- collision:new_slider{configKey="distance", max=22.1*7, step=22.1,jump=22.1*3, decimalPlaces=1}.convertToLabelValue = dist_label_converter
			collision:createSlider {
				configKey = "max_xy_dist",
				label = "Max xy-distance to use",
				description = "The xy-distance between objects and the center of the container should be less than or equal to this number.\n\n\z
					    (The xy-distance is given by taking the distance only between xy-coordinates, i.e., taking the distance of (x1,y1,0) and (x2,y2,0).)",
				max = 22.1 * 7,
				step = 22.1,
				jump = 22.1 * 3,
				decimalPlaces = 1,
			}.convertToLabelValue = dist_label_converter

			collision:createSlider {
				configKey = "max_z_dist",
				label = "Max z-distance to use",
				description = "The z-distance between objects should be less than this number.",
				max = 200,
				decimalPlaces = 1,
				step = 22.1,
				jump = 22.1 * 3,
			}.convertToLabelValue = dist_label_converter

			collision:createSlider {
				configKey = "initial_raytest_max_dist",
				label = "Initial container raytest max distance",
				description = "Before doing anything else, a ray is fired up from the center of the container to see if anything is directly ontop of it.\n\n\z
                        This setting lets you customize how much distance should be between this object and an object detected above it.",
				max = 22.1 * 2.5,
				decimalPlaces = 2,
				step = 22.1 / 2,
				jump = 22.1,
			}.convertToLabelValue = dist_label_converter

			collision:createSlider {
				configKey = "obj_raytest_max_dist",
				label = "Object raytest max distance",
				description = "After all other tests have passed, a ray is fired down from an object this mod thinks is likely to be ontop of a container. This setting determines the maximum distance of that ray test. \n\n\z
                    Note: The distance is offset by the bounding box of the item being tested, so that this setting behaves more consistently with small/large objects.",
				max = 22.1 * 9,
				decimalPlaces = 1,
				step = 22.1,
				jump = 22.1 * 3,
			}.convertToLabelValue = dist_label_converter

			local bb_settings = collision:createCategory {
				label = "Bounding Box Settings",
				description = "Another part of checking collision is making sure the bounding boxes aren't intersecting. But before doing so, this mod tweaks the bounding box of the container before using it in calculations.\n\n\z
                        This is to accomodate for the container potentially getting bigger as a result of opening, and also so that we can ignore collisions that might happen at the \"bottom\" of the container. \z
                        (If something is too close to the side of a barrel, that won't stop you from opening the barrel.)",
			}
			do -- bounding box settings
				bb_settings:createYesNoButton {
					configKey = "bb_check",
					label = "Check bounding box collision",
					description = "Should bounding boxes be tested for collision?",
				}
				bb_settings:createSlider {
					configKey = "bb_xy_scale",
					label = "xy-scale",
					description = "How much should we scale the x and y coordinates of the bounding box?",
					max = 2,
					decimalPlaces = 2,
					step = 0.01,
					jump = 0.05,
				}
				bb_settings:createSlider {
					configKey = "bb_z_top_scale",
					label = "z-scale",
					description = "How much should we scale the top of the bounding box? This should probably be a bit bigger than 1, \z
                            so we can properly account for the container opening.",
					max = 2,
					decimalPlaces = 2,
					step = 0.01,
					jump = 0.05,
					min = 0.5,
				}
				bb_settings:createPercentageSlider {
					configKey = "bb_z_ignore_bottom_percent",
					label = "Ignore bottom %%s%%%% of box.",
					description = "This setting lets you determine how much of the \"bottom\" part of the bounding box should be ignored. \z
                            This is so that we don't erroneously detect \"collisions\" that might be caused by objects on the floor next to a chest, for example.",
					max = 0.95,
				}
				bb_settings:createSlider {
					configKey = "bb_other_max_diagonal",
					label = "Don't check collision on objects with diagional length bigger than .",
					description = "Objects with really big bounding boxes \"tend\" to be hollow (such as rooms, tents, etc). This setting lets you determine which objects are too big to be checked for.\n\n\z
                            Set to 0 to check collision regardless of bounding box size.",
					max = 1000,
				}
			end
		end
		do -- log settings
			advanced:createLogLevelOptions {
				config = config,
				defaultConfig = default,
				configKey = "log_level",
			}
		end
	end
	-- maybe later

	-- take from the original QuickLoot mod, and very slightly altered
	local function get_containers()
		local added = {}
		for obj in tes3.iterateObjects(tes3.objectType.container) do
			---@diagnostic disable-next-line: undefined-field
			if obj.script ~= nil then
				added[obj.id:lower()] = true
			end
		end
		return table.keys(added, function(a, b)
			return a:lower() < b:lower()
		end
		)
	end


	---@return mwseMCMExclusionsPageFilter[]
	local function make_filters(obj_types)
		obj_types = obj_types or common.obj_types_to_check

		local filters = {} ---@type mwseMCMExclusionsPageFilter[]

		for i, obj_type in ipairs(obj_types) do
			filters[i] = {
				label = table.find(tes3.objectType, obj_type),
				callback = function()
					local added = {}
					for obj in tes3.iterateObjects(obj_type) do
						added[obj.id:lower()] = true
					end
					return table.keys(added, true)
				end
				,
			}
		end
		return filters
	end


	template:createExclusionsPage {
		label = "Blacklist",
		description = "These containers will not be interacted with by this mod whatsoever.",
		leftListLabel = "Banned containers",
		rightListLabel = "Allowed containers",
		variable = mwse.mcm.createTableVariable { id = "blacklist", table = config },
		filters = { { label = "Containers", callback = get_containers } },
	}
	template:createExclusionsPage {
		label = "Collision blacklist",
		description = "These objects will be ignored when checking if a container collides with another object. \z
			Some objects have weird geometry/bounding boxes and make good candidates for being on this list.",
		leftListLabel = "Banned objects",
		rightListLabel = "Allowed objects",
		variable = mwse.mcm.createTableVariable { id = "blacklist", table = config.collision },
		filters = make_filters(),
	}
end
)
