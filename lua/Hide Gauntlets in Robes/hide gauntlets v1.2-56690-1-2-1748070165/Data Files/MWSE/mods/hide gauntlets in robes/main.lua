local modName = "Hide Gauntlets in Robes"

local hands = {
    tes3.activeBodyPart.leftHand,
    tes3.activeBodyPart.rightHand,
}

local gauntletWristIndices = require("hide gauntlets in robes.wrist_indices")

local function onBodyPartsUpdated(e)
    if e.reference ~= tes3.player then
        return
    end

    local bpm = e.reference.bodyPartManager
    if not bpm then
        return
    end

    local robe = tes3.getEquippedItem({
        actor = tes3.player,
        objectType = tes3.objectType.clothing,
        slot = tes3.clothingSlot.robe,
    })
    if not robe then
        return
    end

    for _, part in pairs(hands) do
        local activeBodyPart = bpm:getActiveBodyPart(tes3.activeBodyPartLayer.armor, part)
        if activeBodyPart and activeBodyPart.node and activeBodyPart.item then
            local wi = gauntletWristIndices[activeBodyPart.bodyPart.id:lower()]
            if wi then
                for _, idx in pairs(wi) do
                    activeBodyPart.node.children[idx + 1].appCulled = true
                end
            end
        end
    end
end
event.register(tes3.event.bodyPartsUpdated, onBodyPartsUpdated)
