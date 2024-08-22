local self = require("openmw.self")
local core = require("openmw.core")
local lastCellId
local function onUpdate()
    if self.cell.id ~= lastCellId then
        lastCellId = self.cell.id
        core.sendGlobalEvent("onCellChange_Hest",lastCellId)
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate
    }
}