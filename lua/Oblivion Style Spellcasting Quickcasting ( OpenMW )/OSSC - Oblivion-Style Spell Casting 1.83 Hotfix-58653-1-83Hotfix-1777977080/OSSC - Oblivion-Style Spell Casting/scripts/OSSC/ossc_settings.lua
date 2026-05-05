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

-- Register the Quick Cast input action so it can be bound by the player in Settings > Controls
input.registerAction {
    key          = 'OSSC_QuickCast',
    type         = input.ACTION_TYPE.Boolean,
    l10n         = 'OSSC',
    defaultValue = false,
}

if I.Settings and I.Settings.registerPage then
    pcall(function()
        I.Settings.registerPage({
            key = 'OSSCPage',
            l10n = 'OSSC',
            name = 'Oblivion-Style Spell Casting v1.83',
            description = 'Settings for the OSSC Mod'
        })
    end)

    pcall(function()
        I.Settings.registerGroup({
            key = 'SettingsOSSC_Keys',
            page = 'OSSCPage',
            l10n = 'OSSC',
            name = 'General',
            permanentStorage = true,
            order = 1,
            settings = {
                {
                    key         = 'QuickCastBinding',
                    renderer    = 'inputBinding',
                    default     = 'OSSC_QuickCast_default',
                    name        = 'Quick Cast',
                    description = 'Key used to quick-cast the currently selected spell.\n\nDO NOT BIND THIS KEY TO SPELL STANCE BINDING!',
                    argument    = {
                        type = 'action',
                        key  = 'OSSC_QuickCast',
                    },
                },
                {
                    key = 'EnablePlayerSwirls',
                    name = 'Enable Player VFX/Particles',
                    description = 'Show cast effects around the player during casting.',
                    renderer = 'checkbox',
                    default = true
                },
                {
                    key = 'EnableHandSwirls',
                    name = 'Enable Hand VFX (element ball)',
                    description = 'Show magic swirls around the casting hand.',
                    renderer = 'checkbox',
                    default = true
                },
                {
                    key = 'EnableCastGlow',
                    name = 'Enable Cast VFX around hand',
                    description = 'Show the school-specific cast static (e.g. VFX_DestructCast) at the left hand during wind-up. This is a larger, school-burst effect separate from the swirls above.',
                    renderer = 'checkbox',
                    default = false
                },
                {
                    key = 'SkillUsesScaledCompatibility',
                    name = 'Skill Uses Scaled Compat **NOT WORKING YET**',
                    description = 'Enable if using Skill Uses Scaled mod. Disables OSSC internal skill gain.',
                    renderer = 'checkbox',
                    default = false
                }
            }
        })
    end)

    pcall(function()
        -- `select` needs argument.l10n + l10n/OSSC/*.yaml; stored values are keys (off, reduce_25, reduce_50).
        local generalStorage = storage.playerSection('SettingsOSSC_General')
        local penaltySelectItems = { 'off', 'reduce_25', 'reduce_50' }
        local function migratePenaltyKey(key)
            local v = generalStorage:get(key)
            if v == nil then return end
            if v == 'off' or v == 'reduce_25' or v == 'reduce_50' then return end
            local n = tonumber(v)
            if n == 0 then generalStorage:set(key, 'off'); return end
            if n == 1 then generalStorage:set(key, 'reduce_25'); return end
            if n == 2 then generalStorage:set(key, 'reduce_50'); return end
            if v == 'Off' or v == 'off' then generalStorage:set(key, 'off'); return end
            if v == 'Reduce 25%' or v == 'reduce 25%' then generalStorage:set(key, 'reduce_25'); return end
            if v == 'Reduce 50%' or v == 'reduce 50%' then generalStorage:set(key, 'reduce_50'); return end
            local s = tostring(v):lower()
            if s == 'ossc_penalty_off' or s == 'disabled' then generalStorage:set(key, 'off'); return end
            if s == 'ossc_penalty_25' or s == '25%' or s == '25' or s == '-25%' then generalStorage:set(key, 'reduce_25'); return end
            if s == 'ossc_penalty_50' or s == '50%' or s == '50' or s == '-50%' then generalStorage:set(key, 'reduce_50'); return end
            generalStorage:set(key, 'off')
        end
        migratePenaltyKey('QuickCastChancePenalty')
        migratePenaltyKey('QuickCastEffectPenalty')

        local okReg, errReg = pcall(function()
            I.Settings.registerGroup({
            key = 'SettingsOSSC_General',
            page = 'OSSCPage',
            l10n = 'OSSC',
            name = 'Gameplay',
            permanentStorage = true,
            order = 2,
            settings = {
                {
                    key = 'UseFatigue',
                    name = 'Use Fatigue',
                    description = 'Enable/disable fatigue usage (reading from GMSTs)and fatigue spellcast success chance upon spellcasting.(MCP Formula)',
                    renderer = 'checkbox',
                    default = true
                },
                {
                    key         = 'DebugMode',
                    name        = 'Debug Mode',
                    description = 'Show OSSC logic debug messages in the console (F10).',
                    renderer    = 'checkbox',
                    default     = false
                },
                {
                    key = 'SkillExperience',
                    name = 'Skill Experience Ratio',
                    description = 'Ratio of XP awarded for a successful spellcast.',
                    renderer = 'number',
                    default = 1.0,
                    min = 0,
                    max = 100
                },
                {
                    key = 'QuickCastChancePenalty',
                    name = 'Quick Cast Chance Penalty',
                    description = 'Off = full chance. Reduce 25% / 50% multiply success chance by 0.75 or 0.5.',
                    default = 'off',
                    renderer = 'select',
                    argument = {
                        disabled = false,
                        l10n = 'OSSC',
                        items = penaltySelectItems,
                    },
                },
                -- {
                --     key = 'QuickCastEffectPenalty',
                --     name = 'Quick Cast Effect Penalty',
                --     description = 'Off = full magnitude, area, duration. Reduce 25% / 50% scale effects down.',
                --     default = 'off',
                --     renderer = 'select',
                --     argument = {
                --         disabled = false,
                --         l10n = 'OSSC',
                --         items = penaltySelectItems,
                --     },
                -- }
            }
            })
        end)
        if not okReg then
            print("[OSSC Settings] ERROR registering Gameplay group: " .. tostring(errReg))
        end
    end)


    pcall(function()
        I.Settings.registerGroup({
            key = 'SettingsOSSC_AnimSpeeds',
            page = 'OSSCPage',
            l10n = 'OSSC',
            name = 'Animation Speeds (for developers)',
            description = 'Do not change unless you know what you are doing.',
            permanentStorage = true,
            order = 4,
            settings = {
                { key = 'AnimSpeed_Quickcasts', name = 'Quick Cast Speed',   description = 'Speed for quickcast (Target) animation.',  renderer = 'number', default = 1.00 },
                { key = 'AnimSpeed_Quickbuffs', name = 'Quick Buff Speed',   description = 'Speed for quickbuff (Self) animation.',    renderer = 'number', default = 1.00 },
                { key = 'AnimSpeed_Qcconjs',    name = 'Conjuration Speed',  description = 'Speed for qcconj (Touch/Self) animation.', renderer = 'number', default = 1.00 },
                { key = 'AnimSpeed_Qctouchs',   name = 'Touch Speed',        description = 'Speed for qctouch (Touch) animation.',     renderer = 'number', default = 1.00 },
                { key = 'AnimSpeed_Qcalts',     name = 'Alteration Speed',   description = 'Speed for qcalt (Touch/Target) animation.', renderer = 'number', default = 1.00 },
                { key = 'AnimSpeed_Qcills',     name = 'Illusion Speed',     description = 'Speed for qcill (Touch/Self) animation.',  renderer = 'number', default = 1.00 },
                { key = 'AnimSpeed_Qcsnaps',    name = 'Snap Speed',         description = 'Speed for qcsnap animation.',              renderer = 'number', default = 1.00 },
                { key = 'AnimSpeedScale',      name = 'Global Cast Scale',  description = 'Global multiplier for all cast animations.', renderer = 'number', default = 1.0 },
            }
        })
    end)

end

print("--- OSSC SETTINGS INITIALIZATION FINISHED ---")
return {}
