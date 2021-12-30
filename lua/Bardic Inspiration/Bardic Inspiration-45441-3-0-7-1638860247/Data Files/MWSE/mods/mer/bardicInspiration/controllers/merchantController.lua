
local common = require("mer.bardicInspiration.common")
local gearVersionId = "bardicInspirationGearAdded_v"
local gearVersion = 20211206
local function hasGearAdded(reference)
    return reference.data[gearVersionId .. gearVersion] == true
end
local function setGearAdedd(reference)
    reference.data[gearVersionId .. gearVersion] = true
end


local function createLuteContainerObject()
    common.log:debug("Creating Lute Container Object")
    --create a new container object
    local containerObj = tes3.createObject{
        objectType = tes3.objectType.container,
        getIfExists = true,
        id = common.staticData.merchantContainerId,
        name = "Lutes",
        mesh = [[EditorMarker.nif]],
        capacity = 10000
    }
    if containerObj then
        --Add contents
        for _, data in ipairs(common.staticData.containerContents) do
            if not containerObj.inventory:contains(data.item) then
                common.log:trace("Adding %s %s to container", data.count, data.item)
                containerObj.inventory:addItem(data)
            end
        end
        return containerObj
    end
end

local function createLuteContainerReference(merchantRef, containerObj)
    assert(containerObj, "containerObj is nil")
    local containerRef = tes3.createReference{
        object = containerObj,
        position = merchantRef.position:copy(),
        orientation = merchantRef.orientation:copy(),
        cell = merchantRef.cell,
    }
    if containerRef then
        common.log:debug("Created container reference")
        containerRef.sceneNode.appCulled = true
        tes3.setOwner{ owner = merchantRef, reference = containerRef }
        return containerRef
    end
end



local function removeOldContainers(ref)
    for container in ref.cell:iterateReferences(tes3.objectType.container) do
        if container.baseObject.id:lower() == common.staticData.merchantContainerId:lower() then
            local owner = tes3.getOwner(container)
            if owner.id:lower() == ref.baseObject.id:lower() then
                common.log:debug("Found old container %s, removing", container.object.id)
                container:disable()
                mwscript.setDelete{ reference = container}
            else
                common.log:debug("Owner check failed")
            end
        end
    end
end


local function tryAddContainer(e)
    if not common.config.enabled then return end
    --check merchant
    local isLuteMerchant = common.config.luteMerchants[string.lower(e.reference.baseObject.id)]
    local merchantRef = e.reference
    if not isLuteMerchant then return end
    common.log:debug("is Lute Merchant")

    if not hasGearAdded(merchantRef) then
        setGearAdedd(merchantRef)
        --create object
        local containerObj = createLuteContainerObject()
        if containerObj then
            common.log:debug("Created container object")
        else
            common.log:error("Failed to create container object")
            return
        end
        --remove old reference
        removeOldContainers(merchantRef)
        --create reference
        createLuteContainerReference(merchantRef, containerObj)
    end
end
event.register("mobileActivated", tryAddContainer )