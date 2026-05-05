local cam = require('openmw.interfaces').Camera
local camera = require('openmw.camera')
local core = require('openmw.core')
local self = require('openmw.self')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')
local storage = require("openmw.storage")
local async = require("openmw.async")
local input = require("openmw.input")
local calendar = require('openmw_aux.calendar')
local lastCell
local lastHour
local function onUpdate(dt)
    if self.cell ~= lastCell then
        lastCell = self.cell
        core.sendGlobalEvent("CellChange", self)
        self:sendEvent("CellChange", self)
    end
    local hour = calendar.formatGameTime("%H")
    if hour ~= lastHour then
        lastHour = hour
        core.sendGlobalEvent("hourChange",self)
    end
end

local function UiModeChanged(data)
    data.player = self
    core.sendGlobalEvent("UiModeChanged", data)
end
return {
    interfaceName = "ZS_Events",
    interface = {
    },
    engineHandlers = {
        onUpdate = onUpdate
    },
    eventHandlers = {
        UiModeChanged = UiModeChanged,
    }
}
