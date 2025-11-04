local util = require('openmw.util')
local I = require("openmw.interfaces")
local ui = require("openmw.ui")
local async = require("openmw.async")
local c = require('scripts.HitKillFeedback.constants').c

local MOD_NAME = 'HitKillFeedBack'
local prefix = 'SettingsPlayer'

-- print('c.effectColor.damagehealth = ', c.effectColor.damagehealth)

local o = {

        damageColors = {
                name = 'Damage Numbers Colors',
                settings = {
                        healthDmgColor = {
                                name = 'Health',
                                key = 'healthDmgColor',
                                default = util.color.hex(c.effectColor.damagehealth),
                                value = util.color.hex(c.effectColor.damagehealth),
                                renderer = "color",
                        },
                        fatigueDmgColor = {
                                name = 'Fatigue',
                                key = 'fatigueDmgColor',
                                default = util.color.hex(c.effectColor.damagefatigue),
                                value = util.color.hex(c.effectColor.damagefatigue),
                                renderer = "color",
                        },
                        magickaDmgColor = {
                                name = 'Magicka',
                                key = 'magickaDmgColor',
                                default = util.color.hex(c.effectColor.damagemagicka),
                                value = util.color.hex(c.effectColor.damagemagicka),
                                renderer = "color",
                        },
                        fireDmgColor = {
                                name = 'Fire',
                                key = 'fireDmgColor',
                                default = util.color.hex(c.effectColor.firedamage),
                                value = util.color.hex(c.effectColor.firedamage),
                                renderer = "color",
                        },
                        frostDmgColor = {
                                name = 'Frost',
                                key = 'frostDmgColor',
                                default = util.color.hex(c.effectColor.frostdamage),
                                value = util.color.hex(c.effectColor.frostdamage),
                                renderer = "color",
                        },
                        shockDmgColor = {
                                name = 'Shock',
                                key = 'shockDmgColor',
                                default = util.color.hex(c.effectColor.shockdamage),
                                value = util.color.hex(c.effectColor.shockdamage),
                                renderer = "color",
                        },
                        poisonDmgColor = {
                                name = 'Poison',
                                key = 'poisonDmgColor',
                                default = util.color.hex(c.effectColor.poison),
                                value = util.color.hex(c.effectColor.poison),
                                renderer = "color",
                        },
                        missColor = {
                                name = 'Miss',
                                key = 'missColor',
                                default = util.color.hex(c.effectColor.miss),
                                value = util.color.hex(c.effectColor.miss),
                                renderer = "color",
                        },
                }
        },

        damageNumbers = {
                name = 'Damage Numbers',
                settings = {
                        enableDamageNumbers = {
                                name = "Enable damage Numbers",
                                key = 'enableDamageNumbers',
                                value = true,
                                default = true,
                                description = "",
                                renderer = "checkbox",
                        },
                        damageNUMSize = {
                                name = "Melee/Ranged damage text size",
                                key = 'damageNUMSize',
                                value = 24,
                                default = 24,
                                description = "default = 24",
                                renderer = "number",
                        },
                        damageNUMDuration = {
                                name = "Melee/Ranged damage text duration",
                                key = 'damageNUMDuration',
                                value = 0.6,
                                default = 0.6,
                                description = "default = 0.6",
                                renderer = "number",
                        },

                }
        },
        spellDMG = {
                name = 'Spell Damage Numbers',
                settings = {
                        enableSpellDamageNumbers = {
                                key = 'enableSpellDamageNumbers',
                                value = true,
                                default = true,
                                name = "Show spell damage (experimental)",
                                description = "",
                                renderer = "checkbox",
                        },
                        enableSpellDMGSound = {
                                key = 'enableSpellDMGSound',
                                value = true,
                                default = true,
                                name = "Enable sound on spell damage",
                                description = "",
                                renderer = "checkbox",
                        },
                        spellDamageNUMSize = {
                                name = "Spell damage text size",
                                key = 'spellDamageNUMSize',
                                value = 16,
                                default = 16,
                                description = "default = 16",
                                renderer = "number",
                        },
                        spellDamageNUMDuration = {
                                name = "Spell damage text duration",
                                key = 'spellDamageNUMDuration',
                                value = 1,
                                default = 1,
                                description = "default = 1",
                                renderer = "number",
                        },
                }
        },
        cameraShake = {
                name = 'Camera Shake',
                description = "Camera shake on successful hits",
                settings = {
                        enableCamShakeOnHit = {
                                key = 'enableCamShakeOnHit',
                                value = true,
                                default = true,
                                name = "Enable camera shake on hit",
                                description = "",
                                renderer = "checkbox",
                        },
                        enableCamShakeOnKill = {
                                key = 'enableCamShakeOnKill',
                                value = true,
                                default = true,
                                name = "Enable camera shake on kill",
                                description = "",
                                renderer = "checkbox",
                        },

                        camShakeIntensity = {
                                key = 'camShakeIntensity',
                                name = "Camera shake intensity",
                                value = 0.015,
                                default = 0.015,
                                renderer = "number",
                                description = 'default = 0.015',
                                argument = {
                                        min = 0,
                                        integer = false,
                                },
                        },
                        camShakeDuration = {
                                key = 'camShakeDuration',
                                name = "Camera shake duration",
                                value = 0.12,
                                default = 0.12,
                                renderer = "number",
                                description = 'default = 0.12',
                                argument = {
                                        min = 0,
                                        integer = false,
                                },
                        },
                }
        },
        hitStop = {
                name = 'Hit Stop',
                description = "Hit stop on successful hits",
                settings = {
                        enableHitStop = {
                                key = 'enableHitStopOnHit',
                                value = true,
                                default = true,
                                name = "Enable hit stop on hit",
                                description = "",
                                renderer = "checkbox",
                        },
                        hitStopDuration = {
                                key = 'hitStopDuration',
                                value = 0.08,
                                default = 0.08,
                                name = "Hit stop duration",
                                description = 'default = 0.08 range: 0 - 1',
                                renderer = "number",
                                argument = {
                                        min = 0,
                                        max = 1,
                                        integer = false,
                                },
                        },
                }
        },
        killMessage = {
                name = 'Kill Messages',
                settings = {
                        enableKillMessage = {
                                key = 'enableKillMessage',
                                value = true,
                                default = true,
                                name = "Enable kill announce",
                                description = "",
                                renderer = "checkbox",
                        },
                        killMessageDuration = {
                                key = 'killMessageDuration',
                                value = 8,
                                default = 8,
                                name = "Kill text duration",
                                description = "default = 8",
                                renderer = "number",
                                argument = {
                                        min = 0,
                                        integer = false,
                                },
                        },
                        killMessages = {
                                key = 'killMessages',
                                value = '#ff5555ENEMY#ffffff was Slain!\n#ffffffYou have killed#ff5555 ENEMY',
                                default =
                                '#ff5555ENEMY#ffffff was Slain!\n#ffffffYou have killed#ff5555 ENEMY',
                                name = "Kill messages to display",
                                description =
                                "Each message in a new line. The word ENEMY will be replaced with the enemy name",
                                renderer = "text",
                        },
                }
        },
        killSlowMotion = {
                name = 'Kill Slow Motion',
                settings = {
                        enableKillSlow = {
                                key = 'enableKillSlow',
                                value = true,
                                default = true,
                                name = "Enable slow motion on kill",
                                description = "",
                                renderer = "checkbox",
                        },
                        slowMotionDuration = {
                                key = 'slowMotionDuration',
                                value = 0.7,
                                default = 0.7,
                                name = "Slow motion duration",
                                description = "default = 0.7",
                                renderer = "number",
                                argument = {
                                        min = 0,
                                        integer = false,
                                },
                        },
                        slowMotionScale = {
                                key = 'slowMotionScale',
                                value = 0.35,
                                default = 0.35,
                                name = "Slow motion scale",
                                description = "default: 0.35 range: 0 - 0.9",
                                renderer = "number",
                                argument = {
                                        min = 0,
                                        max = 0.9,
                                        integer = false,
                                },
                        },
                }
        },

}





for i, v in pairs(o) do
        v.key = prefix .. i
end

local sectionOLookup = {}

for i, v in pairs(o) do
        sectionOLookup[v.key] = i
end



local function getOptions(props)
        return {
                page = MOD_NAME,
                l10n = MOD_NAME,
                permanentStorage = true,
                key = props.key,
                name = props.name,
                description = props.description,
                settings = {}
        }
end

local damageColorsGroup = getOptions(o.damageColors)
damageColorsGroup.settings = {
        o.damageColors.settings.healthDmgColor,
        o.damageColors.settings.fatigueDmgColor,
        o.damageColors.settings.magickaDmgColor,
        o.damageColors.settings.fireDmgColor,
        o.damageColors.settings.frostDmgColor,
        o.damageColors.settings.shockDmgColor,
        o.damageColors.settings.poisonDmgColor,
        o.damageColors.settings.missColor,
}
I.Settings.registerGroup(damageColorsGroup)

local damageNumbersGroup = getOptions(o.damageNumbers)
damageNumbersGroup.settings = {
        o.damageNumbers.settings.enableDamageNumbers,
        o.damageNumbers.settings.damageNUMSize,
        o.damageNumbers.settings.damageNUMDuration,

        -- o.damageNumbers.settings.damageNUMColor,
}
I.Settings.registerGroup(damageNumbersGroup)

local spellDMGGroup = getOptions(o.spellDMG)
spellDMGGroup.settings = {
        o.spellDMG.settings.enableSpellDamageNumbers,
        o.spellDMG.settings.enableSpellDMGSound,

        o.spellDMG.settings.spellDamageNUMSize,
        o.spellDMG.settings.spellDamageNUMDuration,
}
I.Settings.registerGroup(spellDMGGroup)


local hitStopGroup = getOptions(o.hitStop)
hitStopGroup.settings = {
        o.hitStop.settings.enableHitStop,
        o.hitStop.settings.hitStopDuration,
}
I.Settings.registerGroup(hitStopGroup)

local camShakeGroup = getOptions(o.cameraShake)
camShakeGroup.settings = {
        o.cameraShake.settings.enableCamShakeOnHit,
        o.cameraShake.settings.enableCamShakeOnKill,
        o.cameraShake.settings.camShakeIntensity,
        o.cameraShake.settings.camShakeDuration,
}
I.Settings.registerGroup(camShakeGroup)



local killSlowMotionGroup = getOptions(o.killSlowMotion)
killSlowMotionGroup.settings = {
        o.killSlowMotion.settings.enableKillSlow,
        o.killSlowMotion.settings.slowMotionScale,
        o.killSlowMotion.settings.slowMotionDuration,
}
I.Settings.registerGroup(killSlowMotionGroup)


local killMessageGroup = getOptions(o.killMessage)
killMessageGroup.settings = {
        o.killMessage.settings.enableKillMessage,
        o.killMessage.settings.killMessageDuration,
        o.killMessage.settings.killMessages,
}
I.Settings.registerGroup(killMessageGroup)



I.Settings.registerPage {
        key = MOD_NAME,
        l10n = MOD_NAME,
        name = 'Hit/Kill Feedback',
        description = 'Hit/Kill Feedback'
}

return { o = o, sectionOLookup = sectionOLookup }
