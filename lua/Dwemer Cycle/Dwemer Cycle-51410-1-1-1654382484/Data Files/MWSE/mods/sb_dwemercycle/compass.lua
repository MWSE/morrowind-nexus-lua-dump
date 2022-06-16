local compass = include("sb_compass.interop")
local zero = require("sb_dwemercycle.zero")

--- @param e simulateEventData
local function simulateCallback(e)
    local zeroRef = zero.getReference()
    if (zeroRef) then
        if (compass.getMarker(zeroRef)) then
            local helmet = tes3.getEquippedItem { actor = tes3.player, objectType = tes3.objectType.armor, slot = tes3.armorSlot.helmet }
            if ((zero.getReference() and zero.isMounted() ~= true or zero.getReference() == nil)
                    and (helmet and helmet.object.id == "sb_dwemer_helm")) then
                compass.showDynamic(zeroRef)
            else
                compass.hideDynamic(zeroRef)
            end
        else
            compass.createDynamic(zeroRef, "sb_zero", "Icons\\sb_dwemercycle\\icn_compass.tga", { 0, 1, 1 })
        end
    end
end

    if (compass) then
        event.register(tes3.event.simulate, simulateCallback)
    end