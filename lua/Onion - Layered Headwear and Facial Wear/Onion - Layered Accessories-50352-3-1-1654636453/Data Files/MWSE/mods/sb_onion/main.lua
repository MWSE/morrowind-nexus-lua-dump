local interop = require("sb_onion.interop")

---attachWearable
---@param parent niObject
---@param wearable wearable
---@param reference tes3reference
local function attachWearable(parent, wearable, reference)
    local fileName = {}
    -- load female body part if the player is female and female body part exists
    if (reference.object.female and (wearable.raceSub[reference.object.race.name] and wearable.raceSub[reference.object.race.name].mesh[2] or wearable.mesh[2])) then
        fileName = wearable.raceSub[reference.object.race.name] and wearable.raceSub[reference.object.race.name].mesh[2] or wearable.mesh[2]
    else
        fileName = wearable.raceSub[reference.object.race.name] and wearable.raceSub[reference.object.race.name].mesh[1] or wearable.mesh[1]
    end
    local node = tes3.loadMesh(fileName)
    if node then
        node = node:clone()

        -- rename the root node so we can easily find it for detaching
        node.name = "sb_" .. interop.wearableSlots[wearable.slot - interop.offsetValue + 1][1]

        -- position and scale root node
        local boneNode = interop.bodyParts[interop.wearableSlots[wearable.slot - interop.offsetValue + 1][2]]
        node.translation = parent:getObjectByName(boneNode).translation + tes3vector3.new(table.unpack(wearable.racePos[reference.object.race.name] or wearable.racePos[""] or { 0, 0, 0 }))
        node.scale = parent.scale * parent:getObjectByName(boneNode).scale * (wearable.raceScale[reference.object.race.name] or wearable.raceScale[""] or 1)

        -- correct and rotate node
        local rotation = wearable.raceRot[reference.object.race.name] or wearable.raceRot[""] or { 0, 0, 0 }
        node.rotation = tes3matrix33.new()
        node.rotation:fromEulerXYZ((180 + rotation[1]) / 180 * 3.14, (-90 + rotation[2]) / 180 * 3.14, (rotation[3]) / 180 * 3.14)

        parent:attachChild(node, true)
    end
end

---attachLayer
---@param layer layer
---@param reference tes3reference
local function attachLayer(layer, reference)
    local fileName = {}
    -- load female body part if the player is female and female body part exists
    if (reference.object.female and (layer.raceSub[reference.object.race.name] and layer.raceSub[reference.object.race.name].mesh[2] or layer.mesh[2])) then
        fileName = layer.raceSub[reference.object.race.name] and layer.raceSub[reference.object.race.name].mesh[2] or layer.mesh[2]
    else
        fileName = layer.raceSub[reference.object.race.name] and layer.raceSub[reference.object.race.name].mesh[1] or layer.mesh[1]
    end
    local node = tes3.loadMesh(fileName)
    if node then
        node = node:clone()

        local newWeight = 1 / reference.object.weight
        local newHeight = 1 / reference.object.height
        local newScale = tes3vector3.new(newWeight ^ 2, newWeight ^ 2, newHeight ^ 2)

        for shape in table.traverse(node.children) do
            if (shape:isInstanceOfType(tes3.niType.NiTriShape)) then
                local skin = shape.skinInstance
                local rot = shape.rotation

                if (skin) then
                    skin.root = reference.sceneNode:getObjectByName(skin.root.name)
                    for i, bone in ipairs(skin.bones) do
                        skin.bones[i] = reference.sceneNode:getObjectByName(bone.name)
                    end

                    shape.name = "sb_" .. interop.wearableSlots[layer.slot - interop.offsetValue + 1][1]
                    shape.rotation = tes3matrix33.new(rot.x * newScale, rot.y * newScale, rot.z * newScale)
                    shape:update()
                    reference.sceneNode:getObjectByName("Bip01"):attachChild(shape)
                end
            end
        end
    end
end

---detachWearable
---@param parent niObject
---@param slot slots
local function detachWearable(parent, slot)
    for node in table.traverse(parent.children) do
        if (node.name == "sb_" .. interop.wearableSlots[slot - interop.offsetValue + 1][1]) then
            node.parent:detachChild(node)
        end
    end
end

local function onEquip(e)
    -- must be a valid wearable
    local wearable = interop.wearables[e.item.id]
    local layer = interop.layers[e.item.id]
    if ((wearable and wearable.raceSub[e.reference.object.race.name] == "") or (layer and layer.raceSub[e.reference.object.race.name] == "")) then
        return false
    end
end

local function onEquipped(e)
    -- must be a valid wearable or layer
    local wearable = interop.wearables[e.item.id]
    local layer = interop.layers[e.item.id]
    if (wearable == nil and layer == nil) then
        -- unequip exclusive slots
        if (e.item.objectType == tes3.objectType.armor) then
            for _, stack in pairs(e.reference.object.equipment) do
                local w = interop.wearables[stack.object.id] or interop.layers[stack.object.id]
                if (w) then
                    for _, es in ipairs(w.exSlot) do
                        if (es == e.item.slot) then
                            e.reference.mobile:unequip { item = stack.object }
                            break
                        end
                    end
                end
            end
        end

        return
    end

    -- get parent for attaching
    local parent = e.reference.sceneNode:getObjectByName(interop.bodyParts[interop.wearableSlots[(wearable and wearable.slot or layer.slot) - interop.offsetValue + 1][2]])

    -- detach old wearable or layer mesh
    detachWearable((wearable and parent or e.reference.sceneNode), (wearable and wearable.slot or layer.slot))

    -- unequip exclusive slots
    for _, exSlot in ipairs(wearable and wearable.exSlot or layer.exSlot) do
        e.reference.mobile:unequip { armorSlot = exSlot }
    end
    for _, stack in pairs(e.reference.object.equipment) do
        if (stack.object.id ~= (wearable and wearable.id or layer.id)) then
            local w = interop.wearables[stack.object.id] or interop.layers[stack.object.id]
            if (w) then
                for _, es in ipairs(w.exSlot) do
                    if (es == (wearable and wearable.slot or layer.slot)) then
                        e.reference.mobile:unequip { item = stack.object }
                        break
                    end
                end
            end
        end
    end

    -- cull body parts
    for _, bodyPart in ipairs(wearable and wearable.cull or layer.cull) do
        e.reference.sceneNode:getObjectByName(interop.bodyParts[bodyPart]).parent.appCulled = true
    end

    -- attach new wearable or layer mesh
    if (wearable) then
        attachWearable(parent, wearable, e.reference)
    else
        attachLayer(layer, e.reference)
    end

    -- update parent scene node
    parent:update()
    parent:updateEffects()
    parent:updateProperties()
end

local function onUnequipped(e)
    -- must be a valid wearable or layer
    local wearable = interop.wearables[e.item.id]
    local layer = interop.layers[e.item.id]
    if (wearable == nil and layer == nil) then
        return
    end

    -- get parent for detaching
    local parent = e.reference.sceneNode:getObjectByName(interop.bodyParts[interop.wearableSlots[(wearable and wearable.slot or layer.slot) - interop.offsetValue + 1][2]])

    -- uncull body parts
    for _, bodyPart in ipairs(wearable and wearable.cull or layer.cull) do
        e.reference.sceneNode:getObjectByName(interop.bodyParts[bodyPart]).parent.appCulled = false
    end
    for _, stack in pairs(e.reference.object.equipment) do
        local w = interop.wearables[stack.object.id] or interop.layers[stack.object.id]
        if (w) then
            for _, bp in ipairs(w.cull) do
                e.reference.sceneNode:getObjectByName(interop.bodyParts[bp]).parent.appCulled = true
            end
        end
    end

    -- detach old wearable mesh
    detachWearable((wearable and parent or e.reference.sceneNode), (wearable and wearable.slot or layer.slot))

    -- update parent scene node
    parent:update()
    parent:updateEffects()
    parent:updateProperties()
end

local function onMobileActivated(e)
    if (e.reference == tes3.player or e.reference.object.objectType ~= tes3.objectType.npc) then
        return
    end
    for _, stack in pairs(e.reference.object.equipment) do
        if (onEquip { reference = e.reference, item = stack.object } == nil) then
            onEquipped { reference = e.reference, item = stack.object }
        end
    end
    for _, stack in pairs(e.reference.object.inventory) do
        if (onEquip { reference = e.reference, item = stack.object } == nil) then
            onEquipped { reference = e.reference, item = stack.object }
        end
    end
end

local function onMobileDeactivated(e)
    if (e.reference == tes3.player or e.reference.object.objectType ~= tes3.objectType.npc) then
        return
    end
    for _, stack in pairs(e.reference.object.equipment) do
        onUnequipped { reference = e.reference, item = stack.object }
    end
end

local function referenceSceneNodeCreatedCallback(e)
    if (e.reference == tes3.player or e.reference.object.objectType == tes3.objectType.npc) then
        for _, stack in pairs(e.reference.object.equipment) do
            if (onEquip { reference = e.reference, item = stack.object } == nil) then
                onEquipped { reference = e.reference, item = stack.object }
            end
        end
        for _, stack in pairs(e.reference.object.inventory) do
            if (onEquip { reference = e.reference, item = stack.object } == nil) then
                onEquipped { reference = e.reference, item = stack.object }
            end
        end
    end
end

local function menuExitCallback(e)
    for _, cell in ipairs(tes3.getActiveCells()) do
        for ref in tes3.iterate(cell.actors) do
            if (ref ~= tes3.player and ref.object.objectType == tes3.objectType.npc) then
                for _, stack in pairs(ref.object.equipment) do
                    onUnequipped { reference = ref, item = stack.object }
                end

                for _, stack in pairs(ref.object.inventory) do
                    if (onEquip { reference = ref, item = stack.object } == nil) then
                        onEquipped { reference = ref, item = stack.object }
                    end
                end

                ref.sceneNode:update()
                ref.sceneNode:updateEffects()
                ref.sceneNode:updateProperties()
            end
        end
    end
end

local function loadedCallback(e)
    if (e.newGame == false) then
        for _, stack in pairs(tes3.player.object.equipment) do
            if (onEquip { reference = tes3.player, item = stack.object } == nil) then
                onEquipped { reference = tes3.player, item = stack.object }
            end
        end
    end
end

local function initializedCallback(e)
    interop.registerAll()
    event.register("equip", onEquip)
    event.register("equipped", onEquipped)
    event.register("unequipped", onUnequipped)
    event.register("mobileActivated", onMobileActivated)
    event.register("mobileDeactivated", onMobileDeactivated)
    event.register("referenceSceneNodeCreated", referenceSceneNodeCreatedCallback)
    event.register("menuExit", menuExitCallback)
    event.register("loaded", loadedCallback)
end

event.register("initialized", initializedCallback, { priority = interop.offsetValue })
