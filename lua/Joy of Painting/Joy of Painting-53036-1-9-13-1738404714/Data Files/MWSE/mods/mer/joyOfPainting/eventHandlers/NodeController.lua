local NodeManager = require("mer.joyOfPainting.services.NodeManager")
local ReferenceManager = require("mer.joyOfPainting.services.ReferenceManager")

---@param e referenceSceneNodeCreatedEventData
local function manageSceneNodeCreated(e)
    if not e.reference then return end
    for _, switch in pairs(NodeManager.switches) do
        if switch:requirements(e.reference) then
            ReferenceManager.registerReference(e.reference)
            NodeManager.processSwitch(switch, e.reference)
        end
    end
end

--event.register("referenceSceneNodeCreated", manageSceneNodeCreated)
