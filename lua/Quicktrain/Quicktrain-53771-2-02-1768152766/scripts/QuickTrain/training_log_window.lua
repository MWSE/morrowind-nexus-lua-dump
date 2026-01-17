local I = require("openmw.interfaces")
local ambient = require('openmw.ambient')
local async = require("openmw.async")
local core = require("openmw.core")
local self = require("openmw.self")
local ui = require("openmw.ui")
local util = require("openmw.util")
local types = require("openmw.types")
local input = require("openmw.input")


local trainingLogWindow
local hoveredOverId
local columnsAndRows = {}
local selectedCol = 1
local selectedRow = 1

local scale = 0.8
local function scaledVector2(x,y)
return util.vector2(x * scale * 0.90, y * scale)
end
local function mouseMove(mouseEvent, data)
    local id = data.id
    if hoveredOverId ~= id then
        hoveredOverId = id
        for attributeIndex, attribute in ipairs(columnsAndRows) do
            for skillIndex, skill in ipairs(attribute) do
                if skill == id then
                    selectedCol = attributeIndex
                    selectedRow = skillIndex
                    I.TrainingLogWindow.drawTrainingLog()
                    return
                end
            end
        end
        I.TrainingLogWindow.drawTrainingLog()
    end
end
local function flexedItems(content, horizontal)
    if not horizontal then
        horizontal = false
    end
    return ui.content {
        {
            type = ui.TYPE.Flex,
            content = ui.content(content),
            events = {
                mouseMove = async:callback(mouseMove),
            },
            props = {
                horizontal = horizontal,
                align = ui.ALIGNMENT.Start,
                arrange = ui.ALIGNMENT.Start,
                --     size = util.vector2(100, 100),
                autosize = true
            }
        }
    }
end
local function renderItemBold(item, bold, id, tooltipData)
    if not id then id = item end
    local textTemplate = I.MWUI.templates.textNormal
    if bold or hoveredOverId == id then
        textTemplate = I.MWUI.templates.textHeader
    end
    return {
        type = ui.TYPE.Container,
        id = id,
        tooltipData = tooltipData,
        props = {
            --  anchor = util.vector2(-1,0),
            align = ui.ALIGNMENT.Center,
            relativePosition = util.vector2(1, 0.5),
            arrange = ui.ALIGNMENT.Center,
        },
        events = {
            mouseMove = async:callback(mouseMove),
          --  mousePress = async:callback(mouseClick),
        },
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Center,
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = textTemplate,
                        props = {
                            text = item,
                            textSize = 15 * scale,
                            relativePosition = util.vector2(0.5, 0.5),
                            arrange = ui.ALIGNMENT.Center,
                            align = ui.ALIGNMENT.Center,
                        }
                    }
                }
            }
        }
    }
end

local function renderButton(text)
    local itemTemplate
    itemTemplate = I.MWUI.templates.boxThick

    return {
        type = ui.TYPE.Container,
      --  events = {},
        template = itemTemplate,
        content = ui.content { renderItemBold(text) },
    }
end
local function renderItemBoxed(content, size, itemTemplate)
    local text
    if not size then
        size = scaledVector2(100, 100)
    end
    if not itemTemplate then
        itemTemplate = I.MWUI.templates.boxThick
    end

    return {
        type = ui.TYPE.Container,
    --    events = {},
        template = itemTemplate,
        content = ui.content {
            {
                props = {
                    size = size,
                    relativePosition = util.vector2(0.5,0.5)
                },
                content = content
            },
        },
    }
end
local function getSkillBase(skillID, actor)
    return types.NPC.stats.skills[skillID:lower()](actor).base
end
local function getAttributeMultipler(attributeId)
    local currentLevel = types.Actor.stats.attributes[attributeId](self).base
    local multipler = math.floor(types.Actor.stats.level(self).skillIncreasesForAttribute[attributeId] / 2)
    if multipler == 0 then
        multipler = 1
    elseif multipler > 5 then
        multipler = 5
    end
    
    if currentLevel + multipler > 100 then
        multipler =( currentLevel + multipler) - 100
    end
    return multipler
end
local function drawTrainingLog()
    if trainingLogWindow then
        trainingLogWindow:destroy()
    end
    local xContent = {}
    local content  = {}
    for attributeIndex, attribute in pairs(core.stats.Attribute.records) do
        local mySkills = {}
        local attribContent = {}
        local modifier = getAttributeMultipler(attribute.id)
        local attribName = tostring(attribute.name ..": " .. tostring( types.Actor.stats.attributes[attribute.id](self).base) )
        table.insert(attribContent, renderItemBold(attribName, true))
        table.insert(attribContent, renderItemBold("(Level Modifier x" .. tostring(modifier) .. ")", false))
        local skillIndex = 0
        if not columnsAndRows[attributeIndex] then
            columnsAndRows[attributeIndex] = {}
        end
        for index, skill in pairs(core.stats.Skill.records) do
            if skill.attribute == attribute.id then
                skillIndex = skillIndex + 1

                if not columnsAndRows[attributeIndex][skillIndex] then
                    columnsAndRows[attributeIndex][skillIndex] = skill.name
                end
                local skillname = tostring(skill.name)
                --   local skillBase = getSkillBase(skill.id,self)
                --  local formattedString = string.format("%-10s: %d", skillname, skillBase)

                table.insert(mySkills, skillname)
                table.insert(attribContent, renderItemBold(skillname))
            end
        end
        if #mySkills > 0 then
            table.insert(xContent, renderItemBoxed(flexedItems(attribContent, false), scaledVector2(200, 180)))
        end
    end
    local attributeColumns = renderItemBoxed(flexedItems(xContent, true), util.vector2((160 * scale) * 8, 250 * scale),
        I.MWUI.templates.padding)
    local headerText       = renderItemBold("Training Log", true)
    table.insert(content, headerText)
    table.insert(content, attributeColumns)
    local knownTrainers = {}
    local spacelessId = ""
    for i, item in ipairs(core.stats.Skill.records) do
        if item.name == hoveredOverId then
            spacelessId = item.id
            break
        end
    end
    if hoveredOverId and core.stats.Skill.record(spacelessId) then
        table.insert(knownTrainers, renderItemBold(hoveredOverId .. ": " .. getSkillBase(spacelessId, self)))
        table.insert(knownTrainers, renderItemBold("Known Trainers:"))
        local data = I.TrainingLog.getSkillData(hoveredOverId)
        for i = 1, 10, 1 do
            if data[i] then
                table.insert(knownTrainers, renderItemBold(data[i].line))
            else
                table.insert(knownTrainers, renderItemBold(""))
            end
        end
    else
        for i = 1, 12, 1 do
            table.insert(knownTrainers, renderItemBold(""))
        end
    end
    local trainerRow = renderItemBoxed(flexedItems(knownTrainers, false),  util.vector2((160 * scale) * 7, 400 * scale),
        I.MWUI.templates.padding)
    table.insert(content, trainerRow)
    -- table.insert(content, imageContent(resource, size))
    trainingLogWindow = ui.create {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick
        ,
        props = {
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.5),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    horizontal = false,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                    size = util.vector2(0, 0),
                }
            }
        }
    }
end

local function openTrainingLog()
    --I.UI.setMode("Interface", { windows = {} })
    drawTrainingLog()
end

local function UiModeChanged(data)
    local newMode = data.newMode
    local arg = data.arg
    if newMode == "Training" then
    elseif not newMode and trainingLogWindow then
        trainingLogWindow:destroy()
        trainingLogWindow = nil
    elseif newMode ~= "Scroll" and trainingLogWindow then

        trainingLogWindow:destroy()
        trainingLogWindow = nil
    end
end

local function onKeyPress(key)
    if not trainingLogWindow then return end

    local nextCol = selectedCol
    local nextRow = selectedRow
    if key.code == input.KEY.LeftArrow then
        nextCol = nextCol - 1
    elseif key.code == input.KEY.RightArrow then
        nextCol = nextCol + 1
    elseif key.code == input.KEY.DownArrow then
        nextRow = nextRow + 1
    elseif key.code == input.KEY.UpArrow then
        nextRow = nextRow - 1
    end
    if not columnsAndRows[nextCol] or not columnsAndRows[nextCol][nextRow] then

    else
        hoveredOverId = columnsAndRows[nextCol][nextRow]
        selectedCol = nextCol
        selectedRow = nextRow
        drawTrainingLog()
    end
end
local function onControllerButtonPress(id)
    if not trainingLogWindow then return end

    local nextCol = selectedCol
    local nextRow = selectedRow
    if id == input.CONTROLLER_BUTTON.DPadLeft then
        nextCol = nextCol - 1
    elseif id == input.CONTROLLER_BUTTON.DPadRight then
        nextCol = nextCol + 1
    elseif id == input.CONTROLLER_BUTTON.DPadDown then
        nextRow = nextRow + 1
    elseif id == input.CONTROLLER_BUTTON.DPadUp then
        nextRow = nextRow - 1
    end
    if not columnsAndRows[nextCol] or not columnsAndRows[nextCol][nextRow] then

    else
        hoveredOverId = columnsAndRows[nextCol][nextRow]
        selectedCol = nextCol
        selectedRow = nextRow
        drawTrainingLog()
    end
end
return {

    interfaceName = "TrainingLogWindow",
    interface = {
        drawTrainingLog = drawTrainingLog,
        openTrainingLog = openTrainingLog,
    },
    eventHandlers = {
        UiModeChanged = UiModeChanged,
        drawTrainingLog = drawTrainingLog,
        openTrainingLog = openTrainingLog,
    },
    engineHandlers = {
        onKeyPress = onKeyPress,
        onControllerButtonPress = onControllerButtonPress,
    }
}
