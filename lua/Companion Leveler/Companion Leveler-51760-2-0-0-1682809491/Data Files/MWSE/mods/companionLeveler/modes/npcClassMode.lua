----Initialize----------------------------------------------------------------------------------------------------------
local config = require("companionLeveler.config")
local tables = require("companionLeveler.tables")
local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.functions.common")
local spells = require("companionLeveler.functions.spells")
local abilities = require("companionLeveler.functions.abilities")
local sumr = require("companionLeveler.menus.summary")


local npcClassMode = {}

--
----NPC Class Mode----------------------------------------------------------------------------------------------------------------------
--
function npcClassMode.companionLevelNPC(companions)
    log = logger.getLogger("Companion Leveler")
    local leveled = 0

    for i = #companions, 1, -1 do
        --Companion Data
        local companionRef = companions[i]
        local modData = func.getModData(companionRef)
        if modData.blacklist == false then
            leveled = leveled + 1
            local name = companionRef.object.name
            local attTable = companionRef.mobile.attributes

            --Level Increased by 1
            modData.level = modData.level + 1
            log:debug("" .. name .. "'s level data increased by 1.")
            func.calcEXP(companionRef)
            local storedLevel = modData.level

            --Class Data
            local class = companionRef.object.class
            if modData.class ~= class.id then
                class = tes3.findClass(modData.class)
            end
            log:debug("" .. name .. "'s class is " .. class.name .. ".")
            log:trace("Fetching " .. name .. "'s class skills...")
            local majSkills = class.majorSkills
            local minSkills = class.minorSkills
            log:trace("Fetching " .. name .. "'s class attributes...")
            local mAttributes = class.attributes

            --Trained Major Skills
            local tSkillMajor1 = majSkills[math.random(1, #majSkills)]
            if tSkillMajor1 == modData.ignore_skill then
                repeat
                    tSkillMajor1 = majSkills[math.random(1, #majSkills)]
                until tSkillMajor1 ~= modData.ignore_skill
            end

            local tSkillMajor2 = majSkills[math.random(1, #majSkills)]
            if tSkillMajor2 == modData.ignore_skill then
                repeat
                    tSkillMajor2 = majSkills[math.random(1, #majSkills)]
                until tSkillMajor2 ~= modData.ignore_skill
            end

            local tSkillMajor3 = majSkills[math.random(1, #majSkills)]
            if tSkillMajor3 == modData.ignore_skill then
                repeat
                    tSkillMajor3 = majSkills[math.random(1, #majSkills)]
                until tSkillMajor3 ~= modData.ignore_skill
            end

            --Trained Minor Skills
            local tSkillMinor1 = minSkills[math.random(1, #minSkills)]
            if tSkillMinor1 == modData.ignore_skill then
                repeat
                    tSkillMinor1 = minSkills[math.random(1, #minSkills)]
                until tSkillMinor1 ~= modData.ignore_skill
            end

            local tSkillMinor2 = minSkills[math.random(1, #minSkills)]
            if tSkillMinor2 == modData.ignore_skill then
                repeat
                    tSkillMinor2 = minSkills[math.random(1, #minSkills)]
                until tSkillMinor2 ~= modData.ignore_skill
            end

            --Trained Favored Attributes
            local trainedAtt1 = mAttributes[1]
            local trainedAtt2 = mAttributes[2]

            ----Mentor Bonus-----------------------------------------------------------------------------------------------------------
            local playerClass = tes3.mobilePlayer.object.class
            log:debug("Player's class is " .. playerClass.name .. ".")
            local trainedSkillP = playerClass.majorSkills[math.random(1, #playerClass.majorSkills)]
            local skillP = companionRef.mobile:getSkillStatistic(trainedSkillP)
            local mSkillP = tes3.skillName[trainedSkillP]
            local mSkillModP = config.mentorBonusMod
            local selectionMen = 0
            if config.mentorBonus == true then
                if math.random(0, 99) < config.mentorChance then
                    selectionMen = 1
                    if config.aboveMaxSkill == false then
                        if skillP.base + mSkillModP > 100 then
                            mSkillModP = math.max(100 - skillP.base, 0)
                        end
                    end
                    tes3.modStatistic({ skill = trainedSkillP, value = mSkillModP, reference = companionRef })
                    modData.skill_gained[trainedSkillP + 1] = modData.skill_gained[trainedSkillP + 1] + mSkillModP
                    log:info("" ..
                        tes3.mobilePlayer.object.name ..
                        " Mentored " .. name .. " in " .. mSkillP .. " by " .. mSkillModP .. ".")
                end
            end
            local menSummary = {
                [0] = "Received no Mentor bonuses.",
                [1] = "" ..
                    tes3.mobilePlayer.object.name ..
                    "'s Mentoring increased " .. tes3.skillName[trainedSkillP] .. " by " .. mSkillModP .. "!"
            }
            ----Racial Bonus-----------------------------------------------------------------------------------------------------------
            log:trace("Fetching " .. name .. "'s Racial information...")
            local race = companionRef.object.race
            local selectionR = 0
            local trainedSkillR = 0
            local rBonusAmount = config.racialBonusMod
            if config.racialBonus == true then
                if math.random(0, 99) < config.racialChance then
                    log:debug("" .. name .. "'s Racial Bonus roll succeeded.")
                    selectionR = 1
                    trainedSkillR = race.skillBonuses[math.random(1, #race.skillBonuses)].skill
                    if (trainedSkillR == nil or trainedSkillR < 0 or trainedSkillR > 26) then
                        trainedSkillR = 8
                        log:warn("" .. name .. "'s chosen Racial Skill returned nil. Reverting to Athletics.")
                    end
                    local rSkill = companionRef.mobile:getSkillStatistic(trainedSkillR)
                    if config.aboveMaxSkill == false then
                        if rSkill.base + rBonusAmount > 100 then
                            rBonusAmount = math.max(100 - rSkill.base, 0)
                        end
                    end
                    tes3.modStatistic({ skill = trainedSkillR, value = rBonusAmount, reference = companionRef })
                    modData.skill_gained[trainedSkillR + 1] = modData.skill_gained[trainedSkillR + 1] + rBonusAmount
                else
                    log:debug("" .. name .. "'s Racial Bonus roll failed.")
                end
            end
            local rSummary = {
                [0] = "Received no Racial bonuses.",
                [1] = "" ..
                    race.name .. " heritage increased " .. tes3.skillName[trainedSkillR] .. " by " .. rBonusAmount .. "!"
            }
            ----Faction Bonus----------------------------------------------------------------------------------------------------------
            local selectionF = 0
            local selectionMgk = 0
            local nFaction = "placeholder"
            local fAttributes = {}
            local fSkills = {}
            local trainedAttF = 0
            local trainedSkillF = 0
            log:trace("Fetching " .. name .. "'s Faction information...")
            local faction = companionRef.object.faction
            local fBonusAmountA = config.factionBonusMod
            local fBonusAmountS = config.factionBonusMod
            if faction ~= nil then
                if config.factionBonus == true then
                    selectionF = 2
                    nFaction = faction.name
                    fAttributes = faction.attributes
                    fSkills = faction.skills
                    trainedAttF = fAttributes[math.random(1, #fAttributes)]
                    trainedSkillF = fSkills[math.random(1, #fSkills)]
                    if (trainedSkillF == nil or trainedSkillF < 0 or trainedSkillF > 26) then
                        trainedSkillF = 8
                        log:warn("" .. name .. "'s chosen Faction Skill returned nil. Reverting to Athletics.")
                    end
                    local fAttName = tables.capitalization[trainedAttF]
                    local fAtt = attTable[trainedAttF + 1]
                    if math.random(0, 99) < config.factionChance then
                        log:debug("" .. name .. "'s Faction Bonus roll succeeded.")
                        log:info("" .. name .. " received a bonus from " .. nFaction .. ".")
                        selectionF = 1
                        if config.aboveMaxAtt == false then
                            if fAtt.base + fBonusAmountA > 100 then
                                fBonusAmountA = math.max(100 - fAtt.base, 0)
                            end
                        end
                        tes3.modStatistic({ attribute = trainedAttF, value = fBonusAmountA, reference = companionRef })
                        modData.att_gained[trainedAttF + 1] = modData.att_gained[trainedAttF + 1] + fBonusAmountA
                        if (fAttName == "Intelligence" and fBonusAmountA > 0) then
                            selectionMgk = 1
                        end
                        local fSkill = companionRef.mobile:getSkillStatistic(trainedSkillF)
                        if config.aboveMaxSkill == false then
                            if fSkill.base + fBonusAmountS > 100 then
                                fBonusAmountS = math.max(100 - fSkill.base, 0)
                            end
                        end
                        tes3.modStatistic({ skill = trainedSkillF, value = fBonusAmountS, reference = companionRef })
                        modData.skill_gained[trainedSkillF + 1] = modData.skill_gained[trainedSkillF + 1] + fBonusAmountS
                    else
                        log:debug("" .. name .. "'s Faction Bonus roll failed.")
                    end
                end
            end
            local fSummary = {
                [0] = "" .. name .. " has no Faction.",
                [1] = "" ..
                    nFaction ..
                    " training increased " ..
                    tables.capitalization[trainedAttF] ..
                    " by " .. fBonusAmountA .. " and " .. tes3.skillName[trainedSkillF] .. " by " .. fBonusAmountS .. "!",
                [2] = "" .. name .. " has received no " .. nFaction .. " training lately."
            }
            ----1st major skill trained------------------------------------------------------------------------------------------------
            local majSkillStat1 = companionRef.mobile:getSkillStatistic(tSkillMajor1)
            local mSkill1 = tes3.skillName[tSkillMajor1]
            local min1 = config.minMajor1
            local max1 = config.maxMajor1
            if min1 > max1 then
                max1 = min1
            end
            local mSkillMod1 = math.random(min1, max1)
            if config.aboveMaxSkill == false then
                if majSkillStat1.base + mSkillMod1 > 100 then
                    mSkillMod1 = math.max(100 - majSkillStat1.base, 0)
                end
            end
            tes3.modStatistic({ skill = tSkillMajor1, value = mSkillMod1, reference = companionRef })
            modData.skill_gained[tSkillMajor1 + 1] = modData.skill_gained[tSkillMajor1 + 1] + mSkillMod1
            log:info("" .. name .. "'s 1st Major Skill in " .. mSkill1 .. " trained by " .. mSkillMod1 .. ".")
            ----2nd major skill trained------------------------------------------------------------------------------------------------
            local majSkillStat2 = companionRef.mobile:getSkillStatistic(tSkillMajor2)
            local mSkill2 = tes3.skillName[tSkillMajor2]
            local min2 = config.minMajor2
            local max2 = config.maxMajor2
            if min2 > max2 then
                max2 = min2
            end
            local mSkillMod2 = math.random(min2, max2)
            if config.aboveMaxSkill == false then
                if majSkillStat2.base + mSkillMod2 > 100 then
                    mSkillMod2 = math.max(100 - majSkillStat2.base, 0)
                end
            end
            tes3.modStatistic({ skill = tSkillMajor2, value = mSkillMod2, reference = companionRef })
            modData.skill_gained[tSkillMajor2 + 1] = modData.skill_gained[tSkillMajor2 + 1] + mSkillMod2
            log:info("" .. name .. "'s 2nd Major Skill in " .. mSkill2 .. " trained by " .. mSkillMod2 .. ".")
            ----3rd major skill trained-------------------------------------------------------------------------------------------------
            local majSkillStat3 = companionRef.mobile:getSkillStatistic(tSkillMajor3)
            local mSkill3 = tes3.skillName[tSkillMajor3]
            local min3 = config.minMajor3
            local max3 = config.maxMajor3
            if min3 > max3 then
                max3 = min3
            end
            local mSkillMod3 = math.random(min3, max3)
            if config.aboveMaxSkill == false then
                if majSkillStat3.base + mSkillMod3 > 100 then
                    mSkillMod3 = math.max(100 - majSkillStat3.base, 0)
                end
            end
            tes3.modStatistic({ skill = tSkillMajor3, value = mSkillMod3, reference = companionRef })
            modData.skill_gained[tSkillMajor3 + 1] = modData.skill_gained[tSkillMajor3 + 1] + mSkillMod3
            log:info("" .. name .. "'s 3rd Major Skill in " .. mSkill3 .. " trained by " .. mSkillMod3 .. ".")
            ----1st Minor Skill Trained-------------------------------------------------------------------------------------------------
            local minSkillStat1 = companionRef.mobile:getSkillStatistic(tSkillMinor1)
            local minSkill1 = tes3.skillName[tSkillMinor1]
            local min4 = config.minMinor1
            local max4 = config.maxMinor1
            if min4 > max4 then
                max4 = min4
            end
            local minSkillMod1 = math.random(min4, max4)
            if config.aboveMaxSkill == false then
                if minSkillStat1.base + minSkillMod1 > 100 then
                    minSkillMod1 = math.max(100 - minSkillStat1.base, 0)
                end
            end
            tes3.modStatistic({ skill = tSkillMinor1, value = minSkillMod1, reference = companionRef })
            modData.skill_gained[tSkillMinor1 + 1] = modData.skill_gained[tSkillMinor1 + 1] + minSkillMod1
            log:info("" .. name .. "'s 1st Minor Skill in " .. minSkill1 .. " trained by " .. minSkillMod1 .. ".")
            ----2nd Minor Skill Trained--------------------------------------------------------------------------------------------------
            local minSkillStat2 = companionRef.mobile:getSkillStatistic(tSkillMinor2)
            local minSkill2 = tes3.skillName[tSkillMinor2]
            local min5 = config.minMinor2
            local max5 = config.maxMinor2
            if min5 > max5 then
                max5 = min5
            end
            local minSkillMod2 = math.random(min5, max5)
            if config.aboveMaxSkill == false then
                if minSkillStat2.base + minSkillMod2 > 100 then
                    minSkillMod2 = math.max(100 - minSkillStat2.base, 0)
                end
            end
            tes3.modStatistic({ skill = tSkillMinor2, value = minSkillMod2, reference = companionRef })
            modData.skill_gained[tSkillMinor2 + 1] = modData.skill_gained[tSkillMinor2 + 1] + minSkillMod2
            log:info("" .. name .. "'s 2nd Minor Skill in " .. minSkill2 .. " trained by " .. minSkillMod2 .. ".")
            ----1st Random Skill Trained--------------------------------------------------------------------------------------------------
            local valueRS1 = math.random(0, 26)
            if valueRS1 == modData.ignore_skill then
                repeat
                    valueRS1 = math.random(0, 26)
                until valueRS1 ~= modData.ignore_skill
            end
            local rSkillStat1 = companionRef.mobile:getSkillStatistic(valueRS1)
            local rSkill1 = tes3.skillName[valueRS1]
            local min6 = config.minRandom1
            local max6 = config.maxRandom1
            if min6 > max6 then
                max6 = min6
            end
            local rSkillMod1 = math.random(min6, max6)
            if config.aboveMaxSkill == false then
                if rSkillStat1.base + rSkillMod1 > 100 then
                    rSkillMod1 = math.max(100 - rSkillStat1.base, 0)
                end
            end
            tes3.modStatistic({ skill = valueRS1, value = rSkillMod1, reference = companionRef })
            modData.skill_gained[valueRS1 + 1] = modData.skill_gained[valueRS1 + 1] + rSkillMod1
            log:info("" .. name .. "'s 1st Random Skill in " .. rSkill1 .. " trained by " .. rSkillMod1 .. ".")
            ----2nd Random Skill Trained---------------------------------------------------------------------------------------------------
            local valueRS2 = math.random(0, 26)
            if valueRS2 == modData.ignore_skill then
                repeat
                    valueRS2 = math.random(0, 26)
                until valueRS2 ~= modData.ignore_skill
            end
            local rSkillStat2 = companionRef.mobile:getSkillStatistic(valueRS2)
            local rSkill2 = tes3.skillName[valueRS2]
            local min7 = config.minRandom2
            local max7 = config.maxRandom2
            if min7 > max7 then
                max7 = min7
            end
            local rSkillMod2 = math.random(min7, max7)
            if config.aboveMaxSkill == false then
                if rSkillStat2.base + rSkillMod2 > 100 then
                    rSkillMod2 = math.max(100 - rSkillStat2.base, 0)
                end
            end
            tes3.modStatistic({ skill = valueRS2, value = rSkillMod2, reference = companionRef })
            modData.skill_gained[valueRS2 + 1] = modData.skill_gained[valueRS2 + 1] + rSkillMod2
            log:info("" .. name .. "'s 2nd Random Skill in " .. rSkill2 .. " trained by " .. rSkillMod2 .. ".")
            ----1st major attribute trained-------------------------------------------------------------------------------------------------
            local mAtt1 = tables.capitalization[trainedAtt1]
            local min8 = config.minMajorAtt1
            local max8 = config.maxMajorAtt1
            if min8 > max8 then
                max8 = min8
            end
            local mAttMod1 = math.random(min8, max8)
            local tAtt1 = attTable[trainedAtt1 + 1]
            if config.aboveMaxAtt == false then
                if tAtt1.base + mAttMod1 > 100 then
                    mAttMod1 = math.max(100 - tAtt1.base, 0)
                end
            end
            tes3.modStatistic({ attribute = trainedAtt1, value = mAttMod1, reference = companionRef })
            modData.att_gained[trainedAtt1 + 1] = modData.att_gained[trainedAtt1 + 1] + mAttMod1
            log:info("" .. name .. "'s 1st Major Attribute in " .. mAtt1 .. " trained by " .. mAttMod1 .. ".")
            ----2nd major attribute trained--------------------------------------------------------------------------------------------------
            local mAtt2 = tables.capitalization[trainedAtt2]
            local min9 = config.minMajorAtt2
            local max9 = config.maxMajorAtt2
            if min9 > max9 then
                max9 = min9
            end
            local mAttMod2 = math.random(min9, max9)
            local tAtt2 = attTable[trainedAtt2 + 1]
            if config.aboveMaxAtt == false then
                if tAtt2.base + mAttMod2 > 100 then
                    mAttMod2 = math.max(100 - tAtt2.base, 0)
                end
            end
            tes3.modStatistic({ attribute = trainedAtt2, value = mAttMod2, reference = companionRef })
            modData.att_gained[trainedAtt2 + 1] = modData.att_gained[trainedAtt2 + 1] + mAttMod2
            log:info("" .. name .. "'s 2nd Major Attribute in " .. mAtt2 .. " trained by " .. mAttMod2 .. ".")
            ----random attribute trained------------------------------------------------------------------------------------------------------
            local valueRand
            repeat
                valueRand = math.random(0, 7)
            until (valueRand ~= trainedAtt1 and valueRand ~= trainedAtt2)

            local mAtt3 = tables.capitalization[valueRand]
            local min10 = config.minRandAtt
            local max10 = config.maxRandAtt
            if min10 > max10 then
                max10 = min10
            end
            local mAttMod3 = math.random(min10, max10)
            local tAtt3 = attTable[valueRand + 1]
            if config.aboveMaxAtt == false then
                if tAtt3.base + mAttMod3 > 100 then
                    mAttMod3 = math.max(100 - tAtt3.base, 0)
                end
            end
            tes3.modStatistic({ attribute = valueRand, value = mAttMod3, reference = companionRef })
            modData.att_gained[valueRand + 1] = modData.att_gained[valueRand + 1] + mAttMod3
            log:info("" .. name .. "'s Random Attribute in " .. mAtt3 .. " trained by " .. mAttMod3 .. ".")
            ----Specialization Bonus----------------------------------------------------------------------------------------------------------
            log:debug("Fetching " .. name .. "'s specialization information...")
            local specialSwitch = 0
            local stealthBonus = tables.stealthTable[math.random(1, 4)]
            local stealthSkillBonus = tables.stealthSkillTable[math.random(1, 9)]
            local magicBonus = tables.magicTable[math.random(1, 4)]
            local magicSkillBonus = tables.magicSkillTable[math.random(1, 9)]
            local combatBonus = tables.combatTable[math.random(1, 4)]
            local combatSkillBonus = tables.combatSkillTable[math.random(1, 9)]
            local tAttStealth = attTable[stealthBonus + 1]
            local tAttMagic = attTable[magicBonus + 1]
            local tAttCombat = attTable[combatBonus + 1]
            local tSkillStealth = companionRef.mobile:getSkillStatistic(stealthSkillBonus)
            local tSkillMagic = companionRef.mobile:getSkillStatistic(magicSkillBonus)
            local tSkillCombat = companionRef.mobile:getSkillStatistic(combatSkillBonus)
            local bonusAmountS = config.specialBonusMod
            local bonusAmountA = config.specialBonusMod
            if config.specialBonus == true then
                if math.random(0, 99) < config.specialChance then
                    log:debug("" .. name .. "'s Specialization Bonus roll succeeded.")
                    --Stealth
                    if companionRef.object.class.specialization == 2 then
                        if config.aboveMaxSkill == false then
                            if tSkillStealth.base + bonusAmountS > 100 then
                                bonusAmountS = math.max(100 - tSkillStealth.base, 0)
                            end
                        end
                        if config.aboveMaxAtt == false then
                            if tAttStealth.base + bonusAmountA > 100 then
                                bonusAmountA = math.max(100 - tAttStealth.base, 0)
                            end
                        end
                        tes3.modStatistic({ attribute = stealthBonus, value = bonusAmountA, reference = companionRef })
                        modData.att_gained[stealthBonus + 1] = modData.att_gained[stealthBonus + 1] + bonusAmountA
                        tes3.modStatistic({ skill = stealthSkillBonus, value = bonusAmountS, reference = companionRef })
                        modData.skill_gained[stealthSkillBonus + 1] = modData.skill_gained[stealthSkillBonus + 1] +
                            bonusAmountS
                        log:info("" ..
                            name ..
                            "'s Stealth Bonus awarded " ..
                            config.specialBonusMod ..
                            " in " ..
                            tables.capitalization[stealthBonus] .. " and " .. tes3.skillName[stealthSkillBonus] .. "!")
                        specialSwitch = 1
                    end
                    --Magic
                    if companionRef.object.class.specialization == 1 then
                        local intCheck = tes3.attributeName[magicBonus]
                        if config.aboveMaxSkill == false then
                            if tSkillMagic.base + bonusAmountS > 100 then
                                bonusAmountS = math.max(100 - tSkillMagic.base, 0)
                            end
                        end
                        if config.aboveMaxAtt == false then
                            if tAttMagic.base + bonusAmountA > 100 then
                                bonusAmountA = math.max(100 - tAttMagic.base, 0)
                            end
                        end
                        tes3.modStatistic({ attribute = magicBonus, value = bonusAmountA, reference = companionRef })
                        modData.att_gained[magicBonus + 1] = modData.att_gained[magicBonus + 1] + bonusAmountA
                        tes3.modStatistic({ skill = magicSkillBonus, value = bonusAmountS, reference = companionRef })
                        modData.skill_gained[magicSkillBonus + 1] = modData.skill_gained[magicSkillBonus + 1] +
                            bonusAmountS
                        log:info("" ..
                            name ..
                            "'s Magic Bonus awarded " ..
                            config.specialBonusMod ..
                            " in " ..
                            tables.capitalization[magicBonus] .. " and " .. tes3.skillName[magicSkillBonus] .. "!")
                        specialSwitch = 2
                        if (intCheck == "intelligence" and bonusAmountA > 0) then
                            selectionMgk = 1
                        end
                    end
                    --Combat
                    if companionRef.object.class.specialization == 0 then
                        if config.aboveMaxSkill == false then
                            if tSkillCombat.base + bonusAmountS > 100 then
                                bonusAmountS = math.max(100 - tSkillCombat.base, 0)
                            end
                        end
                        if config.aboveMaxAtt == false then
                            if tAttCombat.base + bonusAmountA > 100 then
                                bonusAmountA = math.max(100 - tAttCombat.base, 0)
                            end
                        end
                        tes3.modStatistic({ attribute = combatBonus, value = bonusAmountA, reference = companionRef })
                        modData.att_gained[combatBonus + 1] = modData.att_gained[combatBonus + 1] + bonusAmountA
                        tes3.modStatistic({ skill = combatSkillBonus, value = bonusAmountS, reference = companionRef })
                        modData.skill_gained[combatSkillBonus + 1] = modData.skill_gained[combatSkillBonus + 1] +
                            bonusAmountS
                        log:info("" ..
                            name ..
                            "'s Combat Bonus awarded " ..
                            config.specialBonusMod ..
                            " in " ..
                            tables.capitalization[combatBonus] .. " and " .. tes3.skillName[combatSkillBonus] .. "!")
                        specialSwitch = 3
                    end
                else
                    log:debug("" .. name .. "'s Specialization Bonus roll failed.")
                end
            end
            local specialSummary = {
                [0] = "Received no Class Specialization bonus.",
                [1] = "Received a " ..
                    bonusAmountA ..
                    " point bonus to " ..
                    tables.capitalization[stealthBonus] ..
                    " and a " ..
                    bonusAmountS ..
                    " point bonus to " ..
                    tes3.skillName[stealthSkillBonus] ..
                    " due to their specialization in Stealth! (" .. companionRef.object.class.name .. ")",
                [2] = "Received a " ..
                    bonusAmountA ..
                    " point bonus to " ..
                    tables.capitalization[magicBonus] ..
                    " and a " ..
                    bonusAmountS ..
                    " point bonus to " ..
                    tes3.skillName[magicSkillBonus] ..
                    " due to their specialization in Magic! (" .. companionRef.object.class.name .. ")",
                [3] = "Received a " ..
                    bonusAmountA ..
                    " point bonus to " ..
                    tables.capitalization[combatBonus] ..
                    " and a " ..
                    bonusAmountS ..
                    " point bonus to " ..
                    tes3.skillName[combatSkillBonus] ..
                    " due to their specialization in Combat! (" .. companionRef.object.class.name .. ")"
            }
            ----health increased by percentage of endurance after training------------------------------------------------------------------------
            local hpMod = companionRef.mobile.endurance.base
            local hpBase = companionRef.mobile.health.base
            local hpChange = (hpMod * (config.healthMod * 0.01))
            local hpValue = (hpBase + hpChange)
            local selectionHth = 0
            if config.levelHealth == true then
                tes3.modStatistic({ name = "health", value = math.round(hpChange), reference = companionRef })
                modData.hth_gained = modData.hth_gained + math.round(hpChange)
                log:info("" .. name .. "'s Health increased to " .. math.round(hpValue) .. ".")
                selectionHth = 1
            end
            local hpSummary = {
                [0] = "Fortitude remains unchanged",
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
                log:info("" .. name .. "'s Intelligence increased by " .. mgkValue .. " from Magicka Guarantee.")
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
                [0] = "Magicka reserves remain unchanged.",
                [1] = "Magicka reserves increased to " .. math.round(companionRef.mobile.magicka.base) .. "!",
            }
            ----Spell Learning----------------------------------------------------------------------------------------------------------------
            ----Restoration-------------------------------------------------------------------------------------------------------------------
            if config.spellLearning == true then
                log:debug("Begin " .. name .. "'s NPC Spell Learning check.")
                local restoRoll = false
                if (
                    mSkill1 == "Restoration" or mSkill2 == "Restoration" or mSkill3 == "Restoration" or
                        minSkill1 == "Restoration" or
                        minSkill2 == "Restoration" or rSkill1 == "Restoration" or rSkill2 == "Restoration" or
                        tes3.skillName[trainedSkillF] == "Restoration") then
                    restoRoll = true
                end
                ----Destruction-------------------------------------------------------------------------------------------------------------------
                local destroRoll = false
                if (
                    mSkill1 == "Destruction" or mSkill2 == "Destruction" or mSkill3 == "Destruction" or
                        minSkill1 == "Destruction" or
                        minSkill2 == "Destruction" or rSkill1 == "Destruction" or rSkill2 == "Destruction" or
                        tes3.skillName[trainedSkillF] == "Destruction") then
                    destroRoll = true
                end
                ----Alteration-------------------------------------------------------------------------------------------------------------------
                local alterRoll = false
                if (
                    mSkill1 == "Alteration" or mSkill2 == "Alteration" or mSkill3 == "Alteration" or
                        minSkill1 == "Alteration" or
                        minSkill2 == "Alteration" or rSkill1 == "Alteration" or rSkill2 == "Alteration" or
                        tes3.skillName[trainedSkillF] == "Alteration") then
                    alterRoll = true
                end
                ----Conjuration----------------------------------------------------------------------------------------------------------------
                local conjRoll = false
                if (
                    mSkill1 == "Conjuration" or mSkill2 == "Conjuration" or mSkill3 == "Conjuration" or
                        minSkill1 == "Conjuration" or
                        minSkill2 == "Conjuration" or rSkill1 == "Conjuration" or rSkill2 == "Conjuration" or
                        tes3.skillName[trainedSkillF] == "Conjuration") then
                    conjRoll = true
                end
                ----Illusion-----------------------------------------------------------------------------------------------------------------
                local illuRoll = false
                if (
                    mSkill1 == "Illusion" or mSkill2 == "Illusion" or mSkill3 == "Illusion" or minSkill1 == "Illusion" or
                        minSkill2 == "Illusion" or rSkill1 == "Illusion" or rSkill2 == "Illusion" or
                        tes3.skillName[trainedSkillF] == "Illusion") then
                    illuRoll = true
                end
                ----Mysticism---------------------------------------------------------------------------------------------------------------------
                local mystRoll = false
                if (
                    mSkill1 == "Mysticism" or mSkill2 == "Mysticism" or mSkill3 == "Mysticism" or
                        minSkill1 == "Mysticism" or
                        minSkill2 == "Mysticism" or rSkill1 == "Mysticism" or rSkill2 == "Mysticism" or
                        tes3.skillName[trainedSkillF] == "Mysticism") then
                    mystRoll = true
                end
                spells.spellRoll(restoRoll, destroRoll, alterRoll, conjRoll, illuRoll, mystRoll, companionRef)
            end
            ----NPC Abilities-----------------------------------------------------------------------------------------------------------------
            if config.abilityLearningNPC == true then
                abilities.npcAbilities(class.name, companionRef)
                abilities.executeAbilities(companionRef)
                timer.start({ type = timer.game, duration = math.random(8, 96), iterations = 1,
                    callback = "companionLeveler:abilityTimer" })
            end
            ----Derived Stat Mod Data--------------------------------------------------------------------------------------------------------
            modData.mgk_gained = (companionRef.mobile.magicka.base - companionRef.baseObject.magicka)
            modData.fat_gained = (companionRef.mobile.fatigue.base - companionRef.baseObject.fatigue)
            ----NPC Level up Summary----------------------------------------------------------------------------------------------------------
            if config.levelSummary == true then
                local regsum = "" ..
                    name ..
                    " the " ..
                    class.name ..
                    " ascended to Level " ..
                    storedLevel ..
                    "!\n\n" ..
                    hpSummary[selectionHth] ..
                    ", and " ..
                    mgkSummary[selectionMgk] ..
                    "\n\nTrained " ..
                    mAtt1 ..
                    " by " ..
                    mAttMod1 ..
                    ", " ..
                    mAtt2 ..
                    " by " ..
                    mAttMod2 ..
                    ", and " ..
                    mAtt3 ..
                    " by " ..
                    mAttMod3 ..
                    "!\n\n" ..
                    rSummary[selectionR] ..
                    "\n\n" ..
                    specialSummary[specialSwitch] ..
                    "\n\n" ..
                    fSummary[selectionF] ..
                    "\n\n" ..
                    menSummary[selectionMen] ..
                    "\n\nTrained Major Skills in " ..
                    mSkill1 ..
                    " by " ..
                    mSkillMod1 ..
                    ", " ..
                    mSkill2 ..
                    " by " ..
                    mSkillMod2 ..
                    ", and " ..
                    mSkill3 ..
                    " by " ..
                    mSkillMod3 ..
                    "!\n\nTrained Minor Skills in " ..
                    minSkill1 ..
                    " by " ..
                    minSkillMod1 ..
                    " and " ..
                    minSkill2 ..
                    " by " ..
                    minSkillMod2 ..
                    "!\n\nUnderwent additional training in " ..
                    rSkill1 .. " by " .. rSkillMod1 .. " and " .. rSkill2 .. " by " .. rSkillMod2 .. "!"
                modData.summary = regsum
                log:debug("Level Summary triggered from " .. name .. "'s NPC Class Mode.")

                sumr.createWindow(companionRef)

                local menu = tes3ui.findMenu(sumr.id_menu)
                local block = menu:findChild("pane_block_sum")
                local pane = block:findChild(sumr.id_pane)

                local a = pane:createTextSelect { text = "" .. name .. "", id = "sumSelect_" .. i .. "" }
                a:register("mouseClick", function(e) sumr.onSelectN(i, companionRef) end)

                menu:updateLayout()
            else
                tes3.messageBox("" .. name .. " ascended to Level " .. storedLevel .. "!")
            end
        end
    end
    if leveled > 0 then
        tes3.playSound({ sound = "skillraise" })
    end
    abilities.contract()
    abilities.bounty()
end

return npcClassMode
