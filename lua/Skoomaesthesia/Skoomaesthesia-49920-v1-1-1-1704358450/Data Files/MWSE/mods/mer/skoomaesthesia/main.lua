require('mer.skoomaesthesia.mcm')
local common = require("mer.skoomaesthesia.common")
local logger = common.createLogger("Skoomaesthesia")
event.register("initialized", function()
    require('mer.skoomaesthesia.controllers.TripController')
    require('mer.skoomaesthesia.controllers.PipeController')
    require('mer.skoomaesthesia.controllers.AddictionController')
    logger:info("Initialized %s", common.getVersion())
end)
--Hacky workaround
event.register("initialized", function()
    tes3.getObject("ken").mesh = "skoomaesthesia\\SkoomaEquip.nif"
    tes3.getObject("todd").mesh = "skoomaesthesia\\SkoomaWorld.nif"
end, {priority = 1000})

--Register known items
local Skoomaesthesia = require("mer.skoomaesthesia")
local moonSugars = {
    { id = "ingred_moon_sugar_01" }
}
local skoomas = {
    { id = "ingred_skooma_01" }
}
local pipes = {
    { id = "apparatus_a_spipe_01" },
    { id = "apparatus_a_spipe_tsiya" },
    { id = "t_com_skoomapipe_01" },
}

for _, moonSugar in pairs(moonSugars) do
    Skoomaesthesia.registerMoonSugar(moonSugar)
end
for _, skooma in pairs(skoomas) do
    Skoomaesthesia.registerSkooma(skooma)
end
for _, pipe in pairs(pipes) do
    Skoomaesthesia.registerPipe(pipe)
end
