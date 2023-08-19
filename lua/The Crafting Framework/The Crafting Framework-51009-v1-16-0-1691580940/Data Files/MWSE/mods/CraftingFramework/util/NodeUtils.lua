--[[
    A class for helper functions related to \
    node manipulation
]]
---@class CraftingFramework.NodeUtils
local NodeUtils = {}

-- Get the first parent of a node of the given name
---@param node niNode
---@param parentName string
---@return niNode|nil
function NodeUtils.getNamedParent(node, parentName)
    local parentNode = node.parent
    while parentNode do
        if parentNode.name == parentName then
            return parentNode
        end
        parentNode = parentNode.parent
    end
    return nil
end


return NodeUtils