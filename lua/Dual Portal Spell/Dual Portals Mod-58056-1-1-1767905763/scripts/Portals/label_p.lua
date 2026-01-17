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
local Camera = require("openmw.camera")
local input = require("openmw.input")
local ui = require("openmw.ui")
local ambient = require("openmw.ambient")
local async = require("openmw.async")
local activeObjectTypes = {}
local myModData = storage.globalSection("MoveObjectsCellGen")
local settlementModData = storage.globalSection("AASettlements")
local cellGenStorage = storage.globalSection("AACellGen2")

local settlementModData = storage.globalSection("AASettlements")

local renameWindow = nil
local uithing = nil

local currentSettlement = nil

local bedCount = 0

local genModData = storage.globalSection("MoveObjectsCellGen")

local currentCategory = nil --if nil, then show the category selection level
local currentSubCat = nil   --if nil, but above isn't, show subcategories.
local function anglesToV(pitch, yaw)
    local xzLen = math.cos(pitch)
    return util.vector3(
        xzLen * math.sin(yaw), -- x
        xzLen * math.cos(yaw), -- y
        math.sin(pitch)        -- z
    )
end
local function getCameraDirData()
    local pos = Camera.getPosition()
    local pitch, yaw

    pitch = -(Camera.getPitch() + Camera.getExtraPitch())
    yaw = (Camera.getYaw() + Camera.getExtraYaw())

    return pos, anglesToV(pitch, yaw)
end
local function startsWith(str, prefix)
    return string.sub(str, 1, string.len(prefix)) == prefix
end

local function getPosInCrosshairs(mdist)
    local pos, v = getCameraDirData()

    local dist = 500
    if (mdist ~= nil) then
        dist = mdist
    end

    return pos + v * dist
end
local function isObjectInTable(obj, table)
    for i, value in ipairs(table) do
        if value == obj then
            return true
        end
    end
    return false
end
local useRenderingRay = true
local function getObjInCrosshairs(ignoreObjects, maxDistance, forceRay, collisionType, ignoreList)
    collisionType = collisionType or nearby.COLLISION_TYPE.AnyPhysical

    if ignoreObjects and type(ignoreObjects) ~= "table" then
        ignoreObjects = { ignoreObjects }
    end
    if ignoreList then
        if not ignoreObjects then
            ignoreObjects = {}
        end
        for index, obj in ipairs(ignoreList) do
            table.insert(ignoreObjects, obj)
        end
    end

    local position, direction = getCameraDirData() -- Get camera position and direction
    local startPosition = position + direction * 50
    local distance = maxDistance or 500

    local ret -- Declare ret outside the if-else structure

    if ignoreObjects and not forceRay and useRenderingRay == false then
        -- Perform a normal ray cast when not forced to use rendering ray
        ret = nearby.castRay(startPosition, position + direction * distance, {
            ignore = ignoreObjects,
            collisionType = collisionType,
        })
    else
        -- Choose the ray casting method based on useRenderingRay flag
        if useRenderingRay then
            ret = nearby.castRenderingRay(startPosition, position + direction * distance, { ignore = ignoreObjects })
            if not ret or not ret.hitPos then
                ret = nearby.castRay(startPosition, position + direction * distance, {
                    ignore = ignoreObjects,
                    collisionType = collisionType,
                })
            end
        else
            ret = nearby.castRay(startPosition, position + direction * distance, {
                ignore = ignoreObjects,
                collisionType = collisionType
            })
        end
    end

    -- Handle case where ret.hitPos is nil by creating a new table to return
    if not ret or not ret.hitPos then
        -- Cannot modify ret directly, so return a new table
        return {
            hitPos = position + direction * distance,
            hitObject = nil -- Assume no object was hit if hitPos was not originally returned
        }
    else
        return ret
    end
end
local function getDoorDestinationStr(obj)
    local check = cellGenStorage:get("doorData")[obj.id]
    if check then
        local name = cellGenStorage:get("cellNames")[check.targetCell]
        if name then
            return name, check.targetCell
        end
        local settlmenetCheck = getCurrentSettlementName()
        if check.targetCell ~= self.cell.name and settlmenetCheck then
            return settlmenetCheck, check.targetCell
        end
        return check.targetCell, check.targetCell
    end
end
local renameWindow = nil
local uithing = nil


local doorToActivate = nil
local doorDelay = -1

local function playDoorSound(door)
    local doorSoundMap = cellGenStorage:get("doorSoundMap")
    local val = doorSoundMap[door.recordId]
    if not val then return end
    ambient.playSound(val)
end
local function renderItemBold(item, bold)
    local template = I.MWUI.templates.textHeader

    return {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Center,
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = template,
                        props = {
                            text = item,
                            arrange = ui.ALIGNMENT.Center
                        }
                    }
                }
            }
        }
    }
end
local function renderItem(item, bold)
    return {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Center,
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = item,
                            arrange = ui.ALIGNMENT.Center
                        }
                    }
                }
            }
        }
    }
end
local function renderItemChoice(itemList, currentItem, small)
    local vertical = 0
    local horizontal = ui.layers[1].size.x / 2 - 100
    if (small == true) then
        horizontal = ui.layers[1].size.x / 2 - 25
        vertical = vertical + ui.layers[1].size.y / 2 - 100
    else
    end
    local content = {}
    for _, item in ipairs(itemList) do
        if item == currentItem then
            local itemLayout = renderItemBold(item)
            itemLayout.template = I.MWUI.templates.padding
            table.insert(content, itemLayout)
        else
            local itemLayout = renderItem(item)
            itemLayout.template = I.MWUI.templates.padding
            table.insert(content, itemLayout)
        end
    end
    return ui.create {
        layer = "HUD",
        template = I.MWUI.templates.boxTransparent,
        props = {
            relativePosition = v2(0.5, 0.05),
            anchor = v2(0.5, 0.5),
            --position = v2(horizontal, vertical),
            arrange = ui.ALIGNMENT.Center
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    vertical = true,
                    arrange = ui.ALIGNMENT.Center
                }
            }
        }
    }
end
local currentText = ""
local buttonContext = ""
local doorID = ""
local function textChanged(firstField)
    currentText = (firstField)
end
local baseCell
local function buttonClick()
    print(currentText)
    core.sendGlobalEvent("cellRename2", { text = currentText, context = buttonContext, originalCell = baseCell })
    renameWindow:destroy()
    I.UI.setMode()
end

local function destroyWindow()
    renameWindow:destory()
end
local activePortal
local function onInputAction(id)
    if id == input.ACTION.Activate then
        if activePortal then
            core.sendGlobalEvent("ActivatePortal",{portal = activePortal})

        end
    end
end
local cellGenStorage = storage.globalSection("AACellGen2")


local function getCellName(baseCellName)
    if not cellGenStorage:get("cellNames")[baseCellName] then
        return baseCellName
    else
        return cellGenStorage:get("cellNames")[baseCellName] 
    end
end
local function onFrame()
    --      renderItemChoice({"Banana","Box","Pizza"},"Box")
    local obj = getObjInCrosshairs(nil, 250).hitObject
    local targetCell = nil
    if (uithing) then
        uithing:destroy()
    end
    if (obj == nil) then
        activePortal = nil
        return
    end

    local doorSoundMap = I.Portal.getLabelData()
    if not doorSoundMap[obj.id] then
        activePortal = nil
        return
    else
        targetCell = doorSoundMap[obj.id]
    end
    activePortal = obj
    if (targetCell == nil) then
        return
    end
    uithing = renderItemChoice({ "Portal", "to", targetCell }, "Portal")
end
local function getLabelForCell()

    return self.cell.name
end
local function playClap()
    ambient.playSound("Thunderclap")
end
return {
    interfaceName = "Portal_Labels",
    interface = {
        version = 1,
        createWindow = createWindow,
        destroyWindow = destroyWindow,
        getLabelForCell = getLabelForCell
    },
    eventHandlers = {
        UiModeChanged = function(data)
            -- print('LMMUiModeChanged to', data.newMode, '(' .. tostring(data.arg) .. ')')
            if renameWindow ~= nil and data.newMode == nil then
                renameWindow:destroy()
            end
        end,
        playClap = playClap,

    },
    engineHandlers = {
        onFrame = onFrame,
        onInputAction = onInputAction,
        onSave = onSave,
    }
}
