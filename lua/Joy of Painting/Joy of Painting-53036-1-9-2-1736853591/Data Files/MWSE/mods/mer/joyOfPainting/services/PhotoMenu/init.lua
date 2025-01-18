--[[
    Service for taking a photo. Includes toggling shaders,
    adjusting Zoom etc
]]

local ImageBuilder = require("mer.joyOfPainting.services.Image.ImageBuilder")
local ShaderService = require("mer.joyOfPainting.services.ShaderService")
local Subject = require("mer.joyOfPainting.items.Subject")
local Painting = require("mer.joyOfPainting.items.Painting")
local config = require("mer.joyOfPainting.config")
local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("PhotoMenu")
local occlusionTesterLogger = common.createLogger("OcclusionTester")
local GUID = require("mer.joyOfPainting.services.GUID")
local UIHelper = require("mer.joyOfPainting.services.UIHelper")
local SkillService = require("mer.joyOfPainting.services.SkillService")
local PaintService = require("mer.joyOfPainting.services.PaintService")
local ArtStyle = require("mer.joyOfPainting.items.ArtStyle")
local OcclusionTester = require("mer.joyOfPainting.services.subjectCapture.OcclusionTester")
local SubjectService = require("mer.joyOfPainting.services.subjectCapture.SubjectService")
local ZoomSlider = require("mer.joyOfPainting.services.PhotoMenu.ZoomSlider")
local ImageLib = require("imagelib")

local alwaysOnShaders


---@class JOP.PhotoMenu.newParams
---@field artStyle JOP.ArtStyle.data
---@field getCanvasConfig fun():JOP.Canvas
---@field doRotate? function
---@field captureCallback? function
---@field closeCallback? function
---@field cancelCallback? function
---@field finalCallback? function
---@field controls string[]?
---@field colorPickers string[]?

---@class JOP.PhotoMenu : JOP.PhotoMenu.newParams
---@field artStyle JOP.ArtStyle
---@field controls string[]
---@field subjects table<string, JOP.SubjectService.Result>
---@field location JOP.Painting.location
---@field canvasConfig JOP.Canvas
---@field painting JOP.Painting
---@field shaders JOP.ArtStyle.shader[]?
---@field isLooking boolean? default false
local PhotoMenu = {
    shaders = nil,
    isLooking = false
}
PhotoMenu.menuID = "TJOP.PhotoMenu"

local function getpaintingTexture()
    return GUID.generate() .. ".dds"
end


---comment
---@param photoMenuParams JOP.PhotoMenu.newParams
---@return any
function PhotoMenu:new(photoMenuParams)
    alwaysOnShaders = {
        config.shaders.window,
    }
    logger:debug("Creating new PhotoMenu")
    ---@type JOP.PhotoMenu
    local o = setmetatable(photoMenuParams, self)
    self.__index = self

    o.canvasConfig = photoMenuParams.getCanvasConfig()
    o.artStyle = ArtStyle:new(photoMenuParams.artStyle)

    --Add controls
    o.controls = {}
    if o.artStyle and o.artStyle.controls then
        for _, control in ipairs(o.artStyle.controls) do
            table.insert(o.controls, control)
        end
    end

    --Add color pickers
    o.colorPickers = {}
    if o.artStyle and o.artStyle.colorPickers then
        for _, colorPicker in ipairs(o.artStyle.colorPickers) do
            table.insert(o.colorPickers, colorPicker)
        end
    end

    --add shaders
    o.shaders = {}
    for _, shader in ipairs(alwaysOnShaders) do
        table.insert(o.shaders, shader)
    end
    if o.artStyle and o.artStyle.shaders then
        logger:debug("artStyle has shaders")
        for _, shader in ipairs(o.artStyle.shaders) do
            logger:debug("Adding shader %s", shader.id)
            table.insert(o.shaders, shader)
            --Insert always on controls
            if shader.defaultControls then
                for _, control in ipairs(shader.defaultControls) do
                    table.insert(o.controls, control)
                end
            end
            if shader.defaultColorPickers then
                for _, colorPicker in ipairs(shader.defaultColorPickers) do
                    table.insert(o.colorPickers, colorPicker)
                end
            end
        end
    end

    --Using lfs, create a link from the canvas texture to jop/composite_tex.dds
    local compositeTexPath = "Data Files\\Textures\\jop\\composite_tex.dds"
    --Delete the current compositeTexPath file if it exists
    if lfs.attributes(compositeTexPath) then
        logger:debug("Deleting existing composite texture")
        local success, errReason = os.remove( tes3.installDirectory .. "\\" .. compositeTexPath)
        if not success then
            logger:error("Failed to delete composite texture: %s", errReason)
        end
    end

    local canvasTexPath = common.getCanvasTexture(o.canvasConfig.canvasTexture)
    logger:debug("Creating composite texture link from %s to %s", canvasTexPath, compositeTexPath)

    ImageLib.Image.fromPath(canvasTexPath):save(compositeTexPath)
    --reload the composite shader
    ShaderService.reload("jop_composite")

    return o
end

---@return table<string, JOP.SubjectService.Result>
function PhotoMenu:calculateSubjectResults()
    local occlusionTester = OcclusionTester.new{
        logger = occlusionTesterLogger,
        viewportAspectResolution = PaintService.getAspectRatio(self.canvasConfig),
        viewportScale = 0.8
    }
    local subjectService = SubjectService.new{
        occlusionTester = occlusionTester,
    }
    local subjects = subjectService:getSubjects()
    logger:debug("Found %s subjects", table.size(subjects))
    return subjects
end

function PhotoMenu:calculateLocation()
    self.location = {
        cellId = tes3.player.cell.id:lower(),
        regionId = tes3.player.cell.region and tes3.player.cell.region.id:lower(),
        cellName = tes3.player.cell.displayName,
        position = tes3.player.position:copy(),
    }
end

function PhotoMenu:getImageBuilder()
    local paintingTexture = getpaintingTexture()
    logger:debug("Painting name: %s", paintingTexture)
    local imageData = {
        savedPaintingPath = "Data Files\\" .. PaintService.getSavedPaintingPath(self.artStyle),
        paintingPath = "Data Files\\" .. PaintService.getPaintingTexturePath(paintingTexture),
        canvasConfig = self.canvasConfig,
        iconSize = 32,
        iconBorder = 3,
        iconPath = config.locations.paintingIconsDir .. paintingTexture,
        framedIconPath = config.locations.paintingIconsDir .. "f_" .. paintingTexture,
        framePath = config.locations.frameIconsDir .. "frame_square.dds",
    }

    local builder = ImageBuilder:new(imageData)
        :registerStep("calculateSubjectResults", function(next)
            self.subjects = self:calculateSubjectResults()
            self:calculateLocation()
            timer.frame.delayOneFrame(next)
            return true
        end)
        :registerStep("doCaptureCallback", function()
            if self.captureCallback then
                logger:debug("Calling capture callback")
                self.captureCallback({
                    paintingTexture = paintingTexture,
                    subjects = self.subjects,
                    location = self.location
                })
            end
        end)
        :registerStep("incrementSavedPaintingIndex", function()
            logger:debug("Incrementing saved painting index")
            PaintService.incrementSavedPaintingIndex(self.artStyle)
        end)
        :registerStep("usePaint", function()
            logger:debug("Using paint")
            self.artStyle:usePaint()
        end)
        :registerStep("startPainting", function()
            logger:debug("Starting painting")
            self:hideMenu()
            self:finishMenu()
            tes3.playSound{sound = self.canvasConfig.animSound}
        end)
        :registerStep("waitForPaintingAnim", function(next)
            logger:debug("Waiting %G seconds for painting animation to finish",
                self.canvasConfig.animSpeed)
            timer.start{
                duration = self.canvasConfig.animSpeed,
                type = timer.simulate,
                callback = next
            }
            return true
        end)
        :registerStep("enableControls", function()
            logger:debug("Enabling controls")
            common.enablePlayerControls()
        end)
        :registerStep("progressSkill", function()
            SkillService.progressSkillFromPainting()
        end)
        :registerStep("namePainting", function(next)
            self.paintingName = self:getDefaultPaintingName()
            UIHelper.openPaintingMenu{
                dataHolder = self,
                paintingTexture = paintingTexture,
                tooltipText = Painting.createTooltipText(self.location, self.subjects),
                canvasId = self.canvasConfig.canvasId,
                callback = next,
                cancelCallback = self.cancelCallback,
                setNameText = "Name " .. self.artStyle.name,
            }
            return true
        end)
        :registerStep("doFinalCallback", function()
            if self.finalCallback then
                logger:debug("Calling finalCallback")
                if self.paintingName == nil or self.paintingName == "" then
                    self.paintingName = self:getDefaultPaintingName()
                end
                self.finalCallback{
                    paintingName = self.paintingName
                }
                logger:debug("Successfully captured painting.")
            end
        end)
    return builder
end

function PhotoMenu:getDefaultPaintingName()
    local paintingName = "Untitled"
    if self.subjects and table.size(self.subjects) > 0 then
        --name painting after subject with largest presence
        local maxPresence = 0
        ---@type JOP.SubjectService.Result
        local maxResult
        for _, result in pairs(self.subjects) do
            logger:debug("Subject %s: presence: %s", result.objectId, result.presence)
            if result.presence > maxPresence then
                maxPresence = result.presence
                maxResult = result
            end
        end
        if maxResult then
            logger:debug("Max presence: %s", maxPresence)
            for subjectId in pairs(maxResult.subjectIds) do
                local subject = Subject.getSubject(subjectId)
                if subject then
                    logger:debug("Setting name from subject %s", subject.id)
                    paintingName = subject.getName{
                        objectId = maxResult.objectId
                    }
                    break
                end
            end
        end
    else
        paintingName = self.location.cellName --[[@as string]]
        if paintingName:find(", ") then
            --set to after the first comma
            paintingName = paintingName:match(", (.*)")
        end
    end
    logger:debug("Default painting name: %s", paintingName)
    return paintingName
end


--[[
    Captures the current scene and saves it to a painting
]]
function PhotoMenu:capture()
    logger:debug("Capturing image")

    local builder = self:getImageBuilder()

    builder:start()
        :calculateSubjectResults()
        :takeScreenshot()
        :createWallpaper()
        :incrementSavedPaintingIndex()
        :createPaintingTexture()
        :createIcon()
        :deleteScreenshot()
        :startPainting()
        :finish()
        :doCaptureCallback()
        :waitForPaintingAnim()
        :usePaint()
        :enableControls()
        :namePainting()
        :progressSkill()
        :doFinalCallback()
        :build()
end

---@param parent tes3uiElement
function PhotoMenu:createCaptureButtons(parent)
    logger:debug("Creating capture button")
    local paintButton = parent:createButton {
        id = "JOP.CaptureButton",
        text = "Paint"
    }
    paintButton:register("mouseClick", function(e)
        self:capture()
    end)
end

function PhotoMenu:createHeader(parent)
    logger:debug("Creating header")
    parent:createLabel {
        id = "JOP.Header",
        text = "Hold Right Click to hide menu and move camera"
    }
end


---@param control JOP.ArtStyle.control
function PhotoMenu:setShaderValue(control)
    local canvasConfig = self.canvasConfig
    local shaderValue
    if control.calculate then
        local paintingSkill = SkillService.getPaintingSkillLevel()
        shaderValue = control.calculate(paintingSkill, self.artStyle, canvasConfig)
    else
        local sliderMin = control.sliderMin or 0
        local sliderMax = control.sliderMax or 100
        shaderValue = math.remap(config.persistent[control.id], sliderMin, sliderMax, control.shaderMin, control.shaderMax)
    end

    logger:debug("Setting %s to %s", control.id, shaderValue)
    ShaderService.setUniform(control.shader, control.uniform, shaderValue)
end

---@param parent any
---@param control JOP.ArtStyle.control
function PhotoMenu:createControlSlider(parent, control)
    logger:debug("Creating slider for %s", control.id)
    config.persistent[control.id] = config.persistent[control.id] or control.sliderDefault

    local sliderMin = control.sliderMin or 0
    local sliderMax = control.sliderMax or 100

    local slider = mwse.mcm.createSlider(parent, {
        label = control.name .. ": %s",
        current = control.sliderDefault,
        min = sliderMin,
        max = sliderMax,
        step = 1,
        jump = math.ceil(sliderMax / 10),
        variable = mwse.mcm.createTableVariable {
            id = control.id,
            table = config.persistent
        }
    })
    self.controlSliders = self.controlSliders or {}
    table.insert(self.controlSliders, slider)
    slider.callback = function()
        self:setShaderValue(control)
    end
end

function PhotoMenu:getControlsBlock()
    return self.menu:findChild("JOP.ControlsBlock")
end

function PhotoMenu:createControlsBlock(parent)
    local controlsBlock = parent:createBlock {id = "JOP.ControlsBlock"}
    controlsBlock.flowDirection = "top_to_bottom"
    controlsBlock.widthProportional = 1.0
    controlsBlock.autoHeight = true
    return controlsBlock
end

---@param parent tes3uiElement
---@param colorPicker JOP.ArtStyle.colorPicker
function PhotoMenu:createColorPicker(parent, colorPicker)


    if not config.persistent[colorPicker.id] then
        config.persistent[colorPicker.id] = colorPicker.defaultValue
    end

    local initialColor = config.persistent[colorPicker.id] --[[@as mwseColorTable]]
    --Fix old defaultColors
    if not(initialColor.r or initialColor.g or initialColor.b) then
        initialColor = { r = 1, g = 1, b = 1 }
    end

    logger:debug("Creating color picker %s with intial value {r:%s, g:%s, b:%s}",
        colorPicker.id, initialColor.r, initialColor.g, initialColor.b)

    local block = parent:createBlock{
        id = colorPicker.id
    }
    block.flowDirection = "top_to_bottom"
    block.widthProportional = 1.0
    block.autoHeight = true

    --header
    block:createLabel {
        text = colorPicker.name
    }
    ---@type tes3uiElement
    local pickerElement = block:createColorPicker{
        initialColor = initialColor,-- ImagePixel
        alpha = false,
        showDataRow = false,
        showSaturationSlider = false,
        showSaturationPicker = false,
        showPreviews = false,
        showOriginal = false,
    }

    local function update()
        local picker = pickerElement.widget --[[@as tes3uiColorPicker]]
        local pixel = picker:getColor()
        local color = tes3vector3.new(pixel.r, pixel.g, pixel.b)
        config.persistent[colorPicker.id] = color
        logger:debug("Setting color %s to %s", colorPicker.id, color)
        ShaderService.setUniform(colorPicker.shader, colorPicker.uniform, config.persistent[colorPicker.id])
    end
    pickerElement:register("colorChanged", update)

    update()
end

function PhotoMenu:createShaderControls(parent)
    local controlsBlock = self:getControlsBlock()
        or self:createControlsBlock(parent)
    if self.controls then
        logger:debug("Creating shader controls")
        local controls = self.controls
        for _, controlName in ipairs(controls) do
            local control = config.controls[controlName]
            if not control then
                logger:error("Control %s not found", controlName)
            else
                if not control.calculate then
                    self:createControlSlider(controlsBlock, control)
                end
                self:setShaderValue(control)
            end
        end
    end
    if self.colorPickers then
        logger:debug("Creating color pickers")
        for _, colorPickerId in ipairs(self.colorPickers) do
            local colorPicker = config.colorPickers[colorPickerId]
            if not colorPicker then
                logger:error("Color picker %s not found", colorPickerId)
            else
                logger:debug("Creating color picker %s", colorPickerId)
                self:createColorPicker(controlsBlock, colorPicker)
            end
        end
    end
end

-- Rotate the painting
function PhotoMenu:createRotateButton(parent)
    if not self.doRotate then
        return
    end
    logger:debug("Creating rotate button")
    local canvasId = self.canvasConfig.canvasId
    logger:debug("Canvas ID: %s", canvasId)
    local canvasName = tes3.getObject(canvasId).name
    logger:debug("Canvas Name: %s", canvasName)
    local button = parent:createButton {
        id = "JOP.RotateButton",
        text = "Rotate " .. canvasName
    }
    button:register("mouseClick", function(e)
        self:close()
        self:doRotate(self)
        self.canvasConfig = self.getCanvasConfig()
        self:open()
    end)
end

function PhotoMenu:resetControls()
    logger:debug("Resetting controls")
    for _, shader in ipairs(self.shaders) do
        logger:debug("- shader %s", shader.id)
    end

    for _, controlId in pairs(self.controls) do
        local control = config.controls[controlId]
        logger:debug("Control %s for shader %s", control.id, control.shader )
        config.persistent[control.id] = control.sliderDefault
        self:setShaderValue(control)
    end
    local controlsBlock = self:getControlsBlock()
    if controlsBlock then
        controlsBlock:destroyChildren()
    end
    self:createShaderControls(self.menu)
end

function PhotoMenu:createResetButton(parent)
    logger:debug("Creating reset button")
    local button = parent:createButton {
        id = "JOP.ResetButton",
        text = "Reset"
    }
    button:register("mouseClick", function(e)
        self:resetControls()
    end)
end

function PhotoMenu:createFindSubjectsButton(parent)
    logger:debug("Creating find subjects button")
    local button = parent:createButton {
        id = "JOP.FindSubjectsButton",
        text = "Find Subjects"
    }
    button:register("mouseClick", function(e)
        local subjects = self:calculateSubjectResults()

        if table.size(subjects) > 0 then
            local subjectNames = Subject.getSubjectNames(subjects)
            local subjectNamesString = "Found subjects:"
            for name in pairs(subjectNames) do
                subjectNamesString = string.format("%s\n - %s", subjectNamesString, name)
            end
            tes3.messageBox(subjectNamesString)
        else
            tes3.messageBox("No subjects found")
        end
    end)
end

function PhotoMenu:createCloseButton(parent)
    logger:debug("Creating close button")
    local button = parent:createButton {
        id = "JOP.CloseButton",
        text = "Close"
    }
    button:register("mouseClick", function(e)
        self:close()
        if self.closeCallback then
            logger:debug("Calling close callback")
            self.closeCallback()
        end
    end)
end


---@param parent tes3uiElement
function PhotoMenu:createHelpText(parent)
    logger:debug("Creating help text button")
    local border = parent:createThinBorder {
        id = "JOP.HelpTextButton",
    }
    border.autoHeight = true
    border.autoWidth = true
    border.absolutePosAlignX = 1.0
    border.absolutePosAlignY = 0.0
    border.borderAllSides = 10
    border.paddingAllSides = 5
    border.paddingLeft = 10
    border.paddingRight = 10
    local text = border:createLabel {
        text = "?",
        color = tes3ui.getPalette("header_color"),
        font = 2
    }
    if self.artStyle.helpText then
        local function onHelp()
            local tooltip = tes3ui.createTooltipMenu()
            tooltip:createLabel{ text = self.artStyle.helpText }
        end
        border:register("help", onHelp)
        text:register("help", onHelp)
    end
end

function PhotoMenu:setAspectRatio()
    local frameSize = config.frameSizes[self.canvasConfig.frameSize]
    if not frameSize then
        logger:error("Frame Size '%s' is not registered.", self.canvasConfig.frameSize)
        return
    end
    ShaderService.setUniform(
        config.shaders.window.shaderId,
        "aspectRatio",
        frameSize.aspectRatio
    )
end

function PhotoMenu:initMGESettings()
    --ZOOM
    self.zoomSlider:init()
    --PPL
    self.previousLightingMode = mge.getLightingMode()
    logger:debug("Setting previousLightingMode to: %s", table.find(mge.lightingMode, self.previousLightingMode))

    config.persistent.lightingMode = config.persistent.lightingMode or mge.getLightingMode()
    logger:debug("Setting lighting mode to: %s", table.find(mge.lightingMode, config.persistent.lightingMode))
    mge.setLightingMode(config.persistent.lightingMode)
end

function PhotoMenu:restoreMGESettings()
    logger:debug("Restoring MGE Settings")
    self.zoomSlider:restore()
    logger:debug("restoring lighting mode to: %s", table.find(mge.lightingMode, self.previousLightingMode))
    mge.setLightingMode(self.previousLightingMode)
end

function PhotoMenu:enableShaders()
    logger:debug("Enabling shaders")
    for _, shader in ipairs(self.shaders) do
        logger:debug("- shader: %s", shader.shaderId)
        ShaderService.enable(shader.shaderId)
    end
end

function PhotoMenu:disableShaders()
    logger:debug("Disabling shaders")
    for _, shader in ipairs(self.shaders) do
        logger:debug("- shader: %s", shader.shaderId)
        ShaderService.disable(shader.shaderId)
    end
end

local function isRightClickPressed(e)
    return e.button == 1
end
local hideMenuOnRightClick
function PhotoMenu:registerIOEvents()
    logger:debug("Registering IO events.")

    --When right click is held down, hide the menu
    hideMenuOnRightClick = function(e)
        if isRightClickPressed(e) then
            if self.isLooking then
                timer.frame.delayOneFrame(function()
                    self.isLooking = false
                    self:createMenu()
                end)
            else
                self.isLooking = true
                self:hideMenu()
            end
        end
    end
    self.zoomSlider:registerEvents()

    timer.frame.delayOneFrame(function()
        event.register("mouseButtonDown", hideMenuOnRightClick)
    end)

end

function PhotoMenu:unregisterIOEvents()
    logger:debug("Unregistering IO events.")
    event.unregister("mouseButtonDown", hideMenuOnRightClick)
    self.zoomSlider:unregisterEvents()
end


function PhotoMenu:createMenu()
    logger:debug("Creating Menu")
    local menu = tes3ui.createMenu {
        id = self.menuID,
        fixedFrame = true
    }
    menu.minWidth = 410
    menu.absolutePosAlignX = 0.02
    menu.absolutePosAlignY = 0.5
    self.menu = menu

    self:createHeader(menu)
    self:createHelpText(menu)
    self.zoomSlider:create(menu)
    self:createShaderControls(menu)
    self:createResetButton(menu)
    self:createRotateButton(menu)
    self:createFindSubjectsButton(menu)
    self:createCaptureButtons(menu)
    self:createCloseButton(menu)
    self.active = true
    tes3ui.enterMenuMode(menu.id)
end

function PhotoMenu:open()
    logger:debug("Opening Photo Menu")
    common.disablePlayerControls()
    self.zoomSlider = ZoomSlider:new(self)
    self:initMGESettings()
    self:createMenu()
    self:setAspectRatio()
    self:enableShaders()
    self:registerIOEvents()
    self:resetControls()
end

--Destroy the menu
function PhotoMenu:hideMenu()
    tes3ui.leaveMenuMode()
    tes3ui.findMenu(self.menuID):destroy()
    self.active = false
end

function PhotoMenu:resetControlDefaults()
    for _, controlId in pairs(self.controls) do
        local control = config.controls[controlId]
        if control.defaultValue then
            logger:debug("Resetting %s to %s", control.id, control.defaultValue)
            ShaderService.setUniform(control.shader, control.uniform, control.defaultValue)
        end
    end
end

--Destroy menu and restore all settings (shaders, controls etc)
function PhotoMenu:close()
    logger:debug("Closing Photo Menu")
    self:hideMenu()
    self:finishMenu()
    common.enablePlayerControls()
end

--Reset events, settings, shaders
function PhotoMenu:finishMenu()
    self:unregisterIOEvents()
    self:restoreMGESettings()
    self:disableShaders()
    self:resetControlDefaults()
end



return PhotoMenu
