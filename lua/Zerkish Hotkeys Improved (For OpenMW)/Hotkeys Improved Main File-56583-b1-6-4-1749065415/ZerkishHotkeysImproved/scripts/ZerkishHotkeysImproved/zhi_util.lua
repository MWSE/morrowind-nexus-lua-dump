-- Zerkish Hotkeys Improved - zhi_util.lua
-- utility library

local core = require('openmw.core')
local ui    = require('openmw.ui')
local types = require('openmw.types')

local ZItems = require('scripts.ZModUtils.Utility.Items')

local ZHIL10n = core.l10n('ZerkishHotkeysImproved')

local textureCache = {}

-- Returns non-localized 'flavor text' based on a weapon record.
local function getWeaponSubtext(weaponRecord)
    if weaponRecord == nil then return nil end

    --if weaponRecord.type == types.Weapon.TYPE.AxeOneHand then return "Axe, One Handed" end
    if weaponRecord.type == types.Weapon.TYPE.AxeOneHand then return ZHIL10n('in_game_tooltip_item_st_weapon_axe1h') end
    --if weaponRecord.type == types.Weapon.TYPE.AxeTwoHand then return "Axe, Two Handed" end
    if weaponRecord.type == types.Weapon.TYPE.AxeTwoHand then return ZHIL10n('in_game_tooltip_item_st_weapon_axe2h') end
    --if weaponRecord.type == types.Weapon.TYPE.BluntOneHand then return "Blunt, One Handed" end
    if weaponRecord.type == types.Weapon.TYPE.BluntOneHand then return ZHIL10n('in_game_tooltip_item_st_weapon_blunt1h') end
    --if weaponRecord.type == types.Weapon.TYPE.BluntTwoClose then return "Blunt, Two Handed" end
    if weaponRecord.type == types.Weapon.TYPE.BluntTwoClose then return ZHIL10n('in_game_tooltip_item_st_weapon_blunt2h') end
    --if weaponRecord.type == types.Weapon.TYPE.BluntTwoWide then return "Blunt, Two Handed" end
    if weaponRecord.type == types.Weapon.TYPE.BluntTwoWide then return ZHIL10n('in_game_tooltip_item_st_weapon_blunt2h') end
    --if weaponRecord.type == types.Weapon.TYPE.LongBladeOneHand then return "Long Blade, One Handed" end
    if weaponRecord.type == types.Weapon.TYPE.LongBladeOneHand then return ZHIL10n('in_game_tooltip_item_st_weapon_lblade1h') end
    --if weaponRecord.type == types.Weapon.TYPE.LongBladeTwoHand then return "Long Blade, Two Handed" end
    if weaponRecord.type == types.Weapon.TYPE.LongBladeTwoHand then return ZHIL10n('in_game_tooltip_item_st_weapon_lblade2h') end
    --if weaponRecord.type == types.Weapon.TYPE.MarksmanBow then return "Marksman" end
    if weaponRecord.type == types.Weapon.TYPE.MarksmanBow then return ZHIL10n('in_game_tooltip_item_st_weapon_marksman') end
    --if weaponRecord.type == types.Weapon.TYPE.MarksmanCrossbow then return "Marksman" end
    if weaponRecord.type == types.Weapon.TYPE.MarksmanCrossbow then return ZHIL10n('in_game_tooltip_item_st_weapon_marksman') end
    --if weaponRecord.type == types.Weapon.TYPE.MarksmanThrown then return "Marksman" end
    if weaponRecord.type == types.Weapon.TYPE.MarksmanThrown then return ZHIL10n('in_game_tooltip_item_st_weapon_marksman') end
    --if weaponRecord.type == types.Weapon.TYPE.ShortBladeOneHand then return "Short Blade, One Handed" end
    if weaponRecord.type == types.Weapon.TYPE.ShortBladeOneHand then return ZHIL10n('in_game_tooltip_item_st_weapon_sblade') end
    --if weaponRecord.type == types.Weapon.TYPE.SpearTwoWide then return "Spear, Two Handed" end
    if weaponRecord.type == types.Weapon.TYPE.SpearTwoWide then return ZHIL10n('in_game_tooltip_item_st_weapon_spear') end
    
    if weaponRecord.type == types.Weapon.TYPE.Arrow then return ZHIL10n('in_game_tooltip_item_st_weapon_arrow') end
    if weaponRecord.type == types.Weapon.TYPE.Bolt then return ZHIL10n('in_game_tooltip_item_st_weapon_bolt') end

    return nil
end

local armorClassL10n = { }
armorClassL10n['Light'] = ZHIL10n('in_game_tooltip_item_st_armor_class_light')
armorClassL10n['Medium'] = ZHIL10n('in_game_tooltip_item_st_armor_class_medium')
armorClassL10n['Heavy'] = ZHIL10n('in_game_tooltip_item_st_armor_class_heavy')

-- This function returns 'flavor text' based on record on and type.
local function getItemSubText(record, type)
    if (not record) or (not type) then return nil end

    if type == types.Apparatus then
        local app = ZHIL10n('in_game_tooltip_item_st_apparatus')
        local specific = nil
        --return 'Apparatus'
        if record.type == types.Apparatus.TYPE.Alembic then specific = ZHIL10n('in_game_tooltip_item_st_apparatus_alembic')
        elseif record.type == types.Apparatus.TYPE.Calcinator then specific = ZHIL10n('in_game_tooltip_item_st_apparatus_calcinator')
        elseif record.type == types.Apparatus.TYPE.Retort then specific = ZHIL10n('in_game_tooltip_item_st_apparatus_retort')
        elseif record.type == types.Apparatus.TYPE.MortarPestle then specific = ZHIL10n('in_game_tooltip_item_st_apparatus_mortarpestle')
        end

        if specific then return string.format("%s, %s", specific, app)
        else return app end
        -- elseif record.type == types.Apparatus.TYPE.Calcinator then return 'Calcinator'
        -- elseif record.type == types.Apparatus.TYPE.Alembic then return 'Mortar and Pestle'
        -- elseif record.type == types.Apparatus.TYPE.Retort then return 'Retort'
        -- else return nil end
    elseif type == types.Armor then
        local slotStr = nil
        --if record.type == types.Armor.TYPE.Boots then slotStr = "Boots"
        if record.type == types.Armor.TYPE.Boots then slotStr = ZHIL10n('in_game_tooltip_item_st_armor_boots')
        --elseif record.type == types.Armor.TYPE.Cuirass then slotStr = "Cuirass"
        elseif record.type == types.Armor.TYPE.Cuirass then slotStr = ZHIL10n('in_game_tooltip_item_st_armor_cuirass')
        --elseif record.type == types.Armor.TYPE.Greaves then slotStr = "Greaves"
        elseif record.type == types.Armor.TYPE.Greaves then slotStr = ZHIL10n('in_game_tooltip_item_st_armor_greaves')
        --elseif record.type == types.Armor.TYPE.Helmet then slotStr = "Helmet"
        elseif record.type == types.Armor.TYPE.Helmet then slotStr = ZHIL10n('in_game_tooltip_item_st_armor_helmet')
        --elseif record.type == types.Armor.TYPE.LBracer then slotStr = "Left Bracer"
        elseif record.type == types.Armor.TYPE.LBracer then slotStr = ZHIL10n('in_game_tooltip_item_st_armor_lbracer')
        --elseif record.type == types.Armor.TYPE.LGauntlet then slotStr = "Left Gauntlet"
        elseif record.type == types.Armor.TYPE.LGauntlet then slotStr = ZHIL10n('in_game_tooltip_item_st_armor_lgauntlet')
        --elseif record.type == types.Armor.TYPE.LPauldron then slotStr = "Left Pauldron"
        elseif record.type == types.Armor.TYPE.LPauldron then slotStr = ZHIL10n('in_game_tooltip_item_st_armor_lpauldron')
        --elseif record.type == types.Armor.TYPE.RBracer then slotStr = "Right Bracer"
        elseif record.type == types.Armor.TYPE.RBracer then slotStr = ZHIL10n('in_game_tooltip_item_st_armor_rbracer')
        --elseif record.type == types.Armor.TYPE.RGauntlet then slotStr = "Right Gauntlet"
        elseif record.type == types.Armor.TYPE.RGauntlet then slotStr = ZHIL10n('in_game_tooltip_item_st_armor_rgauntlet')
        --elseif record.type == types.Armor.TYPE.RPauldron then slotStr = "Right Pauldron"
        elseif record.type == types.Armor.TYPE.RPauldron then slotStr = ZHIL10n('in_game_tooltip_item_st_armor_rpauldron')
        --elseif record.type == types.Armor.TYPE.Shield then slotStr = "Shield"
        elseif record.type == types.Armor.TYPE.Shield then slotStr = ZHIL10n('in_game_tooltip_item_st_armor_shield')
        end

        local ac = ZItems.getArmorClass(record)
        local acl10n = armorClassL10n[ac]

        local acfmt = ZHIL10n('in_game_tooltip_item_st_armor_class_format', {class=acl10n})
        local final = ZHIL10n('in_game_tooltip_item_st_armor_format', {armorslot=slotStr, armorclass_format=acfmt})

        return final
    elseif type == types.Book then
        if record.isScroll then
            return ZHIL10n('in_game_tooltip_item_st_scroll')
        end
        return ZHIL10n('in_game_tooltip_item_st_book')
    elseif type == types.Clothing then
        local slotStr = nil
        --if record.type == types.Clothing.TYPE.Amulet then slotStr = "Amulet"
        if record.type == types.Clothing.TYPE.Amulet then slotStr = ZHIL10n('in_game_tooltip_item_st_clothing_amulet')
        --elseif record.type == types.Clothing.TYPE.Belt then slotStr = "Belt"
        elseif record.type == types.Clothing.TYPE.Belt then slotStr = ZHIL10n('in_game_tooltip_item_st_clothing_belt')
        --elseif record.type == types.Clothing.TYPE.LGlove then slotStr = "Left Glove"
        elseif record.type == types.Clothing.TYPE.LGlove then slotStr = ZHIL10n('in_game_tooltip_item_st_clothing_lglove')
        --elseif record.type == types.Clothing.TYPE.Pants then slotStr = "Pants"
        elseif record.type == types.Clothing.TYPE.Pants then slotStr = ZHIL10n('in_game_tooltip_item_st_clothing_pants')
        --elseif record.type == types.Clothing.TYPE.RGlove then slotStr = "Right Glove"
        elseif record.type == types.Clothing.TYPE.RGlove then slotStr = ZHIL10n('in_game_tooltip_item_st_clothing_rglove')
        --elseif record.type == types.Clothing.TYPE.Ring then slotStr = "Ring"
        elseif record.type == types.Clothing.TYPE.Ring then slotStr = ZHIL10n('in_game_tooltip_item_st_clothing_ring')
        --elseif record.type == types.Clothing.TYPE.Robe then slotStr = "Robe"
        elseif record.type == types.Clothing.TYPE.Robe then slotStr = ZHIL10n('in_game_tooltip_item_st_clothing_robe')
        --elseif record.type == types.Clothing.TYPE.Shirt then slotStr = "Shirt"
        elseif record.type == types.Clothing.TYPE.Shirt then slotStr = ZHIL10n('in_game_tooltip_item_st_clothing_shirt')
        --elseif record.type == types.Clothing.TYPE.Shoes then slotStr = "Shoes"
        elseif record.type == types.Clothing.TYPE.Shoes then slotStr = ZHIL10n('in_game_tooltip_item_st_clothing_shoes')
        --elseif record.type == types.Clothing.TYPE.Skirt then slotStr = "Skirt"
        elseif record.type == types.Clothing.TYPE.Skirt then slotStr = ZHIL10n('in_game_tooltip_item_st_clothing_skirt')
        end
        --return string.format("%s, Clothing", slotStr)
        return ZHIL10n('in_game_tooltip_item_st_clothing_format', {clothingslot=slotStr})
    elseif type == types.Ingredient then
        --return "Ingredient"
        return ZHIL10n('in_game_tooltip_item_st_ingredient')
    elseif type == types.Light then
        --return "Light"
        return ZHIL10n('in_game_tooltip_item_st_light')
    elseif type == types.Lockpick then
        --return "Lockpick"
        return ZHIL10n('in_game_tooltip_item_st_lockpick')
    elseif type == types.Potion then
        --return "Potion"
        return ZHIL10n('in_game_tooltip_item_st_potion')
    elseif type == types.Probe then
        --return "Probe"
        return ZHIL10n('in_game_tooltip_item_st_probe')
    elseif type == types.Repair then
        --return "Repair Tool"
        return ZHIL10n('in_game_tooltip_item_st_repair')
    elseif type == types.Weapon then
        return getWeaponSubtext(record)
    end

    return ""
end

local function getCachedTexture(props)
    local key = ""
    for k, v in pairs(props) do
        key = key .. tostring(v)
    end

    if textureCache[key] then
        return textureCache[key]
    end

    local texture = ui.texture(props)
    textureCache[key] = texture
    return texture
end

return {

    getHotkeyIdentifier = function(hotbar, num)
        return string.format('ZHI_Hotbar_%d_%d', hotbar, num % 10)
    end,

    getCachedTexture = getCachedTexture,

        -- Get non-localized 'flavor text' based on an item record.
    -- Examples: "Cuirass, Medium" or "Short Blade, One Handed"
    getItemSubText = getItemSubText,

    -- Returns alocalized display text based on enchantment type.
    getEnchantTypeText = function(enchantment)
        if enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnStrike then
            return ZHIL10n('in_game_tooltip_enchantment_type_castonstrike')
        elseif enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnUse then
            return ZHIL10n('in_game_tooltip_enchantment_type_castonuse')
        elseif enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnce then
            return ZHIL10n('in_game_tooltip_enchantment_type_castonce')
        elseif enchantment.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
            return ZHIL10n('in_game_tooltip_enchantment_type_constanteffect')
        end
        return nil
    end,    

}
