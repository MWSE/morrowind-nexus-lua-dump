local mod = {
    name = "Hunger Bar",
    config = "Hunger Bar Config",
    ver = "2.0",
    author = "TribalLu",
    cf = {onOff = true, slider = 5, sliderpercent = 1018, switch = true, Xwidth = 65, Xheight = 14}
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


local function registerModConfig()
    local template = mwse.mcm.createTemplate(mod.name)
    template:saveOnClose(mod.config, cf)
    template:register()

    local page = template:createSideBarPage({label="\""..mod.name.."\" Settings"})
    page.sidebar:createInfo{ text = "Welcome to \""..mod.name.."\" Configuration Menu. \n \n \n A mod by "..mod.author.."."}
    page.sidebar:createHyperLink{ text = mod.author.."'s Nexus Profile", url = "https://next.nexusmods.com/profile/TribalLu/about-me" }

    local category0 = page:createCategory("Hunger Bar Config")

    local subcat = page:createCategory(" Refresh")
    subcat:createButton{label = "Click to Refresh", description = "Refreshes the Screen", callback = refreshHungerFillbarCustomization, buttonText = "Refresh"}

    local subcat = page:createCategory("Hunger Bar")

    local subcat = page:createCategory(" Show/Hide Bar")
    subcat:createOnOffButton{label = "Show(On)/Hide(Off)", description = "Turns the mod On or Off. [Default: On]", variable = mwse.mcm.createTableVariable{id = "onOff", table = cf}, callback = updateHungerFillbarCustomization}

    local subcat = page:createCategory(" Display Total")
    subcat:createOnOffButton{label = "On/Off", description = "Toggles the fillbar text. [Default: On]", variable = mwse.mcm.createTableVariable{id = "switch", table = cf}, callback = updateHungerFillbarCustomization}

    local subcat = page:createCategory(" Position")
    subcat:createSlider{label = "Horizontal", description = "Change the bars position horizontally. [Default: 5]", min = 0, max = 1920, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "slider", table = cf}, callback = updateHungerFillbarCustomization}
    subcat:createSlider{label = "Vertical:", description = "Change the bars position vertically. [Default: 1018]", min = 0, max = 1080, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "sliderpercent", table = cf}, callback = updateHungerFillbarCustomization}

    local subcat = page:createCategory(" Size")
    subcat:createSlider{label = "Width", description = "Change the bars width. [Default: 65]", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "Xwidth", table = cf}, callback = updateHungerFillbarCustomization}
    subcat:createSlider{label = "Height", description = "Change the bars height. [Default: 14]", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "Xheight", table = cf}, callback = updateHungerFillbarCustomization}

end event.register("modConfigReady", registerModConfig)
