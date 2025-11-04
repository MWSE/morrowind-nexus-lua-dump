-- Crafting materials for using in other crafting recipes

wildcardFunctions["Any Raw Silk"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Ingredient)) do
		if item.type.record(item).name:find(" Silk")
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any Thread"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Miscellaneous)) do
		if item.type.record(item).name == "Bobbin"
		or item.type.record(item).id == "misc_spool_01"
		or item.type.record(item).id == "T_Com_GoldThread_01"
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

categoryMapping["M - Materials"] = "Materials"

local file, errorMsg = vfs.open("CF_recipes/CraftingMaterials_Onkija.data")
if file then
	local recipedata = file:read("*all")
	file:close()
	return recipedata
else
	print("Error opening file CF_recipes/CraftingMaterials_Onkija.data :" .. (errorMsg or "unknown error"))
end

