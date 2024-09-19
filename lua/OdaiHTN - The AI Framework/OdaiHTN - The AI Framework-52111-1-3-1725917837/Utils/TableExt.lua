if (mwse == nil) then
    function table.size(t)
        local count = 0
        for _ in pairs(t) do
            count = count + 1
        end
        return count
    end

    function table.removevalue(t, value)
        for k, v in ipairs(t) do
            if (v == value) then
                table.remove(t, k)
                break
            end
        end
    end

    function table.new(n, m)
        local t = {}
        for i = 1, n do
            table.insert(t, {})
            for j = 1, m do
                table.insert(t[i], {})
            end
        end
        return t
    end
end
