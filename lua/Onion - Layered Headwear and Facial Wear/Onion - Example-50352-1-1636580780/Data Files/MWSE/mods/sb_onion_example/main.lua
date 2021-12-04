local onion = require("sb_onion.interop")

local wearableID = {
    "fur_helm"
}

local wearableSubstituteID = {
    {
        ["Bosmer"]   = "fur_colovian_helm",
        ["Argonian"] = "fur_colovian_helm",
        ["Wood Elf"] = "", -- unequip for Wood Eld
        ["Orc"]      = "" -- unequip for Orc
    }
}

local wearableOffset = {
    {
        ["Imperial"] = { 0, 0, 0 },
        ["Dark Elf"] = { 0, 0, 0 }
    }
}

local wearableScale = {
    {
        ["Imperial"] = 1,
        ["Dark Elf"] = 1
    }
}

local function initializedCallback(e)
    for i, ID in ipairs(wearableID) do
        onion.registerWearable(ID, onion.types.eyewear, wearableSubstituteID[i] or {}, wearableOffset[i] or {}, wearableScale[i] or {})
    end
end
event.register("initialized", initializedCallback, { priority = 361 })
