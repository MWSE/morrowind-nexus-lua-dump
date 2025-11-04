--Initialize------------------------------------------------
local config = require("dailyTraining.config")
local strings = require("dailyTraining.strings")
local logger = require("logging.logger")
local msgBox = include("messageBox.box") --interop
local skillSelection = ""
local skillNumber = 40
local skillType = ""
local hourText = 0
local costPerHr = 0
local ambushFlag = 0

local log = logger.new {
    name = "Daily Training",
    logLevel = "TRACE",
}
log:setLogLevel(config.logLevel)

local function initialized(e)
    log:info("Initialized.")
end

event.register("initialized", initialized)


--IDs--------------------------------------------------------
local id_menu = tes3ui.registerID("kl_daily_menu")
local id_labelHour = tes3ui.registerID("kl_daily_labelHour")
local id_labelProgress = tes3ui.registerID("kl_daily_labelProgress")
local id_labelSession = tes3ui.registerID("kl_daily_labelSession")
local id_labelSkill = tes3ui.registerID("kl_daily_labelSkill")
local id_labelEfficiency = tes3ui.registerID("kl_daily_labelEfficiency")
local id_blockInner = tes3ui.registerID("kl_daily_blockInner")
local id_blockCombat = tes3ui.registerID("kl_daily_blockCombat")
local id_blockMagic = tes3ui.registerID("kl_daily_blockMagic")
local id_blockStealth = tes3ui.registerID("kl_daily_blockStealth")
local id_btnOk = tes3ui.registerID("kl_daily_ok")
local id_btnCancel = tes3ui.registerID("kl_daily_cancel")
local id_fillBarMenu = tes3ui.registerID("kl_fill_menu")
local id_fillBar = tes3ui.registerID("kl_fill_bar")


--Mod Data---------------------------------------------------
local function getModData(playerRef)
    log:trace("Checking saved Mod Data.")
    if not playerRef.data.dailyTraining then
        log:info("Player Mod Data not found, setting to base Mod Data values.")
        playerRef.data.dailyTraining = { ["streak"] = 0, ["cooldown"] = 0, ["lastTrained"] = 0, ["dayCheck"] = 0,
            ["streakSkill"] = "",
            ["noDupe"] = 0 }
        playerRef.modified = true
    else
        log:trace("Saved Mod Data found.")
    end
    return playerRef.data.dailyTraining
end

--Cooldown Elapsed--------------------------------------------
local function cooldownElapsed()
    local modData = getModData(tes3.player)
    if (config.trainCD == true and config.cdMessages == true and modData.cooldown == 1) then
        if msgBox then
            msgBox.logMessage("" .. strings.cdFlavor[math.random(1, 34)] .. "", { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
        else
            tes3.messageBox("" .. strings.cdFlavor[math.random(1, 34)] .. "")
        end
    end
    modData.cooldown = 0
    log:debug("Training cooldown elapsed.")
end

timer.register("dailyTraining:cooldownElapsed", cooldownElapsed)

--Streak Loss Counter-----------------------------------------
local function loseStreak()
    local modData = getModData(tes3.player)
    modData.lastTrained = modData.lastTrained + 1
    modData.dayCheck = modData.dayCheck + 1
    log:debug("" .. modData.lastTrained .. " hours since " .. modData.streakSkill .. " last trained.")
    log:debug("" .. modData.dayCheck .. " hours on dayCheck.")
    if (modData.lastTrained >= config.gracePeriod and modData.streak > 0) then
        modData.streak = 0
        if msgBox then
            msgBox.logMessage("" .. modData.streakSkill .. " training streak lost!", { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
        else
            tes3.messageBox("" .. modData.streakSkill .. " training streak lost!")
        end
        modData.streakSkill = ""
        log:info("Training streak lost!")
    end
end

timer.register("dailyTraining:loseStreak", loseStreak)

--Hostile actor check in interiors-----------------------------------
local function isHostileToPlayer()
    local cell = tes3.getPlayerCell()
    for cre in cell:iterateReferences(tes3.objectType.creature) do --Check creatures
        if (cre ~= nil and cre.mobile ~= nil) then
            if (cre.mobile.fight >= 83 and cre.mobile.health.current > 0) then
                log:debug("Hostile creature found.")
                return true
            end
        end
    end
    for npc in cell:iterateReferences(tes3.objectType.npc) do --Check creatures
        if (npc ~= nil and npc.mobile ~= nil) then
            if (npc.mobile.fight >= 83 and npc.mobile.health.current > 0) then
                log:debug("Hostile NPC found.")
                return true
            end
        end
    end
    log:debug("No hostiles found.")
    return false
end

--Ambushed!-------------------------------------------------------
local function ambush()
    log:debug("Ambush triggered.")
    local cell = tes3.getPlayerCell()
    local modData = getModData(tes3.player)
    local cameraPosition = tes3.getCameraPosition()
    local spawns = 0
    if cell.isInterior then
        for cre in cell:iterateReferences(tes3.objectType.creature) do --Check creatures
            if (cre ~= nil and cre.mobile ~= nil and spawns == 0) then
                if (
                    string.endswith(cre.mobile.reference.object.name, "Sphere") or
                        string.endswith(cre.mobile.reference.object.name, "Centurion") or
                        string.endswith(cre.mobile.reference.object.name, "Fabricant") or
                        string.startswith(cre.mobile.reference.object.name, "Centurion") or
                        string.startswith(cre.mobile.reference.object.name, "Dwarven")) then
                    if (cre.mobile.health.current > 0 and cre.mobile.fight >= 83) then
                        tes3.createReference({ object = tes3.getObject("in_dwe_all_lev+2"):pickFrom(),
                            position = cameraPosition,
                            cell = cell })
                        spawns = spawns + 1
                        log:debug("Dwemer creature spawned!")
                    end
                end
                if (string.startswith(cre.mobile.reference.id, "bm") or string.startswith(cre.mobile.reference.id, "BM")
                    ) then
                    if (cre.mobile.health.current > 0 and cre.mobile.fight >= 83) then
                        tes3.createReference({ object = tes3.getObject("bm_in_icecaves"):pickFrom(),
                            position = cameraPosition,
                            cell = cell })
                        spawns = spawns + 1
                        log:debug("Bloodmoon creature spawned!")
                    end
                end
                if (string.startswith(cre.mobile.reference.id, "goblin")) then
                    if (cre.mobile.health.current > 0 and cre.mobile.fight >= 83) then
                        tes3.createReference({ object = tes3.getObject("in_goblins"):pickFrom(),
                            position = cameraPosition,
                            cell = cell })
                        spawns = spawns + 1
                        log:debug("Goblin creature spawned!")
                    end
                end
                if (cre.mobile.reference.object.type == 1) then
                    if (cre.mobile.health.current > 0 and cre.mobile.fight >= 83) then
                        tes3.createReference({ object = tes3.getObject("in_dae_all_lev+2"):pickFrom(),
                            position = cameraPosition,
                            cell = cell })
                        spawns = spawns + 1
                        log:debug("Daedra spawned!")
                    end
                end
                if (cre.mobile.reference.object.type == 2) then
                    if (cre.mobile.health.current > 0 and cre.mobile.fight >= 83) then
                        tes3.createReference({ object = tes3.getObject("in_tomb_all_lev+2"):pickFrom(),
                            position = cameraPosition,
                            cell = cell })
                        spawns = spawns + 1
                        log:debug("Undead spawned!")
                    end
                end
                if (cre.mobile.reference.object.type == 3) then
                    if (cre.mobile.health.current > 0 and cre.mobile.fight >= 83) then
                        tes3.createReference({ object = tes3.getObject("in_6th_all_lev+2"):pickFrom(),
                            position = cameraPosition,
                            cell = cell })
                        spawns = spawns + 1
                        log:debug("Humanoid spawned!")
                    end
                end
                if spawns == 0 then
                    if (cre.mobile.health.current > 0 and cre.mobile.fight >= 83) then
                        tes3.createReference({ object = tes3.getObject("in_cave_all_lev+2"):pickFrom(),
                            position = cameraPosition,
                            cell = cell })
                        spawns = spawns + 1
                        log:debug("Regular cave creature spawned!")
                    end
                end
            end
        end
    else
        if (cell.displayName == "Ashlands Region" and spawns == 0) then
            local ref = tes3.createReference({ object = tes3.getObject("ex_molagmar_sleep"):pickFrom(),
                position = cameraPosition,
                cell = cell })
            spawns = spawns + 1
            log:debug("Ashlands creature spawned!")
            if string.startswith(ref.id, "scrib") then
                if msgBox then
                    msgBox.logMessage(strings.scribFlavor[math.random(1, 13)], { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
                else
                    tes3.messageBox(strings.scribFlavor[math.random(1, 13)])
                end
                modData.cooldown = 0
            end
        end
        if (cell.displayName == "Ascadian Isles Region" and spawns == 0) then
            local ref = tes3.createReference({ object = tes3.getObject("ex_ascadianisles_sleep"):pickFrom(),
                position = cameraPosition,
                cell = cell })
            spawns = spawns + 1
            log:debug("Ascadian Isles creature spawned!")
            if string.startswith(ref.id, "scrib") then
                if msgBox then
                    msgBox.logMessage(strings.scribFlavor[math.random(1, 13)], { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
                else
                    tes3.messageBox(strings.scribFlavor[math.random(1, 13)])
                end
                modData.cooldown = 0
            end
        end
        if (cell.displayName == "Azura's Coast Region" and spawns == 0) then
            local ref = tes3.createReference({ object = tes3.getObject("ex_azurascoast_sleep"):pickFrom(),
                position = cameraPosition,
                cell = cell })
            spawns = spawns + 1
            log:debug("Azura's Coast creature spawned!")
            if string.startswith(ref.id, "scrib") then
                if msgBox then
                    msgBox.logMessage(strings.scribFlavor[math.random(1, 13)], { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
                else
                    tes3.messageBox(strings.scribFlavor[math.random(1, 13)])
                end
                modData.cooldown = 0
            end
        end
        if (cell.displayName == "Bitter Coast Region" and spawns == 0) then
            local ref = tes3.createReference({ object = tes3.getObject("ex_bittercoast_sleep"):pickFrom(),
                position = cameraPosition,
                cell = cell })
            spawns = spawns + 1
            log:debug("Bitter Coast creature spawned!")
            if string.startswith(ref.id, "scrib") then
                if msgBox then
                    msgBox.logMessage(strings.scribFlavor[math.random(1, 13)], { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
                else
                    tes3.messageBox(strings.scribFlavor[math.random(1, 13)])
                end
                modData.cooldown = 0
            end
        end
        if (cell.displayName == "Grazelands Region" and spawns == 0) then
            tes3.createReference({ object = tes3.getObject("ex_grazelands_sleep"):pickFrom(),
                position = cameraPosition,
                cell = cell })
            spawns = spawns + 1
            log:debug("Grazelands creature spawned!")
        end
        if (cell.displayName == "Molag Amur Region" and spawns == 0) then
            local ref = tes3.createReference({ object = tes3.getObject("ex_molagmar_sleep"):pickFrom(),
                position = cameraPosition,
                cell = cell })
            spawns = spawns + 1
            log:debug("Molag Amur creature spawned!")
            if string.startswith(ref.id, "scrib") then
                if msgBox then
                    msgBox.logMessage(strings.scribFlavor[math.random(1, 13)], { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
                else
                    tes3.messageBox(strings.scribFlavor[math.random(1, 13)])
                end
                modData.cooldown = 0
            end
        end
        if (cell.displayName == "Red Mountain Region" and spawns == 0) then
            tes3.createReference({ object = tes3.getObject("ex_RedMtn_all_sleep"):pickFrom(),
                position = cameraPosition,
                cell = cell })
            spawns = spawns + 1
            log:debug("Red Mountain creature spawned!")
        end
        if (cell.displayName == "Sheogorad Region" and spawns == 0) then
            local ref = tes3.createReference({ object = tes3.getObject("ex_sheogorad_sleep"):pickFrom(),
                position = cameraPosition,
                cell = cell })
            spawns = spawns + 1
            log:debug("Sheogorad creature spawned!")
            if string.startswith(ref.id, "scrib") then
                if msgBox then
                    msgBox.logMessage(strings.scribFlavor[math.random(1, 13)], { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
                else
                    tes3.messageBox(strings.scribFlavor[math.random(1, 13)])
                end
                modData.cooldown = 0
            end
        end
        if (cell.displayName == "West Gash Region" and spawns == 0) then
            local ref = tes3.createReference({ object = tes3.getObject("ex_westgash_sleep"):pickFrom(),
                position = cameraPosition,
                cell = cell })
            spawns = spawns + 1
            log:debug("West Gash creature spawned!")
            if string.startswith(ref.id, "scrib") then
                if msgBox then
                    msgBox.logMessage(strings.scribFlavor[math.random(1, 13)], { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
                else
                    tes3.messageBox(strings.scribFlavor[math.random(1, 13)])
                end
                modData.cooldown = 0
            end
        end
        if (string.startswith(cell.displayName, "Solstheim") and spawns == 0) then
            tes3.createReference({ object = tes3.getObject("bm_ex_isinplains_sleep"):pickFrom(),
                position = cameraPosition,
                cell = cell })
            spawns = spawns + 1
            log:debug("Solstheim creature spawned!")
        end
        if (spawns == 0) then
            local ref = tes3.createReference({ object = tes3.getObject("ex_wild_all_sleep"):pickFrom(),
                position = cameraPosition,
                cell = cell })
            spawns = spawns + 1
            log:debug("Generic exterior creature spawned!")
            if string.startswith(ref.id, "scrib") then
                if msgBox then
                    msgBox.logMessage(strings.scribFlavor[math.random(1, 13)], { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
                else
                    tes3.messageBox(strings.scribFlavor[math.random(1, 13)])
                end
                modData.cooldown = 0
            end
        end
    end
    timer.delayOneFrame(function()
        timer.delayOneFrame(function()
            timer.delayOneFrame(function()
                ambushFlag = 0
                if msgBox then
                    msgBox.logMessage("Your training has been interrupted.", { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
                else
                    tes3.messageBox("Your training has been interrupted.")
                end
            end)
        end)
    end)
end

--End Training------------------------------------------------
local function fadeIn(e)
    local menu = tes3ui.findMenu(id_fillBarMenu)
    menu:destroy()
    tes3ui.leaveMenuMode()
    if (config.playSound == true and skillNumber ~= 25 and skillNumber ~= 40) then
        tes3.playSound({ sound = strings.sounds[skillNumber], volume = 0.7 })
    end
    tes3.fadeIn({ duration = 0.5 })
    log:debug("Training complete.")
end

--Training----------------------------------------------------
local function trainTime()
    if ambushFlag == 1 then return end
    if tes3ui.findMenu(id_fillBarMenu) == nil then return end
    
    local menu = tes3ui.findMenu(id_fillBarMenu)
    local bar = menu:findChild(id_fillBar)
    local modData = getModData(tes3.player)
    bar.widget.current = (bar.widget.current + 1)
    menu:updateLayout()

    --Update Last Trained--
    if (modData.streakSkill == skillSelection) then
        modData.lastTrained = 0
    end

    --Pass Time--
    local gameHour = tes3.getGlobal('GameHour')
    gameHour = gameHour + 1
    tes3.setGlobal('GameHour', gameHour)

    --Resource Drain--
    if config.trainCost == true then
        tes3.modStatistic({ name = skillType:lower(), current = (costPerHr * -1), reference = tes3.mobilePlayer })
    end

    --Novice Skill Bonus--
    local skillCheck = tes3.player.mobile:getSkillStatistic(skillNumber)
    local expBonus = 0.1
    if skillCheck.base < config.weakSkill then
        expBonus = expBonus + (config.weakMod / 1000)
        log:info("Novice bonus experience rewarded on " .. tes3.getSkillName(skillNumber) .. ".")
    end
    
    --Racial Skill Bonus--
    local race = tes3.mobilePlayer.object.race
    if config.raceBonus == true then
        local raceSwitch = 0
        for i = 1, 7 do
            if (skillNumber == race.skillBonuses[i].skill) then
                raceSwitch = 1
            end
        end
        if raceSwitch == 1 then
            expBonus = expBonus + 0.015
            log:info("Racial bonus experience rewarded on " .. tes3.getSkillName(skillNumber) .. ".")
        end
    end
    --Miscellaneous Reduction--
    local class = tes3.mobilePlayer.object.class
    if config.miscPenalty == true then
        local miscSwitch = 1
        for i = 1, 5 do
            if (skillNumber == class.majorSkills[i] or skillNumber == class.minorSkills[i]) then
                miscSwitch = 0
            end
        end
        if miscSwitch == 1 then
            expBonus = expBonus - 0.015
            log:info("Miscellaneous experience penalty incurred on " .. tes3.getSkillName(skillNumber) .. ".")
        end
    end
    --Endurance/Willpower Modifier--
    if config.attModifier == true then
        if (skillType == "Fatigue" or skillType == "Health") then
            local endurance = tes3.mobilePlayer.endurance
            if endurance.current ~= endurance.base then
                local modCalc = (((endurance.current / endurance.base) / 10) - 0.1)
                if modCalc > 0.05 then
                    modCalc = 0.05
                end
                if modCalc < -0.05 then
                    modCalc = -0.05
                end
                expBonus = expBonus + modCalc
            end
        else
            local willpower = tes3.mobilePlayer.willpower
            if willpower.current ~= willpower.base then
                local modCalc = (((willpower.current / willpower.base) / 10) - 0.1)
                if modCalc > 0.05 then
                    modCalc = 0.05
                end
                if modCalc < -0.05 then
                    modCalc = -0.05
                end
                expBonus = expBonus + modCalc
            end
        end
    end
    --Specialization Skill?--
    if config.specSkills == true then
        local specialization = class.specialization
        local specSwitch = 0
        if specialization == 0 then
            for i = 1, 9 do
                if skillNumber == strings.combatSkillTable[i] then
                    specSwitch = 1
                end
            end
        end
        if specialization == 1 then
            for i = 1, 9 do
                if skillNumber == strings.magicSkillTable[i] then
                    specSwitch = 1
                end
            end
        end
        if specialization == 2 then
            for i = 1, 9 do
                if skillNumber == strings.stealthSkillTable[i] then
                    specSwitch = 1
                end
            end
        end
        if specSwitch == 1 then
            tes3.player.mobile:exerciseSkill(skillNumber, (config.expMod * (expBonus + 0.025)))
            log:info("Specialization bonus experience rewarded on " .. tes3.getSkillName(skillNumber) .. ".")
            log:info("" .. config.expMod * (expBonus + 0.025) .. " experience gained.")
        else
            tes3.player.mobile:exerciseSkill(skillNumber, (config.expMod * expBonus))
            log:info("" .. config.expMod * expBonus .. " experience gained.")
        end
    else
        tes3.player.mobile:exerciseSkill(skillNumber, (config.expMod * expBonus))
        log:info("" .. config.expMod * expBonus .. " experience gained.")
    end
    --Ambush Check--
    if config.ambush == true then
        local cell = tes3.getPlayerCell()
        if (cell.restingIsIllegal == false) then
            if (cell.isInterior and isHostileToPlayer()) then
                if math.random(1, 99) < config.ambushChance then
                    ambush()
                    fadeIn()
                    ambushFlag = 1
                    log:debug("Training was interrupted in an interior!")
                end
            end
            if cell.isInterior == false then
                if math.random(1, 99) < config.ambushChance then
                    ambush()
                    fadeIn()
                    ambushFlag = 1
                    log:debug("Training was interrupted in an exterior!")
                end
            end
        end
    end
    if bar.widget ~= nil then
        if (bar.widget.current == bar.widget.max) then
            --Streak Check-----------------------------------------
            local added = 0
            if modData.streak == 0 then
                modData.streak = modData.streak + 1
                added = 1
                modData.dayCheck = 0
                modData.streakSkill = skillSelection
                log:debug("Streak is 0. Streak is now 1.")
            end
            if (modData.dayCheck >= 20 and added == 0 and modData.streakSkill == skillSelection) then
                modData.streak = modData.streak + 1
                added = 1
                modData.dayCheck = 0
                log:debug("Over 20 hours since last trained. Streak added.")
            end
            if (modData.streak >= 3 and modData.streakSkill == skillSelection and config.streakBonus == true) then
                if (modData.streak >= 3 and modData.streak < 7) then
                    tes3.player.mobile:exerciseSkill(skillNumber, (config.expMod * 0.1))
                    if msgBox then
                        msgBox.logMessage("You gained a little experience through consistently training " .. skillSelection .. " for " .. modData.streak .. " days!", { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
                    else
                        tes3.messageBox("You gained a little experience through consistently training " .. skillSelection .. " for " .. modData.streak .. " days!")
                    end
                end
                if (modData.streak >= 7 and modData.streak < 30) then
                    tes3.player.mobile:exerciseSkill(skillNumber, ((config.expMod * 0.1) * 2))
                    if msgBox then
                        msgBox.logMessage("You gained a fair amount of experience through consistently training " .. skillSelection .. " for " .. modData.streak .. " days!", { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
                    else
                        tes3.messageBox("You gained a fair amount of experience through consistently training " .. skillSelection .. " for " .. modData.streak .. " days!")
                    end
                end
                if (modData.streak >= 30 and modData.streak < 180) then
                    tes3.player.mobile:exerciseSkill(skillNumber, ((config.expMod * 0.1) * 3))
                    if msgBox then
                        msgBox.logMessage("You gained a modest amount of experience through consistently training " .. skillSelection .. " for " .. modData.streak .. " days!", { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
                    else
                        tes3.messageBox("You gained a modest amount of experience through consistently training " .. skillSelection .. " for " .. modData.streak .. " days!")
                    end
                end
                if (modData.streak >= 180 and modData.streak < 365) then
                    tes3.player.mobile:exerciseSkill(skillNumber, ((config.expMod * 0.1) * 4))
                    if msgBox then
                        msgBox.logMessage("You gained a considerable amount of experience through consistently training " .. skillSelection .. " for " .. modData.streak .. " days!", { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
                    else
                        tes3.messageBox("You gained a considerable amount of experience through consistently training " .. skillSelection .. " for " .. modData.streak .. " days!")
                    end
                end
                if (modData.streak >= 365) then
                    tes3.player.mobile:exerciseSkill(skillNumber, ((config.expMod * 0.1) * 5))
                    if msgBox then
                        msgBox.logMessage("You gained a vast amount of experience through consistently training " .. skillSelection .. " for " .. modData.streak .. " days!", { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
                    else
                        tes3.messageBox("You gained a vast amount of experience through consistently training " .. skillSelection .. " for " .. modData.streak .. " days!")
                    end
                end
                log:info("Streak bonus applied! " .. modData.streak .. " day streak!")
            end
            log:debug("Streak is " .. modData.streak .. ".")
            if (modData.streakSkill == skillSelection) then
                modData.lastTrained = 0
            end
            --Attribute Burn--
            if config.skillBurn == true then
                if (skillType == "Fatigue" or skillType == "Health") then
                    tes3.applyMagicSource({
                        reference = tes3.player,
                        name = "Training Fatigue",
                        bypassResistances = true,
                        effects = {
                            { id = tes3.effect.drainAttribute, attribute = 5,
                                duration = (math.random(120, 180) * hourText),
                                min = (2 * hourText),
                                max = (5 * hourText) },
                        },
                    })
                else
                    tes3.applyMagicSource({
                        reference = tes3.player,
                        name = "Training Strain",
                        bypassResistances = true,
                        effects = {
                            { id = tes3.effect.drainAttribute, attribute = 2,
                                duration = (math.random(120, 180) * hourText),
                                min = (2 * hourText),
                                max = (5 * hourText) },
                        },
                    })
                end
            end
            --Finish Training-----------------------------------------
            timer.start({ type = timer.real, duration = 1, callback = fadeIn })
            if modData.noDupe == 0 then
                modData.noDupe = 1
                timer.start({ type = timer.game, duration = 1, iterations = -1, callback = "dailyTraining:loseStreak" })
                log:debug("Streak loss timer began.")
            end
        end
    end
end

--On Skill Selection--------------------------------------------------------------
local function onSelect(i)
    local menu = tes3ui.findMenu(id_menu)
    local label = menu:findChild(id_labelSession)
    local label2 = menu:findChild(id_labelProgress)
    local labelE = menu:findChild(id_labelEfficiency)
    local labelS = menu:findChild(id_labelSkill)
    local expAmount = 100
    if (menu) then
        local id = menu:findChild("sTrainB_" .. i .. "")
        --Change States
        for n = 0, 26 do
            local id2 = menu:findChild("sTrainB_" .. n .. "")
            if id2.widget.state == 4 then
                id2.widget.state = 1
            end
        end
        id.widget.state = 4
        skillSelection = id.text
        --Determine Skill Type/Cost--
        skillNumber = i
        skillType = "Fatigue"
        local skillStat = tes3.player.mobile:getSkillStatistic(skillNumber)
        costPerHr = math.round((skillStat.base * 0.1) * config.costMultF)
        if (skillNumber >= 9 and skillNumber <= 15) then
            skillType = "Magicka"
            costPerHr = math.round((skillStat.base * 0.1) * config.costMultM)
        end
        if (skillNumber == 2 or skillNumber == 3 or skillNumber == 17 or skillNumber == 21) then
            skillType = "Health"
            costPerHr = math.round((skillStat.base * 0.1) * config.costMultH)
        end
        local cost = (costPerHr * hourText)
        if config.trainCost == false then
            cost = 0
        end
        if (skillType == "Health" or skillType == "Fatigue") then
            local endLimit = math.round((tes3.mobilePlayer.endurance.current * 0.1) * (config.endMod * 0.1))
            label.text = "Endurance Session Hours: " .. endLimit .. ""
            label2.text = "" .. skillType .. " Cost: " .. cost .. ""
        else
            local wilLimit = math.round((tes3.mobilePlayer.willpower.current * 0.1) * (config.wilMod * 0.1))
            label.text = "Willpower Session Hours: " .. wilLimit .. ""
            label2.text = "" .. skillType .. " Cost: " .. cost .. ""
        end
        labelS.text = "" .. skillSelection .. " " .. tes3.findGMST(tes3.gmst.sSkill).value .. ": " .. tes3.mobilePlayer:getSkillStatistic(skillNumber).base .. ""
        --Novice Skill?--
        local skillCheck = tes3.player.mobile:getSkillStatistic(skillNumber)
        if skillCheck.base < config.weakSkill then
            expAmount = expAmount + config.weakMod
        end
        --Racial Skill?--
        local race = tes3.mobilePlayer.object.race
        if config.raceBonus == true then
            local raceSwitch = 0
            for n = 1, 7 do
                if (skillNumber == race.skillBonuses[n].skill) then
                    raceSwitch = 1
                end
            end
            if raceSwitch == 1 then
                expAmount = expAmount + 15
                log:info("Racial bonus experience rewarded on " .. tes3.getSkillName(skillNumber) .. ".")
            end
        end
        --Miscellaneous Skill?--
        local class = tes3.mobilePlayer.object.class
        if config.miscPenalty == true then
            local miscSwitch = 1
            for n = 1, 5 do
                if (skillNumber == class.majorSkills[n] or skillNumber == class.minorSkills[n]) then
                    miscSwitch = 0
                end
            end
            if miscSwitch == 1 then
                expAmount = expAmount - 15
            end
        end
        --Endurance/Willpower Modifier--
        if config.attModifier == true then
            if (skillType == "Fatigue" or skillType == "Health") then
                local endurance = tes3.mobilePlayer.endurance
                if endurance.current ~= endurance.base then
                    local modCalc = math.round((((endurance.current / endurance.base) / 10) - 0.1) * 1000)
                    if modCalc > 50 then
                        modCalc = 50
                    end
                    if modCalc < -50 then
                        modCalc = -50
                    end
                    expAmount = expAmount + modCalc
                end
            else
                local willpower = tes3.mobilePlayer.willpower
                if willpower.current ~= willpower.base then
                    local modCalc = math.round((((willpower.current / willpower.base) / 10) - 0.1) * 1000)
                    if modCalc > 50 then
                        modCalc = 50
                    end
                    if modCalc < -50 then
                        modCalc = -50
                    end
                    expAmount = expAmount + modCalc
                end
            end
        end
        --Specialization Skill?--
        if config.specSkills == true then
            local specialization = class.specialization
            local specSwitch = 0
            if specialization == 0 then
                for n = 1, 9 do
                    if skillNumber == strings.combatSkillTable[n] then
                        specSwitch = 1
                    end
                end
            end
            if specialization == 1 then
                for n = 1, 9 do
                    if skillNumber == strings.magicSkillTable[n] then
                        specSwitch = 1
                    end
                end
            end
            if specialization == 2 then
                for n = 1, 9 do
                    if skillNumber == strings.stealthSkillTable[n] then
                        specSwitch = 1
                    end
                end
            end
            if specSwitch == 1 then
                labelE.text = "Experience Efficiency: " .. (expAmount + 25) .. "%"
            else
                labelE.text = "Experience Efficiency: " .. expAmount .. "%"
            end
        else
            labelE.text = "Experience Efficiency: " .. expAmount .. "%"
        end
        menu:updateLayout()
    end
end

--On Menu OK-----------------------------------------------------------------------------------------------
local function onOK(e)
    if skillNumber == 40 then
        if msgBox then
            msgBox.logMessage("Please select a skill.", { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
        else
            tes3.messageBox("Please select a skill.")
        end
        return
    end
    local menu = tes3ui.findMenu(id_menu)
    local rMenu = tes3ui.findMenu("MenuRestWait")
    local modData = getModData(tes3.player)
    local endLimit = math.round((tes3.mobilePlayer.endurance.current * 0.1) * (config.endMod * 0.1))
    log:debug("Endurance Limit: " .. endLimit .. " hours.")
    local wilLimit = math.round((tes3.mobilePlayer.willpower.current * 0.1) * (config.wilMod * 0.1))
    log:debug("Willpower Limit: " .. wilLimit .. " hours.")
    local skillStat = tes3.player.mobile:getSkillStatistic(skillNumber)
    if (menu) then
        --Training Success Switch-----------------------------------------------------------------------------------------
        local switch = 1
        --Magic Skills-----------------------------------------------------------------------------------------------
        if (skillNumber >= 9 and skillNumber <= 15) then

            log:debug("Magic skill selected. Skill Number: " .. skillNumber .. "")
            --Cooldown--
            if (modData.cooldown == 1 and config.trainCD == true) then
                if msgBox then
                    msgBox.logMessage("You require rest before training again.", { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
                else
                    tes3.messageBox("You require rest before training again.")
                end
                switch = 0
                log:info("Training still on cooldown.")
            end
            --Town Training allowed?--
            if (config.townTrain == false and config.townSkills == true and switch == 1) then
                local cell = tes3.getPlayerCell()
                if cell.restingIsIllegal then
                    --Is skill not a town skill?--
                    if skillNumber ~= 9 then
                        if msgBox then
                            msgBox.logMessage("You cannot train " .. tes3.getSkillName(skillNumber) .. " in public areas!", { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
                        else
                            tes3.messageBox("You cannot train " .. tes3.getSkillName(skillNumber) .. " in public areas!")
                        end
                        switch = 0
                        log:debug("Cannot train " .. tes3.getSkillName(skillNumber) .. " in public areas!")
                    end
                end
            end
            if (config.townTrain == false and config.townSkills == false and switch == 1) then
                local cell = tes3.getPlayerCell()
                if cell.restingIsIllegal then
                    if msgBox then
                        msgBox.logMessage("You cannot train in public areas!", { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
                    else
                        tes3.messageBox("You cannot train in public areas!")
                    end
                    switch = 0
                    log:debug("Cannot train in public areas!")
                end
            end
            --Skill Limit?--
            if (config.skillLimit == true and switch == 1) then
                if (skillStat.base >= config.skillMax) then
                    if msgBox then
                        msgBox.logMessage("You're too knowledgeable to train the " .. skillSelection .. " skill through simple practice!", { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
                    else
                        tes3.messageBox("You're too knowledgeable to train the " .. skillSelection .. " skill through simple practice!")
                    end
                    switch = 0
                    log:debug("Cannot train expert skill! Skill Number: " .. skillNumber .. "")
                end
            end
            --Willpower Limit?--
            if (hourText > wilLimit and switch == 1 and config.sessionLimit == true) then
                if msgBox then
                    msgBox.logMessage("You lack the will to train " .. skillSelection .. " beyond " .. wilLimit .. " hours.", { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
                else
                    tes3.messageBox("You lack the will to train " .. skillSelection .. " beyond " .. wilLimit .. " hours.")
                end
                switch = 0
                log:debug("You lack the will to train " .. skillSelection .. " beyond " .. wilLimit .. " hours.")
            end
            --Costs--
            costPerHr = math.round((skillStat.base * 0.1) * config.costMultM)
            log:trace("Cost per hour recalculated as " .. costPerHr .. ".")
            local mgkCost = (hourText * costPerHr)
            log:trace("Total Magicka cost calculated as " .. mgkCost .. ".")
            if (tes3.mobilePlayer.magicka.current < mgkCost and switch == 1) then
                if msgBox then
                    msgBox.logMessage("You lack the " .. mgkCost .. " magicka required to train " .. skillSelection .. " for that long.", { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
                else
                    tes3.messageBox("You lack the " .. mgkCost .. " magicka required to train " .. skillSelection .. " for that long.")
                end
                switch = 0
                log:debug("You lack the " .. mgkCost .. " magicka required to train " .. skillSelection .. " for that long.")
            end
            --Training Success--
            if switch == 1 then
                skillType = "Magicka"
                tes3ui.leaveMenuMode()
                menu:destroy()
                rMenu:destroy()
                tes3.fadeOut({ duration = 0.5 })
                timer.start({ duration = config.trainCDtime, callback = "dailyTraining:cooldownElapsed",
                    type = timer.game, persist = true })
                log:debug("Cooldown began for " .. config.trainCDtime .. " hours.")
                modData.cooldown = 1
                local fillMenu = tes3ui.createMenu { id = "kl_fill_menu", fixedFrame = true }
                local fillBar = fillMenu:createFillBar({ id = "kl_fill_bar", current = 0, max = hourText })
                fillBar.widget.showText = true
                fillBar.widget.fillColor = { 0.2, 0.2, 0.6 }
                timer.start({ type = timer.real, duration = 1, iterations = hourText, callback = trainTime })
            end
        else
            --Non-Magic Skills--------------------------------------------------------------------------------------
            log:debug("Non-magic skill selected. Skill Number: " .. skillNumber .. "")
            --Cooldown--
            if (modData.cooldown == 1 and config.trainCD == true) then
                if msgBox then
                    msgBox.logMessage("You require rest before training again.", { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
                else
                    tes3.messageBox("You require rest before training again.")
                end
                switch = 0
                log:debug("Training still on cooldown.")
            end
            --Town Training Allowed?--
            if (config.townTrain == false and config.townSkills == true and switch == 1) then
                local cell = tes3.getPlayerCell()
                if cell.restingIsIllegal then
                    --Is skill not a town skill?--
                    if (skillNumber ~= 20 and skillNumber ~= 16 and skillNumber ~= 1 and skillNumber ~= 8 and skillNumber ~= 24 and skillNumber ~= 18 and skillNumber ~= 19 and skillNumber ~= 25) then
                        if msgBox then
                            msgBox.logMessage("You cannot train " .. tes3.getSkillName(skillNumber) .. " in public areas!", { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
                        else
                            tes3.messageBox("You cannot train " .. tes3.getSkillName(skillNumber) .. " in public areas!")
                        end
                        switch = 0
                        log:debug("Cannot train " .. tes3.getSkillName(skillNumber) .. " in public areas!")
                    end
                end
            end
            if (config.townTrain == false and config.townSkills == false and switch == 1) then
                local cell = tes3.getPlayerCell()
                if cell.restingIsIllegal then
                    if msgBox then
                        msgBox.logMessage("You cannot train in public areas!", { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
                    else
                        tes3.messageBox("You cannot train in public areas!")
                    end
                    switch = 0
                    log:debug("Cannot train in public areas!")
                end
            end
            --Skill Limit?--
            if (config.skillLimit == true and switch == 1) then
                if (skillStat.base >= config.skillMax) then
                    if msgBox then
                        msgBox.logMessage("You're too knowledgeable to train the " .. skillSelection .. " skill through simple practice!", { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
                    else
                        tes3.messageBox("You're too knowledgeable to train the " .. skillSelection .. " skill through simple practice!")
                    end
                    switch = 0
                    log:debug("Cannot train expert skill! Skill Number: " .. skillNumber .. "")
                end
            end
            --Endurance Limit?--
            if (hourText > endLimit and switch == 1 and config.sessionLimit == true) then
                if msgBox then
                    msgBox.logMessage("You lack the endurance to train " .. skillSelection .. " beyond " .. endLimit .. " hours.", { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
                else
                    tes3.messageBox("You lack the endurance to train " .. skillSelection .. " beyond " .. endLimit .. " hours.")
                end
                switch = 0
                log:debug("You lack the endurance to train " .. skillSelection .. " beyond " .. endLimit .. " hours.")
            end
            --Costs--
            costPerHr = math.round((skillStat.base * 0.1) * config.costMultF)
            local hthSwitch = 0
            if (skillNumber == 2 or skillNumber == 3 or skillNumber == 17 or skillNumber == 21) then
                costPerHr = math.round((skillStat.base * 0.1) * config.costMultH)
                hthSwitch = 1
            end
            log:trace("Cost per hour recalculated as " .. costPerHr .. ".")
            local fatCost = (hourText * costPerHr)
            log:trace("Total Fatigue/Health cost calculated as " .. fatCost .. ".")
            if (tes3.mobilePlayer.fatigue.current < fatCost and switch == 1 and hthSwitch == 0) then
                if msgBox then
                    msgBox.logMessage("You lack the " .. fatCost .. " stamina required to train " .. skillSelection .. " for that long.", { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
                else
                    tes3.messageBox("You lack the " .. fatCost .. " stamina required to train " .. skillSelection .. " for that long.")
                end
                switch = 0
                log:debug("You lack the " ..
                    fatCost .. " stamina required to train " .. skillSelection .. " for that long.")
            end
            if (tes3.mobilePlayer.fatigue.current <= fatCost and switch == 1 and hthSwitch == 1) then
                if msgBox then
                    msgBox.logMessage("You lack the " .. fatCost .. " fortitude required to train " .. skillSelection .. " for that long.", { msgBox.config.dtRed, msgBox.config.dtGreen, msgBox.config.dtBlue })
                else
                    tes3.messageBox("You lack the " .. fatCost .. " fortitude required to train " .. skillSelection .. " for that long.")
                end
                switch = 0
                log:debug("You lack the " .. fatCost .. " fortitude required to train " .. skillSelection .. " for that long.")
            end
            --Training Success--
            if switch == 1 then
                skillType = "Fatigue"
                if hthSwitch == 1 then
                    skillType = "Health"
                end
                tes3ui.leaveMenuMode()
                menu:destroy()
                rMenu:destroy()
                tes3.fadeOut({ duration = 0.5 })
                timer.start({ duration = config.trainCDtime, callback = "dailyTraining:cooldownElapsed",
                    type = timer.game, persist = true })
                log:debug("Cooldown began for " .. config.trainCDtime .. " hours.")
                modData.cooldown = 1
                local fillMenu = tes3ui.createMenu { id = id_fillBarMenu, fixedFrame = true }
                local fillBar = fillMenu:createFillBar({ id = id_fillBar, current = 0, max = hourText })
                fillBar.widget.showText = true
                if hthSwitch == 0 then
                    fillBar.widget.fillColor = { 0.2, 0.6, 0.2 }
                end
                timer.start({ type = timer.real, duration = 1, iterations = hourText, callback = trainTime })
            end
        end
    end
end

--Menu Cancel---------------------------------------------------------------------------------
local function onCancel(e)
    local menu = tes3ui.findMenu(id_menu)
    if (menu) then
        tes3ui.leaveMenuMode()
        menu:destroy()
    end
    skillNumber = 40
end

--Training Menu----------------------------------------------------------------------------------
local function trainMenu(e)
    local modData = getModData(tes3.player)
    local rMenu = tes3ui.findMenu("MenuRestWait")
    hourText = tonumber(rMenu:findChild("MenuRestWait_hour_text").text)
    skillNumber = 40

    -- Create window and frame
    local menu = tes3ui.createMenu { id = id_menu, fixedFrame = true, modal = true }
    menu.alpha = 1.0

    -- Create layout
    local hourLabel = menu:createLabel { id = id_labelHour, text = "You decided to train for " .. hourText .. " hours." }
    if hourText == 1 then
        hourLabel.text = "You decided to train for " .. hourText .. " hour."
    end
    hourLabel.borderBottom = 10

    local main_block = menu:createBlock { id = "main_block" }
    main_block.autoWidth = true
    main_block.autoHeight = true
    main_block.flowDirection = "top_to_bottom"

    local bord = main_block:createThinBorder {}
    bord.width = 673
    bord.height = 197
    bord.borderBottom = 20
    bord.paddingAllSides = 2
    local border = bord:createThinBorder { id = "kl_border" }
    border.width = 669
    border.height = 193
    border.paddingAllSides = 4

    local inner = border:createBlock { id = id_blockInner }
    inner.height = 192
    inner.width = 668
    inner.paddingAllSides = 10
    inner.flowDirection = "left_to_right"

    local combat = inner:createBlock { id = id_blockCombat }
    combat.height = 192
    combat.width = 150
    combat.flowDirection = "top_to_bottom"

    local cPer = inner:createBlock {}
    cPer.flowDirection = "top_to_bottom"
    cPer.height = 192
    cPer.width = 40

    local magic = inner:createBlock { id = id_blockMagic }
    magic.height = 192
    magic.width = 150
    magic.borderLeft = 40
    magic.flowDirection = "top_to_bottom"

    local mPer = inner:createBlock {}
    mPer.flowDirection = "top_to_bottom"
    mPer.height = 192
    mPer.width = 40
    mPer.borderRight = 40

    local stealth = inner:createBlock { id = id_blockStealth }
    stealth.height = 192
    stealth.width = 150
    stealth.flowDirection = "top_to_bottom"

    local sPer = inner:createBlock {}
    sPer.flowDirection = "top_to_bottom"
    sPer.height = 192
    sPer.width = 40

    --Skill List--
    local skillProg = tes3.mobilePlayer.skillProgress
    for i = 0, 8 do
        local b = combat:createTextSelect { text = "" .. tes3.skillName[i] .. "", id = "sTrainB_" .. i .. "" }
        local p = cPer:createLabel { text = "" .. math.round((skillProg[i + 1] / tes3.mobilePlayer:getSkillProgressRequirement(i)) * 100) .. "%", id = "sTrainP_" .. i .. "" }
        if config.noColor == false then
            b.widget.idleActive = { 0.6, 0.6, 0.0 }
        end
        b:register("mouseClick", function() onSelect(i) end)
    end
    for i = 9, 17 do
        local b = magic:createTextSelect { text = "" .. tes3.skillName[i] .. "", id = "sTrainB_" .. i .. "" }
        local p = mPer:createLabel { text = "" .. math.round((skillProg[i + 1] / tes3.mobilePlayer:getSkillProgressRequirement(i)) * 100) .. "%", id = "sTrainP_" .. i .. "" }
        if config.noColor == false then
            b.widget.idleActive = { 0.6, 0.6, 0.0 }
        end
        b:register("mouseClick", function() onSelect(i) end)
    end
    for i = 18, 26 do
        local b = stealth:createTextSelect { text = "" .. tes3.skillName[i] .. "", id = "sTrainB_" .. i .. "" }
        local p = sPer:createLabel { text = "" .. math.round((skillProg[i + 1] / tes3.mobilePlayer:getSkillProgressRequirement(i)) * 100) .. "%", id = "sTrainP_" .. i .. "" }
        if config.noColor == false then
            b.widget.idleActive = { 0.6, 0.6, 0.0 }
        end
        b:register("mouseClick", function() onSelect(i) end)
    end

    --Colorize--
    if config.noColor == false then
        for i = 9, 15 do
            local b = inner:findChild("sTrainB_" .. i .. "")
            local p = inner:findChild("sTrainP_" .. i .. "")
            b.widget.idle = { 0.3, 0.3, 0.7 }
            p.color = { 0.3, 0.3, 0.7 }
        end

        for i = 2, 3 do
            local b = inner:findChild("sTrainB_" .. i .. "")
            local p = inner:findChild("sTrainP_" .. i .. "")
            b.widget.idle = { 0.6, 0.2, 0.2 }
            p.color = { 0.6, 0.2, 0.2 }
        end

        local c = inner:findChild("sTrainB_21")
        local p_1 = inner:findChild("sTrainP_21")
        c.widget.idle = { 0.6, 0.2, 0.2 }
        p_1.color = { 0.6, 0.2, 0.2 }

        local c_2 = inner:findChild("sTrainB_17")
        local p_2 = inner:findChild("sTrainP_17")
        c_2.widget.idle = { 0.6, 0.2, 0.2 }
        p_2.color = { 0.6, 0.2, 0.2 }

        for i = 0, 1 do
            local b = inner:findChild("sTrainB_" .. i .. "")
            local p = inner:findChild("sTrainP_" .. i .. "")
            b.widget.idle = { 0.2, 0.6, 0.2 }
            p.color = { 0.2, 0.6, 0.2 }
        end

        for i = 4, 8 do
            local b = inner:findChild("sTrainB_" .. i .. "")
            local p = inner:findChild("sTrainP_" .. i .. "")
            b.widget.idle = { 0.2, 0.6, 0.2 }
            p.color = { 0.2, 0.6, 0.2 }
        end

        for i = 18, 20 do
            local b = inner:findChild("sTrainB_" .. i .. "")
            local p = inner:findChild("sTrainP_" .. i .. "")
            b.widget.idle = { 0.2, 0.6, 0.2 }
            p.color = { 0.2, 0.6, 0.2 }
        end

        for i = 22, 26 do
            local b = inner:findChild("sTrainB_" .. i .. "")
            local p = inner:findChild("sTrainP_" .. i .. "")
            b.widget.idle = { 0.2, 0.6, 0.2 }
            p.color = { 0.2, 0.6, 0.2 }
        end

        local c_3 = inner:findChild("sTrainB_16")
        local p_3 = inner:findChild("sTrainP_16")
        c_3.widget.idle = { 0.2, 0.6, 0.2 }
        p_3.color = { 0.2, 0.6, 0.2 }
    end

    if config.townTrain == false and tes3.getPlayerCell().restingIsIllegal then
        if config.townSkills == true then
            for i = 0, 26 do
                if (i == 20 or i == 16 or i == 1 or i == 8 or i == 24 or i == 18 or i == 19 or i == 25 or i == 9) then
                    --do nothing
                else
                    local b = menu:findChild("sTrainB_" .. i .. "")
                    b.disabled = true
                    b.widget.state = tes3.uiState.disabled
                    local p = menu:findChild("sTrainP_" .. i .. "")
                    p.color = { 0.702, 0.659, 0.529 }
                end
            end
        else
            for i = 0, 26 do
                local b = menu:findChild("sTrainB_" .. i .. "")
                b.disabled = true
                b.widget.state = tes3.uiState.disabled
                local p = menu:findChild("sTrainP_" .. i .. "")
                p.color = { 0.702, 0.659, 0.529 }
            end
        end
    end

    --Skill Info--
    local skillLabel = main_block:createLabel { id = id_labelSkill, text = "Select skill to train." }
    skillLabel.wrapText = true
    skillLabel.justifyText = tes3.justifyText.center
    if config.townTrain == false then
        skillLabel.text = "Unable to train in public."
        if config.townSkills == true then
            skillLabel.text = "Select public skill to train."
        end
    end
    local selectLabel = main_block:createLabel { id = id_labelProgress, text = " " }
    selectLabel.wrapText = true
    selectLabel.justifyText = tes3.justifyText.center
    local expBonusLabel = main_block:createLabel({ id = id_labelEfficiency, text = " " })
    expBonusLabel.wrapText = true
    expBonusLabel.justifyText = tes3.justifyText.center
    local sesLabel = main_block:createLabel { id = id_labelSession, text = " " }
    sesLabel.wrapText = true
    sesLabel.justifyText = tes3.justifyText.center

    local line = main_block:createDivider()
    line.borderTop = 10
    line.borderBottom = 9

    --Streak Info--
    local streakLabel = main_block:createLabel({ text = "Streak Skill: " .. modData.streakSkill .. "" })
    streakLabel.wrapText = true
    streakLabel.justifyText = tes3.justifyText.center
    local streakTotal = main_block:createLabel({ text = "Streak Amount: " .. modData.streak .. " days" })
    streakTotal.wrapText = true
    streakTotal.justifyText = tes3.justifyText.center

    --Buttons--
    local button_block = menu:createBlock {}
    button_block.widthProportional = 1.0 -- width is 100% parent width
    button_block.autoHeight = true
    button_block.childAlignX = 1.0 -- right content alignment
    button_block.borderTop = 25

    local button_ok = button_block:createButton { id = id_btnOk, text = tes3.findGMST("sOK").value }
    local button_cancel = button_block:createButton { id = id_btnCancel, text = tes3.findGMST("sCancel").value }

    -- Events
    menu:register(tes3.uiEvent.keyEnter, onOK)
    button_ok:register(tes3.uiEvent.mouseClick, onOK)
    button_cancel:register(tes3.uiEvent.mouseClick, onCancel)

    -- Final setup
    menu:updateLayout()
    tes3ui.enterMenuMode(id_menu)
end


--Rest Menu Training Button------------------------------------------------------------------------------
local function trainButton(e)
    local window = e.element:findChild(tes3ui.registerID("MenuRestWait"))
    local windowC = window:findChild(tes3ui.registerID("PartNonDragMenu_main"))
    windowC.minWidth = 312
    local windowB = e.element:findChild(tes3ui.registerID("MenuRestWait_buttonlayout"))
    local tButton = windowB:createButton({ id = "kl_daily_button_id", text = "Train" })
    tButton.borderAllSides = 0
    tButton.borderLeft = 3
    windowB:reorderChildren(-2, -1, 1)
    window:updateLayout()
    tButton:register(tes3.uiEvent.mouseClick, trainMenu)
end

event.register(tes3.event.uiActivated, trainButton, { filter = "MenuRestWait" })





--Config Stuff------------------------------------------------------------------------------------------------------------------------------
event.register("modConfigReady", function()
    require("dailyTraining.mcm")
    config = require("dailyTraining.config")
end)