local UI = require("openmw.ui")
local OMWUtil = require("openmw.util")

local SharedUI = require("scripts/WayfarersAtlas/UI/SharedUI")
local Utils = require("scripts/WayfarersAtlas/Utils")
local Immutable = require("scripts/WayfarersAtlas/Immutable")
local Array = Immutable.Array
local Dictionary = Immutable.Dictionary

local UIObject = require("scripts/WayfarersAtlas/UI/UIObject")
local Window = require("scripts/WayfarersAtlas/UI/Widgets/Window")
local Dropdown = require("scripts/WayfarersAtlas/UI/Widgets/Dropdown")
local NotesLayer = require("scripts/WayfarersAtlas/UI/NotesLayer")

local v2 = OMWUtil.vector2

local MIN_WINDOW_SIZE = v2(250, 200)

---@class WAY.MapWindow: WAY.UIObject
local MapWindow = UIObject:extend("MapWindow")

function MapWindow.new()
	---@class WAY.MapWindow
	local self = MapWindow.bind({})

	---@private
	self._initialized = false
	---@private
	---@type WAY.MapWindow.Props?
	self._props = nil

	---@private
	self._mouseRelImageTL = v2(0, 0)
	---@private
	self._imageScrollOffset = v2(0, 0)

	---@private
	---@type WAY.MapEntry
	self._map = nil

	return self
end

function MapWindow:_calcImageBounds()
	local winSize = self._window:getProps().size
	local imageSize = self._image:getProps().size
	local imageAnchor = self._image:getProps().anchor

	local imageAnchorInv = v2(1, 1) - imageAnchor
	local wiggleRoom = Utils.v2clamp(imageSize - winSize, v2(0, 0), imageSize)

	return -Utils.v2mul(wiggleRoom, imageAnchorInv), Utils.v2mul(wiggleRoom, imageAnchor)
end

function MapWindow:_patchMap(delta)
	self._map = Dictionary.merge(self._map, delta)
end

function MapWindow:_initWindow()
	local windowContentRoot = UIObject.bind(UI.create({
		props = { relativeSize = v2(1, 1) },
	}))
		:registerEvent("focusGain", function()
			self._focused = true
		end)
		:registerEvent("focusLoss", function()
			self._focused = false
		end)

	local window = Window.new({
		minSize = MIN_WINDOW_SIZE,
		onDragged = function(pos)
			self._props.onWindowDragged(pos)
		end,
		onResized = function(size)
			self._props.onWindowResized(size)
		end,
	})
	window:setSize(MIN_WINDOW_SIZE)
	window:setTitle("Map")
	window:getWindowContent():add(windowContentRoot:getBound())

	self._window = window
	self._rootLayout = self._window:getLayout()
	self._windowContentRoot = windowContentRoot
end

function MapWindow:onVisibleChanged(visible)
	if self._window then
		self._window:setVisible(visible)
	end

	if self._notesLayer then
		self._notesLayer:setVisible(visible)
	end
end

-- Clamps only an offset into a vector.
local function v2clampOffset(v, offset, min, max)
	min = v2(math.min(min.x, v.x), math.min(min.y, v.y))
	max = v2(math.max(max.x, v.x), math.max(max.y, v.y))

	local clamped = Utils.v2clamp(v + offset, min, max)
	local clampedOffset = clamped - v

	return clampedOffset
end

function MapWindow:_initImage()
	local image = self._windowContentRoot:addChild(UIObject.bind({
		name = "image",
		type = UI.TYPE.Image,
		props = {
			size = v2(0, 0),
			position = v2(0, 0),
			anchor = v2(0.5, 0.5),
			relativePosition = v2(0.5, 0.5),
		},
	}))

	self._image = image

	image:registerEvent("mouseMove", function(e)
		self._mouseRelImageTL = e.offset
	end)

	SharedUI.scrollableXY({
		uiObject = image,
		onScroll = function(pos)
			if self._draggingNote then
				return
			end

			local offset = v2clampOffset(self._map.imageOffset, pos, self:_calcImageBounds())
			self._imageScrollOffset = offset
			self:queueUpdate()
		end,
		onScrollFinished = function()
			if self._draggingNote then
				return
			end

			self:_patchMap({ imageOffset = self._map.imageOffset + self._imageScrollOffset })
			self._imageScrollOffset = v2(0, 0)
			self._props.onMapChanged(self._map)
		end,
	})
end

function MapWindow:_init()
	if self._initialized then
		return
	end

	self._initialized = true

	self:_initWindow()
	self:_initImage()
end

function MapWindow:_handleZoom(steps)
	if not self._focused or self._draggingNote then
		return
	end

	local imageSize = self._image:getProps().size
	local mapEntry = self._map

	local newZoom = Utils.clamp(mapEntry.zoom + steps * 0.1, 0.1, 2.0)
	local newImageSize = mapEntry.imageSize * newZoom

	-- Mouse is relative to the top left of the image.
	-- The image's origin is relative to the center of the image.
	local cursorPosRelFromCenter = self._mouseRelImageTL - (imageSize / 2)
	-- Because size X and Y are scaled uniformly, only need to choose one component.
	-- Subtract 1 since 1 would mean "equal".
	local sizeDiffScaled = (newImageSize.x / imageSize.x) - 1
	local deltaOffset = cursorPosRelFromCenter * sizeDiffScaled

	self:_patchMap({
		zoom = newZoom,
		imageOffset = mapEntry.imageOffset - deltaOffset,
	})

	self:queueUpdate()

	self._props.onMapChanged(self._map)
end

function MapWindow:onUpdate()
	if not self._initialized then
		return
	end

	local currentMap = self._map
	local imageAssetSize = currentMap.imageSize
	local newImageSize = imageAssetSize * currentMap.zoom

	self._image:getProps().size = newImageSize

	self._image:getProps().position = currentMap.imageOffset + self._imageScrollOffset

	self._windowContentRoot:update()
end

function MapWindow:onDestroyed()
	if self._window then
		self._window:destroy()
	end

	if self._notesLayer then
		self._notesLayer:destroy()
	end
end

function MapWindow:onMouseWheel(v, h)
	if not self._initialized then
		return
	end

	self:_handleZoom(v)
	Utils.deepCallEvent(self._rootLayout, "custom_globalMouseWheel", v, h)
end

function MapWindow:onMouseClick()
	if not self._initialized then
		return
	end

	Utils.deepCallEvent(self._rootLayout, "custom_globalMouseClick")
end

function MapWindow:_updateMap()
	local mapEntry = self._map

	local imageProps = self._image:getProps()
	imageProps.resource = UI.texture({
		path = mapEntry.imagePath,
		size = mapEntry.imageSize,
	})

	local index = Array.find(self._props.mapDefinitions, function(def)
		return def.id == mapEntry.id
	end)

	if index then
		self._dropdownMenu:setSelectedIndex(index)
	end

	Utils.remove(self._image:getContent(), "notesLayer")

	self._notesLayer = self._image:addChildName(
		"notesLayer",
		NotesLayer.new({
			notes = self._props.notes,
			parentUnscaledSize = mapEntry.imageSize,
			newNote = self._props.newNote,
			getSize = function()
				return self._image:getProps().size
			end,
			onDraggingNote = function(dragging)
				self._draggingNote = dragging
			end,
			onPrompting = function(prompting)
				self._dropdownMenuDisableOverlay.props.visible = prompting
				self._dropdownMenu:queueUpdate()
			end,
		})
	)

	self._props.onMapChanged(self._map)
end

---@class WAY.MapWindow.Props
---@field map WAY.MapEntry
---@field mapDefinitions WAY.MapDefinition[]
---@field windowOffset userdata
---@field windowSize userdata
---@field windowName string
---@field onMapChanged fun(newMapEntry: WAY.MapEntry)
---@field onMapSwitched fun(newMapId: string)
---@field onWindowDragged fun(pos)
---@field onWindowResized fun(size)
---@field newNote function
---@field notes table<string, WAY.NoteRecord> Is not read-only.

---@param props WAY.MapWindow.Props
function MapWindow:render(props)
	local lastProps = self._props
	self._props = props

	local updateMap = false

	if not lastProps or (self._map ~= props.map) then
		self._map = props.map
		updateMap = true
	end

	self:_init()

	if not lastProps or (lastProps.mapDefinitions ~= props.mapDefinitions) then
		if self._dropdownMenu then
			Utils.remove(self._windowContentRoot:getContent(), "dropdownMenu")
		end

		---@type WAY.Dropdown
		---@diagnostic disable-next-line
		self._dropdownMenu = self._windowContentRoot
			:addChildName(
				"dropdownMenu",
				Dropdown.new({
					items = Array.map(props.mapDefinitions, function(map)
						return map.name
					end),
				})
			)
			:registerEvent("custom_onSelected", function(selectedIndex)
				local id = self._props.mapDefinitions[selectedIndex].id
				if id ~= self._map.id then
					self._props.onMapSwitched(id)
				end
			end)

		self._dropdownMenuDisableOverlay = self._dropdownMenu:addChild({
			props = {
				visible = false,
				alpha = 0,
				relativeSize = OMWUtil.vector2(1, 1),
				propagateEvents = false,
			},
		})
	end

	if not lastProps or (lastProps.windowOffset ~= props.windowOffset) then
		self._window:setPosition(props.windowOffset)
	end

	if not lastProps or (lastProps.windowSize ~= props.windowSize) then
		self._window:setSize(props.windowSize)
	end

	if not lastProps or (lastProps.windowName ~= props.windowName) then
		self._window:setTitle(props.windowName)
	end

	if updateMap then
		self:_updateMap()
	end

	self:queueUpdate()
end

return MapWindow
