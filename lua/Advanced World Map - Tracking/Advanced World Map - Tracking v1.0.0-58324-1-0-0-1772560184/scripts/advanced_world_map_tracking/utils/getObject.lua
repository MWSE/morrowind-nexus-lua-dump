local supportedObjectTypes = require("scripts.advanced_world_map_tracking.supportedObjectTypes")

return function(id)
    for tp, _ in pairs(supportedObjectTypes) do
        local rec = tp.record(id)
        if rec then return rec end
    end
    return nil
end