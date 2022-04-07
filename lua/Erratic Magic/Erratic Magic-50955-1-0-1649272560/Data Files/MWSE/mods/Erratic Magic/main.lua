local cf = mwse.loadConfig("Erratic Magic", {onOff = true})


local function teleport(e)

local x = math.random(-20000, 150000)
local y = math.random(-50000, 150000)
local z = math.random(1, 10000)

if not cf.onOff then
    if e.caster ~= tes3.player then return end
end

tes3.positionCell({reference = e.caster, position = {x, y, z}})

end


local function registerModConfig()
    local template = mwse.mcm.createTemplate("Erratic Magic")

    template:saveOnClose("Erratic Magic", cf) template:register()

    local page = template:createSideBarPage({label = "Settings"})

    local category = page:createCategory("NPCs affected")

    category:createOnOffButton({label = "On/Off", description = "Toggles whether NPCs will be affected or not. [Default: On]", variable = mwse.mcm.createTableVariable{id = "onOff", table = cf}})
end

event.register("modConfigReady", registerModConfig)


local function initialized()
    event.register("spellCastedFailure", teleport)
    print("Erratic Magic Initialized.")
end

event.register("initialized", initialized)