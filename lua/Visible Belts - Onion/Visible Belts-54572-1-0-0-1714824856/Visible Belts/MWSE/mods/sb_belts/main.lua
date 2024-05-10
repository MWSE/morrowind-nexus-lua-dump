local onion = require("sb_onion.interop")

local wearableID = {
    "commonbelt1",
    "commonbelt2",
    "commonbelt3",
    "commonbelt4",
    "commonbelt5",
    "exquistebelt",
    "expensivebelt1",
    "expensivebelt2",
    "expensivebelt3",
    "extravagantbelt1",
    "extravagantbelt2",
    "heartfire",
    "Erabenimsun"
}

local wearableSlot = {
    onion.slots.stomach,
    onion.slots.stomach,
    onion.slots.stomach,
    onion.slots.stomach,
    onion.slots.stomach,
    onion.slots.stomach,
    onion.slots.stomach,
    onion.slots.stomach,
    onion.slots.stomach,
    onion.slots.stomach,
    onion.slots.stomach,
    onion.slots.stomach,
    onion.slots.stomach,
}

local wearableOffset = {
    { [""] = { -26, 1, 0 } }, -- default offset
    { [""] = { -26, 1, 0 } },
    { [""] = { -26, 1, 0 } },
    { [""] = { -26, 1, 0 } },
    { [""] = { -26, 1, 0 } },
    { [""] = { -26, 1, 0 } },
    { [""] = { -26, 1, 0 } },
    { [""] = { -26, 1, 0 } },
    { [""] = { -26, 1, 0 } },
    { [""] = { -26, 1, 0 } },
    { [""] = { -26, 1, 0 } },
    { [""] = { -26, 1, 0 } },
    { [""] = { -26, 1, 0 } },
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
        [""] = { 0, 0, 0 }
},
    {
        [""] = { 0, 0, 0 }
},
    {
        [""] = { 0, 0, 0 }
},
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