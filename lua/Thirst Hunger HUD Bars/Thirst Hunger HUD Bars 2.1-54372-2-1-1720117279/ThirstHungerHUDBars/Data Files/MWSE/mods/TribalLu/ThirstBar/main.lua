local mod = {
    name = "Thirst Bar",
    config = "ThirstBarConfig",
    ver = "2.1",
    author = "TribalLu",
    cf = {onOff = true, slider = 5, sliderpercent = 973, switch = true, Xwidth = 73, Xheight = 15, resolutionHor = 1920, resolutionVer = 1080}
            }
local cf = mwse.loadConfig(mod.config, mod.cf)

local ids = {
    FillbarBlock = tes3ui.registerID("ThirstBar:FillbarBlock"),
    Fillbar = tes3ui.registerID("ThirstBar:Fillbar"),
}

local thirstlevelGlobalVarId = 'thirstlevel'

local function updateThirstFillbar(fillbar)
    local current = tes3.getGlobal(thirstlevelGlobalVarId)
    local max = 4

    fillbar.widget.current = current
    fillbar.widget.max = max

    fillbar.widget.fillColor = {0.2,0.8,0.9}
    fillbar.widget.showText = cf.switch
    fillbar.visible = cf.onOff
end

local function createThirstFillbar(element)
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
        updateThirstFillbar(fillbar)

    element:updateLayout()

    return
end

local menuMultiThirstFillbarsBlock
event.register("loaded", function()
    timer.start({
        duration = .01,
        iterations = -1,
        type = timer.real,
        callback = function()
            if (not menuMultiThirstFillbarsBlock) then return end

            local fillbar = menuMultiThirstFillbarsBlock:findChild(ids.Fillbar)
            if (fillbar) then
                updateThirstFillbar(fillbar)
            end
            menuMultiThirstFillbarsBlock:updateLayout()
        end
    })
end)

local function createMenuMultiThirstFillbar(e)
	if not e.newlyCreated then return end

	menuMultiThirstFillbarsBlock = e.element:findChild(tes3ui.registerID("MenuMulti_fillbars_layout"))
	menuThirstBar = createThirstFillbar(menuMultiThirstFillbarsBlock)
end
event.register("uiActivated", createMenuMultiThirstFillbar, { filter = "MenuMulti" })


local function refreshThirstFillbarCustomization()
            local block = menuMultiThirstFillbarsBlock:findChild(ids.FillbarBlock)
            if block then
	    block:destroy()
	    menuMultiThirstFillbarsBlock:updateLayout()
            end
	createThirstFillbar(menuMultiThirstFillbarsBlock)
end

local function updateThirstFillbarCustomization()
            local block = menuMultiThirstFillbarsBlock:findChild(ids.FillbarBlock)
            if block then	
		block.width = cf.Xwidth
		block.height = cf.Xheight
		block.positionX = cf.slider
		block.positionY = -cf.sliderpercent
		block.visible = cf.onOff
		local fillbar = menuMultiFillbarsBlock:findChild(ids.Fillbar)
		if fillbar then
		fillbar.height = cf.Xheight
		end
	    menuMultiThirstFillbarsBlock:updateLayout()
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
	
	local category0 = page:createCategory("Welcome to \""..mod.name.."\" Configuration Menu. \n \n This mod adds in the Thirst bar to your HUD")
    
	local subcat = page:createCategory("On the next page you can change the Location, Size and Visibility of the Bars. \n Note: If your changes didn't take affect, Press the Refresh button.")

    local subcat = page:createCategory(" Refresh")
    subcat:createButton{label = "Click to Refresh", callback = refreshThirstFillbarCustomization, buttonText = "Refresh"}

--Page2
	local page0 = template:createSideBarPage({label="Bar Settings"})

    local subcat = page0:createCategory("Thirst Bar")

    local subcat = page0:createCategory(" Show/Hide Bar")
    subcat:createOnOffButton{label = "Show(On)/Hide(Off)", variable = mwse.mcm.createTableVariable{id = "onOff", table = cf}, callback = updateThirstFillbarCustomization}

    local subcat = page0:createCategory(" Display Total")
    subcat:createOnOffButton{label = "On/Off", variable = mwse.mcm.createTableVariable{id = "switch", table = cf}, callback = updateThirstFillbarCustomization}

    local subcat = page0:createCategory(" Position")
    subcat:createSlider{label = "Horizontal (Min:0 to Max:"..cf.resolutionHor..")", min = 0, max = cf.resolutionHor, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "slider", table = cf}, callback = updateThirstFillbarCustomization}
    subcat:createSlider{label = "Vertical (Min:0 to Max:"..cf.resolutionVer..")", min = 0, max = cf.resolutionVer, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "sliderpercent", table = cf}, callback = updateThirstFillbarCustomization}

    local subcat = page0:createCategory(" Size")
    subcat:createSlider{label = "Width", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "Xwidth", table = cf}, callback = updateThirstFillbarCustomization}
    subcat:createSlider{label = "Height", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "Xheight", table = cf}, callback = updateThirstFillbarCustomization}

--Page3	
	local page1 = template:createSideBarPage({label="Other Options"})
	
	local subcat = page1:createCategory(" Screen Resolution     <- 1080p --- 4k ->")
    subcat:createSlider{label = "Horizontal", min = 1920, max = 3840, step = 1920, jump = 1920, variable = mwse.mcm.createTableVariable{id = "resolutionHor", table = cf}, callback = changeResolutionHor}
    subcat:createSlider{label = "Vertical", min = 1080, max = 2160, step = 1080, jump = 1080, variable = mwse.mcm.createTableVariable{id = "resolutionVer", table = cf}, callback = changeResolutionVer}

	local subcat = page1:createCategory("")
	page1.sidebar:createInfo{ text = "Thank you for using "..mod.name..". \n A mod by "..mod.author.."."}
	page1.sidebar:createHyperLink{ text = mod.author.."'s Nexus Profile", url = "https://next.nexusmods.com/profile/TribalLu/about-me" }
	
end event.register("modConfigReady", registerModConfig)
