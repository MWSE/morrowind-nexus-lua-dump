local common = require("KBev.ProgressionMod.common")
local mcm = require("KBev.ProgressionMod.mcm")
local framework = require("KBev.ProgressionMod.interop")
require("KBev.ProgressionMod.levelManager")
require("KBev.ProgressionMod.cgen")

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

local function giveXP(e)
	if (not mcm.xpEnabled) or (e.amount == 0) then return end
	framework.playerData.giveXP(e.amount)
	common.xpMsg({message = e.message, xp = e.amount})
end
event.register("KCP:grantXP", giveXP)

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
	setupVanillaQuests()
	event.trigger("KCP:Initialized")
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

local levelQueued = false

local function levelUpTimer()
	if levelQueued and tes3.canRest{ checkForEnemies = true, checkForSolidGround = false, showMessage = false } then
		levelQueued = false
		tes3.streamMusic{ path = "Special/MW_Triumph.mp3" }
		tes3.runLegacyScript{command = "EnableLevelUpMenu"}
	end
end
timer.register("KCP:levelUpTimer", levelUpTimer)

local function levelUpTimer()
	if tes3.canRest{ checkForEnemies = true, checkForSolidGround = false, showMessage = false } then
		tes3.streamMusic{ path = "Special/MW_Triumph.mp3" }
		tes3.runLegacyScript{command = "EnableLevelUpMenu"}
	else checkForLevelUP()
	end
end
timer.register("KCP:levelUpTimer", levelUpTimer)

local function dbgLevelMenuTest(e)
	tes3.streamMusic{ path = "Special/MW_Triumph.mp3" }
	tes3.runLegacyScript{command = "EnableLevelUpMenu"}
end
event.register("KCP:dbgLevelUp", dbgLevelMenuTest)

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
		giveXP({message = "Чтение книги навыка", amount = mcm.bkSklXP})
	end
	if (e.source == tes3.skillRaiseSource.training) and (mcm.trainerXPEnabled) then
		giveXP({message = "Тренировка навыка", amount = mcm.trnSklXP})
	end
	if (e.source == tes3.skillRaiseSource.progress) and (mcm.exerciseXPEnabled) then
		local iXP = mcm[getSkillProficiency(e.skill) .. "SklXP"]
		giveXP({message = "Увеличение навыка", amount = iXP})
		if (mcm.blockSkillRaise) then
			tes3.modStatistic({
				reference = tes3.player,
				skill = e.skill,
				value = -1,
			})
		end
	end
	
end
event.register("skillRaised", onSkillRaised, {priority = -999})

local function advanceLevel() 
	if mcm.lvlRst then
		tes3.mobilePlayer.levelUpProgress = tes3.findGMST(tes3.gmst.iLevelupTotal).value
		tes3.messageBox("Вам следует отдохнуть и поразмышлять над тем, что вы узнали.")
	else	
		timer.start{
		type = timer.simulate,
		duration = 5,
		callback = "KCP:levelUpTimer",
		persist = true,
		
		}
	end
end

local function checkForLevelUP()
	if (tes3.player.object.level < mcm.xpLvlCap) and (common.playerData.xp >= framework.playerData.calcXPReq(tes3.player.object.level)) then
		advanceLevel()
	end
end
event.register("KCP:checkForLevelUP", checkForLevelUP)



local function onXPGain(e)
	if not mcm.xpEnabled then return end
	if (tes3.player.object.level < mcm.xpLvlCap) and (e.total >= framework.playerData.calcXPReq(tes3.player.object.level) and (tes3.mobilePlayer.levelUpProgress < tes3.findGMST(tes3.gmst.iLevelupTotal).value)) then
		advanceLevel()
	end
end
event.register("KCP:XPGained", onXPGain)

--quest update code
local function onJournal(e)
	local msg
	if (not e.info.isQuestFinished) or ( common.playerData.questsCompleted[e.topic.id]) then return end
	common.dbg("Quest Completed - " .. e.topic.id)
	local questType = framework.quest.getQuestType(e.topic.id)
	common.dbg("Quest type == " .. questType)
	if questType ~= "noXP" then
		if questType == "task" then
			msg = "Задача выполнена"
		else
			msg = "Квест выполнен"
		end
		giveXP({message = msg, amount = mcm[questType .. "QuestXP"]})
	end
	common.playerData.questsCompleted[e.topic.id] = true
end
event.register("journal", onJournal)

--Boss Monster Death Code
local function onDeath(e)
	common.dbg( e.reference.baseObject.id .. "has died")
	
	if mcm.fargothXPEnabled and e.reference.baseObject.id == "fargoth" then
		giveXP({message = "Хрисскар улыбается вам", amount = mcm.fargothXP})
	elseif mcm.bossXPEnabled and common.bossMonsters[e.reference.baseObject.id] then 
		giveXP({message = "Босс повержен", amount = mcm.bossXP})
	end
end
event.register(tes3.event.death, onDeath)

--location discovery code
local function onCellChanged(e)
    -- Не обрабатываем смену ячейки, если идёт генерация персонажа, это интерьер или отключено в настройках.
    if (tes3.worldController.charGenState.value ~= -1) or e.cell.isInterior or not mcm.cellXPEnabled then
        return 
    end
    
    -- Проверяем идентификатор(название) ячейки.
    if e.cell.id then
        local displayName = e.cell.id  -- Изначально используем оригинальное название
        
        if tes3.isLuaModActive("Pirate.CelDataModule") then
            displayName = CellNameTranslations[displayName] or displayName
        end
        
        -- Выдаём опыт, если локация ещё не посещалась.
        if not framework.playerData.getCellVisited(e.cell.id) then
            giveXP({
                message = "Локация исследована: " .. displayName,
                amount = mcm.cellXP
            })
        end
        
        -- В любом случае отмечаем ячейку как посещённую.
        framework.playerData.setCellVisited(e.cell.id)
    end
end

event.register("cellChanged", onCellChanged)