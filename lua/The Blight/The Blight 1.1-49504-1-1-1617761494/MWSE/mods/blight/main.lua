-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
    require("blight.mcm")
end)

local common = require("blight.common")

require("blight.modules.diseases")
require("blight.modules.blightstorms")
require("blight.modules.blight-progression")
require("blight.modules.active-transmission")
require("blight.modules.passive-transmission")
require("blight.modules.decal-mapping")
require("blight.modules.npc-protective-gear")
require("blight.modules.blighted-tooltips")

local function initialized()
    for object in tes3.iterateObjects(tes3.objectType.spell) do
        if object.castType == tes3.spellType.blight then
            if object.id ~= "corprus" then
                common.diseases[object.id] = { id = object.id }
            end
        end
    end
    print("[Blight: INFO] Initialized")
end
event.register("initialized", initialized)
