local core = require("darkcraft/darkcraft_core")

local saveFile = "moreBarter"

local data = {
    barterMul = 3
}

local config = {}

config.load = function()
    mwse.log("Loading config from " .. saveFile)
    local loadedData = core.loadConfig(saveFile)
    if(loadedData ~= nil) then
        if(loadedData.barterMul ~= nil and type(loadedData.barterMul) == "number") then
            mwse.log("Loaded barter multiplier: " .. loadedData.barterMul)
            data.barterMul = loadedData.barterMul
        end
    end
end

config.save = function()
    mwse.log("Saving Config")
    core.saveConfig(saveFile, data)
end

config.getBarterMul = function()
    return data.barterMul
end

config.setBarterMul = function(newValue)
    if(newValue ~= nil and type(newValue) == "number") then
        if(newValue == data.barterMul) then
            return
        end
        mwse.log("Changing barter mul to " .. newValue)
        data.barterMul = newValue
        config.save()
    end
end

return config
