local lightMeshes = {}
event.register("initialized", function(e)
    for light in tes3.iterateObjects(tes3.objectType.light) do
        lightMeshes["meshes\\" .. light.mesh:lower()] = true
        lightMeshes["meshes\\x" .. light.mesh:lower()] = true
    end
end)

-- remove flames for off by default lights
event.register("referenceSceneNodeCreated", function(e)
    if e.reference.object.isOffByDefault then
        for node in table.traverse{e.reference.sceneNode} do
            if node.name == "CandleFlameAnimNode" then
                node.appCulled = true
            end
        end
    end
end)

-- get the replacement for a node based on its name
local function getReplacement(node)
    return pcall(function()
		local fileName = node.parent.name
		local replacement = "\\r0\\l\\" .. fileName .. ".nif"
		if tes3.getFileExists("meshes\\" .. replacement) then
            return tes3.loadMesh(replacement):clone()
        end
    end)
end

local function onMeshLoaded(e)
    if not lightMeshes[e.path:lower()] then
        return
    end

    for node in table.traverse{e.node} do
        if node:isInstanceOfType(tes3.niType.NiParticles) then
            local success, replacement = getReplacement(node)
            if success and replacement then
                local parent = node.parent
                parent:detachChild(node)
                parent:attachChild(replacement, true)
				if bit.band(parent.flags, 128) == 0 then
                    parent.flags = bit.bor(parent.flags, 128)
                end
            end
        end
    end
end
event.register("meshLoaded", onMeshLoaded)
