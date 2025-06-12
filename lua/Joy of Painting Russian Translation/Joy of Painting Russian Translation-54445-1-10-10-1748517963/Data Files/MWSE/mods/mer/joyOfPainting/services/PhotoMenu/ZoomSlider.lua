local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("ZoomSlider")
local config = require("mer.joyOfPainting.config")

local useMGEZoom = true

---@class JOP.PhotoMenu.ZoomSlider
local ZoomSlider = {}

---@param photoMenu JOP.PhotoMenu
---@return JOP.PhotoMenu.ZoomSlider
function ZoomSlider:new(photoMenu)
    local o = {}
    setmetatable(o, self)
    self.photoMenu = photoMenu
    --self.camera = tes3.worldController.worldCamera.cameraData
    self.__index = self
    return o
end


--Add the slider to a parent element
---@param parent tes3uiElement
function ZoomSlider:create(parent)
    logger:debug("Creating zoom slider")
    config.persistent.zoom = config.persistent.zoom or 100
    self.slider = mwse.mcm.createSlider(parent, {
        label = "Масштаб: %s%%",
        current = config.persistent.zoom,
        min = 100,
        max = 1000,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable {
            id = "zoom",
            table = config.persistent
        }
    })
    self.slider.callback = function()
        self:updateZoom()
    end
end

function ZoomSlider:updateZoom()
    if useMGEZoom then
        mge.camera.zoom = config.persistent.zoom / 100
    else
        local zoom = (config.persistent.zoom / 100)
        local x = math.tan((math.pi / 360) * mge.camera.fov)
        local newFov = math.atan(x / zoom) * (360 / math.pi)
        self.camera.fov = newFov
    end
end


---Initialise zoom levels and MGE settings
function ZoomSlider:init()
    logger:debug("Initialising MGE Settings")
    --Enable rendering in menus so scroll wheel zoom works
    self.previousPauseRenderingInMenus = mge.render.pauseRenderingInMenus
    mge.render.pauseRenderingInMenus = false
    self.previousZoomState = mge.camera.zoomEnable
    if useMGEZoom then
        mge.camera.zoomEnable = true
        mge.camera.zoom = config.persistent.zoom / 100
    else
        self.previousFov = self.camera.fov
        mge.camera.zoom = 1
        mge.camera.zoomEnable = false
    end
end

---Restore MGE settings
function ZoomSlider:restore()
    mge.render.pauseRenderingInMenus = self.previousPauseRenderingInMenus
    mge.camera.zoomEnable = self.previousZoomState
    if useMGEZoom then
        mge.camera.zoom = 1
    else
        self.camera.fov = self.previousFov
    end
end

local scrollToZoom
local updateFOV
---Registers the IO event for scroll to zoom
function ZoomSlider:registerEvents()

    updateFOV = function()
        self:updateZoom()
    end

    --Use scroll wheel to affect zoom
    scrollToZoom = function(e)
        logger:debug("delta: %s", e.delta)
        local newVal = config.persistent.zoom + (e.delta * 0.1)
        config.persistent.zoom = math.clamp(newVal, 100, 1000)
        self:updateZoom()
        if self.photoMenu.active then
            self.slider.elements.slider.widget.current = config.persistent.zoom - 100
            self.slider.elements.slider:findChild("PartScrollBar_elevator"):triggerEvent("mouseClick")
            self.slider:update()
            self.slider.elements.slider:updateLayout()
            self.photoMenu.menu:updateLayout()
        end
        logger:debug("New Zoom after slider: %s", config.persistent.zoom)
    end
    timer.frame.delayOneFrame(function()
        event.register(tes3.event.mouseWheel, scrollToZoom)
        event.register(tes3.event.enterFrame, updateFOV)
        event.register(tes3.event.load, function()
            self:unregisterEvents()
        end)
    end)
end

---Unregister scroll event
function ZoomSlider:unregisterEvents()
    logger:debug("Unregistering IO events.")
    event.unregister(tes3.event.mouseWheel, scrollToZoom)
    event.unregister(tes3.event.enterFrame, updateFOV)
end

return ZoomSlider