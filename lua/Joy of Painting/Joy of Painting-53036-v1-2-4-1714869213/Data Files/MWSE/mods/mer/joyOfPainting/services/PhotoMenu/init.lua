--[[
    Service for taking a photo. Includes toggling shaders,
    adjusting Zoom etc
]]

local ImageBuilder = require("mer.joyOfPainting.services.ImageMagick.ImageBuilder")
local ShaderService = require("mer.joyOfPainting.services.ShaderService")
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

local alwaysOnShaders



---@class JOP.PhotoMenu
---@field artStyle JOP.ArtStyle
---@field canvasConfig table
---@field paintingName string
---@field captureCallback function
---@field closeCallback function
---@field cancelCallback function
---@field finalCallback function
---@field isLooking boolean? default false
local PhotoMenu = {
    shaders = nil,
    isLooking = false
}
PhotoMenu.menuID = "TJOP.PhotoMenu"

local function getpaintingTexture()
    return GUID.generate() .. ".dds"
end

function PhotoMenu:new(data)
    alwaysOnShaders = {
        config.shaders.window,
    }
    logger:debug("Creating new PhotoMenu")
    local o = setmetatable(data, self)
    self.__index = self
    o.shaders = {}
    o.artStyle = ArtStyle:new(data.artStyle)

    --add always on shaders
    for _, shader in ipairs(alwaysOnShaders) do
        table.insert(o.shaders, shader)
    end
    if data.artStyle and data.artStyle.shaders then
        logger:debug("artstyle has shaders")
        for _, shader in ipairs(data.artStyle.shaders) do
            table.insert(o.shaders, shader)
        end
    end

    return o
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
            if config.mcm.enableSubjectCapture then
                local occlusionTester = OcclusionTester.new{
                    logger = occlusionTesterLogger,
                    viewportAspectResolution = config.frameSizes[self.canvasConfig.frameSize].aspectRatio,
                    viewportScale = 0.8
                }
                local subjectService = SubjectService.new{
                    occlusionTester = occlusionTester,
                }
                local subjects = subjectService:getSubjects()
                self.subjects = subjects
                timer.frame.delayOneFrame(next)
                return true
            end
        end)
        :registerStep("doCaptureCallback", function()
            if self.captureCallback then
                logger:debug("Calling capture callback")
                self.captureCallback({
                    paintingTexture = paintingTexture,
                    subjects = self.subjects,
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
            self.paintingName = "Untitled"
            UIHelper.openPaintingMenu{
                dataHolder = self,
                paintingTexture = paintingTexture,
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
                    self.paintingName = "Untitled"
                end
                self.finalCallback{
                    paintingName = self.paintingName
                }
                logger:debug("Successfully captured painting.")
            end
        end)
        :registerArtStyle(self.artStyle)
    return builder
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
        [self.artStyle.name](builder)
        :incrementSavedPaintingIndex()
        :createPaintingTexture()
        :createIcon()
        :deleteScreenshot()
        :calculateAverageColor()
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



function PhotoMenu:setShaderValue(control)
    local shaderValue
    if control.calculate then
        local paintingSkill = SkillService.getPaintingSkillLevel()
        shaderValue = control.calculate(paintingSkill)
    else
        shaderValue = math.remap(config.persistent[control.id], 0, 100, control.shaderMin, control.shaderMax)
    end

    logger:debug("Setting %s to %s", control.id, shaderValue)
    ShaderService.setUniform(control.shader, control.uniform, shaderValue)
end

---@param parent any
---@param control JOP.ArtStyle.control
function PhotoMenu:createControlSlider(parent, control)
    logger:debug("Creating slider for %s", control.id)
    config.persistent[control.id] = config.persistent[control.id] or control.sliderDefault
    local slider = mwse.mcm.createSlider(parent, {
        label = control.name .. ": %s",
        current = control.sliderDefault,
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
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

function PhotoMenu:createShaderControls(parent)
    local controlsBlock = self:getControlsBlock()
        or self:createControlsBlock(parent)
    if not self.artStyle.controls then
        logger:debug("ArtStyle %s has no controls", self.artStyle.name)
        return
    end
    logger:debug("Creating shader controls")
    local controls = self.artStyle.controls
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

function PhotoMenu:resetControls()
    logger:debug("Resetting controls")
    for _, shader in ipairs(self.shaders) do
        logger:debug("- shader %s", shader)
    end

    ---@param control JOP.ArtStyle.control
    for _, control in pairs(config.controls) do
        logger:debug("Control %s for shader %s", control.id, control.shader )
        if table.find(self.shaders, control.shader)then
            logger:debug("ShaderService is active, Resetting %s", control.id)
            config.persistent[control.id] = control.sliderDefault
            self:setShaderValue(control)
        end
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

function PhotoMenu:setAspectRatio()
    local frameSize = config.frameSizes[self.canvasConfig.frameSize]
    if not frameSize then
        logger:error("Frame Size '%s' is not registered.", self.canvasConfig.frameSize)
        return
    end
    ShaderService.setUniform(
        config.shaders.window,
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
    for _, shaderId in ipairs(self.shaders) do
        logger:debug("- shader: %s", shaderId)
        ShaderService.enable(shaderId)
    end
end

function PhotoMenu:disableShaders()
    logger:debug("Disabling shaders")
    for _, shaderId in ipairs(self.shaders) do
        logger:debug("- shader: %s", shaderId)
        ShaderService.disable(shaderId)
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
                self.isLooking = false
                self:createMenu()
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
    menu.minWidth = 400
    menu.absolutePosAlignX = 0.02
    menu.absolutePosAlignY = 0.5
    self.menu = menu

    self:createHeader(menu)
    self.zoomSlider:create(menu)
    self:createShaderControls(menu)
    self:createResetButton(menu)
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

--Destroy menu and restore all settings (shaders, controls etc)
function PhotoMenu:close()
    logger:debug("Closing Photo Menu")
    self:hideMenu()
    timer.delayOneFrame(function()
        common.enablePlayerControls()
        self:finishMenu()
    end)
end

--Reset events, settings, shaders
function PhotoMenu:finishMenu()
    self:unregisterIOEvents()
    self:restoreMGESettings()
    self:disableShaders()
end



return PhotoMenu
