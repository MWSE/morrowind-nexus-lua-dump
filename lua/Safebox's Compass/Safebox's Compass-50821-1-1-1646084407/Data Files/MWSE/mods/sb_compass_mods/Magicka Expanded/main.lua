local compass = require("sb_compass.interop")
local enchancedDetection = include("OperatorJack.EnhancedDetection.controllers")

local function dist(ref)
    return math.sqrt(math.abs(ref.position.x - tes3.player.position.x) ^ 2 + math.abs(ref.position.y - tes3.player.position.y) ^ 2)
end

local function createMarker(ref, id, mag, icon, subIcon, mrkDetectColour)
    if (compass.getMarker(ref)) then
        if (compass.getMarker(ref).sub == id) then
            if (compass.getMarker(ref).marker.visible == false and dist(ref) <= mag * 20) then
                compass.showDynamic(ref)
            elseif ((compass.getMarker(ref).marker.visible and dist(ref) > mag * 20) or mag == 0) then
                compass.destroyDynamic(ref)
            end
        elseif (type(compass.getMarker(ref).sub) == "userdata") then
            if (compass.getMarker(ref).sub.name == tostring(tes3.effect.detectAnimal) .. "-sub") then
                compass.destroySub(ref)
            end
            if (compass.getMarker(ref).sub.name == id .. "-sub") then
                if (compass.getMarker(ref).sub.visible == false and dist(ref) <= mag * 20) then
                    compass.showDynamicSub(ref)
                elseif ((compass.getMarker(ref).sub.visible and dist(ref) > mag * 20) or mag == 0) then
                    compass.destroySub(ref)
                end
            end
        elseif (type(compass.getMarker(ref).sub) ~= "userdata" and mag > 0) then
            compass.registerSub(ref, id, "Icons\\sb_compass_dynamic\\" .. subIcon, mrkDetectColour)
        end
    elseif (mag > 0) then
        compass.createDynamic(ref, tostring(ref), "Icons\\sb_compass_dynamic\\" .. icon, mrkDetectColour)
        compass.getMarker(ref).sub = id
    end
end

local function createDetectMarker(effect, ref, icon, subIcon, mrkDetectColour)
    local mag, magAbs = tes3.getEffectMagnitude { reference = tes3.player, effect = effect }
    createMarker(ref, tostring(effect), mag, icon, subIcon, mrkDetectColour)
end

local function simulateCallback(e)
    for ref, _ in pairs(enchancedDetection.referenceControllers.daedra.references) do
        createDetectMarker(336, ref, "daedra.tga", "daedra-sub.tga", compass.mcm.colours.violet)
    end
    for ref, _ in pairs(enchancedDetection.referenceControllers.automaton.references) do
        createDetectMarker(337, ref, "automaton.tga", "automaton-sub.tga", compass.mcm.colours.violet)
    end
    for ref, _ in pairs(enchancedDetection.referenceControllers.humanoid.references) do
        createDetectMarker(338, ref, "humanoid.tga", "humanoid-sub.tga", compass.mcm.colours.violet)
    end
    for ref, _ in pairs(enchancedDetection.referenceControllers.dead.references) do
        createDetectMarker(339, ref, "dead.tga", "dead-sub.tga", compass.mcm.colours.violet)
    end
    for ref, _ in pairs(enchancedDetection.referenceControllers.undead.references) do
        createDetectMarker(340, ref, "undead.tga", "undead-sub.tga", compass.mcm.colours.violet)
    end
    for ref, _ in pairs(enchancedDetection.referenceControllers.door.references) do
        createDetectMarker(341, ref, "door.tga", "door-sub.tga", compass.mcm.colours.violet)
    end
    for ref, _ in pairs(enchancedDetection.referenceControllers.trap.references) do
        createDetectMarker(342, ref, "trap.tga", "trap-sub.tga", compass.mcm.colours.violet)
    end
end

local function initializedCallback(e)
    if (enchancedDetection) then
        --event.register(tes3.event.simulate, simulateCallback)
    end
end
event.register(tes3.event.initialized, initializedCallback)