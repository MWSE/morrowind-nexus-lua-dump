--[[
    This service finds all the objects of interest (subjects) in a scene, and
    uses the occlusion tester to determine how much screen they take
    up and how occluded they are.
]]
local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("SubjectService")

---@class JOP.SubjectService
local SubjectService = {
    ---@type OcclusionTester
    occlusionTester = nil,
    subjects = {},
}

---@class JOP.SubjectService.params
---@field occlusionTester OcclusionTester
---@field logger? mwseLogger
---@field subjects? table<string, JOP.Subject>

---@class JOP.Subject.Result
---@field presence number The ratio of active pixels to total screen pixels
---@field visibility number The ratio of active pixels to total object pixels
---@field framing number The ratio of non-active pixels to total pixels along the edge of the screen

---@class JOP.Subject
---@field id string
---@field nodes niNode[]

---@param e JOP.SubjectService.params
---@return JOP.SubjectService
function SubjectService.new(e)
    local self = setmetatable({}, { __index = SubjectService })
    self.occlusionTester = e.occlusionTester
    return self
end

--[[
    Create a subject from a reference and insert it into the subjects table.
]]
---@param subjects table<string, JOP.Subject>
---@param reference tes3reference
function SubjectService:insertSubject(subjects, reference)
    local objId = reference.baseObject.id:lower()
    if subjects[objId] == nil then
        logger:debug("Found reference %s", objId)
        subjects[objId] = {
            id = objId,
            nodes = {},
        }
    end
    table.insert(subjects[objId].nodes, reference.sceneNode)
end

--[[
    Returns a table of potential subjects, indexed by their object id.
    A "potential subject" is defined as:
        - An actor in an active cell
        - That has a scene node
        - That is visible to the player
]]
---@return table<string, JOP.Subject>
function SubjectService:getPotentialSubjects()
    local camera = tes3.worldController.worldCamera.cameraData.camera
    local subjects = {}
    for _, cell in pairs(tes3.getActiveCells()) do
        ---@param ref tes3reference
        for _, ref in pairs(cell.actors) do
            if  ref.sceneNode ~= nil
                and not ref.sceneNode:isAppCulled()
                and not ref.sceneNode:isFrustumCulled(camera)
            then
                self:insertSubject(subjects, ref)
            end
        end
    end
    return subjects
end

--[[
    Check whether a subject result meets the minimum visibility threshold to
    be considered a "real" subject.
]]
---@param result JOP.Subject.Result
---@return boolean
function SubjectService:subjectMeetsVisibilityThreshold(result)
    return result.presence > config.subject.MINIMUM_PRESENCE
        and result.visibility > config.subject.MINIMUM_VISIBILITY
end


--[[
    Generate a result for a subject.
]]
---@param subject JOP.Subject
---@return JOP.Subject.Result
function SubjectService:generateResult(subject)
    local result = {}
    self.occlusionTester:setTargets(subject.nodes)
    self.occlusionTester:enable()
    result.count = #subject.nodes
    local diagnostics = self.occlusionTester:getPixelDiagnostics(subject.id)
    result.presence = diagnostics.presence
    result.visibility = diagnostics.visibility
    result.framing = 1 - diagnostics.framing
    self.occlusionTester:disable()
    return result
end

--[[
    Generate results for a list of subjects.
]]
---@param subjects JOP.Subject[]
---@return table<string, JOP.Subject.Result>
function SubjectService:generateResults(subjects)
    local results = {}
    for _, subject in pairs(subjects) do
        logger:debug("Subject: %s, nodes: %d", subject.id, #subject.nodes)
        local result = self:generateResult(subject)
        logger:debug("Presence: %f, Visibility: %f, Framing: %f",
            result.presence, result.visibility, result.framing)
        if self:subjectMeetsVisibilityThreshold(result) then
            logger:debug("Subject %s is visible enough", subject.id)
            results[subject.id] = result
        end
    end
    return results
end

--[[
    Get results for all the subjects in the scene.
]]
---@return table<string, JOP.Subject.Result>
function SubjectService:getSubjects()
    local subjects = self:getPotentialSubjects()
    return self:generateResults(subjects)
end

return SubjectService