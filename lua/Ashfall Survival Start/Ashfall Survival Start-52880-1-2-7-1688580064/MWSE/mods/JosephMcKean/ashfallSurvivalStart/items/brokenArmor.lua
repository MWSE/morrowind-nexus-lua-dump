local common = require("JosephMcKean.ashfallSurvivalStart.common")
local log = common.createLogger("brokenArmor")

---@param e cellChangedEventData
local function breakArmor(e)
	if tes3.player.data.ass.brokenIndorilArmor then
		return
	end
	if e.cell.id ~= "Masartus, Monastery" then
		return
	end
	--- This is a generic iterator function that is used
	--- to loop over all the items in an inventory
	---@param ref tes3reference
	---@return fun(): tes3item, integer, tes3itemData|nil
	local function iterItems(ref)
		local function iterator()
			for _, stack in pairs(ref.object.inventory) do
				---@cast stack tes3itemStack
				local item = stack.object

				-- Account for restocking items,
				-- since their count is negative
				local count = math.abs(stack.count)

				-- first yield stacks with custom data
				if stack.variables then
					for _, data in pairs(stack.variables) do
						if data then
							coroutine.yield(item, data.count, data)
							count = count - data.count
						end
					end
				end
				-- then yield all the remaining copies
				if count > 0 then
					coroutine.yield(item, count)
				end
			end
		end
		return coroutine.wrap(iterator)
	end

	local corpse = tes3.getReference("jsmk_ass_corpse")
	if not corpse then
		return
	end
	for item, _, itemData in iterItems(corpse) do
		if item.id:startswith("indoril") then
			if itemData then
				itemData.condition = 1
				tes3.player.data.ass.brokenIndorilArmor = true
			else
				log:debug("No itemData")
			end
		end
	end
end
event.register("cellChanged", breakArmor)
