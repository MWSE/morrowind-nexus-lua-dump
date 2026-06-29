local ui = require('openmw.ui')
local util = require('openmw.util')
local auxUi = require('openmw_aux.ui')
local async = require('openmw.async')
local I = require('openmw.interfaces')

local baseTemplates = require('scripts.InventoryExtender.ui.templates.base')
local specialTemplates = require('scripts.InventoryExtender.ui.templates.magic')
local constants = require('scripts.InventoryExtender.util.constants')

local v2 = util.vector2

local ColumnSettingsModal = {}

local function createCheckbox(checked, disabled)
    return {
        template = I.MWUI.templates.box,
        props = {
            size = v2(20, 20),
        },
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                content = ui.content {
                    {
                        template = baseTemplates.textNormal,
                        props = {
                            text = checked and 'x' or '',
                            size = v2(10, 10),
                            autoSize = false,
                            textAlignH = ui.ALIGNMENT.Center,
                            textAlignV = ui.ALIGNMENT.Center,
                            textColor = disabled and constants.Colors.DISABLED or constants.Colors.DEFAULT,
                        },
                    }
                }
            }
        }
    }
end

function ColumnSettingsModal.create(params, ctx)
    local rows = ui.content {}

    for _, column in ipairs(params.columns or {}) do
        local checked = params.isColumnVisible(column.id)
        local disabled = checked and not params.canHideColumn(column.id)

        rows:add(specialTemplates.interactive({
            canClick = function()
                return not disabled
            end,
            onClick = function()
                params.onToggle(column.id, not checked)
            end,
            name = 'column_' .. column.id,
        }, {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                arrange = ui.ALIGNMENT.Center,
                autoSize = false,
                size = v2(240, specialTemplates.LINE_HEIGHT + 10),
            },
            content = ui.content {
                createCheckbox(checked, disabled),
                baseTemplates.intervalH(8),
                {
                    template = baseTemplates.textNormal,
                    props = {
                        text = column.label,
                        textColor = disabled and constants.Colors.DISABLED or constants.Colors.DEFAULT,
                        autoSize = true,
                    },
                    userData = {
                        colorable = not disabled,
                    }
                },
                {
                    external = { grow = 1, stretch = 1, }
                }
            },
            userData = {
                disabled = disabled,
            },
        }, ctx))
    end

    local layout = {
        type = ui.TYPE.Flex,
        props = {
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            {
                template = baseTemplates.textHeader,
                props = {
                    text = params.title,
                }
            },
            baseTemplates.intervalV(8),
            {
                template = I.MWUI.templates.box,
                content = ui.content {
                    {
                        template = I.MWUI.templates.padding,
                        content = ui.content {
                            {
                                type = ui.TYPE.Flex,
                                content = rows,
                            }
                        }
                    }
                }
            },
            baseTemplates.intervalV(8),
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    specialTemplates.interactive({
                        onClick = function()
                            auxUi.deepDestroy(ctx.modalElement)
                            ctx.modalElement = nil
                        end,
                    }, baseTemplates.button(params.closeLabel or constants.Strings.OK), ctx),
                }
            }
        }
    }

    if ctx.modalElement then
        auxUi.deepDestroy(ctx.modalElement)
    end
    if ctx.activeTooltip then
        auxUi.deepDestroy(ctx.activeTooltip)
        ctx.activeTooltip = nil
    end

    ctx.modalElement = ui.create(specialTemplates.modal({
        {
            template = baseTemplates.padding(8),
            content = ui.content {
                layout
            }
        }
    }))
    ctx.modalElement.layout.events = {
        mouseMove = async:callback(function(e)
            ctx.lastCursorPos = e.position
            return true
        end),
    }

    return ctx.modalElement
end

return ColumnSettingsModal