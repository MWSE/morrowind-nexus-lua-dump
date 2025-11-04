-- Ebony And Daedric functions for wildcard ingredients

wildcardFunctions["Any Daedric Spear"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("daedric")
		and item.type.record(item).model:find("spear")
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end


wildcardFunctions["Any Ebony Arrow"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("arrow")
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any Ebony Battleaxe"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("battleaxe")
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any Ebony Bolt"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("bolt")
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any Ebony Boots"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Armor)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("boot")
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any Ebony Broadsword"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("broadsword")
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

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

wildcardFunctions["Any Ebony Closed Helm"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Armor)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("helmet")
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any Ebony Club"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("club")
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any Ebony Crossbow"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("crossbow")
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any Ebony Cuirass"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Armor)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("cuirass")
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

wildcardFunctions["Any Ebony Dart"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("dart")
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

wildcardFunctions["Any Ebony Greatsword"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("ebon")
		and 
			(item.type.record(item).model:find("gsword")
			or item.type.record(item).model:find("greatsword"))
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any Ebony Greaves"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Armor)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("greaves")
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

wildcardFunctions["Any Ebony Helm"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Armor)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("helm")
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

wildcardFunctions["Any Ebony Bracer"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Armor)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("bracer")
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any Ebony Knife"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("knife")
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

wildcardFunctions["Any Ebony Longsword"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("longsword")
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any Ebony Mace"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("mace")
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any Ebony Naginata"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("naginata")
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

wildcardFunctions["Any Ebony Pauldron"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Armor)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("pauldron")
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any Ebony Saber"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("saber")
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any Ebony Scepter"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("scepter")
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any Ebony Scimitar"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("scimitar")
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any Ebony Shield"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Armor)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("shield")
		and not item.type.record(item).model:find("tower")
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

wildcardFunctions["Any Ebony Spear"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("spear")
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any Ebony Staff"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("staff")
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

wildcardFunctions["Any Ebony Throwing Star"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("star")
		then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any Ebony Tower Shield"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Armor)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("shield")
		and item.type.record(item).model:find("tower")
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

wildcardFunctions["Any Ebony War Axe"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll(types.Weapon)) do
		if item.type.record(item).model:find("ebon")
		and item.type.record(item).model:find("war")
		and item.type.record(item).model:find("axe")
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

local file, errorMsg = vfs.open("CF_recipes/EbonyAndDaedricCrafting.data")
if file then
	local recipedata = file:read("*all")
	file:close()
	return recipedata
else
	print("Error opening file CF_recipes/EbonyAndDaedricCrafting.data :" .. (errorMsg or "unknown error"))
end

