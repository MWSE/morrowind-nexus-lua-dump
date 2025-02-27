local core = require('openmw.core')
local async = require('openmw.async')
local input = require('openmw.input')
local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require("openmw.interfaces")

local def = require('scripts.NCGDMW.definition')

-- THANKS:
-- https://gitlab.com/urm-openmw-mods/camerahim/-/blob/1a12e3f8c902291d5629f2d8cc8649eac315533a/Data%20Files/scripts/CameraHIM/settings.lua#L23-35
I.Settings.registerRenderer(
        "NCGDMW_hotkey", function(value, set)
            return {
                template = I.MWUI.templates.textEditLine,
                props = {
                    text = value and input.getKeyName(value) or '',
                    textAlignH = ui.ALIGNMENT.End,
                },
                events = {
                    keyPress = async:callback(function(e)
                        set(e.code)
                    end)
                }
            }
        end)

local growingInterval = {
    external = { grow = 1 }
}

local stretchingLine = {
    template = I.MWUI.templates.horizontalLine,
    external = { stretch = 1 },
}

local leftArrow = ui.texture {
    path = 'textures/omw_menu_scroll_left.dds',
}

local rightArrow = ui.texture {
    path = 'textures/omw_menu_scroll_right.dds',
}

local function validateNumber(text, argument)
    local number = tonumber(text)
    if not number then return end
    if argument.min and number < argument.min then return argument.min end
    if argument.max and number > argument.max then return argument.max end
    if argument.integer and math.floor(number) ~= number then return math.floor(number) end
    return number
end

local registerMultiSelectNumberRenderer = function(settingKey, allItems)
    I.Settings.registerRenderer(
            settingKey, function(data, set, argument)
                data = data or {}
                local items = {}
                local lines = {}

                local getAvailableItems = function()
                    local available = {}
                    local taken = {}
                    for _, item in ipairs(items) do
                        taken[item.key] = true
                    end
                    for _, item in ipairs(allItems) do
                        if not taken[item.key] then
                            table.insert(available, item)
                        end
                    end
                    return available
                end

                local getNextItem = function(key, forward)
                    local available = {}
                    local taken = {}
                    for _, item in ipairs(items) do
                        if item.key ~= key then
                            taken[item.key] = true
                        end
                    end
                    local index
                    for _, item in ipairs(allItems) do
                        if not taken[item.key] then
                            if item.key == key then
                                index = #available + 1
                            end
                            table.insert(available, item)
                        end
                    end
                    return available[(index + (forward and 0 or -2)) % #available + 1]
                end

                local lastInput

                for index, item in pairs(data) do
                    table.insert(items, { key = item.key, name = item.name, value = item.value })

                    table.insert(lines, {
                        type = ui.TYPE.Flex,
                        props = { horizontal = true },
                        external = { stretch = 1 },
                        content = ui.content {
                            growingInterval,
                            {
                                type = ui.TYPE.Image,
                                props = {
                                    resource = leftArrow,
                                    size = util.vector2(1, 1) * 12,
                                },
                                events = {
                                    mouseClick = async:callback(function()
                                        items[index] = getNextItem(item.key, false)
                                        set(items)
                                    end),
                                },
                            },
                            { template = I.MWUI.templates.interval },
                            {
                                template = I.MWUI.templates.textNormal,
                                props = { text = item.name },
                            },
                            { template = I.MWUI.templates.interval },
                            {
                                type = ui.TYPE.Image,
                                props = {
                                    resource = rightArrow,
                                    size = util.vector2(1, 1) * 12,
                                },
                                events = {
                                    mouseClick = async:callback(function()
                                        items[index] = getNextItem(item.key, true)
                                        set(items)
                                    end),
                                },
                            },
                            {
                                template = I.MWUI.templates.textEditLine,
                                props = {
                                    text = tostring(item.value),
                                    size = util.vector2(50, 0),
                                    textAlignH = ui.ALIGNMENT.End,
                                },
                                events = {
                                    textChanged = async:callback(function(value)
                                        lastInput = value
                                    end),
                                    focusLoss = async:callback(function()
                                        if not lastInput then return end
                                        local number = validateNumber(lastInput, argument)
                                        if number and number ~= data then
                                            items[index].value = number
                                        end
                                        set(items)
                                        lastInput = nil
                                    end),
                                }
                            },
                            { props = { size = util.vector2(10, 0) } },
                            {
                                type = ui.TYPE.Text,
                                template = I.MWUI.templates.textNormal,
                                props = {
                                    text = "x",
                                    textSize = 14,
                                    textColor = util.color.rgb(.8, .3, .4),
                                },
                                events = {
                                    mouseClick = async:callback(function()
                                        table.remove(items, index)
                                        set(items)
                                    end),
                                }
                            },
                        },
                    })
                end

                return {
                    type = ui.TYPE.Flex,
                    content = ui.content {
                        {
                            type = ui.TYPE.Flex,
                            props = {
                                horizontal = true,
                                size = util.vector2(200, 0),
                            },
                            external = { stretch = 1 },
                            content = ui.content {
                                growingInterval,
                                {
                                    type = ui.TYPE.Text,
                                    template = I.MWUI.templates.textNormal,
                                    props = {
                                        text = "+",
                                        textSize = 32,
                                    },
                                    events = {
                                        mouseClick = async:callback(function()
                                            local available = getAvailableItems()
                                            if #available > 0 then
                                                items[#items + 1] = available[1]
                                                set(items)
                                            end
                                        end),
                                    }
                                },
                            },
                        },
                        stretchingLine,
                        table.unpack(lines),
                    },
                }
            end)

end

local skillItems = {}
local attributeItems = {}
if def.isLuaApiRecentEnough then
    for _, stat in pairs(core.stats.Skill.records) do
        table.insert(skillItems, { key = stat.id, name = stat.name, value = 1000 })
    end
    for _, stat in pairs(core.stats.Attribute.records) do
        table.insert(attributeItems, { key = stat.id, name = stat.name, value = 1000 })
    end
else
    attributeItems = {
        { key = "strength", name = "Strength", value = 1000 },
        { key = "intelligence", name = "Intelligence", value = 1000 },
        { key = "willpower", name = "Willpower", value = 1000 },
        { key = "agility", name = "Agility", value = 1000 },
        { key = "speed", name = "Speed", value = 1000 },
        { key = "endurance", name = "Endurance", value = 1000 },
        { key = "personality", name = "Personality", value = 1000 },
        { key = "luck", name = "Luck", value = 1000 },
    }
    skillItems = {
        { key = "block", name = "Block", value = 1000 },
        { key = "armorer", name = "Armorer", value = 1000 },
        { key = "mediumarmor", name = "Medium Armor", value = 1000 },
        { key = "heavyarmor", name = "Heavy Armor", value = 1000 },
        { key = "bluntweapon", name = "Blunt Weapon", value = 1000 },
        { key = "longblade", name = "Long Blade", value = 1000 },
        { key = "axe", name = "Axe", value = 1000 },
        { key = "spear", name = "Spear", value = 1000 },
        { key = "athletics", name = "Athletics", value = 1000 },
        { key = "enchant", name = "Enchant", value = 1000 },
        { key = "destruction", name = "Destruction", value = 1000 },
        { key = "alteration", name = "Alteration", value = 1000 },
        { key = "illusion", name = "Illusion", value = 1000 },
        { key = "conjuration", name = "Conjuration", value = 1000 },
        { key = "mysticism", name = "Mysticism", value = 1000 },
        { key = "restoration", name = "Restoration", value = 1000 },
        { key = "alchemy", name = "Alchemy", value = 1000 },
        { key = "unarmored", name = "Unarmored", value = 1000 },
        { key = "security", name = "Security", value = 1000 },
        { key = "sneak", name = "Sneak", value = 1000 },
        { key = "acrobatics", name = "Acrobatics", value = 1000 },
        { key = "lightarmor", name = "Light Armor", value = 1000 },
        { key = "shortblade", name = "Short Blade", value = 1000 },
        { key = "marksman", name = "Marksman", value = 1000 },
        { key = "mercantile", name = "Mercantile", value = 1000 },
        { key = "speechcraft", name = "Speechcraft", value = 1000 },
        { key = "handtohand", name = "Hand-to-hand", value = 1000 },
    }
end

registerMultiSelectNumberRenderer("NCGDMW_per_skill_uncapper", skillItems)
registerMultiSelectNumberRenderer("NCGDMW_per_attribute_uncapper", attributeItems)