if (mwse.buildDate == nil) or (mwse.buildDate < 20220506) then
    event.register("initialized", function()
        tes3.messageBox("[Of Eggs and Dwarves] Invalid MWSE version. Please run MWSE-Updater.exe.")
    end)
    return
end


local function getCameraShaker()
    local wc = tes3.worldController.worldCamera

    local object = wc.cameraRoot:getObjectByName("slf_qk_animation.nif")
    if not object then
        object = tes3.loadMesh("slf\\slf_qk_animation.nif"):clone()
        assert(object.name == "slf_qk_animation.nif")

        local camera = wc.cameraData.camera
        local parent = camera.parent
        object:attachChild(camera, true)
        parent:attachChild(object, true)
        parent:update()
    end

    return object
end


local function stopCameraShaking()
    local cameraShaker = getCameraShaker()
    cameraShaker.controller.active = false
    cameraShaker:clearTransforms()
    cameraShaker:update()
end


local prevRange = 1.0
local function startCameraShaking(ref)
    local o = ref.orientation * (180 / math.pi)
    local chance, speed, range = o.x, o.y, o.z

    -- apply new speed
    local cameraShaker = getCameraShaker()
    cameraShaker.controller.frequency = speed

    -- apply new range
    if not math.isclose(range, prevRange, 1e-5) then
        for _, axis in pairs(cameraShaker.controller.data.rotationKeys) do
            for _, keys in pairs(axis.keys) do
                for i, key in ipairs(keys) do
                    key.value = key.value * (1.0 / prevRange) * range
                end
            end
        end
        prevRange = range
    end

    -- start animation
    cameraShaker.controller.active = true
end


event.register("loaded", function()
    for _, cell in ipairs(tes3.getActiveCells()) do
        for ref in cell:iterateReferences(tes3.objectType.activator) do
            if ref.id:lower() == "slf_qk_helper" then
                startCameraShaking(ref)
                return
            end
        end
    end
    stopCameraShaking()
end)


event.register("referenceActivated", function(e)
    if e.reference.id:lower() == "slf_qk_helper" then
        timer.delayOneFrame(function()
            startCameraShaking(e.reference)
        end)
    end
end)


event.register("referenceDeactivated", function(e)
    if e.reference.id:lower() == "slf_qk_helper" then
        stopCameraShaking()
    end
end)


event.register("cellChanged", function(e)
    if e.previousCell and e.previousCell.displayName:find("Gnisis") then
        stopCameraShaking()
    end
end)


mwse.log("[Of Eggs and Dwarves] Initialized")
