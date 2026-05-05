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
            key         = settings.KEY_DEBUG_UI_MESSAGES,
            renderer    = 'checkbox',
            name        = 'debugUIMessages_name',
            description = 'debug_messages_description',
            default     = settings.DEFAULT_DEBUG_UI_MESSAGES,
        },
    },
}

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
    end
    return nil
end

local function onSkillFailed(skillid, params)
    print(('[FailureXP-debug] onSkillFailed fired: skillid=%s useType=%s skillGain=%s')
        :format(tostring(skillid), tostring(params.useType), tostring(params.skillGain)))
    local category = classify(skillid, params.useType)
    if not category then
        print('[FailureXP-debug] no category match, ignoring')
        return
    end

    local mult = settings.getFractionFor(category)
    local fraction = math.max(0, mult - 1.0)
    if fraction <= 0 then return end

    local successGain = params.skillGain
    if not successGain or successGain <= 0 then return end

    local gain = successGain * fraction

    -- Route through the success chain so the default XP handler applies the gain
    -- and triggers level-up if the threshold is crossed.
    I.SkillProgression.skillUsed(skillid, { skillGain = gain, useType = params.useType })
    local debugUI = settings.getDebugUIMessagesEnabled()
    if debugUI then
        ui.showMessage(('[FailureXP] +%.2f %s'):format(gain, skillid))
    end
end

I.SkillProgression.addSkillUsedFailedHandler(onSkillFailed)
