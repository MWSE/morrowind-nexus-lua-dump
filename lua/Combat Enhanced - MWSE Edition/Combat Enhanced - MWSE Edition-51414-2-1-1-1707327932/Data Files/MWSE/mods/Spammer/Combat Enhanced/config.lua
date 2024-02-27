local config = {}

---@param page tes3uiElement The container element,
---@param text string The text to display
---@return tes3uiElement header The newly created header.
function config.createHeader(page, text) --Creates a new Header.
    local header = page:createLabel({ text = text })
    header.color = tes3ui.getPalette(tes3.palette.bigHeaderColor)
    header.borderBottom = 5
    return header
end

---@class createOnOffButtonParams : table
---@field desc string The description text to display.
---@field modInfo tes3uiElement The element to hide when displaying the description.
---@param page tes3uiElement The container element.
---@param params createOnOffButtonParams The default parameters.
---@return tes3uiElement cycle the newly created button.
function config.createOnOffButton(page, params) --Creates an On/Off button.
    local cycleButtonDesc = params.modInfo.parent:createLabel({
        text = params.desc
    })
    cycleButtonDesc.visible = false

    local cycle = page:createCycleButton { options = { { text = "On", value = true }, { text = "Off", value = false } } }
    cycle.borderBottom = 20
    cycle:register("mouseOver", function()
        params.modInfo.visible = false
        cycleButtonDesc.visible = true
    end)
    cycle:register("mouseLeave", function()
        params.modInfo.visible = true
        cycleButtonDesc.visible = false
    end)
    return cycle
end

---@class createSliderParams : table
---@field current number The current value of the slider.
---@field max number|nil The maximum value of the slider. Defaults to 100.
---@field min number|nil The minimum value of the slider. Defaults to 0.
---@field step number|nil The change in value when clicking the right or left button. Defaults to 1.
---@field jump number|nil The change in value when clicking an empty area next to the slider handle. Defaults to 10.
---@field desc string The description text to display.
---@field modInfo tes3uiElement The element to hide when displaying the description.
---@field format string The text to display.
---@param configBlock tes3uiElement the container element.
---@param params createSliderParams The default parameters.
---@return tes3uiElement slider The newly created slider.
function config.createSlider(configBlock, params) --Creates a new Slider
    local min = params.min or 0
    local max = params.max or 100
    local sliderDesc = params.modInfo.parent:createLabel({
        text = params.desc
    })
    sliderDesc.visible = false
    local desc = configBlock:createLabel({ text = string.format(params.format, params.current + min) })
    desc.borderBottom = 1
    local slider = configBlock:createSlider { current = params.current, max = (max - min), step = (params.step or 1), jump = (params.jump or 10) }
    slider.widthProportional = 1
    slider.borderBottom = 20
    slider:registerAfter("PartScrollBar_changed", function()
        desc.text = string.format(params.format, slider.widget.current + min)
        slider:getTopLevelMenu():updateLayout()
    end)
    slider:register("mouseOver", function()
        params.modInfo.visible = false
        sliderDesc.visible = true
    end)
    slider:register("mouseLeave", function()
        params.modInfo.visible = true
        sliderDesc.visible = false
    end)
    return slider
end


---@param parent tes3uiElement
---@param horizontal boolean|nil
---@return tes3uiElement
function config.createBorderedBlock(parent, horizontal)
    local infoBlock = parent:createThinBorder()
    infoBlock.heightProportional = 1.0
    infoBlock.widthProportional = 1.0
    infoBlock.paddingAllSides = 12
    infoBlock.flowDirection = (horizontal and "left_to_right") or "top_to_bottom"
    infoBlock.wrapText = true
    return infoBlock
end


---@param parent tes3uiElement
---@param text string
---@return tes3uiElement
function config.createButton(parent, text)
    local button = parent:createButton { text = text }
    button.borderBottom = 20
    return button
end
return config
