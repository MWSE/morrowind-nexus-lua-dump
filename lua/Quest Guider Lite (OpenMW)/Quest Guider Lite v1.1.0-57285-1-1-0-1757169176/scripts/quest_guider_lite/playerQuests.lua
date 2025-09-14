local include = require("scripts.quest_guider_lite.utils.include")
local tableLib = require("scripts.quest_guider_lite.utils.table")
local localStorage = require("scripts.quest_guider_lite.storage.localStorage")
local commonData = require("scripts.quest_guider_lite.common")
local timeLib = require("scripts.quest_guider_lite.timeLocal")
local cellData = require("scripts.quest_guider_lite.core.cellData")
local stringLib = require("scripts.quest_guider_lite.utils.string")
local dateLib = require("scripts.quest_guider_lite.utils.date")

local playerFunc = require('openmw.types').Player
local core = require('openmw.core')

---@type questGuider.dataHandler.global|questGuider.dataHandler.player
local dataHandler
local questLib = include("scripts.quest_guider_lite.quest")

local playerRef = include('openmw.self')
if not playerRef then
    local world = include('openmw.world')
    if world then
        playerRef = world.players[1]
    end
    ---@type questGuider.dataHandler.global|questGuider.dataHandler.player
    dataHandler = include("scripts.quest_guider_lite.storage.dataHandler") or {}
else
    ---@type questGuider.dataHandler.global|questGuider.dataHandler.player
    dataHandler = include("scripts.quest_guider_lite.storage.playerDataHandler") or {}
end


local this = {}


---@class questGuider.PlayerJournalTopicEntry
---@field id string
---@field actor string
---@field text string


---@class questGuider.PlayerJournalTopic
---@field id string
---@field name string
---@field entries questGuider.PlayerJournalTopicEntry[]


---@class questGuider.playerQuest.storageQuestInfo
---@field diaId string
---@field index integer
---@field timestamp number
---@field cellData tes3cellData?

---@class questGuider.playerQuest.storageQuestData
---@field name string
---@field disabled boolean?
---@field finished boolean?
---@field timestamp number?
---@field list questGuider.playerQuest.storageQuestInfo[]

---@class questGuider.playerQuest.storageData
---@field questData table<string, questGuider.playerQuest.storageQuestData>


---@return questGuider.playerQuest.storageData?
local function getStorageData()
    return localStorage.data[commonData.playerQuestDataLabel]
end

---@return questGuider.playerQuest.storageData?
local function initStorageData()
    local storageData = getStorageData()
    if not storageData or not storageData.questData then
        localStorage.data[commonData.playerQuestDataLabel] = localStorage.data[commonData.playerQuestDataLabel] or {}
        localStorage.data[commonData.playerQuestDataLabel].questData = localStorage.data[commonData.playerQuestDataLabel].questData or {}
        storageData = getStorageData()
    end
    return storageData
end

---@return questGuider.playerQuest.storageQuestData?
local function initStorageQuestData(qName)
    local storageData = initStorageData()
    if not storageData then return end

    local questData = storageData.questData[qName]
    if not questData then
        local arr = {
            name = qName,
            disabled = false,
            finished = false,
            timestamp = 0,
        }
        storageData.questData[qName] = arr
        questData = arr
    end
    if not questData.list then
        questData.list = {}
    end
    return questData
end


---@class questGuider.playerQuest.data
---@field records table<string, any>
---@field isFinished boolean?

---@type table<string, questGuider.playerQuest.data>
this.questData = {}

---@type table<string, boolean>
this.finished = {}

local initialized = false

function this.init()
    if initialized then return end

    local storageData = initStorageData()

    this.finished = {}

    for _, dia in pairs(core.dialogue.journal.records) do
        local qName = dia.questName or ""
        if qName then
            if not this.questData[qName] then this.questData[qName] = {records = {}} end
            this.questData[qName].records[dia.id] = dia
        end
    end

    local qEntries = {}

    if core.API_REVISION >= 93 then

        local journalFuncs = playerFunc.journal(playerRef)

        local year = 427
        local lastMonth

        for _, entry in ipairs(journalFuncs.journalTextEntries) do
            if (lastMonth or entry.month) > entry.month then year = year + 1 end

            local dia = core.dialogue.journal.records[entry.questId or ""]
            if dia then
                local questName = dia.questName or ""

                qEntries[questName] = qEntries[questName] or {}
                table.insert(qEntries[questName], {entry = entry, dia = dia, year = year})

            end

            lastMonth = entry.month
        end

    end

    for qId, q in pairs(playerFunc.quests(playerRef)) do
        if q.finished then
            this.finished[q.id] = true
        end

        local dia = core.dialogue.journal.records[q.id]
        if not dia then goto continue end
        local qName = dia.questName or ""

        local qData = this.questData[qName]
        if not qData then goto continue end

        if core.API_REVISION >= 93 and storageData then

            if not storageData.questData[qName] and qEntries[qName] then
                local storageQuestData = initStorageQuestData(qName)

                if storageQuestData then

                    storageQuestData.timestamp = 0
                    storageQuestData.finished = storageQuestData.finished or q.finished
                    for i, entryData in ipairs(qEntries[qName]) do

                        local entry = entryData.entry
                        local diaRecord = entryData.dia
                        local index = 0

                        for _, info in pairs(diaRecord.infos) do
                            if info.id == entry.id then
                                index = info.questStage
                            end
                        end

                        local timestamp = dateLib.getTimestampByDate(entry.day, entry.month, entryData.year) + i
                        storageQuestData.timestamp = math.max(storageQuestData.timestamp, timestamp)

                        table.insert(storageQuestData.list, {
                            diaId = diaRecord.id,
                            index = index,
                            timestamp = timestamp,
                        })
                    end

                end

            end

        elseif storageData and not storageData.questData[qName] then
            local storageQuestData = initStorageQuestData(qName)
            if storageQuestData then
                storageQuestData.finished = storageQuestData.finished or q.finished
                storageQuestData.timestamp = timeLib.time
                table.insert(storageQuestData.list, {
                    diaId = q.id,
                    index = q.stage,
                    timestamp = timeLib.time,
                })
            end

        end

        if q.finished then
            qData.isFinished = true
            for id, rec in pairs(qData.records) do
                this.finished[id] = true
            end
        end

        ::continue::
    end

    initialized = true
end

function this.reset()
    initialized = false
    this.finished = {}
end

function this.isInitialized()
    return initialized
end


---@param diaId string
function this.getQuestDialogue(diaId)
    local quest = playerFunc.quests(playerRef)[diaId]
    return quest
end


---@param qName string
---@return questGuider.playerQuest.data?
function this.getQuestDataByName(qName)
    return this.questData[qName]
end


---@return questGuider.playerQuest.storageData?
function this.getStorageData()
    return initStorageData()
end


---@param list string[]
---@return table<string, questGuider.playerQuest.storageQuestData>
function this.generateStorageQuestDataByDiaIdList(list)
    ---@type table<string, questGuider.playerQuest.storageQuestData>
    local res = {}

    for _, diaId in pairs(list or {}) do
        local dialogue = core.dialogue.journal.records[diaId]
        if not dialogue then goto continue end

        local qName = dialogue.questName or ""

        local plData = this.getQuestStorageData(qName)

        ---@type questGuider.playerQuest.storageQuestData
        local storDt = res[qName]
        if not storDt then
            ---@type questGuider.playerQuest.storageQuestData
            storDt = {
                list = {},
                tempDias = {},
                name = qName,
                timestamp = plData and plData.timestamp,
                disabled = plData and plData.disabled,
                finished = plData and plData.finished,
            }
            res[qName] = storDt
        end

        local indexes = {}

        for i, info in pairs(dialogue.infos) do
            if info.text ~= qName then
                table.insert(indexes, info.questStage)
            end
        end

        table.sort(indexes)

        local tempDia = {indexData = {}, count = 0}

        for _, index in ipairs(indexes) do
            ---@type questGuider.playerQuest.storageQuestInfo
            local dt = {
                diaId = diaId,
                index = index,
                timestamp = nil,
            }

            table.insert(tempDia.indexData, dt)
            tempDia.count = tempDia.count + 1
        end

        table.insert(storDt.tempDias, tempDia) ---@diagnostic disable-line: undefined-field

        ::continue::
    end

    for qName, qDt in pairs(res) do
        table.sort(qDt.tempDias, function (a, b) ---@diagnostic disable-line: undefined-field
            return a.count > b.count
        end)

        for _, diaDt in ipairs(qDt.tempDias) do ---@diagnostic disable-line: undefined-field
            for _, dt in ipairs(diaDt.indexData) do
                table.insert(qDt.list, dt)
            end
        end
        qDt.tempDias = nil ---@diagnostic disable-line: inject-field
    end

    return res
end


---@param qName string
---@return questGuider.playerQuest.storageQuestData?
function this.getQuestStorageData(qName)
    local storageData = initStorageData()
    if not storageData then return end

    return storageData.questData[qName]
end


---@param diaId string
---@return questGuider.playerQuest.data?
function this.getQuestDataByDiaId(diaId)
    local dia = core.dialogue.journal.records[diaId]
    if not dia then return end

    return this.questData[dia.questName or ""]
end


---@param diaId string
---@param index integer
---@return string?
function this.getJournalText(diaId, index)
    local dia = core.dialogue.journal.records[diaId]
    if not dia then return end

    for _, info in pairs(dia.infos) do
        if info.questStage == index then
            return info.text
        end
    end
end


function this.update(diaId, index)
    local qDia = this.getQuestDialogue(diaId)
    if not qDia then return end

    if qDia.finished then
        this.finished[diaId] = true
    end

    local dia = core.dialogue.journal.records[diaId]
    if not dia then return end

    local questData = initStorageQuestData(dia.questName or "")
    if questData then
        questData.finished = questData.finished or qDia.finished
        questData.timestamp = timeLib.time
        table.insert(questData.list, {
            diaId = diaId,
            index = index,
            timestamp = timeLib.time,
            cellData = cellData.getCellData(playerRef.cell) ---@diagnostic disable-line: need-check-nil
        })
    end

    local data = this.getQuestDataByName(dia.questName or "")
    if not data then return end

    if qDia.finished then
        data.isFinished = true
        for id, _ in pairs(data.records) do
            this.finished[id] = true
        end
    end
end

---@param dialogueId string lowercase
---@return boolean?
function this.isFinished(dialogueId)
    return this.finished[dialogueId]
end

---@param diaId string
---@return integer|nil
function this.getCurrentIndex(diaId)
    local qData = playerFunc.quests(playerRef)[diaId]
    if not qData then return end
    return qData.stage
end


---@param diaId string
---@return string?
function this.getQuestNameByDiaId(diaId)
    local dia = core.dialogue.journal.records[diaId]
    if not dia then return end

    return dia.questName
end


---@return table<string, questGuider.PlayerJournalTopic>
function this.getTopicList()
    if core.API_REVISION < 93 then return {} end

    return playerFunc.journal(playerRef).topics
end

---@return questGuider.PlayerJournalTopic?
function this.getTopicData(topicId)
    if core.API_REVISION < 93 then return end

    return playerFunc.journal(playerRef).topics[topicId]
end


return this