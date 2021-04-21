local function initialized()

	for creature in tes3.iterateObjects(tes3.objectType.creature) do
	local name = creature.name

	name = string.gsub(name, "Diseased ", "")
	name = string.gsub(name, "Blighted ", "")
	name = string.gsub(name, "Plaguebearer ", "")
	name = string.gsub(name, "Infected ", "")
	name = string.gsub(name, "Plague ", "")
	creature.name = name

    end

	mwse.log("[No Disease Labels] Disease labels removed")
end

event.register("initialized", initialized)