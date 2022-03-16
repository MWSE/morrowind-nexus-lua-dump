local constants = require("Wisp.ImprovedMainMenu.common.constants")
local log       = require("Wisp.ImprovedMainMenu.common.debug").log
local helpers   = require("Wisp.ImprovedMainMenu.common.helpers")
local config    = require("Wisp.ImprovedMainMenu.config").config

local runtimeStatus = {
	isModEnabled = false,
	registeredUIElements = {
		mainMenu = {
			id = "MenuOptions",
			e = nil
		},
		continueButton = {
			id = tes3ui.registerID("ImprovedMainMenu:ContinueButton"),
			e  = nil
		},
		newGameButton = {
			id = "MenuOptions_New_container",
			e  = nil
		},
		creditsButton = {
			id = "MenuOptions_Credits_container",
			e  = nil
		},
		returnButton = {
			id = "MenuOptions_Return_container",
			e  = nil
		}
	},
	addons = {
		continueButton = {
			isEnabled = false,
			enable    = nil,
			disable   = nil,
			flags     = {
				mainMenuIsHidden = false
			}
		},
		continueConfirmation = {
			isEnabled = false,
			enable    = nil,
			disable   = nil,
			flags     = {
				stopNextMenuClickSound = false
			}
		},
		newGameConfirmation = {
			isEnabled = false,
			enable    = nil,
			disable   = nil,
			flags     = {
				stopNextMenuClickSound = false
			}
		},
		hideNewGameButtonInGame = {
			isEnabled = false,
			enable    = nil,
			disable   = nil
		},
		hideCreditsButton = {
			isEnabled = false,
			enable    = nil,
			disable   = nil
		},
		hideReturnButton = {
			isEnabled = false,
			enable    = nil,
			disable   = nil
		}
	}
}

-- Forward Definitions --

--[[
	Info: We need to forward define updateConfiguration to be used directly by event handlers when
	we need to update the runtime configuration.
]]--
local updateConfiguration

-- Helpers --

local function showMenuOptions()
	local mainMenuStatus = runtimeStatus.registeredUIElements.mainMenu
	local flags = runtimeStatus.addons.continueButton.flags

	if (not mainMenuStatus.e) or mainMenuStatus.e.visible then return false end

	mainMenuStatus.e.visible = true
	log:debug("Showed the Main Menu.")

	flags.mainMenuIsHidden = false

	return true
end

local function hideMenuOptions()
	local mainMenuStatus = runtimeStatus.registeredUIElements.mainMenu
	local flags = runtimeStatus.addons.continueButton.flags

	if (not mainMenuStatus.e) or (not mainMenuStatus.e.visible) then return false end

	mainMenuStatus.e.visible = false
	log:debug("Hid the Main Menu.")

	flags.mainMenuIsHidden = true

	return true
end

local function makeYesNoPrompt(args)
	if not args then args = {} end
	
	local message = args.message or "Would you like to continue?"
	local onYes   = args.onYes
	local onNo    = args.onNo

	local function handler(e)

		--[[
	        Info: We play Menu Click sound for consistency.
	    ]]--
	    tes3.worldController.menuClickSound:play()

	    --[[
	        Info: We prompt for the user's confirmation in order to foward the event to the original
	        handler.
	    ]]--
	    local messageBox = tes3.messageBox{
	        message = message,
	        buttons = { tes3.findGMST(tes3.gmst.sYes).value, tes3.findGMST(tes3.gmst.sNo).value },
	        callback = function(args)
	            if args.button == 0 then
	            	if onYes then return onYes(e) end
	            else
	            	if onNo then return onNo(e) end
	            end
	        end
	    }

	    --[[
	        Info: We cancel the calls to any subsequent handlers of this event.
	    ]]--
	    return false

	end

	return handler

end

-- Interceptors --

local function onNextMenuClickSound(e)
	local flags = runtimeStatus.addons.newGameConfirmation.flags

	--[[
        Info: If the a stop action has not been requested then we don't perform any changes.
    ]]--
	if not flags.stopNextMenuClickSound then return end

	-- Enabled --

    --[[
        Info: If the current sound is not a Menu Click sound then we don't perform any changes.
    ]]--
    if e.sound ~= tes3.worldController.menuClickSound then return end

    -- Menu Click Sound --

    flags.stopNextMenuClickSound = false

    log:debug("Menu Click sound detected and stopped.")

    return false

end

local function onMenuMessageUIActivation(e)

	local mainMenuStatus = runtimeStatus.registeredUIElements.mainMenu
	local flags = runtimeStatus.addons.continueButton.flags

	if not flags.mainMenuIsHidden then return end

	--[[
		Warning: If any code is run at this point as spam of warning messages appears in the log
		similar to what it would expected if the onContinueButtonClick was called repeatedly. This
		prevents us from showing the Main Menu at this point.
	]]--

	e.element:findChild("MenuMessage_button_layout").children[2]:registerBefore(
		tes3.uiEvent.mouseClick,
		function(e)
			if not showMenuOptions() then
				log:warn("Could not show the Main Menu.")
			end
		end
	)

end

-- Main --

local function onContinueButtonClick(e)
	local mainMenuStatus = runtimeStatus.registeredUIElements.mainMenu
	local continueButtonFlags = runtimeStatus.addons.continueButton.flags
	local continueConfirmationFlags = runtimeStatus.addons.continueConfirmation.flags

	--[[
        Info: If requested, we play Menu Click sound for consistency.
    ]]--
    if not continueConfirmationFlags.stopNextMenuClickSound then
    	tes3.worldController.menuClickSound:play()
    end

    --[[
    	We temporarily hide the Main Menu to prevent it from flashing on the loading screen.
    ]]--
    if not hideMenuOptions() then
		log:warn("Could not hide the Main Menu.")
	end 

    --[[
    	Info: This flag needs to be reset in case the save file is corrupted and the user decides t
    	cancel the loading action in the next prompt.
    ]]--
    continueConfirmationFlags.stopNextMenuClickSound = false

    helpers.loadMostRecentSaveFile()

end

local function addContinueButton()
	local mainMenuStatus = runtimeStatus.registeredUIElements.mainMenu
	local continueButtonStatus = runtimeStatus.registeredUIElements.continueButton
	local continueButtonTextures = constants.assets.textures.continueButton

    -- Main Menu --

    local exitButton = mainMenuStatus.e:findChild("MenuOptions_Exit_container")

    --[[
        Info: If a Exit button is not found then we don't perform any changes.
    ]]--
    if not exitButton then return false end

    local mainMenuButtonsContainer = exitButton.parent

    --[[
    	Warning: The MWSE documentation indicates that the aruments are id, idle, over, and path,
    	but as of the current version this is wrong. Furthermore, it is required to pass named
    	arguments to this function, which is not specified.
    ]]--
    continueButtonStatus.e = mainMenuButtonsContainer:createImageButton{
    	id      = continueButtonStatus.id,
    	idle    = continueButtonTextures.idle,
    	over    = continueButtonTextures.over,
    	pressed = continueButtonTextures.pressed
    }

    -- Continue Button --

    continueButtonStatus.e.height = 50
	continueButtonStatus.e.autoHeight = false

	if not mainMenuButtonsContainer:reorderChildren(1, continueButtonStatus.e, 1) then
		log:error("Failed to re-order Main Menu entries.")
	end

	continueButtonStatus.e:register(tes3.uiEvent.mouseClick, onContinueButtonClick)

	return true
end

local registeredYesNoPrompts = {
	newGame = makeYesNoPrompt{
		message = "Do you want to start a new game?",
		onYes = function(e)
			local flags = runtimeStatus.addons.newGameConfirmation.flags

			--[[
                Info: If the New Game action is confirmed we pass the event to the original
                handler. However, we need to stop the original Menu Click sound from playing.
                The safest way to do that is through a handler for the soundObjectPlay event. 
            ]]--
            flags.stopNextMenuClickSound = true
            return e.source:forwardEvent(e)
		end
	},
	continue = makeYesNoPrompt{
		message = "Do you want to load the most recent save file?",
		onYes = function(e)
			local flags = runtimeStatus.addons.continueConfirmation.flags

			--[[
                Info: If the Continue action is confirmed we pass the event to the original
                handler. However, we need to stop the original Menu Click sound from playing by
                setting the correspoding flag. 
            ]]--
            flags.stopNextMenuClickSound = true
            --[[
            	Warning: forwardEvent doesn't seem to work with custom buttons.
            ]]--
            return onContinueButtonClick(e)
		end
	},
}

local function updateMainMenuComponents()
	local mainMenuStatus = runtimeStatus.registeredUIElements.mainMenu
	local continueButtonStatus = runtimeStatus.registeredUIElements.continueButton
	local newGameButtonStatus = runtimeStatus.registeredUIElements.newGameButton
	local creditsButtonStatus = runtimeStatus.registeredUIElements.creditsButton
	local returnButtonStatus = runtimeStatus.registeredUIElements.returnButton

	local continueButtonFlags = runtimeStatus.addons.continueButton.flags

	-- Addon Updates: Continue Button --

	local isContinueButtonNewlyCreated = false
	local isContinueButtonShown        = false

	if runtimeStatus.addons.continueButton.isEnabled then

		showMenuOptions()

		isContinueButtonShown = (
				config.addon_continueButton_visibility == constants.visibilityTypes.always
				or not helpers.isSimulationAlive()
			) and helpers.getMostRecentSaveFilePath{existential = true}

		if not mainMenuStatus.e:findChild(continueButtonStatus.id) then
			log:debug("Detected and attempted to sync out-of-order updates to the Continue button.")

			if isContinueButtonShown then

				if not addContinueButton() then
					log:error("Failed to sync out-of-order updates to the Continue button.")
				else
					isContinueButtonNewlyCreated = true
				end

			else

				--[[
					Info: If we don't create the Continue button anew, we need to remove its
					reference.
				]]--
				continueButtonStatus.e = nil

			end

		end

		--[[
			Info: We update the Continue button's visibility according to the options and the number
			of available save files.
		]]--
		if continueButtonStatus.e and continueButtonStatus.e.visible ~= isContinueButtonShown then
			if isContinueButtonShown then
				continueButtonStatus.e.visible = true
				log:debug("Showed the Continue button.")
			else
				continueButtonStatus.e.visible = false
				log:debug("Hid the Continue button.")
			end
		end

	end

	-- Addon Updates: Continue Confirmation --

	local isContinuePromptRegistered = false
	local isContinuePromptShown      = false

	if runtimeStatus.addons.continueConfirmation.isEnabled then

		isContinuePromptShown =
			isContinueButtonShown
			and (
			 	config.addon_continueConfirmation_visibility == constants.visibilityTypes.always
				or helpers.isSimulationAlive()
			)

		if isContinuePromptShown then

			if not isContinueButtonNewlyCreated then

				--[[
					Warning: The Main Menu has the tendency to destroy its buttons its time it shows
					up. Therefore, we need to update the handler accordingly.
				]]--
				isContinuePromptRegistered = continueButtonStatus.e:unregisterBefore(tes3.uiEvent.mouseClick, registeredYesNoPrompts.continue)

			end

			continueButtonStatus.e:registerBefore(tes3.uiEvent.mouseClick, registeredYesNoPrompts.continue)
		end
		
		--[[
			Info: If an out-of-order update was detected we make sure to reset the
			stopNextMenuClickSound flag in order to avoid stopping a Menu Click sound
			accidentaly.
		]]--
		if not isContinuePromptRegistered then
			runtimeStatus.addons.continueConfirmation.flags.stopNextMenuClickSound = false
		end

	end

	-- Addon Updates: New Game Confirmation

	local isNewGamePromptRegistered = false

	if runtimeStatus.addons.newGameConfirmation.isEnabled then

		--[[
			Warning: The Main Menu has the tendency to change the handler for its New Game button
			Click event under certain game conditions, e.g., after a game was loaded or after the
			player just died. Therefore, we need to update the handler accordingly.
		]]--
		isNewGamePromptRegistered = newGameButtonStatus.e:unregisterBefore(tes3.uiEvent.mouseClick, registeredYesNoPrompts.newGame)

		--[[
			Info: If an out-of-order update was detected we make sure to reset the
			stopNextMenuClickSound flag in order to avoid stopping a Menu Click sound that we are
			not supposed to handle.
		]]--
		if not isNewGamePromptRegistered then
			runtimeStatus.addons.newGameConfirmation.flags.stopNextMenuClickSound = false
		end

		if not helpers.isSimulationAlive() then
			newGameButtonStatus.e:registerBefore(tes3.uiEvent.mouseClick, registeredYesNoPrompts.newGame)

			if not isNewGamePromptRegistered then
				log:debug("Detected and attempted to sync out-of-order updates to the New Game button.")
			end
		end

	end

	-- Addon Updates: Hide New Game Button --

	if runtimeStatus.addons.hideNewGameButtonInGame.isEnabled then

		if not helpers.isSimulationAlive() then
			if not newGameButtonStatus.e.visible then
				newGameButtonStatus.e.visible = true
				log:debug("Showed the New Game button.")
			end
		else
			if newGameButtonStatus.e.visible then
				newGameButtonStatus.e.visible = false
				log:debug("Hid the New Game button.")
			end
		end
		
	end

	-- Addon Updates: Hide Credits Button --

	if runtimeStatus.addons.hideCreditsButton.isEnabled then

		if creditsButtonStatus.e.visible then
			creditsButtonStatus.e.visible = false
			log:debug("Hid the Credits button.")
		end

	end

	-- Addon Updates: Hide Return Button --

	if runtimeStatus.addons.hideReturnButton.isEnabled then

		if returnButtonStatus.e.visible then
			returnButtonStatus.e.visible = false
			log:debug("Hid the Return button.")
		end

	end

end

-- Event Handlers --

local function onMenuOptionsUIActivated(e)
	local mainMenuStatus = runtimeStatus.registeredUIElements.mainMenu
	local newGameButtonStatus = runtimeStatus.registeredUIElements.newGameButton
	local creditsButtonStatus = runtimeStatus.registeredUIElements.creditsButton
	local returnButtonStatus = runtimeStatus.registeredUIElements.returnButton
	
	-- Initialization --

	local isConfigurationUpdateRequired = not mainMenuStatus.e

	mainMenuStatus.e = e.element

	newGameButtonStatus.e = mainMenuStatus.e:findChild(newGameButtonStatus.id)
	creditsButtonStatus.e = mainMenuStatus.e:findChild(creditsButtonStatus.id)
	returnButtonStatus.e = mainMenuStatus.e:findChild(returnButtonStatus.id)

	--[[
		Warning: The Main Menu is re-created every single time we enter the menu mode, so we can't
		really use the newlyCreated flag.
	]]--
	if isConfigurationUpdateRequired then updateConfiguration() end

	updateMainMenuComponents()
	
end

local function onNewConfigurationSaved()

	updateConfiguration()
	updateMainMenuComponents()

end

-- Configuration --

local function enableMod()
	local mainMenuStatus = runtimeStatus.registeredUIElements.mainMenu

	-- Event Handlers --

	--[[
        Info: We want to make sure we update the Main Menu, a.k.a., MenuOptions, after all its
        components have been initialized.
    ]]--
	event.register(
		tes3.event.uiActivated, onMenuOptionsUIActivated,
		{ filter = mainMenuStatus.id }
	)

	return true
end

local function disableMod()
	local mainMenuStatus = runtimeStatus.registeredUIElements.mainMenu

	-- Event Handlers --

	--[[
		Warning: If onMenuOptionsUIActivated is currently executing we cannot track if the following
		unregistration was successful reliably. The following warning is just indicative.
	]]--
	if not event.unregister(
		tes3.event.uiActivated, onMenuOptionsUIActivated,
		{ filter = mainMenuStatus.id })
	then
		log:warn("Could not unregister onMenuOptionsUIActivated handler.")
	end

	return true
end

function runtimeStatus.addons.continueButton.enable()
	local continueButtonStatus = runtimeStatus.registeredUIElements.continueButton

	-- Event Handlers --

	--[[
		Info we register an interceptor to handle the special case that the most recent file is
		correupted. In that case an addtional message box appears with the options to continue with
		the loading action or to cancel. In the later case we need to make sure that the Main Menu
		is visible again.
	]]--
	event.register(tes3.event.uiActivated, onMenuMessageUIActivation, { filter = "MenuMessage" })

	return true
end

function runtimeStatus.addons.continueButton.disable()
	local continueButtonStatus = runtimeStatus.registeredUIElements.continueButton
	local flags = runtimeStatus.addons.continueButton.flags

	-- UI Elements --

	if not continueButtonStatus.e then return false end

	continueButtonStatus.e:destroy()
	continueButtonStatus.e = nil

	-- Event Handlers --

	if not event.unregister(tes3.event.uiActivated, onMenuMessageUIActivation, { filter = "MenuMessage" }) then
		log:error("Could not unregister onMenuMessageUIActivation handler.")

		return false
	end

	-- Flags --

	flags.mainMenuIsHidden = false

	return true
end

function runtimeStatus.addons.continueConfirmation.disable()
	local continueButtonStatus = runtimeStatus.registeredUIElements.continueButton
	local flags = runtimeStatus.addons.continueConfirmation.flags

	-- UI Elements -

	if continueButtonStatus.e then

		if not continueButtonStatus.e:unregisterBefore(tes3.uiEvent.mouseClick, registeredYesNoPrompts.continue) then
			log:error("Could not unregister registeredYesNoPrompts.continue handler.")

			return false
		end

	end

	-- Flags --

	flags.stopNextMenuClickSound = false

	return true
end

function runtimeStatus.addons.newGameConfirmation.enable()
	local newGameButtonStatus = runtimeStatus.registeredUIElements.newGameButton

	-- Event Handlers --

	--[[
        Warning: We need a high priority for this handler in order to for any subsequent
        handlers to do not be called if the sound is stopped.
    ]]--
	event.register(tes3.event.soundObjectPlay, onNextMenuClickSound, { priority = 100 })

	return true
end

function runtimeStatus.addons.newGameConfirmation.disable()
	local newGameButtonStatus = runtimeStatus.registeredUIElements.newGameButton
	local flags = runtimeStatus.addons.newGameConfirmation.flags

	-- UI Elements -

	if not newGameButtonStatus.e then return false end

	if not newGameButtonStatus.e:unregisterBefore(tes3.uiEvent.mouseClick, registeredYesNoPrompts.newGame) then
		log:warn("Could not unregister registeredYesNoPrompts.newGame handler.")
	end

	-- Event Handlers --

	--[[
		Warning: If onMenuOptionsUIActivated is currently executing we cannot track if the following
		unregistration was successful reliably. The following warning is just indicative.
	]]--
	if not event.unregister(tes3.event.soundObjectPlay, onNextMenuClickSound) then
		log:warn("Could not unregister onNextMenuClickSound handler.")
	end

	-- Flags --

	flags.stopNextMenuClickSound = false

	return true
end

function runtimeStatus.addons.hideNewGameButtonInGame.disable()
	local newGameButtonStatus = runtimeStatus.registeredUIElements.newGameButton

	-- UI Elements --

	if not newGameButtonStatus.e then return false end

	newGameButtonStatus.e.visible = true

	return true
end

function runtimeStatus.addons.hideCreditsButton.disable()
	local creditsButtonStatus = runtimeStatus.registeredUIElements.creditsButton

	-- UI Elements --

	if not creditsButtonStatus.e then return false end

	creditsButtonStatus.e.visible = true

	return true
end

function runtimeStatus.addons.hideReturnButton.disable()
	local returnButtonStatus = runtimeStatus.registeredUIElements.returnButton

	-- UI Elements --

	if not returnButtonStatus.e then return false end

	returnButtonStatus.e.visible = true

	return true
end

function updateConfiguration()
	local mainMenuStatus = runtimeStatus.registeredUIElements.mainMenu

	-- Main Mod --

	log:info("Updating the run-time configuration.")

	if runtimeStatus.isModEnabled ~= config.isModEnabled then
		if runtimeStatus.isModEnabled then
			if disableMod() then
				runtimeStatus.isModEnabled = false
				log:info("Mod Disabled")
			else
				logError("Failed to disable the mod.")
			end
		else
			if enableMod() then
				runtimeStatus.isModEnabled = true
				log:info("Mod Enabled")
			else
				logError("Failed to enable the mod.")
			end
		end
	end

	--[[
		Info: We cannot update the addons until the Main Menu is initialized.
	]]--
	if not mainMenuStatus.e then return end

	-- Addons --

	for addonId, addon in pairs(runtimeStatus.addons) do
		local newAddonState = runtimeStatus.isModEnabled and config.isAddonEnabled(addonId)

		log:debug(string.format(
			"Updating the run-time configuration of the addon %s (Current State: %s | New State: %s).",
			 addonId,
			 addon.isEnabled,
			 newAddonState
		))

		if addon.isEnabled ~= newAddonState then
			if addon.isEnabled then
				if (not addon.disable) or addon.disable() then
					addon.isEnabled = false
					log:info(string.format("Disabled %s Addon", addonId))
				else
					log:error(string.format("Failed to disable addon %s.", addonId))
				end
			else
				if (not addon.enable) or addon.enable() then
					addon.isEnabled = true
					log:info(string.format("Enabled %s Addon", addonId))
				else
					log:error(string.format("Failed to enable addon %s.", addonId))
				end
			end
		end

	end

	mainMenuStatus.e:updateLayout()

end

-- Initialization --

local function onInitialized(e)

	-- Logger --

	log:setLogLevel(config.logLevel)

	-- Main --
  
    updateConfiguration()

    log:info("Mod Initialized")

end

event.register(tes3.event.initialized, onInitialized)
event.register("ImprovedMainMenu:NewConfigurationSaved", onNewConfigurationSaved)

require("Wisp.ImprovedMainMenu.mcm")

