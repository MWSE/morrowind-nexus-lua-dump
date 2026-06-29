local function lookupLayout(layout, names)
   local current = layout
   for _, name in ipairs(names) do
      current = current.content[name]
      if current == nil then
         error('Unable to find layout with name ' .. name .. ' (names: ' .. table.concat(names, ".") .. ')')
      end
   end
   return current
end

return {
   lookupLayout = lookupLayout,
}
