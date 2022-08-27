----Initialize----------------------------------------------------------------------------------------------------------
local config = require("companionLeveler.config")
local tables = require("companionLeveler.tables")
local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.common")
local sumr = require("companionLeveler.summary")
local companionTableB = {}

local buildMode = {}


----Build Mode--------------------------------------------------------------------------------------------------------------------
function buildMode.companionLevel2(companionsZ)
	for i = #companionsZ, 1, -1 do
		log = logger.getLogger("Companion Leveler")
		local companionRef = companionsZ[i]
		local name = companionRef.object.name
		local modData = func.getModData(companionRef)
		local attTable = {}
		local skillTable = {}
		----Level Increased by 1------------------------------------------------------------------------------------------------------
		modData.level = modData.level + 1
		log:debug("" .. name .. "'s level data increased by 1.")
		local storedLevel = modData.level
		local storedTlevel = 0
		for n = 1, 8 do
			local att = companionRef.mobile.attributes[n]
			local min = modData.attMods[n]
			local max = modData.attModsMax[n]
			if min > max then
				max = min
			end
			local amount = math.random(min, max)
			local offset = (n - 1)
			if config.aboveMaxAtt == false then
				if att.base + amount > 100 then
					amount = math.max(100 - att.base, 0)
				end
			end
			tes3.modStatistic({ attribute = offset, value = amount, reference = companionRef })
			attTable[n] = amount
			log:debug("" .. tables.capitalization[offset] .. " increased by " .. amount .. ".")
		end
		----Level Health--------------------------------------------------------------------------------------------------------------------
		local hpMod = companionRef.mobile.endurance.base
		local hpBase = companionRef.mobile.health
		local hpValue = (hpBase.base + (hpMod * (config.healthMod * 0.01)))
		if config.levelHealth == true then
			tes3.modStatistic({ name = "health", value = math.round((hpMod * (config.healthMod * 0.01))), reference = companionRef })
			log:info("" .. name .. "'s Health increased to " .. math.round(hpValue) .. ".")
		end
		----NPC Skills-----------------------------------------------------------------------------------------------------------------------
		if companionRef.object.class ~= nil then
			for n = 1, 27 do
				local offset = (n - 1)
				local skill = companionRef.mobile:getSkillStatistic(offset)
				local min = modData.skillMods[n]
				local max = modData.skillModsMax[n]
				if min > max then
					max = min
				end
				local amount = math.random(min, max)
				if config.aboveMaxSkill == false then
					if skill.base + amount > 100 then
						amount = math.max(100 - skill.base, 0)
					end
				end
				tes3.modStatistic({ skill = offset, value = amount, reference = companionRef })
				skillTable[n] = amount
				log:debug("" .. tes3.skillName[offset] .. " increased by " .. amount .. ".")
			end
		----NPC Spell Learning----------------------------------------------------------------------------------------------------------------
		----Restoration-------------------------------------------------------------------------------------------------------------------
			if config.spellLearning == true then
				local restoRoll = false
				if (skillTable[16] > 0) then
					restoRoll = true
				end
				if restoRoll == true then
					local mrValue = companionRef.mobile:getSkillStatistic(15)
					if math.random(0,99) < config.spellChance then
						if mrValue.base >= 25 and mrValue.base < 50 then
							local iterations = 0
							repeat
								local rSpell = math.random(1,5)
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
								local rSpell = math.random(1,23)
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
				if (skillTable[11] > 0) then
					destroRoll = true
				end
				if destroRoll == true then
					local mdValue = companionRef.mobile:getSkillStatistic(10)
					if math.random(0,99) < config.spellChance then
						if mdValue.base >= 25 and mdValue.base < 50 then
							local iterations = 0
							repeat
								local dSpell = math.random(1,7)
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
				if (skillTable[12] > 0) then
					alterRoll = true
				end
				if alterRoll == true then
					local maValue = companionRef.mobile:getSkillStatistic(11)
					if math.random(0,99) < config.spellChance then
						if maValue.base >= 25 and maValue.base < 50 then
							local iterations = 0
							repeat
								local aSpell = math.random(1,5)
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
				if (skillTable[14] > 0) then
					conjRoll = true
				end
				if conjRoll == true then
					local mcValue = companionRef.mobile:getSkillStatistic(13)
					if math.random(0,99) < config.spellChance then
						if mcValue.base >= 25 and mcValue.base < 50 then
							local iterations = 0
							repeat
								local cSpell = math.random(1,6)
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
				if (skillTable[13] > 0) then
					illuRoll = true
				end
				if illuRoll == true then
					local miValue = companionRef.mobile:getSkillStatistic(12)
					if math.random(0,99) < config.spellChance then
						if miValue.base >= 25 and miValue.base < 50 then
							local iterations = 0
							repeat
								local iSpell = math.random(1,6)
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
				if (skillTable[15] > 0) then
					mystRoll = true
				end
				if mystRoll == true then
					local mmValue = companionRef.mobile:getSkillStatistic(14)
					if math.random(0,99) < config.spellChance then
						if mmValue.base >= 25 and mmValue.base < 50 then
							local iterations = 0
							repeat
								local mSpell = math.random(1,5)
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
		end
		----Creature Spell Learning---------------------------------------------------------------------------------------------
		if companionRef.object.class == nil then
			local cType = modData.type
			--Normal
			if cType == "Normal" then
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
			if cType == "Daedra" then
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
			if cType == "Undead" then
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
			if cType == "Humanoid" then
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
			if cType == "Centurion" then
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
			if cType == "Spriggan" then
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
			if cType == "Goblin" then
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
			if cType == "Domestic" then
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
		end
		----Level Summary--------------------------------------------------------------------------------------------------------------------
		if config.levelSummary == true then
			if companionRef.object.objectType ~= tes3.objectType.creature then
				local regsum = "" .. name .. " ascended to Level " .. storedLevel .. "!\n\n[Health]: " .. math.round(hpValue) .. ", [Magicka]: " .. math.round(companionRef.mobile.magicka.base) .. " \n\n[Attributes]: Strength + " .. attTable[1] .. ", Intelligence: + " .. attTable[2] .. ", Willpower: + " .. attTable[3] .. ", Agility: + " .. attTable[4] .. ", Speed: + " .. attTable[5] .. ", Endurance: + " .. attTable[6] .. ", Personality: + " .. attTable[7] .. ", Luck: + " .. attTable[8] .. ".\n\n[Combat Skills]: Block + " .. skillTable[1] .. ", Armorer + " .. skillTable[2] .. ", Medium Armor + " .. skillTable[3] .. ", Heavy Armor + " .. skillTable[4] .. ", Blunt Weapon + " .. skillTable[5] .. ", Long Blade + " .. skillTable[6] .. ", Axe + " .. skillTable[7] .. ", Spear + " .. skillTable[8] .. ", Athletics + " .. skillTable[9] .. ".\n\n[Magic Skills]: Enchant + " .. skillTable[10] .. ", Destruction + " .. skillTable[11] .. ", Alteration + " .. skillTable[12] .. ", Illusion + " .. skillTable[13] .. ", Conjuration + " .. skillTable[14] .. ", Mysticism + " .. skillTable[15] .. ", Restoration + " .. skillTable[16] .. ", Alchemy + " .. skillTable[17] .. ", Unarmored + " .. skillTable[18] .. ".\n\n[Stealth Skills]: Security + " .. skillTable[19] .. ", Sneak + " .. skillTable[20] .. ", Acrobatics + " .. skillTable[21] .. ", Light Armor + " .. skillTable[22] .. ", Short Blade + " .. skillTable[23] .. ", Marksman + " .. skillTable[24] .. ", Mercantile + " .. skillTable[25] .. ", Speechcraft + " .. skillTable[26] .. ", Hand-to-Hand + " .. skillTable[27] .. "."
				modData.summary = regsum
				sumr.createWindow(companionRef)
				log:debug("Level Summary triggered from " .. name .. "'s NPC Build Mode.")
				local menu = tes3ui.findMenu(sumr.id_menu)
				local block = menu:findChild("pane_block_sum")
				local pane = block:findChild(sumr.id_pane)
				local a = pane:createTextSelect{ text = "" .. name .. "", id = "sumSelect_" .. i .. "" }
				a:register("mouseClick", function(e) sumr.onSelectN(i, companionRef) end)
				menu:updateLayout()
			else
				local regsum = "" .. name .. " ascended to Level " .. storedLevel .. "!\n\n[Health]: " .. math.round(hpValue) .. ", [Magicka]: " .. companionRef.mobile.magicka.base .. " \n\n[Type]: " .. modData.type .. " level " .. storedTlevel .. ".\n\n[Attributes]: Strength + " .. attTable[1] .. ", Intelligence: + " .. attTable[2] .. ", Willpower: + " .. attTable[3] .. ", Agility: + " .. attTable[4] .. ", Speed: + " .. attTable[5] .. ", Endurance: + " .. attTable[6] .. ", Personality: + " .. attTable[7] .. ", Luck: + " .. attTable[8] .. "."
				modData.summary = regsum
				sumr.createWindow(companionRef)
				log:debug("Level Summary triggered from " .. name .. "'s Creature Build Mode.")
				local menu = tes3ui.findMenu(sumr.id_menu)
				local block = menu:findChild("pane_block_sum")
				local pane = block:findChild(sumr.id_pane)
				local a = pane:createTextSelect{ text = "" .. name .. "", id = "sumSelectC_" .. i .. "" }
				a:register("mouseClick", function(e) sumr.onSelectC(i, companionRef) end)
				menu:updateLayout()
			end
		else
			tes3.messageBox("" .. name .. " grew to level " .. storedLevel .. "!")
		end
	end
	tes3.playSound({sound = "skillraise"})
	table.clear(companionTableB)
	log:debug("Companion Table cleared at end of Build Mode.")
end

function buildMode.companionCheck2(e)
    for mobileActor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
        if (func.validCompanionCheck(mobileActor)) then
            companionTableB[#companionTableB +1] = mobileActor.reference
        end
	end
	log = logger.getLogger("Companion Leveler")
	log:debug("Build Mode table generated.")
	buildMode.companionLevel2(companionTableB)
end

return buildMode