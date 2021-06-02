require('mer.skoomaesthesia.mcm')
local Util = require('mer.skoomaesthesia.util.Util')
event.register("initialized", function()


        require('mer.skoomaesthesia.controllers.TripController')
        require('mer.skoomaesthesia.controllers.PipeController')
        require('mer.skoomaesthesia.controllers.AddictionController')
        Util.log:info("Initialized.")
end)
--Hacky workaround
event.register("initialized", function()
        tes3.getObject("ken").mesh = "skoomaesthesia\\SkoomaEquip.nif"
        tes3.getObject("todd").mesh = "skoomaesthesia\\SkoomaWorld.nif"
end, {priority = 1000})