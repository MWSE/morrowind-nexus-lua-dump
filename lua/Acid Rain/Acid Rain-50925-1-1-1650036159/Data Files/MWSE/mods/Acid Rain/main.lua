local cf = mwse.loadConfig("Acid Rain", { rad = 50, onOff = true, blocked = {} })

local r = 100
local myTimer = nil


local function getCells()
    local list = {}
    for _,cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
        if (cell.isOrBehavesAsExterior == true and cell.restingIsIllegal == false) then
            table.insert(list, cell.id)
        end
    end
    table.sort(list)
    return list
end


local function acidRainMyTimer()
    if cf.onOff then
    tes3.messageBox("You should find a shelter, the rain is hurting you.") end
    tes3.mobilePlayer:applyDamage({ damage = 1, applyArmor = true, resistAttribute = 9 })
end

local function acidRain()

    if myTimer then
        myTimer:cancel()
        myTimer = nil
    end

    local cell = tes3.mobilePlayer.cell
    if (cell.isOrBehavesAsExterior == false or cell.restingIsIllegal == true or table.find(cf.blocked, cell.id)) then
        return
    end

    local weather = tes3.getCurrentWeather()
    local weatherCheck = weather.index
    if (weatherCheck == tes3.weather.rain or weatherCheck == tes3.weather.thunder) then
        r = math.random(1, 100)
        print(r)
        if r <= cf.rad then
            myTimer = timer.start({duration = 1, callback = acidRainMyTimer, iterations = -1 })
        end
    end
end

local function acidRain2()
    local cell = tes3.mobilePlayer.cell
    if (cell.isOrBehavesAsExterior == false or cell.restingIsIllegal == true) then
        return
    end
    local weather = tes3.getCurrentWeather()
    local weatherCheck = weather.index
    if (weatherCheck == tes3.weather.rain or weatherCheck == tes3.weather.thunder) then
        if r <= cf.rad then
            tes3.messageBox("You can't rest during an acid rain, find a shelter!")
            return false
        end
    end

end


local function registerModConfig()
    local template = mwse.mcm.createTemplate("Acid Rain")
    template:saveOnClose("Acid Rain", cf)
    template:register()
    local page = template:createSideBarPage({ label = "Acid Rain" })
    local category = page:createCategory("Acid Rain Chance")
    category:createSlider { label = "Chances for the rain to be acid, in %", min = 0, max = 100, step = 1, jump = 10, variable = mwse.mcm.createTableVariable { id = "rad", table = cf } }
    local category1 = page:createCategory("Toggle MessageBox")
    category1:createOnOffButton({label = "On/Off", description = "Toggles whether the message \"The acid is hurting you, find a shelter.\" will display or not. [Default: On]", variable = mwse.mcm.createTableVariable{id = "onOff", table = cf}})
    template:createExclusionsPage{label = "Cell Config", description = "Here you are.", variable = mwse.mcm.createTableVariable{id = "blocked", table = cf}, filters = {{label = "Cells", callback = getCells}}}
end event.register("modConfigReady", registerModConfig)





local function initialized()
    event.register("weatherTransitionFinished", acidRain)
    event.register("weatherChangedImmediate", acidRain)
    event.register("cellChanged", acidRain)
    event.register("uiShowRestMenu", acidRain2)
    print("[Acid Rain] Acid Rain initialized")
end event.register("initialized", initialized)
