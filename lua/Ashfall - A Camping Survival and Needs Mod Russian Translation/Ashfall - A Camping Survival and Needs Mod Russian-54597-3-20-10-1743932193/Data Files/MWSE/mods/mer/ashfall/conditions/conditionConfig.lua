local Condition = require("mer.ashfall.conditions.Condition")

---@class Ashfall.Conditions
local conditions = {}

conditions.hunger = Condition:new{
    id = "hunger",
    default = "wellFed",
    showMessageOption = "showHunger",
    enableOption = "enableHunger",
    min = 0,
    max = 100,
    minDebuffState = "hungry",
    states = {
        starving = {
            text = "Изголодался",
            min = 80, max = 100,
            spell = "fw_h_starving",
            effects = {
                { id = tes3.effect.drainAttribute, attribute = tes3.attribute.agility, amount = 0.5 }
            }
        },
        veryHungry = {
            text = "Очень голоден",
            min = 60, max = 80,
            spell = "fw_h_veryHungry",
            effects = {
                { id = tes3.effect.drainAttribute, attribute = tes3.attribute.agility, amount = 0.3 }
            }
        },
        hungry = {
            text = "Голоден",
            min = 40, max = 60,
            spell = "fw_h_hungry",
            effects = {
                { id = tes3.effect.drainAttribute, attribute = tes3.attribute.agility, amount = 0.1 }
            }
        },
        peckish = {
            text = "Легкий голод",
            min = 20, max = 40,
            spell = "fw_h_peckish",
            effects = {
                { id = tes3.effect.drainAttribute, attribute = tes3.attribute.agility, amount = 0.05 }
            }
        },
        wellFed = {
            text = "Сыт",
            min = 0, max = 20,
            spell = "fw_h_wellFed",
            effects = {
                { id = tes3.effect.fortifyAttribute, attribute = tes3.attribute.agility, amount = 0.1 }
            }
        },
    },
}

conditions.thirst = Condition:new{
    id = "thirst",
    default = "hydrated",
    showMessageOption = "showThirst",
    enableOption = "enableThirst",
    min = 0,
    max = 100,
    minDebuffState = "veryThirsty",
    states = {
        dehydrated = {
            text = "Обезвоженность",
            min = 80, max = 100,
            spell = "fw_t_dehydrated",
            effects = {
                { id = tes3.effect.drainAttribute, attribute = tes3.attribute.willpower, amount = 0.5 }
            }
        },
        parched = {
            text = "Сильная жажда",
            min = 60, max = 80,
            spell = "fw_t_parched",
            effects = {
                { id = tes3.effect.drainAttribute, attribute = tes3.attribute.willpower, amount = 0.3 }
            }
        },
        veryThirsty = {
            text = "Жажда",
            min = 40, max = 60,
            spell = "fw_t_veryThirsty",
            effects = {
                { id = tes3.effect.drainAttribute, attribute = tes3.attribute.willpower, amount = 0.1 }
            }
        },
        thirsty = {
            text = "Легкая жажда",
            min = 20, max = 40,
            spell = "fw_t_thirsty",
            effects = {
                { id = tes3.effect.drainAttribute, attribute = tes3.attribute.willpower, amount = 0.05 }
            }
        },
        hydrated = {
            text = "Норма",
            min = 0, max = 20,
            spell = "fw_t_hydrated",
            effects = {
                { id = tes3.effect.fortifyAttribute, attribute = tes3.attribute.willpower, amount = 0.1 }
            }
        },
    },
}

conditions.tiredness = Condition:new{
    id = "tiredness",
    default = "rested",
    showMessageOption = "showTiredness",
    enableOption = "enableTiredness",
    min = 0,
    max = 100,
    minDebuffState = "veryTired",
    states = {
        exhausted = {
            text = "Измучен",
            min = 80, max = 100,
            spell = "fw_s_exhausted",
            effects = {
                { id = tes3.effect.drainAttribute, attribute = tes3.attribute.intelligence, amount = 0.5 },
                { id = tes3.effect.weaknesstoCommonDisease, amount = 80}
            }
        },
        veryTired = {
            text = "Очень устал",
            min = 60, max = 80,
            spell = "fw_s_veryTired",
            effects = {
                { id = tes3.effect.drainAttribute, attribute = tes3.attribute.intelligence, amount = 0.3 },
                { id = tes3.effect.weaknesstoCommonDisease, amount = 40}
            }
        },
        tired = {
            text = "Устал",
            min = 40, max = 60,
            spell = "fw_s_tired",
            effects = {
                { id = tes3.effect.drainAttribute, attribute = tes3.attribute.intelligence, amount = 0.1 },
                { id = tes3.effect.weaknesstoCommonDisease, amount = 10}
            }
        },
        rested = {
            text = "Отдохнул",
            min = 20, max = 40,
        },
        wellRested = {
            text = "Бодр",
            min = 0, max = 20,
            spell = "fw_s_wellRested",
            effects = {
                { id = tes3.effect.fortifyFatigue, amount = 0.1 }
            }
        },
    },
}

conditions.temp = Condition:new{
    id = "temp",
    default = "comfortable",
    showMessageOption = "showTemp",
    enableOption = "enableTemperatureEffects",
    min = -100,
    max = 100,
    states = {
        scorching = {
            text = "Палящий зной",
            min = 80, max = 100,
            spell = "fw_cond_scorching",
            effects = {
                { id = tes3.effect.drainAttribute, attribute = tes3.attribute.endurance, amount = 0.3 },
                { id = tes3.effect.drainAttribute, attribute = tes3.attribute.strength, amount = 0.1 }
            }
        },
        veryHot = {
            text = "Очень жарко",
            min = 60, max = 80,
            spell = "fw_cond_very_hot",
            effects = {
                { id = tes3.effect.drainAttribute, attribute = tes3.attribute.endurance, amount = 0.2 }
            }
        },
        hot = {
            text = "Жарко",
            min = 40, max = 60,
            spell = "fw_cond_hot",
            effects = {
                { id = tes3.effect.drainAttribute, attribute = tes3.attribute.endurance, amount = 0.1 }
            }
        },
        warm = {
            text = "Тепло",
            min = 20, max = 40,
            spell = "fw_cond_warm",
            effects = {
                { id = tes3.effect.fortifyAttribute, attribute = tes3.attribute.endurance, amount = 0.05 },
                { id = tes3.effect.fortifyAttribute, attribute = tes3.attribute.willpower, amount = 0.05 },
            }
        },
        comfortable = {
            text = "Комфортно",
            min = -20, max = 20,
        },
        chilly = {
            text = "Прохладно",
            min = -40, max = -20,
            spell = "fw_cond_chilly",
            effects = {
                { id = tes3.effect.drainAttribute, attribute = tes3.attribute.speed, amount = 0.2 }
            }
        },
        cold = {
            text = "Холодно",
            min = -60, max = -40,
            spell = "fw_cond_cold",
            effects = {
                { id = tes3.effect.drainAttribute, attribute = tes3.attribute.speed, amount = 0.4 }
            }
        },
        veryCold = {
            text = "Очень холодно",
            min = -80, max = -60,
            spell = "fw_cond_very_cold",
            effects = {
                { id = tes3.effect.drainAttribute, attribute = tes3.attribute.speed, amount = 0.6 }
            }
        },
        freezing = {
            text = "Замерзание",
            min = -100, max = -80,
            spell = "fw_cond_freezing",
            effects = {
                { id = tes3.effect.drainAttribute, attribute = tes3.attribute.speed, amount = 0.8 }
            }
        }
    },
}

conditions.wetness = Condition:new{
    id = "wetness",
    default = "dry",
    showMessageOption = "showWetness",
    enableOption = "enableTemperatureEffects",
    min = 0,
    max = 100,
    states = {
        soaked  =   { text = "Промокший"   , min = 75, max = 100   , spell = "fw_wetcond_soaked"  },
        wet     =   { text = "Мокрый"      , min = 50, max = 75    , spell = "fw_wetcond_wet"     },
        damp    =   { text = "Влажный"     , min = 25, max = 50    , spell = "fw_wetcond_damp"    },
        dry     =   { text = "Сухой"      , min = 0, max = 25     , spell = nil               }
    },
}

conditions.foodPoison = Condition:new{
    id = "foodPoison",
    default = "healthy",
    showMessageOption = "showSickness",
    enableOption = "enableSickness",
    min = 0,
    max = 100,
    states = {
        sick = {
            text = "Вы заразились пищевым отравлением.",
            sound = "ashfall_gurgle_01",
            min = 80,
            max = 100,
            spell = "ashfall_d_foodPoison",
            effects = {
                { id = tes3.effect.drainAttribute, attribute = tes3.attribute.strength, amount = 0.2 },
            }
        },
        healthy = { text = "Вы излечились от пищевого отравления.", min = 0, max = 80, spell = nil }
    },
    getCurrentStateMessage = function(self)
        return self:getCurrentStateData().text
    end
}

conditions.dysentery = Condition:new{
    id = "dysentery",
    default = "healthy",
    showMessageOption = "showSickness",
    enableOption = "enableSickness",
    min = 0,
    max = 100,
    states = {
        sick = {
            text = "Вы заразились дизентерией",
            sound = "ashfall_gurgle_02",
            min = 80,
            max = 100,
            spell = "ashfall_d_dysentry",
            effects = {
                { id = tes3.effect.drainAttribute, attribute = tes3.attribute.speed, amount = 0.2 },
                { id = tes3.effect.drainAttribute, attribute = tes3.attribute.willpower, amount = 0.2 },
            }
        },
        healthy = { text = "Вы излечились от дизентерии.", min = 0, max = 80, spell = nil }
    },
    getCurrentStateMessage = function(self)
        return self:getCurrentStateData().text
    end
}


conditions.blightness = Condition:new{
    id = "blightness",
    default = "healthy",
    showMessageOption = "showSickness",
    enableOption = "enableBlight",
    min = 0,
    max = 100,
    states = {
        sick = {
            min = 99,
            max = 100,
            blights = {
                "ash-chancre",
                "black-heart blight",
                "chanthrax blight",
                "ash woe blight",
            },
        },
        healthy = { min = 0, max = 99, spell = nil }
    },
    conditionChanged = function(self)
        local stateData =  self:getCurrentStateData()
        if stateData.blights then
            if not self:hasSpell() then
                --get blight chance for this weather
                local blightDiseaseChance = 10

                local rollForDisease = math.random(100)
                if rollForDisease < blightDiseaseChance then
                    local rollForResist = math.random(100)
                    if rollForResist > tes3.mobilePlayer.resistBlightDisease then
                        local newBlight = table.choice(stateData.blights)
                        ---@diagnostic disable-next-line
                        mwscript.addSpell({ reference = tes3.player, spell = newBlight })

                        stateData.spell = newBlight
                        self:showUpdateMessages()
                    end
                end
                self:setValue(0)
            end
        end
    end,
    getCurrentStateMessage = function(self)
        local spell = self:getCurrentSpellObj()
        if spell then
            return string.format("Вы заключили договор %s.", spell.name)
        end
    end,
    hasSpell = function(self)
        if not self.blights then
            self.blights = {}
            for spell in tes3.iterateObjects(tes3.objectType.spell) do
                ---@diagnostic disable-next-line
                if spell.castType == tes3.spellType.blight then
                    table.insert( self.blights, spell)
                end
            end
        end
        for _, blight in ipairs(self.blights) do
            if tes3.mobilePlayer:isAffectedByObject(blight) then
                return true
            end
        end
    end,
}

local fluDiseaseChance = 5
conditions.flu = Condition:new{
    id = "flu",
    default = "noFlu",
    showMessageOption = "showSickness",
    enableOption = "enableEnvironmentSickness",
    min = 0,
    max = 100,
    states = {
        hasFlu = {
            text = "Вы заболели гриппом.",
            min = 80,
            max = 100,
            spell = "ashfall_d_flu",
            effects = {
                { id = tes3.effect.drainAttribute, attribute = tes3.attribute.endurance, amount = 0.2 },
                { id = tes3.effect.drainAttribute, attribute = tes3.attribute.intelligence, amount = 0.1 },
            }
        },
        noFlu = { text = "Вы излечились от гриппа.", min = 0, max = 80, spell = nil },
    },
    conditionChanged = function(self)
        local stateData =  self:getCurrentStateData()
        if stateData.spell then
            if not self:hasSpell() then
                local doAddFlu = false
                local rollForDisease = math.random(100)
                if rollForDisease < fluDiseaseChance then
                    local rollForResist = math.random(100)
                    if rollForResist > tes3.mobilePlayer.resistCommonDisease then
                        doAddFlu = true
                    end
                end

                if doAddFlu then
                    local fluSpell = tes3.getObject(self.states.hasFlu.spell)
                    self:scaleSpellValues()
                    mwscript.addSpell({ reference = tes3.player, spell = fluSpell }) ---@diagnostic disable-line
                    self:showUpdateMessages()
                else
                    self:setValue(0)
                end
            end
        else
            if self:hasSpell() then
                ---@diagnostic disable-next-line
                mwscript.removeSpell({ reference = tes3.player, spell = tes3.getObject(self.states.hasFlu.spell) })
                tes3.messageBox("Вы излечились от гриппа.")
            end
        end
    end,
    hasSpell = function(self)
        return self:isAffected(self.states.hasFlu)
    end,
    getCurrentStateMessage = function(self)
        return self:getCurrentStateData().text
    end,
}


return conditions