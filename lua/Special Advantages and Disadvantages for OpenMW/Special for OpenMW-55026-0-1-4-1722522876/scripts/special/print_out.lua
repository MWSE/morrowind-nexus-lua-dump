local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; local _ = require('scripts/special/conf')

GrouppedSpecial = {}






local specials = {}
for _, advantage in ipairs(advantages) do
   table.insert(specials, advantage)
end
for _, disadvantage in ipairs(disadvantages) do
   table.insert(specials, disadvantage)
end

local grouppedSpecials = {}
local grouppedSpecialsByGroup = {}
for _, special in ipairs(specials) do
   local pgroup = ''
   local numParents = 0
   local last = nil

   for i, part in ipairs(special.group) do
      if pgroup ~= '' then
         numParents = numParents + 1
      end
      pgroup = pgroup .. '.' .. part
      if not grouppedSpecialsByGroup[pgroup] then
         local grouppedSpecial = {
            name = part,
            items = {},
            numParents = numParents,
         }
         if last then
            table.insert(last.items, grouppedSpecial)
         end
         grouppedSpecialsByGroup[pgroup] = grouppedSpecial
         if i == 1 then
            table.insert(grouppedSpecials, grouppedSpecial)
         end
      end
      last = grouppedSpecialsByGroup[pgroup]
   end

   if last then
      numParents = numParents + 1
      last.items = last.items or {}
      table.insert(last.items, {
         name = special.name,
         special = special,
         items = {},
         numParents = numParents,
      })
   else
      table.insert(grouppedSpecials, {
         name = special.name,
         special = special,
         items = {},
         numParents = numParents,
      })
   end
end

local toPrint = {}
local function push(specials_)
   table.sort(specials_, function(s1, s2)
      return s1.name < s2.name
   end)
   for i = 0, #specials_ - 1 do
      table.insert(toPrint, specials_[#specials_ - i])
   end
end
push(grouppedSpecials)
while #toPrint > 0 do
   local curr = table.remove(toPrint)
   local str = string.rep(' ', curr.numParents) .. curr.name
   if #curr.items > 0 then
      print(str)
      push(curr.items)
   else
      print(str .. ' [cost:' .. tostring(curr.special.cost) .. ']: ' .. curr.special.description)
   end
end
