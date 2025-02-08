include("diject.quest_guider.Data.luaAnnotations")

local this = {}

this.version = 4

---@type questDataGenerator.quests
this.quests = {}
---@type questDataGenerator.questByTopicText
this.questByText = {}
---@type table<string, questDataGenerator.objectInfo>
this.questObjects = {}
---@type questDataGenerator.localVariableByQuestId
this.localVariablesByScriptId = {}

local defaultInfo = {version = 0, files = {}, time = 0}
this.info = table.deepcopy(defaultInfo)

local isReady = false
local versionChanged = false

---@return boolean
function this.init()
    isReady = false
    this.quests = json.loadfile("mods\\diject\\quest_guider\\Data\\quests")
    this.questByText = json.loadfile("mods\\diject\\quest_guider\\Data\\questByTopicText")
    this.questObjects = json.loadfile("mods\\diject\\quest_guider\\Data\\questObjects")
    this.localVariablesByScriptId = json.loadfile("mods\\diject\\quest_guider\\Data\\localVariables")
    local infoData = loadfile(tes3.installDirectory.."\\Data Files\\MWSE\\mods\\diject\\quest_guider\\Data\\info.lua")
    this.info = infoData and infoData() or nil

    if this.quests and this.questObjects and this.questByText and this.localVariablesByScriptId and this.info and
            this.version == this.info.version then
        isReady = true
        versionChanged = false
    else
        this.quests = {}
        this.questObjects = {}
        this.questByText = {}
        this.localVariablesByScriptId = {}
        this.info = table.deepcopy(defaultInfo)
        if this.version ~= this.info.version then
            versionChanged = true
        end
    end

    return isReady
end

---@return boolean
function this.isReady()
    return isReady
end

function this.reset()
    this.quests = {}
    this.questObjects = {}
    this.questByText = {}
    this.localVariablesByScriptId = {}
end

---@return boolean ret returns true if the data changed
function this.compareGameFileData()
    if not isReady then return true end

    local activeMods = tes3.dataHandler.nonDynamicData.activeMods
    local files = this.info.files

    local activeFiles = {}

    for _, gameFile in ipairs(activeMods) do
        if gameFile.playerName == "" then
            table.insert(activeFiles, gameFile.filename:lower())
        end
    end

    if #activeFiles ~= #files then return true end

    for i, activeFile in ipairs(activeFiles) do
        if activeFile ~= files[i] then
            return true
        end
    end

    return false
end

function this.isGameFileDataEmpty()
    return #this.info.files == 0
end

function this.isVersionChanged()
    return versionChanged
end

return this