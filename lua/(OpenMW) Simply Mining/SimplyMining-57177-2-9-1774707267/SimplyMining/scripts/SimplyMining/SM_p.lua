I = require('openmw.interfaces')
types = require('openmw.types')
self = require('openmw.self')
Player = require('openmw.types').Player
async = require('openmw.async')
ui = require('openmw.ui')
util = require('openmw.util')
core = require'openmw.core'
v2 = util.vector2
v3 = util.vector3
I = require('openmw.interfaces')
core = require('openmw.core')
ambient = require('openmw.ambient')
animation = require('openmw.animation')
input = require('openmw.input')
camera = require('openmw.camera')
nearby = require('openmw.nearby')
time = require('openmw_aux.time')
MODNAME = "SimplyMining"
MINING_SKILL_ID = 'mining_skill'
THEFT_COLOR = util.color.rgb(1, 0, 0)
G_onFrameFunctions = {}
G_blockedBySunsDusk = false
G_skillRegistered = false
storage = require('openmw.storage')


require("scripts.SimplyMining.SM_locale")

require("scripts.SimplyMining.SM_settings")

require("scripts.SimplyMining.SM_helpers")

require("scripts.SimplyMining.SM_fakeTooltips")


function registerMiningSkill()
	if G_skillRegistered or not I.SkillFramework then
		return
	end
	I.SkillFramework.registerSkill(MINING_SKILL_ID, {
		name = L("Skill.name", "Mining"),
		description = L("Skill.desc","Mining ore and stuff"),
		icon = { fgr = "textures/SimplyMining/pick.dds" },
		attribute = "endurance",
		specialization = I.SkillFramework.SPECIALIZATION.Combat,
		skillGain = {
			[1] = 1,
		},
		startLevel = 5,
		maxLevel = 150,
		statsWindowProps = {
			subsection = I.SkillFramework.STATS_WINDOW_SUBSECTIONS.Crafts
		}
	})
	I.SkillFramework.registerRaceModifier(MINING_SKILL_ID, 'argonian', 3)
	I.SkillFramework.registerRaceModifier(MINING_SKILL_ID, 'khajiit', 3)
	I.SkillFramework.registerRaceModifier(MINING_SKILL_ID, 'nord', -1)
	I.SkillFramework.registerRaceModifier(MINING_SKILL_ID, 'orc', -1)
	G_skillRegistered = true
end

if S_USE_MINING_SKILL then
	async:newUnsavableSimulationTimer(0.1, registerMiningSkill)
end


iconText = require("scripts.SimplyMining.iconText")

if S_SWING_MINING then
	mineOre = require"scripts.SimplyMining.SM_mineOre_swing"
else
	mineOre = require"scripts.SimplyMining.SM_mineOre"
end
require("scripts.SimplyMining.database")

nodeToItemLookup ={}
for item, nodes in pairs(db_nodes_all) do
	for _, node in pairs(nodes) do
		nodeToItemLookup[node] = item
	end
end

require("scripts.SimplyMining.SM_oreSpawner")

local function onFrame(dt)
	for _, f in pairs(G_onFrameFunctions) do
		f(dt)
	end
end

--I.AnimationController.addTextKeyHandler('', function(groupname, key) --self start/stop, touch start/stop, target start/stop
--	print(groupname,key) --use this to see animations that are playing
--end)


local function onLoad(data)
	saveData = data or {version = 1}
	
	if not saveData.cellOreCount then
		saveData.cellOreCount = {}
	end
	if not saveData.cellFailCount then
		saveData.cellFailCount = {}
	end
	if not saveData.cellCapacity then
		saveData.cellCapacity = {}
	end
	if not saveData.retryCells then
		saveData.retryCells = {}
	end
	if not saveData.nerfedCells then
		saveData.nerfedCells = {}
	end
	if not saveData.spawnedOres then
		saveData.spawnedOres = {}
		core.sendGlobalEvent("SimplyMining_requestSpawnedOres", self)
	end
	if not saveData.version then
		saveData.realCellOreCount = saveData.realCellOreCount or {}
		for a,b in pairs(saveData.cellOreCount) do
			saveData.cellCapacity[a] = 0
			if not saveData.realCellOreCount[a] then
				saveData.realCellOreCount[a] = 1
			end
			if not saveData.cellFailCount[a] then
				saveData.cellFailCount[a] = 100
			end
		end
		saveData.cellOreCount = {}
		for a,b in pairs(saveData.realCellOreCount) do
			saveData.cellOreCount[a] = b
		end
		saveData.version = 1
	end
end

local function onSave()
	return saveData
end

local function notifyItem (data)
	local item = data[1]
	local count = data[2]
	local position = data[3]
	iconText.spawnIconText3D(position, item.type.record(item).icon, count)
	ambient.playSound("item bodypart up")
end


local function notifyFail (position)
	iconText.spawnIconText3D(position, nil, "fail", nil, 24)
	ambient.playSound("enchant fail")
end

local function UiModeChanged(data)
	if data.oldMode == "Dialogue" and data.newMode == nil then
		core.sendGlobalEvent("SimplyMining_convertOres", self)
	end
end


local function onConsoleCommand(command, str)
    if str:match("^lua mining") then
        local level = str:match("^lua mining%s+(%d+)")
		if G_skillRegistered then
			local skillStat = I.SkillFramework.getSkillStat(MINING_SKILL_ID)
			if level then
				skillStat.base = tonumber(level)
				ui.printToConsole("mining skill set to " .. level, ui.CONSOLE_COLOR.Success)
				
			else
				ui.printToConsole("mining skill: " .. tostring(skillStat.base or 0), ui.CONSOLE_COLOR.Info)
			end
		else
			ui.printToConsole("mining skill not registered")
		end
        return
    end
end

local function SimplyMining_receiveSpawnedOres(t)
	for a in pairs(t) do
		saveData.spawnedOres[a] = true
	end
end
local function SimplyMining_receiveSpawnedOre(id)
	saveData.spawnedOres[id] = true
end

local function startMining(data)
	mineOre(data)
end

local function SunsDusk_receiveCellInfo(cellInfo)
	G_blockedBySunsDusk = false
	if cellInfo.isExterior then return end
	if not cellInfo.isIceCave and not cellInfo.isCave and not cellInfo.isMine then 
		G_blockedBySunsDusk = true
	end
end

return {
	engineHandlers = {
		onLoad = onLoad,
		onInit = onLoad,
		onSave = onSave,
		onFrame = onFrame,
		onUpdate = onUpdate,
		onConsoleCommand = onConsoleCommand,
	},
	eventHandlers = { 
		SimplyMining_startMining = startMining,
		SimplyMining_sparkFx = sparkFx,
		SimplyMining_notifyItem = notifyItem,
		SimplyMining_notifyFail = notifyFail,
		SimplyMining_receiveSpawnedOres = SimplyMining_receiveSpawnedOres,
		SimplyMining_receiveSpawnedOre = SimplyMining_receiveSpawnedOre,
		SunsDusk_receiveCellInfo = SunsDusk_receiveCellInfo,
		UiModeChanged = UiModeChanged,
	}
}
