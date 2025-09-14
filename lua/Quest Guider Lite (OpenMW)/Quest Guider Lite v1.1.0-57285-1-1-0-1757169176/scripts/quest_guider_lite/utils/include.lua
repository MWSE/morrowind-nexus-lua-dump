return function(path)
    local res, out = pcall(function ()
        return require(path)
    end)
    return res and out or nil
end