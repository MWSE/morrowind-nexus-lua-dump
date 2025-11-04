----Initialize----------------------------------------------------------------------------------------------------------
local config = require("companionLeveler.config")
local tables = require("companionLeveler.tables")
local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.functions.common")
local spells = require("companionLeveler.functions.spells")
local abilities = require("companionLeveler.functions.abilities")
local sumr = require("companionLeveler.menus.summary")


local buildMode = {}

--
----Build Mode-------------------------------------------------------------------------------------------------------------------------------------
--
function buildMode.companionLevelBuild(companions)
	log = logger.getLogger("Companion Leveler")
	local leveled = 0

	for i = #companions, 1, -1 do
		local companionRef = companions[i]
		local modData = func.getModData(companionRef)
		if modData.blacklist == false then
			leveled = leveled + 1
			local name = companionRef.object.name
			local attTable = {}
			local skillTable = {}
			----Level Increased by 1------------------------------------------------------------------------------------------------------
			modData.level = modData.level + 1
			log:debug("" .. name .. "'s level data increased by 1.")
			func.calcEXP(companionRef)
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
				tes3.modStatistic({ name = "health", value = math.round((hpMod * (config.healthMod * 0.01))),
					reference = companionRef })
				log:info("" .. name .. "'s Health increased to " .. math.round(hpValue) .. ".")
			end
			----NPC Skills-----------------------------------------------------------------------------------------------------------------------
			if companionRef.object.class ~= nil then
				--Training Sessions Reset
				modData.sessions_current = 0
				log:debug("" .. name .. "'s training session limit reset.")

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
				if (config.spellLearning == true and modData.spellLearning == true) then
					local restoRoll = false
					if (skillTable[16] > 0) then
						restoRoll = true
					end
					----Destruction-------------------------------------------------------------------------------------------------------------------
					local destroRoll = false
					if (skillTable[11] > 0) then
						destroRoll = true
					end
					----Alteration-------------------------------------------------------------------------------------------------------------------
					local alterRoll = false
					if (skillTable[12] > 0) then
						alterRoll = true
					end
					----Conjuration----------------------------------------------------------------------------------------------------------------
					local conjRoll = false
					if (skillTable[14] > 0) then
						conjRoll = true
					end
					----Illusion-----------------------------------------------------------------------------------------------------------------
					local illuRoll = false
					if (skillTable[13] > 0) then
						illuRoll = true
					end
					----Mysticism---------------------------------------------------------------------------------------------------------------------
					local mystRoll = false
					if (skillTable[15] > 0) then
						mystRoll = true
					end
					spells.spellRoll(restoRoll, destroRoll, alterRoll, conjRoll, illuRoll, mystRoll, companionRef)
				end
				----NPC Abilities------------------------------------------------------------------------------------------------------------
				if (config.abilityLearningNPC == true and modData.abilityLearning == true) then
					local class = tes3.findClass(modData.class)
					abilities.npcAbilities(class.name, companionRef)
				end
				if config.triggeredAbilities == true then
					abilities.executeAbilities(companionRef)
					abilities.contract(companionRef)
					abilities.bounty(companionRef)
				end
				--Technique Points
				modData.tp_max = modData.tp_max + 1
				modData.tp_current = modData.tp_max
			end
			----Creature Type Level---------------------------------------------------------------------------------------------------------------
			if companionRef.object.class == nil then
				local cType = modData.type
				local chance = config.spellChanceC
				for n = 1, #tables.typeTable do
                    if tables.typeTable[n] == cType then
                        modData.typelevels[n] = modData.typelevels[n] + 1
                        storedTlevel = modData.typelevels[n]
                        if cType == "Daedra" then
                            chance = chance + 2
                        end
                        if cType == "Undead" then
                            chance = chance + 2
                        end
                        if cType == "Humanoid" then
                            chance = chance + 10
                        end
                        if cType == "Spriggan" then
                            chance = chance + 3
                        end
                        if cType == "Spectral" then
                            chance = chance + 3
                        end
                        if cType == "Draconic" then
                            if modData.level % 2 ~= 0 then
                                chance = 0
                            else
                                chance = chance + 5
                            end
                        end
                        if cType == "Aquatic" then
                            chance = chance + 2
                        end
						if cType == "Impish" then
                            chance = chance + 3
                        end
                    end
                end
				log:info("" .. name .. "'s " .. cType .. " level increased by 1.")
				----Creature Spell Learning---------------------------------------------------------------------------------------------
				if (config.spellLearningC == true and modData.spellLearning == true) then
					if math.random(0, 99) < chance then
						spells.creatureSpellRoll(modData.level, cType, companionRef)
					end
				end
				if (config.abilityLearning == true and modData.abilityLearning == true) then
					abilities.creatureAbilities(cType, companionRef)
				end
			end
			----Level Summary--------------------------------------------------------------------------------------------------------------------
			if config.levelSummary == true then
				if companionRef.object.objectType ~= tes3.objectType.creature then
					local regsum = "" ..
						name ..
						" ascended to Level " ..
						storedLevel ..
						"!\n\n[Health]: " ..
						math.round(hpValue) ..
						", [Magicka]: " ..
						math.round(companionRef.mobile.magicka.base) ..
						" \n\n[Attributes]: Strength + " ..
						attTable[1] ..
						", Intelligence: + " ..
						attTable[2] ..
						", Willpower: + " ..
						attTable[3] ..
						", Agility: + " ..
						attTable[4] ..
						", Speed: + " ..
						attTable[5] ..
						", Endurance: + " ..
						attTable[6] ..
						", Personality: + " ..
						attTable[7] ..
						", Luck: + " ..
						attTable[8] ..
						".\n\n[Combat Skills]: Block + " ..
						skillTable[1] ..
						", Armorer + " ..
						skillTable[2] ..
						", Medium Armor + " ..
						skillTable[3] ..
						", Heavy Armor + " ..
						skillTable[4] ..
						", Blunt Weapon + " ..
						skillTable[5] ..
						", Long Blade + " ..
						skillTable[6] ..
						", Axe + " ..
						skillTable[7] ..
						", Spear + " ..
						skillTable[8] ..
						", Athletics + " ..
						skillTable[9] ..
						".\n\n[Magic Skills]: Enchant + " ..
						skillTable[10] ..
						", Destruction + " ..
						skillTable[11] ..
						", Alteration + " ..
						skillTable[12] ..
						", Illusion + " ..
						skillTable[13] ..
						", Conjuration + " ..
						skillTable[14] ..
						", Mysticism + " ..
						skillTable[15] ..
						", Restoration + " ..
						skillTable[16] ..
						", Alchemy + " ..
						skillTable[17] ..
						", Unarmored + " ..
						skillTable[18] ..
						".\n\n[Stealth Skills]: Security + " ..
						skillTable[19] ..
						", Sneak + " ..
						skillTable[20] ..
						", Acrobatics + " ..
						skillTable[21] ..
						", Light Armor + " ..
						skillTable[22] ..
						", Short Blade + " ..
						skillTable[23] ..
						", Marksman + " ..
						skillTable[24] ..
						", Mercantile + " ..
						skillTable[25] .. ", Speechcraft + " .. skillTable[26] .. ", Hand-to-Hand + " .. skillTable[27] .. "."
					modData.summary = regsum
					sumr.createWindow(companionRef)
					log:debug("Level Summary triggered from " .. name .. "'s NPC Build Mode.")
					local menu = tes3ui.findMenu(sumr.id_menu)
					local block = menu:findChild("pane_block_sum")
					local pane = block:findChild(sumr.id_pane)
					local a = pane:createTextSelect { text = "" .. name .. "", id = "sumSelect_" .. i .. "" }
					a:register("mouseClick", function(e) sumr.onSelectN(i, companionRef) end)
					menu:updateLayout()
				else
					local abilityString = ""
					for n = 1, #tables.abList do
						if modData.abilities[n] == true then
							abilityString = abilityString .. tes3.getObject(tables.abList[n]).name .. ", "
						end
					end
					abilityString = string.gsub(abilityString, ", $", ".", 1)
					local regsum = "" ..
						name ..
						" ascended to Level " ..
						storedLevel ..
						"!\n\n[Health]: " ..
						math.round(hpValue) ..
						", [Magicka]: " ..
						companionRef.mobile.magicka.base ..
						" \n\n[Type]: " ..
						modData.type ..
						" level " ..
						storedTlevel ..
						".\n\n[Attributes]: Strength + " ..
						attTable[1] ..
						", Intelligence: + " ..
						attTable[2] ..
						", Willpower: + " ..
						attTable[3] ..
						", Agility: + " ..
						attTable[4] ..
						", Speed: + " ..
						attTable[5] ..
						", Endurance: + " ..
						attTable[6] ..
						", Personality: + " .. attTable[7] .. ", Luck: + " .. attTable[8] .. ".\n\nAbilities: " .. abilityString .. ""
					modData.summary = regsum
					sumr.createWindow(companionRef)
					log:debug("Level Summary triggered from " .. name .. "'s Creature Build Mode.")
					local menu = tes3ui.findMenu(sumr.id_menu)
					local block = menu:findChild("pane_block_sum")
					local pane = block:findChild(sumr.id_pane)
					local a = pane:createTextSelect { text = "" .. name .. "", id = "sumSelectC_" .. i .. "" }
					a:register("mouseClick", function(e) sumr.onSelectC(i, companionRef) end)
					menu:updateLayout()
				end
			else
				func.clMessageBox("" .. name .. " grew to level " .. storedLevel .. "!")
			end
		end
	end
	if leveled > 0 then
		tes3.playSound({ sound = "skillraise" })
	end

	--Start Recurring Ability Timer (Triggered)
	local modDataP = func.getModDataP()
	if modDataP.noDupe == 0 then
		timer.start({ type = timer.game, duration = math.random(48, 96), iterations = 1, callback = "companionLeveler:abilityTimer2" })
		modDataP.noDupe = 1
	end
    --Start Hourly Timer
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

return buildMode