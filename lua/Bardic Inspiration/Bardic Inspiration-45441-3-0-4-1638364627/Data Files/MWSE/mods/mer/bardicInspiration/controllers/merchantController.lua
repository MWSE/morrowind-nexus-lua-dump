
local common = require("mer.bardicInspiration.common")

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
            common.log:trace("Adding %s %s to container", data.count, data.item)
            containerObj.inventory:addItem(data)
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

local function tryAddContainer(e)
    if not common.config.enabled then return end
    --check merchant
    local isLuteMerchant = common.config.luteMerchants[string.lower(e.reference.baseObject.id)]
    local merchantRef = e.reference
    if not isLuteMerchant then return end
    common.log:debug("is Lute Merchant")
    --create object
    local containerObj = createLuteContainerObject()
    if containerObj then
        common.log:debug("Created container object")
    else
        common.log:error("Failed to create container object")
        return
    end
    --create reference
    local containerRef = createLuteContainerReference(merchantRef, containerObj)
    if containerRef then
        common.log:debug("Created container reference")
    else
        common.log:error("Failed to create container reference")
        return
    end
end
event.register("mobileActivated", tryAddContainer )