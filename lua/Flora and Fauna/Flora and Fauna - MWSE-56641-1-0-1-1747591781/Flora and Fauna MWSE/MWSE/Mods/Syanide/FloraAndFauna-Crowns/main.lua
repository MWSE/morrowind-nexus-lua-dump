local onion = require("sb_onion.interop")

local wearableID = {
    "RedRose_Crown",
    "BlackRose_Crown",
    "Duskb_Crown",
    "GoldSedge_Crown",
    "hornlily_Crown",
    "LaurelF_Crown",
    "NobSedge_Crown",
    "orcscrown_Crown",
    "PiPeony_Crown",
    "ProsePi_Crown",
    "ProsePur_Crown",
    "ProseRed_Crown",
    "Sweetbarrel_Crown",
    "TimsaF_Crown",
    "MornGlory_Crown",
    "MtnDamask_Crown",
    "TigerLily_Crown"
}

local wearableSlot = {
    onion.slots.headband,
    onion.slots.headband,
    onion.slots.headband,
    onion.slots.headband,
    onion.slots.headband,
    onion.slots.headband,
    onion.slots.headband,
    onion.slots.headband,
    onion.slots.headband,
    onion.slots.headband,
    onion.slots.headband,
    onion.slots.headband,
    onion.slots.headband,
    onion.slots.headband,
    onion.slots.headband,
    onion.slots.headband,
    onion.slots.headband
}

local wearableOffset = {
    { [""] = { -0.01, 1, 0 } },
    { [""] = { -0.01, 1, 0 } },
    { [""] = { -0.01, 1, 0 } },
    { [""] = { -0.01, 1, 0 } },
    { [""] = { -0.01, 1, 0 } },
    { [""] = { -0.01, 1, 0 } },
    { [""] = { -0.01, 1, 0 } },
    { [""] = { -0.01, 1, 0 } },
    { [""] = { -0.01, 1, 0 } },
    { [""] = { -0.01, 1, 0 } },
    { [""] = { -0.01, 1, 0 } },
    { [""] = { -0.01, 1, 0 } },
    { [""] = { -0.01, 1, 0 } },
    { [""] = { -0.01, 1, 0 } },
    { [""] = { -0.01, 1, 0 } },
    { [""] = { -0.01, 1, 0 } },
    { [""] = { -0.01, 1, 0 } }
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