local mod = {
    name = "Thirst Bar",
    config = "Thirst Bar Config",
    ver = "2.0",
    author = "TribalLu",
    cf = {onOff = true, slider = 5, sliderpercent = 1003, switch = true, Xwidth = 65, Xheight = 14}
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


local function registerModConfig()
    local template = mwse.mcm.createTemplate(mod.name)
    template:saveOnClose(mod.config, cf)
    template:register()

    local page = template:createSideBarPage({label="\""..mod.name.."\" Settings"})
    page.sidebar:createInfo{ text = "Welcome to \""..mod.name.."\" Configuration Menu. \n \n \n A mod by "..mod.author.."."}
    page.sidebar:createHyperLink{ text = mod.author.."'s Nexus Profile", url = "https://next.nexusmods.com/profile/TribalLu/about-me" }

    local category0 = page:createCategory("Thirst Bar Config")

    local subcat = page:createCategory(" Refresh")
    subcat:createButton{label = "Click to Refresh", description = "Refreshes the Screen", callback = refreshThirstFillbarCustomization, buttonText = "Refresh"}

    local subcat = page:createCategory("Thirst Bar")

    local subcat = page:createCategory(" Show/Hide Bar")
    subcat:createOnOffButton{label = "Show(On)/Hide(Off)", description = "Turns the mod On or Off. [Default: On]", variable = mwse.mcm.createTableVariable{id = "onOff", table = cf}, callback = updateThirstFillbarCustomization}

    local subcat = page:createCategory(" Display Total")
    subcat:createOnOffButton{label = "On/Off", description = "Toggles the fillbar text. [Default: On]", variable = mwse.mcm.createTableVariable{id = "switch", table = cf}, callback = updateThirstFillbarCustomization}

    local subcat = page:createCategory(" Position")
    subcat:createSlider{label = "Horizontal", description = "Change the bars position horizontally. [Default: 5]", min = 0, max = 1920, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "slider", table = cf}, callback = updateThirstFillbarCustomization}
    subcat:createSlider{label = "Vertical", description = "Change the bars position vertically. [Default: 1003]", min = 0, max = 1080, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "sliderpercent", table = cf}, callback = updateThirstFillbarCustomization}

    local subcat = page:createCategory(" Size")
    subcat:createSlider{label = "Width", description = "Change the bars width. [Default: 65]", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "Xwidth", table = cf}, callback = updateThirstFillbarCustomization}
    subcat:createSlider{label = "Height", description = "Change the bars height. [Default: 14]", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "Xheight", table = cf}, callback = updateThirstFillbarCustomization}

end event.register("modConfigReady", registerModConfig)
