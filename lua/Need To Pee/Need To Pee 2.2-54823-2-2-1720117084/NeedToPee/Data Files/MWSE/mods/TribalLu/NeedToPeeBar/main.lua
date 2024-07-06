local mod = {
    name = "Need to Pee Bars",
    config = "NeedtoPeeBarsConfig",
    ver = "2.2",
    author = "TribalLu",
    cf = {onOff = true, slider = 5, sliderpercent = 1003, switch = true, Xwidth = 73, Xheight = 15, onOff2 = true, slider2 = 5, sliderpercent2 = 1018, switch2 = true, Xwidth2 = 73, Xheight2 = 15, resolutionHor = 1920, resolutionVer = 1080}
            }
local cf = mwse.loadConfig(mod.config, mod.cf)

local ids = {
    FillbarBlock = tes3ui.registerID("PainBar:PeeLevelBlock"),
    Fillbar = tes3ui.registerID("PainBar:PeeLevelbar"),
    FillbarBlock2 = tes3ui.registerID("PeeBar:PeeBlock"),
    Fillbar2 = tes3ui.registerID("PeeBar:Peebar"),
}

local function updatePeeFillbar(fillbar)
    local current = tes3.player.data.NeedToPee.currentPeeLevel
    local max = 5

    fillbar.widget.current = current
    fillbar.widget.max = max

    fillbar.widget.fillColor = {1.0,0.1,0.0}
    fillbar.widget.showText = cf.switch
    fillbar.visible = cf.onOff
end
local function updatePeeFillbar2(fillbar2)
    local current2 = tes3.player.data.NeedToPee.trueTotal
    local max2 = tes3.player.data.NeedToPee.trueTotalMax
	
	if tes3.player.data.NeedToPee.currentPeeLevel == 1 then
		current2 = tes3.player.data.NeedToPee.trueTotal - tes3.player.data.NeedToPee.trueTotalMax
	elseif tes3.player.data.NeedToPee.currentPeeLevel == 2 then
		current2 = tes3.player.data.NeedToPee.trueTotal - math.floor( tes3.player.data.NeedToPee.trueTotalMax * 2 )
	elseif tes3.player.data.NeedToPee.currentPeeLevel == 3 then
		current2 = tes3.player.data.NeedToPee.trueTotal - math.floor( tes3.player.data.NeedToPee.trueTotalMax * 3 )
	elseif tes3.player.data.NeedToPee.currentPeeLevel == 4 then
		current2 = tes3.player.data.NeedToPee.trueTotal - math.floor( tes3.player.data.NeedToPee.trueTotalMax * 4 )
	elseif tes3.player.data.NeedToPee.currentPeeLevel == 5 then
		current2 = tes3.player.data.NeedToPee.trueTotalMax
	end

    fillbar2.widget.current = current2
    fillbar2.widget.max = max2

    fillbar2.widget.fillColor = {0.9,0.8,0.0}
    fillbar2.widget.showText = cf.switch2
    fillbar2.visible = cf.onOff2
end

local function createPeeFillbar(element)
    local block = element:createRect({ id = ids.FillbarBlock, color = {0.0, 0.0, 0.0} })
    block.ignoreLayoutX = true
    block.ignoreLayoutY = true
    block.width = cf.Xwidth
    block.height = cf.Xheight
    block.borderAllSides = 2
    block.alpha = 0.8
    block.positionX = cf.slider
    block.positionY = -cf.sliderpercent
    block.visible = cf.onOff

        local fillbar = block:createFillBar({id = ids.Fillbar})
        fillbar.width = cf.Xwidth
        fillbar.height = cf.Xheight
        fillbar.widget.showText = cf.switch
        updatePeeFillbar(fillbar)

    local block2 = element:createRect({ id = ids.FillbarBlock2, color = {0.0, 0.0, 0.0} })
    block2.ignoreLayoutX = true
    block2.ignoreLayoutY = true
    block2.width = cf.Xwidth2
    block2.height = cf.Xheight2
    block2.borderAllSides = 2
    block2.alpha = 0.8
    block2.positionX = cf.slider2
    block2.positionY = -cf.sliderpercent2
    block2.visible = cf.onOff2

        local fillbar2 = block2:createFillBar({id = ids.Fillbar2})
        fillbar2.width = cf.Xwidth2
        fillbar2.height = cf.Xheight2
        fillbar2.widget.showText = cf.switch2
        updatePeeFillbar2(fillbar2)

    element:updateLayout()

    return
end

local menuMultiPeeFillbarsBlock
event.register("loaded", function()
    timer.start({
        duration = .01,
        iterations = -1,
        type = timer.real,
        callback = function()
            if (not menuMultiPeeFillbarsBlock) then return end

            local fillbar = menuMultiPeeFillbarsBlock:findChild(ids.Fillbar)
            if (fillbar) then
                updatePeeFillbar(fillbar)
            end
            local fillbar2 = menuMultiPeeFillbarsBlock:findChild(ids.Fillbar2)
            if (fillbar2) then
                updatePeeFillbar2(fillbar2)
            end

            menuMultiPeeFillbarsBlock:updateLayout()
        end
    })
end)

local function createMenuMultiPeeFillbar(e)
	if not e.newlyCreated then return end

	menuMultiPeeFillbarsBlock = e.element:findChild(tes3ui.registerID("MenuMulti_fillbars_layout"))
	menuPeeBar = createPeeFillbar(menuMultiPeeFillbarsBlock)
end
event.register("uiActivated", createMenuMultiPeeFillbar, { filter = "MenuMulti" })


local function refreshPeeFillbarCustomization()
            local block = menuMultiPeeFillbarsBlock:findChild(ids.FillbarBlock)
            if block then
	    block:destroy()
	    menuMultiPeeFillbarsBlock:updateLayout()
            end
            local block2 = menuMultiPeeFillbarsBlock:findChild(ids.FillbarBlock2)
            if block2 then
	    block2:destroy()
	    menuMultiPeeFillbarsBlock:updateLayout()
            end

	createPeeFillbar(menuMultiPeeFillbarsBlock)
end

local function updatePeeFillbarCustomization()
            local block = menuMultiPeeFillbarsBlock:findChild(ids.FillbarBlock)
            if block then	
		block.width = cf.Xwidth
		block.height = cf.Xheight
		block.positionX = cf.slider
		block.positionY = -cf.sliderpercent
		block.visible = cf.onOff
		local fillbar = menuMultiPeeFillbarsBlock:findChild(ids.Fillbar)
		if fillbar then
		fillbar.width = cf.Xwidth
		fillbar.height = cf.Xheight
		end
	    menuMultiPeeFillbarsBlock:updateLayout()
            end
            local block2 = menuMultiPeeFillbarsBlock:findChild(ids.FillbarBlock2)
            if block2 then	
		block2.width = cf.Xwidth2
		block2.height = cf.Xheight2
		block2.positionX = cf.slider2
		block2.positionY = -cf.sliderpercent2
		block2.visible = cf.onOff2
		local fillbar2 = menuMultiPeeFillbarsBlock:findChild(ids.Fillbar2)
		if fillbar2 then
		fillbar2.width = cf.Xwidth2
		fillbar2.height = cf.Xheight2
		end
	    menuMultiPeeFillbarsBlock:updateLayout()
            end
end

local function changeResolutionHor()
	if cf.resolutionHor == 3840 then
		tes3.messageBox("Horizontal set to 4k. Restart Required.")
	elseif cf.resolutionHor == 1920 then
		tes3.messageBox("Horizontal set to 1080p. Restart Required.")
	end
end

local function changeResolutionVer()
	if cf.resolutionVer == 2160 then
		tes3.messageBox("Vertical set to 4k. Restart Required.")
	elseif cf.resolutionVer == 1080 then
		tes3.messageBox("Vertical set to 1080p. Restart Required.")
	end
end

local function registerModConfig()
    local template = mwse.mcm.createTemplate(mod.name)
    template:saveOnClose(mod.config, cf)
    template:register()

--Page1
    local page = template:createPage({label=mod.name})
	
	local category0 = page:createCategory("Welcome to \""..mod.name.."\" Configuration Menu. \n \n This mod adds in the Pain and Pee bars to your HUD")
    
	local subcat = page:createCategory("On the next page you can change the Location, Size and Visibility of the Bars. \n Note: If your changes didn't take affect, Press the Refresh button.")

    local subcat = page:createCategory(" Refresh")
    subcat:createButton{label = "Click to Refresh", callback = refreshPeeFillbarCustomization, buttonText = "Refresh"}
	
--Page2
	local page0 = template:createSideBarPage({label="Bar Settings"})

    local subcat = page0:createCategory("Pain Level Bar")

    local subcat = page0:createCategory(" Show/Hide Bar")
    subcat:createOnOffButton{label = "Show(On)/Hide(Off)", variable = mwse.mcm.createTableVariable{id = "onOff", table = cf}, callback = updatePeeFillbarCustomization}

    local subcat = page0:createCategory(" Display Total")
    subcat:createOnOffButton{label = "On/Off", variable = mwse.mcm.createTableVariable{id = "switch", table = cf}, callback = updatePeeFillbarCustomization}

    local subcat = page0:createCategory(" Position")
    subcat:createSlider{label = "Horizontal (Min:0 to Max:"..cf.resolutionHor..")", min = 0, max = cf.resolutionHor, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "slider", table = cf}, callback = updatePeeFillbarCustomization}
    subcat:createSlider{label = "Vertical (Min:0 to Max:"..cf.resolutionVer..")", min = 0, max = cf.resolutionVer, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "sliderpercent", table = cf}, callback = updatePeeFillbarCustomization}

    local subcat = page0:createCategory(" Size")
    subcat:createSlider{label = "Width", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "Xwidth", table = cf}, callback = updatePeeFillbarCustomization}
    subcat:createSlider{label = "Height", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "Xheight", table = cf}, callback = updatePeeFillbarCustomization}

--Page2Sidebar
	page0.sidebar.noScroll = false
    local subcat = page0.sidebar:createCategory("Pee Bar")

    local subcat = page0.sidebar:createCategory(" Show/Hide Bar")
    page0.sidebar:createOnOffButton{label = "Show(On)/Hide(Off)", variable = mwse.mcm.createTableVariable{id = "onOff2", table = cf}, callback = updatePeeFillbarCustomization}

    local subcat = page0.sidebar:createCategory(" Display Total")
    page0.sidebar:createOnOffButton{label = "On/Off", variable = mwse.mcm.createTableVariable{id = "switch2", table = cf}, callback = updatePeeFillbarCustomization}

    local subcat = page0.sidebar:createCategory(" Position")
    page0.sidebar:createSlider{label = "Horizontal (Min:0 to Max:"..cf.resolutionHor..")", min = 0, max = cf.resolutionHor, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "slider2", table = cf}, callback = updatePeeFillbarCustomization}
    page0.sidebar:createSlider{label = "Vertical (Min:0 to Max:"..cf.resolutionVer..")", min = 0, max = cf.resolutionVer, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "sliderpercent2", table = cf}, callback = updatePeeFillbarCustomization}

    local subcat = page0.sidebar:createCategory(" Size")
    page0.sidebar:createSlider{label = "Width", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "Xwidth2", table = cf}, callback = updatePeeFillbarCustomization}
    page0.sidebar:createSlider{label = "Height", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "Xheight2", table = cf}, callback = updatePeeFillbarCustomization}

--Page3	
	local page1 = template:createSideBarPage({label="Other Options"})
	
	local subcat = page1:createCategory(" Screen Resolution     <- 1080p --- 4k ->")
    subcat:createSlider{label = "Horizontal", min = 1920, max = 3840, step = 1920, jump = 1920, variable = mwse.mcm.createTableVariable{id = "resolutionHor", table = cf}, callback = changeResolutionHor}
    subcat:createSlider{label = "Vertical", min = 1080, max = 2160, step = 1080, jump = 1080, variable = mwse.mcm.createTableVariable{id = "resolutionVer", table = cf}, callback = changeResolutionVer}

	local subcat = page1:createCategory("")
	page1.sidebar:createInfo{ text = "Thank you for using "..mod.name..". \n A mod by "..mod.author.."."}
	page1.sidebar:createHyperLink{ text = mod.author.."'s Nexus Profile", url = "https://next.nexusmods.com/profile/TribalLu/about-me" }

end event.register("modConfigReady", registerModConfig)
