-- Nordic And Stalhrim recipes

materialMapping["stalhrim"] = "ingred_raw_Stalhrim_01"

categoryMapping["N - Nordic"] = "Nordic"
categoryMapping["S - Solstheim"] = "Solstheim"

local file, errorMsg = vfs.open("CF_recipes/NordicAndStalhrimCrafting.data")
if file then
	local recipedata = file:read("*all")
	file:close()
	return recipedata
else
	print("Error opening file CF_recipes/NordicAndStalhrimCrafting.data :" .. (errorMsg or "unknown error"))
end

