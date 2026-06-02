if not wildcardFunctions["Any rope"] then
    local validRopes = {
        t_com_rope_01 = true,
        t_de_coiledrope_01 = true,
        sd_campingitem_rope = true,
    }

    wildcardFunctions["Any rope"] = function()
        local ret = {}
        for _, item in pairs(types.Player.inventory(self):getAll(types.Miscellaneous)) do
            if validRopes[item.recordId] then
                table.insert(ret, item)
            end
        end
        table.sort(ret, function(a,b) return a.count > b.count end)
        return ret
    end
end

if not wildcardFunctions["Any scrap wood"] then
    local matchStrings = {
        "^t_com_scrapwood",
    }

    wildcardFunctions["Any scrap wood"] = function()
        local ret = {}
        for _, item in pairs(types.Player.inventory(self):getAll(types.Miscellaneous)) do
            for _, matchString in ipairs(matchStrings) do
                if item.recordId:find(matchString) then
                    table.insert(ret, item)
                    break
                end
            end
        end
        table.sort(ret, function(a,b) return a.count > b.count end)
        return ret
    end
end

return {
    {
        id = '!a_fishing_pole',
        craftingCategory = 'Fishing',
        level = 5,
        ingredients = {
            { id = 'Any scrap wood', count = 2 },
            { id = 'ingred_kresh_fiber_01', count = 6 },
        }
    },
    {
        id = 'a_bait_bucket',
        craftingCategory = 'Fishing',
        level = 5,
        ingredients = {
            { id = 'Any scrap wood', count = 4 },
            { id = 'Any rope', count = 1 },
        }
    }
}