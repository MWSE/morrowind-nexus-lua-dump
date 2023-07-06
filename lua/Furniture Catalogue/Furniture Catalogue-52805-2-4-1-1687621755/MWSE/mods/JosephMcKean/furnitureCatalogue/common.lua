local common = {}
common.mod = "Furniture Catalogue"
local furnConfig = require("JosephMcKean.furnitureCatalogue.furnConfig")

---@param obj tes3object
---@return furnitureCatalogue.furniture?
function common.getFurniture(obj)
	local craftableId = obj.id
	local prefix = "jsmk_fc_crate_"
	if string.startswith(craftableId:lower(), prefix) then
		local index = string.gsub(craftableId, prefix, "")
		return furnConfig.furniture[index]
	end
end

-- Shuffle the table by performing Fisher-Yates twice
---@param x table
function common.shuffle(x)
	for _ = 1, 2 do
		for i = #x, 2, -1 do
			-- pick an element in x[:i+1] with which to exchange x[i]
			local j = math.random(i - 1)
			x[i], x[j] = x[j], x[i]
		end
	end
	return x
end

return common
