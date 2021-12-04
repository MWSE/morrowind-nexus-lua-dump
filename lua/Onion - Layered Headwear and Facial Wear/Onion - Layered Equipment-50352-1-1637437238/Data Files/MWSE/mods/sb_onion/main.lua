local interop = require("sb_onion.interop")

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
        node.name = "Bip01 " .. wearable.type

        -- position and scale root node
        node.translation = --[[parent.translation +]] parent:getObjectByName("Head").translation
        node.scale = parent.scale * parent:getObjectByName("Head").scale
        if (wearable.racePos[reference.object.race.name]) then
            node.translation = node.translation + tes3vector3.new(table.unpack(wearable.racePos[reference.object.race.name]))
        end
        if (wearable.raceScale[reference.object.race.name]) then
            node.scale = node.scale * wearable.raceScale[reference.object.race.name]
        end

        -- correct rotation
        node.rotation = tes3matrix33.new()
        node.rotation:fromEulerXYZ(180 / 180 * 3.14, -90 / 180 * 3.14, 0)

        parent:attachChild(node, true)
    end
end

local function detachWearable(parent, nodeName)
    local node = parent:getObjectByName("Bip01 " .. nodeName)
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
    local parent = e.reference.sceneNode:getObjectByName("Bip01 Head")

    -- detach old wearable mesh
    detachWearable(parent, wearable.type)

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
    local parent = e.reference.sceneNode:getObjectByName("Bip01 Head")

    -- detach old wearable mesh
    detachWearable(parent, wearable.type)

    -- update parent scene node
    parent:update()
    parent:updateNodeEffects()
end

local function onMobileActivated(e)
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
    for _, stack in pairs(e.reference.object.equipment) do
        onUnequipped { reference = e.reference, item = stack.object }
    end
end

local function initializedCallback(e)
    interop.registerAll()
    event.register("equip", onEquip)
    event.register("equipped", onEquipped)
    event.register("unequipped", onUnequipped)
    event.register("mobileActivated", onMobileActivated)
    event.register("mobileDeactivated", onMobileDeactivated)
end
event.register("initialized", initializedCallback, { priority = 360 })
