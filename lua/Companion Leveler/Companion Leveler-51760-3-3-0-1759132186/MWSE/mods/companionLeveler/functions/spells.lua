local config = require("companionLeveler.config")
local tables = require("companionLeveler.tables")
local func = require("companionLeveler.functions.common")
local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")

local this = {}

-- Helper: Try to teach a spell from a table to a companion, with custom message/sound/log.
--- @param spellTable table
--- @param modData table
--- @param companionRef tes3reference
--- @param sound string|tes3sound?
--- @param message string?
--- @param logFunc function?
--- @param spellNameOverride function?
--- @param soundPath string?
local function tryLearnSpell(spellTable, modData, companionRef, sound, message, logFunc, spellNameOverride, soundPath)
    local iterations = 0
    local wasAdded = false
    local name = companionRef.object.name
    repeat
        local idx = math.random(1, #spellTable)
        local learned = spellTable[idx]
        local learnedObj = tes3.getObject(learned) or learned
        local found = false
        for n = 1, #modData.unusedSpells do
            if learnedObj.id == tes3.getObject(modData.unusedSpells[n]).id then
                found = true
                break
            end
        end
        iterations = iterations + 1
        if not found then
            wasAdded = tes3.addSpell({ reference = companionRef, spell = learnedObj.id or learnedObj })
            if wasAdded == true then
                local spellName = spellNameOverride and spellNameOverride(learned) or (learnedObj.name or learnedObj.id or learnedObj)
                if message then
                    tes3.messageBox(message:format(name, spellName))
                end
                if logFunc then
                    logFunc(name, spellName)
                end
                if soundPath then
                    tes3.playSound({ soundPath = soundPath })
                elseif sound then
                    tes3.playSound({ sound = sound })
                end
            end
        end
    until (wasAdded == true or iterations == 100)
end

--
----NPC Spells--------------------------------------------------------------------------------------------------------------------------
--
function this.spellRoll(schools, skills, companionRef)
    local name = companionRef.object.name
    local modData = func.getModData(companionRef)
    log = logger.getLogger("Companion Leveler")
    for i = 1, 6 do
        if schools[i] == true then
            if math.random(0, 99) < config.spellChance then
                if skills[i] >= 15 then
                    local spellTable = tables.spellTables[i][1]
                    if skills[i] >= 40 then
                        spellTable = tables.spellTables[i][2]
                    end
                    if skills[i] >= 75 then
                        spellTable = tables.spellTables[i][3]
                    end
                    if skills[i] >= 100 then
                        spellTable = tables.spellTables[i][4]
                    end

                    tryLearnSpell(
                        spellTable, modData, companionRef,
                        ({"restoration area", "shock cast", "alteration hit", "conjuration area", "illusion hit", "mysticism area"})[i],
                        "%s learned to cast %s!",
                        function(n, s) log:debug("Spell roll succeeded. Spell %s added to %s.", s, n) end
                    )
                end
            end
        end
    end
end

--
----Creature Spells----------------------------------------------------------------------------------------------------------------------------------
--
function this.creatureSpellRoll(level, cType, companionRef)
    local modData = func.getModData(companionRef)
    log = logger.getLogger("Companion Leveler")

    if cType == "Normal" then
        if level < 10 then
            tryLearnSpell(
                tables.normalTable1, modData, companionRef,
                "alitMOAN",
                "%s learned the skill %s!",
                function(n, s) log:info("%s learned the spell %s.", n, s) end
            )
        else
            tryLearnSpell(
                tables.normalTable2, modData, companionRef,
                "alitMOAN",
                "%s learned the skill %s!",
                function(n, s) log:info("%s learned the spell %s.", n, s) end
            )
        end
    elseif cType == "Daedra" then
        if level < 10 then
            tryLearnSpell(
                tables.daedraTable1, modData, companionRef,
                "atroflame moan",
                "%s learned to cast %s!",
                function(n, s) log:info("%s learned to cast %s.", n, s) end
            )
        else
            tryLearnSpell(
                tables.daedraTable2, modData, companionRef,
                "atroflame moan",
                "%s learned to cast %s!",
                function(n, s) log:info("%s learned to cast %s.", n, s) end
            )
        end
    elseif cType == "Undead" then
        if level < 10 then
            tryLearnSpell(
                tables.undeadTable1, modData, companionRef,
                "skeleton roar",
                "%s learned to cast %s!",
                function(n, s) log:info("%s learned to cast %s.", n, s) end
            )
        else
            tryLearnSpell(
                tables.undeadTable2, modData, companionRef,
                "skeleton roar",
                "%s learned to cast %s!",
                function(n, s) log:info("%s learned to cast %s.", n, s) end
            )
        end
    elseif cType == "Humanoid" then
        if level < 10 then
            tryLearnSpell(
                tables.humanoidTable1, modData, companionRef,
                "ash ghoul roar",
                "%s learned to cast %s!",
                function(n, s) log:info("%s learned to cast %s.", n, s) end
            )
        else
            tryLearnSpell(
                tables.humanoidTable2, modData, companionRef,
                "ash ghoul roar",
                "%s learned to cast %s!",
                function(n, s) log:info("%s learned to cast %s.", n, s) end
            )
        end
    elseif cType == "Centurion" then
        tryLearnSpell(
            tables.centurionTable, modData, companionRef,
            "cent spider moan",
            "%s learned to cast %s!",
            function(n, s) log:info("%s learned to cast %s.", n, s) end
        )
    elseif cType == "Spriggan" then
        local sprigganNameOverride = function(learned)
            if learned == "BM_summonwolf" then
                return "Call Wolf"
            elseif learned == "BM_summonbear" then
                return "Call Bear"
            elseif learned == "bm_summonbonewolf" then
                return "Summon Bonewolf"
            end
            return learned
        end
        if level < 10 then
            tryLearnSpell(
                tables.sprigganTable1, modData, companionRef,
                "spriggan roar",
                "%s learned to cast %s!",
                function(n, s) log:info("%s learned to cast %s.", n, s) end,
                sprigganNameOverride
            )
        else
            tryLearnSpell(
                tables.sprigganTable2, modData, companionRef,
                "spriggan roar",
                "%s learned to cast %s!",
                function(n, s) log:info("%s learned to cast %s.", n, s) end,
                sprigganNameOverride
            )
        end
    elseif cType == "Goblin" then
        tryLearnSpell(
            tables.goblinTable, modData, companionRef,
            "goblin moan",
            "%s learned to cast %s!",
            function(n, s) log:info("%s learned to cast %s.", n, s) end
        )
    elseif cType == "Spectral" then
        if level < 10 then
            tryLearnSpell(
                tables.spectralTable1, modData, companionRef,
                "ancestor ghost roar",
                "%s learned to cast %s!",
                function(n, s) log:info("%s learned to cast %s.", n, s) end
            )
        else
            tryLearnSpell(
                tables.spectralTable2, modData, companionRef,
                "ancestor ghost roar",
                "%s learned to cast %s!",
                function(n, s) log:info("%s learned to cast %s.", n, s) end
            )
        end
    elseif cType == "Insectile" then
        if level < 10 then
            tryLearnSpell(
                tables.insectileTable1, modData, companionRef,
                "kwamF roar",
                "%s learned to cast %s!",
                function(n, s) log:info("%s learned to cast %s.", n, s) end
            )
        else
            tryLearnSpell(
                tables.insectileTable2, modData, companionRef,
                "kwamF roar",
                "%s learned to cast %s!",
                function(n, s) log:info("%s learned to cast %s.", n, s) end
            )
        end
    elseif cType == "Draconic" then
        if level > 3 then
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
            tryLearnSpell(
                table, modData, companionRef,
                nil,
                "%s learned to cast %s!",
                function(n, s) log:info("%s learned to cast %s.", n, s) end,
                nil,
                "companionLeveler\\dragon_spell.wav"
            )
        end
    elseif cType == "Aquatic" then
        if level < 10 then
            tryLearnSpell(
                tables.aquaticTable1, modData, companionRef,
                "dreugh moan",
                "%s learned to cast %s!",
                function(n, s) log:info("%s learned to cast %s.", n, s) end
            )
        else
            tryLearnSpell(
                tables.aquaticTable2, modData, companionRef,
                "dreugh moan",
                "%s learned to cast %s!",
                function(n, s) log:info("%s learned to cast %s.", n, s) end
            )
        end
    elseif cType == "Avian" then
        if level < 10 then
            tryLearnSpell(
                tables.avianTable1, modData, companionRef,
                "cliff racer moan",
                "%s learned to cast %s!",
                function(n, s) log:info("%s learned to cast %s.", n, s) end
            )
        else
            tryLearnSpell(
                tables.avianTable2, modData, companionRef,
                "cliff racer moan",
                "%s learned to cast %s!",
                function(n, s) log:info("%s learned to cast %s.", n, s) end
            )
        end
    elseif cType == "Bestial" then
        if level > 5 then
            tryLearnSpell(
                tables.bestialTable, modData, companionRef,
                "wolf roar",
                "%s learned to cast %s!",
                function(n, s) log:info("%s learned to cast %s.", n, s) end,
                function(learned)
                    local obj = tes3.getObject(learned)
                    return obj and obj.name or learned
                end
            )
        end
    elseif cType == "Impish" then
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
        tryLearnSpell(
            table, modData, companionRef,
            "scamp moan",
            "%s learned to cast %s!",
            function(n, s) log:info("%s learned to cast %s.", n, s) end
        )
    elseif cType == "Fiery" then
        local firstLearned = false
        for i, threshold in ipairs({3, 7, 12, 18}) do
            if level >= threshold and not firstLearned then
                local spell = tables.fireTable[i]
                local learned = tes3.getObject(spell)
                local found = false
                for n = 1, #modData.unusedSpells do
                    if learned.id == tes3.getObject(modData.unusedSpells[n]).id then
                        found = true
                        break
                    end
                end
                if not found then
                    local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })
                    if wasAdded == true then
                        tes3.messageBox(("%s learned to cast %s!"):format(companionRef.object.name, learned.name))
                        log:info("%s learned to cast %s.", companionRef.object.name, learned.name)
                        firstLearned = true
                        tes3.playSound({ sound = "destruction cast" })
                    else
                        log:trace("%s already knows %s.", companionRef.object.name, spell)
                    end
                end
            end
        end
    elseif cType == "Frozen" then
        local firstLearned = false
        for i, threshold in ipairs({3, 7, 12, 18}) do
            if level >= threshold and not firstLearned then
                local spell = tables.frostTable[i]
                local learned = tes3.getObject(spell)
                local found = false
                for n = 1, #modData.unusedSpells do
                    if learned.id == tes3.getObject(modData.unusedSpells[n]).id then
                        found = true
                        break
                    end
                end
                if not found then
                    local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })
                    if wasAdded == true then
                        tes3.messageBox(("%s learned to cast %s!"):format(companionRef.object.name, learned.name))
                        log:info("%s learned to cast %s.", companionRef.object.name, learned.name)
                        firstLearned = true
                        tes3.playSound({ sound = "frost_cast" })
                    else
                        log:trace("%s already knows %s.", companionRef.object.name, spell)
                    end
                end
            end
        end
    elseif cType == "Galvanic" then
        local firstLearned = false
        for i, threshold in ipairs({3, 7, 12, 18}) do
            if level >= threshold and not firstLearned then
                local spell = tables.shockTable[i]
                local learned = tes3.getObject(spell)
                local found = false
                for n = 1, #modData.unusedSpells do
                    if learned.id == tes3.getObject(modData.unusedSpells[n]).id then
                        found = true
                        break
                    end
                end
                if not found then
                    local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })
                    if wasAdded == true then
                        tes3.messageBox(("%s learned to cast %s!"):format(companionRef.object.name, learned.name))
                        log:info("%s learned to cast %s.", companionRef.object.name, learned.name)
                        firstLearned = true
                        tes3.playSound({ sound = "shock cast" })
                    else
                        log:trace("%s already knows %s.", companionRef.object.name, spell)
                    end
                end
            end
        end
    elseif cType == "Poisonous" then
        local firstLearned = false
        for i, threshold in ipairs({3, 7, 12, 18}) do
            if level >= threshold and not firstLearned then
                local spell = tables.poisonTable[i]
                local learned = tes3.getObject(spell)
                local found = false
                for n = 1, #modData.unusedSpells do
                    if learned.id == tes3.getObject(modData.unusedSpells[n]).id then
                        found = true
                        break
                    end
                end
                if not found then
                    local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned.id })
                    if wasAdded == true then
                        tes3.messageBox(("%s learned to cast %s!"):format(companionRef.object.name, learned.name))
                        log:info("%s learned to cast %s.", companionRef.object.name, learned.name)
                        firstLearned = true
                        tes3.playSound({ sound = "alteration cast" })
                    else
                        log:trace("%s already knows %s.", companionRef.object.name, spell)
                    end
                end
            end
        end
    elseif cType == "Pestilent" then
        if level > 2 then
            tryLearnSpell(
                tables.pestTable, modData, companionRef,
                "rat roar",
                "%s learned to cast %s!",
                function(n, s) log:info("%s learned to cast %s.", n, s) end,
                function(learned)
                    local obj = tes3.getObject(learned)
                    return obj and obj.name or learned
                end
            )
        end
    elseif cType == "Fungal" then
        if level > 2 then
            tryLearnSpell(
                tables.fungalTable, modData, companionRef,
                nil,
                "%s learned to cast %s!",
                function(n, s) log:info("%s learned to cast %s.", n, s) end,
                function(learned)
                    local obj = tes3.getObject(learned)
                    return obj and obj.name or learned
                end, "companionLeveler\\creature_spell.wav"
            )
        end
    elseif cType == "Seismic" then
        if level > 2 then
            tryLearnSpell(
                tables.seisTable, modData, companionRef,
                nil,
                "%s learned to cast %s!",
                function(n, s) log:info("%s learned to cast %s.", n, s) end,
                function(learned)
                    local obj = tes3.getObject(learned)
                    return obj and obj.name or learned
                end, "companionLeveler\\creature_spell.wav"
            )
        end
    end
end

return this