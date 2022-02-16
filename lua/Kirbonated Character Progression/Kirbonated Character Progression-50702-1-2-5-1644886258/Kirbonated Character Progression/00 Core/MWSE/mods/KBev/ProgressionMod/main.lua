local common = require("KBev.ProgressionMod.common")
local mcm = require("KBev.ProgressionMod.mcm")
local framework = require("KBev.ProgressionMod.interop")
require("KBev.ProgressionMod.levelManager")

--[[
TODO for 1.3
-Point Buy for Races
-Race ability Overhaul
-Birthsign Overhaul
]]

local vanillaQuestLedger = {
	main = { --main quests of Morrowind and the expansions.
	--Morrowind Act 1
		"A1_1_FindSpymaster",
		"A1_2_AntabolisInformant",
		"A1_4_MuzgobInformant",
		"A1_V_VivecInformants",
		"A1_11_ZainsubaniInformant",
		"A2_1_MeetSulMatuul",
		"A2_2_6thHouse",
		"A2_3_CorprusCure",
		"A2_4_MiloGone",
		"A2_6_Incarnate",
	--Morrowind Act 2, 
		"B5_RedoranHort",
		"B6_HlaaluHort",
		"B7_TelvanniHort",
		"B1_UnifyUrshilaku",
		"B2_AhemmusaSafe",
		"B3_ZainabBride",
		"B4_KillWarLovers",
		"B8_MeetVivec",
	--Morrowind Act 3,
		"C3_DestroyDagoth",
		"CX_BackPath",
	--Tribunal Main Quests
		"TR_DBHunt",
		"TR05_People",
		"TR06_Temple",
		"TR07_Guard",
		"TR08_Hlaalu",
		"TR09_Journalist",
		"TR_KillGoblins",
		"TR_ShrineDead",
		"TR_MazedBand",
		"TR_MHAttack",
		"TR_Bamz",
		"R_Assassins",
		"TR_Champion",
		"TR_ShowPower",
		"TR_MissingHand_02",
		"TR_Blade",
		"TR_SothaSil",
	--Bloodmoon Main Quests
		"BM_Morale",
		"BM_Smugglers",
		"BM_CariusGone",
		"BM_Stones",
		"BM_Trial",
		"BM_Draugr",
		"BM_SkaalAttack",
		"BM_Ceremony1",
		"BM_BearHunt1",
		"BM_FrostGiant1",
		"BM_Ceremony2",
		"BM_BearHunt2",
		"BM_FrostGiant2",
		"BM_WildHunt",
		},
	task = { --these are usually quests that are small tasks within larger scale quests
	--"Sleepers Awake"
		"A1_SleepersAwake",
	--"Vivec Informants"
		"A1_10_MehraMilo", "A1_6_AddhiranirrInformant", "A1_7HuleeyaInformant",
	--Mages Guild Misc Tasks
		"MG_Bowl",
	--Ald'ruhn Misc Tasks
		"Town_Ald_Bevene", "Town_Ald_Bivale", "Town_Ald_Daynes", "Town_Ald_Llethri", "Town_Ald_Tiras",
	}
}

local function setupVanillaQuests()
	for _, quest in ipairs(vanillaQuestLedger.main) do
		framework.quest.registerMainQuest(quest)
	end
	for _, quest in ipairs(vanillaQuestLedger.task) do
		framework.quest.registerTaskQuest(quest)
	end
end

local function onInit()
	common.info("Mod Initialized")
	if (not mcm) then common.info("mcm failed to load") end
	event.trigger("KBProgression:Initialized")
end
event.register("initialized", onInit)

--[[XP FUNCTIONS]]

--[[
	vanillaXPBlocker(e):
	Blocks all vanilla Skill XP gain when xp features are enabled. Should always run last in case other mods are loaded that modify skill XP
	
	This function used to claim the event, but this was changed for compatibility reasons
]]
local function vanillaXPBlocker(e)
	if (mcm.xpEnabled) and not (mcm.allowExercise) then
		e.progress = 0
	end
end
event.register("exerciseSkill", vanillaXPBlocker, {priority = -999})

local function getSkillProficiency(index)
	local skillType = tes3.mobilePlayer.skills[index + 1].type
	if skillType == tes3.skillType.major then return "mjr"
	elseif skillType == tes3.skillType.minor then return "mnr"
	else return "msc" end
end

local function onSkillRaised(e)
	if not mcm.xpEnabled then return end
	if tes3.mobilePlayer.levelUpProgress < tes3.findGMST(tes3.gmst.iLevelupTotal).value then
		tes3.mobilePlayer.levelUpProgress = 0
	end
	if (e.source == tes3.skillRaiseSource.book) and (mcm.skillBookXPEnabled) then
		framework.playerData.giveXP(mcm.bkSklXP)
		common.xpMsg({message = "Skill Book Read", xp = mcm.bkSklXP})
	end
	if (e.source == tes3.skillRaiseSource.training) and (mcm.trainerXPEnabled) then
		framework.playerData.giveXP(mcm.trnSklXP)
		common.xpMsg({message = "Skill Trained", xp = mcm.trnSklXP})
	end
	if (e.source == tes3.skillRaiseSource.progress) and (mcm.exerciseXPEnabled) then
		local iXP = mcm[getSkillProficiency(e.skill) .. "SklXP"]
		framework.playerData.giveXP(iXP)
		common.xpMsg({message = "Skill Exercised", xp = iXP})
	end
end
event.register("skillRaised", onSkillRaised, {priority = -999})

local function onXPGain(e)
	if not mcm.xpEnabled then return end
	if (tes3.player.object.level < mcm.xpLvlCap) and (e.total >= framework.playerData.calcXPReq(tes3.player.object.level) and (tes3.mobilePlayer.levelUpProgress < tes3.findGMST(tes3.gmst.iLevelupTotal).value)) then
		framework.playerData.advanceLevel()
	end
end
event.register("KBProgression:XPGained", onXPGain)

local function debugGiveXP(e)
	if not mcm.xpEnabled then return end
	framework.playerData.giveXP(e.amount)
	common.xpMsg({message = e.message or "DEBUG", xp = e.amount})
end
event.register("KBProgression:grantXP", debugGiveXP)

--quest update code
local function onJournal(e)
	if (not e.info.isQuestFinished) or (tes3.player.data.KBProgression.questsCompleted[e.topic.id]) then return end
	common.info("Quest Completed - " .. e.topic.id)
	local questType = framework.quest.getQuestType(e.topic.id)
	common.info("Quest type == " .. questType)
	if questType ~= "noXP" then
		framework.playerData.giveXP(mcm[questType .. "QuestXP"])
		if questType == "task" then
			common.xpMsg({message = "Task Completed", xp = mcm[questType .. "QuestXP"]})
		else
			common.xpMsg({message = "Quest Completed", xp = mcm[questType .. "QuestXP"]})
		end
	end
	tes3.player.data.KBProgression.questsCompleted[e.topic.id] = true
end
event.register("journal", onJournal)

--Boss Monster Death Code
local function onDeath(e)
	if (not mcm.bossXPEnabled) then return end
	if common.bossMonsters[e.reference.object.id] then
		framework.playerData.giveXP(mcm.bossXP)
		common.xpMsg({message = "Boss Defeated", xp = mcm[mcm.bossXP]})
	end
end
event.register("death", onDeath)

--location discovery code
local function onCellChanged(e)
	if (tes3.worldController.charGenState.value ~= -1) or e.cell.isInterior or not mcm.cellXPEnabled then
		return 
	end
	if e.cell.id and not framework.playerData.getCellVisited(e.cell.id) then
		common.xpMsg({message = "Location Discovered: " .. e.cell.id, xp = mcm.cellXP})
		framework.playerData.setCellVisited(e.cell.id)
		framework.playerData.giveXP(mcm.cellXP)
	elseif e.cell.id then
	end
end
event.register("cellChanged", onCellChanged)