local this = {}

-- Debug --

--[[
	Info: The types of debug messages and their severity levels.
]]--
this.msgTypes = {
	error     = { severityLevel = 1, label = "Error" },
	warning   = { severityLevel = 2, label = "Warning" },
	info      = { severityLevel = 3, label = "Info" },
	debugInfo = { severityLevel = 4, label = "Debug Info" }
}

this.logLevels = {
	trace = "TRACE",
	debug = "DEBUG",
	info  = "INFO",
	error = "ERROR",
	none  = "NONE"
}

-- Assets --

this.assets = {
	textures = {
		continueButton = {
			idle    = "Textures/menu_continue.dds",
			over    = "Textures/menu_continue_over.dds",
			pressed = "Textures/menu_continue_pressed.dds"
		}
	}
}

-- Options --

this.visibilityTypes = {
	never     = 0,
	inGame    = 1,
	notInGame = 2,
	always    = 3
}

return this