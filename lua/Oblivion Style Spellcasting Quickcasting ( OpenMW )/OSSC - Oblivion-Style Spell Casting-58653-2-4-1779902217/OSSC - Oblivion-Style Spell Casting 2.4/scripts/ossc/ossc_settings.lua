local I       = require('openmw.interfaces')
local input   = require('openmw.input')
local storage = require('openmw.storage')

local function debugLog(msg)
    local section = storage.playerSection('SettingsOSSC_General')
    if section and section:get('DebugMode') then
        print("[OSSC Settings] " .. tostring(msg))
    end
end

debugLog("--- OSSC SETTINGS INITIALIZATION START ---")

input.registerAction {
    key          = 'OSSC_QuickCast',
    type         = input.ACTION_TYPE.Boolean,
    l10n         = 'OSSC',
    defaultValue = false,
}

if I.Settings and I.Settings.registerPage then

    pcall(function()
        I.Settings.registerPage({
            key         = 'OSSCPage',
            l10n        = 'OSSC',
            name        = 'Oblivion-Style Spell Casting v2.4',
            description = 'Settings for the OSSC Mod'
        })
    end)

    -- ── Group 1: General ──────────────────────────────────────────────────
    pcall(function()
        I.Settings.registerGroup({
            key              = 'SettingsOSSC_Keys',
            page             = 'OSSCPage',
            l10n             = 'OSSC',
            name             = 'General',
            permanentStorage = true,
            order            = 1,
            settings         = {
                {
                    key         = 'QuickCastBinding',
                    renderer    = 'inputBinding',
                    default     = 'OSSC_QuickCast_default',
                    name        = 'Quick Cast (Keyboard / Gamepad Buttons)',
                    description = 'Bind a keyboard key or gamepad button here.\n\nTo CLEAR the binding: click it and press Escape.\n\nNote: L2/R2 triggers cannot be bound here — use the trigger options below instead.',
                    argument    = { type = 'action', key = 'OSSC_QuickCast' },
                },
                {
                    key         = 'QuickCastTrigger',
                    name        = 'Quick Cast - Gamepad Trigger',
                    description = 'Use a trigger as additional Quick Cast input.\nL2/R2 are analog axes and cannot be bound via inputBinding above, so use this instead.\nL2 = Left Trigger\nR2 = Right Trigger',
                    renderer    = 'select',
                    default     = 'none',
                    argument    = {
                        disabled = false,
                        l10n     = 'OSSC',
                        items    = { 'Disabled', 'L2/LT', 'R2/RT' },
                    },
                },
                {
                    key         = 'QuickCastTriggerThreshold',
                    name        = 'Trigger Activation Threshold (L2/R2 setting only)',
                    description = 'How far to pull the trigger to count as a press (0.1 = very light, 1.0 = full pull).',
                    renderer    = 'number',
                    default     = 0.60,
                    min         = 0.10,
                    max         = 1.00,
                },
                {
                    key         = 'EnablePlayerSwirls',
                    name        = 'Enable Player VFX/Particles',
                    description = 'Show cast effects around the player during casting.',
                    renderer    = 'checkbox',
                    default     = true
                },
                {
                    key         = 'EnableHandSwirls',
                    name        = 'Enable Hand VFX (element ball)',
                    description = 'Show magic swirls around the casting hand.',
                    renderer    = 'checkbox',
                    default     = true
                },
                {
                    key         = 'EnableCastGlow',
                    name        = 'Enable Cast VFX around hand',
                    description = 'Show the school-specific cast static at the left hand during wind-up.',
                    renderer    = 'checkbox',
                    default     = false
                },
                {
                    key         = 'SkillUsesScaledCompatibility',
                    name        = 'Skill Uses Scaled Compat **NOT WORKING YET**',
                    description = 'Enable if using Skill Uses Scaled mod. Disables OSSC internal skill gain.',
                    renderer    = 'checkbox',
                    default     = false
                },
            }
        })
    end)

    -- ── Group 2: Gameplay ─────────────────────────────────────────────────
    pcall(function()
        local generalStorage     = storage.playerSection('SettingsOSSC_General')
        local penaltySelectItems = { 'off', 'reduce_25', 'reduce_50' }

        local function migratePenaltyKey(key)
            local v = generalStorage:get(key)
            if v == nil then return end
            if v == 'off' or v == 'reduce_25' or v == 'reduce_50' then return end
            local n = tonumber(v)
            if n == 0 then generalStorage:set(key, 'off');       return end
            if n == 1 then generalStorage:set(key, 'reduce_25'); return end
            if n == 2 then generalStorage:set(key, 'reduce_50'); return end
            local s = tostring(v):lower()
            if s == 'off' or s == 'disabled' or s == 'ossc_penalty_off' then generalStorage:set(key, 'off'); return end
            if s == 'reduce 25%' or s == '25%' or s == '25' or s == '-25%' or s == 'ossc_penalty_25' then generalStorage:set(key, 'reduce_25'); return end
            if s == 'reduce 50%' or s == '50%' or s == '50' or s == '-50%' or s == 'ossc_penalty_50' then generalStorage:set(key, 'reduce_50'); return end
            generalStorage:set(key, 'off')
        end
        migratePenaltyKey('QuickCastChancePenalty')
        migratePenaltyKey('QuickCastEffectPenalty')

        local ok, err = pcall(function()
            I.Settings.registerGroup({
                key              = 'SettingsOSSC_General',
                page             = 'OSSCPage',
                l10n             = 'OSSC',
                name             = 'Gameplay',
                permanentStorage = true,
                order            = 2,
                settings         = {
                    {
                        key         = 'UseFatigue',
                        name        = 'Use Fatigue',
                        description = 'Enable fatigue drain and fatigue-based spell success chance (MCP formula).',
                        renderer    = 'checkbox',
                        default     = true
                    },
                    {
                        key         = 'DebugMode',
                        name        = 'Debug Mode',
                        description = 'Show OSSC logic debug messages in the console (F10).',
                        renderer    = 'checkbox',
                        default     = false
                    },
                    {
                        key         = 'SkillExperience',
                        name        = 'Skill Experience Ratio',
                        description = 'Ratio of XP awarded for a successful spellcast.',
                        renderer    = 'number',
                        default     = 1.0,
                        min         = 0,
                        max         = 100
                    },
                    {
                        key         = 'QuickCastChancePenalty',
                        name        = 'Quick Cast Chance Penalty',
                        description = 'Off = full chance. Reduce 25%/50% multiply success chance by 0.75 or 0.5.',
                        default     = 'off',
                        renderer    = 'select',
                        argument    = {
                            disabled = false,
                            l10n     = 'OSSC',
                            items    = penaltySelectItems,
                        },
                    },
                }
            })
        end)
        if not ok then
            print("[OSSC Settings] ERROR registering Gameplay group: " .. tostring(err))
        end
    end)

    -- ── Group 3: Cast Animations ──────────────────────────────────────────
    pcall(function()
        local ANIM_GROUPS = {
            'quickcast', 'quickbuff',
            'qcconj',  'qctouch',
            'qcalt', 'qcill',
            'qcsnap',
            'qcdrain',
            'qcskrow',
        }

        local function animEntry(key, name, description, default)
            return {
                key      = key,
                name     = name,
                description = description,
                default  = default,
                renderer = 'select',
                argument = { disabled = false, l10n = 'OSSC', items = ANIM_GROUPS },
            }
        end

        I.Settings.registerGroup({
            key              = 'SettingsOSSC_Animations',
            page             = 'OSSCPage',
            l10n             = 'OSSC',
            name             = 'Cast Animations',
            description      = 'Choose which animation plays for each school, cast range and camera perspective.\nEnchanted items use the same school-based selection as regular spells.',
            permanentStorage = true,
            order            = 3,
            settings         = {
                {
                    key         = 'SnapSoundVolume',
                    name        = 'Snap Sound Volume',
                    description = 'Volume of the snap sound played whenever the qcsnap animation is used (0.0 = silent, 1.0 = full).',
                    renderer    = 'number',
                    default     = 0.45,
                    min         = 0.0,
                    max         = 1.0,
                },

                animEntry('Anim_Alteration_Self_1st',    'Alteration – Self (1st person)',    'Animation for Alteration self-range spells in first person.',    'qcsnap'),
                animEntry('Anim_Alteration_Self_3rd',    'Alteration – Self (3rd person)',    'Animation for Alteration self-range spells in third person.',    'qcsnap'),
                animEntry('Anim_Alteration_Target_1st',  'Alteration – Target (1st person)',  'Animation for Alteration target-range spells in first person.',  'qcalt'),
                animEntry('Anim_Alteration_Target_3rd',  'Alteration – Target (3rd person)',  'Animation for Alteration target-range spells in third person.',  'qcalt'),

                animEntry('Anim_Conjuration_Self_1st',   'Conjuration – Self (1st person)',   'Animation for Conjuration self-range spells in first person.',   'quickbuff'),
                animEntry('Anim_Conjuration_Self_3rd',   'Conjuration – Self (3rd person)',   'Animation for Conjuration self-range spells in third person.',   'quickbuff'),
                animEntry('Anim_Conjuration_Touch_1st',  'Conjuration – Touch (1st person)',  'Animation for Conjuration touch-range spells in first person.',  'qctouch'),
                animEntry('Anim_Conjuration_Touch_3rd',  'Conjuration – Touch (3rd person)',  'Animation for Conjuration touch-range spells in third person.',  'qctouch'),
                animEntry('Anim_Conjuration_Target_1st', 'Conjuration – Target (1st person)', 'Animation for Conjuration target-range spells in first person.', 'quickcast'),
                animEntry('Anim_Conjuration_Target_3rd', 'Conjuration – Target (3rd person)', 'Animation for Conjuration target-range spells in third person.', 'quickcast'),

                animEntry('Anim_Destruction_Self_1st',   'Destruction – Self (1st person)',   'Animation for Destruction self-range spells in first person.',   'quickbuff'),
                animEntry('Anim_Destruction_Self_3rd',   'Destruction – Self (3rd person)',   'Animation for Destruction self-range spells in third person.',   'quickbuff'),
                animEntry('Anim_Destruction_Touch_1st',  'Destruction – Touch (1st person)',  'Animation for Destruction touch-range spells in first person.',  'qcdrain'),
                animEntry('Anim_Destruction_Touch_3rd',  'Destruction – Touch (3rd person)',  'Animation for Destruction touch-range spells in third person.',  'qcdrain'),
                animEntry('Anim_Destruction_Target_1st', 'Destruction – Target (1st person)', 'Animation for Destruction target-range spells in first person.', 'quickcast'),
                animEntry('Anim_Destruction_Target_3rd', 'Destruction – Target (3rd person)', 'Animation for Destruction target-range spells in third person.', 'quickcast'),

                animEntry('Anim_Illusion_Self_1st',      'Illusion – Self (1st person)',      'Animation for Illusion self-range spells in first person.',      'qcill'),
                animEntry('Anim_Illusion_Self_3rd',      'Illusion – Self (3rd person)',      'Animation for Illusion self-range spells in third person.',      'qcill'),
                animEntry('Anim_Illusion_Touch_1st',     'Illusion – Touch (1st person)',     'Animation for Illusion touch-range spells in first person.',     'qcill'),
                animEntry('Anim_Illusion_Touch_3rd',     'Illusion – Touch (3rd person)',     'Animation for Illusion touch-range spells in third person.',     'qcill'),
                animEntry('Anim_Illusion_Target_1st',    'Illusion – Target (1st person)',    'Animation for Illusion target-range spells in first person.',    'quickcast'),
                animEntry('Anim_Illusion_Target_3rd',    'Illusion – Target (3rd person)',    'Animation for Illusion target-range spells in third person.',    'quickcast'),

                animEntry('Anim_Mysticism_Self_1st',     'Mysticism – Self (1st person)',     'Animation for Mysticism self-range spells in first person.',     'qcsnap'),
                animEntry('Anim_Mysticism_Self_3rd',     'Mysticism – Self (3rd person)',     'Animation for Mysticism self-range spells in third person.',     'qcsnap'),
                animEntry('Anim_Mysticism_Touch_1st',    'Mysticism – Touch (1st person)',    'Animation for Mysticism touch-range spells in first person.',    'qctouch'),
                animEntry('Anim_Mysticism_Touch_3rd',    'Mysticism – Touch (3rd person)',    'Animation for Mysticism touch-range spells in third person.',    'qctouch'),
                animEntry('Anim_Mysticism_Target_1st',   'Mysticism – Target (1st person)',   'Animation for Mysticism target-range spells in first person.',   'quickcast'),
                animEntry('Anim_Mysticism_Target_3rd',   'Mysticism – Target (3rd person)',   'Animation for Mysticism target-range spells in third person.',   'quickcast'),

                animEntry('Anim_Restoration_Self_1st',   'Restoration – Self (1st person)',   'Animation for Restoration self-range spells in first person.',   'quickbuff'),
                animEntry('Anim_Restoration_Self_3rd',   'Restoration – Self (3rd person)',   'Animation for Restoration self-range spells in third person.',   'quickbuff'),
                animEntry('Anim_Restoration_Touch_1st',  'Restoration – Touch (1st person)',  'Animation for Restoration touch-range spells in first person.',  'qcdrain'),
                animEntry('Anim_Restoration_Touch_3rd',  'Restoration – Touch (3rd person)',  'Animation for Restoration touch-range spells in third person.',  'qcdrain'),
                animEntry('Anim_Restoration_Target_1st', 'Restoration – Target (1st person)', 'Animation for Restoration target-range spells in first person.', 'quickcast'),
                animEntry('Anim_Restoration_Target_3rd', 'Restoration – Target (3rd person)', 'Animation for Restoration target-range spells in third person.', 'quickcast'),
            }
        })
    end)

    -- ── Group 4: Animation Speeds ─────────────────────────────────────────
    pcall(function()
        I.Settings.registerGroup({
            key              = 'SettingsOSSC_AnimSpeeds',
            page             = 'OSSCPage',
            l10n             = 'OSSC',
            name             = 'Animation Speeds (for developers)',
            description      = 'Do not change unless you know what you are doing.',
            permanentStorage = true,
            order            = 4,
            settings         = {
                { key = 'AnimSpeed_Quickcast', name = 'Quick Cast Speed',   description = 'Speed for quickcast (Target) animation.',          renderer = 'number', default = 1.00 },
                { key = 'AnimSpeed_Quickbuff', name = 'Quick Buff Speed',   description = 'Speed for quickbuff (Self) animation.',            renderer = 'number', default = 1.00 },
                { key = 'AnimSpeed_Qcconj',    name = 'Conjuration Speed',  description = 'Speed for qcconj animation.',                     renderer = 'number', default = 1.00 },
                { key = 'AnimSpeed_Qctouch',   name = 'Touch Speed',        description = 'Speed for qctouch animation.',                    renderer = 'number', default = 1.00 },
                { key = 'AnimSpeed_Qcalt',     name = 'Alteration Speed',   description = 'Speed for qcalt (Alteration Target) animation.',   renderer = 'number', default = 1.00 },
                { key = 'AnimSpeed_Qcill',     name = 'Illusion Speed',     description = 'Speed for qcill animation.',                      renderer = 'number', default = 1.00 },
                { key = 'AnimSpeed_Qcsnap',    name = 'Snap Speed',         description = 'Speed for qcsnap animation.',                     renderer = 'number', default = 1.00 },
                { key = 'AnimSpeed_Qcdrain',   name = 'Drain Speed',        description = 'Speed for qcdrain animation.',                    renderer = 'number', default = 1.00 },
                { key = 'AnimSpeed_Qcskrow',   name = 'Skrow Speed',        description = 'Speed for qcskrow animation.',                    renderer = 'number', default = 1.00 },
                { key = 'AnimSpeedScale',      name = 'Global Cast Scale',  description = 'Global multiplier applied on top of all speeds.',  renderer = 'number', default = 1.00 },
                {
                    key         = 'SafetyUnlockTimer',
                    name        = 'Safety Unlock Timer',
                    description = 'Maximum time (seconds) the cast stays locked as a fallback if the animation never fires its stop key.',
                    renderer    = 'number',
                    default     = 1.00,
                    min         = 0.1,
                    max         = 5.0,
                },
            }
        })
    end)

end

print("--- OSSC SETTINGS INITIALIZATION FINISHED ---")
return {}