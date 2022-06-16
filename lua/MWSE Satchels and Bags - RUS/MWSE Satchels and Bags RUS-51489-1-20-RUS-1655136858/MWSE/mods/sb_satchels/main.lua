local onion = require("sb_onion.interop")

local wearableID = {
    "fy_fannypack_b",
    "fy_fannypack_l",
    "fy_fannypack_r",
    "fy_waistbag_b",
    "fy_waistbag_l",
    "fy_waistbag_r",
    "fy_thighbag_l",
    "fy_thighbag_r",
    "fy_fpktbg_l",
    "fy_fpktbg_r",
    "fy_fpkpch",
    "fy_satchel",
    "fy_ubelt"
}

local wearableSlot = {
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.chest,
    onion.slots.buttocks
}

local wearableOffset = {
    { [""] = { -16, 2, 0 } }, -- default offset
    { [""] = { -18, 0, 0 } },
    { [""] = { -18, 0, 0 } }, 
    { [""] = { -20, 0, 0 } },
    { [""] = { -20, 2.5, -1 } }, 
    { [""] = { -20, 2.5, 1 } },
    { [""] = { -18, 0, 0 } }, 
    { [""] = { -18, 0, 0 } },
    { [""] = { -16, 2, 0 } }, 
    { [""] = { -16, 2, 0 } },
    { [""] = { -13.5, 0, 0 } }, 
    { [""] = { -41, 2, 0 } },
    { [""] = { -15, 0, 0 } }
}

local wearableRotation = {
    {
        [""] = { 0, 0, 0 }
},
    {
        [""] = { 0, 0, 0 }
},
    {
        [""] = { 0, 0, 0 }
},
    {
        [""] = { 0, 0, -15 }
},
    {
        [""] = { 0, 0, 0 }
},
    {
        [""] = { 0, 0, 0 }
},
    {
        [""] = { 0, 0, 0 }
},
    {
        [""] = { 0, 0, 0 }
},
    {
        [""] = { 0, 0, 0 }
},
    {
        [""] = { 0, 0, 0 }
},
    {
        [""] = { 0, 0, 0 }
},
    {
        [""] = { 0, 0, 90 }
},
    {
        [""] = { 0, 0, 0 }
}
}

local function initializedCallback(e)
    for i = 1, table.getn(wearableID), 1 do
        onion.register {
            id      = wearableID[i],
            slot    = wearableSlot[i],
            racePos = wearableOffset[i],
            raceRot = wearableRotation[i]
        }-- , onion.types.eyewear, wearableSubstituteID[i] or {}, wearableOffset[i] or {}, wearableScale[i] or {})
    end
end
event.register("initialized", initializedCallback, { priority = onion.offsetValue + 1 })
