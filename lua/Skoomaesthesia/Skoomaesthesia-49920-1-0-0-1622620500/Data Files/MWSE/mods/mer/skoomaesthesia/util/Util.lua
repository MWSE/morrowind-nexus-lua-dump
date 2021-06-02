local Util = {}
local config = require("mer.skoomaesthesia.config")
do --logger
    local logLevel = config.mcm.logLevel
    local logger = require("mer.skoomaesthesia.util.logger")
    Util.log = logger.new{
        name = config.static.modName,
        logLevel = logLevel
    }
end

Util.messageBox = require("mer.skoomaesthesia.util.messageBox")

Util.hasSkooma = function()
    for id, _ in pairs(config.static.skoomaIds) do
        if tes3.player.object.inventory:contains(id) then
            return true
        end
    end
    return false
end

Util.getSkooma = function()
    for id, _ in pairs(config.static.skoomaIds) do
        if tes3.player.object.inventory:contains(id) then
            return id
        end
    end
    return false
end

Util.hasMoonSugar = function()
    for id, _ in pairs(config.static.moonSugarIds) do
        if tes3.player.object.inventory:contains(id) then
            return true
        end
    end
    return false
end

return Util