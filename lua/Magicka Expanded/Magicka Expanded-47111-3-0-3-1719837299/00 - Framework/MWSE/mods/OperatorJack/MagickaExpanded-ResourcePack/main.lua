local pathId = "operatorJackGearAdded"
local sharedContainerId = "OJ_ME_BookContainer"

local merchants = {
    ["simine fralinie"] = sharedContainerId,
    ["jobasha"] = sharedContainerId,
    ["tr_m1_felisel_gavos"] = sharedContainerId,
    ["tr_m1_sevaen_ondyn"] = sharedContainerId,
    ["tr_m2_edheldur"] = sharedContainerId,
    ["tr_m1_cornelius_arjax"] = sharedContainerId,
    ["dorisa darvel"] = sharedContainerId,
    ["codus callonus"] = sharedContainerId
}

local function placeContainer(merchant, containerId)
    local container = tes3.createReference {
        object = containerId,
        position = merchant.position:copy(),
        orientation = merchant.orientation:copy(),
        cell = merchant.cell
    }
    tes3.setOwner {reference = container, owner = merchant}
end

local function onMobileActivated(e)
    local obj = e.reference.baseObject
    local container = merchants[obj.id:lower()]
    if container then
        if e.reference.data[pathId] ~= true then
            e.reference.data[pathId] = true
            placeContainer(e.reference, container)
        end
    end
end
event.register(tes3.event.mobileActivated, onMobileActivated)
