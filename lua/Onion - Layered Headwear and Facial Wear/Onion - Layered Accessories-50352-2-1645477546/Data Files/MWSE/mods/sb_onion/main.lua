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

---detachWearable
---@param parent niObject
---@param slot slots
local function detachWearable(parent, slot)
    local node = parent:getObjectByName("sb_" .. interop.wearableSlots[slot - interop.offsetValue + 1][1])
    if node then
        parent:detachChild(node)
    end
end

local function onEquip(e)
    -- must be a valid wearable
    local wearable = interop.wearables[e.item.id]
    if wearable and wearable.raceSub[e.reference.object.race.name] == "" then
        return false
    end
end

local function onEquipped(e)
    -- must be a valid wearable
    local wearable = interop.wearables[e.item.id]
    if not wearable then
        return
    end

    -- get parent for attaching
    local parent = e.reference.sceneNode:getObjectByName(interop.bodyParts[interop.wearableSlots[wearable.slot - interop.offsetValue + 1][2]]).parent

    -- detach old wearable mesh
    detachWearable(parent, wearable.slot)

    -- detach exclusive slots
    --timer.frame.delayOneFrame(function()
    --for _, stack in pairs(e.reference.object.equipment) do
    --    if (stack.object.id == wearable.id) then
    --        debug.log(stack.object.id)
    --        debug.log(wearable.slot)
    --        for _, exSlot in ipairs(wearable.exSlot) do
    --            debug.log(exSlot)
    --            debug.log(e.reference.mobile:unequip{ type = tes3.objectType.armor, armorSlot = exSlot})
    --        end
    --    else
    --        local w = table.find(interop.wearables, stack.object.id)
    --        if (w) then
    --            print(w)
    --            for _, es in ipairs(w.exSlot) do
    --                if (es == wearable.slot) then
    --                    debug.log(es)
    --                    debug.log(e.reference.mobile:unequip{ type = tes3.objectType.armor, armorSlot = w.slot})
    --                end
    --            end
    --        end
    --    end
    --    end  end)

    -- cull body parts
    for _,bodyPart in ipairs(wearable.cull) do
        e.reference.sceneNode:getObjectByName(interop.bodyParts[bodyPart]).parent.appCulled = true
    end

    -- attach new wearable mesh
    attachWearable(parent, wearable, e.reference)

    -- update parent scene node
    parent:update()
    parent:updateNodeEffects()
end

local function onUnequipped(e)
    -- must be a valid wearable
    local wearable = interop.wearables[e.item.id]
    if not wearable then
        return
    end

    -- get parent for detaching
    local parent = e.reference.sceneNode:getObjectByName(interop.bodyParts[interop.wearableSlots[wearable.slot - interop.offsetValue + 1][2]]).parent

    -- uncull body parts
    for _,bodyPart in ipairs(wearable.cull) do
        e.reference.sceneNode:getObjectByName(interop.bodyParts[bodyPart]).parent.appCulled = false
    end
    for _, stack in pairs(e.reference.object.equipment) do
        local w = table.find(interop.wearables, stack.object.id)
        if (w) then
            for _,bp in ipairs(w.cull) do
                e.reference.sceneNode:getObjectByName(interop.bodyParts[bp]).parent.appCulled = true
            end
        end
    end

    -- detach old wearable mesh
    detachWearable(parent, wearable.slot)

    -- update parent scene node
    parent:update()
    parent:updateNodeEffects()
end

local function onMobileActivated(e)
    if (e.reference == tes3.player) then
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
    if (e.reference == tes3.player) then
        return
    end
    for _, stack in pairs(e.reference.object.equipment) do
        onUnequipped { reference = e.reference, item = stack.object }
    end
end

local function menuExitCallback(e)
    for _, cell in ipairs(tes3.getActiveCells()) do
        for ref in tes3.iterate(cell.actors) do
            if (ref ~= tes3.player) then
                for _, stack in pairs(ref.object.equipment) do
                    onUnequipped { reference = ref, item = stack.object }
                end

                for _, stack in pairs(ref.object.inventory) do
                    if (onEquip { reference = ref, item = stack.object } == nil) then
                        onEquipped { reference = ref, item = stack.object }
                    end
                end
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
    event.register("menuExit", menuExitCallback)
    event.register("loaded", loadedCallback)
end
event.register("initialized", initializedCallback, { priority = interop.offsetValue })
