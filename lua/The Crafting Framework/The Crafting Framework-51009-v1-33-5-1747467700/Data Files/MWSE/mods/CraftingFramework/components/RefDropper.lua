local Util = require("CraftingFramework.util.Util")
local RefStack = require("CraftingFramework.util.RefStack")
local logger = Util.createLogger("RefDropper")

---@class CraftingFramework.RefDropper.data
---@field droppedObjectId string The id of the object that was dropped
---@field replacerId? string The id of the object to swap the dropped item with
---@field scale number? The scale of the dropped item
---@field returnExcess? boolean `Default: true` If true, will return excess items to the player
---@field onDrop? fun(self: CraftingFramework.RefDropper, reference: tes3reference) A callback to run when the item is placed. Receives the dropped reference, or the new reference if replacerId is set.


--[[
    This class allows you to have an item dropped into the world be replaced with another item.
]]
---@class CraftingFramework.RefDropper : CraftingFramework.RefDropper.data
local RefDropper = {
    ---@type CraftingFramework.RefDropper[]
    registeredRefDroppers = {}
}

---@param data CraftingFramework.RefDropper.data
function RefDropper.register(data)
    local refSwapper = RefDropper:new(data)
    if RefDropper.registeredRefDroppers[refSwapper.droppedObjectId] then
        --merge, copy missing
        table.copymissing(RefDropper.registeredRefDroppers[refSwapper.droppedObjectId], refSwapper)
    else
        RefDropper.registeredRefDroppers[refSwapper.droppedObjectId] = refSwapper
    end
end

---@param data table
---@return CraftingFramework.RefDropper
function RefDropper:new(data)
    data = table.copy(data)
    logger:assert(type(data.droppedObjectId) == "string", "data.droppedObjectId is required")
    setmetatable(data, self)
    self.__index = self
    data.droppedObjectId = data.droppedObjectId:lower()
    data.replacerId = data.replacerId and data.replacerId:lower()
    data.scale = data.scale or 1
    if data.returnExcess == nil then
        data.returnExcess = true
    end
    return data
end

--[[
    Called when an object is dropped into the world.
    @param reference tes3reference
]]
function RefDropper:drop(reference)
    if self.replacerId then
        logger:debug("Swapping %s with %s", reference, self.replacerId)
        local newRef = tes3.createReference{
            object = self.replacerId,
            position = reference.position:copy(),
            orientation = reference.orientation:copy(),
            cell = reference.cell,
            scale = self.scale,
        }
        local refStack = RefStack:new{
            reference = reference,
        }
        if refStack then
            logger:debug("Returning excess items")
            refStack:returnExcess()
        end
        reference:delete()
        reference = newRef
    else
        logger:debug("Setting %s scale to %s", reference, self.scale)
        reference.scale = self.scale
    end
    if self.onDrop then
        logger:debug("Running onDrop callback")
        self:onDrop(reference)
    end
end


return RefDropper