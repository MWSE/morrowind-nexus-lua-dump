local onion = require("sb_onion.interop")


local facemaskID = {
    "_RV_Ashmask_1",
	"_RV_Ashmask_2",
	"_RV_Ashmask_3",
    "_RV_Facewrap_1",
    "_RV_Facewrap_2",
	"_RV_Facewrap_3",
	"_RV_Facewrap_4",
	"_RV_Facewrap_5",
	"_RV_Facewrap_6",
	"_RV_Facewrap_7",
	"_RV_Facewrap_8",
	"_RV_Daedramask_1",
	"_RV_Daedramask_2",
	"_RV_Daedramask_3",
	"_RV_Daedramask_4",
	"_RV_Orcishmask_1",
	"_RV_Orcishmask_2"
}

local facemaskSlot = {
    onion.slots.faceMask,
	onion.slots.faceMask,
	onion.slots.faceMask,
	onion.slots.faceMask,
	onion.slots.faceMask,
	onion.slots.faceMask,
	onion.slots.faceMask,
	onion.slots.faceMask,
	onion.slots.faceMask,
	onion.slots.faceMask,
	onion.slots.faceMask,
	onion.slots.faceMask,
	onion.slots.faceMask,
	onion.slots.faceMask,
	onion.slots.faceMask,
	onion.slots.faceMask,
	onion.slots.faceMask

}

local facemaskPos = {
	{ ["Dark Elf"] = { 0, -0.5, 0 }, ["High Elf"] = { 0, -0.5, 0 }, ["Wood Elf"] = { 0, -0.5, 0 }, ["Orc"] = { 0, -0.5, 0 }, ["Khajiit"] = { 0, -0.5, 0 } },
	{ ["Dark Elf"] = { 0, -0.5, 0 }, ["High Elf"] = { 0, -0.5, 0 }, ["Wood Elf"] = { 0, -0.5, 0 }, ["Orc"] = { 0, -0.5, 0 }, ["Khajiit"] = { 0, -0.5, 0 } },
	{ ["Dark Elf"] = { 0, -0.5, 0 }, ["High Elf"] = { 0, -0.5, 0 }, ["Wood Elf"] = { 0, -0.5, 0 }, ["Orc"] = { 0, -0.5, 0 }, ["Khajiit"] = { 0, -0.5, 0 } },
	{ ["Dark Elf"] = { 0, -0.5, 0 }, ["High Elf"] = { 0, -0.5, 0 }, ["Wood Elf"] = { 0, -0.5, 0 }, ["Orc"] = { 0, -0.2, 0 }, ["Khajiit"] = { 0, -0.5, 0 } },
	{ ["Dark Elf"] = { 0, -0.5, 0 }, ["High Elf"] = { 0, -0.5, 0 }, ["Wood Elf"] = { 0, -0.5, 0 }, ["Orc"] = { 0, -0.2, 0 }, ["Khajiit"] = { 0, -0.5, 0 } },
	{ ["Dark Elf"] = { 0, -0.5, 0 }, ["High Elf"] = { 0, -0.5, 0 }, ["Wood Elf"] = { 0, -0.5, 0 }, ["Orc"] = { 0, -0.2, 0 }, ["Khajiit"] = { 0, -0.5, 0 } },
	{ ["Dark Elf"] = { 0, -0.5, 0 }, ["High Elf"] = { 0, -0.5, 0 }, ["Wood Elf"] = { 0, -0.5, 0 }, ["Orc"] = { 0, -0.2, 0 }, ["Khajiit"] = { 0, -0.5, 0 } },
	{ ["Dark Elf"] = { 0, -0.5, 0 }, ["High Elf"] = { 0, -0.5, 0 }, ["Wood Elf"] = { 0, -0.5, 0 }, ["Orc"] = { 0, -0.2, 0 }, ["Khajiit"] = { 0, -0.5, 0 } },
	{ ["Dark Elf"] = { 0, -0.5, 0 }, ["High Elf"] = { 0, -0.5, 0 }, ["Wood Elf"] = { 0, -0.5, 0 }, ["Orc"] = { 0, -0.2, 0 }, ["Khajiit"] = { 0, -0.5, 0 } },
	{ ["Dark Elf"] = { 0, -0.5, 0 }, ["High Elf"] = { 0, -0.5, 0 }, ["Wood Elf"] = { 0, -0.5, 0 }, ["Orc"] = { 0, -0.2, 0 }, ["Khajiit"] = { 0, -0.5, 0 } },
	{ ["Dark Elf"] = { 0, -0.5, 0 }, ["High Elf"] = { 0, -0.5, 0 }, ["Wood Elf"] = { 0, -0.5, 0 }, ["Orc"] = { 0, -0.2, 0 }, ["Khajiit"] = { 0, -0.5, 0 } },
	{ ["Dark Elf"] = { 0, -0.5, 0 }, ["High Elf"] = { 0, -0.5, 0 }, ["Wood Elf"] = { 0, -0.5, 0 }, ["Orc"] = { 0, -0.5, 0 }, ["Khajiit"] = { 0, -0.5, 0 } },
	{ ["Dark Elf"] = { 0, -0.5, 0 }, ["High Elf"] = { 0, -0.5, 0 }, ["Wood Elf"] = { 0, -0.5, 0 }, ["Orc"] = { 0, -0.5, 0 }, ["Khajiit"] = { 0, -0.5, 0 } },
	{ ["Dark Elf"] = { 0, -0.5, 0 }, ["High Elf"] = { 0, -0.5, 0 }, ["Wood Elf"] = { 0, -0.5, 0 }, ["Orc"] = { 0, -0.5, 0 }, ["Khajiit"] = { 0, -0.5, 0 } },
	{ ["Dark Elf"] = { 0, -0.5, 0 }, ["High Elf"] = { 0, -0.5, 0 }, ["Wood Elf"] = { 0, -0.5, 0 }, ["Orc"] = { 0, -0.5, 0 }, ["Khajiit"] = { 0, -0.5, 0 } },
	{ ["Dark Elf"] = { 0, -0.5, 0 }, ["High Elf"] = { 0, -0.5, 0 }, ["Wood Elf"] = { 0, -0.5, 0 }, ["Orc"] = { 0, -0.5, 0 }, ["Khajiit"] = { 0, -0.5, 0 } },
	{ ["Dark Elf"] = { 0, -0.5, 0 }, ["High Elf"] = { 0, -0.5, 0 }, ["Wood Elf"] = { 0, -0.5, 0 }, ["Orc"] = { 0, -0.5, 0 }, ["Khajiit"] = { 0, -0.5, 0 } }
}

local facemaskScale = {
	{ ["Orc"] = 1.1, ["Khajiit"] = 1.1 },
	{ ["Orc"] = 1.1, ["Khajiit"] = 1.1 },
	{ ["Orc"] = 1.1, ["Khajiit"] = 1.1 },
	{ ["Orc"] = 1.1, ["Khajiit"] = 1.1 },
	{ ["Orc"] = 1.1, ["Khajiit"] = 1.1 },
	{ ["Orc"] = 1.1, ["Khajiit"] = 1.1 },
	{ ["Orc"] = 1.1, ["Khajiit"] = 1.1 },
	{ ["Orc"] = 1.1, ["Khajiit"] = 1.1 },
	{ ["Orc"] = 1.1, ["Khajiit"] = 1.1 },
	{ ["Orc"] = 1.1, ["Khajiit"] = 1.1 },
	{ ["Orc"] = 1.1, ["Khajiit"] = 1.1 },
	{ ["Orc"] = 1.1, ["Khajiit"] = 1.1 },
	{ ["Orc"] = 1.1, ["Khajiit"] = 1.1 },
	{ ["Orc"] = 1.1, ["Khajiit"] = 1.1 },
	{ ["Orc"] = 1.1, ["Khajiit"] = 1.1 },
	{ ["Orc"] = 1.1, ["Khajiit"] = 1.1 },
	{ ["Orc"] = 1.1, ["Khajiit"] = 1.1 }

}

local function initializedCallback(e)
        for i = 1, table.getn(facemaskID), 1 do
        onion.register {
            id      = facemaskID[i],
            slot    = facemaskSlot[i],
			racePos = facemaskPos[i],
			raceScale = facemaskScale[i]
    }
	end
end
event.register("initialized", initializedCallback, { priority = onion.offsetValue + 1 })

