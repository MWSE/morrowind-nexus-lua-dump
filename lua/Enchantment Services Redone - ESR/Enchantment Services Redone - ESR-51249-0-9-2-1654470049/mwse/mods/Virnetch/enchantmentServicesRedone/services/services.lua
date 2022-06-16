
local common = require("Virnetch.enchantmentServicesRedone.common")


--- @class esrService
--- @field id string
--- @field name string
--- @field description string
--- @field config table The service's config table
--- @field insertAfter number? Optional. Id of the ui element to insert this service after
--- @field requirements function Returns true if the object offers the service.
--- @field callback function Called when the player clicks on the service button.

--- @type table<string, esrService>
local services = {}


-- Require all "service.lua" files in subdirectories in the services folder
local servicesDir = "Data Files\\MWSE\\mods\\Virnetch\\enchantmentServicesRedone\\services"
for entry in lfs.dir(servicesDir) do
	if entry ~= "." and entry ~= ".." then
		local attributes = lfs.attributes(servicesDir.."\\"..entry)
		if attributes.mode == "directory" then	--- @diagnostic disable-line: undefined-field
			services[entry] = require("Virnetch.enchantmentServicesRedone.services."..entry..".service")
		end
	end
end

-- To keep the service buttons visible after the menu updates
local function setServiceButtonVisibilitiesToTrue()
	local menu = tes3ui.findMenu(common.GUI_ID.MenuDialog)
	if not menu then return end

	for _, service in pairs(services) do
		local GUI_ID_MenuDialog_NewService = tes3ui.registerID("MenuDialog_service_vir_"..service.id)
		local serviceButton = menu:findChild(GUI_ID_MenuDialog_NewService)
		if serviceButton and not serviceButton.visible then
			serviceButton.visible = true
		end
	end
end
event.register(tes3.event.uiEvent, setServiceButtonVisibilitiesToTrue)

--- @param e uiActivatedEventData
local function onMenuDialogActivated(e)
	local actor = tes3ui.getServiceActor()
	local actorRef = actor.reference

	local topicsScrollPane = e.element:findChild(common.GUI_ID.MenuDialog_TopicList)
	local divider = topicsScrollPane:findChild(common.GUI_ID.MenuDialog_Divider)
	local topicsList = divider.parent

	-- Need to update the visibility once after the menu is updated for the
	-- first time, after that, we update the visibility on each "uiEvent" event.
	local updatedOnce = false
	local function updateOnce()
		-- e.element:unregisterAfter(tes3.uiEvent.update, updateOnce)
		-- Using unregisterAfter would cause the game to crash if there is still a lower priority callback registered.
		if updatedOnce then return end
		updatedOnce = true

		setServiceButtonVisibilitiesToTrue()
	end
	e.element:registerAfter(tes3.uiEvent.update, updateOnce)

	-- Add the service buttons
	for _, service in pairs(services) do
		if (
			service.config.enableService ~= false
			and service.config.enable ~= false
		) then
			-- Check if npc offers the service
			if service.requirements(actorRef.object) then
				common.log:debug("Adding service %s to %s", service.name, actorRef.id)

				-- Create the new button
				local GUI_ID_MenuDialog_NewService = tes3ui.registerID("MenuDialog_service_vir_"..service.id)
				local button = topicsList:createTextSelect({ id = GUI_ID_MenuDialog_NewService, text = service.name })

				-- Move the button
				local insertAfter = service.insertAfter and topicsList:findChild(service.insertAfter)
				if insertAfter then
					-- First insert the button before insertAfter, then move insertAfter before it
					topicsList:reorderChildren(insertAfter, button, 1)
					topicsList:reorderChildren(button, insertAfter, 1)
				else
					-- By default move it above the divider, into the services section
					topicsList:reorderChildren(divider, button, 1)
				end

				button:register(tes3.uiEvent.mouseClick, function()
					service.callback({
						reference = actorRef,
						topicsList = topicsList
					})
				end)

				-- Add a tooltip
				if common.config.showTooltips and service.description then
					button:register(tes3.uiEvent.help, function()
						common.tooltip(service.description, true)
					end)
				end
			end
		end
	end
end
event.register(tes3.event.uiActivated, onMenuDialogActivated, { filter = "MenuDialog", priority = -100 } )

return services