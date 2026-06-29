local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local util = require('openmw.util')
local auxUi = require('openmw_aux.ui')
local v2 = util.vector2
local async = require('openmw.async')

local baseTemplates = require('scripts.InventoryExtender.ui.templates.base')
local specialTemplates = require('scripts.InventoryExtender.ui.templates.magic')

local constants = require('scripts.InventoryExtender.util.constants')

-- This template shows a modal dialog for selecting the number of items to move in a stack.

local ItemStackModal = {}

function ItemStackModal.create(params, ctx)
    local maxCount = params.maxCount or 1
    local onConfirm = params.onConfirm or function(count) end

    local selectedCount = params.selectedCount or maxCount
    
    local layout = {
        type = ui.TYPE.Flex,
        props = {
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
        },
        content = ui.content {},
        userData = {},
        events = {},
    }

    layout.content:add({
        template = baseTemplates.textNormal,
        props = {
            text = constants.Strings.TAKE,
        }
    })
    layout.content:add(baseTemplates.intervalV(8))

    local function validate(count)
        local number = tonumber(count)
        if not number then return nil end
        number = util.clamp(util.round(number), 1, maxCount)
        return number
    end

    local textEdit

    local slider = baseTemplates.slider(1, maxCount, selectedCount, 1, 360, function(newCount)
        selectedCount = validate(newCount)
        textEdit.props.text = tostring(selectedCount)
        ctx.modalElement:update()
    end)

    textEdit = {
        template = baseTemplates.textEditLine,
        props = {
            text = tostring(selectedCount),
            size = v2(100, 0),
        },
    }
    textEdit.events = {
        textChanged = async:callback(function(text)
            local number = validate(text)
            if number then
                selectedCount = number
                slider.layout.userData.triggerChange(number)
            end
        end),
        focusLoss = async:callback(function()
            textEdit.props.text = tostring(selectedCount)
            ctx.modalElement:update()
        end),
    }

    layout.content:add({
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = ui.ALIGNMENT.Center,
        },
        external = {
            stretch = 1,
        },
        content = ui.content {
            {
                template = baseTemplates.textNormal,
                props = {
                    text = params.itemName or 'Item',
                }
            },
            {
                external = { grow = 1, stretch = 1, }
            },
            {
                template = I.MWUI.templates.box,
                content = ui.content {
                    {
                        template = I.MWUI.templates.padding,
                        content = ui.content {
                            textEdit
                        }
                    }
                }
            },
        }
    })
    layout.content:add(baseTemplates.intervalV(8))
    layout.content:add(slider)
    layout.content:add(baseTemplates.intervalV(8))

    local buttonFlex = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {},
    }
    buttonFlex.content:add(specialTemplates.interactive({
        onClick = function()
            auxUi.deepDestroy(ctx.modalElement)
            ctx.modalElement = nil
            onConfirm(selectedCount)
        end,
    }, baseTemplates.button(constants.Strings.OK), ctx))
    buttonFlex.content:add(baseTemplates.intervalH(8))
    buttonFlex.content:add(specialTemplates.interactive({
        onClick = function()
            auxUi.deepDestroy(ctx.modalElement)
            ctx.modalElement = nil
        end,
    }, baseTemplates.button(constants.Strings.CANCEL), ctx))

    layout.content:add(buttonFlex)

    if ctx.modalElement then
        auxUi.deepDestroy(ctx.modalElement)
    end
    if ctx.activeTooltip then
        auxUi.deepDestroy(ctx.activeTooltip)
        ctx.activeTooltip = nil
    end

    ctx.modalElement = ui.create(specialTemplates.modal({{
        template = baseTemplates.padding(8),
        content = ui.content {
            layout
        }
    }}))
    ctx.modalElement.layout.events = {
        mouseMove = async:callback(function(e, layout)
            ctx.lastCursorPos = e.position
            return true
        end),
    }

    return ctx.modalElement
end

return ItemStackModal