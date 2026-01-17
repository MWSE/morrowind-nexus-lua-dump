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

function sk00maUtils.achievementToData(achievement)

    local data = {
        name = achievement.name,
        icon = achievement.icon,
        description = achievement.description,
        bgColor = achievement.bgColor,
        id = achievement.id
    }
    
    return data

end

function sk00maUtils.tableToString(tbl)
    local result = "{"
    local first = true

    for k, v in pairs(tbl) do
        if not first then
            result = result .. ", "
        end
        first = false

        result = result .. string.format("%q = %q", k, tostring(v))
    end

    result = result .. "}"
    return result
end

function sk00maUtils.stringToTable(str)
    local tbl = {}

    str = str:match("{(.*)}")
    if not str or str:match("^%s*$") then
        return tbl
    end

    for key, value in str:gmatch('"(.-)"%s*=%s*"(.-)"') do
        -- convert numbers back
        if tonumber(value) then
            value = tonumber(value)
        elseif value == "true" then
            value = true
        elseif value == "false" then
            value = false
        end

        tbl[key] = value
    end

    return tbl
end

return sk00maUtils