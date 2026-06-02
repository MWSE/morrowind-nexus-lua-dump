-- FailureXPBonus/player.lua
--
-- Subscribes to the engine's skill-failed event (added by the patched engine)
-- and grants a configurable fraction of a successful use's XP.

local I        = require('openmw.interfaces')
local ui       = require('openmw.ui')
local core     = require('openmw.core')
local settings = require('scripts.FailureXPBonus.settings')

I.Settings.registerPage{
    key         = 'FailureXPBonus',
    l10n        = 'FailureXPBonus',
    name        = 'name',
    description = 'description',
}

I.Settings.registerGroup{
    key               = settings.GROUP,
    page              = 'FailureXPBonus',
    l10n              = 'FailureXPBonus',
    name              = 'group_name',
    permanentStorage  = true,
    settings = {
        {
            key         = settings.KEY_MASTER_ENABLED,
            renderer    = 'checkbox',
            name        = 'master_enabled_name',
            description = 'master_enabled_description',
            default     = settings.DEFAULT_MASTER_ENABLED,
        },
        {
            key         = settings.KEY_MASTER_FRACTION,
            renderer    = 'number',
            name        = 'master_fraction_name',
            description = 'master_fraction_description',
            default     = settings.DEFAULT_MASTER_FRACTION,
            argument    = { min = 1.0, max = 10.0, integer = false },
        },
        {
            key         = settings.KEY_WEAPON,
            renderer    = 'number',
            name        = 'weapon_name',
            description = 'weapon_description',
            default     = settings.DEFAULT_WEAPON,
            argument    = { min = 1.0, max = 10.0, integer = false },
        },
        {
            key         = settings.KEY_MAGIC,
            renderer    = 'number',
            name        = 'magic_name',
            description = 'magic_description',
            default     = settings.DEFAULT_MAGIC,
            argument    = { min = 1.0, max = 10.0, integer = false },
        },
        {
            key         = settings.KEY_LOCKPICK,
            renderer    = 'number',
            name        = 'lockpick_name',
            description = 'lockpick_description',
            default     = settings.DEFAULT_LOCKPICK,
            argument    = { min = 1.0, max = 10.0, integer = false },
        },
        {
            key         = settings.KEY_PICKPOCKET,
            renderer    = 'number',
            name        = 'pickpocket_name',
            description = 'pickpocket_description',
            default     = settings.DEFAULT_PICKPOCKET,
            argument    = { min = 1.0, max = 10.0, integer = false },
        },
        {
            key         = settings.KEY_MERCANTILE,
            renderer    = 'number',
            name        = 'mercantile_name',
            description = 'mercantile_description',
            default     = settings.DEFAULT_MERCANTILE,
            argument    = { min = 1.0, max = 10.0, integer = false },
        },
        {
            key         = settings.KEY_ALCHEMY,
            renderer    = 'number',
            name        = 'alchemy_name',
            description = 'alchemy_description',
            default     = settings.DEFAULT_ALCHEMY,
            argument    = { min = 1.0, max = 10.0, integer = false },
        },
        {
            key         = settings.KEY_ENCHANT,
            renderer    = 'number',
            name        = 'enchant_name',
            description = 'enchant_description',
            default     = settings.DEFAULT_ENCHANT,
            argument    = { min = 1.0, max = 10.0, integer = false },
        },
        {
            key         = settings.KEY_REPAIR,
            renderer    = 'number',
            name        = 'repair_name',
            description = 'repair_description',
            default     = settings.DEFAULT_REPAIR,
            argument    = { min = 1.0, max = 10.0, integer = false },
        },
        {
            key         = settings.KEY_BLOCK,
            renderer    = 'number',
            name        = 'block_name',
            description = 'block_description',
            default     = settings.DEFAULT_BLOCK,
            argument    = { min = 1.0, max = 10.0, integer = false },
        },
        {
            key         = settings.KEY_ACROBATICS,
            renderer    = 'number',
            name        = 'acrobatics_name',
            description = 'acrobatics_description',
            default     = settings.DEFAULT_ACROBATICS,
            argument    = { min = 1.0, max = 10.0, integer = false },
        },
        {
            key         = settings.KEY_DEBUG_UI_MESSAGES,
            renderer    = 'checkbox',
            name        = 'debug_messages_name',
            description = 'debug_messages_description',
            default     = settings.DEFAULT_DEBUG_UI_MESSAGES,
        },
        {
            key         = settings.KEY_IMMERSIVE_MESSAGES,
            renderer    = 'checkbox',
            name        = 'immersive_messages_name',
            description = 'immersive_messages_description',
            default     = settings.DEFAULT_IMMERSIVE_MESSAGES,
        },
    },
}

local l10n = core.l10n('FailureXPBonus')

local USE_TYPES = I.SkillProgression.SKILL_USE_TYPES
local CAT = settings.CATEGORY

-- Map (skillid, useType) → category. Anything unmapped is ignored.
local function classify(skillid, useType)
    if useType == USE_TYPES.Weapon_SuccessfulHit then
        return CAT.WEAPON
    elseif useType == USE_TYPES.Spellcast_Success then
        return CAT.MAGIC
    elseif skillid == 'security' and useType == USE_TYPES.Security_PickLock then
        return CAT.LOCKPICK
    elseif skillid == 'security' and useType == USE_TYPES.Security_DisarmTrap then
        return CAT.LOCKPICK
    elseif skillid == 'sneak' and useType == USE_TYPES.Sneak_PickPocket then
        return CAT.PICKPOCKET
    elseif skillid == 'mercantile' and useType == USE_TYPES.Mercantile_Success then
        return CAT.MERCANTILE
    elseif skillid == 'alchemy' and useType == USE_TYPES.Alchemy_CreatePotion then
        return CAT.ALCHEMY
    elseif skillid == 'enchant' and useType == USE_TYPES.Enchant_CreateMagicItem then
        return CAT.ENCHANT
    elseif skillid == 'armorer' and useType == USE_TYPES.Armorer_Repair then
        return CAT.REPAIR
    elseif skillid == 'block' and useType == USE_TYPES.Block_Success then
        return CAT.BLOCK
    elseif skillid == 'acrobatics' and useType == USE_TYPES.Acrobatics_Fall then
        return CAT.ACROBATICS
    end
    return nil
end

local function onSkillFailed(skillid, params)
    local category = classify(skillid, params.useType)
    if not category then return end

    local mult = settings.getFractionFor(category)
    local fraction = math.max(0, mult - 1.0)
    if fraction <= 0 then return end

    local successGain = params.skillGain
    if not successGain or successGain <= 0 then return end

    local gain = successGain * fraction

    -- Route through the success chain so the default XP handler applies the gain
    -- and triggers level-up if the threshold is crossed.
    I.SkillProgression.skillUsed(skillid, { skillGain = gain, useType = params.useType })

    local immersive = settings.getImmersiveMessagesEnabled()
    if settings.getDebugUIMessagesEnabled() then
        if immersive then
            ui.showMessage(l10n('immersive_' .. category, { gain = string.format('%.2f', gain) }))
        else
            ui.showMessage(('[FailureXP] +%.2f %s'):format(gain, skillid))
        end
    end

    -- When immersive wording is enabled, ask the engine to suppress its own
    -- vanilla "you failed" messageBox so the toast above is the only message
    -- the player sees for this failure. Requires engine support (interface
    -- version >= 4); on older engines this return is harmlessly ignored.
    if immersive then return true end
end

I.SkillProgression.addSkillUsedFailedHandler(onSkillFailed)
