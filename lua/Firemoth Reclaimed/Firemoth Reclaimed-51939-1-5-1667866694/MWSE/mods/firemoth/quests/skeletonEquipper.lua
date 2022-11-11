local targetMeshes = table.invert({
    "meshes\\fm\\r\\xskeleton_rising_1.nif",
    "meshes\\fm\\r\\xskeleton_rising_2.nif",
})

local targetCreatures = table.invert({
    assert(tes3.getObject("fm_skeleton_1")),
    assert(tes3.getObject("fm_skeleton_2")),
})

---@type tes3armor[]
local targetArmors = {
    assert(tes3.getObject("imperial boots")),
    assert(tes3.getObject("imperial cuirass_armor")),
    assert(tes3.getObject("imperial helmet armor")),
    assert(tes3.getObject("imperial right gauntlet")),
    assert(tes3.getObject("imperial right pauldron")),
    assert(tes3.getObject("imperial skirt_clothing")),
}

local partConfigs = {
    [1] = { name = "Head", translation = tes3vector3.new(0, 2.8, 2.0) },
    [4] = { name = "Chest" },
    [8] = { name = "Right Upper Arm" },
    [9] = { name = "Right Foot" },
    [10] = { name = "Right Ankle" },
    [13] = { name = "Right Clavicle" },
}

local regular = { "Head", "Right Upper Arm", "Right Foot", "Right Ankle", "Right Clavicle" }
local skinned = { "Groin", "Chest" }


local function attachRegular(sceneNode, partNode, partIndex)
    local config = partConfigs[partIndex]
    if config then
        assert(sceneNode:getObjectByName(config.name)):attachChild(partNode)
        if config.translation then
            partNode.translation = partNode.translation + config.translation
        end
    end
end

local function attachSkinned(sceneNode, partNode)
    for node in table.traverse(partNode.children) do
        local skin = node.skinInstance
        local root = skin and skin.root
        if root and root.name == "Bip01" then
            pcall(function()
                skin.root = assert(sceneNode:getObjectByName(root.name))
                for i, bone in ipairs(skin.bones) do
                    skin.bones[i] = assert(sceneNode:getObjectByName(bone.name))
                end
                skin.root:attachChild(node)
            end)
        end
    end
end

local function isSkinned(root)
    for node in table.traverse(root.children) do
        if node.skinInstance then
            return true
        end
    end
end

local function patchMesh(sceneNode)
    for _, armor in pairs(targetArmors) do
        for _, p in pairs(armor.parts) do
            if p.male then
                local root = tes3.loadMesh(p.male and p.male.mesh)
                if root then
                    if isSkinned(root) then
                        attachSkinned(sceneNode, root:clone())
                    else
                        attachRegular(sceneNode, root:clone(), p.male.part)
                    end
                end
            end
        end
    end
end

event.register(tes3.event.meshLoaded, function(e)
    ---@cast e meshLoadedEventData
    if targetMeshes[e.path:lower()] then
        patchMesh(e.node)
    end
end)

event.register(tes3.event.referenceSceneNodeCreated, function(e)
    ---@cast e referenceSceneNodeCreatedEventData
    if targetCreatures[e.reference.baseObject] then
        local bip01 = e.reference.sceneNode:getObjectByName("Bip01")
        -- Show random regular equipment.
        for _, name in pairs(regular) do
            if math.random() > 0.5 then
                local node = assert(bip01:getObjectByName(name))
                node.appCulled = true
                node:update()
            end
        end
        -- Show random skinned equipment.
        for _, name in pairs(skinned) do
            if math.random() > 0.5 then
                for _, child in pairs(bip01.children) do
                    if child and child.name:gsub("Tri ", ""):startswith(name) then
                        child.appCulled = true
                        child:update()
                    end
                end
            end
        end
    end
end)
