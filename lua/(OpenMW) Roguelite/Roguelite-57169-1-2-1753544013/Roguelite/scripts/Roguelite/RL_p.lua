I = require('openmw.interfaces')
types = require('openmw.types')
self = require('openmw.self')
Player = require('openmw.types').Player
async = require('openmw.async')
ui = require('openmw.ui')
util = require('openmw.util')
v2 = util.vector2
I = require('openmw.interfaces')
core = require('openmw.core')
ambient = require('openmw.ambient')
animation = require('openmw.animation')
input = require('openmw.input')
local camera = require('openmw.camera')
nearby = require('openmw.nearby')
local time = require('openmw_aux.time')

MODNAME = "Roguelite"
local storage = require('openmw.storage')
playerSection = storage.playerSection('Settings'..MODNAME)
local settings = require("scripts.Roguelite.RL_settings")
runDB = storage.playerSection("Roguelite_runs")
--globalSection = storage.globalSection('Roguelite')
updateChallengeTracker = require("scripts.Roguelite.ui_hud_challengeTracker")

onFrameFunctions = {}
onFrameJobs = {}
iterateOnFrameJobs = nil
buttonFocus = nil
local currentCell
inventoryBeforeAlchemy = {}
potionsBeforeAlchemy = 0
local alchemyMode = false
--local lastSleepTick = nil
hudAlpha = 0
skillSet = {}
RESTLESS_SURVIVAL_CHEAT = false



-- AVERAGE ITEM VALUE
local categories = {"Weapon", "Armor", "Miscellaneous", "Apparatus", "Clothing", "Potion"}
local allValues = {}
for _, cat in ipairs(categories) do
    local records = types[cat] and types[cat].records
    if records then
        for _, record in ipairs(records) do
            if record.value and record.value > 0 then
                table.insert(allValues, record.value)
            end
        end
    end
end
table.sort(allValues, function(a, b) return a > b end)
local topCount = math.ceil(#allValues * 0.33)
local bottomCount = math.ceil(#allValues * 0.01)
local sum = 0
for i = bottomCount, topCount do
    sum = sum + allValues[i]
end
averageItemValue = sum / topCount

local function thousandsSeperator(amount)
  local formatted = amount
  while true do  
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2')
    if (k==0) then
      break
    end
  end
  return formatted
end

challengeData = {
slayer={
        id = "slayer", 
        name = "Blood-Soaked Warrior", 
        description = "Slay 300 enemies",
		requirement = 300,
		icon = "textures/roguelite/slayer.png",
		hudIcon = "textures/roguelite/slayer_hud.png",
    },
merchant={
        id = "merchant", 
        name = "Golden Hoarder", 
        description = "Amass "..thousandsSeperator(math.ceil(averageItemValue*0.1)*800).." g",
		requirement = math.ceil(averageItemValue*0.1)*800,
		icon = "textures/roguelite/merchant.png",
		hudIcon = "textures/roguelite/merchant_hud.png",
    },
questline={
        id = "questline", 
        name = "Fate's Champion", 
        description = "Complete a major questline (Main Quests or Factions)",
		requirement = 1,
		icon = "textures/roguelite/questline.png",
		hudIcon = "textures/roguelite/questline_hud.png",
    },
museum={
        id = "museum", 
        name = "Curator of Legends", 
        description = "Donate 7 artifacts to the museum",
		requirement = 7,
		icon = "textures/roguelite/museum.png",
		hudIcon = "textures/roguelite/museum_hud.png",
    },
dungeons={
        id = "dungeons", 
        name = "Tomb Raider", 
        description = "Clear 20 dungeons",
		requirement = 20,
		icon = "textures/roguelite/dungeons.png",
		hudIcon = "textures/roguelite/dungeons_hud.png",
    },
level={
        id = "level", 
        name = "Ascendant Hero", 
        description = "Reach level 20",
		requirement = 20,
		icon = "textures/roguelite/level.png",
		hudIcon = "textures/roguelite/level_hud.png",
    },
survival={
        id = "survival", 
        name = "Restless Wanderer", 
        description = "Survive 14 days without resting or waiting (can still level up)",
		requirement = 14,
		icon = "textures/roguelite/survival.png",
		hudIcon = "textures/roguelite/survival_hud.png",
    },
vampirism={
        id = "vampirism", 
        name = "Curse Breaker", 
        description = "Find a cure for your vampirism",
		requirement = 1,
		fixRequirement = true,
		icon = "textures/roguelite/vampirism.png",
		hudIcon = "textures/roguelite/vampirism_hud.png",
    },
}

db_museum = require("scripts.Roguelite.db_museum")
db_questlines = require("scripts.Roguelite.db_questlines")


---------------------------------------------------------------------------------------------------------------------- DIALOGUES ----------------------------------------------------------------------------------------------------------------------
function makeNextDialogue()
	--require("scripts.Roguelite.crafting_framework")
	--do return end

	if not saveData.challenges then
		require("scripts.Roguelite.ui_dialogue_challenge")
	elseif not saveData.blessings then
		if (runDB:get("UNLOCKED_BLESSINGS") or 0) + playerSection:get("EXTRA_BLESSINGS") < 1 then
			saveData.blessings = {}
			I.UI.setMode() --DONE
			skillSet = {}
			local classRecord = types.NPC.record(self).class and types.NPC.classes.record(types.NPC.record(self).class)
			if classRecord then
				for _, skill in pairs(classRecord.majorSkills) do
					skillSet[skill] = 2
				end
				for _, skill in pairs(classRecord.minorSkills) do
					skillSet[skill] = 1
				end
			end
		else
			require("scripts.Roguelite.ui_dialogue_blessing")
		end
	elseif saveData.blessings.birthsign and not saveData.additionalBirthsign then
		require("scripts.Roguelite.ui_dialogue_birthsign")
	elseif saveData.blessings.attribute and not saveData.boostedAttribute then
		require("scripts.Roguelite.ui_dialogue_attribute")
	else
		I.UI.setMode() --DONE
		skillSet = {}
		local classRecord = types.NPC.record(self).class and types.NPC.classes.record(types.NPC.record(self).class)
		if classRecord then
			for _, skill in pairs(classRecord.majorSkills) do
				skillSet[skill] = 2
			end
			for _, skill in pairs(classRecord.minorSkills) do
				skillSet[skill] = 1
			end
		end
	end
end

function blessingSelectionReturn(selectedBlessings)
	saveData.blessings = {}
	for _, id in pairs(selectedBlessings) do
		if id == "disposition" then
			types.NPC.stats.skills.mercantile(self).base = types.NPC.stats.skills.mercantile(self).base + 25
		end
		saveData.blessings[id] = 1
		if core.magic.spells.records["roguelite_"..id] then
			types.Actor.spells(self):add("roguelite_"..id)
		end
		if id == "teleportation" then
			types.Actor.spells(self):add("roguelite_almsivi")
			types.Actor.spells(self):add("roguelite_divine")
			types.Actor.spells(self):add("roguelite_recall")
			types.Actor.spells(self):add("roguelite_mark")
		end
	end
	lastLevel = nil --recheck level
	if saveData.blessings.disposition then
		core.sendGlobalEvent("Roguelite_hasDispositionBlessing", self)
	end
	if saveData.blessings.herbalist then
		if I.HUDMarkers and I.HUDMarkers.version >=6 and playerSection:get("DETECT_INGREDIENTS") then
			I.HUDMarkers.setIngredientBonus("Roguelite", 120)
			I.HUDMarkers.setHerbBonus("Roguelite", 120)
		end
	end
	
	makeNextDialogue()
end

function attributeSelectionReturn(selectedAttribute)
	types.NPC.stats.attributes[selectedAttribute](self).base = 80
	saveData.boostedAttribute = selectedAttribute
	makeNextDialogue()
end

function birthsignSelectionReturn(selectedBirthsign)
	local birthsign = types.Player.birthSigns.records[selectedBirthsign]
	for _, spellId in ipairs(birthsign.spells) do
		types.Actor.spells(self):add(spellId)
	end
	saveData.additionalBirthsign = selectedBirthsign
	makeNextDialogue()
end

function challengeSelectionReturn(selectedChallenges)
	saveData.challenges = {}
	for a,b in pairs(selectedChallenges) do
		saveData.challenges[b] = 0
		if b == "vampirism" then
			core.sendGlobalEvent("Roguelite_startVampirism", self)
		end
		if b == "merchant" then
			saveData.progress.merchant = types.Actor.inventory(self):countOf("gold_001")
		end
		if b == "survival" then
			saveData.progress.survival = 0
		end
	end
	saveData.startTime = core.getGameTime()
	updateChallengeTracker()
	makeNextDialogue()
end



function chargenDialogueReturn(button)
	if button == "yesButton" then
		saveData.runId = tostring(math.random())
		while runDB:get(saveData.runId) do
			saveData.runId = tostring(math.random())
		end
		saveData.completedChallenges = 0
		runDB:set(saveData.runId,0)
		for _, att in pairs(types.NPC.stats.attributes) do
			att(self).base = math.floor(att(self).base * playerSection:get("ATTRIBUTE_MULT")) - math.floor( playerSection:get("ATTRIBUTE_SUBTRACT"))
		end
		for _, skill in pairs(types.NPC.stats.skills) do
			skill(self).base = math.floor(skill(self).base * playerSection:get("SKILL_MULT")) - math.floor( playerSection:get("SKILL_SUBTRACT"))
		end
		saveData.finishedChargen = true
		makeNextDialogue()
	elseif button == "neverButton" then
		saveData.finishedChargen = true
		I.UI.setMode()
	else
		I.UI.setMode()
	end
end
---------------------------------------------------------------------------------------------------------------------- LOGIC ----------------------------------------------------------------------------------------------------------------------




local function onFrame(dt)
	for _, onFrameFunction in pairs(onFrameFunctions) do
		onFrameFunction(dt)
	end
	-- chargen finished, save and spawn dialogue on save callback
	if self.cell then
		if not currentCell or self.cell.id ~=currentCell.id then
			if saveData.challenges and saveData.challenges.dungeons == 0 then
				core.sendGlobalEvent("Roguelite_cellChanged", self)
			end
			local newGen = types.Player.isCharGenFinished(self)
			if newGen and newGen ~= saveData.finishedChargen then
				self.type.sendMenuEvent(self, 'Roguelite_saveBeforeStart')
				onFrameFunctions["afterGameSavedBeforeStart"] = function(dt)
					if dt > 0 then
						I.UI.setMode('Interface', {windows = {}})
						require("scripts.Roguelite.ui_dialogue_start")
						
						onFrameFunctions["afterGameSavedBeforeStart"] = nil
					end
				end
			end
			currentCell = self.cell
		end
	end
	iterateOnFrameJobs = next(onFrameJobs,iterateOnFrameJobs)
	if iterateOnFrameJobs then
		onFrameJobs[iterateOnFrameJobs](dt)
	end
end


-- IRONMAN
table.insert(onFrameJobs, function(dt)
	if saveData.runId then
		local health = types.Actor.stats.dynamic.health(self).current
		if not deadYet and health <= 0 then
			print("died")
			runDB:set(saveData.runId, runDB:get(saveData.runId) + 1)
			deadYet = true
		elseif health > 0 then
			deadYet = false
		end
	end

end)

local function applyPerfectGrowth()
	if saveData.blessings and saveData.blessings.maxgains then
		for _, attributeRecord in pairs(core.stats.Attribute.records) do
			if attributeRecord.id ~= "luck" then
				types.Actor.stats.level(self).skillIncreasesForAttribute[attributeRecord.id] = 10
			end
		end
	end
end

local function applyStuntedGrowth()
	if saveData.boostedAttribute then
		onFrameFunctions["stuntedGrowth"] = function()
			types.Actor.stats.level(self).skillIncreasesForAttribute[saveData.boostedAttribute] = 0
			onFrameFunctions["stuntedGrowth"] = nil
		end
	end
end

-- LEVELUP (challenge + perfect growth)
table.insert(onFrameJobs, function(dt)
	if saveData.runId then
		local level = types.Actor.stats.level(self).current
		if level ~= lastLevel then
			saveData.progress.level = level
			lastLevel = level
			applyPerfectGrowth()
			applyStuntedGrowth()
		end
	end
end)
table.insert(onFrameJobs, function(dt)
	if saveData.challenges and hudAlpha > 0 and hud_challengeTracker then
		hudAlpha = hudAlpha - 0.007
		hud_challengeTracker.layout.props.alpha = math.max(0,math.min(1,hudAlpha))^2
		hud_challengeTracker:update()
	end
end)

-- GOLD + DAY CHECK (merchant challenge)
table.insert(onFrameJobs, function(dt)
	if saveData.challenges then
		local needsUpdate = false
		if saveData.challenges.merchant == 0 then
			local gold = types.Actor.inventory(self):countOf("gold_001")
			if gold ~= saveData.progress.merchant then
				saveData.progress.merchant = gold
				needsUpdate = "merchant"
			end
		end
		if saveData.challenges.survival == 0 then
			local lastSurvival = saveData.progress.survival
			if saveData.startTime then
				saveData.progress.survival = math.floor((core.getGameTime() - saveData.startTime) / time.day)
				if lastSurvival ~= saveData.progress.survival then
					needsUpdate = "survival"
					hudAlpha = 2.5
				end
			end
		end
		if needsUpdate then
			updateChallengeTracker(needsUpdate)
		end
	end
end)

-- SKILL LEVEL UP (Divine Inspiration)
I.SkillProgression.addSkillLevelUpHandler(function(skillId, source,options)
	local now = core.getRealTime()
	print(source, "SkillLevelUp, slowmode pass:", now > (skillUpSlowMode or 0) + 0.1, skillId, saveData.blessings and saveData.blessings.scholar and "isScholar", types.NPC.stats.skills[skillId](self).base)
	if saveData.blessings and now > (skillUpSlowMode or 0) + 0.1  then
		local runs = 1
		if saveData.blessings.scholar and source == "book" then
			types.NPC.stats.skills[skillId](self).base = types.NPC.stats.skills[skillId](self).base + 6
			print("leveled to",types.NPC.stats.skills[skillId](self).base)
			types.Actor.stats.level(self).skillIncreasesForAttribute[options.levelUpAttribute] = types.Actor.stats.level(self).skillIncreasesForAttribute[options.levelUpAttribute] + 6
			local classRecord =  types.NPC.classes.record(types.NPC.record(self).class)
			for _, skill in pairs(classRecord.majorSkills) do
				if skill == skillId then
					types.Actor.stats.level(self).progress = types.Actor.stats.level(self).progress+4
					break
				end
			end
			for _, skill in pairs(classRecord.minorSkills) do
				if skill == skillId then
					types.Actor.stats.level(self).progress = types.Actor.stats.level(self).progress+4
					break
				end
			end
			runs = 7
		end
		for i=1, runs do
			if saveData.blessings.skillup then
				local chance = 2^(skillSet[skillId] or 0)*0.125
				if math.random() < chance then
					local rndId = math.random(1,#core.stats.Attribute.records)
					local att = core.stats.Attribute.records[rndId].id
					print("+1 "..att)
					types.NPC.stats.attributes[att](self).base = types.NPC.stats.attributes[att](self).base + 1
					ui.showMessage(core.stats.Attribute.records[rndId].name.." increased to "..math.floor(types.NPC.stats.attributes[att](self).base+0.01))
				end
			end
		end
		applyPerfectGrowth()
		applyStuntedGrowth()
	end
	skillUpSlowMode = now
end)


require("scripts.Roguelite.blessing_shadowdancer")
require("scripts.Roguelite.blessing_resurgence")

--local function UiModeChanged(data)
--	if data.newMode == "Dialogue" and data.arg and types.NPC.objectIsInstance(data.arg) then
--		print(types.Actor.inventory(data.arg):find("gold_001"))
--		if saveData.blessings and saveData.blessings.disposition then
--			core.sendGlobalEvent("Roguelite_setBarterGold",{data.arg,1000})
--		end
--	end
--end

-- ALCHEMY BLESSING
table.insert(onFrameJobs, function(dt)
	if alchemyMode and saveData.blessings and saveData.blessings.alchemist then
		local tempInventory= {}
		local potionsAfterAlchemy = 0
		for a,b in pairs(types.Actor.inventory(self):getAll()) do
			tempInventory[b.id]= {count = b.count, item = b}
			if types.Potion.objectIsInstance(b) then
				potionsAfterAlchemy = potionsAfterAlchemy + b.count
			end
		end
		
		local flawless = false
		if math.random() < 0.40 then
			for id, t in pairs(tempInventory) do
				if types.Potion.objectIsInstance(t.item) and types.Potion.record(t.item).name:sub(1,#"Flawless ") ~= "Flawless " and (not inventoryBeforeAlchemy[id] or inventoryBeforeAlchemy[id].count < t.count) then
					flawless = true
					core.sendGlobalEvent("Roguelite_buffPotion", {self, t.item, t.count - ( inventoryBeforeAlchemy[id] and inventoryBeforeAlchemy[id].count or 0)})
				end
			end
		end
		local rnd = math.random()
		if potionsAfterAlchemy == potionsBeforeAlchemy and rnd < 0.6 then -- actually 30%
			local recoupedIngredients = 0
			for id, t in pairs(inventoryBeforeAlchemy) do
				if types.Ingredient.objectIsInstance(t.item) and (not tempInventory[id] or tempInventory[id].count < t.count) and math.random() < 0.5 then
					recoupedIngredients = recoupedIngredients + 1
					core.sendGlobalEvent("Roguelite_spawnItem", {self, t.item.recordId, tempInventory[id] and t.count - tempInventory[id].count or t.count})
				end
			end
			if recoupedIngredients > 0 then
				ui.showMessage("rescued "..recoupedIngredients.." ingredient"..(recoupedIngredients>1 and "s" or ""))
			end
		elseif potionsAfterAlchemy > potionsBeforeAlchemy and rnd < 0.5 then
			local recoupedIngredients ={} -- recordId, count
			local totalValue = 0
			for id, t in pairs(inventoryBeforeAlchemy) do
				if types.Ingredient.objectIsInstance(t.item) and (not tempInventory[id] or tempInventory[id].count < t.count) then
					table.insert(recoupedIngredients, {t.item.recordId, tempInventory[id] and t.count - tempInventory[id].count or t.count})
					totalValue = totalValue + t.item.type.record(t.item).value
				end
			end
			if rnd < 0.04+totalValue^0.6*0.006 then -- 100 = 14%, 300 = 22%, 600 = 32%, 1000 = 42%, 1500 = 52%
				for _, t in pairs(recoupedIngredients) do
					core.sendGlobalEvent("Roguelite_spawnItem", {self, t[1], t[2]})
				end
				if flawless then
					ui.showMessage("Flawless free potion!")
				else
					ui.showMessage("Free potion!")
				end
			end
		elseif flawless then
			ui.showMessage("Flawless!")
		end
		inventoryBeforeAlchemy = tempInventory
		potionsBeforeAlchemy = potionsAfterAlchemy
	end
end)


-- SLUMBER, RESTLESS AND ALCHEMY
local function UiModeChanged(data)
	-- ALCHEMIST
	if data.newMode == "Alchemy" then
		alchemyMode = true
		inventoryBeforeAlchemy= {}
		potionsBeforeAlchemy = 0
		for a,b in pairs(types.Actor.inventory(self):getAll()) do
			inventoryBeforeAlchemy[b.id]= {count = b.count, item = b}
			if types.Potion.objectIsInstance(b) then
				potionsBeforeAlchemy = potionsBeforeAlchemy +b.count
			end
		end
	else
		alchemyMode = false
	end	
	-- SLUMBER
	if saveData and saveData.blessings and saveData.blessings.slumber then
		if data.oldMode == "Rest" and data.newMode == nil then --can happen when traveling (fixed for singleplayer)
			core.sendGlobalEvent("Roguelite_wakeUp", self)
		end
		if data.oldMode == "Rest" and data.newMode == "Rest" then
			core.sendGlobalEvent("Roguelite_slumberMode")
		end
	end
	if saveData.challenges then
		-- RESTLESS
		if saveData and saveData.challenges.survival == 0 and not RESTLESS_SURVIVAL_CHEAT then
			if data.oldMode == "Rest" and data.newMode == "Rest" then
				if types.Actor.stats.level(self).progress >= core.getGMST("iLevelupTotal") then
					I.UI.setMode("LevelUp")
				else
					I.UI.setMode()
				end
			end
		end
		-- MUSEUM
		if saveData.challenges.museum == 0 and data.newMode == "Dialogue" and data.arg and data.arg.recordId == "torasa aram" then
			preMuseumInventory= {}
			for a,b in pairs(types.Actor.inventory(self):getAll()) do
				preMuseumInventory[b.id]= {count = b.count, item = b}
			end
		end
		if preMuseumInventory and data.newMode == nil then
			local postMuseumInventory = {}
			for a,b in pairs(types.Actor.inventory(self):getAll()) do
				postMuseumInventory[b.id]= {count = b.count, item = b}
			end
			for itemId, t in pairs(preMuseumInventory) do
				if not postMuseumInventory[itemId] and db_museum[t.item.recordId] then
					saveData.progress.museum = (saveData.progress.museum or 0) + 1
					updateChallengeTracker("museum")
				end
			end
			preMuseumInventory = nil
		end
		-- QUESTLINE
		if saveData.challenges.questline == 0 and data.oldMode == "Dialogue" and data.newMode == nil then
			local finishedQuestlines = 0
			for faction, quests in pairs(db_questlines) do
				local finished = true
				for questId in pairs(quests) do	
					finished = finished and types.Player.quests(self)[questId] and types.Player.quests(self)[questId].finished
				end
				if finished then
					finishedQuestlines = finishedQuestlines + 1
				end
			end
			if saveData.progress.questline ~= finishedQuestlines then
				saveData.progress.questline = finishedQuestlines
				updateChallengeTracker("questline")
			end
		end
	end
	if data.oldMode =="Interface" then
		updateChallengeTracker()
	end
end

-- time skip fix
table.insert(onFrameJobs, function(dt)
	if saveData.challenges and saveData.challenges.survival == 0 then
		local now = core.getGameTime()
		if lastGameTime then
			if now - lastGameTime >time.hour/2 then
				local seconds = (now - lastGameTime)
				print("time skip detected, +".. math.floor(seconds/time.hour*10)/10 .." hours")
				saveData.startTime = saveData.startTime + (now - lastGameTime)
				if not RESTLESS_SURVIVAL_CHEAT then
					types.Actor.stats.dynamic.health(self).current  = lastHealth 
					types.Actor.stats.dynamic.fatigue(self).current = lastFatigue
					types.Actor.stats.dynamic.magicka(self).current = lastMagicka
					core.sendGlobalEvent("Roguelite_fixTimeskip", {self, seconds})
				end
			end
		end	
		lastGameTime = now
		lastHealth =  types.Actor.stats.dynamic.health(self).current
		lastFatigue = types.Actor.stats.dynamic.fatigue(self).current
		lastMagicka = types.Actor.stats.dynamic.magicka(self).current
	end
end)


-- RELEASE COMPANION (SLUMBER)
I.SkillProgression.addSkillUsedHandler(function(skillId, params)
	if saveData and saveData.blessings and saveData.blessings.slumber and skillId == "mysticism" then
		local spell = types.Player.getSelectedSpell(self)
		for _,effect in pairs(spell.effects) do
			if effect.id == "dispel" then
				viewportBugfixDelay = core.getRealTime() + 0.05
				onFrameFunctions["releaseCompanion"] = function()
					if core.getRealTime() > viewportBugfixDelay then
						local cameraPos = camera.getPosition()
						local iMaxActivateDist = core.getGMST("iMaxActivateDist")+0.1
						local activationDistance = iMaxActivateDist + camera.getThirdPersonDistance();
						local telekinesis = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Telekinesis);
						if (telekinesis) then
							activationDistance = activationDistance + (telekinesis.magnitude * 22);
						end
						activationDistance = activationDistance+0.1
						local res = nearby.castRenderingRay(
							cameraPos,
							cameraPos + camera.viewportToWorldVector(v2(0.5,0.5)) * activationDistance,
							{ ignore = self }
						)
						if res.hitObject and types.Actor.objectIsInstance(res.hitObject) then
							res.hitObject:sendEvent("Roguelite_releaseCompanion",self)
						end
						onFrameFunctions["releaseCompanion"] = nil
					end
				end
			end
		end
	end
end)


local function onLoad(data)
	if data then
		saveData = data		
	else
		saveData = {}
	end
	if saveData.finishedChargen == nil then
		saveData.finishedChargen = types.Player.isCharGenFinished(self)
	end
	if saveData.progress == nil then
		saveData.progress = {}
	end
	updateChallengeTracker()
	lastLevel = nil
	if saveData.blessings then
		if saveData.blessings.disposition then
			core.sendGlobalEvent("Roguelite_hasDispositionBlessing", self)
		end
		if saveData.blessings.herbalist and I.HUDMarkers and I.HUDMarkers.version >=6 and playerSection:get("DETECT_INGREDIENTS") then
			I.HUDMarkers.setIngredientBonus("Roguelite", 120)
			I.HUDMarkers.setHerbBonus("Roguelite", 120)
		end
	end
	lastGameTime = nil
	currentCell = nil
	deadYet = nil
	skillSet = {}
	local classRecord = types.NPC.record(self).class and types.NPC.classes.record(types.NPC.record(self).class)
	if classRecord then
		for _, skill in pairs(classRecord.majorSkills) do
			skillSet[skill] = 2
		end
		for _, skill in pairs(classRecord.minorSkills) do
			skillSet[skill] = 1
		end
	end
	--print("CHEATER!",runDB:get(saveData.runId),runDB:set(saveData.runId,0))
end

local function onSave()
    return saveData
end

local function actorDied(actor)
	if saveData.blessings and saveData.blessings.soulstone then
		local chance = 0.2
		local soulSize = 0
		if types.Creature.objectIsInstance(actor) then
			soulSize = types.Creature.record(actor).soulValue
		elseif types.NPC.objectIsInstance(actor) then
			soulSize = math.min(7,math.floor(types.Actor.stats.level(actor).current/10))
			soulSize = types.Creature.record("roguelite_human_soul_"..soulSize).soulValue
		end
		chance = chance + soulSize*0.03/100
		if math.random() <chance  then
			ambient.playSound("conjuration hit")
			actor:sendEvent("Roguelite_soultrapVFX")
			core.sendGlobalEvent("Roguelite_makeSoulgem", {self.object, actor})
		end
	end
	saveData.progress.slayer = (saveData.progress.slayer or 0) + 1
	updateChallengeTracker("slayer")
end


local function dungeonCleared()
	print("clear!")
	saveData.progress.dungeons = (saveData.progress.dungeons or 0) + 1
	updateChallengeTracker("dungeons")
	hudAlpha = 2.5
end

local function curedVampirism()
	saveData.progress.vampirism = 1
	updateChallengeTracker("vampirism")
	hudAlpha = 2.5
end

return {
	engineHandlers = {
        onLoad = onLoad,
        onInit = onLoad,
        onSave = onSave,
		onFrame = onFrame,
		onConsoleCommand = onConsoleCommand,

	},
	eventHandlers = { 
		UiModeChanged = UiModeChanged,
		Roguelite_actorDied = actorDied,
		Roguelite_dungeonCleared = dungeonCleared,
		Roguelite_curedVampirism = curedVampirism,
	}
}