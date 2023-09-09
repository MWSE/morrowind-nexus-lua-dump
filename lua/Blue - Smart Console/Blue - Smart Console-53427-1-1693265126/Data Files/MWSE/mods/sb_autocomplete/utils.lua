---@param str string
---@return table<string>
function string.nonTrimSplit(str)
	local endsInWhiteSpace = str:match(" $")
	local t = {}
	for str in string.gmatch(str, "([^%s]+)") do
		table.insert(t, str)
	end
	if (#t > 0) then
		t[#t] = t[#t] .. (endsInWhiteSpace and " " or "")
	end
	return t
end
getmetatable("").nonTrimSplit = string.nonTrimSplit

---@param str string
---@return boolean
function string:contains(str)
    return self:find(str, 1, true) ~= nil
end
getmetatable("").contains = string.contains

---@param id string
---@return tes3reference
function selectOrGetReference(id)
    local reference = tes3.getReference(id)
    local selectedReference = tes3ui.getConsoleReference()
	return selectedReference or reference
end
getmetatable("").selectOrGetReference = selectOrGetReference