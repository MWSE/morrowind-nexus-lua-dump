include("diject.quest_guider.Data.luaAnnotations")
local config = include("diject.quest_guider.config")
local questLib = include("diject.quest_guider.quest")

local this = {}

this.version = 1 -- can be nil

this.event = {
    dataInitialized = "questGuider:dataInitialized",
}

---@class questGuider.event.dataInitialized.params
---@field success boolean

---@class eventlib
---@field register fun(eventId: '"questGuider:dataInitialized"', callback: (fun(e: questGuider.event.dataInitialized.params): boolean?), options: nil)


function this.isEnabled()
    return config.data.main.enabled
end


---@param objectId string
---@return questDataGenerator.objectInfo?
function this.getObjectData(objectId)
    return questLib.getObjectData(objectId)
end


---@param questId string
---@return questDataGenerator.questData?
function this.getQuestData(questId)
    return questLib.getQuestData(questId)
end


---@param reqBlock questDataGenerator.requirementBlock list of requirements to complete a quest stage
---@return questGuider.quest.getDescriptionDataFromBlock.return?
function this.getInfoFromDataBlock(reqBlock)
    return questLib.getDescriptionDataFromDataBlock(reqBlock, nil, config.default)
end


---@param requirement questDataGenerator.requirementData
---@return table<string, questGuider.quest.getRequirementPositionData.returnData>? ret by object id
function this.getRequirementPositionData(requirement)
    return questLib.getRequirementPositionData(requirement, config.default)
end


return this