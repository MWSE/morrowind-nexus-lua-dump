local this = {}

local textOnOff = { [false] = "Off", [true] = "On" }
local configSpacing = 17

local function createConfigSliderPackage(params)
    local horizontalBlock = params.parent:createBlock({})
    horizontalBlock.flowDirection = "left_to_right"
    horizontalBlock.widthProportional = 1.0
    horizontalBlock.height = 30
    horizontalBlock.borderBottom = configSpacing

    local label = horizontalBlock:createLabel({ text = params.label })
    label.absolutePosAlignY = 0.5
    label.minWidth = 300

    local key = params.key
    local value = this.config[key] or params.default or 0
    
    local sliderLabel = horizontalBlock:createLabel({ text = tostring(value) })
    sliderLabel.absolutePosAlignY = 0.5
    sliderLabel.minWidth = 30

    local range = params.max - params.min

    local slider = horizontalBlock:createSlider({ current = value - params.min, max = range, step = params.step, jump = params.jump })
    slider.absolutePosAlignY = 0.5
    slider.width = 300
    slider:register("PartScrollBar_changed", function(e)
        this.config[key] = slider:getPropertyInt("PartScrollBar_current") + params.min
        sliderLabel.text = this.config[key]
        if (params.onUpdate) then
            params.onUpdate(e)
        end
    end)

    return { block = horizontalBlock, label = label, sliderLabel = sliderLabel, slider = slider }
end

function createOnOffOption(params)
    local block = params.parent:createBlock{}
    block.widthProportional = 1.0
    block.autoHeight = true
    block.borderBottom = configSpacing

    local label = block:createLabel{ text = params.label }
    label.absolutePosAlignY = 0.5
    label.minWidth = 300

    local key = params.key
    local button = block:createButton{ text = textOnOff[this.config[key]] }
    button:register("mouseClick", function(e)
        this.config[key] = not this.config[key]
        e.source.text = textOnOff[this.config[key]]
        e.source:getTopLevelMenu():updateLayout()
    end)
end

function snapOption(e, n)
    this.config.snapN = n
    
    for i, button in ipairs(this.snapButtons) do
        if (i == n) then
            -- Active state
            this.snapButtons[i].widget.state = 4
        else
            -- Normal state
            this.snapButtons[i].widget.state = 1
        end
    end

    this.pane:updateLayout()
end

function createSnapOption(parent, n, label)
    local button = parent:createButton{ text = label }
    button:register("mouseClick", function(e) snapOption(e, n) end)
    if (n == this.config.snapN) then
        -- Active state
        button.widget.state = 4
    end
    this.snapButtons[n] = button
end

local function getKeybindName(scancode)
    return tes3.findGMST(tes3.gmst.sKeyName_00 + scancode).value
end

function keybindDown(e)
    if (this.binder) then
        -- If keycode not ESC
        if (e.keyCode ~= 1) then
            this.config[this.binder.configKey] = e.keyCode
            this.binder.button.text = getKeybindName(e.keyCode)
            this.onConfigUpdate()
        end
        this.binder.button.widget.state = 1
        this.binder = nil
        this.pane:updateLayout()
    end
    
    event.unregister("keyDown", keybindDown)
end

function keybindClick(e, configKey)
    local alreadyRegistered = false
    if (this.binder) then
        this.binder.button.widget.state = 1
        alreadyRegistered = true
    end
    
    this.binder = { button = e.source, configKey = configKey }
    e.source.widget.state = 4
    this.pane:updateLayout()

    if (not alreadyRegistered) then
        event.register("keyDown", keybindDown)
    end
end

function createKeybind(parent, label, configKey)
    local block = parent:createBlock{}
    block.widthProportional = 1.0
    block.autoHeight = true
    block.borderBottom = 16
    local keybindLabel = block:createLabel{ text = label }
    keybindLabel.absolutePosAlignY = 0.5
    keybindLabel.minWidth = 300
    local button = block:createButton{ text = getKeybindName(this.config[configKey]) }
    button:register("mouseClick", function(e) keybindClick(e, configKey) end)
end

function this.onCreate(parent)
    local pane = parent:createThinBorder{}
    pane.widthProportional = 1.0
    pane.heightProportional = 1.0
    pane.paddingAllSides = 12
    pane.flowDirection = "top_to_bottom"
    this.pane = pane

    local subhead1 = pane:createLabel{ text = "quis nostrum exercitationem ullam corporis suscipit laboriosam" }
    subhead1.font = 2

    local header = pane:createLabel{ text = "Perfect Placement - from Sun's Reach Laboratorum\nversion 2.0" }
    header.color = tes3ui.getPalette("header_color")
    header.borderAllSides = 12

    local subhead2 = pane:createLabel{ text = "sed quia consequuntur magni dolores eos" }
    subhead2.font = 2
    subhead2.borderBottom = 12

    local summary = pane:createLabel{ text = "In first person view, use the [Grab / drop item] key on an item to manipulate it." }
    summary.borderBottom = 40

    createOnOffOption{
        parent = pane,
        label = "Display keybind guide",
        key = "showGuide"
    }

    createOnOffOption{
        parent = pane,
        label = "Orient to ground by default",
        key = "initialGroundAlign"
    }

    createOnOffOption{
        parent = pane,
        label = "Orient to walls by default",
        key = "initialWallAlign"
    }

    createConfigSliderPackage{
        parent = pane,
        label = "Rotate mode sensitivity",
        key = "sensitivity",
        min = 5,
        max = 50,
        step = 1,
        jump = 2
    }
    
    local optionSnap = pane:createBlock{}
    optionSnap.widthProportional = 1.0
    optionSnap.autoHeight = true
    optionSnap.borderBottom = configSpacing
    local optionSnapLabel = optionSnap:createLabel{ text = "Snap rotation mode to nearest" }
    optionSnapLabel.absolutePosAlignY = 0.5
    optionSnapLabel.minWidth = 300
    local optionSnap2 = optionSnap:createBlock{}
    optionSnap2.autoWidth = true
    optionSnap2.autoHeight = true
    
    this.snapButtons = {}
    createSnapOption(optionSnap2, 1, "90 deg")
    createSnapOption(optionSnap2, 2, "45 deg")
    createSnapOption(optionSnap2, 3, "30 deg")
    createSnapOption(optionSnap2, 4, "15 deg")
    
    createKeybind(pane, "Grab / drop item", "keybind")
    createKeybind(pane, "Rotate item", "keybindRotate")
    createKeybind(pane, "Vertical mode cycle", "keybindVertical")
    createKeybind(pane, "Orient to surface toggle", "keybindWallAlign")
    createKeybind(pane, "Snap rotation toggle", "keybindSnap")

    pane:updateLayout()
end

function this.onClose(container)
    if (this.binder) then
        this.binder = nil
        event.unregister("keyDown", keybindDown)
    end
    
    mwse.saveConfig(this.configId, this.config)
    this.onConfigUpdate()
end

return this