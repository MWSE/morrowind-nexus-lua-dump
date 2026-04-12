local M = {}

-- used in both performer and detector
local warningColor = "\27[38;5;180m"
-- local defaultColor = "\27[0m"

local function insertAfterNewlines(str, insertText)
	return str:gsub("(\n)", "%1" .. insertText)
end

function M.warningPrint(...)
	local args = { ... }
	for i, v in ipairs(args) do
		args[i] = insertAfterNewlines(tostring(v), warningColor)
	end
	table.insert(args, 1, warningColor)
	print(table.unpack(args))
end

function M.canPerformStackAction(focusedContainer, types, uiMode, currentStackType)
	if not M.isValidContainerOpen(focusedContainer, types, uiMode) then
		-- DB.log("attempt to perform stack action while valid container is not open")
		return false
	end

	if currentStackType ~= Keys.CONSTANT_KEYS.Options.StackType.None then
		if DB.logging then
			DB.log("attempt to do stack action" .. " stacks while " .. currentStackType .. " stacks is already running")
		end
		return false
	end
	return true
end

function M.isValidContainerOpen(focusedContainer, types, uiMode)
	if uiMode ~= "Container" then
		-- DB.log("ui mode does not equal container: ", uiMode)
		return false
	end
	if not M.isContainerValid(focusedContainer, types) then
		-- DB.log("valid copntainer not open")
		return false
	end
	return true
end

function M.isContainerValid(container, types)
	if container == nil then
		return false
	end
	if types.Actor.objectIsInstance(container) then
		-- DB.log("container is actor:")
		return types.Actor.isDead(container)
	end
	if not types.Container.objectIsInstance(container) then
		return false
	end

	return true
end

function M.listHasValue(list, value)
	for _, v in ipairs(list) do
		if v == value then
			return true
		end
	end
	return false
end

function M.convertTableKeyListToMaxLengthString(tbl, maxStringLength, wordCutOffLength)
	local elpises = "..."
	local comma = ", "
	local stringList = {}
	local remainingStringLength = maxStringLength

	local workingString = ""
	for key, _ in pairs(tbl) do
		DB.log("remainingStringLength: ", remainingStringLength)
		if remainingStringLength >= #key + #comma + wordCutOffLength + #elpises then
			workingString = key .. comma
			table.insert(stringList, workingString)
			remainingStringLength = remainingStringLength - (#key + #comma)
		elseif remainingStringLength >= wordCutOffLength + #elpises then
			workingString = string.sub(key, 0, wordCutOffLength) .. elpises
			table.insert(stringList, workingString)
			remainingStringLength = remainingStringLength - (wordCutOffLength + #elpises)
			break
		end
	end

	if DB.logging then
		local finishedString = table.concat(stringList)
		DB.log("string length: ", #finishedString)
		return finishedString
	end

	return table.concat(stringList)
end

function M.elipseListString(str, maxSize)
	if #str <= maxSize then
		return str
	else
		local elipses = "..."
		str = string.sub(str, 0, maxSize - #elipses)

		DB.log("ends with: " .. string.sub(str, -2))
		if string.sub(str, -1) == "," then
			str = string.sub(str, 0, -2)
		elseif string.sub(str, -2) == ", " then
			str = string.sub(str, 0, -3)
		end
		return str .. elipses
	end
end

function M.tableKeysToList(tbl)
	local list = {}
	-- table.sort(tbl)
	for k, _ in pairs(tbl) do
		table.insert(list, k)
	end
	return list
end

return M
