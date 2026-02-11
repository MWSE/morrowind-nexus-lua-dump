local None = require("scripts/WayfarersAtlas/Immutable/None")

local Dictionary = {}

---@generic T
---@return T
function Dictionary.copy(dict)
	local new = {}
	for k, v in pairs(dict) do
		new[k] = v
	end

	return new
end

---@generic T
---@param dest T
---@return T
function Dictionary.merge(dest, with)
	local new = Dictionary.copy(dest)

	for k, v in pairs(with) do
		if v == None then
			new[k] = nil
		else
			new[k] = v
		end
	end

	return new
end

---@generic T
---@param dest T
---@return T
function Dictionary.mergeDeep(dest, with)
	local new = Dictionary.copy(dest)

	for k, v in pairs(with) do
		if v == None then
			new[k] = nil
		elseif type(v) == "table" and type(dest[k]) == "table" then
			new[k] = Dictionary.mergeDeep(dest[k], v)
		else
			new[k] = v
		end
	end

	return new
end

local function compareDeep(t1, t2)
	for key, value in pairs(t1) do
		if type(value) ~= type(t2[key]) then
			return false
		elseif type(value) == "table" and type(t2[key]) == "table" then
			if not compareDeep(value, t2[key]) then
				return false
			end
		elseif value ~= t2[key] then
			return false
		end
	end

	return true
end

---@param t1 table
---@param t2 table
function Dictionary.equalsDeep(t1, t2)
	return compareDeep(t1, t2) and compareDeep(t2, t1)
end

return Dictionary
