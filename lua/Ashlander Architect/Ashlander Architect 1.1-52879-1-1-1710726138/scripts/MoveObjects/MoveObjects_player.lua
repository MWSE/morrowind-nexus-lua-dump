local ui = require("openmw.ui")
local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local v3 = require("openmw.util").vector3
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local storage = require("openmw.storage")
local camera = require("openmw.camera")
local debug = require("openmw.debug")
local input = require("openmw.input")
local ui = require("openmw.ui")
local async = require("openmw.async")
local BuildMode = require("scripts.moveobjects.movement.buildmode_p")
local contextMenu = require("scripts.moveobjects.utility.contextMenu")
local cellGenStorage = storage.globalSection("AACellGen2")
local buildData = require("scripts.MoveObjects.Movement.TileData")
local vfs = require('openmw.vfs')
local requireShiftToRotate = false

local blockPosUpdate = false
local wallBuilding = false
local collideType = nearby.COLLISION_TYPE.AnyPhysical
local activeObjectTypes = {}
local structureData = require("scripts.MoveObjects.StructureData")
local cellcache = require("scripts.MoveObjects.Cellgen2.cellcache")
local config = require("scripts.MoveObjects.config")
if not config.isUpdated then
    I.Settings.registerPage {
        key = "AshlanderArchitect",
        l10n = "AshlanderArchitect",
        name = "AshlanderArchitect",
        description =
        "Ashlander Architect requires an OpenMW version newer than the current one. Download a build newer than " .. config.buildDate
    }
    error("Your OpenMW version is too old!")
end
local function setCollideType(type)
    --collideType = type
    --I.BFMT_Mouse.setColType(type)
end
local forceAllowGrab = false
local time = require('openmw_aux.time')
local zutils = require("scripts.moveobjects.utility.player").interface
local zutilsUI = require("scripts.moveobjects.utility.ui").interface

local settlementModData = storage.globalSection("AASettlements")
local genModData = storage.globalSection("MoveObjectsCellGen")

local gridSize = 0
local currentCategory = nil --if nil, then show the category selection level
local currentSubCat = nil   --if nil, but above isn't, show subcategories.
local isRelease = false
local function registerDefaultBindings()

end

local knownActions = require("scripts.MoveObjects.input.knownActions")

local function createRotation(x, y, z)
    if (core.API_REVISION < 40) then
        return util.vector3(x, y, z)
    else
        local rotate = util.transform.rotateZ(z)
        local rotatex = util.transform.rotateX(x)
        local rotatey = util.transform.rotateY(y)
        rotate = rotate:__mul(rotatex)
        rotate = rotate:__mul(rotatey)
        return rotate
    end
end
local function getZRotation(rotation)
    if (core.API_REVISION < 40) then
        return rotation.z
    else
        return rotation:getYaw()
    end
end

local function partition_table_by_intcount(table, left, right)
    local pivotValue = table[right]["IntCount"]
    local i = left - 1

    for j = left, right - 1 do
        if table[j]["IntCount"] <= pivotValue then
            i = i + 1
            table[i], table[j] = table[j], table[i]
        end
    end

    table[i + 1], table[right] = table[right], table[i + 1]
    return i + 1
end

local function sortByIntCount(a, b)
    if a.IntCount == nil then
        error("Nil Intcount on " .. a.Static_ID)
    end
    return tonumber(a.IntCount) < tonumber(b.IntCount)
end

local function quicksort_table_by_intcount(tablex, left, right)
    table.sort(tablex, sortByIntCount)
end

--Book position must be set. Moving items should work well.
--Books can be picked up, made upright.
--To make a book upright, it must be set to angle x 270, then z is set to the same as the bookcase, plus some offset.
--For imperial bookshelf, it would be (bkrot - 90)
--Open ended bookshelves depend on the player's position, or if the bookshelf is against the wall or not.

--Bookshelf position should account for the shelf scale.
local function getCurrentSettlementId()
    local list = settlementModData:get("settlementList")
    local settlementId = nil
    if (self.cell.isExterior) then
        for x, structure in ipairs(settlementModData:get("settlementList")) do
            local dist = math.sqrt((self.position.x - structure.settlementCenterx) ^ 2 +
                (self.position.y - structure.settlementCentery) ^ 2)

            if (dist < structure.settlementDiameter / 2) then
                return structure.markerId
            end
        end
    else
        local intData = cellGenStorage:get("CellGenData")
        for x, sett in ipairs(list) do
            for index, value in ipairs(intData) do
                if value.settlementId == sett.markerId and self.cell.name == value.cellName then
                    local dist = math.sqrt((self.position.x - value.interiorPos.x) ^ 2 +
                        (self.position.y - value.interiorPos.y) ^ 2)
                    if (dist < sett.settlementDiameter / 2) then
                        return sett.markerId
                    end
                end
            end
        end
    end
    return nil
end
local gridRefOb = nil

local currentRefs = {}
local currentMainRef = nil
local selectedItemIsReal = false --if the selected item hasn't been placed yet, we don't need to preserve it.
local zPosLock = 0
local zPosManOffset = 0
local xPosManOffset = 0
local yPosManOffset = 0

local tempObjects = {}
local tempDisable = {}

local ignoreCategories = false

local obDistance = 500
local playerpath = nil
local awaitingNewItem = false
local controllerMode = false
local awaitingNewItemToStore = false
local scrollMode = 1
local selectedIndex = 1
local selectedIndexCat = 1
local selectedIndexSubCat = 1
local selectedIndexMain = 1

local offsetX = 0
local offsetY = 0

local gridMode = 0
--0 is normal, use grid when reference point exists.
--1 is use world grid.

local moveModes = {
    pointAndClick = 1,
    moveWithArrows = 2,
}
local function getMoveMode()
    if selectedItemIsReal and I.BFMT_Cam.isInOverheadMode() then
        config.print("SSE")
        return moveModes.movpoeWithArrows
    else
        return moveModes.pointAndClick
    end
end
local function setCurrentMainRef(obj)
    currentMainRef = obj

    BuildMode.setGrabbedObject(currentMainRef)
    core.sendGlobalEvent("updateTargetObj", { obj = obj, moveMode = getMoveMode() })
    if not obj then
        setCollideType(nearby.COLLISION_TYPE.AnyPhysical)
        wallBuilding = false
    end
end

local offsetZ = 0

local selectedIndexBySubCategory = {}
local selectedIndexByCategory = {}


local function getCurrentSelectedObj()
    return currentMainRef
end

local buildModeEnabled = false
local collisionEnabled = true
local zDegrees = 0
local xDegrees = 0
local yDegrees = 0
local function anglesToV(pitch, yaw)
    local xzLen = math.cos(pitch)
    return util.vector3(
        xzLen * math.sin(yaw), -- x
        xzLen * math.cos(yaw), -- y
        math.sin(pitch)        -- z
    )
end

local TypeTable = { {
    MarkerID = "zhac_jbmarker_alchemist",
    NPCPostfix = "al",
    FriendlyName = "Alchemist"
}, {
    MarkerID = "zhac_jbmarker_blacksmith",
    NPCPostfix = "bl",
    FriendlyName = "Blacksmith"
}, {
    MarkerID = "zhac_jbmarker_bookseller",
    NPCPostfix = "bo",
    FriendlyName = "Bookseller"
}, {
    MarkerID = "zhac_jbmarker_caravaneer",
    NPCPostfix = "ca",
    FriendlyName = "Caravaneer"
}, {
    MarkerID = "zhac_jbmarker_clothier",
    NPCPostfix = "co",
    FriendlyName = "Clothier"
}, {
    MarkerID = "zhac_jbmarker_enchanter",
    NPCPostfix = "En",
    FriendlyName = "Enchanter"
}, {
    MarkerID = "zhac_jbmarker_gguide",
    NPCPostfix = "gg",
    FriendlyName = "Guild Guide"
}, {
    MarkerID = "zhac_jbmarker_healer",
    NPCPostfix = "he",
    FriendlyName = "Healer"
}, {
    MarkerID = "zhac_jbmarker_publican",
    NPCPostfix = "pu",
    FriendlyName = "Publican"
}, {
    MarkerID = "zhac_jbmarker_shipmaster",
    NPCPostfix = "sh",
    FriendlyName = "Shipmaster"
}, {
    MarkerID = "zhac_jbmarker_sorcerer",
    NPCPostfix = "so",
    FriendlyName = "Sorcerer"
}, {
    MarkerID = "zhac_jbmarker_trader",
    NPCPostfix = "tr",
    FriendlyName = "Trader"
} }
local function removeTempObject()
    if (selectedItemIsReal == false) then
        local indexToRemove
        for i, object in ipairs(tempObjects) do
            if object == currentMainRef then
                indexToRemove = i
                break
            end
        end
        BuildMode.deleteTempObjects()
        -- table.remove(tempObjects, indexToRemove)
        --  zutils.deleteItem(currentMainRef)
    end
end
local ctrl = input.CONTROLLER_BUTTON
local controllerButtonData = {
    { id = ctrl.A,             text = "A" },
    { id = ctrl.B,             text = "B" },
    { id = ctrl.Back,          text = "Back" },
    { id = ctrl.DPadDown,      text = "DPadDown" },
    { id = ctrl.DPadLeft,      text = "DPadLeft" },
    { id = ctrl.DPadRight,     text = "DPadRight" },
    { id = ctrl.DPadUp,        text = "DPadUp" },
    { id = ctrl.Guide,         text = "Guide" },
    { id = ctrl.LeftShoulder,  text = "Left Shoulder" },
    { id = ctrl.LeftStick,     text = "Left Stick Press" },
    { id = ctrl.RightShoulder, text = "Right Shoulder" },
    { id = ctrl.RightStick,    text = "Right Stick Press" },
    { id = ctrl.Start,         text = "Start" },
    { id = ctrl.Y,             text = "Y" },
    { id = ctrl.X,             text = "X" },
}
local ignoreButtons = {
    { id = ctrl.DPadDown,  text = "DPadDown" },
    { id = ctrl.DPadLeft,  text = "DPadLeft" },
    { id = ctrl.DPadRight, text = "DPadRight" },
    { id = ctrl.DPadUp,    text = "DPadUp" },
    { id = ctrl.Guide,     text = "Guide" },

}
local function getAllCtrlButtons()
    local ret = {}
    for i, button in ipairs(controllerButtonData) do
        local ignore = false
        for i, igbutton in ipairs(ignoreButtons) do
            if (igbutton.id == button.id) then
                ignore = true
            end
        end
        if (ignore == false) then
            table.insert(ret, button.text)
        end
    end

    return ret
end
local function textToControllerButton(buttonText)
    for i, button in ipairs(controllerButtonData) do
        if (button.text == buttonText) then
            return button.id
        end
    end
end
local function controllerButtonToText(button)

end

local function createPreviewObject()

end

I.Settings.registerPage {
    key = "AshlanderArchitect",
    l10n = "AshlanderArchitect",
    name = "AshlanderArchitect",
    description = "AshlanderArchitect"
}
I.Settings.registerGroup {
    key = "SettingsAshlanderArchitect",
    page = "AshlanderArchitect",
    l10n = "AshlanderArchitect",
    name = "AshlanderArchitect",
    description = "",
    permanentStorage = false,
    settings = {
        {
            key = "AllowBuildingAnywhere",
            renderer = "checkbox",
            name = "Allow Building Outside of Settlements",
            description =
            "If set to true, you'll be able to build structures and objects outside of placed settlements.",
            default = false
        },
        {
            key = "DisableJumping",
            renderer = "checkbox",
            name = "Disable Jumping in Build Mode",
            description =
            "If set to true, then jumping will be disabled while in build mode. This allows for more buttons to be reused.",
            default = "true"
        },
        {
            key = "textScale",
            renderer = "number",
            name = "Text Scale",
            integer = false,
            description =
            "This determines the scale of text in game. Raising the number will make text larger, lowering it will make it smaller.",
            default = 1
        },
        {
            key = "EnableButtonBox",
            renderer = "checkbox",
            name = "Display Button Info Window",
            description =
            "If set to true, then while in build mode, you will see a box with infomration on what keys/buttons you can press.",
            default = "true"
        },
        {
            key = "KeepOffset",
            renderer = "checkbox",
            name = "Keep objects offset from where you grabbed it",
            description =
            "If set to true, this will prevent objects from jumping to where your cursor is when you grab it.",
            default = true
        },
        {
            key = "AllowGrabAll",
            renderer = "checkbox",
            name = "Allow grabbing any object",
            default = false,
            description =
            "By default, you may only grab items, objects you can place, and natural objects like plants and rocks. This allows you to grab any object in your crosshairs.",

        },
        {
            key = "freeItemMode",
            renderer = "select",
            name = "Free Placement Mode",
            default = "Free in God Mode",
            argument = {
                disabled = false,
                l10n = "AshlanderArchitectButtons",
                items = { "Free in God Mode", "Free Always", "Free Never" },
            },
        },
    }
}
I.Settings.registerGroup {
    key = "SettingsAshlanderArchitectController",
    page = "AshlanderArchitect",
    l10n = "AshlanderArchitectButtons",
    name = "Ashlander Architect Controller Bindings",
    description =
    "Settings for controller mode in Ashlander Architect. LSh means Left Shoulder, RS means Right Stick Press. ",
    permanentStorage = true,
    settings = {
        {
            key = "PlaceButton",
            renderer = "select",
            l10n = "AshlanderArchitectButtons",
            name = "Place/Drop Object/Select Page Button",
            default = "A",
            argument = {
                disabled = false,
                l10n = "AshlanderArchitectButtons",
                items = getAllCtrlButtons(),
            },
        },

        {
            key = "ForceControllerMode",
            renderer = "checkbox",
            name = "Force Controller Mode",
            description =
            "If set to true, the user interface will be forced into controller mode no matter what keys are pressed.",
            default = "true"
        },
        {
            key = "UseDPadArrows",
            renderer = "checkbox",
            name = "Use DPad as Arrow Keys",
            description =
            "If set to true, the DPad will be used for navigating the menu, instead of the bumpers, A, and B. However, you will need to remap your DPad in Steam or any other tool to make then send arrow key signals instead.",
            default = "true"
        }

    }
}

local controllerSettings = storage.playerSection("SettingsAshlanderArchitectController")
local playerSettings = storage.playerSection("SettingsAshlanderArchitect")
--windows
local currentItemName = nil
local imageBoxCenter = nil
local imageBoxLeft1 = nil
local imageBoxLeft2 = nil
local imageBoxLeft3 = nil
local imageBoxRight1 = nil
local imageBoxRight2 = nil
local imageBoxRight3 = nil

local itemRequirementsBox = nil

local SettlementBox = nil

local itemInfo = {}
local buttonsAndInfo = nil
local selectedItemInfo = nil
local function insertObject(objectsTable, objectType)
    local subcategoryName = objectType.Subcategory

    if not objectsTable[subcategoryName] then
        local newObject = {
            Static_ID = objectType.Static_ID,
            Name = objectType.Name,
            Category = objectType.Category,
            Subcategory = subcategoryName,
            Grid_Size = objectType.Grid_Size,
            Z_Offset = objectType.Z_Offset,
            Texture_Name = objectType.Texture_Name
        }
        objectsTable[subcategoryName] = newObject
    end
    quicksort_table_by_intcount(objectsTable)
end
local function findObjectById(id)
    for _, object in ipairs(I.moveobjects_data.objectTypes) do
        if object.Static_ID:lower() == id:lower() then
            return object
        end
    end
    --config.print("Couldn't find", id)
    return nil
end
local function findObjectName(obj)
    for _, object in ipairs(I.moveobjects_data.objectTypes) do
        if object.Static_ID:lower() == obj.recordId:lower() then
            return object.Name
        end
    end
end

local function getObjectToSelect()
    local hitObject = zutils.getObjInCrosshairs(nil, 100000, false, collideType, tempObjects).hitObject

    if I.BFMT_Cam.isInOverheadMode() then
        hitObject = I.BFMT_Mouse.getMousedOverObject()
    end
    if hitObject and not hitObject:isValid() then
        return nil
    end
    return hitObject
end


local function getCurrentObjData()
    local index
    if not selectedItemIsReal then
        index = activeObjectTypes[selectedIndex].Static_ID
    elseif currentMainRef then
        index = currentMainRef.recordId
    else

    end
    return findObjectById(index)
end
local function getPosToSelect()
    local hitPos = zutils.getObjInCrosshairs(currentMainRef, obDistance, true, collideType, tempObjects).hitPos
    if I.BFMT_Cam.isInOverheadMode() then
        hitPos = I.BFMT_Mouse.getMouseWorldPos()
    else

        if not collisionEnabled then
              hitPos = zutils.getPosInCrosshairs(obDistance)
        end
    end
    if currentMainRef then
        local findOb = getCurrentObjData()
        if findOb and hitPos then
            hitPos = util.vector3(hitPos.x, hitPos.y, hitPos.z)
        end
    end
    return hitPos
end

local function insertObjectsByCategory(objectTypes, categoryName)
    local objectsTable = {}

    for i, objectType in ipairs(I.moveobjects_data.objectTypes) do
        if objectType.Category == categoryName then
            insertObject(objectsTable, objectType)
        end
    end

    return objectsTable
end


local function orderNPC()
    local hitPos = getPosToSelect()
    local hitObject = getObjectToSelect()
    local done = false
    if (hitObject and currentMainRef) then
        if (hitObject.type == types.Activator) then
            for index, tableitem in pairs(TypeTable) do
                if (tableitem.MarkerID == hitObject.recordId) then
                    ui.showMessage("Sending " ..
                        types.NPC.record(currentMainRef).name .. " to work as a " .. tableitem.FriendlyName)

                    currentMainRef:sendEvent("setJobSite", hitObject)
                    done = true
                end
            end
            if (hitObject.recordId == "zhac_settlement_marker1" or hitObject.recordId == "zhac_settlement_marker_c") then
                done = true
            else
                for x, structure in ipairs(genModData:get("generatedStructures")) do
                    if (structure.OutsideDoorID == hitObject.id) then
                        currentMainRef:sendEvent("enterBuilding", { doorId = hitObject.id })
                        ui.showMessage("Sending " ..
                            types.NPC.record(currentMainRef).name .. " into " .. structure.InsideCellLabel)
                        done = true
                    end
                    if (structure.InsideDoorID == hitObject.id) then
                        currentMainRef:sendEvent("exitBuilding", { doorId = hitObject.id })
                        ui.showMessage("Sending " ..
                            types.NPC.record(currentMainRef).name .. " outside of " .. structure.InsideCellLabel)
                        done = true
                    end
                end
            end
        elseif (hitObject.type == types.Creature) then
            ui.showMessage("Ordering " ..
                types.NPC.record(currentMainRef).name .. " to attack " .. types.Creature.record(hitObject).name)
            currentMainRef:sendEvent("attackTarget", hitObject)
            done = true
        end
    end
    if (done == false and currentMainRef) then
        currentMainRef:sendEvent("goToPosition", hitPos)
        ui.showMessage("Sending " .. types.NPC.record(currentMainRef).name .. " to targeted position")
    end
end

local idCache = {}
local function recordExists(recordID)
    if idCache[recordID] then
        return idCache[recordID]
    end
    for key, xtype in pairs(types) do
        if xtype.record and xtype.record(recordID) then
            idCache[recordID] = true
            return true
        end
    end
    idCache[recordID] = false
    return false
end
local structureBlacklist = {}
local function canBuildStructure(structureName, fstructureData)
    for index, value in ipairs(fstructureData.ids) do
        if not recordExists(value.recordId) then
            -- config.print("Can't build " .. structureName)
            return false
        end
    end
    for index, cellName in ipairs(fstructureData.interiors) do
        if not cellcache[cellName] then
            --config.print("Couldn't find " .. cellName)
        else
            for index, value in ipairs(cellcache[cellName]) do
                if not recordExists(value.recordId) then
                    ---  config.print("Can't build " .. structureName)
                    return false
                end
            end
        end
    end
    return true
end

local function refreshStoredData()
    structureData = require("scripts.MoveObjects.StructureData")
    cellcache = require("scripts.MoveObjects.Cellgen2.cellcache")
    structureBlacklist = {}
    for structureName, value in pairs(structureData) do
        if not canBuildStructure(structureName, value) then
            structureBlacklist[structureName] = true
            table.insert(structureBlacklist, structureName)
        end
    end
end
for structureName, value in pairs(structureData) do
    if not canBuildStructure(structureName, value) then
        structureBlacklist[structureName] = true
        table.insert(structureBlacklist, structureName)
    end
end
local currentBuiltStructure
local function checkifExists(obdata)
    local obId = obdata.Static_ID:lower()
    local type = obdata.Object_Type
    if not playerSettings:get("AllowBuildingAnywhere") then
        if not getCurrentSettlementId() and obId ~= "zhac_settlement_marker" then
            return false
        end
    end
    if structureData[obId] and not structureBlacklist[obId] then
        return true
    end
    local keyCheck = string.upper(string.sub(type, 1, 1)) .. string.sub(type, 2)
    if types[keyCheck] then

        return zutils.CheckForRecord(obId, types[keyCheck])
    elseif type == "auto" then
        for key, value in pairs(types) do
            local check = zutils.CheckForRecord(obId, value)
            if check then return true end
        end
    elseif (type == "static") then
        return zutils.CheckForRecord(obId, types.Static)
    elseif (type == "container") then
        return zutils.CheckForRecord(obId, types.Container)
    elseif (type == "activator") then
        return zutils.CheckForRecord(obId, types.Activator)
    elseif (type == "esm4static") then
        return core.contentFiles.has(obdata.contentFile)
    elseif (type == "light") then
        return zutils.CheckForRecord(obId, types.Light)
    end
    return false
end
local function updateActiveObjects()
    -- config.print("Updating objects")
    local factiveObjectTypes = {}
    activeObjectTypes = {}

    if currentCategory == nil and not ignoreCategories then --Top/Category menu
        for i, objectType in ipairs(I.moveobjects_data.objectTypes) do
            local categoryName = objectType.Category
            local subcategoryName = objectType.Subcategory

            if not factiveObjectTypes[categoryName] and checkifExists(objectType) then
                local firstObject = {
                    Static_ID = objectType.Static_ID,
                    Name = categoryName,
                    Category = categoryName,
                    Subcategory = subcategoryName,
                    Grid_Size = objectType.Grid_Size,
                    Z_Offset = objectType.Z_Offset,
                    Texture_Name = objectType.Texture_Name,
                    DefaultDist = objectType.DefaultDist,
                    Object_Type = objectType.Object_Type,
                    itemRequired = objectType.itemRequired,
                    IntCount = objectType.IntCount
                }
                factiveObjectTypes[categoryName] = firstObject
            end
        end
    elseif currentSubCat == nil and not ignoreCategories then --Subcategory Menu
        for i, objectType in ipairs(I.moveobjects_data.objectTypes) do
            local categoryName = objectType.Category
            local subcategoryName = objectType.Subcategory

            if categoryName == currentCategory and checkifExists(objectType) then
                if not factiveObjectTypes[subcategoryName] then
                    local firstObject = {
                        Static_ID = objectType.Static_ID,
                        Name = subcategoryName,
                        Category = categoryName,
                        Subcategory = subcategoryName,
                        Grid_Size = objectType.Grid_Size,
                        Z_Offset = objectType.Z_Offset,
                        Texture_Name = objectType.Texture_Name,
                        DefaultDist = objectType.DefaultDist,
                        Object_Type = objectType.Object_Type,
                        itemRequired = objectType.itemRequired,
                        IntCount = objectType.IntCount
                    }
                    factiveObjectTypes[subcategoryName] = firstObject
                end
            end
        end
    else
        for i, objectType in ipairs(I.moveobjects_data.objectTypes) do
            local categoryName = objectType.Category
            local subcategoryName = objectType.Subcategory

            if (categoryName == currentCategory and subcategoryName == currentSubCat and checkifExists(objectType)) or ignoreCategories then
                local newObj = {
                    Static_ID = objectType.Static_ID,
                    Name = objectType.Name,
                    Category = categoryName,
                    Subcategory = subcategoryName,
                    Grid_Size = objectType.Grid_Size,
                    Z_Offset = objectType.Z_Offset,
                    Texture_Name = objectType.Texture_Name,
                    DefaultDist = objectType.DefaultDist,
                    Object_Type = objectType.Object_Type,
                    itemRequired = objectType.itemRequired,
                    IntCount = objectType.IntCount
                }
                table.insert(activeObjectTypes, newObj)
            end
        end
    end

    for _, object in pairs(factiveObjectTypes) do
        table.insert(activeObjectTypes, object)
    end
    quicksort_table_by_intcount(activeObjectTypes)

    if #activeObjectTypes == 0 then
        -- config.print("Found no objects!")
        currentSubCat = nil
        currentCategory = nil
        updateActiveObjects()
    end
end

local enableUi = true
local function canOrderNPC(npc)
    local list = settlementModData:get("settlementList")
    local settlementId = getCurrentSettlementId()

    for x, structure in ipairs(settlementModData:get("settlementList")) do
        if (structure.markerId == settlementId) then
            for i, npcId in ipairs(structure.settlementNPCs) do
                if (npcId == npc.id) then
                    return true
                end
            end
        end
    end

    return false
end
local lastSettlement
local function updateUi()
    if selectedIndex > #activeObjectTypes then
        selectedIndex = 1
    end
    if (true) then
        -- return
    end
    if (imageBoxCenter) then
        imageBoxCenter:destroy()
    end
    if (SettlementBox) then
        SettlementBox:destroy()
    end
    if (imageBoxLeft1) then
        imageBoxLeft1:destroy()
    end
    if (imageBoxLeft2) then
        imageBoxLeft2:destroy()
    end
    if (imageBoxLeft3) then
        imageBoxLeft3:destroy()
    end
    if (imageBoxRight1) then
        imageBoxRight1:destroy()
    end
    if (itemRequirementsBox) then
        itemRequirementsBox:destroy()
    end
    if (imageBoxRight2) then
        imageBoxRight2:destroy()
    end
    if (imageBoxRight3) then
        imageBoxRight3:destroy()
    end
    if (buttonsAndInfo) then
        buttonsAndInfo:destroy()
    end
    if (selectedItemInfo) then
        selectedItemInfo:destroy()
    end
    if (buildModeEnabled == false) then
        return
    end
    if (enableUi == false) then
        return
    end
    local buttonTable = {} -- "Stamp Currently selected item: left click", "Select object in crosshairs: Right Click",

    if (currentMainRef ~= nil) then
        if (currentMainRef.type == types.NPC) then
            local hitObject = getObjectToSelect()
            local done = false
            if (hitObject) then
                if (hitObject.type == types.Activator) then
                    for index, tableitem in pairs(TypeTable) do
                        if (tableitem.MarkerID:lower() == hitObject.recordId:lower()) then
                            table.insert(buttonTable,
                                "Send " ..
                                types.NPC.record(currentMainRef).name .. " to work as a " .. tableitem.FriendlyName)
                            done = true
                        else

                        end
                    end
                    if (hitObject.recordId == "zhac_settlement_marker1" or hitObject.recordId == "zhac_settlement_marker_c") then

                    else
                        for x, structure in ipairs(genModData:get("generatedStructures")) do
                            if (structure.OutsideDoorID == hitObject.id) then
                                table.insert(buttonTable, "Send " ..
                                    types.NPC.record(currentMainRef).name .. " into " .. structure.InsideCellLabel)
                                done = true
                            end
                            if (structure.InsideDoorID == hitObject.id) then
                                table.insert(buttonTable, "Send " ..
                                    types.NPC.record(currentMainRef).name ..
                                    " outside of " .. structure.InsideCellLabel)
                                done = true
                            end
                        end
                    end
                elseif (hitObject.type == types.Creature) then
                    table.insert(buttonTable, "Order " ..
                        types.NPC.record(currentMainRef).name ..
                        " to attack " .. types.Creature.record(hitObject).name)
                    done = true
                end
            end
            if (done == false) then
                table.insert(buttonTable, "Send " .. types.NPC.record(currentMainRef).name .. " to targeted position")
            end
        end
    end
    if (currentCategory ~= nil and currentSubCat ~= nil) then
        table.insert(buttonTable,
            "Stamp Currently selected object: " .. I.AA_Bindings.getButtonLabel("orderNPC", controllerMode))
    end
    if (currentMainRef == nil) then
        local hitObject = getObjectToSelect()

        if (hitObject) then
            table.insert(buttonTable,
                "Set grid reference object to targeted object: " ..
                I.AA_Bindings.getButtonLabel("removeGridRef", controllerMode))
        else
            table.insert(buttonTable,
                "Remove grid reference object: " .. I.AA_Bindings.getButtonLabel("removeGridRef", controllerMode))
        end
    end
    if (I.BFMT_Cam.isInOverheadMode()) then
        if currentMainRef and selectedItemIsReal then
            table.insert(buttonTable,
                "Move Selected Item: Drag Mouse while left clicking")
            table.insert(buttonTable,
                "Axis Modifiers: X, Y, Z")
        end
        table.insert(buttonTable,
            "Exit Overhead Mode: " ..
            I.AA_Bindings.getButtonLabel("toggleOverview", controllerMode))
    else
        table.insert(buttonTable,
            "Enter Overhead Mode: " ..
            I.AA_Bindings.getButtonLabel("toggleOverview", controllerMode))
    end
    if currentMainRef ~= nil and buildData[currentMainRef.recordId] and not wallBuilding then
        table.insert(buttonTable, I.AA_Bindings.getBindingDesc("startWallBuilding", true))
    end
    if (currentMainRef ~= nil and selectedItemIsReal and currentMainRef.type ~= types.NPC) then
        table.insert(buttonTable, I.AA_Bindings.getBindingDesc("destroySelectedObject", true))
        table.insert(buttonTable, I.AA_Bindings.getBindingDesc("returnToOriginalPos", true))
        table.insert(buttonTable,
            "Drop targeted object: " .. I.AA_Bindings.getButtonLabel("grabTargetedObject", controllerMode))
    end
    if (currentMainRef == nil) then
        table.insert(buttonTable, I.AA_Bindings.getBindingDesc("grabTargetedObject", true))
    end
    if (zPosLock == 0) then
        table.insert(buttonTable,
            "Enable Vertical Position Lock: " ..
            I.AA_Bindings.getButtonLabel("toggleVerticalPositionLock", controllerMode))
    else
        table.insert(buttonTable,
            "Disable Vertical Position Lock: " ..
            I.AA_Bindings.getButtonLabel("toggleVerticalPositionLock", controllerMode))
    end
    table.insert(buttonTable,
        string.format(I.AA_Bindings.getBindingDesc("toggleSurfaceSnapping", true),
            collisionEnabled and "Enable" or "Disable"))

    if (input.isAltPressed() == false and input.isCtrlPressed() == false) then
        if (I.BFMT_Cam.isInOverheadMode()) then
            table.insert(buttonTable, "Adjust Object Rotation: Scroll Wheel(With Shift or M Pressed)")
        else
            table.insert(buttonTable, "Adjust Object Rotation: Scroll Wheel")
        end
    elseif (input.isCtrlPressed() == true) then
        table.insert(buttonTable, "Adjust Object Vertical Position: Scroll Wheel")
    else
        table.insert(buttonTable, "Adjust Object Distance: Scroll Wheel")
    end
    table.insert(buttonTable, I.AA_Bindings.getBindingDesc("resetHeightOffset", true))
    table.insert(buttonTable, I.AA_Bindings.getBindingDesc("resetRotation", true))
    if not currentMainRef then
        table.insert(buttonTable, I.AA_Bindings.getBindingDesc("swapObject", true))
    end
    if I.BFMT_Cam.isInOverheadMode() then
        table.insert(buttonTable, I.AA_Bindings.getBindingDesc("resetCursor", true))
    end
    if (controllerMode == false) then
        --  "Rotate Right: C",
        --  "Rotate Left: X" }
        if wallBuilding then
            buttonTable = {}
            table.insert(buttonTable, "Cancel Wall Building: Escape")
            table.insert(buttonTable, "Place wall: Click")
            table.insert(buttonTable, "Raise Ramped Wall: X")
            table.insert(buttonTable, "Lower Ramped Wall: Z")
            table.insert(buttonTable, "Flip Wall: J")
            table.insert(buttonTable, "Raise Entire Wall: Scroll Wheel")
        end
        buttonsAndInfo = zutilsUI.renderItemChoice(buttonTable, 0.0, 0.01)
        table.insert(buttonTable, "Deselect Settler: Right Click")
    else
        local buttonTable = {}
        if (currentCategory ~= nil and currentSubCat ~= nil) then
            table.insert(buttonTable, "Stamp Currently selected object: A Button")
        else
            table.insert(buttonTable, "Enter Selected Category: A Button")
        end
        if (currentMainRef ~= nil and selectedItemIsReal) then
            table.insert(buttonTable, "Destroy selected object: Y")
            table.insert(buttonTable, "Drop targeted object: X Button")
        end
        if (currentMainRef == nil) then
            table.insert(buttonTable, "Pick up targeted object: X")
        end
        if (zPosLock == 0) then
            table.insert(buttonTable, "Enable Vertical Position Lock: Y Button Long Press")
        else
            table.insert(buttonTable, "Disable Vertical Position Lock: Y Button Long Press")
        end
        if (collisionEnabled) then
            table.insert(buttonTable, "Disable Surface Snapping: Y Button")
        else
            table.insert(buttonTable, "Enable Surface Snapping: Y Button")
        end
        table.insert(buttonTable, "Adjust Object Rotation: Trigger Left and Right")
        table.insert(buttonTable, "Reset Object Rotation:Double LStick Push")
        table.insert(buttonTable, "Adjust Object Vertical Position: Trigger L&R + RStick Push")
        table.insert(buttonTable, "Reset Object Vertical Position:Double LStick Push")
        table.insert(buttonTable, "Adjust Object Distance: Trigger L&R + LStick Push")

        buttonsAndInfo = zutilsUI.renderItemChoice(buttonTable, 0.0, 0.01)
        -- buttonsAndInfo = zutilsUI.renderItemChoice(buttonTable, 0.8, 0.01,ui.ALIGNMENT.End)
    end
    local infoTable = {}
    table.insert(infoTable, "Vertical Position Offset: " .. util.round(zPosManOffset))
    table.insert(infoTable, "Selected Object Distance: " .. util.round(obDistance))
    if collideType == nearby.COLLISION_TYPE.AnyPhysical then
        table.insert(infoTable, "Current Cursor Hit Type: Normal")
    elseif collideType == nearby.COLLISION_TYPE.HeightMap then
        table.insert(infoTable, "Current Cursor Hit Type: Terrain Only")
    end
    table.insert(infoTable, "Currently Selected Item:")
    if (currentMainRef == nil) then
        table.insert(infoTable, "None")
        local hitObject = getObjectToSelect()

        if (hitObject and hitObject:isValid() and hitObject.type ~= types.NPC) then
            table.insert(infoTable, "Object to select at this pos:")
            local lookUp = findObjectById(hitObject.recordId)
            if (lookUp) then
                table.insert(infoTable, lookUp.Name)
            else
                local nameCheck = zutils.FindGameObjectName(hitObject)
                if (nameCheck) then
                    table.insert(infoTable, nameCheck)
                else
                    table.insert(infoTable, hitObject.recordId)
                end
            end
        elseif (hitObject and hitObject.type == types.NPC and canOrderNPC(hitObject)) then
            table.insert(infoTable, "Settler to select at this pos:")
            table.insert(infoTable, types.NPC.record(hitObject).name)
        end
    else
        if (currentMainRef) then
            local lookUp = getCurrentObjData()
            if (lookUp) then
                table.insert(infoTable, lookUp.Name)
            else
                local nameCheck = zutils.FindGameObjectName(currentMainRef)
                if (nameCheck) then
                    table.insert(infoTable, nameCheck)
                else
                    table.insert(infoTable, currentMainRef.recordId)
                end
            end
        end
        table.insert(infoTable, "Vertical Rotation: " .. util.round(math.deg(getZRotation(currentMainRef.rotation))))
    end
    selectedItemInfo = zutilsUI.renderItemChoice(infoTable, 0.9, 0.01, ui.ALIGNMENT.Start, util.vector2(0.5, 0))
    local currentSettlementID = getCurrentSettlementId()

    if not currentSettlementID and lastSettlement then
        currentCategory = nil
        currentSubCat = nil
        updateActiveObjects()
        removeTempObject()
        setCurrentMainRef()
    end
    if currentSettlementID then
        for x, structure in ipairs(settlementModData:get("settlementList")) do
            if structure.markerId == currentSettlementID then
                SettlementBox = zutilsUI.renderItemChoice({ structure.settlementName }, 0.96, 0.90)
            end
        end
    end
    lastSettlement = currentSettlementID

    if currentCategory and currentSubCat then
        itemRequirementsBox = zutilsUI.renderObjectRequirements(activeObjectTypes[selectedIndex], 0.5, 0.9, 5)
    end
    imageBoxCenter = zutilsUI.renderTextWithBox(activeObjectTypes[selectedIndex], 0.5, 0.8, 5)
    local offsets = { 0.3, 0.2, 0.1, 0.7, 0.8, 0.9 }

    if selectedIndex > 1 then
        imageBoxLeft1 = zutilsUI.renderTextWithBox(activeObjectTypes[selectedIndex - 1], offsets[1], 0.8)
    end

    if selectedIndex > 2 then
        imageBoxLeft2 = zutilsUI.renderTextWithBox(activeObjectTypes[selectedIndex - 2], offsets[2], 0.8)
    end

    if selectedIndex > 3 then
        imageBoxLeft3 = zutilsUI.renderTextWithBox(activeObjectTypes[selectedIndex - 3], offsets[3], 0.8)
    end

    if selectedIndex < #activeObjectTypes then
        imageBoxRight1 = zutilsUI.renderTextWithBox(activeObjectTypes[selectedIndex + 1], offsets[4], 0.8)
    end

    if selectedIndex < #activeObjectTypes - 1 then
        imageBoxRight2 = zutilsUI.renderTextWithBox(activeObjectTypes[selectedIndex + 2], offsets[5], 0.8)
    end

    if selectedIndex < #activeObjectTypes - 2 then
        imageBoxRight3 = zutilsUI.renderTextWithBox(activeObjectTypes[selectedIndex + 3], offsets[6], 0.8)
    end
end
local function getCameraDirData()
    local pos = camera.getPosition()
    local pitch, yaw

    pitch = -(camera.getPitch() + camera.getExtraPitch())
    yaw = (camera.getYaw() + camera.getExtraYaw())

    return pos, anglesToV(pitch, yaw)
end
local lastDist = 0
local function updateSelectedItem()
    --need to remove the selected item, and replace it with the new item.

    offsetX = 0
    offsetY = 0
    offsetZ = 0
    local id = activeObjectTypes[selectedIndex].Static_ID
    core.sendGlobalEvent("setCurrentDestName", activeObjectTypes[selectedIndex].Name)
    if structureData[id] then
        currentBuiltStructure = id
        setCollideType(nearby.COLLISION_TYPE.HeightMap)
    else
        currentBuiltStructure = nil
        setCollideType(nearby.COLLISION_TYPE.AnyPhysical)
    end
    if currentCategory == nil or currentSubCat == nil or selectedItemIsReal == true then
        id = nil
    end
    BuildMode.updateSelectedObject(id)
    --config.print("Selected item")

    if (currentSubCat == nil or currentCategory == nil and ignoreCategories == false) then
        return
    end
    if (awaitingNewItem) then
        config.print("Still waiting for item")
        return
    end
    if (currentMainRef == nil) then
        local tcell = self.cell
        local tpos = self.position
        local trot = util.vector3(0, 0, math.rad(zDegrees))
        if (activeObjectTypes[selectedIndex].DefaultDist ~= lastDist) then
            lastDist = activeObjectTypes[selectedIndex].DefaultDist
            obDistance = lastDist
        end
        --  awaitingNewItem = true
        -- zutils.createItem(activeObjectTypes[selectedIndex].Static_ID, tcell, tpos, trot)
        return
    end

    if (currentMainRef.recordId == activeObjectTypes[selectedIndex].Static_ID:lower()) then
        config.print("This is the same as the last.")
        return
    end



    local tcell = currentMainRef.cell
    local tpos = currentMainRef.position
    local trot = util.vector3(0, 0, math.rad(zDegrees))
    if (selectedItemIsReal == false) then
        -- removeTempObject()
        -- zutils.deleteItem(currentMainRef)
    end
    if (activeObjectTypes[selectedIndex].DefaultDist ~= lastDist) then
        lastDist = activeObjectTypes[selectedIndex].DefaultDist
        obDistance = lastDist
    end
    --awaitingNewItem = true
    -- zutils.createItem(activeObjectTypes[selectedIndex].Static_ID, tcell, tpos, trot)
    --need to wait for stage 2
end

local rightClickedObject
local function contextMenuClicked(text, index, id)
    if id == "destroyitem" then
        core.sendGlobalEvent("DeletePlacedObject",
            { object = rightClickedObject, settlementId = getCurrentSettlementId() })
    elseif id == "copyitem" and rightClickedObject then
        local data = findObjectById(rightClickedObject.recordId)
        local categoryName = data.Category
        local subcategoryName = data.Subcategory
        currentCategory = categoryName
        currentSubCat = subcategoryName
        updateActiveObjects()

        updateSelectedItem()
    end
end
local function handleRightClickOnObject(obj)
    rightClickedObject = obj
    local buttons = {}
    local cursorPos = I.BFMT_Mouse.getNormMousePos()
    if obj then
        local name = findObjectName(rightClickedObject) or "Object"
        local data = findObjectById(rightClickedObject.recordId)
        if name and data then
            table.insert(buttons, { text = "Copy " .. name, id = "copyitem" })
        end
        table.insert(buttons, { text = "Destroy " .. name, id = "destroyitem" })
        table.insert(buttons, { text = "Rename " .. name, id = "renameitem" })
    else
        table.insert(buttons, { text = "Paste", id = "pasteitem" })
    end

    contextMenu.createContextMenu(buttons, contextMenuClicked,
        { windowPos = cursorPos }
    )
end
local function normalize_degrees(degrees)
    return (degrees % 360 + 360) % 360 - (degrees % 360 < 0 and 360 or 0)
end

local function updateBuildModeState()
    BuildMode.setBuildModeState(buildModeEnabled)
    if (buildModeEnabled == true) then
        input.setControlSwitch(input.CONTROL_SWITCH.Fighting, false)
        input.setControlSwitch(input.CONTROL_SWITCH.Magic, false)
        input.setControlSwitch(input.CONTROL_SWITCH.ViewMode, false)
        input.setControlSwitch(input.CONTROL_SWITCH.VanityMode, false)
        --  if(controllerMode == false) then
        input.setControlSwitch(input.CONTROL_SWITCH.Controls, false)
        input.setControlSwitch(input.CONTROL_SWITCH.Jumping, false)
        --  end
        camera.setMode(camera.MODE.FirstPerson)
        types.Actor.setStance(self, types.Actor.STANCE.Nothing)
        I.ControlsZack.overrideMovementControls(false)
        I.ControlsZack.takeControlOfActor(self, true)
        I.Controls.overrideMovementControls(true)
        selectedItemIsReal = false
        if (currentCategory ~= nil and currentSubCat ~= nil and selectedItemIsReal == false) then
            selectedItemIsReal = false
            awaitingNewItem = true
            zutils.createItem(activeObjectTypes[selectedIndex].Static_ID, self.cell, self.position,
                util.vector3(0, 0, math.rad(zDegrees)))
        end
    else
        input.setControlSwitch(input.CONTROL_SWITCH.Fighting, true)
        input.setControlSwitch(input.CONTROL_SWITCH.Magic, true)
        input.setControlSwitch(input.CONTROL_SWITCH.ViewMode, true)
        input.setControlSwitch(input.CONTROL_SWITCH.Controls, true)
        input.setControlSwitch(input.CONTROL_SWITCH.Jumping, true)
        input.setControlSwitch(input.CONTROL_SWITCH.VanityMode, true)
        I.ControlsZack.overrideMovementControls(true)
        I.Controls.overrideMovementControls(false)
        if (selectedItemIsReal == false) then
            removeTempObject()
            --   zutils.deleteItem(currentMainRef)
        end
        core.sendGlobalEvent("destroyMarkers")

        setCurrentMainRef()
    end
end
-- Create a table to store objects' original positions
local objectPositions = {}

-- Function to save object's original position
local function saveObjectOriginalPosition(object)
    -- Check if the object already exists in the table
    for i, storedObject in ipairs(objectPositions) do
        if storedObject.id == object.id then
            -- Object already exists, do nothing
            return
        end
    end

    -- Object doesn't exist, save its original position
    local position = object.position
    -- local rotation = {
    --     x = object.rotation.x,
    ---      y = object.rotation.y,
    --     z = object.rotation.z
    --  }

    local data = {
        id = object.id,
        position = object.position,
        rotation = object.rotation
    }

    -- Add the object to the table
    table.insert(objectPositions, data)
end

-- Function to return an object to its original position
local function returnObjectToOriginalPosition(object)
    -- Search for the object in the table

    for i, storedObject in ipairs(objectPositions) do
        if storedObject.id == object.id then
            -- Found the object, return it to its original position

            -- Prepare the data for teleportation
       
            -- Teleport the object to its original position
            core.sendGlobalEvent("ZackUtilsTeleport", {
                item = object,
                position = storedObject.position,
                rotation = storedObject.rotation
            })

            -- Exit the function after teleportation
            return
        end
    end
    if object.startingPosition then
        core.sendGlobalEvent("ZackUtilsTeleport", {
            item = object,
            position = object.startingPosition,
            rotation = object.startingRotation
        })

    end
    -- If the object's original position was not found in the table
    -- config.print("No original position found for object with ID: " .. object.id)
end
local function convertStringToTable(inputString)
    local dataTable = {}
    local entryCount = 0

    for entry in string.gmatch(inputString, "([^|]+)") do
        local itemID, count = string.match(entry, "(.-);(.+)")
        if not itemID then return end
        count = tonumber(count)

        local carriedCount = types.Actor.inventory(self):countOf(itemID)
        local dataEntry = {
            itemID = itemID,
            count = count,
            carried = carriedCount >= count
        }
        if (dataEntry.itemID ~= nil) then
            table.insert(dataTable, dataEntry)
            entryCount = entryCount + 1
            --   config.print(itemID)
        end
    end

    -- Handle single item case
    if entryCount == 0 then
        local itemID, count = string.match(inputString, "(.-);(.+)")
        count = tonumber(count)
        if not itemID then return end

        local carriedCount = types.Actor.inventory(self):countOf(itemID)
        local dataEntry = {
            itemID = itemID,
            count = count,
            carried = carriedCount >= count
        }

        table.insert(dataTable, dataEntry)
    end

    return dataTable
end


local function allowedToGrab(object)
    local obId = object.id
    local obrid = object.recordId
    if not object.contentFile then return true end --can always pick up objects the player placed. May need more speficiation above this.
    if playerSettings:get("AllowGrabAll") then
        return true
    end
    if forceAllowGrab then return true end
    saveObjectOriginalPosition(object)
    if not forceAllowGrab and string.sub(obrid, 1, 3) == "in_" or string.sub(obrid, 1, 3) == "ex_" then return false end
    --can't pick up interior objects
    return true
end
local function onMouseWheel(scroll, horizontal)
    if (buildModeEnabled == false) then
        return
    end
    if (core.isWorldPaused()) then
        return
    end
    local amount = scroll
    local scrollIn = scroll > 0
    local scrollOut = scroll < 0
    local xPressed = input.isKeyPressed(input.KEY.X)
    local yPressed = input.isKeyPressed(input.KEY.Y)
    local rotationAmount = amount

    
    if (currentMainRef) then
        local findOb = getCurrentObjData()
        if (findOb) then
            if (findOb.Grid_Size > 0) then
                rotationAmount = 90
            end
        end
    end
    local shiftIsPressed = input.isShiftPressed() or input.isKeyPressed(input.KEY.H)
    if (input.isCtrlPressed()) then  --move towards me
        if zPosLock ~= 0 and currentMainRef then
            local findOb = getCurrentObjData()
            if findOb and findOb.Grid_Size then
                zPosLock = zPosLock + (findOb.Grid_Size / 8)
            else
                zPosLock = zPosLock + amount
            end
        else
            if xPressed then
                xPosManOffset = xPosManOffset + amount
            elseif yPressed then
                yPosManOffset = yPosManOffset + amount
            else
                zPosManOffset = zPosManOffset + amount
            end
        end
        updateUi()
    elseif (input.isAltPressed()) then --move towards me
        obDistance = obDistance + amount
        updateUi()
    elseif (  (shiftIsPressed or not requireShiftToRotate) and currentMainRef) then --move towards me
        if xPressed then
            xDegrees = normalize_degrees(xDegrees + rotationAmount)
        elseif yPressed then
            yDegrees = normalize_degrees(yDegrees + rotationAmount)
        else
            zDegrees = normalize_degrees(zDegrees + rotationAmount)
        end
        local x = math.rad(xDegrees)
        local y = math.rad(yDegrees)
        local z = math.rad(zDegrees)
        local toRot = createRotation(x, y,
            z)
        BuildMode.updateTargetPos(currentMainRef.position, toRot)
        updateUi()
    elseif (scrollOut and (shiftIsPressed or not requireShiftToRotate) and currentMainRef) then
        if xPressed then
            xDegrees = normalize_degrees(xDegrees - rotationAmount)
        elseif yPressed then
            yDegrees = normalize_degrees(yDegrees - rotationAmount)
        else
            zDegrees = normalize_degrees(zDegrees - rotationAmount)
        end
        local x = math.rad(xDegrees)
        local y = math.rad(yDegrees)
        local z = math.rad(zDegrees)
        local toRot = createRotation(x, y,
            z)
        BuildMode.updateTargetPos(currentMainRef.position, toRot)
        updateUi()
    else
    end

    if wallBuilding then
        local value
        if scrollIn and input.isShiftPressed() then
            value = "zoomin"
        elseif scrollOut and input.isShiftPressed() then
            value = "zoomout"
        end
        core.sendGlobalEvent("keyPress", value)
        return
    end
end
local function onMouseButtonPress(mb)
    if wallBuilding then
        local value
        if mb == 2 then
            value = "rightclick"
        elseif mb == 1 then
            value = "leftclick"
        end
        core.sendGlobalEvent("keyPress", value)
        return
    end
end
--Input Functions
local function onInputAction(action)

end
local doubleClickSpeed = 10
local lastClick = 0
local function handleWallBuilding(key)
    if wallBuilding then
        if key.code == input.KEY.Escape then
            setCollideType(nearby.COLLISION_TYPE.AnyPhysical)
            core.sendGlobalEvent("keyPress", "esc")
            return
        end
        core.sendGlobalEvent("keyPress", key.symbol)
        return
    end
end
local function stampObject()
    if currentMainRef == nil then
        --   zutils.createItem(activeObjectTypes[selectedIndex].Static_ID, self.cell, self.position, self.rotation)
        selectedItemIsReal = false
        --   awaitingNewItem = true
    else
        local canPlace = true
        local cheatMode = playerSettings:get("freeItemMode")
        local canCheat = false

        if cheatMode == "Free in God Mode" and debug.isGodMode() then
            canCheat = true
        elseif cheatMode == "Free Always" then
            canCheat = true
        end

        if (activeObjectTypes[selectedIndex].itemRequired ~= nil) then
            local data = convertStringToTable(activeObjectTypes[selectedIndex].itemRequired)
            if data then
                for index, dataOb in ipairs(data) do
                    if (dataOb.carried == false and not canCheat) then
                        canPlace = false
                        ui.showMessage("Some items are missing!")
                    end
                end
            end
        end
        if (canPlace) then
            if (activeObjectTypes[selectedIndex].itemRequired ~= nil and not canCheat) then
                local data = convertStringToTable(activeObjectTypes[selectedIndex].itemRequired)
                if data then
                    for index, dataOb in ipairs(data) do
                        core.sendGlobalEvent("removeItemCount_AA",
                            { itemId = dataOb.itemID, count = dataOb.count, actor = self })
                    end
                end
            end
            core.sendGlobalEvent("dropOne", currentMainRef)
--                awaitingNewItemToStore = true
            selectedItemIsReal = false
            blockPosUpdate = true
            BuildMode.createPermObject()
            async:newUnsavableSimulationTimer(0.4, function()
                blockPosUpdate = false
            end)
            ui.showMessage("Placed Object")
        elseif (currentMainRef ~= nil and currentMainRef.count > 1) then
            core.sendGlobalEvent("dropOne", currentMainRef)
        end
    end
    updateUi()
end
local function grabObject()
    if not currentMainRef then
        local hitObject = getObjectToSelect()
        if hitObject and hitObject.type ~= types.NPC then
            zDegrees = normalize_degrees(math.deg(getZRotation(hitObject.rotation)))

            local hitPosReal = getPosToSelect()
            if (hitObject and hitPosReal and playerSettings:get("KeepOffset")) then
                offsetX = hitObject.position.x - hitPosReal.x
                offsetY = hitObject.position.y - hitPosReal.y
                offsetZ = hitObject.position.z - hitPosReal.z
                --    config.print(offsetX, offsetY, offsetZ)
            end
            local position = hitObject.position

            selectedItemIsReal = true
            setCurrentMainRef(hitObject)
            BuildMode.setGrabbedObject(currentMainRef)
            local findOb = findObjectById(hitObject.recordId)
            if (findOb) then

            end
            -- calculate offsetslll
        elseif hitObject and hitObject.type == types.NPC and canOrderNPC(hitObject) then
            selectedItemIsReal = true
            setCurrentMainRef(hitObject)
        end
    else
        selectedItemIsReal = false
        setCurrentMainRef()
    end
    updateUi()
end
local function handleInput(key, controller, type)
    if (core.isWorldPaused()) then
        --  return
    end
    local b = I.AA_Bindings
    if not b then
        return
    end
    handleWallBuilding(key)
    local bindings = {} --= b.passInput(controller, key.code)
    if key or controller then
        local code = -999

        if key then
            code = key.code
        end
        bindings = b.passInput(controller, code)
        if bindings == nil and I.AA_Bindings then
            registerDefaultBindings()
            bindings = b.passInput(controller, code)
        end
    end
    if not key and controller then
        controllerMode = true

    elseif key and not controller then
        controllerMode = false
    end

    if type == knownActions.resetCursor and I.BFMT_Cam.isInOverheadMode() then
        I.BFMT_Mouse.resetCursorLoc()
    elseif (type == knownActions.toggleBuildMode) then
        buildModeEnabled = not buildModeEnabled
        if not buildModeEnabled then
            if I.BFMT_Cam.isInOverheadMode() then
                I.BFMT_Cam.exitCamMode()
                requireShiftToRotate = false
            end
        end
        updateBuildModeState()
        updateActiveObjects()
        updateUi()
    end
    if (buildModeEnabled == false) then
        return
    end
    --if key.symbol == "k" then
    --    local lookUp = getCurrentObjData()
    --    if lookUp then
    --        vfs.takeScreenshot("/users/tobias/OMWSS/" .. lookUp.Static_ID .. ".jpg")
    --    end
    --end
    local hitObject = getObjectToSelect()
    if (type == knownActions.resetHeightOffset) then
        if (lastClick == 0) then
            lastClick = core.getGameTime()
        elseif (core.getGameTime() - lastClick < doubleClickSpeed) then
            zPosManOffset = 0
        else

        end
        lastClick = core.getGameTime()
    elseif type == knownActions.swapObject and hitObject and not currentMainRef then
        ui.showMessage("Swap Objects" .. hitObject.recordId)
        core.sendGlobalEvent("swapObject", hitObject)
    elseif currentMainRef and type == knownActions.startWallBuilding and buildData[currentMainRef.recordId] then
        setCollideType(nearby.COLLISION_TYPE.HeightMap)
        core.sendGlobalEvent("startBuildingFromHub", currentMainRef)
        setCurrentMainRef()
        wallBuilding = true
        updateUi()
        return
    elseif (type == knownActions.resetRotation) then
        if (lastClick == 0) then
            lastClick = core.getGameTime()
        elseif (core.getGameTime() - lastClick < doubleClickSpeed) then
            zDegrees = 0
            ui.showMessage("Reset Rotation")
        else

        end
        lastClick = core.getGameTime()
    elseif (type == knownActions.orderNPC and currentMainRef and currentMainRef.type == types.NPC) then
        orderNPC()
    elseif (type == knownActions.grabTargetedObject) then
        grabObject()
    elseif ((type == knownActions.arrowRight) and core.isWorldPaused() == false and selectedItemIsReal == false) then --right/up
        input.setControlSwitch(input.CONTROL_SWITCH.Controls, false)
        if (selectedIndex < #activeObjectTypes) then
            selectedIndex = selectedIndex + 1

            updateUi()
            updateSelectedItem()
        end
    elseif ((type == knownActions.arrowLeft) and core.isWorldPaused() == false and selectedItemIsReal == false) then --left/down
        input.setControlSwitch(input.CONTROL_SWITCH.Controls, false)
        if (selectedIndex > 1) then
            selectedIndex = selectedIndex - 1
            updateUi()
            updateSelectedItem()
        end
    elseif (type == knownActions.toggleUI) then
        enableUi = not enableUi
    elseif type == knownActions.toggleOverview then
        if I.BFMT_Cam.isInOverheadMode() then
            I.BFMT_Cam.exitCamMode()

            requireShiftToRotate = false
            I.ControlsZack.overrideMovementControls(false)
        elseif self.cell.isExterior then
            I.BFMT_Cam.enterCamMode(self.position)
            requireShiftToRotate = true
            I.ControlsZack.overrideMovementControls(true)
        end
    elseif (type == knownActions.destroySelectedObject) then
        if (selectedItemIsReal == false) then
            removeTempObject()
        end
        core.sendGlobalEvent("DeletePlacedObject", { object = currentMainRef, settlementId = getCurrentSettlementId() })

        selectedItemIsReal = false
        setCurrentMainRef()
    elseif (type == knownActions.removeGridRef) then
        local swingAt = getObjectToSelect()

        if (swingAt ~= nil and findObjectById(swingAt.recordId) ~= nil) then
            ui.showMessage("Set grid reference object to " .. findObjectById(swingAt.recordId).Name)
            gridRefOb = swingAt
            gridRefOb = swingAt
            -- config.print(gridRefOb.position)
            zPosLock = swingAt.position.z
            config.print("set grid Ref OB" .. swingAt.recordId .. gridRefOb.recordId)
        else
            ui.showMessage("Removed grid reference object")
            gridRefOb = nil
        end
    elseif ((type == knownActions.arrowUp) and ignoreCategories == false and currentCategory == nil and currentSubCat == nil and selectedItemIsReal == false) then --selecting the category
        currentCategory = activeObjectTypes[selectedIndex].Category
        selectedIndexCat = selectedIndex
        selectedIndex = selectedIndexSubCat
        -- config.print("Entering cat")
        updateActiveObjects()
    elseif ((type == knownActions.arrowUp) and currentCategory ~= nil and currentSubCat == nil and selectedItemIsReal == false) then --selecting the subcategory
        currentSubCat = activeObjectTypes[selectedIndex].Subcategory
        updateActiveObjects()
        selectedIndexSubCat = selectedIndex
        selectedIndex = selectedIndexMain
        -- config.print("Entering subcat")
        updateUi()
        updateSelectedItem()
    elseif ((type == knownActions.arrowUp and ignoreCategories == true)) then --selecting the subcategory
        updateActiveObjects()
        -- config.print("Entering subcat")
        updateUi()
        updateSelectedItem()
    elseif ((type == knownActions.arrowDown) and currentCategory ~= nil and currentSubCat ~= nil and selectedItemIsReal == false) then --Go back to select the subcat
        removeTempObject()
        selectedIndexMain = selectedIndex
        selectedIndex = selectedIndexSubCat
        setCurrentMainRef()

        -- currentMainRef = nil
        currentSubCat = nil
        updateActiveObjects()
        updateUi()
    elseif ((type == knownActions.arrowDown) and currentCategory ~= nil and currentSubCat == nil and selectedItemIsReal == false) then --go back to category
        currentCategory = nil
        updateActiveObjects()
        selectedIndexSubCat = selectedIndex
        selectedIndex = selectedIndexCat
    elseif (type == knownActions.toggleScrollMode) then
        -- for _, info in ipairs(itemInfo) do
        --  config.print(info.recordId, info.positionZ)
        --end
        if (scrollMode == 1) then
            scrollMode = 2
        elseif scrollMode == 2 then
            scrollMode = 3
        elseif scrollMode == 3 then
            scrollMode = 1
        end
        updateUi()
    elseif (type == knownActions.grabTargetedObject) then  --Right Click
        if I.BFMT_Cam.isInOverheadMode() then
            local hitObject = getObjectToSelect()
            selectedItemIsReal = true
            setCurrentMainRef(hitObject)
            --  handleRightClickOnObject(hitObject)
        end
        if not currentMainRef and not I.BFMT_Cam.isInOverheadMode() then
            local hitPosReal = getPosToSelect()
            local hitObject = getObjectToSelect()

            if hitObject and allowedToGrab(hitObject) then
                if (hitObject and hitPosReal) then
                    offsetX = 0 --hitObject.position.x - hitPosReal.x
                    offsetY = 0 --hitObject.position.y - hitPosReal.y
                    offsetZ = 0 --hitObject.position.z - hitPosReal.z
                    --  config.print(offsetX, offsetY, offsetZ)
                end
                zDegrees = normalize_degrees(math.deg((zutils.getObjectAngle(hitObject).z)))
                -- zDegrees = normalize_degrees(math.deg(getZRotation(hitObject.rotation)))
                local position = hitObject.position
                selectedItemIsReal = true
                setCurrentMainRef(hitObject)
                local findOb = findObjectById(hitObject.recordId)
                if (findOb) then

                end
                -- calculate offsetslll
            end
        elseif not I.BFMT_Cam.isInOverheadMode() then
            if (selectedItemIsReal == false) then
                removeTempObject()
                --  zutils.deleteItem(currentMainRef)
            else
                BuildMode.setGrabbedObject(nil)
            end
            selectedItemIsReal = false
            setCurrentMainRef()
        end
        updateUi()
    elseif (type == knownActions.orderNPC and currentSubCat ~= nil and currentCategory ~= nil and selectedItemIsReal == false) then --Left Click
       stampObject()
    elseif (type == knownActions.orderNPC and selectedItemIsReal == true and currentMainRef ~= nil and currentMainRef.type == types.NPC) then --Left Click
       orderNPC()
    elseif (type == knownActions.orderNPC and selectedItemIsReal == true and currentMainRef) then
     
        core.sendGlobalEvent("dropOne", currentMainRef)
    elseif type == knownActions.toggleVerticalPositionLock and zPosLock == 0 and currentMainRef ~= nil then
        zPosLock = currentMainRef.position.z
        updateUi()
    elseif type == knownActions.toggleVerticalPositionLock and zPosLock ~= 0 then
        zPosLock = 0
        updateUi()
    elseif type == knownActions.toggleSurfaceSnapping then --stamp
        collisionEnabled = not collisionEnabled
    elseif type == knownActions.returnToOriginalPos and currentMainRef and selectedItemIsReal then
         returnObjectToOriginalPosition(currentMainRef)
          currentMainRef = nil
    end
end
local backStart = 0
local YPress = 0
local BPress = 0
local function onControllerButtonRelease(id)
    if (id == input.CONTROLLER_BUTTON.Back) then
        if core.getGameTime() - backStart > 15 then
            buildModeEnabled = not buildModeEnabled
            updateBuildModeState()
            updateActiveObjects()
            updateUi()
        else --single press
            if (currentMainRef == nil) then
                return
            end
            if (selectedItemIsReal == false) then
                removeTempObject()
            end
            if (currentMainRef.type ~= types.NPC) then
                core.sendGlobalEvent("DeletePlacedObject",
                    { object = currentMainRef, settlementId = getCurrentSettlementId() })
                selectedItemIsReal = false
                setCurrentMainRef()
            end
        end
    end
    if (id == input.CONTROLLER_BUTTON.Y) then
        --config.print(core.getGameTime() - YPress)
        if core.getGameTime() - YPress > 15 and currentMainRef ~= nil then --double pressed
            if (zPosLock == 0) then
                zPosLock = currentMainRef.position.z
                ui.showMessage("Locked Z Position")
            else
                zPosLock = 0
            end
        else
            collisionEnabled = not collisionEnabled
            updateUi()
        end
    end
    if (id == input.CONTROLLER_BUTTON.B) then
        -- config.print(core.getGameTime() - BPress)
        if core.getGameTime() - BPress > 15 then --double pressed
            local swingAt = getObjectToSelect()

            if (swingAt ~= nil and findObjectById(swingAt.recordId) ~= nil) then
                ui.showMessage("Set grid reference object to " .. findObjectById(swingAt.recordId).Name)
                gridRefOb = swingAt
                gridRefOb = swingAt
                -- config.print(gridRefOb.position)
                config.print("set grid Ref OB" .. swingAt.recordId .. gridRefOb.recordId)
            else
                ui.showMessage("Removed grid reference object")
                config.print("Removed Grid Ob")
                gridRefOb = nil
            end
        else
            if (currentCategory ~= nil and currentSubCat ~= nil and selectedItemIsReal == false) then --Go back to select the subcat
                removeTempObject()
                selectedIndexMain = selectedIndex
                selectedIndex = selectedIndexSubCat

                setCurrentMainRef()
                currentSubCat = nil
                updateActiveObjects()
            elseif (currentCategory ~= nil and currentSubCat == nil and selectedItemIsReal == false) then --go back to category
                currentCategory = nil
                updateActiveObjects()
                selectedIndexSubCat = selectedIndex
                selectedIndex = selectedIndexCat
            end
        end
    end
end
local function onControllerButtonPress(id)
    if (id == input.CONTROLLER_BUTTON.Back) then
        backStart = core.getGameTime()
    end
    if (id == input.CONTROLLER_BUTTON.Y) then
        YPress = core.getGameTime()
    end
    if (id == input.CONTROLLER_BUTTON.B) then
        BPress = core.getGameTime()
    end
    --  handleInput(nil, id)
end
local function onKeyPress(key)
    if not types.Player.isCharGenFinished(self) then
        return
    end
    contextMenu.passKeyInput(key)
    --  handleInput(key, nil)
end
--End of Input Functions

local waitTime = 0
local function onUpdate(dt)

end
local categories = {}
local function onLoad()

end
local rightSkip = false
local leftSkip = false
local lookMode = false
local thingToKill = nil
local wasSwinging = false
local function compareFloored(n1, n2)
    if (math.floor(n1 + 0.5) == math.floor(n2 + 0.5)) then
        return true
    else
        return false
    end
end

local treeData = {}
local function findClosestNumber(numbers, reference)
    local closestNumber = nil
    local minDifference = math.huge

    for _, number in ipairs(numbers) do
        local difference = math.abs(reference - number)
        if difference < minDifference then
            minDifference = difference
            closestNumber = number
        end
    end

    return closestNumber
end
local function getPositionBehind(pos, rot, distance, direction)
    local currentRotation = -rot
    local angleOffset = 0

    if direction == "north" then
        angleOffset = math.rad(90)
    elseif direction == "south" then
        angleOffset = math.rad(-90)
    elseif direction == "east" then
        angleOffset = 0
    elseif direction == "west" then
        angleOffset = math.rad(180)
    else
        error("Invalid direction. Please specify 'north', 'south', 'east', or 'west'.")
    end

    currentRotation = currentRotation - angleOffset
    local obj_x_offset = distance * math.cos(currentRotation)
    local obj_y_offset = distance * math.sin(currentRotation)
    local obj_x_position = pos.x + obj_x_offset
    local obj_y_position = pos.y + obj_y_offset
    return util.vector3(obj_x_position, obj_y_position, pos.z)
end
local function getPosToPlace(grid, hitPos, zPos, dist, zOffset, v, pos, hitObReal)
    local toPos
    if (currentMainRef ~= nil and currentMainRef.type == types.Book) then
        -- hitPos = I.ZackUtilsAA.getObjInCrosshairs(currentMainRef,dist,true).hitPos
        local bookCaseRot = I.MoveObjects_Book.getRotationForCase(currentMainRef, hitObReal)
        local bookCaseData = I.MoveObjects_Book.getBookcaseData(hitObReal)
        toPos = pos + v * dist
        local bookHalfSize = currentMainRef:getBoundingBox().halfSize.y
        if (bookCaseRot) then
            local CorrectedZ = hitObReal.position.z +
                findClosestNumber(bookCaseData.shelfZOffset, hitPos.z - hitObReal.position.z) + bookHalfSize

            local myHS = currentMainRef:getBoundingBox().halfSize.z
            for index, item in ipairs(nearby.items) do
                if (item ~= currentMainRef) then
                    local itemHS = item:getBoundingBox().halfSize.z
                    if (I.ZackUtilsAA.distanceBetweenPos(util.vector3(hitPos.x, hitPos.y, CorrectedZ), item.position) < (myHS + itemHS)) then
                        config.print(
                            I.ZackUtilsAA.distanceBetweenPos(util.vector3(hitPos.x, hitPos.y, CorrectedZ), item.position),
                            myHS, itemHS)
                        return currentMainRef.position
                    end
                end
            end
            return util.vector3(hitPos.x, hitPos.y, CorrectedZ), bookCaseRot
        else
            return util.vector3(hitPos.x, hitPos.y, hitPos.z), bookCaseRot
        end
    end
    if (grid == false) then
        if I.BFMT_Cam.isInOverheadMode() then
            toPos = I.BFMT_Mouse.getMouseWorldPos()
            local objHalfSize = toPos.z
            toPos = util.vector3(toPos.x + offsetX, toPos.y + offsetY, toPos.z + zPosManOffset)
        else
            toPos = pos + v * dist
            local objHalfSize = hitPos.z
            toPos = util.vector3(hitPos.x + offsetX, hitPos.y + offsetY, objHalfSize + zPosManOffset)
        end
        if zPosLock ~= 0 then
            toPos = util.vector3(toPos.x, toPos.y, zPosLock + zOffset)
        else
            toPos = util.vector3(toPos.x, toPos.y, toPos.z + zPosManOffset + zOffset)

            if xPosManOffset ~= 0 then
                local rotation = 0

                if currentMainRef then
                    rotation = currentMainRef.rotation:getAnglesZYX()
                end
                local dir = "east"
                if xPosManOffset < 0 then
                    dir = "west"
                end
                toPos = getPositionBehind(toPos, rotation, math.abs(xPosManOffset), dir)
                config.print(xPosManOffset)
            end

            if yPosManOffset ~= 0 then
                local rotation = 0

                if currentMainRef then
                    rotation = currentMainRef.rotation:getAnglesZYX()
                end
                local dir = "north"
                if xPosManOffset < 0 then
                    dir = "south"
                end
                toPos = getPositionBehind(toPos, rotation, math.abs(yPosManOffset), dir)
            end
        end
    else
        if (gridRefOb == nil) then
            config.print("No grid ref ob!")
            return
        end
        if I.BFMT_Cam.isInOverheadMode() then
            hitPos = I.BFMT_Mouse.getMouseWorldPos()

            if zPosLock ~= 0 then
                hitPos = util.vector3(hitPos.x, hitPos.y, zPosLock)
            else
                hitPos = util.vector3(hitPos.x, hitPos.y, hitPos.z)
            end
            zPos = hitPos.z
        end
        toPos = util.vector3(
            math.floor((gridRefOb.position.x + 128) / gridSize) *
            gridSize,
            math.floor((gridRefOb.position.y + 128) / gridSize) *
            gridSize,
            math.floor((gridRefOb.position.z + 148) /
                gridSize) *
            gridSize - 128 + zPosManOffset
        )
        toPos = toPos - gridRefOb.position

        toPos = util.vector3(
            (math.floor((hitPos.x + 128) / gridSize) *
                gridSize) - toPos.x,
            (math.floor((hitPos.y + 128) / gridSize) *
                gridSize) - toPos.y,
            (math.floor((zPos + 148) /
                    gridSize) *
                gridSize - 128) - toPos.z
        )
        if zPosLock ~= 0 then
            toPos = util.vector3(toPos.x, toPos.y, zPosLock)
        end
        -- toPos = util.vector3(toPos.x,toPos.y,toPos.z + zPosManOffset)
    end
    return toPos
end
local function permaObjectStore(object)
    if not object then
        config.print("Got nothing in return")
        return
    end
    local testRef = object
    --This is an object that's being placed
    if (testRef ~= nil) then
        if (testRef.type == types.Activator) then
            for index, value in ipairs(nearby.activators) do
                if (value.recordId ~= testRef.recordId and compareFloored(value.position.x, testRef.position.x) and compareFloored(value.position.y, testRef.position.y) and compareFloored(value.position.z, testRef.position.z)) then
                    zutils.deleteItem(value)
                end
            end
        end
        if (testRef.type == types.Activator) then
            for index, value in ipairs(tempDisable) do
                if (value.recordId ~= testRef.recordId and compareFloored(value.position.x, testRef.position.x) and compareFloored(value.position.y, testRef.position.y) and compareFloored(value.position.z, testRef.position.z)) then
                    table.remove(tempDisable, index)
                    zutils.deleteItem(value)
                end
            end
        end
        local mySettlement = getCurrentSettlementId()
        if (findObjectById(testRef.recordId) and findObjectById(testRef.recordId).Subcategory == "Beds" and mySettlement) then
            core.sendGlobalEvent("addBedIdEvent", { settlementId = mySettlement, bedId = testRef.id })
        end


        if (gridRefOb == nil and findObjectById(testRef.recordId) and findObjectById(testRef.recordId).Grid_Size > 0) then
            gridRefOb = testRef
            zPosLock = testRef.position.z
            config.print("Setting RefOb")
            --  config.print(gridRefOb.position)
        end

        awaitingNewItemToStore = false
    end
end
local function createItemReturn_AA(data)
    local objectList = data.objectList
    if not objectList or #objectList == 0 then
        setCurrentMainRef()
    end
    if not data.mainRef then
        setCurrentMainRef(objectList[1])
    else
        setCurrentMainRef(data.mainRef)
    end

    tempObjects = objectList or {}
    awaitingNewItem = false
end
local function getPositionBehind(pos, rot, distance, direction)
    local currentRotation = -rot.z
    local angleOffset = 0

    if direction == "north" then
        angleOffset = math.rad(90)
    elseif direction == "south" then
        angleOffset = math.rad(-90)
    elseif direction == "east" then
        angleOffset = 0
    elseif direction == "west" then
        angleOffset = math.rad(180)
    else
        error("Invalid direction. Please specify 'north', 'south', 'east', or 'west'.")
    end

    currentRotation = currentRotation - angleOffset
    local obj_x_offset = distance * math.cos(currentRotation)
    local obj_y_offset = distance * math.sin(currentRotation)
    local obj_x_position = pos.x + obj_x_offset
    local obj_y_position = pos.y + obj_y_offset
    return util.vector3(obj_x_position, obj_y_position, pos.z)
end
local settingsFixed = false
local function swingAt()
    if (self.controls.use > 0 and types.Actor.stance(self) == types.Actor.STANCE.Weapon) then
        wasSwinging = true
        --  config.print("Swinging")
    else
        if (wasSwinging == true and not isRelease) then
            local swingAt = zutils.getObjInCrosshairs()
            local equip = types.Actor.getEquipment(self)
            local weapon = equip[types.Actor.EQUIPMENT_SLOT.CarriedRight]
            if (swingAt.hitObject and weapon and weapon.type == types.Weapon) then
                local wrecord = types.Weapon.record(weapon)
                local isPickaxe = wrecord.icon == "icons\\w\\tx_miner_pick.dds"
                local isAxe = wrecord.type == types.Weapon.TYPE.AxeOneHand
                local conditionCheckAxe = I.MoveObjects_Resources.matchCondition("Tree", swingAt.hitObject.recordId)
                local conditionCheckPickAxe = I.MoveObjects_Resources.matchCondition("Rock", swingAt.hitObject.recordId)
                if conditionCheckPickAxe and isPickaxe then
                    I.MoveObjects_Resources.attemptRockHarvest(swingAt.hitObject)
                    --also check model here
                elseif isAxe and not isPickaxe and conditionCheckAxe then
                    I.MoveObjects_Resources.attemptTreeHarvest(swingAt.hitObject)
                end
            else
                config.print("No hit")
            end

            wasSwinging = false
        end
    end
end
local rWasPressed, lWasPressed = false, false
local function onFrameInput()
    local rightButtonPressed = input.isMouseButtonPressed(3)
    local leftButtonPressed = input.isMouseButtonPressed(1)
    local rightButtonPressedOnce = rightButtonPressed and not rWasPressed
    local leftButtonPressedOnce = leftButtonPressed and not lWasPressed
    if ((input.getAxisValue(input.CONTROLLER_AXIS.RightX) > 0.1 or input.getAxisValue(input.CONTROLLER_AXIS.RightX) < -0.1) or (input.getAxisValue(input.CONTROLLER_AXIS.RightY) > 0.1 or input.getAxisValue(input.CONTROLLER_AXIS.RightY) < -0.1)) then
        if (lookMode == false) then
            input.setControlSwitch(input.CONTROL_SWITCH.Controls, true)

            I.ControlsZack.overrideMovementControls(true)
            I.Controls.overrideMovementControls(false)
            lookMode = true
        end
    else
        if (lookMode == true) then
            input.setControlSwitch(input.CONTROL_SWITCH.Controls, false)

            I.ControlsZack.overrideMovementControls(false)
            I.Controls.overrideMovementControls(true)
            lookMode = false
        end
    end
    ---
    if (input.isControllerButtonPressed(input.CONTROLLER_BUTTON.RightStick)) then
        if (input.getAxisValue(input.CONTROLLER_AXIS.TriggerRight) > 0) then
            zPosManOffset = zPosManOffset + (1 * input.getAxisValue(input.CONTROLLER_AXIS.TriggerRight))
        end
        if (input.getAxisValue(input.CONTROLLER_AXIS.TriggerLeft) > 0) then
            zPosManOffset = zPosManOffset - (1 * input.getAxisValue(input.CONTROLLER_AXIS.TriggerLeft))
        end
    elseif (input.isControllerButtonPressed(input.CONTROLLER_BUTTON.LeftStick)) then
        if (input.getAxisValue(input.CONTROLLER_AXIS.TriggerRight) > 0) then
            obDistance = obDistance + (4 * input.getAxisValue(input.CONTROLLER_AXIS.TriggerRight))
        end
        if (input.getAxisValue(input.CONTROLLER_AXIS.TriggerLeft) > 0) then
            obDistance = obDistance - (4 * input.getAxisValue(input.CONTROLLER_AXIS.TriggerLeft))
        end
    else
        if (input.getAxisValue(input.CONTROLLER_AXIS.TriggerRight) > 0 and rightSkip == false) then
            local grid = false
            local findOb = findObjectById(currentMainRef.recordId)
            if (findOb) then
                gridSize = findOb.Grid_Size
                grid = gridSize > 0
            end
            if (grid and gridRefOb == nil) then
                grid = false
            end
            if (grid) then
                zDegrees = normalize_degrees(zDegrees + 90)
                rightSkip = true
            else
                zDegrees = normalize_degrees(zDegrees + (2 * input.getAxisValue(input.CONTROLLER_AXIS.TriggerRight)))
            end
            zDegrees = normalize_degrees(zDegrees + (2 * input.getAxisValue(input.CONTROLLER_AXIS.TriggerRight)))
        elseif (input.getAxisValue(input.CONTROLLER_AXIS.TriggerRight) == 0) then
            rightSkip = false
        end
        if (input.getAxisValue(input.CONTROLLER_AXIS.TriggerLeft) > 0 and leftSkip == false) then
            local grid = false
            local findOb = findObjectById(currentMainRef.recordId)
            if (findOb) then
                gridSize = findOb.Grid_Size
                grid = gridSize > 0
            end
            if (grid and gridRefOb == nil) then
                grid = false
            end
            if (grid) then
                zDegrees = normalize_degrees(zDegrees - 90)
                leftSkip = true
            else
                zDegrees = normalize_degrees(zDegrees - (4 * input.getAxisValue(input.CONTROLLER_AXIS.TriggerLeft)))
            end
        elseif (input.getAxisValue(input.CONTROLLER_AXIS.TriggerLeft) == 0) then
            leftSkip = false
        end
    end
    lWasPressed = leftButtonPressed
    rWasPressed = rightButtonPressed
end

local function getEquipped(recordId, actor)
    for i, x in pairs(types.Actor.getEquipment(world.players[1])) do
        if x.recordId == recordId then return true end
    end
    return false
end
local function onFrame(dt)

    if blockPosUpdate then return end
    if (not settingsFixed and I.AA_Bindings ~= nil) then
        registerDefaultBindings()
        settingsFixed = true
    end
    -- updateUi()
    if (zutils == nil) then
        ui.showMessage("Unable to load Zackutils")
        return
    end
    if (core.isWorldPaused()) then
        return
    end
    swingAt()
    if (buildModeEnabled == false) then
        return
    end
    waitTime = waitTime + dt
    if (waitTime > 0.3) then
        waitTime = 0

        updateUi()
    end
    core.sendGlobalEvent("onFrame_AA")
    if wallBuilding and currentMainRef then
        core.sendGlobalEvent("updateEndPosition", getPosToSelect())
        return
    end

    ---
    --normally the controller view stick can't be used while in controls disabled mode, so we re-enable it while the stick is used
    onFrameInput()

    if (playerpath ~= nil and #playerpath > 0) then
        local currentPoint = playerpath[1]
        zutils.teleportItem(self, currentPoint)
        table.remove(playerpath, 1)
    end
    if currentMainRef and currentMainRef.type ~= types.NPC then
        local hitObject = currentMainRef
        local hitPos
        local hitObReal = nil
        local numberId = tonumber(currentMainRef.id:match("([^" .. "_" .. "]+)"))
        local formId
        local ignoreObs = { hitObject }
        local zOffset = 0


        if collisionEnabled then
            hitPos    = getPosToSelect()
            hitObReal = getObjectToSelect()
        else
              hitPos = zutils.getPosInCrosshairs(obDistance)
        end
        if (hitPos == nil) then
            return
        end
        local pos, v = getCameraDirData()
        local dist = 50
        local toPos
        local toRot = createRotation(math.rad(xDegrees), math.rad(yDegrees),
            math.rad(zDegrees))

        local zPos = hitPos.z
        if (zPosLock == 1) then
            zPosLock = currentMainRef.position.z
            -- config.print("Now locked")
        elseif (zPosLock == 0) then --do nothing
            -- config.print("Not locked")
        else
            zPos = zPosLock
            -- config.print("Is locked")
        end
        if (currentMainRef == nil) then
            return
        end
        local index
        if not selectedItemIsReal then
            index = activeObjectTypes[selectedIndex].Static_ID
        else
            index = currentMainRef.recordId
        end
        local findOb = findObjectById(index)
        if (findOb) then
            if (findOb.Grid_Size > 0) then
                zDegrees = normalize_degrees(math.floor((zDegrees + 45) / 90) * 90)
            end
        end

        local grid = false
        if (findOb) then
            zOffset = findOb.Z_Offset --hitObject.position.z - hitObject.boundingBox.min.z

            -- zOffset = findOb.Z_Offset
            gridSize = findOb.Grid_Size
            grid = gridSize > 0
        end
        if (grid and gridRefOb == nil) then
            --  config.print("grid ref ob is nil")
            grid = false
        end
        local toPos, toRotX = getPosToPlace(grid, hitPos, zPos, dist, zOffset, v, pos, hitObReal)

        if not I.BFMT_Cam.isInOverheadMode() or not selectedItemIsReal and not blockPosUpdate then
            BuildMode.updateTargetPos(toPos, toRot)
        end
        if (currentCategory ~= nil and currentSubCat ~= nil) then
            if (toPos) then
                local zPos = toPos.z
                if (zPosLock > 0) then
                    zPos = zPosLock
                end

                if hitPos and hitObject and toPos then
                    if (toRotX ~= nil) then
                        toRot = toRotX
                    end
                    -- teleportTempItem(util.vector3(toPos.x, toPos.y, zPos), toRot)
                end
            end
        end
    end
end
local delayCheck = 0
local function camMovement(offset, delay)
    if wallBuilding then return end
    if not currentMainRef then return end
    if not selectedItemIsReal then
        return
    end
    local zPressed = input.isKeyPressed(input.KEY.Z)
    local xPressed = input.isKeyPressed(input.KEY.X)
    local yPressed = input.isKeyPressed(input.KEY.Y)
    local mult = 0.1
    local findOb = getCurrentObjData()
    local toPos
    local addAmount
    if findOb and findOb.Grid_Size > 0 then
        addAmount = findOb.Grid_Size / 8
        if delayCheck > 0 then
            mult = 0
            delayCheck = delayCheck - delay
            return
        else
            delayCheck = 0.1
        end
        if offset.y < 0 then
            addAmount = -addAmount
        end
    else
        addAmount = offset.y * mult
    end
    if zPressed then
        toPos = util.vector3(currentMainRef.position.x, currentMainRef.position.y,
            currentMainRef.position.z + addAmount)
    elseif yPressed then
        toPos = util.vector3(currentMainRef.position.x, currentMainRef.position.y + addAmount,
            currentMainRef.position.z)
    elseif xPressed then
        toPos = util.vector3(currentMainRef.position.x + addAmount, currentMainRef.position.y,
            currentMainRef.position.z)
    else
        toPos = getPositionBehind(currentMainRef.position, { z = I.BFMT_Cam.getcurrentCamRot() }, offset.x * mult,
            "north")
        toPos = getPositionBehind(toPos, { z = I.BFMT_Cam.getcurrentCamRot() }, addAmount, "west")
    end
    local toRot = createRotation(math.rad(xDegrees), math.rad(yDegrees),
        math.rad(zDegrees))
    BuildMode.updateTargetPos(toPos, toRot)
    -- currentCamObjPos = util.vector3(currentCamObjPos.x - (offset.x * mult),currentCamObjPos.y - (offset.y * mult),currentCamObjPos.z)
end
local function onSave()
    buildModeEnabled = false
    updateBuildModeState()
end
local function onConsoleCommand(mode, command, object)
    if (command == "movetovoid") then
        zutils.teleportItemToCell(self, "Infinite Abyss", self.position, self.rotation)
    end
end

--Need to create crafting interface.
local function setSelectedObj(obj)
    setCurrentMainRef(obj)
end
local function getCurrentMainRef()
    return currentMainRef
end
local function getTarget()
    local origin = camera.getPosition()
    local direction = camera.viewportToWorldVector(util.vector2(0.5, 0.5))

    local result = nearby.castRay(
        origin,
        origin + direction * camera.getViewDistance()
    )

    if (result) then return result.hitObject end
end
return {
    interfaceName = "MoveObjects",
    interface = {
        handleInput             = handleInput,
        convertStringToTable    = convertStringToTable,
        version                 = 1,
        registerDefaultBindings = registerDefaultBindings,
        getActiveObjectTypes    = function() return activeObjectTypes end,
        getCurrentMainRef       = getCurrentMainRef,
        --  onInputAction = onInputAction,
        camMovement             = camMovement,
        getTarget               = getTarget,
        refreshStoredData       = refreshStoredData,
        getBuildModeState = function ()
            return buildModeEnabled
        end
    },
    eventHandlers = {
        StartControlMode    = StartControlMode,
        createItemReturn_AA = createItemReturn_AA,
        permaObjectStore    = permaObjectStore,
        setSelectedObj      = setSelectedObj,
        UiModeChanged       = function(data)
            if not data.newMode and I.BFMT_Cam.isInOverheadMode() then
                -- I.UI.setMode("Interface", { windows = {} })
                I.BFMT_Cam.exitCamMode()
                I.ControlsZack.overrideMovementControls(false)
            end
        end,
        unblockPosUpdate = function()

            blockPosUpdate = false
        end,
    },
    engineHandlers = {
        --   onInputAction = onInputAction,
        --onControllerButtonPress = onControllerButtonPress,
        -- onControllerButtonRelease = onControllerButtonRelease,

        onMouseWheel = onMouseWheel,
        --^TEMP
        onUpdate = onUpdate,
        onKeyPress = onKeyPress,
        onFrame = onFrame,
        onConsoleCommand = onConsoleCommand,
        onLoad = onLoad,
        onSave = onSave,
        onInit = onLoad,
    }
}
