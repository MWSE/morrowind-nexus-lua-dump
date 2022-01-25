local me = include("OperatorJack.MagickaExpanded.magickaExpanded")
local common = require('ss20.common')
local config = common.config
tes3.claimSpellEffectId(config.manipulateEffectId, 8113)
tes3.claimSpellEffectId(config.shrineTeleportEffectId, 8114)

local function registerEffects()
    if me then
        me.effects.alteration.createBasicEffect{
            id = tes3.effect[config.manipulateEffectId],
            name = config.manipulateEffectName,
            baseCost = 0,
            hasNoMagnitude = true,
            hasNoDuration = true,
            canCastSelf = true,
            icon = "ss20\\ss20_i_soul_manip.tga",
        }

        me.effects.mysticism.createBasicTeleportationEffect({
            id = tes3.effect[config.shrineTeleportEffectId],
            name = config.shrineTeleportEffectName,
            description = " ",
            baseCost = 0,
            positionCell = {
                cell = config.shrineCellId,
                orientation = {x=0,y=0,z=0},
                position = {0, 0, 38},
            }
        })
    end
end
event.register("magicEffectsResolved", registerEffects)

local function checkMeInstalled()
    if not me then
        common.messageBox{
            header = "Magicka Expanded Required",
            message = string.format("You need to install the Magicka Expanded framework in order to play %s.", config.modName),
            buttons = {
                {
                    text = "Exit Morrowind and go to Nexus Page",
                    callback = function()
                        os.execute("start https://www.nexusmods.com/morrowind/mods/47111")
                        os.exit()
                    end
                },
                { text = "Cancel"}
            }
        }
    end
end
event.register("loaded", checkMeInstalled)

local function registerSpells()
    local manipulationSpell = me.spells.createBasicSpell{
        id = config.manipulateSpellId,
        name = config.manipulateSpellName,
        effect = tes3.effect[config.manipulateEffectId],
        magickaCost = 0
    }
    manipulationSpell.alwaysSucceeds = true


    local shrineTeleportSpell = me.spells.createBasicSpell({
        id = config.shrineTeleportSpellId,
        name = config.shrineTeleportEffectName,
        effect = tes3.effect[config.shrineTeleportEffectId],
        range = tes3.effectRange.touch,
        radius = 5
      })
      shrineTeleportSpell.alwaysSucceeds = true
end
event.register("MagickaExpanded:Register", registerSpells)