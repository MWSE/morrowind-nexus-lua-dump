---@param creature tes3reference
local function calm(creature)
	if creature.object.swims then
		local creatureMobile = creature.mobile ---@cast creatureMobile tes3mobileCreature
		creatureMobile.fight = 0
		if creatureMobile.inCombat then
			creatureMobile:stopCombat(true)
		end
	end
end

local isShrineCell = {
	["Azura's Coast Region (19, 10)"] = true,
	["Azura's Coast Region (19, 11)"] = true,
	["Azura's Coast Region (20, 10)"] = true,
	["Dagon Urul Region (20, 11)"] = true,
}

---@param e cellChangedEventData
local function checkIfShrineCells(e)
	for _, cell in pairs(tes3.getActiveCells()) do
		if tes3.player.data.reflectionsInWater.pilgrimageComplete or isShrineCell[e.cell.editorName] then
			for creature in cell:iterateReferences(tes3.objectType.creature) do
				calm(creature)
			end
		end
	end
end
event.register("cellChanged", checkIfShrineCells)
