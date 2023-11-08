local activation = require("openmw.interfaces").Activation
local types = require("openmw.types")
local core = require("openmw.core")
local storage = require('openmw.storage')
local world = require('openmw.world')

--you can't sleep in someone elses bed!
local bedMessageGMST = "sNotifyMessage64"

local MOD_NAME = "comprehensive_rebalance"
local settings = storage.globalSection("SettingsGlobal" .. MOD_NAME .. "rest")
local strings = core.l10n(MOD_NAME)

--holds when the player last rested
--TODO: Handle this for every player (in the case of multiplayer)
local lastRested = 0

local function handleRestTimeEvent(data)
	lastRested = data.restTime
end

local function isBed(object)
	local scrName = types.Activator.record(object.recordId).mwscript
	return scrName == "bed_standard"
end

local function isInFaction(id, actor)
	for _, value in ipairs(types.NPC.getFactions(actor)) do
		if value == id then
			return types.NPC.getFactionRank(actor, id)
		end
	end
	return -1
end

local function canSleep(bed, actor)

	local message = core.getGMST(bedMessageGMST)

	--prevent re-using beds so soon!
    if settings:get('noRepeatedSleeping') and lastRested + (settings:get('noRepeatedSleepingTimer') * 60) > world.getSimulationTime() then
        actor:sendEvent("showMessage", strings("not_tired"))
        return false
    end

	--check global variable, for renting
	if bed.globalVariable and world.mwscript.getGlobalVariables then
		if world.mwscript.getGlobalVariables(actor)[bed.globalVariable] ~= 1 then
			return false
		end

	--if bed is owned, we can't use it
	elseif bed.ownerRecordId and settings:get("noTresspassSleep") then
		--actor:sendEvent("showMessage", "owned")
		actor:sendEvent("showMessage", message)
		return false
		
	--we must be in the same faction as the bed owner, and be the right rank
	elseif bed.ownerFactionId then
		local rank = isInFaction(bed.ownerFactionId, actor)
		
		if (rank == -1 or rank < bed.ownerFactionRank) and settings:get("noTresspassSleep") then
			--actor:sendEvent("showMessage", "rank too low")
			actor:sendEvent("showMessage", message)
			return false
		end
	end
	
	actor:sendEvent("handleBed")
	return true

end

local function activateHandler(activator, actor)
	
	if isBed(activator) and not canSleep(activator, actor) then
		return false
	else
		sleepTimer = world.getSimulationTime()
		return true
  end
end

activation.addHandlerForType(types.Activator, activateHandler)

return
{
	eventHandlers =
	{
		UiModeChanged = setLastSleep,
		playerRested = handleRestTimeEvent
	},
}