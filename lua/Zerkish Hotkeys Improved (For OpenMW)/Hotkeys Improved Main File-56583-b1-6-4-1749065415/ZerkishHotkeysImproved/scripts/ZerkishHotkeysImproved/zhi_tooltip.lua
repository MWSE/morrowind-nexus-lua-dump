-- Zerkish Improved Hotkeys - zhi_tooltip.lua
-- tooltip utility file

local core  = require('openmw.core')
local I     = require('openmw.interfaces')
local ui    = require('openmw.ui')
local util  = require('openmw.util')
local Actor = require('openmw.types').Actor
local types = require('openmw.types')
local self  = require('openmw.self')
local async = require('openmw.async')
local input = require('openmw.input')

local constants = require('scripts.omw.mwui.constants')

-- ZHI modules
local ZHIUtil   = require('scripts.ZerkishHotkeysImproved.zhi_util')
--local ZHIUI     = require('scripts.ZerkishHotkeysImproved.zhi_ui')

local ZMUtility = require('scripts.ZModUtils.Utility')

local tooltipWindow = nil

local ZHIL10n = core.l10n('ZerkishHotkeysImproved')

local TT_CONSTANTS = {
    HeaderTextSize = 20,
    SubTextSize = 16,
    ExtendedTextSize = 14,
    TextSize = 16,
    HPadding = 4,
    VPadding = 4,

    SubTextColor = util.color.rgb(0.75, 0.75, 0.75),
    ExtendedColor = util.color.rgb(0.5, 0.5, 0.5),

    ECWidth = 200,
    ECHeight = 14,
}

local function getEffectLine(effectParams, nameOnly, textColor, isConstant)
    local root = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            autoSize = true,
            arrange = ui.ALIGNMENT.Center,
            alignt = ui.ALIGNMENT.Center,
        },
        content = ui.content({})
    }
    local effect = core.magic.effects.records[effectParams.id]

    root.content:add({
        type = ui.TYPE.Image,
        props = {
            resource = ZHIUtil.getCachedTexture({ --ui.texture({
                path = effect.icon 
            }),
            size = util.vector2(16, 16),
            color = textColor
        }
    })

    -- Padding
    root.content:add({
        type = ui.TYPE.Widget,
        props = {
            size = util.vector2(4, 0)
        }
    })

    local text = effect.name

    local isSkill = ZMUtility.equalAnyOf(effect.id, core.magic.EFFECT_TYPE.AbsorbSkill,
        core.magic.EFFECT_TYPE.DamageSkill, core.magic.EFFECT_TYPE.DrainSkill,
        core.magic.EFFECT_TYPE.FortifySkill, core.magic.EFFECT_TYPE.RestoreSkill)

    local isAttribute = ZMUtility.equalAnyOf(effect.id, core.magic.EFFECT_TYPE.AbsorbAttribute,
        core.magic.EFFECT_TYPE.DamageAttribute, core.magic.EFFECT_TYPE.DrainAttribute,
        core.magic.EFFECT_TYPE.FortifyAttribute, core.magic.EFFECT_TYPE.RestoreAttribute)

    if isSkill then
        local b, e = string.find(text, 'Skill')
        if b and e then
            text = string.sub(text, 1, b - 1) .. ZMUtility.capitalize(tostring(effectParams.affectedSkill))
        end
    elseif isAttribute then
        local b, e = string.find(text, 'Attribute')
        if b and e then
            text = string.sub(text, 1, b - 1) .. ZMUtility.capitalize(tostring(effectParams.affectedAttribute))
        end
    end


    if not nameOnly then
        if effect.hasMagnitude then
            if effectParams.magnitudeMin == effectParams.magnitudeMax then
                --text = string.format("%s %d pts", text, effectParams.magnitudeMin)
                text = string.format("%s %s", text, ZHIL10n('in_game_tooltip_effect_magnitude', {num=effectParams.magnitudeMin}))
            else
                --text = string.format("%s %d to %d pts", text, effectParams.magnitudeMin, effectParams.magnitudeMax)
                text = string.format("%s %s", text, ZHIL10n('in_game_tooltip_effect_magnitude_minmax', {min=effectParams.magnitudeMin, max=effectParams.magnitudeMax}))
            end
        end

        if effect.hasDuration and not isConstant then
            --text = string.format("%s for %d secs", text, effectParams.duration)
            text = string.format('%s %s', text, ZHIL10n('in_game_tooltip_effect_duration', {seconds=effectParams.duration}))
        end

        if effectParams.area > 0 then
            --text = string.format("%s in %d ft", text, effectParams.area)
            text = string.format('%s %s', text, ZHIL10n('in_game_tooltip_effect_area', {area=effectParams.area}))
        end

        local range = ZHIL10n('in_game_tooltip_effect_range_self')
        if effectParams.range == core.magic.RANGE.Target then
            range = ZHIL10n('in_game_tooltip_effect_range_target')
        elseif effectParams.range == core.magic.RANGE.Touch then
            range = ZHIL10n('in_game_tooltip_effect_range_touch')
        end

        text = string.format('%s %s', text, range)
        --text = string.format("%s on %s", text, range)
    end

    root.content:add({
        type = ui.TYPE.Text,
        props = {
            textSize = TT_CONSTANTS.TextSize,
            textColor = textColor and textColor or constants.normalColor,
            text = text,
            textAlignH = ui.ALIGNMENT.End,
        }
    })

    return root
end

local function getItemLine(text, color, size)
    return {
        type = ui.TYPE.Text,
        props = {
            text = text,
            textSize = size == nil and TT_CONSTANTS.TextSize or size,
            textColor = color ~= nil and color or constants.normalColor
        }
    }
end

local function addItemLine(lines, text, color, size)
    table.insert(lines, getItemLine(text, color, size))
end

local function getSpellTooltipData(spell, showExtendedTooltips)
    local rows = {}

    local header = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = true,
            align = ui.ALIGNMENT.Center,
        },
        content = ui.content({})
    }

    header.content:add({
        type = ui.TYPE.Text,
        props = {
            textSize = TT_CONSTANTS.HeaderTextSize,
            textColor = constants.headerColor,
            text = spell.name
        },
    })

    local school = ZMUtility.Magic.getSpellSchool(spell)
    if school then
        header.content:add({
            type = ui.TYPE.Text,
            props = {
                textSize = TT_CONSTANTS.SubTextSize,
                textColor = TT_CONSTANTS.SubTextColor,
                text = tostring(school)
            },
        })
    end

    if showExtendedTooltips == true then
        header.content:add({
            type = ui.TYPE.Text,
            props = {
                textSize = TT_CONSTANTS.ExtendedTextSize,
                textColor = TT_CONSTANTS.ExtendedColor,
                text = "id: " .. tostring(spell.id)
            },
        })   
    end

    local content = {
        type = ui.TYPE.Flex,
        props = {

        },
        content = ui.content({
            header,
            {
                type = ui.TYPE.Widget,
                props = {
                    size = util.vector2(0, 6)
                }
            }
        })
    }


    
    -- if showExtendedTooltips then
    --     addItemLine(rows, string.format("Cost: %d", tonumber(ZHIUtil.getSpellCost(spell))), TT_CONSTANTS.ExtendedColor, TT_CONSTANTS.ExtendedTextSize)
    --     addItemLine(rows, string.format("Cast Chance: %d%%", tonumber(ZHIUtil.getSpellCastChance(spell))), TT_CONSTANTS.ExtendedColor, TT_CONSTANTS.ExtendedTextSize)

    --     table.insert(rows, {
    --         type = ui.TYPE.Widget,
    --         props = { size = util.vector2(0, 2) }
    --     })        
    -- end

    --addItemLine(rows, string.format("Cost: %d", tonumber(ZMUtility.Magic.getSpellCost(spell))))
    addItemLine(rows, ZHIL10n('in_game_tooltip_spell_cost', {magicka=tonumber(ZMUtility.Magic.getSpellCost(spell))}))
    --addItemLine(rows, string.format("Cast Chance: %d%%", tonumber(ZMUtility.Magic.getSpellCastChance(self, spell))))
    addItemLine(rows, ZHIL10n('in_game_tooltip_spell_chance', {chance=tonumber(ZMUtility.Magic.getSpellCastChance(self, spell))}))

    table.insert(rows, {
        type = ui.TYPE.Widget,
        props = { size = util.vector2(0, 6) }
    })        

    for i=1, #spell.effects do
        local effect = spell.effects[i]
        local line = getEffectLine(effect)
        table.insert(rows, line)
        table.insert(rows, {
            type = ui.TYPE.Widget,
            props = { size = util.vector2(0, 2) }
        })        
        --table.insert(rows, line)
    end

    for i=1,#rows do
        content.content:add(rows[i])
    end

    return content
end



local function getItemRecordContent(itemType, record, itemObject, showExtendedTooltips)
    local content = {}

    if itemType == types.Apparatus then
        if record.quality then
            --addItemLine(content, string.format('Quality: %s', ZMUtility.formatNumber(record.quality)))
            addItemLine(content, ZHIL10n('in_game_tooltip_quality', {string=ZMUtility.formatNumber(record.quality)}))
        end
    elseif itemType == types.Armor then
        --addItemLine(content, string.format("Armor Rating: %d", ZMUtility.Items.getArmorRatingForActor(self, record)))
        addItemLine(content, ZHIL10n('in_game_tooltip_armor_rating', {num=ZMUtility.Items.getArmorRatingForActor(self, record)}))
        if showExtendedTooltips then
            if record.baseArmor then
                --addItemLine(content, string.format("base rating: %s", ZMUtility.formatNumber(record.baseArmor)), TT_CONSTANTS.ExtendedColor, TT_CONSTANTS.ExtendedTextSize)
                addItemLine(content, ZHIL10n('in_game_tooltip_base_rating_ext', {num=ZMUtility.formatNumber(record.baseArmor)}), TT_CONSTANTS.ExtendedColor, TT_CONSTANTS.ExtendedTextSize)
            end
            if record.enchantCapacity then
                --addItemLine(content, string.format("enchant capacity: %d", record.enchantCapacity), TT_CONSTANTS.ExtendedColor, TT_CONSTANTS.ExtendedTextSize)
                addItemLine(content, ZHIL10n('in_game_tooltip_enchant_capacity_ext', {num=record.enchantCapacity}), TT_CONSTANTS.ExtendedColor, TT_CONSTANTS.ExtendedTextSize)
            end
        end
    elseif itemType == types.Book then
        -- Books have no specific data normally
        if showExtendedTooltips and record.skill then
            --addItemLine(content, string.format("skill: %s", record.skill), TT_CONSTANTS.ExtendedColor, TT_CONSTANTS.ExtendedTextSize)
            addItemLine(content, ZHIL10n('in_game_tooltip_skill_ext', {skill=record.skill}), TT_CONSTANTS.ExtendedColor, TT_CONSTANTS.ExtendedTextSize)
        end
    elseif itemType == types.Clothing then
        -- Clothing has no data by default
        if showExtendedTooltips and record.enchantCapacity then
            --addItemLine(content, string.format("enchant capacity: %d", record.enchantCapacity), TT_CONSTANTS.ExtendedColor, TT_CONSTANTS.ExtendedTextSize)
            addItemLine(content, ZHIL10n('in_game_tooltip_enchant_capacity_ext', {num=record.enchantCapacity}), TT_CONSTANTS.ExtendedColor, TT_CONSTANTS.ExtendedTextSize)
        end
    elseif itemType == types.Ingredient then
        -- ingredients have no data by default
    elseif itemType == types.Light then
        -- lights have no data by default
        if showExtendedTooltips then
            --addItemLine(content, string.format("carriable: %s", record.isCarriable and "true" or "false"), TT_CONSTANTS.ExtendedColor, TT_CONSTANTS.ExtendedTextSize)
            --addItemLine(content, string.format("is fire: %s", record.isFire and "true" or "false"), TT_CONSTANTS.ExtendedColor, TT_CONSTANTS.ExtendedTextSize)
            addItemLine(content, ZHIL10n('in_game_tooltip_carriable_ext', {truefalse=record.isCarriable and "true" or "false"}), TT_CONSTANTS.ExtendedColor, TT_CONSTANTS.ExtendedTextSize)
            addItemLine(content, ZHIL10n('in_game_tooltip_isfire_ext', {truefalse=record.isFire and "true" or "false"}), TT_CONSTANTS.ExtendedColor, TT_CONSTANTS.ExtendedTextSize)
            if record.radius then
                --addItemLine(content, string.format("radius: %d", record.radius), TT_CONSTANTS.ExtendedColor, TT_CONSTANTS.ExtendedTextSize)
                addItemLine(content, ZHIL10n('in_game_tooltip_radius_ext', {num=record.radius}), TT_CONSTANTS.ExtendedColor, TT_CONSTANTS.ExtendedTextSize)
            end
        end
    elseif itemType == types.Lockpick then
        local uses = record.maxCondition
        if itemObject then
            local itemData = types.Item.itemData(itemObject)
            uses = math.floor(itemData.condition)
        end
        if uses then
            --addItemLine(content, string.format("Uses: %d", uses))
            addItemLine(content, ZHIL10n('in_game_tooltip_uses', {num=uses}))
        end
        if record.quality then
            --addItemLine(content, string.format("Quality: %s", ZMUtility.formatNumber(record.quality)))
            addItemLine(content, ZHIL10n('in_game_tooltip_quality', {string=ZMUtility.formatNumber(record.quality)}))
        end
        if showExtendedTooltips and record.maxCondition then
            --addItemLine(content, string.format("max uses: %d", record.maxCondition), TT_CONSTANTS.ExtendedColor, TT_CONSTANTS.ExtendedTextSize)
            addItemLine(content, ZHIL10n('in_game_tooltip_max_uses_ext', {num=record.maxCondition}), TT_CONSTANTS.ExtendedColor, TT_CONSTANTS.ExtendedTextSize)
        end
    elseif itemType == types.Potion then
        -- Potion effects are added later with enchants
    elseif itemType == types.Probe then
        local uses = record.maxCondition
        if itemObject then
            local itemData = types.Item.itemData(itemObject)
            uses = math.floor(itemData.condition)
        end
        if uses then 
            --addItemLine(content, string.format("Uses: %d", uses))
            addItemLine(content, ZHIL10n('in_game_tooltip_uses', {num=uses}))
        end
        if record.quality then
            --addItemLine(content, string.format("Quality: %s", ZMUtility.formatNumber(record.quality)))
            addItemLine(content, ZHIL10n('in_game_tooltip_quality', {string=ZMUtility.formatNumber(record.quality)}))
        end
        if showExtendedTooltips and record.maxCondition then
            --addItemLine(content, string.format("max uses: %d", record.maxCondition), TT_CONSTANTS.ExtendedColor, TT_CONSTANTS.ExtendedTextSize)
            addItemLine(content, ZHIL10n('in_game_tooltip_max_uses_ext', {num=record.maxCondition}), TT_CONSTANTS.ExtendedColor, TT_CONSTANTS.ExtendedTextSize)
        end
    elseif itemType == types.Repair then
        local uses = record.maxCondition
        if itemObject then
            local itemData = types.Item.itemData(itemObject)
            uses = math.floor(itemData.condition)
        end
        if uses then
            --addItemLine(content, string.format("Uses: %d", uses))
            addItemLine(content, ZHIL10n('in_game_tooltip_uses', {num=uses}))
        end
        if record.quality then
            --addItemLine(content, string.format("Quality: %s", ZMUtility.formatNumber(record.quality)))
            addItemLine(content, ZHIL10n('in_game_tooltip_quality', {string=ZMUtility.formatNumber(record.quality)}))
        end
        if showExtendedTooltips and record.maxCondition then
            --addItemLine(content, string.format("max uses: %d", record.maxCondition), TT_CONSTANTS.ExtendedColor, TT_CONSTANTS.ExtendedTextSize)
            addItemLine(content, ZHIL10n('in_game_tooltip_max_uses_ext', {num=record.maxCondition}), TT_CONSTANTS.ExtendedColor, TT_CONSTANTS.ExtendedTextSize)
        end
    elseif itemType == types.Weapon then
        if record.chopMinDamage and record.chopMaxDamage then
            --addItemLine(content, string.format("Chop: %d - %d", record.chopMinDamage, record.chopMaxDamage))
            addItemLine(content, ZHIL10n('in_game_tooltip_weapon_chop', {min=record.chopMinDamage, max=record.chopMaxDamage}))
        end
        if record.slashMinDamage and record.slashMaxDamage then
            --addItemLine(content, string.format("Slash: %d - %d", record.slashMinDamage, record.slashMaxDamage))
            addItemLine(content, ZHIL10n('in_game_tooltip_weapon_slash', {min=record.slashMinDamage, max=record.slashMaxDamage}))
        end
        if record.thrustMinDamage then
            --addItemLine(content, string.format("Thrust: %d - %d", record.thrustMinDamage, record.thrustMaxDamage))
            addItemLine(content, ZHIL10n('in_game_tooltip_weapon_thrust', {min=record.thrustMinDamage, max=record.thrustMaxDamage}))
        end
        if showExtendedTooltips then
            if record.enchantCapacity then
                --addItemLine(content, string.format("enchant capacity: %d", record.enchantCapacity), TT_CONSTANTS.ExtendedColor, TT_CONSTANTS.ExtendedTextSize)
                addItemLine(content, ZHIL10n('in_game_tooltip_enchant_capacity_ext', {num=record.enchantCapacity}), TT_CONSTANTS.ExtendedColor, TT_CONSTANTS.ExtendedTextSize)
            end
            if record.speed and record.reach then
                --addItemLine(content, string.format("speed: %.2f, reach: %.2f", record.speed, record.reach), TT_CONSTANTS.ExtendedColor, TT_CONSTANTS.ExtendedTextSize)
                addItemLine(content, ZHIL10n('in_game_tooltip_weapon_ext', {speed=record.speed, reach=record.reach}), TT_CONSTANTS.ExtendedColor, TT_CONSTANTS.ExtendedTextSize)
            end
        end
    end

    if ZMUtility.equalAnyOf(itemType, types.Armor, types.Weapon) then
        local cond = record.health
        if itemObject then
            local itemData = types.Item.itemData(itemObject)
            if itemData then cond = types.Item.itemData(itemObject).condition end
        end
        if cond and record.health then
            --addItemLine(content, string.format("Condition: %d/%d", cond, record.health))
            addItemLine(content, ZHIL10n('in_game_tooltip_item_condition', {current=cond, max=record.health}))
        end
    end

    if record.weight and record.weight > 0 then

        local weight = nil
        if itemType == types.Armor then
            weight = ZHIL10n('in_game_tooltip_weight_armor', {weight=ZMUtility.formatNumber(record.weight), armorclass=ZMUtility.Items.getArmorClass(record)})
        else
            weight = ZHIL10n('in_game_tooltip_weight', {weight=ZMUtility.formatNumber(record.weight)})
        end

        -- -- if we need to show decimals
        -- local weight = string.format("Weight: %s", ZMUtility.formatNumber(record.weight))

        -- if itemType == types.Armor then
        --     weight = string.format("%s (%s)", weight, ZMUtility.Items.getArmorClass(record))
        -- end
        addItemLine(content, weight)
    end

    if record.value > 0 then
        --addItemLine(content, string.format("Value: %d", record.value))
        addItemLine(content, ZHIL10n('in_game_tooltip_value', {value=record.value}))
    end

    return content
end

local function getEnchantmentChargeWidget(enchantment, itemObject)

    local percentCharge = 1.0
    local itemData = itemObject and types.Item.itemData(itemObject) or nil

    if itemData then
        percentCharge = math.min(1.0, math.max(0.0, itemData.enchantmentCharge / enchantment.charge))
    end

    local inner = {
        type = ui.TYPE.Widget,
        props = {
            size = util.vector2(TT_CONSTANTS.ECWidth, TT_CONSTANTS.ECHeight)
        },
        content = ui.content({
            {
                type = ui.TYPE.Image,
                props = {
                    tileH = true,
                    tileV = true,
                    size = util.vector2(percentCharge * TT_CONSTANTS.ECWidth, 16),
                    --alpha = 0.5,
                    color = util.color.rgb(0.90, 0.20, 0.15),
                    resource = ZHIUtil.getCachedTexture({ --ui.texture({
                        path = "textures/menu_bar_gray.dds",
                        size = util.vector2(1, 16),
                        offset = util.vector2(0, 0),
                    })  
                }
            },
            {
                type = ui.TYPE.Text,
                props = {
                    autoSize = false,
                    text = string.format("%d/%d", percentCharge * enchantment.charge, enchantment.charge),
                    size = util.vector2(TT_CONSTANTS.ECWidth, TT_CONSTANTS.ECHeight),
                    textSize = 16,
                    textColor = constants.normalColor,
                    textShadowColor = util.color.rgb(0,0, 0),
                    anchor = util.vector2(0.0, 0.1), -- Text alignment is really weird for some reason.
                    --relativePosition = util.vector2(0.5, 0.5),
                    --position = util.vector2(TT_CONSTANTS.ECWidth / 2.0, TT_CONSTANTS.ECHeight / 2.0 - 2),
                    textAlignV = ui.ALIGNMENT.Center,
                    textAlignH = ui.ALIGNMENT.Center,
                }
            }
            
        })
    }

    local outer = {
        template = I.MWUI.templates.boxSolid,
        type = ui.TYPE.Container,
        props = {

        },
        content = ui.content({inner})
    }

    local content = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
        },
        content = ui.content({
            {
                type = ui.TYPE.Text,
                props = {
                    text = ZHIL10n('in_game_tooltip_charge'),
                    textSize = TT_CONSTANTS.TextSize,
                    textColor = constants.normalColor,
                }
            },
            {
                type = ui.TYPE.Widget,
                props = { size = util.vector2(4, 0) }
            },
            outer
        })
    }

    return content
end

local function getEnchantmentContent(itemType, record, itemObject, showExtendedTooltips)
    local content = {}

    --print('getEnchantmentContent', record.enchant)
    if record.enchant then
        local enchantment = core.magic.enchantments.records[record.enchant]
        --print('adding enchantment type line')
        table.insert(content, {
            type = ui.TYPE.Widget,
            props = { size = util.vector2(0, 4) }
        })
        addItemLine(content, ZHIUtil.getEnchantTypeText(enchantment), TT_CONSTANTS.SubTextColor, TT_CONSTANTS.SubTextSize)
        -- padding
        table.insert(content, {
            type = ui.TYPE.Widget,
            props = { size = util.vector2(0, 4) }
        })
        for i=1,#enchantment.effects do
            table.insert(content, getEffectLine(enchantment.effects[i], false, nil, enchantment.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect))
            table.insert(content, {
                type = ui.TYPE.Widget,
                props = { size = util.vector2(0, 4) }
            })
        end

        if ZMUtility.equalAnyOf(enchantment.type, core.magic.ENCHANTMENT_TYPE.CastOnStrike, core.magic.ENCHANTMENT_TYPE.CastOnUse) then
            table.insert(content, getEnchantmentChargeWidget(enchantment, itemObject)) 
        end
    elseif itemType == types.Potion then
        table.insert(content, {
            type = ui.TYPE.Widget,
            props = { size = util.vector2(0, 4) }
        })
        for i=1,#record.effects do
            table.insert(content, getEffectLine(record.effects[i]))
            table.insert(content, {
                type = ui.TYPE.Widget,
                props = { size = util.vector2(0, 4) }
            })
        end
    end

    return content
end

local function getItemTooltipData(record, itemType, itemObject, showExtendedTooltips)
    local header = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = true,
            align = ui.ALIGNMENT.Center,
        },
        content = ui.content({})
    }

    local itemTitle = record.name
    
    if itemObject and itemObject.count > 1 then
        itemTitle = string.format("%s (%d)", itemTitle, itemObject.count)
    end

    header.content:add({
        type = ui.TYPE.Text,
        props = {
            textSize = TT_CONSTANTS.HeaderTextSize,
            textColor = constants.headerColor,
            text = itemTitle
        },
    })

    local subtext = ZHIUtil.getItemSubText(record, itemType)

    if subtext then
        header.content:add({
            type = ui.TYPE.Text,
            props = {
                textSize = TT_CONSTANTS.SubTextSize,
                textColor = TT_CONSTANTS.SubTextColor,
                text = subtext
            },
        })
    end

    if showExtendedTooltips == true then
        header.content:add({
            type = ui.TYPE.Text,
            props = {
                textSize = TT_CONSTANTS.ExtendedTextSize,
                textColor = TT_CONSTANTS.ExtendedColor,
                text = "id: " .. tostring(record.id)
            },
        })
    end

    local recordLines = getItemRecordContent(itemType, record, itemObject, showExtendedTooltips)

    local recordContent = {
        type = ui.TYPE.Flex,
        props = {},
        content = ui.content(recordLines)
    }

    -- enchantment
    local enchantmentContent = getEnchantmentContent(itemType, record, itemObject, showExtendedTooltips)

    local content = {
        type = ui.TYPE.Flex,
        props = {

        },
        content = ui.content({
            header,
            {
                type = ui.TYPE.Widget,
                props = {
                    size = util.vector2(0, 6)
                }
            },
            recordContent,
            {
                type = ui.TYPE.Flex,
                props = {},
                content = ui.content(enchantmentContent)
            }
        })
    }

    if itemType == types.Ingredient then
        local alchemySkill = ZMUtility.Stats.getActorSkill(self, 'alchemy')
        local numShown = 0
        if alchemySkill >= 60 then
            numShown = 4
        elseif alchemySkill >= 45 then
            numShown = 3
        elseif alchemySkill >= 30 then
            numShown = 2
        elseif alchemySkill >= 15 then
            numShown = 1
        end

        content.content:add({
            type = ui.TYPE.Widget,
            props = { size = util.vector2(0, 4) }
        })
        for i=1,#record.effects do
            if i <= numShown or showExtendedTooltips then
                local color = nil
                if i > numShown then
                    color = TT_CONSTANTS.ExtendedColor
                end
                content.content:add(getEffectLine(record.effects[i], true, color))
            else
                content.content:add(getItemLine("?????"))
            end
            content.content:add({
                type = ui.TYPE.Widget,
                props = { size = util.vector2(0, 4) }
            })
        end
    end

    -- for i=1,#rows do
    --     content.content:add(rows[i])
    -- end

    return content
end

local function setTooltipData(layout, data)
    local content = ZMUtility.findLayoutByNameRecursive(layout.content, 'tooltip_content')
    --print('setTooltipData', content, data.item, data.spell)
    if not content then return end

    local showExtendedTooltips = I.ZHI.isExtendedTooltipsEnabled()
    
    if data.spell then
        local spellContent = getSpellTooltipData(data.spell, showExtendedTooltips)
        content.content = ui.content({spellContent})
    elseif data.item then
        local itemType = data.item.itemType
        local record = itemType.records[data.item.recordId]

        local itemObject = nil
        if data.item.itemId then
            itemObject = I.ZHI.getSpecificInventoryItem(data.item.recordId, data.item.itemId) 
        end

        -- try to find first best other item of the same type.
        if not itemObject then
            itemObject = I.ZHI.getFirstInventoryItem(data.item.recordId)
        end

        local itemContent = getItemTooltipData(record, itemType, itemObject, showExtendedTooltips)
        content.content = ui.content({itemContent})
    end
end

local function createTooltip(data)

        local ttContent = {
            type = ui.TYPE.Flex,
            name = 'tooltip_content',
            props = {
                propagateEvents = true,
                autoSize = true,
                arrange = ui.ALIGNMENT.Center,
                --align = ui.ALIGNMENT.Center,
                --size = util.vector2(120, 40)
            },
            content = ui.content({

            })
        }

        local hPadded = {
            type = ui.TYPE.Flex,
            props = {
                autoSize = true,
                horizontal = true,
            },
            content = ui.content({
                {
                    type = ui.TYPE.Widget,
                    props = { size = util.vector2(TT_CONSTANTS.HPadding, 0) }
                },
                ttContent,
                {
                    type = ui.TYPE.Widget,
                    props = { size = util.vector2(TT_CONSTANTS.HPadding, 0) }
                },
            })
        }

        local vPadded = {
            type = ui.TYPE.Flex,
            props = {
                autoSize = true,
            },
            content = ui.content({
                {
                    type = ui.TYPE.Widget,
                    props = { size = util.vector2(0, TT_CONSTANTS.VPadding) }
                },
                hPadded,
                {
                    type = ui.TYPE.Widget,
                    props = { size = util.vector2(0, TT_CONSTANTS.VPadding) }
                },
            })
        }

        local root = {
            template = I.MWUI.templates.boxSolid,
            type = ui.TYPE.Container,
            layer = I.ZHI.getTooltipLayer(),
            props = {
                propagateEvents = true,
                inheritAlpha = false,
                anchor = util.vector2(0.0, 0.0),
            },
            content = ui.content({ vPadded })
        }

        setTooltipData(root, data)

        return root
end

local function createSelf(data)
    local layout = createTooltip(data)
    tooltipWindow = ui.create(layout)
    tooltipWindow:update()
end

return {

    createTooltip = createTooltip,

    setTooltipData = setTooltipData,

    updateTooltip = function(position, data)
        if data == nil then
            if tooltipWindow then
                tooltipWindow:destroy()
                tooltipWindow = nil
            end
            return
        end

        if not tooltipWindow then
            createSelf(data)
        end

        if tooltipWindow then
            tooltipWindow.layout.props.position = position
            setTooltipData(tooltipWindow.layout, data)
            tooltipWindow:update()
        end
    end,
}