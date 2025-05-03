local nearby = require("openmw.nearby")
local self = require("openmw.self")
local core = require("openmw.core")
local util = require("openmw.util")
local I = require("openmw.interfaces")
local standingOn
local function checkPlacement()
    if self.contentFile then
        return
    end
    local selfData = {}
    local result = nearby.castRay(self.position, util.vector3(self.position.x,
                                                              self.position.y,
                                                              self.position.z -
                                                                  1000),
                                  {ignore = self})

    if result.hitObject and result.hitObject ~= standingOn then
        standingOn = result.hitObject
        core.sendGlobalEvent("standUpdate",{actor = self, object = standingOn})
    elseif standingOn and not result.hitObject then
        standingOn = nil
        core.sendGlobalEvent("standUpdate",{actor = self, object = nil})
    end

end
local function onActive()
    if self.cell and not self.contentFile then
        
    checkPlacement()
    end
end
local delay = 0
local function onTeleported()
end
local lastCell
local function onUpdate()
    if lastCell ~= self.cell then
        if not self.cell then
            core.sendGlobalEvent("standUpdate",{actor = self, object = nil})
          --  print("Picked up")
        elseif not lastCell and self.cell then
        --    print("dropped")
            checkPlacement()
        end
        lastCell = self.cell
    end
end

return {engineHandlers = {onActive = onActive,onUpdate = onUpdate, onTeleported = onTeleported,}}
