local types = require("openmw.types")
local acti = require("openmw.interfaces").Activation
local core = require("openmw.core")
local world = require("openmw.world")
local storage = require("openmw.storage")
local shiftPressed = false
local noSleepGMST = "sNotifyMessage64"
local deadActors = {}

local function onPlayerAdded(player)
  if (not world.mwscript.getGlobalVariables) then
    player:sendEvent("NSS_OutOfDate")
      error("Newer version of OpenMW is required")
    end
end
local function isInFaction(factionId, actor)
  for index, value in ipairs(types.NPC.getFactions(actor)) do
    if value == factionId then
      return types.NPC.getFactionRank(actor, factionId)
    end
  end
  return -1
end
local function canUseBed(bed, actor)
  if bed.globalVariable and world.mwscript.getGlobalVariables then
    local var = world.mwscript.getGlobalVariables(actor)[bed.globalVariable]
    if var == 1 then
      return true
    end
  end
  if bed.ownerFactionId then
    local bedRank = isInFaction(bed.ownerFactionId, actor)
    if bedRank == -1 or bedRank < bed.ownerFactionRank then
      return false
    else
      return true
    end
  elseif bed.ownerRecordId then
    local ownerNPCRecord = types.NPC.record(bed.ownerRecordId)
    local ownerRef
    for index, actor in ipairs(world.activeActors) do
      if actor.recordId == ownerNPCRecord.id then
        ownerRef = actor
      end
    end
    if ownerRef and types.Actor.stats.dynamic.health(ownerRef).current > 0 then
      return false
    elseif deadActors[ownerNPCRecord.id] or ownerRef and types.Actor.stats.dynamic.health(ownerRef).current <= 0 then
      deadActors[ownerNPCRecord.id] = true
      return true
    end
    return false
  end
end
local function activateBed(object, actor)
  local scrName = types.Activator.record(object.recordId).mwscript
  if scrName == "bed_standard" and canUseBed(object, actor) == false then
    local message = core.getGMST(noSleepGMST)
    actor:sendEvent("NSS_showMessage", message)

    return false
  end
end
acti.addHandlerForType(types.Activator, activateBed)
local function onSave()
  return { deadActors = deadActors }
end
local function onLoad(data)
  if data then
    deadActors = data.deadActors
  end
end
return { engineHandlers = { onLoad = onLoad, onSave = onSave, onPlayerAdded = onPlayerAdded } }
