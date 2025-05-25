local log = include("diject.quest_guider.utils.log")
local tableLib = include("diject.quest_guider.utils.table")
local tooltipLib = include("diject.quest_guider.UI.tooltipSys")
local filedBlockLib = include("diject.quest_guider.UI.fieldBlockSys")
local stringLib = include("diject.quest_guider.utils.string")

local questLib = include("diject.quest_guider.quest")
local cellLib = include("diject.quest_guider.cell")
local trackingLib = include("diject.quest_guider.tracking")
local playerQuests = include("diject.quest_guider.playerQuests")
local types = include("diject.quest_guider.types")
local mapInfo = include("diject.quest_guider.mapInfo")
local menuContainer = include("diject.quest_guider.UI.menuContainer")

local config = include("diject.quest_guider.config")

local markerColors = include("diject.quest_guider.Types.color")

local mcp_mapExpansion = tes3.hasCodePatchFeature(tes3.codePatchFeature.mapExpansionForTamrielRebuilt)

local this = {}

local infoMenu = {
    block = "qGuider_info_block",
    headerId = "qGuider_info_header",
    questidId = "qGuider_info_questId",
    sourceModId = "qGuider_info_sourceMod",
    indexId = "qGuider_info_index",
    nextIndexes = "qGuider_info_nextIndexes",
    currentIndex = "qGuider_info_currentIndex",
}

local requirementsMenu = {
    block = "qGuider_req_block",
    scroll = "qGuider_scroll_pane",
    text = "qGuider_req_text",
    headerLabel = "qGuider_req_headerLabel",
    finishedLabel = "qGuider_req_finishedLabel",
    selectedCurrentBlock = "qGuider_req_selectedCurrentBlock",
    selectedLabel = "qGuider_req_selectedLabel",
    currentLabel = "qGuider_req_currentLabel",
    allLabel = "qGuider_req_allLabel",
    indexTabBlock = "qGuider_req_indexTabBlock",
    indexTabLabel = "qGuider_req_indexTabLabel",
    indexTab = "qGuider_req_indexTab",
    requirementBlock = "qGuider_req_requirementBlock",
    requirementLabel = "qGuider_req_requirementLabel",
    requirementIndexMainBlock = "qGuider_req_requirementIndexMainBlock",
    requirementIndexBlock = "qGuider_req_requirementIndexBlock",
    nextIndexValueLabel = "qGuider_req_nextIndexValueLabel",
    nextIndexLabel = "qGuider_req_nextIndexLabel",
    localValueTooltipBlock = "qGuider_req_localValueTooltipBlock",
}

local scriptLocalsMenu = {
    block = "qGuider_locals_block",
    headerLabel = "qGuider_locals_headerLabel",
    requirementsFullBlock = "qGuider_locals_requirementsFullBlock",
    requirementsBlock = "qGuider_locals_requirementsBlock",
    resultLabel = "qGuider_locals_resultLabel"
}

local mapMenu = {
    block = "qGuider_map_block",
    requirementBlock = "qGuider_map_requirementBlock",
    mapBlock = "qGuider_map_mapBlock",
    pane = "qGuider_map_pane",
    markerBlock = "qGuider_map_markerBlock",
    image = "qGuider_map_image",
    marker = "qGuider_map_marker",
    tooltipBlock = "qGuider_map_tooltipBlock",
    tooltipName = "qGuider_map_tooltipName",
    tooltipDescription = "qGuider_map_tooltipDescription",
}

local containerMenu = {
    trackBtn = "qGuider_container_trackBtn",
}

local journalMenu = {
    requirementBlock = "qGuider_journal_reqBlock",
    questNameLabel = "qGuider_journal_qNameLabel",
    questNameBlock = "qGuider_journal_qNameBlock",
    requirementsIcon = "qGuider_journal_reqIcon",
    mapIcon = "qGuider_journal_MapIcon",
}

local helpMenu = {
    label = "qGuider_help_label",
}

this.colors = {
    default = {0.792, 0.647, 0.376},
    lightDefault = {0.892, 0.747, 0.476},
    lightGreen = {0.5, 1, 0.5},
    lightYellow = {0.8, 0.8, 0.5},
    lightLightYellow = {0.8, 0.8, 0.3},
    disabled = {0.25, 0.25, 0.25}
}

function this.init()
    this.colors.default = tes3ui.getPalette(tes3.palette.normalColor)
    this.colors.lightDefault = tes3ui.getPalette(tes3.palette.notifyColor)
    this.colors.disabled = tes3ui.getPalette(tes3.palette.journalFinishedQuestOverColor)
end


---@class questGuider.ui.markerImage
---@field path string
---@field scale number?
---@field shiftX integer?
---@field shiftY integer?

---@type table<string, questGuider.ui.markerImage>
this.markers = {
    quest = {path = "diject\\quest guider\\defaultArrow32x32.dds", shiftX = -8, shiftY = 15, scale = 0.5},
    zone = { path = "diject\\quest guider\\circleZoneMarker128x128.dds", shiftX = -64, shiftY = 64, scale = 128},
}


local updateContainerMenu = menuContainer.updateContainerMenu

local makeLabelSelectable = include("diject.quest_guider.UI.utils").makeLabelSelectable

---@param element tes3uiElement
---@param message string
---@param justifyText tes3.justifyText?
---@return boolean
function this.createHelpMessage(element, message, justifyText)
    if not config.data.main.helpLabels then return false end
    local block = element:createBlock{}
    block.autoWidth = true
    block.autoHeight = true
    block.maxWidth = 400
    local label = block:createLabel{ id = helpMenu.label, text = message }
    label.autoWidth = false
    label.autoHeight = true
    label.widthProportional = 1
    label.justifyText = justifyText or tes3.justifyText.center
    label.wrapText = true
    label.color = this.colors.lightDefault
    return true
end


---@param parent tes3uiElement
---@param questId string
---@param index integer|string
---@param questData questDataGenerator.questData
function this.drawQuestInfoMenu(parent, questId, index, questData)
    local topicData = questData[tostring(index)]
    local questName = questData.name or "???"
    local topicIndex = tostring(index) or "???"

    local mainBlock = parent:createBlock{ id = infoMenu.block }
    mainBlock.flowDirection = tes3.flowDirection.topToBottom
    mainBlock.autoHeight = true
    mainBlock.autoWidth = true
    mainBlock.maxWidth = 300

    local headerLabel = mainBlock:createLabel{ id = infoMenu.headerId, text = questName }

    local questIdStr = questId or "???"
    local questIdLabel = mainBlock:createLabel{ id = infoMenu.questidId, text = string.format("Quest id: \"%s\"", questIdStr) }

    local sourceMod = ((playerQuests.getQuestData(questId) or {}).record or {}).sourceMod
    if sourceMod then
        local sourceModLabel = mainBlock:createLabel{ id = infoMenu.sourceModId, text = string.format("Source mod: \"%s\"", sourceMod) }
    end

    local indexesStr = ""
    local indexes = questLib.getIndexes(questData)
    for _, ind in ipairs(indexes or {}) do
        indexesStr = indexesStr..tostring(ind)..", "
    end
    if #indexesStr > 0 then
        indexesStr = indexesStr:sub(1, -3)
    end
    local indexStr = string.format("Stage: %s of [%s]", topicIndex, indexesStr)
    local topicIndexLabel = mainBlock:createLabel{ id = infoMenu.indexId, text = indexStr }

    if topicData and topicData.next and #topicData.next > 0 then
        local nextIndexesStr = "Possible next stage"..(#topicData.next > 1 and "es" or "")..": "..tableLib.valuesToStr(topicData.next)
        local topicnextIndexesLabel = mainBlock:createLabel{ id = infoMenu.nextIndexes, text = nextIndexesStr }
    end

    local currentIndex = playerQuests.getCurrentIndex(questId)
    if currentIndex then
        local currentData = questData[tostring(currentIndex)]
        local finishedStr = currentData and currentData.finished and " (Finished)" or ""
        local currentIndexStr = string.format("Current stage: %d%s", currentIndex, finishedStr)
        local currentIndexLabel = mainBlock:createLabel{ id = infoMenu.currentIndex, text = currentIndexStr }
    end

    updateContainerMenu(mainBlock)
end


---@param parent tes3uiElement
---@param scriptNames table<string, table<string, string>>
---@return boolean|nil ret return true, if contains a script var from "scriptNames"
function this.drawScriptLocalsMenu(parent, scriptNames)
    local ret = false

    local mainBlock = parent:createBlock{ id = scriptLocalsMenu.block }
    mainBlock.flowDirection = tes3.flowDirection.topToBottom
    mainBlock.autoHeight = true
    mainBlock.widthProportional = 1
    mainBlock.visible = true

    local function isContainsVarName(scrName, varName)
        local scrData = scriptNames[scrName]

        if not scrData then return false end

        if scrData[varName] then
            return true
        end

        local varsToFind = table.copy(scrData)
        for n, v in pairs(scrData) do
            if not tonumber(v) then
                varsToFind[v] = true
            end
        end

        local scriptData = questLib.getLocalVariableDataByScriptName(scrName)
        if not scriptData then return false end

        local function findInResults()
            local count = table.size(varsToFind)

            for varN, data in pairs(scriptData) do
                for _, valBlock in pairs(data.results) do
                    for _, block in pairs(valBlock) do
                        for _, req in pairs(block) do
                            for n, _ in pairs(varsToFind) do
                                if not varsToFind[req.value] and string.find(req.value or "", n) then
                                    varsToFind[req.value] = true
                                end
                                if not varsToFind[req.variable] and string.find(req.variable or "", n) then
                                    varsToFind[req.variable] = true
                                end
                            end
                        end
                    end
                end
            end

            if count ~= table.size(varsToFind) then findInResults() end
        end

        findInResults()

        if varsToFind[varName] then return true end

        return false
    end

    local wasCreated = false

    for scriptName, varTargetData in pairs(scriptNames) do

        local scriptData = questLib.getLocalVariableDataByScriptName(scriptName)

        if not scriptData then goto continue end

        local divider = mainBlock:createDivider{ id = nil }
        local headerLabel = mainBlock:createLabel{ id = nil, text = string.format("Script \"%s\":", scriptName) }
        headerLabel.color = this.colors.lightYellow

        for varName, varData in pairs(scriptData) do
            if not isContainsVarName(scriptName, varName) then
                goto continue
            end

            wasCreated = true

            local varLabel = mainBlock:createLabel{ id = nil, text = string.format("Variable \"%s\":", varName) }
            varLabel.borderLeft = 5
            varLabel.borderTop = 5

            local varValuesBlock = mainBlock:createBlock{ id = nil }
            varValuesBlock.borderTop = 4
            varValuesBlock.borderLeft = 8
            varValuesBlock.autoHeight = true
            varValuesBlock.widthProportional = 1
            varValuesBlock.flowDirection = tes3.flowDirection.leftToRight

            local varReqsBlock = mainBlock:createBlock{ id = scriptLocalsMenu.requirementsFullBlock }
            varReqsBlock.borderTop = 2
            varReqsBlock.autoHeight = true
            varReqsBlock.widthProportional = 1
            varReqsBlock.flowDirection = tes3.flowDirection.topToBottom

            local varValueLabel = varValuesBlock:createLabel{ id = nil, text = "Value:" }
            varValueLabel.color = this.colors.lightLightYellow
            varValueLabel.borderRight = 10

            for valueStr, resData in pairs(varData.results or {}) do
                local resLabel = varValuesBlock:createLabel{ id = scriptLocalsMenu.resultLabel, text = string.format("- %s -", tostring(valueStr)) }
                resLabel.borderRight = 6
                resLabel.color = this.colors.disabled

                makeLabelSelectable(resLabel)

                resLabel:register(tes3.uiEvent.mouseClick, function (e)
                    for _, child in pairs(varValuesBlock.children) do
                        if child.name == scriptLocalsMenu.resultLabel then
                            child.color = this.colors.disabled
                        end
                    end
                    resLabel.color = this.colors.lightGreen
                    varReqsBlock:destroyChildren()

                    for _, requirements in pairs(resData) do

                        if #varReqsBlock.children > 0 then
                            local block = varReqsBlock:createBlock{ id = nil }
                            block.autoHeight = true
                            block.widthProportional = 1
                            block.flowDirection = tes3.flowDirection.topToBottom
                            block.childAlignX = 0.5

                            local label = block:createLabel{ id = nil, text = "or" }
                        end

                        local requirementData = questLib.getDescriptionDataFromDataBlock(requirements)

                        local reqsBlock = varReqsBlock:createRect{ id = scriptLocalsMenu.requirementsBlock }
                        reqsBlock.alpha = 0.1
                        reqsBlock.autoHeight = true
                        reqsBlock.widthProportional = 1
                        reqsBlock.flowDirection = tes3.flowDirection.topToBottom

                        if requirementData then
                            reqsBlock:setLuaData("requirementData", requirementData)
                            for _, req in pairs(requirementData) do
                                local reqLabel = reqsBlock:createLabel{ id = requirementsMenu.requirementLabel, text = req.str }
                                reqLabel.borderTop = 4
                                reqLabel.color = this.colors.lightDefault
                                reqLabel.wrapText = true
                                reqLabel:setLuaData("requirement", req)

                                if req.positionData then
                                    local tooltip = tooltipLib.new{parent = reqLabel}
                                    if config.data.main.helpLabels then
                                        tooltip:add{name = "Click to track.", nameColor = this.colors.lightDefault}
                                    end
                                    for objId, posDt in pairs(req.positionData) do
                                        local posDescriptions = {}
                                        for _, p in pairs(posDt.positions) do
                                            table.insert(posDescriptions, p.description)
                                        end
                                        tooltip:add{name = posDt.name}
                                        local strings = stringLib.getValueEnumString(posDescriptions, config.data.journal.requirements.pathDescriptions, nil, true)
                                        for _, str in pairs(strings) do
                                            tooltip:add{description = str}
                                        end
                                    end
                                end

                                makeLabelSelectable(reqLabel)
                            end
                        else
                            local reqLabel = reqsBlock:createLabel{ id = requirementsMenu.requirementLabel, text = "???" }
                            reqLabel.color = this.colors.lightDefault
                            reqLabel.borderTop = 4

                            makeLabelSelectable(reqLabel)
                        end
                    end

                    local parentMain = parent:getTopLevelMenu():findChild(mapMenu.block)
                    local scroll = parent:getTopLevelMenu():findChild(requirementsMenu.scroll)
                    if parentMain then
                        updateContainerMenu(parentMain, scroll)
                    else
                        updateContainerMenu(mainBlock, scroll)
                    end
                end)

                if ((varTargetData[varName]) and (varTargetData[varName] == valueStr or not tonumber(valueStr))) or
                        table.find(varTargetData, varName) then
                    resLabel:triggerEvent(tes3.uiEvent.mouseClick)
                    ret = true
                end
            end
            ::continue::
        end

        ::continue::
    end

    if not wasCreated then
        mainBlock.visible = false
    end

    return ret
end


---@param parent tes3uiElement
---@param questId string
---@param index integer|string|nil
---@param questData questDataGenerator.questData
---@return boolean|nil
function this.drawQuestRequirementsMenu(parent, questId, index, questData)
    local playerCurrentIndex = playerQuests.getCurrentIndex(questId)
    local currentTopicData = questData[tostring(playerCurrentIndex)]
    local playerCurrentIndexStr = tostring(playerCurrentIndex or "???")

    local hideSelected = false
    local hideCurrent = false
    if not currentTopicData then
        hideSelected = true
        hideCurrent = true
    elseif index == nil then
        hideSelected = true
        index = playerCurrentIndex
    end

    local questName = questData.name or "???"
    local topicIndexStr = tostring(index or "???")

    local mainBlock = parent:createRect{ id = requirementsMenu.block }
    mainBlock.flowDirection = tes3.flowDirection.topToBottom
    mainBlock.height = 400
    mainBlock.width = 400
    mainBlock.visible = false

    mainBlock:setLuaData("questId", questId)

    local scrollBlock = mainBlock:createVerticalScrollPane{ id = requirementsMenu.scroll }
    scrollBlock.heightProportional = 1
    scrollBlock.widthProportional = 1
    scrollBlock.widget.scrollbarVisible = true

    local scrollBlockContent = scrollBlock:getContentElement()

    local headerLabel = scrollBlockContent:createLabel{ id = requirementsMenu.headerLabel }
    headerLabel.borderBottom = 2
    headerLabel.wrapText = true

    local function resetHeaderQuestName()
        headerLabel.text = string.format("%s, id: \"%s\"", questName, questId)
    end

    resetHeaderQuestName()

    if currentTopicData and playerQuests.isFinished(questId) then
        local finishedLabel = scrollBlockContent:createLabel{ id = requirementsMenu.finishedLabel, text = "Finished" }
        finishedLabel.color = this.colors.lightGreen
        finishedLabel.widthProportional = 1
    end

    local selectedCurrentBlock = scrollBlockContent:createBlock{ id = requirementsMenu.selectedCurrentBlock }
    selectedCurrentBlock.autoHeight = true
    selectedCurrentBlock.autoWidth = true
    selectedCurrentBlock.flowDirection = tes3.flowDirection.leftToRight
    selectedCurrentBlock.borderBottom = 2
    -- selectedCurrentBlock.visible = false
    selectedCurrentBlock:createLabel{ id = requirementsMenu.text, text = "Stage:" }.borderRight = 20
    local selLabel = selectedCurrentBlock:createLabel{ id = requirementsMenu.selectedLabel, text = string.format("Selected (%s)", topicIndexStr) }
    local lstLabel = selectedCurrentBlock:createLabel{ id = requirementsMenu.currentLabel, text = string.format("Current (%s)", playerCurrentIndexStr) }
    local allLabel = selectedCurrentBlock:createLabel{ id = requirementsMenu.allLabel, text = "All" }
    lstLabel.borderLeft = 20
    allLabel.borderLeft = 20

    if hideSelected then
        selLabel.visible = false
    end

    if hideCurrent then
        lstLabel.visible = false
    end

    makeLabelSelectable(selLabel)
    makeLabelSelectable(lstLabel)
    makeLabelSelectable(allLabel)

    local reqIndexMainBlock = scrollBlockContent:createBlock{ id = requirementsMenu.requirementIndexMainBlock }
    reqIndexMainBlock.autoHeight = true
    reqIndexMainBlock.autoWidth = true
    reqIndexMainBlock.borderBottom = 2
    reqIndexMainBlock.flowDirection = tes3.flowDirection.leftToRight
    local nextIndexLabel = reqIndexMainBlock:createLabel{ id = requirementsMenu.nextIndexLabel, text = "Possible next:" }
    -- nextIndexLabel.visible = false

    local reqIndexBlock = reqIndexMainBlock:createBlock{ id = requirementsMenu.requirementIndexBlock }
    reqIndexBlock.autoHeight = true
    reqIndexBlock.width = 300
    reqIndexBlock.borderLeft = 10
    reqIndexBlock.flowDirection = tes3.flowDirection.topToBottom

    local indexFieldBlock = filedBlockLib.new{parent = reqIndexBlock, delimiter = ",", delimiterBorderRight = 6}

    local indexTabBlock = scrollBlockContent:createBlock{ id = requirementsMenu.indexTabBlock }
    indexTabBlock.autoHeight = true
    indexTabBlock.autoWidth = false
    indexTabBlock.width = 360
    indexTabBlock.flowDirection = tes3.flowDirection.topToBottom
    indexTabBlock.visible = false

    local tabFieldBlock = filedBlockLib.new{parent = indexTabBlock, delimiter = "or", delimiterBorderRight = 6, borderRight = 6}

    local reqBlock = scrollBlockContent:createBlock{ id = requirementsMenu.requirementBlock }
    reqBlock.autoHeight = true
    reqBlock.widthProportional = 1
    reqBlock.borderTop = 2
    reqBlock.flowDirection = tes3.flowDirection.topToBottom


    local function resetDynamicToDefault()
        indexTabBlock.visible = false
        reqBlock:destroyChildren()
        indexFieldBlock:destroyChildren()
        -- indexTabBlock:destroyChildren()
        tabFieldBlock:destroyChildren()
        selLabel.color = this.colors.disabled
        lstLabel.color = this.colors.disabled
        allLabel.color = this.colors.disabled
        nextIndexLabel.text = "Possible next:"
        indexFieldBlock.width = 250
    end

    ---@param topicIndex integer?
    local function drawTopicInfo(topicIndex)

        local indexes
        local linkedIndexData
        if topicIndex then
            indexes, linkedIndexData = questLib.getNextIndexes(questData, questId, topicIndex, {findInLinked = true})
        else
            indexes = questLib.getIndexes(questData)
        end
        if not indexes and not linkedIndexData then
            -- indexTabBlock:destroyChildren()
            tabFieldBlock:destroyChildren()
            reqBlock:destroyChildren()
            return
        end

        ---@type tes3uiElement[]
        local nextIndTabs = {}

        ---@param ind integer
        ---@param qId string?
        ---@param qData questDataGenerator.questData?
        local function createIndex(ind, qId, qData)
            local islinkedDia = qData ~= nil
            if qData == nil then
                qData = questData
            end
            local indStr = tostring(ind)
            local indTopicData = qData[indStr]
            if not indTopicData then return end

            local nextIndexValueLabel = indexFieldBlock:add{
                id = requirementsMenu.nextIndexValueLabel,
                text = islinkedDia and "<"..indStr..">" or "-"..indStr.."-"
            }
            if not nextIndexValueLabel then return end
            table.insert(nextIndTabs, nextIndexValueLabel)

            makeLabelSelectable(nextIndexValueLabel)

            nextIndexValueLabel:setLuaData("data", indTopicData)

            nextIndexValueLabel:register(tes3.uiEvent.mouseClick, function (e)

                if not islinkedDia then
                    resetHeaderQuestName()
                else
                    headerLabel.text = string.format("%s, id: \"%s\"", qData.name or "???", qId)
                end

                for _, tb in pairs(nextIndTabs) do
                    tb.color = this.colors.disabled
                end
                e.source.color = this.colors.lightGreen

                -- indexTabBlock:destroyChildren()
                tabFieldBlock:destroyChildren()
                reqBlock:destroyChildren()

                -- indexTabBlock:createLabel{ id = requirementsMenu.text, text = "Requirements:" }.borderRight = 10
                tabFieldBlock:add{ id = requirementsMenu.text, text = "Requirements:", isLabel = true }

                local tabs = {}
                for i, reqDataBlock in pairs(indTopicData.requirements or {}) do

                    indexTabBlock.visible = true

                    local tab = tabFieldBlock:add{ id = requirementsMenu.indexTab, text = "-"..tostring(i).."-" }
                    if not tab then goto continue end
                    table.insert(tabs, tab)

                    makeLabelSelectable(tab)

                    local requirementData = questLib.getDescriptionDataFromDataBlock(reqDataBlock, qId)
                    tab:setLuaData("requirementData", requirementData)

                    tab:register(tes3.uiEvent.mouseClick, function (e)
                        reqBlock:destroyChildren()
                        reqBlock:setLuaData("index", ind)
                        reqBlock:setLuaData("questId", qId)

                        local playerIndex = playerQuests.getCurrentIndex(qId) or -1
                        if playerIndex >= ind then
                            local block = reqBlock:createBlock{}
                            block.autoHeight = true
                            block.widthProportional = 1
                            block.childAlignX = 0.5
                            local label = block:createLabel{ id = "qGuider_req_requirementCurrentLabel", text = playerIndex == ind and "Current" or "Completed"}
                            label.color = this.colors.lightGreen
                        end

                        ---@type table<string, table<string, string>>
                        local variableScripts = {}

                        if requirementData then
                            reqBlock:setLuaData("requirementData", requirementData)

                            for _, req in pairs(requirementData) do
                                local reqType = req.data.type

                                local reqLabel = reqBlock:createLabel{ id = requirementsMenu.requirementLabel, text = req.str }
                                reqLabel.borderTop = 4
                                reqLabel.color = this.colors.lightDefault
                                reqLabel.wrapText = true
                                reqLabel:setLuaData("requirement", req)
                                reqLabel:setLuaData("index", ind)
                                reqLabel:setLuaData("questId", qId)
                                for objId, _ in pairs(req.objects or {}) do
                                    local trackingObj = trackingLib.getObjectData(objId)
                                    if trackingObj then
                                        reqLabel.color = trackingObj.color
                                        break
                                    end
                                end

                                if reqType == types.requirementType.Journal then
                                    local tooltip = tooltipLib.new{parent = reqLabel}
                                    local currInd = playerQuests.getCurrentIndex(req.data.variable)
                                    tooltip:add{name = string.format("Your current index of this quest is %s", tostring(currInd or 0)),
                                        nameColor = this.colors.default}
                                end

                                if req.positionData then
                                    local tooltip = tooltipLib.new{parent = reqLabel}
                                    if config.data.main.helpLabels then
                                        tooltip:add{name = "Click to track.", nameColor = this.colors.lightDefault}
                                    end
                                    for objId, posDt in pairs(req.positionData) do
                                        local posDescriptions = {}
                                        for j = 1, math.min(config.data.journal.requirements.pathDescriptions + 1, #posDt.positions) do
                                            local p = posDt.positions[j]
                                            table.insert(posDescriptions, p.description)
                                        end
                                        tooltip:add{name = posDt.name}
                                        local strings = stringLib.getValueEnumString(posDescriptions, config.data.journal.requirements.pathDescriptions,
                                            nil, true, posDt.inWorld or #posDt.positions)
                                        for _, str in pairs(strings) do
                                            tooltip:add{description = str}
                                        end
                                    end

                                    reqLabel:register(tes3.uiEvent.mouseClick, function (e)
                                        for objId, posDt in pairs(req.positionData) do
                                            local res = trackingLib.addMarker{objectId = objId, questId = qId, questStage = ind,
                                                positionData = posDt, reqData = req}
                                            if res then
                                                reqLabel.color = res.color
                                            end
                                        end
                                        if tes3.player.cell.isInterior then
                                            trackingLib.addMarkersForInteriorCell(tes3.player.cell)
                                        end
                                    end)
                                end

                                makeLabelSelectable(reqLabel)

                                local scriptName = req.data.script
                                if scriptName and (reqType == types.requirementType.CustomLocal or reqType == types.requirementType.CustomNotLocal) then
                                    if not variableScripts[scriptName] then
                                        variableScripts[scriptName] = {[req.data.variable] = req.data.value}
                                    else
                                        variableScripts[scriptName][req.data.variable] = req.data.value
                                    end

                                    reqLabel:register(tes3.uiEvent.help, function (e)
                                        local tooltip = tes3ui.createTooltipMenu()

                                        local block = tooltip:createBlock{id = requirementsMenu.localValueTooltipBlock}
                                        block.flowDirection = tes3.flowDirection.topToBottom
                                        block.autoHeight = true
                                        block.autoWidth = false
                                        block.width = 400

                                        if not this.drawScriptLocalsMenu(block, {[scriptName] = {[req.data.variable] = req.data.value}}) then
                                            tooltip:destroy()
                                        else
                                            updateContainerMenu(tooltip)
                                        end
                                    end)
                                end
                            end
                        else
                            local reqLabel = reqBlock:createLabel{ id = requirementsMenu.requirementLabel, text = "???" }
                            reqLabel.color = this.colors.lightDefault
                            reqLabel.borderTop = 4

                            makeLabelSelectable(reqLabel)
                        end

                        if config.data.journal.requirements.scriptValues and table.size(variableScripts) > 0 then
                            this.drawScriptLocalsMenu(reqBlock, variableScripts)
                        end

                        for _, tb in pairs(tabs) do
                            tb.color = this.colors.disabled
                        end
                        tab.color = this.colors.lightGreen

                        local callback = reqBlock:getLuaData("callback")
                        if callback then
                            callback(reqBlock, requirementData)
                        else
                            updateContainerMenu(mainBlock, scrollBlock)
                        end

                    end)

                    ::continue::
                end

                if #tabs > 0 then
                    tabs[1]:triggerEvent(tes3.uiEvent.mouseClick)
                    reqIndexMainBlock.visible = true
                    -- nextIndexLabel.visible = true
                    -- tabs[1].color = this.colors.lightGreen

                    if #tabs == 1 then
                        tabs[1].visible = false
                    end
                end

            end)
        end

        for _, ind in ipairs(indexes or {}) do
            createIndex(ind, questId)
        end

        for qId, data in pairs(linkedIndexData or {}) do
            createIndex(data.index, qId, data.qData)
        end

        if #nextIndTabs > 0 then
            local found = false
            for _, tab in pairs(nextIndTabs) do
                ---@type questDataGenerator.stageData
                local data = tab:getLuaData("data")
                if data and data.requirements and #data.requirements > 0 then
                    tab:triggerEvent(tes3.uiEvent.mouseClick)
                    found = true
                    break
                end
            end
            if not found then
                nextIndTabs[1]:triggerEvent(tes3.uiEvent.mouseClick)
            end
            -- nextIndTabs[1].color = this.colors.lightGreen
        end
    end

    selLabel:register(tes3.uiEvent.mouseClick, function (e)
        resetDynamicToDefault()
        selLabel.color = this.colors.lightGreen
        drawTopicInfo(index)
    end)

    lstLabel:register(tes3.uiEvent.mouseClick, function (e)
        resetDynamicToDefault()
        lstLabel.color = this.colors.lightGreen
        drawTopicInfo(playerCurrentIndex)
    end)

    allLabel:register(tes3.uiEvent.mouseClick, function (e)
        resetDynamicToDefault()
        nextIndexLabel.text = "Stages:"
        indexFieldBlock.width = 300
        allLabel.color = this.colors.lightGreen
        drawTopicInfo()
    end)

    if hideSelected and hideCurrent then
        allLabel:triggerEvent(tes3.uiEvent.mouseClick)
    elseif config.data.journal.requirements.currentByDefault or hideSelected then
        lstLabel:triggerEvent(tes3.uiEvent.mouseClick)
    else
        selLabel:triggerEvent(tes3.uiEvent.mouseClick)
    end

    updateContainerMenu(mainBlock, scrollBlock)

    mainBlock.visible = indexTabBlock.visible or nextIndexLabel.visible or selectedCurrentBlock.visible or allLabel.visible

    return mainBlock.visible
end



---@class questGuider.ui.createMarker.params
---@field pane tes3uiElement
---@field scale number?
---@field markerData questGuider.ui.markerImage
---@field x number
---@field y number
---@field color number[]|nil
---@field name string|nil
---@field description string|nil

---@param params questGuider.ui.createMarker.params
---@param widthHeight {width: number, height: number}
---@return number x, number y
local function convertObjectPosToWorldPaneCoordinates(params, widthHeight)
    local currentZoomX = widthHeight.width /  tes3.dataHandler.nonDynamicData.mapTexture.width
    local currentZoomY = widthHeight.height / tes3.dataHandler.nonDynamicData.mapTexture.height

    local xOffset = 4
    local yOffset = 4
    if mapInfo.uiExpansion then
        xOffset = 0
        yOffset = 0
    else
        if mcp_mapExpansion then
            xOffset = 1
            yOffset = 2
        end
    end

    local x = ((-mapInfo.worldBounds.minX + params.x / 8192) * mapInfo.worldBounds.cellResolution + xOffset) * currentZoomX
    local y = ((-mapInfo.worldBounds.maxY - 1 + params.y / 8192) * mapInfo.worldBounds.cellResolution - yOffset) * currentZoomY
    return x, y
end


---@param widthHeight {width: number, height: number}
---@param coordinates {x: number, y: number}
---@param markerData questGuider.ui.markerImage
---@param scale number?
local function calcMarkerPos(widthHeight, coordinates, markerData, scale)
    local xw, yw = convertObjectPosToWorldPaneCoordinates(coordinates, widthHeight)
    local x = xw + ((markerData.shiftX * (scale or 1)) or 0)
    local y = yw + ((markerData.shiftY * (scale or 1)) or 0)
    return x, y, xw, yw
end


---@param params questGuider.ui.createMarker.params
---@return tes3uiElement|nil
---@return number|nil x
---@return number|nil y
---@return number|nil xw
---@return number|nil yw
local function createMarker(params)
    if not params.pane then return end
    if not params.markerData or not params.markerData.path then return end

    local image = params.pane:createImage{id = mapMenu.marker, path = "textures\\"..params.markerData.path}

    if not image then return end

    local markerScale = params.markerData.scale or 1
    local approxConfig = config.data.tracking.approx
    if approxConfig.enabled then
        local radius = approxConfig.worldMap.radius
        markerScale = (mapInfo.worldBounds.cellResolution * (params.scale or 1) * radius / 4096) / params.markerData.scale
    end

    local x, y, xw, yw = calcMarkerPos(params.pane, params, params.markerData, approxConfig.enabled and markerScale or nil)

    image.autoHeight = true
    image.autoWidth = true
    image.absolutePosAlignX = -2
    image.absolutePosAlignY = -2
    image.positionX = math.min(x, params.pane.width)
    image.positionY = math.max(y, -params.pane.height)
    image.color = params.color or {1, 1, 1}
    image.imageScaleX = markerScale
    image.imageScaleY = markerScale
    image.alpha = approxConfig.enabled and config.data.journal.map.marker.zoneAlpha or config.data.journal.map.marker.alpha

    image:setLuaData("records", {params})

    local tooltip = tooltipLib.new{parent = image}
    tooltip:add{name = params.name, description = params.description}

    return image, x, y, xw, yw
end


---@param parent tes3uiElement
---@param questId string
---@param index integer|string|nil
---@param questData questDataGenerator.questData
---@param hideMap boolean|nil
function this.drawMapMenu(parent, questId, index, questData, hideMap)
    local approxConfig = config.data.tracking.approx

    local mainBlock = parent:createBlock{ id = mapMenu.block }
    mainBlock.flowDirection = tes3.flowDirection.leftToRight
    mainBlock.autoHeight = true
    mainBlock.autoWidth = true

    local reqBlock = mainBlock:createBlock{ id = mapMenu.requirementBlock }
    reqBlock.flowDirection = tes3.flowDirection.topToBottom
    reqBlock.autoHeight = true
    reqBlock.autoWidth = true

    local mapBlock = mainBlock:createBlock{ id = mapMenu.mapBlock }
    mapBlock.flowDirection = tes3.flowDirection.topToBottom
    mapBlock.width = 400
    mapBlock.height = 400
    mapBlock.visible = not hideMap

    local imageWidth = tes3.dataHandler.nonDynamicData.mapTexture.width
    local imageHeight = tes3.dataHandler.nonDynamicData.mapTexture.height

    local pane = mapBlock:createBlock{ id = mapMenu.pane }
    pane.width = imageWidth
    pane.height = imageHeight
    pane.ignoreLayoutX = true
    pane.ignoreLayoutY = true

    local mapMarkersBlock = pane:createBlock{ id = mapMenu.markerBlock }
    mapMarkersBlock.widthProportional = 1
    mapMarkersBlock.heightProportional = 1
    mapMarkersBlock.childAlignX = 0
    mapMarkersBlock.childAlignY = 1
    mapMarkersBlock.width = imageWidth
    mapMarkersBlock.height = imageHeight

    mapMarkersBlock:getTopLevelMenu():updateLayout()

    if not this.drawQuestRequirementsMenu(reqBlock, questId, index, questData) then
        return false
    end

    local innMenuReqBlock = reqBlock:findChild(requirementsMenu.requirementBlock)
    if not innMenuReqBlock then
        mapBlock.visible = false
        return
    end

    local qIndexForTracking = index
    if not qIndexForTracking then
        local playerCurrentIndex = playerQuests.getCurrentIndex(questId)
        if not playerCurrentIndex then return end
        qIndexForTracking = playerCurrentIndex
    end


    ---@param reqBl tes3uiElement 
    local function drawMarkers(reqBl)
        if not reqBl then return end

        mapMarkersBlock:destroyChildren()
        local image = mapMarkersBlock:createImage{id = mapMenu.image}
        image.texture = tes3.dataHandler.nonDynamicData.mapTexture:clone()

        local colorIndex = 1

        local colorOfObject = {}

        local markersData = {}

        ---@type { parent : tes3uiElement, marker : tes3uiElement }[]
        local markers = {}

        ---@param e tes3uiEventData
        local function mouseOver(e)
            local parentEl = e.source
            for _, markerDt in pairs(markers) do
                if parentEl.color[1] ~= markerDt.parent.color[1] or
                        parentEl.color[2] ~= markerDt.parent.color[2] or
                        parentEl.color[3] ~= markerDt.parent.color[3] then
                    markerDt.marker.visible = false
                end
            end
        end

        ---@param e tes3uiEventData
        local function mouseLeave(e)
            for _, markerDt in pairs(markers) do
                markerDt.marker.visible = true
            end
        end

        ---@param child tes3uiElement
        local function processChild(child)
            if child.name ~= requirementsMenu.requirementLabel and child.name ~= scriptLocalsMenu.requirementLabel then return end

            ---@type questGuider.quest.getDescriptionDataFromBlock.returnArr
            local reqData = child:getLuaData("requirement")
            local qId = child:getLuaData("questId")
            local qIndex = child:getLuaData("index")
            if not reqData or not reqData.positionData or not qIndex or not qId then return end

            local color = markerColors[colorIndex]


            local foundObjectsInChildren = 0
            for objId, dt in pairs(reqData.positionData) do

                foundObjectsInChildren = foundObjectsInChildren + 1

                local trackingObj = trackingLib.getObjectData(objId)

                if trackingObj then
                    color = trackingObj.color
                    if colorOfObject[objId] then colorOfObject[objId] = color end
                end

                if colorOfObject[objId] then
                    color = colorOfObject[objId]
                    goto continue
                else
                    colorOfObject[objId] = color
                end

                for _, posData in pairs(dt.positions) do
                    if posData.isExitEx then
                        local x = posData.exitPos.x
                        local y = posData.exitPos.y

                        table.insert(markersData, { parent = child, x = x, y = y, color = color, objId = objId, objName = dt.name, descr = posData.description })
                    end
                end

                ::continue::
            end

            if foundObjectsInChildren > 0 then
                child.color = color
                colorIndex = colorIndex == #markerColors and 1 or colorIndex + 1

                child:register(tes3.uiEvent.mouseOver, mouseOver)
                child:register(tes3.uiEvent.mouseLeave, mouseLeave)

                ---@param e tes3uiEventData
                local function mouseClick(e)
                    for objId, posDt in pairs(reqData.positionData or {}) do
                        trackingLib.addMarker{objectId = objId, questId = qId, questStage = qIndex,
                            positionData = posDt, reqData = reqData}
                    end
                    if tes3.player.cell.isInterior then
                        trackingLib.addMarkersForInteriorCell(tes3.player.cell)
                    end
                    trackingLib.updateMarkers(true)
                    drawMarkers(reqBl)
                end

                child:register(tes3.uiEvent.mouseClick, mouseClick)
            end
        end

        for _, child in pairs(reqBl.children) do
            processChild(child)
        end

        local scriptBlock = reqBl:findChild(scriptLocalsMenu.block)
        if scriptBlock then
            for children in table.traverse({scriptBlock}, "children") do
                processChild(children)
            end
        end

        if #markersData == 0 then
            mapBlock.width = 0
            mapBlock.height = 0
            goto continue
        else
            mapBlock.width = 400
            mapBlock.height = 400
        end

        do
            local minMaxX = {math.huge, -math.huge}
            local minMaxY = {math.huge, -math.huge}

            for _, data in pairs(markersData) do

                local x, y = calcMarkerPos({width = imageWidth, height = imageHeight}, data, this.markers.quest)

                minMaxX[1] = math.min(minMaxX[1], x)
                minMaxX[2] = math.max(minMaxX[2], x)
                minMaxY[1] = math.min(minMaxY[1], y)
                minMaxY[2] = math.max(minMaxY[2], y)

            end

            local xDiff = (minMaxX[2] - minMaxX[1])
            local yDiff = (minMaxY[2] - minMaxY[1])
            local xCenter = (minMaxX[1] + minMaxX[2]) / 2
            local yCenter = (minMaxY[1] + minMaxY[2]) / 2
            local additionalBorder = approxConfig.enabled and (mapInfo.worldBounds.cellResolution * approxConfig.worldMap.radius / 4048) or 0
            local xScale = xDiff == 0 and math.huge or mapBlock.width / ((xDiff + additionalBorder) * 1.5)
            local yScale = yDiff == 0 and math.huge or mapBlock.height / ((yDiff + additionalBorder) * 1.5)

            local scale = math.max(0.1, math.min(config.data.journal.map.maxScale, xScale, yScale))

            mapMarkersBlock.width = imageWidth * scale
            mapMarkersBlock.height = imageHeight * scale
            pane.width = imageWidth * scale
            pane.height = imageHeight * scale

            image.imageScaleX = scale
            image.imageScaleY = scale

            minMaxX = {math.huge, -math.huge}
            minMaxY = {math.huge, -math.huge}
            for _, data in pairs(markersData) do

                local im, x, y, xw, yw = createMarker{
                    pane = mapMarkersBlock,
                    scale = scale,
                    markerData = config.data.tracking.approx.enabled and this.markers.zone or this.markers.quest,
                    x = data.x, y = data.y, color = data.color,
                    name = data.objName,
                    description = data.descr,
                }

                if im then
                    table.insert(markers, {marker = im, parent = data.parent})
                    minMaxX[1] = math.min(minMaxX[1], xw)
                    minMaxX[2] = math.max(minMaxX[2], xw)
                    minMaxY[1] = math.min(minMaxY[1], yw)
                    minMaxY[2] = math.max(minMaxY[2], yw)
                end
            end

            xCenter = (minMaxX[1] + minMaxX[2]) / 2
            yCenter = (minMaxY[1] + minMaxY[2]) / 2
            pane.positionX = math.clamp(-xCenter + mapBlock.width / 2, -(pane.width - mapBlock.width), 0)
            pane.positionY = math.clamp(-(yCenter + mapBlock.height / 2), 0, pane.height - mapBlock.height)
        end

        ::continue::

        local scroll = parent:getTopLevelMenu():findChild(requirementsMenu.scroll)
        updateContainerMenu(mainBlock, scroll)
    end

    drawMarkers(innMenuReqBlock)

    innMenuReqBlock:setLuaData("callback", function(reqBl)
        drawMarkers(reqBl)
    end)

    return true
end


---@param parent tes3uiElement
---@param questId string
---@param index integer|string|nil
---@param questData questDataGenerator.questData
local function drawRequirementMenu(parent, questId, index, questData)
    return this.drawMapMenu(parent, questId, index, questData, not config.data.journal.map.enabled)
end


local ffi = require("ffi")

ffi.cdef[[
    char *strstr(const char *haystack, const char *needle);
]]

local function search_with_ffi_optimized(data, word, byName, includeFinished)
    local word_c = ffi.cast("const char*", word)
    local results = {}

    for _, dt in ipairs(data) do
        if dt.isFinished and not includeFinished then goto continue end

        local field
        if byName then
            field = dt.name
        else
            field = dt.id
        end

        local str = (field or ""):lower()
        local str_c = ffi.cast("const char*", str)
        if ffi.C.strstr(str_c, word_c) ~= nil then
            table.insert(results, dt)
        end

        ::continue::
    end
    return results
end

---@param parent tes3uiElement
---@return tes3uiElement|nil
function this.drawQuestsMenu(parent)
    if not parent then return end

    local playerQuestData = questLib.getPlayerQuestData()

    if not playerQuestData then return end

    local mainBlock = parent:createRect{ id = "qGuider_quests_block" }
    mainBlock.flowDirection = tes3.flowDirection.topToBottom
    mainBlock.autoHeight = true
    mainBlock.autoWidth = true

    local filterBlock = mainBlock:createBlock{ id = "qGuider_quests_filterBlock" }
    filterBlock.flowDirection = tes3.flowDirection.leftToRight
    filterBlock.autoHeight = true
    filterBlock.autoWidth = true

    local filterTextBorder = filterBlock:createThinBorder{ id = "qGuider_quests_filterTextInputBorder" }
    filterTextBorder.width = 300
    filterTextBorder.height = 25

    local filterTextInput = filterTextBorder:createTextInput{ id = "qGuider_quests_filterTextInput", autoFocus = true }
    filterTextInput.widthProportional = 1
    filterTextInput.heightProportional = 1

    local filterBtn = filterBlock:createButton{ id = "qGuider_quests_filterBtn", text = "Search" }

    local filterByName = true
    local filterTypeBtn = filterBlock:createButton{ id = "qGuider_quests_filterTypeBtn", text = "by name" }
    filterTypeBtn:register(tes3.uiEvent.mouseClick, function (e)
        filterByName = not filterByName
        if filterByName then
            e.source.text = "by name"
        else
            e.source.text = "by id"
        end
    end)

    local showFinished = true
    local displayFinishedBtn = filterBlock:createButton{ id = "qGuider_quests_displayFinishedBtn", text = "display finished quests" }
    displayFinishedBtn.borderLeft = 20
    displayFinishedBtn:register(tes3.uiEvent.mouseClick, function (e)
        showFinished = not showFinished
        if showFinished then
            e.source.text = "display finished quests"
        else
            e.source.text = "don't display finished quests"
        end

        filterBtn:triggerEvent(tes3.uiEvent.mouseClick)
    end)

    local mainSubBlock = mainBlock:createBlock{ id = "qGuider_quests_subBlock" }
    mainSubBlock.flowDirection = tes3.flowDirection.leftToRight
    mainSubBlock.autoHeight = true
    mainSubBlock.autoWidth = true

    local infoBlock = mainSubBlock:createBlock{ id = "qGuider_quests_infoBlock" }
    infoBlock.flowDirection = tes3.flowDirection.topToBottom
    infoBlock.height = 440
    infoBlock.width = 800

    local listBlock = mainSubBlock:createBlock{ id = "qGuider_quests_listBlock" }
    listBlock.flowDirection = tes3.flowDirection.topToBottom
    listBlock.height = 400
    listBlock.width = 300

    local questScroll = listBlock:createVerticalScrollPane{ id = "qGuider_quests_questPane" }
    questScroll.heightProportional = 1
    questScroll.widthProportional = 1

    local questPaneContent = questScroll:getContentElement()

    table.sort(playerQuestData, function (a, b)
        return (a.name or ("_"..a.id)) < (b.name or ("_"..b.id))
    end)

    filterBtn:register(tes3.uiEvent.mouseClick, function (e)
        questPaneContent:destroyChildren()
        infoBlock:destroyChildren()

        local res = search_with_ffi_optimized(playerQuestData, (filterTextInput.text or ""):lower(), filterByName, showFinished)
        for _, qData in ipairs(res) do
            local questName = qData.name or string.format("id: \"%s\"", qData.id)
            local label = questPaneContent:createLabel{ id = "qGuider_quests_questLabel", text = questName }
            makeLabelSelectable(label)

            label:register(tes3.uiEvent.mouseClick, function (e)
                infoBlock:destroyChildren()
                drawRequirementMenu(infoBlock, qData.id, nil, questLib.getQuestData(qData.id) or {})
            end)

            label:register(tes3.uiEvent.help, function (e)
                local tooltip = tes3ui.createTooltipMenu()
                tooltip.autoHeight = true
                tooltip.autoWidth = true
                tooltip.maxWidth = 400

                local tooltipContent = tooltip:getContentElement()
                tooltipContent.autoHeight = true
                tooltipContent.autoWidth = true
                tooltipContent.maxWidth = 400

                local text = string.format("\"%s\", id: \"%s\"", qData.name or "", qData.id)
                local nameLabel = tooltip:createLabel{ id = "qGuider_quests_tooltipLabel", text = text }
                nameLabel.widthProportional = 1
                nameLabel.autoHeight = true
                nameLabel.wrapText = true
            end)
        end

        updateContainerMenu(mainSubBlock, questScroll)
    end)

    updateContainerMenu(mainSubBlock, questScroll, mainSubBlock)
    menuContainer.centerToScreen(mainSubBlock:getTopLevelMenu())

    return mainSubBlock
end


---@class questGuider.ui.createContainerButtons.params
---@field trackCurrentBtn boolean?
---@field trackDisplayedBtn boolean?
---@field removeBtn boolean?

---@param questId string? lowercase
---@param menuEl any tes3uiElement
---@param buttonBlock any tes3uiElement
---@param params questGuider.ui.createContainerButtons.params? by default all buttons are enabled
function this.createContainerButtons(questId, menuEl, buttonBlock, params)
    if not params then
        params = {trackCurrentBtn = true, trackDisplayedBtn = true, removeBtn = true}
    end

    local function getQuestId()
        if questId then
            return questId
        else
            local topMenu = menuEl:getTopLevelMenu()
            local reqMenuBlock = topMenu:findChild(requirementsMenu.block)
            if not reqMenuBlock then return end

            local qId = reqMenuBlock:getLuaData("questId")

            return qId
        end
    end

    if params.trackCurrentBtn ~= false then

        local trackButton = buttonBlock:createButton{ id = containerMenu.trackBtn, text = "Track Current" }
        trackButton:register(tes3.uiEvent.mouseClick, function (e)
            local qId = getQuestId()
            if not qId then return end

            trackingLib.trackQuestsbyQuestId(qId)
            local innMenuReqBlock = menuEl:findChild(requirementsMenu.requirementBlock)
            if innMenuReqBlock then
                local drawFunc = innMenuReqBlock:getLuaData("callback")
                if drawFunc then
                    drawFunc(innMenuReqBlock)
                end
            end

            trackingLib.updateMarkers(true)
        end)
    end

    if params.trackDisplayedBtn ~= false then

        local trackDisplayedButton = buttonBlock:createButton{ id = containerMenu.trackBtn, text = "Track displayed" }
        trackDisplayedButton:register(tes3.uiEvent.mouseClick, function (e)
            local reqBlock = menuEl:findChild(requirementsMenu.requirementBlock)
            if not reqBlock then return end

            local objects = {}
            for _, child in pairs(reqBlock.children) do
                if child.name == requirementsMenu.requirementLabel then
                    ---@type questGuider.quest.getDescriptionDataFromBlock.returnArr
                    local requirement = child:getLuaData("requirement")
                    if not requirement then goto continue end

                    if not requirement.positionData then goto continue end

                    local qIndex = child:getLuaData("index")
                    if not qIndex then goto continue end

                    local qId = child:getLuaData("questId")
                    if not qId then goto continue end


                    for objId, posData in pairs(requirement.positionData) do
                        trackingLib.addMarker{objectId = objId, positionData = posData, questId = qId, questStage = qIndex, reqData = requirement}
                        objects[objId] = true
                    end
                end
                ::continue::
            end
            objects = table.keys(objects)

            if #objects > 0 then
                local names = {}
                for _, objId in pairs(objects) do
                    local obj = tes3.getObject(objId)
                    if not obj then goto continue end
                    table.insert(names, obj.name)
                    ::continue::
                end
                tes3ui.showNotifyMenu(stringLib.getValueEnumString(names, config.data.journal.requirements.pathDescriptions, "Started tracking %s."))
            end

            local drawFunc = reqBlock:getLuaData("callback")
            if drawFunc then
                drawFunc(reqBlock)
            end

            trackingLib.updateMarkers(true)
        end)

    end

    if params.removeBtn ~= false then

        local removeButton = buttonBlock:createButton{ id = containerMenu.trackBtn, text = "Remove" }
        removeButton:register(tes3.uiEvent.mouseClick, function (e)
            local reqBlock = menuEl:findChild(requirementsMenu.requirementBlock)
            if not reqBlock then return end

            local qId = reqBlock:getLuaData("questId")
            if not qId then return end

            trackingLib.removeMarker{questId = qId, removeLinked = true}

            tes3ui.showNotifyMenu("The markers have been removed.")

            local innMenuReqBlock = menuEl:findChild(requirementsMenu.requirementBlock)
            if innMenuReqBlock then
                local drawFunc = innMenuReqBlock:getLuaData("callback")
                if drawFunc then
                    drawFunc(innMenuReqBlock)
                end
            end

            trackingLib.updateMarkers(true)
        end)
    end
end


function this.updateJournalMenu()
    if not config.data.journal.requirements.enabled and not config.data.journal.info.enabled then
        return
    end

    local menu = tes3ui.findMenu("MenuJournal")
    if not menu then return end

    if menu:findChild(journalMenu.requirementBlock) then
        return
    end

    for _, pageName in pairs({"MenuBook_page_1", "MenuBook_page_2"}) do
        local page = menu:findChild(pageName)

        if not page then goto continue end

        for i, element in pairs(page.children) do

            if element.type == tes3.uiElementType.text then
                element.height = 4
            end
            if element.name ~= "MenuBook_hypertext" then goto continue end

            local questInfo = questLib.getQuestInfoByJournalText(element.text)

            if not questInfo then goto continue end

            local questId = questInfo[1].id
            local questIndex = questInfo[1].index
            local quest = questLib.getQuestData(questId)

            if not quest then goto continue end

            local function createTrackAllButton(menuEl, buttonBlock)
                this.createContainerButtons(questId, menuEl, buttonBlock)
            end

            local block = page:createBlock{ id = journalMenu.requirementBlock }
            page:reorderChildren(element, block, 1)
            block.flowDirection = tes3.flowDirection.leftToRight
            block.autoHeight = true
            block.autoWidth = true

            if config.data.journal.info.enabled then
                local infoBlock = block:createBlock{ id = journalMenu.questNameBlock }
                infoBlock.autoHeight = true
                infoBlock.autoWidth = false
                infoBlock.borderRight = 5
                infoBlock.width = math.max(1, page.width - 42)

                local infoLabel = infoBlock:createLabel{ id = journalMenu.questNameLabel, text = "("..tostring(questIndex)..") "..(quest.name or "") }
                infoLabel.color = this.colors.lightGreen
                infoLabel.alpha = 1

                infoLabel:register(tes3.uiEvent.help, function (ei)
                    local tooltip = tes3ui.createTooltipMenu()
                    if not config.data.journal.info.tooltip then
                        if not this.createHelpMessage(tooltip, "Click to open.", tes3.justifyText.left) then
                            tooltip:destroy()
                        end
                        return
                    else
                        this.createHelpMessage(tooltip, "Click to open.")
                    end
                    this.drawQuestInfoMenu(tooltip, questId, questIndex, quest)
                end)

                infoLabel:register(tes3.uiEvent.mouseClick, function (ei)
                    local el = menuContainer.draw("Info")
                    this.drawQuestInfoMenu(el, questId, questIndex, quest)
                    menuContainer.centerToCursor(el)
                end)
            end

            if config.data.journal.requirements.enabled then
                local mapLabel = block:createImage{ id = journalMenu.mapIcon, path = "textures\\diject\\quest guider\\journalIcon64x64.dds" }
                mapLabel.imageScaleX = 0.25
                mapLabel.imageScaleY = 0.25
                mapLabel.color = {0.9, 0.9, 0.9}

                makeLabelSelectable(mapLabel)

                mapLabel:register(tes3.uiEvent.help, function (ei)
                    local tooltip = tes3ui.createTooltipMenu()
                    tooltip.autoWidth = true
                    if not config.data.journal.requirements.tooltip then
                        if not this.createHelpMessage(tooltip, "Click to open. / Shift+Click to track the quest objects.", tes3.justifyText.left) then
                            tooltip:destroy()
                        end
                        return
                    else
                        this.createHelpMessage(tooltip, "Click to open. / Shift+Click to track the quest objects.")
                    end
                    if not drawRequirementMenu(tooltip, questId, questIndex, quest) then
                        tooltip:destroy()
                    end
                end)
                mapLabel:register(tes3.uiEvent.mouseClick, function (ei)
                    if tes3.worldController.inputController:isShiftDown() then
                        trackingLib.trackQuestsbyQuestId(questId)
                        return
                    end

                    local el, buttonBlock = menuContainer.draw("Requirements", createTrackAllButton)

                    if not el or not buttonBlock then return end

                    if not drawRequirementMenu(el, questId, questIndex, quest) then
                        el:destroy() ---@diagnostic disable-line: need-check-nil
                        return
                    end
                    menuContainer.centerToCursor(el)
                end)
            end

            ::continue::
        end

        ::continue::
    end
end


function this.addAllQuestsButton()
    if not config.data.journal.requirements.enabled and not config.data.journal.info.enabled then
        return
    end

    local menu = tes3ui.findMenu("MenuJournal")
    if not menu then return end

    if menu:findChild(journalMenu.requirementBlock) then
        return
    end

    local bookmarkTopics = menu:findChild("MenuJournal_button_bookmark_topics")
    if bookmarkTopics then
        local bookmarkPanel = bookmarkTopics.parent

        local questsImage = bookmarkPanel:createImage{ id = nil, path = "textures\\diject\\quest guider\\journalIcon64x64.dds" }
        questsImage.imageScaleX = 0.25
        questsImage.imageScaleY = 0.25
        questsImage.color = {0.9, 0.9, 0.9}

        makeLabelSelectable(questsImage)

        questsImage:reorder{ after = bookmarkTopics }

        questsImage:register(tes3.uiEvent.mouseClick, function (e)
            local el, buttonBlock = menuContainer.draw("Quests", function (menuEl, buttonBlock)
                this.createContainerButtons(nil, menuEl, buttonBlock, { trackCurrentBtn = false })
            end)
            if not el then return end

            this.drawQuestsMenu(el)

            el:getTopLevelMenu():updateLayout()
        end)
    end
end


this.drawRequirementMenu = drawRequirementMenu

return this