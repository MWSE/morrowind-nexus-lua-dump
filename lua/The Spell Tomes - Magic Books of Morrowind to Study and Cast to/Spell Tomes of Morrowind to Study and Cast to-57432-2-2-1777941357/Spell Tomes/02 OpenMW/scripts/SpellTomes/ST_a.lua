local self = require("openmw.self")
local types = require("openmw.types")
local core = require("openmw.core")
local time = require("openmw_aux.time")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
 
require("scripts.SpellTomes.ST_database")
 
-- bail if FDU isn't loaded
if not I.FollowerDetectionUtil then
	return {}
end
 
local settings = storage.globalSection("SettingsSpellTomes")
local customSpells = {}
local stopTimerFn
local isFollower = I.FollowerDetectionUtil.getState().followsPlayer
 
local function unhook()
	if stopTimerFn then
		stopTimerFn()
		stopTimerFn = nil
	end
	core.sendGlobalEvent("SpellTomes_unhookObject", self)
end
 
local function update()
	-- clear previously taught spells so leaving the tome behind un-teaches it
	for _, spellId in ipairs(customSpells) do
		types.Actor.spells(self):remove(spellId)
	end
	customSpells = {}
	
	if types.Actor.isDead(self)
	or not isFollower
	or not settings:get("TEACH_COMPANIONS")
	then
		unhook()
		return
	end
	
	-- teach the spell of any tome currently in inventory
	for _, item in pairs(types.Actor.inventory(self):getAll(types.Book)) do
		local spellId = spellTomes[item.recordId]
		if spellId then
			types.Actor.spells(self):add(spellId)
			customSpells[#customSpells + 1] = spellId
		end
	end
end
 
local function updateFollowerStatus(data)
	local state = data.followers[self.id]
	isFollower = state ~= nil and state.followsPlayer or false
end
 
local function onLoad()
	stopTimerFn = time.runRepeatedly(update, 0.989 * time.second, {
		type = time.SimulationTime,
		initialDelay = 0.989 * time.second,
	})
end
 
return {
	engineHandlers = {
		onLoad = onLoad,
		onInit = onLoad,
		onInactive = unhook,
	},
	eventHandlers = {
		FDU_UpdateFollowerList = updateFollowerStatus,
	},
}
