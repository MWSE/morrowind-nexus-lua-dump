-- The Art of Archery by JosephMcKean
local mod = "The Art of Archery"

local logging = require("JosephMcKean.archery.logging")
local log = logging.createLogger("main")

-- Initializing our mod
event.register(tes3.event.initialized, function()
	require("JosephMcKean.archery.events")
	log:info("Initialized!")
end)

require("JosephMcKean.archery.mcm")
