local I = require("openmw.interfaces")
local OMWUtil = require("openmw.util")
local Input = require("openmw.input")
local Async = require("openmw.async")
local UI = require("openmw.ui")
local OMWSelf = require("openmw.self")
local Core = require("openmw.core")
local Ambient = require("openmw.ambient")

local MapWindow = require("scripts/WayfarersAtlas/UI/MapWindow")
local fsGetMaps = require("scripts/WayfarersAtlas/fsGetMaps")
local StorageData = require("scripts/WayfarersAtlas/StorageData")
local SharedUI = require("scripts/WayfarersAtlas/UI/SharedUI")
local UIUpdater = require("scripts/WayfarersAtlas/UI/UIUpdater")
local UIContext = require("scripts/WayfarersAtlas/UI/UIContext")
local fsGetNoteOptions = require("scripts/WayfarersAtlas/fsGetNoteOptions")
local DataVersions = require("scripts/WayfarersAtlas/DataVersions")

local Immutable = require("scripts/WayfarersAtlas/Immutable")
local Dictionary = Immutable.Dictionary
local Array = Immutable.Array

local l10n = Core.l10n("WayfarersAtlas")

---@type WAY.MapDefinition
local BLANK_MAP_DEF = {
	id = "blank",
	name = l10n("NoAvailableMaps"),
	imagePath = "black",
	imageSize = OMWUtil.vector2(-1, -1),
}
local CUSTOM_UI_MODE = "Interface"

local MapWindowUI = MapWindow.new()
local ModStorage = StorageData.new()

---@type WAY.MapEntry[]
local maps = {}
---@type WAY.MapPack[]
local mapPacks = {}
---@type WAY.MapDefinition[]
local visibleMapDefinitions = {}

local mapId = nil
local windowOffset = OMWUtil.vector2(0, 0)
local windowSize = OMWUtil.vector2(0, 0)

local isVisible = false
local enabledByEngine = false
---@type "default" | "large" | "custom"
local windowMode = "default"
local updateFlag = false
local mapSettingsUpdatedFlag = false

local lastCell = nil
local lastCellName = ""

local nextNoteId = 1
local notesByMap = {}

local function updateMapDefinitions()
	visibleMapDefinitions = {}

	for _, mapPack in ipairs(mapPacks) do
		if ModStorage:getMapPackData(mapPack)("enabled") == false then
			goto continue
		end

		for _, mapDefinition in pairs(mapPack.mapDefinitions) do
			local getDefData = ModStorage:getMapDefinitionData(mapPack, mapDefinition)
			if getDefData("enabled") == false then
				goto continue
			end

			table.insert(
				visibleMapDefinitions,
				Dictionary.merge(mapDefinition, {
					name = getDefData("customName"),
				})
			)

			::continue::
		end

		::continue::
	end

	table.sort(visibleMapDefinitions, function(a, b)
		if a.name == b.name then
			return a.imagePath < b.imagePath
		else
			return a.name < b.name
		end
	end)

	if visibleMapDefinitions[1] == nil then
		visibleMapDefinitions[1] = BLANK_MAP_DEF
	end

	return visibleMapDefinitions
end

local function updateMap(newMapId)
	if newMapId == nil then
		mapId = visibleMapDefinitions[1].id
		return
	end

	local found = Array.find(visibleMapDefinitions, function(def)
		return def.id == newMapId
	end)

	if found then
		mapId = newMapId
	else
		mapId = visibleMapDefinitions[1].id
	end
end

local function loadMultisaveData()
	local errors, newMapPacks = fsGetMaps()
	mapPacks = newMapPacks

	if next(errors) then
		UI.showMessage(l10n("MapPacksErrored"))
	end

	local saveData = ModStorage:updateVersions(DataVersions.multisaveData, ModStorage:getSave())

	maps = {}
	mapId = nil
	windowOffset = saveData.windowOffset
	windowSize = saveData.windowSize

	local function loadMap(mapDefinition)
		local savedSettings = saveData.mapData[mapDefinition.id] or {}

		maps[mapDefinition.id] = {
			id = mapDefinition.id,
			name = mapDefinition.name,
			imagePath = mapDefinition.imagePath,
			imageSize = mapDefinition.imageSize,
			zoom = savedSettings.zoom or 1.0,
			imageOffset = savedSettings.imageOffset or OMWUtil.vector2(0, 0),
		}
	end

	for _, mapPack in pairs(mapPacks) do
		for _, mapDefinition in pairs(mapPack.mapDefinitions) do
			loadMap(mapDefinition)
		end
	end

	loadMap(BLANK_MAP_DEF)

	updateMapDefinitions()
	updateMap(saveData.selectedMapId)
end

local function saveMultisaveData()
	---@type WAY.StorageData
	local storageData = Dictionary.merge(ModStorage:getSave(), {
		version = #DataVersions.multisaveData + 1,
		mapData = {},
		windowOffset = windowOffset,
		windowSize = windowSize,
		selectedMapId = mapId,
	})

	for _, map in pairs(maps) do
		storageData.mapData[map.id] = {
			imageOffset = map.imageOffset,
			zoom = map.zoom,
		}
	end

	ModStorage:setSave(storageData)
end

local function setupUIContext()
	local noteOptions = fsGetNoteOptions()
	UIContext.noteColors = noteOptions.colors
	UIContext.noteIconPaths = noteOptions.icons
end

local function onMapSettingsChanged()
	mapSettingsUpdatedFlag = true
end

local startupDone = false
local function startup()
	if startupDone then
		return
	end

	if not UI.layers.indexOf("WAY_Popup") then
		UI.layers.insertAfter("Windows", "WAY_Popup", { interactive = true })
	end

	if ModStorage:getConfig().b_DisableBuiltinMap then
		I.UI.registerWindow("Map", function()
			enabledByEngine = true
		end, function()
			enabledByEngine = false
		end)
	end

	loadMultisaveData()
	setupUIContext()

	for _, mapPack in pairs(mapPacks) do
		ModStorage:subscribeMapPack(mapPack, onMapSettingsChanged)

		for _, mapDefinition in pairs(mapPack.mapDefinitions) do
			ModStorage:subscribeMapDefinition(mapPack, mapDefinition, onMapSettingsChanged)
		end
	end

	startupDone = true
end

local function onLoad(data)
	data = ModStorage:updateVersions(DataVersions.saveData, data)

	nextNoteId = data.nextNoteId or 1

	for id, notes in pairs(data.notesByMap) do
		notesByMap[id] = Dictionary.copy(notes)
	end

	-- Ensure this loads after restoring the save file in case it somehow errors.
	startup()
end

local function onSave()
	-- Captures the reloadlua console command.
	if isVisible then
		saveMultisaveData()
	end

	return {
		version = #DataVersions.saveData + 1,
		notesByMap = notesByMap,
		nextNoteId = nextNoteId,
	}
end

local function makeProps()
	local config = ModStorage:getConfig()
	local map = maps[mapId]

	local notes = notesByMap[map.id]
	if notes == nil then
		notes = {}
		notesByMap[map.id] = notes
	end

	---@type WAY.MapWindow.Props
	return {
		map = map,
		mapDefinitions = visibleMapDefinitions,
		windowOffset = windowOffset,
		windowSize = windowSize,
		windowName = (config.b_ShowAreaOnMap and lastCellName) or (map and map.name or "Map"),
		onMapChanged = function(newMap)
			maps[newMap.id] = newMap
		end,
		onMapSwitched = function(newMapId)
			updateMap(newMapId)
			updateFlag = true
			Ambient.playSound("book page")
		end,
		onWindowDragged = function(pos)
			windowOffset = pos
		end,
		onWindowResized = function(size)
			windowSize = size
		end,
		notes = notes,
		newNote = function(relativePosition)
			local id = nextNoteId

			---@type WAY.NoteRecord
			local record = {
				id = id,
				relativePosition = relativePosition,
				color = UIContext.noteColors[1],
				iconPath = UIContext.noteIconPaths[1],
				name = l10n("DefaultNoteName", { id = id }),
				description = "",
				pinned = false,
			}

			return record, function()
				nextNoteId = nextNoteId + 1
			end
		end,
	}
end

local function checkInventoryMenuOpen()
	local config = ModStorage:getConfig()

	if config.b_DisableBuiltinMap then
		return enabledByEngine
	else
		-- Check we aren't in a UI context in case the map window was pinned.
		return I.UI.isWindowVisible("Map") and I.UI.getMode() ~= nil
	end
end

local function checkCanShow()
	local config = ModStorage:getConfig()

	if windowMode == "default" then
		return config.b_ShowInInventory and checkInventoryMenuOpen()
	elseif windowMode == "large" then
		return I.UI.getMode() ~= nil
	elseif windowMode == "custom" then
		return I.UI.getMode() ~= nil
	else
		return false
	end
end

local function getCellDisplayName()
	local currentCell = OMWSelf.object.cell
	if currentCell == lastCell then
		return lastCellName
	end

	lastCell = currentCell

	local name = currentCell.name
	if name ~= "" then
		return name
	end

	local regionId = currentCell.region
	if regionId ~= "" then
		return Core.regions.records[regionId].name
	end

	return ""
end

local function onFrame()
	local currentCellName = getCellDisplayName()
	if lastCellName ~= currentCellName then
		updateFlag = true
		lastCellName = currentCellName
	end

	local canShow = checkCanShow()

	-- If we are showing and now should not, update.
	if isVisible and not canShow then
		updateFlag = true
	-- If we are not showing and now should, update.
	elseif not isVisible and canShow then
		updateFlag = true

		if mapSettingsUpdatedFlag then
			mapSettingsUpdatedFlag = false
			updateMapDefinitions()

			-- Change if the current map is no longer valid.
			updateMap(mapId)
		end
	end

	-- If we're out of UI context and the map window is hidden, update to destroy it.
	if not canShow and I.UI.modes[1] == nil and not MapWindowUI:isVisible() then
		updateFlag = true
	end

	if updateFlag then
		-- If we cannot show, but are still in a UI context, hide to preserve state.
		if not canShow and I.UI.modes[1] then
			MapWindowUI:setVisible(false)
		-- Else, destroy to clear state when returning to gameplay.
		elseif not canShow then
			MapWindowUI:destroy()
			MapWindowUI = MapWindow.new()

			-- Only set window mode back to default if we had already been showing the GUI
			-- for at least one frame. This prevents off-by-one desync bugs.
			if isVisible then
				windowMode = "default"
			end
		elseif windowMode == "large" or windowMode == "custom" then
			MapWindowUI:setVisible(true)

			local _screenSize = UI.screenSize()
			local _windowSize = _screenSize * 0.8

			MapWindowUI:render(Dictionary.merge(makeProps(), {
				windowOffset = (_screenSize / 2) - (_windowSize / 2),
				windowSize = _windowSize,
				onWindowDragged = function() end,
				onWindowResized = function() end,
			}))
		elseif windowMode == "default" then
			MapWindowUI:setVisible(true)
			MapWindowUI:render(makeProps())
		end
	end

	updateFlag = false

	-- Save settings on menu close.
	if not canShow and isVisible then
		saveMultisaveData()
	end

	isVisible = canShow

	UIUpdater:flush()
end

local function onMouseWheel(v, h)
	MapWindowUI:onMouseWheel(v, h)
end

local function onMouseButtonPress(button)
	if button == SharedUI.MouseButton.Left then
		MapWindowUI:onMouseClick()
	end
end

Input.registerTriggerHandler(
	"WAY_ToggleLargeView",
	Async:callback(function()
		local mode = I.UI.getMode()

		if windowMode == "default" and mode then
			windowMode = "large"
			Ambient.playSound("book open")
			updateFlag = true
		elseif windowMode == "default" and not mode then
			windowMode = "custom"
			I.UI.addMode(CUSTOM_UI_MODE, { windows = {} })
			Ambient.playSound("book open")
			updateFlag = true
		elseif windowMode == "large" and mode then
			windowMode = "default"
			Ambient.playSound("book close")
			updateFlag = true
		elseif windowMode == "custom" then
			windowMode = "default"
			I.UI.removeMode(CUSTOM_UI_MODE)
			Ambient.playSound("book close")
			updateFlag = true
		end
	end)
)

return {
	engineHandlers = {
		onInit = startup,
		onLoad = onLoad,
		onSave = onSave,
		onFrame = onFrame,
		onMouseWheel = onMouseWheel,
		onMouseButtonPress = onMouseButtonPress,
	},
}
