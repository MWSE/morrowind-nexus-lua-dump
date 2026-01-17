local config = require "herbert100.animated containers.config" ---@type herbert.AC.config
local defns = require "herbert100.animated containers.defns" ---@type herbert.AC.defns
local common = require("herbert100.animated containers.common")
local interop = require("herbert100.animated containers.interop")
local log = mwse.Logger.new()
local i18n = mwse.loadTranslations("herbert100.animated containers")


local this = {}

---@param e activateEventData
function this.activate(e)
	-- tes3.messageBox('OnActivateObject %s', eventData.target.object.id)
	local ref = e.target

	if ref.object.objectType ~= tes3.objectType.container
		or ref:testActionFlag(tes3.actionFlag.useEnabled) == false
		or ref.lockNode and (ref.lockNode.locked or ref.lockNode.trap)
		or config.blacklist[ref.baseObject.id:lower()]
	then
		return
	end

	log("activated %s", ref.object.name)

	if interop._should_skip_next_activation then
		log("skipping because we were told to")
		interop._should_skip_next_activation = false
		return
	end

	local state = interop.get_state(ref)


	log("about to switch on the state (%s) of %s", state, ref)

	-- if the container is closed
	if state == 1 then
		log("container is closed, checking if we can open it.")
		if interop.can_open(ref, false) then
			log("we can open it. about to play open animation.")
			interop.open(ref, config.activate_on_open)
			return false
		end
	else -- the container isn't closd
		-- only continue if we're supposed to do stuff to open containers
		if not config.activate_to_close then
			log("container is open and we're not supposed to close it")
			return
		end
		-- if the container is open, close it
		if state == defns.container_state.open then
			if interop.can_close(ref, false) then
				interop.close(ref)
			end
			-- if the container is opening, mark it as opened
		elseif state == defns.container_state.opening then
			interop.set_state(ref, defns.container_state.open)
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
			if ref.data.CA_bl ~= nil then
				ref.data.CA_bl = nil
				ref.modified = true
			end
		end
		local state = interop.get_state(ref)

		if type(state) == "number" and state >= opening then
			if config.stay_open_between_loads then
				local anim_info = interop.get_animation_info(ref)

				if anim_info then
					tes3.playAnimation { reference = ref, group = anim_info.open_group, startFlag = 1 }
					interop.set_state(ref, defns.container_state.open)
				else
					log:error("container %s had a container state flag but no animation information!", ref)
				end
			else -- clear the state
				interop.set_state(ref, nil)
			end
		end
	end
end

function this.initialize()
	event.register("activate", this.activate, { priority = 301 })

	---@param e cellActivatedEventData
	event.register(tes3.event.cellActivated, function(e)
		this.update_all_containers(e.cell)
	end)

	---@param e cellChangedEventData
	event.register(tes3.event.cellChanged, function(e)
		this.update_all_containers(e.cell)
	end)


	---@param e loadedEventData
	event.register(tes3.event.loaded, function(e)
		this.update_all_containers(tes3.player.cell)
	end)


	common.initialize()
	log:writeInitMessage()
end

event.register(tes3.event.initialized, this.initialize)



return this
