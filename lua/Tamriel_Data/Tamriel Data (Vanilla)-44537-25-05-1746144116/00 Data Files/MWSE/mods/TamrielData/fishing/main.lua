local ultimateFishing = include("mer.fishing")

local fishingNets = {
	{ id = "t_de_fishingnet_01" },
}

local baits = {
    {
        id = "t_com_worms_01",
        type = "bait",
        uses = 20,
    },
}

event.register(tes3.event.initialized, function()
	if ultimateFishing then
		for _,item in ipairs(fishingNets) do
			ultimateFishing.registerFishingNet(item)
		end
		for _, bait in ipairs(baits) do
			ultimateFishing.registerBait(bait)
		end
	end
end)
