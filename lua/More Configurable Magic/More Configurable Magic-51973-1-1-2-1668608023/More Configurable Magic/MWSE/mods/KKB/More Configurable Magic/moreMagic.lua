local moreConfigurableMagic = {}
moreConfigurableMagic.inputBoxes = {}
moreConfigurableMagic.clipboard = {}
moreConfigurableMagic.pasting = false
moreConfigurableMagic.activeInputBox = nil
moreConfigurableMagic.mcpDur = false
local config = require("KKB.More Configurable Magic.config")


---Create tooltip for a UI element
---@param e tes3uiElement
local function createToolTip(e, textFunction, textFunctionParams)
    e:register("help", function()
        local tooltip = tes3ui.createTooltipMenu()
        local tooltipBlock = tooltip:createBlock{}
        tooltipBlock.flowDirection = "top_to_bottom"
        tooltipBlock.autoHeight = true
        tooltipBlock.autoWidth = true
        tooltipBlock:createLabel{text=textFunction(textFunctionParams)}
        return tooltipBlock
    end)
end

local editValues = {}
---@param e tes3uiEventData
local function grabEditValues(e)
    local elem = e.source
    local editData = {}
    editData.l = elem:getPropertyInt("MenuSpellmaking_MagLow")
    editData.h = elem:getPropertyInt("MenuSpellmaking_MagHigh")
    editData.d = elem:getPropertyInt("MenuSpellmaking_Duration")
    editData.a = elem:getPropertyInt("MenuSpellmaking_Area")
    local ranges = {
        [tes3.findGMST(tes3.gmst.sRangeSelf).value] = tes3.effectRange.self,
        [tes3.findGMST(tes3.gmst.sRangeTouch).value] = tes3.effectRange.touch,
        [tes3.findGMST(tes3.gmst.sRangeTarget).value] = tes3.effectRange.target,
    }
    local lastWord = elem.children[2].children[1].text
    editData.r = ranges[lastWord:match("%s([^%s]+)$")]
    editValues = editData
end

---@param element tes3uiElement
local function focusCleaning(element)
    local name = element.name:lower()
    local msv = tes3ui.findMenu("MenuSetValues")
end

---@param e keyDownEventData
local function tabSwitch(e)
    if not config.inputField or not moreConfigurableMagic.inputBoxes[1] then
        return
    end
    if moreConfigurableMagic.activeInputBox == nil then
        moreConfigurableMagic.activeInputBox = moreConfigurableMagic.inputBoxes[1]
        local input = moreConfigurableMagic.activeInputBox
        for _, box in pairs(moreConfigurableMagic.inputBoxes) do
            box.text = box.text:gsub("|", "")
         end
        input.text = input.text .. "|"
        tes3ui.acquireTextInput(input)
        moreConfigurableMagic.activeInputBox = input
    else
        if tes3.worldController.inputController:isAltDown() then
            return
        end
        local numBoxes = #moreConfigurableMagic.inputBoxes
        local boxIndex = nil
        for i, b in pairs(moreConfigurableMagic.inputBoxes) do
            if b.name == moreConfigurableMagic.activeInputBox.name then
                boxIndex = i
                break
            end
        end
        local step = 1
        if tes3.worldController.inputController:isShiftDown() then
            step = -1
        end
        if boxIndex == 1 and step == -1 then
            boxIndex = numBoxes
        elseif boxIndex == numBoxes and step == 1 then
            boxIndex = 1
        else
            boxIndex = boxIndex + step
        end
        local input = moreConfigurableMagic.inputBoxes[boxIndex]
        for _, box in pairs(moreConfigurableMagic.inputBoxes) do
            box.text = box.text:gsub("|", "")
         end
        input.text = input.text .. "|"
        tes3ui.acquireTextInput(input)
        moreConfigurableMagic.activeInputBox = input
    end
end

---@param e keyDownEventData
local function enterDone(e)
    if tes3ui.findMenu("MenuConsole") then
        return
    end
    local msv = tes3ui.findMenu("MenuSetValues")
    if not msv then
        return
    end
    local okb = msv:findChild("MenuSetValues_OkButton")
    if okb then
        okb:triggerEvent("mouseClick")
    end
end

---@param e keyDownEventData
local function deleteDone(e)
    local msv = tes3ui.findMenu("MenuSetValues")
    if not msv then
        return
    end
    local dlb = msv:findChild("MenuSetValues_Deletebutton")
    if dlb then
        dlb:triggerEvent("mouseClick")
    end
end

---@param e keyDownEventData
local function copyShortcut(e)
    if not tes3.worldController.inputController:isControlDown() then
        return
    end
    local msv = tes3ui.findMenu("MenuSetValues")
    if not msv then
        return
    end
    local btn = msv:findChild("KKB_MCM:copyButton")
    if btn then
        btn:triggerEvent("mouseClick")
    end
end

---@param e keyDownEventData
local function pasteShortcut(e)
    if not tes3.worldController.inputController:isControlDown() then
        return
    end
    local msv = tes3ui.findMenu("MenuSetValues")
    if not msv then
        return
    end
    local btn = msv:findChild("KKB_MCM:pasteButton")
    if btn then
        btn:triggerEvent("mouseClick")
    end
end

--Make sure the player can't fuck up their menu with weird values
local function sanityCheck(x, params)
    local defaultVal = params.defaultVal or 1
    if not x then
        return defaultVal
    end
    if type(x) == "string" then
        x = x:gsub("[^0123456789]", "")
    end
    x = tonumber(x) or defaultVal
    local cap = params.cap
    if cap then
        x = math.min(x, cap)
    end
    return math.floor(math.max(x, defaultVal))
end

---@param slider tes3uiElement
local function adjustCurrentMax(slider, value, params)
    --mwse.log("Calling ADCM for: "..slider.name)
    params = params or {}
    if not params.skipMax then
        if not slider.name:lower():find("mag") then
            slider.widget.max = math.max(slider.widget.max, value)
        else
            slider:setPropertyFloat("PartScrollBar_max", math.max(config.mag, value))
        end
    end
    slider.widget.current = value
    if params.textElem and params.textPrefix then
        params.textElem.text = params.textPrefix..value
    end
    slider:triggerEvent("PartScrollBar_changed")
end

---@param element tes3uiElement
local function replaceWithTextInput(element, inputId, defaultVal, okButton, borderVal, optionalParams)
    optionalParams = optionalParams or {}
    local container = optionalParams.optionalParent or element.parent
    container.childAlignX = 0
    local borderedInput = container:createThinBorder{}
    borderedInput.height = 22
    borderedInput.borderLeft = borderVal
    borderedInput.width = 60
    local boxName = string.format("KKB_MCM:%sInput", inputId)
    local input = borderedInput:createTextInput{id=boxName, name=boxName}
    input.borderLeft = 2
    table.insert(moreConfigurableMagic.inputBoxes, input)
    if defaultVal == 1 and inputId == "duration" and (moreConfigurableMagic.mcpDur and tes3ui.findMenu("MenuSpellmaking") or tes3ui.findMenu("MenuEnchantment")) then
        defaultVal = 0
    end
    input.text = defaultVal
    input.childAlignX = 0.5
    borderedInput:registerAfter("click", function()
         for _, box in pairs(moreConfigurableMagic.inputBoxes) do
            box.text = box.text:gsub("|", "")
         end
        input.text = input.text .. "|"
        tes3ui.acquireTextInput(input)
        moreConfigurableMagic.activeInputBox = input
    end)

    input:registerAfter("keyPress", function (e)
        e.source.text = e.source.text:gsub("[^0123456789]", "")
        e.source.text = e.source.text:gsub('^0+', '')
        if e.source.text == "" then
            e.source.text = "0"
        end
        e.source.text = e.source.text .. "|"
        local defVal = 1
        if inputId == "area" or (inputId == "duration" and (moreConfigurableMagic.mcpDur and tes3ui.findMenu("MenuSpellmaking") or tes3ui.findMenu("MenuEnchantment"))) then
            defVal = 0
        end
        local setVal = sanityCheck(input.text, {defaultVal=defVal, cap=optionalParams.cap})
        local oldVal = moreConfigurableMagic.currentValues[inputId]
        if setVal ~= oldVal then
            if inputId == "high" or inputId == "low" then
                moreConfigurableMagic.currentValues[inputId] = setVal
                local topMenu = element:getTopLevelMenu()
                local lowBox = topMenu:findChild(string.format("KKB_MCM:%sInput", "low"))
                local highBox = topMenu:findChild(string.format("KKB_MCM:%sInput", "high"))
                local lowVal = sanityCheck(lowBox.text, {defaultVal=1, cap=config.mag})
                local highVal = sanityCheck(highBox.text, {defaultVal=1, cap=config.mag})
                if lowVal > highVal then
                    if inputId == "low" then
                        highVal = lowVal
                        moreConfigurableMagic.currentValues.low = lowVal
                        moreConfigurableMagic.currentValues.high = highVal
                    else
                        moreConfigurableMagic.currentValues.high = 1
                        moreConfigurableMagic.currentValues.low = 1
                        highVal = 1
                        lowVal = 1
                    end
                else
                    moreConfigurableMagic.currentValues.low = lowVal
                    moreConfigurableMagic.currentValues.high = highVal
                end
                local lowOptions = {}
                local highOptions = {}
                
                lowOptions.textElem = topMenu:findChild("MenuSetValues_MagLow")
                highOptions.textElem = topMenu:findChild("MenuSetValues_MagHigh")
                local lowSlider = topMenu:findChild("MenuSetValues_MagLowSlider")
                local highSlider = topMenu:findChild("MenuSetValues_MagHighSlider")
                lowOptions.textPrefix = ""
                highOptions.textPrefix = tes3.findGMST(tes3.gmst.sTo).value.." "
                adjustCurrentMax(lowSlider, lowVal, lowOptions)
                adjustCurrentMax(highSlider, highVal, highOptions)
            else
                moreConfigurableMagic.currentValues[inputId] = setVal
                adjustCurrentMax(element, setVal, optionalParams)
            end
        end
    end)
    element.visible = false
    return input
end

local function pasteIn(params)
    local msv = tes3ui.findMenu("MenuSetValues")
    local rangeBtn = msv:findChild("MenuSetValues_Range")
    if params.writedata.r then
        local originalText = rangeBtn.children[1].text
        rangeBtn:triggerEvent("click")
        while rangeBtn.children[1].text ~= params.writedata.r and rangeBtn.children[1].text ~= originalText do
            rangeBtn:triggerEvent("click")
        end
    end
    if params.highSlider and params.writedata.h then
        msv:findChild("MenuSetValues_MagHigh").text = string.format("%s %s", tes3.findGMST(tes3.gmst.sTo).value, params.writedata.h)
        adjustCurrentMax(params.highSlider, params.writedata.h, {textElem = params.textHigh, textPrefix = tes3.findGMST(tes3.gmst.sTo).value.." ", skipMax=params.skipMax})
        if params.hBox then
            params.hBox.text = params.writedata.h
        end
    end
    if params.lowSlider and params.writedata.l then
        msv:findChild("MenuSetValues_MagLow").text = params.writedata.l
        adjustCurrentMax(params.lowSlider, params.writedata.l, {textElem=params.textLow, textPrefix="", skipMax=params.skipMax})
        if params.lBox then
            params.lBox.text = params.writedata.l
        end
    end
    if params.durSlider and params.writedata.d then
        msv:findChild("MenuSetValues_duration").text = params.writedata.d
        adjustCurrentMax(params.durSlider, params.writedata.d, {textElem=params.textDuration, textPrefix="", skipMax=params.skipMax})
        if params.dBox then
            params.dBox.text = params.writedata.d
        end
    end
    if params.areaSlider and params.writedata.a then
        msv:findChild("MenuSetValues_area").text = params.writedata.a
        adjustCurrentMax(params.areaSlider, params.writedata.a, {textElem=params.textArea, textPrefix="", skipMax=params.skipMax})
        if params.aBox then
            params.aBox.text = params.writedata.a
        end
    end
    if config.copyStatIds then
        if params.writedata.skill then
            msv:setPropertyInt("MenuSetValues_Skills", params.writedata.skill)
        end
        if params.writedata.attribute then
            msv:setPropertyInt("MenuSetValues_Attribute", params.writedata.skill)
        end
    end
end

---@param e uiActivatedEventData
local function setSliderValues(e)
    if not e.newlyCreated then
        return
    end
    local spellmakingMenu = tes3ui.findMenu("MenuSpellmaking")
    local enchantMenu = tes3ui.findMenu("MenuEnchantment")
    local menu = spellmakingMenu or enchantMenu
    if not (menu) then
        return
    end
    
    local lowSlider = e.element:findChild("MenuSetValues_MagLowSlider")
    local highSlider = e.element:findChild("MenuSetValues_MagHighSlider")
    local durSlider = e.element:findChild("MenuSetValues_DurationSlider")
    local areaSlider = e.element:findChild("MenuSetValues_AreaSlider")
    local okButton = e.element:findChild("MenuSetValues_OkButton")
    local textLow = e.element:findChild("MenuSetValues_MagLow")
    local textHigh = e.element:findChild("MenuSetValues_MagHigh")
    local textDuration = e.element:findChild("MenuSetValues_duration")
    local textArea = e.element:findChild("MenuSetValues_area")
    local lBox, hBox, dBox, aBox
    moreConfigurableMagic.currentValues = {}
    if lowSlider and highSlider then
        moreConfigurableMagic.currentValues.low=lowSlider.widget.current
        moreConfigurableMagic.currentValues.high=highSlider.widget.current
    end
    if areaSlider then
        moreConfigurableMagic.currentValues.area=areaSlider.widget.current
    end
    if not config.inputField and next(moreConfigurableMagic.currentValues) then
        if lowSlider and lowSlider.visible then
            lowSlider:setPropertyFloat("PartScrollBar_max", sanityCheck(config.mag, {defaultVal=1}))
            lowSlider.widget.jump = sanityCheck(config.magJump, {defaultVal=1})
        end
        if highSlider and highSlider.visible then
            highSlider:setPropertyFloat("PartScrollBar_max", sanityCheck(config.mag, {defaultVal=1}))
            highSlider.widget.jump = sanityCheck(config.magJump, {defaultVal=1})
        end
        if durSlider and durSlider.visible then
            durSlider.widget.max = sanityCheck(config.duration, {defaultVal=1})
            durSlider.widget.jump = sanityCheck(config.durJump, {defaultVal=1})
        end
        if areaSlider and areaSlider.visible then
            areaSlider.widget.max = sanityCheck(config.area, {defaultVal=1})
            areaSlider.widget.jump = sanityCheck(config.areaJump, {defaultVal=1})
        end
    elseif config.inputField and next(moreConfigurableMagic.currentValues) then
        moreConfigurableMagic.inputBoxes = {}
        local rangeContainer = e.element:findChild("MenuSetValues_Range").parent
        rangeContainer.childAlignX = 0.29
        rangeContainer.borderBottom = 10
        if lowSlider and lowSlider.visible and highSlider and highSlider.visible then
            textLow.visible = false
            lBox = replaceWithTextInput(lowSlider, "low", lowSlider.widget.current, okButton, 30,
            {textElem=textLow, textPrefix="", cap=config.mag})
            textHigh.visible = false
            local dashLabel = lBox.parent.parent:createLabel{text="-"}
            dashLabel.borderLeft = 5
            dashLabel.borderRight = 5
            hBox = replaceWithTextInput(highSlider, "high", highSlider.widget.current, okButton, 3,
            {optionalParent=lBox.parent.parent, textElem = textHigh, textPrefix = tes3.findGMST(tes3.gmst.sTo).value.." ", cap=config.mag})
        end
        if durSlider and durSlider.visible then
            textDuration.visible = false
            dBox = replaceWithTextInput(durSlider, "duration", durSlider.widget.current, okButton, 41,
            {textElem=textDuration, textPrefix="", cap=config.duration})
        end
        if areaSlider and areaSlider.visible then
            textArea.visible = false
            aBox = replaceWithTextInput(areaSlider, "area", areaSlider.widget.current, okButton, 74,
            {textElem=textArea, textPrefix="", cap=config.area})
        end
    end

    if editValues and not config.inputField then
        pasteIn{
            writedata=editValues,
            highSlider = highSlider,
            lowSlider = lowSlider,
            areaSlider = areaSlider,
            durSlider = durSlider,
            textHigh = textHigh,
            textLow = textLow,
            textDuration = textDuration,
            textArea = textArea,
            hBox = hBox,
            lBox = lBox,
            dBox = dBox,
            aBox = aBox,
            skipMax=true,
        }
    end


    if config.copyPaste and next(moreConfigurableMagic.currentValues) then
        e.element.maxHeight = e.element.maxHeight + 10
        e.element.height = e.element.height + 10
        local copyButton = okButton.parent:createButton{id="KKB_MCM:copyButton", text="Copy"}
        okButton.parent.childAlignX = 0
        copyButton.borderAllSides = 0
        copyButton.borderLeft = 20
        copyButton.height = okButton.height
        copyButton.width = 25
        copyButton:registerAfter("click", function ()
            moreConfigurableMagic.clipboard = {}
            if lowSlider then
                if config.inputField then
                    moreConfigurableMagic.clipboard.l = moreConfigurableMagic.currentValues.low
                else
                    moreConfigurableMagic.clipboard.l = lowSlider.widget.current
                end
            end
            if highSlider then
                if config.inputField then
                    moreConfigurableMagic.clipboard.h = moreConfigurableMagic.currentValues.high
                else
                    moreConfigurableMagic.clipboard.h = highSlider.widget.current
                end
            end
            if durSlider then
                if config.inputField then
                    moreConfigurableMagic.clipboard.d = moreConfigurableMagic.currentValues.duration
                else
                    moreConfigurableMagic.clipboard.d = durSlider.widget.current
                end
            end
            if areaSlider then
                if config.inputField then
                    moreConfigurableMagic.clipboard.a = moreConfigurableMagic.currentValues.area
                else
                    moreConfigurableMagic.clipboard.a = areaSlider.widget.current
                end
            end
            if moreConfigurableMagic.clipboard.l and moreConfigurableMagic.clipboard.h then
                moreConfigurableMagic.clipboard.h = math.max(moreConfigurableMagic.clipboard.l, moreConfigurableMagic.clipboard.h)
            end
            local rangeBtn = e.element:findChild("MenuSetValues_Range")
            if rangeBtn and rangeBtn.children[1] then
                moreConfigurableMagic.clipboard.r = rangeBtn.children[1].text
            end
            local attribute = e.element:getPropertyInt("MenuSetValues_Attribute")
            if not tes3.worldController.inputController:isControlDown() and attribute and attribute >= 0 then
                moreConfigurableMagic.clipboard.attribute = attribute
            end
            local skill = e.element:getPropertyInt("MenuSetValues_Skills")
            if not tes3.worldController.inputController:isControlDown() and skill and skill >= 0 then
                moreConfigurableMagic.clipboard.skill = skill
            end
        end)
        createToolTip(copyButton, function(params) return "Copy effect values to clipboard." end, {})

        local pasteButton = okButton.parent:createButton{id="KKB_MCM:pasteButton", text="Paste"}
        pasteButton.borderAllSides = 0
        pasteButton.height = okButton.height
        pasteButton.width = 25
        pasteButton:registerAfter("click", function()
            pasteIn{
                writedata=moreConfigurableMagic.clipboard,
                highSlider = highSlider,
                lowSlider = lowSlider,
                areaSlider = areaSlider,
                durSlider = durSlider,
                textHigh = textHigh,
                textLow = textLow,
                textDuration = textDuration,
                textArea = textArea,
                hBox = hBox,
                lBox = lBox,
                dBox = dBox,
                aBox = aBox,
                skipMax=true,
            }
            if not tes3.worldController.inputController:isControlDown() then
                moreConfigurableMagic.pasting = true
                okButton:triggerEvent("mouseClick")
                moreConfigurableMagic.pasting = false
            end
        end)
        createToolTip(pasteButton, function()
            local defaultText = "Paste effect values from clipboard. CTRL-Click to paste without inputting."
            if not moreConfigurableMagic.clipboard or not next(moreConfigurableMagic.clipboard) then
                return defaultText
            end
            --mwse.log("T - %s %s %s %s %s", clipboard.l, clipboard.h, clipboard.d, clipboard.a, clipboard.r)
            local prefix = "\nCurrent data:"
            local magText = ""
            if moreConfigurableMagic.clipboard.l and (moreConfigurableMagic.clipboard.l == moreConfigurableMagic.clipboard.h) then
                magText = string.format(" %s %s %s", magText, moreConfigurableMagic.clipboard.l, tes3.findGMST(tes3.gmst.spoints).value)
            elseif moreConfigurableMagic.clipboard.l and (moreConfigurableMagic.clipboard.l < moreConfigurableMagic.clipboard.h) then
                magText = string.format(" %s %s %s %s %s", magText, moreConfigurableMagic.clipboard.l, tes3.findGMST(tes3.gmst.sTo).value, moreConfigurableMagic.clipboard.h, tes3.findGMST(tes3.gmst.spoints).value)
            end
            local durText = ""
            if moreConfigurableMagic.clipboard.d then
                durText = string.format(" %s %s %s", tes3.findGMST(tes3.gmst.sfor).value, moreConfigurableMagic.clipboard.d, tes3.findGMST(tes3.gmst.sseconds).value)
            end
            local areaText = ""
            if moreConfigurableMagic.clipboard.a then
                areaText = string.format(" %s %s %s", tes3.findGMST(tes3.gmst.sin).value, moreConfigurableMagic.clipboard.a, tes3.findGMST(tes3.gmst.sfeet).value)
            end
            local rangeText = ""
            if moreConfigurableMagic.clipboard.r then
                rangeText = string.format(" %s %s", tes3.findGMST(tes3.gmst.sOn).value:lower(), moreConfigurableMagic.clipboard.r)
            end
            local data = string.format("%s%s%s%s", magText, durText, areaText, rangeText)
            if config.copyStatIds then
                if moreConfigurableMagic.clipboard.attribute then
                    data = data..string.format("\n%s", tes3.getAttributeName(moreConfigurableMagic.clipboard.attribute))
                end
                if moreConfigurableMagic.clipboard.skill then
                    data = data..string.format("\n%s", tes3.getSkillName(moreConfigurableMagic.clipboard.skill))
                end
            end
            data = data:gsub("^ [a-zA-Z]+ ", " ")
            data = data:gsub("^ +", " ")
            return defaultText..prefix..data
        end)
    end
    e.element:updateLayout()
    if config.keyboardShortcuts then
        event.register("keyDown", tabSwitch, {filter = tes3.scanCode.tab})
        event.register("keyDown", enterDone, {filter = tes3.scanCode.enter})
        event.register("keyDown", enterDone, {filter = tes3.scanCode.numpadEnter})
        event.register("keyDown", deleteDone, {filter = tes3.scanCode.delete})
        event.register("keyDown", copyShortcut, {filter = tes3.scanCode.c})
        event.register("keyDown", pasteShortcut, {filter = tes3.scanCode.v})
    end

    ---@param e tes3uiEventData
    local function cancelSaveOldValues(e)
        if editValues and not moreConfigurableMagic.pasting then
            pasteIn{
                writedata=editValues,
                highSlider = highSlider,
                lowSlider = lowSlider,
                areaSlider = areaSlider,
                durSlider = durSlider,
                textHigh = textHigh,
                textLow = textLow,
                textDuration = textDuration,
                textArea = textArea,
                hBox = hBox,
                lBox = lBox,
                dBox = dBox,
                aBox = aBox,
                skipMax=true,
            }
        end
    end
    local cancelButton = e.element:findChild("MenuSetValues_Cancelbutton")
    cancelButton:registerBefore("click", cancelSaveOldValues)

    e.element:registerAfter("destroy", function ()
        moreConfigurableMagic.inputBoxes = {}
        editValues = {}
        moreConfigurableMagic.activeInputBox = nil
        if config.keyboardShortcuts then
            event.unregister("keyDown", copyShortcut, {filter = tes3.scanCode.c})
            event.unregister("keyDown", pasteShortcut, {filter = tes3.scanCode.v})
            event.unregister("keyDown", deleteDone, {filter = tes3.scanCode.delete})
            event.unregister("keyDown", enterDone, {filter = tes3.scanCode.numpadEnter})
            event.unregister("keyDown", enterDone, {filter = tes3.scanCode.enter})
            event.unregister("keyDown", tabSwitch, {filter = tes3.scanCode.tab})
        end
        local scroll
        if spellmakingMenu then
            scroll = menu:findChild("MenuSpellmaking_Scroll")
        elseif enchantMenu then
            scroll = menu:findChild("MenuEnchantment_scroll")
        end
        if not scroll then
            return
        end
        local pane = scroll:findChild("PartScrollPane_pane")
        if pane and pane.children then
            for _, effectEntry in pairs(pane.children) do
                effectEntry:registerBefore("mouseClick", grabEditValues)
            end
        end
    end)
end
event.register("uiActivated", setSliderValues, {filter="MenuSetValues"})
return moreConfigurableMagic