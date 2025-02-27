local interop = {}

interop.offsetValue = 360
interop.slotCount = 0

---@class mode
interop.mode = {
    wearable = 0,
    layer = 1
}

---@class bodyParts
interop.bodyParts = {
    [tes3.activeBodyPart.head]          = "Bip01 Head",
    [tes3.activeBodyPart.hair]          = "Hair",

    [tes3.activeBodyPart.neck]          = "Bip01 Neck",
    [tes3.activeBodyPart.leftPauldron]  = "Bip01 L Clavicle",
    [tes3.activeBodyPart.rightPauldron] = "Bip01 R Clavicle",

    [tes3.activeBodyPart.chest]         = "Bip01 Spine2",
    [tes3.activeBodyPart.groin]         = "Bip01 Spine",

    [tes3.activeBodyPart.tail]          = "Bip01 Tail",

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
    { "Face Paint",      tes3.activeBodyPart.head },
    { "Forehead",        tes3.activeBodyPart.head },
    { "Eye Wear",        tes3.activeBodyPart.head },
    { "Face Mask",       tes3.activeBodyPart.head },
    { "Left Ear",        tes3.activeBodyPart.head },
    { "Right Ear",       tes3.activeBodyPart.head },
    { "Mouth",           tes3.activeBodyPart.head },
    { "Chin",            tes3.activeBodyPart.head },
    { "Nose",            tes3.activeBodyPart.head },
    { "Head Top",        tes3.activeBodyPart.head },
    { "Headband",        tes3.activeBodyPart.head },
    { "Head Back",       tes3.activeBodyPart.head },

    { "Neck",            tes3.activeBodyPart.neck },
    { "Left Shoulder",   tes3.activeBodyPart.leftPauldron },
    { "Right Shoulder",  tes3.activeBodyPart.rightPauldron },

    { "Chest",           tes3.activeBodyPart.chest },
    { "Shoulder Blades", tes3.activeBodyPart.chest },
    { "Stomach",         tes3.activeBodyPart.chest },
    { "Back",            tes3.activeBodyPart.chest },
    { "Groin",           tes3.activeBodyPart.groin },
    { "Buttocks",        tes3.activeBodyPart.groin },
    { "Tail",            tes3.activeBodyPart.tail },
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
---@field exNodes bodyParts[] | string[]
---@field ignoreNodes bodyParts[] | string[]
---@field raceSub string
interop.layer = {}

---@type wearable[]
interop.wearables = {}

---@type layer[]
interop.layers = {}

---@class slots
interop.slots = {
    facePaint      = 0,
    forehead       = 1,
    eyeWear        = 2,
    faceMask       = 3,
    leftEar        = 4,
    rightEar       = 5,
    mouth          = 6,
    chin           = 7,
    nose           = 8,
    headTop        = 9,
    headband       = 10,
    headBack       = 11,

    neck           = 12,
    leftShoulder   = 13,
    rightShoulder  = 14,

    chest          = 15,
    shoulderBlades = 16,
    stomach        = 17,
    back           = 18,
    groin          = 19,
    buttocks       = 20,
    tail           = 21
}

function interop.getSlotsCount()
    return table.size(interop.slots)
end

---addSlot
---@param slotData slotData
---@return slots
function interop.addSlot(slotData)
    interop.slots[slotData.id] = interop.getSlotsCount()
    table.insert(interop.wearableSlots, slotData.data)
    return interop.slots[slotData.id]
end

---Register a new onion.
---@param onion wearable | layer
---@param mode? mode
---@return wearable | layer
function interop.register(onion, mode)
    if (mode == 0 or mode == nil) then
        interop.wearables[onion.id] = {
            id        = onion.id,
            slot      = onion.slot,
            exSlot    = onion.exSlot or {},
            cull      = onion.cull or {},
            raceSub   = onion.raceSub or {},
            racePos   = onion.racePos or { [""] = { 0, 0, 0 } },
            raceRot   = onion.raceRot or { [""] = { 0, 0, 0 } },
            raceScale = onion.raceScale or { [""] = 1 },
            mesh      = {}
        }
        return interop.wearables[onion.id]
    elseif (mode == 1) then
        interop.layers[onion.id] = {
            id          = onion.id,
            slot        = onion.slot,
            exSlot      = onion.exSlot or {},
            cull        = onion.cull or {},
            exNodes   = onion.exNodes or {},
            ignoreNodes = onion.ignoreNodes or {},
            raceSub     = onion.raceSub or {},
            mesh        = {}
        }
        return interop.layers[onion.id]
    end
end

function interop.registerAll()
    interop.slotCount = table.size(tes3.armorSlot) + (include("ashfall.interop") and 1 or 0)
    pcall(function()
        for k, v in pairs(interop.wearableSlots) do
            tes3.addArmorSlot { slot = k + interop.slotCount, name = v[1] }
        end
    end)
    for _, tab in ipairs({ interop.wearables, interop.layers }) do
        for k, v in pairs(tab) do
            -- remap slot to custom wearableSlot
            local wearableObject = tes3.getObject(k)
            if (wearableObject) then
                wearableObject.slot = v.slot + interop.slotCount
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
                        substitute.slot = v.slot + interop.slotCount
                        -- get mesh files for male and female body parts
                        v.raceSub[ks] = { id = vs, mesh = {} }
                        v.raceSub[ks].mesh[1] = substitute.parts[1].male.mesh
                        if (substitute.parts[1].female) then
                            v.raceSub[ks].mesh[2] = substitute.parts[1].female.mesh
                        end
                        substitute.parts[1].type = 255
                    end
                end
                mwse.log("    - Registered wearable: %s (Onion slot = [%s - %s], Morrowind slot = [%s])", k,
                    wearableObject.slot - interop.slotCount,
                    interop.wearableSlots[wearableObject.slot - interop.slotCount + 1][1], wearableObject.slot)
            else
                mwse.log("    - Cannot register wearable: %s", k)
            end
        end
    end
end

return interop
