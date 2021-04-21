local defaultConfig = {
	tooltip =
		1,
	OldMult =
		"3",
	Hand =
		true,
	Break =
		false,
	DegMult =
		10,
	MinChance =
		5,
	MaxChance =
		10,
	ConstChance =
		50,
	MaxItems =
		5
    }
local config = mwse.loadConfig("Lua_Lockbashing", defaultConfig)
return config