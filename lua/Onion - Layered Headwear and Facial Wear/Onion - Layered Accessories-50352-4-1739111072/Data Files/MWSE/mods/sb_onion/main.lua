local interop = require("sb_onion.interop")

---attachWearable
---@param parent niObject
---@param wearable wearable
---@param reference tes3reference
local function attachWearable(parent, wearable, reference)
    local fileName = {}
    -- load female body part if the player is female and female body part exists
    if (reference.object.female and (wearable.raceSub[reference.object.race.name] and wearable.raceSub[reference.object.race.name].mesh[2] or wearable.mesh[2])) then
        fileName = wearable.raceSub[reference.object.race.name] and wearable.raceSub[reference.object.race.name].mesh[2] or
            wearable.mesh[2]
    else
        fileName = wearable.raceSub[reference.object.race.name] and wearable.raceSub[reference.object.race.name].mesh[1] or
            wearable.mesh[1]
    end
    local node = tes3.loadMesh(fileName)
    if node then
        node = node:clone()

        -- rename the root node so we can easily find it for detaching
        node.name = "sb_" .. interop.wearableSlots[wearable.slot + 1][1]

        -- position and scale root node
        local boneNode = interop.bodyParts[interop.wearableSlots[wearable.slot + 1][2]]
        node.translation = parent:getObjectByName(boneNode).translation +
            tes3vector3.new(table.unpack(wearable.racePos[reference.object.race.name] or wearable.racePos[""] or
                { 0, 0, 0 }))
        node.scale = parent.scale * parent:getObjectByName(boneNode).scale *
            (wearable.raceScale[reference.object.race.name] or wearable.raceScale[""] or 1)

        -- correct and rotate node
        local rotation = wearable.raceRot[reference.object.race.name] or wearable.raceRot[""] or { 0, 0, 0 }
        node.rotation = tes3matrix33.new()
        node.rotation:fromEulerXYZ((180 + rotation[1]) / 180 * 3.14, (-90 + rotation[2]) / 180 * 3.14,
            (rotation[3]) / 180 * 3.14)

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
        fileName = layer.raceSub[reference.object.race.name] and layer.raceSub[reference.object.race.name].mesh[2] or
            layer.mesh[2]
    else
        fileName = layer.raceSub[reference.object.race.name] and layer.raceSub[reference.object.race.name].mesh[1] or
            layer.mesh[1]
    end
    local node = tes3.loadMesh(fileName)
    if node then
        node = node:clone()

        local newWeight = 1 / reference.object.weight
        local newHeight = 1 / reference.object.height
        local newScale = tes3vector3.new(newWeight, newWeight, newHeight)

        local attachNode = niNode:new()
        local rot = attachNode.rotation
        attachNode.name = "sb_" .. interop.wearableSlots[layer.slot + 1][1]
        attachNode.rotation = tes3matrix33.new(rot.x * newScale, rot.y * newScale, rot.z * newScale)

        for shape in table.traverse(node.children) do
            if (shape:isInstanceOfType(tes3.niType.NiTriShape)) then
                local skin = shape.skinInstance

                if (skin) then
                    skin.root = attachNode
                    for i, bone in ipairs(skin.bones) do
                        local boneNode = reference.sceneNode:getObjectByName(bone.name)
                        if (boneNode) then
                            skin.bones[i] = boneNode
                        end

                        -- check if layer has exclusive nodes that must be shown
                        if (#layer.exNodes > 0) then
                            for _, child in ipairs(boneNode.children) do
                                if (child:isInstanceOfType(tes3.niType.NiTriShape)) then
                                    -- cull branch
                                    child.parent.appCulled = true
                                    for _, exNode in ipairs(layer.exNodes) do
                                        if (
                                            (type(exNode) == "string" and bone.name == exNode) or
                                            (bone.name == interop.bodyParts[exNode])
                                        ) then
                                            -- uncull branch
                                            child.parent.appCulled = false
                                        end
                                    end

                                    -- check if layer has ignore nodes that must be culled
                                    for _, ignoreNode in ipairs(layer.ignoreNodes) do
                                        if (
                                            (type(ignoreNode) == "string" and bone.name == ignoreNode) or
                                            (bone.name == interop.bodyParts[ignoreNode])
                                        ) then
                                            -- cull node
                                            child.appCulled = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                    attachNode:attachChild(shape, true)
                end
            end
        end

        -- -- check if layer has ignore nodes that must be culled
        -- for _, ignoreNode in ipairs(layer.ignoreNodes) do
        --     local selectedNode
        --     if (type(ignoreNode) == "string") then
        --         selectedNode = node:getObjectByName(ignoreNode)
        --     else
        --         selectedNode = node:getObjectByName(interop.bodyParts[ignoreNode])
        --     end

        --     -- compare ignored nodes with exclusive nodes, and skip nodes that appear in both lists
        --     if (#layer.exNodes > 0) then
        --         for _, exNode in ipairs(layer.exNodes) do
        --             if (
        --                 not (type(exNode) == "string" and selectedNode.name == exNode) and
        --                 not (selectedNode.name == interop.bodyParts[exNode])
        --             ) then
        --                 for shape in table.traverse(selectedNode.children) do
        --                     if (shape:isInstanceOfType(tes3.niType.NiTriShape)) then
        --                         selectedNode:detachChild(shape)
        --                     end
        --                 end
        --             end
        --         end
        --     else
        --         for shape in table.traverse(selectedNode.children) do
        --             if (shape:isInstanceOfType(tes3.niType.NiTriShape)) then
        --                 selectedNode:detachChild(shape)
        --             end
        --         end
        --     end
        -- end

        attachNode:update()
        attachNode:updateEffects()
        attachNode:updateProperties()
        reference.sceneNode:attachChild(attachNode, true)
    end
end

---detachWearable
---@param parent niObject
---@param slot slots
local function detachWearable(parent, slot)
    for node in table.traverse(parent.children) do
        if (node.name == "sb_" .. interop.wearableSlots[slot + 1][1]) then
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
    local parent = e.reference.sceneNode:getObjectByName(interop.bodyParts
        [interop.wearableSlots[(wearable and wearable.slot or layer.slot) + 1][2]])

    -- detach old wearable or layer mesh
    detachWearable((wearable and parent or e.reference.sceneNode), (wearable and wearable.slot or layer.slot))

    -- unequip exclusive slots
    for _, exSlot in ipairs(wearable and wearable.exSlot or layer.exSlot) do
        e.reference.mobile:unequip { armorSlot = exSlot }
        -- e.reference.mobile.flags = bit.bor(tes3.mobilePlayer.flags, 0x80000000)
    end
    for _, stack in pairs(e.reference.object.equipment) do
        if (stack.object.id ~= (wearable and wearable.id or layer.id)) then
            local w = interop.wearables[stack.object.id] or interop.layers[stack.object.id]
            if (w) then
                for _, es in ipairs(w.exSlot) do
                    if (es == (wearable and wearable.slot or layer.slot)) then
                        e.reference.mobile:unequip { item = stack.object }
                        -- e.reference.mobile.flags = bit.bor(e.reference.mobile.flags, 0x80000000)
                        break
                    end
                end
            end
        end
    end

    -- update cull list
    for _, bodyPart in ipairs(wearable and wearable.cull or layer.cull) do
        e.reference.data.onionCulls = e.reference.data.onionCulls or {}
        e.reference.data.onionCulls[interop.bodyParts[bodyPart]] = e.reference.data.onionCulls[interop.bodyParts[bodyPart]] or {}
        local alreadyCulled = false
        for _, node in ipairs(e.reference.data.onionCulls[interop.bodyParts[bodyPart]]) do
            if (node == (wearable and wearable.id or layer.id)) then
                alreadyCulled = true
                break
            end
        end
        if (alreadyCulled == false) then
            table.insert(e.reference.data.onionCulls[interop.bodyParts[bodyPart]], wearable and wearable.id or layer.id)
        end
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
    local parent = e.reference.sceneNode:getObjectByName(interop.bodyParts
        [interop.wearableSlots[(wearable and wearable.slot or layer.slot) + 1][2]])

    -- clear cull list
    for _, bodyPart in ipairs(wearable and wearable.cull or layer.cull) do
        if (e.reference.data.onionCulls and e.reference.data.onionCulls[interop.bodyParts[bodyPart]]) then
            table.removevalue(e.reference.data.onionCulls[interop.bodyParts[bodyPart]], wearable and wearable.id or layer.id)
        end
        if (#e.reference.data.onionCulls[interop.bodyParts[bodyPart]] == 0) then
            e.reference.data.onionCulls[interop.bodyParts[bodyPart]] = nil
        end
    end
    for _, stack in pairs(e.reference.object.equipment) do
        local w = interop.wearables[stack.object.id] or interop.layers[stack.object.id]
        if (w) then
            for _, bp in ipairs(w.cull) do
                if (e.reference.data.onionCulls and e.reference.data.onionCulls[interop.bodyParts[bp]]) then
                    table.removevalue(e.reference.data.onionCulls[interop.bodyParts[bp]], wearable and wearable.id or layer.id)
                end
                if (#e.reference.data.onionCulls[interop.bodyParts[bp]] == 0) then
                    e.reference.data.onionCulls[interop.bodyParts[bp]] = nil
                end
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

local function onBodyPartsUpdated(e)
    -- cull body parts
    if (e.reference.object.objectType ~= tes3.objectType.npc) then
        return
    end
    if (e.reference.data.onionCulls) then
        for bodyPart, _ in pairs(e.reference.data.onionCulls) do
            if (e.reference.sceneNode:getObjectByName(bodyPart)) then
                for shape in table.traverse(e.reference.sceneNode:getObjectByName(bodyPart).children) do
                    if (shape:isInstanceOfType(tes3.niType.NiTriShape)) then
                        shape.appCulled = true
                    end
                end
            end
        end
        e.reference.sceneNode:update()
    end
end

local function onMobileActivated(e)
    if (e.reference == tes3.player or e.reference == tes3.player1stPerson or e.reference.object.objectType ~= tes3.objectType.npc or e.reference.sceneNode == nil) then
        return
    end
    -- for _, stack in pairs(e.reference.object.equipment) do
    --     if (onEquip { reference = e.reference, item = stack.object } == nil) then
    --         onEquipped { reference = e.reference, item = stack.object }
    --     end
    -- end
    for _, stack in pairs(e.reference.object.inventory) do
        if (onEquip { reference = e.reference, item = stack.object } == nil) then
            onEquipped { reference = e.reference, item = stack.object }
        end
    end
end

local function onMobileDeactivated(e)
    if (e.reference == tes3.player or e.reference == tes3.player1stPerson or e.reference.object.objectType ~= tes3.objectType.npc or e.reference.sceneNode == nil) then
        return
    end
    for _, stack in pairs(e.reference.object.equipment) do
        onUnequipped { reference = e.reference, item = stack.object }
        -- e.reference.mobile.flags = bit.bor(tes3.mobilePlayer.flags, 0x80000000)
    end
end

local function referenceSceneNodeCreatedCallback(e)
    if (e.reference == tes3.player or e.reference == tes3.player1stPerson) then
        for _, stack in pairs(e.reference.object.equipment) do
            if (onEquip { reference = e.reference, item = stack.object } == nil) then
                onEquipped { reference = e.reference, item = stack.object }
            end
        end
    elseif (e.reference.object.objectType == tes3.objectType.npc) then
        -- for _, stack in pairs(e.reference.object.equipment) do
        --     if (onEquip { reference = e.reference, item = stack.object } == nil) then
        --         onEquipped { reference = e.reference, item = stack.object }
        --     end
        -- end
        for _, stack in pairs(e.reference.object.inventory) do
            if (onEquip { reference = e.reference, item = stack.object } == nil) then
                onEquipped { reference = e.reference, item = stack.object }
            end
        end
    end
    onBodyPartsUpdated { reference = e.reference }
end

local function uiActivatedCallback(e)
    if (e.element.name == "MenuContents") then
        e.element:registerBefore(tes3.uiEvent.update, function(k)
            mwse.log("Onion tes3.uiEvent.update - %s", e.element.name)
            local serviceReference = tes3ui.getServiceActor() and tes3ui.getServiceActor().reference or nil
            mwse.log("    serviceReference - %s", serviceReference)
            if (serviceReference) then
                if (serviceReference.object.objectType == tes3.objectType.npc and serviceReference.sceneNode) then
                    -- for _, stack in pairs(serviceReference.object.equipment) do
                    --     mwse.log("    equipment stack - %s", stack.object)
                    --     onUnequipped { reference = serviceReference, item = stack.object }
                    -- end

                    for _, stack in pairs(serviceReference.object.equipment) do
                        mwse.log("        inventory stack - %s", stack.object)
                        onUnequipped { reference = serviceReference, item = stack.object }
                        -- serviceReference.mobile.flags = bit.bor(serviceReference.mobile.flags, 0x80000000)
                    end
                end
            end
        end)
        e.element:registerAfter(tes3.uiEvent.update, function(k)
            mwse.log("Onion tes3.uiEvent.update - %s", e.element.name)
            local serviceReference = tes3ui.getServiceActor() and tes3ui.getServiceActor().reference or nil
            mwse.log("    serviceReference - %s", serviceReference)
            if (serviceReference) then
                if (serviceReference.object.objectType == tes3.objectType.npc and serviceReference.sceneNode) then
                    -- for _, stack in pairs(serviceReference.object.equipment) do
                    --     mwse.log("    equipment stack - %s", stack.object)
                    --     onUnequipped { reference = serviceReference, item = stack.object }
                    -- end

                    for _, stack in pairs(serviceReference.object.inventory) do
                        mwse.log("        inventory stack - %s", stack.object)
                        onEquipped { reference = serviceReference, item = stack.object }
                        -- serviceReference.mobile.flags = bit.bor(serviceReference.mobile.flags, 0x80000000)
                    end
                end
            end
        end)
        e.element:registerBefore(tes3.uiEvent.destroy, function(k)
            mwse.log("Onion tes3.uiEvent.destroy - %s", e.element.name)
            local serviceReference = tes3ui.getServiceActor() and tes3ui.getServiceActor().reference or nil
            mwse.log("    serviceReference - %s", serviceReference)
            if (serviceReference) then
                if (serviceReference.object.objectType == tes3.objectType.npc and serviceReference.sceneNode) then
                    -- for _, stack in pairs(serviceReference.object.equipment) do
                    --     mwse.log("    equipment stack - %s", stack.object)
                    --     onUnequipped { reference = serviceReference, item = stack.object }
                    -- end

                    for _, stack in pairs(serviceReference.object.inventory) do
                        mwse.log("        inventory stack - %s", stack.object)
                        if (onEquip { reference = serviceReference, item = stack.object } == nil) then
                            onEquipped { reference = serviceReference, item = stack.object }
                        end
                    end
                end
            end
        end)
    end
end

local function loadedCallback(e)
    if (e.newGame == false) then
        for _, stack in pairs(tes3.player.object.equipment) do
            if (onEquip { reference = tes3.player, item = stack.object } == nil) then
                onEquipped { reference = tes3.player, item = stack.object }
            end
            if (onEquip { reference = tes3.player1stPerson, item = stack.object } == nil) then
                onEquipped { reference = tes3.player1stPerson, item = stack.object }
            end
        end
        onBodyPartsUpdated { reference = tes3.player }
        onBodyPartsUpdated { reference = tes3.player1stPerson }
    end
end

local function initializedCallback(e)
    mwse.log("[Onion - Layered Accessories]:")
    interop.registerAll()
    event.register("equip", onEquip)
    event.register("equipped", onEquipped)
    event.register("unequipped", onUnequipped)
    event.register("bodyPartsUpdated", onBodyPartsUpdated)
    event.register("mobileActivated", onMobileActivated)
    event.register("mobileDeactivated", onMobileDeactivated)
    event.register("referenceSceneNodeCreated", referenceSceneNodeCreatedCallback)
    event.register("uiActivated", uiActivatedCallback)
    event.register("loaded", loadedCallback)
    
    -- event.register("equip", function (e)
    --     mwse.log("Onion event callback - equip - %s", e)
    -- end)
    -- event.register("equipped", function (e)
    --     mwse.log("Onion event callback - equipped - %s", e)
    -- end)
    -- event.register("unequipped", function (e)
    --     mwse.log("Onion event callback - unequipped - %s", e)
    -- end)
    -- event.register("bodyPartsUpdated", function (e)
    --     mwse.log("Onion event callback - bodyPartsUpdated - %s", e)
    -- end)
    -- event.register("mobileActivated", function (e)
    --     mwse.log("Onion event callback - mobileActivated - %s", e)
    -- end)
    -- event.register("mobileDeactivated", function (e)
    --     mwse.log("Onion event callback - mobileDeactivated - %s", e)
    -- end)
    -- event.register("referenceSceneNodeCreated", function (e)
    --     mwse.log("Onion event callback - referenceSceneNodeCreated - %s", e)
    -- end)
    -- event.register("uiActivated", function (e)
    --     mwse.log("Onion event callback - uiActivated - %s", e)
    -- end)
    -- event.register("loaded", function (e)
    --     mwse.log("Onion event callback - loaded - %s", e)
    -- end)
end

event.register("initialized", initializedCallback, { priority = interop.offsetValue })
