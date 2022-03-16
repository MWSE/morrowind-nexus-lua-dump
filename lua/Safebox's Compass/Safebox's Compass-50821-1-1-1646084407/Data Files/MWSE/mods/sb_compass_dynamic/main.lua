local compass = require("sb_compass.interop")

local companions = 0

local function hash()
    local friendlyActors = tes3.mobilePlayer.friendlyActors
    return (tostring(friendlyActors[1]) .. tostring(friendlyActors[#friendlyActors]) .. tostring(friendlyActors:size()))
end

local function dist(ref)
    return math.sqrt(math.abs(ref.position.x - tes3.player.position.x) ^ 2 + math.abs(ref.position.y - tes3.player.position.y) ^ 2)
end

local function createMarker(ref, id, mag, icon, subIcon, mrkDetect)
    if (compass.getMarker(ref)) then
        if (compass.getMarker(ref).sub == id) then
            if (compass.getMarker(ref).marker.visible == false and dist(ref) <= mag * 20) then
                compass.showDynamic(ref)
            elseif ((compass.getMarker(ref).marker.visible and dist(ref) > mag * 20) or mag == 0) then
                compass.destroyDynamic(ref)
            end
        elseif (type(compass.getMarker(ref).sub) == "userdata" and compass.getMarker(ref).sub.name == id .. "-sub") then
            if (compass.getMarker(ref).sub.visible == false and dist(ref) <= mag * 20) then
                compass.showDynamicSub(ref)
            elseif ((compass.getMarker(ref).sub.visible and dist(ref) > mag * 20) or mag == 0) then
                compass.destroySub(ref)
            end
        elseif (type(compass.getMarker(ref).sub) ~= "userdata" and mag > 0) then
            compass.registerSub(ref, id, "Icons\\sb_compass_dynamic\\" .. subIcon, mrkDetect.colour)
        end
    elseif (mag > 0) then
        compass.createDynamic(ref, tostring(ref), "Icons\\sb_compass_dynamic\\" .. icon, mrkDetect.colour)
        compass.getMarker(ref).sub = id
    end
end

local function createDetectMarker(toggle, effect, ref, icon, subIcon, markerConfig)
    if (toggle) then
        local mag, magAbs = tes3.getEffectMagnitude { reference = tes3.player, effect = effect }
        createMarker(ref, tostring(effect), mag, icon, subIcon, markerConfig)
    end
end

local function simulateCallback(e)
    if (compass.mcm.config.mrkCompanion.enabled --[[and companions ~= hash()]]) then
        companions = hash()
        for mobile in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
            local marker = compass.getMarker(mobile.reference)
            if (marker) then
                if (marker.marker.visible == false and tes3.getCurrentAIPackageId(mobile) == tes3.aiPackage.follow) then
                    compass.showDynamic(mobile.reference)
                elseif (marker.marker.visible == true and tes3.getCurrentAIPackageId(mobile) ~= tes3.aiPackage.follow) then
                    compass.hideDynamic(mobile.reference)
                end
            elseif (marker == nil) then
                compass.createDynamic(mobile.reference, tostring(mobile.reference), "Icons\\sb_compass_dynamic\\companion.tga", compass.mcm.config.mrkCompanion.colour)
            end
        end
    end
    for _, cell in ipairs(tes3.getActiveCells()) do
        for ref in cell:iterateReferences() do
            local type = ref.baseObject.objectType
            if (type == tes3.objectType.creature) then
                createDetectMarker(compass.mcm.config.mrkDetectAnimal.enabled, tes3.effect.detectAnimal, ref, "animal.tga", "animal-sub.tga", compass.mcm.config.mrkDetectAnimal)
            elseif (type == tes3.objectType.container or type == tes3.objectType.npc) then
                for item in tes3.iterate(ref.object.inventory.items) do
                    local isKey = item.object.isKey or false
                    local enchantment = item.object.enchantment or false
                    createDetectMarker(compass.mcm.config.mrkDetectKey.enabled and isKey, tes3.effect.detectKey, ref, "key.tga", "key-sub.tga", compass.mcm.config.mrkDetectKey)
                    createDetectMarker(compass.mcm.config.mrkDetectEnchantment.enabled and enchantment, tes3.effect.detectEnchantment, ref, "enchant.tga", "enchant-sub.tga", compass.mcm.config.mrkDetectEnchantment)
                end
            else
                local isKey = ref.object.isKey or false
                local enchantment = ref.object.enchantment or false
                createDetectMarker(compass.mcm.config.mrkDetectKey.enabled and isKey, tes3.effect.detectKey, ref, "key.tga", "key-sub.tga", compass.mcm.config.mrkDetectKey)
                createDetectMarker(compass.mcm.config.mrkDetectEnchantment.enabled and enchantment, tes3.effect.detectEnchantment, ref, "enchant.tga", "enchant-sub.tga", compass.mcm.config.mrkDetectEnchantment)
            end
        end
    end
end

local function cellActivatedCallback(e)
    companions = hash()
end

local function initializedCallback(e)
    event.register(tes3.event.simulate, simulateCallback)
    compass.registerEvent(tes3.event.cellActivated, cellActivatedCallback)
end
event.register(tes3.event.initialized, initializedCallback)