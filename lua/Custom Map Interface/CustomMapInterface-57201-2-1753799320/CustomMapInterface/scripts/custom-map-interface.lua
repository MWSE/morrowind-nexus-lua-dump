local I = require('openmw.interfaces')
local input = require('openmw.input')
local async = require('openmw.async')
local ui = require('openmw.ui')
local util = require('openmw.util')
local storage = require('openmw.storage')

input.registerTrigger {
    key = 'toggleMap',
    l10n = 'CustomMapInterface',
}

local function makePathSetting(index, default)
	indexStr = tostring(index)
	return {
		key = 'path' .. indexStr,
		renderer = 'textLine',
		name = 'Path to Map ' .. indexStr,
		description = 'The path to the texture for map ' .. indexStr,
		default = default,
	}
end

I.Settings.registerPage {
    key = 'CustomMapInterfacePage',
    l10n = 'CustomMapInterface',
    name = 'Custom Map Interface',
    description = 'Custom Map Interface adds an interface to view custom maps.',
}

I.Settings.registerGroup {
    key = 'SettingsPlayerCustomMapInterface',
    page = 'CustomMapInterfacePage',
    l10n = 'CustomMapInterface',
    name = 'Settings',
    description = 'Settings for Custom Map Interface',
    permanentStorage = true,
    settings = {
		{
            key = 'toggleMap',
            renderer = 'inputBinding',
            name = 'Toggle Map',
            description = 'This is the control that opens and closes the map',
            default = 'M',
			argument = {key = 'toggleMap', type = 'trigger'},
        },
        {
            key = 'zoomSpeed',
            renderer = 'number',
            name = 'Zoom Speed',
            description = 'This is the speed that the map zooms in and out at.',
            default = 10,
        },
		{
            key = 'invertScroll',
            renderer = 'checkbox',
            name = 'Invert Zoom Scroll',
            description = 'This inverts the scroll direction when using the mouse scroll wheel to zoom. By default scrolling up zooms in.',
            default = false,
        },
		{
            key = 'moveSpeed',
            renderer = 'number',
            name = 'Map Move Speed',
            description = 'This is the speed in pixels that the map will move at when using the movement keys.',
            default = 10,
        },
		makePathSetting(1, 'textures/vvardenfellMapWagner.tga'),
		makePathSetting(2, 'textures/solstheimMapWagner.tga'),
		makePathSetting(3, 'textures/mournholdMapWagner.tga'),
		makePathSetting(4, ''),
		makePathSetting(5, ''),
		makePathSetting(6, ''),
		makePathSetting(7, ''),
		makePathSetting(8, ''),
		makePathSetting(9, ''),
    },
}

local playerSettings = storage.playerSection('SettingsPlayerCustomMapInterface')

local zoomSpeed = playerSettings:get('zoomSpeed')
local invertScroll = playerSettings:get('invertScroll') and -1 or 1
local moveSpeed = playerSettings:get('moveSpeed')
local paths = {}
for i = 1, 9 do
	local path = playerSettings:get('path' .. tostring(i))
	if path and path ~= "" then paths[i] = path end
end

local templates = I.MWUI.templates
local vec2 = util.vector2

local imageSize = vec2(1024, 1024)
local center = ui.screenSize() / 2

local mousePositionStart = vec2(0, 0)

local images = {}
local positions = {center, center, center}
local sizes = {imageSize, imageSize, imageSize}

for i, path in ipairs(paths) do
	local image
	image = ui.create {
		layer = "Windows",
		type = ui.TYPE.Image,
		props = {
			visible = false,
			size = imageSize,
			anchor = vec2(0.5, 0.5),
			position = center,
			resource = ui.texture {
				path = path,
			},
		},
		events = {
			mousePress = async:callback(function(mouseEvent)
				if mouseEvent then
					mousePositionStart = mouseEvent.position
				end
			end),
			mouseMove = async:callback(function(mouseEvent)
				if mouseEvent.button then
					local change = mouseEvent.position - mousePositionStart
					mousePositionStart = mouseEvent.position
					image.layout.props.position = image.layout.props.position + change
					image:update()
					positions[i] = image.layout.props.position
				end
			end),
		},
	}
	images[i] = image
end

local currentMapIndex = 1
local mapIsVisible = false

local function setVisibility(image, visible)
	image.layout.props.visible = visible
	image:update()
end

local function toggleMap()
	mapIsVisible = not mapIsVisible
	setVisibility(images[currentMapIndex], mapIsVisible)
	if mapIsVisible then
		I.UI.setMode("Interface", {windows = {}})
	else
		I.UI.setMode()
	end
end

input.registerTriggerHandler('toggleMap', async:callback(toggleMap))

local function switchMap(index)
	if mapIsVisible then
		setVisibility(images[currentMapIndex], false)
		currentMapIndex = index
		setVisibility(images[currentMapIndex], true)
	end
end

for i = 1, #paths do
	strI = tostring(i)
	input.registerTriggerHandler('QuickKey' .. strI, async:callback(function() switchMap(i) end))
end

local function zoomMap(zoomDirection)	
	if mapIsVisible then
		local change = vec2(1, 1) * zoomDirection * zoomSpeed * invertScroll
		sizes[currentMapIndex] = sizes[currentMapIndex] + change
		local map = images[currentMapIndex]
		map.layout.props.size = sizes[currentMapIndex]
		map:update()
	end
end

input.registerActionHandler('Zoom3rdPerson', async:callback(function(zoomDirection) zoomMap(zoomDirection) end))

return {
	engineHandlers = {
		onSave = function()
			return {
				currentMapIndex = currentMapIndex,
				positions = positions,
				sizes = sizes,
			}
		end,
		
		onLoad = function(data)
			if data then
				currentMapIndex = data.currentMapIndex
				positions = data.positions
				sizes = data.sizes
				for i, image in ipairs(images) do
					image.layout.props.size = sizes[i]
					image.layout.props.position = positions[i]
					image:update()
				end
			end
		end,
		
		onFrame = function()
			if mapIsVisible then
				local vertical = input.getRangeActionValue('MoveBackward') - input.getRangeActionValue('MoveForward')
				local horizontal = input.getRangeActionValue('MoveRight') - input.getRangeActionValue('MoveLeft')
				positions[currentMapIndex] = positions[currentMapIndex] + vec2(horizontal, vertical) * moveSpeed
				local map = images[currentMapIndex]
				map.layout.props.position = positions[currentMapIndex]
				map:update()
			end
		end,
	},
	
	eventHandlers = {
		UiModeChanged = function(data)
			if data.oldMode == "Interface" then
				mapIsVisible = false
				setVisibility(images[currentMapIndex], false)
			end
		end,
	},
}
