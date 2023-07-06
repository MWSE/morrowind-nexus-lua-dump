local ashfall = include("mer.ashfall.interop")
local bedroll = include("mer.ashfall.items.bedroll")
local CraftingFramework = require("CraftingFramework")
local MenuActivator = CraftingFramework.MenuActivator

local catalogue = require("JosephMcKean.furnitureCatalogue.catalogue")
local common = require("JosephMcKean.furnitureCatalogue.common")
local config = require("JosephMcKean.furnitureCatalogue.config")
local furnConfig = require("JosephMcKean.furnitureCatalogue.furnConfig")

local logging = require("JosephMcKean.furnitureCatalogue.logging")
local log = logging.createLogger("recipes")

---@param id string
---@return string newId
local function generateNewId(id)
	local idLen = id:len()
	local prefix = "jsmk_fc_"
	local prefixLen = prefix:len()
	local maxLen = 31
	local subLen = idLen + prefixLen - maxLen
	local subbedId = ""
	local subbedLen = 0
	local newId = prefix .. id

	---@return string
	local function subUnderScore()
		subbedId, subbedLen = id:gsub("_", "", subLen)
		newId = prefix .. subbedId
		if subbedLen < subLen then
			subLen = subLen - subbedLen
			newId = prefix:sub(1, prefixLen - subLen) .. subbedId
		end
		return newId
	end

	if newId:len() > maxLen then
		newId = subUnderScore()
		if newId:len() > maxLen then log:error("newId %s too long", newId) end
	end
	return newId
end

--- Returns the recipe id of the furniture recipe
---@param furniture furnitureCatalogue.furniture
---@return string id
local function recipeId(furniture) return "FurnitureCatalogue:" .. furniture.newId end

local ashfallOnlyCategory = { ["Beds"] = bedroll and bedroll.buttons.sleep, ["Water"] = { text = "Ashfall: Water Menu", callback = function(e) event.trigger("Ashfall:WaterMenu") end } }

--- Returns the additionalMenuOptions for furniture recipes
---@param index string
---@param furniture furnitureCatalogue.furniture
local function additionalMenuOptions(index, furniture)
	local buttons = {}
	-- Only register beds if Ashfall is installed
	if ashfallOnlyCategory[furniture.category] and ashfall then table.insert(buttons, ashfallOnlyCategory[furniture.category]) end
	local anotherOne = {
		text = "Reorder",
		callback = function(e)
			local id = recipeId(furniture):lower() -- all CF recipe id is lowercased
			local recipe = CraftingFramework.interop.getRecipe(id)
			if recipe then
				log:debug("Found recipe of %s, crafting...", id)
				recipe:craft()
			end
		end,
		enableRequirements = function(e)
			if tes3.getItemCount({ reference = tes3.player, item = "gold_001" }) >= furniture.cost then return true end
			return false
		end,
		tooltipDisabled = function() return { text = "Can't afford another one." } end,
	}
	table.insert(buttons, anotherOne)
	return buttons
end

---@param furniture furnitureCatalogue.furniture
---@return number
local function goldCount(furniture) return furniture.cost end

---@param ref tes3reference
local function getNewStock(ref)
	ref.data.furnitureCatalogue.todayStock = {}
	local validFurniture = table.copy(furnConfig.validFurniture, {}) ---@type string[]
	common.shuffle(validFurniture)
	for i = 1, config.stockAmount do
		local furniture = table.remove(validFurniture) ---@type string
		if not furniture then break end
		ref.data.furnitureCatalogue.todayStock[furniture] = true
	end
end

--- Custom requirement for furniture being purchasable
local customRequirements = {
	---@param furniture furnitureCatalogue.furniture
	inStock = function(furniture)
		return {
			getLabel = function() return "In-Stock" end,
			check = function()
				local today = tes3.findGlobal("DaysPassed").value
				tes3.player.data.furnitureCatalogue = tes3.player.data.furnitureCatalogue or {}
				--- Get new stock every day
				if tes3.player.data.furnitureCatalogue.today ~= today then
					getNewStock(tes3.player)
					tes3.player.data.furnitureCatalogue.today = today
				end
				if tes3.player.data.furnitureCatalogue.todayStock[furniture.id] or furniture.alwaysInStock then
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
	soundPaths = { "jsmk\\fc\\spendMoneyCoin1.wav", "jsmk\\fc\\spendMoneyCoin2.wav", "jsmk\\fc\\spendMoneyCoin3.wav", "jsmk\\fc\\spendMoneyCoin4.wav", "jsmk\\fc\\spendMoneyCoinBag1.wav" },
})
--- I am doing this cast because the soundType parameter accepts CraftingFramework.Craftable.SoundType
--- But "spendMoney" is not one of the alias
local soundType = "spendMoney" ---@cast soundType CraftingFramework.Craftable.SoundType

---@param furniture furnitureCatalogue.furniture
---@return craftingFrameworkRotationAxis
local function rotationAxis(furniture) return furniture.category == "Rugs" and "y" or "z" end

---@param self CraftingFramework.Craftable
---@param e CraftingFramework.Craftable.SuccessMessageCallback.params
---@return string successMessage
local function successMessageCallback(self, e) return string.format("%s has been added to your inventory.", self.name) end

---@param recipes CraftingFramework.Recipe.data[]
---@param index string
---@param furniture furnitureCatalogue.furniture
local function addRecipe(recipes, index, furniture)
	local furnitureObj = tes3.getObject(furniture.id) ---@cast furnitureObj tes3activator|tes3container|tes3static
	if not furnitureObj then return end
	if furnitureObj.objectType == tes3.objectType.light then -- tes3light doesn't have createCopy method sadly
		furniture.newId = furniture.id
		log:debug("%s is a light", furniture.id)
	elseif furniture.newId == furniture.id then
		log:debug("furniture.newId == furniture.id = %s", furniture.id)
	else
		furniture.newId = furniture.newId or generateNewId(furniture.id)
		log:debug("%s:createCopy({ id = %s })", furniture.id, furniture.newId)
		furnitureObj = furnitureObj:createCopy({ id = furniture.newId })
	end
	-- Only register beds if Ashfall is installed
	if furniture.category == "Beds" then if not ashfall then return end end
	-- Only register alternative recipe if the base recipe does not exist
	if furniture.base then if tes3.getObject(furniture.base) then return end end
	--- The recipe for the furniture
	---@type CraftingFramework.Recipe 
	local recipe = {
		id = recipeId(furniture),
		craftableId = furniture.newId,
		additionalMenuOptions = additionalMenuOptions(index, furniture),
		materials = { { material = "gold_001", count = goldCount(furniture) } }, --- It would be cool if the count parameter here can accept function
		knowledgeRequirement = function() return not (furniture.notForSale or furniture.deprecated or (furniture.category == "Debug" and not config.debugMode)) end, --- this is for duplicate or debug furniture
		customRequirements = { customRequirements.inStock(furniture) },
		category = furniture.category,
		name = furniture.name,
		soundType = soundType,
		materialRecovery = 100, -- Reorder misclick happens too often, might as well full refund
		scale = furniture.scale,
		previewMesh = furnitureObj.mesh,
		rotationAxis = rotationAxis(furniture),
		successMessageCallback = function(self, e) return successMessageCallback(self, e) end,
	}
	table.insert(recipes, recipe)
end

--- Registering MenuActivator
do
	if not MenuActivator then return end
	local recipesCatalogue = {} ---@type CraftingFramework.Recipe.data[]
	---@param index string 
	---@param furniture furnitureCatalogue.furniture
	for index, furniture in pairs(furnConfig.furniture) do addRecipe(recipesCatalogue, index, furniture) end
	MenuActivator:new({
		name = "Furniture Catalogue",
		id = "FurnitureCatalogue",
		type = "event",
		recipes = recipesCatalogue,
		defaultSort = "name",
		defaultFilter = "canCraft",
		defaultShowCategories = true,
		collapseCategories = true,
		craftButtonText = "Purchase",
		materialsHeaderText = "Cost",
	})
end
