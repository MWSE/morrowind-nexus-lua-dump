local mod = {
    name = "Sit, Rest, and Heal",
    config = "SitRestandHealConfig",
    ver = "1.3",
    author = "TribalLu",
			}
local configDefault = {
	enabled = true,
	hotkey = tes3.scanCode.n,
	messageonOFF = true, 
	icononOFF = false,
	iconslider = 5, 
	iconsliderpercent = 900, 
	iconXwidth = 35, 
	iconXheight = 35, 
	soundoption = true, 
	lowhealthoption = 5, 
	lowmagickaoption = 5, 
	highhealthoption = 15, 
	highmagickaoption = 10, 
	resolutionHor = 1920, 
	resolutionVer = 1080,
}

local config = mwse.loadConfig(mod.config, configDefault)

if not config then
    config = { blocked = {} }
end

local ids = {
    SRHBlock = tes3ui.registerID("SRH:Block"),
    SRHImage = tes3ui.registerID("SRH:Image"),
}

local keybindButton
local enableButton
local SRHTimer
local MovementTimer
local messageonoffButton
local soundonoffButton

local healtick = "tribs/healing_tick_01.wav"

local mySRH = 0
local iniSRH = 0
local function mySitRestHeal()
	if tes3.menuMode() then
		return
	end

	if ( mySRH == 0 ) then
		if iniSRH == 0 then iniSRH = 1 end
		tes3.loadAnimation({ reference = tes3.player, file = "Squat.nif", })
			if ( config.messageonOFF ) then
			tes3.messageBox("You are now resting.")
			else end
		mySRH = 1
		config.icononOFF = true
			local block = menuMultiSRHFillbarsBlock:findChild(ids.SRHBlock)
			if block then	
			block.visible = config.icononOFF
			menuMultiSRHFillbarsBlock:updateLayout()
			end
		SRHTimer:resume()
		MovementTimer:resume()
	elseif ( mySRH == 1 ) then 
		tes3.loadAnimation({ reference = tes3.player })
			if ( config.messageonOFF ) then
			tes3.messageBox("You are no longer resting.")
			else end
		mySRH = 0
		config.icononOFF = false
			local block = menuMultiSRHFillbarsBlock:findChild(ids.SRHBlock)
			if block then	
			block.visible = config.icononOFF
			menuMultiSRHFillbarsBlock:updateLayout()
			end
		SRHTimer:pause()
		MovementTimer:pause()
	end
end

local function SRHTimerActive()
	if ( not tes3.mobilePlayer.isMovingForward and not tes3.mobilePlayer.isMovingBack and not tes3.mobilePlayer.isMovingLeft and not tes3.mobilePlayer.isMovingRight ) then
		if tes3.mobilePlayer.health.base <= 150 then
			if mySRH == 1 then
				tes3.mobilePlayer.health.current = tes3.mobilePlayer.health.current + config.lowhealthoption
				if tes3.mobilePlayer.health.current >= tes3.mobilePlayer.health.base then tes3.mobilePlayer.health.current = tes3.mobilePlayer.health.base end
			end
		else
			if mySRH == 1 then
				tes3.mobilePlayer.health.current = tes3.mobilePlayer.health.current + config.highhealthoption
				if tes3.mobilePlayer.health.current >= tes3.mobilePlayer.health.base then tes3.mobilePlayer.health.current = tes3.mobilePlayer.health.base end
			end
		end
		if tes3.mobilePlayer.magicka.base <= 150 then
			if mySRH == 1 then
				tes3.mobilePlayer.magicka.current = tes3.mobilePlayer.magicka.current + config.lowmagickaoption
				if tes3.mobilePlayer.magicka.current >= tes3.mobilePlayer.magicka.base then tes3.mobilePlayer.magicka.current = tes3.mobilePlayer.magicka.base end
			end
		else
			if mySRH == 1 then
				tes3.mobilePlayer.magicka.current = tes3.mobilePlayer.magicka.current + config.highmagickaoption
				if tes3.mobilePlayer.magicka.current >= tes3.mobilePlayer.magicka.base then tes3.mobilePlayer.magicka.current = tes3.mobilePlayer.magicka.base end
			end
		end
		if ( config.soundoption == true ) then
			if tes3.mobilePlayer.health.current < tes3.mobilePlayer.health.base then
				tes3.playSound({ soundPath = healtick, volume = 0.7 })
			elseif tes3.mobilePlayer.magicka.current < tes3.mobilePlayer.magicka.base then
				tes3.playSound({ soundPath = healtick, volume = 0.7 })
			end
		end
		local seph = include("seph.hudCustomizer.hud")
		if seph then
			seph:updateMenuMulti()
		end
		tes3.setStatistic{ reference = tes3.player, name = "health", current = tes3.mobilePlayer.health.current }
		tes3.setStatistic{ reference = tes3.player, name = "magicka", current = tes3.mobilePlayer.magicka.current }
	end
end

local function MovementActive()
	if ( tes3.mobilePlayer.isMovingForward or tes3.mobilePlayer.isMovingBack or tes3.mobilePlayer.isMovingLeft or tes3.mobilePlayer.isMovingRight ) then
		tes3.loadAnimation({ reference = tes3.player })
			if ( config.messageonOFF ) then
			tes3.messageBox("You are no longer resting.")
			else end
		mySRH = 0
		config.icononOFF = false
			local block = menuMultiSRHFillbarsBlock:findChild(ids.SRHBlock)
			if block then	
			block.visible = config.icononOFF
			menuMultiSRHFillbarsBlock:updateLayout()
			end
		SRHTimer:pause()
		MovementTimer:pause()
	end
end

local function startSRHTimer()
	SRHTimer = timer.start({ duration = 5, iterations = -1, type = timer.real, callback = SRHTimerActive})
	if iniSRH == 0 then SRHTimer:pause() end
end

local function startMovementTimer()
	MovementTimer = timer.start({ duration = 0.01, iterations = -1, type = timer.real, callback = MovementActive})
	if iniSRH == 0 then MovementTimer:pause() end
end

local function assignHotkey(e)
	event.unregister(tes3.event.keyDown, mySitRestHeal, { filter = config.hotkey } )
	config.hotkey = e.keyCode

	if ( config.enabled ) then
		event.register(tes3.event.keyDown, mySitRestHeal, { filter = config.hotkey } )
	end
	local buttonName = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey).value
	tes3.messageBox('Hotkey is now "%s"', buttonName);
	keybindButton.buttonText = buttonName
	event.unregister(tes3.event.keyDown, assignHotkey)
	keybindButton:setText(buttonName)
end

local function initialized()
	if ( config.enabled) then
		event.register(tes3.event.keyDown, mySitRestHeal, { filter = config.hotkey } )
		event.register(tes3.event.loaded, startSRHTimer)
		event.register(tes3.event.loaded, startMovementTimer)
	end
		config.icononOFF = false
		local block = menuMultiSRHFillbarsBlock:findChild(ids.SRHBlock)
		if block then	
		block.visible = config.icononOFF
		menuMultiSRHFillbarsBlock:updateLayout()
		end
print("[Sit, Rest, and Heal] Sit, Rest, and Heal Initialized")
end

event.register(tes3.event.initialized, initialized)

local function createSRHFillbar(element)
    local block = element:createRect({ id = ids.SRHBlock, color = {0.0, 0.0, 0.0} })
    block.ignoreLayoutX = true
    block.ignoreLayoutY = true
    block.width = config.iconXwidth
    block.height = config.iconXheight
    block.borderAllSides = 2
    block.alpha = 0.8
    block.positionX = config.iconslider
    block.positionY = -config.iconsliderpercent
    block.visible = config.icononOFF
	
		local SRHImagePath = "icons\\tribk\\sitrestheal."
		local path = lfs.fileexists(SRHImagePath .. "dds") and SRHImagePath .. "dds" or SRHImagePath .. "tga"
        local SRHimage = block:createImage({id = ids.SRHImage, path = path })
        SRHimage.width = config.iconXwidth
        SRHimage.height = config.iconXheight

    element:updateLayout()

    return
end

local function createMenuMultiSRHFillbar(e)
	if not e.newlyCreated then return end

	menuMultiSRHFillbarsBlock = e.element:findChild(tes3ui.registerID("MenuMulti_icons_layout"))
	menuSRHBar = createSRHFillbar(menuMultiSRHFillbarsBlock)
end
event.register("uiActivated", createMenuMultiSRHFillbar, { filter = "MenuMulti" })

local function refreshSRHFillbarCustomization()
        local block = menuMultiSRHFillbarsBlock:findChild(ids.SRHBlock)
        if block then
			block:destroy()
			menuMultiSRHFillbarsBlock:updateLayout()
        end
	createSRHFillbar(menuMultiSRHFillbarsBlock)
end

local function updateSRHFillbarCustomization()
        local block = menuMultiSRHFillbarsBlock:findChild(ids.SRHBlock)
        if block then	
		block.width = config.iconXwidth
		block.height = config.iconXheight
		block.positionX = config.iconslider
		block.positionY = -config.iconsliderpercent
		block.visible = config.icononOFF
		local SRHimage = menuMultiFillbarsBlock:findChild(ids.SRHImage)
		if SRHimage then
		SRHimage.width = config.iconXwidth
		SRHimage.height = config.iconXheight
		end
	    menuMultiSRHFillbarsBlock:updateLayout()
        end
end

local function getButtonText(featureString, bool)
	local s
	
	if ( bool ) then
		s = featureString .. " Enabled"
	else
		s = featureString .. " Disabled"
	end
	
	return s
end

local function changeResolutionHor()
	if config.resolutionHor == 3840 then
		tes3.messageBox("Horizontal set to 4k. Restart Required.")
	elseif config.resolutionHor == 1920 then
		tes3.messageBox("Horizontal set to 1080p. Restart Required.")
	end
end

local function changeResolutionVer()
	if config.resolutionVer == 2160 then
		tes3.messageBox("Vertical set to 4k. Restart Required.")
	elseif config.resolutionVer == 1080 then
		tes3.messageBox("Vertical set to 1080p. Restart Required.")
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
		event.unregister(tes3.event.keyDown, mySitRestHeal, { filter = config.hotkey } )
			
			if ( config.enabled ) then
				event.register(tes3.event.keyDown, mySitRestHeal, { filter = config.hotkey } )
				enableButton.buttonText = getButtonText("Mod", config.enabled)
				enableButton:setText(getButtonText("Mod", config.enabled))
			else
				enableButton.buttonText = getButtonText("Mod", config.enabled)
				enableButton:setText(getButtonText("Mod", config.enabled))
			end
        end
    })

	local subcat = page:createCategory("This mod adds in a new game feature that allows you to Rest in real time in order to slowly heal your Health and Magicka points. \n \nDefault heals are as followed: \n Health 1-150 = +5 Health per Tick \n Magicka 1-150 = +5 Magicka per Tick \n Health 150+ = +15 Health per Tick \n Magicka 150+ = +10 Magicka per Tick")

	local subcat = page:createCategory("On the next page you can change the Location of the Icon. \n Note: If your changes didn't take affect, Press the Refresh button.")

	local subcat = page:createCategory(" Refresh")
    subcat:createButton{label = "Click to Refresh", callback = refreshSRHFillbarCustomization, buttonText = "Refresh"}

--Page2
	local page0 = template:createSideBarPage({label="Settings"})

	local category0 = page0:createCategory("Keybinds for SitRestHeal")
	
	keybindButton = category0:createButton({
	
	label = "SitRestHeal Hotkey",
        buttonText = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey).value;
        callback = function(self)
			tes3.messageBox("Press a key.")
            event.register(tes3.event.keyDown, assignHotkey)
        end
    })
	
	local category1 = page0:createCategory("Display Message Notifications")
	
	messageonoffButton = category1:createButton({
	
	label = "Messages On(true)/Off(false)",
		buttonText = config.messageonOFF,
		callback = function(self)
			config.messageonOFF = not config.messageonOFF
			if ( config.messageonOFF == true ) then
				tes3.messageBox("Messages enabled.")
				messageonoffButton.buttonText = (config.messageonOFF)
				messageonoffButton:setText(config.messageonOFF)
			else
				tes3.messageBox("Messages disabled.")
				messageonoffButton.buttonText = (config.messageonOFF)
				messageonoffButton:setText(config.messageonOFF)
			end
		end
    })
	
	local category2 = page0:createCategory("Sound Option")
	
	soundonoffButton = category2:createButton({
	
	label = "Sound On(true)/Off(false)",
        buttonText = config.soundoption, 
		callback = function(self)
			config.soundoption = not config.soundoption
			if ( config.soundoption == true ) then
				tes3.messageBox("Sound enabled.")
				soundonoffButton.buttonText = (config.soundoption)
				soundonoffButton:setText(config.soundoption)
			else
				tes3.messageBox("Sound disabled.")
				soundonoffButton.buttonText = (config.soundoption)
				soundonoffButton:setText(config.soundoption)
			end
		end
    })
	
	local category3 = page0:createCategory("Tick Totals")
	category3:createSlider {label = "Tick Total for Low Health", max = 150, min = 0, step = 1, jump = 10, variable = mcm:createTableVariable {id = "lowhealthoption", table = config}}
	category3:createSlider {label = "Tick Total for Low Magicka", max = 150, min = 0, step = 1, jump = 10, variable = mcm:createTableVariable {id = "lowmagickaoption", table = config}}
	category3:createSlider {label = "Tick Total for High Health", max = 300, min = 0, step = 1, jump = 10, variable = mcm:createTableVariable {id = "highhealthoption", table = config}}
	category3:createSlider {label = "Tick Total for High Magicka", max = 300, min = 0, step = 1, jump = 10, variable = mcm:createTableVariable {id = "highmagickaoption", table = config}}

--Page2Sidebar
	page0.sidebar.noScroll = false
	local subcat = page0.sidebar:createCategory("Resting Icon Position")
	page0.sidebar:createSlider {label = "Horizontal (Min:0 to Max:"..config.resolutionHor..")", max = config.resolutionHor, min = 0, step = 1, jump = 10, variable = mcm:createTableVariable {id = "iconslider", table = config}, callback = updateSRHFillbarCustomization}
	page0.sidebar:createSlider {label = "Vertical (Min:0 to Max:"..config.resolutionVer..")", max = config.resolutionVer, min = 0, step = 1, jump = 10, variable = mcm:createTableVariable {id = "iconsliderpercent", table = config}, callback = updateSRHFillbarCustomization}
	
--Page3	
	local page1 = template:createSideBarPage({label="Other Options"})
	
	local subcat = page1:createCategory(" Screen Resolution     <- 1080p --- 4k ->")
    subcat:createSlider{label = "Horizontal", min = 1920, max = 3840, step = 1920, jump = 1920, variable = mcm.createTableVariable{id = "resolutionHor", table = config}, callback = changeResolutionHor}
    subcat:createSlider{label = "Vertical", min = 1080, max = 2160, step = 1080, jump = 1080, variable = mcm.createTableVariable{id = "resolutionVer", table = config}, callback = changeResolutionVer}

	local subcat = page1:createCategory("")
	page1.sidebar:createInfo{ text = "Thank you for using "..mod.name..". \n A mod by "..mod.author.."."}
	page1.sidebar:createHyperLink{ text = mod.author.."'s Nexus Profile", url = "https://next.nexusmods.com/profile/TribalLu/about-me" }

    mcm.register(template)
end

event.register("modConfigReady", registerModConfig)