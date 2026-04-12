local util = require("openmw_aux.util")
local textColor = "\27[36m"









local M = {}

M.logging = false
M.logging = true

local function insertAfterNewlines(str, insertText)
   return (string.gsub(str, "\n", "\n" .. insertText))
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

   print(table.unpack(args))
end







function M.printTable(t, maxDepth)
   if not M.logging then
      return
   end
   maxDepth = maxDepth or 1
   M.log("====")
   M.log(util.deepToString(t, maxDepth))
   M.log("====")

end

return M
