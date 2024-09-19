local logger = require("logging.logger")

local interop = require("zoom.interop")
local config = require("zoom.config").config
local log = logger.new({
	name = "Zoom Spyglass Addon",
	logLevel = config.logLevel,
})


--- @type Zoom.telescopeData[]
local telescopes = {
	-- Tamriel_Data.esm
	{
		id = "T_Com_Spyglass01",
	},
	-- AATL_DATA.esm
	{
		id = "AATL_M_Telescope_C",
	},
	{
		id = "AATL_M_Telescope_P",
	},
	{
		id = "AATL_M_Telescope_R",
	},
	{
		id = "AATL_M_Telescope_Wayfinder",
	}
}

interop.setTelescopeRequired(true)
interop.registerTelescopes(telescopes)
