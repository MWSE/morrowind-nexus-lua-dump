local mod = {
    name = "Dynamic HUD Bars",
    config = "DynamicHUDBarsConfig",
    ver = "2.1",
    author = "TribalLu",
    cf = {onOff = true, slider = 5, sliderpercent = 3, switch = true, Xwidth = 65, Xheight = 15, onOff2 = true, slider2 = 5, sliderpercent2 = 19, switch2 = true, Xwidth2 = 65, Xheight2 = 15, onOff3 = true, slider3 = 5, sliderpercent3 = 35, switch3 = true, Xwidth3 = 65, Xheight3 = 15, resolutionHor = 1920, resolutionVer = 1080}
            }
local cf = mwse.loadConfig(mod.config, mod.cf)

local ids = {
    FillbarBlock = tes3ui.registerID("HealthBar:FillbarBlock"),
    Fillbar = tes3ui.registerID("HealthBar:Fillbar"),
    FillbarBlock2 = tes3ui.registerID("MagickaBar:FillbarBlock"),
    Fillbar2 = tes3ui.registerID("MagickaBar:Fillbar"),
    FillbarBlock3 = tes3ui.registerID("FatigueBar:FillbarBlock"),
    Fillbar3 = tes3ui.registerID("FatigueBar:Fillbar"),
}

local function updateFillbar(fillbar)
    local current = tes3.mobilePlayer.health.current
    local max = tes3.mobilePlayer.health.base

    fillbar.widget.current = current
    fillbar.widget.max = max

    fillbar.widget.fillColor = {0.78,0.24,0.12}
    fillbar.widget.showText = cf.switch
    fillbar.visible = cf.onOff
end
local function updateFillbar2(fillbar2)
    local current2 = tes3.mobilePlayer.magicka.current
    local max2 = tes3.mobilePlayer.magicka.base

    fillbar2.widget.current = current2
    fillbar2.widget.max = max2

    fillbar2.widget.fillColor = {0.21,0.27,0.62}
    fillbar2.widget.showText = cf.switch2
    fillbar2.visible = cf.onOff2
end
local function updateFillbar3(fillbar3)
    local current3 = tes3.mobilePlayer.fatigue.current
    local max3 = tes3.mobilePlayer.fatigue.base

    fillbar3.widget.current = current3
    fillbar3.widget.max = max3

    fillbar3.widget.fillColor = {0.0,0.59,0.24}
    fillbar3.widget.showText = cf.switch3
    fillbar3.visible = cf.onOff3
end


local function createFillbar(element)
    local block = element:createRect({ id = ids.FillbarBlock, color = {0.0, 0.0, 0.0} })
    block.ignoreLayoutX = true
    block.ignoreLayoutY = true
    block.width = tes3.mobilePlayer.health.base
    block.height = cf.Xheight
    block.borderAllSides = 2
    block.alpha = 0.8
    block.positionX = cf.slider
    block.positionY = -cf.sliderpercent
    block.visible = cf.onOff

        local fillbar = block:createFillBar({id = ids.Fillbar})
        fillbar.width = tes3.mobilePlayer.health.base
        fillbar.height = cf.Xheight
        fillbar.widget.showText = cf.switch
        updateFillbar(fillbar)

    local block2 = element:createRect({ id = ids.FillbarBlock2, color = {0.0, 0.0, 0.0} })
    block2.ignoreLayoutX = true
    block2.ignoreLayoutY = true
    block2.width = tes3.mobilePlayer.magicka.base
    block2.height = cf.Xheight2
    block2.borderAllSides = 2
    block2.alpha = 0.8
    block2.positionX = cf.slider2
    block2.positionY = -cf.sliderpercent2
    block2.visible = cf.onOff2

        local fillbar2 = block2:createFillBar({id = ids.Fillbar2})
        fillbar2.width = tes3.mobilePlayer.magicka.base
        fillbar2.height = cf.Xheight2
        fillbar2.widget.showText = cf.switch2
        updateFillbar2(fillbar2)

    local block3 = element:createRect({ id = ids.FillbarBlock3, color = {0.0, 0.0, 0.0} })
    block3.ignoreLayoutX = true
    block3.ignoreLayoutY = true
    block3.width = tes3.mobilePlayer.fatigue.base
    block3.height = cf.Xheight3
    block3.borderAllSides = 2
    block3.alpha = 0.8
    block3.positionX = cf.slider3
    block3.positionY = -cf.sliderpercent3
    block3.visible = cf.onOff3

        local fillbar3 = block3:createFillBar({id = ids.Fillbar3})
        fillbar3.width = tes3.mobilePlayer.fatigue.base
        fillbar3.height = cf.Xheight3
        fillbar3.widget.showText = cf.switch3
        updateFillbar3(fillbar3)

    element:updateLayout()

    return
end


local menuMultiFillbarsBlock
event.register("loaded", function()
    timer.start({ duration = .01, iterations = -1, type = timer.real, callback = function()
            if (not menuMultiFillbarsBlock) then return end

            local fillbar = menuMultiFillbarsBlock:findChild(ids.Fillbar)
            if (fillbar) then
                updateFillbar(fillbar)
            end
            local fillbar2 = menuMultiFillbarsBlock:findChild(ids.Fillbar2)
            if (fillbar2) then
                updateFillbar2(fillbar2)
            end
            local fillbar3 = menuMultiFillbarsBlock:findChild(ids.Fillbar3)
            if (fillbar3) then
                updateFillbar3(fillbar3)
            end

            menuMultiFillbarsBlock:updateLayout()
        end
    })
end)


local function createMenuMultiBloodFillbar(e)
    if not e.newlyCreated then return end

    menuMultiFillbarsBlock = e.element:findChild(tes3ui.registerID("MenuMulti_fillbars_layout"))
    menuHUDBars = createFillbar(menuMultiFillbarsBlock)
end
event.register("uiActivated", createMenuMultiBloodFillbar, { filter = "MenuMulti" })


local function refreshFillbarCustomization()
            local block = menuMultiFillbarsBlock:findChild(ids.FillbarBlock)
            if block then
	    block:destroy()
	    menuMultiFillbarsBlock:updateLayout()
            end
            local block2 = menuMultiFillbarsBlock:findChild(ids.FillbarBlock2)
            if block2 then
	    block2:destroy()
	    menuMultiFillbarsBlock:updateLayout()
	    end
            local block3 = menuMultiFillbarsBlock:findChild(ids.FillbarBlock3)
            if block3 then
	    block3:destroy()
	    menuMultiFillbarsBlock:updateLayout()
	    end
	createFillbar(menuMultiFillbarsBlock)
end

local function defaultFillbarCustomization()
	cf.Xheight = 15
	cf.slider = 5
	cf.sliderpercent = 3
	cf.onOff = true
            local block = menuMultiFillbarsBlock:findChild(ids.FillbarBlock)
            if block then
		block.height = cf.Xheight
		block.positionX = cf.slider
		block.positionY = -cf.sliderpercent
		block.visible = cf.onOff
		local fillbar = menuMultiFillbarsBlock:findChild(ids.Fillbar)
		if fillbar then
		fillbar.height = cf.Xheight
		end
	    menuMultiFillbarsBlock:updateLayout()
            end
	cf.Xheight2 = 15
	cf.slider2 = 5
	cf.sliderpercent2 = 19
	cf.onOff2 = true
            local block2 = menuMultiFillbarsBlock:findChild(ids.FillbarBlock2)
            if block2 then
		block2.height = cf.Xheight2
		block2.positionX = cf.slider2
		block2.positionY = -cf.sliderpercent2
		block2.visible = cf.onOff2
		local fillbar2 = menuMultiFillbarsBlock:findChild(ids.Fillbar2)
		if fillbar2 then
		fillbar2.height = cf.Xheight2
		end
	    menuMultiFillbarsBlock:updateLayout()
	    end
	cf.Xheight3 = 15
	cf.slider3 = 5
	cf.sliderpercent3 = 35
	cf.onOff3 = true
            local block3 = menuMultiFillbarsBlock:findChild(ids.FillbarBlock3)
            if block3 then
		block3.height = cf.Xheight3
		block3.positionX = cf.slider3
		block3.positionY = -cf.sliderpercent3
		block3.visible = cf.onOff3
		local fillbar3 = menuMultiFillbarsBlock:findChild(ids.Fillbar3)
		if fillbar3 then
		fillbar3.height = cf.Xheight3
		end
	    menuMultiFillbarsBlock:updateLayout()
	    end
end

local function updateFillbarCustomization()
            local block = menuMultiFillbarsBlock:findChild(ids.FillbarBlock)
            if block then
		block.height = cf.Xheight
		block.positionX = cf.slider
		block.positionY = -cf.sliderpercent
		block.visible = cf.onOff
		local fillbar = menuMultiFillbarsBlock:findChild(ids.Fillbar)
		if fillbar then
		fillbar.height = cf.Xheight
		end
	    menuMultiFillbarsBlock:updateLayout()
            end
            local block2 = menuMultiFillbarsBlock:findChild(ids.FillbarBlock2)
            if block2 then
		block2.height = cf.Xheight2
		block2.positionX = cf.slider2
		block2.positionY = -cf.sliderpercent2
		block2.visible = cf.onOff2
		local fillbar2 = menuMultiFillbarsBlock:findChild(ids.Fillbar2)
		if fillbar2 then
		fillbar2.height = cf.Xheight2
		end
	    menuMultiFillbarsBlock:updateLayout()
	    end
            local block3 = menuMultiFillbarsBlock:findChild(ids.FillbarBlock3)
            if block3 then
		block3.height = cf.Xheight3
		block3.positionX = cf.slider3
		block3.positionY = -cf.sliderpercent3
		block3.visible = cf.onOff3
		local fillbar3 = menuMultiFillbarsBlock:findChild(ids.Fillbar3)
		if fillbar3 then
		fillbar3.height = cf.Xheight3
		end
	    menuMultiFillbarsBlock:updateLayout()
	    end
end

local function levelUpCallback(e)
            local block = menuMultiFillbarsBlock:findChild(ids.FillbarBlock)
            if block then
	    block:destroy()
	    menuMultiFillbarsBlock:updateLayout()
            end
            local block2 = menuMultiFillbarsBlock:findChild(ids.FillbarBlock2)
            if block2 then
	    block2:destroy()
	    menuMultiFillbarsBlock:updateLayout()
	    end
            local block3 = menuMultiFillbarsBlock:findChild(ids.FillbarBlock3)
            if block3 then
	    block3:destroy()
	    menuMultiFillbarsBlock:updateLayout()
	    end
	createFillbar(menuMultiFillbarsBlock)
end
event.register(tes3.event.levelUp, levelUpCallback)

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
	
	local category0 = page:createCategory("Welcome to \""..mod.name.."\" Configuration Menu. \n \n This mod adds in custom Health, Magicka and Fatigue bars to your HUD. These bars will automatically increase in width as you level up representing the total of the stat.")

	local subcat = page:createCategory("On the next page you can change the Location, Size and Visibility of the Bars. \n Note: If your changes didn't take affect, Press the Refresh button.")

    local subcat = page:createCategory(" Refresh")
    subcat:createButton{ label = "Click to Refresh", callback = refreshFillbarCustomization, buttonText = "Refresh"}

    local subcat = page:createCategory(" Default")
    subcat:createButton{ label = "Click to Default to Top of Screen", callback = defaultFillbarCustomization, buttonText = "Default"}

--Page2
	local page0 = template:createSideBarPage({label="Bar Settings"})

    local subcat = page0:createCategory("Health Bar")

    local subcat = page0:createCategory(" Show/Hide Bar")
    subcat:createOnOffButton{label = "Show(On)/Hide(Off)", variable = mwse.mcm.createTableVariable{id = "onOff", table = cf}, callback = updateFillbarCustomization}

    local subcat = page0:createCategory(" Display Total")
    subcat:createOnOffButton{label = "On/Off", variable = mwse.mcm.createTableVariable{id = "switch", table = cf}, callback = updateFillbarCustomization}

    local subcat = page0:createCategory(" Position")
    subcat:createSlider{label = "Horizontal (Min:0 to Max:"..cf.resolutionHor..")", min = 0, max = cf.resolutionHor, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "slider", table = cf}, callback = updateFillbarCustomization}
    subcat:createSlider{label = "Vertical (Min:0 to Max:"..cf.resolutionVer..")", min = 0, max = cf.resolutionVer, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "sliderpercent", table = cf}, callback = updateFillbarCustomization}

    local subcat = page0:createCategory(" Size")
--    subcat:createSlider{label = "Width", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "Xwidth", table = cf}, callback = updateFillbarCustomization}
    subcat:createSlider{label = "Height", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "Xheight", table = cf}, callback = updateFillbarCustomization}

    local subcat = page0:createCategory("Magicka Bar")

    local subcat = page0:createCategory(" Show/Hide Bar")
    subcat:createOnOffButton{label = "Show(On)/Hide(Off)", variable = mwse.mcm.createTableVariable{id = "onOff2", table = cf}, callback = updateFillbarCustomization}

    local subcat = page0:createCategory(" Display Total")
    subcat:createOnOffButton{label = "On/Off", variable = mwse.mcm.createTableVariable{id = "switch2", table = cf}, callback = updateFillbarCustomization}

    local subcat = page0:createCategory(" Position")
    subcat:createSlider{label = "Horizontal (Min:0 to Max:"..cf.resolutionHor..")", min = 0, max = cf.resolutionHor, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "slider2", table = cf}, callback = updateFillbarCustomization}
    subcat:createSlider{label = "Vertical (Min:0 to Max:"..cf.resolutionVer..")", min = 0, max = cf.resolutionVer, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "sliderpercent2", table = cf}, callback = updateFillbarCustomization}

    local subcat = page0:createCategory(" Size")
--    subcat:createSlider{label = "Width", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "Xwidth2", table = cf}, callback = updateFillbarCustomization}
    subcat:createSlider{label = "Height", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "Xheight2", table = cf}, callback = updateFillbarCustomization}

--Page2Sidebar
	page0.sidebar.noScroll = false
    local subcat = page0.sidebar:createCategory("Fatigue Bar")

    local subcat = page0.sidebar:createCategory(" Show/Hide Bar")
    page0.sidebar:createOnOffButton{label = "Show(On)/Hide(Off)", variable = mwse.mcm.createTableVariable{id = "onOff3", table = cf}, callback = updateFillbarCustomization}

    local subcat = page0.sidebar:createCategory(" Display Total")
    page0.sidebar:createOnOffButton{label = "On/Off", variable = mwse.mcm.createTableVariable{id = "switch3", table = cf}, callback = updateFillbarCustomization}

    local subcat = page0.sidebar:createCategory(" Position")
    page0.sidebar:createSlider{label = "Horizontal (Min:0 to Max:"..cf.resolutionHor..")", min = 0, max = cf.resolutionHor, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "slider3", table = cf}, callback = updateFillbarCustomization}
    page0.sidebar:createSlider{label = "Vertical (Min:0 to Max:"..cf.resolutionVer..")", min = 0, max = cf.resolutionVer, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "sliderpercent3", table = cf}, callback = updateFillbarCustomization}

    local subcat = page0.sidebar:createCategory(" Size")
--    page0.sidebar:createSlider{label = "Width", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "Xwidth3", table = cf}, callback = updateFillbarCustomization}
    page0.sidebar:createSlider{label = "Height", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "Xheight3", table = cf}, callback = updateFillbarCustomization}

--Page3	
	local page1 = template:createSideBarPage({label="Other Options"})
	
	local subcat = page1:createCategory(" Screen Resolution     <- 1080p --- 4k ->")
    subcat:createSlider{label = "Horizontal", min = 1920, max = 3840, step = 1920, jump = 1920, variable = mwse.mcm.createTableVariable{id = "resolutionHor", table = cf}, callback = changeResolutionHor}
    subcat:createSlider{label = "Vertical", min = 1080, max = 2160, step = 1080, jump = 1080, variable = mwse.mcm.createTableVariable{id = "resolutionVer", table = cf}, callback = changeResolutionVer}

	local subcat = page1:createCategory("")
	page1.sidebar:createInfo{ text = "Thank you for using "..mod.name..". \n A mod by "..mod.author.."."}
	page1.sidebar:createHyperLink{ text = mod.author.."'s Nexus Profile", url = "https://next.nexusmods.com/profile/TribalLu/about-me" }
	
end event.register("modConfigReady", registerModConfig)
