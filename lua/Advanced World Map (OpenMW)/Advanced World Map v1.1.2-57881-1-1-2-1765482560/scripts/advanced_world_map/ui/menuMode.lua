local UI = require("openmw.interfaces").UI
local core = require("openmw.core")

local this = {}


local modeId = "Journal"


function this.activate()
    UI.addMode(modeId, {windows = {}})
end


function this.deactivate()
    UI.removeMode(modeId)
end


---@return boolean
function this.isActive()
    for _, m in pairs(UI.modes) do
        if m == modeId then
            return true
        end
    end
    return false
end


---@return boolean
function this.isMenuInteractive()
    return (UI.getMode() or core.isWorldPaused()) and true or false
end


return this