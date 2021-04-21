local config = mwse.loadConfig("CompanionCombatCommunication") or {}
config.talkKey = config.talkKey or {
	keyCode = tes3.scanCode.c,
	isShiftDown = false,
	isAltDown = false,
	isControlDown = false,
}
local function myRayTest()
    local hitResult = tes3.rayTest({ position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector() })
    local hitReference = hitResult and hitResult.reference
    if (hitReference == nil) then
        return
    end
    if (hitReference.mobile) then
        if tes3.getCurrentAIPackageId(hitReference.mobile) ~= tes3.aiPackage.follow then
            tes3.messageBox("No companions in range")
            return
        end
        tes3.runLegacyScript({ reference = hitReference, command = "ForceGreeting" })
    else
       tes3.messageBox("No companions in range")
    end
end
local function keyCheck(e)
    if e.keyCode == config.talkKey.keyCode and not tes3.menuMode() then
        myRayTest()
    end
end
local function onLoaded()
    event.register("keyUp", keyCheck)
end
local function initialized()
    event.register("loaded", onLoaded)
end
event.register("initialized", initialized)
local function registerModConfig()
	local template = mwse.mcm.createTemplate("CompanionCombatCommunication")
	template:saveOnClose("CompanionCombatCommunication", config)
	local page = template:createPage()
	page:createKeyBinder{
		label = "Assign Keybind",
		allowCombinations = true,
		variable = mwse.mcm.createTableVariable{
			id = "talkKey",
			table = config,
			defaultSetting = {
				keyCode = tes3.scanCode.c,
				isShiftDown = false,
				isAltDown = false,
				isControlDown = false,
			}
		}
	}
    mwse.mcm.register(template)
end
event.register("modConfigReady", registerModConfig)