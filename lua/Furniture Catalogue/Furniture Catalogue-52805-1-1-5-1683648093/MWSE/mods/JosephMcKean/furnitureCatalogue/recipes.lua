local ashfall = include("mer.ashfall.interop")
local bedroll = include("mer.ashfall.items.bedroll")
local CraftingFramework = require("CraftingFramework")
local Craftable = CraftingFramework.Craftable
local MenuActivator = CraftingFramework.MenuActivator

local catalogue = require("JosephMcKean.furnitureCatalogue.catalogue")
local common = require("JosephMcKean.furnitureCatalogue.common")
local config = require("JosephMcKean.furnitureCatalogue.config")
local furnConfig = require("JosephMcKean.furnitureCatalogue.furnConfig")

local log = common.createLogger("recipes")

--- Returns the recipe id of the furniture recipe
---@param furniture furnitureCatalogue.furniture
---@return string id
local function recipeId(furniture)
	return "FurnitureCatalogue:" .. furniture.id
end

local ashfallOnlyCategory = {
	["Beds"] = bedroll and bedroll.buttons.sleep,
	["Water"] = {
		text = "Ashfall: Water Menu",
		callback = function(e)
			event.trigger("Ashfall:WaterMenu")
		end,
	},
}

--- Returns the additionalMenuOptions for furniture recipes
---@param index string
---@param furniture furnitureCatalogue.furniture
local function additionalMenuOptions(index, furniture)
	local buttons = {}
	-- Only register beds if Ashfall is installed
	if ashfallOnlyCategory[furniture.category] and ashfall then
		table.insert(buttons, ashfallOnlyCategory[furniture.category])
	end
	return buttons
end

---@param furniture furnitureCatalogue.furniture
---@return number
local function goldCount(furniture)
	return furniture.cost
end

---@param ref tes3reference
local function getNewStock(ref)
	ref.data.furnitureCatalogue.todayStock = {}
	local picked = {}
	local stockAmount = config.stockAmount
	--- From the list of furniture, we randomly pick 50
	for i = 1, stockAmount do
		picked[math.random(1, table.size(furnConfig.furniture))] = true
	end
	local j = 1
	-- Faction specific furniture feature is still in development
	-- local isAshlander = common.isAshlander(ref)
	--- Loop through the list of furniture again
	for index, furniture in pairs(furnConfig.furniture) do
		--- if it should always be in stock, or is one of the picked ones
		if furniture.alwaysInStock or picked[j] then
			--- if the player or the merchant selling the furniture is an Ashlander
			--[[if isAshlander then
				--- and the furniture is available at Ashlander merchant
				if furniture.ashlandersAvailable or furniture.ashlandersOnly then
					log:debug("%s is %s, adding to todayStock", furniture.id,
					          (furniture.ashlandersAvailable and "ashlandersAvailable") or (furniture.ashlandersOnly and "ashlandersOnly") or "not available")
					--- add the furniture to today's list of available furniture
					ref.data.furnitureCatalogue.todayStock[furniture.id] = true
				end
			else
				--- if the player or the merchant is not an Ashlander though, check if the furniture can only be sold at Ashlander.
				--- if not, add the furniture to today's list of available furniture
				if not furniture.ashlandersOnly then
					log:debug("%s is %s, adding to todayStock", furniture.id, (furniture.ashlandersOnly and "ashlandersOnly") or "not ashlandersOnly")
					ref.data.furnitureCatalogue.todayStock[furniture.id] = true
				end
			end]]
			ref.data.furnitureCatalogue.todayStock[furniture.id] = true
		end
		j = j + 1
	end
end

--- Custom requirement for furniture being purchasable
local customRequirements = {
	---@param furniture furnitureCatalogue.furniture
	inStock = function(furniture)
		return {
			getLabel = function()
				return "In-Stock"
			end,
			check = function()
				local today = tes3.findGlobal("DaysPassed").value
				tes3.player.data.furnitureCatalogue = tes3.player.data.furnitureCatalogue or {}
				--- Get new stock every day
				if tes3.player.data.furnitureCatalogue.today ~= today then
					getNewStock(tes3.player)
					tes3.player.data.furnitureCatalogue.today = today
				end
				if tes3.player.data.furnitureCatalogue.todayStock[furniture.id] then
					return true
				else
					return false, string.format("Unfortunately, this product is out of stock.")
				end
			end,
		}
	end,
}

--- Thanks Merlord for adding this register soundType feature
CraftingFramework.SoundType.register({
	id = "spendMoney",
	soundPaths = {
		"jsmk\\fc\\spendMoneyCoin1.wav",
		"jsmk\\fc\\spendMoneyCoin2.wav",
		"jsmk\\fc\\spendMoneyCoin3.wav",
		"jsmk\\fc\\spendMoneyCoin4.wav",
		"jsmk\\fc\\spendMoneyCoinBag1.wav",
	},
})
--- I am doing this cast because the soundType parameter accepts CraftingFramework.Craftable.SoundType
--- But "spendMoney" is not one of the alias
local soundType = "spendMoney" ---@cast soundType CraftingFramework.Craftable.SoundType

---@param self CraftingFramework.Craftable
---@param e CraftingFramework.Craftable.SuccessMessageCallback.params
---@return string successMessage
local function successMessageCallback(self, e)
	return string.format("%s has been added to your inventory.", self.name)
end

---@param recipes CraftingFramework.Recipe.data[]
---@param index string
---@param furniture furnitureCatalogue.furniture
local function addRecipe(recipes, index, furniture)
	local furnitureObj = tes3.getObject(furniture.id)
	if not furnitureObj then
		return
	end
	-- Only register beds if Ashfall is installed
	if furniture.category == "Beds" then
		if not ashfall then
			return
		end
	end
	--- The recipe for the furniture
	---@type CraftingFramework.Recipe 
	local recipe = {
		id = recipeId(furniture),
		craftableId = furniture.id,
		additionalMenuOptions = additionalMenuOptions(index, furniture),
		description = furniture.description,
		materials = { { material = "gold_001", count = goldCount(furniture) } }, --- It would be cool if the count parameter here can accept function
		knownByDefault = not furniture.notForSale, --- this is for duplicate furniture
		customRequirements = { customRequirements.inStock(furniture) },
		category = furniture.category,
		name = furniture.name,
		soundType = soundType,
		scale = furniture.scale,
		previewMesh = furnitureObj.mesh,
		successMessageCallback = function(self, e)
			return successMessageCallback(self, e)
		end,
	}
	table.insert(recipes, recipe)
end

--- Registering MenuActivator
do
	if not MenuActivator then
		return
	end
	local recipesCatalogueI = {} ---@type CraftingFramework.Recipe.data[]
	---@param index string 
	---@param furniture furnitureCatalogue.furniture
	for index, furniture in pairs(furnConfig.furniture) do
		addRecipe(recipesCatalogueI, index, furniture)
	end
	MenuActivator:new({
		name = "Furniture Catalogue: Standard",
		id = "FurnitureCatalogueI",
		type = "event",
		recipes = recipesCatalogueI,
		defaultSort = "name",
		defaultFilter = "canCraft",
		defaultShowCategories = true,
		craftButtonText = "Purchase",
		materialsHeaderText = "Cost",
	})
end
