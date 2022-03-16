local onion = require("sb_onion.interop")

local wearableID = {
    "fur_helm",
    "fur_bracer_right"
}

local customSlot = onion.addSlot({
    id   = "custSlot",
    data = { "Custom Slot", tes3.activeBodyPart.head }
})

local wearableSlot = {
    customSlot,
    onion.slots.rightShoulder
}

local wearableExSlot = {
    { onion.slots.eyeWear, tes3.armorSlot.helmet },
    {}
}

local wearableCull = {
    { tes3.activeBodyPart.leftUpperArm },
    {}
}

local wearableSubstituteID = {
    {
        ["Bosmer"]   = "fur_colovian_helm",
        ["Argonian"] = "fur_colovian_helm",
        ["Wood Elf"] = "", -- unequip for Wood Eld
        ["Orc"]      = "" -- unequip for Orc
    },
    {
        ["Dark Elf"] = "fur_helm"
    }
}

local wearableOffset = {
    {
        [""]         = { 5, 0, 0 }, -- default offset
        ["Imperial"] = { 10, 0, 0 },
        ["Dark Elf"] = { 0, 10, 0 }
    },
    {}
}

local wearableRotation = {
    {},
    {
        ["bosmer"] = { -45, 0, 0 }
    }
}

local wearableScale = {
    {
        [""]         = 1, -- default scale
        ["Dark Elf"] = 1.2
    },
    {}
}

local function initializedCallback(e)
    for i = 1, table.getn(wearableID), 1 do
        onion.register {
            id        = wearableID[i],
            slot      = wearableSlot[i],
            exSlot    = wearableExSlot[i],
            cull      = wearableCull[i],
            raceSub   = wearableSubstituteID[i],
            racePos   = wearableOffset[i],
            raceRot   = wearableRotation[i],
            raceScale = wearableScale[i]
        }-- , onion.types.eyewear, wearableSubstituteID[i] or {}, wearableOffset[i] or {}, wearableScale[i] or {})
    end
end
event.register("initialized", initializedCallback, { priority = onion.offsetValue + 1 })
