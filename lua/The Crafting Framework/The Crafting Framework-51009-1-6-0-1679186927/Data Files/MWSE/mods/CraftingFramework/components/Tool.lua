local Util = require("CraftingFramework.util.Util")
local log = Util.createLogger("Tool")

---@class CraftingFramework.Tool.data
---@field id string **Required.**  This will be the unique identifier used internally by Crafting Framework to identify this `tool`.
---@field name string The name of the tool. Used in various UIs.
---@field ids table<number, string> **Required.**  This is the list of item ids that are considered identical tool.
---@field requirement fun(stack : tes3itemStack): boolean Optionally, you can provide a function that will be used to evaluate if a certain item in the player's inventory can be used as a tool. It will be called with a `tes3itemStack` parameter, that it needs to evaluate if it should be recognized as a tool. When that is the case the function needs to return `true`, `false` otherwise. Used when no `ids` are provided.


---@class CraftingFramework.Tool : CraftingFramework.Tool.data
---@field ids table<string, boolean>
Tool = {
    schema = {
        name = "Tool",
        fields = {
            id = { type = "string", required = true },
            name = { type = "string", required = false },
            ids = { type = "table", childType = "string", required = false },
            requirement = { type = "function", required = false},
        }
    }
}


Tool.registeredTools = {}
---@param id string
---@return CraftingFramework.Tool tool
function Tool.getTool(id)
    return Tool.registeredTools[id]
end

---@param data CraftingFramework.Tool.data
---@return CraftingFramework.Tool Tool
function Tool:new(data)
    Util.validate(data, Tool.schema)
    if not Tool.registeredTools[data.id] then
        Tool.registeredTools[data.id] = {
            id = data.id,
            name = data.name,
            ids = {},
            requirement = data.requirement
        }
    end
    local tool = Tool.registeredTools[data.id]
    --add tool ids
    if data.ids then
        log:debug("Adding tool ids: %s", table.concat(data.ids, ", "))
        for _, id in ipairs(data.ids) do
            tool.ids[id:lower()] = true
        end
    end
    setmetatable(tool, self)
    self.__index = self
    return tool
end

---@return string name
function Tool:getName()
    return self.name
end

---@param amount number
function Tool:use(amount)
    amount = amount or 1
    log:debug("Using tool, degrading by %s", amount)
    for id, _ in pairs(self:getToolIds()) do
        local obj = tes3.getObject(id)
        if obj then
            local itemStack = tes3.player.object.inventory:findItemStack(obj)
            if itemStack then

                if not itemStack.object.maxCondition then
                    log:debug("Found invincible tool, skipping: %s", self:getName())
                    return
                end
                log:debug("Found in inventory: %s", itemStack.object.id)
                if not itemStack.variables then
                    tes3.addItemData{
                        to = tes3.player,
                        item = itemStack.object,
                        updateGUI = true
                    }
                end
                for _, itemData in ipairs(itemStack.variables) do
                    if itemData.condition > 0 then
                        log:debug("Degrading condition of tool: %s", self:getName())
                        itemData.condition = math.max(0, itemData.condition - amount)
                        return
                    end
                end
                log:debug("Couldn't find an itemData with condition to degrade")
                return
            end
        end
    end
    log:debug("Couldn't find any item to degrade")
end

---Gets a list of tool IDs. Only guaranteed to include items that are in teh player's inventory.
---@return table<string, true>
function Tool:getToolIds()
    log:debug("getToolIds for tool %s", self:getName())
    local ids = {}
    if self.ids and table.size(self.ids) > 0 then
        table.copy(self.ids, ids)
    end
    if self.requirement then
        local requirementIds = {}
        for _, stack in pairs(tes3.player.object.inventory) do
            if self.requirement(stack) then
                ids[stack.object.id:lower()] = true
            end
        end
        table.copy(requirementIds, ids)
    end
    log:debug("getToolIds(): Returning ids: %s", table.concat(table.keys(ids), ", "))
    return ids
end

---Check if the given item is a tool. If the tool has a `requirement` callback,
---this will only return true if the item is in the player's inventory.
---@param item tes3item
function Tool:itemIsTool(item)
    if not item then
        return false
    end
    local id = item.id:lower()
    local ids = self:getToolIds()
    return ids[id] == true
end

return Tool