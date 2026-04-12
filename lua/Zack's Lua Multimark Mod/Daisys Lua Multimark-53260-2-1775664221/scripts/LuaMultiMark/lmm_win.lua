local ui         = require("openmw.ui")
local I          = require("openmw.interfaces")
local util       = require("openmw.util")
local v2         = util.vector2
local core       = require("openmw.core")
local self       = require("openmw.self")
local types      = require("openmw.types")
local input      = require("openmw.input")
local async      = require("openmw.async")
--Thanks ChatGPT
--──────────────────────────────────────────────────────────────────────────────
-- Theme & Constants
--──────────────────────────────────────────────────────────────────────────────
local Theme      = {
    -- spacing
    gapXS              = 4,
    gapS               = 0,
    gapM               = 0,
    gapL               = 0,
    padS               = 8,
    padM               = 6,
    padL               = 8,

    -- sizes
    rowH               = 20,
    infoRowH           = 16,
    listWidth          = 440, -- visual width for list panel
    maxRowsHint        = 10, -- fallback

    -- typography
    textSize           = 16,
    textSizeSm         = 13,
    textSizeLg         = 18,

    -- colors (using MWUI text templates’ default colors where possible)
    colText            = nil, -- take from template
    colMuted           = util.color.rgb(0.80, 0.80, 0.80),
    colAccent          = util.color.rgb(0.95, 0.95, 1.00),
    colDanger          = util.color.rgb(1.00, 0.60, 0.60),

    -- visuals
    listBoxTemplate    = I.MWUI.templates.box,
    listBoxTransparent = I.MWUI.templates.boxTransparent,
    padTemplate        = I.MWUI.templates.padding,
    textNormal         = I.MWUI.templates.textNormal,
    textHeader         = I.MWUI.templates.textHeader,
    textEditLine       = I.MWUI.templates.textEditLine,
}

-- Window modes (kept for compatibility)
local windowType = { inventory = 1, magic = 2 }

--──────────────────────────────────────────────────────────────────────────────
-- Utilities
--──────────────────────────────────────────────────────────────────────────────

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function padRight(str, len)
    str = tostring(str or "")
    local n = len - #str
    if n > 0 then return str .. string.rep(" ", n) end
    return str
end

local function isOverwrite(iw)
    return iw and iw.context == "overwrite"
end

local function colorTextProps(text, size, color, alignH, alignV)
    return {
        type = ui.TYPE.Text,
        template = Theme.textNormal,
        props = {
            text      = tostring(text or ""),
            textSize  = size or Theme.textSize,
            textColor = color or Theme.colText,
            align     = alignV or ui.ALIGNMENT.Center,
            arrange   = alignH or ui.ALIGNMENT.Start,
        }
    }
end

--──────────────────────────────────────────────────────────────────────────────
-- Mouse handling
--──────────────────────────────────────────────────────────────────────────────

local function onRowMouse(mouseEvent, data)
    local iw     = data.props.iw
    local rowIdx = data.props.index
    local isSel  = data.props.selected

    if not iw then return end

    -- Clicking anywhere on a row focuses it first
    if not isSel then
        iw.selectedPosX = rowIdx - iw.scrollOffset
        iw.selectedPosX = clamp(iw.selectedPosX, 1, iw.rowCountY - 1) -- keep in visible pane
        iw:reDraw()
        return
    end

    -- If already selected:
    if isOverwrite(iw) then
        -- confirm overwrite
        I.LMM.saveMarkOverwrite(iw.selectedPosX, iw.selectedPosY)
        return
    end

    if mouseEvent.button == 1 then
        -- activate / recall
        I.LMM.doRecall(rowIdx, iw)
    elseif mouseEvent.button == 3 then
        -- rename
        I.LMM.enterEditMode()
    end
end

--──────────────────────────────────────────────────────────────────────────────
-- List Row Rendering
--──────────────────────────────────────────────────────────────────────────────

--- Render one list row with consistent styling.
--- Handles normal, selected, edit, and overwrite states.
local function renderListRow(iw, isSelected, label, absoluteIndex)
    local rowText
    local textColor

    if iw.editMode and isSelected then
        local editText = iw.editLine or ""
        if iw.drawLine then editText = editText .. "_" end
        rowText   = editText
        textColor = Theme.colAccent
    elseif label then
        rowText   = label
        textColor = Theme.colText
    else
        rowText   = ""
        textColor = Theme.colText
    end

    -- overwrite state nudges the selected row’s color
    if isSelected and isOverwrite(iw) then
        textColor = Theme.colDanger
    elseif isSelected and not iw.editMode then
        -- tasteful emphasis on selection
        textColor = Theme.colAccent
    end

    local rowInner = {
        -- A mild, left-aligned text with padding
        colorTextProps(padRight(rowText, 48), Theme.textSize, textColor, ui.ALIGNMENT.Start, ui.ALIGNMENT.Center),
    }

    local rowTemplate = isSelected and Theme.listBoxTemplate or Theme.padTemplate

    return {
        type = ui.TYPE.Container,
        props = {
            size     = v2(Theme.listWidth, Theme.rowH),
            autoSize = false,
            selected = isSelected,
            index    = absoluteIndex,
            iw       = iw,
        },
        events = { mousePress = async:callback(onRowMouse) },
        content = ui.content {
            {
                template  = rowTemplate, -- box when selected, padding otherwise
                props     = { padding = v2(Theme.padM, 0) },
                alignment = ui.ALIGNMENT.Center, -- valid values only
                content   = ui.content(rowInner),
            }
        }
    }
end

--──────────────────────────────────────────────────────────────────────────────
-- List Panel
--──────────────────────────────────────────────────────────────────────────────
local function withTitledFrame(title, bodyContentNode)
  return {
    -- Outer translucent frame
    template = Theme.listBoxTransparent,
    props    = { padding = v2(Theme.padL, Theme.padL) },
    content  = ui.content{
      -- Header bar
      {
        type  = ui.TYPE.Container,
        props = {
          size     = v2(Theme.listWidth, 22),
          autoSize = false,
        },
        content = ui.content{
          {
            template = Theme.listBoxTemplate,     -- subtle bar under the text
            props    = { padding = v2(6, 2) },
            content  = ui.content{
              {
                type     = ui.TYPE.Text,
                template = Theme.textHeader,
                props    = {
                  text     = title or "",
                  textSize = Theme.textSize,      -- uses your header color
                  align    = ui.ALIGNMENT.Center,
                  arrange  = ui.ALIGNMENT.Center,
                }
              }
            }
          }
        }
      },

      -- Small gap between header and body
      { template = Theme.padTemplate, props = { padding = v2(0, Theme.gapS) } },

      -- Body node (your list panel)
      bodyContentNode,
    }
  }
end
--- Renders the scrollable list (Y) with an info row at the bottom.
local function renderItemList(iw)
    local list        = iw.list or {}
    local total       = #list
    local visibleRows = clamp((iw.rowCountY or 0) - 1, 1, 999) -- reserve last row for info

    local maxOffset   = math.max(0, total - visibleRows)

    iw.scrollOffset   = clamp(iw.scrollOffset or 0, 0, maxOffset)
    iw.selectedPosX   = clamp(iw.selectedPosX or 1, 1, visibleRows)

    -- ensure selected absolute index in bounds
    if iw.scrollOffset + iw.selectedPosX > total and total > 0 then
        iw.selectedPosX = math.max(1, total - iw.scrollOffset)
    end

    local rows = {}

    for i = 1, visibleRows do
        local absIndex   = iw.scrollOffset + i
        local isSelected = (i == iw.selectedPosX)
        local item       = list[absIndex]
        local label      = item and (item.label or "(No label)") or nil

        table.insert(rows, renderListRow(iw, isSelected, label, absIndex))
    end

    -- info row: available marks & selection index
    local infoContents
    if iw.editMode then
        infoContents = {
            colorTextProps("Type to rename. Press Enter to save.", Theme.textSizeSm, Theme.colMuted, ui.ALIGNMENT.Center,
                ui.ALIGNMENT.Center)
        }
    else
        local avail  = I.LMM.getMaxSlots() - I.LMM.getMarkDataLength()
        local selAbs = I.LMM.getSelectedMarkIndex()
        selAbs       = (selAbs < 1) and 1 or selAbs
        local info   = string.format("Available: %d    Selected: %d/%d", avail, selAbs, total)
        infoContents = { colorTextProps(info, Theme.textSizeSm, Theme.colMuted, ui.ALIGNMENT.Center, ui.ALIGNMENT.Center) }
    end

    local infoRow = {
        type = ui.TYPE.Container,
        props = {
            size     = v2(Theme.listWidth, Theme.infoRowH),
            autoSize = false,
            iw       = iw,
        },
        content = ui.content {
            {
                template  = Theme.padTemplate,
                props     = { padding = v2(Theme.padM, 0) },
                alignment = ui.ALIGNMENT.Start,
                content   = ui.content(infoContents),
            }
        }
    }

    table.insert(rows, infoRow)
    local totalH = (Theme.rowH * visibleRows) + Theme.infoRowH
    local totalH = (Theme.rowH * visibleRows) + Theme.infoRowH
    local totalW = Theme.listWidth

    return ui.create {
        layer    = "Windows",
        -- bring back the translucent background frame
        template = Theme.listBoxTransparent, -- I.MWUI.templates.boxTransparent
        props    = {
            anchor           = v2(0.5, 0.5),
            relativePosition = v2(iw.posX, iw.posY),
            autoSize         = true, -- no giant gutters
            align            = ui.ALIGNMENT.Center,
            arrange          = ui.ALIGNMENT.Center,
            name             = "LMM_List",
        },
        content  = ui.content {
            -- inner padding inside the translucent box so rows don’t touch the frame
            {
                template = Theme.padTemplate, -- I.MWUI.templates.padding
                props    = { padding = v2(Theme.padL, Theme.padL) },
                content  = ui.content {
                    {
                        type    = ui.TYPE.Flex,
                        props   = {
                            vertical = true,
                            size     = v2(totalW, totalH), -- exact content height; outer box autosizes
                            align    = ui.ALIGNMENT.Center,
                            arrange  = ui.ALIGNMENT.Start,
                            autoSize = false,
                        },
                        content = ui.content(rows),
                    }
                }
            }
        }
    }
end

--──────────────────────────────────────────────────────────────────────────────
-- Grid Panel (kept; lightly styled)
--──────────────────────────────────────────────────────────────────────────────

local ICON = { size = 40, gap = 10 }

local function renderGridCell(item, isSelected)
    local template = isSelected and Theme.listBoxTemplate or Theme.padTemplate
    return {
        type = ui.TYPE.Container,
        props = { size = v2(ICON.size, ICON.size), autoSize = false },
        content = ui.content {
            { template = template, alignment = ui.ALIGNMENT.Center }
        }
    }
end

local function renderItemGrid(iw)
    local rows, cols = iw.rowCountY, iw.rowCountX
    local gridW      = cols * (ICON.size + ICON.gap) - ICON.gap
    local gridH      = rows * (ICON.size + ICON.gap) - ICON.gap

    local columns    = {}
    for x = 1, cols do
        local col = {}
        for y = 1, rows do
            local isSel = (iw.selectedPosX == x and iw.selectedPosY == y)
            table.insert(col, renderGridCell(nil, isSel))
        end
        table.insert(columns, {
            type    = ui.TYPE.Flex,
            props   = { vertical = true, size = v2(ICON.size, gridH), arrange = ui.ALIGNMENT.Start },
            content = ui.content(col)
        })
    end

    return ui.create {
        layer    = "Windows",
        template = Theme.listBoxTransparent,
        props    = {
            anchor           = v2(0.5, 0.5),
            relativePosition = v2(iw.posX, iw.posY),
            size             = v2(gridW, gridH),
            align            = ui.ALIGNMENT.Center,
            arrange          = ui.ALIGNMENT.Center,
            name             = "LMM_Grid"
        },
        content  = ui.content(columns)
    }
end

--──────────────────────────────────────────────────────────────────────────────
-- Window Object
--──────────────────────────────────────────────────────────────────────────────

local function createItemWindow(list, posX, posY, context, rowCountY)
    local iw = {
        -- data
        list         = list or {},
        context      = context or "normal",

        -- mode & layout
        listMode     = true, -- list by default
        windowType   = 0, -- you can set via setters below
        posX         = posX or 0.5,
        posY         = posY or 0.5,
        rowCountX    = 8,
        rowCountY    = rowCountY or Theme.maxRowsHint,

        -- selection & scroll
        selected     = true,
        selectedPosX = 1,
        selectedPosY = 1,
        scrollOffset = 0,

        -- editing
        editMode     = false,
        drawLine     = false,
        editLine     = "",

        -- ui handles
        ui           = nil,
        headerUi     = nil,
        infoUi       = nil,
    }

    -- API: item accessor (works for list; grid path left for completeness)
    function iw:getItemAt(x, y)
        local idx
        if self.listMode then
            idx = (self.scrollOffset or 0) + x
        else
            idx = (y - 1) * (self.rowCountX or 1) + x + (self.scrollOffset or 0)
        end
        return self.list[idx]
    end

    function iw:setWindowType(t)
        if t == windowType.inventory then
            self.windowType = t
            self.listMode   = false
        elseif t == windowType.magic then
            self.windowType = t
            self.listMode   = true
        else
            self.windowType = 0
            self.listMode   = true
        end
        self:reDraw()
    end

    function iw:setGridSize(x, y)
        self.rowCountX = x
        self.rowCountY = y
        self:reDraw()
    end

    function iw:reDraw()
        if self.ui then self.ui:destroy() end
        self.ui = self.listMode and renderItemList(self) or renderItemGrid(self)
    end

    function iw:drawWindow() self:reDraw() end

    function iw:destroy()
        if self.ui then
            self.ui:destroy(); self.ui = nil
        end
        if self.headerUi then
            self.headerUi:destroy(); self.headerUi = nil
        end
        if self.infoUi then
            self.infoUi:destroy(); self.infoUi = nil
        end
    end

    -- first draw
    iw:drawWindow()
    return iw
end

--──────────────────────────────────────────────────────────────────────────────
-- Exports
--──────────────────────────────────────────────────────────────────────────────

return {
    interfaceName = "LMM_Window",
    interface = {
        version          = 1,
        createItemWindow = createItemWindow,
    },
}
