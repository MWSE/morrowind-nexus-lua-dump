local common = require("JosephMcKean.furnitureCatalogue.common")
local furnConfig = require("JosephMcKean.furnitureCatalogue.furnConfig")

local logging = require("JosephMcKean.furnitureCatalogue.logging")
local log = logging.createLogger("interop")

--[[

	Register Furniture for Furniture Catalogue Explained

	Example Code:

	local furnitureCatalogue = include("JosephMcKean.furnitureCatalogue.interop")
	if furnitureCatalogue then
		furnitureCatalogue.registerFurniture({
			["551"] = { id = "ab_furn_shalk_01", name = "Shalk", category = "Other", cost = 60 },
			["552"] = { id = "flora_ashtree_05", name = "Tree, Ashland", category = "Plants", cost = 120 },
		})
	end

	MAKE SURE YOU REGISTER YOUR FURNITURE BEFORE FURNITURE CATALOGUE FINISHED ADDING RECIPES. 
	You can do that by registering your furniture in event "initialized", 
		and set the priority higher.

	key ("551" in the example): required, the index of the new furniture. 
		index must be a string like "551", NOT a number like 551.
		If a furniture of this index already exists, it will overwrite the previous registered furniture.
		The string could be anything, as long as it is less than or equal to 17 characters.
	id: required, the object id of the new furniture.
	name: required, the name of the new furniture.
	category: required, the category of the new furniture. I suggest you use the existing ones.
	cost: required, the price of the new furniture.

]]

local function registerFurniture(e)
	---@param index string
	---@param furnitureData furnitureCatalogue.furniture
	for index, furnitureData in pairs(e.data) do
		--- Checking validity of the interop data
		assert(type(index) == 'string', "index must be a valid string")
		assert(type(furnitureData.id) == 'string', "id must be a valid string")
		assert(type(furnitureData.name) == 'string', "name must be a string")
		assert(type(furnitureData.category) == 'string', "category must be a string")
		assert(type(furnitureData.cost) == 'number', "cost must be a number")
		if furnitureData.alwaysInStock then assert(type(furnitureData.alwaysInStock) == 'boolean', "alwaysInStock must be a boolean") end
		if furnitureData.scale then assert(type(furnitureData.scale) == 'number', "size must be a number") end
		--- Warning the users that the furniture is getting overwritten
		if furnConfig.furniture[index] then log:info("registerFurniture overwriting furniture[%s] %s with %s", index, furnConfig.furniture[index].id, furnitureData.id) end
		furnConfig.furniture[index] = furnitureData
	end
	return true
end

---@class furnitureCatalogue.Interop
local Interop = { registerFurniture = function(data) return registerFurniture({ data = data }) end }

return Interop
