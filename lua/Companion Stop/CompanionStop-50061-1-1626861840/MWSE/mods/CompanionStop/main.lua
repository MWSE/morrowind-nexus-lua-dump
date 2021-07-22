local config = mwse.loadConfig("CompanionStop") or {}
config.stopKey = config.stopKey or {
	keyCode = tes3.scanCode.v,
	isShiftDown = false,
	isAltDown = false,
	isControlDown = false,
}

local function stopFollow()
    for follower in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
        tes3.setAIWander({
			reference = follower,
			range = 0,
			idles = {0,0,0,0,0,0,0,0,0}
			})
    end
end
local function keyCheck(e)
    if e.keyCode == config.stopKey.keyCode and not tes3.menuMode() then
        stopFollow()
    end
end
local function onLoaded()
    event.register("keyUp", keyCheck)
end
event.register("loaded", onLoaded)

---------MCM---------
local function registerModConfig()
	local template = mwse.mcm.createTemplate("CompanionStop")
	template:saveOnClose("CompanionStop", config)
	local page = template:createPage()
	page:createKeyBinder{
		label = "Assign Keybind",
		allowCombinations = true,
		variable = mwse.mcm.createTableVariable{
			id = "stopKey",
			table = config,
			defaultSetting = {
				keyCode = tes3.scanCode.v,
				isShiftDown = false,
				isAltDown = false,
				isControlDown = false,
			}
		}
	}
    mwse.mcm.register(template)
end
event.register("modConfigReady", registerModConfig)