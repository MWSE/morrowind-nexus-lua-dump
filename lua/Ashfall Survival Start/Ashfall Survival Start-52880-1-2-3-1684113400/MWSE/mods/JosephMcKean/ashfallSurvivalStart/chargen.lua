local Recipe = require("CraftingFramework").Recipe

local common = require("JosephMcKean.ashfallSurvivalStart.common")
local log = common.createLogger("chargen")
local raft = require("JosephMcKean.ashfallSurvivalStart.items.raft")

local chargen = {}

local safeRef ---@type tes3reference?
local isVanillaItem = { ["common_shirt_01"] = true, ["common_pants_01"] = true, ["common_shoes_01"] = true }

---@class ashfallSurvivalStart.transferItems.params
---@field from tes3reference
---@field to tes3reference

---@param e ashfallSurvivalStart.transferItems.params
local function transferItems(e)
	for _, stack in pairs(e.from.object.inventory) do
		if e.from ~= tes3.player or not isVanillaItem[stack.object.id:lower()] then
			tes3.transferItem(
			{ from = e.from, to = e.to, item = stack.object, count = stack.count, playSound = false, limitCapacity = false, reevaluateEquipment = true })
		end
	end
end

---@param cell tes3cell
local function inMasartus(cell)
	local masartusGridX, masartusGridY = 25, 27
	return math.abs(cell.gridX - masartusGridX) <= 2 and math.abs(cell.gridY - masartusGridY) <= 2
end

---@param e cellChangedEventData
local function leaveIsland(e)
	if tes3.player.data.ass.charGenFinished and not tes3.player.data.ass.returnCharGenItems then
		if not e.cell.isInterior and not inMasartus(e.cell) then
			safeRef = safeRef or tes3.getReference("jsmk_ass_co_safe")
			transferItems({ from = safeRef, to = tes3.player })
			tes3.messageBox("Modded starting equipment has been added to your inventory.")
			Recipe.getRecipe(raft.id):unlearn()
			tes3.player.data.ass.returnCharGenItems = true
		end
	end
end
event.register("cellChanged", leaveIsland)

local function transferCharGenItems(e)
	tes3.player.data.ass.charGenFinished = true
	timer.start({
		type = timer.simulate,
		duration = 0.8, -- AotC is 0.7
		callback = function()
			safeRef = tes3.getReference("jsmk_ass_co_safe")
			transferItems({ from = tes3.player, to = safeRef })
		end,
	})
	timer.start({
		type = timer.simulate,
		duration = 2.1, -- ashfall is 2.0
		callback = function()
			tes3.messageBox("Modded starting equipment has been temporarily removed.")
			safeRef = safeRef or tes3.getReference("jsmk_ass_co_safe")
			transferItems({ from = tes3.player, to = safeRef })
			Recipe.getRecipe(raft.id):learn()
		end,
	})
end
event.register("charGenFinished", transferCharGenItems)

return chargen
