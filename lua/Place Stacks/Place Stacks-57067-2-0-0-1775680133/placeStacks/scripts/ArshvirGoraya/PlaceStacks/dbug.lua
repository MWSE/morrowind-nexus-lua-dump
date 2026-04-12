local util = require("openmw_aux.util")
local textColor = "\27[36m" -- cyan
-- local defaultColor = "\27[0m"

local M = {}

M.logging = false
-- M.logging = true -- comment this out in production builds!

local function insertAfterNewlines(str, insertText)
	return str:gsub("(\n)", "%1" .. insertText)
end

function M.log(...)
	if not M.logging then
		return
	end
	local args = { ... }

	for i, v in ipairs(args) do
		if type(v) == "table" then
			v = util.deepToString(v, 2)
		end
		args[i] = insertAfterNewlines(tostring(v), textColor)
	end

	table.insert(args, 1, textColor)
	-- table.insert(args, defaultColor)
	print(table.unpack(args))
end

-- function M.uilog(...)
-- 	if not M.logging then
-- 		return
-- 	end
-- end

function M.printTable(t, maxDepth)
	if not M.logging then
		return
	end
	maxDepth = maxDepth or 1
	M.log("====")
	M.log(util.deepToString(t, maxDepth))
	M.log("====")
	-- print("\27[36m====\n" .. util.deepToString(t, maxDepth) .. "\n====\27[0m")
end

return M
