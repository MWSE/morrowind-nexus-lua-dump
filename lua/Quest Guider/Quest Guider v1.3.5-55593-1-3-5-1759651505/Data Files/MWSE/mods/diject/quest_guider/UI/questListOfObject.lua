local questLib = include("diject.quest_guider.quest")
local menuContainer = include("diject.quest_guider.UI.menuContainer")
local journalUI = include("diject.quest_guider.UI.journal")
local uiUtils = include("diject.quest_guider.UI.utils")
local playerQuests = include("diject.quest_guider.playerQuests")

local config = include("diject.quest_guider.config")


local this = {}

---@class questGuider.questListOfObject.show.params
---@field objectId string should be lowercase
---@field showStarts boolean? default true
---@field showInvolved boolean? default true

---@param params questGuider.questListOfObject.show.params
function this.show(params)
    local objData = questLib.getObjectData(params.objectId)
    if not objData or (not objData.starts and not objData.stages) then return end

    local object = tes3.getObject(params.objectId)

    local menu, buttonBlock = menuContainer.draw(object and object.name or "Info")
    if not menu then return end


    local mainBlock = menu:createBlock{ id = "qGuider_objectQuests_block" }
    mainBlock.flowDirection = tes3.flowDirection.topToBottom
    mainBlock.width = 300
    mainBlock.height = 400

    local scrollElement = mainBlock:createVerticalScrollPane{ id = "qGuider_objectQuests_scrollPane" }
    scrollElement.heightProportional = 1
    scrollElement.widthProportional = 1
    scrollElement.widget.scrollbarVisible = true

    local scrollContent = scrollElement:getContentElement()

    local fontHeight = tes3ui.textLayout.getFontHeight{}
    local height = 0

    ---@type table<string, {id : string, name : string, index : integer, data : any}>
    local quests = {}

    for i, stageData in pairs(objData.stages) do
        local data = quests[stageData.id]
        if data then
            data.index = math.min(data.index, stageData.index)
        else
            local qData = questLib.getQuestData(stageData.id)
            if qData then
                quests[stageData.id] = {id = stageData.id, name = qData.name or "???", index = stageData.index, data = qData}
            end
        end
    end


    local function createLabel(parent, qData, filterStarted)
        local currentIndex = playerQuests.getCurrentIndex(qData.id) or 0
        if filterStarted and config.data.tracking.giver.hideStarted and currentIndex > 0 then
            return
        end

        local questElement = parent:createLabel{
            id = "qGuider_objectQuests_quest",
            text = string.format("%s (%s)", qData.name, tostring(currentIndex))
        }
        questElement.justifyText = tes3.justifyText.left
        questElement.borderAllSides = 2

        uiUtils.makeLabelSelectable(questElement)

        questElement:register(tes3.uiEvent.mouseClick, function (e)
            local el = menuContainer.draw("Requirements")
            if not el then return end

            if not journalUI.drawRequirementMenu(el, qData.id, qData.index, qData.data) then
                el:destroy()
                return
            end
            menuContainer.centerToCursor(el)
        end)

        questElement:register(tes3.uiEvent.help, function (ei)
            local tooltip = tes3ui.createTooltipMenu()
            tooltip.autoWidth = true
            if not config.data.journal.requirements.tooltip then
                if not journalUI.createHelpMessage(tooltip, "Click to open.", tes3.justifyText.left) then
                    tooltip:destroy()
                end
                return
            else
                journalUI.createHelpMessage(tooltip, "Click to open.")
            end
            if not journalUI.drawMapMenu(tooltip, qData.id, qData.index, qData.data, not config.data.journal.map.enabled) then
                tooltip:destroy()
            end
        end)

        return true
    end

    local hasData = false

    if params.showStarts ~= false then
        height = height + (#objData.starts + 2) * fontHeight

        local block = scrollContent:createBlock{}
        block.autoHeight = true
        block.widthProportional = 1
        block.childAlignX = 0.5

        local label = block:createLabel{ id = "qGuider_objectQuests_startsLabel", text = "Starts" }
        label.autoHeight = true
        label.autoWidth = true
        label.borderAllSides = 3

        local startsBlock = scrollContent:createBlock{ id = "qGuider_objectQuests_startsBlock" }
        startsBlock.autoHeight = true
        startsBlock.widthProportional = 1
        startsBlock.flowDirection = tes3.flowDirection.topToBottom

        local foundMatched = false
        for _, id in pairs(objData.starts) do
            local data = quests[id]
            if not data then goto continue end

            foundMatched = createLabel(startsBlock, data, true) or foundMatched

            ::continue::
        end

        if not foundMatched then
            block.visible = false
            startsBlock.visible = false
        end

        hasData = hasData or foundMatched
    end

    if params.showInvolved ~= false then
        height = height + 2 * fontHeight

        local block = scrollContent:createBlock{}
        block.autoHeight = true
        block.widthProportional = 1
        block.childAlignX = 0.5

        local label = block:createLabel{ id = "qGuider_objectQuests_startsLabel", text = "Involved in" }
        label.autoHeight = true
        label.autoWidth = true
        label.borderAllSides = 3

        local involvedBlock = scrollContent:createBlock{ id = "qGuider_objectQuests_involvedBlock" }
        involvedBlock.autoHeight = true
        involvedBlock.widthProportional = 1
        involvedBlock.flowDirection = tes3.flowDirection.topToBottom

        for _, data in pairs(quests) do
            height = height + fontHeight
            hasData = createLabel(involvedBlock, data) or hasData
        end
    end

    if not hasData then
        menu:destroy()
        tes3ui.showNotifyMenu("The object has no data to display.")
        return
    end

    height = height + 10
    mainBlock.height = height > 400 and 400 or height

    menuContainer.updateContainerMenu(mainBlock, scrollElement)
end

return this