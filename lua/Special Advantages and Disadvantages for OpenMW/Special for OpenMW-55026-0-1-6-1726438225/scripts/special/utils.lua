local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local table = _tl_compat and _tl_compat.table or table; local ui = require('openmw.ui')

function lookupLayout(layout, names)
   local current = layout
   for _, name in ipairs(names) do
      current = current.content[name]
      if current == nil then
         error('Unable to find layour with name ' .. name .. '(names: ' .. table.concat(names, ".") .. ')')
      end
   end
   return current
end
