local interop = {}

interop.offsetValue = 360

---@class bodyParts
interop.bodyParts = {
    [tes3.activeBodyPart.head]          = "Head",
    [tes3.activeBodyPart.hair]          = "Hair",

    [tes3.activeBodyPart.neck]          = "Neck",
    [tes3.activeBodyPart.leftPauldron]  = "Left Pauldron",
    [tes3.activeBodyPart.rightPauldron] = "Right Pauldron",

    [tes3.activeBodyPart.chest]         = "Chest",
    [tes3.activeBodyPart.groin]         = "Groin",

    [tes3.activeBodyPart.tail]          = "Tail",

    [tes3.activeBodyPart.leftUpperArm]  = "Left Upper Arm",
    [tes3.activeBodyPart.rightUpperArm] = "Right Upper Arm",
    [tes3.activeBodyPart.leftForearm]   = "Left Forearm",
    [tes3.activeBodyPart.rightForearm]  = "Right Forearm",
    [tes3.activeBodyPart.leftWrist]     = "Left Wrist",
    [tes3.activeBodyPart.rightWrist]    = "Right Wrist",
    [tes3.activeBodyPart.leftHand]      = "Left Hand",
    [tes3.activeBodyPart.rightHand]     = "Right Hand",

    [tes3.activeBodyPart.leftUpperLeg]  = "Left Upper Leg",
    [tes3.activeBodyPart.rightUpperLeg] = "Right Upper Leg",
    [tes3.activeBodyPart.leftKnee]      = "Left Knee",
    [tes3.activeBodyPart.rightKnee]     = "Right Knee",
    [tes3.activeBodyPart.leftAnkle]     = "Left Ankle",
    [tes3.activeBodyPart.rightAnkle]    = "Right Ankle",
    [tes3.activeBodyPart.leftFoot]      = "Left Foot",
    [tes3.activeBodyPart.rightFoot]     = "Right Foot"
}

---@class wearableSlots
interop.wearableSlots = {
    { "Face Paint", tes3.activeBodyPart.head },
    { "Forehead", tes3.activeBodyPart.head },
    { "Eye Wear", tes3.activeBodyPart.head },
    { "Face Mask", tes3.activeBodyPart.head },
    { "Left Ear", tes3.activeBodyPart.head },
    { "Right Ear", tes3.activeBodyPart.head },
    { "Mouth", tes3.activeBodyPart.head },
    { "Chin", tes3.activeBodyPart.head },
    { "Nose", tes3.activeBodyPart.head },
    { "Head Top", tes3.activeBodyPart.head },
    { "Headband", tes3.activeBodyPart.head },
    { "Head Back", tes3.activeBodyPart.head },

    { "Neck", tes3.activeBodyPart.neck },
    { "Left Shoulder", tes3.activeBodyPart.leftPauldron },
    { "Right Shoulder", tes3.activeBodyPart.rightPauldron },

    { "Chest", tes3.activeBodyPart.chest },
    { "Shoulder Blades", tes3.activeBodyPart.chest },
    { "Stomach", tes3.activeBodyPart.chest },
    { "Back", tes3.activeBodyPart.chest },
    { "Groin", tes3.activeBodyPart.groin },
    { "Tail", tes3.activeBodyPart.tail },
}

---@class slotData
---@field id string
---@field data table
local slotData

---@class wearable
---@field id string
---@field slot slots
---@field exSlot number[]
---@field cull bodyParts[]
---@field raceSub string
---@field racePos number[]
---@field raceRot number[]
---@field raceScale number
interop.wearable = {}

---@type wearable[]
interop.wearables = {}

---@class types
---@deprecated Use slots instead.
interop.types = {
    facepaint = 0 + interop.offsetValue,
    eyewear   = 2 + interop.offsetValue,
    facewear  = 3 + interop.offsetValue,
    earwear   = 4 + interop.offsetValue,
    lipwear   = 6 + interop.offsetValue,
    nosewear  = 8 + interop.offsetValue,
    headwear  = 9 + interop.offsetValue
}

---@class slots
interop.slots = {
    facePaint      = 0 + interop.offsetValue,
    forehead       = 1 + interop.offsetValue,
    eyeWear        = 2 + interop.offsetValue,
    faceMask       = 3 + interop.offsetValue,
    leftEar        = 4 + interop.offsetValue,
    rightEar       = 5 + interop.offsetValue,
    mouth          = 6 + interop.offsetValue,
    chin           = 7 + interop.offsetValue,
    nose           = 8 + interop.offsetValue,
    headTop        = 9 + interop.offsetValue,
    headband       = 10 + interop.offsetValue,
    headBack       = 11 + interop.offsetValue,

    neck           = 12 + interop.offsetValue,
    leftShoulder   = 13 + interop.offsetValue,
    rightShoulder  = 14 + interop.offsetValue,

    chest          = 15 + interop.offsetValue,
    shoulderBlades = 16 + interop.offsetValue,
    stomach        = 17 + interop.offsetValue,
    back           = 18 + interop.offsetValue,
    groin          = 19 + interop.offsetValue,
    buttocks       = 20 + interop.offsetValue
}

function interop.getSlotsCount()
    local count = 0
    for k, v in pairs(interop.slots) do
        count = count + 1
    end
    return count
end

---addSlot
---@param slotData slotData
---@return slots
function interop.addSlot(slotData)
    interop.slots[slotData.id] = interop.getSlotsCount() + interop.offsetValue
    table.insert(interop.wearableSlots, slotData.data)
    return interop.slots[slotData.id]
end

---@deprecated Use register() instead.
function interop.registerWearable(id, slot, raceSub, racePos, raceScale)
    interop.wearables[id] = { id = id, slot = slot, exSlot = {}, cull = {}, raceSub = raceSub or {}, racePos = racePos or { [""] = { 0, 0, 0 } }, raceRot = { [""] = { 0, 0, 0 } }, raceScale = raceScale or { [""] = 1 }, mesh = {} }
end

---Register a new wearable.
---@param wearable wearable
---@return wearable
function interop.register(wearable)
    interop.wearables[wearable.id] = {
        id        = wearable.id,
        slot      = wearable.slot,
        exSlot    = wearable.exSlot or {},
        cull      = wearable.cull or {},
        raceSub   = wearable.raceSub or {},
        racePos   = wearable.racePos or { [""] = { 0, 0, 0 } },
        raceRot   = wearable.raceRot or { [""] = { 0, 0, 0 } },
        raceScale = wearable.raceScale or { [""] = 1 },
        mesh      = {}
    }
end

function interop.registerAll()
    pcall(function()
        for k, v in pairs(interop.wearableSlots) do
            tes3.addArmorSlot { slot = k + interop.offsetValue, name = v[1] }
        end
    end)
    for k, v in pairs(interop.wearables) do
        -- remap slot to custom wearableSlot
        local wearableObject = tes3.getObject(k)
        if (wearableObject) then
            wearableObject.slot = v.slot
            -- get mesh files for male and female body parts
            interop.wearables[k].mesh[1] = wearableObject.parts[1].male.mesh
            if (wearableObject.parts[1].female) then
                interop.wearables[k].mesh[2] = wearableObject.parts[1].female.mesh
            end
            wearableObject.parts[1].type = 255
            for ks, vs in pairs(v.raceSub) do
                -- remap slot to custom wearableSlot
                local substitute = tes3.getObject(vs)
                if (substitute) then
                    substitute.slot = v.slot
                    -- get mesh files for male and female body parts
                    v.raceSub[ks] = { id = vs, mesh = {} }
                    v.raceSub[ks].mesh[1] = substitute.parts[1].male.mesh
                    if (substitute.parts[1].female) then
                        v.raceSub[ks].mesh[2] = substitute.parts[1].female.mesh
                    end
                    substitute.parts[1].type = 255
                end
            end
            mwse.log("[Onion - Layered Accessories]: Registered wearable: %s (slot = [%s]_%s)", k, wearableObject.slot, interop.wearableSlots[wearableObject.slot - interop.offsetValue + 1][1])
        else
            mwse.log("[Onion - Layered Accessories]: Cannot register wearable: %s", k)
        end
    end
end

return interop