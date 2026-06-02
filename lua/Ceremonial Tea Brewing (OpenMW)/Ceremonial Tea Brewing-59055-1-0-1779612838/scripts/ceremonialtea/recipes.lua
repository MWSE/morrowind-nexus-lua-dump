-- recipe list. every recipe shares the fields in the loop
-- cup is a wildcard, tea_resolveCup swaps the base for the tea/cup combo the player actually used.

local teaTypes = {
	{
		prefix = "blk",
		category = "Black Teas",
		names = {
			"Corinth Black Tea",
			"Orcrest Chai",
			"Wayrest Breakfast Tea",
			"Riverhold Berry Tea",
			"Rimmen Black Tea",
			"Stoneflower Tea",
			"Senchal Whitetip Black Tea",
			"Willowflower Black Tea",
			"Black Anther Tea",
		},
	},
	{
		prefix = "grn",
		category = "Green Teas",
		names = {
			"Deshaan Green Tea",
			"Akavirian Jasmine Tea",
			"Akavirian Matcha",
			"Deshaan Saltrice Tea",
			"Akavirian Sencha Tea",
			"Willowflower Green Tea",
			"Jorval Green Tea",
		},
	},
	{
		prefix = "herb",
		category = "Herbal Teas",
		names = {
			"Canis Root Tea",
			"Evermore Chamomile Tea",
			"Dragonstar Hibiscus Tea",
			"Janeth Honeybush Tea",
			"Mournhold Lemongrass Tea",
			"Cloudrest Mint Tea",
			"Skaven Redbush Tea",
			"Skaven Redbush Chai",
			"Dragonstar Berry Redbush",
		},
	},
	{
		prefix = "puerh",
		category = "Oolong & Pu'erh",
		names = {
			"Soulrest Oolong",
			"Gideon Green Pu erh",
			"Blackrose Pu erh",
		},
	},
	{
		prefix = "white",
		category = "White Teas",
		names = {
			"Cloudrest White Tea",
			"Shimmerene Silver Tea",
		},
	},
}

local coffeeNames = {
	"Corinth Light Arabica Coffee",
	"Skaven Golden Arabica Coffee",
	"Cespar Light Robusta Coffee",
	"Corinth Dark Arabica Coffee",
	"Skaven Red Arabica Coffee",
	"Cespar Dark Robusta Coffee",
}

-- MiscItem	teamod_funnel_kb01	Sterling Silver Funnel
-- MiscItem	teamod_funnel_kb02	Fine Silver Funnel
-- MiscItem	teamod_funnel_steel	Steel Funnel

------------------------------ build recipes ------------------------------

local list = {}

for _, teaType in ipairs(teaTypes) do
	for i, name in ipairs(teaType.names) do
		local suffix = teaType.prefix .. string.format("%02d", i)
		list[#list + 1] = {
			id = "tm_tea_kb02_" .. suffix,
			nameOpt = name,
			craftingCategory = teaType.category,
			ingredients = {
				{ id = "tm_" .. suffix, count = 1 },
				{ id = "Tea Cup", count = 1 },
			},
			userData = { kind = "tea", suffix = suffix },
		}
	end
end

for i, name in ipairs(coffeeNames) do
	local suffix = "g0" .. i
	list[#list + 1] = {
		id = "tm_cof_kb02_" .. suffix,
		nameOpt = name,
		craftingCategory = "Coffee",
		ingredients = {
			{ id = "tm_coffee_" .. suffix, count = 1 },
			{ id = "Tea Cup", count = 1 },
		},
		userData = { kind = "cof", suffix = suffix },
	}
end

for _, r in ipairs(list) do
	r.level = 1
	r.craftingTime = 5
	r.experience = 5
	r.craftingSound = "alchemy"
	r.resultFunc = "tea_resolveCup"
	r.ingredientsFunc = "tea_batchScale"
	r.countFunc = "tea_batchCount"
	r.skill = "alchemy"
	r.types = "Potion"
	r.secondSkill = "sunsdusk_cooking"
	r.secondLevel = 1
	r.expFunc = "tea_flatExp"
	r.craftingEvent = "tea_brewComplete"
	if r.userData and r.userData.kind == "cof" then
		r.profession = "Brew Coffee"
		r.stations = { { id = "CoffeePot" } }
	else
		r.profession = "Brew Tea"
		r.stations = { { id = "Teakettle" } }
	end
end

return list