--- Encapsulates logic for reusable array operations
---@class arrays
local this = {}

--- Checks if a string array contains a specific value (case-insensitive)
---@public
---@param strings string[] An array of strings to search
---@param value string The string value to search for
---@return boolean contains True if the value is found in the array, false otherwise
function this.contains(strings, value)
	for _, v in ipairs(strings) do
		if v:lower() == value:lower() then
			return true
		end
	end
	return false
end

-- This function loops over the references inside the
-- tes3referenceList and adds them to an array-style table
---@public
---@param list tes3referenceList The reference list to convert
---@return tes3reference[] references An array of references extracted from the list
function this.fromReferenceList(list)
	---@type tes3reference[]
	local result = {}
	local i = 1
	if list.size == 0 then
		return {}
	end
	local ref = list.head

	while ref.nextNode do
		result[i] = ref
		i = i + 1
		ref = ref.nextNode
	end

	-- Add the last reference
	result[i] = ref

	return result
end

return this
