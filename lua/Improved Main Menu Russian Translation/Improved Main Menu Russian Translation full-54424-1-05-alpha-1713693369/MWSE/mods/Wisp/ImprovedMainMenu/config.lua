local constants = require("Wisp.ImprovedMainMenu.common.constants")
local log       = require("Wisp.ImprovedMainMenu.common.debug").log

local this = {
	configPath = "ImprovedMainMenu",
	defaults = {
		isModEnabled                            = true,
		addon_continueButton_isEnabled          = true,
		addon_continueButton_visibility         = constants.visibilityTypes.always,
		addon_continueConfirmation_isEnabled    = true,
		addon_continueConfirmation_visibility   = constants.visibilityTypes.inGame,
		addon_newGameConfirmation_isEnabled     = true,
		addon_hideNewGameButtonInGame_isEnabled = true,
		addon_hideCreditsButton_isEnabled       = true,
		addon_hideReturnButton_isEnabled        = false,
	    logLevel                                = constants.logLevels.none
	}
}

local loadedConfig = mwse.loadConfig(this.configPath, this.defaults)

this.config = setmetatable(
	{
	    save = function(args)
	    	if not args then args = {} end

	    	local isEventTriggeringRequested = args.triggerUpdateEvent or true

	        mwse.saveConfig(this.configPath, loadedConfig)

	        -- Proadcasting -- 

	        log:info("The new configuration was saved successfully.")

	        --[[
	        	Info: We trigger a configuration update through our custom event as sson as the new
	        	options are saved to the configuration file.
	        ]]--
	        if isEventTriggeringRequested then
	        	event.trigger("ImprovedMainMenu:NewConfigurationSaved")
	        end
	        
	    end,

	    isAddonEnabled = function(addonId)
	    	local key = table.concat({"addon", addonId, "isEnabled"}, "_")

			return loadedConfig[key]
		end,

	},
	{
	    __index = function(_, key)
	        return loadedConfig[key]
	    end,
	    __newindex = function(_, key, value)
	        loadedConfig[key] = value
	    end,
	}
)

return this