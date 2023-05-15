local data = {}

---@type table<number, string>
data.bodyParts = {
    [tes3.activeBodyPart.head]          = "Bip01 Head",
    [tes3.activeBodyPart.neck]          = "Bip01 Neck",

    [tes3.activeBodyPart.chest]         = "Bip01",
    [tes3.activeBodyPart.groin]         = "Bip01 Spine",
    [tes3.activeBodyPart.tail]          = "Bip01 Tail",

    [tes3.activeBodyPart.leftUpperArm]  = "Bip01 L UpperArm",
    [tes3.activeBodyPart.leftForearm]   = "Bip01 L Forearm",
    [tes3.activeBodyPart.leftHand]      = "Bip01 L Hand",

    [tes3.activeBodyPart.rightUpperArm] = "Bip01 R UpperArm",
    [tes3.activeBodyPart.rightForearm]  = "Bip01 R Forearm",
    [tes3.activeBodyPart.rightHand]     = "Bip01 R Hand",

    [tes3.activeBodyPart.leftUpperLeg]  = "Bip01 L Thigh",
    [tes3.activeBodyPart.leftKnee]      = "Bip01 L Calf",
    [tes3.activeBodyPart.leftFoot]      = "Bip01 L Foot",

    [tes3.activeBodyPart.rightUpperLeg] = "Bip01 R Thigh",
    [tes3.activeBodyPart.rightKnee]     = "Bip01 R Calf",
    [tes3.activeBodyPart.rightFoot]     = "Bip01 R Foot"
}

---@type table<string, number>[]
data.tattooSlots = {
    { "Head",        tes3.activeBodyPart.head },
    { "Neck",        tes3.activeBodyPart.neck },

    { "Torso",       tes3.activeBodyPart.chest },
    { "Hips",        tes3.activeBodyPart.groin },
    { "Tail",        tes3.activeBodyPart.tail },

    { "Upper Arm L", tes3.activeBodyPart.leftUpperArm },
    { "Lower Arm L", tes3.activeBodyPart.leftForearm },
    { "Hand L",      tes3.activeBodyPart.leftForearm },

    { "Upper Arm R", tes3.activeBodyPart.rightUpperArm },
    { "Lower Arm R", tes3.activeBodyPart.rightForearm },
    { "Hand R",      tes3.activeBodyPart.rightForearm },

    { "Upper Leg L", tes3.activeBodyPart.leftUpperLeg },
    { "Lower Leg L", tes3.activeBodyPart.leftKnee },
    { "Foot L",      tes3.activeBodyPart.leftFoot },

    { "Upper Leg R", tes3.activeBodyPart.rightUpperLeg },
    { "Lower Leg R", tes3.activeBodyPart.rightKnee },
    { "Foot R",      tes3.activeBodyPart.rightFoot }
}

---@enum tattooSlots
data.slots = {
    head    = 1,
    neck    = 2,
    
    torso   = 3,
    hips    = 4,
    tail    = 5,
    
    upArmL  = 6,
    lowArmL = 7,
    handL   = 8,
    
    upArmR  = 9,
    lowArmR = 10,
    handR   = 11,
    
    upLegL  = 12,
    lowLegL = 13,
    footL   = 14,
    
    upLegR  = 15,
    lowLegR = 16,
    footR   = 17
}

---@class tattoo
---@field id string
---@field slot tattooSlots
---@field mPaths table<string, string>
---@field fPaths table<string, string>
data.tattoo = {}

---@type table<string, tattoo>
data.tattooProps = {}

---@type table<string, table<string, table<string, niSourceTexture>>>
data.tattoos = {}

return data