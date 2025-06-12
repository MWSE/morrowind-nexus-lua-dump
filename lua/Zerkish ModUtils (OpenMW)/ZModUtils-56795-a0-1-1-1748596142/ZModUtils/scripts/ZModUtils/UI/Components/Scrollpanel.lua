-- ZModUtils - Scrollpanel.lua
-- Author: Zerkish (2025)
--
-- This is a higher level component that creates a panel with a scrollbar component (if required)

local auxUI = require('openmw_aux.ui')
local ui = require('openmw.ui')
local vector2 = require('openmw.util').vector2
local constants = require('scripts.omw.mwui.constants')
local I = require('openmw.interfaces')

local ZMIconButton = require('scripts.ZModUtils.UI.Components.IconButton')
local ZMScrollbar = require('scripts.ZModUtils.UI.Components.Scrollbar')
local ZMUIConstants = require('scripts.ZModUtils.UI.Constants')

local sbAdjustment = ZMUIConstants.VScrollbarWidth + constants.border * 2

local function adjustPanelSize(contentSize, panelSize, forceScrollbar)
    local actualX = panelSize.x

    if forceScrollbar or contentSize.y > panelSize.y then
        actualX = actualX + sbAdjustment
    end
    return vector2(actualX, panelSize.y)
end

-- Utility function for moving the scrolled content based on scrollbar position (VERTICAL)
-- Replaces setInnerContentPositionFromScrollbarPosition
local function setContentYPositionFromScrollbarPosition(content, scrollbar)
    assert(content ~= nil and content.layout.userData ~= nil)

    -- there is no scrollbar with few items.
    if scrollbar ~= nil then
        local scrollbarPos = ZMScrollbar.getScrollbarHandlePosition(scrollbar)
        local maxBarPosition = ZMScrollbar.getScrollbarHandleMaxPosition(scrollbar)

        local contentY = 0
        if maxBarPosition > 1 then
            local ratio = scrollbarPos / maxBarPosition
            ratio = math.max(0, math.min(ratio, 1))
            --ratio = 1
            contentY = ratio * (content.layout.userData.contentSizeY - content.layout.userData.containerSizeY)
        end
        content.layout.props.position = vector2(content.layout.props.position.x, -contentY)
        --content.userData.contentPosY = contentY
        content:update()
    end
end

-- numItems can be negative
local function moveScrollbarByItemNum(content, scrollbar, numItems)
    local maxBarPosition = ZMScrollbar.getScrollbarHandleMaxPosition(scrollbar)

    local ratio = maxBarPosition / (content.layout.userData.contentSizeY - content.layout.userData.containerSizeY)
    local itemSizeInBar = content.layout.userData.itemSize.y * ratio

    local scrollbarPos = ZMScrollbar.getScrollbarHandlePosition(scrollbar)
    scrollbarPos = math.floor(scrollbarPos / itemSizeInBar + 0.5) * itemSizeInBar

    -- move scrollbar by one item
    local newScrollbarY = math.min(math.max(scrollbarPos + itemSizeInBar * numItems, 0), maxBarPosition)

    ZMScrollbar.setScrollbarHandlePosition(scrollbar, newScrollbarY)
    scrollbar:update()
end

local function onVScrollbarUpButton(mEvent, layout)
    -- -- stored handle to the scrollPaneContent
    local content = layout.userData.content
    local scrollbar = layout.userData.scrollbar
    
    moveScrollbarByItemNum(content, scrollbar, -1)
    setContentYPositionFromScrollbarPosition(content, scrollbar)
    --I.ZHI.updateUI()
end

local function onVScrollbarDownButton(mEvent, layout)
    -- -- stored handle to the scrollPaneContent
    local content = layout.userData.content
    local scrollbar = layout.userData.scrollbar

    moveScrollbarByItemNum(content, scrollbar, 1)
    setContentYPositionFromScrollbarPosition(content, scrollbar)
    --I.ZHI.updateUI()
end

local function onVScrollPaneScrollbarDrag(mEvent, layout, scrollbar)
    assert(layout ~= nil)
    assert(layout.userData ~= nil)
    local content = scrollbar.layout.userData

    --print('drag', scrollbar, content)
    setContentYPositionFromScrollbarPosition(content, scrollbar)
    --I.ZHI.updateUI()
end

local upBtnTexture = ui.texture({ path = 'textures/omw_menu_scroll_up.dds' })
local downBtnTexture = ui.texture({ path = 'textures/omw_menu_scroll_down.dds' })

local function createVerticalScrollbarWithButtons(panelSize, contentSize, outerContent)
    -- the actual height of the scrollbar, removing the two buttons + all the borders and adding outer padding
    local scrollbarHeight = panelSize.y - ZMUIConstants.VScrollbarWidth * 2 - constants.border * 6 - constants.thickBorder * 2

    local ratio = panelSize.y / contentSize.y -- - containerSize.y
    if ratio >= 1.0 then ratio = 1.0 end

    -- Minimum size in case of very many items
    local barSize = math.max(ratio * scrollbarHeight, ZMUIConstants.VScrollbarWidth) 
    --local scrollbarLayout = ZHIScrollbar.createScrollbarV(ZHIUI_CONSTANTS.VScrollbarSize, scrollbarHeight, barSize, onVScrollPaneScrollbarDrag)
    local scrollbar = ZMScrollbar.createVScrollbar({
        size = vector2(ZMUIConstants.VScrollbarWidth, scrollbarHeight),
        handleSize = barSize,
        callback = onVScrollPaneScrollbarDrag,
    })

    if (scrollbar) then
        --scrollbarLayout.name = "vpane_scrollbar"
        scrollbar.layout.userData = outerContent
    end
    
    local scrollbarActualSize = ZMUIConstants.VScrollbarWidth -- + constants.border * 2

    local btnUserData = {
        content = outerContent,
        scrollbar = scrollbar,
    }

    local upButton = ZMIconButton.create(upBtnTexture, vector2(scrollbarActualSize, scrollbarActualSize), onVScrollbarUpButton, btnUserData)
    local downButton = ZMIconButton.create(downBtnTexture, vector2(scrollbarActualSize, scrollbarActualSize), onVScrollbarDownButton, btnUserData)

    -- Wrap the scrollbar and buttons 
    return {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            size = vector2(scrollbarActualSize, panelSize.y),
            align = ui.ALIGNMENT.Center,
            arrange = ui.ALIGNMENT.Center,
        },
        userData = {
            scrollbar = scrollbar,
            upButton = upButton,
            downButton = downButton,
        },
        content = ui.content({
            upButton,
            scrollbar,
            downButton,
        })
    }

end

local function createVScrollPanel(params)
    if not params then return nil end
    assert(params.contentElement, "params.contentElement is required")
    assert(params.contentElement.layout, "params.contentElement.layout does not exist")
    assert(params.contentElement.layout.props.size, 'params.contentElement.layout.props.size is not set')
    assert(params.size, 'params.size is not set')

    local contentSize = params.contentElement.layout.props.size
    local shouldCreateScrollbar = params.forceScrollbar or contentSize.y > params.size.y
    
    local contentActualSizeX = contentSize.x
    if shouldCreateScrollbar then
        contentActualSizeX = math.min(contentSize.x, params.size.x - sbAdjustment)
    end

    local outerContentLayout = {
        --template = I.MWUI.templates.c,
        type = ui.TYPE.Widget,
        --name = 'outerContent',
        props = {
            --autoSize = true,
            size = vector2(params.size.x, contentSize.y),
            position = vector2(0, 0),
        },
        content = ui.content({ params.contentElement }),
        userData = {
            --items = items,
            itemSize = params.itemSize,
            containerSizeY = params.size.y,
            contentSizeY = contentSize.y,
            contentPosY = 0,
        },
    }

    local outerContent = ui.create(outerContentLayout)

    local listArea = {
        type = ui.TYPE.Widget,
        props = {
            autoSize = false,
            size = vector2(contentActualSizeX, contentSize.y),
        },
        content = ui.content({ outerContent }),
    }

    local contentPane = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            size = params.size,
            horizontal = true,
            --align = ui.ALIGNMENT.Center,
        },
        userData = {
            outerContent = outerContent,
            listArea = listArea,
        },
        content = ui.content({
            -- List Area
            listArea,
        })
    }

    local scrollbar = nil
    if shouldCreateScrollbar then
        local scrollbarWithButtons = createVerticalScrollbarWithButtons(params.size, contentSize, outerContent)

        local sbWrapper = {
            type = ui.TYPE.Flex,
            props = {
                size = vector2(sbAdjustment, params.size.y),
                horizontal = true,
                -- arrange = ui.ALIGNMENT.Center,
                -- align = ui.ALIGNMENT.Center,
            },
            content = ui.content({
                scrollbarWithButtons,
            })
        }

        scrollbar = scrollbarWithButtons.userData.scrollbar
        contentPane.content:add(scrollbarWithButtons)
        contentPane.userData.scrollbar = scrollbar
    end

    local container = {
        type = ui.TYPE.Widget,
        props = {
            autoSize = false,
            size = params.size,
            --position = util.vector2(0, -32)
        },
        content = ui.content({contentPane})
    }
    setContentYPositionFromScrollbarPosition(outerContent, scrollbar)

    local element = ui.create(container)
    contentPane.userData.element = element

    return element
end

local lib = {
    -- params
    -- params.size      : util.vector2 with the size of the scrollpanel
    -- params.itemSize  : util.vector2 with the size of each 'item', rows for vertical.
    --      This is used for accurately scrolling one item at a time.
    --      If you need to mix items of varying sizes it's recommended to make them multiples of itemSize.y
    -- params.contentElement   : UiElement with the content widget.
    --      Should have a fixed size that is pre-calculated.
    createVertical = createVScrollPanel,
    destroy = function(scrollPanel)
        auxUI.deepDestroy(scrollPanel)
    end,

    updateContent = function(scrollPanel)
        assert(scrollPanel)
        assert(scrollPanel.layout.content and #scrollPanel.layout.content > 0)
        local contentPane = scrollPanel.layout.content[1]
        assert(contentPane.userData and contentPane.userData.outerContent)

        local outer = contentPane.userData.outerContent
        local contentElement = outer.layout.content[1]
        assert(contentElement)

        local contentSizeY = contentElement.layout.props.size.y
        outer.layout.userData.contentSizeY = contentSizeY
        outer.layout.props.size = vector2(outer.layout.props.size.x, contentSizeY)

        local listArea = contentPane.userData.listArea
        listArea.props.size = vector2(listArea.props.size.x, contentSizeY)

        local scrollbar = contentPane.userData.scrollbar
        local panelSize = contentPane.userData.element.layout.props.size

        -- the actual height of the scrollbar, removing the two buttons + all the borders and adding outer padding
        local scrollbarHeight = panelSize.y - ZMUIConstants.VScrollbarWidth * 2 - constants.border * 6 - constants.thickBorder * 2

        local ratio = panelSize.y / contentSizeY
        if ratio >= 1.0 then ratio = 1.0 end

        -- Minimum size in case of very many items
        local barSize = math.max(ratio * scrollbarHeight, ZMUIConstants.VScrollbarWidth)
        ZMScrollbar.setScrollbarHandleSize(scrollbar, barSize)
        scrollbar:update()

        --outer:update()
        contentPane.userData.element:update()
        setContentYPositionFromScrollbarPosition(contentPane.userData.outerContent, contentPane.userData.scrollbar)
    end,

    -- Pass in content size and panel size to adjust panel size to accomodate a scrollbar if required.
    adjustPanelSize = adjustPanelSize,

    moveScrollbarByItems = function(scrollPanel, num)
        assert(scrollPanel)
        assert(scrollPanel.layout.content and #scrollPanel.layout.content > 0)
        local contentPane = scrollPanel.layout.content[1]
        assert(contentPane.userData and contentPane.userData.outerContent)
        if not  contentPane.userData.scrollbar then
            return
        end

        moveScrollbarByItemNum(contentPane.userData.outerContent, contentPane.userData.scrollbar, num)
    end,
}

return lib