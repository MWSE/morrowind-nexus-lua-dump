local ui = require("openmw.ui")
local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local Camera = require("openmw.camera")
local input = require("openmw.input")
local storage = require("openmw.storage")

local Actor = require("openmw.types").Actor
local myModData = storage.globalSection("MundisData")

local buttonDest = nil
local PLAYER_WIDTH = 100
local sneakState = false
local function getSneakState()

    if core.API_REVISION > 29 then
        return self.controls.sneak
    else
        return sneakState
    end

end
local function renderItem(item)
    local template = I.MWUI.templates.textNormal
    if (input.isActionPressed(input.ACTION.Sneak)) then
        template = I.MWUI.templates.textHeader
    end
    if (input.isCtrlPressed()) then
        template = I.MWUI.templates.textHeader
    end
    return {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = template,
                        props = {
                            text = item.recordId,
                            arrange = ui.ALIGNMENT.Center
                        }
                    }
                }
            }
        }
    }
end
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
local function isSelf(t)
    return t == self.object
end
local function getObjInCrosshairs()
    local pos, v = getCameraDirData()
    local dist = 200
    local result = nearby.castRenderingRay(pos, pos + v * dist)
    -- Ignore player if in 3rd person
    if result.hitObject and isSelf(result.hitObject) then
        result = nearby.castRenderingRay(result.hitPos + v * PLAYER_WIDTH, result.hitPos + v * (PLAYER_WIDTH + dist))
    end
    -- Get approximated area. Note that this allows you to aim through walls, because we can't distinguish floor and wall

    return result.hitObject
end
local function renderItemBold(item, bold)
    local template = I.MWUI.templates.textHeader
    if (input.isCtrlPressed()) then
        --template = I.MWUI.templates.textHeader
    end
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

local function renderItemChoice(itemList, horizontal, vertical, align, anchor)
    local content = {}
    for _, item in ipairs(itemList) do
        local itemLayout = renderItem(item)
        itemLayout.template = I.MWUI.templates.padding
        table.insert(content, itemLayout)
    end
    return ui.create {
        layer = "HUD",
        template = I.MWUI.templates.boxTransparent,
        props = {
            -- relativePosition = v2(0.65, 0.8),
            anchor = anchor,
            relativePosition = v2(horizontal, vertical),
            arrange = align,
            align = align,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    vertical = true,
                    arrange = align,
                    align = align,
                }
            }
        }
    }
end
local function renderItemChoice(itemList, currentItem, small)
    local align = ui.ALIGNMENT.Center
    local vertical = 0
    local horizontal = 0.5 --ui.screenSize().x / 2 - 100
    local arrange = align
    if (small == true) then
        horizontal = 0.5 --ui.screenSize().x / 2 - 25
        vertical = 0.5
    else
        arrange = ui.ALIGNMENT.Start
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
            -- relativePosition = v2(0.65, 0.8),
            --  anchor = v2(0.5,0.5),
            relativePosition = v2(horizontal, vertical),
            anchor = v2(horizontal, vertical),
            arrange = arrange,
            align = align,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    vertical = true,
                    arrange = align,
                    relativePosition = v2(0.5, 0.5),
                    align = align,
                }
            }
        }
    }
end
local uithing
local function onConsoleCommand(mode, command, selectedObject) --test commands
    if command == "luaship" then
        core.sendGlobalEvent("airshipTeleport", self)
    elseif command == "luaui" then
        uithing = renderItemChoice({ "Box" }, "Box")
    elseif command == "luastop" then
        uithing:destroy()
    end
end
local function sendMessage(eventData)
    --ui.showMessage(eventData)
end

local function onFrame()
    --      renderItemChoice({"Banana","Box","Pizza"},"Box")
    local obj = getObjInCrosshairs()
    if (uithing) then
        uithing:destroy()
    end
    if obj and obj.recordId == "mundis_3_exitdoor" then
        local currData = nil
        for index, value in ipairs(myModData:get("MUNDISLocData")) do
            if value.ID == myModData:get("LocIndex") then
                currData = value
            end
        end
        if currData then
            local dest = currData.cellData.cellLabel
            uithing = renderItemChoice({ "Reinforced Wooden Door", "to", dest }, "Reinforced Wooden Door")
        end
    elseif obj and obj.recordId == "zhac_button_mundis_curr" then
        local mdata = myModData:get("MUNDISLocData")
        if not buttonDest then
            buttonDest = myModData:get("LocIndex")
        end

        print(buttonDest)
        for index, dataItem in ipairs(mdata) do
            if (dataItem.ID == buttonDest) then
                local text = { dataItem.cellData.cellLabel }
                if getSneakState() then
                    local currData
                    for index, dataItemx in ipairs(mdata) do
                        if dataItemx.ID == myModData:get("LocIndex") then
                            currData = dataItemx
                        end
                    end
                    if not currData then
                        table.insert(text, "Activate to change to " .. tostring(myModData:get("LocIndex")))
                    else
                        table.insert(text, "Activate to change to " .. currData.cellData.cellLabel)
                    end
                end
                uithing = renderItemChoice(text, text[1], true)
            end
        end
    elseif obj then
        local mdata = myModData:get("MUNDISLocData")
        local bdata = myModData:get("buttonData")
        if bdata and bdata[obj.recordId] then
            if bdata[obj.recordId] == -1 then
                local text = { "-Not Set-" }
                if getSneakState() then
                    local currData
                    for index, dataItemx in ipairs(mdata) do
                        if dataItemx.ID == myModData:get("LocIndex") then
                            currData = dataItemx
                        end
                    end
                    if not currData then
                        table.insert(text, "Activate to change to " .. tostring(myModData:get("LocIndex")))
                    else
                        table.insert(text, "Activate to change to " .. currData.cellData.cellLabel)
                    end
                end
                uithing = renderItemChoice(text, text[1], true)
                return
            end
            for index, dataItem in ipairs(mdata) do
                if (dataItem.ID == bdata[obj.recordId]) then
                    local text = { dataItem.cellData.cellLabel }
                    if getSneakState() then
                        local currData
                        for index, dataItemx in ipairs(mdata) do
                            if dataItemx.ID == myModData:get("LocIndex") then
                                currData = dataItemx
                            end
                        end
                        if not currData then
                            table.insert(text, "Activate to change to " .. tostring(myModData:get("LocIndex")))
                        else
                            table.insert(text, "Activate to change to " .. currData.cellData.cellLabel)
                        end
                    end
                    uithing = renderItemChoice(text, text[1], true)
                end
            end
        end
        --uithing.layout.content[1].content[2].horizontal = true
    end
end
local wasPressing = false
local function onInputAction(id)
    if id == input.ACTION.Activate then
        local obj = getObjInCrosshairs()
        if (obj) then
            local mdata = myModData:get("MUNDISLocData")
            local bdata = myModData:get("buttonData")
            if bdata and bdata[obj.recordId] then
                local changeMe = false

                if getSneakState() then
                    local currData
                    for index, dataItemx in ipairs(mdata) do
                        if dataItemx.ID == myModData:get("LocIndex") then
                            core.sendGlobalEvent("setButtonDest", { buttonId = obj.recordId, newId = dataItemx.ID })
                            return
                        end
                    end
                end
                for index, dataItem in ipairs(mdata) do
                    if (dataItem.ID == bdata[obj.recordId]) then
                        core.sendGlobalEvent("checkButtonText", dataItem.ID)
                    end
                end
            elseif (obj.recordId == "mundis_3_exitdoor") then
                core.sendGlobalEvent("exitMundisFunc", { 2, self })
            elseif obj.recordId == "zhac_button_mundis_prev" then
                local mdata = myModData:get("MUNDISLocData")
                local lastId = buttonDest
                for index, dataItem in ipairs(mdata) do
                    if (dataItem.ID == buttonDest) then
                        buttonDest = lastId.ID
                        ui.showMessage(string.format("%g: %s", lastId.ID,lastId.cellData.cellLabel))
                        
                        return
                    else
                        lastId = dataItem
                    end
                end
            elseif obj.recordId == "zhac_button_mundis_curr" then
                local mdata = myModData:get("MUNDISLocData")
                for index, dataItem in ipairs(mdata) do
                    if (dataItem.ID == buttonDest) then
                        core.sendGlobalEvent("checkButtonText", dataItem.ID)
                        
                        return
                    end
                end
            elseif obj.recordId == "zhac_button_mundis_next" then
                local mdata = myModData:get("MUNDISLocData")
                local next = false
                local lastId = buttonDest
                for index, dataItem in ipairs(mdata) do
                    if (dataItem.ID == buttonDest) then
                        next = true
                    elseif next then
                        buttonDest = dataItem.ID
                        ui.showMessage(string.format("%g: %s", dataItem.ID,dataItem.cellData.cellLabel))
                        return
                    end
                end
            end
        end
    elseif id == input.ACTION.Sneak then
        sneakState = true
    end
end
local function onKeyRelease()
    sneakState = false
end
local function onLoad(data)
    if data then buttonDest = data.buttonDest end
end
local function setPlayerControlState(state)
    
if core.API_REVISION > 29 then 
    I.Controls.overrideMovementControls(not state)
    end
end
local function showMessageMundis(message)
    ui.showMessage(message)
end
local function onSave()
    return { buttonDest = buttonDest }
end
return {
    eventHandlers = {
        sendMessage = sendMessage,
        returnActivators = returnActivators,
        recieveActivators = recieveActivators,
        setPlayerControlState = setPlayerControlState,
        showMessageMundis = showMessageMundis,
    },
    engineHandlers = {
        onFrame = onFrame,
        onInputAction = onInputAction,
        onSave = onSave,
        onLoad = onLoad,
        onKeyRelease = onKeyRelease,
    }
}
