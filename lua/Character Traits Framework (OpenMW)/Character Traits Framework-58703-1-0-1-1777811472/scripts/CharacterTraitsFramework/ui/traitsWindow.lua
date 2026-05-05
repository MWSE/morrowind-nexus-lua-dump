---@diagnostic disable: missing-fields
local ui = require('openmw.ui')
local auxUi = require("openmw_aux.ui")
local util = require('openmw.util')
local v2 = util.vector2
local I = require("openmw.interfaces")
local self = require("openmw.self")
local storage = require("openmw.storage")

local buttonTemplate = require("scripts.CharacterTraitsFramework.ui.templates.button")
local VirtualList = require("scripts.CharacterTraitsFramework.ui.templates.virtual_list.extras").VirtualListExt
local settings = storage.playerSection("SettingsCharacterTraitsFramework")

-- can be edited
local textSize = 16
local contentWidth = 750
local traitListWidthFraction = .35
local traitListWidth = contentWidth * traitListWidthFraction
local descriptionWidth = contentWidth - traitListWidth
local contentHeight = 450
-- don't touch
local topPadding = 8
local contentOuterPadding = 4
local contentCenterPadding = 6
local rootWidth = contentWidth + contentOuterPadding * 2 + contentCenterPadding
local startIdx = 1

local availableTraits = 0

local traitsWindow = {}

local function padding(x, y)
    return {
        props = {
            size = util.vector2(x, y)
        }
    }
end

local function borderPadding(content, size)
    return {
        name = "wrapper",
        template = I.MWUI.templates.borders,
        props = {
            size = size
        },
        content = ui.content {
            {
                name = "padding",
                template = I.MWUI.templates.padding,
                content = ui.content { content }
            }
        }
    }
end

local function itemListSorter(a, b)
    -- Prioritize objects with id == "nil"
    if a.id == "nil" and b.id ~= "nil" then
        return true
    elseif a.id ~= "nil" and b.id == "nil" then
        return false
    end

    -- Fallback to alphabetical sorting by name (case-insensitive)
    return a.name:lower() < b.name:lower()
end


traitsWindow.new = function(traitMap)
    local root

    -- the thing works with indexes, so yeah
    local traitList = {}
    availableTraits = 0
    for _, trait in pairs(traitMap) do
        if trait:checkDisabled() and not settings:get("ignoreRequirements") then
            trait.name = "~ " .. trait.name
        else
            availableTraits = availableTraits + 1
        end
        traitList[#traitList + 1] = trait
    end
    table.sort(traitList, itemListSorter)

    local descWrapper = borderPadding({
            name = "descFlex",
            type = ui.TYPE.Flex,
            props = {
                horizontal = false,
                autoSize = false,
                size = v2(descriptionWidth, contentHeight),
            },
            content = ui.content {
                ui.create {
                    name = "header",
                    template = I.MWUI.templates.textHeader,
                    props = {
                        text = traitList[startIdx].name,
                        textSize = textSize,
                    }
                },
                padding(0, 5),
                ui.create {
                    name = "description",
                    template = I.MWUI.templates.textParagraph,
                    props = {
                        text = traitList[startIdx].description,
                        textSize = textSize,
                    },
                    external = {
                        stretch = .975,
                        grow = 1,
                    }
                },
            }
        },
        v2(descriptionWidth, contentHeight)
    )

    local descFlex = descWrapper.content["padding"].content["descFlex"]
    local descHeader = descFlex.content[1]
    local descBody = descFlex.content[3]

    local function onTraitSelect(list, idx)
        local trait = traitList[idx]

        descHeader.layout.props.text = trait.name
        descBody.layout.props.text = trait.description
        descHeader:update()
        descBody:update()

        list:changeSelection(idx)
    end



    local virtualTraitList
    virtualTraitList = VirtualList.create {
        viewportSize = v2(traitListWidth - 3, contentHeight - 3),
        itemSize = v2(traitListWidth, textSize + 2),
        itemCount = #traitList,
        itemLayout = function(idx, list)
            local itemLayout = list:createItemLayout {
                index = idx,
                props = {
                    text = traitList[idx].name,
                    textSize = textSize,
                },
                onMousePress = function()
                    onTraitSelect(list, idx)
                end,
            }

            return itemLayout
        end,
    }

    virtualTraitList:setKeyPressHandler({
        setSelectedIndex = function(idx)
            onTraitSelect(virtualTraitList, idx)
        end,
    })

    local content = {
        name = "content",
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            align = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            padding(contentOuterPadding, 0),
            borderPadding(virtualTraitList:getElement(), v2(traitListWidth, contentHeight)),
            padding(contentCenterPadding, 0),
            descWrapper,
            padding(contentOuterPadding, 0),
        }
    }

    local header = {
        name = "header",
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = "Select your " .. traitList[startIdx].type,
            textSize = textSize,
        }
    }

    local footer = ui.create {
        name = "footer",
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            size = v2(rootWidth, 0),
            align = ui.ALIGNMENT.End
        },
        content = ui.content {
            buttonTemplate.button(
                "Random",
                textSize,
                function()
                    local idx = math.random(availableTraits)
                    onTraitSelect(virtualTraitList, idx)
                    virtualTraitList:scrollToIndex(idx, "center")
                end,
                "buttonRandom",
                1
            ),
            padding(contentOuterPadding, 0),
            buttonTemplate.button(
                "OK",
                textSize,
                function()
                    local selectedTrait = traitList[virtualTraitList:getSelectedIndex()]
                    if selectedTrait:checkDisabled() and not settings:get("ignoreRequirements") then
                        ui.showMessage("The conditions for this " .. traitList[startIdx].type .. " are not met.")
                    else
                        self:sendEvent(
                            "CharacterTraits_traitSelected",
                            { type = selectedTrait.type, id = selectedTrait.id }
                        )
                        auxUi.deepDestroy(root)
                    end
                end,
                "buttonOk",
                1
            ),
            padding(contentCenterPadding, 0),
        }
    }

    root = ui.create {
        name = "root",
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick,
        props = {
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
        },
        content = ui.content { {
            name = "rootPadding",
            template = I.MWUI.templates.padding,
            content = ui.content { {
                name = "flex_V1",
                type = ui.TYPE.Flex,
                props = {
                    horizontal = false,
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    padding(0, topPadding),
                    header,
                    padding(0, contentOuterPadding),
                    content,
                    padding(0, contentOuterPadding),
                    footer,
                    padding(0, topPadding),
                }
            } }
        } }
    }

    onTraitSelect(virtualTraitList, startIdx)
    root:update()

    return root
end

traitsWindow.getMouseWheelHandler = VirtualList.getMouseWheelHandler

return traitsWindow
