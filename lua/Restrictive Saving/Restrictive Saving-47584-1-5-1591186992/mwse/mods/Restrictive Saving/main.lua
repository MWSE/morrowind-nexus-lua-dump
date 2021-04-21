-- Restrictive Saving

local defaultConfig = {
	messages = true,
	hardSave = true,
	autoSave = false,
	quickSave = false,
	day = false,
	noSave = false,
	
	rest = false,
	combat = false,
	enemies = false,
	effects = false,
	health = false,
	fatigue = false,
	encumbered = false,
	weather = false,
	grounded = false,
	transform = false,
	
	bed = false,
}

local config = mwse.loadConfig("Restrictive Saving", defaultConfig)

local bed = false

local function hideSave(e)
	local menu_save_id = tes3ui.registerID("MenuOptions_Save_container")
	local mainMenu = e.element
	if config.hardSave then
		mainMenu:findChild(menu_save_id).visible = false
		mainMenu:updateLayout()
	end
end

local function onUiShowRestMenu(e)
	if config.rest then
		if (e.scripted == true) then
			config.bed = true
		else
			config.bed = false
		end
	end
end

local function onSaved(e)
	local now = tes3.getSimulationTimestamp()
	tes3.player.data.anuLastSaveDate = now
end

local function onSave(e)
	local cell = tes3.getPlayerCell()
	
	if config.quickSave then
		if (e.filename == "quiksave") or (e.filename == "sss_q_" .. os.time(os.date("!*t"))) then
			if config.messages then
				tes3.messageBox({ message = "You cannot quicksave the game" })
				return false
			end
		end
	end
	
	if config.autoSave then
		if (e.filename == "autosave") or (e.filename == "sss_a_" .. os.time(os.date("!*t"))) then
			if config.messages then
				tes3.messageBox({ message = "You cannot autosave the game" })
				return false
			end
		end
	end
	
	if config.day then
		local now = tes3.getSimulationTimestamp()
		local timeSinceLastSave = now - (tes3.player.data.anuLastSaveDate or 0)
		if (timeSinceLastSave <= 24) then
			if config.messages then
				tes3.messageBox("You must wait another %.2f hours before saving again.", 24 - timeSinceLastSave)
			end
			return false
		end
	end
	
	if config.rest then
		if (config.bed == false) then
			if config.messages then
				tes3.messageBox({ message = "You cannot save the game without resting in a bed" })
			end
			config.bed = false
			return false
		end
	end
	
	if config.effects then
		local effect = tes3.mobilePlayer.activeMagicEffectList.first.next
		for _, effect in pairs(tes3.mobilePlayer.activeMagicEffectList) do
			if (effect.harmful == true) then
				if config.messages then
					tes3.messageBox({ message = "You cannot save the game while under a harmful spell effect" })
				end
				return false
			end
		end
	end
	
	if config.weather then
		if cell.region then
			if ( cell.region.weather.index >= 4 ) then
				if config.messages then
					tes3.messageBox({ message = "You must seek shelter to save" })
				end
				return false
			end
		end
	end
	
	if config.combat then
		if tes3.mobilePlayer.inCombat then
			if config.messages then
				tes3.messageBox({ message = "You cannot save the game while in combat" })
			end
			return false
		end
	end
	
	if config.enemies then
		if tes3.mobilePlayer.fight > 0 then
			if config.messages then
				tes3.messageBox({ message = "You cannot save the game while enemies are nearby" })
			end
			return false
		end
	end
	
	if config.encumbered then
		local encumb = tes3.getMobilePlayer().encumbrance
		if (encumb.current > encumb.base) then
			if config.messages then
				tes3.messageBox({ message = "You cannot save the game while encumbered" })
			end
			return false
		end
	end
	
	if config.health then
		local hp = tes3.getMobilePlayer().health
		if (hp.current < hp.base) then
			if config.messages then
				tes3.messageBox({ message = "You cannot save the game while injured" })
			end
			return false
		end
	end
	
	if config.fatigue then
		local fp = tes3.getMobilePlayer().fatigue
		if (fp.current < fp.base) then
			if config.messages then
				tes3.messageBox({ message = "You cannot save the game while fatigued" })
			end
			return false
		end
	end
	
	if config.grounded then
		local flying = tes3.getMobilePlayer().isFlying
		local jumping = tes3.getMobilePlayer().isJumping
		local swimming = tes3.getMobilePlayer().isSwimming
		local underwater = tes3.getMobilePlayer().underwater
		if (flying or jumping or swimming or underwater) then
			if config.messages then
				tes3.messageBox({ message = "You must be grounded to save the game" })
			end
			return false
		end
	end
	
	if config.transform then
		local wolf = tes3.getMobilePlayer().werewolf
		if wolf then
			if config.messages then
				tes3.messageBox({ message = "You cannot save the game as a werewolf" })
			end
			return false
		end
	end
	
	if config.noSave then
		tes3.messageBox({ message = "You cannot save the game" })
		return false
	end
end

local function initialized(e)
	event.register("save", onSave)
	event.register("saved", onSaved)
	event.register("uiShowRestMenu", onUiShowRestMenu)
	event.register("uiActivated", hideSave, { filter = "MenuOptions" })
end
event.register("initialized", initialized)

-- MCM

local function registerMCM()
	local template = mwse.mcm.createTemplate("Restrictive Saving")
	template:saveOnClose("Restrictive Saving", config)
	
	local page = template:createSideBarPage()
	page.label = "Settings"
	page.description = "Restrictive Saving\n\nBy: Anumaril21\n\nRestrictive Saving is a simple, configurable immersion and challenge mod that prevents the player from saving based on a number of optional variables."
	page.noScroll = false
	
	local category = page:createCategory("General Settings")
	
	local messageButton = category:createOnOffButton({
		label = "Enable Messages",
		description = "Determines whether 'cannot sleep' messages are displayed.\n\nDefault: On",
		variable = mwse.mcm:createTableVariable{id = "messages", table = config},
	})
	
	local hardsaveButton = category:createOnOffButton({
		label = "Restrict Hardsaving",
		description = "Determines whether the player is restricted from hard saving by removing access to the save button from the options menu.\n\nDefault: On",
		variable = mwse.mcm:createTableVariable{id = "hardSave", table = config},
	})
	
	local autosaveButton = category:createOnOffButton({
		label = "Restrict Autosaving",
		description = "Determines whether the player is restricted from autosaving the game.\n\nDefault: Off",
		variable = mwse.mcm:createTableVariable{id = "autoSave", table = config},
	})
	
	local quicksaveButton = category:createOnOffButton({
		label = "Restrict Quicksaving",
		description = "Determines whether the player is restricted from quicksaving the game.\n\nDefault: Off",
		variable = mwse.mcm:createTableVariable{id = "quickSave", table = config},
	})
	
	local messageButton = category:createOnOffButton({
		label = "Restrict Saving More Than Once Per Day",
		description = "Determines whether the player is prevented from saving more than once per in-game day.\n\nDefault: Off",
		variable = mwse.mcm:createTableVariable{id = "day", table = config},
	})
	
	local nosaveButton = category:createOnOffButton({
		label = "Restrict All Saving",
		description = "Determines whether the player is prevented from saving at all. This setting is for experienced players or speedrunners looking for a challenge, and is not recommended otherwise.\n\nDefault: Off",
		variable = mwse.mcm:createTableVariable{id = "noSave", table = config},
	})
	
	local category2 = page:createCategory("Situational Settings")
	
	local restButton = category2:createOnOffButton({
		label = "Restrict Saving Unless Resting",
		description = "Determines whether the player must rest in a bed in order to save. Provides a challenge as well as an additional level of immersion.\n\nDefault: Off",
		variable = mwse.mcm:createTableVariable{id = "rest", table = config},
	})
	
	local combatButton = category2:createOnOffButton({
		label = "Restrict Saving in Combat",
		description = "Determines whether the player is prevented from saving while in combat.\n\nDefault: Off",
		variable = mwse.mcm:createTableVariable{id = "combat", table = config},
	})
	
	local enemiesButton = category2:createOnOffButton({
		label = "Restrict Saving While Enemies are Nearby",
		description = "Determines whether the player is prevented from saving while enemies are nearby.\n\nDefault: Off",
		variable = mwse.mcm:createTableVariable{id = "enemies", table = config},
	})
	
	local effectButton = category2:createOnOffButton({
		label = "Restrict Saving Under Harmful Spell Effects",
		description = "Determines whether the player is prevented from saving while under harmful spell effects. This extends to diseases, including Corprus, introducing a challenge and making that portion of the main quest a more harrowing experience.\n\nDefault: Off",
		variable = mwse.mcm:createTableVariable{id = "effects", table = config},
	})
	
	local healthButton = category2:createOnOffButton({
		label = "Restrict Saving While Damaged",
		description = "Determines whether the player is prevented from saving while injured.\n\nDefault: Off",
		variable = mwse.mcm:createTableVariable{id = "health", table = config},
	})
	
	local fatigueButton = category2:createOnOffButton({
		label = "Restrict Saving While Fatigued",
		description = "Determines whether the player is prevented from saving while fatigued.\n\nDefault: Off",
		variable = mwse.mcm:createTableVariable{id = "fatigue", table = config},
	})
	
	local encumberedButton = category2:createOnOffButton({
		label = "Restrict Saving While Encumbered",
		description = "Determines whether the player is prevented from saving while encumbered.\n\nDefault: Off",
		variable = mwse.mcm:createTableVariable{id = "encumbered", table = config},
	})
	
	local weatherButton = category2:createOnOffButton({
		label = "Restrict Saving in Inclement Weather",
		description = "Determines whether the player is prevented from saving in rain, thunder, ash, blight, snow, and blizzard weather types.\n\nDefault: Off",
		variable = mwse.mcm:createTableVariable{id = "weather", table = config},
	})
	
	local groundedButton = category2:createOnOffButton({
		label = "Restrict Saving Unless Grounded",
		description = "Determines whether the player is prevented from saving while flying, jumping, swimming, or underwater.\n\nDefault: Off",
		variable = mwse.mcm:createTableVariable{id = "grounded", table = config},
	})
	
	local transformButton = category2:createOnOffButton({
		label = "Restrict Saving as a Werewolf",
		description = "Determines whether the player is prevented from saving while in werewolf form.\n\nDefault: Off",
		variable = mwse.mcm:createTableVariable{id = "transform", table = config},
	})
	
	mwse.mcm.register(template)
end

event.register("modConfigReady", registerMCM)
	
	