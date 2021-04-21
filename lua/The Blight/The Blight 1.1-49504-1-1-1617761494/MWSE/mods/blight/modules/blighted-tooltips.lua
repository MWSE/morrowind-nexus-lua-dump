local common = require("blight.common")

local function onTooltipDrawn(e)
    if not e.reference then return end

    if not common.config.enableTooltip then return end

    -- ensure the reference is susceptible to blight
    if (e.object.organic ~= true
        and e.object.objectType ~= tes3.objectType.npc
        and e.object.objectType ~= tes3.objectType.creature)
    then
        return
    end

    -- only interested in references afflicted by blight
    if not common.hasBlight(e.reference) then
        return
    end

    local name = e.tooltip:findChild(tes3ui.registerID("HelpMenu_name"))
    if name and not name.text:lower():find("blight") then
        name.text = name.text .. " (Blighted)"
    end
end
event.register("uiObjectTooltip", onTooltipDrawn, {priority=100})
