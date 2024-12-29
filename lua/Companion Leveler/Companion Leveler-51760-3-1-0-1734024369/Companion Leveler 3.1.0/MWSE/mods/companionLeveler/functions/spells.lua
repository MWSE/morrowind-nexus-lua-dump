local config = require("companionLeveler.config")
local tables = require("companionLeveler.tables")
local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")


local this = {}

--
----NPC Spells--------------------------------------------------------------------------------------------------------------------------
--
function this.spellRoll(resto, destro, alter, conj, illu, myst, companionRef)
    log = logger.getLogger("Companion Leveler")
    local name = companionRef.object.name
    if resto == true then
        local mrValue = companionRef.mobile:getSkillStatistic(15)
        if math.random(0, 99) < config.spellChance then
            if mrValue.base >= 15 and mrValue.base < 40 then
                local iterations = 0
                repeat
                    local rSpell = math.random(1, 5)
                    log:trace("Restoration Spell #" .. rSpell .. ".")
                    local learned = tables.restorationTable[rSpell]
                    local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:debug("Spell roll succeeded. Restoration spell " .. learned .. " added to " .. name .. ".")
                        tes3.playSound({ sound = "restoration area" })
                    else
                        log:trace("Restoration spell roll failed on " .. name .. ".")
                    end
                until (wasAdded == true or iterations == 15)
            end
            if mrValue.base >= 40 and mrValue.base < 75 then
                local iterations = 0
                repeat
                    local rSpell = math.random(1, 14)
                    log:trace("Restoration Spell #" .. rSpell .. ".")
                    local learned = tables.restorationTable[rSpell]
                    local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:debug("Spell roll succeeded. Restoration spell " .. learned .. " added to " .. name .. ".")
                        tes3.playSound({ sound = "restoration area" })
                    else
                        log:trace("Restoration spell roll failed on " .. name .. ".")
                    end
                until (wasAdded == true or iterations == 30)
            end
            if mrValue.base >= 75 and mrValue.base < 100 then
                local iterations = 0
                repeat
                    local rSpell = math.random(1, 22)
                    log:trace("Restoration Spell #" .. rSpell .. ".")
                    local learned = tables.restorationTable[rSpell]
                    local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:debug("Spell roll succeeded. Restoration spell " .. learned .. " added to " .. name .. ".")
                        tes3.playSound({ sound = "restoration area" })
                    else
                        log:trace("Restoration spell roll failed on " .. name .. ".")
                    end
                until (wasAdded == true or iterations == 50)
            end
            if mrValue.base >= 100 then
                local iterations = 0
                repeat
                    local rSpell = math.random(1, 35)
                    log:trace("Restoration Spell #" .. rSpell .. ".")
                    local learned = tables.restorationTable[rSpell]
                    local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:debug("Spell roll succeeded. Restoration spell " .. learned .. " added to " .. name .. ".")
                        tes3.playSound({ sound = "restoration area" })
                    else
                        log:trace("Restoration spell roll failed on " .. name .. ".")
                    end
                until (wasAdded == true or iterations == 70)
            end
        end
    end
    if destro == true then
        local mdValue = companionRef.mobile:getSkillStatistic(10)
        if math.random(0, 99) < config.spellChance then
            if mdValue.base >= 15 and mdValue.base < 40 then
                local iterations = 0
                repeat
                    local dSpell = math.random(1, 7)
                    log:trace("Destruction Spell #" .. dSpell .. ".")
                    local learned = tables.destructionTable[dSpell]
                    local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:debug("Spell roll succeeded. Destruction spell " .. learned .. " added to " .. name .. ".")
                        tes3.playSound({ sound = "shock cast" })
                    else
                        log:trace("Destruction spell roll failed on " .. name .. ".")
                    end
                until (wasAdded == true or iterations == 15)
            end
            if mdValue.base >= 40 and mdValue.base < 75 then
                local iterations = 0
                repeat
                    local dSpell = math.random(1, 17)
                    log:trace("Destruction Spell #" .. dSpell .. ".")
                    local learned = tables.destructionTable[dSpell]
                    local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:debug("Spell roll succeeded. Destruction spell " .. learned .. " added to " .. name .. ".")
                        tes3.playSound({ sound = "shock cast" })
                    else
                        log:trace("Destruction spell roll failed on " .. name .. ".")
                    end
                until (wasAdded == true or iterations == 30)
            end
            if mdValue.base >= 75 and mdValue.base < 100 then
                local iterations = 0
                repeat
                    local dSpell = math.random(1, 27)
                    log:trace("Destruction Spell #" .. dSpell .. ".")
                    local learned = tables.destructionTable[dSpell]
                    local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:debug("Spell roll succeeded. Destruction spell " .. learned .. " added to " .. name .. ".")
                        tes3.playSound({ sound = "shock cast" })
                    else
                        log:trace("Destruction spell roll failed on " .. name .. ".")
                    end
                until (wasAdded == true or iterations == 50)
            end
            if mdValue.base >= 100 then
                local iterations = 0
                repeat
                    local dSpell = math.random(1, 35)
                    log:trace("Destruction Spell #" .. dSpell .. ".")
                    local learned = tables.destructionTable[dSpell]
                    local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:debug("Spell roll succeeded. Destruction spell " .. learned .. " added to " .. name .. ".")
                        tes3.playSound({ sound = "shock cast" })
                    else
                        log:trace("Destruction spell roll failed on " .. name .. ".")
                    end
                until (wasAdded == true or iterations == 70)
            end
        end
    end
    if alter == true then
        local maValue = companionRef.mobile:getSkillStatistic(11)
        if math.random(0, 99) < config.spellChance then
            if maValue.base >= 15 and maValue.base < 40 then
                local iterations = 0
                repeat
                    local aSpell = math.random(1, 5)
                    log:trace("Alteration Spell #" .. aSpell .. ".")
                    local learned = tables.alterationTable[aSpell]
                    local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:debug("Spell roll succeeded. Alteration spell " .. learned .. " added to " .. name .. ".")
                        tes3.playSound({ sound = "alteration hit" })
                    else
                        log:trace("Alteration spell roll failed on " .. name .. ".")
                    end
                until (wasAdded == true or iterations == 15)
            end
            if maValue.base >= 40 and maValue.base < 75 then
                local iterations = 0
                repeat
                    local aSpell = math.random(1, 12)
                    log:trace("Alteration Spell #" .. aSpell .. ".")
                    local learned = tables.alterationTable[aSpell]
                    local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:debug("Spell roll succeeded. Alteration spell " .. learned .. " added to " .. name .. ".")
                        tes3.playSound({ sound = "alteration hit" })
                    else
                        log:trace("Alteration spell roll failed on " .. name .. ".")
                    end
                until (wasAdded == true or iterations == 30)
            end
            if maValue.base >= 75 and maValue.base < 100 then
                local iterations = 0
                repeat
                    local aSpell = math.random(1, 15)
                    log:trace("Alteration Spell #" .. aSpell .. ".")
                    local learned = tables.alterationTable[aSpell]
                    local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:debug("Spell roll succeeded. Alteration spell " .. learned .. " added to " .. name .. ".")
                        tes3.playSound({ sound = "alteration hit" })
                    else
                        log:trace("Alteration spell roll failed on " .. name .. ".")
                    end
                until (wasAdded == true or iterations == 40)
            end
            if maValue.base >= 100 then
                local iterations = 0
                repeat
                    local aSpell = math.random(1, 21)
                    log:trace("Alteration Spell #" .. aSpell .. ".")
                    local learned = tables.alterationTable[aSpell]
                    local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:debug("Spell roll succeeded. Alteration spell " .. learned .. " added to " .. name .. ".")
                        tes3.playSound({ sound = "alteration hit" })
                    else
                        log:trace("Alteration spell roll failed on " .. name .. ".")
                    end
                until (wasAdded == true or iterations == 50)
            end
        end
    end
    if conj == true then
        local mcValue = companionRef.mobile:getSkillStatistic(13)
        if math.random(0, 99) < config.spellChance then
            if mcValue.base >= 15 and mcValue.base < 40 then
                local iterations = 0
                repeat
                    local cSpell = math.random(1, 6)
                    log:trace("Conjuration Spell #" .. cSpell .. ".")
                    local learned = tables.conjurationTable[cSpell]
                    local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:debug("Spell roll succeeded. Conjuration spell " .. learned .. " added to " .. name .. ".")
                        tes3.playSound({ sound = "conjuration area" })
                    else
                        log:trace("Conjuration spell roll failed on " .. name .. ".")
                    end
                until (wasAdded == true or iterations == 15)
            end
            if mcValue.base >= 40 and mcValue.base < 75 then
                local iterations = 0
                repeat
                    local cSpell = math.random(1, 14)
                    log:trace("Conjuration Spell #" .. cSpell .. ".")
                    local learned = tables.conjurationTable[cSpell]
                    local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:debug("Spell roll succeeded. Conjuration spell " .. learned .. " added to " .. name .. ".")
                        tes3.playSound({ sound = "conjuration area" })
                    else
                        log:trace("Conjuration spell roll failed on " .. name .. ".")
                    end
                until (wasAdded == true or iterations == 30)
            end
            if mcValue.base >= 75 and mcValue.base < 100 then
                local iterations = 0
                repeat
                    local cSpell = math.random(1, 24)
                    log:trace("Conjuration Spell #" .. cSpell .. ".")
                    local learned = tables.conjurationTable[cSpell]
                    local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:debug("Spell roll succeeded. Conjuration spell " .. learned .. " added to " .. name .. ".")
                        tes3.playSound({ sound = "conjuration area" })
                    else
                        log:trace("Conjuration spell roll failed on " .. name .. ".")
                    end
                until (wasAdded == true or iterations == 50)
            end
            if mcValue.base >= 100 then
                local iterations = 0
                repeat
                    local cSpell = math.random(1, 30)
                    log:trace("Conjuration Spell #" .. cSpell .. ".")
                    local learned = tables.conjurationTable[cSpell]
                    local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:debug("Spell roll succeeded. Conjuration spell " .. learned .. " added to " .. name .. ".")
                        tes3.playSound({ sound = "conjuration area" })
                    else
                        log:trace("Conjuration spell roll failed on " .. name .. ".")
                    end
                until (wasAdded == true or iterations == 70)
            end
        end
    end
    if illu == true then
        local miValue = companionRef.mobile:getSkillStatistic(12)
        if math.random(0, 99) < config.spellChance then
            if miValue.base >= 15 and miValue.base < 40 then
                local iterations = 0
                repeat
                    local iSpell = math.random(1, 6)
                    log:trace("Illusion Spell #" .. iSpell .. ".")
                    local learned = tables.illusionTable[iSpell]
                    local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:debug("Spell roll succeeded. Illusion spell " .. learned .. " added to " .. name .. ".")
                        tes3.playSound({ sound = "illusion hit" })
                    else
                        log:trace("Illusion spell roll failed on " .. name .. ".")
                    end
                until (wasAdded == true or iterations == 15)
            end
            if miValue.base >= 40 and miValue.base < 75 then
                local iterations = 0
                repeat
                    local iSpell = math.random(1, 12)
                    log:trace("Illusion Spell #" .. iSpell .. ".")
                    local learned = tables.illusionTable[iSpell]
                    local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:debug("Spell roll succeeded. Illusion spell " .. learned .. " added to " .. name .. ".")
                        tes3.playSound({ sound = "illusion hit" })
                    else
                        log:trace("Illusion spell roll failed on " .. name .. ".")
                    end
                until (wasAdded == true or iterations == 30)
            end
            if miValue.base >= 75 and miValue.base < 100 then
                local iterations = 0
                repeat
                    local iSpell = math.random(1, 15)
                    log:trace("Illusion Spell #" .. iSpell .. ".")
                    local learned = tables.illusionTable[iSpell]
                    local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:debug("Spell roll succeeded. Illusion spell " .. learned .. " added to " .. name .. ".")
                        tes3.playSound({ sound = "illusion hit" })
                    else
                        log:trace("Illusion spell roll failed on " .. name .. ".")
                    end
                until (wasAdded == true or iterations == 40)
            end
            if miValue.base >= 100 then
                local iterations = 0
                repeat
                    local iSpell = math.random(1, 19)
                    log:trace("Illusion Spell #" .. iSpell .. ".")
                    local learned = tables.illusionTable[iSpell]
                    local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:debug("Spell roll succeeded. Illusion spell " .. learned .. " added to " .. name .. ".")
                        tes3.playSound({ sound = "illusion hit" })
                    else
                        log:trace("Illusion spell roll failed on " .. name .. ".")
                    end
                until (wasAdded == true or iterations == 45)
            end
        end
    end
    if myst == true then
        local mmValue = companionRef.mobile:getSkillStatistic(14)
        if math.random(0, 99) < config.spellChance then
            if mmValue.base >= 15 and mmValue.base < 40 then
                local iterations = 0
                repeat
                    local mSpell = math.random(1, 5)
                    log:trace("Mysticism Spell #" .. mSpell .. ".")
                    local learned = tables.mysticismTable[mSpell]
                    local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:debug("Spell roll succeeded. Mysticism spell " .. learned .. " added to " .. name .. ".")
                        tes3.playSound({ sound = "mysticism area" })
                    else
                        log:trace("Mysticism spell roll failed on " .. name .. ".")
                    end
                until (wasAdded == true or iterations == 15)
            end
            if mmValue.base >= 40 and mmValue.base < 75 then
                local iterations = 0
                repeat
                    local mSpell = math.random(1, 11)
                    log:trace("Mysticism Spell #" .. mSpell .. ".")
                    local learned = tables.mysticismTable[mSpell]
                    local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:debug("Spell roll succeeded. Mysticism spell " .. learned .. " added to " .. name .. ".")
                        tes3.playSound({ sound = "mysticism area" })
                    else
                        log:trace("Mysticism spell roll failed on " .. name .. ".")
                    end
                until (wasAdded == true or iterations == 30)
            end
            if mmValue.base >= 75 and mmValue.base < 100 then
                local iterations = 0
                repeat
                    local mSpell = math.random(1, 18)
                    log:trace("Mysticism Spell #" .. mSpell .. ".")
                    local learned = tables.mysticismTable[mSpell]
                    local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:debug("Spell roll succeeded. Mysticism spell " .. learned .. " added to " .. name .. ".")
                        tes3.playSound({ sound = "mysticism area" })
                    else
                        log:trace("Mysticism spell roll failed on " .. name .. ".")
                    end
                until (wasAdded == true or iterations == 40)
            end
            if mmValue.base >= 100 then
                local iterations = 0
                repeat
                    local mSpell = math.random(1, 22)
                    log:trace("Mysticism Spell #" .. mSpell .. ".")
                    local learned = tables.mysticismTable[mSpell]
                    local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                    iterations = iterations + 1
                    if wasAdded == true then
                        tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                        log:debug("Spell roll succeeded. Mysticism spell " .. learned .. " added to " .. name .. ".")
                        tes3.playSound({ sound = "mysticism area" })
                    else
                        log:trace("Mysticism spell roll failed on " .. name .. ".")
                    end
                until (wasAdded == true or iterations == 50)
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

    if cType == "Normal" then
        local iterations = 0
        if level < 10 then
            repeat
                local normSpell = math.random(1, #tables.normalTable1)
                log:trace("Normal Spell Table 1, #" .. normSpell .. ".")
                local learned = tables.normalTable1[normSpell]
                local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                iterations = iterations + 1
                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned the skill " .. learned .. "!")
                    log:info("" .. name .. " learned the spell " .. learned .. ".")
                    tes3.playSound({ sound = "alitMOAN" })
                else
                    log:debug("Normal spell roll failed on " .. name .. ".")
                end
            until (wasAdded == true or iterations == 10)
        else
            repeat
                local normSpell = math.random(1, #tables.normalTable2)
                log:trace("Normal Spell Table 2, #" .. normSpell .. ".")
                local learned = tables.normalTable2[normSpell]
                local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                iterations = iterations + 1
                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned the skill " .. learned .. "!")
                    log:info("" .. name .. " learned the spell " .. learned .. ".")
                    tes3.playSound({ sound = "alitMOAN" })
                else
                    log:debug("Normal spell roll failed on " .. name .. ".")
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
                local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                iterations = iterations + 1
                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                    log:info("" .. name .. " learned to cast " .. learned .. ".")
                    tes3.playSound({ sound = "atroflame moan" })
                else
                    log:debug("Daedric spell roll failed on " .. name .. ".")
                end
            until (wasAdded == true or iterations == 30)
        else
            repeat
                local daeSpell = math.random(1, #tables.daedraTable2)
                log:trace("Daedric Spell Table 2, #" .. daeSpell .. ".")
                local learned = tables.daedraTable2[daeSpell]
                local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                iterations = iterations + 1
                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                    log:info("" .. name .. " learned to cast " .. learned .. ".")
                    tes3.playSound({ sound = "atroflame moan" })
                else
                    log:debug("Daedric spell roll failed on " .. name .. ".")
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
                local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                iterations = iterations + 1
                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                    log:info("" .. name .. " learned to cast " .. learned .. ".")
                    tes3.playSound({ sound = "skeleton roar" })
                else
                    log:debug("Undead spell roll failed on " .. name .. ".")
                end
            until (wasAdded == true or iterations == 25)
        else
            repeat
                local undSpell = math.random(1, #tables.undeadTable2)
                log:trace("Undead Spell Table 2, #" .. undSpell .. ".")
                local learned = tables.undeadTable2[undSpell]
                local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                iterations = iterations + 1
                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                    log:info("" .. name .. " learned to cast " .. learned .. ".")
                    tes3.playSound({ sound = "skeleton roar" })
                else
                    log:debug("Undead spell roll failed on " .. name .. ".")
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
                local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                iterations = iterations + 1
                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                    log:info("" .. name .. " learned to cast " .. learned .. ".")
                    tes3.playSound({ sound = "ash ghoul roar" })
                else
                    log:debug("Humanoid spell roll failed on " .. name .. ".")
                end
            until (wasAdded == true or iterations == 35)
        else
            repeat
                local humSpell = math.random(1, #tables.humanoidTable2)
                log:trace("Humanoid Spell Table 2, #" .. humSpell .. ".")
                local learned = tables.humanoidTable2[humSpell]
                local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                iterations = iterations + 1
                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                    log:info("" .. name .. " learned to cast " .. learned .. ".")
                    tes3.playSound({ sound = "ash ghoul roar" })
                else
                    log:debug("Humanoid spell roll failed on " .. name .. ".")
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
            local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
            iterations = iterations + 1
            if wasAdded == true then
                tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                log:info("" .. name .. " learned to cast " .. learned .. ".")
                tes3.playSound({ sound = "cent spider moan" })
            else
                log:debug("Centurion spell roll failed on " .. name .. ".")
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
                local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
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
            until (wasAdded == true or iterations == 35)
        else
            repeat
                local sprSpell = math.random(1, #tables.sprigganTable2)
                log:trace("Spriggan Spell Table 2, #" .. sprSpell .. ".")
                local learned = tables.sprigganTable2[sprSpell]
                local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
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
            until (wasAdded == true or iterations == 70)
        end
    end
    if cType == "Goblin" then
        local iterations = 0
        repeat
            local gobSpell = math.random(1, #tables.goblinTable)
            log:trace("Goblin Spell Table 1, #" .. gobSpell .. ".")
            local learned = tables.goblinTable[gobSpell]
            local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
            iterations = iterations + 1
            if wasAdded == true then
                tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                log:info("" .. name .. " learned to cast " .. learned .. ".")
                tes3.playSound({ sound = "goblin moan" })
            else
                log:debug("Goblin spell roll failed on " .. name .. ".")
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
                local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                iterations = iterations + 1
                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                    log:info("" .. name .. " learned to cast " .. learned .. ".")
                    tes3.playSound({ sound = "ancestor ghost roar" })
                else
                    log:trace("Spectral spell roll failed on " .. name .. ".")
                end
            until (wasAdded == true or iterations == 35)
        else
            repeat
                local specSpell = math.random(1, #tables.spectralTable2)
                log:trace("Spectral Spell Table 2, #" .. specSpell .. ".")
                local learned = tables.spectralTable2[specSpell]
                local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                iterations = iterations + 1
                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                    log:info("" .. name .. " learned to cast " .. learned .. ".")
                    tes3.playSound({ sound = "ancestor ghost roar" })
                else
                    log:trace("Spectral spell roll failed on " .. name .. ".")
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
                local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                iterations = iterations + 1
                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                    log:info("" .. name .. " learned to cast " .. learned .. ".")
                    tes3.playSound({ sound = "kwamF roar" })
                else
                    log:trace("Insectile spell roll failed on " .. name .. ".")
                end
            until (wasAdded == true or iterations == 15)
        else
            repeat
                local insSpell = math.random(1, #tables.insectileTable2)
                log:trace("Insectile Spell Table 2, #" .. insSpell .. ".")
                local learned = tables.insectileTable2[insSpell]
                local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                iterations = iterations + 1
                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                    log:info("" .. name .. " learned to cast " .. learned .. ".")
                    tes3.playSound({ sound = "kwamF roar" })
                else
                    log:trace("Insectile spell roll failed on " .. name .. ".")
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
                    table = tables.restorationTable
                elseif randNum == 2 then
                    table = tables.destructionTable
                elseif randNum == 3 then
                    table = tables.alterationTable
                elseif randNum == 4 then
                    table = tables.illusionTable
                elseif randNum == 5 then
                    table = tables.mysticismTable
                elseif randNum == 6 then
                    table = tables.conjurationTable
                end

                local draSpell = math.random(1, #table)
                log:trace("Draconic Spell Table, #" .. draSpell .. ".")
                local learned = table[draSpell]
                local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                iterations = iterations + 1
                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                    log:info("" .. name .. " learned to cast " .. learned .. ".")
                    tes3.playSound({ soundPath = "companionLeveler\\dragon_spell.wav" })
                else
                    log:trace("Draconic spell roll failed on " .. name .. ".")
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
                local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                iterations = iterations + 1
                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                    log:info("" .. name .. " learned to cast " .. learned .. ".")
                    tes3.playSound({ sound = "dreugh moan" })
                else
                    log:trace("Aquatic spell roll failed on " .. name .. ".")
                end
            until (wasAdded == true or iterations == 20)
        else
            repeat
                local aqSpell = math.random(1, #tables.aquaticTable2)
                log:trace("Aquatic Spell Table 2, #" .. aqSpell .. ".")
                local learned = tables.aquaticTable2[aqSpell]
                local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                iterations = iterations + 1
                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                    log:info("" .. name .. " learned to cast " .. learned .. ".")
                    tes3.playSound({ sound = "dreugh moan" })
                else
                    log:trace("Aquatic spell roll failed on " .. name .. ".")
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
                local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                iterations = iterations + 1
                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                    log:info("" .. name .. " learned to cast " .. learned .. ".")
                    tes3.playSound({ sound = "cliff racer moan" })
                else
                    log:trace("" .. cType .. " spell roll failed on " .. name .. ".")
                end
            until (wasAdded == true or iterations == 20)
        else
            repeat
                local spell = math.random(1, #tables.avianTable2)
                log:trace("" .. cType .. " Spell Table 2, #" .. spell .. ".")
                local learned = tables.avianTable2[spell]
                local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
                iterations = iterations + 1
                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                    log:info("" .. name .. " learned to cast " .. learned .. ".")
                    tes3.playSound({ sound = "cliff racer moan" })
                else
                    log:trace("" .. cType .. " spell roll failed on " .. name .. ".")
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
                local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })
                iterations = iterations + 1
                if wasAdded == true then
                    tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                    log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                    tes3.playSound({ sound = "wolf roar" })
                else
                    log:trace("" .. cType .. " spell roll failed on " .. name .. ".")
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
                table = tables.restorationTable
            elseif randNum == 2 then
                table = tables.destructionTable
            elseif randNum == 3 then
                table = tables.alterationTable
            elseif randNum == 4 then
                table = tables.illusionTable
            elseif randNum == 5 then
                table = tables.mysticismTable
            elseif randNum == 6 then
                table = tables.conjurationTable
            end

            local spell = math.random(1, #table)
            log:trace("Impish Spell Table, #" .. spell .. ".")
            local learned = table[spell]
            local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
            iterations = iterations + 1
            if wasAdded == true then
                tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
                log:info("" .. name .. " learned to cast " .. learned .. ".")
                tes3.playSound({ sound = "scamp moan" })
            else
                log:trace("Impish spell roll failed on " .. name .. ".")
            end
        until (wasAdded == true or iterations == 30)
    end
    if cType == "Fiery" then
        local firstLearned = false

        if level >= 3 then
            local spell = tables.fireTable[1]
            local learned = tes3.getObject(spell)
            local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

            if wasAdded == true then
                tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                firstLearned = true
                tes3.playSound({ sound = "destruction cast" })
            else
                log:trace("" .. name .. " already knows " .. spell .. ".")
            end
        end
        if (level >= 7 and not firstLearned) then
            local spell = tables.fireTable[2]
            local learned = tes3.getObject(spell)
            local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

            if wasAdded == true then
                tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                firstLearned = true
                tes3.playSound({ sound = "destruction cast" })
            else
                log:trace("" .. name .. " already knows " .. spell .. ".")
            end
        end
        if (level >= 12 and not firstLearned) then
            local spell = tables.fireTable[3]
            local learned = tes3.getObject(spell)
            local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

            if wasAdded == true then
                tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                firstLearned = true
                tes3.playSound({ sound = "destruction cast" })
            else
                log:trace("" .. name .. " already knows " .. spell .. ".")
            end
        end
        if (level >= 18 and not firstLearned) then
            local spell = tables.fireTable[4]
            local learned = tes3.getObject(spell)
            local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

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
    if cType == "Frozen" then
        local firstLearned = false

        if level >= 3 then
            local spell = tables.frostTable[1]
            local learned = tes3.getObject(spell)
            local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

            if wasAdded == true then
                tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                firstLearned = true
                tes3.playSound({ sound = "frost_cast" })
            else
                log:trace("" .. name .. " already knows " .. spell .. ".")
            end
        end
        if (level >= 7 and not firstLearned) then
            local spell = tables.frostTable[2]
            local learned = tes3.getObject(spell)
            local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

            if wasAdded == true then
                tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                firstLearned = true
                tes3.playSound({ sound = "frost_cast" })
            else
                log:trace("" .. name .. " already knows " .. spell .. ".")
            end
        end
        if (level >= 12 and not firstLearned) then
            local spell = tables.frostTable[3]
            local learned = tes3.getObject(spell)
            local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

            if wasAdded == true then
                tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                firstLearned = true
                tes3.playSound({ sound = "frost_cast" })
            else
                log:trace("" .. name .. " already knows " .. spell .. ".")
            end
        end
        if (level >= 18 and not firstLearned) then
            local spell = tables.frostTable[4]
            local learned = tes3.getObject(spell)
            local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

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
    if cType == "Galvanic" then
        local firstLearned = false

        if level >= 3 then
            local spell = tables.shockTable[1]
            local learned = tes3.getObject(spell)
            local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

            if wasAdded == true then
                tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                firstLearned = true
                tes3.playSound({ sound = "shock cast" })
            else
                log:trace("" .. name .. " already knows " .. spell .. ".")
            end
        end
        if (level >= 7 and not firstLearned) then
            local spell = tables.shockTable[2]
            local learned = tes3.getObject(spell)
            local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

            if wasAdded == true then
                tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                firstLearned = true
                tes3.playSound({ sound = "shock cast" })
            else
                log:trace("" .. name .. " already knows " .. spell .. ".")
            end
        end
        if (level >= 12 and not firstLearned) then
            local spell = tables.shockTable[3]
            local learned = tes3.getObject(spell)
            local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

            if wasAdded == true then
                tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                firstLearned = true
                tes3.playSound({ sound = "shock cast" })
            else
                log:trace("" .. name .. " already knows " .. spell .. ".")
            end
        end
        if (level >= 18 and not firstLearned) then
            local spell = tables.shockTable[4]
            local learned = tes3.getObject(spell)
            local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

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
    if cType == "Poisonous" then
        local firstLearned = false

        if level >= 3 then
            local spell = tables.poisonTable[1]
            local learned = tes3.getObject(spell)
            local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

            if wasAdded == true then
                tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                firstLearned = true
                tes3.playSound({ sound = "alteration cast" })
            else
                log:trace("" .. name .. " already knows " .. spell .. ".")
            end
        end
        if (level >= 7 and not firstLearned) then
            local spell = tables.poisonTable[2]
            local learned = tes3.getObject(spell)
            local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

            if wasAdded == true then
                tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                firstLearned = true
                tes3.playSound({ sound = "alteration cast" })
            else
                log:trace("" .. name .. " already knows " .. spell .. ".")
            end
        end
        if (level >= 12 and not firstLearned) then
            local spell = tables.poisonTable[3]
            local learned = tes3.getObject(spell)
            local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

            if wasAdded == true then
                tes3.messageBox("" .. name .. " learned to cast " .. learned.name .. "!")
                log:info("" .. name .. " learned to cast " .. learned.name .. ".")
                firstLearned = true
                tes3.playSound({ sound = "alteration cast" })
            else
                log:trace("" .. name .. " already knows " .. spell .. ".")
            end
        end
        if (level >= 18 and not firstLearned) then
            local spell = tables.poisonTable[4]
            local learned = tes3.getObject(spell)
            local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })

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

return this