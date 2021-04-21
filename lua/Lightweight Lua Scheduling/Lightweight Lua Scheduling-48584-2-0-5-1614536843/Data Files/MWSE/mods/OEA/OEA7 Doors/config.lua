local defaultConfig = {
	Person =
		true,
	Lock =
		true,
	Crime =
		true,
        Message =
		true,
        Rain =
		true,
	worstWeather = 
		tes3.weather.rain,
	Start =
		20,
	End =
		8,
        IsBlocked = {
		["fargoth"] = true,
		["agronian guy"] = true,
		["balmora, caius cosades' house"] = true,
		["alveleg"] = true,
		["milyn faram"] = true
	},
	Button = {
		keyCode = tes3.scanCode.z
        },
	Timing =
		true
    }
local config = mwse.loadConfig("Lightweight_Lua_Scheduling", defaultConfig)
return config