-----------------------------------
-- Argonian Puzzle Canal
-----------------------------------

local common = include("q.PredatorBeastRaces.common")

local puzzleCanalCellID = "vivec, puzzle canal, center"
local amphibious


local function onCellChange(e)
	if e.cell.id:lower() ~= puzzleCanalCellID then

		common.addSpell(amphibious)

	elseif e.cell.id:lower() == puzzleCanalCellID then

		common.removeSpell(amphibious)

		tes3.messageBox("The magic of the Shrine of Courtesy has blocked your natural alteration school abilities.")
	end		-- The magic of the Shrine of Courtesy...
end

-----------------------------------

local function setup()
	event.unregister("cellChanged", onCellChange)

	if common.isArgonian(tes3.player) then

		common.removeSpell("q_Argonian_Amphibious_Start")
		amphibious = tes3.getObject("q_Argonian_Amphibious")

		event.register("cellChanged", onCellChange)
	end
end

event.register("PBR_chargenEnded", setup)
