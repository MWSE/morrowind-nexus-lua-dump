local mod = {
    name = "Hunger Bar",
    config = "HungerBarConfig",
    ver = "2.1",
    author = "TribalLu",
    cf = {onOff = true, slider = 5, sliderpercent = 988, switch = true, Xwidth = 73, Xheight = 15, resolutionHor = 1920, resolutionVer = 1080}
            }
local cf = mwse.loadConfig(mod.config, mod.cf)

local ids = {
    FillbarBlock = tes3ui.registerID("HungerBar:FillbarBlock"),
    Fillbar = tes3ui.registerID("HungerBar:Fillbar"),
}

local hungerlevelGlobalVarId = 'hungerlevel'

local function updateHungerFillbar(fillbar)
    local current = tes3.getGlobal(hungerlevelGlobalVarId)
    local max = 4

    fillbar.widget.current = current
    fillbar.widget.max = max

    fillbar.widget.fillColor = {0.9,0.7,0.2}
    fillbar.widget.showText = cf.switch
    fillbar.visible = cf.onOff
end

local function createHungerFillbar(element)
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
        fillbar.widget.showText = false
        updateHungerFillbar(fillbar)

    element:updateLayout()

    return
end

local menuMultiHungerFillbarsBlock
event.register("loaded", function()
    timer.start({
        duration = .01,
        iterations = -1,
        type = timer.real,
        callback = function()
            if (not menuMultiHungerFillbarsBlock) then return end

            local fillbar = menuMultiHungerFillbarsBlock:findChild(ids.Fillbar)
            if (fillbar) then
                updateHungerFillbar(fillbar)
            end

            menuMultiHungerFillbarsBlock:updateLayout()
        end
    })
end)


local function createMenuMultiHungerFillbar(e)
    if not e.newlyCreated then return end

    menuMultiHungerFillbarsBlock = e.element:findChild(tes3ui.registerID("MenuMulti_fillbars_layout"))
    menuHungerBar = createHungerFillbar(menuMultiHungerFillbarsBlock)
end
event.register("uiActivated", createMenuMultiHungerFillbar, { filter = "MenuMulti" })


local function refreshHungerFillbarCustomization()
            local block = menuMultiHungerFillbarsBlock:findChild(ids.FillbarBlock)
            if block then
	    block:destroy()
	    menuMultiHungerFillbarsBlock:updateLayout()
            end
	createHungerFillbar(menuMultiHungerFillbarsBlock)
end

local function updateHungerFillbarCustomization()
            local block = menuMultiHungerFillbarsBlock:findChild(ids.FillbarBlock)
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
	    menuMultiHungerFillbarsBlock:updateLayout()
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
	
	local category0 = page:createCategory("Welcome to \""..mod.name.."\" Configuration Menu. \n \n This mod adds in the Hunger bar to your HUD")
    
	local subcat = page:createCategory("On the next page you can change the Location, Size and Visibility of the Bars. \n Note: If your changes didn't take affect, Press the Refresh button.")

    local subcat = page:createCategory(" Refresh")
    subcat:createButton{label = "Click to Refresh", callback = refreshHungerFillbarCustomization, buttonText = "Refresh"}

--Page2
	local page0 = template:createSideBarPage({label="Bar Settings"})

    local subcat = page0:createCategory("Hunger Bar")

    local subcat = page0:createCategory(" Show/Hide Bar")
    subcat:createOnOffButton{label = "Show(On)/Hide(Off)", variable = mwse.mcm.createTableVariable{id = "onOff", table = cf}, callback = updateHungerFillbarCustomization}

    local subcat = page0:createCategory(" Display Total")
    subcat:createOnOffButton{label = "On/Off", variable = mwse.mcm.createTableVariable{id = "switch", table = cf}, callback = updateHungerFillbarCustomization}

    local subcat = page0:createCategory(" Position")
    subcat:createSlider{label = "Horizontal (Min:0 to Max:"..cf.resolutionHor..")", min = 0, max = cf.resolutionHor, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "slider", table = cf}, callback = updateHungerFillbarCustomization}
    subcat:createSlider{label = "Vertical (Min:0 to Max:"..cf.resolutionVer..")", min = 0, max = cf.resolutionVer, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "sliderpercent", table = cf}, callback = updateHungerFillbarCustomization}

    local subcat = page0:createCategory(" Size")
    subcat:createSlider{label = "Width", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "Xwidth", table = cf}, callback = updateHungerFillbarCustomization}
    subcat:createSlider{label = "Height", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "Xheight", table = cf}, callback = updateHungerFillbarCustomization}

--Page3	
	local page1 = template:createSideBarPage({label="Other Options"})
	
	local subcat = page1:createCategory(" Screen Resolution     <- 1080p --- 4k ->")
    subcat:createSlider{label = "Horizontal", min = 1920, max = 3840, step = 1920, jump = 1920, variable = mwse.mcm.createTableVariable{id = "resolutionHor", table = cf}, callback = changeResolutionHor}
    subcat:createSlider{label = "Vertical", min = 1080, max = 2160, step = 1080, jump = 1080, variable = mwse.mcm.createTableVariable{id = "resolutionVer", table = cf}, callback = changeResolutionVer}

	local subcat = page1:createCategory("")
	page1.sidebar:createInfo{ text = "Thank you for using "..mod.name..". \n A mod by "..mod.author.."."}
	page1.sidebar:createHyperLink{ text = mod.author.."'s Nexus Profile", url = "https://next.nexusmods.com/profile/TribalLu/about-me" }

end event.register("modConfigReady", registerModConfig)
