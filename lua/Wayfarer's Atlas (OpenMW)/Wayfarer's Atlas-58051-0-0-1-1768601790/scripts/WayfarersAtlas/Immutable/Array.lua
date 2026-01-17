local Array = {}

---@generic T
---@param array T
---@return T
function Array.copy(array)
	local newArray = {}
	for _, item in ipairs(array) do
		table.insert(newArray, item)
	end

	return newArray
end

---@generic T
---@param array T[]
---@param mapFn fun(item: T, index: integer): any
function Array.map(array, mapFn)
	local mappedArray = {}

	for i, item in ipairs(array) do
		mappedArray[i] = mapFn(item, i)
	end

	return mappedArray
end

---@generic T
---@param array T[]
---@param mapFn fun(item: T): any
function Array.mapFilter(array, mapFn)
	local mappedArray = {}

	for i, item in ipairs(array) do
		local result = mapFn(item)
		if result ~= nil then
			table.insert(mappedArray, result)
		end
	end

	return mappedArray
end

---@generic T
---@param array T[]
---@param predicate fun(item: T): boolean
---@return T[]
function Array.filter(array, predicate)
	local filteredArray = {}

	for _, item in ipairs(array) do
		if predicate(item) then
			table.insert(filteredArray, item)
		end
	end

	return filteredArray
end

---@generic T
---@param haystack T[]
---@param selectFn fun(item: T): any
function Array.find(haystack, selectFn, needle)
	if needle == nil then
		needle = true
	end

	for i, item in ipairs(haystack) do
		if selectFn(item) == needle then
			return i
		end
	end

	return nil
end

---@generic T
---@param array T
---@return T
function Array.insert(array, item, pos)
	local newArray = Array.copy(array)
	if pos then
		table.insert(newArray, pos, item)
	else
		table.insert(newArray, item)
	end

	return newArray
end

function Array.remove(array, pos)
	local newArray = Array.copy(array)
	table.remove(newArray, pos)

	return newArray
end

function Array.concat(arrays)
	local final = {}

	for _, array in ipairs(arrays) do
		for _, item in ipairs(array) do
			table.insert(final, item)
		end
	end

	return final
end

function Array.join(...)
	return Array.concat({ ... })
end

return Array
