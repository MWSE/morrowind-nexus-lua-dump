
---@class questDataGenerator.requirementData
---@field type string requirement type id
---@field operator integer equal = 48, notEqual = 49, greater = 50, greaterOrEqual = 51, less = 52, lessOrEqual = 53,
---@field value number|string|nil : object->variable (operator) value
---@field variable string|nil : object->variable (operator) value
---@field object string|nil : object->variable (operator) value
---@field skill integer|nil skill id
---@field attribute integer|nil attribute id
---@field script string|nil script id if this requrement from a script

---@alias questDataGenerator.requirementBlock questDataGenerator.requirementData[] list of requirements to complete a quest stage

---@class questDataGenerator.stageData
---@field id string dialogue id
---@field requirements questDataGenerator.requirementBlock[]
---@field next integer[] possible next indexes
---@field nextIndex integer|nil following index
---@field finished boolean|nil finished flag
---@field restart boolean|nil restart flag


---@alias questDataGenerator.questData { name: string, links: string[]?, hasFinished: boolean?, [string]: questDataGenerator.stageData }

---@alias questDataGenerator.quests table<string, questDataGenerator.questData>


---@class questDataGenerator.questTopicInfo
---@field id string quest id
---@field index integer quest index

---@alias questDataGenerator.questByTopicText table<string, questDataGenerator.questTopicInfo[]>

---@class questDataGenerator.objectPosition
---@field pos number[] {x, y, z}
---@field name string|nil cell id
---@field grid integer[]|nil {gridX, gridY}

---@class questDataGenerator.objectInfo
---@field type integer accuracy not guaranteed for <=3. 1 - object, 2 - owner, 3 - dialog, 4 - script, 5 - local variable, 6 - dialogue topic
---@field inWorld integer the number of this object in the game world
---@field total integer the number of this object in the game world, including containers where it can be located
---@field norm number the number of this object in the game world + conatiners multiplyed by the chance to get it
---@field starts string[]|nil list of quest ids that this object can start
---@field stages questDataGenerator.questTopicInfo[] quest stages in which this object appears
---@field positions questDataGenerator.objectPosition[]
---@field links {[1] : string, [2] : number}[]|nil objects that contain this object, with the chance to get it
---@field contains {[1] : string, [2] : number}[]|nil objects that this object contains, with the chance to get it

---@class questDataGenerator.localVariableData
---@field type integer
---@field results table<string, questDataGenerator.requirementBlock[]>

---@alias questDataGenerator.localVariableByQuestId table<string, table<string, questDataGenerator.localVariableData>>


---@class questDataGenerator.dialogueTopicInfo
---@field id string dialogue topic id
---@field reqs questDataGenerator.requirementBlock|nil requirements to get this topic. Contains only function/variable requirements

---@alias questDataGenerator.dialogueTopicData table<string, questDataGenerator.dialogueTopicInfo[]>

---@class questDataGenerator.dataInfo
---@field version integer data format version
---@field time integer UNIX timestamp
---@field format string format of the data files
---@field files string[] list of all files that were used to generate this data

---@class questDataGenerator.mapImageInfo
---@field version integer
---@field time integer
---@field file string
---@field width integer
---@field height integer
---@field pixelsPerCell integer
---@field gridX {min : integer, max : integer}
---@field gridY {min : integer, max : integer}
