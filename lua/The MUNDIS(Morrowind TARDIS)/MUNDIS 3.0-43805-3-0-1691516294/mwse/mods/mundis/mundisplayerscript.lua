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
local PLAYER_WIDTH = 100

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
    local template = I.MWUI.templates.textNormal
    if (input.isActionPressed(input.ACTION.Sneak)) then
        template = I.MWUI.templates.textHeader
    end
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
local function renderItemChoice(itemList, currentItem, small)
    local vertical = 0
    local horizontal = ui.screenSize().x / 2 - 100
    if (small == true) then
        horizontal = ui.screenSize().x / 2 - 25
        vertical = vertical + ui.screenSize().y / 2 - 100
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
            -- relativePosition = v2(0.65, 0.8),
            --  anchor = v2(-1, -2),
            position = v2(horizontal, vertical),
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
        for i, door in ipairs(nearby.activators) do
            if door.recordId == "mundis_3_soundplayer" then
                --	door:sendEvent("sendSound",2)
                break -- exit the loop once the door is found
            end
        end
        local dest = myModData:get("MUNDISStartData")[myModData:get("LocIndex")].cell
        uithing = renderItemChoice({ "Reinforced Wooden Door", "to", dest }, "Reinforced Wooden Door")
    elseif obj then
        local mdata = myModData:get("MUNDISStartData")
        for index, dataItem in ipairs(mdata) do
            if (dataItem.buttonId) then
                if (string.lower("mundis_switch_" .. dataItem.buttonId) == obj.recordId) then
                    uithing = renderItemChoice({ dataItem.cell }, dataItem.cell, true)
                end
            end
        end
        --uithing.layout.content[1].content[2].horizontal = true
    end
end
local function onInputAction(id)
    --ui.showMessage(id .. "AND THE REST")
    if id == input.ACTION.Activate then
        local obj = getObjInCrosshairs()
        if (obj) then
            local mdata = myModData:get("MUNDISStartData")
            for index, dataItem in ipairs(mdata) do
                if (dataItem.buttonId) then
                    if (string.lower("mundis_switch_" .. dataItem.buttonId) == obj.recordId) then
                        core.sendGlobalEvent("checkButtonText", dataItem.cell)
                        ui.showMessage(dataItem.cell)
                        for i, door in ipairs(nearby.activators) do
                            if door.recordId == "mundis_3_soundplayer" then
                                door:sendEvent("sendSound", 1)
                                break -- exit the loop once the door is found
                            end
                        end
                    end
                end
            end
            if (obj.recordId == "mundis_3_exitdoor") then
                core.sendGlobalEvent("exitMundisFunc", { 2, self })
            end
        end
    end
end
local function onLoad()
end

return {
    eventHandlers = {
        sendMessage = sendMessage,
        returnActivators = returnActivators,
        recieveActivators = recieveActivators
    },
    engineHandlers = {
        onFrame = onFrame,
        onInputAction = onInputAction
    }
}
