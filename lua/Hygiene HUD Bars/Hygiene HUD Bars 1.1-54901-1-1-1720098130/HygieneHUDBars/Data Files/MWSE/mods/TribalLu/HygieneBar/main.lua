local mod = {
    name = "Hygiene Bars",
    config = "HygieneBarsConfig",
    ver = "1.1",
    author = "TribalLu",
    cf = {onOff = true, slider = 5, sliderpercent = 951, switch = true, Xwidth = 73, Xheight = 15, onOff2 = true, slider2 = 5, sliderpercent2 = 943, switch2 = false, Xwidth2 = 37, Xheight2 = 8, onOff3 = true, slider3 = 41, sliderpercent3 = 943, switch3 = false, Xwidth3 = 37, Xheight3 = 8, onOff4 = true, slider4 = 5, sliderpercent4 = 966, switch4 = false, Xwidth4 = 73, Xheight4 = 7, dirtvar = 12, resolutionHor = 1920, resolutionVer = 1080}
            }
local cf = mwse.loadConfig(mod.config, mod.cf)

local ids = {
    FillbarBlock = tes3ui.registerID("HygieneBar:FillbarBlock"),
    Fillbar = tes3ui.registerID("HygieneBar:Fillbar"),
    FillbarBlock2 = tes3ui.registerID("AshBar:FillbarBlock"),
    Fillbar2 = tes3ui.registerID("AshBar:Fillbar"),
    FillbarBlock3 = tes3ui.registerID("BlightAshBar:FillbarBlock"),
    Fillbar3 = tes3ui.registerID("BlightAshBar:Fillbar"),
	FillbarBlock4 = tes3ui.registerID("DirtBar:FillbarBlock"),
    Fillbar4 = tes3ui.registerID("DirtBar:Fillbar"),
}

local function updateHygieneFillbar(fillbar)
    local current = tes3.player.data.VvardenfellAblutions.currentDirtLevel
    local max = 5

    fillbar.widget.current = current
    fillbar.widget.max = max

    fillbar.widget.fillColor = {1.0,0.7,0.8}
    fillbar.widget.showText = cf.switch
    fillbar.visible = cf.onOff
end
local function updateHygieneFillbar2(fillbar2)
    local current2 = 1
    local max2 = 1

    fillbar2.widget.current = current2
    fillbar2.widget.max = max2

    fillbar2.widget.fillColor = {0.8,0.8,0.8}
    fillbar2.widget.showText = cf.switch2
    fillbar2.visible = tes3.player.data.VvardenfellAblutions.ashy
end
local function updateHygieneFillbar3(fillbar3)
    local current3 = 1
    local max3 = 1

    fillbar3.widget.current = current3
    fillbar3.widget.max = max3

    fillbar3.widget.fillColor = {0.2,0.2,0.2}
    fillbar3.widget.showText = cf.switch3
    fillbar3.visible = tes3.player.data.VvardenfellAblutions.blighty
end

local function updateHygieneFillbar4(fillbar4)
    local current4 = tes3.player.data.VvardenfellAblutions.hygiene
    local max4 = cf.dirtvar
	
	if tes3.player.data.VvardenfellAblutions.currentDirtLevel == 1 then
		current4 = tes3.player.data.VvardenfellAblutions.hygiene - cf.dirtvar
	elseif tes3.player.data.VvardenfellAblutions.currentDirtLevel == 2 then
		current4 = tes3.player.data.VvardenfellAblutions.hygiene - math.floor( cf.dirtvar * 2 )
	elseif tes3.player.data.VvardenfellAblutions.currentDirtLevel == 3 then
		current4 = tes3.player.data.VvardenfellAblutions.hygiene - math.floor( cf.dirtvar * 3 )
	elseif tes3.player.data.VvardenfellAblutions.currentDirtLevel == 4 then
		current4 = tes3.player.data.VvardenfellAblutions.hygiene - math.floor( cf.dirtvar * 4 )
	elseif tes3.player.data.VvardenfellAblutions.currentDirtLevel == 5 then
		current4 = cf.dirtvar
	end

    fillbar4.widget.current = current4
    fillbar4.widget.max = max4

    fillbar4.widget.fillColor = {1.0,0.7,0.8}
    fillbar4.widget.showText = cf.switch4
    fillbar4.visible = cf.onOff4
end

local function createHygieneFillbar(element)
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
        updateHygieneFillbar(fillbar)

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
        updateHygieneFillbar2(fillbar2)

    local block3 = element:createRect({ id = ids.FillbarBlock3, color = {0.0, 0.0, 0.0} })
    block3.ignoreLayoutX = true
    block3.ignoreLayoutY = true
    block3.width = cf.Xwidth3
    block3.height = cf.Xheight3
    block3.borderAllSides = 2
    block3.alpha = 0.8
    block3.positionX = cf.slider3
    block3.positionY = -cf.sliderpercent3
    block3.visible = cf.onOff3

        local fillbar3 = block3:createFillBar({id = ids.Fillbar3})
        fillbar3.width = cf.Xwidth3
        fillbar3.height = cf.Xheight3
        fillbar3.widget.showText = cf.switch3
        updateHygieneFillbar3(fillbar3)
		
    local block4 = element:createRect({ id = ids.FillbarBlock4, color = {0.0, 0.0, 0.0} })
    block4.ignoreLayoutX = true
    block4.ignoreLayoutY = true
    block4.width = cf.Xwidth4
    block4.height = cf.Xheight4
    block4.borderAllSides = 2
    block4.alpha = 0.8
    block4.positionX = cf.slider4
    block4.positionY = -cf.sliderpercent4
    block4.visible = cf.onOff4

        local fillbar4 = block4:createFillBar({id = ids.Fillbar4})
        fillbar4.width = cf.Xwidth4
        fillbar4.height = cf.Xheight4
        fillbar4.widget.showText = cf.switch4
        updateHygieneFillbar4(fillbar4)

    element:updateLayout()

    return
end

local menuMultiHygieneFillbarsBlock
event.register("loaded", function()
    timer.start({
        duration = .01,
        iterations = -1,
        type = timer.real,
        callback = function()
            if (not menuMultiHygieneFillbarsBlock) then return end

            local fillbar = menuMultiHygieneFillbarsBlock:findChild(ids.Fillbar)
            if (fillbar) then
                updateHygieneFillbar(fillbar)
            end
            local fillbar2 = menuMultiHygieneFillbarsBlock:findChild(ids.Fillbar2)
            if (fillbar2) then
                updateHygieneFillbar2(fillbar2)
            end
            local fillbar3 = menuMultiHygieneFillbarsBlock:findChild(ids.Fillbar3)
            if (fillbar3) then
                updateHygieneFillbar3(fillbar3)
            end
            local fillbar4 = menuMultiHygieneFillbarsBlock:findChild(ids.Fillbar4)
            if (fillbar4) then
                updateHygieneFillbar4(fillbar4)
            end

            menuMultiHygieneFillbarsBlock:updateLayout()
        end
    })
end)

local function createMenuMultiHygieneFillbar(e)
	if not e.newlyCreated then return end

	menuMultiHygieneFillbarsBlock = e.element:findChild(tes3ui.registerID("MenuMulti_fillbars_layout"))
	menuHygieneBar = createHygieneFillbar(menuMultiHygieneFillbarsBlock)
end
event.register("uiActivated", createMenuMultiHygieneFillbar, { filter = "MenuMulti" })


local function refreshHygieneFillbarCustomization()
            local block = menuMultiHygieneFillbarsBlock:findChild(ids.FillbarBlock)
            if block then
	    block:destroy()
	    menuMultiHygieneFillbarsBlock:updateLayout()
            end
            local block2 = menuMultiHygieneFillbarsBlock:findChild(ids.FillbarBlock2)
            if block2 then
	    block2:destroy()
	    menuMultiHygieneFillbarsBlock:updateLayout()
	    end
            local block3 = menuMultiHygieneFillbarsBlock:findChild(ids.FillbarBlock3)
            if block3 then
	    block3:destroy()
	    menuMultiHygieneFillbarsBlock:updateLayout()
	    end
            local block4 = menuMultiHygieneFillbarsBlock:findChild(ids.FillbarBlock4)
            if block4 then
	    block4:destroy()
	    menuMultiHygieneFillbarsBlock:updateLayout()
	    end
	createHygieneFillbar(menuMultiHygieneFillbarsBlock)
end

local function updateHygieneFillbarCustomization()
            local block = menuMultiHygieneFillbarsBlock:findChild(ids.FillbarBlock)
            if block then	
		block.width = cf.Xwidth
		block.height = cf.Xheight
		block.positionX = cf.slider
		block.positionY = -cf.sliderpercent
		block.visible = cf.onOff
		local fillbar = menuMultiHygieneFillbarsBlock:findChild(ids.Fillbar)
		if fillbar then
		fillbar.width = cf.Xwidth
		fillbar.height = cf.Xheight
		end
	    menuMultiHygieneFillbarsBlock:updateLayout()
        end
            local block2 = menuMultiHygieneFillbarsBlock:findChild(ids.FillbarBlock2)
            if block2 then
		block2.width = cf.Xwidth2
		block2.height = cf.Xheight2
		block2.positionX = cf.slider2
		block2.positionY = -cf.sliderpercent2
		block2.visible = cf.onOff2
		local fillbar2 = menuMultiHygieneFillbarsBlock:findChild(ids.Fillbar2)
		if fillbar2 then
		fillbar2.width = cf.Xwidth2
		fillbar2.height = cf.Xheight2
		end
	    menuMultiHygieneFillbarsBlock:updateLayout()
	    end
            local block3 = menuMultiHygieneFillbarsBlock:findChild(ids.FillbarBlock3)
            if block3 then
		block3.width = cf.Xwidth3
		block3.height = cf.Xheight3
		block3.positionX = cf.slider3
		block3.positionY = -cf.sliderpercent3
		block3.visible = cf.onOff3
		local fillbar3 = menuMultiHygieneFillbarsBlock:findChild(ids.Fillbar3)
		if fillbar3 then
		fillbar3.width = cf.Xwidth3
		fillbar3.height = cf.Xheight3
		end
	    menuMultiHygieneFillbarsBlock:updateLayout()
	    end
            local block4 = menuMultiHygieneFillbarsBlock:findChild(ids.FillbarBlock4)
            if block4 then
		block4.width = cf.Xwidth4
		block4.height = cf.Xheight4
		block4.positionX = cf.slider4
		block4.positionY = -cf.sliderpercent4
		block4.visible = cf.onOff4
		local fillbar4 = menuMultiHygieneFillbarsBlock:findChild(ids.Fillbar4)
		if fillbar4 then
		fillbar4.width = cf.Xwidth4
		fillbar4.height = cf.Xheight4
		end
	    menuMultiHygieneFillbarsBlock:updateLayout()
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
	
	local category0 = page:createCategory("Welcome to \""..mod.name.."\" Configuration Menu. \n \n Hygiene Bars add in HUD bars to your screen. These bars are for the Hygiene variables from the Mod Vvardenfell Ablutions - A Bathing Mod. \n \n HUD Bar Definitions: \n Hygiene Bar = Your Hygiene level. \n Dirt Bar = The amount of dirt towards your next Hygiene Level. \n Ash Bar = Will turn Gray if you are covered in Ash. \n Blight Ash Bar = Will turn Dark Gray if you are covered in Blighted Ash.")
    
	local category1 = page:createCategory("The first thing you need to do it to set your Dirt Variable. This needs to be the same number of hours you chose in the Bathing Config Menu.")
	
	local subcat = page:createCategory(" Dirt Variable (The hours you chose in the Bathing Config Menu)")
	subcat:createSlider{label = "How fast do you get dirty?", min = 0, max = 720, step = 1, jump = 12, variable = mwse.mcm.createTableVariable{id = "dirtvar", table = cf}, callback = updateHygieneFillbarCustomization}

	local subcat = page:createCategory("On the next page you can change the Location, Size and Visibility of the Bars. \n Note: If your changes didn't take affect, Press the Refresh button.")

    local subcat = page:createCategory(" Refresh")
    subcat:createButton{label = "Click to Refresh", callback = refreshHygieneFillbarCustomization, buttonText = "Refresh"}

--Page2
	local page0 = template:createSideBarPage({label="Bar Settings"})
	
    local subcat = page0:createCategory("Hygiene Bar")

    local subcat = page0:createCategory(" Show/Hide Bar")
    subcat:createOnOffButton{label = "Show(On)/Hide(Off)", variable = mwse.mcm.createTableVariable{id = "onOff", table = cf}, callback = updateHygieneFillbarCustomization}

    local subcat = page0:createCategory(" Display Total")
    subcat:createOnOffButton{label = "On/Off", variable = mwse.mcm.createTableVariable{id = "switch", table = cf}, callback = updateHygieneFillbarCustomization}

    local subcat = page0:createCategory(" Position")
    subcat:createSlider{label = "Horizontal (Min:0 to Max:"..cf.resolutionHor..")", min = 0, max = cf.resolutionHor, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "slider", table = cf}, callback = updateHygieneFillbarCustomization}
    subcat:createSlider{label = "Vertical (Min:0 to Max:"..cf.resolutionVer..")", min = 0, max = cf.resolutionVer, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "sliderpercent", table = cf}, callback = updateHygieneFillbarCustomization}

    local subcat = page0:createCategory(" Size")
    subcat:createSlider{label = "Width", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "Xwidth", table = cf}, callback = updateHygieneFillbarCustomization}
    subcat:createSlider{label = "Height", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "Xheight", table = cf}, callback = updateHygieneFillbarCustomization}

    local subcat = page0:createCategory("Ash Bar")

    local subcat = page0:createCategory(" Show/Hide Bar")
    subcat:createOnOffButton{label = "Show(On)/Hide(Off)", variable = mwse.mcm.createTableVariable{id = "onOff2", table = cf}, callback = updateHygieneFillbarCustomization}

    --local subcat = page0:createCategory(" Display Total")
    --subcat:createOnOffButton{label = "On/Off", description = "Toggles the fillbar text. [Default: On]", variable = mwse.mcm.createTableVariable{id = "switch2", table = cf}, callback = updateHygieneFillbarCustomization}

    local subcat = page0:createCategory(" Position")
    subcat:createSlider{label = "Horizontal (Min:0 to Max:"..cf.resolutionHor..")", min = 0, max = cf.resolutionHor, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "slider2", table = cf}, callback = updateHygieneFillbarCustomization}
    subcat:createSlider{label = "Vertical (Min:0 to Max:"..cf.resolutionVer..")", min = 0, max = cf.resolutionVer, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "sliderpercent2", table = cf}, callback = updateHygieneFillbarCustomization}

    local subcat = page0:createCategory(" Size")
    subcat:createSlider{label = "Width", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "Xwidth2", table = cf}, callback = updateHygieneFillbarCustomization}
    subcat:createSlider{label = "Height", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "Xheight2", table = cf}, callback = updateHygieneFillbarCustomization}

--Page2Sidebar
    local subcat = page0.sidebar:createCategory("Dirt Bar")
	page0.sidebar.noScroll = false

    local subcat = page0.sidebar:createCategory(" Show/Hide Bar")
    page0.sidebar:createOnOffButton{label = "Show(On)/Hide(Off)", variable = mwse.mcm.createTableVariable{id = "onOff4", table = cf}, callback = updateHygieneFillbarCustomization}

    local subcat = page0.sidebar:createCategory(" Display Total")
    page0.sidebar:createOnOffButton{label = "On/Off", variable = mwse.mcm.createTableVariable{id = "switch4", table = cf}, callback = updateHygieneFillbarCustomization}

    local subcat = page0.sidebar:createCategory(" Position")
    page0.sidebar:createSlider{label = "Horizontal (Min:0 to Max:"..cf.resolutionHor..")", min = 0, max = cf.resolutionHor, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "slider4", table = cf}, callback = updateHygieneFillbarCustomization}
    page0.sidebar:createSlider{label = "Vertical (Min:0 to Max:"..cf.resolutionVer..")", min = 0, max = cf.resolutionVer, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "sliderpercent4", table = cf}, callback = updateHygieneFillbarCustomization}

    local subcat = page0.sidebar:createCategory(" Size")
    page0.sidebar:createSlider{label = "Width", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "Xwidth4", table = cf}, callback = updateHygieneFillbarCustomization}
    page0.sidebar:createSlider{label = "Height", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "Xheight4", table = cf}, callback = updateHygieneFillbarCustomization}

    local subcat = page0.sidebar:createCategory("Blight Ash Bar")

    local subcat = page0.sidebar:createCategory(" Show/Hide Bar")
    page0.sidebar:createOnOffButton{label = "Show(On)/Hide(Off)", variable = mwse.mcm.createTableVariable{id = "onOff3", table = cf}, callback = updateHygieneFillbarCustomization}

    --local subcat = page0.sidebar:createCategory(" Display Total")
    --page0.sidebar:createOnOffButton{label = "On/Off", description = "Toggles the fillbar text. [Default: On]", variable = mwse.mcm.createTableVariable{id = "switch3", table = cf}, callback = updateHygieneFillbarCustomization}

    local subcat = page0.sidebar:createCategory(" Position")
    page0.sidebar:createSlider{label = "Horizontal (Min:0 to Max:"..cf.resolutionHor..")", min = 0, max = cf.resolutionHor, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "slider3", table = cf}, callback = updateHygieneFillbarCustomization}
    page0.sidebar:createSlider{label = "Vertical (Min:0 to Max:"..cf.resolutionVer..")", min = 0, max = cf.resolutionVer, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "sliderpercent3", table = cf}, callback = updateHygieneFillbarCustomization}

    local subcat = page0.sidebar:createCategory(" Size")
    page0.sidebar:createSlider{label = "Width", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "Xwidth3", table = cf}, callback = updateHygieneFillbarCustomization}
    page0.sidebar:createSlider{label = "Height", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "Xheight3", table = cf}, callback = updateHygieneFillbarCustomization}

--Page3	
	local page1 = template:createSideBarPage({label="Other Options"})
	page1.sidebar:createInfo{ text = "Thank you for using "..mod.name..". \n A mod by "..mod.author.."."}
	page1.sidebar:createHyperLink{ text = mod.author.."'s Nexus Profile", url = "https://next.nexusmods.com/profile/TribalLu/about-me" }
	
	local subcat = page1:createCategory(" Screen Resolution     <- 1080p --- 4k ->")
    subcat:createSlider{label = "Horizontal", min = 1920, max = 3840, step = 1920, jump = 1920, variable = mwse.mcm.createTableVariable{id = "resolutionHor", table = cf}, callback = changeResolutionHor}
    subcat:createSlider{label = "Vertical", min = 1080, max = 2160, step = 1080, jump = 1080, variable = mwse.mcm.createTableVariable{id = "resolutionVer", table = cf}, callback = changeResolutionVer}

end event.register("modConfigReady", registerModConfig)
