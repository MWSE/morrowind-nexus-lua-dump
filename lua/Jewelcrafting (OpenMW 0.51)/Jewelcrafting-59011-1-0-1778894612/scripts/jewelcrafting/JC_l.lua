content = require('openmw.content')
if not content or not content.miscs or not content.books then return end

local recipes = require("scripts.jewelcrafting.recipes")

content.globals.records["jewelcraftlvl"] = 0

content.miscs.records.jc_pliers_common = {
	name   = "Jewelcrafting Pliers",
	model  = "meshes/tr/m/tr_misc_tongs_01.nif",
	icon   = "icons/tr/m/tr_misc_tongs_01.dds",
	weight = 5.0,
	value  = 50,
}

------------------------------ scroll records ------------------------------

local TIER_VALUES = {
	com = 75,
	exp = 200,
	ext = 500,
	exq = 1500,
}

local TIER_DISPLAY = {
	com = "Common",
	exp = "Expensive",
	ext = "Extravagant",
	exq = "Exquisite",
}

local SCROLL_MODEL = "meshes/m/Text_Scroll_open_02.NIF"
local SCROLL_ICON  = "icons/m/Tx_scroll_open_02.tga"

local function makeScroll(id, headline, body, value)
	content.books.records[id] = {
		name     = headline,
		model    = SCROLL_MODEL,
		icon     = SCROLL_ICON,
		weight   = 0.2,
		value    = value,
		isScroll = true,
		text     = '<DIV ALIGN="CENTER"><FONT COLOR="000000" SIZE="3" FACE="Magic Cards"><BR>'
			.. headline
			.. '<BR><BR></FONT><FONT COLOR="000000" SIZE="2" FACE="Century Gothic">'
			.. body
			.. "<BR></FONT></DIV>",
	}
end

local categories = {}
local seen = {}
for _, r in ipairs(recipes) do
	local ud = r.userData
	if ud.tier == "exq" then
		if type(r.disabled) == "string" and r.disabled:sub(1, 6) == "jc_rs_" then
			categories[#categories + 1] = {
				tier     = ud.tier,
				kind     = ud.kind,
				scrollId = r.disabled,
				recipe   = { id = r.id:lower(), nameOpt = r.nameOpt },
			}
		end
	else
		local key = ud.tier .. "_" .. ud.kind
		if not seen[key] then
			seen[key] = true
			categories[#categories + 1] = {
				tier     = ud.tier,
				kind     = ud.kind,
				scrollId = "jc_rs_" .. ud.tier .. "_" .. ud.kind .. "_wild",
				recipe   = nil,
			}
		end
	end
end

for _, c in ipairs(categories) do
	local headline, body, value
	if c.recipe then
		headline = "Recipe: " .. c.recipe.nameOpt
		body     = "This scroll contains an exquisite jewelcrafting pattern. "
			.. "Reading it will teach you to craft " .. c.recipe.nameOpt .. " and consume the scroll."
		value    = TIER_VALUES.exq
	else
		local kindName = c.kind == "ring" and "Ring" or "Amulet"
		local tierName = TIER_DISPLAY[c.tier]
		headline = "Recipe: " .. tierName .. " " .. kindName
		body     = "This scroll contains a " .. tierName:lower() .. " " .. c.kind
			.. " pattern. Reading it will teach you a new recipe and consume the scroll."
		value    = TIER_VALUES[c.tier] or 75
	end
	makeScroll(c.scrollId, headline, body, value)
end