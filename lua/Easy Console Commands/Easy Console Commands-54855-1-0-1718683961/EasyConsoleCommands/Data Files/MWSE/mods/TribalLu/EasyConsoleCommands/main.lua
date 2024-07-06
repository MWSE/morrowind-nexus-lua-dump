local mod = {
    name = "Easy Console Commands",
    config = "Easy Console Commands Config",
    ver = "1.0",
    author = "TribalLu",
            }
local configDefault = {
	enabled = true,
	hotkey = 199,
	hotkey2 = 211,
	hotkey3 = 209,
}

local config = mwse.loadConfig(mod.config, configDefault)

if not config then
    config = { blocked = {} }
end

local keybindButton
local keybindButton2
local keybindButton3
local enableButton

local function easyResetActor(e)
	local executed = mwscript.stopScript({ script = "trib_reset_easyRA_script" })
	local executed = mwscript.startScript({ script = "trib_easyRA_script" })
end

local function undoeasyResetActor(e)
	local executed = mwscript.stopScript({ script = "trib_easyRA_script" })
	local executed = mwscript.startScript({ script = "trib_reset_easyRA_script" })
end

local function easyToggleCollision(e)
	local executed = mwscript.stopScript({ script = "trib_reset_easyTCL_script" })
	local executed = mwscript.startScript({ script = "trib_easyTCL_script" })
end

local function undoeasyToggleCollision(e)
	local executed = mwscript.stopScript({ script = "trib_easyTCL_script" })
	local executed = mwscript.startScript({ script = "trib_reset_easyTCL_script" })
end

local function easyToggleMenus(e)
	local executed = mwscript.stopScript({ script = "trib_reset_easyTM_script" })
	local executed = mwscript.startScript({ script = "trib_easyTM_script" })
end

local function undoeasyToggleMenus(e)
	local executed = mwscript.stopScript({ script = "trib_easyTM_script" })
	local executed = mwscript.startScript({ script = "trib_reset_easyTM_script" })
end

local function assignHotkey(e)
	event.unregister(tes3.event.keyDown, easyResetActor, { filter = config.hotkey } )
	event.unregister(tes3.event.keyUp, undoeasyResetActor, { filter = config.hotkey } )
	config.hotkey = e.keyCode

	if ( config.enabled ) then
		event.register(tes3.event.keyDown, easyResetActor, { filter = config.hotkey } )
		event.register(tes3.event.keyUp, undoeasyResetActor, { filter = config.hotkey } )
	end
	local buttonName = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey).value
	tes3.messageBox('ResetActor hotkey is now "%s"', buttonName);
	keybindButton.buttonText = buttonName
	event.unregister(tes3.event.keyDown, assignHotkey)
	keybindButton:setText(buttonName)
end

local function assignHotkey2(e)
	event.unregister(tes3.event.keyDown, easyToggleCollision, { filter = config.hotkey2 } )
	event.unregister(tes3.event.keyUp, undoeasyToggleCollision, { filter = config.hotkey2 } )
	config.hotkey2 = e.keyCode

	if ( config.enabled ) then
		event.register(tes3.event.keyDown, easyToggleCollision, { filter = config.hotkey2 } )
		event.register(tes3.event.keyUp, undoeasyToggleCollision, { filter = config.hotkey2 } )
	end
	local buttonName2 = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey2).value
	tes3.messageBox('ToggleCollision hotkey is now "%s"', buttonName2);
	keybindButton2.buttonText = buttonName2
	event.unregister(tes3.event.keyDown, assignHotkey2)
	keybindButton2:setText(buttonName2)
end

local function assignHotkey3(e)
	event.unregister(tes3.event.keyDown, easyToggleMenus, { filter = config.hotkey3 } )
	event.unregister(tes3.event.keyUp, undoeasyToggleMenus, { filter = config.hotkey3 } )
	config.hotkey3 = e.keyCode

	if ( config.enabled ) then
		event.register(tes3.event.keyDown, easyToggleMenus, { filter = config.hotkey3 } )
		event.register(tes3.event.keyUp, undoeasyToggleMenus, { filter = config.hotkey3 } )
	end
	local buttonName3 = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey3).value
	tes3.messageBox('ToggleMenus hotkey is now "%s"', buttonName3);
	keybindButton3.buttonText = buttonName3
	event.unregister(tes3.event.keyDown, assignHotkey3)
	keybindButton3:setText(buttonName3)
end

local function resetHotKeys()
	event.unregister(tes3.event.keyDown, easyResetActor, { filter = config.hotkey } )
	event.unregister(tes3.event.keyUp, undoeasyResetActor, { filter = config.hotkey } )
	event.unregister(tes3.event.keyDown, easyToggleCollision, { filter = config.hotkey2 } )
	event.unregister(tes3.event.keyUp, undoeasyToggleCollision, { filter = config.hotkey2 } )
	event.unregister(tes3.event.keyDown, easyToggleMenus, { filter = config.hotkey3 } )
	event.unregister(tes3.event.keyUp, undoeasyToggleMenus, { filter = config.hotkey3 } )
	config.hotkey = 199
	config.hotkey2 = 211
	config.hotkey3 = 209
		if ( config.enabled ) then
			event.register(tes3.event.keyDown, easyResetActor, { filter = config.hotkey } )
			event.register(tes3.event.keyUp, undoeasyResetActor, { filter = config.hotkey } )
			event.register(tes3.event.keyDown, easyToggleCollision, { filter = config.hotkey2 } )
			event.register(tes3.event.keyUp, undoeasyToggleCollision, { filter = config.hotkey2 } )
			event.register(tes3.event.keyDown, easyToggleMenus, { filter = config.hotkey3 } )
			event.register(tes3.event.keyUp, undoeasyToggleMenus, { filter = config.hotkey3 } )
		end
	local buttonName = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey).value
	keybindButton.buttonText = buttonName
	keybindButton:setText(buttonName)
	local buttonName2 = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey2).value
	keybindButton2.buttonText = buttonName2
	keybindButton2:setText(buttonName2)
	local buttonName3 = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey3).value
	keybindButton3.buttonText = buttonName3
	keybindButton3:setText(buttonName3)
end

local function initialized()
	if ( config.enabled) then
		event.register(tes3.event.keyDown, easyResetActor, { filter = config.hotkey } )
		event.register(tes3.event.keyUp, undoeasyResetActor, { filter = config.hotkey } )
		event.register(tes3.event.keyDown, easyToggleCollision, { filter = config.hotkey2 } )
		event.register(tes3.event.keyUp, undoeasyToggleCollision, { filter = config.hotkey2 } )
		event.register(tes3.event.keyDown, easyToggleMenus, { filter = config.hotkey3 } )
		event.register(tes3.event.keyUp, undoeasyToggleMenus, { filter = config.hotkey3 } )
		local executed = mwscript.startScript({ script = "trib_reset_easyRA_script" })
		local executed = mwscript.startScript({ script = "trib_reset_easyTCL_script" })
		local executed = mwscript.startScript({ script = "trib_reset_easyTM_script" })
	end
print("[EasyKeys] EasyKeys Initialized")
end

event.register(tes3.event.initialized, initialized)

local function getButtonText(featureString, bool)
	local s
	
	if ( bool ) then
		s = featureString .. " Enabled"
	else
		s = featureString .. " Disabled"
	end
	
	return s
end

local function registerModConfig()

    local mcm = mwse.mcm
    local template = mcm.createTemplate(mod.name)
    template:saveOnClose(mod.config, config)

    local page = template:createSideBarPage({label="\""..mod.name.."\" Settings"})
    page.sidebar:createInfo{ text = "Welcome to \""..mod.name.."\" Configuration Menu. \n \n This mod adds in keybinds for console commands. Now you are one button press away from these common needs. \n \n \n \n A mod by "..mod.author.."."}
    page.sidebar:createHyperLink{ text = mod.author.."'s Nexus Profile", url = "https://next.nexusmods.com/profile/TribalLu/about-me" }
	
    local category0 = page:createCategory("Easy Console Commands Config")

    enableButton = category0:createButton({
	
        buttonText = getButtonText("Mod", config.enabled),
        description = "Toggle the mod On/Off.",
        callback = function(self)
            config.enabled = not config.enabled
		event.unregister(tes3.event.keyDown, easyResetActor, { filter = config.hotkey } )
		event.unregister(tes3.event.keyUp, undoeasyResetActor, { filter = config.hotkey } )
		event.unregister(tes3.event.keyDown, easyToggleCollision, { filter = config.hotkey2 } )
		event.unregister(tes3.event.keyUp, undoeasyToggleCollision, { filter = config.hotkey2 } )
		event.unregister(tes3.event.keyDown, easyToggleMenus, { filter = config.hotkey3 } )
		event.unregister(tes3.event.keyUp, undoeasyToggleMenus, { filter = config.hotkey3 } )
			
			if ( config.enabled ) then
				event.register(tes3.event.keyDown, easyResetActor, { filter = config.hotkey } )
				event.register(tes3.event.keyUp, undoeasyResetActor, { filter = config.hotkey } )
				event.register(tes3.event.keyDown, easyToggleCollision, { filter = config.hotkey2 } )
				event.register(tes3.event.keyUp, undoeasyToggleCollision, { filter = config.hotkey2 } )
				event.register(tes3.event.keyDown, easyToggleMenus, { filter = config.hotkey3 } )
				event.register(tes3.event.keyUp, undoeasyToggleMenus, { filter = config.hotkey3 } )
				enableButton.buttonText = getButtonText("Mod", config.enabled)
				enableButton:setText(getButtonText("Mod", config.enabled))
			else
				enableButton.buttonText = getButtonText("Mod", config.enabled)
				enableButton:setText(getButtonText("Mod", config.enabled))
			end
        end
    })

	local category1 = page:createCategory("Keybind Options")
	
	keybindButton = category1:createButton({
	
	label = "ResetActors Hotkey",
        buttonText = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey).value;
        description = "Choose a ResetActors hotkey.",
        callback = function(self)
			tes3.messageBox("Press a key.")
            event.register(tes3.event.keyDown, assignHotkey)
        end
    })

	keybindButton2 = category1:createButton({
	
	label = "ToggleCollision Hotkey",
        buttonText = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey2).value;
        description = "Choose a ToggleCollision hotkey.",
        callback = function(self)
			tes3.messageBox("Press a key.")
            event.register(tes3.event.keyDown, assignHotkey2)
        end
    })
	
	keybindButton3 = category1:createButton({
	
	label = "ToggleMenus Hotkey",
        buttonText = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey3).value;
        description = "Choose a ToggleMenus hotkey.",
        callback = function(self)
			tes3.messageBox("Press a key.")
            event.register(tes3.event.keyDown, assignHotkey3)
        end
    })
	
	local category2 = page:createCategory("Reset All Keys")
	
	resetAll = category2:createButton({

        buttonText = "Reset",
        callback = resetHotKeys
    })

    mcm.register(template)
end

event.register("modConfigReady", registerModConfig)