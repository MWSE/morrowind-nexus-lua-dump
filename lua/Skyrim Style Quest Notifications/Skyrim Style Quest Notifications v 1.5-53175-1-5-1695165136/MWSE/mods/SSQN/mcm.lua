local config = require("SSQN.config")
local common = require("SSQN.common")
-- When the mod config menu is ready to start accepting registrations, 
-- register this mod.
local function registerModConfig()
    -- Create the top level component Template
    -- The name will be displayed in the mod list on the lefthand pane
    local template = mwse.mcm.createTemplate({ name = "Skyrim Style Quest Notifications"})

    -- Save config options when the mod config menu is closed
    template:saveOnClose("SSQN", config)

    -- Create a simple container Page under Template
    local preferences = template:createSideBarPage({ label = "Preferences" })
	preferences.sidebar:createInfo({
		text = "Skyrim Style Quest Notifications\nby Nazz \n\nThis mod notifies you when you start or finish a quest. The idea is to mimic the quest notifications from Skyrim, hence the name. None of the settings should require restarting Morrowind"
	})

    -- Create a button under Page that toggles a variable between true and false
    preferences:createOnOffButton({
        label = "Enable Start Quest Notifications",
        description = "Turns the notifications you receive for starting a quest on or off. Turning this and the Finish notifcation off effectively disables the mod.\n\nDefault: On",
        variable = mwse.mcm:createTableVariable({ id = "SSQNSenabled", table = config }),
    })

	-- Create a button under Page that toggles a variable between true and false
	preferences:createOnOffButton({
		label = "Enable Finish Quest Notifications",
		description = "Turns the notifications you receive for finishing a quest on or off. Turning this and the Start notifcation off effectively disables the mod.\n\nDefault: On",
		variable = mwse.mcm:createTableVariable({ id = "SSQNFenabled", table = config }),
	})

    preferences:createOnOffButton({
		label = "Notification Icon On/Off",
		description = "Turns notification icons on or off \n\nDefault: On",
		variable = mwse.mcm:createTableVariable({ id = "imageonoff", table = config }),
	})

    preferences:createDropdown({
		label = "Notification Sound",
		description = "Select the sound to be played when the notification appears. Selecting None silences the notification\n\nDefault: Skyrim Quest",
		options = {
			{ label = "Skyrim Quest", value = "\\SSQN\\quest_update.wav" },
			{ label = "6th House Chime", value = "\\Fx\\envrn\\bell2.wav" },
			{ label = "Skill Raise", value = "\\Fx\\inter\\levelUP.wav"},
			{ label = "Magic Effect", value = "\\Fx\\magic\\mystA.wav"},
			{ label = "Oblivion Quest", value = "\\SSQN\\ob_quest.wav"},
			{ label = "Cliff Racer", value = "\\Cr\\cliffr\\scrm.wav"},
			{ label = "None", value = "NONE" },
		},
		variable = mwse.mcm:createTableVariable({ id = "soundfile", table = config }),
	})

	preferences:createSlider({
		label = "Horizontal Notification Location",
		description = "Where the notification will be displayed on the horizontal axis\n\n0 = Far Left of Screen\n\n50 = Middle of Screen\n\n100 = Far Right of Screen\n\nDefault = 50",
		min = 0,
		max = 100,
		step = 5,
		jump = 15,
		variable = mwse.mcm:createTableVariable({ id = "xlocation", table = config }),
	})

	preferences:createSlider({
		label = "Vertical Notification Location",
		description = "Where the notificaiton will be displayed on the vertical axis\n\n0 = Top of Screen\n\n50 = Middle of Screen\n\n100 = Bottom of Screen\n\nDefault = 10",
		min = 0,
		max = 100,
		step = 5,
		jump = 15,
		variable = mwse.mcm:createTableVariable({ id = "ylocation", table = config }),
	})

	preferences:createDropdown{
		label = "Logging Level",
		description = "Set the MWSE log level for this mod. Change requires a restart\n\nDefault = NONE.",
		options = {
			{ label = "TRACE", value = "TRACE" },
			{ label = "DEBUG", value = "DEBUG" },
			{ label = "INFO", value = "INFO" },
			{ label = "WARN", value = "WARN" },
			{ label = "ERROR", value = "ERROR" },
			{ label = "NONE", value = "NONE" },
		},
		variable = mwse.mcm.createTableVariable{ id = "logLevel", table = config },
		callback = function(self)
			common.log:setLogLevel(self.variable.value)
		end
	}

    -- Finish up.
    template:register()
end

event.register("modConfigReady", registerModConfig)