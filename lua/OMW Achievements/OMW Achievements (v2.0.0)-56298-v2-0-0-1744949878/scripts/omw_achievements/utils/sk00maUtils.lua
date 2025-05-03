local sk00maUtils = {}

function sk00maUtils.not_contains(table, value)
    for _, v in ipairs(table) do
        if v == value then
            return false
        end
    end
    return true
end

function sk00maUtils.contains(table, value)
    for _, v in ipairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

function sk00maUtils.search(source, search_list)
    local lookup = {}
    for _, item in ipairs(source) do
        lookup[item] = (lookup[item] or 0) + 1
    end

    for _, item in ipairs(search_list) do
        if not lookup[item] or lookup[item] == 0 then
            return false
        end
        lookup[item] = lookup[item] - 1
    end

    return true
end

function sk00maUtils.getAchievementById(achievementsList, id)

    for i = 1, #achievementsList do
        if achievementsList[i].id == id then
            return achievementsList[i]
        end
    end

end

return sk00maUtils