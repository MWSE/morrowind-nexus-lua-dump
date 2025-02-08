local ultimateFishing = include("mer.fishing")

local fishingNets = {
	{ id = "t_de_fishingnet_01" },
}

event.register("initialized", function()
	if ultimateFishing then
		for _,item in ipairs(fishingNets) do
			ultimateFishing.registerFishingNet(item)
		end
	end
end)
