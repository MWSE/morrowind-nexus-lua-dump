event.register("initialized", function()
	if not tes3.isModActive("Ashfall.esp") then return end
	if not tes3.isModActive("Ashfall Survival Start.esp") then return end

	event.register("loaded", function() tes3.player.data.ass = tes3.player.data.ass or {} end, { priority = 10 })
	-- require("JosephMcKean.ashfallSurvivalStart.survivalistsSense")
	require("JosephMcKean.ashfallSurvivalStart.chargen")
	require("JosephMcKean.ashfallSurvivalStart.items")
	require("JosephMcKean.ashfallSurvivalStart.weather")
	require("JosephMcKean.ashfallSurvivalStart.restInterrupt")
end, { priority = 10 })

event.register("initialized", function()
	local physicalJournal = include("Spammer.Physical Journal.interop")
	if physicalJournal then physicalJournal:registerEsp("Ashfall Survival Start.esp") end
end, { priority = -1010 })

event.register("UIEXP:sandboxConsole", function(e)
	e.sandbox.detectBranches = function()
		local marker = tes3.createObject({ id = "marker_error", objectType = tes3.objectType.miscItem })
		marker.mesh = "marker_error.nif"
		for ref in tes3.player.cell:iterateReferences() do
			if not ref.disabled then
				if ref.id:startswith("ashfall_branch") or ref.id == "ashfall_stone" or ref.id == "ashfall_flint" then
					tes3.createReference({ object = "marker_error", position = ref.position, orientation = ref.orientation })
				end
			end
		end
	end
end)
