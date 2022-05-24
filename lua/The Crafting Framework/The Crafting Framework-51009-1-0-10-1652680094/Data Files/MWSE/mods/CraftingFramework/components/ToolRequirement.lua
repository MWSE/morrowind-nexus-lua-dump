local Util = require("CraftingFramework.util.Util")
local log = Util.createLogger("ToolRequirement")
local Tool = require("CraftingFramework.components.Tool")

---@class craftingFrameworkToolRequirement
local ToolRequirement = {
    schema = {
        name = "ToolRequirement",
        fields = {
            tool = { type = "string", required = true },
            equipped = { type = "boolean", required = false },
            count = { type = "number", required = false, default = 1 },
            conditionPerUse = { type = "number", required = false },
        }
    }
}


--Constructor
---@param data craftingFrameworkToolRequirementData
---@return craftingFrameworkToolRequirement toolRequirement
function ToolRequirement:new(data)
    Util.validate(data, ToolRequirement.schema)
    data.tool = Tool.getTool(data.tool)
    setmetatable(data, self)
    self.__index = self
    return data
end

function ToolRequirement:getLabel()
    return nil
end


---@return boolean
function ToolRequirement:hasTool()
    log:debug("hasTool()")
    if self.tool then
        for id, _ in pairs(self.tool:getToolIds()) do
            log:debug("hasTool: id: %s", id)
            if self:checkToolRequirements(id) then
                log:debug("hasTool(): Has tool %s", id)
                return true
            end
        end
        log:debug("hasTool: No tool found")
        return false
    end
    log:debug("tool not registered, ignore it and return hasTool=true")
    return true
end

---@return boolean
function ToolRequirement:hasToolEquipped()
    log:debug("hasToolEquipped()")
    if self.tool then
        for id, _ in pairs(self.tool:getToolIds()) do
            local obj = tes3.getObject(id)
            if obj then
                return self:checkToolEquipped(obj)
            end
        end
    end
    return false
end


---@return boolean
function ToolRequirement:hasToolCondition()
    log:debug("hasToolCondition()")
    if self.tool then
        for id, _ in pairs(self.tool:getToolIds()) do
            log:debug("id: %s", id)
            local obj = tes3.getObject(id)
            if obj then
                log:debug("Found tool, returning checkCondition")
                return self:checkToolCondition(obj)
            end
        end
        log:debug("No valid tool found")
        return true
    end
    log:debug("no Tool found")
    return true
end


function ToolRequirement:checkInventoryToolCount(obj)
    log:debug("checkInventoryToolCount()")
    local countNeeded = self.count or 1
    local count = tes3.getItemCount{ reference = tes3.player, item = obj }
    if count < countNeeded then
        return false
    end
    return true
end

function ToolRequirement:checkToolEquipped(obj)
    log:debug("checkToolEquipped()")
    if self.equipped then
        local hasEquipped = tes3.getEquippedItem{
            actor = tes3.player,
            objectType = obj.objectType,
            slot = obj.slot,
            type = obj.type
        }
        if not hasEquipped then
            log:debug("Tool %s needs to be equipped and isn't", obj.id)
            return false
        end
        log:debug("Tool %s is equipped", obj.id)
        return true
    end
    log:debug("Tool doesn't need equipping")
    return true
end



function ToolRequirement:checkToolRequirements(id)
    log:debug("checkToolRequirements() for id %s", id)
    local obj = tes3.getObject(id)
    local isValid = obj
        and self:checkInventoryToolCount(obj)
        and self:checkToolEquipped(obj)
        and self:checkToolCondition(obj)
    if isValid then
        log:debug("Has specific tool")
        return true
    end
    return false
end

function ToolRequirement:checkToolCondition(obj)
    log:debug("checkToolCondition() for item %s", obj.id)
    if obj.maxCondition then
        local stack = tes3.player.object.inventory:findItemStack(obj)
        if not( stack and stack.variables ) then return true end
        for _, data in pairs(stack.variables) do
            if data.condition and data.condition > 0 then
                return true
            end
        end
        log:debug("Scanned inventory and found no %s with enough condition", obj.id)
        return false
    end
end



return ToolRequirement