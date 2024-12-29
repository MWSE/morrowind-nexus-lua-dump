local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("ReferenceManager")
---@class JOP.ReferenceManager
local ReferenceManager = {
    new = function(self, o)
        o = o or {}   -- create object if user does not provide one
        o.references = {}
        setmetatable(o, self)
        self.__index = self
        return o
    end,

    addReference = function(self, ref)
        self.references[ref] = true
    end,

    removeReference = function(self, ref)
            self.references[ref] = nil
    end,

    isReference = function(self, ref)
        return self:requirements(ref)
    end,

    iterate = function(self, callback)
        for ref, _ in pairs(self.references) do
            --check requirements in case it's no longer valid
            if self:requirements(ref) then
                if ref.sceneNode then
                    callback(ref)
                end
            else
                --no longer valid, remove from ref list
                self.references[ref] = nil
            end
        end
    end,

    references = nil,
    requirements = nil
}

ReferenceManager.controllers = {
    waterFilter = ReferenceManager:new{
        requirements = function(_, ref)
            local isWaterFilter = ref.sceneNode
                and ref.sceneNode:getObjectByName("FILTER_WATER")
            return isWaterFilter
        end
    }
}

function ReferenceManager.invalidate(e)
    local ref = e.object
    for _, controller in pairs(ReferenceManager.controllers) do
        if controller.references[ref] == true then
            controller:removeReference(ref)
        end
    end
end

---@class JOP.ReferenceController.registerReferenceController.params
---@field id string The id of the controller
---@field requirements fun(self: JOP.ReferenceManager, ref:tes3reference):boolean A function that returns true if the reference is valid for this controller
---@field onActive? fun(self: JOP.ReferenceManager, ref:tes3reference) A callback that is triggered when a reference is activated

---@param e JOP.ReferenceController.registerReferenceController.params
function ReferenceManager.registerReferenceController(e)
    assert(e.id, "No id provided")
    assert(e.requirements, "No reference requirements provieded")
    ReferenceManager.controllers[e.id] =  ReferenceManager:new{
        requirements =  e.requirements,
        onActive = e.onActive
    }
    return ReferenceManager.controllers[e.id]
end

function ReferenceManager.registerReference(reference)
    local controllersAddedTo = {}
    for _, controller in pairs(ReferenceManager.controllers) do
        if controller:requirements(reference) then
            controller:addReference(reference)
            table.insert(controllersAddedTo, controller)
        end
    end
    return controllersAddedTo
end

function ReferenceManager.iterateReferences(refType, callback)
    if not ReferenceManager.controllers[refType] then
        logger:warn("No reference controller for %s", refType)
        return
    end
    for ref, _ in pairs(ReferenceManager.controllers[refType].references) do
        --check requirements in case it's no longer valid
        if ReferenceManager.controllers[refType]:requirements(ref) then
            if ref.sceneNode then
                callback(ref)
            end
        else
            --no longer valid, remove from ref list
            ReferenceManager.controllers[refType].references[ref] = nil
        end
    end
end

function ReferenceManager.isReference(refType, reference)
    return ReferenceManager.controllers[refType]:isReference(reference)
end

return ReferenceManager