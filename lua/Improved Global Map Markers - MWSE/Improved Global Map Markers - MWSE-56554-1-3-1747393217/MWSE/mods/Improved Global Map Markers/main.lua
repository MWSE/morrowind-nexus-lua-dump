-- print('local allExtCells = {')
-- for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
	-- if cell.name ~= nil and not cell.isInterior then
		-- print('	["'..tostring(cell.id:lower())..'"] = "",')	
	-- end
-- end
-- print('}')

local config = mwse.loadConfig("Improved Global Map Markers",{
    Key = {keyCode = tes3.scanCode[']']},
	MarkerStyle = 0,
	MarkerSize = 35,
	FastTravel = false,
	DoubleClick = false,
	ShowAllMarkersMap = false
})

local allExtCells = require("Improved Global Map Markers.allExtCells")
local extCells = allExtCells.extCells
local doubleExtCells = allExtCells.doubleExtCells

local mapMarkerLib = include("diject.mapMarkerLib.interop")
local records = {}
local recordsLocal = {}

local function createMarkerForLocal(dds, sc, ShiftX, ShiftY, text, pr, Before, cell, position)
	local cellName = cell.name
	if cellName == nil then
		cellName = cell.id
	end
    local recordParams = {
        path = dds,
        scale = sc, 
        textureShiftX = ShiftX,
        textureShiftY = ShiftY,
		scaleTexture = true,
        name = cellName..text, 
        --description = string.format("x: %d, y: %d", X / 8192, Y / 8192),
		priority = pr,
        temporary = true,	
    }
    local record = mapMarkerLib.record.new(recordParams)
    if not record then return end
	recordsLocal[record] = true
	local localMarkerParams = {
		record = record,
		position = position,
		cell = cell,
		shortTerm = false,
		temporary = true,
		group = false,
		insertBefore = Before,
	}
	local localMarker = mapMarkerLib.localMarker.new(localMarkerParams)
	if not localMarker then return end
end

local function createMarkerForPosition(dds, sc, ShiftX, ShiftY, text, pr, Before, cell, X, Y)
    local recordParams = {
        path = dds,
        scale = sc, 
        textureShiftX = ShiftX,
        textureShiftY = ShiftY,
		scaleTexture = true,
        name = cell.name..text, 
		--description = string.format("x: %d, y: %d", X / 8192, Y / 8192),
		priority = pr,
        temporary = true,
		userData = {pos = {x = X, y = Y}, cell = cell},
        onClickCallback = function (e)
			if config.FastTravel == true then
				if config.DoubleClick == false then
					local uData = e.record.userData
					tes3ui.showMessageMenu({
						message = "Fast travel to \n\n"..uData.cell.name.."\n",
						leaveMenuMode = false,
						buttons = {
							{text = "Yes", 
							callback = function()
								local DoorMarker = false
								for ref in cell:iterateReferences(tes3.objectType.static, false) do
									if ref.object.id == 'DoorMarker' then
										DoorMarker = true
										tes3ui.leaveMenuMode()
										tes3.positionCell{cell = uData.cell.id, position = ref.position, orientation = ref.orientation}								
										break
									end							
								end
								if DoorMarker == false then
									tes3ui.leaveMenuMode()	
									mwscript.positionCell{reference = tes3.player, cell = uData.cell.id, x = uData.pos.x + 4500, y = uData.pos.y + 4500}
								end												
							end},
						},
						cancels = true
					})
				end
			end	
        end,
        onDoubleClickCallback = function (e)
			if config.FastTravel == true then
				if config.DoubleClick == true then
					local uData = e.record.userData
					tes3ui.showMessageMenu({
						message = "Fast travel to \n\n"..uData.cell.name.."\n",
						leaveMenuMode = false,
						buttons = {
							{text = "Yes", 
							callback = function()
								local DoorMarker = false
								for ref in cell:iterateReferences(tes3.objectType.static, false) do
									if ref.object.id == 'DoorMarker' then
										DoorMarker = true
										tes3ui.leaveMenuMode()
										tes3.positionCell{cell = uData.cell.id, position = ref.position, orientation = ref.orientation}								
										break
									end							
								end
								if DoorMarker == false then
									tes3ui.leaveMenuMode()	
									mwscript.positionCell{reference = tes3.player, cell = uData.cell.id, x = uData.pos.x + 4500, y = uData.pos.y + 4500}
								end												
							end},
						},
						cancels = true
					})
				end
			end	
        end,		
    }
    local record = mapMarkerLib.record.new(recordParams)
    if not record then return end
	records[record] = true
	if not cell.isInterior then
		local worldMarkerParams = {
			record = record,
			x = X,
			y = Y,			
			temporary = true,
			group = false,
			insertBefore = Before,
		}
		local worldMarker = mapMarkerLib.worldMarker.new(worldMarkerParams)
	end
end

local function drawLocalsMarkers()
	for record, _ in pairs(recordsLocal) do record:remove() end	
	recordsLocal = {}
	
	local path = ""
	if config.MarkerStyle == 0 then path = "Morrowind\\" else path = "Skyrim\\" end
	
	local data = tes3.getPlayerRef().data
	local activeCells = tes3.getActiveCells()	
	for _, cell in pairs(activeCells) do
		local scale = 1
		local ShiftX = 9 - ((16 * 1) / 2)
		local ShiftY = 9 + ((16 * 1) / 2)	
		for door in cell:iterateReferences(tes3.objectType.door, false) do
			if door.destination and door.destination.cell then
				if data.listClearedIntCells[door.destination.cell.id:lower()] or data.listClearedExtCells[door.destination.cell.id:lower()] then
					createMarkerForLocal(path.."Cleared.dds", scale, ShiftX, ShiftY, ' (Cleared)', 100, false, cell, door.position)
				end
			end		
		end		
	end
end

local function DrawOneExtMarker(cell)
	local data = tes3.getPlayerRef().data
	local scale = config.MarkerSize / 100
	local X = cell.gridX * 8192
	local Y = cell.gridY * 8192						
	local ShiftX = 9 - ((32 * scale) / 2)
	local ShiftY = 9 + ((32 * scale) / 2)

	local path = ""
	if config.MarkerStyle == 0 then path = "Morrowind\\" else path = "Skyrim\\" end
	
	if extCells[cell.id:lower()] then
		local cellType = extCells[cell.id:lower()]
		if typeCell ~= "" then 
			createMarkerForPosition(path..cellType..".dds", scale, ShiftX, ShiftY, ' ('..cellType..')', 0, true, cell, X, Y)
			if doubleExtCells[cell.id:lower()] then
				local cellType = doubleExtCells[cell.id:lower()]
				createMarkerForPosition(path..cellType..".dds", scale, ShiftX, ShiftY, '', 0, true, cell, X, Y)
			end
		end
	end
	if data.listClearedExtCells[cell.id:lower()] then
		ShiftX = 9 - ((16 * scale) / 2)
		ShiftY = 9 + ((16 * scale) / 2)
		createMarkerForPosition(path.."Cleared.dds", scale, ShiftX, ShiftY, ' (Cleared)', 100, false, cell, X, Y)
	end				
end

local function DrawAllMarkers()
	for record, _ in pairs(records) do record:remove() end	
	records = {}
	if tes3.getPlayerRef() then
		local data = tes3.getPlayerRef().data
		local sourceCells = {}
		if config.ShowAllMarkersMap == true then sourceCells = tes3.dataHandler.nonDynamicData.cells else sourceCells = data.listMarkersOpenCells end			
		for _, cellData in pairs(sourceCells) do
			local cell
			if config.ShowAllMarkersMap == true then cell = cellData else cell = tes3.getCell({x = cellData.pos.x, y = cellData.pos.y}) end
			if cell.name ~= nil and not cell.isInterior then
				DrawOneExtMarker(cell)		
			end
		end
		drawLocalsMarkers()
		mapMarkerLib.updateLocalMarkers(true)
		mapMarkerLib.updateWorldMarkers(true)
	end
end
	
local function menuEnterCallback(e)
	local menu = tes3ui.findMenu("MenuMap")
	if menu and e.menu == menu then
		local data = tes3.getPlayerRef().data	
		local cell = tes3.getPlayerCell()		
		local name = cell.displayName
		local title = e.menu:findChild("PartDragMenu_title")
		if title then 
			if data.listClearedIntCells[cell.id:lower()] or data.listClearedExtCells[cell.id:lower()] then 
				title.text = name.." (Cleared)" 
			else 
				title.text = name 
			end 
		end	
		DrawAllMarkers()
	end
end
event.register("menuEnter", menuEnterCallback)

local function uiObjectTooltipCallback(e)
    if e.object and e.object.objectType == tes3.objectType.door and e.reference.destination and e.reference.destination.cell then
		local cell = e.reference.destination.cell
		local data = tes3.getPlayerRef().data	
		if data.listClearedIntCells[cell.id:lower()] or data.listClearedExtCells[cell.id:lower()] then
			local destCell = e.tooltip:findChild("HelpMenu_destinationCell")
			if destCell then destCell.text = destCell.text.." (Cleared)" end
		end
	end
end
event.register("uiObjectTooltip", uiObjectTooltipCallback)

local function listCell()
    if tes3ui.menuMode() then return end
    local cell = tes3.getPlayerCell()
	local data = tes3.getPlayerRef().data
	if not cell.isInterior then
		if not data.listClearedExtCells[cell.id:lower()] then
			data.listClearedExtCells[cell.id:lower()] = true
			DrawOneExtMarker(cell)
			tes3.messageBox(string.format("%s added to the list of cleared cells", cell.name))
		else
			data.listClearedExtCells[cell.id:lower()] = nil
			DrawOneExtMarker(cell)
			tes3.messageBox(string.format("%s removed from the list of cleared cells", cell.name))
		end
	end
	if cell.isInterior then
		if not data.listClearedIntCells[cell.id:lower()] then
			data.listClearedIntCells[cell.id:lower()] = true
			drawLocalsMarkers()
			tes3.messageBox(string.format("%s added to the list of cleared cells", cell.name))
		else
			data.listClearedIntCells[cell.id:lower()] = nil
			drawLocalsMarkers()
			tes3.messageBox(string.format("%s removed from the list of cleared cells", cell.name))
		end
	end	
end

local function registerConfig()
    local template = mwse.mcm.createTemplate("Improved Global Map Markers")
    template:saveOnClose("Improved Global Map Markers", config)
	template:register()
	
    local page = template:createSideBarPage({
        label = "Improved Global Map Markers",
        description = "",
    })	
	
	local settings = page:createCategory("Settings:\n")
	
	settings:createKeyBinder{
        label = "Cleaned cell hotkey.\nRestart the game to apply.",
        description = 'While in the desired external or internal cell, press the hotkey, the cell will be added to the list of cleared cells, pressing it again will remove the cell from the list.\n\nThe internal cell will be assigned the status "Cleared", the door leading to this cell will be inscribed "Cleared", a flag marker will be visible on the local map.\n\nThe external cell (global map) receives a flag marker.\n\nBy default ]',
        allowCombinations = true,
        variable = mwse.mcm.createTableVariable{id = "Key", table = config, defaultSetting = {keyCode = tes3.scanCode[']']}}
    }

	settings:createSlider({
		label = "Markers: 0 - Vanilla style, 1 - Skyrim style (colored)",
		description = "Default is 0.",
		min = 0,
		max = 1,
		step = 1,
		jump = 1,
		callback = DrawAllMarkers,
		variable = mwse.mcm.createTableVariable{id = 'MarkerStyle', table = config},
	})

	settings:createSlider({
		label = "Markers size.",
		description = "Size 18 fills the empty part of the yellow square of the cell.\nSize 35 fills the entire yellow square of the cell (the square is hidden).\nSize 57 fills the entire area of the cell.\n\nThe default value is 35.",
		min = 18,
		max = 57,
		step = 1,
		jump = 10,
		callback = DrawAllMarkers,
		variable = mwse.mcm.createTableVariable{id = 'MarkerSize', table = config},
	})
	
	settings:createOnOffButton({
		label = "Fast travel.",
		description = "Allows you to fast travel to a location by clicking on a marker on the global map.\n\nFast travel occurs to the first door (according to the list in the location) or if there is no door, then to the center of the location.\n\nDefault is off.",
		callback = DrawAllMarkers,
		variable = mwse.mcm:createTableVariable{id = 'FastTravel', table = config}
	})
	
	settings:createOnOffButton({
		label = "Double click for fast travel.",
		description = "Default is off.",
		callback = DrawAllMarkers,
		variable = mwse.mcm:createTableVariable{id = 'DoubleClick', table = config}
	})
	
	settings:createOnOffButton({
		label = "Show all markers on the global map.",
		description = "On - shows all markers from the mod on the global map, even if you have not explored these locations.\nOff - shows markers from the mod only for explored locations.\n\nBy default, off",
		callback = DrawAllMarkers,
		variable = mwse.mcm:createTableVariable{id = 'ShowAllMarkersMap', table = config}
	})	
end
event.register("modConfigReady", registerConfig)

local function NewGame(e)
	if e.newGame then
		local data = tes3.getPlayerRef().data
		data.listMarkersOpenCells = {}
		data.listClearedIntCells = {}
		data.listClearedExtCells = {}
	end
end
event.register('load', NewGame)

local function onLoaded(e)
	local data = tes3.getPlayerRef().data
	local player = tes3.getPlayerRef()
	if not data.listMarkersOpenCells then data.listMarkersOpenCells = {} end
	if not data.listClearedExtCells then data.listClearedExtCells = {} end
	if not data.listClearedIntCells then data.listClearedIntCells = {} end
	DrawAllMarkers()
end
event.register('loaded', onLoaded)

local function cellChangedCallback(e)
	local data = tes3.getPlayerRef().data
	if not e.cell.isInterior then
		if not data.listMarkersOpenCells[e.cell.editorName:lower()] then
			data.listMarkersOpenCells[e.cell.editorName:lower()] = {cell = e.cell.id:lower(), pos = {x = e.cell.gridX, y = e.cell.gridY}}
			DrawOneExtMarker(e.cell)
		end
	end	
	drawLocalsMarkers()
end
event.register("cellChanged", cellChangedCallback)

local function initialized()
    event.register("keyDown", listCell, {filter = config.Key.keyCode})
end
event.register("initialized", initialized)