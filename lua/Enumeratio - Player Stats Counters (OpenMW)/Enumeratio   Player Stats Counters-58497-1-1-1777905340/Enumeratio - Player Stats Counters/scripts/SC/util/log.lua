local DEBUG = false

return function(str)
    if DEBUG then
        print("[SC DEBUG] " .. tostring(str))
    end
end
