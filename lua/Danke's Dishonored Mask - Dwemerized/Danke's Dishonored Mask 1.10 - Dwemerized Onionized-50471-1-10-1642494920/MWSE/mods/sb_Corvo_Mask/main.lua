local onion = require("sb_onion.interop")

local wearableID = "ab_dnk_dwem_mask"

local wearableSubstituteID = {
    {
          ["Imperial"] = "ab_dnk_dwem_mask",
          ["Dark Elf"] = "ab_dnk_dwem_mask",
		  ["High Elf"] = "ab_dnk_dwem_mask",
		  ["Wood Elf"] = "ab_dnk_dwem_mask",
		  ["Breton"] = "ab_dnk_dwem_mask",
		  ["Redguard"] = "ab_dnk_dwem_mask",
		  ["Nord"] = "ab_dnk_dwem_mask",
		  ["Orc"] = "ab_dnk_dwem_mask",
		  ["Argonian"] = "",
		  ["Khajiit"] = "",
		  ["Dwarf"] = "ab_dnk_dwem_mask",
		  ["Dwemer"] = "ab_dnk_dwem_mask"
    }
}

local wearableOffset = { 
    {
          ["Imperial"] = { 0.2, 2.1, 0 },
          ["Dark Elf"] = { 0, 1.8, 0 },
		  ["High Elf"] = { 0, 2.1, 0 },
		  ["Wood Elf"] = { 0, 2, 0 },
		  ["Breton"] = { 0.2, 2.3, 0 },
		  ["Redguard"] = { 0.2, 2, 0 },
		  ["Nord"] = { 0.2, 2.2, 0 },
		  ["Orc"] = { 0, 2.1, 0 },
		  ["Argonian"] = { 0, 2.2, 0 },
		  ["Khajiit"] = { 0, 2.2, 0 },
		  ["Dwarf"] = { 0.2, 2, 0 },
		  ["Dwemer"] = { 0.2, 2, 0 }
    }
}

local wearableScale = {
    {
          ["Imperial"] = 1,
          ["Dark Elf"] = 1.1,
		  ["High Elf"] = 1.1,
		  ["Wood Elf"] = 1,
		  ["Breton"] = 1,
		  ["Redguard"] = 1,
		  ["Nord"] = 1.1,
		  ["Orc"] = 1.1,
		  ["Argonian"] = 1,
		  ["Khajiit"] = 1,
		  ["Dwarf"] = 1,
		  ["Dwemer"] = 1
    }
}

local function initializedCallback(e)
    onion.registerWearable(wearableID, onion.types.facewear, wearableSubstituteID[1], wearableOffset[1], wearableScale[1])
end
event.register("initialized", initializedCallback, { priority = onion.offsetValue + 1 })
