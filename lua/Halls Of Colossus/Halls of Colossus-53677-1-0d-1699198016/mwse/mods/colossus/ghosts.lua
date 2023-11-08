---@param e referenceSceneNodeCreatedEventData
local function onReferenceSceneNodeCreated(e)
    if not e.reference.id:find("^ggw_g_") then
        return
    end

    local root = e.reference.sceneNode:getObjectByName("Bip01")
        or e.reference.sceneNode:getObjectByName("Root Bone") --[[@as niNode]]

    local effect = tes3.loadMesh("ggw\\e\\ghost_effect.nif"):clone() --[[@as niNode]]

    for node in table.traverse({ root }) do
        if node:isInstanceOfType(ni.type.NiNode) then
            ---@cast node niNode
            node:detachAllEffects()
        end
        if node:isInstanceOfType(ni.type.NiAVObject) then
            ---@cast node niAVObject
            node:detachAllProperties()
        end
    end

    for _, child in pairs(root.children) do
        effect:attachChild(child)
    end

    root:attachChild(effect)

    root:updateProperties()
    root:updateEffects()
    root:update()
end
event.register("referenceSceneNodeCreated", onReferenceSceneNodeCreated, { priority = 7070 })
