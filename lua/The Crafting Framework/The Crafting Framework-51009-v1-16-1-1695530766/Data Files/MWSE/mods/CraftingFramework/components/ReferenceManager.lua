local util = require("CraftingFramework.util.Util")
local logger = util.createLogger("ReferenceManager")

---A reference manager allows you to keep track of references that meet certain requirements.
---@class CraftingFramework.ReferenceManager : CraftingFramework.ReferenceManager.constructorParams
---@field references table<tes3reference, any> A set of active references that have been added to the manager. The value is a table that can be used to store data about the reference.
local ReferenceManager = {
    ---@type table<string, CraftingFramework.ReferenceManager>
    registeredManagers = {},
}

----------------------------------------
-- Static Methods
----------------------------------------

---@class CraftingFramework.ReferenceManager.constructorParams
---@field requirements fun(self: CraftingFramework.ReferenceManager, ref:tes3reference):boolean A function that returns true if the provided tes3reference is valid for this controller
---@field id? string The id of the registered manager. If provided, the manager can be accessed with ReferenceManager.get(id)
---@field onActivated? fun(self: CraftingFramework.ReferenceManager, ref:tes3reference) A callback that is triggered when a reference is activated
---@field logger? mwseLogger A logger to use for this manager. If not provided, a logger will be created with the id of the manager. If no id is provided, the default ReferenceManager logger will be used

---Construct a new reference manager.
---If an id is provided, the manager will be registered and can be accessed with ReferenceManager.get(id)
---@param params CraftingFramework.ReferenceManager.constructorParams
---@return CraftingFramework.ReferenceManager
function ReferenceManager:new(params)
    logger:assert(type(params.requirements) == "function", "ReferenceManager:new - No requirements function provided")
    if params.onActivated then
        logger:assert(type(params.onActivated) == "function", "ReferenceManager:new - onActivated is not a function")
    end

    local thisLogger = params.logger
    if not thisLogger then
        if params.id then
            thisLogger = util.createLogger("ReferenceManager: " .. params.id)
        else
            thisLogger = logger
        end
    end

    ---@type CraftingFramework.ReferenceManager
    local referenceManager = {
        id = params.id,
        requirements = params.requirements,
        references = {},
        onActivated = params.onActivated,
        logger = thisLogger,
    }
    setmetatable(referenceManager, self)
    self.__index = self

    if referenceManager.id then
        referenceManager.logger:debug("Registering reference manager %s", referenceManager.id)
        ReferenceManager.registeredManagers[referenceManager.id] = referenceManager
    end
    return referenceManager
end

-- Get a registered reference manager by id
---@param id string
---@return CraftingFramework.ReferenceManager
function ReferenceManager.get(id)
    return ReferenceManager.registeredManagers[id]
end

-- Register a reference against any valid managers
---@param reference tes3reference
function ReferenceManager.registerReference(reference)
    for _, referenceManager in pairs(ReferenceManager.registeredManagers) do
        if referenceManager:requirements(reference) then
            referenceManager:addReference(reference)
            if referenceManager.onActivated then
                referenceManager:onActivated(reference)
            end
        end
    end
end

-- Unregister a reference from any managers it is no longer valid for
---@param reference tes3reference
function ReferenceManager.unregisterReference(reference)
    for _, referenceManager in pairs(ReferenceManager.registeredManagers) do
        if referenceManager.references[reference] ~= nil then
            referenceManager:removeReference(reference)
        end
    end
end

----------------------------------------
-- Methods
----------------------------------------

--Add a reference to the reference manager
---@param reference tes3reference
function ReferenceManager:addReference(reference)
    self.logger:trace("Adding reference %s", reference.id)
    self.references[reference] = {}
end

---Removes a reference from the reference manager
---@param reference tes3reference
function ReferenceManager:removeReference(reference)
    self.logger:trace("Removing reference %s", reference.id)
    self.references[reference] = nil
end

---Execute a callback against each reference in the manager
---Before executing the callback, the reference is checked against the
---requirements function to ensure it is still valid.
---@param callback fun(ref:tes3reference, refData:any): boolean|nil Return false to break the iteration
function ReferenceManager:iterateReferences(callback)
    self.logger:trace("Iterating references")
    for ref, refData in pairs(self.references) do
        if self:requirements(ref) then
            if ref.sceneNode then
                if callback(ref, refData) == false then
                    break
                end
            end
        else
            self:removeReference(ref)
        end
    end
end

----------------------------------------
-- Events
----------------------------------------

---@param e referenceActivatedEventData
event.register("referenceActivated", function(e)
    --Only use this event after loaded event to avoid double
    if (tes3.player and tes3.player.tempData.cfHasLoadedRefs) then
        if not e.reference then
            logger:error("Reference is nil")
            return
        end
        ReferenceManager.registerReference(e.reference)
    end
end)

---@param e referenceDeactivatedEventData
event.register("referenceDeactivated", function(e)
    if not e.reference then
        logger:error("Reference is nil")
        return
    end
    ReferenceManager.unregisterReference(e.reference)
end)

event.register("loaded", function()
    --re-trigger referenceActivated for each reference
    for _, cell in pairs(tes3.getActiveCells()) do
        for ref in cell:iterateReferences() do
            ReferenceManager.registerReference(ref)
        end
    end
    tes3.player.tempData.cfHasLoadedRefs = true
end)

return ReferenceManager