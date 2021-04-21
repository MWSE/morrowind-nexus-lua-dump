local darkcraft = {}

darkcraft.debug = function(o)
    local t = type(o)
    if(t == "table") then
        for i,v in pairs(o) do
            mwse.log(i .. " - " .. type(v))
        end
    elseif(t == "userdata") then
        for i,v in pairs(getmetatable(o)) do
            mwse.log(i .. " - " .. type(v))
        end
    end
end

darkcraft.saveConfig = function(filename, config)
    lfs.mkdir("Data Files/MWSE/config")
    lfs.mkdir("Data Files/MWSE/config/darkcraft")
    json.savefile("config/darkcraft/" .. filename, config, {indent = true})
end

darkcraft.loadConfig = function(filename)
    return json.loadfile("config/darkcraft/" .. filename)
end

return darkcraft