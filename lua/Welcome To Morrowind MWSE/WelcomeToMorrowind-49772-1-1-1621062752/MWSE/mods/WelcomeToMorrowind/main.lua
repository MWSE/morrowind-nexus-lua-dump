local defaultConfig = ({toggle = true, spawnChance = 100, spawnNum = 4, spawnDist = 3000 })
local config = mwse.loadConfig ("WelcomeToMorrowind", defaultConfig)
local function onDeath(e)
    if config.toggle == false then return end
    local spawnRNG = math.random(100)
    if spawnRNG > config.spawnChance then return end
    if e.reference.baseObject.id == "cliff racer" then
        mwscript.placeAtPC {object = "cliff racer", distance = config.spawnDist, direction = 0}
        if config.spawnNum < 2 then return end
        mwscript.placeAtPC {object = "cliff racer", distance = config.spawnDist, direction = 1}
        if config.spawnNum < 3 then return end
        mwscript.placeAtPC {object = "cliff racer", distance = config.spawnDist, direction = 2}
        if config.spawnNum < 4 then return end
        mwscript.placeAtPC {object = "cliff racer", distance = config.spawnDist, direction = 3}
    end
end
event.register("death", onDeath)
local function registerModConfig()
	local template = mwse.mcm.createTemplate("WelcomeToMorrowind")
    template:saveOnClose("WelcomeToMorrowind", config)
    local page = template:createPage()
    local category = page:createCategory("Settings")
    category:createOnOffButton({
    label = "Enable spawn",
    variable = mwse.mcm:createTableVariable{id = "toggle", table = config}
    })
    category:createSlider({
    label = "Spawn chance",
    min = 1,
    max = 100,
    step = 1,
    jump = 10,
    variable = mwse.mcm.createTableVariable{id = "spawnChance", table = config},
    })
    category:createSlider({
    label = "Number of spawns",
    min = 1,
    max = 4,
    step = 1,
    jump = 1,
    variable = mwse.mcm.createTableVariable{id = "spawnNum", table = config},
    })
    category:createSlider({
    label = "Spawn distance",
    min = 1,
    max = 5000,
    step = 1,
    jump = 100,
    variable = mwse.mcm.createTableVariable{id = "spawnDist", table = config},
    })
    mwse.mcm.register(template)
end
event.register("modConfigReady", registerModConfig)