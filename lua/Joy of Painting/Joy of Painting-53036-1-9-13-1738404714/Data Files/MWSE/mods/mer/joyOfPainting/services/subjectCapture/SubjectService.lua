--[[
    This service finds all the objects of interest (subjects) in a scene, and
    uses the occlusion tester to determine how much screen they take
    up and how occluded they are.
]]
local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local Subject = require("mer.joyOfPainting.items.Subject")
local logger = common.createLogger("SubjectService")

---@class JOP.SubjectService
local SubjectService = {
    ---@type OcclusionTester
    occlusionTester = nil,
    subjects = {},
    --A list of non-NPC subjects that will be detected within a scene
}

---@class JOP.SubjectService.params
---@field occlusionTester OcclusionTester
---@field logger? mwseLogger
---@field subjects? table<string, JOP.SubjectService.Subject>

---@class JOP.SubjectService.Result
---@field objectId string The object id
---@field subjectIds table<string, boolean> The subject ids matching this result
---@field presence number The ratio of active pixels to total screen pixels
---@field visibility number The ratio of active pixels to total object pixels
---@field framing number The ratio of non-active pixels to total pixels along the edge of the screen
---@field count number The number references in the scene that generated this result

---@class JOP.SubjectService.Subject
---@field objectId string
---@field subjectIds table<string, boolean>
---@field nodes niNode[]

---@param e JOP.SubjectService.params
---@return JOP.SubjectService
function SubjectService.new(e)
    local self = setmetatable({}, { __index = SubjectService })
    self.occlusionTester = e.occlusionTester
    return self
end

--Create a subject from a reference and insert it into the subjects table.
---@param subjects table<string, JOP.SubjectService.Subject>
---@param reference tes3reference
local function _insertSubject(subjects, reference)
    local objId = reference.baseObject.id:lower()
    if subjects[objId] == nil then
        logger:debug("Inserting reference '%s' as subject", objId)

        local validSubjects = Subject.getSubjectsFromRef(reference)

        ---@type table<string, boolean>
        local subjectIds
        if #validSubjects > 0 then
            subjectIds = {}
            for _, subject in ipairs(validSubjects) do
                subjectIds[subject.id] = true
            end
        end

        subjects[objId] = {
            objectId = objId,
            subjectIds = subjectIds,
            nodes = {},
        }
    end
    table.insert(subjects[objId].nodes, reference.sceneNode)
end


---Check if the reference is visible to the camera
---@param reference tes3reference
local function _isRefVisible(reference)
    return reference.sceneNode ~= nil
    and not reference.sceneNode:isAppCulled()
    and not reference.sceneNode:isFrustumCulled(tes3.worldController.worldCamera.cameraData.camera)
end

--[[
    Returns a table of potential subjects, indexed by their object id.
    A "potential subject" is defined as:
        - An actor in an active cell
        - That has a scene node
        - That is visible to the player
]]
---@return table<string, JOP.SubjectService.Subject>
function SubjectService:getPotentialSubjects()
    local subjects = {}
    for _, cell in pairs(tes3.getActiveCells()) do
        ---@param ref tes3reference
        for ref in cell:iterateReferences() do
            if Subject.isSubject(ref) and _isRefVisible(ref) then
                _insertSubject(subjects, ref)
            end
        end
    end
    return subjects
end

--[[
    Check whether a subject result meets the minimum visibility threshold to
    be considered a "real" subject.
]]
---@param result JOP.SubjectService.Result
---@return boolean
function SubjectService:subjectMeetsVisibilityThreshold(result)
    return result.presence > config.subject.MINIMUM_PRESENCE
        and result.visibility > config.subject.MINIMUM_VISIBILITY
end


--[[
    Generate a result for a subject.
]]
---@param subject JOP.SubjectService.Subject
---@return JOP.SubjectService.Result
function SubjectService:generateResult(subject)
    ---@type JOP.SubjectService.Result
    local result = {
        objectId = subject.objectId,
        subjectIds = subject.subjectIds,
        presence = 0,
        visibility = 0,
        framing = 0,
        count = 0
    }
    self.occlusionTester:setTargets(subject.nodes)
    self.occlusionTester:enable()
    result.count = #subject.nodes
    local diagnostics = self.occlusionTester:getPixelDiagnostics(subject.objectId)
    result.presence = diagnostics.presence
    result.visibility = diagnostics.visibility
    result.framing = 1 - diagnostics.framing
    self.occlusionTester:disable()
    return result
end

--[[
    Generate results for a list of subjects.
]]
---@param subjects JOP.SubjectService.Subject[]
---@return table<string, JOP.SubjectService.Result>
function SubjectService:generateResults(subjects)
    local results = {}
    for _, subject in pairs(subjects) do
        logger:debug("Subject: %s, nodes: %d", subject.objectId, #subject.nodes)
        local result = self:generateResult(subject)
        logger:debug("Presence: %f, Visibility: %f, Framing: %f",
            result.presence, result.visibility, result.framing)
        if self:subjectMeetsVisibilityThreshold(result) then
            logger:debug("Subject %s is visible enough", subject.objectId)
            results[subject.objectId] = result
        end
    end
    return results
end

--[[
    Get results for all the subjects in the scene.
]]
---@return table<string, JOP.SubjectService.Result>
function SubjectService:getSubjects()
    local subjects = self:getPotentialSubjects()
    return self:generateResults(subjects)
end

return SubjectService