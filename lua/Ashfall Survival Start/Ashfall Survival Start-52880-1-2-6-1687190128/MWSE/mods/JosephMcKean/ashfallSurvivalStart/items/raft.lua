local ashfall = require("mer.ashfall.interop")
local bushcrafting = ashfall.bushcrafting
local Recipe = require("CraftingFramework").Recipe

local common = require("JosephMcKean.ashfallSurvivalStart.common")
local log = common.createLogger("raft")

local raft = {}
raft.id = "jsmk_ass_ac_raft"

local function onWater(e)
	local cell = tes3.player.cell
	local waterLevel = cell.hasWater and cell.waterLevel
	if not cell.isInterior and waterLevel and e.reference.position.z - waterLevel < 30 then
		return true
	end
	return false
end

local function canSail(e)
	return tes3.player.data.ass.hasMap and onWater(e)
end

local sailHome = {
	text = "Sail Home",
	callback = function(e)
		if tes3.isModActive("TR_Mainland.esm") then
			tes3.positionCell({ reference = tes3.player, cell = "Bal Oyra", position = { 152976, 202552, 94 }, orientation = { 0, 0, 4.37 } })
		else
			tes3.positionCell({ reference = tes3.player, cell = "Dagon Fel", position = { 61617, 183466, 36 } })
		end
		tes3.updateJournal({ id = "jsmk_ass", index = 70, showMessage = true })
	end,
	enableRequirements = canSail,
	tooltipDisabled = function(e)
		return {
			text = onWater(e) and "You don't know which direction is Vvardenfell. Maybe there's a map on this island." or "The raft needs to be placed on open water.",
		}
	end,
}

---@type CraftingFramework.CustomRequirement.data
local outdoorsOnly = {
	getLabel = function()
		return "Outdoors"
	end,
	check = function()
		local cell = tes3.player.cell
		local isOutdoors = not cell.isInterior
		if isOutdoors then
			return true
		else
			return false, "You must be outdoors to craft this"
		end
	end,
}

--- @param e CraftingFramework.MenuActivator.RegisteredEvent
local function registerBushcraftingRecipe(e)
	log:debug("Ashfall:ActivateBushcrafting:Registered")
	local bushcraftingActivator = e.menuActivator
	--- @type CraftingFramework.Recipe.data
	local recipe = {
		id = raft.id,
		craftableId = raft.id,
		additionalMenuOptions = { sailHome },
		description = "A raft to sail home.",
		materials = { { material = "wood", count = 14 }, { material = "resin", count = 4 }, { material = "rope", count = 7 }, { material = "straw", count = 1 } },
		knownByDefault = false,
		skillRequirements = { ashfall.bushcrafting.survivalTiers.apprentice },
		customRequirements = { outdoorsOnly },
		soundType = "wood",
		category = "Structures",
		craftCallback = function()
			tes3.player.data.ass.hasRaft = true
			if tes3.player.data.ass.hasMap then
				tes3.updateJournal({ id = "jsmk_ass", index = 60, showMessage = true })
			else
				tes3.updateJournal({ id = "jsmk_ass", index = 30, showMessage = true })
			end
		end,
	}
	local recipes = { recipe }
	bushcraftingActivator:registerRecipes(recipes)
end
event.register("Ashfall:ActivateBushcrafting:Registered", registerBushcraftingRecipe)

return raft
