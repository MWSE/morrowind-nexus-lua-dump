local onion = require("sb_onion.interop")

local wearableID = {
    "daedric_tail",
    "netch_tail",
    "glass_tail",
    "chitin_tail",
    "dwemer_tail",
    "armunan_tail",
    "ebony_tail",
    "gahjulan_tail",
    "indoril_tail",
    "iron_tail",
    "orc_tail",
    "steel_tail",
    "adamantium_tail",
    "bonemold_tail",
    "ice_tail",
    "nordic_tail",
}

local wearableSlot = {
    onion.slots.tail,
    onion.slots.tail,
    onion.slots.tail,
    onion.slots.tail,
    onion.slots.tail,
    onion.slots.tail,
    onion.slots.tail,
    onion.slots.tail,
    onion.slots.tail,
    onion.slots.tail,
    onion.slots.tail,
    onion.slots.tail,
    onion.slots.tail,
    onion.slots.tail,
    onion.slots.tail,
    onion.slots.tail,
}

local wearableSubstituteID = {
    ["Breton"] = "", -- prevent this race from wearing equipment
    ["Dark Elf"] = "",
    ["High Elf"] = "",
    ["Imperial"] = "",
    ["Khajiit"] = "",
    ["Nord"] = "",
    ["Orc"] = "",
    ["Wood Elf"] = ""
}

local wearableOffset = {
    { [""] = { 16, 8, 0 } }, -- default offset
    { [""] = { 16, 8, 0 } },
    { [""] = { 16, 8, 0 } }, -- default offset
    { [""] = { 16, 8, 0 } },
    { [""] = { 16, 8, 0 } },
    { [""] = { 16, 8, 0 } }, -- default offset
    { [""] = { 16, 8, 0 } },
    { [""] = { 16, 8, 0 } }, -- default offset
    { [""] = { 16, 8, 0 } },
    { [""] = { 16, 8, 0 } },
    { [""] = { 16, 8, 0 } },
    { [""] = { 16, 8, 0 } },
    { [""] = { 16, 8, 0 } },
    { [""] = { 16, 8, 0 } },
    { [""] = { 16, 8, 0 } },
    { [""] = { 16, 8, 0 } },
}

local wearableRotation = {
    {
        [""] = { 180, 180, 0 }
},
    {
        [""] = { 180, 180, 0 }
},
    {
        [""] = { 180, 180, 0 }
},
    {
        [""] = { 180, 180, 0 }
},
    {
        [""] = { 180, 180, 0 }
},
    {
        [""] = { 180, 180, 0 }
},
    {
        [""] = { 180, 180, 0 }
},
    {
        [""] = { 180, 180, 0 }
},
    {
        [""] = { 180, 180, 0 }
},
    {
        [""] = { 180, 180, 0 }
},
    {
        [""] = { 180, 180, 0 }
},
    {
        [""] = { 180, 180, 0 }
},
    {
        [""] = { 180, 180, 0 }
},
    {
        [""] = { 180, 180, 0 }
},
    {
        [""] = { 180, 180, 0 }
},
    {
        [""] = { 180, 180, 0 }
},
}

local function initializedCallback(e)
    for i = 1, table.getn(wearableID), 1 do
        onion.register {
            id      = wearableID[i],
            slot    = wearableSlot[i],
            raceSub = wearableSubstituteID[i],
            racePos = wearableOffset[i],
            raceRot = wearableRotation[i]
        }-- , onion.types.eyewear, wearableSubstituteID[i] or {}, wearableOffset[i] or {}, wearableScale[i] or {})
    end
end
event.register("initialized", initializedCallback, { priority = onion.offsetValue + 1 })