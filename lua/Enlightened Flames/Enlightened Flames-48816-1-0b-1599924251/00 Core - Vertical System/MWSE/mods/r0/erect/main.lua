local function getLookUpTargetParent()
    local root = tes3.worldController.armCamera.cameraRoot.parent
    -- re-use it if already exists
    for _, node in pairs(root.children) do
        if node.name == "LookUpTargetParent" then
            return node
        end
    end
    -- otherwise create a new node
    node = niNode.new()
    node.name = "LookUpTargetParent"
    node.translation.z = 3.4e38
    root:attachChild(node)
    return node
end

event.register("meshLoaded", function(e)
    if e.node:hasStringDataStartingWith("hasLookUp") then
        local node = e.node:getObjectByName("LookUpTarget")
        if node then
            getLookUpTargetParent():attachChild(node)
        end
    end
end)