local common = require("mer.darkShard.common")
local logger = common.createLogger("telescope")
local ControlPanel = require("mer.darkShard.components.ControlPanel")
local ReferenceManager = require("CraftingFramework").ReferenceManager

ReferenceManager:new{
    id = "DarkShard:TelescopeSupports",
    onActivated = function(self, reference)
        logger:debug("Adding Control Panel")
        ControlPanel.spawn(reference)
    end,
    requirements = function(self, reference)
        return reference.object.id:lower() == "in_dwrv_scope10"
    end
}

event.register("activate", function(e)
    if not (e.activator == tes3.player) then return end
    if not e.target then return end
    local panel = ControlPanel:new{ reference = e.target }
    if panel then
        panel:activate()
    end
end)