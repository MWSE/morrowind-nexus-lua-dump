---@meta
---@class craftingFrameworkToolData
---Data used to construct a new Tool
---@field id string **Required.**  This will be the unique identifier used internally by Crafting Framework to identify this `tool`.
---@field name string The name of the tool. Used in various UIs.
---@field ids table<number, string> **Required.**  This is the list of item ids that are considered identical tool.
---@field requirement fun(stack : tes3itemStack): boolean Optionally, you can provide a function that will be used to evaluate if a certain item in the player's inventory can be used as a tool. It will be called with a `tes3itemStack` parameter, that it needs to evaluate if it should be recognized as a tool. When that is the case the function needs to return `true`, `false` otherwise. Used when no `ids` are provided.

---@class craftingFrameworkTool
---A tool is an item that is required for crafting an item, but not consumed during crafting like a material. It may need to be equipped, and can be confugured to lose durability each time it is used for crafting.
---@field id string The tool's id. This is the id used as the tool's unique identifer within Crafting Framework. It shouldn't be confused with item ids defined in the Construction Set.
---@field name string The tool's name.
---@field ids table<string, true> A standard lookup table with the in-game ids of the items that are registered as this tool.
---@field requirement fun(stack : tes3itemStack): boolean Optionally, you can provide a function that will be used to evaluate if a certain item in the player's inventory can be used as a tool. When that is the case the function needs to return `true`, `false` otherwise. Used when no `ids` are provided.
---@field registeredTools table<string, craftingFrameworkTool>
craftingFrameworkTool = {}

---@param id string The tool's unique identifier.
---@return craftingFrameworkTool tool The tool requested.
function craftingFrameworkTool.getTool(id) end

---This method creates a new tool.
---@param data craftingFrameworkToolData This table accepts following values:
---
--- `id`: string — **Required.**  This will be the unique identifier used internally by Crafting Framework to identify this `tool`.
---
--- `name`: string — The name of the tool. Used in various UIs.
---
--- `ids`: table<number, string> — **Required.**  This is the list of item ids that are considered identical tool.
---
--- `requirement`: fun(stack : tes3itemStack): boolean —  Optionally, you can provide a function that will be used to evaluate if a certain item in the player's inventory can be used as a tool. It will be called with a `tes3itemStack` parameter, that it needs to evaluate if it should be recognized as a tool. When that is the case the function needs to return `true`, `false` otherwise. Used when no `ids` are provided.
---@return craftingFrameworkTool Tool The newly constructed tool.
function craftingFrameworkTool:new(data) end

---This method returns the name of the tool.
---@return string name
function craftingFrameworkTool:getName() end

---Find a valid tool of this type and apply condition damage if appropriate.
---@param amount number How much condition damage is done.
function  craftingFrameworkTool:use(amount) end

---The method returns a list of valid tool ids.
---@return table<string, true>
function craftingFrameworkTool:getToolIds() end

---This method should return `true` when given `itemStack` can be used as a tool. Usually this method will be invoked for each item in the player's inventory when `tool:getToolIds()` is called.
---@param stack tes3itemStack
---@return boolean
function craftingFrameworkTool:requirement(stack) end
