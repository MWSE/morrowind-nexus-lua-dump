event.register("initialized", function()
	---@param e cellChangedEventData
	event.register("cellChanged", function(e)
		for lightRef in e.cell:iterateReferences(tes3.objectType.light) do
			local light = lightRef.object ---@cast light tes3light
			if light.isNegative then
				lightRef:disable()
				lightRef:delete()
			end
		end
	end)
end)
