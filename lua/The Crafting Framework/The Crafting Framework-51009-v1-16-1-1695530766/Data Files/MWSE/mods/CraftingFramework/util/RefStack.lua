--[[
    Class for managing references that represent multiple items
]]
---@class CraftingFramework.RefStack
---@field reference tes3reference
---@field logger mwseLogger
local RefStack = {}

function RefStack.isStack(reference)
    return (
        reference.attachments and
        reference.attachments.variables and
        reference.attachments.variables.count > 1
    )
end

--Create a new RefStack from a reference. Returns nil if reference isn't a stack
---@return CraftingFramework.RefStack?
function RefStack:new(e)
    assert(e.reference, "Reference is required")
    if not RefStack.isStack(e.reference) then return end
    local o = {}
    setmetatable(o, self)
    if e.logger then
        o.logger = e.logger
    else
        local name = "RefStack"
        local MWSELogger = require("logging.logger")
        o.logger = MWSELogger.new {
            name = name,
            logLevel = "INFO"
        }
    end
    self.__index = self
    o.reference = e.reference
    return o
end

--Returns the number of items in the stack
function RefStack:getCount()
    return self.reference
        and self.reference.attachments
        and self.reference.attachments.variables
        and self.reference.attachments.variables.count or 1
end

--Reduce the stack by the given amount
function RefStack:reduce(amount)
    local stackCount = self:getCount()
    if stackCount <= amount then
        self.logger:debug("Reduced to 0, deleting reference")
        self.reference:delete()
        return 0
    else
        self.reference.attachments.variables.count = self:getCount() - amount
        self.logger:debug("Reduced by %s, new count is %s", amount, self:getCount())
        return self:getCount()
    end
end

--Returns all but one of the items to the player inventory
function RefStack:returnExcess()
    local stackCount = self:getCount()
    if stackCount <= 1 then
        self.logger:debug("Stack count is %s, no excess to return", stackCount)
        return
    end
    local excessCount = stackCount - 1
    self.logger:debug("Returning %s items to player inventory", excessCount)
    tes3.addItem{
        reference = tes3.player,
        item = self.reference.object,---@diagnostic disable-line
        count = excessCount,
        playSound = false,
    }
    self:reduce(excessCount)
end

return RefStack