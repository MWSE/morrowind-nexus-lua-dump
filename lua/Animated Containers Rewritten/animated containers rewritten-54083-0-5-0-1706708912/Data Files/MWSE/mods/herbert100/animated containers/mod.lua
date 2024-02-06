local config = require "herbert100.animated containers.config" ---@type herbert.AC.config
local defns = require "herbert100.animated containers.defns" ---@type herbert.AC.defns
local common = require("herbert100.animated containers.common")
local log = require("herbert100.Logger").new(defns) .. "main" ---@type herbert.Logger
local pk = defns.persistent_data_keys
local i18n = mwse.loadTranslations("herbert100.animated containers")


local Container = require("herbert100.animated containers.Container") ---@type herbert.AC.Container

local this = {}

---@param e activateEventData
function this.activate(e)
	log("activated %s", e.target.object.name)
	-- tes3.messageBox('OnActivateObject %s', eventData.target.object.id)
	local ref = e.target

	if ref.object.objectType ~= tes3.objectType.container 
	or ref:testActionFlag(tes3.actionFlag.useEnabled) == false
	or ref.lockNode and (ref.lockNode.locked or ref.lockNode.trap)
	then return end

	-- constructor will check the blacklists
	local container = Container.new(ref)
	if not container then
		log("container for %s couldn't be made properly: %s", ref)
		
	end

	local state = container.state
	-- this isn't set when problems happen during object creation.

	
	log("about to check state of %s", container)

	-- if the container is closed
	if state == 1 then
		-- see if it can be opened, and then open it
		log("container is closed, checking if we can open it.")
		if container:can_open() then
			log("we can open it. about to play open animation.")
			container:open(config.activate_on_open)
			return false -- prevent activation
		end
	else -- the container isn't open

		-- only continue if we're supposed to do stuff to open containers
		if not config.activate_to_close then
			log("container is open and we're not supposed to close it")
			return 
		end
		-- if the container is open, close it
		if state == defns.container_state.open then 
			container:close()
		-- if the container is opening, mark it as opened
		elseif state ==  defns.container_state.opening then 
			container:set_state(defns.container_state.open)
		end
		return false -- block the activation
	end
end



--- makes sure any containers marked as opened are actually opened
---@param cell tes3cell
function this.update_all_containers(cell)
	log:trace("updating all containers")
	local opening = defns.container_state.opening
	local do_reset = config.collision.reset_on_load
	for ref in cell:iterateReferences(tes3.objectType.container) do
		if do_reset then
			-- checking that it was set so we dont mark every container as modified
			if ref.data[pk.blocked_by_immovable] ~= nil then	
				ref.data[pk.blocked_by_immovable] = nil
				ref.modified = true
			end
		end
		local state = ref.data[pk.container_state]

		if type(state) == "number" and state >= opening then
			if config.stay_open_between_loads then
				local anim_info = common.get_animation(ref)

				if anim_info then
					tes3.playAnimation{reference = ref, group = anim_info.open_group, startFlag = 1}
				else
					log:error("container %s had a container state flag but no animation information!", ref)
				end

			else -- clear the state


				if ref.data[pk.container_state] ~= nil then
					ref.data[pk.container_state] = nil
					ref.modified = true
				end
			end
		end
	end
end


function this.initialize()

	event.register("activate", this.activate, {priority = 301})

	---@param e cellActivatedEventData
	event.register(tes3.event.cellActivated, function (e)
		this.update_all_containers(e.cell)
	end)

	---@param e cellChangedEventData
	event.register(tes3.event.cellChanged, function (e)
		this.update_all_containers(e.cell)
	end)


	---@param e loadedEventData
	event.register(tes3.event.loaded, function (e)
		this.update_all_containers(tes3.player.cell)
	end)


	common.initialize()
	log:info("mod initialized")
end


event.register(tes3.event.initialized, this.initialize)



-- =============================================================================
-- MCM
-- =============================================================================

event.register("modConfigReady",function ()

	local MCM = require("herbert100.MCM").new{mod_name=defns.mod_name, config=config, i18n = i18n}

	MCM:register()

	local page = MCM:new_sidebar_page{id="main_page"}

	for _, id in ipairs{"activate_on_open", "auto_close", "stay_open_between_loads", "play_sound", "activate_to_close"} do
		page:new_button{id=id}
	end
	page:new_button{id="check", config=config.collision, label = i18n("MCM.advanced.collision.check.label"),
		desc = i18n("MCM.advanced.collision.check.desc")
	}
	
	page:new_pslider{id="open_wait_percent"}

	page:add_log_settings()

	do -- advanced settings
		local advanced = MCM:new_sidebar_page{id="advanced"}

		advanced:new_textfield{id="activate_event_priority", restart=true, }

		do -- collision settings 
			local collision = advanced:new_category{id="collision", config=config.collision}
			
			collision:new_button{id="check", }
			collision:new_button{id="reset_on_load"}
			collision:new_dslider{id="max_degree", max=90, dp=1, }
			collision:new_dslider{id="max_xy_dist", max=150, dp=1, }
			collision:new_dslider{id="max_z_dist", max=200, dp=1, }
			collision:new_dslider{id="initial_raytest_max_dist", max=50, dp=1, }
			collision:new_dslider{id="obj_raytest_max_dist", max=200, dp=1, }

			local bb_settings = collision:new_category{id = "bounding_box"}
			do -- bounding box settings
				bb_settings:new_button{id="bb_check"}
				bb_settings:new_dslider{id="bb_xy_scale", max=2, dp=3, step = 0.01, jump = 0.05, }
				bb_settings:new_dslider{id="bb_z_top_scale",  max=2, dp=3, step = 0.01, jump = 0.05, min=0.5, }
				bb_settings:new_pslider{id="bb_z_ignore_bottom_percent", max=0.95, }
				bb_settings:new_slider{id="bb_other_max_diagonal", max = 1000, }
			end
		end
		do -- log settings
			local log_settings = advanced:new_category{id="log", config=config.log_settings, }
			log:add_to_MCM{component=log_settings.component, config=config}


			log_settings:new_button{id="log_replace_table"}
			log_settings:new_button{id="log_every_replacement"}
			log_settings:new_button{id="log_add_interop_data"}
		end
	end
	-- maybe later
	-- MCM.template:createExclusionsPage{label="Blacklist",filters={options={}}}


	 -- take from the original QuickLoot mod, and very slightly altered
	 local function get_containers()
		local added = {}
		for obj in tes3.iterateObjects(tes3.objectType.container) do
			---@diagnostic disable-next-line: undefined-field
			if obj.script ~= nil then
				added[obj.id:lower()] = true
			end
		end
		return table.keys(added, function(a,b) return a:lower() < b:lower() end)
	end

	---@return mwseMCMExclusionsPageFilter[]
	local function make_filters(obj_types)
		obj_types = obj_types or common.obj_types_to_check

		local filters = {} ---@type mwseMCMExclusionsPageFilter[]

		for i, obj_type in ipairs(obj_types) do
			
			filters[i] = {label = table.find(tes3.objectType, obj_type), callback = function()

				local added = {}
				for obj in tes3.iterateObjects(obj_type) do
					added[obj.id:lower()] = true
				end
				return table.keys(added, true)

			end}

		end
		return filters
	end

	MCM.template:createExclusionsPage{
		label = "Blacklist",
		description = "These containers will not be interacted with by this mod whatsoever.",
		leftListLabel = "Banned containers",
		rightListLabel = "Allowed containers",
		variable = mwse.mcm.createTableVariable{ id = "blacklist", table = config, },
		filters = { {label="Containers", callback = get_containers}, },
	}
	MCM.template:createExclusionsPage{
		label = "Collision blacklist",
		description = "These objects will be ignored when checking if a container collides with another object. \z
			Some objects have weird geometry/bounding boxes and make good candidates for being on this list.",
		leftListLabel = "Banned objects",
		rightListLabel = "Allowed objects",
		variable = mwse.mcm.createTableVariable{ id = "blacklist", table = config.collision, },
		filters = make_filters(),
	}
end)

return this