local core = require("openmw.core")
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local v2 = require("openmw.util").vector2
local input = require("openmw.input")
local self = require("openmw.self")

local mDef = require("scripts.fresh-loot.config.definition")
local mTypes = require("scripts.fresh-loot.config.types")
local mStore = require("scripts.fresh-loot.settings.store")
local mObj = require("scripts.fresh-loot.util.objects")
local mMod = require("scripts.fresh-loot.loot.modifier")

local l10n = core.l10n(mDef.MOD_NAME);

local module = {}

local itemWindow
local itemColumns = {}
local rowHasNameColumn = {}
local lastShownRowIndex = 0
local boxTemplate = I.MWUI.templates.boxTransparent

local function padding(horizontal, vertical)
    return { props = { size = v2(horizontal, vertical) } }
end

local growingInterval = {
    external = { grow = 1 }
}

local stretchingLine = {
    template = I.MWUI.templates.horizontalLine,
    external = {
        stretch = 1,
    },
}

local function title(text)
    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textHeader,
        props = {
            text = text,
            textSize = 32,
        }
    }
end

local function head(text)
    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textHeader,
        props = { text = text }
    }
end

local function text(str, extraProps)
    local props = { text = tostring(str) }
    if extraProps then
        for k, v in pairs(extraProps) do
            props[k] = v
        end
    end
    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = props,
    }
end

local function icon(resource)
    return {
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture { path = resource },
            size = v2(32, 32),
        },
    }
end

local function cell(content, onLeft)
    return {
        type = ui.TYPE.Flex,
        external = { stretch = 1 },
        props = {
            size = v2(0, 36),
            arrange = onLeft and ui.ALIGNMENT.Start or ui.ALIGNMENT.End
        },
        content = ui.content {
            growingInterval,
            padding(0, 2),
            content,
            padding(0, 2),
            growingInterval,
        },
    }
end

local function column(content)
    return {
        type = ui.TYPE.Flex,
        props = { horizontal = true },
        content = ui.content {
            padding(5, 0),
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
            },
            padding(5, 0),
        },
    }
end

local function centerWindow(content)
    return {
        layer = "Windows",
        template = boxTemplate,
        props = {
            relativePosition = v2(.5, .5),
            anchor = v2(.5, .5)
        },
        content = ui.content { content }
    }
end

local function window(content)
    return centerWindow({
        type = ui.TYPE.Flex,
        content = ui.content {
            padding(0, 10),
            {
                type = ui.TYPE.Flex,
                props = { horizontal = true },
                external = { stretch = 1 },
                content = ui.content { padding(30, 0), content, padding(30, 0) }
            },
            padding(0, 20),
        }
    })
end

local function requestWindow()
    local items = {}
    local inventory = self.type.inventory(self)
    for type in pairs(mTypes.itemTypes) do
        for _, item in ipairs(inventory:getAll(type)) do
            table.insert(items, item)
        end
    end
    core.sendGlobalEvent(mDef.events.filterConvertedItems, mTypes.new.requestEvent(mDef.events.returnConvertedItems, self, items))
end

local headers = {
    cell(),
    cell(head(l10n("window_header_name")), true),
    cell(head(l10n("window_header_mod"))),
    cell(head(l10n("window_header_level"))),
    cell(head(l10n("window_header_props"))),
}

local function setItemColumns(convertedItems)
    table.sort(convertedItems, function(a, b) return a.name < b.name end)
    itemColumns = { {}, {}, {}, {}, {} }
    rowHasNameColumn = {}
    local hasProps = false
    for _, convertedItem in ipairs(convertedItems) do
        local record = mObj.getRecord(convertedItem.item)
        table.insert(itemColumns[1], cell(icon(record.icon)))
        table.insert(itemColumns[2], cell(text(record.name), true))
        table.insert(rowHasNameColumn, true)
        for i = 1, 2 do
            local lvlMod = convertedItem.lvlMods[i]
            if lvlMod then
                if i > 1 then
                    table.insert(itemColumns[1], cell())
                    table.insert(itemColumns[2], cell())
                    table.insert(rowHasNameColumn, false)
                end
                table.insert(itemColumns[3], cell(text('"' .. mMod.getAffixName(lvlMod.mod) .. '"')))
                table.insert(itemColumns[4], cell(text(lvlMod.lvl)))
                local description = mMod.getDescription(lvlMod.mod, lvlMod.lvl)
                hasProps = hasProps or description
                table.insert(itemColumns[5], cell(text(description or "")))
            end
        end
    end
    if not hasProps then
        itemColumns[5] = nil
    end
end

local noItemsContent = {
    type = ui.TYPE.Flex,
    content = ui.content {
        padding(0, 10),
        text(l10n("window_no_items")),
    }
}

local function createWindow(fromRowIndex)
    local content = {}
    if #rowHasNameColumn == 0 then
        table.insert(content, noItemsContent)
    else
        lastShownRowIndex = math.min(fromRowIndex + mStore.cfg.maxItemWindowRowsPerPage.get() - 1, #rowHasNameColumn)
        while (lastShownRowIndex < #rowHasNameColumn and not rowHasNameColumn[lastShownRowIndex + 1]) do
            lastShownRowIndex = lastShownRowIndex + 1
        end
        for i, col in ipairs(itemColumns) do
            table.insert(content, column({ headers[i], table.unpack(col, fromRowIndex, lastShownRowIndex) }))
        end
    end

    itemWindow = ui.create(
            window({
                type = ui.TYPE.Flex,
                content = ui.content {
                    {
                        type = ui.TYPE.Flex,
                        props = { arrange = ui.ALIGNMENT.Center },
                        external = { stretch = 1 },
                        content = ui.content { title(l10n("window_title")) }
                    },
                    padding(0, 10),
                    stretchingLine,
                    {
                        type = ui.TYPE.Flex,
                        props = { horizontal = true },
                        content = ui.content(content),
                    },
                }
            }))

end

local function showWindow(convertedItems)
    setItemColumns(convertedItems)
    createWindow(1)
end
module.showWindow = showWindow

local function toggleItemWindow()
    if itemWindow then
        itemWindow:destroy()
        if lastShownRowIndex == #rowHasNameColumn then
            itemWindow = nil
        else
            createWindow(lastShownRowIndex + 1)
        end
    else
        requestWindow()
    end
end

local function onKeyPress(key)
    -- Prevent the item window from rendering over the escape menu
    if key.code == input.KEY.Escape and itemWindow then
        toggleItemWindow()
        return
    end

    if key.code == mStore.cfg.itemsWindowKey.get() then
        toggleItemWindow()
    end
end
module.onKeyPress = onKeyPress

module.callbackEvents = {
    [mDef.events.returnConvertedItems] = showWindow
}

return module
