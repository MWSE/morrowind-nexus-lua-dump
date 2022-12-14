local m = {}

m.bands = {
	"_KD_BandCopper",
	"_KD_BandGold",
	"_KD_BandMithril",
	"_KD_BandOrc",
}

m.chains = {
	"_KD_ChainBlack",
	"_KD_ChainBlackGems",
	"_KD_ChainGold",
	"_KD_ChainGoldGems",
	"_KD_ChainSilver",
	"_KD_ChainSilverGems",
}

m.circlets = {
	"_KD_CircletBBlue",
	"_KD_CircletBGreen",
	"_KD_CircletBPearl",
	"_KD_CircletBRed",
	"_KD_CircletBTopaz",
	"_KD_CircletGBlue",
	"_KD_CircletGGreen",
	"_KD_CircletGPearl",
	"_KD_CircletGRed",
	"_KD_CircletGTopaz",
	"_KD_CircletSBlue",
	"_KD_CircletSGreen",
	"_KD_CircletSPearl",
	"_KD_CircletSRed",
	"_KD_CircletSTopaz",
}

 m.diadems_s =  {
	"_KD_DiaG",
	"_KD_DiaS",
}

m.diadems_g =  {
	"_KD_DiaGDia",
	"_KD_DiaGEm",
	"_KD_DiaGRu",
	"_KD_DiaGSa",
	"_KD_DiaSDia",
	"_KD_DiaSEm",
	"_KD_DiaSRu",
	"_KD_DiaSSa",
	"_KD_WEDia",
	"_KD_WEGreen",
	"_KD_WERed",
}

m.diadems_e = {
	"_KD_elvDia",
	"_KD_elvEm",
	"_KD_elvRu",
	"_KD_twin",
	"_KD_twinS",
}

m.crowns = {
	"_KD_CrownCeltic",
	"_KD_CrownCross",
	"_KD_CrownLeather",
}

local function merge(tables)
	local result = {}

	for _, t in ipairs(tables) do
		for _, item in ipairs(t) do
			table.insert(result, item)
		end
	end

	return result
end

m.diadems = merge {m.diadems_e, m.diadems_g, m.diadems_s}

m.all = merge {m.bands, m.chains, m.circlets, m.diadems, m.crowns}

return m