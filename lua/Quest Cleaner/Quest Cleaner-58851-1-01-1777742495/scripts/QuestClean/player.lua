local self = require("openmw.self")
local I = require("openmw.interfaces")
local core = require("openmw.core")
local types = require("openmw.types")
local input = require("openmw.input")

local QuestsWindow = require("scripts.QuestClean.ui.questsWindow")

local questWindowVisible = false
local mouseWheelHandler = function() end
local cleanedQuests = {
    -- id = {
    --     name = string,
    --     previousFinished = boolean,
    -- },
}

local function questMenuVisibilityUpdated(prevStatus)
    questWindowVisible = not prevStatus
    if questWindowVisible then
        mouseWheelHandler = QuestsWindow.getMouseWheelHandler()
        ---@diagnostic disable-next-line: missing-fields
        I.UI.setMode('Interface', { windows = {} })
        core.sendGlobalEvent('Pause', 'ui')
    else
        mouseWheelHandler = function() end
        I.UI.setMode()
        core.sendGlobalEvent('Unpause', 'ui')
    end
end

local function closeQuestMenu(updateUiMode)
    QuestsWindow.close()
    questWindowVisible = false
    mouseWheelHandler = function() end

    if updateUiMode then
        I.UI.setMode()
        core.sendGlobalEvent('Unpause', 'ui')
    end
end

local function initQuestMenu()
    QuestsWindow.new(cleanedQuests)

    questMenuVisibilityUpdated(questWindowVisible)
end

local function questCleaned(data)
    if not data or not data.quests then return end

    local quests = types.Player.quests(self)

    for _, quest in pairs(data.quests) do
        local playerQuest = quests[quest.id]
        if playerQuest and not cleanedQuests[quest.id] then
            cleanedQuests[quest.id] = {
                name = quest.name,
                previousFinished = playerQuest.finished,
            }
            playerQuest.finished = true
        end
    end

end

local function questReenabled(data)
    if not data or not data.questIds then return end

    local quests = types.Player.quests(self)

    for _, id in pairs(data.questIds) do
        local cleanedQuest = cleanedQuests[id]
        local playerQuest = quests[id]
        if cleanedQuest and playerQuest then
            playerQuest.finished = cleanedQuest.previousFinished
            cleanedQuests[id] = nil
        end
    end
end

local function closeMenu()
    if questWindowVisible then
        closeQuestMenu(true)
    end
end

local function onUpdate()
    if I.UI.getMode() == nil and questWindowVisible then
        closeQuestMenu(false)
    end
end

local function onLoad(data)
    if not data then return end
    cleanedQuests = data.cleanedQuests or cleanedQuests
end

local function onSave()
    return {
        cleanedQuests = cleanedQuests,
    }
end

return {
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
        onMouseWheel = function(...)
            ---@diagnostic disable-next-line: redundant-parameter
            mouseWheelHandler(...)
        end,
        onUpdate = onUpdate,
        onKeyPress = function (key)
            if key.symbol == "c" and I.UI.getMode() == "Journal" then
                initQuestMenu()
            end
        end,
        onControllerButtonPress = function(id)
            if id == input.CONTROLLER_BUTTON.Y and I.UI.getMode() == "Journal" then
                
                initQuestMenu()
                return
            end
            if not questWindowVisible then return end

            if id == input.CONTROLLER_BUTTON.DPadDown then
                QuestsWindow.navigate(1)
            elseif id == input.CONTROLLER_BUTTON.DPadUp then
                QuestsWindow.navigate(-1)
            elseif id == input.CONTROLLER_BUTTON.DPadRight then
                QuestsWindow.navigateButton(1)
            elseif id == input.CONTROLLER_BUTTON.DPadLeft then
                QuestsWindow.navigateButton(-1)
            elseif id == input.CONTROLLER_BUTTON.A then
                QuestsWindow.pressButton()
   
            end
        end,
    },
    eventHandlers = {
        QuestClean_questCleaned = questCleaned,
        QuestClean_questReenabled = questReenabled,
        QuestClean_closeMenu = closeMenu,
    },
    interfaceName = "QuestClean",
    interface = {
        getCleanedQuests = function() return cleanedQuests end,
        initQuestMenu = initQuestMenu,
    }
}
