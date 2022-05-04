local cf = mwse.loadConfig("Erratic Magic", {onOff = true, random = 50})


local function teleport(e)

    if not cf.onOff then
        if e.caster ~= tes3.player then
            return
        end
    end

    local miscast = math.random(0, 100)
    if miscast <= cf.random then
        local x = math.random(-20000, 150000)
        local y = math.random(-50000, 150000)
        local z = math.random(1, 10000)
        tes3.positionCell({reference = e.caster, position = {x, y, z}})
    end
end


local function registerModConfig()
    local template = mwse.mcm.createTemplate("Erratic Magic")

    template:saveOnClose("Erratic Magic", cf) template:register()

    local page = template:createSideBarPage({label = "Settings"})

    local category = page:createCategory("NPCs affected")
    category:createOnOffButton({label = "On/Off", description = "Toggles whether NPCs will be affected or not. [Default: On]", variable = mwse.mcm.createTableVariable{id = "onOff", table = cf}})
    local category2 = page:createCategory("Miscast Rate:")
    category2:createSlider{label = "Rate", description = "How often the random teleportation will occur, in %. Default is 50.", min = 0, max = 100, step = 1, jump = 10, variable = mwse.mcm.createTableVariable{id = "random", table = cf}}
end

event.register("modConfigReady", registerModConfig)


local function initialized()
    event.register("spellCastedFailure", teleport)
    print("Erratic Magic Initialized.")
end

event.register("initialized", initialized)