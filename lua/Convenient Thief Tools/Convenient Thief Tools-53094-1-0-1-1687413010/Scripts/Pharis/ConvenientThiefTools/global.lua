--[[

Mod: Convenient Thief Tools
Author: Pharis

--]]

local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local types = require("openmw.types")

-- Mod info
local modInfo = require("Scripts.Pharis.ConvenientThiefTools.modinfo")
local modName = modInfo.modName
local modVersion = modInfo.modVersion

-- Settings
local generalSettings = storage.globalSection("SettingsPlayer" .. modName)
local gameplaySettings = storage.globalSection("SettingsPlayer" .. modName .. "Gameplay")

local function isLockpick(object)
	return (object) and (types.Lockpick.objectIsInstance(object))
end

local function isProbe(object)
	return (object) and (types.Probe.objectIsInstance(object))
end

local function lockableActivationHandler(object, actor)
	if (not generalSettings:get("modEnable"))
		or (not types.Player.objectIsInstance(actor)) then return true end

	local carriedRight = types.Actor.equipment(actor)[types.Actor.EQUIPMENT_SLOT.CarriedRight]

	if (gameplaySettings:get("autoEquipProbe")) and (not isProbe(carriedRight)) and (types.Lockable.getTrapSpell(object)) then
		if (#types.Actor.inventory(actor):getAll(types.Probe) == 0) then
			return true
		end
		actor:sendEvent("PharisConvenientThiefToolsActivateLockable", {object = object, probe = true})
		return false
	end

	-- Skip auto equipping lockpick if player has the key
	-- still needs to prioritize checking for trap first
	local keyRecord = types.Lockable.getKeyRecord(object)
	if (keyRecord) and (types.Actor.inventory(actor):find(keyRecord.id)) then
		return true
	end

	if (gameplaySettings:get("autoEquipLockpick")) and (not isLockpick(carriedRight)) and (types.Lockable.isLocked(object)) then
		actor:sendEvent("PharisConvenientThiefToolsActivateLockable", {object = object, probe = false})
		return false
	end

	return true
end

I.Activation.addHandlerForType(types.Container, lockableActivationHandler)
I.Activation.addHandlerForType(types.Door, lockableActivationHandler)
