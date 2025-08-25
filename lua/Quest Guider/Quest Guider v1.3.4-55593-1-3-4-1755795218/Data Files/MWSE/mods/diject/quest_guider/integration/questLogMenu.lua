local log = include("diject.quest_guider.utils.log")
local config = include("diject.quest_guider.config")
local journalUI = include("diject.quest_guider.UI.journal")
local trackingLib = include("diject.quest_guider.tracking")
local questLib = include("diject.quest_guider.quest")
local menuContainer = include("diject.quest_guider.UI.menuContainer")
local filedBlockLib = include("diject.quest_guider.UI.fieldBlockSys")

local priority = -278
local buttonId = "qGuider_QLMBtn"

local this = {}

this.isMenuActive = false

local lastKey = nil


local makeLabelSelectable = include("diject.quest_guider.UI.utils").makeLabelSelectable

---@param quest tes3quest
local function uiContainer(quest, parent)
    if #quest.dialogue <= 1 then
        local diaId = quest.dialogue and quest.dialogue[1] and quest.dialogue[1].id
        if not diaId then return end
        diaId = diaId:lower()

        local diaData = questLib.getQuestData(diaId)
        if not diaData then return end

        return journalUI.drawRequirementMenu(parent, diaId, nil, diaData)
    else
        local block = parent:createBlock{}
        block.autoWidth = false
        block.width = 400
        block.autoHeight = true
        block.flowDirection = tes3.flowDirection.topToBottom
        local tabFieldBlock = filedBlockLib.new{parent = block, delimiter = ",", delimiterBorderRight = 6, borderRight = 6}

        local mainBlock = parent:createBlock{}
        mainBlock.autoWidth = true
        mainBlock.autoHeight = true

        ---@type tes3uiElement[]
        local tabs = {}
        for _, dialogue in pairs(quest.dialogue) do
            if not dialogue.journalIndex or dialogue.journalIndex == 0 then goto continue end

            local diaId = dialogue.id:lower()
            local diaData = questLib.getQuestData(diaId)
            if not diaData then goto continue end

            local tab = tabFieldBlock:add{ id = "qGuider_qlm_dialogueTab", text = "\""..dialogue.id.."\"" }

            if not tab then goto continue end

            table.insert(tabs, tab)

            makeLabelSelectable(tab)
            tab:setLuaData("data", {id = diaId, qData = diaData, index = dialogue.journalIndex})

            tab:register(tes3.uiEvent.mouseClick, function (e)
                mainBlock:destroyChildren()
                local elem = e.source
                if not elem then return end

                for _, tb in pairs(tabs) do
                    tb.color = tes3ui.getPalette(tes3.palette.journalFinishedQuestOverColor)
                end
                elem.color = {0.5, 1, 0.5}

                local data = elem:getLuaData("data")
                if not data then return end

                journalUI.drawRequirementMenu(mainBlock, data.id, nil, data.qData)
            end)

            ::continue::
        end

        if #tabs > 0 then
            for _, tab in pairs(tabs) do
                local luaData = tab:getLuaData("data")
                if luaData and questLib.getNextIndexes(luaData.qData, luaData.id, luaData.index) then
                    tab:triggerEvent(tes3.uiEvent.mouseClick)
                    return true
                end
            end
            tabs[1]:triggerEvent(tes3.uiEvent.mouseClick)
            return true
        else
            return false
        end
    end
end

-- ################################################################################################

local function onQLMKeyCallback(e)
    if tes3ui.menuMode() or not tes3.player then return end

    this.isMenuActive = true

    timer.start{duration = 0.25, type = timer.real, callback = function()

        local menu = tes3ui.findMenu("QLM:menu")
        if not menu then return end

        if menu:findChild(buttonId) then return end

        local closeBtn = menu:findChild("QLM:close_button")
        if not closeBtn then return end

        local buttonPanel = closeBtn.parent
        if not buttonPanel then return end

        ---@type tes3uiElement
        local leftButtonBlock
        for _, child in ipairs(buttonPanel.children) do
            if child.name ~= "QLM:close_button" then
                leftButtonBlock = child
                break
            end
        end
        if not leftButtonBlock then return end

        local qGuiderBtn = leftButtonBlock:createButton{ id = buttonId, text = "Quest Guider" }

        qGuiderBtn:getTopLevelMenu():updateLayout()

        log("Integrated into \"Quest Log Menu\"")

        local function getQuestParams()
            local elemIndex = this.Quest_List:get_active_quest_index()
            if not elemIndex then return end
            local questDt = this.Quest_List.quests[elemIndex] and this.Quest_List.quests[elemIndex].quest

            return questDt
        end

        if config.data.integration.questLogMenu.tooltip then
            qGuiderBtn:register(tes3.uiEvent.help, function (ei)
                local quest = getQuestParams()
                if not quest then return end

                local tooltip = tes3ui.createTooltipMenu()
                tooltip.autoWidth = true
                if not config.data.journal.requirements.tooltip then
                    if not journalUI.createHelpMessage(tooltip, "Click to open. / Shift+Click to track quest objects. / Ctrl+Click to show list of all quests.", tes3.justifyText.left) then
                        tooltip:destroy()
                    end
                    return
                else
                    journalUI.createHelpMessage(tooltip, "Click to open. / Shift+Click to track quest objects. / Ctrl+Click to show list of all quests.")
                end
                if not uiContainer(quest, tooltip) then
                    tooltip:destroy()
                end
            end)
        end

        qGuiderBtn:register(tes3.uiEvent.mouseClick, function()
            local quest = getQuestParams()
            if not quest then return end

            if tes3.worldController.inputController:isShiftDown() then
                for _, dia in pairs(quest.dialogue) do
                    if dia.journalIndex and dia.journalIndex > 0 then
                        trackingLib.trackQuestsbyQuestId(dia.id:lower())
                    end
                end

                return

            elseif tes3.worldController.inputController:isControlDown() then
                local el, buttonBlock = menuContainer.draw("Quests", function (menuEl, buttonBlock)
                    journalUI.createContainerButtons(nil, menuEl, buttonBlock, { trackCurrentBtn = false })
                end)
                if not el then return end

                journalUI.drawQuestsMenu(el)

                el:getTopLevelMenu():updateLayout()
                return
            end

            local function createContainerButtons(menuEl, buttonBlock)
                journalUI.createContainerButtons(nil, menuEl, buttonBlock, {})
            end

            local el, buttonBlock = menuContainer.draw("Requirements", createContainerButtons)

            if not el or not buttonBlock then return end

            if not uiContainer(quest, el) then
                el:destroy()
                return
            end
            menuContainer.centerToCursor(el)
        end)
    end}

    event.unregister(tes3.event.keyDown, onQLMKeyCallback, { filter = lastKey, priority = priority })
end

local function getQLMKey()
    ---@type herbert.QLM.config?
    local QLM_config = mwse.loadConfig("Quest Log Menu")
    if not QLM_config or not QLM_config.key then return end
    return QLM_config.key.keyCode
end

local function onMCMClosed(e)
    local key = getQLMKey()
    if not key then return end
    this.initKeyCallback(key)
end

local function onMenuDestroyed(e)
    this.isMenuActive = false
    this.initKeyCallback(lastKey)

    if tes3.player and config.data.integration.questLogMenu.hideHidden then
        local disabledQuests_old = table.copy(trackingLib.disabledQuests)
        table.clear(trackingLib.disabledQuests)

        local data = tes3.player.data["herbert_QL"]
        if data and data.hidden_ids then
            for _, quest in pairs(tes3.worldController.quests) do
                if not data.hidden_ids[quest.id] then goto continue end

                for _, dialogue in pairs(quest.dialogue or {}) do
                    local idLower = dialogue.id:lower()
                    trackingLib.setDisableMarkerState{ questId = idLower, value = true }
                    trackingLib.disabledQuests[idLower] = true
                    disabledQuests_old[idLower] = nil
                end

                ::continue::
            end
        end

        for qId, _ in pairs(disabledQuests_old) do
            trackingLib.setDisableMarkerState{ questId = qId, value = false }
        end
        trackingLib.updateMarkers(true)
    end
end

local function onLoaded()
    this.isMenuActive = false
    this.initKeyCallback(lastKey)


    if not config.data.integration.questLogMenu.hideHidden then return end
    local data = tes3.player.data["herbert_QL"]
    if data and data.hidden_ids then
        for _, quest in pairs(tes3.worldController.quests) do
            if not data.hidden_ids[quest.id] then goto continue end

            for _, dialogue in pairs(quest.dialogue or {}) do
                local id = dialogue.id:lower()
                trackingLib.disabledQuests[id] = true
            end

            ::continue::
        end
        trackingLib.updateMarkers(true)
    end
end



function this.initKeyCallback(key)
    if not key then return end
    if lastKey then
        event.unregister(tes3.event.keyDown, onQLMKeyCallback, { filter = lastKey, priority = priority })
    end
    if not this.isMenuActive then
        event.register(tes3.event.keyDown, onQLMKeyCallback, { filter = key, priority = priority })
    end
    lastKey = key
end


function this.init()
    local QLMKey = getQLMKey()
    if not QLMKey then return end

    ---@type herbert.QLM.Quest_List?
    local Quest_List = include("herbert100.quest log menu.Quest_List")
    if not Quest_List then return end

    this.Quest_List = Quest_List

    this.initKeyCallback(QLMKey)

    event.register("herbert.QLM:menu_destroyed", onMenuDestroyed)
    event.register("herbert:QLM:MCM_closed", onMCMClosed)
    event.register(tes3.event.loaded, onLoaded)
end

return this