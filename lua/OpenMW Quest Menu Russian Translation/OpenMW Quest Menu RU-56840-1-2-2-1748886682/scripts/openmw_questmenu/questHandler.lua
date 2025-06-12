local self = require("openmw.self")
local core = require("openmw.core")
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local types = require("openmw.types")
local ui = require('openmw.ui')
local util = require('openmw.util')
local vfs = require('openmw.vfs')
local async = require('openmw.async')

local QuestCleaner = require('scripts.openmw_questmenu.questCleaner')

local modVersion = "1.1.0"

local questList = {
    quests = {},
    version = modVersion
}
local followedQuest = nil

local playerCustomizationSettings = storage.playerSection('Settings/OpenMWQuestMenu/2_Customization')

local function cleanQuestList()
    questList.quests = QuestCleaner.cleanList(questList.quests)
    return questList.quests
end

local function getQuestText(questId, stage)
    local dialogueRecord = core.dialogue.journal.records[questId]

    local filteredDialogue = nil
    for _, dialogue in pairs(dialogueRecord.infos) do
        if dialogue.questStage == stage then
            filteredDialogue = dialogue
        end
    end

    if filteredDialogue == nil then
        return "Error: No information found."
    end

    return filteredDialogue.text
end

local function getFollowedQuest(quests)
    for _, quest in pairs(quests) do
        if quest.followed == true then
            return quest
        end
    end

    return nil
end

local function showFollowedQuest(quest)
    if quest == nil then
        return
    end

    if (followedQuest ~= nil) then
        followedQuest:destroy()
        followedQuest = nil
    end

    local function createIcon()
        if I.SSQN then
            local icon = I.SSQN.getQIcon(quest.id)

            if not vfs.fileExists(icon) then icon = "Icons\\SSQN\\DEFAULT.dds" end

            return {
                type = ui.TYPE.Image,
                props = {
                    size = util.vector2(playerCustomizationSettings:get('FIconSize'),
                        playerCustomizationSettings:get('FIconSize')),
                    resource = ui.texture { path = icon },
                }
            }
        end

        return {}
    end

    local stage = #quest.stages > 0 and quest.stages[1] or "No Information Found"
    local text = getQuestText(quest.id, stage)

    followedQuest = ui.create({
        type = ui.TYPE.Container,
        layer = 'Windows',
        template = I.MWUI.templates.boxTransparent,
        props = {
            position = util.vector2(
                playerCustomizationSettings:get('FPosX'),
                playerCustomizationSettings:get('FPosY')
            ),
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content {
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true
                        },
                        content = ui.content {
                            createIcon(),
                            {
                                type = ui.TYPE.Widget,
                                props = {
                                    size = util.vector2(10, 6)
                                }
                            },
                            {
                                type = ui.TYPE.Flex,
                                content = ui.content {
                                    {
                                        type = ui.TYPE.Flex,
                                        props = {
                                            horizontal = true
                                        },
                                        content = ui.content {
                                            {
                                                type = ui.TYPE.Text,
                                                props = {
                                                    text = quest.name,
                                                    textColor = util.color.rgb(1, 1, 1),
                                                    textSize = playerCustomizationSettings:get('FHeadlineSize'),
                                                    textAlignH = ui.ALIGNMENT.Start
                                                },
                                            }
                                        }
                                    },
                                    {
                                        template = I.MWUI.templates.textParagraph,
                                        props = {
                                            size = util.vector2(playerCustomizationSettings:get('FWidth'), 10),
                                            text = text,
                                            textSize = playerCustomizationSettings:get('FTextSize'),
                                        },
                                    }
                                }
                            }
                        }
                    }
                }
            }
        },
        events = {
            mousePress = async:callback(function(coord, layout)
                layout.userData.doDrag = true
                layout.userData.lastMousePos = coord.position
            end),
            mouseRelease = async:callback(function(_, layout)
                layout.userData.doDrag = false
            end),
            mouseMove = async:callback(function(coord, layout)
                if followedQuest == nil or not layout.userData.doDrag then return end
                local props = layout.props
                props.position = props.position - (layout.userData.lastMousePos - coord.position)
                followedQuest:update()
                layout.userData.lastMousePos = coord.position
            end),
        },
        userData = {
            doDrag = false,
            lastMousePos = nil,
        }
    })
end

local function followQuest(qid)
    local newFollowedQuest = nil
    local newQuestList = {}

    for _, quest in ipairs(questList.quests) do
        if quest.id == qid then
            newFollowedQuest = quest
            newFollowedQuest.followed = not quest.followed
            table.insert(newQuestList, newFollowedQuest)
        else
            quest.followed = false
            table.insert(newQuestList, quest)
        end
    end

    if (newFollowedQuest ~= nil and newFollowedQuest.followed) then
        showFollowedQuest(newFollowedQuest)
    end

    if (followedQuest and (newFollowedQuest == nil or not newFollowedQuest.followed)) then
        followedQuest:destroy()
        followedQuest = nil
    end

    questList.quests = newQuestList
    return newQuestList
end

local function toggleQuest(qid)
    local newQuestList = {};
    for _, quest in ipairs(questList.quests) do
        if quest.id == qid then
            quest.hidden = not quest.hidden
        end

        table.insert(newQuestList, quest)
    end
    questList.quests = newQuestList
end

local function onLoadMidGame()
    local newQuestList = {}
    local addedQuests = 0

    for _, quest in pairs(types.Player.quests(self)) do
        local questExists = false
        for __, eQuest in pairs(questList.quests) do
            if eQuest.id == quest.id then
                questExists = true
                print('Quest ' .. quest.id .. ' already exists. Skip!')
                table.insert(newQuestList, eQuest)
            end
        end

        if not questExists then
            local dialogueRecord = core.dialogue.journal.records[quest.id]

            if dialogueRecord.questName and dialogueRecord.questName ~= "" and not QuestCleaner.isBlacklisted(quest.id) then
                addedQuests = addedQuests + 1
                local newQuest = {
                    id = quest.id,
                    name = dialogueRecord.questName,
                    hidden = false,
                    finished = quest.finished,
                    followed = false,
                    stages = {}
                }
                table.insert(newQuest.stages, 1, quest.stage)
                table.insert(newQuestList, newQuest)
            end
        end
    end

    questList.quests = newQuestList
    ui.showMessage("Reloading: added " .. tostring(addedQuests) .. " quests.")
    return newQuestList
end

local function onUpdateToNewVersion(oldList)
    local newQuestList = {
        quests = {},
        version = modVersion
    };

    if (not oldList.version) then
        for _, quest in ipairs(oldList) do
            quest.notes = nil
            quest.stages = {}

            if (quest.name and quest.name ~= "" and not QuestCleaner.isBlacklisted(quest.id)) then
                table.insert(quest.stages, quest.stage)
                table.insert(newQuestList.quests, quest)
            end
        end
    end

    questList = newQuestList
end

local function onQuestUpdate(questId, stage)
    local isFinished = false;
    for _, quest in pairs(types.Player.quests(self)) do
        if (quest.id == questId) then
            isFinished = quest.finished
        end
    end

    local qid = questId:lower()
    local dialogueRecord = core.dialogue.journal.records[qid]

    local questExists = false;
    local newQuestList = {};
    for _, quest in ipairs(questList.quests) do
        -- If Quest already exists just update it:
        if quest.id == qid then
            questExists = true
            quest.finished = isFinished
            table.insert(quest.stages, 1, stage)
        end

        -- Unfollow quest when it is finished
        if quest.followed and isFinished then
            followQuest(qid)
        end

        table.insert(newQuestList, quest)
    end

    -- If Quest doesnt exist yet, add new list entry:
    if (questExists == false and dialogueRecord.questName and dialogueRecord.questName ~= "" and not QuestCleaner.isBlacklisted(qid)) then
        local newQuest = {
            id = qid,
            name = dialogueRecord.questName,
            hidden = false,
            finished = isFinished,
            followed = false,
            stages = {}
        }

        table.insert(newQuest.stages, stage)
        table.insert(newQuestList, 1, newQuest)
    end

    questList.quests = newQuestList
    showFollowedQuest(getFollowedQuest(newQuestList))
end

local function onSave()
    return {
        questList = questList,
    }
end

local function onLoad(data)
    if not data or not data.questList then
        onLoadMidGame()
        return
    end

    -- Legacy Support
    if not data.questList.version or data.questList.version ~= modVersion then
        onUpdateToNewVersion(data.questList)
        return
    end

    questList = data.questList
    showFollowedQuest(getFollowedQuest(data.questList.quests))
end

local function getQuestList()
    return questList.quests
end

return {
    interfaceName = 'OpenMWQuestList',
    interface = {
        cleanQuestList = cleanQuestList,
        getQuestList = getQuestList,
        getQuestText = getQuestText,
        followQuest = followQuest,
        fetchQuests = onLoadMidGame,
        toggleQuest = toggleQuest
    },
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
        onQuestUpdate = onQuestUpdate
    }
}
