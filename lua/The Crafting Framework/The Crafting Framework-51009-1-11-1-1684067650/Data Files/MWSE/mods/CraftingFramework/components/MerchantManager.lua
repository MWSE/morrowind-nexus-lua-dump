---@class MerchantManager.registerEvents.params
---@field enabledEvent string (optional) event to listen for to enable the merchant inventories

---@class MerchantManager.ContainerData
---@field merchantId string
---@field contents table<string, number> list of items to add to the merchant container
---@field enabled fun(merchant: tes3reference):boolean (optional) whether the merchant container is enabled by default. Defaults to true

---@class MerchantManager.new.params
---@field modName string name of the mod registering the merchant manager, used as a unique identifier
---@field logger mwseLogger logger to use for logging
---@field containers MerchantManager.ContainerData[] list of containers to register

---@class MerchantManager
---@field modName string name of the mod registering the merchant manager, used as a unique identifier
---@field logger mwseLogger MWSELogger to use for logging
---@field registeredContainers table<string, MerchantManager.ContainerData>
--- A class for managing custom inventories for merchants.
local MerchantManager = {
    registeredMerchantManagers = {}
}

---@param e MerchantManager.new.params
---@return MerchantManager
--- Creates a new MerchantManager
---
--- `modName` name of the mod registering the merchant manager, used as a unique identifier
---
--- `logger` (optional) logger to use for logging. If not set, an MWSELogger will be created using the modName, with log level set to "INFO". This can be accessed via the `logger` property on the returned MerchantManager
---
--- `containers` list of containers to register
function MerchantManager.new(e)
    local self = setmetatable({}, { __index = MerchantManager })
    self.logger = e.logger
    if not self.logger then
        local name = e.modName and e.modName .. ".MerchantManager" or "MerchantManager"
        local MWSELogger = require("logging.logger")
        self.logger = MWSELogger.new {
            name = name,
            logLevel = "INFO"
        }
    end
    self.logger:assert(type(e.modName) == "string", "modName must be provided")
    self.logger:assert(type(e.containers) == "table", "containers must be provided")

    self.modName = e.modName
    self.registeredContainers = {}
    for _, container in ipairs(e.containers) do
        self:registerMerchantContainer(container)
    end
    table.insert(MerchantManager.registeredMerchantManagers, self)
    self.logger:debug("MerchantManager created for %s", e.modName)
    return self
end

---@param e MerchantManager.ContainerData
--- Register a merchant container
---
--- `merchantId` id of the merchant to add the container to
---
--- `contents` list of items to add to the merchant container
---
--- `enabled` (optional) whether the merchant conateiner is enabled by default. Defaults to true
function MerchantManager:registerMerchantContainer(e)
    self.logger:assert(type(e.merchantId) == "string", "merchantId must be a string")
    self.logger:assert(type(e.contents) == "table", "contents must be a table")
    if self.registeredMerchantManagers[e.merchantId:lower()] then
        self.logger:warn("Merchant %s already registered, overwriting", e.merchantId)
    end
    self.logger:debug("Registering merchant container for %s", e.merchantId)
    local contents = {}
    for id, count in pairs(e.contents) do
        self.logger:assert(type(id) == "string", "id must be a string")
        self.logger:assert(type(count) == "number", "count must be a number")
        self.logger:debug("- %s: %d", id, count)
        contents[id:lower()] = count
    end
    self.registeredContainers[e.merchantId:lower()] = {
        contents = contents,
        enabled = e.enabled or function() return true end
    }
end

---@param e MerchantManager.registerEvents.params|nil
--- Register the mobileActivated event to add containers to merchants
---
--- `enabledEvent` (optional) event to listen for to trigger a refresh of merchants that are currently active.
function MerchantManager:registerEvents(e)
    e = e or {}
    ---@param e mobileActivatedEventData
    event.register("mobileActivated", function(e)
        self:processMerchant(e.reference)
    end)
    if type(e.enabledEvent) == "string" then
        event.register(e.enabledEvent, function()
            self:processMerchantsInActiveCells()
        end)
    end
end

---@param merchantRef tes3reference
function MerchantManager:getContainerData(merchantRef)
    return self.registeredContainers[merchantRef.baseObject.id:lower()]
end

---@return string data field name for the container id
function MerchantManager:getMerchantDataField()
    return self.modName .. "_containerData"
end

---@param merchantRef tes3reference
function MerchantManager:getMerchantData(merchantRef)
    local key = self:getMerchantDataField()
    return merchantRef.data[key] or {}
end

---@param merchantRef tes3reference
function MerchantManager:setMerchantData(merchantRef, data)
    local key = self:getMerchantDataField()
    merchantRef.data[key] = data
end

---@param merchantRef tes3reference
function MerchantManager:getContainerId(merchantRef)
    return self:getMerchantData(merchantRef).containerId
end

---@param merchantRef tes3reference
---@param containerId string
function MerchantManager:setContainerId(merchantRef, containerId)
    local data = self:getMerchantData(merchantRef)
    data.containerId = containerId
    self:setMerchantData(merchantRef, data)
end

function MerchantManager:setContentsData(merchantRef)
    local data = self:getMerchantData(merchantRef)
    data.contents = table.copy(self:getContainerData(merchantRef).contents)
    self:setMerchantData(merchantRef, data)
end

function MerchantManager:clearContentsData(merchantRef)
    local key = self:getMerchantDataField()
    merchantRef.data[key] = nil
end

---@param merchantRef tes3reference
---@return tes3reference|nil
function MerchantManager:getExistingContainer(merchantRef)
    local containerId = self:getContainerId(merchantRef)
    if not containerId then return end
    local container = tes3.getReference(containerId)
    if not container then return end
    return container
end

---@param merchantRef tes3reference
---@return tes3reference|nil
function MerchantManager:createContainer(merchantRef)
    local containerObj = tes3.createObject {
        objectType = tes3.objectType.container,
        getIfExists = true,
        name = "Merchant Container",
        mesh = [[EditorMarker.nif]],
        capacity = 10000
    }
    local container = tes3.createReference {
        ---@diagnostic disable-next-line: assign-type-mismatch
        object = containerObj,
        position = merchantRef.position:copy(),
        orientation = merchantRef.orientation:copy(),
        cell = merchantRef.cell
    }
    if container then
        self.logger:debug("Created container %s for merchant %s", container.id, merchantRef.id)
        container.sceneNode.appCulled = true
        ---@diagnostic disable-next-line: assign-type-mismatch
        tes3.setOwner { owner = merchantRef, reference = container }
        self:setContainerId(merchantRef, containerObj.id)
        return container
    else
        self.logger:error("Failed to create merchant container for merchant %s", merchantRef.id)
    end
end

function MerchantManager:clearContainer(containerRef)
    for _, stack in pairs(containerRef.object.inventory) do
        self.logger:debug("Removing %s %s from container %s", stack.count, stack.object.id, containerRef.id)
        tes3.removeItem {
            reference = containerRef,
            item = stack.object,
            itemData = stack.itemData,
            count = stack.count
        }
    end
end

---@param merchantRef tes3reference
---@param containerRef tes3reference
function MerchantManager:populateContainer(merchantRef, containerRef)
    --For each item in the container, check if it is in the contents list, and sync the container with the item list
    local containerData = self:getContainerData(merchantRef)
    if not containerData then
        self.logger:warn("No container data for merchant %s", merchantRef.id)
        return
    end
    local newContents = containerData.contents
    --Check contentsData exists, if so, compare with current contents
    local contentsData = self:getMerchantData(merchantRef).contents
    if not contentsData then
        self:setContentsData(merchantRef)
    else
        --Check if contentsData is different from newContents
        local contentsDataChanged = false
        for id, count in pairs(newContents) do
            if contentsData[id] ~= count then
                contentsDataChanged = true
                break
            end
        end
        if not contentsDataChanged then
            for id, count in pairs(contentsData) do
                if newContents[id] ~= count then
                    contentsDataChanged = true
                    break
                end
            end
        end
        if contentsDataChanged then
            self.logger:debug("Contents data changed, updating container")
            self:setContentsData(merchantRef)
        else
            self.logger:debug("Contents data unchanged, skipping update")
            return
        end
    end

    --Remove all items from the container
    self:clearContainer(containerRef)
    --Add all items from the contents list
    for id, count in pairs(newContents) do
        local item = tes3.getObject(id)
        if item then
            self.logger:debug("Adding item %s to container %s", item.id, containerRef.id)
            ---@diagnostic disable-next-line: assign-type-mismatch
            tes3.addItem { reference = containerRef, item = item, count = count }
        else
            self.logger:warn("Item %s not found", id)
        end
    end
end

---@param merchantRef tes3reference
function MerchantManager:enabledForMerchant(merchantRef)
    local containerData = self:getContainerData(merchantRef)
    if not containerData then return false end
    if not containerData.enabled then return true end
    local enabled = containerData.enabled(merchantRef)
    if not enabled then
        self.logger:debug("Merchant %s is not enabled for merchant containers", merchantRef.id)
    end
    return enabled
end

---@param merchantRef tes3reference
function MerchantManager:processMerchant(merchantRef)
    if not merchantRef then return end
    local containerData = self:getContainerData(merchantRef)
    if not containerData then return end
    local containerRef = self:getExistingContainer(merchantRef)
    if containerRef then
        if not self:enabledForMerchant(merchantRef) then
            self.logger:debug("Merchant %s is not enabled for merchant containers, removing container", merchantRef.id)
            containerRef:disable()
            containerRef:delete()
            self:clearContentsData(merchantRef)
            return
        end
    else
        self.logger:debug("Existing container not found, creating new container")
        containerRef = self:createContainer(merchantRef)
        if not containerRef then
            self.logger:error("Failed to create container for merchant %s", merchantRef.id)
            return
        end
    end
    self.logger:debug("Populating container %s for merchant %s", containerRef.id, merchantRef.id)
    self:populateContainer(merchantRef, containerRef)
end

---@param cell tes3cell
function MerchantManager:processMerchantsInCell(cell)
    for ref in cell:iterateReferences() do
        self:processMerchant(ref)
    end
end

function MerchantManager:processMerchantsInActiveCells()
    for _, cell in pairs(tes3.getActiveCells()) do
        self.logger:debug("Cell: %s", cell.id)
        self:processMerchantsInCell(cell)
    end
end

return MerchantManager
