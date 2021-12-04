
local function hashEffects(ingredient)
	local hashes = {}
	for i = 1, 4 do
		local effect = ingredient.effects[i]
		if (effect > 0) then
			table.insert(hashes, string.format("%03d:%03d:%03d", effect, ingredient.effectAttributeIds[i], ingredient.effectSkillIds[i]))
		end
	end

	table.sort(hashes)
	return json.encode(hashes)
end

event.register("initialized", function(e)
	local data = {}
	for ingredient in tes3.iterateObjects(tes3.objectType.ingredient) do
		local hash = hashEffects(ingredient)
		data[hash] = data[hash] or {}
		table.insert(data[hash], ingredient)
	end

	for k, v in pairs(data) do
		if (#v > 1) then
			local results = {}
			for _, ingredient in ipairs(v) do
				table.insert(results, string.format("%s (%s) [%s]", ingredient.name, ingredient.id, ingredient.mesh))
			end
			mwse.log("Ingredient clash: %s => %s", k, table.concat(results, ", "))
		end
	end
end)
