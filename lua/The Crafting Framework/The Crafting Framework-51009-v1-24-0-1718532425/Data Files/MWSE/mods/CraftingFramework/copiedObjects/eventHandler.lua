
local CopiedObjects = require("CraftingFramework.copiedObjects")
local logger = CopiedObjects.logger
local initialized

event.register("objectCreated", function(e)
    if not initialized then return end
    local copiedFrom = e.copiedFrom
    if not copiedFrom then return end
    local trackedObjectData = CopiedObjects.getTrackedObjectData(copiedFrom.id)
    if trackedObjectData then
        logger:debug("objectCreated(): Running callback for original: %s, copy: %s", copiedFrom.id, e.object.id)
        CopiedObjects.persistCopy(copiedFrom.id, e.object.id)
        trackedObjectData.onCopied(copiedFrom, e.object)
    end
end)
event.register("initialized", function() initialized = true end)
event.register("loaded", function()
    logger:debug("Running callbacks on copied objects on load")
    for originalId, copyIds in pairs(CopiedObjects.getPersistedCopies()) do
        local original = tes3.getObject(originalId)
        --Run callbacks
        if original then
            for copyId in pairs(copyIds) do
                local copy = tes3.getObject(copyId)
                if copy then
                    local trackedObjectData = CopiedObjects.getTrackedObjectData(originalId)
                    if trackedObjectData then
                        logger:debug("- Running callback for original: %s, copy: %s", originalId, copyId)
                        trackedObjectData.onCopied(original, copy)
                    end
                end
            end
        end
    end
end)