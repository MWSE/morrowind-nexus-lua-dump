----Initialize----------------------------------------------------------------------------------------------------------
local config = require("companionLeveler.config")
local tables = require("companionLeveler.tables")
local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.functions.common")
local spells = require("companionLeveler.functions.spells")
local abilities = require("companionLeveler.functions.abilities")
local sumr = require("companionLeveler.menus.summary")


local creClassMode = {}

--
----Creature Class Mode----------------------------------------------------------------------------------------------------------------------
--
function creClassMode.levelUp(companions)
    log = logger.getLogger("Companion Leveler")
    local leveled = 0

    for i = #companions, 1, -1 do
        local companionRef = companions[i]
        local modData = func.getModData(companionRef)
        if modData.blacklist == false then
            leveled = leveled + 1
            local name = companionRef.object.name
            log:debug("" .. name .. " is Creature #" .. i .. ".")
            local attTable = companionRef.mobile.attributes
            ----Level Increased by 1------------------------------------------------------------------------------------------------------
            modData.level = modData.level + 1
            log:debug("" .. name .. "'s level data increased by 1.")
            func.calcEXP(companionRef)
            local storedLevel = modData.level
            local storedTlevel = 0
            ----Creature Class Mode-----------------------------------------------------------------------------------------------
            local selectionMgk = 0
            local selectionHth = 0
            local cName = modData.type
            log:info("" .. name .. " is a " .. cName .. " type creature.")
            local trainedAtt1 = 0
            local trainedAtt2 = 0
            local chance = config.spellChanceC
            for n = 1, #tables.typeTable do
                if tables.typeTable[n] == cName then
                    modData.typelevels[n] = modData.typelevels[n] + 1
                    storedTlevel = modData.typelevels[n]
                    trainedAtt1 = tables.typeStat1[n]
                    trainedAtt2 = tables.typeStat2[n]
                    if cName == "Daedra" then
                        chance = chance + 2
                    end
                    if cName == "Undead" then
                        chance = chance + 2
                    end
                    if cName == "Humanoid" then
                        chance = chance + 10
                    end
                    if cName == "Spriggan" then
                        chance = chance + 5
                    end
                    if cName == "Spectral" then
                        chance = chance + 5
                    end
                    if cName == "Draconic" then
                        if modData.level % 2 ~= 0 then
                            chance = 0
                        else
                            chance = chance + 5
                        end
                    end
                    if cName == "Aquatic" then
                        chance = chance + 2
                    end
                    if cName == "Impish" then
                        chance = chance + 5
                    end
                end
            end
            log:info("" .. name .. "'s " .. cName .. " level increased by 1.")
            ----Spell/Ability Learning----------------------------------------------------------------------------------------------------
            if (config.spellLearningC == true and modData.spellLearning == true) then
                if math.random(0, 99) < chance then
                    spells.creatureSpellRoll(modData.level, cName, companionRef)
                end
            end
            
            if (config.abilityLearning == true and modData.abilityLearning == true) then
                abilities.creatureAbilities(cName, companionRef)
            end

            --Technique Points
            modData.tp_max = modData.tp_max + 1
            modData.tp_current = modData.tp_max
            ----1st major attribute trained-------------------------------------------------------------------------------------------------
            local mAtt1 = tables.capitalization[trainedAtt1]
            local min1 = config.minMajorAtt1
            local max1 = config.maxMajorAtt1
            
            if min1 > max1 then
                max1 = min1
            end

            local mAttMod1 = math.random(min1, max1)
            local tAtt1 = attTable[trainedAtt1 + 1]

            if cName == "Brute" then
                mAttMod1 = mAttMod1 + 2
                log:debug("Brute Type Bonus to Primary Attribute rewarded to " .. name .. ".")
            end

            if cName == "Domestic" or cName == "Impish" then
                mAttMod1 = mAttMod1 + 1
                log:debug("Domestic/Impish Type Bonus to Primary Attribute rewarded to " .. name .. ".")
            end

            if config.aboveMaxAtt == false then
                if tAtt1.base + mAttMod1 > 100 then
                    mAttMod1 = math.max(100 - tAtt1.base, 0)
                end
            end

            if modData.attributeTraining == false then
                mAttMod1 = 0
            end
            tes3.modStatistic({ attribute = trainedAtt1, value = mAttMod1, reference = companionRef })
            modData.att_gained[trainedAtt1 + 1] = modData.att_gained[trainedAtt1 + 1] + mAttMod1
            ----2nd major attribute trained--------------------------------------------------------------------------------------------------
            local mAtt2 = tables.capitalization[trainedAtt2]
            local min2 = config.minMajorAtt2
            local max2 = config.maxMajorAtt2

            if min2 > max2 then
                max2 = min2
            end

            local mAttMod2 = math.random(min2, max2)
            local tAtt2 = attTable[trainedAtt2 + 1]

            if (cName == "Normal" or cName == "Centurion" or cName == "Spriggan" or cName == "Spectral" or cName == "Insectile") then
                mAttMod2 = mAttMod2 + 1
                log:debug("Normal/Centurion/Spriggan/Spectral/Insectile Type Bonus to Secondary Attribute rewarded to " .. name .. ".")
            end

            if config.aboveMaxAtt == false then
                if tAtt2.base + mAttMod2 > 100 then
                    mAttMod2 = math.max(100 - tAtt2.base, 0)
                end
            end

            if modData.attributeTraining == false then
                mAttMod2 = 0
            end
            tes3.modStatistic({ attribute = trainedAtt2, value = mAttMod2, reference = companionRef })
            modData.att_gained[trainedAtt2 + 1] = modData.att_gained[trainedAtt2 + 1] + mAttMod2
            ----random attribute trained------------------------------------------------------------------------------------------------------
            local valueRand
            repeat
                valueRand = math.random(0, 7)
            until (valueRand ~= trainedAtt1 and valueRand ~= trainedAtt2)

            if cName == "Draconic" then
                valueRand = 6
            end

            local mAtt3 = tables.capitalization[valueRand]
            local min3 = config.minRandAtt
            local max3 = config.maxRandAtt

            if min3 > max3 then
                max3 = min3
            end

            local mAttMod3 = math.random(min3, max3)

            if cName == "Brute" then
                if valueRand == 1 or valueRand == 3 then
                    if mAttMod3 < 2 then
                        mAttMod3 = 0
                    else
                        mAttMod3 = mAttMod3 - 2
                    end
                    log:debug("Brute Type Penalty to Agility/Intelligence issued to " .. name .. ".")
                end
            end

            local tAtt3 = attTable[valueRand + 1]

            if config.aboveMaxAtt == false then
                if tAtt3.base + mAttMod3 > 100 then
                    mAttMod3 = math.max(100 - tAtt3.base, 0)
                end
            end

            if modData.attributeTraining == false then
                mAttMod3 = 0
            end
            tes3.modStatistic({ attribute = valueRand, value = mAttMod3, reference = companionRef })
            modData.att_gained[valueRand + 1] = modData.att_gained[valueRand + 1] + mAttMod3
            ----health increased by 1/10th of endurance after training------------------------------------------------------------------------
            local hpMod = companionRef.mobile.endurance.base
            local hpBase = companionRef.mobile.health.base
            local hpChange = (hpMod * (config.healthMod * 0.01))
            if cName == "Impish" then
                hpChange = hpChange / 2
            end
            local hpValue = (hpBase + hpChange)

            if config.levelHealth == true then
                tes3.modStatistic({ name = "health", value = math.round(hpChange), reference = companionRef })
                modData.hth_gained = modData.hth_gained + math.round(hpChange)
                log:info("Leveling " .. name .. "'s health to " .. math.round(hpValue) .. ".")
                selectionHth = 1
            end

            local hpSummary = {
                [0] = "Fortitude remained unchanged",
                [1] = "Increased Fortitude to " .. math.round(hpValue) .. "",
            }
            ----Intelligence increased for guaranteed magicka---------------------------------------------------------------------------------
            local mgkBase = companionRef.mobile.intelligence
            local mgkValue = config.magickaMod

            if config.levelMagicka == true then
                if config.aboveMaxAtt == false then
                    if mgkBase.base + mgkValue > 100 then
                        mgkValue = math.max(100 - mgkBase.base, 0)
                    end
                end
                tes3.modStatistic({ name = "intelligence", value = mgkValue, reference = companionRef })
                modData.att_gained[2] = modData.att_gained[2] + mgkValue
                log:info("Giving " .. mgkValue .. " guaranteed Intelligence to " .. name .. ".")
                if mgkValue > 0 then
                    selectionMgk = 1
                end
            end

            if (mAtt1 == "Intelligence" and mAttMod1 > 0) then
                selectionMgk = 1
            end
            if (mAtt2 == "Intelligence" and mAttMod2 > 0) then
                selectionMgk = 1
            end
            if (mAtt3 == "Intelligence" and mAttMod3 > 0) then
                selectionMgk = 1
            end

            local mgkSummary = {
                [0] = "Magicka reserves remained unchanged.",
                [1] = "Magicka reserves increased to " .. math.round(companionRef.mobile.magicka.base) .. "!",
            }
            ----Derived Stat Mod Data--------------------------------------------------------------------------------------------------------
            modData.mgk_gained = (companionRef.mobile.magicka.base - companionRef.baseObject.magicka)
            modData.fat_gained = (companionRef.mobile.fatigue.base - companionRef.baseObject.fatigue)
            ----Metamorph Skills--------------------------------------------------------------------------------------------------------------
            if companionRef.object.objectType ~= tes3.objectType.creature then
                --Gotta Train Wep/Magic Skills and Unarmored
                local limit = false
                if config.aboveMaxSkill == false then
                    limit = true
                end
                for n = 4, 8 do
                    tes3.modStatistic({ skill = n, value = 2, reference = companionRef, limit = limit })
                end
                for n = 10, 15 do
                    tes3.modStatistic({ skill = n, value = 2, reference = companionRef, limit = limit })
                end
                tes3.modStatistic({ skill = 17, value = 2, reference = companionRef, limit = limit })
                tes3.modStatistic({ skill = 19, value = 2, reference = companionRef, limit = limit })
                tes3.modStatistic({ skill = 20, value = 2, reference = companionRef, limit = limit })
                tes3.modStatistic({ skill = 22, value = 2, reference = companionRef, limit = limit })
                tes3.modStatistic({ skill = 23, value = 2, reference = companionRef, limit = limit })
                tes3.modStatistic({ skill = 26, value = 2, reference = companionRef, limit = limit })
            end
            ----Creature Level up Summary----------------------------------------------------------------------------------------------------------
            if config.levelSummary == true then
                log:debug("" ..
                    name ..
                    "'s [LVL]: " ..
                    storedLevel ..
                    ". [Type]: " ..
                    cName ..
                    ". [HP]: " ..
                    math.round(hpValue) ..
                    " [MP]: " ..
                    companionRef.mobile.magicka.base ..
                    " [Attributes]: " ..
                    mAtt1 ..
                    " + " ..
                    mAttMod1 .. ", " .. mAtt2 .. " + " .. mAttMod2 .. ", " .. mAtt3 .. " + " .. mAttMod3 .. "")
                local abilityString = ""
                for n = 1, #modData.abilities do
                    if modData.abilities[n] == true then
                        abilityString = abilityString .. tes3.getObject(tables.abList[n]).name .. ", "
                    end
                end
                abilityString = string.gsub(abilityString, ", $", ".", 1)
                local regsum = "" ..
                    name ..
                    " ascended to level " ..
                    storedLevel ..
                    "!\n\nType: " ..
                    cName ..
                    " level " ..
                    storedTlevel ..
                    ".\n\n" ..
                    hpSummary[selectionHth] ..
                    ", and " ..
                    mgkSummary[selectionMgk] ..
                    "\n\n" ..
                    name ..
                    " trained their " ..
                    mAtt1 ..
                    " by " ..
                    mAttMod1 ..
                    ", " ..
                    mAtt2 ..
                    " by " ..
                    mAttMod2 .. ", and " .. mAtt3 .. " by " .. mAttMod3 .. "!\n\nAbilities: " .. abilityString .. ""
                modData.summary = regsum
                log:debug("Level Summary triggered from " .. name .. "'s Creature Class Mode.")

                sumr.createWindow(companionRef)

                local menu = tes3ui.findMenu(sumr.id_menu)
                local block = menu:findChild("pane_block_sum")
                local pane = block:findChild(sumr.id_pane)

                local a = pane:createTextSelect { text = "" .. name .. "", id = "sumSelectC_" .. i .. "" }
                a:register("mouseClick", function(e) sumr.onSelectC(i, companionRef) end)

                menu:updateLayout()
            else
                tes3.messageBox("" .. name .. " grew to level " .. storedLevel .. "!")
            end
        end
    end
    if leveled > 0 then
        tes3.playSound({ sound = "skillraise" })
    end

    --Start Hourly Timer
    local modDataP = func.getModDataP()
    if modDataP.hrTimerCreated == false then
        local gameHour = tes3.getGlobal('GameHour')
        local rounded = math.round(gameHour)

        if rounded < gameHour then
            timer.start({ type = timer.game, duration = (rounded + 1) - gameHour, iterations = 1, callback = "companionLeveler:hourlyTimer" })
        else
            timer.start({ type = timer.game, duration = rounded - gameHour, iterations = 1, callback = "companionLeveler:hourlyTimer" })
        end

        modDataP.hrTimerCreated = true
        log:debug("New Hourly Timer created at " .. tes3.getGlobal("GameHour") .. ".")
    end
end

return creClassMode