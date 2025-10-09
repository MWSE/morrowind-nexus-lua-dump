local ui = require("openmw.ui")
local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local Camera = require("openmw.camera")
local input = require("openmw.input")
local storage = require("openmw.storage")
local ui = require("openmw.ui")
local async = require("openmw.async")
local I = require("openmw.interfaces")
local vfs = require('openmw.vfs')

local config = require("scripts.MoveObjects.config")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local Camera = require("openmw.camera")
local input = require("openmw.input")
local storage = require("openmw.storage")
local acti = require("openmw.interfaces").Activation
local playerSelected
local iconsize = 4
--local calculateTextScale() = 0.8
local Actor = require("openmw.types").Actor

local playerSettings = storage.playerSection("SettingsAshlanderArchitect")

local function imageContent(resource, size)
    if (size == nil) then
        size = iconsize
    end
    return {
        type = ui.TYPE.Image,
        props = {
            resource = resource,
            size = util.vector2(ui.layers[1].size.y / size, ui.layers[1].size.y / size),
            relativeSize = util.vector2(0.2, 0.2)
        }
    }
end



local function lerp(x, x1, x2, y1, y2)
    return y1 + (x - x1) * ((y2 - y1) / (x2 - x1))
end

local function calculateTextScale()
    local screenSize = ui.layers[1].size
    local width = screenSize.x
    local scale = lerp(width, 1280, 2560, 1.3, 1.8)
    local textScaleSetting = playerSettings:get("textScale") or 1
    return scale * textScaleSetting
end
local function textContent(text, template, color)
    if (template == nil) then
        template = I.MWUI.templates.textHeader
    else
        if (color ~= nil) then
            template.props.textColor = color
        end
    end
    return {
        type = ui.TYPE.Text,
        template = template,
        props = {
            text = tostring(text),
            textSize = 20 * calculateTextScale(),
            arrange = ui.ALIGNMENT.Start,
            align = ui.ALIGNMENT.Start
        }
    }
end
local function textContentLeft(text)
    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            relativePosition = v2(0.5, 0.5),
            text = tostring(text),
            textSize = 10 * calculateTextScale(),
            arrange = ui.ALIGNMENT.Start,
            align = ui.ALIGNMENT.Start
        }
    }
end
local function paddedTextContent(text)
    return {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                props = {
                    anchor = util.vector2(0, -0.5)
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = text,
                            textSize = 10 * calculateTextScale(),
                            arrange = ui.ALIGNMENT.Center
                        }
                    }
                }
            }
        }
    }
end
local function renderItemBoxed(item, bold)
    return {
        type = ui.TYPE.Container,
        props = {
            --  anchor = util.vector2(-1,0),
            align = ui.ALIGNMENT.Center,
            relativePosition = util.vector2(1, 0.5),
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            {
                template = I.MWUI.templates.borders,
                alignment = ui.ALIGNMENT.Center,
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textHeader,
                        props = {
                            text = item,
                            textSize = 10 * calculateTextScale(),
                            relativePosition = v2(0.5, 0.5),
                            arrange = ui.ALIGNMENT.Center,
                            align = ui.ALIGNMENT.Center,
                        }
                    }
                }
            }
        }
    }
end
local function renderItemBold(item, bold)
    return {
        type = ui.TYPE.Container,
        props = {
            --  anchor = util.vector2(-1,0),
            align = ui.ALIGNMENT.Center,
            relativePosition = util.vector2(1, 0.5),
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Center,
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textHeader,
                        props = {
                            text = item,
                            textSize = 10 * calculateTextScale(),
                            relativePosition = v2(0.5, 0.5),
                            arrange = ui.ALIGNMENT.Center,
                            align = ui.ALIGNMENT.Center,
                        }
                    }
                }
            }
        }
    }
end -- Compact, centered, not-wide text input window-- Compact text input using the backward-compatible boxedTextEditContent
local function renderTextInput(textLines, existingText, editCallback, OKCallback, OKText)
    OKText = OKText or "OK"

    -- Clamp overall window width (uses screen size but stays narrow)
    local screenW = ui.layers[1].size.x
    local winW = math.max(260, math.min(420, math.floor(screenW * 0.35)))

    local content = {}
    for _, line in ipairs(textLines or {}) do
        table.insert(content, I.DaisyUtilsUI_AA.textContentLeft(line))
    end

    -- Use the new backward-compatible signature (opts table).
    -- Stays narrow by clamping internally; not full-width.
    local textEdit = I.DaisyUtilsUI_AA.boxedTextEditContent(
        existingText or "",
        async:callback(editCallback),
        {
            multiline = false,
            minWidth = 260,
            maxWidth = math.max(320, math.min(420, winW)),
            height = 30,
        }
    )

    local okButton = I.DaisyUtilsUI_AA.boxedTextContent(OKText, async:callback(OKCallback))

    if I.DaisyUtilsUI_AA.spacer then table.insert(content, I.DaisyUtilsUI_AA.spacer(6)) end
    table.insert(content, textEdit)
    if I.DaisyUtilsUI_AA.spacer then table.insert(content, I.DaisyUtilsUI_AA.spacer(8)) end
    table.insert(content, okButton)

    return ui.create {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick,
        props = {
            relativePosition = util.vector2(0.5, 0.5),
            anchor = util.vector2(0.5, 0.5),
            vertical = false,
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    horizontal = false,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                    size = util.vector2(winW, 10), -- keep container narrow
                    padding = 8,
                }
            }
        }
    }
end
local function renderItem(item, bold)
    return {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Center,
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = item,
                            textSize = 10 * calculateTextScale(),
                            arrange = ui.ALIGNMENT.Center
                        }
                    }
                }
            }
        }
    }
end
local function renderItemBBoxed(item, bold)
    return {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Center,
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = item,
                            textSize = 10 * calculateTextScale(),
                            arrange = ui.ALIGNMENT.Center
                        }
                    }
                }
            }
        }
    }
end
local function renderItemChoiceReal(itemList, selectedItem, horizontal, vertical, align, anchor)
    local content = {}
    for _, item in ipairs(itemList) do
        if (item == selectedItem) then
            local itemLayout = renderItemBold(item)
            itemLayout.template = I.MWUI.templates.padding
            table.insert(content, itemLayout)
        else
            local itemLayout = renderItem(item)
            itemLayout.template = I.MWUI.templates.padding
            table.insert(content, itemLayout)
        end
    end
    table.insert(content, renderItemBoxed("OK"))
    return ui.create {
        layer = "HUD",
        template = I.MWUI.templates.boxTransparent,
        props = {
            -- relativePosition = v2(0.65, 0.8),
            anchor = anchor,
            relativePosition = v2(horizontal, vertical),
            arrange = align,
            align = align,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    vertical = true,
                    arrange = align,
                    align = align,
                }
            }
        }
    }
end
local RecordStorage = storage.globalSection("RecordStorage")
local function convertStringToTable(inputString)
    local dataTable = {}
    local entryCount = 0

    for entry in string.gmatch(inputString, "([^|]+)") do
        local itemID, count = string.match(entry, "(.-);(.+)")
        if not itemID then
            return
        end
        local createdRecords = RecordStorage:get("createdRecords")

        if createdRecords[itemID] then itemID = createdRecords[itemID] end
        count = tonumber(count)

        local carriedCount = types.Actor.inventory(self):countOf(itemID)
        local dataEntry = {
            itemID = itemID,
            count = count,
            carried = carriedCount >= count
        }
        if (dataEntry.itemID ~= nil) then
            table.insert(dataTable, dataEntry)
            entryCount = entryCount + 1
            --   print(itemID)
        end
    end

    -- Handle single item case
    if entryCount == 0 then
        local itemID, count = string.match(inputString, "(.-);(.+)")
        local createdRecords = RecordStorage:get("createdRecords")

        if createdRecords[itemID] then itemID = createdRecords[itemID] end
        count = tonumber(count)

        local carriedCount = types.Actor.inventory(self):countOf(itemID)
        local dataEntry = {
            itemID = itemID,
            count = count,
            carried = carriedCount >= count
        }

        table.insert(dataTable, dataEntry)
    end

    return dataTable
end
local auxUi = require('openmw_aux.ui')
local function renderIcon(icon, text, red)
    local iconsize = 32
    local template = auxUi.deepLayoutCopy(I.MWUI.templates.textHeader)
    local color = nil
    if (red) then
        color = ui.CONSOLE_COLOR.Error
    end
    template.textSize = 2
    local iconResource = ui.texture({ path = icon })
    return {
        type = ui.TYPE.Container,
        props = {
            size = util.vector2(iconsize, iconsize)
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content {
                    imageContent(iconResource, iconsize),
                    textContent(tostring(text), template, color)
                },
                props = {
                    anchor = v2(0.0, -0.0),
                    horizontal = true,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                }
            }
        }
    }
end
local function renderObjectRequirements(tableItem, horizontal, vertical, size)
    if not tableItem then return end


    if not tableItem.requirements or #tableItem.requirements == 0 then return end
    local requirements = tableItem.requirements
    if (not requirements or #requirements == 0) then
        --print("Item not found" .. tableItem.EditorId)
        return
    else
    end
    local content = {}
    local itemcounts = {}
    local data = tableItem.requirements
    if data then
        for index, dataOb in ipairs(data) do
            itemcounts[dataOb.item] = types.Actor.inventory(self):countOf(dataOb.item)
        end
    end
    local createdRecords = RecordStorage:get("createdRecords")
    for index, dataob in ipairs(requirements) do
        local obRecord = nil
        local itemID = dataob.item
        if createdRecords[itemID] then itemID = createdRecords[itemID] end
        obRecord = types.Miscellaneous.records[itemID]
        --  local resource = ui.texture { -- texture in the top left corner of the atlas
        -- path = obRecord.icon
        -- }
        local carriedCount = itemcounts[dataob.item]

        local itemLayout = renderIcon(obRecord.icon, dataob.count, carriedCount < dataob.count)
        itemcounts[dataob.item] = itemcounts[dataob.item] - dataob.count
        table.insert(content, itemLayout)
    end
    return ui.create {
        layer = "HUD",
        template = I.MWUI.templates.boxTransparent,
        props = {
            -- relativePosition = v2(0.65, 0.8),
            anchor = util.vector2(0.5, 0.5),
            relativePosition = v2(horizontal, vertical),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            vertical = false,
            horizontal = true
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    vertical = false,
                    horizontal = true,
                    arrange = ui.ALIGNMENT.Center,
                    align = ui.ALIGNMENT.Center,
                }
            }
        }
    }
end
local function renderItemChoice(itemList, horizontal, vertical, align, anchor)
    local content = {}
    for _, item in ipairs(itemList) do
        local itemLayout = renderItem(item)
        itemLayout.template = I.MWUI.templates.padding
        table.insert(content, itemLayout)
    end
    return ui.create {
        layer = "HUD",
        template = I.MWUI.templates.boxTransparent,
        props = {
            -- relativePosition = v2(0.65, 0.8),
            anchor = anchor,
            relativePosition = v2(horizontal, vertical),
            arrange = align,
            align = align,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    vertical = true,
                    arrange = align,
                    align = align,
                }
            }
        }
    }
end
local scale = 1.2
-- Safe + backward-compatible: renders a compact box with a title and an image.
-- Accepts either a table-like item (preferred) or a plain string label.
-- Fallbacks:
--  • Name order: EditorId → Name → FriendlyName → recordId → id → "<unnamed>"
--  • Texture order: textures/ashlanderarchitect/<EditorId|Texture_Name>.{jpg,png} → cs-icon.{png,jpg}
--  • Position defaults to screen center if not provided.
--  • Size defaults to 8*scale (your existing global 'scale' is respected).
local function flexedItems(content, horizontal, size)
    if not horizontal then
        horizontal = false
    end
    return {
        {
            type = ui.TYPE.Flex,
            content = ui.content(content),
            props = {
                horizontal = horizontal,
                align = ui.ALIGNMENT.Start,
                arrange = ui.ALIGNMENT.Start,
                size = size,
                autosize = false
            }
        }
    }
end
local function renderTextWithBox(tableItem, horizontal, vertical, size)
    -- ---------- helpers ----------
    local function toLabel(item)
        if type(item) == "string" then return item end
        if type(item) ~= "table" or not item then return "<unnamed>" end
        return item.FriendlyName
            or item.Name
            or item.EditorId
            or item.recordId
            or (item.id and tostring(item.id))
            or "<unnamed>"
    end

    local function texExists(path)
        return vfs.fileExists(path)
    end

    local function pickTexture(item)
        -- candidates in priority order
        local baseDir = "textures/ashlanderarchitect/"
        local editor = (type(item) == "table" and item and item.EditorId) or nil
        local texname = (type(item) == "table" and item and item.Texture_Name) or nil
        local candidates = {}

        if editor and #editor > 0 then
            table.insert(candidates, baseDir .. editor .. ".jpg")
            table.insert(candidates, baseDir .. editor .. ".png")
        end
        if texname and #texname > 0 then
            table.insert(candidates, baseDir .. texname .. ".jpg")
            table.insert(candidates, baseDir .. texname .. ".png")
        end
        -- defaults
        table.insert(candidates, baseDir .. "cs-icon.png")
        table.insert(candidates, baseDir .. "cs-icon.jpg")

        for _, p in ipairs(candidates) do
            if texExists(p) then
                return p
            end
        end
        -- hard fallback (shouldn't happen if defaults exist)
        return baseDir .. "cs-icon.png"
    end

    -- ---------- params / sizing ----------
    local label = toLabel(tableItem)
    local imgPath = pickTexture(tableItem)

    local s = (size == nil) and (8 * scale) or (size * scale)
    local x = tonumber(horizontal) or 0.5
    local y = tonumber(vertical) or 0.5

    -- ---------- content ----------
    local content = {}
    table.insert(content, renderItemBold(label))

    local resource = ui.texture { path = imgPath }
    table.insert(content, imageContent(resource, s))

    -- ---------- node ----------
    return ui.create {
        layer = "HUD",
        template = I.MWUI.templates.boxTransparent,
        props = {
            anchor = util.vector2(0.5, 0.5),
            relativePosition = v2(x, y),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
        },
        content = ui.content(flexedItems(content)),
    }
end

local function boxedTextContent(text, callback, textScale, name)
    if textScale == nil then
        textScale = 1
    end
    return {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                template = I.MWUI.templates.box,
                props = {
                    anchor = util.vector2(0, -0.5)
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        events = { mouseClick = callback },
                        props = {
                            text = text,
                            textSize = (15 * calculateTextScale()) * textScale,
                            align = ui.ALIGNMENT.Center,
                            name = name,
                        }
                    }
                }
            }
        }
    }
end
-- Backward-compatible, narrower TextEdit box.
-- Works with BOTH old and new call styles:
--   boxedTextEditContent(text, cb, true)              -- legacy multiline
--   boxedTextEditContent(text, cb, false)             -- legacy single-line
--   boxedTextEditContent(text, cb, { multiline=true })-- new opts table
--   boxedTextEditContent(text, cb, { fill=true })     -- fill parent width
--   boxedTextEditContent(text, cb, { minWidth=260, maxWidth=420, height=180, textSize=16 })
local function boxedTextEditContent(text, callback, third)
    -- ---- interpret 3rd arg (boolean for legacy, table for new opts) ----
    local isMultiline, opts
    if type(third) == "boolean" or third == nil then
        isMultiline = third and true or false
        opts = {}
    elseif type(third) == "table" then
        opts = third
        isMultiline = not not opts.multiline
    else
        -- unknown type -> default
        isMultiline, opts = false, {}
    end

    -- ---- sizing & behavior knobs (with sensible clamps) ----
    local fill           = not not opts.fill
    local minW           = tonumber(opts.minWidth) or 280
    local maxW           = tonumber(opts.maxWidth) or 420
    local screenW        = ui.layers and ui.layers[1] and ui.layers[1].size.x or 1280
    local targetW        = math.max(minW, math.min(maxW, math.floor(screenW * 0.35)))

    local lineH          = 30
    local multiH         = tonumber(opts.height) or 160
    local height         = isMultiline and multiH or lineH

    local tsize          = tonumber(opts.textSize) or (15 * (calculateTextScale and calculateTextScale() or 1))

    -- prefer multiline template if available, otherwise fall back
    local multilineTpl   = I.MWUI.templates.textEditMultiline or I.MWUI.templates.textEditLine
    local editTemplate   = isMultiline and multilineTpl or I.MWUI.templates.textEditLine

    -- ---- props computed for fill vs fixed width ----
    local containerProps = fill
        and { relativeSize = util.vector2(1, 0), anchor = util.vector2(0.5, 0.5) }
        or { size = util.vector2(targetW, height), anchor = util.vector2(0.5, 0.5) }

    local boxProps       = fill
        and { relativeSize = util.vector2(1, 0) }
        or { size = util.vector2(targetW, height) }

    local editProps
    if fill then
        editProps = {
            text = text or "",
            relativeSize = util.vector2(1, 0),
            size = util.vector2(0, height),
            textSize = tsize,
            align = ui.ALIGNMENT.Center,
            multiline = isMultiline,
        }
    else
        editProps = {
            text = text or "",
            size = util.vector2(targetW - 12, height), -- slight inset so it doesn't touch the box edges
            textSize = tsize,
            align = ui.ALIGNMENT.Center,
            multiline = isMultiline,
        }
    end

    return {
        type = ui.TYPE.Container,
        props = containerProps,
        content = ui.content {
            {
                template = I.MWUI.templates.box,
                props = boxProps,
                content = ui.content {
                    {
                        type = ui.TYPE.TextEdit,
                        template = editTemplate,
                        events = { textChanged = callback },
                        props = editProps,
                    }
                }
            }
        }
    }
end
return {
    interfaceName = "DaisyUtilsUI_AA",
    interface = {
        version = 1,
        imageContent = imageContent,
        textContent = textContent,
        textContentLeft = textContentLeft,
        paddedTextContent = paddedTextContent,
        boxedTextContent = boxedTextContent,
        hoverOne = hoverOne,
        hoverTwo = hoverTwo,
        hoverNone = hoverNone,
        boxedTextEditContent = boxedTextEditContent,
        renderItemChoice = renderItemChoice,
        renderTextWithBox = renderTextWithBox,
        renderTextInput = renderTextInput,
        renderTravelOptions = renderTravelOptions,
        renderItemChoiceReal = renderItemChoiceReal,
        renderObjectRequirements = renderObjectRequirements,
    },
}
