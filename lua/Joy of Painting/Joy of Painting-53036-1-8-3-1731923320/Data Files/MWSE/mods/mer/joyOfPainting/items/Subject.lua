local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("Subject")

local Subject = {}

---@class JOP.Subject.registerSubjectParams
---@field id string A unique idenfitider for the subject
---@field name nil|string|fun(e: JOP.Subject.requirements.Params):string (Default: reference name) The name of the subject, displayed in UIs. can be a function to display name dynamically
---@field objectIds nil|string[] Instead of providing a requirements function, you can provide a list of objectIds to check for
---@field requirements nil|fun(e: JOP.Subject.requirements.Params): boolean Returns true if the given reference is a valid subject

---@class JOP.Subject
---@field id string
---@field getName fun(e: JOP.Subject.getName.params):string
---@field objectIds nil|table<string, true>
---@field requirements nil|fun(e: JOP.Subject.requirements.Params): boolean

---@class JOP.Subject.requirements.Params
---@field reference tes3reference

---@class JOP.Subject.getName.params
---@field objectId string

---Resolve the name function
---@param name nil|string|fun(e: JOP.Subject.requirements.Params):string
---@return fun(e: JOP.Subject.getName.params):string
local function resolveName(name)
    if name == nil then
        return function(e)
            local obj = tes3.getObject(e.objectId)
            return obj and obj.name or e.objectId
        end
    end
    if type(name) == "string" then
        return function(e)
            return name
        end
    end
    return name
end

---Resolve the objectIds into a table
---@param objectIds nil|string[]
---@return nil|table<string, true>
local function resolveObjectIds(objectIds)
    if objectIds == nil then return nil end
    local resolved = {}
    if objectIds then
        resolved = {}
        for _, id in ipairs(objectIds) do
            resolved[id:lower()] = true
        end
    end
    return resolved
end

---Validate the subject parameters and log errors
---@param e JOP.Subject.registerSubjectParams
---@return boolean
local function validateParams(e)
    if not e.id then
        logger:error("Subject must have an id")
        return false
    end
    if  (not e.objectIds) and (not e.requirements) then
        logger:error("Subject must have either objectIds or requirements function")
        return false
    end
    return true
end

---Register a subject
---@param e JOP.Subject.registerSubjectParams
function Subject.registerSubject(e)
    if not validateParams(e) then return end

    logger:debug("Registering subject %s", e.id)

    local id = e.id:lower()

    local existing = config.subjects[id]
    if existing then
        logger:warn("Merging existing subject %s", id)
        if existing.objectIds then
            if e.objectIds then
                for _, id in ipairs(e.objectIds) do
                    existing.objectIds[id:lower()] = true
                end
            end
        else
            if e.objectIds then
                existing.objectIds = resolveObjectIds(e.objectIds)
            end
        end
        if e.requirements then
            if existing.requirements then
                logger:warn("Merging requirements callbacks for subject %s", id)
                ---@type fun(e: JOP.Subject.requirements.Params): boolean
                local oldRequirements = existing.requirements
                existing.requirements = function(e2)
                    return oldRequirements(e2) or e.requirements(e2)
                end
            else
                existing.requirements = e.requirements
            end
        end
    else
        ---@type JOP.Subject
        local subject = {
            id = id,
            getName = resolveName(e.name),
            objectIds = resolveObjectIds(e.objectIds),
            requirements = e.requirements
        }
        config.subjects[id] = subject
    end
end


function Subject.getSubject(id)
    return config.subjects[id:lower()]
end


---@param results table<string, JOP.SubjectService.Result>
---@return table<string, boolean>
function Subject.getSubjectNames(results)
    local subjectNames = {}
    for objectId, result in pairs(results) do
        for subjectId in pairs(result.subjectIds) do
            local subject = Subject.getSubject(subjectId)
            if subject then
                subjectNames[subject.getName{ objectId = objectId }] = true
                break
            end
        end
    end
    return subjectNames
end


---Get a list of subjects this reference is valid for
---@param reference tes3reference
---@return JOP.Subject[]
function Subject.getSubjectsFromRef(reference)
    local id = reference.baseObject.id:lower()
    local subjects = {}
    for _, subject in pairs(config.subjects) do
        local idMatch = subject.objectIds == nil
            or subject.objectIds[id]
        if idMatch then
            if subject.requirements then
                local requirementsMet = subject.requirements{reference = reference}
                if requirementsMet then
                    table.insert(subjects, subject)
                end
            else
                table.insert(subjects, subject)
            end
        end
    end
    return subjects
end

---Check if the reference is a subject
---@param reference tes3reference
---@return boolean
function Subject.isSubject(reference)
    local id = reference.baseObject.id:lower()
    for _, subject in pairs(config.subjects) do
        local idMatch = subject.objectIds == nil
            or subject.objectIds[id]
        if idMatch then
            if subject.requirements then
                local requirementsMet = subject.requirements{reference = reference}
                if requirementsMet then
                    return true
                end
            else
                return true
            end
        end
    end
    return false
end

return Subject