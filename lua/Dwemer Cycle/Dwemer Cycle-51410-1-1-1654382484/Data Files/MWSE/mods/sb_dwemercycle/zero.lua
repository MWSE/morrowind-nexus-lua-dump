local zero = {
    variables   = {
        -- 0-100 kph
        distance = 100,
        -- rate (slow, medium, fast)
        time     = { 15, 10, 5 }
    },
    constraints = {
        -- max speed (slow, medium, fast)
        speed = { 48 / 3, (2 * 48) / 3, 48 },
        -- jump height (low, medium, high)
        jump  = { 0.25, 0.5, 1 }
    }
}

function zero.getAcc (index)
    return zero.variables.distance / zero.variables.time[index]
end

function zero.milesPerHour (index, m)
    return math.min(zero.getSpeedLimitMiles(index), zero.getVelMiles() / m)
end

function zero.kilometersPerHour (index, m)
    return math.min(zero.getSpeedLimitKilometers(index), zero.getVelKilometers() / m)
end

function zero.getJump (index)
    return zero.getAcc(index)
end

function zero.getReference()
    return tes3.getReference("sb_dwemercycle")
end

function zero.getMobile()
    return zero.getReference().mobile
end

function zero.getVel()
    return zero.getReference().data["absoluteVelocity"] or 0
end

function zero.setVel(value)
    zero.getReference().data["absoluteVelocity"] = value
end

function zero.getVelMiles()
    return zero.getReference().data["absoluteVelocity"] * 2.237
end

function zero.getVelKilometers()
    return zero.getReference().data["absoluteVelocity"] * 3.6
end

function zero.getSpeedLimit(index)
    return zero.constraints.speed[index] / 3.6
end

function zero.getSpeedLimitMiles(index)
    return zero.constraints.speed[index] / 1.609
end

function zero.getSpeedLimitKilometers(index)
    return zero.constraints.speed[index]
end

function zero.applyAcc(index, delta, m)
    if (zero.getMobile().magicka.current > 0) then
        local relative_speed = math.sqrt(1 - ((zero.getVel() + (zero.getAcc(index) * zero.getMobile().speed.normalized) * delta * m) / ((zero.getSpeedLimit(index) * zero.getMobile().speed.normalized) * m)) ^ 2)
        if (relative_speed == relative_speed) then
            zero.getReference().data["absoluteVelocity"] = math.max(0, zero.getVel() + relative_speed)
            zero.updateFuel(relative_speed)
        end
    end
    --print("Acc")
    --print("acc : " .. relative_speed)
    --print("cap : " .. zero.getSpeedLimit(index) * m)
    --print("vel : " .. zero.getVel())
end

local function applyRelativeDrag(coefficient, speedIndex, delta, m)
    return coefficient * (1 - math.sqrt(1 - (((zero.getSpeedLimit(speedIndex) * zero.getMobile().speed.normalized) * m) - zero.getVel() + ((zero.getAcc(3) * zero.getMobile().speed.normalized) * delta * m)) / ((zero.getSpeedLimit(speedIndex) * zero.getMobile().speed.normalized) * m)) ^ 2) - coefficient
end

function zero.applyDrag(index, delta, m)
    local relative_speed = applyRelativeDrag(0.5, index, delta, m)
    zero.getReference().data["absoluteVelocity"] = math.max(0, zero.getVel() + (relative_speed == relative_speed and relative_speed or 0))
    --print("Drag")
    --print("neg acc : " .. relative_speed)
    ----print("neg cap : " .. zero.getSpeed(index) * m)
    --print("neg vel : " .. zero.getVel())
end

function zero.applyBrake(delta, m)
    local relative_speed = -math.exp(-applyRelativeDrag(1, 3, delta, m))
    zero.getReference().data["absoluteVelocity"] = math.max(0, zero.getVel() + math.min(-0.5, relative_speed == relative_speed and relative_speed or -0.5))
    --print("Bra")
    --print("neg acc : " .. relative_speed)
    ----print("neg cap : " .. zero.getSpeed(index) * m)
    --print("neg vel : " .. zero.getVel())
end

function zero.isMounted()
    return zero.getReference().data["isMounted"]
end

function zero.getGear()
    return zero.getReference().data["gear"]
end

function zero.increaseGear()
    tes3.playSound { sound = "enchant success", reference = zero.getReference(), loop = false, volume = zero.getGear() < 3 and 0.75 or 0 }
    zero.getReference().data["gear"] = math.min(zero.getReference().data["gear"] + 1, 3)
end

function zero.decreaseGear()
    tes3.playSound { sound = "enchant fail", reference = zero.getReference(), loop = false, volume = zero.getGear() > 1 and 0.75 or 0 }
    zero.getReference().data["gear"] = math.max(zero.getReference().data["gear"] - 1, 1)
end

function zero.getAlwaysRun()
    return zero.getReference().data["alwaysRun"]
end

function zero.getSneaking()
    return zero.getReference().data["isSneaking"]
end

function zero.getAmbientLight()
    if (zero.getReference().data["orange"] == nil or zero.getReference().data["blue"] == nil) then
        local orange = { tes3vector3.new(0, 0, 0), 0 }
        local blue = { tes3vector3.new(0, 0, 0), 0 }
        ---@param node niNode
        for _, node in pairs(zero.getReference().sceneNode.children[1].children) do
            if (node) then
                if (string.find(node.name, "Orange")) then
                    orange[1] = orange[1] + node.translation
                    orange[2] = orange[2] + 1
                elseif (string.find(node.name, "Blue")) then
                    blue[1] = node.translation
                    blue[2] = 1
                end
            end
        end
        for key, translation in pairs({ orange = orange, blue = blue }) do
            zero.getReference().data[key] = niPointLight.new()
            zero.getReference().data[key].diffuse = tes3vector3.new(0, 0, 0)
            zero.getReference().data[key].ambient = (key == "orange" and tes3vector3.new(1, 0.5, 0) or tes3vector3.new(0, 1, 1)) * 0.75
            zero.getReference().data[key]:setAttenuationForRadius(128)
            zero.getReference().data[key].translation = translation[1] * (1 / translation[2])
            zero.getReference().sceneNode:attachChild(zero.getReference().data[key])
        end
    end
    return { zero.getReference().data["orange"], zero.getReference().data["blue"] }
end

function zero.getLight()
    local head = zero.getReference().sceneNode:getObjectByName("Body__Mt_Motorcycle_Headlight.001").worldBoundOrigin
    local tail = zero.getReference().sceneNode:getObjectByName("Body__Mt_Motorcycle_Taillamp.001").worldBoundOrigin
    if (zero.getReference().sceneNode:getObjectByName("NiPointLight_Head") == nil) then
        zero.getReference().data["lights"] = { headlight = "NiPointLight_Head" --[[ , taillamp = tail ]] }
        for key, translation in pairs({ headlight = head --[[ , taillamp = tail ]] }) do
            local light = niPointLight.new()
            light.name = zero.getReference().data["lights"][key]
            light.diffuse = tes3vector3.new(0, 0, 0)
            light.ambient = tes3vector3.new(0.75, 0.75, 0.75)
            light:setAttenuationForRadius(256)
            light.translation = (translation - zero.getReference().sceneNode.worldBoundOrigin) + (tes3vector3.new(0, 0, 32) * (key == "headlight" and 1 or -1))
            zero.getReference().sceneNode:attachChild(light)
        end
    end
    return zero.getReference().data["lights"]
end

function zero.updateLight()
    zero.getReference().sceneNode:update()
    zero.getReference().sceneNode:updateEffects()
    for _, key in pairs({ "headlight" --[[ , "taillamp", "orange", "blue" ]] }) do
        zero.getReference():getOrCreateAttachedDynamicLight(zero.getReference().sceneNode:getObjectByName(zero.getLight()[key]), 1.0)
    end
end

function zero.getLightOnOff()
    return zero.getReference().data["lightEnabled"]
end

function zero.toggleLight()
    if (zero.getLightOnOff() or zero.getLightOnOff() == nil) then
        zero.getReference().data["lightEnabled"] = false
        --zero.getReference().sceneNode:detachChild(zero.getReference().data["light"])
    else
        zero.getReference().data["lightEnabled"] = true
        --zero.getReference().sceneNode:attachChild(zero.getReference().data["light"])
    end
    local lights = zero.getLight()
    for _, light in pairs(lights) do
        zero.getReference().sceneNode:getObjectByName(light).enabled = zero.getLightOnOff()
    end
end

function zero.getMountedPose(reference)
    return "sb_dwemercycle\\pose" .. (tes3.player.object.race.isBeast and "_kna" or "") .. (reference == tes3.mobilePlayer.firstPersonReference and ".1st" or "") .. ".nif"
end

function zero.initMount()
    zero.getReference().data["isMounted"] = true
    zero.getReference().data["gear"] = 1
    zero.getReference().data["alwaysRun"] = tes3.mobilePlayer.alwaysRun
    zero.getReference().data["isSneaking"] = tes3.mobilePlayer.isSneaking

    tes3.loadAnimation { reference = tes3.player, file = zero.getMountedPose(tes3.player) }
    tes3.loadAnimation { reference = tes3.mobilePlayer.firstPersonReference, file = zero.getMountedPose(tes3.mobilePlayer.firstPersonReference) }
    tes3.playAnimation { reference = tes3.player, group = tes3.animationGroup.idle, loopCount = 0 }
    tes3.playAnimation { reference = tes3.mobilePlayer.firstPersonReference, group = tes3.animationGroup.idle, loopCount = 0 }
    tes3.mobilePlayer.alwaysRun = false
    tes3.player.sceneNode.rotation = zero.getReference().sceneNode.rotation
    tes3.mobilePlayer.weaponReady = false
    tes3.mobilePlayer.spellReadied = false

    zero.getReference().data["encumbranceMessage"] = tes3.findGMST("sNotifyMessage59").value
    tes3.findGMST("sNotifyMessage59").value = ""
    zero.getMobile().magicka.base = zero.getSpeedLimitKilometers(1) * 10
    zero.getMobile().magicka.current = zero.getSpeedLimitKilometers(1) * 10
end

function zero.calcDismountDamage(m, inWater)
    if (zero.getVelKilometers() / m >= zero.getSpeedLimitKilometers(1)) then
        tes3.mobilePlayer:applyDamage { damage = zero.getVelKilometers() / m * zero.getMobile().strength.normalized, applyArmor = true, applyDifficulty = true, playerAttack = true }
        if (tes3.mobilePlayer.health.current > 0) then
            tes3.playAnimation { reference = tes3.player, group = inWater and tes3.animationGroup.swimKnockDown or tes3.animationGroup.knockDown }
            tes3.playAnimation { reference = tes3.mobilePlayer.firstPersonReference, group = inWater and tes3.animationGroup.swimKnockDown or tes3.animationGroup.knockDown }
        end
    end
end

local function dismount(x, m)
    tes3.mobilePlayer.alwaysRun = zero.getReference().data["alwaysRun"]
    tes3.mobilePlayer.isSneaking = zero.getReference().data["isSneaking"]
    tes3.player.position = zero.getMobile().position + zero.getReference().sceneNode.rotation:transpose().x * x
    tes3.mobilePlayer.autoRun = false
    zero.calcDismountDamage(m, tes3.mobilePlayer.isSwimming)
end

function zero.toggleMount(m, force)
    zero.getReference().data["isMounted"] = not zero.getReference().data["isMounted"]
    --zero.getReference().mobile.torchSlot = tes3.getReference("white_1024_01")
    if (zero.getReference().data["isMounted"]) then
        zero.getReference().data["alwaysRun"] = tes3.mobilePlayer.alwaysRun
        zero.getReference().data["isSneaking"] = tes3.mobilePlayer.isSneaking
        tes3.loadAnimation { reference = tes3.player, file = zero.getMountedPose(tes3.player) }
        tes3.loadAnimation { reference = tes3.mobilePlayer.firstPersonReference, file = zero.getMountedPose(tes3.mobilePlayer.firstPersonReference) }
        tes3.playAnimation { reference = tes3.player, group = tes3.animationGroup.idle, loopCount = 0 }
        tes3.playAnimation { reference = tes3.mobilePlayer.firstPersonReference, group = tes3.animationGroup.idle, loopCount = 0 }
        tes3.mobilePlayer.alwaysRun = false
        tes3.player.sceneNode.rotation = zero.getReference().sceneNode.rotation
        tes3.findGMST("sNotifyMessage59").value = ""
    else
        tes3.loadAnimation { reference = tes3.player }
        tes3.loadAnimation { reference = tes3.mobilePlayer.firstPersonReference }
        tes3.findGMST("sNotifyMessage59").value = zero.getReference().data["encumbranceMessage"]
        if (tes3.mobilePlayer.isMovingLeft) then
            dismount(-64, m)
        elseif (tes3.mobilePlayer.isMovingRight) then
            dismount(64, m)
        elseif (force) then
            dismount(0, m)
        else
            tes3.loadAnimation { reference = tes3.player, file = zero.getMountedPose(tes3.player) }
            tes3.loadAnimation { reference = tes3.mobilePlayer.firstPersonReference, file = zero.getMountedPose(tes3.mobilePlayer.firstPersonReference) }
            tes3.playAnimation { reference = tes3.player, group = tes3.animationGroup.idle, loopCount = 0 }
            tes3.playAnimation { reference = tes3.mobilePlayer.firstPersonReference, group = tes3.animationGroup.idle, loopCount = 0 }
            zero.getReference().data["isMounted"] = true
            tes3.findGMST("sNotifyMessage59").value = ""
        end
    end
end

function zero.updateFuel(accel)
    zero.getMobile().magicka.current = math.max(0, 10 * (zero.getMobile().magicka.current * 0.1 - accel * 0.001))
end

function zero.updateAnimationSpeed(m)
    --print((zero.getVelKilometers() / m) / zero.getSpeedLimitKilometers(3))
    for node in table.traverse(zero.getReference().sceneNode.children) do
        if node.controller and string.find(node.name, "Wheel") then
            --node.controller.frequency = (zero.getVelKilometers() / m) / zero.getSpeedLimitKilometers(3)
        end
    end
end

local function playCreateDestroyVFX()
    local waterLevel = (zero.getMobile() and (zero.getMobile().cell.isInterior == false and 0 or (zero.getMobile().cell.hasWater and zero.getMobile().cell.waterLevel or nil)))
    local zeroPos = tes3vector3.new(
            zero.getReference().position.x,
            zero.getReference().position.y,
            waterLevel == nil and zero.getReference().position.z or (zero.getReference().position.z + 64) > waterLevel and (zero.getReference().position.z + 64) or waterLevel
    )
    local zeroDestroyed = tes3.createReference { object = "sb_bike_destroyed", position = zeroPos, orientation = zero.getReference().orientation }
    local zeroVFX = tes3.applyMagicSource {
        reference         = zeroDestroyed,
        name              = "",
        castChance        = 100,
        bypassResistances = true,
        effects           = {}
    }
    if zeroVFX then
        zeroVFX:playVisualEffect {
            effectIndex = 0,
            position    = zeroDestroyed.position,
            visual      = "VFX_MysticismArea",
            scale       = 10
        }
    end
    tes3.playSound { sound = "alteration hit", reference = zeroDestroyed }
    timer.start { duration = 5, callback = function()
        zeroDestroyed:delete()
    end }
end

function zero.destroy(m)
    if (zero.isMounted()) then
        zero.getReference().data["isMounted"] = false
        tes3.loadAnimation { reference = tes3.player }
        tes3.loadAnimation { reference = tes3.mobilePlayer.firstPersonReference }
        tes3.findGMST("sNotifyMessage59").value = zero.getReference().data["encumbranceMessage"]
        dismount(0, m)
    end
    if (tes3.getSoundPlaying { sound = "forcefield", reference = zero.getReference() }) then
        tes3.removeSound { sound = "forcefield", reference = zero.getReference() }
    end
    if (tes3.getSoundPlaying { sound = "Machinery", reference = zero.getReference() }) then
        tes3.removeSound { sound = "Machinery", reference = zero.getReference() }
    end
    playCreateDestroyVFX()
    zero.getReference():delete()
end

function zero.create()
    local dwemerCycle = zero.getReference() and zero.getReference().deleted == false
    if (dwemerCycle) then
        zero.destroy(0)
    end
    tes3.createReference { object = "sb_dwemercycle", cell = tes3.player.cell.isInterior and tes3.player.cell or nil, position = tes3.player.position + tes3.player.sceneNode.rotation:transpose().y * 128, orientation = tes3.player.orientation + tes3vector3.new(0, 0, -90 / 180 * 3.14) }
    zero.setVel(0)
    --zero.getAmbientLight()
    zero.getLight()
    zero.updateLight()
    zero.toggleLight()
    playCreateDestroyVFX()
end

return zero
