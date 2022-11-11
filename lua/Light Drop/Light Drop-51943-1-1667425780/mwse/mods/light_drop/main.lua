
local defaultHotkey = {["keyCode"] = tes3.scanCode.g, ["isShiftDown"] = false, ["isControlDown"] = false, ["isAltDown"] = false}


---------------- MCM --------------------------------

local function modConfigReadyCallback()

	EasyMCM = require("easyMCM.EasyMCM")
	local template = EasyMCM.createTemplate("Light Drop")
	local page = template:createPage()
	
	page:createKeyBinder{
		label = "Light Drop Hotkey",
		allowCombinations = true,
		variable = EasyMCM.createPlayerData{
								id = "hotkey",
								path = "light_drop",
								defaultSetting = {keyCode = defaultHotkey.keyCode}
							},
		getLetter = function(self, keyCode)
						for letter, code in pairs(tes3.scanCode) do
							if code == keyCode then
								return string.upper(letter)
							end
						end 
						return nil
					end
	}
	
	template:register()
	
end

event.register("modConfigReady", modConfigReadyCallback)

---------------- MCM --------------------------------


local function keyDownCallback(e)

	if (tes3.menuMode()) then return end
	if (not tes3.player) then return end
	
	local hotkey
	
	if (tes3.player.data.light_drop and tes3.player.data.light_drop.hotkey) then
		hotkey = tes3.player.data.light_drop.hotkey
	else
		hotkey = defaultHotkey
	end
	
	if (not (e.keyCode == hotkey.keyCode)) then return end
	if (not (e.isShiftDown == hotkey.isShiftDown)) then return end
	if (not (e.isControlDown == hotkey.isControlDown)) then return end
	if (not (e.isAltDown == hotkey.isAltDown)) then return end

	local equippedLightStack = tes3.getEquippedItem({actor = tes3.player, objectType = tes3.objectType.light})
	if (equippedLightStack) then
		tes3.dropItem({reference = tes3.player, item = equippedLightStack.object})
	end
	
end
	
local function initializedCallback()
    event.register("keyDown", keyDownCallback)
end

event.register(tes3.event.initialized, initializedCallback)