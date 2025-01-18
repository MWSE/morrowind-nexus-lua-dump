--[[
    ...
--]]

local backpacks = {
    ["aa_backpack_a"] = true,
    ["aa_backpack_AF"] = true,
    ["aa_backpack_BN"] = true,
    ["aa_backpack_dummy"] = true,
    ["aa_backpack_FW"] = true,
    ["aa_backpack_NoM"] = true,
	["aa_backpack_comp"] = true,
}

local backpackSlot = 11

local backpackOffset = {
    translation = tes3vector3.new(22.9866, 0.5588, -1.9998),
    rotation = tes3matrix33.new(0.2339, -0.0440, 0.9713, 0.0114, -0.9988, -0.0480, 0.9722, 0.0222, -0.2331),
    scale = 1,
}


local function registerBackpacks()
    pcall(function()
        tes3.addArmorSlot{slot=backpackSlot, name="Backpack"}
    end)
    for id in pairs(backpacks) do
        local obj = tes3.getObject(id)
        -- remap slot to custom backpackSlot
        obj.slot = backpackSlot
        -- store the bodypart mesh for later
        backpacks[id] = obj.parts[1].male.mesh
        -- clear bodypart so it doesn't overwrite left pauldron
        obj.parts[1].type = 255
        obj.parts[1].male = nil
        mwse.log("[Adventurer's Backpack]: Registered backpack: %s (slot=%s)", obj, obj.slot)
    end
end


local function attachBackpack(parent, fileName)
    local node = tes3.loadMesh(fileName)
    if node then
        node = node:clone()
        -- rename the root node so we can easily find it for detaching
        node.name = "Bip01 AttachBackpack"
        -- offset the node to emulate vanilla's left pauldron behavior
        node.translation = backpackOffset.translation:copy()
        node.rotation = backpackOffset.rotation:copy()
        node.scale = backpackOffset.scale
        parent:attachChild(node, true)
    end
end


local function detachBackpack(parent)
    local node = parent:getObjectByName("Bip01 AttachBackpack")
    if node then
        parent:detachChild(node)
    end
end



local function onEquipped(e)
    -- must be a valid backpack
    local fileName = backpacks[e.item.id]
    if not fileName then return end

    -- get parent for attaching
    local parent = e.reference.sceneNode:getObjectByName("Bip01 Spine1")

    -- detach old backpack mesh
    detachBackpack(parent)

    -- attach new backpack mesh
    attachBackpack(parent, fileName)

    -- update parent scene node
    parent:update()
    parent:updateNodeEffects()
end


local function onUnequipped(e)
    -- must be a valid backpack
    local fileName = backpacks[e.item.id]
    if not fileName then return end

    -- get parent for detaching
    local parent = e.reference.sceneNode:getObjectByName("Bip01 Spine1")

    -- detach old backpack mesh
    detachBackpack(parent)

    -- update parent scene node
    parent:update()
    parent:updateNodeEffects()
end


local function onMobileActivated(e)
    for _, stack in pairs(e.reference.object.equipment) do
        onEquipped{reference=e.reference, item=stack.object}
    end
end


local function onLoaded(e)
    onMobileActivated{reference=tes3.player}
    for i, cell in ipairs(tes3.getActiveCells()) do
        for ref in cell:iterateReferences(tes3.objectType.npc) do
            onMobileActivated{reference=ref}
        end
    end
end


event.register("initialized", function(e)
    if tes3.isModActive("Adventurer's backback.ESP") then
        registerBackpacks()
        event.register("loaded", onLoaded)
        event.register("equipped", onEquipped)
        event.register("unequipped", onUnequipped)
        event.register("mobileActivated", onMobileActivated)
        mwse.log("[Adventurer's Backpack] Initialized")
    else
        mwse.log("[Adventurer's Backpack] Mod Inactive")
    end
end)
