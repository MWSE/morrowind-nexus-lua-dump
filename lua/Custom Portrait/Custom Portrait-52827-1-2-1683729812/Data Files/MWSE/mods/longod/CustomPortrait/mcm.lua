---@class ModConfig
local modConfig = {
    characterProfile = nil, ---@type PortraitProfile?
}

local settings = require("longod.CustomPortrait.config")
local validator = require("longod.CustomPortrait.validator")

local indent = 16
local spacing = 4

local guidOuterContainer = tes3ui.registerID("CP:OuterContainer")
local guidInnerContainer = tes3ui.registerID("CP:InnerContainer")
local guidButton = tes3ui.registerID("CP:Button")
local guidLabel = tes3ui.registerID("CP:Label")
local guidTextInputLabel = tes3ui.registerID("CP:TextInput")
local guidSlider = tes3ui.registerID("CP:Slider")
local guidContainer = tes3ui.registerID("CP:Container")
local guidBorder = tes3ui.registerID("CP:Border")
local guidImage = tes3ui.registerID("CP:Image")
local guidScrollPane = tes3ui.registerID("CP:ScrollPane")
local guidDivider = tes3ui.registerID("CP:Divider")

---@param parentBlock tes3uiElement
---@return tes3uiElement
local function CreateOuterContainer(parentBlock)
    local outerContainer = parentBlock:createBlock({ id = guidOuterContainer })
    outerContainer.flowDirection = tes3.flowDirection.topToBottom
    outerContainer.widthProportional = 1.0
    outerContainer.autoHeight = true
    outerContainer.borderAllSides = spacing
    outerContainer.borderLeft = indent
    return outerContainer
end

---@param parentBlock tes3uiElement
---@return tes3uiElement
local function CreateInnerContainer(parentBlock)
    local innerContainer = parentBlock:createBlock({ id = guidInnerContainer })
    innerContainer.widthProportional = parentBlock.widthProportional
    innerContainer.autoWidth = parentBlock.autoWidth
    innerContainer.heightProportional = parentBlock.heightProportional
    innerContainer.autoHeight = parentBlock.autoHeight
    innerContainer.flowDirection = tes3.flowDirection.leftToRight
    -- innerContainer.paddingAllSides = 6
    innerContainer.paddingLeft = indent
    return innerContainer
end

---@param element tes3uiElement
local function ContentsChanged(element)
    if element and element.widget and element.widget.contentsChanged then
        local widget = element.widget ---@cast widget tes3uiScrollPane
        widget:contentsChanged()
    end
end

---@param bool boolean
---@return string
local function GetYesNo(bool)
    ---@diagnostic disable-next-line: return-type-mismatch
    return bool and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value
end

---@param parentBlock tes3uiElement
---@param text string
---@param bool boolean
---@param callback fun(e: tes3uiEventData) : boolean
---@return tes3uiElement
---@return tes3uiElement
---@return tes3uiElement
---@return tes3uiElement
local function CreateButton(parentBlock, text, bool, callback)
    local outer = CreateOuterContainer(parentBlock)
    local inner = CreateInnerContainer(outer)
    local button = inner:createButton({ id = guidButton, text = GetYesNo(bool) })
    button.borderAllSides = 0
    button.borderRight = indent
    button.paddingAllSides = 2

    local label = inner:createLabel({ id = guidLabel, text = text })
    label.borderTop = 2 -- fit button

    button:register(tes3.uiEvent.mouseClick,
        ---@param e tes3uiEventData
        function(e)
            local result = callback(e)
            e.source.text = GetYesNo(result)
        end)
    return outer, inner, button, label
end

---@param parentBlock tes3uiElement
---@param text string
---@return tes3uiElement
---@return tes3uiElement
local function CreateDescription(parentBlock, text)
    local block = CreateInnerContainer(parentBlock)
    block.paddingLeft = indent * 4
    local desc = block:createLabel({ id = guidLabel, text = text })
    desc.wrapText = true
    desc.color = tes3ui.getPalette(tes3.palette.disabledColor)
    return block, desc
end

---@param content tes3uiElement
---@param scrollBar tes3uiElement
---@param profile PortraitProfile
---@param isGlobal boolean
local function CreateProfileSettings(content, scrollBar, profile, isGlobal)
    local enableField = nil ---@type tes3uiElement
    local pathField = nil ---@type tes3uiElement
    local widthField = nil ---@type tes3uiElement
    local heightField = nil ---@type tes3uiElement
    local cropField = nil ---@type tes3uiElement
    local cropValueField = nil ---@type tes3uiElement
    local previewFrame = nil ---@type tes3uiElement
    local previewImage = nil ---@type tes3uiElement

    ---@param updateLayout boolean
    local function UpdatePreview(updateLayout)
        if not validator.IsValidPath(profile.path) then
            tes3.messageBox("[Custom Portrait] Invalid Path:\n" .. profile.path)
            return
        end
        local texture = niSourceTexture.createFromPath(profile.path)
        if not validator.IsValidTextue(texture) then
            tes3.messageBox("[Custom Portrait] Invalid Image:\n" .. profile.path)
            return
        end
        -- simulate character image
        local textureWidth     = math.max(texture.width, 1)
        local textureHeight    = math.max(texture.height, 1)
        local desiredWidth     = math.max(profile.width > 0 and profile.width or textureWidth, 1)
        local desiredHeight    = math.max(profile.height > 0 and profile.height or textureHeight, 1)
        local desiredAspect    = desiredWidth / desiredHeight
        local widthRatio       = desiredWidth / textureWidth
        local heightRatio      = desiredHeight / textureHeight
        local aspectRatio      = widthRatio / heightRatio

        -- frame settings
        local border           = previewFrame
        local padding          = 4
        local aspect           = 0.5
        border.paddingAllSides = padding
        border.autoWidth       = false
        border.autoHeight      = false
        local imageHeight      = math.clamp(desiredHeight, 128, 256) -- limit
        local heightScale      = imageHeight / desiredHeight
        border.height          = imageHeight + padding * 2

        -- crop
        local minWidth         = imageHeight * aspect
        local maxWidth         = math.max(desiredWidth * heightScale, minWidth)
        border.width           = (math.lerp(minWidth, maxWidth, profile.cropWidth)) + padding * 2

        -- scale
        local image            = previewImage
        image.contentPath      = profile.path
        image.width            = imageHeight * aspect
        image.height           = imageHeight
        image.scaleMode        = false
        image.autoWidth        = true
        image.autoHeight       = true
        if aspect > desiredAspect then
            -- fit width base
            local scale = image.width / textureWidth
            image.imageScaleX = scale
            image.imageScaleY = scale / aspectRatio
        else
            -- fit height base
            local scale = image.height / textureHeight
            image.imageScaleX = scale * aspectRatio
            image.imageScaleY = scale
        end
        if updateLayout then
            image:getTopLevelMenu():updateLayout()
            ContentsChanged(scrollBar)
        end
    end

    ---@param parentBlock tes3uiElement
    ---@param text string
    ---@param numeric boolean?
    ---@param validate fun(text:string): any
    ---@return tes3uiElement
    ---@return tes3uiElement
    local function CreateInputField(parentBlock, text, numeric, validate)
        local border = parentBlock:createThinBorder()
        border.widthProportional = 1.0
        border.autoHeight = true
        border.flowDirection = tes3.flowDirection.leftToRight
        local inputField = border:createTextInput({ id = guidTextInputLabel, text = text:trim(), numeric = numeric })
        inputField.widthProportional = 1.0
        inputField.autoHeight = true
        inputField.widget.lengthLimit = nil
        inputField.widget.eraseOnFirstKey = false
        inputField.borderLeft = 5
        inputField.borderBottom = 4
        inputField.borderTop = 2
        inputField.consumeMouseEvents = false
        inputField.wrapText = true
        if not validate or validate(inputField.text) ~= nil then
            inputField.color = tes3ui.getPalette(tes3.palette.normalOverColor)
        else
            inputField.color = tes3ui.getPalette(tes3.palette.negativeColor)
        end
        return border, inputField
    end

    ---@param parentBlock tes3uiElement
    ---@return tes3uiElement
    ---@return tes3uiElement
    local function CreateInputButton(parentBlock)
        local submit = parentBlock:createButton({ id = guidButton, text = mwse.mcm.i18n("Submit") })
        submit.borderAllSides = 0
        submit.paddingAllSides = 2
        local revert = parentBlock:createButton({ id = guidButton, text = "Revert" })
        revert.borderAllSides = 0
        revert.paddingAllSides = 2
        return submit, revert
    end

    ---@param e tes3uiElement
    ---@param input tes3uiElement
    local function RegisterAcquireTextInput(e, input)
        e:register(tes3.uiEvent.mouseClick, function()
            tes3ui.acquireTextInput(input)
        end)
        if e.children then
            for _, element in ipairs(e.children) do
                RegisterAcquireTextInput(element, input)
            end
        end
    end

    local _, inner, button = CreateButton(content, "Enable Portrait", profile.enable,
        function()
            profile.enable = not profile.enable
            return profile.enable
        end)
    enableField = button
    if isGlobal then
        local _, desc = CreateDescription(inner, "If disabled, the portrait will not be used unless it is individually enabled on a character. In other words, only certain characters can use portraits.")
        desc.borderTop = 2
    else
        local _, desc = CreateDescription(inner, "If disabled, the global portrait is used for the current character.")
        desc.borderTop = 2
    end

    -- text input
    do
        local outer = CreateOuterContainer(content)
        local inner = CreateInnerContainer(outer)

        local label = inner:createLabel({ id = guidLabel, text = "Image Path" })
        label.minWidth = 96
        label.autoWidth = true
        label.autoHeight = true
        label.borderRight = indent
        label.borderTop = 2

        ---@param text string
        ---@return boolean
        local function Validate(text)
            return validator.IsValidPath(text)
        end

        local border, inputField = CreateInputField(inner, profile.path, false, Validate)
        border.borderRight = indent
        pathField = inputField

        local submit, revert = CreateInputButton(inner)
        submit.borderRight = indent

        CreateDescription(outer,
            "The path of the portrait image from 'Data Files'. Image file format must be DDS, TGA or BMP. " ..
            "And the image must have power-of-2 dimensions (i.e. 64, 128, 256, 512, 1024). " ..
            "If the aspect ratio does not match that of the image before resizing, shrink or stretch the image, or add margins. It can be adjusted in the settings described below.")

        RegisterAcquireTextInput(border, inputField)

        local backupPath = profile.path -- when opened mcm
        local function Accept()
            local text = inputField.text:trim()
            if Validate(text) then
                profile.path = text
                UpdatePreview(true)
            else
                tes3.messageBox("[Custom Portrait] Invalid Path:\n" .. profile.path)
            end
        end

        inputField:register(tes3.uiEvent.keyEnter,
            ---@param e tes3uiEventData
            function(e)
                Accept()
            end)
        inputField:register(tes3.uiEvent.keyPress,
            ---@param e tes3uiEventData
            function(e)
                e.source:forwardEvent(e)

                local text = inputField.text:trim()
                if Validate(text) then
                    inputField.color = tes3ui.getPalette(tes3.palette.normalOverColor)
                else
                    inputField.color = tes3ui.getPalette(tes3.palette.negativeColor)
                end
                inputField:getTopLevelMenu():updateLayout()
            end)

        submit:register(tes3.uiEvent.mouseClick,
            ---@param e tes3uiEventData
            function(e)
                Accept()
            end)
        revert:register(tes3.uiEvent.mouseClick,
            ---@param e tes3uiEventData
            function(e)
                --inputField.text = profile.path
                inputField.text = backupPath
                local text = inputField.text:trim()
                if Validate(text) then
                    inputField.color = tes3ui.getPalette(tes3.palette.normalOverColor)
                else
                    inputField.color = tes3ui.getPalette(tes3.palette.negativeColor)
                end
                UpdatePreview(true)
            end)
    end

    -- width height
    do
        local outer = CreateOuterContainer(content)
        local inner = CreateInnerContainer(outer)

        ---@param text string
        ---@return any
        local function Validate(text)
            local number = tonumber(text)
            if number ~= nil and number >= 0 then
                return number
            end
            return nil
        end

        do
            local label = inner:createLabel({ id = guidLabel, text = "Width" })
            label.minWidth = 96
            label.autoWidth = true
            label.autoHeight = true
            label.borderRight = indent
            label.borderTop = 2
            local border, inputField = CreateInputField(inner, tostring(profile.width), true, Validate)
            border.borderRight = indent
            widthField = inputField

            RegisterAcquireTextInput(border, inputField)

            local function Accept()
                local number = Validate(inputField.text:trim())
                if number ~= nil then
                    profile.width = math.floor(number)
                    inputField.color = tes3ui.getPalette(tes3.palette.normalOverColor)
                    UpdatePreview(true)
                else
                    inputField.color = tes3ui.getPalette(tes3.palette.negativeColor)
                end
                inputField:getTopLevelMenu():updateLayout()
            end
            inputField:register(tes3.uiEvent.keyEnter,
                ---@param e tes3uiEventData
                function(e)
                    Accept()
                end)
            inputField:register(tes3.uiEvent.keyPress,
                ---@param e tes3uiEventData
                function(e)
                    e.source:forwardEvent(e)
                    Accept()
                end)
        end
        do
            local label = inner:createLabel({ id = guidLabel, text = "Height" })
            label.minWidth = 96
            label.autoWidth = true
            label.autoHeight = true
            label.borderRight = indent
            label.borderTop = 2
            local border, inputField = CreateInputField(inner, tostring(profile.height), true, Validate)
            heightField = inputField

            RegisterAcquireTextInput(border, inputField)

            local function Accept()
                local number = Validate(inputField.text:trim())
                if number ~= nil then
                    profile.height = math.floor(number)
                    inputField.color = tes3ui.getPalette(tes3.palette.normalOverColor)
                    UpdatePreview(true)
                else
                    inputField.color = tes3ui.getPalette(tes3.palette.negativeColor)
                end
                inputField:getTopLevelMenu():updateLayout()
            end
            inputField:register(tes3.uiEvent.keyEnter,
                ---@param e tes3uiEventData
                function(e)
                    Accept()
                end)
            inputField:register(tes3.uiEvent.keyPress,
                ---@param e tes3uiEventData
                function(e)
                    e.source:forwardEvent(e)
                    Accept()
                end)
        end

        CreateDescription(outer,
            "Specifies the size of the original image for aspect ratio. " ..
            "This can adjust for the change in aspect ratio that occurs when it was changed to power-of-2 dimensions. " ..
            "When 0, dimensions are treated as the aspect ratio as is. " ..
            "The aspect ratio of the original character image is 1:2.")
    end

    -- crop
    local cropResolution = 1024
    do
        local outer = CreateOuterContainer(content)
        local inner = CreateInnerContainer(outer)

        local label = inner:createLabel({ id = guidLabel, text = "Crop Width" })
        label.minWidth = 96
        label.autoWidth = true
        label.autoHeight = true
        label.borderRight = indent
        label.borderTop = 2 -- fit button

        local slider = inner:createSlider({ id = guidSlider, current = profile.cropWidth * cropResolution, step = 1,
            jump = 16, max = cropResolution })
        slider.widthProportional = 1.0
        slider.heightProportional = 1.0
        slider.borderRight = indent
        slider.borderTop = 4
        cropField = slider

        local right = inner:createBlock({ id = guidContainer })
        right.width = 64
        right.autoHeight = true
        right.childAlignX = 1.0

        local label = right:createLabel({ id = guidLabel, text = string.format("%.3f", profile.cropWidth) })
        label.autoWidth = true
        label.autoHeight = true
        cropValueField = label

        CreateDescription(outer,
            "The ratio of the portrait width to be cropped. " ..
            "If the image is too wide, the usability of the inventory will be impaired.")

        ---@param e tes3uiEventData
        local function OnValueChanged(e)
            local val = (slider.widget.current) / cropResolution
            label.text = string.format("%.3f", val)
            val = math.clamp(val, 0.0, 1.0)
            profile.cropWidth = math.clamp(val, 0, 1)
            UpdatePreview(true)
        end

        for _, child in ipairs(slider.children) do
            child:register(tes3.uiElementType.mouseClick, OnValueChanged)  -- click, drag
            child:register(tes3.uiEvent.mouseRelease, OnValueChanged)      -- drag
            for _, gchild in ipairs(child.children) do
                gchild:register(tes3.uiEvent.mouseClick, OnValueChanged)   -- click, drag
                gchild:register(tes3.uiEvent.mouseRelease, OnValueChanged) -- drag
            end
        end

        -- need to update only value test?
        slider:register(tes3.uiEvent.partScrollBarChanged, OnValueChanged)
    end

    do
        local outer = CreateOuterContainer(content)
        local inner = CreateInnerContainer(outer)

        do
            -- test button
            local button = inner:createButton({
                id = guidButton,
                text = "Hide Preview"
            })
            button.borderAllSides = 0
            button.paddingAllSides = 2
            button:register(tes3.uiEvent.mouseClick, function(e)
                previewFrame.visible = not previewFrame.visible
                button.text = previewFrame.visible and "Hide Preview" or "Show Preview"
                previewFrame:getTopLevelMenu():updateLayout()
                ContentsChanged(scrollBar)
            end)
        end
        do
            local right = inner:createBlock({ id = guidContainer })
            right.widthProportional = 1.0
            right.autoHeight = true
            right.childAlignX = 1.0
            local button = right:createButton({ id = guidButton, text = "Reset to Default" })
            button.borderAllSides = 0
            button.paddingAllSides = 2

            ---@param input tes3uiElement
            ---@param value string|number
            local function SetInputValue(input, value)
                if input then
                    input.text = tostring(value)
                    input.color = tes3ui.getPalette(tes3.palette.normalOverColor) -- expects always valid
                end
            end

            button:register(tes3.uiEvent.mouseClick,
                ---@param e tes3uiEventData
                function(e)
                    table.copy(settings.Default().global, profile)
                    -- feedback values
                    if enableField then
                        enableField.text = GetYesNo(profile.enable)
                    end
                    SetInputValue(pathField, profile.path)
                    SetInputValue(widthField, profile.width)
                    SetInputValue(heightField, profile.height)
                    cropField.widget.current = profile.cropWidth * cropResolution
                    cropValueField.text = string.format("%.3f", profile.cropWidth)
                    UpdatePreview(true)
                end)
        end
    end
    -- preview
    do
        local outer = CreateOuterContainer(content)
        local inner = CreateInnerContainer(outer)
        local border = inner:createThinBorder({ id = guidBorder })
        border.width = 128
        border.height = 128
        local image = border:createImage({ id = guidImage })
        previewFrame = border
        previewImage = image
        UpdatePreview(false)
    end
end

---@param container tes3uiElement
function modConfig.onCreate(container)
    local pane = container:createVerticalScrollPane({ id = guidScrollPane })
    pane.widthProportional = 1.0
    pane.heightProportional = 1.0
    local content = pane:getContentElement()
    local headerColor = tes3ui.getPalette(tes3.palette.headerColor)

    local config = settings.Load()

    local characterProfileBlock ---@type tes3uiElement


    ---comment
    ---@param element tes3uiElement
    ---@param visible boolean
    local function SetVisibility(element, visible)
        if element then
            element.visible = visible
            if element.children then
                for _, child in ipairs(element.children) do
                    SetVisibility(child, visible)
                end
            end
        end
    end

    do
        local block = CreateOuterContainer(content)
        do
            local inner = CreateInnerContainer(block)
            local label = inner:createLabel({ id = guidLabel, text = "Common Settings" })
            label.color = headerColor
            inner:createDivider({ id = guidDivider }).widthProportional = 1
        end

        do
            CreateButton(block, "Enable Mod", config.enable,
                function()
                    config.enable = not config.enable
                    return config.enable
                end)
        end
        do
            local _, inner = CreateButton(block, "Use Different Portraits For Each Character", config
                .useCharacterProfile,
                function()
                    config.useCharacterProfile = not config.useCharacterProfile
                    SetVisibility(characterProfileBlock, config.useCharacterProfile)
                    container:updateLayout()
                    ContentsChanged(pane)
                    return config.useCharacterProfile
                end)
        end
    end

    -- per character profile...
    do
        local block = CreateOuterContainer(content)
        characterProfileBlock = block
        do
            local inner = CreateInnerContainer(block)
            local label = inner:createLabel({ id = guidLabel, text = "Character Portrait" })
            label.color = headerColor
            inner:createDivider({ id = guidDivider }).widthProportional = 1
        end

        if tes3.onMainMenu() then
            local outer = CreateOuterContainer(block)
            local inner = CreateInnerContainer(outer)
            inner:createLabel({ id = guidLabel, text = "Enabled In-Game" }).color = tes3ui.getPalette(tes3.palette
            .disabledColor)
        else
            modConfig.characterProfile = settings:GetCharacterProfile()
            if modConfig.characterProfile then
                CreateProfileSettings(block, pane, modConfig.characterProfile, false)
            end
        end
        SetVisibility(characterProfileBlock, config.useCharacterProfile)
    end

    -- global profile
    do
        local block = CreateOuterContainer(content)
        do
            local inner = CreateInnerContainer(block)
            local label = inner:createLabel({ id = guidLabel, text = "Global Portrait" })
            label.color = headerColor
            inner:createDivider({ id = guidDivider }).widthProportional = 1
        end
        CreateProfileSettings(block, pane, config.global, true)

        local inner, _ = CreateDescription(block,
            "Tips: Click on the armor rating at the bottom of the portrait to toggle to the rendered character image.")
        inner.paddingLeft = indent * 2
    end

    -- needs double update for proportional?
    container:getTopLevelMenu():updateLayout()
    container:getTopLevelMenu():updateLayout()
    ContentsChanged(pane)
end

---@param container tes3uiElement
function modConfig.onClose(container)
    mwse.saveConfig(settings.configPath, settings.Load())
    -- flush
    settings:SetCharacterProfile(modConfig.characterProfile)
    modConfig.characterProfile = nil
    -- re-init state
    settings.showPortrait = true
end

return modConfig
