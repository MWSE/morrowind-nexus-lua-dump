local modPath = "shiftGoodbye"
local defaultConfig = {
	enabled = true,
	scanCode = { keyCode = tes3.scanCode.lShift, isShiftDown = true, isAltDown = false, isControlDown = false },
}
local config = mwse.loadConfig(modPath, defaultConfig)

local function shiftGoodbye()
	local menu = tes3ui.findMenu("MenuDialog")
	if not menu then
		return
	end

	local block = menu:findChild("MenuDialog_answer_block")
	if not block then
		return
	end

	local choice = false
	for _, child in pairs(block.parent.children) do
		if child.name == "MenuDialog_answer_block" then
			choice = true
			break
		end
	end

	local buttonBye = menu:findChild("MenuDialog_button_bye")
	if not buttonBye then
		return
	end
	buttonBye:registerBefore("mouseClick", function(e)
        if (not config.enabled) then
            return
        end
		if not choice then
			return
		end
		if tes3.worldController.inputController:isKeyDown(config.scanCode.keyCode) then
			tes3.closeDialogueMenu({})
		end
	end)
end
event.register("postInfoResponse", shiftGoodbye)

local function registerModConfig()
	local template = mwse.mcm.createTemplate("Force Close Dialogue Menu")
	template:saveOnClose(modPath, config)

	local page = template:createPage()

	local settings = page:createCategory("Settings")
	settings:createYesNoButton({
		label = "Enable Mod",
		variable = mwse.mcm.createTableVariable({ id = "enabled", table = config }),
	})
	settings:createKeyBinder{
		label = "Assign Force Goodbye Hotkey (Default: Left Shift)",
		allowCombinations = false,
		variable = mwse.mcm.createTableVariable { id = "scanCode", table = config },
	}

	mwse.mcm.register(template)
end
event.register("modConfigReady", registerModConfig)
