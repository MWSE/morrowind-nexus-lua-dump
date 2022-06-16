local interop = {}

interop.offsetValue = 360

---@class mode
interop.mode = {
    wearable = 0,
    layer = 1
}

---@class bodyParts
interop.bodyParts = {
    [tes3.activeBodyPart.head] = "Bip01 Head",
    [tes3.activeBodyPart.hair] = "Head",

    [tes3.activeBodyPart.neck]          = "Bip01 Neck",
    [tes3.activeBodyPart.leftPauldron]  = "Bip01 L Clavicle",
    [tes3.activeBodyPart.rightPauldron] = "Bip01 R Clavicle",

    [tes3.activeBodyPart.chest] = "Bip01 Spine2",
    [tes3.activeBodyPart.groin] = "Bip01 Spine",

    [tes3.activeBodyPart.tail] = "Bip01 Tail",

    [tes3.activeBodyPart.leftUpperArm]  = "Bip01 L UpperArm",
    [tes3.activeBodyPart.rightUpperArm] = "Bip01 R UpperArm",
    [tes3.activeBodyPart.leftForearm]   = "Bip01 L Forearm",
    [tes3.activeBodyPart.rightForearm]  = "Bip01 R Forearm",
    [tes3.activeBodyPart.leftWrist]     = "Left Wrist",
    [tes3.activeBodyPart.rightWrist]    = "Right Wrist",
    [tes3.activeBodyPart.leftHand]      = "Bip01 L Hand",
    [tes3.activeBodyPart.rightHand]     = "Bip01 R Hand",

    [tes3.activeBodyPart.leftUpperLeg]  = "Bip01 L Thigh",
    [tes3.activeBodyPart.rightUpperLeg] = "Bip01 R Thigh",
    [tes3.activeBodyPart.leftKnee]      = "Bip01 L Calf",
    [tes3.activeBodyPart.rightKnee]     = "Bip01 R Calf",
    [tes3.activeBodyPart.leftAnkle]     = "Left Ankle",
    [tes3.activeBodyPart.rightAnkle]    = "Right Ankle",
    [tes3.activeBodyPart.leftFoot]      = "Bip01 L Foot",
    [tes3.activeBodyPart.rightFoot]     = "Bip01 R Foot"
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
    { "Buttocks", tes3.activeBodyPart.groin },
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

---@class layer
---@field id string
---@field slot slots
---@field exSlot number[]
---@field cull bodyParts[]
---@field raceSub string
interop.layer = {}

---@type wearable[]
interop.wearables = {}

---@type layer[]
interop.layers = {}

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
    facePaint = 0 + interop.offsetValue,
    forehead  = 1 + interop.offsetValue,
    eyeWear   = 2 + interop.offsetValue,
    faceMask  = 3 + interop.offsetValue,
    leftEar   = 4 + interop.offsetValue,
    rightEar  = 5 + interop.offsetValue,
    mouth     = 6 + interop.offsetValue,
    chin      = 7 + interop.offsetValue,
    nose      = 8 + interop.offsetValue,
    headTop   = 9 + interop.offsetValue,
    headband  = 10 + interop.offsetValue,
    headBack  = 11 + interop.offsetValue,

    neck          = 12 + interop.offsetValue,
    leftShoulder  = 13 + interop.offsetValue,
    rightShoulder = 14 + interop.offsetValue,

    chest          = 15 + interop.offsetValue,
    shoulderBlades = 16 + interop.offsetValue,
    stomach        = 17 + interop.offsetValue,
    back           = 18 + interop.offsetValue,
    groin          = 19 + interop.offsetValue,
    buttocks       = 20 + interop.offsetValue,
    tail           = 21 + interop.offsetValue
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
---@param mode? mode
---@return wearable
function interop.register(wearable, mode)
    if (mode == 0 or mode == nil) then
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
    elseif (mode == 1) then
        interop.layers[wearable.id] = {
            id      = wearable.id,
            slot    = wearable.slot,
            exSlot  = wearable.exSlot or {},
            cull    = wearable.cull or {},
            raceSub = wearable.raceSub or {},
            mesh    = {}
        }
    end
end

function interop.registerAll()
    pcall(function()
        for k, v in pairs(interop.wearableSlots) do
            tes3.addArmorSlot { slot = k + interop.offsetValue, name = v[1] }
        end
    end)
    for _, tab in ipairs({ interop.wearables, interop.layers }) do
        for k, v in pairs(tab) do
            -- remap slot to custom wearableSlot
            local wearableObject = tes3.getObject(k)
            if (wearableObject) then
                wearableObject.slot = v.slot
                -- get mesh files for male and female body parts
                tab[k].mesh[1] = wearableObject.parts[1].male.mesh
                if (wearableObject.parts[1].female) then
                    tab[k].mesh[2] = wearableObject.parts[1].female.mesh
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
end

return interop
