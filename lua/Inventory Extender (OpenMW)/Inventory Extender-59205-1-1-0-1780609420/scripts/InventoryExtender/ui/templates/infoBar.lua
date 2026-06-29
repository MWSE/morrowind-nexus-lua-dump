local ui = require('openmw.ui')
local util = require('openmw.util')
local v2 = util.vector2

local baseTemplates = require('scripts.InventoryExtender.ui.templates.base')

local InfoBar = {}

function InfoBar.create(props, ctx)
    local maxHeight = props.maxHeight or 32

    local layout = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            autoSize = false,
            size = v2(0, maxHeight),
            relativeSize = v2(1, 0),
            align = ui.ALIGNMENT.Start,
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {},
        userData = {},
    }

    local state = {}

    state.element = ui.create(layout)
    state.ctx = ctx

    local function addInfoLayout(layout, updateFn)
        layout = layout.layout and layout.layout or layout
        layout.userData = layout.userData or {}
        layout.userData.update = updateFn
        state.element.layout.content:add(baseTemplates.intervalH(8))
        state.element.layout.content:add(layout)
        state.element:update()
    end

    local function updateAll()
        for i, child in ipairs(state.element.layout.content) do
            local isElement = child.layout ~= nil
            local userData = isElement and child.layout.userData or child.userData
            if userData and userData.update then
                local updateFn = userData.update
                if updateFn then
                    local newLayout = updateFn(child, state.ctx)
                    newLayout.userData = newLayout.userData or {}
                    newLayout.userData.update = updateFn
                    if isElement then
                        child.layout = newLayout
                        child:update()
                    else
                        state.element.layout.content[i] = newLayout
                    end
                end
            end
        end
        state.element:update()
    end

    state.element.layout.userData.addInfoLayout = addInfoLayout
    state.element.layout.userData.updateAll = updateAll
    return state.element
end

return InfoBar