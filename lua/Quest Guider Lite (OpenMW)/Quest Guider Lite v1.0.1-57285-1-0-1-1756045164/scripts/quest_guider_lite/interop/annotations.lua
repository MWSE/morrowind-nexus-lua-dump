---@diagnostic disable: undefined-doc-name

-- Note: When the data is ready to use, the global event "QGL:Interop:DataReady" will be triggered

---@class QuestGuiderLite
---@field version integer
---@field getQuestsData fun() : questDataGenerator.quests
---@field getObjectsData fun() : table<string, questDataGenerator.objectInfo>
---@field getLocalVarialesData fun() : questDataGenerator.localVariableByQuestId
---@field questLib questGuiderLite.questLib
---@field requirementChecker questGuiderLite.requirementChecker
---@field types table contents from scripts/quest_guider_lite/types.lua


---@class questGuiderLite.questLib
---@field getQuestData fun(questDialogueId : string) : questDataGenerator.questData?
---@field getObjectPositionData fun(recordId : string) : questDataGenerator.objectPosition[]?
---@field getObjectData fun(recordId : string) : questDataGenerator.objectInfo?
---@field getLocalVariableDataByScriptName fun(scriptName : string) : table<string, questDataGenerator.localVariableData>?
---@field getIndexes fun(questData : string|questDataGenerator.questData) : integer[]|nil
---@field getFirstIndex fun(questData : string|questDataGenerator.questData) : integer?
---@field getNextIndexes fun(questData : string|questDataGenerator.questData, qDialogueId : string?, index : integer|string, params : {findInLinked: boolean?, findCompleted: boolean?}?) : integer[]?, table<string, {index: integer, qData: questDataGenerator.questData}>? returns a list of next indexes for the specified quest, and a table with quest data and index for each linked quest
---@field getDescriptionDataFromDataBlock fun(reqBlock : questDataGenerator.requirementBlock, qDialogueId : string?) : questGuiderLite.getDescriptionDataFromBlock.returnArr[]?
---@field getRequirementPositionData fun(requirement : questDataGenerator.requirementData) : table<string, questGuiderLite.getRequirementPositionData.returnData>? return is indexed by record id

---@class questGuiderLite.getDescriptionDataFromBlock.returnArr
---@field str string description
---@field priority number
---@field objects table<string, string>|nil index is id, value is name
---@field positionData table<string, questGuiderLite.getRequirementPositionData.returnData>?
---@field data questDataGenerator.requirementData
---@field reqDataForHandling questDataGenerator.requirementBlock? for requirementType.CustomActor type

---@class questGuiderLite.getRequirementPositionData.positionData
---@field description string?
---@field descriptionBackward string?
---@field id string? cell id of the position
---@field position tes3vector3? coordinates of the position
---@field distanceToPlayer number?
---@field exitPos tes3vector3? coordinates in the game world of the entrance to the exterior cell that leads to the position
---@field entrances tes3vector3[]?
---@field doorPath tes3travelDestinationNode[]? list of doors to exit from the position
---@field cellPath tes3cellData[]? list of cells to exit from the position
---@field rawData questDataGenerator.objectPosition|{id : string}|nil *id* is injected owner id, if it exists
---@field isExitEx boolean? true, if the exit is in an exterior cell

---@class questGuiderLite.getRequirementPositionData.returnData
---@field reqType string requirement type
---@field name string name of the object
---@field inWorld integer? number of instances of the object in the game world
---@field parentObject string?
---@field itemCount integer? item count from *types.requirementType.Item*
---@field actorCount integer? kill count from *types.requirementType.Dead*
---@field positions questGuiderLite.getRequirementPositionData.positionData[]


---@class questGuiderLite.requirementChecker
---@field check fun(req : questDataGenerator.requirementData, objectReference : GameObject?) : boolean? returns nil if cannot handle the requirement
---@field checkBlock fun(block : questDataGenerator.requirementData[], params : questGuiderLite.checkForBlock.params?)
---@field getFilteredRequirementBlock fun(reqBlock : questDataGenerator.requirementBlock, filter : table<string, any>?) : questDataGenerator.requirementBlock? returns a block containing only those requirements that were in the filter indexes

---@class questGuiderLite.checkForBlock.params
---@field reference GameObject?
---@field ignoredTypes table<string, any>?
---@field allowedTypes table<string, any>?
---@field threatErrorsAs boolean?

---@class questGuiderLite.event.dataReady.data
---@field quests questDataGenerator.quests
---@field questObjects table<string, questDataGenerator.objectInfo>
---@field localVariablesByScriptId questDataGenerator.localVariableByQuestId
---@field info {time : integer, version : integer, files : string[]}?
---@field isReady boolean