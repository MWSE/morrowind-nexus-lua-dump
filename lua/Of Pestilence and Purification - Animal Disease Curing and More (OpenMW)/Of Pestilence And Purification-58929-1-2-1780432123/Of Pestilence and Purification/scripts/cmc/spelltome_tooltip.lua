--[[
    Of Pestilence and Purification — Inventory Extender spell-tome tooltip interop

    Adds Spell Tomes-style Inventory Extender tooltips for OPP spell tomes:
      * "Teaches the spell ..."
      * "Known" when the player already knows at least one taught spell
      * "Unread" otherwise

    Inventory Extender is optional. This script registers the tooltip modifier
    only when IE is present.
]]

local core  = require('openmw.core')
local I     = require('openmw.interfaces')
local self  = require('openmw.self')
local types = require('openmw.types')
local ui    = require('openmw.ui')
local util  = require('openmw.util')

local cfg = require('scripts.cmc.config')

local MODIFIER_ID = 'OPP_SpellTomeTooltips'

local COLORS = {
    MAGIC = util.color.rgb(0.7, 0.5, 0.9),
    KNOWN = util.color.rgb(0.5, 0.9, 0.5),
    UNREAD = util.color.rgb(0.8, 0.3, 0.3),
}

local registered = false

local function contentKey(content, key)
    if not content or key == nil then return nil end
    local ok, value = pcall(function() return content[key] end)
    if ok then return value end
    return nil
end

local function tooltipContent(layout)
    local rootContent = layout and layout.content

    -- Inventory Extender 1.x: Templates.tooltip(...) wraps the real tooltip
    -- flex in the first child's first child's content.
    local first = contentKey(rootContent, 1)
    local firstInner = first and first.content
    local nestedTooltip = contentKey(firstInner, 1)
    if nestedTooltip and nestedTooltip.content then
        return nestedTooltip.content
    end

    -- Defensive fallback for named/padded tooltip layouts.
    local padding = contentKey(rootContent, 'padding')
    local paddingInner = padding and padding.content
    local tooltip = contentKey(paddingInner, 'tooltip')
    if tooltip and tooltip.content then
        return tooltip.content
    end

    return nil
end

local function interval(width, height)
    return {
        type = ui.TYPE.Widget,
        props = { size = util.vector2(width or 0, height or 0) },
    }
end

local function textTemplate()
    local base = I.InventoryExtender and I.InventoryExtender.Templates and I.InventoryExtender.Templates.BASE
    return (base and base.textNormal) or (I.MWUI and I.MWUI.templates and I.MWUI.templates.textNormal)
end

local function textLine(text, color)
    return {
        type = ui.TYPE.Text,
        template = textTemplate(),
        props = {
            text = text or '',
            textColor = color,
            autoSize = true,
            multiline = true,
            textAlignH = ui.ALIGNMENT.Center,
        },
    }
end

local function addDivider(content)
    content:add(interval(0, 8))
    if I.MWUI and I.MWUI.templates and I.MWUI.templates.horizontalLine then
        content:add({
            template = I.MWUI.templates.horizontalLine,
            props = { size = util.vector2(200, 2) },
        })
    end
    content:add(interval(0, 4))
end

local function objectRecordId(item)
    local id = item and (item.recordId or item.id)
    if id == nil then return nil end
    return cfg.lowerId(id)
end

local function resolveTomeByRecordId(recordId)
    if not recordId then return nil end
    return cfg.tomeById and cfg.tomeById[cfg.lowerId(recordId)] or nil
end

local function resolveTomeByBookName(recordId)
    if not recordId or not cfg.tomeByName then return nil end
    if not types.Book or not types.Book.records then return nil end

    local ok, record = pcall(function()
        return types.Book.records[recordId] or types.Book.records[cfg.lowerId(recordId)]
    end)
    if ok and record and record.name then
        return cfg.tomeByName[tostring(record.name):lower()]
    end
    return nil
end

local function resolveTome(item)
    local recordId = objectRecordId(item)
    return resolveTomeByRecordId(recordId) or resolveTomeByBookName(recordId)
end

local function spellRecordName(spellId)
    spellId = cfg.lowerId(spellId)
    local record = spellId and core.magic.spells.records[spellId]
    return (record and record.name) or spellId
end

local function spellListText(spells)
    local names = {}
    for _, spellId in ipairs(spells or {}) do
        local name = spellRecordName(spellId)
        if name and name ~= '' then names[#names + 1] = name end
    end

    if #names == 0 then return nil end
    if #names == 1 then return 'Teaches the spell ' .. names[1] .. '.' end
    return 'Teaches the spells ' .. table.concat(names, ', ') .. '.'
end

local function playerKnowsAnySpell(spells)
    local known = {}
    local ok, playerSpells = pcall(function() return types.Player.spells(self) end)
    if not ok or not playerSpells then return false end

    for _, spell in pairs(playerSpells) do
        if spell and spell.id then known[cfg.lowerId(spell.id)] = true end
    end

    for _, spellId in ipairs(spells or {}) do
        if known[cfg.lowerId(spellId)] then return true end
    end
    return false
end

local function layoutContainsSpellTomeBlock(node)
    if not node then return false end
    if node.props and type(node.props.text) == 'string'
        and node.props.text:find('Teaches the spell', 1, true) then
        return true
    end

    local content = node.content
    if not content then return false end

    local ok, count = pcall(function() return #content end)
    if not ok then return false end

    for i = 1, count do
        if layoutContainsSpellTomeBlock(contentKey(content, i)) then return true end
    end
    return false
end

local function addSpellTomeTooltip(item, layout)
    local tome = resolveTome(item)
    if not tome or not tome.spells then return layout end
    if layoutContainsSpellTomeBlock(layout) then return layout end

    layout.userData = layout.userData or {}
    if layout.userData.OPPSpellTomeTooltip then return layout end

    local content = tooltipContent(layout)
    if not content then return layout end
    layout.userData.OPPSpellTomeTooltip = true

    local teachesText = spellListText(tome.spells)
    if not teachesText then return layout end

    addDivider(content)
    content:add(textLine(teachesText, COLORS.MAGIC))
    content:add(interval(0, 2))

    local known = playerKnowsAnySpell(tome.spells)
    content:add(textLine(known and 'Known' or 'Unread', known and COLORS.KNOWN or COLORS.UNREAD))

    return layout
end

local function registerTooltipModifier()
    if registered then return end
    if not I.InventoryExtender or type(I.InventoryExtender.registerTooltipModifier) ~= 'function' then return end

    I.InventoryExtender.registerTooltipModifier(MODIFIER_ID, function(item, layout)
        return addSpellTomeTooltip(item, layout)
    end)
    registered = true
end

return {
    engineHandlers = {
        onInit = registerTooltipModifier,
        onLoad = registerTooltipModifier,
        onUpdate = function()
            if not registered then registerTooltipModifier() end
        end,
    },
}
