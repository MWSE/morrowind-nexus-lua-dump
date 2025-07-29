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
onFrameFunctions = {}
MODNAME = "SimplyMining"
local storage = require('openmw.storage')
playerSection = storage.playerSection('Settings'..MODNAME)
local settings = require("scripts.SimplyMining.SM_settings")
iconText = require("scripts.SimplyMining.iconText")

mineOre = require"scripts.SimplyMining.SM_mineOre"
require("scripts.SimplyMining.database")

nodeToItemLookup ={}
for item, nodes in pairs(db_nodes_all) do
	for _, node in pairs(nodes) do
		nodeToItemLookup[node] = item
	end
end

function calcChance(item)
	if not db_difficulties[item] then
		return 1
	end
	local armorerSkill = types.NPC.stats.skills.armorer(self).modified
	local difficulty = db_difficulties[item]
	local addExp = math.min(1,armorerSkill/difficulty)^2.5
	local addLinear = armorerSkill/difficulty/3.33
	local res = 0.03+ addLinear + addExp
	if res > 1 then
		res = res ^ 0.55
	end
	--print("chance:", 0.1 + addLinear + addExp)
	return res
end
	
	
	


function randomNode(shiftDifficulty)
    -- Gesamtgewicht berechnen
    local totalWeight = 0
    for _, entry in ipairs(db_weights) do
        totalWeight = totalWeight + entry.weight
    end
    
    local random = math.random(1, totalWeight)
    local currentWeight = 0
    
    -- Durch Items in definierter Reihenfolge iterieren
    for _, entry in ipairs(db_weights) do
        currentWeight = currentWeight + entry.weight
        if random <= currentWeight then
            local nodes = db_nodes[entry.item]
            if nodes and #nodes > 0 then
				local rnd = math.random(1, #nodes)
                return nodes[rnd]
            else
                -- Fallback wenn keine Nodes für das Item existieren
				print("ERROR: ",nodes,entry.item)
                return "sm_coal_vein"
            end
        end
    end
    
    -- Sollte nie erreicht werden
	print("ERROR: fallback sm_coal_vein")
    return "sm_coal_vein"
end

require("scripts.SimplyMining.SM_oreSpawner")

 

local function onFrame(dt)
	for _, f in pairs(onFrameFunctions) do
		f(dt)
	end
end


--I.AnimationController.addTextKeyHandler('', function(groupname, key) --self start/stop, touch start/stop, target start/stop
--	print(groupname,key) --use this to see animations that are playing
--end)



local function onLoad(data)
	if data then
		saveData = data
	else
		saveData = {}
	end
	if not saveData.cellOreCount then
		saveData.cellOreCount = {}
	end
	if not saveData.cellFailCount then
		saveData.cellFailCount = {}
	end
	if not saveData.realCellOreCount then
		saveData.realCellOreCount = {}
	end
end

local function onSave()
	return saveData
end

local function notifyItem (data)
	local item = data[1]
	local count = data[2]
	local position = data[3]
	--ui.showMessage("+"..count.." "..item.type.record(item).name)
	iconText.spawnIconText3D(position, item.type.record(item).icon, count)
	ambient.playSound("item bodypart up")
end


local function notifyFail (position)
	--ui.showMessage("mining failed")
	iconText.spawnIconText3D(position, nil, "fail", nil, 24)
	ambient.playSound("enchant fail")
end

return {
	engineHandlers = {
		onLoad = onLoad,
		onInit = onLoad,
		onSave = onSave,
		onFrame = onFrame,
	},
	eventHandlers = { 
		SimplyMining_startMining = mineOre,
		SimplyMining_sparkFx = sparkFx,
		SimplyMining_notifyItem = notifyItem,
		SimplyMining_notifyFail = notifyFail,
	}
}