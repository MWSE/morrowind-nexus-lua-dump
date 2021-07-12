
local common = require("mer.theGuarWhisperer.common")
local function tryAddContainer(e)
    local isMerchant = common.getConfig().merchants[string.lower(e.reference.baseObject.id)]
    if isMerchant then

        e.reference.data.theGuarWhisperer = e.reference.data.theGuarWhisperer or {}
        if not e.reference.data.theGuarWhisperer.containerPlaced then
            e.reference.data.theGuarWhisperer.containerPlaced = true
            local container = tes3.createReference{
                object = common.merchantContainer,
                position = e.reference.position:copy(),
                orientation = e.reference.orientation:copy(),
                cell = e.reference.cell
            }
            tes3.setOwner{ reference = container, owner = e.reference}
        end
    end
end
event.register("mobileActivated", tryAddContainer )