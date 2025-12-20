
-- Directory to save map tile images to
-- default: tes3.installDirectory.."\\map_tiles\\"
local directory = tes3.installDirectory.."\\map_tiles\\"
-- Starting index in the cell list to begin saving from
local startingIndex = 1

-- Whether to include interior or exterior cells
local includeInteriors = true
local includeExteriors = true



local lfs = require("lfs")

local mapMenu
---@type tes3uiElement
local localMap

local savedFiles = {}

local running = false
local cellIndex = startingIndex - 1
local cellCount = 0


local function listFiles(dir)
    dir = tostring(dir or "")
    dir = dir:gsub("/", "\\")

    local results = {}

    for name in lfs.dir(dir) do
        if name ~= "." and name ~= ".." then
            local fullPath = dir
            if fullPath:sub(-1) ~= "\\" then fullPath = fullPath.."\\" end

            local attr = lfs.attributes(fullPath..name)
            if attr and attr.mode ~= "directory" then
                table.insert(results, name)
            end
        end
    end

    return results
end


local function createDirectory(path)
    if not path or path == "" then return nil, "empty path" end
    path = tostring(path)
    path = path:gsub("/", "\\")
    path = path:gsub("\\+$", "")

    local start = ""
    local tail = path

    local drive = tail:match("^([A-Za-z]:)\\?(.*)$")
    if drive then
        local drive_letter = tail:sub(1, 2)
        if tail:sub(3, 3) == "\\" then
            start = drive_letter .. "\\"
            tail = tail:sub(4)
        else
            start = drive_letter
            tail = tail:sub(3)
        end
    elseif tail:sub(1, 2) == "\\\\" then
        start = "\\\\"
        tail = tail:sub(3)
    elseif tail:sub(1, 1) == "\\" then
        start = "\\"
        tail = tail:sub(2)
    end

    if tail == "" then return true end

    local cur = start
    for part in tail:gmatch("([^\\]+)") do
        if cur == "" or cur:sub(-1) == "\\" then
            cur = cur .. part
        else
            cur = cur .. "\\" .. part
        end

        local mode = lfs.attributes(cur, "mode")
        if not mode then
            local ok, err = lfs.mkdir(cur)
            if not ok then
                return nil, tostring(err)
            end
        elseif mode ~= "directory" then
            return nil, "not a directory: " .. cur
        end
    end

    return true
end


---@param cell  tes3cell
local function getFileName(cell, textureX, textureY)
    local fileName = ""
    if cell.isInterior then
        local cellId = cell.id:lower():gsub(":", "")
        fileName = string.format("%s [%d,%d]", cellId, textureX or 0, textureY or 0)
    else
        fileName = string.format("(%d,%d)", cell.gridX, cell.gridY)
    end

    return fileName
end


local function getInteriorFileName(cell)
    local cellId = cell.id:lower():gsub(":", "")
    return cellId
end


---@param cell tes3cell
---@param data {width : number, height : number, mX : integer, mY : integer, nA : number}
local function saveInteriorCellInfo(cell, data)
    local fileName = getInteriorFileName(cell)..".yaml"

    local filePath = directory..fileName

    local file = io.open(filePath, "w")
    if not file then error("Could not open file for writing: "..filePath) end

    local text = string.format(
        "mX: %d\nmY: %d\nwidth: %d\nheight: %d\nnA: %f",
        data.mX,
        data.mY,
        data.width,
        data.height,
        data.nA
    )

    file:write(text)
    file:close()
end


local function saveCellMapImage()
    local textureEl = localMap:findChild("MenuMap_map_pane")
    if not textureEl then return end

    local playerCell = tes3.player.cell

    if playerCell.isInterior and not savedFiles[getInteriorFileName(playerCell)..".yaml"] then
        local mapPane = localMap:findChild("MenuMap_pane")
        local plMarker = mapPane:findChild("MenuMap_local_player") ---@diagnostic disable-line: need-check-nil
        local plPos = tes3.player.position

        local mapPaneWidth = textureEl.width
        local mapPaneHeight = textureEl.height
        local northAngle = 0

        for ref in playerCell:iterateReferences(tes3.objectType.static) do
            if ref.baseObject.id == "NorthMarker" then
                northAngle = ref.orientation.z
                break
            end
        end

        saveInteriorCellInfo(playerCell, {
            mX = plMarker.positionX, ---@diagnostic disable-line: need-check-nil
            mY = plMarker.positionY, ---@diagnostic disable-line: need-check-nil
            nA = northAngle,
            width = math.floor(mapPaneWidth / 512),
            height = math.floor(mapPaneHeight / 512)
        })
    end

    local elemCount = #textureEl.children
    for i = elemCount, 1, -1 do
        local line = textureEl.children[i]

        local y = elemCount - i

        for j, elem in ipairs(line.children or {}) do
            local x = j - 1
            if not playerCell.isInterior and (y ~= 1 or x ~= 1) then goto continue end

            local cell = elem:getPropertyObject("MenuMap_cell") or playerCell

            local fileName = getFileName(cell, x, y)
            local fileNameTga = fileName..".tga"

            local texture = elem.texture
            if not texture then goto continue end

            local pixelData = texture.pixelData

            pixelData:exportTGA(directory..fileNameTga)

            savedFiles[fileNameTga] = fileNameTga
            print("Saved "..directory..fileNameTga)

            ::continue::
        end

        ::continue::
    end
end


local function isCellTexturesSaved(cell)
    if not cell then return end

    if not cell.isInterior then
        local fileName = getFileName(cell)
        local fileNameTga = fileName..".tga"
        local fileNamePng = fileName..".png"
        if savedFiles[fileNameTga] or savedFiles[fileNamePng] then
            return true
        end
    else
        local infoFileName = getInteriorFileName(cell)..".yaml"
        if not savedFiles[infoFileName] then return false end

        local file = io.open(directory..infoFileName, "r")
        if not file then return false end

        local dt = yaml.decode(file:read("*a"))
        file:close()
        if not dt then return false end

        local width = dt.width or 1
        local height = dt.height or 1
        for y = 0, height - 1 do
            for x = 0, width - 1 do
                local tileFileName = getFileName(cell, x, y)
                local tileFileNameTga = tileFileName..".tga"
                local tileFileNamePng = tileFileName..".png"
                if not (savedFiles[tileFileNameTga] or savedFiles[tileFileNamePng]) then
                    return false
                end
            end
        end
        return true
    end

    return false
end


local function getUnsavedCell()
    local cell

    repeat
        if cellIndex > cellCount then
            return nil
        end

        cellIndex = cellIndex + 1
        cell = tes3.dataHandler.nonDynamicData.cells[cellIndex]

        if not cell then
            goto continue
        end

        if cell.isInterior and not includeInteriors then
            cell = nil
            goto continue
        elseif not cell.isInterior and not includeExteriors then
            cell = nil
            goto continue
        end

        if isCellTexturesSaved(cell) then
            cell = nil
        end

        ::continue::
    until cell

    return cell
end


local function chooseNextCellAndTeleport()
    local cell = getUnsavedCell()
    if not cell then
        print("Map tile saving is complete.")
        return false
    end

    print(string.format("%d: %s", cellIndex, cell.editorName))

    tes3.positionCell{
        cell = cell,
        position = cell.isInterior and tes3vector3.new(0, 0, 0) or tes3vector3.new(cell.gridX * 8192 + 4096, cell.gridY * 8192 + 4096, 0),
        forceCellChange = true,
        suppressFader = true,
        teleportCompanions = false
    }

    return true
end



local function timerCallback()
    saveCellMapImage()

    if chooseNextCellAndTeleport() then
        timer.delayOneFrame(timerCallback)
    end
end


--- @param e keyUpEventData
local function keyUpCallback(e)
    if running then return end
    if not tes3.worldController.inputController:isShiftDown() or
            not tes3.worldController.inputController:isControlDown() then
        return
    end
    tes3.runLegacyScript{command = "EnableMapMenu"}
    if not mapMenu then return end

    print(string.format("Using directory: %s", directory))
    if not lfs.attributes(directory, "mode") and not createDirectory(directory) then
        print("Could not create directory: "..directory)
        return
    end

    running = true

    savedFiles = {}
    for _, fileName in pairs(listFiles(directory)) do
        savedFiles[fileName] = true
    end

    cellCount = #tes3.dataHandler.nonDynamicData.cells
    print(string.format("Total cells: %d", cellCount))
    print("Starting index: "..tostring(startingIndex))

    tes3.runLegacyScript{command = "ToggleCollision"}
    tes3.runLegacyScript{command = "ToggleAI"}
    tes3.runLegacyScript{command = "ToggleGodMode"}
    tes3.runLegacyScript{command = "ToggleScripts"}

    if chooseNextCellAndTeleport() then
        timer.delayOneFrame(timerCallback)
    end
end
event.register(tes3.event.keyUp, keyUpCallback, { filter = tes3.scanCode.y })


-- code to reset north marker orientation

-- --- @param e0 referenceActivatedEventData
-- local function referenceActivatedCallback(e0)
--     if e0.reference.baseObject.id == "NorthMarker" then
--         e0.reference.orientation.z = 0
--         e0.reference.orientation = tes3vector3.new(0, 0, 0)
--     end
-- end
-- event.register(tes3.event.referenceActivated, referenceActivatedCallback)


--- @param e uiActivatedEventData
local function menuMapActivated(e)
    mapMenu = e.element

    localMap = mapMenu:findChild("MenuMap_local")
end

event.register(tes3.event.uiActivated, menuMapActivated, {filter = "MenuMap"})