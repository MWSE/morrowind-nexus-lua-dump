local this = {}

local ReferenceController = {
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
 
    references = nil,
    requirements = nil
}

this.controllers = {
    companion = ReferenceController:new{
        requirements = function(_, ref)
            return ref.data and ref.data.tgw
        end
    },
}

local function onRefPlaced(e)
    for id, controller in pairs(this.controllers) do
        if controller:requirements(e.reference) then
            controller:addReference(e.reference)
        end
    end
end
event.register("referenceSceneNodeCreated", onRefPlaced)
event.register("GuarWhisperer:registerReference", onRefPlaced)


local function onObjectInvalidated(e)
    
    local ref = e.object
    for controllerName, controller in pairs(this.controllers) do
        if controller.references[ref] == true then
            controller:removeReference(ref)
        end
    end
end
event.register("objectInvalidated", onObjectInvalidated)

local function registerReferenceController(e)
    assert(e.id, "No id provided")
    assert(e.requirements, "No reference requirements provieded")
    this.controllers[e.id] =  ReferenceController:new{ requirements = e.requirements } 
end
event.register("GuarWhisperer:RegisterReferenceController", registerReferenceController)

return this