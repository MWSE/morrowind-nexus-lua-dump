local I = require('openmw.interfaces')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local anim = require('openmw.animation')
local types = require("openmw.types")
local AI = require('openmw.interfaces').AI
local core = require('openmw.core')
local vfs = require('openmw.vfs')
local time = require('openmw_aux.time')

local customSpells = {}

local function removeSpells()
	for _, spell in pairs(customSpells) do
		--print("removed", spell)
		types.Actor.spells(self):remove(spell)
	end
	customSpells = {}
end

local function addSpells()
	if not spellTomes then
		require("scripts.SpellTomes.ST_database")
	end
	
	local availableSpelltomes = types.Actor.inventory(self):getAll(types.Book)
	for _, item in pairs(availableSpelltomes) do
		if spellTomes[item.recordId] then
			types.Actor.spells(self):add(spellTomes[item.recordId])
			table.insert(customSpells, spellTomes[item.recordId])
		end
	end
	--for a,b in pairs(types.Actor.spells(self)) do
	--	print(b.id)
	--end
end

local function onInactive()
	core.sendGlobalEvent("SpellTomes_unhookObject", self)
end

local function update()
	removeSpells()
	addSpells()
	if types.Actor.isDead(self) then
		stopTimerFn()
		onInactive()
	end
	local isCompanion = false
	AI.forEachPackage(function(p)
		if p and p.type == "Follow" and p.target and types.Player.objectIsInstance(p.target) then
			isCompanion = true
		end
	end)
	if not isCompanion then
		stopTimerFn()
		onInactive()
	end
end

local function onLoad(data)
	stopTimerFn = time.runRepeatedly(update, 0.989 * time.second, {
		type = time.SimulationTime,
		initialDelay = 0.989 * time.second
	})
end

return {
	engineHandlers = {
		onUpdate = onUpdate,	
		onLoad = onLoad,
		onInit = onLoad,
		--onSave = onSave,
		onInactive = onInactive,
	},
	eventHandlers = {
	}
}