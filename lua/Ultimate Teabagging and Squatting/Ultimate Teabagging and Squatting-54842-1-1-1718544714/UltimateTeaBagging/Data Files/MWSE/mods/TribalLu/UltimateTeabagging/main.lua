local mod = {
    name = "Ultimate Teabagging",
    config = "Ultimate Teabagging Config",
    ver = "1.0",
    author = "TribalLu",
            }
local configDefault = {
	enabled = true,
	hotkey = tes3.scanCode.c,
	patches = tes3.scanCode.v,
}

local config = mwse.loadConfig(mod.config, configDefault)

if not config then
    config = { blocked = {} }
end

local keybindButton
local keybindButton2
local enableButton

local function myTeaBag(e)
	tes3.loadAnimation({ reference = tes3.player, file = "Squat.nif", })
end

local function undoTeaBag(e)
	tes3.loadAnimation({ reference = tes3.player })
end

local iamPatches = 0
local function myPatches(e)
	if ( iamPatches == 0 ) then
		tes3.loadAnimation({ reference = tes3.player, file = "Squat.nif", })
		iamPatches = 1
	elseif ( iamPatches == 1 ) then 
		tes3.loadAnimation({ reference = tes3.player })
		iamPatches = 0
	end
end

local function assignHotkey(e)
	event.unregister(tes3.event.keyDown, myTeaBag, { filter = config.hotkey } )
	event.unregister(tes3.event.keyUp, undoTeaBag, { filter = config.hotkey } )
	config.hotkey = e.keyCode

	if ( config.enabled ) then
		event.register(tes3.event.keyDown, myTeaBag, { filter = config.hotkey } )
		event.register(tes3.event.keyUp, undoTeaBag, { filter = config.hotkey } )
	end
	local buttonName = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey).value
	tes3.messageBox('TeaBag hotkey is now "%s"', buttonName);
	keybindButton.buttonText = buttonName
	event.unregister(tes3.event.keyDown, assignHotkey)
	keybindButton:setText(buttonName)
end

local function assignHotkey2(e)
	event.unregister(tes3.event.keyDown, myPatches, { filter = config.patches } )
	config.patches = e.keyCode

	if ( config.enabled ) then
		event.register(tes3.event.keyDown, myPatches, { filter = config.patches } )
	end
	local buttonName2 = tes3.findGMST(tes3.gmst.sKeyName_00 + config.patches).value
	tes3.messageBox('Patches hotkey is now "%s"', buttonName2);
	keybindButton2.buttonText = buttonName2
	event.unregister(tes3.event.keyDown, assignHotkey2)
	keybindButton2:setText(buttonName2)
end

local function initialized()
	if ( config.enabled) then
		event.register(tes3.event.keyDown, myTeaBag, { filter = config.hotkey } )
		event.register(tes3.event.keyUp, undoTeaBag, { filter = config.hotkey } )
		event.register(tes3.event.keyDown, myPatches, { filter = config.patches } )
	end
print("[UltimateTeabagging] UltimateTeabagging Initialized")
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
    page.sidebar:createInfo{ text = "Welcome to \""..mod.name.."\" Configuration Menu. \n \n This mod adds in a new immersive tool which allows you to dip your balls onto your opponents face. Or for the initiative, into their mouths.  \n How it works: \n While your opponent is on the ground, take one of your legs and straddle it on the oposite side of your opponent near the upper chest area. Then bend at your knees until your balls smack them on their face. Repeat up and down until you are satsified. \n \n \n \n A mod by "..mod.author.."."}
    page.sidebar:createHyperLink{ text = mod.author.."'s Nexus Profile", url = "https://next.nexusmods.com/profile/TribalLu/about-me" }
	
    local category0 = page:createCategory("Teabagging Config")

    enableButton = category0:createButton({
	
        buttonText = getButtonText("Mod", config.enabled),
        description = "Toggle the mod On/Off.",
        callback = function(self)
            config.enabled = not config.enabled
		event.unregister(tes3.event.keyDown, myTeaBag, { filter = config.hotkey } )
		event.unregister(tes3.event.keyUp, undoTeaBag, { filter = config.hotkey } )
		event.unregister(tes3.event.keyDown, myPatches, { filter = config.patches } )
			
			if ( config.enabled ) then
				event.register(tes3.event.keyDown, myTeaBag, { filter = config.hotkey } )
				event.register(tes3.event.keyUp, undoTeaBag, { filter = config.hotkey } )
				event.register(tes3.event.keyDown, myPatches, { filter = config.patches } )
				enableButton.buttonText = getButtonText("Mod", config.enabled)
				enableButton:setText(getButtonText("Mod", config.enabled))
			else
				enableButton.buttonText = getButtonText("Mod", config.enabled)
				enableButton:setText(getButtonText("Mod", config.enabled))
			end
        end
    })

	local category1 = page:createCategory("Keybinds for Teabagging")
	
	keybindButton = category1:createButton({
	
	label = "Tea Bag Hotkey",
        buttonText = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey).value;
        description = "Choose teabag hotkey.",
        callback = function(self)
			tes3.messageBox("Press a key.")
            event.register(tes3.event.keyDown, assignHotkey)
        end
    })
	
	keybindButton2 = category1:createButton({
	
	label = "Permanent Squat Hotkey",
        buttonText = tes3.findGMST(tes3.gmst.sKeyName_00 + config.patches).value;
        description = "Choose permanent hotkey.",
        callback = function(self)
			tes3.messageBox("Press a key.")
            event.register(tes3.event.keyDown, assignHotkey2)
        end
    })

    mcm.register(template)
end

event.register("modConfigReady", registerModConfig)