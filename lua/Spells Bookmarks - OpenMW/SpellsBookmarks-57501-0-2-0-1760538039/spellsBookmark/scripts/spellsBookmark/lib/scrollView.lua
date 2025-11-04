local util = require('openmw.util')
local I = require('openmw.interfaces')
local auxUi = require('openmw_aux.ui')
local async = require('openmw.async')
local ui = require('openmw.ui')
local constants = require('scripts.omw.mwui.constants')
local makeInt = require('scripts.spellsBookmark.lib.myGUI').makeInt
local textures = require('scripts.spellsBookmark.lib.myConstants').textures
local myTemplates = require('scripts.spellsBookmark.myTemplates')


local filter = require('scripts.spellsBookmark.filter').filter


-- local SCROLL_AMOUNT = 32 / 2
local SCROLL_AMOUNT = 14
local newTargetSize


---comment
---@param sign -1|1
---@param listState ListState
local function generalScroll(sign, listState)
        newTargetSize = listState.expTargetSize + SCROLL_AMOUNT * -sign

        if newTargetSize > 0 then
                return
        end

        if newTargetSize <= listState.maxSize then
                return
        end

        listState.expTargetSize = newTargetSize
end

local function createExpandable(size)
        local expandable = auxUi.deepLayoutCopy(I.MWUI.templates.interval)
        -- local expandable = auxUi.deepLayoutCopy(I.MWUI.templates.horizontalLine)

        expandable.props.external = { grow = 0, stretch = 0 }
        expandable.props.autoSize = false
        expandable.props.size = util.vector2(0, size)
        expandable.props.isExpandable = true


        return expandable
end

local function getScrollButtonsEvents(arrowState)
        return {
                mousePress = async:callback(function(e)
                        if e.button == 1 then arrowState.press = true end
                end),
                mouseRelease = async:callback(function(e)
                        arrowState.press = false
                end),
                focusGain = async:callback(function() arrowState.focus = true end),
                focusLoss = async:callback(function() arrowState.focus = false end)
        }
end



---comment
---@param listState ListState
---@param uiState UIState
---@return table
local function createListView(listState, uiState)
        listState.expandable = createExpandable(listState.expSize)
        table.insert(listState.items, 1, listState.expandable)

        local listContent = {
                name = 'list',
                type = ui.TYPE.Flex,
                template = myTemplates.getTemplate('none', { 0, 0, 4, 0 }, false),
                props = {
                        autoSize = false,
                        horizontal = false,
                },
                external = { grow = 1, stretch = 1 },
                content = ui.content(listState.items),
                events = {
                        -- mouseMove = async:callback(function(e, l)
                        -- print(l.props.size)
                        -- end),
                        focusGain = async:callback(function() listState.focus = true end),
                        focusLoss = async:callback(function() listState.focus = false end)
                }
        }

        local scrollControls = {
                type = ui.TYPE.Flex,
                -- template = I.MWUI.templates.borders,
                props = {
                        horizontal = true,
                        arrange = ui.ALIGNMENT.Center,
                        align = ui.ALIGNMENT.Center,
                },
                content = ui.content({
                        {
                                type = ui.TYPE.Image,
                                props = {
                                        resource = textures.upArrow,
                                        -- size = util.vector2(20, 20)
                                        size = util.vector2(14, 14)
                                },
                                events = getScrollButtonsEvents(listState.arrow.up)
                        },
                        {
                                type = ui.TYPE.Image,
                                props = {
                                        resource = textures.downArrow,
                                        -- size = util.vector2(20, 20)
                                        size = util.vector2(14, 14)
                                },
                                events = getScrollButtonsEvents(listState.arrow.down)
                        }
                })
        }



        return {
                name = 'mainContent',
                type = ui.TYPE.Flex,
                -- template = getTemplate('none', { 4, 4, 2, 4 }, false),
                template = myTemplates.getTemplate('thin', { 4, 4, 4, 4 }, false),
                -- template = I.MWUI.templates.borders,
                props = {
                        relativeSize = util.vector2(1, 1),
                        arrange = ui.ALIGNMENT.Start,
                        align = ui.ALIGNMENT.Center
                },
                external = { grow = 1, stretch = 0 },
                content = ui.content {
                        -- { template = I.MWUI.templates.horizontalLine },
                        listContent,
                        {
                                template = I.MWUI.templates.horizontalLine,
                                -- external = { grow = 0, stretch = 0 },
                                external = { grow = 0, stretch = 1 },
                                props = {
                                        size = util.vector2(1, 2),
                                        relativeSize = util.vector2(0, 0)
                                }
                        },
                        makeInt(0, 4),
                        {
                                type = ui.TYPE.Flex,
                                template = myTemplates.getTemplate('none', { 0, 0, 0, 0 }, false),
                                -- template = I.MWUI.templates.borders,

                                props = {
                                        horizontal = true,
                                        arrange = ui.ALIGNMENT.Center,
                                        align = ui.ALIGNMENT.Start,
                                        size = util.vector2(100, 20)
                                },
                                content = ui.content {

                                        scrollControls,
                                        makeInt(10, 0),
                                        listState == uiState.allSpells and filter.createFilterBlock(uiState) or {},
                                }
                        },
                        makeInt(0, 10),
                }
        }
end




return { createListView = createListView, generalScroll = generalScroll }
