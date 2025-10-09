-- Ebony And Daedric functions for wildcard ingredients

wildcardFunctions["Any Ebony Claymore"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("claymore")
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any Ebony Dagger"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("dagger")
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any Ebony Dai-Katana"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("ebon")
		and
			(item.type.record(item).model:find("daikatana")
			or item.type.record(item).model:find("dkatana"))
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any Ebony Halberd"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("halberd")
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any Ebony Katana"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("katana")
		and not
			(item.type.record(item).model:find("daikatana")
			or item.type.record(item).model:find("dkatana"))
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any Ebony Longbow"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("ebon")
		and
			(item.type.record(item).model:find("longbow")
			or item.type.record(item).model:find("_bow"))
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any Ebony Open Helm"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Armor)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("helm")
		and
			(item.type.record(item).model:find("open")
			or item.type.record(item).model:find("helm_o"))
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any Ebony Shortsword"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("ebon")
		and
			(item.type.record(item).model:find("shortsword")
			or item.type.record(item).model:find("ssword"))
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any Ebony Tanto"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("tanto")
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any Ebony Wakizashi"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("wakizashi")
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any Ebony Warhammer"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("ebon")
		and
			(item.type.record(item).model:find("warhammer")
			or item.type.record(item).model:find("whammer"))
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any Silk"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Ingredient)) do
		if item.type.record(item).name:find(" Silk")
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

return "EbonyAndDaedric"

