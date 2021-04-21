local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

local spellIds = {
    spiritSeeker = "OJ_ED_SpiritSeeker",
    heartbeat = "detect_creature",
    necromancersFeast = "OJ_ED_NecromancersFeast",
    thiefsInstinct = "detect_key",
    notorgosEscapeRoute = "OJ_ED_NotorgosEscapeRoute",
    ilverisWaryEye = "OJ_ED_IlverisWaryEye",
    fphyggisSoulFinder = "detect enchantment",
    sothasLostServant = "OJ_ED_SothasLostServant",
    auraWhisper = "OJ_ED_AuraWhisper",
    beggarsNose = "beggar's nose spell"
}

local distributions = {
    ["llaalam madalas"] = {
        spellIds.heartbeat,
        spellIds.necromancersFeast,
        spellIds.notorgosEscapeRoute,
        spellIds.ilverisWaryEye,
        spellIds.sothasLostServant,
        spellIds.auraWhisper
    },
    ["felara andrethi"] = {
        spellIds.heartbeat,
        spellIds.necromancersFeast,
        spellIds.ilverisWaryEye
    },
    ["lloros sarano"] = {
        spellIds.spiritSeeker,
        spellIds.notorgosEscapeRoute,
        spellIds.ilverisWaryEye,
        spellIds.fphyggisSoulFinder
    },
    ["llathyno hlaalu"] = {
        spellIds.spiritSeeker,
        spellIds.notorgosEscapeRoute
    },
    ["eldrilu dalen"] = {
        spellIds.spiritSeeker,
        spellIds.ilverisWaryEye
    },
    ["relms gilvilo"] = {
        spellIds.spiritSeeker,
        spellIds.sothasLostServant
    },
    ["nilvyn drothan"] = {
        spellIds.heartbeat,
        spellIds.sothasLostServant
    },
    ["minninbi selkin-adda"] = {
        spellIds.heartbeat,
        spellIds.notorgosEscapeRoute
    },
    ["namanian facian"] = {
        spellIds.notorgosEscapeRoute
    },
    ["llaros uvayn"] = {
        spellIds.notorgosEscapeRoute
    },
    ["sonummu zabamat"] = {
        spellIds.spiritSeeker,
        spellIds.ilverisWaryEye
    },
    ["orrent geontene"] = {
        spellIds.notorgosEscapeRoute,
        spellIds.sothasLostServant
    },
    ["sirilonwe"] = {
        spellIds.fphyggisSoulFinder,
        spellIds.auraWhisper
    },
    ["sharn gra-muzgob"] = {
        spellIds.necromancersFeast
    },
    ["gildan"] = {
        spellIds.thiefsInstinct,
        spellIds.notorgosEscapeRoute
    },
    ["dulian"] = {
        spellIds.spiritSeeker,
        spellIds.ilverisWaryEye,
        spellIds.sothasLostServant
    },
    ["nebia amphia"] = {
        spellIds.spiritSeeker
    },
    ["lalatia varian"] = {
        spellIds.spiritSeeker,
        spellIds.auraWhisper
    },
    ["leles birian"] = {
        spellIds.notorgosEscapeRoute,
        spellIds.auraWhisper
    },
    ["idonea munia"] = {
        spellIds.sothasLostServant
    },
    ["onlyhestandsthere"] = {
        spellIds.necromancersFeast,
        spellIds.thiefsInstinct,
        spellIds.sothasLostServant
    },
    ["j'rasha"] = {
        spellIds.spiritSeeker,
        spellIds.thiefsInstinct,
        spellIds.ilverisWaryEye
    },
    ["Jeanne Andre"] = {
        spellIds.spiritSeeker,
        spellIds.thiefsInstinct,
        spellIds.fphyggisSoulFinder
    },
    ["bronrod_the_roarer"] = {
        spellIds.heartbeat
    },
    ["todd"] = {
        spellIds.spiritSeeker,
        spellIds.heartbeat,
        spellIds.necromancersFeast,
        spellIds.thiefsInstinct,
        spellIds.notorgosEscapeRoute,
        spellIds.ilverisWaryEye,
        spellIds.fphyggisSoulFinder,
        spellIds.sothasLostServant,
        spellIds.auraWhisper
    }
}

local function registerSpells()
    framework.spells.createBasicSpell({
        id = spellIds.spiritSeeker,
        name = "Spirit Seeker",
        effect = tes3.effect.detectUndead,
        range = tes3.effectRange.self,
        magickaCost = 10,
        duration = 10,
        min = 30,
        max = 30
    })
    framework.spells.createComplexSpell({
        id = spellIds.heartbeat,
        name = "Detect Creature",
        magickaCost = 10,
        effects = {
            [1] = {
                id = tes3.effect.detectAnimal,
                range = tes3.effectRange.self,
                duration = 10,
                min = 100,
                max = 100
            },
            [2] = {
                id = tes3.effect.detectHumanoid,
                range = tes3.effectRange.self,
                duration = 10,
                min = 100,
                max = 100
            },
        }
    })
    framework.spells.createComplexSpell({
        id = spellIds.necromancersFeast,
        name = "Necromancer's Feast",
        magickaCost = 15,
        effects = {
            [1] = {
                id = tes3.effect.detectDead,
                range = tes3.effectRange.self,
                duration = 10,
                min = 100,
                max = 100
            },
            [2] = {
                id = tes3.effect.detectUndead,
                range = tes3.effectRange.self,
                duration = 10,
                min = 100,
                max = 100
            },
        }
    })
    framework.spells.createComplexSpell({
        id = spellIds.thiefsInstinct,
        name = "Detect Key",
        magickaCost = 15,
        effects = {
            [1] = {
                id = tes3.effect.detectKey,
                range = tes3.effectRange.self,
                duration = 10,
                min = 10,
                max = 10
            },
            [2] = {
                id = tes3.effect.detectTrap,
                range = tes3.effectRange.self,
                duration = 10,
                min = 10,
                max = 10
            },
        }
    })
    framework.spells.createBasicSpell({
        id = spellIds.notorgosEscapeRoute,
        name = "Notorgo's Escape Route",
        effect = tes3.effect.detectDoor,
        range = tes3.effectRange.self,
        magickaCost = 15,
        duration = 30,
        min = 100,
        max = 100
    })
    framework.spells.createBasicSpell({
        id = spellIds.ilverisWaryEye,
        name = "Ilveri's Wary Eye",
        effect = tes3.effect.detectDaedra,
        range = tes3.effectRange.self,
        magickaCost = 15,
        duration = 10,
        min = 100,
        max = 100
    })
    framework.spells.createBasicSpell({
        id = spellIds.fphyggisSoulFinder,
        name = "Detect Enchantment",
        effect = tes3.effect.detectEnchantment,
        range = tes3.effectRange.self,
        magickaCost = 15,
        duration = 10,
        min = 10,
        max = 10
    })
    framework.spells.createBasicSpell({
        id = spellIds.sothasLostServant,
        name = "Sotha's Lost Servant",
        effect = tes3.effect.detectAutomaton,
        range = tes3.effectRange.self,
        magickaCost = 15,
        duration = 10,
        min = 100,
        max = 100
    })
    framework.spells.createComplexSpell({
        id = spellIds.auraWhisper,
        name = "Aura Whisper",
        magickaCost = 50,
        effects = {
            [1] = {
                id = tes3.effect.detectAutomaton,
                range = tes3.effectRange.self,
                duration = 10,
                min = 150,
                max = 150
            },
            [2] = {
                id = tes3.effect.detectDaedra,
                range = tes3.effectRange.self,
                duration = 10,
                min = 150,
                max = 150
            },
            [3] = {
                id = tes3.effect.detectUndead,
                range = tes3.effectRange.self,
                duration = 10,
                min = 150,
                max = 150
            },
            [4] = {
                id = tes3.effect.detectAnimal,
                range = tes3.effectRange.self,
                duration = 10,
                min = 150,
                max = 150
            },
            [5] = {
                id = tes3.effect.detectHumanoid,
                range = tes3.effectRange.self,
                duration = 10,
                min = 150,
                max = 150
            },
        }
    })
    framework.spells.createComplexSpell({
        id = spellIds.beggarsNose,
        name = "Beggar's Nose",
        magickaCost = 10,
        effects = {
            [1] = {
                id = tes3.effect.detectDoor,
                range = tes3.effectRange.self,
                duration = 30,
                min = 150,
                max = 150
            },
            [2] = {
                id = tes3.effect.detectTrap,
                range = tes3.effectRange.self,
                duration = 30,
                min = 150,
                max = 150
            },
            [3] = {
                id = tes3.effect.detectKey,
                range = tes3.effectRange.self,
                duration = 30,
                min = 150,
                max = 150
            }
        }
    })

    for npcId, distributionSpellIds in pairs(distributions) do
        local npc = tes3.getObject(npcId)
        if (npc) then
            if (type(distributionSpellIds) ~= "table") then
                local spell = tes3.getObject(distributionSpellIds)
                if (spell) then
                    npc.spells:add(spell)
                end
            else
                for _, spellId in pairs(distributionSpellIds) do
                    local spell = tes3.getObject(spellId)
                    if (spell) then
                        npc.spells:add(spell)
                    end
                end
            end
        end
    end
end
event.register("MagickaExpanded:Register", registerSpells)
