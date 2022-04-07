local seph = require("seph")

local config = seph.Config:new()

config.autoClean = true
config.default = {
	blessingChance = 50
}

return config