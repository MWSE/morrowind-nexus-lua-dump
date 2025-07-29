local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local util = require('openmw.util')
local settings = require("scripts.openmw_books_enhanced.settings")

local scrollbarPadding = 2

local function createScrollingWidget(direction, scrollbarWidth, pos, contentNameBorder, contentNameButton)
    return {
        name = contentNameBorder,
        template = I.MWUI.templates.box,
        props = {
            position = pos,
        },
        content = ui.content({
            {
                name = contentNameButton,
                type = ui.TYPE.Image,
                props = {
                    resource = ui.texture { path = 'textures/omw_menu_scroll_' .. direction .. '.dds' },
                    size = util.vector2(1, 1) * scrollbarWidth,
                },
            },
        }),
    }
end

local function createScrollElevatorWidget(pos, siz, content_name)
    return {
        name = content_name.pageScrollbarElevator_BORDER,
        template = I.MWUI.templates.box,
        props = {
            position = pos,
        },
        content = ui.content({
            {
                name = content_name.pageScrollbarElevator,
                type = ui.TYPE.Image,
                props = {
                    resource = ui.texture { path = 'textures/omw_menu_scroll_center_v.dds' },
                    size = siz,
                },
            },
        }),
    }
end

local BR = {}

function BR.addReadableSpace(bookWindow, documentWindowPageData, content_name)
    local readableSpace =
    {
        name = content_name.pageReadableSpace,
        type = ui.TYPE.Image,
        props = {
            size = util.vector2(
                documentWindowPageData.textArea.width,
                documentWindowPageData.textArea.height
            ),
            position = util.vector2(
                documentWindowPageData.textArea.posTopLeftCornerX,
                documentWindowPageData.textArea.posTopLeftCornerY
            ),
            -- resource = ui.texture { path = 'white' },
            -- color = util.color.rgb(234 / 255, 210 / 255, 175 / 255),
        },
    }


    local shouldAddScrollbar = (documentWindowPageData.textArea and documentWindowPageData.textArea.isScrollableVertically)
    if shouldAddScrollbar then
        local scrollbarWidth = settings.SettingsTravOpenmwBooksEnhanced_scrollbarWidth()
        local newReadableSpaceWidth = documentWindowPageData.textArea.width - scrollbarWidth - (2 * scrollbarPadding)
        readableSpace.props.size = util.vector2(
            newReadableSpaceWidth,
            documentWindowPageData.textArea.height
        )

        table.insert(
            bookWindow.content,
            createScrollingWidget(
                "up",
                scrollbarWidth,
                util.vector2(
                    documentWindowPageData.textArea.posTopLeftCornerX + newReadableSpaceWidth + scrollbarPadding,
                    documentWindowPageData.textArea.posTopLeftCornerY
                ),
                content_name.pageScrollbarUpButton_BORDER,
                content_name.pageScrollbarUpButton))
        table.insert(
            bookWindow.content,
            createScrollElevatorWidget(
                util.vector2(
                    documentWindowPageData.textArea.posTopLeftCornerX + newReadableSpaceWidth + scrollbarPadding,
                    documentWindowPageData.textArea.posTopLeftCornerY + scrollbarWidth + (2 * scrollbarPadding)
                ),
                util.vector2(
                    scrollbarWidth,
                    documentWindowPageData.textArea.height - (2 * scrollbarWidth) - (6 * scrollbarPadding)
                ),
                content_name))
        table.insert(
            bookWindow.content,
            createScrollingWidget(
                "down",
                scrollbarWidth,
                util.vector2(
                    documentWindowPageData.textArea.posTopLeftCornerX + newReadableSpaceWidth + scrollbarPadding,
                    documentWindowPageData.textArea.posTopLeftCornerY + documentWindowPageData.textArea.height -
                    (scrollbarWidth + (2 * scrollbarPadding))
                ),
                content_name.pageScrollbarDownButton_BORDER,
                content_name.pageScrollbarDownButton))
    end

    table.insert(bookWindow.content, readableSpace)
end

return BR
