local config = require("OEA.OEA8 Craft.config")
local H = {}

local function OnPotion(e)
	local useLabels = config.useLabels and tes3.hasCodePatchFeature(145) and tes3.getFileExists("Icons\\r0\\p\\bargain_106.dds")
	if (useLabels == true) then
		local potion = e.object
		H.applyLabel(potion)
	end
end
event.register("potionBrewed", OnPotion)

-- Labels

do -- applyLabel
	local assets = {icon=".tga", model=".nif"}
	local qualities = {"exclusive", "quality", "fresh", "standard", "cheap", "bargain"}

	function H.applyLabel(potion)
		for asset, suffix in pairs(assets) do
			local current = potion[asset]:lower()
			for _, quality in pairs(qualities) do
				if current:find(quality) then
					local effect = potion.effects[1].id
					potion[asset] = "r0\\p\\" .. quality .. "_" .. effect .. suffix
					break
				end
			end
		end
	end
end


do -- clearLabel
	local assets = {
		icon = {
			bargain = "m\\tx_potion_bargain_01.tga",
			cheap = "m\\tx_potion_cheap_01.tga",
			exclusive = "m\\tx_potion_exclusive_01.tga",
			fresh = "m\\tx_potion_fresh_01.tga",
			quality = "m\\tx_potion_quality_01.tga",
			standard = "m\\tx_potion_standard_01.tga",
		},
		model = {
			bargain = "m\\misc_potion_bargain_01.nif",
			cheap = "m\\misc_potion_cheap_01.nif",
			exclusive = "m\\misc_potion_exclusive_01.nif",
			fresh = "m\\misc_potion_fresh_01.nif",
			quality = "m\\misc_potion_quality_01.nif",
			standard = "m\\misc_potion_standard_01.nif",
		},
	}
	function H.clearLabel(potion)
		for asset, qualities in pairs(assets) do
			local current = potion[asset]:lower()
			for quality, filename in pairs(qualities) do
				if current:find(quality) then
					potion[asset] = filename
					break
				end
			end
		end
	end
end


function H.loadLabels()
	local useLabels = config.useLabels and tes3.hasCodePatchFeature(145) and tes3.getFileExists("Icons\\r0\\p\\bargain_106.dds")

	for potion in tes3.iterateObjects(tes3.objectType.alchemy) do
		local isLabelled = (
			potion.model:lower():find("^r0\\p\\")
			and potion.icon:lower():find("^r0\\p\\")
		)
		if not useLabels and isLabelled then
			H.clearLabel(potion)
		elseif useLabels and not isLabelled then
			H.applyLabel(potion)
		end
	end
end

return H