local supportedObjectTypes = require("scripts.proximityTool.supportedObjectTypes")

return function(id)
    for tp, _ in pairs(supportedObjectTypes) do
        local rec = tp.record(id)
        if rec then return rec end
    end
    return nil
end