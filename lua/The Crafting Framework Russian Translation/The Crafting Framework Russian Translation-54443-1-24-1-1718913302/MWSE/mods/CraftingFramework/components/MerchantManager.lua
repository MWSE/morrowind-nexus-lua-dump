---@alias MerchantManager.contents table<string, number> Key: item ID, Value: count

---Holds container data for a merchant
---@class MerchantManager.ContainerData
---@field merchantId string id of the merchant to add the container to
---@field contents MerchantManager.contents list of items to add to the merchant container
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
    local merchantId = e.merchantId:lower()
    self.registeredContainers[merchantId] = {
        merchantId = merchantId,
        contents = contents,
        enabled = e.enabled or function() return true end
    }
end

---@param e? { enabledEvent: string }
--- Register the events that keep the merchant containers up to date.
--- Pass an "enabledEvent" to update merchants when the event is fired.
function MerchantManager:registerEvents(e)
    e = e or {}
    ---@param e mobileActivatedEventData
    event.register("mobileActivated", function(e)
        self:processMerchant(e.reference)
    end)
    event.register("activate", function(e)
        self:processMerchant(e.target)
    end)
    if type(e.enabledEvent) == "string" then
        event.register(e.enabledEvent, function()
            self:processMerchantsInActiveCells()
        end)
    end
end

--- Get the container data for a given merchant reference
---@param merchantRef tes3reference
function MerchantManager:getContainerData(merchantRef)
    return self.registeredContainers[merchantRef.baseObject.id:lower()]
end

--- Get the data field name for the container id, based on the mod name
---@return string data field name for the container id
function MerchantManager:getMerchantDataField()
    return self.modName .. "_containerData"
end

--- Get the merchant data for a given merchant reference
---@param merchantRef tes3reference
---@return { containerId: string, contents: MerchantManager.contents}
function MerchantManager:getMerchantData(merchantRef)
    local key = self:getMerchantDataField()
    return merchantRef.data[key] or {}
end

--- Set the merchant data for a given merchant reference
---@param merchantRef tes3reference
function MerchantManager:setMerchantData(merchantRef, data)
    local key = self:getMerchantDataField()
    merchantRef.data[key] = data
end

--- Get the container id for a given merchant reference
---@param merchantRef tes3reference
function MerchantManager:getContainerId(merchantRef)
    return self:getMerchantData(merchantRef).containerId
end

--- Set the container id for a given merchant reference
---@param merchantRef tes3reference
---@param containerId string
function MerchantManager:setContainerId(merchantRef, containerId)
    local data = self:getMerchantData(merchantRef)
    data.containerId = containerId
    self:setMerchantData(merchantRef, data)
end

--- Set the contents data for a given merchant reference
function MerchantManager:setContentsData(merchantRef)
    local data = self:getMerchantData(merchantRef)
    data.contents = table.copy(self:getContainerData(merchantRef).contents)
    self:setMerchantData(merchantRef, data)
end

--- Clear the contents data for a given merchant reference
function MerchantManager:clearContentsData(merchantRef)
    local key = self:getMerchantDataField()
    merchantRef.data[key] = nil
end

--- Get the reference of the container for a given merchant reference, if it exists
---@param merchantRef tes3reference
---@return tes3reference|nil
function MerchantManager:getExistingContainer(merchantRef)
    local containerId = self:getContainerId(merchantRef)
    if not containerId then return end
    local container = tes3.getReference(containerId)
    return container
end

--- Create a container for a given merchant reference
---@param merchantRef tes3reference
---@return tes3reference|nil
function MerchantManager:createContainer(merchantRef)
    self.logger:debug("Creating container for merchant %s", merchantRef.id)
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

--- Remove all items from a given container reference
---@param containerRef tes3reference
function MerchantManager:clearContainer(containerRef)
    self.logger:debug("Clearing container %s", containerRef.id)
    for _, stack in pairs(containerRef.object.inventory) do
        self.logger:debug("- Removing %s %s from container %s", stack.count, stack.object.id, containerRef.id)
        tes3.removeItem {
            reference = containerRef,
            item = stack.object,
            count = stack.count
        }
    end
end

--- Add an item to a given container reference, if the item exists
---@param e { containerRef: tes3reference, itemId: string, count: number }
function MerchantManager:addItem(e)
    local item = tes3.getObject(e.itemId)
    if not item then
        self.logger:warn("Item %s not found", e.itemId)
        return
    end
    ---@diagnostic disable-next-line: assign-type-mismatch
    tes3.addItem { reference = e.containerRef, item = item, count = math.abs(e.count) }
end

---Restock any items with negative counts to their absolute value
---@param merchantRef tes3reference The reference of the merchant
---@param containerRef tes3reference The reference of the container
function MerchantManager:restockNegativeCounts(merchantRef, containerRef)
    self.logger:debug("Restocking negative counts for merchant %s", merchantRef.id)
    local containerData = self:getContainerData(merchantRef)
    if not containerData then return end
    local contents = containerData.contents
    for id, count in pairs(contents) do
        if count < 0 then
            local currentCount = containerRef.object.inventory:getItemCount(id)
            local restockCount = math.abs(count) - currentCount
            if restockCount > 0 then
                self.logger:debug("- Restocking %s %s in container %s", restockCount, id, containerRef.id)
                self:addItem {
                    containerRef = containerRef,
                    itemId = id,
                    count = restockCount
                }
            end
        end
    end
end

---Populate a container with the contents list for a given merchant reference
---@param merchantRef tes3reference The reference of the merchant
---@param containerRef tes3reference The reference of the container
function MerchantManager:populateContainer(merchantRef, containerRef)
    self.logger:debug("Populating container %s for merchant %s", containerRef.id, merchantRef.id)
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
        local contentsDataChanged = self.checkContentsChanged(contentsData, newContents)
        if contentsDataChanged then
            self.logger:debug("Contents data changed, updating container")
            self:setContentsData(merchantRef)
        else
            self.logger:debug("Contents data unchanged, do negative restocking")
            self:restockNegativeCounts(merchantRef, containerRef)
            return
        end
    end
    --Remove all items from the container
    self:clearContainer(containerRef)
    --Add all items from the contents list
    for id, count in pairs(newContents) do
        self.logger:debug("- Adding %s %s to container %s", count, id, containerRef.id)
        self:addItem {
            containerRef = containerRef,
            itemId = id,
            count = count
        }
    end
end

---Check if a merchant container is enabled for a given merchant reference
---@param merchantRef tes3reference
---@return boolean whether the merchant container is enabled for the given merchant reference
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

---Process a merchant.
--- This entails adding missing containers for active merchants,
--- removing containers for inactive merchants,
--- and populating the containers with gear
---@param merchantRef tes3reference
function MerchantManager:processMerchant(merchantRef)
    if not merchantRef then return end
    local containerData = self:getContainerData(merchantRef)
    if not containerData then return end
    self.logger:debug("Processing merchant %s", merchantRef.id)
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
        self.logger:debug("Existing container not found")
        containerRef = self:createContainer(merchantRef)
        if not containerRef then
            self.logger:error("Failed to create container for merchant %s", merchantRef.id)
            return
        end
    end
    self:populateContainer(merchantRef, containerRef)
end

---Process all merchants in a given cell
---@param cell tes3cell
function MerchantManager:processMerchantsInCell(cell)
    for ref in cell:iterateReferences() do
        self:processMerchant(ref)
    end
end

---Process all merchants in active cells
function MerchantManager:processMerchantsInActiveCells()
    for _, cell in pairs(tes3.getActiveCells()) do
        self.logger:debug("Cell: %s", cell.id)
        self:processMerchantsInCell(cell)
    end
end

--------------------------------------------------------
--- Private functions
--------------------------------------------------------

---@private
---@param a MerchantManager.contents
---@param b MerchantManager.contents
---@return boolean #whether the contents have changed
function MerchantManager.checkContentsChanged(a, b)
    for id, count in pairs(a) do
        if b[id] ~= count then
            return true
        end
    end
    for id, count in pairs(b) do
        if a[id] ~= count then
            return true
        end
    end
    return false
end

return MerchantManager
