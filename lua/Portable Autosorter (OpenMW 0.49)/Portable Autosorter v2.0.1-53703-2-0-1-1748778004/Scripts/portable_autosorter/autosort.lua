-- Declarations --
local core = require("openmw.core")
local self = require('openmw.self')
local nearby = require('openmw.nearby')

local posInfo = {
    cell=self.cell.id,
    position=self.position,
    rotation=self.rotation
}

-- Engine Handlers --
local function onActivated(actor)
    core.sendGlobalEvent("runAutoSort", {
        actor=actor,
        containers=nearby.containers,
        autoSortObject=self.object,
        posInfo=posInfo
    })
end

-- Return --
return {
    engineHandlers = {
        onActivated = onActivated
    }
}