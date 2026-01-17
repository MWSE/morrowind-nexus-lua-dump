--[[
LivelyMap for OpenMW.
Copyright (C) Erin Pentecost 2025

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]
local MOD_NAME       = require("scripts.LivelyMap.ns")
local mutil          = require("scripts.LivelyMap.mutil")
local putil          = require("scripts.LivelyMap.putil")
local core           = require("openmw.core")
local util           = require("openmw.util")
local pself          = require("openmw.self")
local aux_util       = require('openmw_aux.util')
local myui           = require('scripts.LivelyMap.pcp.myui')
local camera         = require("openmw.camera")
local ui             = require("openmw.ui")
local settings       = require("scripts.LivelyMap.settings")
local async          = require("openmw.async")
local interfaces     = require('openmw.interfaces')
local storage        = require('openmw.storage')
local h3cam          = require("scripts.LivelyMap.h3.cam")
local overlapfinder  = require("scripts.LivelyMap.overlapfinder")
local fog            = require("scripts.LivelyMap.fog")

---@type MeshAnnotatedMapData?
local currentMapData = nil

local settingCache   = {
    psoUnlock       = settings.pso.psoUnlock,
    psoDepth        = settings.pso.psoDepth,
    psoPushdownOnly = settings.pso.psoPushdownOnly,
    debug           = settings.main.debug,
    fog             = settings.main.fog,
    palleteColor4   = settings.main.palleteColor4,
    palleteColor5   = settings.main.palleteColor5,
}

settings.main.subscribe(async:callback(function(_, key)
    settingCache[key] = settings.main[key]
end))
settings.pso.subscribe(async:callback(function(_, key)
    settingCache[key] = settings.pso[key]
end))

local onRenderStartHandlers = {}
local function invokeOnRenderStartHandlers()
    for _, fn in ipairs(onRenderStartHandlers) do
        local status, err = pcall(function() fn() end)
        if not status then
            print("invokeOnRenderStartHandlers() callback error: " .. tostring(err))
        end
    end
end

local function onRenderStart(fn)
    table.insert(onRenderStartHandlers, fn)
end

--- Shaders aren't available on all platforms, so do a hard hide on it.
local fogShader = nil
if settingCache.fog then
    fogShader = fog.NewFogShader()
end

---@class Icon
--- @field element any UI element.
--- @field pos fun(icon: Icon): util.vector3?
--- @field facing (fun(icon: Icon): util.vector2|util.vector3|nil)?
--- This function should always set the size of the icon if it's visible.
--- Additionally, the layout is expected to have:
--- * an anchor value of (0.5,0.5)
--- * position (not relativePosition)
--- * size (not relativeSize)
--- @field onDraw fun(icon: Icon, posData : ViewportData, parentAspectRatio : util.Vector2)
--- @field onHide fun(icon: Icon)
--- @field priority number? The higher the priority, the higher the layer.
--- @field groupable boolean? If true, the icon may be grouped or adjusted if it collides with other icons.
--- @field [string] any Other stuff might be crammed into this object. It's ok.

---@class RegisteredIcon
--- @field onScreen boolean Exists so we don't call onHide every frame.
--- @field onScreenLastRender boolean
--- @field remove boolean Remove is used to signal deletion.
--- @field ref Icon
--- @field name string Matches the layout name.

---@type RegisteredIcon[]
local icons = {}
---@type RegisteredIcon[]
local iconsPendingRegister = {}


local function hideIcon(icon)
    if icon.onScreen then
        icon.onScreen = false
        icon.ref.onHide(icon.ref)
    end
end

local mouseData = {
    dragging = false,
    clickStartViewportPos = nil,
    clickStartWorldPos = nil,
    clickStartCenterCameraWorldPos = nil,
    thousandPixelsRight = nil,
    thousandPixelsUp = nil,
    dragThreshold = 10,
}
local function mapClicked(mouseEvent, data)
    local cellPos = mutil.worldPosToCellPos(mouseData.clickStartWorldPos)
    print("click! " ..
        aux_util.deepToString(mouseEvent, 3) ..
        " worldspace: " ..
        tostring(mouseData.clickStartWorldPos) .. " cell: " .. math.floor(cellPos.x) .. "," .. math.floor(cellPos.y))
    -- need to go from world pos to cam pos now
    interfaces.LivelyMapControls.trackToWorldPosition(mouseData.clickStartWorldPos, 1)
end
local function mapClickPress(mouseEvent, data)
    if not currentMapData then
        return
    end
    mouseData.clickStartViewportPos          = mouseEvent.position
    mouseData.clickStartWorldPos             = putil.viewportPosToRealPos(currentMapData, mouseEvent.position)
    mouseData.clickStartCenterCameraWorldPos = putil.viewportPosToRealPos(currentMapData, ui.screenSize() / 2)
end
local function mapClickRelease(mouseEvent, data)
    if not currentMapData then
        return
    end
    if (mouseEvent.position - mouseData.clickStartViewportPos):length2() < mouseData.dragThreshold then
        mapClicked(mouseEvent, data)
    end
    mouseData.clickStartViewportPos = nil
    mouseData.clickStartWorldPos = nil
    mouseData.dragging = false
    mouseData.thousandPixelsRight = nil
    mouseData.thousandPixelsUp = nil
end
local function mapDragStart(mouseEvent, data)
    -- re-anchor drag start
    mouseData.clickStartViewportPos = mouseEvent.position
    mouseData.clickStartWorldPos    = putil.viewportPosToRealPos(currentMapData, mouseEvent.position)
    print("drag! " .. aux_util.deepToString(mouseEvent, 3) .. " worldspace: " .. tostring(mouseData.clickStartWorldPos))

    -- Snapshot projection basis
    -- TODO: this breaks when the offset point is not in the mesh
    local rightWorld              = putil.viewportPosToRealPos(
        currentMapData,
        mouseEvent.position + util.vector2(1000, 0)
    )

    local upWorld                 = putil.viewportPosToRealPos(
        currentMapData,
        mouseEvent.position + util.vector2(0, 1000)
    )

    mouseData.thousandPixelsRight = rightWorld - mouseData.clickStartWorldPos
    mouseData.thousandPixelsUp    = upWorld - mouseData.clickStartWorldPos
end
local function mapDragging(mouseEvent, data)
    local deltaViewport =
        mouseEvent.position - mouseData.clickStartViewportPos

    -- Convert viewport delta → world delta using frozen basis
    local deltaWorld =
        mouseData.thousandPixelsRight * (-deltaViewport.x) / 1000 +
        mouseData.thousandPixelsUp * (-deltaViewport.y) / 1000

    interfaces.LivelyMapControls.trackToWorldPosition(mouseData.clickStartCenterCameraWorldPos + deltaWorld, 0)
end
local function mapMouseMove(mouseEvent, data)
    if not currentMapData then
        return
    end
    if not mouseData.clickStartViewportPos then
        return
    end
    if (not mouseData.dragging) and (mouseEvent.position - mouseData.clickStartViewportPos):length2() >= mouseData.dragThreshold then
        mapDragStart(mouseEvent, data)
        mouseData.dragging = true
        -- the jump happens even if I return here
    end
    if not mouseData.dragging then
        return
    end

    mapDragging(mouseEvent, data)
end


local iconContainer = ui.create {
    name = "icons",
    --layer = 'Windows',
    type = ui.TYPE.Widget,
    props = {
        relativeSize = util.vector2(1, 1),
    },
    events = {
    },
    content = ui.content {},
}

local normalButtonColors = {
    default = settingCache.palleteColor5,
    over = mutil.lerpColor(settingCache.palleteColor5, util.color.rgb(1, 1, 1), 0.3),
    pressed = mutil.lerpColor(settingCache.palleteColor5, util.color.rgb(1, 1, 1), 0.5),
}
local psoButtonColors = {
    default = settingCache.palleteColor4,
    over = mutil.lerpColor(settingCache.palleteColor4, util.color.rgb(1, 1, 1), 0.3),
    pressed = mutil.lerpColor(settingCache.palleteColor4, util.color.rgb(1, 1, 1), 0.5),
}

local menuBarButtonSize = util.vector2(32, 32)

local function makeMenuButton(name, path, fn, buttonColors)
    local newButton = ui.create {}
    newButton.layout = myui.createButton(newButton,
        {
            name = name,
            type = ui.TYPE.Image,
            props = {
                anchor = util.vector2(0.5, 0.5),
                size = menuBarButtonSize,
                resource = ui.texture {
                    path = path,
                },
                color = buttonColors.default
            },
            userData = {}
        },
        function(layout, state)
            layout.props.color = buttonColors[state]
        end,
        fn, nil)
    newButton:update()
    return newButton
end

local function markerButtonFn()
    print("markerbutton clicked")
    --- position is pretty accurate so converting it to a string
    --- is basically random
    local newID = tostring(math.floor(pself.position.x)) .. "_" .. tostring(math.floor(pself.position.y)) .. "_custom"
    interfaces.LivelyMapMarker.editMarkerWindow({ id = newID })
end
local newMarkerButton = makeMenuButton("markerButton", "textures/LivelyMap/marker-button.png", markerButtonFn,
    normalButtonColors)
local function journeyButtonFn()
    print("journeybutton clicked")
    interfaces.LivelyMapJourneyIcons.toggleJourney()
end
local journeyButton = makeMenuButton("journeyButton", "textures/LivelyMap/journey-button.png", journeyButtonFn,
    normalButtonColors)

local psoReduceDepthButton = makeMenuButton("psoReduceDepthButton", "textures/LivelyMap/minus-button.png",
    function()
        settings.pso.section:set("psoDepth", math.max(0, settingCache.psoDepth - 1))
    end,
    psoButtonColors
)
local psoIncreaseDepthButton = makeMenuButton("psoIncreaseDepthButton", "textures/LivelyMap/plus-button.png",
    function()
        settings.pso.section:set("psoDepth", math.min(300, settingCache.psoDepth + 1))
    end,
    psoButtonColors
)
local psoTogglePushdownButton = makeMenuButton("psoTogglePushdownButton", "textures/LivelyMap/pushdown-button.png",
    function()
        settings.pso.section:set("psoPushdownOnly", not settingCache.psoPushdownOnly)
    end,
    psoButtonColors
)

local psoMenuButtons = ui.create {
    name = 'psoMenuButtons',
    type = ui.TYPE.Flex,
    props = {
        horizontal = true,
    },
    content = ui.content {
        myui.padWidget(10, 10),
        psoReduceDepthButton,
        psoIncreaseDepthButton,
        psoTogglePushdownButton,
    }
}

local menuBar = ui.create {
    name = 'menuBar',
    type = ui.TYPE.Container,
    template = interfaces.MWUI.templates.boxTransparent,
    props = {
        --relativePosition = util.vector2(0.5, 0.5),
        --size = util.vector2(200, 50),
        --anchor = util.vector2(0.5, 0.5),
        relativePosition = util.vector2(0.5, 0.0),
        anchor = util.vector2(0.5, 0),
        visible = true,
        propagateEvents = false,
    },
    content = ui.content {
        {
            name = 'mainV',
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
            },
            content = ui.content {
                newMarkerButton,
                myui.padWidget(10, 10),
                journeyButton,
                settingCache.psoUnlock and psoMenuButtons or nil,
            }
        }
    }
}

settings.pso.subscribe(async:callback(function(_, key)
    if key == "psoUnlock" then
        print("psoUnlock changed")
        local idx = menuBar.layout.content["mainV"].content:indexOf(psoMenuButtons)
        if settings.pso[key] and not idx then
            print("adding pso buttons. idx=" .. tostring(idx))
            menuBar.layout.content["mainV"].content:add(psoMenuButtons)
            menuBar:update()
        elseif (not settings.pso[key]) and idx then
            print("removing pso buttons. idx=" .. tostring(idx))
            menuBar.layout.content["mainV"].content[idx] = nil
            menuBar:update()
        end
    end
end))

local function newHoverBoxLayout(childLayout)
    if not childLayout then
        return { name = 'hoverBox', props = { visible = false } }
    end
    return {
        name = 'hoverBox',
        type = ui.TYPE.Container,
        template = interfaces.MWUI.templates.boxTransparent,
        props = {
            --relativePosition = util.vector2(0.5, 0.5),
            --size = util.vector2(200, 50),
            --anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.9),
            anchor = util.vector2(0.5, 1),
        },
        content = ui.content { {
            name = 'padding',
            type = ui.TYPE.Container,
            template = interfaces.MWUI.templates.padding,
            props = {},
            content = ui.content { childLayout }
        } }
    }
end

local mainWindow = nil
local hoverBox = ui.create(newHoverBoxLayout())
local pendingHoverBoxLayout = nil

local function newMainWindow()
    return ui.create {
        name = "worldmaproot",
        layer = 'Windows',
        type = ui.TYPE.Widget,
        props = {
            relativeSize = util.vector2(1, 1),
            visible = true,
        },
        events = {
            mousePress = async:callback(mapClickPress),
            mouseRelease = async:callback(mapClickRelease),
            mouseMove = async:callback(mapMouseMove),
        },
        content = ui.content { iconContainer, hoverBox, menuBar },
    }
end

--- Change hover box content.
---@param layout any UI element or layout. Set to empty or nil to clear the hover box.
local function setHoverBoxContent(layout)
    pendingHoverBoxLayout = layout
end

local function applyPendingHoverBoxContent()
    hoverBox.layout = newHoverBoxLayout(pendingHoverBoxLayout)

    if not mainWindow then
        return
    end

    -- all calls to :update() on UI elements this file owns
    -- should be done inside onUpdate() rather than directly exposed
    -- to random callers through the interface. this is because
    -- delayed UI actions can't be nested and result in fatal errors.

    hoverBox:update()
end

local function purgeRemovedIcons()
    --- check if remove is pending
    local doRemoval = false
    for _, icon in ipairs(icons) do
        if icon.remove then
            doRemoval = true
            break
        end
    end

    if not doRemoval then
        return
    end

    local remainingIcons = {}
    local remainingContent = {}

    for _, icon in ipairs(icons) do
        if not icon.remove then
            table.insert(remainingIcons, icon)
            table.insert(remainingContent, icon.ref.element)
            -- icon is responsible for destroying the UI element
        elseif settingCache.debug then
            print("Removing icon '" .. icon.name .. "'.")
        end
    end

    icons = remainingIcons
    iconContainer.layout.content = ui.content(remainingContent)
    if #remainingIcons ~= #remainingContent then
        error("mismatch between icons list and icons container content")
    end
end


---@param icon RegisteredIcon
---@return RectExtent
local function getIconExtent(icon)
    -- assumes anchor is 0.5,0.5
    -- THIS WILL NOT WORK because sizes are absolute, not relative.
    local halfSize = icon.ref.element.layout.props.relativeSize / 2
    return {
        topLeft = icon.ref.element.layout.props.relativePosition - halfSize,
        bottomRight = icon.ref.element.layout.props.relativePosition + halfSize,
    }
end

---Modify the icon locations so they don't overlap so much.
---@param iconList RegisteredIcon[]
local function pushOverlappingIcons(iconList)
    -- first, get center point of all icons
    local center = mutil.averageVector3s(iconList, function(e)
        return e.ref.element.layout.props.relativePosition
    end)
    if not center then
        return
    end
    center = util.vector2(center.x, center.y)
    -- now I need direction vectors to slide each icon away from the others
    -- if I just do (pos - center) it will get a pretty good result,
    -- but for full overlaps this won't detangle them.
    -- whatever I do, it needs to be deterministic so the icons
    -- won't flicker
    for _, icon in ipairs(iconList) do
        if icon.ref.groupable then
            local pos = icon.ref.element.layout.props.relativePosition
            icon.ref.element.layout.props.relativePosition = pos +
                ((pos - center):normalize() * icon.ref.element.layout.props.relativeSize.x * 0.3)
            icon.ref.element.layout.props.relativeSize = icon.ref.element.layout.props.relativeSize * 0.8
            icon.ref.element:update()
        end
    end
end

local corners = {
    topLeft = { x = 0, y = 0 },
    topRight = { x = ui.screenSize().x, y = 0 },
    bottomLeft = { x = 0, y = ui.screenSize().y },
    bottomRight = { x = ui.screenSize().x, y = ui.screenSize().y },
}
local lastVisibleExtent = nil
---@return Extents
local function getVisibleExtent()
    if lastVisibleExtent ~= nil then
        return lastVisibleExtent
    end
    local o = {
        Top = -math.huge,
        Bottom = math.huge,
        Left = math.huge,
        Right = -math.huge,
    }
    for k, v in pairs(corners) do
        local rel = putil.viewportPosToRealPos(currentMapData, v)
        --local rel = putil.viewportPosToRelativeMeshPos(currentMapData, v, true)
        --putil.viewportPosToRealPos(currentMapData, mouseEvent.position)
        --local cellPos = mutil.worldPosToCellPos(mouseData.clickStartWorldPos)
        if rel then
            o.Right = math.max(o.Right, rel.x)
            o.Left = math.min(o.Left, rel.x)
            o.Top = math.max(o.Top, rel.y)
            o.Bottom = math.min(o.Bottom, rel.y)
        end
    end

    for k, v in pairs(o) do
        o[k] = math.floor(v / mutil.CELL_SIZE)
    end
    lastVisibleExtent = o
    --print("visible extents: " .. aux_util.deepToString(lastVisibleExtent, 3))
    return lastVisibleExtent
end

local function applyPendingRegistrations()
    for _, icon in ipairs(iconsPendingRegister) do
        --- Determine where to insert the icon
        if icon.ref.priority == nil then
            icon.ref.priority = 0
        elseif type(icon.ref.priority) ~= "number" then
            error("icon.priority must be a number")
        end
        local insertIndex = mutil.binarySearchFirst(icons, function(p) return p.ref.priority > icon.ref.priority end)

        if settingCache.debug then
            print("Inserted at index " .. tostring(insertIndex) .. " of " .. tostring(#icons) .. ".")
        end

        table.insert(icons, insertIndex, icon)

        icon.ref.onHide(icon.ref)
        iconContainer.layout.content:insert(insertIndex, icon.ref.element)
    end
    iconContainer:update()
    iconsPendingRegister = {}
end

local MAX_FRAME_DURATION = 1 / 30
local function renderIcons()
    applyPendingRegistrations()

    -- If there is no map, hide all icons.
    if currentMapData == nil then
        for _, icon in ipairs(icons) do
            hideIcon(icon)
        end
        return
    end

    purgeRemovedIcons()

    local collisionFinder = overlapfinder.NewOverlapFinder(getIconExtent)

    local uiSize = ui.layers[ui.layers.indexOf("FadeToBlack")].size
    local parentAspectRatio = util.vector2(uiSize.x / uiSize.y, 1)

    -- Render all the icons.
    for i, icon in ipairs(icons) do
        if i % 50 == 0 and core.getRealFrameDuration() > MAX_FRAME_DURATION then
            coroutine.yield()
        end

        -- Get world position.
        local iPos = icon.ref.pos(icon.ref)
        -- Get optional world facing vector.
        local iFacing = icon.ref.facing and icon.ref.facing(icon.ref) or nil

        if iPos then
            local pos = putil.realPosToNormalizedViewportPos(currentMapData, settingCache, iPos, iFacing)
            if pos and pos.viewportPos then
                if pos.viewportPos.pos and pos.viewportPos.onScreen then
                    icon.onScreen = true
                    icon.ref.onDraw(icon.ref, pos, parentAspectRatio)
                    if icon.ref.groupable then
                        collisionFinder:AddElement(icon)
                    end
                    goto continue
                elseif pos.viewportPos.pos and icon.ref.element.layout.props.relativeSize then
                    -- is the edge visible?
                    local halfBox = icon.ref.element.layout.props.relativeSize / 2
                    local min = pos.viewportPos.pos - halfBox
                    local max = pos.viewportPos.pos + halfBox

                    if max.x >= 0 and max.y >= 0 and
                        min.x <= 1 and min.y <= 1 then
                        --[[print(aux_util.deepToString(icon.ref.element.layout, 10))
                        print("partially visible. pos: " ..
                            tostring(pos.viewportPos.pos) ..
                            ", size: " .. tostring(icon.ref.element.layout.props.relativeSize))]]
                        icon.onScreen = true
                        icon.ref.onDraw(icon.ref, pos, parentAspectRatio)
                        if icon.ref.groupable then
                            collisionFinder:AddElement(icon)
                        end
                        goto continue
                    end
                end
            end
        end
        hideIcon(icon)
        :: continue ::
    end

    if core.getRealFrameDuration() > MAX_FRAME_DURATION then
        coroutine.yield()
    end

    --- do we need to combine any?
    ---@type RegisteredIcon[][]
    local overlaps = collisionFinder:GetOverlappingSubsets()
    for _, subset in ipairs(overlaps) do
        if #subset > 1 then
            -- this is a set of atleast 2
            --[[print("Colliding icons: ")
            for _, elem in ipairs(subset) do
                print("- " .. elem.name .. " " .. aux_util.deepToString(getIconExtent(elem), 3))
            end]]
            --- Now I have a list of all the icons that I need to combine.
            pushOverlappingIcons(subset)
        end
    end

    if core.getRealFrameDuration() > MAX_FRAME_DURATION then
        coroutine.yield()
    end

    if mainWindow then
        for _, icon in ipairs(icons) do
            if icon.onScreenLastRender or icon.onScreen then
                icon.ref.element:update()
            end
            icon.onScreenLastRender = icon.onScreen
        end
        iconContainer:update()
    end

    --print("iconContainer: " .. aux_util.deepToString(iconContainer.layout.props))


    -- debugging
    --[[
    local screenCenter = ui.screenSize() / 2
    local cameraFocusPos = putil.viewportPosToRealPos(currentMapData, screenCenter)
    if cameraFocusPos then
        local recalced = putil.realPosToViewportPos(currentMapData, settingCache, cameraFocusPos)
        if recalced then
            print("viewportPosToRealPos(mapData, " .. tostring(screenCenter) .. "): " ..
                tostring(cameraFocusPos) ..
                "\n realPosToViewportPos(mapData, " ..
                tostring(settingCache) .. ", " .. tostring(cameraFocusPos) .. "): " .. aux_util.deepToString(recalced, 3))
        end
    end
    --]]
end

local renderCoroutine = nil
local function renderAdvance()
    local ok
    if not renderCoroutine then
        renderCoroutine = coroutine.create(
            function()
                while true do
                    invokeOnRenderStartHandlers()
                    renderIcons()
                    coroutine.yield()
                end
            end)
        ok = coroutine.resume(renderCoroutine)
    else
        ok = coroutine.resume(renderCoroutine)
    end
    if not ok then
        renderCoroutine = nil
    end
end

---@param data MeshAnnotatedMapData
local function doOnMapMoved(data)
    print("doOnMapMoved: " .. aux_util.deepToString(data, 3))
    currentMapData = data

    if not data.swapped then
        -- invoking addMode while in gamepad UI will result in registerWindow's
        -- hideFn being called on the next frame. This is why we ignore hideFn.
        interfaces.UI.addMode('Interface', { windows = {} })
        interfaces.GamepadControls.setGamepadCursorActive(true)
        if currentMapData then
            mainWindow = newMainWindow()
        end
    end

    setHoverBoxContent(nil)
end

interfaces.LivelyMapToggler.onMapMoved(doOnMapMoved)


local function doOnMapHidden(data)
    print("doOnMapHidden: " .. aux_util.deepToString(data, 3))


    if not data.swapped then
        -- assumes we're exiting-to-gameplay
        interfaces.UI.removeMode('Interface')
        -- remove UI
        if mainWindow then
            mainWindow:destroy()
        end
    end

    currentMapData = nil
end
interfaces.LivelyMapToggler.onMapHidden(doOnMapHidden)

local lastCameraPos = nil
local function onUpdate(dt)
    if fogShader then
        fogShader:update(currentMapData, dt)
    end

    if currentMapData == nil then
        return
    end

    renderAdvance()
    if mainWindow then
        applyPendingHoverBoxContent()
        mainWindow:update()
    end

    -- invalidate visible extents if the camera moved.
    local currentCameraPos = camera.getPosition()
    if currentCameraPos ~= lastCameraPos then
        lastVisibleExtent = nil
        lastCameraPos = currentCameraPos
    end
end

local nextName = 0
---comment
---@param icon Icon
---@return string The name of the icon.
local function registerIcon(icon)
    if not icon then
        error("registerIcon icon is nil")
    end
    if not icon.element or type(icon.element) ~= "userdata" then
        error("registerIcon icon.element is: " .. aux_util.deepToString(icon, 3) .. ", expected UI element.")
    end
    if not icon.pos then
        error("registerIcon icon.pos is nil: " .. aux_util.deepToString(icon, 3))
    end
    if not icon.onDraw then
        error("registerIcon icon.onDraw is nil: " .. aux_util.deepToString(icon, 3))
    end
    if not icon.onHide then
        error("registerIcon icon.onHide is nil: " .. aux_util.deepToString(icon, 3))
    end

    nextName = nextName + 1
    local name = "icon_" .. tostring(nextName)
    icon.element.layout.name = name

    if settingCache.debug then
        print("Registering icon '" .. name .. "': " .. aux_util.deepToString(icon, 4))
    end

    table.insert(iconsPendingRegister, {
        -- onScreen exists so we don't call onHide every frame.
        onScreen = false,
        onScreenLastRender = true,
        -- remove is used to signal deletion
        remove = false,
        ref = icon,
        name = name,
    })
    return name
end

local function getIcon(name)
    for _, icon in ipairs(icons) do
        if icon.name == name then
            return icon
        end
    end
    return nil
end

return {
    interfaceName = MOD_NAME .. "Draw",
    interface = {
        version = 1,
        registerIcon = registerIcon,
        getIcon = getIcon,
        setHoverBoxContent = setHoverBoxContent,
        getVisibleExtent = getVisibleExtent,
        onRenderStart = onRenderStart,
    },
    engineHandlers = {
        onUpdate = onUpdate,
    }
}
