local util = require("CraftingFramework.util.Util")
local logger = util.createLogger("TagManager")
--[[
    A class for managing tags. Tags are used to group ids together for easy access and filtering.
]]
---@class CraftingFramework.TagManager
local TagManager = {
    ---@type table<string, CraftingFramework.Tag>
    registeredTags = {}
}

---@class (exact) CraftingFramework.Tag
---@field ids table<string, boolean> A table of ids that are tagged with this tag

---@class (exact) CraftingFramework.Tag.params
---@field tag string The tag to register
---@field id string The ID to match against the tag


---Register a new tag
---@param tag string The tag to register
function TagManager.registerTag(tag)
    if TagManager.registeredTags[tag] then
        logger:debug("TagManager:RegisterTag - Tag %s already exists", tag)
        return
    end
    logger:debug("TagManager:RegisterTag - Registering tag %s", tag)
    TagManager.registeredTags[tag] = {
        ids = {},
    }
end

---Add an ID to a tag
---@param e CraftingFramework.Tag.params
function TagManager.addId(e)
    logger:assert(e.tag ~= nil, "TagManager:addId - tag is nil")
    logger:assert(e.id ~= nil, "TagManager:addId - id is nil")
    if not TagManager.registeredTags[e.tag] then
        TagManager.registerTag(e.tag)
    end
    local id = e.id:lower()
    if TagManager.registeredTags[e.tag].ids[id] then
        logger:debug("TagManager:addId - ID %s already exists in tag %s", id, e.tag)
        return
    end
    logger:debug("TagManager:addId - Adding ID %s to tag %s", id , e.tag)
    TagManager.registeredTags[e.tag].ids[id] = true
end

---Add a list of ids to a tag
---@param e { tag: string, ids: string[] }
function TagManager.addIds(e)
    logger:assert(e.tag ~= nil, "TagManager:addIds - tag is nil")
    logger:assert(e.ids ~= nil, "TagManager:addIds - ids is nil")
    for _, id in ipairs(e.ids) do
        TagManager.addId({tag = e.tag, id = id})
    end
end

---Remove an ID from a tag
---@param e CraftingFramework.Tag.params
---@return boolean false if the tag does not exist
function TagManager.removeId(e)
    logger:assert(e.tag ~= nil, "TagManager:removeId - tag is nil")
    logger:assert(e.id ~= nil, "TagManager:removeId - id is nil")
    if not TagManager.registeredTags[e.tag] then
        return false
    end
    TagManager.registeredTags[e.tag].ids[e.id:lower()] = nil
    return true
end

---Check if an ID is tagged with a tag
---@param e CraftingFramework.Tag.params
---@return boolean false if the ID is not tagged with the tag, or the tag does not exist
function TagManager.hasId(e)
    logger:assert(e.tag ~= nil, "TagManager:hasId - tag is nil")
    logger:assert(e.id ~= nil, "TagManager:hasId - id is nil")
    if not TagManager.registeredTags[e.tag] then
        return false
    end
    local hasId = TagManager.registeredTags[e.tag].ids[e.id:lower()]
    if hasId then
        logger:debug("TagManager:hasId - ID %s is tagged with %s", e.id, e.tag)
    end
    return hasId
end

---Returns a dictionary of ids that are tagged with a tag
---@param tag string The tag to check
---@return table<string, boolean> A dictionary of ids that are tagged with the tag
function TagManager.getIds(tag)
    if not TagManager.registeredTags[tag] then
        return {}
    end
    return table.copy(TagManager.registeredTags[tag].ids)
end

---Returns a list of tags that an ID is tagged with
---@param id string The ID to check
---@return string[] A table of tags that the ID is tagged with
function TagManager.getTags(id)
    id = id:lower()
    local tags = {}
    for tag, data in pairs(TagManager.registeredTags) do
        if data.ids[id] then
            table.insert(tags, tag)
        end
    end
    return tags
end

return TagManager