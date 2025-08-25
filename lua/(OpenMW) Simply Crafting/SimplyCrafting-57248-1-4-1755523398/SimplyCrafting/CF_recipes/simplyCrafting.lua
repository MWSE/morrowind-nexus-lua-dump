-- Leather function for wildcard ingredients
wildcardFunctions["Any leather"] = function()
    local ret = {}
    for _, item in pairs(types.Player.inventory(self):getAll()) do
        if (item.recordId:find("hide") or item.recordId:find("pelt")) and (types.Ingredient.objectIsInstance(item) or types.Miscellaneous.objectIsInstance(item)) then
            table.insert(ret, item)
        end
    end
    table.sort(ret, function(a,b) return a.count > b.count end)
    return ret
end

return nil