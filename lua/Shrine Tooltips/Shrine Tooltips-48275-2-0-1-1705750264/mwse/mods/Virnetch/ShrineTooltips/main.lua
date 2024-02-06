
local common = require("Virnetch.ShrineTooltips.common")

if mwse.buildDate == nil or mwse.buildDate < 20220511 then
    common.log:error("Build date of %s does not meet minimum build date of 20220511.", mwse.buildDate)
	event.register(tes3.event.initialized, function()
		tes3.messageBox(common.i18n("mod.updateRequired"))
	end)
    return
end

event.register(tes3.event.modConfigReady, function()
	require("Virnetch.ShrineTooltips.mcm")
end)

--- @param e uiActivatedEventData
local function onMenuMessage(e)
	-- Return if not in-game
	if not tes3.player then return end
	if tes3.dataHandler.nonDynamicData.isSavingOrLoading then return end

	-- Return if player didn't activate a shrine this frame
	if not common.activatingShrine then
		common.log:debug("Player didn't activate a shrine this frame, returning")
		return
	end

	-- Get the button layout from the menu
	local buttonLayout = e.element:findChild(common.GUI_ID.MenuMessage_button_layout)
	if not buttonLayout then
		common.log:debug("Message missing buttonLayout, returning")
		return
	end

	for _, button in pairs(buttonLayout.children) do
		if button.text then
			local id = common.effects[string.gsub(button.text, "%W", ""):lower()]	-- Remove all non-alphanumeric characters, lowercase
			if id then
				local spell = tes3.getObject(id)
				if spell and spell.objectType == tes3.objectType.spell then
					common.addSpellTooltipToElement(button, spell)
				end
			end
		end
	end
end

--- @param e activateEventData
local function onActivate(e)
	-- Check if it was activated by the player
	if e.activator and e.activator == tes3.player then
		-- Get the script on the activated object
		local script = e.target and e.target.object and e.target.object.script
		if not script then return end

		-- Check if the script on the activated object is one of the shrine scripts
		if not common.config.shrineScripts[script.id] then return end

		-- Set this to true for one frame so we know that the player activated a shrine when the message box was shown
		common.log:debug("Player activated shrine with script %s", script.id)
		common.activatingShrine = true
		-- Needs three frames of delay due to the confirmation message box...
		timer.delayOneFrame(function()
			timer.delayOneFrame(function()
				timer.delayOneFrame(function()
					common.log:debug("Player no longer activating shrine with script %s", script.id)
					common.activatingShrine = false
				end)
			end)
		end)
	end
end


local function initialized()
	if not common.config.modEnabled then
		common.log:info("Disabled")
		return
	end

	for blessingId in pairs(common.config.blessingIds) do
		local spell = tes3.getObject(blessingId)
		if spell then
			-- Remove all non-alphanumeric characters, lowercase
			local name = string.gsub(spell.name, "%W", ""):lower()
			if name then
				common.log:debug("Blessing id: %s name: %s", blessingId, name)
				common.effects[name] = blessingId
			end
		end
	end

	event.register(tes3.event.uiActivated, onMenuMessage, { filter = "MenuMessage" })
	event.register(tes3.event.activate, onActivate, { priority = -1000 })

	common.log:info("Initialized")
end
event.register(tes3.event.initialized, initialized)