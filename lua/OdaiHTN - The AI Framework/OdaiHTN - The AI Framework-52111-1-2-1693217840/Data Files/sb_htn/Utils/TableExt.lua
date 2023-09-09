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
end
