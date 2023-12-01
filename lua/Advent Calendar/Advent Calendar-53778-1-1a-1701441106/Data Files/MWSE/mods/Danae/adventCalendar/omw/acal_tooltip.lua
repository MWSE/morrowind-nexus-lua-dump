local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local config = require("MWSE.mods.Danae.adventCalendar.config")
local dateStrings = require("MWSE.mods.Danae.adventCalendar.dateStrings")
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
local PLAYER_WIDTH = 10

local Actor = require("openmw.types").Actor
local boxData = {}
local uithing
local records = {}
local function getRecord(id)
    if records[id] then
        return records[id]
    end
    for index, type in pairs(types) do
        if type.record then
            local rec = type.record(id)
            if rec then
                records[id] = rec
                return rec
            end
        end
    end
end
local function renderItem(item)
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
    if t.recordId == "aa_xmas_ap_shelves" then
        return true
    end
    return t == self.object
end
local function getObjInCrosshairs()
    local pos, v = getCameraDirData()
    local dist = 300
    local result = nearby.castRenderingRay(pos, pos + v * dist)

    if result.hitPos then
        
        --ui.showMessage(tostring(result.hitPos))
        if result.hitObject then
          --  ui.showMessage(result.hitObject.recordId)
        end
    end
    -- Ignore player if in 3rd person
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

local function getIsOpened(reference)
    return boxData[reference.id] == true
end

local function addToTooltip(tooltip, message)
    table.insert(tooltip, message)
end
local function checkCanOpen(boxConfig)
    local currentDate = os.date("*t", os.time())
    local minimumDate = boxConfig.minimumDate
    local canOpen = currentDate.month >= minimumDate.month
        and currentDate.day >= minimumDate.day
    return canOpen
end
local function onTooltip(obj)
    local boxId = obj.recordId
    local boxConfig = config.boxes[boxId]
    if not boxConfig  then return end
    local record = getRecord(obj.recordId)
    if  not record then return end
    local e = {}
    e.tooltip = {}
    
    if boxConfig then
        local boxRef = obj
        if checkCanOpen(boxConfig) then
            if getIsOpened(boxRef) then
                table.insert(e.tooltip, config.messages.alreadyOpened)
            else
                table.insert(e.tooltip, config.messages.canOpen)
            end
        else
            local day = dateStrings.days[boxConfig.minimumDate.day]
            local month = dateStrings.months[boxConfig.minimumDate.month]
            table.insert(e.tooltip, string.format("Open on %s %s", day, month))
        end
    end
    return e.tooltip
end
local function onFrame(dt)
    --      renderItemChoice({"Banana","Box","Pizza"},"Box")
    local obj = getObjInCrosshairs()
    if (uithing) then
        uithing:destroy()
    end
    if dt == 0 then return end
    if obj and config.boxes[obj.recordId] then
        local boxId = obj.recordId
        local tooltip = onTooltip(obj)
        if tooltip then
            
            local text = {  }
            uithing = renderItemChoice(tooltip, tooltip[1], true)
        end
        --uithing.layout.content[1].content[2].horizontal = true
    elseif obj then
       -- ui.showMessage(obj.recordId)
    end
end


return {
    eventHandlers = {
        setBoxData = function(data) boxData = data end,
    },
    engineHandlers = {
onFrame = onFrame
    }
}
