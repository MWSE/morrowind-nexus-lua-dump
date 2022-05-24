local onion = require("sb_onion.interop")


local hornsID = {
    "_RV_antlers_1",
	"_RV_antlers_2",
	"_RV_horns_1",
    "_RV_horns_2",
    "_RV_horns_3",
	"_RV_ears_1",
	"_RV_ears_2"
}

local hornsSlot = {
    onion.slots.headTop,
	onion.slots.headTop,
	onion.slots.headTop,
	onion.slots.headTop,
	onion.slots.headTop,
	onion.slots.headTop,
	onion.slots.headTop

}

local hornsPos = {
	{ [""] = { 0, 0, 0 } },
	{ [""] = { 0, 0, 0 } },
	{ [""] = { 0, 0, 0 } },
	{ [""] = { 0, 0, 0 } },
	{ [""] = { 0, 0, 0 } },
	{ [""] = { 0, 0, 0 } },
	{ [""] = { 0, 0, 0 } }
}




local function initializedCallback(e)
        for i = 1, table.getn(hornsID), 1 do
        onion.register {
            id      = hornsID[i],
            slot    = hornsSlot[i],
			racePos = hornsPos[i]
    }
	end
end
event.register("initialized", initializedCallback, { priority = onion.offsetValue + 1 })

