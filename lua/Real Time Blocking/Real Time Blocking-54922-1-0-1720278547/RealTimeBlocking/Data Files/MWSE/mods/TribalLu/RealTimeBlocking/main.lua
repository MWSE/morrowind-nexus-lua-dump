local mod = {
    name = "Real Time Blocking",
    config = "RealTimeBlockingConfig",
    ver = "1.0",
    author = "TribalLu",
            }
local configDefault = {
	enabled = true,
	hotkey = tes3.scanCode.c,
	blockBonus = 50,
}

local config = mwse.loadConfig(mod.config, configDefault)

if not config then
    config = { blocked = {} }
end

local keybindButton
local enableButton
local currentBlock

local function myBlockCallback(e)
	tes3.playAnimation({ reference = tes3.player, shield = tes3.animationState.unreadyWeap, })
	tes3.playAnimation({ reference = tes3.player1stPerson, shield = tes3.animationState.unreadyWeap, })
	currentBlock = tes3.mobilePlayer.block.current
	tes3.mobilePlayer.block.current = tes3.mobilePlayer.block.current + config.blockBonus
end

local function undoBlockCallback(e)
	tes3.playAnimation({ reference = tes3.player })
	tes3.playAnimation({ reference = tes3.player1stPerson })
	tes3.mobilePlayer.block.current = currentBlock
end

local function assignHotkey(e)
	event.unregister(tes3.event.keyDown, myBlockCallback, { filter = config.hotkey } )
	event.unregister(tes3.event.keyUp, undoBlockCallback, { filter = config.hotkey } )
	config.hotkey = e.keyCode
	
	if ( config.enabled ) then
		event.register(tes3.event.keyDown, myBlockCallback, { filter = config.hotkey } )
		event.register(tes3.event.keyUp, undoBlockCallback, { filter = config.hotkey } )
	end
	local buttonName = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey).value
	tes3.messageBox('Block hotkey is now "%s"', buttonName);
	keybindButton.buttonText = buttonName
	event.unregister(tes3.event.keyDown, assignHotkey)
	keybindButton:setText(buttonName)
end

local function initialized()

		if ( config.enabled) then
			event.register(tes3.event.keyDown, myBlockCallback, { filter = config.hotkey } )
			event.register(tes3.event.keyUp, undoBlockCallback, { filter = config.hotkey } )
		end
	
	print("[Active Blocking] Active Blocking Initialized")
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

--Page1
    local page = template:createPage({label=mod.name})

	local category0 = page:createCategory("Welcome to \""..mod.name.."\" Configuration Menu.")

    enableButton = category0:createButton({
	
        buttonText = getButtonText("Mod", config.enabled),
        callback = function(self)
            config.enabled = not config.enabled
			event.unregister(tes3.event.keyDown, myBlockCallback, { filter = config.hotkey } )
			event.unregister(tes3.event.keyUp, undoBlockCallback, { filter = config.hotkey } )
			if ( config.enabled ) then
				event.register(tes3.event.keyDown, myBlockCallback, { filter = config.hotkey } )
				event.register(tes3.event.keyUp, undoBlockCallback, { filter = config.hotkey } )
				enableButton.buttonText = getButtonText("Mod", config.enabled)
				enableButton:setText(getButtonText("Mod", config.enabled))
			else
				enableButton.buttonText = getButtonText("Mod", config.enabled)
				enableButton:setText(getButtonText("Mod", config.enabled))
			end
        end
    })
	
	local subcat = page:createCategory("This mod adds in a new game feature that allows you to Block in real time. \n \n When you are holding down the Block button you get a boost in your Block skill. \n \n Default: +50 Block. \n \n You can customize the bonus below.")

	local subcat = page:createCategory("Block Bonus Total")
	subcat:createSlider {label = "Block bonus:", max = 100, min = 0, step = 1, jump = 10, variable = mcm:createTableVariable {id = "blockBonus", table = config}}

	local subcat = page:createCategory("See more settings on the next Page.")

--Page2
	local page0 = template:createSideBarPage({label="Settings"})

	local category0 = page0:createCategory("Keybinds for Blocking")
	
	keybindButton = category0:createButton({
	
	label = "Blocking Hotkey",
        buttonText = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey).value;
        description = "Choose Blocking hotkey.",
        callback = function(self)
			tes3.messageBox("Press a free key.")
            event.register(tes3.event.keyDown, assignHotkey)
        end
    })

--Page2Sidebar
	page0.sidebar.noScroll = false
	local subcat = page0:createCategory("")
	page0.sidebar:createInfo{ text = "Thank you for using "..mod.name..". \n A mod by "..mod.author.."."}
	page0.sidebar:createHyperLink{ text = mod.author.."'s Nexus Profile", url = "https://next.nexusmods.com/profile/TribalLu/about-me" }
	
    mcm.register(template)
end

event.register("modConfigReady", registerModConfig)