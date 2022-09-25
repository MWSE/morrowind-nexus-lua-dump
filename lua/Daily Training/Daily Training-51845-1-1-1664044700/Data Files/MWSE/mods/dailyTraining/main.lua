--Initialize------------------------------------------------
local config = require("dailyTraining.config")
local strings = require("dailyTraining.strings")
local logger = require("logging.logger")
local skillSelection = ""
local skillNumber = 40
local skillType = ""
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
local id_menu = tes3ui.registerID("kl_train_menu")
local id_label = tes3ui.registerID("kl_train_label_1")
local id_label2 = tes3ui.registerID("kl_train_label_2")
local id_pane = tes3ui.registerID("kl_train_pane")
local id_ok = tes3ui.registerID("kl_train_ok")
local id_cancel = tes3ui.registerID("kl_train_cancel")
local id_fillMenu = tes3ui.registerID("kl_fill_menu")
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
    modData.cooldown = 0
    if (config.trainCD == true and config.cdMessages == true) then
        tes3.messageBox("" .. strings.cdFlavor[math.random(1, 30)] .. "")
    end
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
        tes3.messageBox("" .. modData.streakSkill .. " training streak lost!")
        modData.streakSkill = ""
        log:debug("Training streak lost!")
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
            tes3.createReference({ object = tes3.getObject("ex_molagmar_sleep"):pickFrom(),
                position = cameraPosition,
                cell = cell })
            spawns = spawns + 1
            log:debug("Ashlands creature spawned!")
        end
        if (cell.displayName == "Ascadian Isles Region" and spawns == 0) then
            tes3.createReference({ object = tes3.getObject("ex_ascadianisles_sleep"):pickFrom(),
                position = cameraPosition,
                cell = cell })
            spawns = spawns + 1
            log:debug("Ascadian Isles creature spawned!")
        end
        if (cell.displayName == "Azura's Coast Region" and spawns == 0) then
            tes3.createReference({ object = tes3.getObject("ex_azurascoast_sleep"):pickFrom(),
                position = cameraPosition,
                cell = cell })
            spawns = spawns + 1
            log:debug("Azura's Coast creature spawned!")
        end
        if (cell.displayName == "Bitter Coast Region" and spawns == 0) then
            tes3.createReference({ object = tes3.getObject("ex_bittercoast_sleep"):pickFrom(),
                position = cameraPosition,
                cell = cell })
            spawns = spawns + 1
            log:debug("Bitter Coast creature spawned!")
        end
        if (cell.displayName == "Grazelands Region" and spawns == 0) then
            tes3.createReference({ object = tes3.getObject("ex_grazelands_sleep"):pickFrom(),
                position = cameraPosition,
                cell = cell })
            spawns = spawns + 1
            log:debug("Grazelands creature spawned!")
        end
        if (cell.displayName == "Molag Amur Region" and spawns == 0) then
            tes3.createReference({ object = tes3.getObject("ex_molagmar_sleep"):pickFrom(),
                position = cameraPosition,
                cell = cell })
            spawns = spawns + 1
            log:debug("Molag Amur creature spawned!")
        end
        if (cell.displayName == "Red Mountain Region" and spawns == 0) then
            tes3.createReference({ object = tes3.getObject("ex_RedMtn_all_sleep"):pickFrom(),
                position = cameraPosition,
                cell = cell })
            spawns = spawns + 1
            log:debug("Red Mountain creature spawned!")
        end
        if (cell.displayName == "Sheogorad Region" and spawns == 0) then
            tes3.createReference({ object = tes3.getObject("ex_sheogorad_sleep"):pickFrom(),
                position = cameraPosition,
                cell = cell })
            spawns = spawns + 1
            log:debug("Sheogorad creature spawned!")
        end
        if (cell.displayName == "West Gash Region" and spawns == 0) then
            tes3.createReference({ object = tes3.getObject("ex_westgash_sleep"):pickFrom(),
                position = cameraPosition,
                cell = cell })
            spawns = spawns + 1
            log:debug("West Gash creature spawned!")
        end
        if (string.startswith(cell.displayName, "Solstheim") and spawns == 0) then
            tes3.createReference({ object = tes3.getObject("bm_ex_isinplains_sleep"):pickFrom(),
                position = cameraPosition,
                cell = cell })
            spawns = spawns + 1
            log:debug("Solstheim creature spawned!")
        end
        if (spawns == 0) then
            tes3.createReference({ object = tes3.getObject("ex_wild_all_sleep"):pickFrom(),
                position = cameraPosition,
                cell = cell })
            spawns = spawns + 1
            log:debug("Generic exterior creature spawned!")
        end
    end
    timer.delayOneFrame(function()
        timer.delayOneFrame(function()
            timer.delayOneFrame(function()
                ambushFlag = 0
                tes3.messageBox("Your training has been interrupted.")
            end)
        end)
    end)
end

--End Training------------------------------------------------
local function fadeIn(e)
    local menu = tes3ui.findMenu(id_fillMenu)
    menu:destroy()
    tes3ui.leaveMenuMode()
    tes3.fadeIn({ duration = 0.5 })
    log:debug("Training complete.")
end

--Training----------------------------------------------------
local function trainTime()
    if ambushFlag == 1 then return end
    if tes3ui.findMenu(id_fillMenu) == nil then return end
    local menu = tes3ui.findMenu(id_fillMenu)
    local bar = menu:findChild(id_fillBar)
    bar.widget.current = (bar.widget.current + 1)
    menu:updateLayout()
    local gameHour = tes3.getGlobal('GameHour')
    gameHour = gameHour + 1
    tes3.setGlobal('GameHour', gameHour)
    if config.trainCost == true then
        tes3.modStatistic({ name = skillType, current = (costPerHr * -1), reference = tes3.mobilePlayer })
    end
    tes3.player.mobile:exerciseSkill(skillNumber, (config.expMod * 0.1))
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
            local modData = getModData(tes3.player)
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
                    tes3.messageBox("You gained a little experience through consistently training " ..
                        skillSelection .. " for " .. modData.streak .. " days!")
                end
                if (modData.streak >= 7 and modData.streak < 30) then
                    tes3.player.mobile:exerciseSkill(skillNumber, ((config.expMod * 0.1) * 2))
                    tes3.messageBox("You gained a fair amount of experience through consistently training " ..
                        skillSelection .. " for " .. modData.streak .. " days!")
                end
                if (modData.streak >= 30 and modData.streak < 180) then
                    tes3.player.mobile:exerciseSkill(skillNumber, ((config.expMod * 0.1) * 3))
                    tes3.messageBox("You gained a modest amount of experience through consistently training " ..
                        skillSelection .. " for " .. modData.streak .. " days!")
                end
                if (modData.streak >= 180 and modData.streak < 365) then
                    tes3.player.mobile:exerciseSkill(skillNumber, ((config.expMod * 0.1) * 4))
                    tes3.messageBox("You gained a considerable amount of experience through consistently training " ..
                        skillSelection .. " for " .. modData.streak .. " days!")
                end
                if (modData.streak >= 365) then
                    tes3.player.mobile:exerciseSkill(skillNumber, ((config.expMod * 0.1) * 5))
                    tes3.messageBox("You gained a vast amount of experience through consistently training " ..
                        skillSelection .. " for " .. modData.streak .. " days!")
                end
                log:debug("Streak bonus applied! " .. modData.streak .. " day streak!")
            end
            log:debug("Streak is " .. modData.streak .. ".")
            if (modData.streakSkill == skillSelection) then
                modData.lastTrained = 0
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
    local label = menu:findChild(id_label)
    local label2 = menu:findChild(id_label2)
    local pane = menu:findChild(id_pane)
    local rMenu = tes3ui.findMenu("MenuRestWait")
    local hourText = tonumber(rMenu:findChild("MenuRestWait_hour_text").text)
    if (menu) then
        local id = pane:findChild("sTrainB_" .. i .. "")
        for n = 0, 26 do
            local id2 = pane:findChild("sTrainB_" .. n .. "")
            if id2.widget.state == 4 then
                id2.widget.state = 1
            end
        end
        id.widget.state = 4
        skillSelection = id.text
        skillNumber = i
        skillType = "fatigue"
        local skillStat = tes3.player.mobile:getSkillStatistic(skillNumber)
        costPerHr = math.round((skillStat.base * 0.1) * config.costMultF)
        if (skillNumber == 9 or skillNumber == 10 or skillNumber == 11 or skillNumber == 12 or skillNumber == 13 or
            skillNumber == 14 or skillNumber == 15) then
            skillType = "magicka"
            costPerHr = math.round((skillStat.base * 0.1) * config.costMultM)
        end
        if (skillNumber == 2 or skillNumber == 3 or skillNumber == 17 or skillNumber == 21) then
            skillType = "health"
            costPerHr = math.round((skillStat.base * 0.1) * config.costMultH)
        end
        local cost = (costPerHr * hourText)
        if config.trainCost == false then
            cost = 0
        end
        if (skillType == "health" or skillType == "fatigue") then
            local endLimit = math.round((tes3.mobilePlayer.endurance.current * 0.1) * (config.endMod * 0.1))
            label.text = "Endurance Session Hours: " .. endLimit .. ""
            label2.text = "" .. skillSelection .. " " .. skillType .. " cost: " .. cost .. ""
        else
            local wilLimit = math.round((tes3.mobilePlayer.willpower.current * 0.1) * (config.wilMod * 0.1))
            label.text = "Willpower Session Hours: " .. wilLimit .. ""
            label2.text = "" .. skillSelection .. " " .. skillType .. " cost: " .. cost .. ""
        end
        menu:updateLayout()
    end
end

--On Menu OK-----------------------------------------------------------------------------------------------
local function onOK(e)
    if skillNumber == 40 then
        tes3.messageBox("Please select a skill.")
        return
    end
    local menu = tes3ui.findMenu(id_menu)
    local rMenu = tes3ui.findMenu("MenuRestWait")
    local hourText = tonumber(rMenu:findChild("MenuRestWait_hour_text").text)
    local modData = getModData(tes3.player)
    local endLimit = math.round((tes3.mobilePlayer.endurance.current * 0.1) * (config.endMod * 0.1))
    log:trace("Endurance Limit: " .. endLimit .. " hours.")
    local wilLimit = math.round((tes3.mobilePlayer.willpower.current * 0.1) * (config.wilMod * 0.1))
    log:trace("Willpower Limit: " .. wilLimit .. " hours.")
    local skillStat = tes3.player.mobile:getSkillStatistic(skillNumber)
    if (menu) then
        --Training Success Switch-----------------------------------------------------------------------------------------
        local switch = 1
        --Magic Skills-----------------------------------------------------------------------------------------------
        if (skillNumber == 9 or skillNumber == 10 or skillNumber == 11 or skillNumber == 12 or skillNumber == 13 or
            skillNumber == 14 or skillNumber == 15) then

            log:debug("Magic skill selected. Skill Number: " .. skillNumber .. "")
            --Cooldown--
            if (modData.cooldown == 1 and config.trainCD == true) then
                tes3.messageBox("You require rest before training again.")
                switch = 0
                log:debug("Training still on cooldown.")
            end
            --Town Training allowed?--
            if (config.townTrain == false and switch == 1) then
                local cell = tes3.getPlayerCell()
                if cell.restingIsIllegal then
                    tes3.messageBox("You cannot train in public areas!")
                    switch = 0
                    log:debug("Cannot train in public areas!")
                end
            end
            --Skill Limit?--
            if (config.skillLimit == true and switch == 1) then
                if (skillStat.base >= config.skillMax) then
                    tes3.messageBox("You're too knowledgeable to train the " ..
                        skillSelection .. " skill through simple practice!")
                    switch = 0
                    log:debug("Cannot train expert skill! Skill Number: " .. skillNumber .. "")
                end
            end
            --Willpower Limit?--
            if (hourText > wilLimit and switch == 1 and config.sessionLimit == true) then
                tes3.messageBox("You lack the will to train " .. skillSelection .. " beyond " .. wilLimit .. " hours.")
                switch = 0
                log:debug("You lack the will to train " .. skillSelection .. " beyond " .. wilLimit .. " hours.")
            end
            --Costs--
            costPerHr = math.round((skillStat.base * 0.1) * config.costMultM)
            log:trace("Cost per hour recalculated as " .. costPerHr .. ".")
            local mgkCost = (hourText * costPerHr)
            log:trace("Total Magicka cost calculated as " .. mgkCost .. ".")
            if (tes3.mobilePlayer.magicka.current < mgkCost and switch == 1) then
                tes3.messageBox("You lack the " ..
                    mgkCost .. " magicka required to train " .. skillSelection .. " for that long.")
                switch = 0
                log:debug("You lack the " ..
                    mgkCost .. " magicka required to train " .. skillSelection .. " for that long.")
            end
            --Training Success--
            if switch == 1 then
                skillType = "magicka"
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
                tes3.messageBox("You require rest before training again.")
                switch = 0
                log:debug("Training still on cooldown.")
            end
            --Town Training Allowed?--
            if (config.townTrain == false and switch == 1) then
                local cell = tes3.getPlayerCell()
                if cell.restingIsIllegal then
                    tes3.messageBox("You cannot train in public areas!")
                    switch = 0
                    log:debug("Cannot train in public areas!")
                end
            end
            --Skill Limit?--
            if (config.skillLimit == true and switch == 1) then
                if (skillStat.base >= config.skillMax) then
                    tes3.messageBox("You're too knowledgeable to train the " ..
                        skillSelection .. " skill through simple practice!")
                    switch = 0
                    log:debug("Cannot train expert skill! Skill Number: " .. skillNumber .. "")
                end
            end
            --Endurance Limit?--
            if (hourText > endLimit and switch == 1 and config.sessionLimit == true) then
                tes3.messageBox("You lack the endurance to train " ..
                    skillSelection .. " beyond " .. endLimit .. " hours.")
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
                tes3.messageBox("You lack the " ..
                    fatCost .. " stamina required to train " .. skillSelection .. " for that long.")
                switch = 0
                log:debug("You lack the " ..
                    fatCost .. " stamina required to train " .. skillSelection .. " for that long.")
            end
            if (tes3.mobilePlayer.health.current <= fatCost and switch == 1 and hthSwitch == 1) then
                tes3.messageBox("You lack the " ..
                    fatCost .. " fortitude required to train " .. skillSelection .. " for that long.")
                switch = 0
                log:debug("You lack the " ..
                    fatCost .. " fortitude required to train " .. skillSelection .. " for that long.")
            end
            --Training Success--
            if switch == 1 then
                skillType = "fatigue"
                if hthSwitch == 1 then
                    skillType = "health"
                end
                tes3ui.leaveMenuMode()
                menu:destroy()
                rMenu:destroy()
                tes3.fadeOut({ duration = 0.5 })
                timer.start({ duration = config.trainCDtime, callback = "dailyTraining:cooldownElapsed",
                    type = timer.game, persist = true })
                log:debug("Cooldown began for " .. config.trainCDtime .. " hours.")
                modData.cooldown = 1
                local fillMenu = tes3ui.createMenu { id = id_fillMenu, fixedFrame = true }
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
    -- Create window and frame
    local menu = tes3ui.createMenu { id = id_menu, fixedFrame = true }
    --menu.minWidth = 440

    -- Create layout
    local input_label = menu:createLabel { id = id_label, text = "You decide to train." }
    local input_label2 = menu:createLabel { id = id_label2, text = "Select skill to train." }
    input_label2.borderBottom = 5

    local pane_block = menu:createBlock { id = "pane_block" }
    pane_block.autoWidth = true
    pane_block.autoHeight = true
    pane_block.flowDirection = "top_to_bottom"

    local border = pane_block:createThinBorder { id = "kl_border" }
    border.positionX = 4
    border.positionY = -4
    border.width = 220
    border.height = 480
    border.borderAllSides = 4
    border.paddingAllSides = 4

    local pane = border:createVerticalScrollPane { id = id_pane }
    pane.height = 480
    pane.width = 220
    pane.positionX = 4
    pane.positionY = -4
    pane.widget.scrollbarVisible = true

    --Skill List--
    for i = 0, 8 do
        local b = pane:createTextSelect { text = tes3.skillName[i], id = "sTrainB_" .. i .. "" }
        if config.noColor == false then
            b.widget.idleActive = { 0.6, 0.6, 0.0 }
        end
        b:register("mouseClick", function() onSelect(i) end)
    end
    local line = pane:createDivider()
    for i = 9, 17 do
        local b = pane:createTextSelect { text = tes3.skillName[i], id = "sTrainB_" .. i .. "" }
        if config.noColor == false then
            b.widget.idleActive = { 0.6, 0.6, 0.0 }
        end
        b:register("mouseClick", function() onSelect(i) end)
    end
    local line2 = pane:createDivider()
    for i = 18, 26 do
        local b = pane:createTextSelect { text = tes3.skillName[i], id = "sTrainB_" .. i .. "" }
        if config.noColor == false then
            b.widget.idleActive = { 0.6, 0.6, 0.0 }
        end
        b:register("mouseClick", function() onSelect(i) end)
    end

    --Colorize--
    if config.noColor == false then
        for i = 9, 15 do
            local b = pane:findChild("sTrainB_" .. i .. "")
            b.widget.idle = { 0.2, 0.2, 0.6 }
        end

        for i = 2, 3 do
            local b = pane:findChild("sTrainB_" .. i .. "")
            b.widget.idle = { 0.6, 0.2, 0.2 }
        end

        local c = pane:findChild("sTrainB_21")
        c.widget.idle = { 0.6, 0.2, 0.2 }

        local c_2 = pane:findChild("sTrainB_17")
        c_2.widget.idle = { 0.6, 0.2, 0.2 }

        for i = 0, 1 do
            local b = pane:findChild("sTrainB_" .. i .. "")
            b.widget.idle = { 0.2, 0.6, 0.2 }
        end

        for i = 4, 8 do
            local b = pane:findChild("sTrainB_" .. i .. "")
            b.widget.idle = { 0.2, 0.6, 0.2 }
        end

        for i = 18, 20 do
            local b = pane:findChild("sTrainB_" .. i .. "")
            b.widget.idle = { 0.2, 0.6, 0.2 }
        end

        for i = 22, 26 do
            local b = pane:findChild("sTrainB_" .. i .. "")
            b.widget.idle = { 0.2, 0.6, 0.2 }
        end

        local c_3 = pane:findChild("sTrainB_16")
        c_3.widget.idle = { 0.2, 0.6, 0.2 }
    end

    --Streak Info--
    local streakLabel = pane_block:createLabel({ text = "Streak Skill: " .. modData.streakSkill .. "" })
    local streakTotal = pane_block:createLabel({ text = "Streak Amount: " .. modData.streak .. " days." })

    --Buttons--
    local button_block = menu:createBlock {}
    button_block.widthProportional = 1.0 -- width is 100% parent width
    button_block.autoHeight = true
    button_block.childAlignX = 1.0 -- right content alignment
    button_block.borderTop = 5

    local button_ok = button_block:createButton { id = id_ok, text = tes3.findGMST("sOK").value }
    local button_cancel = button_block:createButton { id = id_cancel, text = tes3.findGMST("sCancel").value }

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
    local tButton = windowB:createButton({ id = "kl_train_button_id", text = "Train" })
    tButton.borderAllSides = 0
    tButton.borderLeft = 3
    window:updateLayout()
    tButton:register(tes3.uiEvent.mouseClick, trainMenu)
end

event.register(tes3.event.uiActivated, trainButton, { filter = "MenuRestWait" })

--Config Stuff------------------------------------------------------------------------------------------------------------------------------
event.register("modConfigReady", function()
    require("dailyTraining.mcm")
    config = require("dailyTraining.config")
end)
