-- Silk function for wildcard ingredients
wildcardFunctions["Any silk"] = function()
    local ret = {}
    for _, item in pairs(types.Player.inventory(self):getAll()) do
        if (item.recordId:find("silk") or item.recordId:find("silkbolt")) 
        and types.Miscellaneous.objectIsInstance(item) 
        then
            table.insert(ret, item)
        end
    end
    table.sort(ret, function(a,b) return a.count > b.count end)
    return ret
end


-- Cloth function for wildcard ingredients
wildcardFunctions["Any cloth"] = function()
    local ret = {}
    for _, item in pairs(types.Player.inventory(self):getAll()) do
        if (item.recordId:find("cloth") or item.recordId:find("clothbolt")) 
        and types.Miscellaneous.objectIsInstance(item) then
            table.insert(ret, item)
        end
    end
    table.sort(ret, function(a,b) return a.count > b.count end)
    return ret
end


-- Basket function for wildcard ingredients
wildcardFunctions["Any basket"] = function()
    local ret = {}
    for _, item in pairs(types.Player.inventory(self):getAll()) do
        if (item.recordId:find("basket")) 
        and types.Miscellaneous.objectIsInstance(item) 
        then
            table.insert(ret, item)
        end
    end
    table.sort(ret, function(a,b) return a.count > b.count end)
    return ret
end


-- Drum function for wildcard ingredients
wildcardFunctions["Any drum"] = function()
    local ret = {}
    for _, item in pairs(types.Player.inventory(self):getAll()) do
        if (item.recordId:find("drum")) 
        and types.Miscellaneous.objectIsInstance(item) 
        then
            table.insert(ret, item)
        end
    end
    table.sort(ret, function(a,b) return a.count > b.count end)
    return ret
end


-- Cutlery_Fork function for wildcard ingredients
wildcardFunctions["Any fork"] = function()
    local ret = {}
    for _, item in pairs(types.Player.inventory(self):getAll()) do
        if (item.recordId:find("fork")) 
        and types.Miscellaneous.objectIsInstance(item) 
        then
            table.insert(ret, item)
        end
    end
    table.sort(ret, function(a,b) return a.count > b.count end)
    return ret
end


-- Cutlery_Knife function for wildcard ingredients
wildcardFunctions["Any spoon"] = function()
    local ret = {}
    for _, item in pairs(types.Player.inventory(self):getAll()) do
        if (item.recordId:find("spoon")) 
        and types.Miscellaneous.objectIsInstance(item) 
        and not
			(item.type.record(item).model:find("wooden")
			or item.type.record(item).model:find("wood")
            or item.type.record(item).model:find("glass"))
        then
            table.insert(ret, item)
        end
    end
    table.sort(ret, function(a,b) return a.count > b.count end)
    return ret
end


-- Pillow function for wildcard ingredients
wildcardFunctions["Any pillow"] = function()
    local ret = {}
    for _, item in pairs(types.Player.inventory(self):getAll()) do
        if (item.recordId:find("pillow")) and types.Miscellaneous.objectIsInstance(item) then
            table.insert(ret, item)
        end
    end
    table.sort(ret, function(a,b) return a.count > b.count end)
    return ret
end


-- Paper function for wildcard ingredients
wildcardFunctions["Any paper"] = function()
    local ret = {}
    for _, item in pairs(types.Player.inventory(self):getAll()) do
        if (item.recordId:find("paper") or item.recordId:find("sc_paper")) 
        and types.Book.objectIsInstance(item) then
            table.insert(ret, item)
        end
    end
    table.sort(ret, function(a,b) return a.count > b.count end)
    return ret
end


return nil