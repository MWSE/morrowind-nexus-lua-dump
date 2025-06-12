-- Zerkish Hotkeys Improved - zhi_hotbarhud.lua
-- Visual Hotbar for Hud

local async     = require('openmw.async')
local core      = require('openmw.core')
local ui        = require('openmw.ui')
local util      = require('openmw.util')
local MWUI      = require('openmw.interfaces').MWUI
local I         = require('openmw.interfaces')
local storage   = require('openmw.storage')
local self      = require('openmw.self')
local types     = require('openmw.types')
local constants = require('scripts.omw.mwui.constants')

local ZHIUI         = require('scripts.ZerkishHotkeysImproved.zhi_ui')
local ZHIUtil       = require('scripts.ZerkishHotkeysImproved.zhi_util')
local ZHIHotbarData = require('scripts.ZerkishHotkeysImproved.zhi_hotbardata')

local ZMUtility = require('scripts.ZModUtils.Utility')

local ZHI_HOTBARHUD_CONSTANTS = {
    HotkeySize = 48,
    HotkeyIconSize = 32,
    HotkeyBorderSize = 44,
    HotkeyPadding = 4,

    DataBarHeight = 6,
    ConditionColor = util.color.rgb(0.90, 0.20, 0.15),
    ChargeColor = util.color.rgb(0.50, 0.60, 0.90),

    KeyTextColor = util.color.rgb(0.65, 0.67, 0.70),
    CountTextColor = constants.headerColor,
}

local isHudVisible = false
local hudWindow = nil

local sHotbarHUDScale = 1.0
local sShowCondition = false
local sShowCharge = false
local sShowCount = false
local sShowKey = false
local sShowSpellCastChance = false
local sAnchorX = 0.5
local sAnchorY = 1.0
local sPositionX = 0.5
local sPositionY = 0.975
local sUpdateInterval = 0.2
local sRemoveEmptyHotkeys = false

-- Appearance
local sIconSize = 32
local sIconBorderEnabled = true
local sIconBorderSize = 44
local sIconMagicEnabled = true
local sHotkeySize = 48
local sHotkeyPadding = 4
local sHotkeyBorderEnabled = true
local sItemCountTextSize = 14
local sItemCountColor = constants.headerColor
local sItemCountAnchorX = 0.9
local sItemCountAnchorY = 0.925
local sKeyTextSize = 14
local sKeyTextColor =  util.color.rgb(0.65, 0.67, 0.70)
local sKeyTextAnchorX = 0.9
local sKeyTextAnchorY = 0.0775
local sDataBarPadding = 1
local sDataBarCondColor = util.color.rgb(0.90, 0.20, 0.15)
local sDataBarChargeColor = util.color.rgb(0.50, 0.60, 0.90)


local function createSmallProgressBar(width, height, color, percent, name)
    local p = percent and (math.max(0.0, math.min(1.0, percent))) or 1.0
    local barLength = (width - constants.border * 2) * p

    local barImage = {
        type = ui.TYPE.Image,
        name = name,
        props = {
            inheritAlpha = false,
            color = color,
            size = util.vector2(barLength, height - constants.border * 2),
            resource = ZHIUtil.getCachedTexture({
                path = 'textures/menu_bar_gray.dds',
                size = util.vector2(1, 8),
                offset = util.vector2(0, 0),
            })
        },
    }

    local barGroup = {
        template = I.MWUI.templates.boxSolid,
        type = ui.TYPE.Container,
        props = {
            inheritAlpha = false,
        },
        content = ui.content({
            {
                type = ui.TYPE.Widget,
                props = {
                    size = util.vector2(width - constants.border * 2, height - constants.border * 2),
                },
                content = ui.content({
                    barImage,
                })
            }
        }),
    }

    return barGroup
end

local function getDataBarSize()
    local borderOffset = 0 -- sHotkeyBorderEnabled and (constants.border * 2) or 0
    local height = math.max(ZHI_HOTBARHUD_CONSTANTS.DataBarHeight * sHotbarHUDScale, constants.border * 2 + 2)

    return util.vector2(sHotkeySize * sHotbarHUDScale + borderOffset, height)
end

local function createHotkeyWidget(num)

    local barWidth = getDataBarSize().x
    local barHeight = getDataBarSize().y

    local innerBarsGroup = {
        type = ui.TYPE.Flex,
        name = "data_bars",
        props = {
            autoSize = true,
            anchor = util.vector2(0.5, 0.0),
            relativePosition = util.vector2(0.5, 0.0),
        },
        content = ui.content({
            createSmallProgressBar(barWidth, barHeight, sDataBarCondColor, 1.0),
            {
                type = ui.TYPE.Widget,
                props = { size = util.vector2(0, sDataBarPadding) }
            },
            createSmallProgressBar(barWidth, barHeight, sDataBarChargeColor, 1.0),
        })
    }

    local bars = {
        type = ui.TYPE.Widget,
        props = {
            size = util.vector2(barWidth, barHeight * 2 + sDataBarPadding)
        },
        content = ui.content({
            innerBarsGroup
        })
    }

    local offset = 0
    if sHotkeyBorderEnabled then
        offset = -constants.border * 2
    end

    local innerWidget = {
        type = ui.TYPE.Widget,
        props = {
            size = util.vector2(sHotkeySize * sHotbarHUDScale + offset, sHotkeySize * sHotbarHUDScale + offset)
        },
        content = ui.content({
            {
                type = ui.TYPE.Image,
                name = 'background',
                props = {
                    inheritAlpha = false,
                    alpha = 1.0,
                    resource = ZHIUtil.getCachedTexture({
                        path = 'textures/zhi_black.bmp',
                        size = util.vector2(32, 32),
                        offset = util.vector2(6, 6),
                        
                    }),
                    --color = util.color.rgb(0, 0, 0),
                    size = util.vector2(sHotkeySize * sHotbarHUDScale + offset, sHotkeySize * sHotbarHUDScale + offset),
                    relativePosition = util.vector2(0.5, 0.5),
                    anchor = util.vector2(0.5, 0.5),
                },
            },
            -- {
            --     type = ui.TYPE.Text,
            --     name = 'txt_hotbar',
            --     props = {
            --         inheritAlpha = false,
            --         text = tostring(num),
            --         textSize = math.floor(sKeyTextSize * sHotbarHUDScale),
            --         textColor = sKeyTextColor, -- ZHI_HOTBARHUD_CONSTANTS.KeyTextColor,
            --         textShadow = true,
            --         textShadowColor = util.color.rgb(0.0, 0.0, 0.0),

            --         anchor = util.vector2(1.0, 0.0),
            --         relativePosition = util.vector2(sKeyTextAnchorX, sKeyTextAnchorY),
            --     }
            -- },
            {
                type = ui.TYPE.Image,
                name = 'bg_magic',
                props = {
                    inheritAlpha = false,
                    resource = ZHIUtil.getCachedTexture({
                        path = 'textures/menu_icon_magic.dds',
                        size = util.vector2(32, 32),
                        offset = util.vector2(6, 6),
                    }),
                    size = util.vector2(sIconBorderSize * sHotbarHUDScale, sIconBorderSize * sHotbarHUDScale),
                    relativePosition = util.vector2(0.5, 0.5),
                    anchor = util.vector2(0.5, 0.5),
                }
            },            
            {
                type = ui.TYPE.Image,
                name = 'border',
                props = {
                    inheritAlpha = false,
                    resource = ZHIUtil.getCachedTexture({
                        path = 'textures/menu_icon_select_magic_magic.dds',
                        size = util.vector2(42, 42),
                        offset = util.vector2(2, 2),
                    }),
                    size = util.vector2(sIconBorderSize * sHotbarHUDScale, sIconBorderSize * sHotbarHUDScale),
                    relativePosition = util.vector2(0.5, 0.5),
                    anchor = util.vector2(0.5, 0.5),
                }
            },
            {
                type = ui.TYPE.Image,
                name = 'icon',
                props = {
                    autoSize = true,
                    inheritAlpha = false,
                    resource = ZHIUtil.getCachedTexture({ --ui.texture({
                        path = 'Icons/gold.tga',
                        --size = util.vector2(16, 16)
                    }),
                    size = util.vector2(sIconSize * sHotbarHUDScale, sIconSize * sHotbarHUDScale),
                    relativePosition = util.vector2(0.5, 0.5),
                    anchor = util.vector2(0.5, 0.5),
                }
            },
        })
    }

    innerWidget.content:add({
        type = ui.TYPE.Widget,
        props = {
            size = util.vector2(1, 1) * (sHotkeySize * sHotbarHUDScale),
            relativePosition = util.vector2(0.5, 0.5),
            anchor = util.vector2(0.5, 0.5),
        },
        content = ui.content({
            {
                type = ui.TYPE.Text,
                name = 'txt_hotbar',
                props = {
                    inheritAlpha = false,
                    text = tostring(num),
                    textSize = math.floor(sKeyTextSize * sHotbarHUDScale),
                    textColor = sKeyTextColor, -- ZHI_HOTBARHUD_CONSTANTS.KeyTextColor,
                    textShadow = true,
                    textShadowColor = util.color.rgb(0.0, 0.0, 0.0),

                    anchor = util.vector2(1.0, 0.0),
                    relativePosition = util.vector2(sKeyTextAnchorX, sKeyTextAnchorY),
                }
            },            
            {
                type = ui.TYPE.Text,
                name = 'txt_count',
                props = {
                    inheritAlpha = false,
                    text = "9999",
                    textSize = math.floor(sItemCountTextSize * sHotbarHUDScale),
                    textColor = sItemCountColor,
                    textShadow = true,
                    textShadowColor = util.color.rgb(0.0, 0.0, 0.0),

                    anchor = util.vector2(1.0, 1.0),
                    relativePosition = util.vector2(sItemCountAnchorX, sItemCountAnchorY),
                    --textAlignH = ui.ALIGNMENT.Start,
                }
            },
        })
    })

    -- innerWidget.content:add({
    --     type = ui.TYPE.Text,
    --     name = 'txt_count',
    --     props = {
    --         inheritAlpha = false,
    --         text = "9999",
    --         textSize = math.floor(sItemCountTextSize * sHotbarHUDScale),
    --         textColor = sItemCountColor,
    --         textShadow = true,
    --         textShadowColor = util.color.rgb(0.0, 0.0, 0.0),

    --         anchor = util.vector2(1.0, 1.0),
    --         relativePosition = util.vector2(sItemCountAnchorX, sItemCountAnchorY),
    --         --textAlignH = ui.ALIGNMENT.Start,
    --     }
    -- })

    local inner = innerWidget

    
    if sHotkeyBorderEnabled then 
        inner = {
            template = I.MWUI.templates.boxSolid,
            type = ui.TYPE.Container,
            props = {
                inheritAlpha = false,
            },
            content = ui.content({
                innerWidget
            })
        }
    end

    -- local innerBorder = {
    --     template = I.MWUI.templates.boxSolid,
    --     type = ui.TYPE.Container,
    --     props = {
    --         inheritAlpha = false,
    --     },
    --     content = ui.content({
    --         innerWidget
    --     })
    -- }

    local group = {
        type = ui.TYPE.Flex,
        props = {
            arrange = ui.ALIGNMENT.Center
        },
        content = ui.content({
            inner,
            {
                type = ui.TYPE.Widget,
                props = { size = util.vector2(0, sDataBarPadding) }
            },
            bars,
        })
    }

    local content = {
        --template = I.MWUI.templates.boxSolid,
        type = ui.TYPE.Container,
        props = {
            inheritAlpha = false,
        },
        content = ui.content({
            group,
        })
    }

    return content
end

local function getIconPathFromSpell (spell)
    if spell == nil then return end

    if #spell.effects == 0 then return end

    return spell.effects[1].effect.icon
end

local function setupWidget(layout, icon, border, count, cond, charge, magic)
    if not layout then return end

    local iconLayout = ZMUtility.findLayoutByNameRecursive(layout.content, 'icon')
    local borderLayout = ZMUtility.findLayoutByNameRecursive(layout.content, 'border')
    local bgLayout = ZMUtility.findLayoutByNameRecursive(layout.content, 'bg_magic')

    local alpha = (count and count > 0) and 1.0 or 0.5

    if iconLayout then
        iconLayout.props.resource = icon
        iconLayout.props.alpha = alpha
    end

    if borderLayout then
        borderLayout.props.resource = border
        borderLayout.props.alpha = alpha
        borderLayout.props.visible = sIconBorderEnabled
    end

    if bgLayout then
        bgLayout.props.visible = sIconMagicEnabled and magic or false
    end

    local keyNumLayout = ZMUtility.findLayoutByNameRecursive(layout.content, 'txt_hotbar')
    if keyNumLayout then
       keyNumLayout.props.visible = sShowKey
    end

    local countLayout = ZMUtility.findLayoutByNameRecursive(layout.content, 'txt_count')
    
    if countLayout then
        if sShowCount and count ~= nil and count > 1 then
            countLayout.props.visible = true
            countLayout.props.text = tostring(count)
        else
            countLayout.props.visible = false
        end
    end

    local bars = ZMUtility.findLayoutByNameRecursive(layout.content, 'data_bars')

    if bars then
        bars.content = ui.content({})
        local barSize = getDataBarSize()

        if cond ~= nil then
            bars.content:add(createSmallProgressBar(barSize.x, barSize.y, sDataBarCondColor, cond))
        end

        if cond and charge and sDataBarPadding > 0 then
            bars.content:add({
                type = ui.TYPE.Widget,
                props = { size = util.vector2(0, sDataBarPadding) }
            })
        end

        if charge then
            bars.content:add(createSmallProgressBar(barSize.x, barSize.y, sDataBarChargeColor, charge))
        end
    end
end

local function setupWidgetFromHotkeyData(hotkeyLayout, hotkeyData)
    if not hotkeyLayout then return end
    if not hotkeyData or not hotkeyData.data then return end

    local item = hotkeyData.data.item
    local spell = hotkeyData.data.spell

    local icon, borderPath
    local borderOffset = util.vector2(2, 2)
    local count, cond, charge
    local magic = false

    if item then
        local itemRecord = types[item.typeStr].records[item.recordId]
        icon = ZHIUtil.getCachedTexture({ --ui.texture({
             path = itemRecord.icon 
        })

        local isBoundToEquip = item.enchantment ~= nil
        
        if isBoundToEquip then
            borderPath = 'textures/menu_icon_select_magic_magic.dds'
            if not sIconBorderEnabled then magic = true end
        else
            if itemRecord.enchant then
                borderPath = 'textures/menu_icon_magic_barter.dds'
                if not sIconBorderEnabled then magic = true end
            else
                borderPath = 'textures/menu_icon_barter.dds'
                borderOffset = util.vector2(4, 4)
            end
        end

        -- local itemObject = I.ZHI.getSpecificInventoryItem(hotkeyData.data.id)
        -- if not itemObject then
        --     itemObject = I.ZHI.getFirstInventoryItem(hotkeyData.data.item.recordId)
        -- end

        local itemObject = nil

        if hotkeyData.data.id then
            itemObject = I.ZHI.getSpecificInventoryItem(item.recordId, hotkeyData.data.id)
        end

        -- try to find first best other item of the same type.
        if not itemObject then
            itemObject = I.ZHI.getFirstInventoryItem(item.recordId)
        end

        if itemObject then
            count = 1
            if sShowCount then
                count = itemObject.count
            end

            local itemData = types.Item.itemData(itemObject)

            if sShowCondition and itemRecord.health then
                cond = 1.0
                if itemData then
                    if itemData.condition == nil then
                        cond = nil
                    else
                        cond = itemData.condition / itemRecord.health
                    end
                end
            end

            if sShowCharge and itemRecord.enchant then
                local enchant = core.magic.enchantments.records[itemRecord.enchant]
                assert(enchant)
                if ZMUtility.equalAnyOf(enchant.type, core.magic.ENCHANTMENT_TYPE.CastOnStrike, core.magic.ENCHANTMENT_TYPE.CastOnUse) then
                    charge = 1.0
                    if itemData then
                        charge = itemData.enchantmentCharge / enchant.charge
                    end
                end
            end
        else
            if sShowCount then
                count = 0
            end
        end
    elseif spell then
        local spellObject = core.magic.spells.records[spell.spellId]
        local smallIconPath = getIconPathFromSpell(spellObject)
        local bigIconPath = ZMUtility.Magic.getSpellEffectBigIconPath(smallIconPath)

        count = 0

        local spells = types.Actor.spells(self)
        for i=1,#spells do 
            if spells[i].id == spell.spellId then
                count = 1
                break
            end
        end        

        -- Try to convert the spell effect icon to the larger icons
        if bigIconPath then
            icon = ZHIUtil.getCachedTexture({ --ui.texture({
                path = bigIconPath
            })
        end

        -- Fallback to original 
        if not icon then
            icon = ZHIUtil.getCachedTexture({ -- ui.texture({
                 path = smallIconPath 
            })
        end

        if sShowSpellCastChance then
            local castChance = ZMUtility.Magic.getSpellCastChance(self, spellObject)
            if castChance then
                cond = ZMUtility.Magic.getSpellCastChance(self, spellObject) / 100.0
            end
        end

        borderPath = 'textures/menu_icon_select_magic.dds'
    end

    local borderIcon
    if borderPath then 
        borderIcon = ZHIUtil.getCachedTexture({ --ui.texture({ 
            path = borderPath,
            size = util.vector2(40, 40),
            offset = borderOffset,
        })
    end

    setupWidget(hotkeyLayout, icon, borderIcon, count, cond, charge, magic)
end

local function createHotkeysRow(hotbar, numKeys)
    local scale = sHotbarHUDScale --I.ZHI.getHotbarHUDScale()

    local size = ZHI_HOTBARHUD_CONSTANTS.HotkeySize * scale
    local bsize = ZHI_HOTBARHUD_CONSTANTS.HotkeyBorderSize * scale
    local isize = ZHI_HOTBARHUD_CONSTANTS.HotkeyIconSize * scale

    local elements = {}
    for i=1,numKeys do
        -- local layout = ZHIUI.createHotkeyAssignmentBox(tostring(i % 10),
        --     size, size,
        --     nil, nil,
        --     bsize, bsize,
        --     isize, isize)
        --ZHIUI.setHotkeyFromData(layout, data)
        
        
        local data = ZHIHotbarData.getHotkeyData(hotbar, i)

        if data and (data.data.id or (not sRemoveEmptyHotkeys)) then
            local layout = createHotkeyWidget(i % 10)
            setupWidgetFromHotkeyData(layout, data)
            layout.props.inheritAlpha = false
            layout.name = string.format('hotkey_%d', i)
            
            
            table.insert(elements, layout)

            if (sHotkeyPadding > 0) and (i < numKeys) then
                table.insert(elements, {
                    type = ui.TYPE.Widget,
                    props = { size = util.vector2(sHotkeyPadding, 0)}
                })
            end
        end
    end

    local content = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            autoSize = true,
        },
        content = ui.content(elements)
    }

    return content
end

local function createHUDLayout()
    local root = {
        --template = I.MWUI.templates.boxSolid,
        type = ui.TYPE.Container,
        layer = 'HUD',
        props = {
            anchor = util.vector2(sAnchorX, sAnchorY),
            relativePosition = util.vector2(sPositionX, sPositionY),
            --alpha = 0.25,
        },
        content = ui.content({createHotkeysRow(I.ZHI.getActiveHotbar(), 9)})
    }

    return root
end

local function createHUD()
    local layout = createHUDLayout()
    return ui.create(layout)
end

-- local function updateHUDFromHotbar(num)
--     ZHIHotbarData.foreachHotkey(num, function(bar, key, data) 
--         if not hudWindow then return end
        
--         local layout = ZHIUtil.findLayoutByNameRecursive(hudWindow.layout.content, ZHIUtil.getHotkeyIdentifier(bar, key))
--         print('update key', layout, data)
--         ZHIUI.setHotkeyFromData(layout, data)
--     end)
-- end

local lastHotbar = 1
local interval = 0.0

local function updateHUD()
    if hudWindow then
        hudWindow:destroy()
    end
    
    hudWindow = createHUD()
    hudWindow:update()
end

local function setVisible(value)
    if isHudVisible == value then
        return
    end

    isHudVisible = value

    if value and not hudWindow then
        hudWindow = createHUD()
    end

    if not hudWindow then
        return
    end

    hudWindow.layout.props.visible = isHudVisible
    hudWindow:update()
end

local function onSettingsChanged(section, key)
    local data = storage.playerSection(section)
    if not data then
        print("ZHI hotbarhud onSettingsChanged unknown section", section)
        return
    end

    if section == "SettingsZHIHotbarAAMain" then
        -- if key == nil or key == 'enable_hotbar_hud' then
        --     setVisible(data:get('enable_hotbar_hud'))
        -- end
        if key == nil or key == 'hotbar_hud_scale' then
            sHotbarHUDScale = data:get('hotbar_hud_scale')
        end
        if key == nil or key == 'anchor_x' then
            sAnchorX = data:get('anchor_x')
        end
        if key == nil or key == 'anchor_y' then
            sAnchorY = data:get('anchor_y')
        end
        if key == nil or key == 'position_x' then
            sPositionX = data:get('position_x')
        end
        if key == nil or key == 'position_y' then
            sPositionY = data:get('position_y')
        end        
        if key == nil or key == 'update_interval' then
            sUpdateInterval = data:get('update_interval')
        end
        if key == nil or key == 'remove_empty_hotkeys' then
            sRemoveEmptyHotkeys = data:get('remove_empty_hotkeys')
        end
    end
    if section == "SettingsZHIHotbarAZFeatures" then
        if key == nil or key == 'display_condition' then
            sShowCondition = data:get('display_condition')
        end
        if key == nil or key == 'display_charge' then
            sShowCharge = data:get('display_charge')
        end
        if key == nil or key == 'display_count' then
            sShowCount = data:get('display_count')
        end
        if key == nil or key == 'display_spell_castchance' then
            sShowSpellCastChance = data:get('display_spell_castchance')
        end
        if key == nil or key == 'display_key' then
            sShowKey = data:get('display_key')
        end
    end
    if section == 'SettingsZHIHotbarBAAppearance' then
        if key == nil or key == 'icon_size' then
            sIconSize = data:get('icon_size')
        end
        if key == nil or key == 'icon_border_enable' then
            sIconBorderEnabled = data:get('icon_border_enable')
        end
        if key == nil or key == 'icon_magic_enable' then
            sIconMagicEnabled = data:get('icon_magic_enable')
        end        
        if key == nil or key == 'icon_border_size' then
            sIconBorderSize = data:get('icon_border_size')
        end

        if key == nil or key == 'hotkey_size' then
            sHotkeySize = data:get('hotkey_size')
        end
        if key == nil or key == 'hotkey_padding' then
            sHotkeyPadding = data:get('hotkey_padding')
        end
        if key == nil or key == 'hotkey_border' then
            sHotkeyBorderEnabled = data:get('hotkey_border')
        end

        if key == nil or key == 'itemcount_text_size' then
           sItemCountTextSize = data:get('itemcount_text_size')
        end
        if key == nil or key == 'itemcount_text_color' then
            sItemCountColor = data:get('itemcount_text_color')
        end
        if key == nil or key == 'itemcount_anchorx' then
            sItemCountAnchorX = data:get('itemcount_anchorx')
        end
        if key == nil or key == 'itemcount_anchory' then
            sItemCountAnchorY = data:get('itemcount_anchory')
        end

        if key == nil or key == 'keynum_text_size' then
           sKeyTextSize = data:get('keynum_text_size')
        end
        if key == nil or key == 'keynum_text_color' then
            sKeyTextColor = data:get('keynum_text_color')
        end
        if key == nil or key == 'keynum_anchorx' then
            sKeyTextAnchorX = data:get('keynum_anchorx')
        end
        if key == nil or key == 'keynum_anchory' then
            sKeyTextAnchorY = data:get('keynum_anchory')
        end
        
        if key == nil or key == 'infobar_padding' then
            sDataBarPadding = data:get('infobar_padding')
        end
        if key == nil or key == 'infobar_cond_color' then
            sDataBarCondColor = data:get('infobar_cond_color')
        end
        if key == nil or key == 'infobar_charge_color' then
            sDataBarChargeColor = data:get('infobar_charge_color')
        end
    end

    if isHudVisible then updateHUD() end
end

return {

    -- setScale = function(value)
    --     sHotbarHUDScale = value
    -- end,

    -- setShowCondition = function(value)
    --     sShowCondition = value
    -- end,

    -- setShowCharge = function(value)
    --     sShowCharge = value
    -- end,

    -- setShowCount = function(value)
    --     sShowCount = value
    -- end,

    -- setShowKey = function(value)
    --     sShowKey = value
    -- end,

    -- setShowSpellCastChance = function(value)
    --     sShowSpellCastChance = value
    -- end,

    -- setAnchorX = function(value)
    --     sAnchorX = value
    -- end,

    -- setAnchorY = function(value)
    --     sAnchorY = value
    -- end,

    isVisible = function()
        return isHudVisible
    end,

    setVisible = setVisible,
    updateHUD = updateHUD,

    onUpdate = function(dt)
        if isHudVisible and hudWindow then
            interval = interval + dt
            local hb = I.ZHI.getActiveHotbar()
            if hb ~= lastHotbar or (interval >= sUpdateInterval) then
                interval = 0
                lastHotbar = hb
                updateHUD()
            end
        end
    end,

    initialize = function ()
        local main = storage.playerSection('SettingsZHIHotbarAAMain')
        local features = storage.playerSection('SettingsZHIHotbarAZFeatures')
        local appearance = storage.playerSection('SettingsZHIHotbarBAAppearance')

        main:subscribe(async:callback(onSettingsChanged))
        features:subscribe(async:callback(onSettingsChanged))
        appearance:subscribe(async:callback(onSettingsChanged))

        onSettingsChanged('SettingsZHIHotbarAAMain', nil)
        onSettingsChanged('SettingsZHIHotbarAZFeatures', nil)
        onSettingsChanged('SettingsZHIHotbarBAAppearance', nil)
    end,
}