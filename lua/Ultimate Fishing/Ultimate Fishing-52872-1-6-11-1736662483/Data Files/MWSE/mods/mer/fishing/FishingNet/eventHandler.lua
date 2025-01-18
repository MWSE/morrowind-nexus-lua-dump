local common = require("mer.fishing.common")
local config = require("mer.fishing.config")
local logger = common.createLogger("FishingNet")
local FishingNet = require("mer.fishing.FishingNet")

---When a fishing net is copied (enchanted, dripified etc),
--- register the new object, and add it to persistent data
--- so it can be registered on subsequent loads
---@param e objectCreatedEventData
event.register("objectCreated", function(e)
    if e.copiedFrom and FishingNet.get(e.copiedFrom.id) then
        logger:info("objectCreated: registering fishing rod %s", e.object.id)
        FishingNet.register{ id = e.object.id}
        config.persistent.copiedFishingNets[e.copiedFrom.id:lower()] = e.object.id:lower()
    end
end)

event.register("loaded", function(e)
    --Register copied fishing rods
    for originalId, copiedId in pairs(config.persistent.copiedFishingNets) do
        logger:info("Registering copied fishing net. Original: %s, New: %s",
        originalId, copiedId)
        if FishingNet.get(originalId) then
            FishingNet.register{id = copiedId}
        end
    end
end)