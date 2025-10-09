local util = require('openmw.util')
local I = require("openmw.interfaces")
local ui = require("openmw.ui")
local async = require("openmw.async")

local MOD_NAME = 'HitKillFeedBack'
local prefix = 'SettingsPlayer'
local o = {
        damageNumbers = {
                name = 'Damage Numbers',
                settings = {
                        enableDamageNumbers = {
                                key = 'enableDamageNumbers',
                                value = true,
                                default = true,
                                name = "Enable damage Numbers",
                                description = "",
                                renderer = "checkbox",
                        },
                        damageNUMSize = {
                                key = 'damageNUMSize',
                                value = 16,
                                default = 16,
                                name = "Damage numbers text size",
                                description = "default = 16",
                                renderer = "number",
                        },
                        damageNUMDuration = {
                                key = 'damageNUMDuration',
                                value = 1,
                                default = 1,
                                name = "Damage numbers duration",
                                description = "default = 1",
                                renderer = "number",
                        },
                        damageNUMColor = {
                                key = 'damageNUMColor',
                                value = util.color.hex('ff5555'),
                                default = util.color.hex('ff5555'),
                                description = 'default = ff5555',
                                name = "Damage numbers color",
                                renderer = "color",
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
                        camShakeYaw = {
                                key = 'camShakeYaw',
                                value = 0.05,
                                default = 0.05,
                                name = "Screen shake yaw",
                                renderer = "number",
                                description = 'default = 0.05',
                                argument = {
                                        min = 0,
                                        integer = false,
                                },
                        },
                        camShakeRoll = {
                                key = 'camShakeRoll',
                                value = 0.05,
                                default = 0.05,
                                name = "Screen shake roll",
                                renderer = "number",
                                description = 'default = 0.05',
                                argument = {
                                        min = 0,
                                        integer = false,
                                },
                        },
                        camShakePitch = {
                                key = 'camShakePitch',
                                value = 0.05,
                                default = 0.05,
                                name = "Screen shake pitch",
                                renderer = "number",
                                description = 'default = 0.05',
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
                                argument = {
                                        test = 'This is the arg from settings'
                                },
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

-- NO ORDER
-- for _, props in pairs(o) do
--         local group = {
--                 page = MOD_NAME,
--                 l10n = MOD_NAME,
--                 permanentStorage = false,
--                 key = props.key,
--                 name = props.name,
--                 description = props.description,
--                 settings = {}
--         }
--         for _, v in pairs(props.settings) do
--                 table.insert(group.settings, v)
--         end

--         I.Settings.registerGroup(group)
-- end

local function getOptions(props)
        return {
                page = MOD_NAME,
                l10n = MOD_NAME,
                permanentStorage = false,
                key = props.key,
                name = props.name,
                description = props.description,
                settings = {}
        }
end

local damageNumbersGroup = getOptions(o.damageNumbers)
damageNumbersGroup.settings = {
        o.damageNumbers.settings.enableDamageNumbers,
        o.damageNumbers.settings.damageNUMSize,
        o.damageNumbers.settings.damageNUMDuration,
        o.damageNumbers.settings.damageNUMColor,
}
I.Settings.registerGroup(damageNumbersGroup)

local spellDMGGroup = getOptions(o.spellDMG)
spellDMGGroup.settings = {
        o.spellDMG.settings.enableSpellDamageNumbers,
        o.spellDMG.settings.enableSpellDMGSound,
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
        o.cameraShake.settings.camShakeYaw,
        o.cameraShake.settings.camShakeRoll,
        o.cameraShake.settings.camShakePitch,
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
