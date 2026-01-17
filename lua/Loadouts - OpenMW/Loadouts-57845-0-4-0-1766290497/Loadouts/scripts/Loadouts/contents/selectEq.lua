local g              = require('scripts.Loadouts.myLib')
local scrollableList = require('scripts.Loadouts.myLib.scrollableList')
local toolTip        = require('scripts.Loadouts.myLib.toolTip')

local selectEqWindow = {
        ---@type ui.Layout[]
        itemsLayouts = {},
        ---@type ui.Element|{}
        element = {},
        ROW_LEN = 10,
        index = 1,
        view = 'list',
}


function selectEqWindow:listNext()
        self:deHighlight()
        self.index = self.index + 1
        if self.index > #self.itemsLayouts then
                self.index = #self.itemsLayouts
        end
        if self.index >= scrollableList.all['itemsList'].startElIndex + scrollableList.all['itemsList'].maxVisibleItems then
                scrollableList.all['itemsList']:scroll(1)
        end
        self:highlight(nil, true)
end

function selectEqWindow:listPrev()
        self:deHighlight()
        self.index = self.index - 1
        if self.index < 1 then
                self.index = 1
        end
        if self.index <= scrollableList.all['itemsList'].startElIndex then
                scrollableList.all['itemsList']:scroll(-1)
        end
        self:highlight(nil, true)
end

function selectEqWindow:next(amount)
        self:deHighlight()

        if amount == 1 then
                local nextIndex = self.index + 1
                if self.index % self.ROW_LEN == 0 then
                        nextIndex = self.index - self.ROW_LEN + 1
                end
                if nextIndex > #self.itemsLayouts then
                        local rowStart = math.floor((self.index - 1) / self.ROW_LEN) * self.ROW_LEN + 1
                        self.index = rowStart
                else
                        self.index = nextIndex
                end
        else
                local nextIndex = self.index + self.ROW_LEN
                if nextIndex > #self.itemsLayouts then
                        local col = (self.index - 1) % self.ROW_LEN
                        self.index = col + 1
                else
                        self.index = nextIndex
                end
        end

        self:highlight(nil, true)
end

function selectEqWindow:prev(amount)
        self:deHighlight()
        if amount == 1 then
                local nextIndex = self.index - 1
                if (self.index - 1) % self.ROW_LEN == 0 then
                        nextIndex = self.index + self.ROW_LEN - 1
                        if nextIndex > #self.itemsLayouts then
                                self.index = #self.itemsLayouts
                        else
                                self.index = nextIndex
                        end
                else
                        self.index = nextIndex
                end
        else
                -- local nextIndex = self.index - self.ROW_LEN
                -- if nextIndex < 1 then
                --         local col = (self.index - 1) % self.ROW_LEN
                --         local lastRowStart = math.ceil(#self.itemsLayouts / self.ROW_LEN) * self.ROW_LEN - self.ROW_LEN +
                --             1
                --         nextIndex = lastRowStart + col
                --         ::retry::
                --         if nextIndex > #self.itemsLayouts then
                --                 nextIndex = nextIndex - self.ROW_LEN
                --                 goto retry
                --         else
                --                 self.index = nextIndex
                --         end
                -- else
                --         self.index = nextIndex
                -- end
                local nextIndex = self.index - self.ROW_LEN

                if nextIndex < 1 then
                        local col = (self.index - 1) % self.ROW_LEN
                        local itemCount = #self.itemsLayouts

                        if col >= itemCount then
                                self.index = itemCount
                        else
                                local targetRow = math.floor((itemCount - col - 1) / self.ROW_LEN)
                                self.index = targetRow * self.ROW_LEN + col + 1
                        end
                else
                        self.index = nextIndex
                end
        end
        self:highlight(nil, true)
end

function selectEqWindow:deHighlight(index)
        if not self.element.layout then return end
        self.index = index or self.index
        if not self.itemsLayouts[self.index] then return end
        self.itemsLayouts[self.index].template = nil
        -- table.insert(g.myVars.myDelayedActions, self.element)
        table.insert(g.myVars.myDelayedActions, scrollableList.all['itemsList'].element)
end

---@param index number|nil
---@param forcePos boolean
function selectEqWindow:highlight(index, forcePos)
        toolTip.currentId = nil
        if not self.element.layout then return end
        self.index = index or self.index
        if not self.itemsLayouts[self.index] then return end
        self.itemsLayouts[self.index].template = g.templates.highlight
        self:showTT(self.index, forcePos)

        table.insert(g.myVars.myDelayedActions, scrollableList.all['itemsList'].element)
end

---comment
---@param index number
---@param forcePos boolean
function selectEqWindow:showTT(index, forcePos)
        toolTip.closed = nil

        g.util.debounce('showTT', 0.4, function()
                g.toolTip.showToolTip(self.itemsLayouts[index].userData.item, forcePos)
        end)
end

return selectEqWindow
