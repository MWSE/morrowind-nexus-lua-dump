
local common = require("mer.midnightOil.common")
local function tryAddContainer(e)
    if not common.modActive() then return end
    --check merchant
    local containerToAdd = common.merchantContainers[string.lower(e.reference.baseObject.id)]
    --check class
    if not containerToAdd and e.reference.object.class then
        containerToAdd = common.merchantClassContainers[e.reference.object.class.id:lower()]
    end
    if containerToAdd then
        e.reference.data.midnightOil = e.reference.data.midnightOil or {}
        if not e.reference.data.midnightOil.containerPlaced then
            e.reference.data.midnightOil.containerPlaced = true
            local container = tes3.createReference{
                object = containerToAdd,
                position = e.reference.position:copy(),
                orientation = e.reference.orientation:copy(),
                cell = e.reference.cell
            }
            tes3.setOwner{ reference = container, owner = e.reference}
            container.sceneNode.appCulled = true
        end
    end
end
event.register("mobileActivated", tryAddContainer )