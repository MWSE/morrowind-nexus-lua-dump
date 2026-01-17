local util        = require('openmw.util')
local async       = require('openmw.async')
local types       = require('openmw.types')
local I           = require('openmw.interfaces')
local auxUi       = require('openmw_aux.ui')
local ui          = require('openmw.ui')
local textures    = require('scripts.ActorInteractions.myLib.myConstants').textures
local myTemplates = require('scripts.ActorInteractions.myLib.myTemplates')
local myConstants = require('scripts.ActorInteractions.myLib.myConstants')
local makeInt     = require('scripts.ActorInteractions.myLib.myGUI').makeInt
local myGUI       = require('scripts.ActorInteractions.myLib.myGUI')

local sizes       = require('scripts.ActorInteractions.myLib.myConstants').sizes
-- local textures = require('scripts.ActorInteractions.myLib.myConstants').textures

---@return ui.Layout
local function getEmptyGridItemLayout()
        return {
                type = ui.TYPE.Flex,
                props = {
                        size = util.vector2(sizes.GRID_ITEM_SIZE, sizes.GRID_ITEM_SIZE),
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center,
                },
                userData = {
                        item = 'empty',
                },
                content = ui.content {
                        {
                                type = ui.TYPE.Image,
                                props = {
                                        resource = textures.emptyEq,
                                        size = util.vector2(sizes.GRID_ITEM_SIZE, sizes.GRID_ITEM_SIZE),
                                },
                        }
                },
        }
end

---@param item ScrollableItem
---@return ui.Layout
local function getGridItemLayout(item)
        return {
                type = ui.TYPE.Flex,
                -- template = I.MWUI.templates.borders,
                props = {
                        size = util.vector2(myConstants.sizes.GRID_ITEM_SIZE, myConstants.sizes.GRID_ITEM_SIZE),
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center,
                },
                userData = {
                        item = item.object or item.spell,
                },
                content = ui.content {
                        {

                                type = ui.TYPE.Container,
                                -- template = types.Actor.hasEquipped(actor, item) and myTemplates.iconFrame,
                                template = item.equipped and myTemplates.iconFrame,
                                content = ui.content {
                                        item.magical and {
                                                type = ui.TYPE.Image,
                                                props = {
                                                        resource = myConstants.textures.magicIcon,
                                                        -- size = util.vector2(myConstants.sizes.LIST_TEXT_SIZE, myConstants.sizes.LIST_TEXT_SIZE),
                                                        size = util.vector2(myConstants.sizes.GRID_ITEM_SIZE - 8,
                                                                myConstants.sizes.GRID_ITEM_SIZE - 8),

                                                },
                                        } or {},
                                        {
                                                type = ui.TYPE.Image,

                                                props = {
                                                        resource = ui.texture {
                                                                path = item.icon,
                                                        },
                                                        size = util.vector2(myConstants.sizes.GRID_ITEM_SIZE - 8,
                                                                myConstants.sizes.GRID_ITEM_SIZE - 8),
                                                },
                                        },
                                        {
                                                type = ui.TYPE.Flex,
                                                props = {
                                                        align = ui.ALIGNMENT.End,
                                                        arrange = ui.ALIGNMENT.End,
                                                        size = util.vector2(myConstants.sizes.GRID_ITEM_SIZE - 8,
                                                                myConstants.sizes.GRID_ITEM_SIZE - 8),
                                                },

                                                content = ui.content {

                                                        {

                                                                template = I.MWUI.templates.textHeader,
                                                                props = {
                                                                        text = tostring(item.count > 1 and item.count or ''),
                                                                },
                                                        }
                                                }
                                        }
                                },
                        }
                },
        }
end


---@return ui.Layout
local function getEmptyTextItemLayout()
        return {
                type = ui.TYPE.Flex,
                props = {
                        horizontal = true,
                        relativeSize = util.vector2(1, 0),
                },
                userData = {
                        name = 'aaaaaaaaaaaaaaaaaaaaa',
                },
                content = ui.content {
                        makeInt(4, 0),
                        {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = 'Empty',
                                        textSize = sizes.LIST_TEXT_SIZE
                                }
                        }
                },
        }
end

---@param item ScrollableItem
---@param extraLO? ui.Layout
---@return ui.Layout
local function getTextListItemLayout(item, extraLO)
        -- -@type WeaponRecord|ArmorRecord|ClothingRecord
        -- local record = item.type.record(item)
        -- local extraInfo
        -- if record.baseArmor then
        --         extraInfo = record.baseArmor
        -- elseif record.chopMaxDamage then
        --         extraInfo = math.max(record.chopMaxDamage, record.slashMaxDamage, record.thrustMaxDamage)
        -- end


        local name
        if item.count and item.count > 1 then
                name = string.format('%s (%s)', item.name, item.count)
        else
                name = string.format('%s', item.name)
        end

        local icon = {
                type = ui.TYPE.Container,
                -- template = types.Actor.hasEquipped(actor, item) and myTemplates.iconFrame,
                template = item.equipped and myTemplates.iconFrame,
                content = ui.content {
                        item.magical and {
                                type = ui.TYPE.Image,
                                props = {
                                        resource = myConstants.textures.magicIcon,
                                        size = util.vector2(myConstants.sizes.LIST_TEXT_SIZE, myConstants.sizes.LIST_TEXT_SIZE),

                                },
                        } or {},
                        {
                                type = ui.TYPE.Image,
                                props = {
                                        resource = ui.texture {
                                                path = item.icon,
                                        },
                                        size = util.vector2(myConstants.sizes.LIST_TEXT_SIZE, myConstants.sizes.LIST_TEXT_SIZE),
                                },
                        }
                },
        }


        return {
                type = ui.TYPE.Flex,
                props = {
                        horizontal = true,
                        relativeSize = util.vector2(1, 0),
                        -- size = util.vector2(200, 30),
                        -- align = ui.ALIGNMENT.Center,
                },
                userData = {
                        -- name = item.name:lower(),
                        item = item.object or item.spell,
                },
                content = ui.content {
                        makeInt(4, 0),
                        icon,
                        makeInt(4, 0),
                        {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        -- text = record.name,
                                        text = name,
                                        textSize = myConstants.sizes.LIST_TEXT_SIZE,
                                }
                        },
                        makeInt(4, 0),
                        extraLO and makeInt(1, 0, 1, 0) or {},
                        extraLO,
                        makeInt(10, 0),
                        -- extraInfo and {
                        --         template = I.MWUI.templates.textNormal,
                        --         props = {
                        --                 text = tostring(extraInfo),
                        --                 textSize = myConstants.sizes.LIST_TEXT_SIZE,
                        --         }
                        -- },
                        -- makeInt(8, 0),
                },

        }
end





---@param text string
---@param icon string
---@return ui.Layout
local function getCustomTextListItemLayout(text, icon)
        local iconLayout = {
                type = ui.TYPE.Image,
                props = {
                        resource = ui.texture {
                                path = icon,
                        },
                        size = util.vector2(myConstants.sizes.LIST_TEXT_SIZE, myConstants.sizes.LIST_TEXT_SIZE),
                },
        }


        return {
                type = ui.TYPE.Flex,
                props = {
                        horizontal = true,
                        relativeSize = util.vector2(1, 0),
                },
                userData = {
                        -- name = item.name:lower(),
                },
                content = ui.content {
                        makeInt(4, 0),
                        iconLayout,
                        makeInt(4, 0),
                        {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = text,
                                        textSize = myConstants.sizes.LIST_TEXT_SIZE,
                                }
                        },
                        makeInt(4, 0),
                },

        }
end

local function getConfirmLayout(callback)
        local el
        el = ui.create {
                layer    = 'Notification',
                type     = ui.TYPE.Flex,
                template = I.MWUI.templates.borders,
                props    = {
                        relativePosition = util.vector2(0.5, 0.5),
                        anchor = util.vector2(0.5, 0.5),
                        relativeSize = util.vector2(0.5, 0.5),
                        arrange = ui.ALIGNMENT.Center,
                },
                content  = ui.content {
                        {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = "Are You Sure?",
                                        textSize = 20,
                                },
                                events = {
                                        mousePress = async:callback(function()
                                                el:destroy()
                                        end)
                                }
                        },

                        {
                                type = ui.TYPE.Flex,
                                template = I.MWUI.templates.borders,
                                content = ui.content {

                                        {
                                                template = I.MWUI.templates.textNormal,
                                                props = {
                                                        text = "No",
                                                        textSize = 20,
                                                },
                                                events = {
                                                        mousePress = async:callback(function()
                                                                el:destroy()
                                                        end)
                                                }
                                        },
                                        {
                                                template = I.MWUI.templates.textNormal,
                                                props = {
                                                        text = "Yes",
                                                        textSize = 20,
                                                },
                                                events = {
                                                        mousePress = async:callback(function()
                                                                callback()
                                                                el:destroy()
                                                        end)
                                                }
                                        },
                                }
                        }
                }
        }
end



return {
        getGridItemLayout = getGridItemLayout,
        getEmptyGridItemLayout = getEmptyGridItemLayout,
        getTextListItemLayout = getTextListItemLayout,
        getEmptyTextItemLayout = getEmptyTextItemLayout,
        getCustomTextListItemLayout = getCustomTextListItemLayout,
        getConfirmLayout = getConfirmLayout,
}
