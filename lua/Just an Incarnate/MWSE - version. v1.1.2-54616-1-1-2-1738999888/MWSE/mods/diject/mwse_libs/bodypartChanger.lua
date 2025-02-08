local localStorage = {}

local storageName = "bodypartChanger_by_diject"

localStorage.data = nil

function localStorage.isReady()
    return localStorage.data ~= nil
end

---@param reference tes3reference
function localStorage.getStorage(reference)
    local data = reference.data[storageName]
    if not data then
        reference.data[storageName] = {}
        data = reference.data[storageName]
    end
    reference.modified = true
    return data
end

---@param reference tes3reference
function localStorage.isExists(reference)
    return reference.data[storageName]
end


local this = {}

this.isEnabledForPlayer = false

local raceBodyPart = {
    ["head"] = "head",
    ["hair"] = "hair",
    ["neck"] = "neck",
    ["chest"] = "chest",
    ["groin"] = "groin",
    ["skirt"] = "skirt",
    ["rightHand"] = "hands",
    ["leftHand"] = "hands",
    ["rightWrist"] = "wrist",
    ["leftWrist"] = "wrist",
    ["rightForearm"] = "forearm",
    ["leftForearm"] = "forearm",
    ["rightUpperArm"] = "upperArm",
    ["leftUpperArm"] = "upperArm",
    ["rightFoot"] = "foot",
    ["leftFoot"] = "foot",
    ["rightAnkle"] = "ankle",
    ["leftAnkle"] = "ankle",
    ["rightKnee"] = "knee",
    ["leftKnee"] = "knee",
    ["rightUpperLeg"] = "upperLeg",
    ["leftUpperLeg"] = "upperLeg",
    ["rightPauldron"] = "clavicle",
    ["leftPauldron"] = "clavicle",
    ["tail"] = "tail",
}

---@param reference tes3reference
---@param index integer
---@return tes3bodyPart|nil
function this.getRaceBaseBodyPart(reference, index)
    local bodyData
    local maleBodyData
    maleBodyData = reference.baseObject.race.maleBody
    if reference.baseObject.female then
        bodyData = reference.baseObject.race.femaleBody
    else
        bodyData = maleBodyData
    end
    for name, id in pairs(tes3.activeBodyPart) do
        local bodyPartData = raceBodyPart[name]
        if id == index and bodyPartData then
            return bodyData[bodyPartData] or maleBodyData[bodyPartData]
        end
    end
end

---@param reference tes3reference
---@param source tes3reference|jai.storage.race
---@param alternativeParts table<string, string>|nil
function this.saveBodyParts(reference, source, alternativeParts)
    if not source or not reference then return end
    if not alternativeParts then alternativeParts = {} end
    local storageData = localStorage.getStorage(reference)
    storageData["body"] = {}
    local body = storageData["body"]
    local bodyData
    if reference.baseObject.female then
        bodyData = source.object and source.object.race.femaleBody or source.female
    else
        bodyData = source.object and source.object.race.maleBody or source.male
    end
    for name, id in pairs(tes3.activeBodyPart) do
        local bodyPartData = alternativeParts[name] or (raceBodyPart[name] and bodyData[raceBodyPart[name]])
        if bodyPartData then
            body[tostring(id)] = type(bodyPartData) == "string" and bodyPartData or bodyPartData.id ---@diagnostic disable-line: undefined-field
        end
    end
    storageData["female"] = reference.baseObject.female
end

---@param reference tes3reference
---@param partId tes3.activeBodyPart
---@return tes3bodyPart|nil
function this.getSavedBodyPart(reference, partId)
    if not localStorage.isExists(reference) then return end
    local storageData = localStorage.getStorage(reference)
    if storageData.body then
        local part = storageData.body[tostring(partId)]
        return part and tes3.getObject(part) or nil
    end
end

---@param reference tes3reference
---@param bodypartId string
---@param partId tes3.bodyPartAttachment
function this.saveBodyPart(reference, bodypartId, partId)
    local storageData = localStorage.getStorage(reference)
    if not storageData.body then storageData.body = {} end
    storageData.body[tostring(partId)] = bodypartId
end


--- @param e bodyPartAssignedEventData
local function bodyPartAssignedCallback(e)
    if not e.reference or not e.bodyPart or e.bodyPart.partType ~= tes3.activeBodyPartLayer.base then return end
    if (e.reference == tes3.player or e.reference == tes3.player1stPerson) and this.isEnabledForPlayer and
            (e.index ~= tes3.activeBodyPart.hair and e.index ~= tes3.activeBodyPart.head) then

        local newPart = this.getRaceBaseBodyPart(e.reference, e.index)
        if newPart then
            e.bodyPart = this.getRaceBaseBodyPart(e.reference, e.index)
        end
    else
        local savedBodyPart = this.getSavedBodyPart(e.reference, e.index)
        if savedBodyPart then
            e.bodyPart = savedBodyPart
        end
    end
end
event.register(tes3.event.bodyPartAssigned, bodyPartAssignedCallback)


return this