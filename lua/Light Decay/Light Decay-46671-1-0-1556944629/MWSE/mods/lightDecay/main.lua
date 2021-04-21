--[[
    Light Decay
--]]

local lightTimer


local function getLight()
    if tes3.player.light then
        return tes3.getEquippedItem{actor=tes3.mobilePlayer, objectType=tes3.objectType.light}
    end
end


local function updateLightRadius()
    local light = getLight()
    if not light then
        lightTimer:pause()
        return
    end

    local maxTime = light.object.time
    local curTime = light.object:getTimeLeft(light)
    local newRadius = light.object.radius * math.log(curTime) / math.log(maxTime)
    if newRadius <= 0 then
        lightTimer:pause()
        return
    end
    tes3.player.light:setAttenuationForRadius(newRadius)

    -- tes3.messageBox("Light: %s\nTime Remaining: %.2f/%.2f\nRadius: %d/%d\nAttenuation: %.6f", light.object.name, curTime, maxTime, newRadius, light.object.radius, tes3.player.light.quadraticAttenuation)
end


local function onLightChanged(e)
    if e.item.objectType ~= tes3.objectType.light then
        return
    elseif e.reference ~= tes3.player then
        return
    end
    lightTimer:reset()
    if e.eventType == "unequipped" then
        lightTimer:pause()
    elseif e.eventType == "equipped" then
        lightTimer:resume()
    end
end
event.register("equipped", onLightChanged)
event.register("unequipped", onLightChanged)


local function onLoaded(e)
    lightTimer = timer.start{type=timer.simulate, iterations=-1, duration=1/3, callback=updateLightRadius}
    lightTimer:pause()
end
event.register("loaded", onLoaded)
