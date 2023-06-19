local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("Subject")

local Subject = {}

---@class JOP.Subject
---@field objectId string The id of the tes3object
---@field requirements fun(reference: tes3reference): boolean Returns true if the given reference is a valid subject

---@param e JOP.Subject
function Subject.registerSubject(e)
   logger:assert(type(e.objectId) == "string", "id must be a string")
    config.subjects[e.objectId:lower()] = e
end

function Subject.isSubject(reference)
    local id = reference.object.id:lower()
    local subject = config.subjects[id] ~= nil
    if subject then
        local requirements = config.subjects[id].requirements
        if requirements then
            return requirements(reference)
        else
            return true
        end
    end
    return false
end

return Subject