local async = require("openmw.async")
local ui = require("openmw.ui")
local util = require("openmw.util")
local core = require("openmw.core")
local playerRef = require("openmw.self")
local input = require("openmw.input")
local I = require("openmw.interfaces")
local UI = I.UI

local commonData = require("scripts.advanced_world_map.common")
local config = require("scripts.advanced_world_map.config.configLib")
local localStorage = require("scripts.advanced_world_map.storage.localStorage")

local realTimer = require("scripts.advanced_world_map.realTimer")
local uiUtils = require("scripts.advanced_world_map.ui.utils")
local tableLib = require("scripts.advanced_world_map.utils.table")
local log = require("scripts.advanced_world_map.utils.log")

local mapTextureHandler = require("scripts.advanced_world_map.mapTextureHandler")
local eventSys = require("scripts.advanced_world_map.eventSys")
local menuMode = require("scripts.advanced_world_map.ui.menuMode")
local menuHandler = require("scripts.advanced_world_map.menuHandler")

local l10n = core.l10n(commonData.l10nKey)

local interval = require("scripts.advanced_world_map.ui.interval")
local mapWidget = require("scripts.advanced_world_map.ui.mapWidget")
local borders = require("scripts.advanced_world_map.ui.borders")
local tooltip = require("scripts.advanced_world_map.ui.tooltip")



local this = {}


this.cachedMapWidgetLayout = {}
this.cachedMapWidgetMetatable = {}

function this.clearMapWidgetCache()
    this.cachedMapWidgetLayout = {}
    this.cachedMapWidgetMetatable = {}
end


---@type advancedWorldMap.ui.menu.map
this.activeMenuMeta = nil


---@class advancedWorldMap.ui.menu.map
local menuMeta = {}
menuMeta.__index = menuMeta

menuMeta.menu = nil


---@return boolean
function menuMeta:openWidget(id)
    local widget = self.widgets[id]
    if not widget then return false end

    if self.activeWidgetId == id then
        if widget.params.onClose then widget.params.onClose(self) end
        self.widgetWindowLayout.content = ui.content{}
        self.activeWidgetId = nil
        self:updateMapWidgetWidth()
    else
        if self.activeWidgetId then
            local widgetData = self.widgets[self.activeWidgetId]
            if widgetData and widgetData.params.onClose then
                widgetData.params.onClose(self)
            end
            self.widgetWindowLayout.content = ui.content{}
            self.activeWidgetId = nil
            self:updateMapWidgetWidth()
        end

        if widget.params.onOpen then widget.params.onOpen(self, self.widgetWindowLayout.content) end
        self.activeWidgetId = id
    end

    self:updateMapWidgetWidth()
    self.mapWidget:updateMarkers()
    return true
end


function menuMeta:closeActiveWidget()
    if not self.activeWidgetId then return end

    local widgetData = self.widgets[self.activeWidgetId]
    if widgetData and widgetData.params.onClose then
        widgetData.params.onClose(self)
    end
    self.widgetWindowLayout.content = ui.content{}
    self.activeWidgetId = nil

    self:updateMapWidgetWidth()
end


---@class advancedWorldMap.ui.menu.addHeaderElement.params
---@field id string
---@field layout table
---@field onOpen fun(menu, content)?
---@field onClose fun(menu)?
---@field onClick fun(menu, event)?
---@field priority number?
---@field showWhenMenuInactive boolean?

---@param params advancedWorldMap.ui.menu.addHeaderElement.params
function menuMeta:addWidget(params)
    if not params or not params.id or not params.layout then return end
    params.priority = params.priority or 0

    local origEvents = tableLib.copy(params.layout.events or {})

    params.layout.userData = params.layout.userData or {}
    params.layout.userData[commonData.widgetPriorityField] = params.priority

    params.layout.props = params.layout.props or {}
    params.layout.props.anchor = util.vector2(0.5, 0.5)

    local pressed = false

    params.layout.events = params.layout.events or {}

    params.layout.events.focusLoss = async:callback(function(e, layout)
        pressed = false

        self.headerLayout.events.focusLoss(e, self.headerLayout)

        if origEvents.focusLoss then origEvents.focusLoss(e, layout) end
    end)

    params.layout.events.mousePress = async:callback(function(e, layout)
        if e.button == 1 then
            pressed = true
        end

        self.headerLayout.events.mousePress(e, self.headerLayout)

        if origEvents.mousePress then origEvents.mousePress(e, layout) end
    end)

    params.layout.events.mouseRelease = async:callback(function(e, layout)
        if pressed and self.headerMovedDistance <= 15 then
            if params.onClick then
                params.onClick(self, e)
            end
            if (params.onOpen or params.onClose) then
                self:openWidget(params.id)
                self:update()
            end
        end
        if e.button == 1 then
            pressed = false
        end

        self.headerLayout.events.mouseRelease(e, self.headerLayout)

        if origEvents.mouseRelease then origEvents.mouseRelease(e, layout) end
    end)

    params.layout.events.mouseMove = async:callback(function(e, layout)
        self.headerLayout.events.mouseMove(e, self.headerLayout)

        if origEvents.mouseMove then origEvents.mouseMove(e, layout) end
    end)


    self.widgets[params.id] = {layout = params.layout, params = params}

    local function addWidget(content)
        local removedIndex = uiUtils.removeFromContent(content, params.id)
        if removedIndex then
            uiUtils.removeFromContent(content, removedIndex)
        end

        local index = #content + 1
        for i, el in ipairs(content) do
            local elPriority = el.userData and el.userData[commonData.widgetPriorityField]
            if elPriority then
                if params.priority > elPriority then
                    index = i
                    break
                end
            end
        end

        content:insert(index, interval(self.params.fontSize, 0))
        content:insert(index, params.layout)
    end

    addWidget(self.widgetActiveHeaderLayout.content)

    if params.showWhenMenuInactive then
        addWidget(self.widgetInactiveHeaderLayout.content)
    end
end


function menuMeta:isWidgetActive(id)
    return self.activeWidgetId == id
end


function menuMeta:hasActiveWidget()
    return self.activeWidgetId ~= nil
end


---@param cellId string?
---@return table? layout
---@return advancedWorldMap.ui.mapWidgetMeta? meta
---@return boolean? isNew
function menuMeta:getMapWidgetForCell(cellId)
    local cellKeyId = cellId or commonData.exteriorMapId

    local isNew = false
    if not this.cachedMapWidgetLayout[cellKeyId] then
        this.cachedMapWidgetLayout[cellKeyId], this.cachedMapWidgetMetatable[cellKeyId] = mapWidget.new{
            updateFunc = self.update,
            size = self.mainSize,
            position = util.vector2(0, 0),
            cellId = cellId,
            screenPosition = self.screenPosition + util.vector2(self:getWidgetWindowWidth(), self.headerHeight),
        }
        isNew = true
    end

    local meta = this.cachedMapWidgetMetatable[cellKeyId]
    if meta then
        meta.screenPosition = self.screenPosition + util.vector2(self:getWidgetWindowWidth(), self.headerHeight)
    end

    return this.cachedMapWidgetLayout[cellKeyId], meta, isNew
end


---@return advancedWorldMap.ui.mapWidgetMeta?
function menuMeta:getCachedMapWidget(cellId)
    local cellKeyId = cellId or commonData.exteriorMapId
    return this.cachedMapWidgetMetatable[cellKeyId]
end


local function controllerYCallback()
    local self = this.activeMenuMeta
    if not self or not self.menu or not self.menu.layout or not self.mapWidget then return end
    if not menuMode.isMenuInteractive() then return end

    local layout = self.mapWidget.layout
    local userData = layout.userData
    ---@type advancedWorldMap.ui.mapElementMeta
    local lastMarker = userData.lastMarkerElement
    layout.events.mouseRelease(
        {
            position = userData.mousePos,
            offset = lastMarker and userData.additiveMouseOffset + userData.mainMouseOffset or userData.mainMouseOffset,
            button = 3,
        },
        lastMarker and lastMarker._elemLayout or layout,
        lastMarker
    )
end


---@param cellId string?
---@return boolean changed
function menuMeta:updateMapWidgetCell(cellId)
    if cellId == commonData.exteriorMapId or cellId and cellId:find(commonData.exteriorCellLabel) then cellId = nil end
    if self.mapWidget and self.mapWidget.cellId == cellId then return false end

    local lay, meta, isNew = self:getMapWidgetForCell(cellId)
    if not lay or not meta then return false end

    tooltip.destroyLast()

    if self.mapWidget then
        eventSys.triggerEvent(eventSys.EVENT.onMapClosed, {menu = self, mapWidget = self.mapWidget, cellId = self.mapWidget.cellId})
        self.mapWidget:closeRightMouseMenu()
    end

    self.mainLayout.content[1].content[2] = lay
    self.mapWidget = meta

    self.mapWidget:setUpdateFunction(self.update)
    self:updateMapWidgetWidth()

    if cellId then
        meta:setZoom(localStorage.data[commonData.localMapZoomFieldId] or 0.5)
    else
        meta:setZoom(localStorage.data[commonData.worldMapZoomFieldId] or 1)
    end

    self.mapWidget:updatePlayerMarker(self.centerOnPlayer, true)
    self.mapWidget:updateMarkers()

    if isNew then
        eventSys.triggerEvent(eventSys.EVENT.onMapInitialized, {menu = self, mapWidget = meta, cellId = cellId})
    end

    eventSys.triggerEvent(eventSys.EVENT.onMapShown, {menu = self, mapWidget = meta, cellId = cellId})

    return true
end


---@return boolean
function menuMeta:updateInteractiveElements()
    local shouldUpdate = false
    local layout = self.menu.layout
    if not layout then return shouldUpdate end

    local isMenuMode = menuMode.isMenuInteractive()
    if self.lastMenuMode == isMenuMode then
        return shouldUpdate
    else
        self.lastMenuMode = isMenuMode
    end

    local lastUIMode = UI.getMode()
    if isMenuMode and (lastUIMode ~= "Journal" and lastUIMode ~= "Interface" or (lastUIMode == "Journal" and not menuMode.isActivated())) then
        shouldUpdate = layout.props.visible ~= false or shouldUpdate
        layout.props.visible = false
        return shouldUpdate
    else
        layout.props.visible = true
    end

    local header = self.headerLayout

    if isMenuMode then
        header.props.visible = true
        header.content[1].props.alpha = config.data.ui.headerBackgroundAlpha / 100
        header.content[2] = self.widgetActiveHeaderLayout
        self.mainLayout.content[2].props.visible = true
    else
        if not localStorage.data[commonData.pinnedStateFieldId] then
            menuHandler.destroyMenu(commonData.mapMenuId)
            return shouldUpdate
        end

        header.content[1].props.alpha = 0
        header.content[2] = self.widgetInactiveHeaderLayout
        self.mainLayout.content[2].props.visible = false
        if #self.widgetInactiveHeaderLayout.content == 0 then
            header.props.visible = false
        end
        if self.mapWidget then
            self.mapWidget:closeRightMouseMenu()
        end
    end
    header.content[3].props.visible = isMenuMode

    return true
end


function menuMeta:requestUpdate()
    menuMeta._requestedUpdate = true
end


function menuMeta:getHeaderHeight()
    return self.headerHeight
end


function menuMeta:close()
    if not self.menu then return end

    if self.params.onClose then self.params.onClose() end

    self:closeActiveWidget()

    if self.mapWidget then
        eventSys.triggerEvent(eventSys.EVENT.onMapClosed, {menu = self, mapWidget = self.mapWidget, cellId = self.mapWidget.cellId})
    end

    eventSys.triggerEvent(eventSys.EVENT.onMenuClosed, {menu = self})
    this.activeMenuMeta = nil

    I.DijectKeyBindings.keybind.unregister("C_Y", controllerYCallback)

    if config.data.main.clearCacheOnClose then
        for id, _ in pairs(this.cachedMapWidgetLayout) do
            if id ~= commonData.exteriorMapId then
                this.cachedMapWidgetLayout[id] = nil
            end
        end
        for id, _ in pairs(this.cachedMapWidgetMetatable) do
            if id ~= commonData.exteriorMapId then
                this.cachedMapWidgetMetatable[id] = nil
            end
        end
    end
    mapTextureHandler.clearInteriorTextureCache()

    if config.data.main.saveVisibilityStateInInterfaceMenu then
        local isInterfaceMode = false
        for _, mode in pairs(UI.modes) do
            if mode == "Interface" then
                isInterfaceMode = true
                break
            end
        end
        if isInterfaceMode then
            localStorage.data[commonData.hideInInterfaceMenuFieldId] = true
        end
    end

    local co = coroutine.create(function ()
        self.menu:destroy()
    end)
    coroutine.resume(co)
end


---@class advencedWorldMap.ui.menu.map.create.params
---@field relativePosition any?
---@field relativeSize any?
---@field fontSize number?
---@field onClose function?


---@param params advencedWorldMap.ui.menu.map.create.params
---@return advancedWorldMap.ui.menu.map
function this.create(params)
    if not params then params = {} end

    if localStorage.data[commonData.pinnedStateFieldId] == nil then
        localStorage.data[commonData.pinnedStateFieldId] = not config.data.main.fastClose
    end

    ---@class advancedWorldMap.ui.menu.map
    local meta = setmetatable({}, menuMeta)

    meta.params = params

    if not params.fontSize then params.fontSize = config.data.ui.fontSize end
    if not params.relativeSize then
        params.relativeSize = util.vector2(config.data.main.relativeSize.x / 100, config.data.main.relativeSize.y / 100)
    end
    if not params.relativePosition then
        params.relativePosition = util.vector2(config.data.main.relativePosition.x / 100, config.data.main.relativePosition.y / 100)
    end

    local screenSize = uiUtils.getScaledScreenSize()
    meta.size = screenSize:emul(params.relativeSize)

    meta.screenPosition = params.relativePosition:emul(screenSize)

    local headerHeight = params.fontSize * 1.25
    meta.headerHeight = headerHeight
    local headerSize = util.vector2(meta.size.x, headerHeight)

    local mainSize = util.vector2(meta.size.x, meta.size.y - headerHeight)
    meta.mainSize = mainSize

    meta.centerOnPlayer = config.data.main.centerOnPlayer

    ---@type table<string, {layout : table, params : advancedWorldMap.ui.menu.addHeaderElement.params}>
    menuMeta.widgets = {}
    ---@type string?
    menuMeta.activeWidgetId = nil

    meta.widgetActiveHeaderLayout = {
        type = ui.TYPE.Flex,
        name = commonData.mapWidgetHeaderLayoutId,
        props = {
            horizontal = true,
            anchor = util.vector2(0, 0.5),
            relativePosition = util.vector2(0, 0.5),
            arrange = ui.ALIGNMENT.Center,
        },
        userData = {

        },
        content = ui.content {

        }
    }

    meta.widgetInactiveHeaderLayout = {
        type = ui.TYPE.Flex,
        name = commonData.mapWidgetHeaderLayoutId,
        props = {
            horizontal = true,
            anchor = util.vector2(0, 0.5),
            relativePosition = util.vector2(0, 0.5),
            arrange = ui.ALIGNMENT.Center,
        },
        userData = {

        },
        content = ui.content {

        }
    }

    meta.widgetWindowLayout = {
        type = ui.TYPE.Flex,
        name = commonData.mapWidgetHeaderLayoutId,
        props = {
            horizontal = true,
            position = util.vector2(2, 2),
            align = ui.ALIGNMENT.Center,
            arrange = ui.ALIGNMENT.Center,
        },
        userData = {

        },
        content = ui.content {

        }
    }

    local updateCDTimer
    local doUpdate = false
    meta.update = function ()
        if not meta.menu then return end
        if not updateCDTimer then
            eventSys.triggerEvent(eventSys.EVENT.onUpdate, {menu = meta})
            meta.menu:update()
            updateCDTimer = realTimer.newTimer(0, function ()
                updateCDTimer = nil
                if doUpdate then
                    doUpdate = false
                    meta.update()
                end
            end)
        else
            doUpdate = true
        end
    end


    local pinBtnLayout = {
        type = ui.TYPE.Widget,
        props = {
            size = util.vector2(meta.headerHeight, meta.headerHeight),
            anchor = util.vector2(0.5, 0.5),
        },
        userData = {},
        events = {
            mousePress = async:callback(function(e, layout)
                if e.button ~= 1 then return end
                layout.userData.pressed = true
            end),

            mouseRelease = async:callback(function(e, layout)
                if layout.userData.pressed and meta.headerMovedDistance <= 15 then
                    meta:togglePin()
                    meta:update()
                end
            end),
        },
        content = ui.content{
            {
                type = ui.TYPE.Image,
                props = {
                    resource = ui.texture{ path = commonData.pinIconPath },
                    alpha = localStorage.data[commonData.pinnedStateFieldId] and 1 or 0.5,
                    size = util.vector2(meta.headerHeight, meta.headerHeight) * 0.6,
                    color = localStorage.data[commonData.pinnedStateFieldId] and config.data.ui.whiteColor or
                        config.data.ui.defaultColor,
                    anchor = util.vector2(0.5, 0.5),
                    position = util.vector2(meta.headerHeight / 2, meta.headerHeight / 2),
                },
            },
            {
                type = ui.TYPE.Image,
                props = {
                    resource = uiUtils.whiteTexture,
                    alpha = 0,
                    size = util.vector2(meta.headerHeight, meta.headerHeight),
                },
            },
        }
    }

    meta.togglePin = function (self)
        local newVal = not localStorage.data[commonData.pinnedStateFieldId]
        localStorage.data[commonData.pinnedStateFieldId] = newVal
        pinBtnLayout.content[1].props.alpha = newVal and 1 or 0.5
        pinBtnLayout.content[1].props.color = newVal and config.data.ui.whiteColor or config.data.ui.defaultColor
    end


    local headerLayout = {
        type = ui.TYPE.Widget,
        props = {
            size = headerSize,
        },
        userData = {

        },
        events = {
            mousePress = async:callback(function(e, layout)
                if e.button ~= 1 then return end

                layout.userData.lastMousePos = e.position
            end),

            mouseRelease = async:callback(function(e, layout)
                local relativePos = meta.menu.layout.props.relativePosition
                config.setValue("main.relativePosition.x", relativePos.x * 100)
                config.setValue("main.relativePosition.y", relativePos.y * 100)
                layout.userData.lastMousePos = nil
                meta.headerMovedDistance = 0

                meta:update()
            end),

            mouseMove = async:callback(function(e, layout)
                if not layout.userData.lastMousePos then return end

                local props = meta.menu.layout.props

                meta.headerMovedDistance = meta.headerMovedDistance +
                    (e.position - layout.userData.lastMousePos):length()

                if meta.headerMovedDistance > 15 then
                    props.relativePosition = props.relativePosition - (layout.userData.lastMousePos - e.position):ediv(screenSize)
                    meta.screenPosition = props.relativePosition:emul(screenSize)
                    meta.mapWidget.screenPosition = meta.screenPosition + util.vector2(meta:getWidgetWindowWidth(), meta.headerHeight)
                    meta:update()
                end

                layout.userData.lastMousePos = e.position
            end),

            focusLoss = async:callback(function(_, layout)
                layout.userData.lastMousePos = nil
                meta.headerMovedDistance = 0
            end),
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = commonData.whiteTexture,
                    relativeSize = util.vector2(1, 1),
                    color = config.data.ui.backgroundColor,
                    alpha = config.data.ui.headerBackgroundAlpha / 100,
                }
            },
            menuMode.isMenuInteractive() and meta.widgetActiveHeaderLayout or meta.widgetInactiveHeaderLayout,
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    arrange = ui.ALIGNMENT.Center,
                    relativePosition = util.vector2(1, 0.5),
                    anchor = util.vector2(1, 0.5)
                },
                userData = {},
                content = ui.content{
                    pinBtnLayout,
                    interval(params.fontSize / 2, 0),
                    {
                        type = ui.TYPE.Text,
                        props = {
                            text = l10n("Close"),
                            textSize = params.fontSize * 1.4,
                            autoSize = true,
                            anchor = util.vector2(1, 0.5),
                            relativePosition = util.vector2(1, 0.5),
                            textColor = config.data.ui.defaultColor,
                            textShadow = true,
                            textShadowColor = config.data.ui.textShadowColor,
                            propagateEvents = false,
                            visible = menuMode.isMenuInteractive(),
                        },
                        userData = {},
                        events = {
                            mousePress = async:callback(function(e, layout)
                                if e.button ~= 1 then return end
                                layout.userData.pressed = true
                            end),
                            mouseRelease = async:callback(function(_, layout)
                                if layout.userData.pressed then
                                    meta:close()
                                end
                                layout.userData.pressed = false
                            end),
                        }
                    }
                },
            },
        }
    }

    meta.headerLayout = headerLayout
    meta.headerMovedDistance = 0

    meta.getWidgetWindowWidth = function (self)
        local widgetWindowWidth = 0
        for _, el in pairs(meta.widgetWindowLayout.content) do
            if el.props and el.props.size then
                widgetWindowWidth = widgetWindowWidth + el.props.size.x
            end
        end
        return widgetWindowWidth
    end

    meta.updateMapWidgetWidth = function (self)
        local widgetWindowWidth = meta:getWidgetWindowWidth()
        local mapWidgetSize = util.vector2(math.max(1, self.mainSize.x - widgetWindowWidth), self.mainSize.y)
        self.mapWidget:setSize(mapWidgetSize)
        self.mapWidget.screenPosition = self.screenPosition + util.vector2(widgetWindowWidth, headerHeight)
    end

    local mainLayout
    mainLayout = {
        type = ui.TYPE.Widget,
        props = {
            size = mainSize,
            position = util.vector2(0, headerHeight),
        },
        userData = {

        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    size = mainSize,
                    horizontal = true
                },
                userData = {

                },
                content = ui.content {
                    meta.widgetWindowLayout,
                    {
                        type = ui.TYPE.Widget,
                    },
                }
            },
            {
                type = ui.TYPE.Image,
                props = {
                    resource = uiUtils.whiteTexture,
                    alpha = 0.3,
                    size = util.vector2(config.data.ui.resizerSize, config.data.ui.resizerSize),
                    anchor = util.vector2(1, 1),
                    relativePosition = util.vector2(1, 1),
                },
                userData = {

                },
                events = {
                    mousePress = async:callback(function(e, layout)
                        layout.userData.lastMousePos = e.position
                    end),

                    mouseRelease = async:callback(function(_, layout)
                        layout.userData.lastMousePos = nil
                        meta.mapWidget:setZoom(meta.mapWidget.zoom)
                        meta:update()
                    end),

                    mouseMove = async:callback(function(e, layout)
                        local lastPos = layout.userData.lastMousePos
                        if not lastPos then return end

                        meta:closeActiveWidget()

                        local posDif = util.vector2(e.position.x - lastPos.x, e.position.y - lastPos.y)
                        local minSize = util.vector2(100, 100)

                        local mapSize = meta.mapWidget:getSize()
                        local newSize = util.vector2(math.max(minSize.x, mapSize.x + posDif.x), math.max(minSize.y, mapSize.y + posDif.y))

                        meta.mapWidget:setSize(newSize)
                        mainLayout.props.size = util.vector2(meta:getWidgetWindowWidth() + newSize.x, newSize.y)
                        meta.mainSize = mainLayout.props.size

                        local hSize = headerLayout.props.size
                        headerLayout.props.size = util.vector2(mainLayout.props.size.x, hSize.y)

                        local size = util.vector2(meta.mainSize.x, meta.mainSize.y + hSize.y)
                        meta.menu.layout.props.size = size
                        meta.size = size

                        config.setValue("main.relativeSize.x", size.x / screenSize.x * 100)
                        config.setValue("main.relativeSize.y", size.y / screenSize.y * 100)

                        eventSys.triggerEvent(eventSys.EVENT["onResized"], {
                            menu = meta,
                            size = size,
                            mapWidgetSize = newSize
                        })

                        meta:update()

                        layout.userData.lastMousePos = e.position
                    end),
                },
            },
            borders(),
        },
    }

    meta.mainLayout = mainLayout

    if meta.centerOnPlayer then
        meta:updateMapWidgetCell(not playerRef.cell.isExterior and playerRef.cell.id or nil)
    else
        meta:updateMapWidgetCell(localStorage.data[commonData.lastCellIdFieldId])
        meta.mapWidget:focusOnWorldPosition(localStorage.data[commonData.lastMapPosFieldId] or util.vector2(0, 0))
        meta.mapWidget:updateMarkers()
    end

    local layout = {
        type = ui.TYPE.Widget,
        layer = "Windows",
        props = {
            size = meta.size,
            relativePosition = params.relativePosition,
        },
        userData = {
            meta = meta,
        },
        content = ui.content {
            headerLayout,
            mainLayout,
        }
    }

    meta.menu = ui.create(layout)
    this.activeMenuMeta = meta


    local function onMouseWheelCallback(content, value)
        for _, dt in pairs(content) do
            if not type(dt) == "table" then goto continue end
            if dt.userData and dt.userData.onMouseWheel then
                dt.userData.onMouseWheel(value)
            end

            if dt.content then
                onMouseWheelCallback(dt.content, value)
            end

            ::continue::
        end
    end

    meta.onMouseWheel = function (self, vertical)
        local layout = meta.menu.layout
        if not layout or not menuMode.isMenuInteractive() then return end
        onMouseWheelCallback(layout.content, vertical)
    end

    meta.onControllerScroll = function (self, vertical)
        if not config.data.input.gamepadControls or
                (meta:hasActiveWidget() and not meta.mapWidget:isInFocus()) then
            meta.onMouseWheel(self, vertical)
        end
    end


    if config.data.input.gamepadControls then
        local gamepadControlsRealTimer

        local function updateRealTimerCallback()
            if not meta.menu.layout then return end
            if not menuMode.isMenuInteractive() or
                    (meta:hasActiveWidget() and not meta.mapWidget:isInFocus()) then
                goto continue

            end

            do
                local rAxisX = input.getAxisValue(input.CONTROLLER_AXIS.RightX)
                local rAxisY = input.getAxisValue(input.CONTROLLER_AXIS.RightY)
                local lTrigger
                if config.data.input.gamepadControlsBumperMode then
                    lTrigger = input.isControllerButtonPressed(input.CONTROLLER_BUTTON.LeftShoulder) and 0.75 or 0
                else
                    lTrigger = input.getAxisValue(input.CONTROLLER_AXIS.TriggerLeft)
                end
                local rTrigger
                if config.data.input.gamepadControlsBumperMode then
                    rTrigger = input.isControllerButtonPressed(input.CONTROLLER_BUTTON.RightShoulder) and 0.75 or 0
                else
                    rTrigger = input.getAxisValue(input.CONTROLLER_AXIS.TriggerRight)
                end

                local hasAxisInput = math.abs(rAxisX) > 0.25 or math.abs(rAxisY) > 0.25
                local hasTriggerInput = lTrigger > 0.25 or rTrigger >= 0.25

                if not hasAxisInput and not hasTriggerInput then
                    goto continue
                end

                local zoom = meta.mapWidget.zoom

                if hasAxisInput then
                    local centerPos = meta.mapWidget:getWorldPositionOfVisibleCenter()

                    if math.abs(rAxisX) > 0.25 then
                        centerPos = util.vector2(centerPos.x + rAxisX * 16384 / zoom, centerPos.y)
                    end
                    if math.abs(rAxisY) > 0.25 then
                        centerPos = util.vector2(centerPos.x, centerPos.y - rAxisY * 16384 / zoom)
                    end

                    meta.mapWidget:focusOnWorldPosition(centerPos)
                end

                if hasTriggerInput then
                    if lTrigger > 0.25 then
                        zoom = zoom * (1 - 0.25 * lTrigger)
                        meta.mapWidget:setZoom(zoom)
                    elseif rTrigger > 0.25 then
                        zoom = zoom * (1 + 0.25 * rTrigger)
                        meta.mapWidget:setZoom(zoom)
                    end
                end

                meta.mapWidget:refreshVisibleArea()
                meta.update()
            end

            ::continue::
            gamepadControlsRealTimer = realTimer.newTimer(0.1, updateRealTimerCallback)
        end
        updateRealTimerCallback()
    end

    local func
    func = function ()
        if meta.menu.layout then
            if meta.mapWidget:updatePlayerMarker(meta.centerOnPlayer) or meta._requestedUpdate then
                meta:update()
                meta._requestedUpdate = false
            end
            async:newUnsavableSimulationTimer(1 / config.data.main.updateFrequency, func)
        end
    end
    async:newUnsavableSimulationTimer(1 / config.data.main.updateFrequency, func)

    I.DijectKeyBindings.keybind.register("C_Y", controllerYCallback, 100)

    eventSys.triggerEvent(eventSys.EVENT["onMenuOpened"], {menu = meta})

    return meta
end


local togglePinActionFunc

eventSys.registerHandler(eventSys.EVENT.onMenuOpened, function (e)

    if config.data.main.saveVisibilityStateInInterfaceMenu then
        local isInterfaceMode = false
        for _, mode in pairs(UI.modes) do
            if mode == "Interface" then
                isInterfaceMode = true
                break
            end
        end
        if isInterfaceMode then
            localStorage.data[commonData.hideInInterfaceMenuFieldId] = false
        end
    end

    togglePinActionFunc = function ()
        e.menu:togglePin()
        if not localStorage.data[commonData.pinnedStateFieldId] and not menuMode.isMenuInteractive() then
            menuHandler.destroyMenu(commonData.mapMenuId)
            return true
        end
        e.menu:update()
    end

    I.DijectKeyBindings.action.register(commonData.togglePinKeyId, togglePinActionFunc)
end, 10000)

eventSys.registerHandler(eventSys.EVENT.onMenuClosed, function (e)
    I.DijectKeyBindings.action.unregister(commonData.togglePinKeyId, togglePinActionFunc)
end, 10000)

eventSys.registerHandler(eventSys.EVENT.onMapClosed, function (e)
    localStorage.data[commonData.lastCellIdFieldId] = e.mapWidget.cellId
    localStorage.data[commonData.lastMapPosFieldId] = e.mapWidget:getWorldPositionOfVisibleCenter()
end, 10000)




return this