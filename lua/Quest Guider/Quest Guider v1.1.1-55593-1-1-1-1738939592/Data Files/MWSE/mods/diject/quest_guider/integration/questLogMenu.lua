local log = include("diject.quest_guider.utils.log")
local config = include("diject.quest_guider.config")
local journalUI = include("diject.quest_guider.UI.journal")
local trackingLib = include("diject.quest_guider.tracking")
local questLib = include("diject.quest_guider.quest")

local priority = -278
local buttonId = "qGuider_QLMBtn"

local this = {}

this.isMenuActive = false

local lastKey = nil

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
            if not questDt then return end
            local questId = questDt.dialogue and questDt.dialogue[1] and questDt.dialogue[1].id
            if not questId then return end
            local quest = questLib.getQuestData(questId)

            return questId, quest
        end

        if config.data.integration.questLogMenu.tooltip then
            qGuiderBtn:register(tes3.uiEvent.help, function (ei)
                local questId, quest = getQuestParams()
                if not questId or not quest then return end

                local tooltip = tes3ui.createTooltipMenu()
                tooltip.autoWidth = true
                if not config.data.journal.requirements.tooltip then
                    if not journalUI.createHelpMessage(tooltip, "Click to open. / Shift+Click to track quest objects.", tes3.justifyText.left) then
                        tooltip:destroy()
                    end
                    return
                else
                    journalUI.createHelpMessage(tooltip, "Click to open. / Shift+Click to track quest objects.")
                end
                if not journalUI.drawRequirementMenu(tooltip, questId, nil, quest) then
                    tooltip:destroy()
                end
            end)
        end

        qGuiderBtn:register(tes3.uiEvent.mouseClick, function()
            local questId, quest = getQuestParams()
            if not questId or not quest then return end

            if tes3.worldController.inputController:isShiftDown() then
                trackingLib.trackQuestsbyQuestId(questId)
                return
            end

            local function createContainerButtons(menuEl, buttonBlock)
                journalUI.createContainerButtons(questId, menuEl, buttonBlock, {trackDisplayedBtn = false})
            end

            local el, buttonBlock = journalUI.drawContainer("Requirements", createContainerButtons)

            if not el or not buttonBlock then return end

            if not journalUI.drawRequirementMenu(el, questId, nil, quest) then
                el:destroy()
                return
            end
            journalUI.centerToCursor(el)
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
end

local function onLoaded()
    this.isMenuActive = false
    this.initKeyCallback(lastKey)
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