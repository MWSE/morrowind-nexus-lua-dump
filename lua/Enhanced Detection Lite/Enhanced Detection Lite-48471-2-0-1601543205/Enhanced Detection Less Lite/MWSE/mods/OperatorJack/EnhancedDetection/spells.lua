local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
local config = require("OperatorJack.EnhancedDetection.config")

local spellIds = {
    thiefsInstinct = "detect_key",
    notorgosEscapeRoute = "OJ_ED_NotorgosEscapeRoute",
    beggarsNose = "beggar's nose spell"
}

local distributions = {
    ["llaalam madalas"] = {
        spellIds.notorgosEscapeRoute
    },
    ["lloros sarano"] = {
        spellIds.notorgosEscapeRoute
    },
    ["llathyno hlaalu"] = {
        spellIds.notorgosEscapeRoute
    },
    ["minninbi selkin-adda"] = {
        spellIds.notorgosEscapeRoute
    },
    ["namanian facian"] = {
        spellIds.notorgosEscapeRoute
    },
    ["llaros uvayn"] = {
        spellIds.notorgosEscapeRoute
    },
    ["orrent geontene"] = {
        spellIds.notorgosEscapeRoute
    },
    ["gildan"] = {
        spellIds.notorgosEscapeRoute
    },
    ["leles birian"] = {
        spellIds.notorgosEscapeRoute
    },
    ["todd"] = {
        spellIds.notorgosEscapeRoute
    }
}

local function registerSpells()
    if config.enableTrap then
        if config.btbgiMode then
            framework.spells.createComplexSpell({
                id = spellIds.thiefsInstinct,
                name = "Detect Key",
                magickaCost = 5,
                effects = {
                    [1] = {
                        id = tes3.effect.detectKey,
                        range = tes3.effectRange.self,
                        duration = 60,
                        min = 100,
                        max = 100
                    },
                    [2] = {
                        id = tes3.effect.detectTrap,
                        range = tes3.effectRange.self,
                        duration = 60,
                        min = 100,
                        max = 100
                    },
                }
            })
        else
            framework.spells.createComplexSpell({
                id = spellIds.thiefsInstinct,
                name = "Detect Key",
                magickaCost = 15,
                effects = {
                    [1] = {
                        id = tes3.effect.detectKey,
                        range = tes3.effectRange.self,
                        duration = 5,
                        min = 50,
                        max = 50
                    },
                    [2] = {
                        id = tes3.effect.detectTrap,
                        range = tes3.effectRange.self,
                        duration = 5,
                        min = 50,
                        max = 50
                    },
                }
            })
        end
    end

    if config.enableDoor then
        if config.btbgiMode then
            framework.spells.createBasicSpell({
                id = spellIds.notorgosEscapeRoute,
                name = "Notorgo's Escape Route",
                effect = tes3.effect.detectDoor,
                range = tes3.effectRange.self,
                magickaCost = 5,
                duration = 60,
                min = 100,
                max = 100
            })
        else
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
        end
    end

    if config.enableTrap and not config.btbgiMode then
        framework.spells.createComplexSpell({
            id = spellIds.beggarsNose,
            name = "Beggar's Nose",
            magickaCost = 5,
            effects = {
                [1] = {
                    id = tes3.effect.detectAnimal,
                    range = tes3.effectRange.self,
                    duration = 60,
                    min = 200,
                    max = 200
                },
                [2] = {
                    id = tes3.effect.detectEnchantment,
                    range = tes3.effectRange.self,
                    duration = 60,
                    min = 200,
                    max = 200
                },
                [3] = {
                    id = tes3.effect.detectKey,
                    range = tes3.effectRange.self,
                    duration = 60,
                    min = 200,
                    max = 200
                },
                [4] = {
                    id = tes3.effect.detectTrap,
                    range = tes3.effectRange.self,
                    duration = 60,
                    min = 200,
                    max = 200
                }
            }
        })
    end

    if config.enableDoor then
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
end

event.register("MagickaExpanded:Register", registerSpells)