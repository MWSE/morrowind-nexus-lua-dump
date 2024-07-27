local mod = {
    name = "Real Time Blocking",
    config = "RealTimeBlockingConfig",
    ver = "1.1",
    author = "TribalLu",
            }
local configDefault = {
	enabled = true,
	hotkey = tes3.scanCode.c,
	blockBonus = 50,
	keyboardmouse = 0,
	mousehotkey = { mouseButton = 1 },
}

local config = mwse.loadConfig(mod.config, configDefault)

if not config then
    config = { blocked = {} }
end

local keybindButton
local mousekeybindButton
local enableButton
local currentBlock
local newBlock
local updatedBlock

local function myBlockCallback(e)
	if config.keyboardmouse == 0 then
	tes3.playAnimation({ reference = tes3.player, shield = tes3.animationState.unreadyWeap, })
	tes3.playAnimation({ reference = tes3.player1stPerson, shield = tes3.animationState.unreadyWeap, })
	currentBlock = tes3.mobilePlayer.block.current
	tes3.mobilePlayer.block.current = tes3.mobilePlayer.block.current + config.blockBonus
	end
end

local function undoBlockCallback(e)
	if config.keyboardmouse == 0 then
	newBlock = tes3.mobilePlayer.block.current
	updatedBlock = math.floor( newBlock - config.blockBonus )
	tes3.playAnimation({ reference = tes3.player })
	tes3.playAnimation({ reference = tes3.player1stPerson })
	tes3.mobilePlayer.block.current = updatedBlock
	tes3.mobilePlayer.block.base = updatedBlock
	end
end

local function mymouseBlockCallback(e)
	if tes3.isKeyEqual({ expected = config.mousehotkey, actual = e }) then
		if config.keyboardmouse == 1 then
		tes3.playAnimation({ reference = tes3.player, shield = tes3.animationState.unreadyWeap, })
		tes3.playAnimation({ reference = tes3.player1stPerson, shield = tes3.animationState.unreadyWeap, })
		currentBlock = tes3.mobilePlayer.block.current
		tes3.mobilePlayer.block.current = tes3.mobilePlayer.block.current + config.blockBonus
		end
	end
end

local function undomouseBlockCallback(e)
	if tes3.isKeyEqual({ expected = config.mousehotkey, actual = e }) then
		if config.keyboardmouse == 1 then
		newBlock = tes3.mobilePlayer.block.current
		updatedBlock = math.floor( newBlock - config.blockBonus )
		tes3.playAnimation({ reference = tes3.player })
		tes3.playAnimation({ reference = tes3.player1stPerson })
		tes3.mobilePlayer.block.current = updatedBlock
		tes3.mobilePlayer.block.base = updatedBlock
		end
	end
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
	tes3.messageBox('Block keyboard hotkey is now "%s"', buttonName);
	keybindButton.buttonText = buttonName
	event.unregister(tes3.event.keyDown, assignHotkey)
	keybindButton:setText(buttonName)
end

local function assignmouseHotkey(e)
	event.unregister(tes3.event.mouseButtonDown, mymouseBlockCallback )
	event.unregister(tes3.event.mouseButtonUp, undomouseBlockCallback )
	config.mousehotkey.mouseButton = e.button
	
	if ( config.enabled ) then
		event.register(tes3.event.mouseButtonDown, mymouseBlockCallback )
		event.register(tes3.event.mouseButtonUp, undomouseBlockCallback )
	end
	local buttonName = config.mousehotkey.mouseButton,
	tes3.messageBox("Block mouse hotkey is now \"Button "..config.mousehotkey.mouseButton.."\"");
	mousekeybindButton.buttonText = "Button "..config.mousehotkey.mouseButton..""
	event.unregister(tes3.event.mouseButtonDown, assignmouseHotkey)
	mousekeybindButton:setText("Button "..config.mousehotkey.mouseButton.."")
end

local function initialized()

		if ( config.enabled) then
			event.register(tes3.event.keyDown, myBlockCallback, { filter = config.hotkey } )
			event.register(tes3.event.keyUp, undoBlockCallback, { filter = config.hotkey } )
			event.register(tes3.event.mouseButtonDown, mymouseBlockCallback )
			event.register(tes3.event.mouseButtonUp, undomouseBlockCallback )
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

local function changekey()
	if config.keyboardmouse == 1 then
		tes3.messageBox("Block assigned to Mouse.")
	elseif config.keyboardmouse == 0 then
		tes3.messageBox("Block assigned to Keyboard.")
	end
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
	
	local subcat = page0:createCategory(" Block Key     <- Keyboard --- Mouse ->")
    subcat:createSlider{label = "Keyboard(0) or Mouse(1)", min = 0, max = 1, step = 1, jump = 1, variable = mcm.createTableVariable{id = "keyboardmouse", table = config}, callback = changekey}

	local category0 = page0:createCategory("Keybinds for Blocking")
	
	keybindButton = category0:createButton({
	
	label = "Keyboard Hotkey",
        buttonText = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey).value;
        description = "Choose Blocking keyboard hotkey.",
        callback = function(self)
			tes3.messageBox("Press a free key.")
            event.register(tes3.event.keyDown, assignHotkey)
        end
    })
	
	mousekeybindButton = category0:createButton({
	
	label = "Mouse Hotkey",
        buttonText = "Button "..config.mousehotkey.mouseButton.."",
        description = "Choose Blocking mouse hotkey.",
        callback = function(self)
			tes3.messageBox("Press a free key.")
            event.register(tes3.event.mouseButtonDown, assignmouseHotkey)
        end
    })
	
	local subcat = page0:createCategory("Definitions: \n Button 0 = Left Mouse Button \n Button 1 = Right Mouse Button \n Button 2 = Middle(Wheel) Mouse Button")

--Page2Sidebar
	page0.sidebar.noScroll = false
	local subcat = page0:createCategory("")
	page0.sidebar:createInfo{ text = "Thank you for using "..mod.name..". \n A mod by "..mod.author.."."}
	page0.sidebar:createHyperLink{ text = mod.author.."'s Nexus Profile", url = "https://next.nexusmods.com/profile/TribalLu/about-me" }
	
    mcm.register(template)
end

event.register("modConfigReady", registerModConfig)