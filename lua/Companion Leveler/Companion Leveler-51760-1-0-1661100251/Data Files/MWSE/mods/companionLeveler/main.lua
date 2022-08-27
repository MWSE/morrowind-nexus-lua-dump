----Initialize-------------------------------------------------------------------------------------------------------------------
local config = require("companionLeveler.config")
local tables = require("companionLeveler.tables")
local logger = require("logging.logger")
local func = require("companionLeveler.common")
local buildMode = require("companionLeveler.buildMode")
local typeChange = require("companionLeveler.typeChange")
local classChange = require("companionLeveler.classChange")
local buildChange = require("companionLeveler.buildChange")
local sumr = require("companionLeveler.summary")

local log = logger.new{
    name = "Companion Leveler",
    logLevel = "TRACE",
}
log:setLogLevel(config.logLevel)

local function initialized(e)
    log:info("Initialized.")
end
event.register("initialized", initialized)

local companionTableNPC = {}
local companionTableCre = {}

----NPC Class Mode--------------------------------------------------------------------------------------------------------------------
local function companionLevelNPC(companions)
	for i = #companions, 1, -1 do
		local companionRef = companions[i]
		local name = companionRef.object.name
		log:debug("" .. name .. " is NPC #" .. i .. ".")
		local modData = func.getModData(companionRef)
		----Level Increased by 1------------------------------------------------------------------------------------------------------
		modData.level = modData.level + 1
		log:debug("" .. name .. "'s level data increased by 1.")
		local storedLevel = modData.level
		----Class Detection-------------------------------------------------------------------------------------------------------
		local class = companionRef.object.class
		local nClass = class.name
		local cSpecialization = class.specialization
		if modData.class ~= nClass then
			class = tes3.findClass(modData.class)
			nClass = modData.class
		end
		log:info("" .. name .. "'s class is " .. nClass .. ".")
		--local cSpecialization = class.specialization
		log:trace("Fetching " .. name .."'s class skills...")
		local skills = class.majorSkills
		local skillz = class.minorSkills
		log:trace("Fetching " .. name .. "'s class attributes...")
		local mAttributes = class.attributes
		local value1 = math.random(1, #skills)
		local value2 = math.random(1, #skills)
		local value3 = math.random(1, #skillz)
		local value4 = math.random(1, #skillz)
		local value5 = math.random(1, #skills)
		local tSkillMajor1 = skills[value1]
		local tSkillMajor2 = skills[value2]
		local tSkillMinor1 = skillz[value3]
		local tSkillMinor2 = skillz[value4]
		local tSkillMajor3 = skills[value5]
		local trainedAtt1 = mAttributes[1]
		local trainedAtt2 = mAttributes[2]
		----Mentor Bonus-----------------------------------------------------------------------------------------------------------
		local pClass = tes3.mobilePlayer.object.class
		local pnClass = pClass.name
		log:info("Player's class is " .. pnClass .. ".")
		local pSkills = pClass.majorSkills
		local valueP = math.random(1, #pSkills)
		local trainedSkillP = pSkills[valueP]
		local skillP = companionRef.mobile:getSkillStatistic(trainedSkillP)
		local mSkillP = tes3.skillName[trainedSkillP]
		local mSkillModP = config.mentorBonusMod
		local selectionMen = 0
		if config.mentorBonus == true then
			if math.random(1,99) < config.mentorChance then
				selectionMen = 1
				if config.aboveMaxSkill == false then
					if skillP.base + mSkillModP > 100 then
						mSkillModP = math.max(100 - skillP.base, 0)
					end
				end
				tes3.modStatistic({ skill = trainedSkillP, value = mSkillModP, reference = companionRef })
				log:info("" .. tes3.mobilePlayer.object.name .. " Mentored " .. name .. " in " .. mSkillP .. " by " .. mSkillModP .. ".")
			end
		end
		local menSummary = {
			[0] = "Received no Mentor bonuses.",
			[1] = "" .. tes3.mobilePlayer.object.name .. "'s Mentoring increased " .. tes3.skillName[trainedSkillP] .. " by " .. mSkillModP .. "!"
		}
		----Racial Bonus-----------------------------------------------------------------------------------------------------------
		log:trace("Fetching " .. name .. "'s Racial information...")
		local race = companionRef.object.race
		local selectionR = 0
		local nRace = "placeholder"
		local trainedSkillR = 0
		local rBonusAmount = config.racialBonusMod
		if config.racialBonus == true then
			if math.random(1,99) < config.racialChance then
				log:debug("" .. name .. "'s Racial Bonus roll succeeded.")
				selectionR = 1
				nRace = race.name
				local rSkills = race.skillBonuses
				local valueR = math.random(1,#rSkills)
				trainedSkillR = rSkills[valueR].skill
				if (trainedSkillR == nil or trainedSkillR < 0 or trainedSkillR > 26) then
					trainedSkillR = 8
					log:debug("" .. name .. "'s chosen Racial Skill returned nil. Reverting to Athletics.")
				end
				local rSkill = companionRef.mobile:getSkillStatistic(trainedSkillR)
				if config.aboveMaxSkill == false then
					if rSkill.base + rBonusAmount > 100 then
						rBonusAmount = math.max(100 - rSkill.base, 0)
					end
				end
				tes3.modStatistic({ skill = trainedSkillR, value = rBonusAmount, reference = companionRef })
			else
				log:debug("" .. name .. "'s Racial Bonus roll failed.")
			end
		end
		local rSummary = {
			[0] = "Received no Racial bonuses.",
			[1] = "" .. nRace .. " heritage increased " .. tes3.skillName[trainedSkillR] .. " by " .. rBonusAmount .. "!"
		}
		----Faction Bonus----------------------------------------------------------------------------------------------------------
		local selectionF = 0
		local selectionMgk = 0
		local nFaction = "placeholder"
		local fAttributes = {}
		local fSkills = {}
		local valueFA = 0
		local valueFS = 0
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
				valueFA = math.random(1,#fAttributes)
				valueFS = math.random(1,#fSkills)
				trainedAttF = fAttributes[valueFA]
				trainedSkillF = fSkills[valueFS]
				if (trainedSkillF == nil or trainedSkillF < 0 or trainedSkillF > 26) then
					trainedSkillF = 8
					log:debug("" .. name .. "'s chosen Faction Skill returned nil. Reverting to Athletics.")
				end
				local fAttName = tables.capitalization[trainedAttF]
				local attTable = companionRef.mobile.attributes
				local offset = (trainedAttF + 1)
				local fAtt = attTable[offset]
				if math.random(0,99) < config.factionChance then
					log:debug("" .. name .. "'s Faction Bonus roll succeeded.")
					log:info("" .. name .. " received a bonus from " .. nFaction .. ".")
					selectionF = 1
					if config.aboveMaxAtt == false then
						if fAtt.base + fBonusAmountA > 100 then
							fBonusAmountA = math.max(100 - fAtt.base, 0)
						end
					end
					tes3.modStatistic({ attribute = trainedAttF, value = fBonusAmountA, reference = companionRef })
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
				else
					log:debug("" .. name .. "'s Faction Bonus roll failed.")
				end
			end
		end
		local fSummary = {
			[0] = "" .. name .. " has no Faction.",
			[1] = "" .. nFaction .. " training increased " .. tables.capitalization[trainedAttF] .. " by " .. fBonusAmountA .. " and " .. tes3.skillName[trainedSkillF] .. " by " .. fBonusAmountS .. "!",
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
		log:info("" .. name .. "'s 2nd Minor Skill in " .. minSkill2 .. " trained by " .. minSkillMod2 .. ".")
		----1st Random Skill Trained--------------------------------------------------------------------------------------------------
		local valueRS1 = math.random(0, 26)
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
		log:info("" .. name .. "'s 1st Random Skill in " .. rSkill1 .. " trained by " .. rSkillMod1 .. ".")
		----2nd Random Skill Trained---------------------------------------------------------------------------------------------------
		local valueRS2 = math.random(0, 26)
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
		log:info("" .. name .. "'s 2nd Random Skill in " .. rSkill2 .. " trained by " .. rSkillMod2 .. ".")
		----1st major attribute trained-------------------------------------------------------------------------------------------------
		local mAtt1 = tables.capitalization[trainedAtt1]
		local min8 = config.minMajorAtt1
		local max8 = config.maxMajorAtt1
		if min8 > max8 then
			max8 = min8
		end
		local mAttMod1 = math.random(min8, max8)
		local attTable1 = companionRef.mobile.attributes
		local offset1 = (trainedAtt1 + 1)
		local tAtt1 = attTable1[offset1]
		if config.aboveMaxAtt == false then
			if tAtt1.base + mAttMod1 > 100 then
				mAttMod1 = math.max(100 - tAtt1.base, 0)
			end
		end
		tes3.modStatistic({ attribute = trainedAtt1, value = mAttMod1, reference = companionRef })
		log:info("" .. name .. "'s 1st Major Attribute in " .. mAtt1 .. " trained by " .. mAttMod1 .. ".")
		----2nd major attribute trained--------------------------------------------------------------------------------------------------
		local mAtt2 = tables.capitalization[trainedAtt2]
		local min9 = config.minMajorAtt2
		local max9 = config.maxMajorAtt2
		if min9 > max9 then
			max9 = min9
		end
		local mAttMod2 = math.random(min9, max9)
		local attTable2 = companionRef.mobile.attributes
		local offset2 = (trainedAtt2 + 1)
		local tAtt2 = attTable2[offset2]
		if config.aboveMaxAtt == false then
			if tAtt2.base + mAttMod2 > 100 then
				mAttMod2 = math.max(100 - tAtt2.base, 0)
			end
		end
		tes3.modStatistic({ attribute = trainedAtt2, value = mAttMod2, reference = companionRef })
		log:info("" .. name .. "'s 2nd Major Attribute in " .. mAtt2 .. " trained by " .. mAttMod2 .. ".")
		----random attribute trained------------------------------------------------------------------------------------------------------
		local valueRand = math.random(0,7)
		local mAtt3 = tables.capitalization[valueRand]
		local min10 = config.minRandAtt
		local max10 = config.maxRandAtt
		if min10 > max10 then
			max10 = min10
		end
		local mAttMod3 = math.random(min10, max10)
		local attTable3 = companionRef.mobile.attributes
		local offset3 = (valueRand + 1)
		local tAtt3 = attTable3[offset3]
		if config.aboveMaxAtt == false then
			if tAtt3.base + mAttMod3 > 100 then
				mAttMod3 = math.max(100 - tAtt3.base, 0)
			end
		end
		tes3.modStatistic({ attribute = valueRand, value = mAttMod3, reference = companionRef })
		log:info("" .. name .. "'s Random Attribute in " .. mAtt3 .. " trained by " .. mAttMod3 .. ".")
		----Specialization Bonus----------------------------------------------------------------------------------------------------------
		log:debug("Fetching " .. name .. "'s specialization information...")
		local specialSwitch = 0
		local specialRoll = math.random(1,4)
		local specialSkillRoll = math.random(1,9)
		local SattTable = companionRef.mobile.attributes
		local stealthBonus = tables.stealthTable[specialRoll]
		local stealthSkillBonus = tables.stealthSkillTable[specialSkillRoll]
		local magicBonus = tables.magicTable[specialRoll]
		local magicSkillBonus = tables.magicSkillTable[specialSkillRoll]
		local combatBonus = tables.combatTable[specialRoll]
		local combatSkillBonus = tables.combatSkillTable[specialSkillRoll]
		local offsetStealth = (stealthBonus + 1)
		local tAttStealth = SattTable[offsetStealth]
		local offsetMagic = (magicBonus + 1)
		local tAttMagic = SattTable[offsetMagic]
		local offsetCombat = (combatBonus + 1)
		local tAttCombat = SattTable[offsetCombat]
		local tSkillStealth = companionRef.mobile:getSkillStatistic(stealthSkillBonus)
		local tSkillMagic = companionRef.mobile:getSkillStatistic(magicSkillBonus)
		local tSkillCombat = companionRef.mobile:getSkillStatistic(combatSkillBonus)
		local bonusAmountS = config.specialBonusMod
		local bonusAmountA = config.specialBonusMod
		if config.specialBonus == true then
			if math.random(0,99) < config.specialChance then
				log:debug("" .. name .. "'s Specialization Bonus roll succeeded.")
				--Stealth
				if cSpecialization == 2 then
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
					tes3.modStatistic({ skill = stealthSkillBonus, value = bonusAmountS, reference = companionRef })
					log:info("" .. name .. "'s Stealth Bonus awarded " .. config.specialBonusMod .. " in " .. tables.capitalization[stealthBonus] .. " and " .. tes3.skillName[stealthSkillBonus] .. "!")
					specialSwitch = 1
				end
				--Magic
				if cSpecialization == 1 then
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
					tes3.modStatistic({ skill = magicSkillBonus, value = bonusAmountS, reference = companionRef })
					log:info("" .. name .. "'s Magic Bonus awarded " .. config.specialBonusMod .. " in " .. tables.capitalization[magicBonus] .. " and " .. tes3.skillName[magicSkillBonus] .. "!")
					specialSwitch = 2
					if (intCheck == "intelligence" and bonusAmountA > 0) then
						selectionMgk = 1
					end
				end
				--Combat
				if cSpecialization == 0 then
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
					tes3.modStatistic({ skill = combatSkillBonus, value = bonusAmountS, reference = companionRef })
					log:info("" .. name .. "'s Combat Bonus awarded " .. config.specialBonusMod .. " in " .. tables.capitalization[combatBonus] .. " and " .. tes3.skillName[combatSkillBonus] .. "!")
					specialSwitch = 3
				end
			else
				log:debug("" .. name .. "'s Specialization Bonus roll failed.")
			end
		end
		local specialSummary = {
			[0] = "Received no Class Specialization bonus.",
			[1] = "Received a " .. bonusAmountA .. " point bonus to " .. tables.capitalization[stealthBonus] .. " and a " .. bonusAmountS .. " point bonus to " .. tes3.skillName[stealthSkillBonus] .. " due to their specialization in Stealth! (" .. companionRef.object.class.name .. ")",
			[2] = "Received a " .. bonusAmountA .. " point bonus to " .. tables.capitalization[magicBonus] .. " and a " .. bonusAmountS .. " point bonus to " .. tes3.skillName[magicSkillBonus] .. " due to their specialization in Magic! (" .. companionRef.object.class.name .. ")",
			[3] = "Received a " .. bonusAmountA .. " point bonus to " .. tables.capitalization[combatBonus] .. " and a " .. bonusAmountS .. " point bonus to " .. tes3.skillName[combatSkillBonus] .. " due to their specialization in Combat! (" .. companionRef.object.class.name .. ")"
		}
		----health increased by percentage of endurance after training------------------------------------------------------------------------
		local hpMod = companionRef.mobile.endurance.base
		local hpBase = companionRef.mobile.health.base
		local hpChange = (hpMod * (config.healthMod * 0.01))
		local hpValue = (hpBase + hpChange)
		local selectionHth = 0
		if config.levelHealth == true then
			tes3.modStatistic({ name = "health", value = math.round(hpChange), reference = companionRef })
			log:info("" .. name .. "'s Health increased to " .. math.round(hpValue) .. ".")
			selectionHth = 1
		end
		local hpSummary = {
			[0] = "Fortitude remains unchanged",
			[1] = "Increased Fortitude to " .. math.round(hpValue) .."",
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
			[1] = "Magicka reserves increased to " .. math.round(companionRef.mobile.magicka.base) .."!",
		}
		----Spell Learning----------------------------------------------------------------------------------------------------------------
		----Restoration-------------------------------------------------------------------------------------------------------------------
		if config.spellLearning == true then
			log:debug("Begin " .. name .. "'s NPC Spell Learning check.")
			local restoRoll = false
			if (mSkill1 == "Restoration" or mSkill2 == "Restoration" or mSkill3 == "Restoration" or minSkill1 == "Restoration" or minSkill2 == "Restoration" or rSkill1 == "Restoration" or rSkill2 == "Restoration" or tes3.skillName[trainedSkillF] == "Restoration") then
				restoRoll = true
			end
			if restoRoll == true then
				local mrValue = companionRef.mobile:getSkillStatistic(15)
				if math.random(0,99) < config.spellChance then
					if mrValue.base >= 25 and mrValue.base < 50 then
						local iterations = 0
						repeat
							local rSpell = math.random(1,5)
							log:trace("Restoration Spell #" .. rSpell .. ".")
							local learned = tables.restorationTable1[rSpell]
							local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
							iterations = iterations + 1
							if wasAdded == true then
								tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
								log:debug("Spell roll succeeded. Restoration spell " .. learned .. " added to " .. name .. ".")
								tes3.playSound({ sound = "restoration area" })
							else
								log:trace("Restoration spell roll failed on " .. name ..".")
							end
						until (wasAdded == true or iterations == 15)
					end
					if mrValue.base >= 50 and mrValue.base < 75 then
						local iterations = 0
						repeat
							local rSpell = math.random(1,14)
							log:trace("Restoration Spell #" .. rSpell .. ".")
							local learned = tables.restorationTable2[rSpell]
							local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
							iterations = iterations + 1
							if wasAdded == true then
								tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
								log:debug("Spell roll succeeded. Restoration spell " .. learned .. " added to " .. name .. ".")
								tes3.playSound({ sound = "restoration area" })
							else
								log:trace("Restoration spell roll failed on " .. name ..".")
							end
						until (wasAdded == true or iterations == 30)
					end
					if mrValue.base >= 75 and mrValue.base < 100 then
						local iterations = 0
						repeat
							local rSpell = math.random(1,22)
							log:trace("Restoration Spell #" .. rSpell .. ".")
							local learned = tables.restorationTable3[rSpell]
							local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
							iterations = iterations + 1
							if wasAdded == true then
								tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
								log:debug("Spell roll succeeded. Restoration spell " .. learned .. " added to " .. name .. ".")
								tes3.playSound({ sound = "restoration area" })
							else
								log:trace("Restoration spell roll failed on " .. name ..".")
							end
						until (wasAdded == true or iterations == 50)
					end
					if mrValue.base >= 100 then
						local iterations = 0
						repeat
							local rSpell = math.random(1,35)
							log:trace("Restoration Spell #" .. rSpell .. ".")
							local learned = tables.restorationTable4[rSpell]
							local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
							iterations = iterations + 1
							if wasAdded == true then
								tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
								log:debug("Spell roll succeeded. Restoration spell " .. learned .. " added to " .. name .. ".")
								tes3.playSound({ sound = "restoration area" })
							else
								log:trace("Restoration spell roll failed on " .. name ..".")
							end
						until (wasAdded == true or iterations == 70)
					end
				end
			end
			----Destruction-------------------------------------------------------------------------------------------------------------------
			local destroRoll = false
			if (mSkill1 == "Destruction" or mSkill2 == "Destruction" or mSkill3 == "Destruction" or minSkill1 == "Destruction" or minSkill2 == "Destruction" or rSkill1 == "Destruction" or rSkill2 == "Destruction" or tes3.skillName[trainedSkillF] == "Destruction") then
				destroRoll = true
			end
			if destroRoll == true then
				local mdValue = companionRef.mobile:getSkillStatistic(10)
				if math.random(0,99) < config.spellChance then
					if mdValue.base >= 25 and mdValue.base < 50 then
						local iterations = 0
						repeat
							local dSpell = math.random(1,7)
							log:trace("Destruction Spell #" .. dSpell .. ".")
							local learned = tables.destructionTable1[dSpell]
							local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
							iterations = iterations + 1
							if wasAdded == true then
								tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
								log:debug("Spell roll succeeded. Destruction spell " .. learned .. " added to " .. name .. ".")
								tes3.playSound({ sound = "shock cast" })
							else
								log:trace("Destruction spell roll failed on " .. name ..".")
							end
						until (wasAdded == true or iterations == 15)
					end
					if mdValue.base >= 50 and mdValue.base < 75 then
						local iterations = 0
						repeat
							local dSpell = math.random(1,17)
							log:trace("Destruction Spell #" .. dSpell .. ".")
							local learned = tables.destructionTable2[dSpell]
							local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
							iterations = iterations + 1
							if wasAdded == true then
								tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
								log:debug("Spell roll succeeded. Destruction spell " .. learned .. " added to " .. name .. ".")
								tes3.playSound({ sound = "shock cast" })
							else
								log:trace("Destruction spell roll failed on " .. name ..".")
							end
						until (wasAdded == true or iterations == 30)
					end
					if mdValue.base >= 75 and mdValue.base < 100 then
						local iterations = 0
						repeat
							local dSpell = math.random(1,27)
							log:trace("Destruction Spell #" .. dSpell .. ".")
							local learned = tables.destructionTable3[dSpell]
							local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
							iterations = iterations + 1
							if wasAdded == true then
								tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
								log:debug("Spell roll succeeded. Destruction spell " .. learned .. " added to " .. name .. ".")
								tes3.playSound({ sound = "shock cast" })
							else
								log:trace("Destruction spell roll failed on " .. name ..".")
							end
						until (wasAdded == true or iterations == 50)
					end
					if mdValue.base >= 100 then
						local iterations = 0
						repeat
							local dSpell = math.random(1,35)
							log:trace("Destruction Spell #" .. dSpell .. ".")
							local learned = tables.destructionTable4[dSpell]
							local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
							iterations = iterations + 1
							if wasAdded == true then
								tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
								log:debug("Spell roll succeeded. Destruction spell " .. learned .. " added to " .. name .. ".")
								tes3.playSound({ sound = "shock cast" })
							else
								log:trace("Destruction spell roll failed on " .. name ..".")
							end
						until (wasAdded == true or iterations == 70)
					end
				end
			end
			----Alteration-------------------------------------------------------------------------------------------------------------------
			local alterRoll = false
			if (mSkill1 == "Alteration" or mSkill2 == "Alteration" or mSkill3 == "Alteration" or minSkill1 == "Alteration" or minSkill2 == "Alteration" or rSkill1 == "Alteration" or rSkill2 == "Alteration" or tes3.skillName[trainedSkillF] == "Alteration") then
				alterRoll = true
			end
			if alterRoll == true then
				local maValue = companionRef.mobile:getSkillStatistic(11)
				if math.random(0,99) < config.spellChance then
					if maValue.base >= 25 and maValue.base < 50 then
						local iterations = 0
						repeat
							local aSpell = math.random(1,5)
							log:trace("Alteration Spell #" .. aSpell .. ".")
							local learned = tables.alterationTable1[aSpell]
							local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
							iterations = iterations + 1
							if wasAdded == true then
								tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
								log:debug("Spell roll succeeded. Alteration spell " .. learned .. " added to " .. name .. ".")
								tes3.playSound({ sound = "alteration hit" })
							else
								log:trace("Alteration spell roll failed on " .. name ..".")
							end
						until (wasAdded == true or iterations == 15)
					end
					if maValue.base >= 50 and maValue.base < 75 then
						local iterations = 0
						repeat
							local aSpell = math.random(1,12)
							log:trace("Alteration Spell #" .. aSpell .. ".")
							local learned = tables.alterationTable2[aSpell]
							local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
							iterations = iterations + 1
							if wasAdded == true then
								tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
								log:debug("Spell roll succeeded. Alteration spell " .. learned .. " added to " .. name .. ".")
								tes3.playSound({ sound = "alteration hit" })
							else
								log:trace("Alteration spell roll failed on " .. name ..".")
							end
						until (wasAdded == true or iterations == 30)
					end
					if maValue.base >= 75 and maValue.base < 100 then
						local iterations = 0
						repeat
							local aSpell = math.random(1,15)
							log:trace("Alteration Spell #" .. aSpell .. ".")
							local learned = tables.alterationTable3[aSpell]
							local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
							iterations = iterations + 1
							if wasAdded == true then
								tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
								log:debug("Spell roll succeeded. Alteration spell " .. learned .. " added to " .. name .. ".")
								tes3.playSound({ sound = "alteration hit" })
							else
								log:trace("Alteration spell roll failed on " .. name ..".")
							end
						until (wasAdded == true or iterations == 40)
					end
					if maValue.base >= 100 then
						local iterations = 0
						repeat
							local aSpell = math.random(1,21)
							log:trace("Alteration Spell #" .. aSpell .. ".")
							local learned = tables.alterationTable4[aSpell]
							local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
							iterations = iterations + 1
							if wasAdded == true then
								tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
								log:debug("Spell roll succeeded. Alteration spell " .. learned .. " added to " .. name .. ".")
								tes3.playSound({ sound = "alteration hit" })
							else
								log:trace("Alteration spell roll failed on " .. name ..".")
							end
						until (wasAdded == true or iterations == 50)
					end
				end
			end
			----Conjuration----------------------------------------------------------------------------------------------------------------
			local conjRoll = false
			if (mSkill1 == "Conjuration" or mSkill2 == "Conjuration" or mSkill3 == "Conjuration" or minSkill1 == "Conjuration" or minSkill2 == "Conjuration" or rSkill1 == "Conjuration" or rSkill2 == "Conjuration" or tes3.skillName[trainedSkillF] == "Conjuration") then
				conjRoll = true
			end
			if conjRoll == true then
				local mcValue = companionRef.mobile:getSkillStatistic(13)
				if math.random(0,99) < config.spellChance then
					if mcValue.base >= 25 and mcValue.base < 50 then
						local iterations = 0
						repeat
							local cSpell = math.random(1,6)
							log:trace("Conjuration Spell #" .. cSpell .. ".")
							local learned = tables.conjurationTable1[cSpell]
							local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
							iterations = iterations + 1
							if wasAdded == true then
								tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
								log:debug("Spell roll succeeded. Conjuration spell " .. learned .. " added to " .. name .. ".")
								tes3.playSound({ sound = "conjuration area" })
							else
								log:trace("Conjuration spell roll failed on " .. name ..".")
							end
						until (wasAdded == true or iterations == 15)
					end
					if mcValue.base >= 50 and mcValue.base < 75 then
						local iterations = 0
						repeat
							local cSpell = math.random(1,14)
							log:trace("Conjuration Spell #" .. cSpell .. ".")
							local learned = tables.conjurationTable2[cSpell]
							local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
							iterations = iterations + 1
							if wasAdded == true then
								tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
								log:debug("Spell roll succeeded. Conjuration spell " .. learned .. " added to " .. name .. ".")
								tes3.playSound({ sound = "conjuration area" })
							else
								log:trace("Conjuration spell roll failed on " .. name ..".")
							end
						until (wasAdded == true or iterations == 30)
					end
					if mcValue.base >= 75 and mcValue.base < 100 then
						local iterations = 0
						repeat
							local cSpell = math.random(1,24)
							log:trace("Conjuration Spell #" .. cSpell .. ".")
							local learned = tables.conjurationTable3[cSpell]
							local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
							iterations = iterations + 1
							if wasAdded == true then
								tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
								log:debug("Spell roll succeeded. Conjuration spell " .. learned .. " added to " .. name .. ".")
								tes3.playSound({ sound = "conjuration area" })
							else
								log:trace("Conjuration spell roll failed on " .. name ..".")
							end
						until (wasAdded == true or iterations == 50)
					end
					if mcValue.base >= 100 then
						local iterations = 0
						repeat
							local cSpell = math.random(1,30)
							log:trace("Conjuration Spell #" .. cSpell .. ".")
							local learned = tables.conjurationTable4[cSpell]
							local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
							iterations = iterations + 1
							if wasAdded == true then
								tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
								log:debug("Spell roll succeeded. Conjuration spell " .. learned .. " added to " .. name .. ".")
								tes3.playSound({ sound = "conjuration area" })
							else
								log:trace("Conjuration spell roll failed on " .. name ..".")
							end
						until (wasAdded == true or iterations == 70)
					end
				end
			end
			----Illusion-----------------------------------------------------------------------------------------------------------------
			local illuRoll = false
			if (mSkill1 == "Illusion" or mSkill2 == "Illusion" or mSkill3 == "Illusion" or minSkill1 == "Illusion" or minSkill2 == "Illusion" or rSkill1 == "Illusion" or rSkill2 == "Illusion" or tes3.skillName[trainedSkillF] == "Illusion") then
				illuRoll = true
			end
			if illuRoll == true then
				local miValue = companionRef.mobile:getSkillStatistic(12)
				if math.random(0,99) < config.spellChance then
					if miValue.base >= 25 and miValue.base < 50 then
						local iterations = 0
						repeat
							local iSpell = math.random(1,6)
							log:trace("Illusion Spell #" .. iSpell .. ".")
							local learned = tables.illusionTable1[iSpell]
							local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
							iterations = iterations + 1
							if wasAdded == true then
								tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
								log:debug("Spell roll succeeded. Illusion spell " .. learned .. " added to " .. name .. ".")
								tes3.playSound({ sound = "illusion hit" })
							else
								log:trace("Illusion spell roll failed on " .. name ..".")
							end
						until (wasAdded == true or iterations == 15)
					end
					if miValue.base >= 50 and miValue.base < 75 then
						local iterations = 0
						repeat
							local iSpell = math.random(1,12)
							log:trace("Illusion Spell #" .. iSpell .. ".")
							local learned = tables.illusionTable2[iSpell]
							local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
							iterations = iterations + 1
							if wasAdded == true then
								tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
								log:debug("Spell roll succeeded. Illusion spell " .. learned .. " added to " .. name .. ".")
								tes3.playSound({ sound = "illusion hit" })
							else
								log:trace("Illusion spell roll failed on " .. name ..".")
							end
						until (wasAdded == true or iterations == 30)
					end
					if miValue.base >= 75 and miValue.base < 100 then
						local iterations = 0
						repeat
							local iSpell = math.random(1,15)
							log:trace("Illusion Spell #" .. iSpell .. ".")
							local learned = tables.illusionTable3[iSpell]
							local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
							iterations = iterations + 1
							if wasAdded == true then
								tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
								log:debug("Spell roll succeeded. Illusion spell " .. learned .. " added to " .. name .. ".")
								tes3.playSound({ sound = "illusion hit" })
							else
								log:trace("Illusion spell roll failed on " .. name ..".")
							end
						until (wasAdded == true or iterations == 40)
					end
					if miValue.base >= 100 then
						local iterations = 0
						repeat
							local iSpell = math.random(1,19)
							log:trace("Illusion Spell #" .. iSpell .. ".")
							local learned = tables.illusionTable4[iSpell]
							local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
							iterations = iterations + 1
							if wasAdded == true then
								tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
								log:debug("Spell roll succeeded. Illusion spell " .. learned .. " added to " .. name .. ".")
								tes3.playSound({ sound = "illusion hit" })
							else
								log:trace("Illusion spell roll failed on " .. name ..".")
							end
						until (wasAdded == true or iterations == 45)
					end
				end
			end
			----Mysticism---------------------------------------------------------------------------------------------------------------------
			local mystRoll = false
			if (mSkill1 == "Mysticism" or mSkill2 == "Mysticism" or mSkill3 == "Mysticism" or minSkill1 == "Mysticism" or minSkill2 == "Mysticism" or rSkill1 == "Mysticism" or rSkill2 == "Mysticism" or tes3.skillName[trainedSkillF] == "Mysticism") then
				mystRoll = true
			end
			if mystRoll == true then
				local mmValue = companionRef.mobile:getSkillStatistic(14)
				if math.random(0,99) < config.spellChance then
					if mmValue.base >= 25 and mmValue.base < 50 then
						local iterations = 0
						repeat
							local mSpell = math.random(1,5)
							log:trace("Mysticism Spell #" .. mSpell .. ".")
							local learned = tables.mysticismTable1[mSpell]
							local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
							iterations = iterations + 1
							if wasAdded == true then
								tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
								log:debug("Spell roll succeeded. Mysticism spell " .. learned .. " added to " .. name .. ".")
								tes3.playSound({ sound = "mysticism area" })
							else
								log:trace("Mysticism spell roll failed on " .. name ..".")
							end
						until (wasAdded == true or iterations == 15)
					end
					if mmValue.base >= 50 and mmValue.base < 75 then
						local iterations = 0
						repeat
							local mSpell = math.random(1,11)
							log:trace("Mysticism Spell #" .. mSpell .. ".")
							local learned = tables.mysticismTable2[mSpell]
							local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
							iterations = iterations + 1
							if wasAdded == true then
								tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
								log:debug("Spell roll succeeded. Mysticism spell " .. learned .. " added to " .. name .. ".")
								tes3.playSound({ sound = "mysticism area" })
							else
								log:trace("Mysticism spell roll failed on " .. name ..".")
							end
						until (wasAdded == true or iterations == 30)
					end
					if mmValue.base >= 75 and mmValue.base < 100 then
						local iterations = 0
						repeat
							local mSpell = math.random(1,18)
							log:trace("Mysticism Spell #" .. mSpell .. ".")
							local learned = tables.mysticismTable3[mSpell]
							local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
							iterations = iterations + 1
							if wasAdded == true then
								tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
								log:debug("Spell roll succeeded. Mysticism spell " .. learned .. " added to " .. name .. ".")
								tes3.playSound({ sound = "mysticism area" })
							else
								log:trace("Mysticism spell roll failed on " .. name ..".")
							end
						until (wasAdded == true or iterations == 40)
					end
					if mmValue.base >= 100 then
						local iterations = 0
						repeat
							local mSpell = math.random(1,22)
							log:trace("Mysticism Spell #" .. mSpell .. ".")
							local learned = tables.mysticismTable4[mSpell]
							local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
							iterations = iterations + 1
							if wasAdded == true then
								tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
								log:debug("Spell roll succeeded. Mysticism spell " .. learned .. " added to " .. name .. ".")
								tes3.playSound({ sound = "mysticism area" })
							else
								log:trace("Mysticism spell roll failed on " .. name ..".")
							end
						until (wasAdded == true or iterations == 50)
					end
				end
			end
		end
		----NPC Level up Summary----------------------------------------------------------------------------------------------------------
		if config.levelSummary == true then
			local regsum = "" .. name .. " the " .. nClass .. " ascended to Level " .. storedLevel .. "!\n\n" .. hpSummary[selectionHth] .. ", and " .. mgkSummary[selectionMgk] .. "\n\nTrained " .. mAtt1 .. " by " .. mAttMod1 .. ", " .. mAtt2 .. " by " .. mAttMod2 .. ", and " .. mAtt3 .. " by " .. mAttMod3 .. "!\n\n" .. rSummary[selectionR] .. "\n\n" .. specialSummary[specialSwitch] .. "\n\n" .. fSummary[selectionF] .. "\n\n" .. menSummary[selectionMen] .. "\n\nTrained Major Skills in " .. mSkill1 .. " by " .. mSkillMod1 .. ", " .. mSkill2 .. " by " .. mSkillMod2 .. ", and " .. mSkill3 .. " by " .. mSkillMod3 .. "!\n\nTrained Minor Skills in " .. minSkill1 .. " by " .. minSkillMod1 .. " and " .. minSkill2 .. " by " .. minSkillMod2 .. "!\n\nUnderwent additional training in " .. rSkill1 .. " by " .. rSkillMod1 .. " and " .. rSkill2 .. " by " .. rSkillMod2 .. "!"
			modData.summary = regsum
			log:debug("Level Summary triggered from " .. name .. "'s NPC Class Mode.")
			sumr.createWindow(companionRef)
			local menu = tes3ui.findMenu(sumr.id_menu)
			local block = menu:findChild("pane_block_sum")
			local pane = block:findChild(sumr.id_pane)
			local a = pane:createTextSelect{ text = "" .. name .. "", id = "sumSelect_" .. i .. "" }
			a:register("mouseClick", function(e) sumr.onSelectN(i, companionRef) end)
			menu:updateLayout()
		else
			tes3.messageBox("" .. name .. " ascended to Level " .. storedLevel .. "!")
		end
	end
	tes3.playSound({sound = "skillraise"})
	table.clear(companionTableNPC)
	log:debug("Companion Table cleared at end of NPC Class Mode.")
end



















----Creature Class Mode----------------------------------------------------------------------------------------------------------------------
local function companionLevelCre(companions)
	for i = #companions, 1, -1 do
		local companionRef = companions[i]
		local name = companionRef.object.name
		log:debug("" .. name .. " is Creature #" .. i .. ".")
		local modData = func.getModData(companionRef)
		----Level Increased by 1------------------------------------------------------------------------------------------------------
		modData.level = modData.level + 1
		log:debug("" .. name .. "'s level data increased by 1.")
		local storedLevel = modData.level
		local storedTlevel = 0
		----Class Detection-------------------------------------------------------------------------------------------------------
		if companionRef.object.class == nil then
			log:debug("Class returned nil. Entering Creature Class Mode.")
			----Creature Class Mode-----------------------------------------------------------------------------------------------
			local selectionMgk = 0
			local selectionHth = 0
			local cType = companionRef.object.type
			local cName = tables.typeTable[cType]
			if modData.type ~= cName then
				cName = modData.type
			end
			log:info("" .. name .. " is a " .. cName .. " type creature.")
			local trainedAtt1 = 0
			local trainedAtt2 = 0
			----Spell Learning----------------------------------------------------------------------------------------------------
			--Normal
			if cName == "Normal" then
				trainedAtt2 = 3
				modData.norlevel = modData.norlevel + 1
				storedTlevel = modData.norlevel
				if config.spellLearningC == true then
					if math.random(1,99) < config.spellChanceC then
						local iterations = 0
						if modData.level < 10 then
							repeat
								local normSpell = math.random(1,15)
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
								local normSpell = math.random(1,25)
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
				end
				if config.abilityLearning == true then
					if modData.norlevel >= 5 then
						local ability = tables.abList[1]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Normal Type Ability Instinct!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[1] .. ".")
							tes3.playSound({ sound = "alitSCRM" })
							modData.abilities[1] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability.")
						end
					end
					if modData.norlevel >= 10 then
						local ability = tables.abList[2]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Normal Type Ability Beast Blood!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[2] .. ".")
							tes3.playSound({ sound = "alitSCRM" })
							modData.abilities[2] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability.")
						end
					end
					if modData.norlevel >= 15 then
						local ability = tables.abList[3]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Normal Type Ability Greater Instinct!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[3] .. ".")
							tes3.playSound({ sound = "alitSCRM" })
							modData.abilities[3] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability.")
						end
					end
					if modData.norlevel >= 20 then
						local ability = tables.abList[4]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Normal Type Ability Evolutionary Stamina!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[4] .. ".")
							tes3.playSound({ sound = "alitSCRM" })
							modData.abilities[4] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability.")
						end
					end
				end
			end
			--Daedra
			if cName == "Daedra" then
				trainedAtt2 = 1
				modData.daelevel = modData.daelevel + 1
				storedTlevel = modData.daelevel
				if config.spellLearningC == true then
					if math.random(1,99) < config.spellChanceC then
						local iterations = 0
						if modData.level < 10 then
							repeat
								local daeSpell = math.random(1,20)
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
								local daeSpell = math.random(1,55)
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
				end
				if config.abilityLearning == true then
					if modData.daelevel >= 5 then
						local ability = tables.abList[5]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Daedra Type Ability Taste of Freedom!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[5] .. ".")
							tes3.playSound({ sound = "dremora scream" })
							modData.abilities[5] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability.")
						end
					end
					if modData.daelevel >= 10 then
						local ability = tables.abList[6]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Daedra Type Ability Daedric Skin!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[6] .. ".")
							tes3.playSound({ sound = "dremora scream" })
							modData.abilities[6] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability.")
						end
					end
					if modData.daelevel >= 15 then
						local ability = tables.abList[7]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Daedra Type Ability Sinful Freedom!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[7] .. ".")
							tes3.playSound({ sound = "dremora scream" })
							modData.abilities[7] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability.")
						end
					end
					if modData.daelevel >= 20 then
						local ability = tables.abList[8]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Daedra Type Ability Dark Barrier!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[8] .. ".")
							tes3.playSound({ sound = "dremora scream" })
							modData.abilities[8] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability.")
						end
					end
				end
			end
			--Undead
			if cName == "Undead" then
				trainedAtt1 = 1
				trainedAtt2 = 5
				modData.undlevel = modData.undlevel + 1
				storedTlevel = modData.undlevel
				if config.spellLearningC == true then
					if math.random(1,99) < config.spellChanceC then
						local iterations = 0
						if modData.level < 10 then
							repeat
								local undSpell = math.random(1,24)
								log:trace("Undead Spell Table 1, #" .. undSpell .. ".")
								local learned = tables.undeadTable1[undSpell]
								local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
								iterations = iterations + 1
								if wasAdded == true then
									tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
									log:info("" .. name .. " learned to cast " .. learned .. ".")
									tes3.playSound({ sound = "ancestor ghost roar" })
								else
									log:debug("Undead spell roll failed on " .. name .. ".")
								end
							until (wasAdded == true or iterations == 30)
						else
							repeat
								local undSpell = math.random(1,44)
								log:trace("Undead Spell Table 2, #" .. undSpell .. ".")
								local learned = tables.undeadTable2[undSpell]
								local wasAdded = tes3.addSpell({ reference = companionRef, spell = learned })
								iterations = iterations + 1
								if wasAdded == true then
									tes3.messageBox("" .. name .. " learned to cast " .. learned .. "!")
									log:info("" .. name .. " learned to cast " .. learned .. ".")
									tes3.playSound({ sound = "ancestor ghost roar" })
								else
									log:debug("Undead spell roll failed on " .. name .. ".")
								end
							until (wasAdded == true or iterations == 60)
						end
					end
				end
				if config.abilityLearning == true then
					if modData.undlevel >= 5 then
						local ability = tables.abList[9]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Undead Type Ability Numbed Flesh!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[9] .. ".")
							tes3.playSound({ sound = "ancestor ghost scream" })
							modData.abilities[9] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability.")
						end
					end
					if modData.undlevel >= 10 then
						local ability = tables.abList[10]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Undead Type Ability Ancestral Memory!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[10] .. ".")
							tes3.playSound({ sound = "ancestor ghost scream" })
							modData.abilities[10] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability.")
						end
					end
					if modData.undlevel >= 15 then
						local ability = tables.abList[11]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Undead Type Ability Still Breath!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[11] .. ".")
							tes3.playSound({ sound = "ancestor ghost scream" })
							modData.abilities[11] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability.")
						end
					end
					if modData.undlevel >= 20 then
						local ability = tables.abList[12]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Undead Type Ability Total Decay!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[12] .. ".")
							tes3.playSound({ sound = "ancestor ghost scream" })
							modData.abilities[12] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability.")
						end
					end
				end
			end
			--Humanoid
			if cName == "Humanoid" then
				trainedAtt1 = 1
				trainedAtt2 = 2
				modData.humlevel = modData.humlevel + 1
				storedTlevel = modData.humlevel
				if config.spellLearningC == true then
					if math.random(1,99) < (config.spellChanceC + 10) then
						local iterations = 0
						if modData.level < 10 then
							repeat
								local humSpell = math.random(1,27)
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
								local humSpell = math.random(1,66)
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
				end
				if config.abilityLearning == true then
					if modData.humlevel >= 5 then
						local ability = tables.abList[13]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Humanoid Type Ability Strange Dream!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[13] .. ".")
							tes3.playSound({ sound = "ash vampire moan" })
							modData.abilities[13] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability.")
						end
					end
					if modData.humlevel >= 10 then
						local ability = tables.abList[14]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Humanoid Type Ability Abnormal Growth!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[14] .. ".")
							tes3.playSound({ sound = "ash vampire moan" })
							modData.abilities[14] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability.")
						end
					end
					if modData.humlevel >= 15 then
						local ability = tables.abList[15]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Humanoid Type Ability Painfully Awake!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[15] .. ".")
							tes3.playSound({ sound = "ash vampire moan" })
							modData.abilities[15] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability.")
						end
					end
					if modData.humlevel >= 20 then
						local ability = tables.abList[16]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Humanoid Type Ability Dream Mastery!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[16] .. ".")
							tes3.playSound({ sound = "ash vampire moan" })
							modData.abilities[16] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability.")
						end
					end
				end
			end
			--Centurion
			if cName == "Centurion" then
				trainedAtt1 = 0
				trainedAtt2 = 5
				modData.cenlevel = modData.cenlevel + 1
				storedTlevel = modData.cenlevel
				if config.spellLearningC == true then
					if math.random(1,99) < config.spellChanceC then
						local iterations = 0
						repeat
							local cenSpell = math.random(1,8)
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
				end
				if config.abilityLearning == true then
					if modData.cenlevel >= 5 then
						local ability = tables.abList[17]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Centurion Type Ability Precision!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[17] .. ".")
							tes3.playSound({ sound = "cent sphere scream" })
							modData.abilities[17] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability.")
						end
					end
					if modData.cenlevel >= 10 then
						local ability = tables.abList[18]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Centurion Type Ability Insulated Exoskeleton!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[18] .. ".")
							tes3.playSound({ sound = "cent sphere scream" })
							modData.abilities[18] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability.")
						end
					end
					if modData.cenlevel >= 15 then
						local ability = tables.abList[19]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Centurion Type Ability Augmented Grip!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[19] .. ".")
							tes3.playSound({ sound = "cent sphere scream" })
							modData.abilities[19] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability.")
						end
					end
					if modData.cenlevel >= 20 then
						local ability = tables.abList[20]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Centurion Type Ability Dwemer Refractors!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[20] .. ".")
							tes3.playSound({ sound = "cent sphere scream" })
							modData.abilities[20] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability.")
						end
					end
				end
			end
			--Spriggan
			if cName == "Spriggan" then
				trainedAtt1 = 1
				trainedAtt2 = 7
				modData.sprlevel = modData.sprlevel + 1
				storedTlevel = modData.sprlevel
				if config.spellLearningC == true then
					if math.random(1,99) < config.spellChanceC then
						local iterations = 0
						if modData.level < 10 then
							repeat
								local sprSpell = math.random(1,32)
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
								local sprSpell = math.random(1,74)
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
				end
				if config.abilityLearning == true then
					if modData.sprlevel >= 5 then
						local ability = tables.abList[21]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Spriggan Type Ability Sap Secretion!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[21] .. ".")
							tes3.playSound({ sound = "sprigganmagic" })
							modData.abilities[21] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability.")
						end
					end
					if modData.sprlevel >= 10 then
						local ability = tables.abList[22]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Spriggan Type Ability Jade Wind!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[22] .. ".")
							tes3.playSound({ sound = "sprigganmagic" })
							modData.abilities[22] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability.")
						end
					end
					if modData.sprlevel >= 15 then
						local ability = tables.abList[23]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Spriggan Type Ability Synthesis!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[23] .. ".")
							tes3.playSound({ sound = "sprigganmagic" })
							modData.abilities[23] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability.")
						end
					end
					if modData.sprlevel >= 20 then
						local ability = tables.abList[24]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Spriggan Type Ability Overgrowth!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[24] .. ".")
							tes3.playSound({ sound = "sprigganmagic" })
							modData.abilities[24] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability.")
						end
					end
				end
			end
			--Goblin
			if cName == "Goblin" then
				trainedAtt1 = 3
				trainedAtt2 = 4
				modData.goblevel = modData.goblevel + 1
				storedTlevel = modData.goblevel
				log:info("" .. name .. "'s Goblin level increased by 1.")
				if config.spellLearningC == true then
					if math.random(1,99) < config.spellChanceC then
						local iterations = 0
						repeat
							local gobSpell = math.random(1,20)
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
				end
				if config.abilityLearning == true then
					if modData.goblevel >= 3 then
						local ability = tables.abList[25]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Goblin Type Ability Quickness!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[25] .. ".")
							tes3.playSound({ sound = "goblin scream" })
							modData.abilities[25] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability!")
						end
					end
					if modData.goblevel >= 5 then
						local ability = tables.abList[26]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Goblin Type Ability Springstep!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[26] .. ".")
							tes3.playSound({ sound = "goblin scream" })
							modData.abilities[26] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability!")
						end
					end
					if modData.goblevel >= 7 then
						local ability = tables.abList[27]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Goblin Type Ability Enduring Quickness!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[27] .. ".")
							tes3.playSound({ sound = "goblin scream" })
							modData.abilities[27] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability!")
						end
					end
					if modData.goblevel >= 10 then
						local ability = tables.abList[28]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Goblin Type Ability Feral Parrying!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[28] .. ".")
							tes3.playSound({ sound = "goblin scream" })
							modData.abilities[28] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability!")
						end
					end
					if modData.goblevel >= 13 then
						local ability = tables.abList[29]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Goblin Type Ability Chameleon Skin!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[29] .. ".")
							tes3.playSound({ sound = "goblin scream" })
							modData.abilities[29] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability!")
						end
					end
					if modData.goblevel >= 15 then
						local ability = tables.abList[30]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Goblin Type Ability Boon of Muluk!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[30] .. ".")
							tes3.playSound({ sound = "goblin scream" })
							modData.abilities[30] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability!")
						end
					end
					if modData.goblevel >= 17 then
						local ability = tables.abList[31]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Goblin Type Ability Freedom of Movement!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[31] .. ".")
							tes3.playSound({ sound = "goblin scream" })
							modData.abilities[31] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability!")
						end
					end
					if modData.goblevel >= 20 then
						local ability = tables.abList[32]
						local wasAdded = tes3.addSpell({ reference = companionRef, spell = ability })
						if wasAdded == true then
							tes3.messageBox("" .. name .. " learned the Goblin Type Ability Perfect Dodge!")
							log:info("" .. name .. " learned the Ability " .. tables.abList[32] .. ".")
							tes3.playSound({ sound = "goblin scream" })
							modData.abilities[32] = true
						else
							log:debug("" .. name .. " already has the " .. ability .. " Ability!")
						end
					end
				end
			end
			if cName == "Domestic" then
				trainedAtt1 = 6
				trainedAtt2 = 7
				modData.domlevel = modData.domlevel + 1
				storedTlevel = modData.domlevel
				log:info("" .. name .. "'s Domestic level increased by 1.")
				if math.random(1, 160) < (companionRef.mobile.personality.base + modData.domlevel) then
					local pLuck = tes3.player.mobile.luck
					local pAmount = 1
					if config.aboveMaxAtt == false then
						if pLuck.base + pAmount > 100 then
							pAmount = math.max(100 - pLuck.base, 0)
						end
					end
					tes3.modStatistic({ attribute = 7, value = pAmount, reference = tes3.player })
					log:info("" .. name .. " Domestic Type bonus increased " .. tes3.player.object.name .. "'s Luck by " .. pAmount .. ".")
					tes3.messageBox("" .. name .. "'s presence made you feel lucky to have them around!")
					tes3.playSound({ sound = "guar moan" })
				end
			end
			----1st major attribute trained-------------------------------------------------------------------------------------------------
			local mAtt1 = tables.capitalization[trainedAtt1]
			local min1 = config.minMajorAtt1
			local max1 = config.maxMajorAtt1
			if min1 > max1 then
				max1 = min1
			end
			local mAttMod1 = math.random(min1, max1)
			local attTable1 = companionRef.mobile.attributes
			local offset1 = (trainedAtt1 + 1)
			local tAtt1 = attTable1[offset1]
			if config.aboveMaxAtt == false then
				if tAtt1.base + mAttMod1 > 100 then
					mAttMod1 = math.max(100 - tAtt1.base, 0)
				end
			end
			tes3.modStatistic({ attribute = trainedAtt1, value = mAttMod1, reference = companionRef })
			----2nd major attribute trained--------------------------------------------------------------------------------------------------
			local mAtt2 = tables.capitalization[trainedAtt2]
			local min2 = config.minMajorAtt2
			local max2 = config.maxMajorAtt2
			if min2 > max2 then
				max2 = min2
			end
			local mAttMod2 = math.random(min2, max2)
			local attTable2 = companionRef.mobile.attributes
			local offset2 = (trainedAtt2 + 1)
			local tAtt2 = attTable2[offset2]
			if (cName == "Normal" or cName == "Centurion" or cName == "Spriggan") then
				mAttMod2 = mAttMod2 + 1
				log:debug("Normal/Centurion/Spriggan Type Bonus to Secondary Attribute rewarded to " .. name .. ".")
			end
			if config.aboveMaxAtt == false then
				if tAtt2.base + mAttMod2 > 100 then
					mAttMod2 = math.max(100 - tAtt2.base, 0)
				end
			end
			tes3.modStatistic({ attribute = trainedAtt2, value = mAttMod2, reference = companionRef })
			----random attribute trained------------------------------------------------------------------------------------------------------
			local valueRand = math.random(0,7)
			local mAtt3 = tables.capitalization[valueRand]
			local min3 = config.minRandAtt
			local max3 = config.maxRandAtt
			if min3 > max3 then
				max3 = min3
			end
			local mAttMod3 = math.random(min3, max3)
			local attTable3 = companionRef.mobile.attributes
			local offset3 = (valueRand + 1)
			local tAtt3 = attTable3[offset3]
			if config.aboveMaxAtt == false then
				if tAtt3.base + mAttMod3 > 100 then
					mAttMod3 = math.max(100 - tAtt3.base, 0)
				end
			end
			tes3.modStatistic({ attribute = valueRand, value = mAttMod3, reference = companionRef })
			----health increased by 1/10th of endurance after training------------------------------------------------------------------------
			local hpMod = companionRef.mobile.endurance.base
			local hpBase = companionRef.mobile.health.base
			local hpChange = (hpMod * (config.healthMod * 0.01))
			local hpValue = (hpBase + hpChange)
			if config.levelHealth == true then
				tes3.modStatistic({ name = "health", value = math.round(hpChange), reference = companionRef })
				log:info("Leveling " .. name .. "'s health to " .. math.round(hpValue) .. ".")
				selectionHth = 1
			end
			local hpSummary = {
				[0] = "Fortitude remained unchanged",
				[1] = "Increased Fortitude to " .. math.round(hpValue) .."",
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
				[1] = "Magicka reserves increased to " .. math.round(companionRef.mobile.magicka.base) .."!",
			}
			----Creature Level up Summary----------------------------------------------------------------------------------------------------------
			if config.levelSummary == true then
				log:debug("" .. name .. "'s [LVL]: " .. storedLevel .. ". [Type]: " .. cName .. ". [HP]: " .. math.round(hpValue) .. " [MP]: " .. companionRef.mobile.magicka.base .. " [Attributes]: " .. mAtt1 .. " + " .. mAttMod1 .. ", " .. mAtt2 .. " + " .. mAttMod2 .. ", " .. mAtt3 .. " + " .. mAttMod3 .. "")
				local regsum = "" .. name .. " ascended to level " .. storedLevel .. "!\n\nType: " .. cName .. " level " .. storedTlevel .. ".\n\n" .. hpSummary[selectionHth] .. ", and " .. mgkSummary[selectionMgk] .. "\n\n" .. name .. " trained their " .. mAtt1 .. " by " .. mAttMod1 .. ", " .. mAtt2 .. " by " .. mAttMod2 .. ", and " .. mAtt3 .. " by " .. mAttMod3 .. "!"
				modData.summary = regsum
				log:debug("Level Summary triggered from " .. name .. "'s Creature Build Mode.")
				sumr.createWindow(companionRef)
				local menu = tes3ui.findMenu(sumr.id_menu)
				local block = menu:findChild("pane_block_sum")
				local pane = block:findChild(sumr.id_pane)
				local a = pane:createTextSelect{ text = "" .. name .. "", id = "sumSelectC_" .. i .. "" }
				a:register("mouseClick", function(e) sumr.onSelectC(i, companionRef) end)
				menu:updateLayout()
			else
				tes3.messageBox("" .. name .. " grew to level " .. storedLevel .. "!")
			end
		end
	end
	table.clear(companionTableCre)
	log:debug("Companion table cleared at end of Creature Class Mode.")
	tes3.playSound({sound = "skillraise"})
end





----Companion Table Generation---------------------------------------------------------------------------------------------------------------
local function companionCheck(e)
    for mobileActor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
        if (func.validCompanionCheck(mobileActor) and mobileActor.reference.object.objectType ~= tes3.objectType.creature) then
            companionTableNPC[#companionTableNPC +1] = mobileActor.reference
        end
		if (func.validCompanionCheck(mobileActor) and mobileActor.reference.object.objectType == tes3.objectType.creature) then
            companionTableCre[#companionTableCre +1] = mobileActor.reference
        end
	end
	log:debug("Class Mode tables generated.")
	companionLevelNPC(companionTableNPC)
	companionLevelCre(companionTableCre)
end

----Mode Select------------------------------------------------------------------------------------------------------------------------------
local function companionCheckBridge(e)
	if config.modEnabled == true then
		if config.buildMode == false then
			timer.start({ duration = 1, callback = companionCheck })
			log:debug("Class Mode triggered.")
		else
			timer.start({ duration = 1, callback = buildMode.companionCheck2 })
			log:debug("Build Mode triggered.")
		end
	end
end
event.register("levelUp", companionCheckBridge)
--tes3.event.jump for testing



----Class/Type/Build Change Controls-----------------------------------------------------------------------------
event.register("uiActivated", function()
    local actor = tes3ui.getServiceActor()
    if actor and func.validCompanionCheck(actor) then
        log:debug("NPC Follower detected. Giving class change topic.")
        tes3.setGlobal("kl_companion", 1)
    else
        log:debug("Target not an NPC Follower. No class change topic given.")
        tes3.setGlobal("kl_companion", 0)
    end
end, { filter = "MenuDialog" })

event.register(tes3.event.keyDown, function(e)
	if e.keyCode ~= config.typeBind.keyCode then return end
	local t = tes3.getPlayerTarget()
	if not t then return end
	if func.validCompanionCheck(t.mobile) then
		if t.object.objectType == tes3.objectType.creature then
			log:trace("Ability Check triggered on " .. t.object.name .. ". (Key Press)")
			local modData = func.getModData(t)
			for i = 1, 32 do
				if modData.abilities[i] == true then
					local wasAdded = tes3.addSpell({ spell = tables.abList[i], reference = t })
					if wasAdded == true then
						log:debug("" .. tables.abList[i] .. " added back to " .. t.object.name .. ".")
					else
						log:trace("" .. tables.abList[i] .. " not learned by " .. t.object.name .. ".")
					end
				end
			end
		end
		if config.buildMode == true then
			log:debug("Build Mode detected. Opening build selection.")
			buildChange.buildChange(t)
		else
			if t.object.objectType == tes3.objectType.creature then
				log:debug("Creature Follower detected. Opening type selection.")
				typeChange.typeChange(t)
			else
				log:debug("NPC Follower detected. Opening class selection.")
				classChange.classChange(t)
			end
		end
	end
end)


----Ability Removing/Re-Adding-----------------------------------------------------------------------------------------
local function abilityClear(e)
	if e.reference.object.objectType ~= tes3.objectType.creature then return end
	log:trace("Ability Check triggered on " .. e.reference.object.name .. ". (Activated)")
	if not func.validCompanionCheck(e.mobile) then
		for i = 1, 32 do
			local wasRemoved = tes3.removeSpell({ spell = tables.abList[i], reference = e.reference })
			if wasRemoved == true then
				log:debug("" .. tables.abList[i] .. " removed from " .. e.reference.object.name .. ".")
			else
				log:trace("" .. tables.abList[i] .. " not removed from " .. e.reference.object.name .. ".")
			end
		end
	else
		local modData = func.getModData(e.reference)
		for i = 1, 32 do
			if modData.abilities[i] == true then
				local wasAdded = tes3.addSpell({ spell = tables.abList[i], reference = e.reference })
				if wasAdded == true then
					log:debug("" .. tables.abList[i] .. " added back to " .. e.reference.object.name .. ".")
				else
					log:trace("" .. tables.abList[i] .. " not learned by " .. e.reference.object.name .. ".")
				end
			end
		end
	end
end
event.register(tes3.event.mobileActivated, abilityClear)





--Config Stuff------------------------------------------------------------------------------------------------------------------------------
event.register("modConfigReady", function()
    require("companionLeveler.mcm")
	config = require("companionLeveler.config")
end)