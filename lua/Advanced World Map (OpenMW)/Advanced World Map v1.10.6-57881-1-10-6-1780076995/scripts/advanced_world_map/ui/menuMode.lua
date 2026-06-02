local UI = require("openmw.interfaces").UI
local core = require("openmw.core")

local this = {}


local modeId = "Journal"

local activated = false


function this.activate()
    activated = true
    UI.addMode(modeId, {windows = {}})
end


function this.deactivate()
    if not activated then return end
    UI.removeMode(modeId)
    activated = false
end


function this.isActivated()
    return activated
end


function this.setActivatedFlag(val)
    activated = val and true or false
end


---@return boolean
function this.isActive()
    if not activated then return false end
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