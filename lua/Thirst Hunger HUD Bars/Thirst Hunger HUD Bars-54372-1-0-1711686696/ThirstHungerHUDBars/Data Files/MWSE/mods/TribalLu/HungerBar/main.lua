local mod = {
    name = "Hunger Bar",
    ver = "1.0",
    author = "TribalLu",
    cf = {onOff = true, slider = 0, sliderpercent = 957, switch = true, Xwidth = 65, Xheight = 14}
            }
local cf = mwse.loadConfig(mod.name, mod.cf)

local ids = {
    FillbarBlock = tes3ui.registerID("HungerBar:FillbarBlock"),
    Fillbar = tes3ui.registerID("HungerBar:Fillbar"),
}

local hungerlevelGlobalVarId = 'hungerlevel'

local function updateFillbar(fillbar)
    local current = tes3.getGlobal(hungerlevelGlobalVarId)
    local max = 4

    fillbar.widget.current = current
    fillbar.widget.max = max

    fillbar.widget.fillColor = {0.9,0.7,0.2}
    fillbar.widget.showText = cf.switch
    fillbar.visible = cf.onOff
end

local function createFillbar(element)
    local block = element:createRect({
        id = ids.FillbarBlock,
        color = {0.0, 0.0, 0.0}
    })
    block.width = cf.Xwidth --65
    block.height = cf.Xheight --14
    block.borderAllSides = 2
    block.alpha = 0.8
    --block.absolutePosAlignX = 0
    --block.absolutePosAlignY = 957/1000
    block.absolutePosAlignX = cf.slider/1000
    block.absolutePosAlignY = cf.sliderpercent/1000
    block.visible = cf.onOff

        local fillbar = block:createFillBar({id = ids.Fillbar})
        fillbar.width = cf.Xwidth --65
        fillbar.height = cf.Xheight --14
        fillbar.widget.showText = false
        updateFillbar(fillbar)

    element:updateLayout()

    return block
end

local menuMultiFillbarsBlock
event.register("loaded", function()
    timer.start({
        duration = .01,
        iterations = -1,
        type = timer.real,
        callback = function()
            if (not menuMultiFillbarsBlock) then return end

            local fillbar = menuMultiFillbarsBlock:findChild(ids.Fillbar)
            if (fillbar) then
                updateFillbar(fillbar)
            end

            menuMultiFillbarsBlock:updateLayout()
        end
    })
end)

local function createMenuMultiBloodFillbar(e)
    if not e.newlyCreated then return end

    menuMultiFillbarsBlock = e.element:findChild(tes3ui.registerID("MenuMulti_fillbars_layout"))
    menuHungerBar = createFillbar(menuMultiFillbarsBlock)
end
event.register("uiActivated", createMenuMultiBloodFillbar, { filter = "MenuMulti" })




local function registerModConfig()
    local template = mwse.mcm.createTemplate(mod.name)
    template:saveOnClose(mod.name, cf)
    template:register()

    local page = template:createSideBarPage({label="\""..mod.name.."\" Settings"})
    page.sidebar:createInfo{ text = "Welcome to \""..mod.name.."\" Configuration Menu. \n \n \n A mod by "..mod.author.."."}
    page.sidebar:createHyperLink{ text = mod.author.."'s Nexus Profile", url = "https://www.nexusmods.com/users/203609459" }

    local category0 = page:createCategory("Show/Hide Bar - Reload to take full effect")
    category0:createOnOffButton{label = "Show(On)/Hide(Off)", description = "Turns the mod On or Off. [Default: On]", variable = mwse.mcm.createTableVariable{id = "onOff", table = cf}}

    local subcat = page:createCategory("Display Total")
    subcat:createOnOffButton{label = "On/Off", description = "Toggles the fillbar text. [Default: On]", variable = mwse.mcm.createTableVariable{id = "switch", table = cf}}

    local subcat = page:createCategory("Position - Reload Required")
    subcat:createSlider{label = "Horizontal", description = "Change the bars position horizontally. [Default: 0]", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "slider", table = cf}}
    subcat:createSlider{label = "Vertical:", description = "Change the bars position vertically. [Default: 957]", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "sliderpercent", table = cf}}

    local subcat = page:createCategory("Size - Reload Required")
    subcat:createSlider{label = "Width", description = "Change the bars width. [Default: 65]", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "Xwidth", table = cf}}
    subcat:createSlider{label = "Height", description = "Change the bars height. [Default: 14]", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "Xheight", table = cf}}

end event.register("modConfigReady", registerModConfig)
