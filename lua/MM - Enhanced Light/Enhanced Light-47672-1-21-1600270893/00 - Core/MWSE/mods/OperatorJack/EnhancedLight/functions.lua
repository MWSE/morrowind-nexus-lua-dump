local lights = {}
local onSimulate

local function clearOrphanedLights()
    local cells = tes3.getActiveCells()
    for _, cell in pairs(cells) do
        for reference in cell:iterateReferences() do
            if (reference.baseObject.id == "LGHT_OJ_EL_LightAnimated" or
                reference.object.id == "LGHT_OJ_EL_LightStationary") then
                if (lights[reference] == nil and reference.disabled == false) then
                    tes3.positionCell{
                        reference = reference, 
                        position = { 0, 0, 10000 },
                    }
                    reference:disable()
                    timer.delayOneFrame(function()
                        mwscript.setDelete{ reference = reference}
                    end)
                end
            end
        end
    end
end
event.register("cellChanged", clearOrphanedLights)
event.register("loaded", clearOrphanedLights)

local function getRadiusFromMagnitude(magnitude)
    return magnitude * 25
end

local function createLight(id, position, cell, radius)
    local lightObject = tes3.getObject(id)
    lightObject.radius = radius

    local lightRef = tes3.createReference({
        object = lightObject,
        position = position,
        cell = cell
    })
    lightRef.modified = false

    return lightRef
end

local function createAnimatedLight(position, cell, radius)
    local id = "LGHT_OJ_EL_LightAnimated"
    return createLight(id, position, cell, radius)
end

local function createStationaryLight(position, cell, radius)
    local id = "LGHT_OJ_EL_LightStationary"
    return createLight(id, position, cell, radius)
end

local function detachLight(light)
    lights[light] = nil
    light:deleteDynamicLightAttachment()
    light:disable()
end

local function setDeleteLight(light, duration)
    return timer.start({
        duration = duration,
        iterations = 1,
        callback = function()
            detachLight(light)
        end
    })
end

local function attachLightToReference(target, radius, duration)
    local light = createAnimatedLight(target.position, target.cell, radius)

    lights[light] = {
        reference = target,
        timer = nil
    }

    event.unregister("simulate", onSimulate)  
    event.register("simulate", onSimulate)

    return light
end

local function attachLightToPoint(point, cell, radius, duration)
    local light = createStationaryLight(point, cell, radius)

    lights[light] = {
        reference = nil,
        timer = setDeleteLight(light, duration)
    }

    return light
end

local function getLightForReference(reference)
    for light, obj in pairs(lights) do
        if (obj.reference == reference) then
            return light
        end 
    end
    return nil
end

local function detachLightFromReference(reference)
    local light = getLightForReference(reference)
    if (light) then
        detachLight(light)
    end
end

local function isReferenceLit(reference)
    return getLightForReference(reference) ~= nil
end


onSimulate = function(e)
    for light, obj in pairs(lights) do
        local reference = obj.reference
        if (reference) then
            if (light.cell ~= reference.cell) then
                if (light.cell.isInterior == true or reference.cell.isInterior == true) then
                    tes3.positionCell({
                        reference = light,
                        position = reference.position,
                        orientation = reference.orientation,
                        cell = reference.cell
                    })
                end
            end

            local distance = light.position:distance(reference.position)
            if (distance > 128) then
                local interDist = distance / 50
                light.position = light.position:interpolate(reference.position, interDist)
            end

            light:setDynamicLighting()
        end
    end
end

return {
    getRadiusFromMagnitude = getRadiusFromMagnitude,
    createLight = createLight,
    createAnimatedLight = createAnimatedLight,
    createStationaryLight = createStationaryLight,
    detachLight = detachLight,
    attachLightToReference = attachLightToReference,
    attachLightToPoint = attachLightToPoint,
    detachLightFromReference = detachLightFromReference,
    isReferenceLit = isReferenceLit
}