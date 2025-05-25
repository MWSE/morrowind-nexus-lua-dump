local config = require("companionLeveler.config")
local tables = require("companionLeveler.tables")
local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.functions.common")


local this = {}

--
----NPC Spells--------------------------------------------------------------------------------------------------------------------------
--
function this.spellRoll(schools, skills, companionRef)
    log = logger.getLogger("Companion Leveler")
    local name = companionRef.object.name
    local modData = func.getModData(companionRef)
    for i = 1, 6 do
        --Choose School
        if schools[i] == true then
            if math.random(0, 99) < config.spellChance then
                --Check Skill
                if skills[i] >= 15 then
                    local table = tables.spellTables[i][1]

                    if skills[i] >= 40 then
                        table = tables.spellTables[i][2]
                    end
                    if skills[i] >= 75 then
                        table = tables.spellTables[i][3]
                    end
                    if skills[i] >= 100 then
                        table = tables.spellTables[i][4]
                    end

                    --Learn Spell
                    local iterations = 0
                    repeat
                        local spell = math.random(1, #table)
                        log:trace("Spell #" .. spell .. " in school " .. i .. ".")
                        local learned = table[spell]
                        local found = false
                        for n = 1, #modData.unusedSpells do
                            if tes3.getObject(learned).id == tes3.getObject(modData.unusedSpells[n]).id then
                                found = true
                                break
                            end
                        end
                        local wasAdded = false
                        iterations = iterations + 1
                        if found == false then
                            wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                            if wasAdded == true then
                                tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                                log:debug("Spell roll succeeded. Spell " .. learned .. " added to " .. name .. ".")
                                if i == 1 then
                                    tes3.playSound({ sound = "restoration area" })
                                elseif i == 2 then
                                    tes3.playSound({ sound = "shock cast" })
                                elseif i == 3 then
                                    tes3.playSound({ sound = "alteration hit" })
                                elseif i == 4 then
                                    tes3.playSound({ sound = "conjuration area" })
                                elseif i == 5 then
                                    tes3.playSound({ sound = "illusion hit" })
                                elseif i == 6 then
                                    tes3.playSound({ sound = "mysticism area" })
                                end
                            else
                                log:trace("Spell roll failed on " .. name .. ".")
                            end
                        end
                    until (wasAdded == true or iterations == 75)
                end
            end
        end
    end
end

--
----Creature Spells----------------------------------------------------------------------------------------------------------------------------------
--
function this.creatureSpellRoll(level, cType, companionRef)
    log = logger.getLogger("Companion Leveler")
    local name = companionRef.object.name
    local modData = func.getModData(companionRef)

    if cType == "Normal" then
        local iterations = 0
        if level < 10 then
            repeat
                local normSpell = math.random(1, #tables.normalTable1)
                log:trace("Normal Spell Table 1, #" .. normSpell .. ".")
                local learned = tables.normalTable1[normSpell]
                local found = false
                for n = 1, #modData.unusedSpells do
                    if tes3.getObject(learned).id == tes3.getObject(modData.unusedSpells[n]).id then
                        found = true
                        break
                    end
                end
                local wasAdded = false
                iterations = iterations + 1
                if not found then
                    wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned the skill " .. learned .. "!")
                        log:info("" .. name .. " learned the spell " .. learned .. ".")
                        tes3.playSound({ sound = "alitMOAN" })
                    else
                        log:debug("Normal spell roll failed on " .. name .. ".")
                    end
                end
            until (wasAdded == true or iterations == 10)
        else
            repeat
                local normSpell = math.random(1, #tables.normalTable2)
                log:trace("Normal Spell Table 2, #" .. normSpell .. ".")
                local learned = tables.normalTable2[normSpell]
                local found = false
                for n = 1, #modData.unusedSpells do
                    if tes3.getObject(learned).id == tes3.getObject(modData.unusedSpells[n]).id then
                        found = true
                        break
                    end
                end
                local wasAdded = false
                iterations = iterations + 1
                if not found then
                    wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned the skill " .. learned .. "!")
                        log:info("" .. name .. " learned the spell " .. learned .. ".")
                        tes3.playSound({ sound = "alitMOAN" })
                    else
                        log:debug("Normal spell roll failed on " .. name .. ".")
                    end
                end
            until (wasAdded == true or iterations == 20)
        end
    end
    if cType == "Daedra" then
        local iterations = 0
        if level < 10 then
            repeat
                local daeSpell = math.random(1, #tables.daedraTable1)
                log:trace("Daedric Spell Table 1, #" .. daeSpell .. ".")
                local learned = tables.daedraTable1[daeSpell]
                local found = false
                for n = 1, #modData.unusedSpells do
                    if tes3.getObject(learned).id == tes3.getObject(modData.unusedSpells[n]).id then
                        found = true
                        break
                    end
                end
                local wasAdded = false
                iterations = iterations + 1
                if not found then
                    wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:info("" .. name .. " learned to cast " .. learned .. ".")
                        tes3.playSound({ sound = "atroflame moan" })
                    else
                        log:debug("Daedric spell roll failed on " .. name .. ".")
                    end
                end
            until (wasAdded == true or iterations == 30)
        else
            repeat
                local daeSpell = math.random(1, #tables.daedraTable2)
                log:trace("Daedric Spell Table 2, #" .. daeSpell .. ".")
                local learned = tables.daedraTable2[daeSpell]
                local found = false
                for n = 1, #modData.unusedSpells do
                    if tes3.getObject(learned).id == tes3.getObject(modData.unusedSpells[n]).id then
                        found = true
                        break
                    end
                end
                local wasAdded = false
                iterations = iterations + 1
                if not found then
                    wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:info("" .. name .. " learned to cast " .. learned .. ".")
                        tes3.playSound({ sound = "atroflame moan" })
                    else
                        log:debug("Daedric spell roll failed on " .. name .. ".")
                    end
                end
            until (wasAdded == true or iterations == 60)
        end
    end
    if cType == "Undead" then
        local iterations = 0
        if level < 10 then
            repeat
                local undSpell = math.random(1, #tables.undeadTable1)
                log:trace("Undead Spell Table 1, #" .. undSpell .. ".")
                local learned = tables.undeadTable1[undSpell]
                local found = false
                for n = 1, #modData.unusedSpells do
                    if tes3.getObject(learned).id == tes3.getObject(modData.unusedSpells[n]).id then
                        found = true
                        break
                    end
                end
                local wasAdded = false
                iterations = iterations + 1
                if not found then
                    wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:info("" .. name .. " learned to cast " .. learned .. ".")
                        tes3.playSound({ sound = "skeleton roar" })
                    else
                        log:debug("Undead spell roll failed on " .. name .. ".")
                    end
                end
            until (wasAdded == true or iterations == 25)
        else
            repeat
                local undSpell = math.random(1, #tables.undeadTable2)
                log:trace("Undead Spell Table 2, #" .. undSpell .. ".")
                local learned = tables.undeadTable2[undSpell]
                local found = false
                for n = 1, #modData.unusedSpells do
                    if tes3.getObject(learned).id == tes3.getObject(modData.unusedSpells[n]).id then
                        found = true
                        break
                    end
                end
                local wasAdded = false
                iterations = iterations + 1
                if not found then
                    wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:info("" .. name .. " learned to cast " .. learned .. ".")
                        tes3.playSound({ sound = "skeleton roar" })
                    else
                        log:debug("Undead spell roll failed on " .. name .. ".")
                    end
                end
            until (wasAdded == true or iterations == 55)
        end
    end
    if cType == "Humanoid" then
        local iterations = 0
        if level < 10 then
            repeat
                local humSpell = math.random(1, #tables.humanoidTable1)
                log:trace("Humanoid Spell Table 1, #" .. humSpell .. ".")
                local learned = tables.humanoidTable1[humSpell]
                local found = false
                for n = 1, #modData.unusedSpells do
                    if tes3.getObject(learned).id == tes3.getObject(modData.unusedSpells[n]).id then
                        found = true
                        break
                    end
                end
                local wasAdded = false
                iterations = iterations + 1
                if not found then
                    wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:info("" .. name .. " learned to cast " .. learned .. ".")
                        tes3.playSound({ sound = "ash ghoul roar" })
                    else
                        log:debug("Humanoid spell roll failed on " .. name .. ".")
                    end
                end
            until (wasAdded == true or iterations == 35)
        else
            repeat
                local humSpell = math.random(1, #tables.humanoidTable2)
                log:trace("Humanoid Spell Table 2, #" .. humSpell .. ".")
                local learned = tables.humanoidTable2[humSpell]
                local found = false
                for n = 1, #modData.unusedSpells do
                    if tes3.getObject(learned).id == tes3.getObject(modData.unusedSpells[n]).id then
                        found = true
                        break
                    end
                end
                local wasAdded = false
                iterations = iterations + 1
                if not found then
                    wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:info("" .. name .. " learned to cast " .. learned .. ".")
                        tes3.playSound({ sound = "ash ghoul roar" })
                    else
                        log:debug("Humanoid spell roll failed on " .. name .. ".")
                    end
                end
            until (wasAdded == true or iterations == 70)
        end
    end
    if cType == "Centurion" then
        local iterations = 0
        repeat
            local cenSpell = math.random(1, #tables.centurionTable)
            log:trace("Centurion Spell Table 1, #" .. cenSpell .. ".")
            local learned = tables.centurionTable[cenSpell]
            local found = false
            for n = 1, #modData.unusedSpells do
                if tes3.getObject(learned).id == tes3.getObject(modData.unusedSpells[n]).id then
                    found = true
                    break
                end
            end
            local wasAdded = false
            iterations = iterations + 1
            if not found then
                wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                iterations = iterations + 1
                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                    log:info("" .. name .. " learned to cast " .. learned .. ".")
                    tes3.playSound({ sound = "cent spider moan" })
                else
                    log:debug("Centurion spell roll failed on " .. name .. ".")
                end
            end
        until (wasAdded == true or iterations == 5)
    end
    if cType == "Spriggan" then
        local iterations = 0
        if level < 10 then
            repeat
                local sprSpell = math.random(1, #tables.sprigganTable1)
                log:trace("Spriggan Spell Table 1, #" .. sprSpell .. ".")
                local learned = tables.sprigganTable1[sprSpell]
                local found = false
                for n = 1, #modData.unusedSpells do
                    if tes3.getObject(learned).id == tes3.getObject(modData.unusedSpells[n]).id then
                        found = true
                        break
                    end
                end
                local wasAdded = false
                iterations = iterations + 1
                if not found then
                    wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        if learned == "BM_summonwolf" then
                            learned = "Call Wolf"
                        end
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:info("" .. name .. " learned to cast " .. learned .. ".")
                        tes3.playSound({ sound = "spriggan roar" })
                    else
                        log:debug("Spriggan spell roll failed on " .. name .. ".")
                    end
                end
            until (wasAdded == true or iterations == 35)
        else
            repeat
                local sprSpell = math.random(1, #tables.sprigganTable2)
                log:trace("Spriggan Spell Table 2, #" .. sprSpell .. ".")
                local learned = tables.sprigganTable2[sprSpell]
                local found = false
                for n = 1, #modData.unusedSpells do
                    if tes3.getObject(learned).id == tes3.getObject(modData.unusedSpells[n]).id then
                        found = true
                        break
                    end
                end
                local wasAdded = false
                iterations = iterations + 1
                if not found then
                    wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        if learned == "BM_summonwolf" then
                            learned = "Call Wolf"
                        end
                        if learned == "BM_summonbear" then
                            learned = "Call Bear"
                        end
                        if learned == "bm_summonbonewolf" then
                            learned = "Summon Bonewolf"
                        end
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:info("" .. name .. " learned to cast " .. learned .. ".")
                        tes3.playSound({ sound = "spriggan roar" })
                    else
                        log:debug("Spriggan spell roll failed on " .. name .. ".")
                    end
                end
            until (wasAdded == true or iterations == 70)
        end
    end
    if cType == "Goblin" then
        local iterations = 0
        repeat
            local gobSpell = math.random(1, #tables.goblinTable)
            log:trace("Goblin Spell Table 1, #" .. gobSpell .. ".")
            local learned = tables.goblinTable[gobSpell]
            local found = false
            for n = 1, #modData.unusedSpells do
                if tes3.getObject(learned).id == tes3.getObject(modData.unusedSpells[n]).id then
                    found = true
                    break
                end
            end
            local wasAdded = false
            iterations = iterations + 1
            if not found then
                wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                iterations = iterations + 1
                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                    log:info("" .. name .. " learned to cast " .. learned .. ".")
                    tes3.playSound({ sound = "goblin moan" })
                else
                    log:debug("Goblin spell roll failed on " .. name .. ".")
                end
            end
        until (wasAdded == true or iterations == 5)
    end
    if cType == "Spectral" then
        local iterations = 0
        if level < 10 then
            repeat
                local specSpell = math.random(1, #tables.spectralTable1)
                log:trace("Spectral Spell Table 1, #" .. specSpell .. ".")
                local learned = tables.spectralTable1[specSpell]
                local found = false
                for n = 1, #modData.unusedSpells do
                    if tes3.getObject(learned).id == tes3.getObject(modData.unusedSpells[n]).id then
                        found = true
                        break
                    end
                end
                local wasAdded = false
                iterations = iterations + 1
                if not found then
                    wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:info("" .. name .. " learned to cast " .. learned .. ".")
                        tes3.playSound({ sound = "ancestor ghost roar" })
                    else
                        log:trace("Spectral spell roll failed on " .. name .. ".")
                    end
                end
            until (wasAdded == true or iterations == 35)
        else
            repeat
                local specSpell = math.random(1, #tables.spectralTable2)
                log:trace("Spectral Spell Table 2, #" .. specSpell .. ".")
                local learned = tables.spectralTable2[specSpell]
                local found = false
                for n = 1, #modData.unusedSpells do
                    if tes3.getObject(learned).id == tes3.getObject(modData.unusedSpells[n]).id then
                        found = true
                        break
                    end
                end
                local wasAdded = false
                iterations = iterations + 1
                if not found then
                    wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:info("" .. name .. " learned to cast " .. learned .. ".")
                        tes3.playSound({ sound = "ancestor ghost roar" })
                    else
                        log:trace("Spectral spell roll failed on " .. name .. ".")
                    end
                end
            until (wasAdded == true or iterations == 60)
        end
    end
    if cType == "Insectile" then
        local iterations = 0
        if level < 10 then
            repeat
                local insSpell = math.random(1, #tables.insectileTable1)
                log:trace("Insectile Spell Table 1, #" .. insSpell .. ".")
                local learned = tables.insectileTable1[insSpell]
                local found = false
                for n = 1, #modData.unusedSpells do
                    if tes3.getObject(learned).id == tes3.getObject(modData.unusedSpells[n]).id then
                        found = true
                        break
                    end
                end
                local wasAdded = false
                iterations = iterations + 1
                if not found then
                    wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:info("" .. name .. " learned to cast " .. learned .. ".")
                        tes3.playSound({ sound = "kwamF roar" })
                    else
                        log:trace("Insectile spell roll failed on " .. name .. ".")
                    end
                end
            until (wasAdded == true or iterations == 15)
        else
            repeat
                local insSpell = math.random(1, #tables.insectileTable2)
                log:trace("Insectile Spell Table 2, #" .. insSpell .. ".")
                local learned = tables.insectileTable2[insSpell]
                local found = false
                for n = 1, #modData.unusedSpells do
                    if tes3.getObject(learned).id == tes3.getObject(modData.unusedSpells[n]).id then
                        found = true
                        break
                    end
                end
                local wasAdded = false
                iterations = iterations + 1
                if not found then
                    wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:info("" .. name .. " learned to cast " .. learned .. ".")
                        tes3.playSound({ sound = "kwamF roar" })
                    else
                        log:trace("Insectile spell roll failed on " .. name .. ".")
                    end
                end
            until (wasAdded == true or iterations == 30)
        end
    end
    if cType == "Draconic" then
        local iterations = 0
        if level > 3 then
            repeat
                local randNum = math.random(1, 6)
                local table

                if randNum == 1 then
                    table = tables.restorationTable4
                elseif randNum == 2 then
                    table = tables.destructionTable4
                elseif randNum == 3 then
                    table = tables.alterationTable4
                elseif randNum == 4 then
                    table = tables.illusionTable4
                elseif randNum == 5 then
                    table = tables.mysticismTable4
                elseif randNum == 6 then
                    table = tables.conjurationTable4
                end

                local draSpell = math.random(1, #table)
                log:trace("Draconic Spell Table, #" .. draSpell .. ".")
                local learned = table[draSpell]
                local found = false
                for n = 1, #modData.unusedSpells do
                    if tes3.getObject(learned).id == tes3.getObject(modData.unusedSpells[n]).id then
                        found = true
                        break
                    end
                end
                local wasAdded = false
                iterations = iterations + 1
                if not found then
                    wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:info("" .. name .. " learned to cast " .. learned .. ".")
                        tes3.playSound({ soundPath = "companionLeveler\\dragon_spell.wav" })
                    else
                        log:trace("Draconic spell roll failed on " .. name .. ".")
                    end
                end
            until (wasAdded == true or iterations == 15)
        end
    end
    if cType == "Aquatic" then
        local iterations = 0
        if level < 10 then
            repeat
                local aqSpell = math.random(1, #tables.aquaticTable1)
                log:trace("Aquatic Spell Table 1, #" .. aqSpell .. ".")
                local learned = tables.aquaticTable1[aqSpell]
                local found = false
                for n = 1, #modData.unusedSpells do
                    if tes3.getObject(learned).id == tes3.getObject(modData.unusedSpells[n]).id then
                        found = true
                        break
                    end
                end
                local wasAdded = false
                iterations = iterations + 1
                if not found then
                    wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:info("" .. name .. " learned to cast " .. learned .. ".")
                        tes3.playSound({ sound = "dreugh moan" })
                    else
                        log:trace("Aquatic spell roll failed on " .. name .. ".")
                    end
                end
            until (wasAdded == true or iterations == 20)
        else
            repeat
                local aqSpell = math.random(1, #tables.aquaticTable2)
                log:trace("Aquatic Spell Table 2, #" .. aqSpell .. ".")
                local learned = tables.aquaticTable2[aqSpell]
                local found = false
                for n = 1, #modData.unusedSpells do
                    if tes3.getObject(learned).id == tes3.getObject(modData.unusedSpells[n]).id then
                        found = true
                        break
                    end
                end
                local wasAdded = false
                iterations = iterations + 1
                if not found then
                    wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:info("" .. name .. " learned to cast " .. learned .. ".")
                        tes3.playSound({ sound = "dreugh moan" })
                    else
                        log:trace("Aquatic spell roll failed on " .. name .. ".")
                    end
                end
            until (wasAdded == true or iterations == 60)
        end
    end
    if cType == "Avian" then
        local iterations = 0
        if level < 10 then
            repeat
                local spell = math.random(1, #tables.avianTable1)
                log:trace("" .. cType .. " Spell Table 1, #" .. spell .. ".")
                local learned = tables.avianTable1[spell]
                local found = false
                for n = 1, #modData.unusedSpells do
                    if tes3.getObject(learned).id == tes3.getObject(modData.unusedSpells[n]).id then
                        found = true
                        break
                    end
                end
                local wasAdded = false
                iterations = iterations + 1
                if not found then
                    wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:info("" .. name .. " learned to cast " .. learned .. ".")
                        tes3.playSound({ sound = "cliff racer moan" })
                    else
                        log:trace("" .. cType .. " spell roll failed on " .. name .. ".")
                    end
                end
            until (wasAdded == true or iterations == 20)
        else
            repeat
                local spell = math.random(1, #tables.avianTable2)
                log:trace("" .. cType .. " Spell Table 2, #" .. spell .. ".")
                local learned = tables.avianTable2[spell]
                local found = false
                for n = 1, #modData.unusedSpells do
                    if tes3.getObject(learned).id == tes3.getObject(modData.unusedSpells[n]).id then
                        found = true
                        break
                    end
                end
                local wasAdded = false
                iterations = iterations + 1
                if not found then
                    wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:info("" .. name .. " learned to cast " .. learned .. ".")
                        tes3.playSound({ sound = "cliff racer moan" })
                    else
                        log:trace("" .. cType .. " spell roll failed on " .. name .. ".")
                    end
                end
            until (wasAdded == true or iterations == 45)
        end
    end
    if cType == "Bestial" then
        local iterations = 0
        if level > 5 then
            repeat
                local spell = math.random(1, #tables.bestialTable)
                log:trace("" .. cType .. " Spell Table, #" .. spell .. ".")
                local learned = tes3.getObject(tables.bestialTable[spell])
                local found = false
                for n = 1, #modData.unusedSpells do
                    if learned.id == tes3.getObject(modData.unusedSpells[n]).id then
                        found = true
                        break
                    end
                end
                local wasAdded = false
                iterations = iterations + 1
                if not found then
                    wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                        log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                        tes3.playSound({ sound = "wolf roar" })
                    else
                        log:trace("" .. cType .. " spell roll failed on " .. name .. ".")
                    end
                end
            until (wasAdded == true or iterations == 20)
        end
    end
    if cType == "Impish" then
        local iterations = 0
        repeat
            local randNum = math.random(1, 6)
            local table

            if randNum == 1 then
                table = tables.restorationTable4
            elseif randNum == 2 then
                table = tables.destructionTable4
            elseif randNum == 3 then
                table = tables.alterationTable4
            elseif randNum == 4 then
                table = tables.illusionTable4
            elseif randNum == 5 then
                table = tables.mysticismTable4
            elseif randNum == 6 then
                table = tables.conjurationTable4
            end

            local spell = math.random(1, #table)
            log:trace("Impish Spell Table, #" .. spell .. ".")
            local learned = table[spell]
            local found = false
            for n = 1, #modData.unusedSpells do
                if tes3.getObject(learned).id == tes3.getObject(modData.unusedSpells[n]).id then
                    found = true
                    break
                end
            end
            local wasAdded = false
            iterations = iterations + 1
            if not found then
                wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                iterations = iterations + 1
                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                    log:info("" .. name .. " learned to cast " .. learned .. ".")
                    tes3.playSound({ sound = "scamp moan" })
                else
                    log:trace("Impish spell roll failed on " .. name .. ".")
                end
            end
        until (wasAdded == true or iterations == 30)
    end
    if cType == "Fiery" then
        local firstLearned = false

        if level >= 3 then
            local spell = tables.fireTable[1]
            local learned = tes3.getObject(spell)
            local found = false
            for n = 1, #modData.unusedSpells do
                if learned.id == tes3.getObject(modData.unusedSpells[n]).id then
                    found = true
                    break
                end
            end
            local wasAdded = false
            if not found then
                wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                    log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                    firstLearned = true
                    tes3.playSound({ sound = "destruction cast" })
                else
                    log:trace("" .. name .. " already knows " .. spell .. ".")
                end
            end
        end
        if (level >= 7 and not firstLearned) then
            local spell = tables.fireTable[2]
            local learned = tes3.getObject(spell)
            local found = false
            for n = 1, #modData.unusedSpells do
                if learned.id == tes3.getObject(modData.unusedSpells[n]).id then
                    found = true
                    break
                end
            end
            local wasAdded = false
            if not found then
                wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                    log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                    firstLearned = true
                    tes3.playSound({ sound = "destruction cast" })
                else
                    log:trace("" .. name .. " already knows " .. spell .. ".")
                end
            end
        end
        if (level >= 12 and not firstLearned) then
            local spell = tables.fireTable[3]
            local learned = tes3.getObject(spell)
            local found = false
            for n = 1, #modData.unusedSpells do
                if learned.id == tes3.getObject(modData.unusedSpells[n]).id then
                    found = true
                    break
                end
            end
            local wasAdded = false
            if not found then
                wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                    log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                    firstLearned = true
                    tes3.playSound({ sound = "destruction cast" })
                else
                    log:trace("" .. name .. " already knows " .. spell .. ".")
                end
            end
        end
        if (level >= 18 and not firstLearned) then
            local spell = tables.fireTable[4]
            local learned = tes3.getObject(spell)
            local found = false
            for n = 1, #modData.unusedSpells do
                if learned.id == tes3.getObject(modData.unusedSpells[n]).id then
                    found = true
                    break
                end
            end
            local wasAdded = false
            if not found then
                wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                    log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                    firstLearned = true
                    tes3.playSound({ sound = "destruction cast" })
                else
                    log:trace("" .. name .. " already knows " .. spell .. ".")
                end
            end
        end
    end
    if cType == "Frozen" then
        local firstLearned = false

        if level >= 3 then
            local spell = tables.frostTable[1]
            local learned = tes3.getObject(spell)
            local found = false
            for n = 1, #modData.unusedSpells do
                if learned.id == tes3.getObject(modData.unusedSpells[n]).id then
                    found = true
                    break
                end
            end
            local wasAdded = false
            if not found then
                wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                    log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                    firstLearned = true
                    tes3.playSound({ sound = "frost_cast" })
                else
                    log:trace("" .. name .. " already knows " .. spell .. ".")
                end
            end
        end
        if (level >= 7 and not firstLearned) then
            local spell = tables.frostTable[2]
            local learned = tes3.getObject(spell)
            local found = false
            for n = 1, #modData.unusedSpells do
                if learned.id == tes3.getObject(modData.unusedSpells[n]).id then
                    found = true
                    break
                end
            end
            local wasAdded = false
            if not found then
                wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                    log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                    firstLearned = true
                    tes3.playSound({ sound = "frost_cast" })
                else
                    log:trace("" .. name .. " already knows " .. spell .. ".")
                end
            end
        end
        if (level >= 12 and not firstLearned) then
            local spell = tables.frostTable[3]
            local learned = tes3.getObject(spell)
            local found = false
            for n = 1, #modData.unusedSpells do
                if learned.id == tes3.getObject(modData.unusedSpells[n]).id then
                    found = true
                    break
                end
            end
            local wasAdded = false
            if not found then
                wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                    log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                    firstLearned = true
                    tes3.playSound({ sound = "frost_cast" })
                else
                    log:trace("" .. name .. " already knows " .. spell .. ".")
                end
            end
        end
        if (level >= 18 and not firstLearned) then
            local spell = tables.frostTable[4]
            local learned = tes3.getObject(spell)
            local found = false
            for n = 1, #modData.unusedSpells do
                if learned.id == tes3.getObject(modData.unusedSpells[n]).id then
                    found = true
                    break
                end
            end
            local wasAdded = false
            if not found then
                wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                    log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                    firstLearned = true
                    tes3.playSound({ sound = "frost_cast" })
                else
                    log:trace("" .. name .. " already knows " .. spell .. ".")
                end
            end
        end
    end
    if cType == "Galvanic" then
        local firstLearned = false

        if level >= 3 then
            local spell = tables.shockTable[1]
            local learned = tes3.getObject(spell)
            local found = false
            for n = 1, #modData.unusedSpells do
                if learned.id == tes3.getObject(modData.unusedSpells[n]).id then
                    found = true
                    break
                end
            end
            local wasAdded = false
            if not found then
                wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                    log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                    firstLearned = true
                    tes3.playSound({ sound = "shock cast" })
                else
                    log:trace("" .. name .. " already knows " .. spell .. ".")
                end
            end
        end
        if (level >= 7 and not firstLearned) then
            local spell = tables.shockTable[2]
            local learned = tes3.getObject(spell)
            local found = false
            for n = 1, #modData.unusedSpells do
                if learned.id == tes3.getObject(modData.unusedSpells[n]).id then
                    found = true
                    break
                end
            end
            local wasAdded = false
            if not found then
                wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                    log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                    firstLearned = true
                    tes3.playSound({ sound = "shock cast" })
                else
                    log:trace("" .. name .. " already knows " .. spell .. ".")
                end
            end
        end
        if (level >= 12 and not firstLearned) then
            local spell = tables.shockTable[3]
            local learned = tes3.getObject(spell)
            local found = false
            for n = 1, #modData.unusedSpells do
                if learned.id == tes3.getObject(modData.unusedSpells[n]).id then
                    found = true
                    break
                end
            end
            local wasAdded = false
            if not found then
                wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                    log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                    firstLearned = true
                    tes3.playSound({ sound = "shock cast" })
                else
                    log:trace("" .. name .. " already knows " .. spell .. ".")
                end
            end
        end
        if (level >= 18 and not firstLearned) then
            local spell = tables.shockTable[4]
            local learned = tes3.getObject(spell)
            local found = false
            for n = 1, #modData.unusedSpells do
                if learned.id == tes3.getObject(modData.unusedSpells[n]).id then
                    found = true
                    break
                end
            end
            local wasAdded = false
            if not found then
                wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                    log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                    firstLearned = true
                    tes3.playSound({ sound = "shock cast" })
                else
                    log:trace("" .. name .. " already knows " .. spell .. ".")
                end
            end
        end
    end
    if cType == "Poisonous" then
        local firstLearned = false

        if level >= 3 then
            local spell = tables.poisonTable[1]
            local learned = tes3.getObject(spell)
            local found = false
            for n = 1, #modData.unusedSpells do
                if learned.id == tes3.getObject(modData.unusedSpells[n]).id then
                    found = true
                    break
                end
            end
            local wasAdded = false
            if not found then
                wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                    log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                    firstLearned = true
                    tes3.playSound({ sound = "alteration cast" })
                else
                    log:trace("" .. name .. " already knows " .. spell .. ".")
                end
            end
        end
        if (level >= 7 and not firstLearned) then
            local spell = tables.poisonTable[2]
            local learned = tes3.getObject(spell)
            local found = false
            for n = 1, #modData.unusedSpells do
                if learned.id == tes3.getObject(modData.unusedSpells[n]).id then
                    found = true
                    break
                end
            end
            local wasAdded = false
            if not found then
                wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                    log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                    firstLearned = true
                    tes3.playSound({ sound = "alteration cast" })
                else
                    log:trace("" .. name .. " already knows " .. spell .. ".")
                end
            end
        end
        if (level >= 12 and not firstLearned) then
            local spell = tables.poisonTable[3]
            local learned = tes3.getObject(spell)
            local found = false
            for n = 1, #modData.unusedSpells do
                if learned.id == tes3.getObject(modData.unusedSpells[n]).id then
                    found = true
                    break
                end
            end
            local wasAdded = false
            if not found then
                wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                    log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                    firstLearned = true
                    tes3.playSound({ sound = "alteration cast" })
                else
                    log:trace("" .. name .. " already knows " .. spell .. ".")
                end
            end
        end
        if (level >= 18 and not firstLearned) then
            local spell = tables.poisonTable[4]
            local learned = tes3.getObject(spell)
            local found = false
            for n = 1, #modData.unusedSpells do
                if learned.id == tes3.getObject(modData.unusedSpells[n]).id then
                    found = true
                    break
                end
            end
            local wasAdded = false
            if not found then
                wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                    log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                    firstLearned = true
                    tes3.playSound({ sound = "alteration cast" })
                else
                    log:trace("" .. name .. " already knows " .. spell .. ".")
                end
            end
        end
    end
end

return this