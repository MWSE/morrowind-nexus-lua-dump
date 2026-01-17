local core = require('openmw.core')
local self = require('openmw.self')
local time = require('openmw_aux.time')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local util = require('openmw.util')

I.Settings.registerPage {
    key = 'DynamicTimescale',
    l10n = 'DynamicTimescale',
    name = 'Dynamic Timescale',
    description = 'Change timescale dynamically between indoors and outdoors'
}

local globalSettings = storage.globalSection('SettingsDynamicTimescale')

local oldCell = nil
local oldStance = types.Actor.stance(self)
local wasSneaking = self.controls.sneak

--local oldPosition
local isMoving, wasMoving, oldPosition = false, false, util.vector3(0, 0, 0)

local function hasCellChanged(cell)
	if cell == oldCell then return
	else
		oldCell = cell
		core.sendGlobalEvent('daisysettimescaleCELL', {player = self.object})
	end
end

local function doTimescaleCheck()
	local currentStance = self.type.stance(self)
	isMoving = self.position ~= oldPosition

	if globalSettings:get('enableFightSneakTime') == true then
		if currentStance ~= self.type.STANCE.Nothing then
			if oldStance ~= self.type.STANCE.Nothing then
				return
			else
				oldStance = self.type.stance(self)
				core.sendGlobalEvent('daisysettimescaleCOMBAT')
			end
		elseif self.controls.sneak == true then
			if wasSneaking == true then
				return
			else
				wasSneaking = self.controls.sneak
				core.sendGlobalEvent('daisysettimescaleSNEAKING')
			end
		elseif types.Actor.stance(self) == 0 and oldStance > 0 then
			oldStance = types.Actor.stance(self)
			if self.controls.sneak == true then
				wasSneaking = self.controls.sneak
				core.sendGlobalEvent('daisysettimescaleSNEAKING')
			else
				core.sendGlobalEvent('daisysettimescaleCELL', {player = self.object})
			end
		elseif self.controls.sneak == false and wasSneaking == true then
			wasSneaking = self.controls.sneak
			core.sendGlobalEvent('daisysettimescaleCELL', {player = self.object})
		elseif isMoving and not wasMoving then
			core.sendGlobalEvent('daisysettimescaleCELL', {player = self.object})
		elseif not isMoving and wasMoving then
			core.sendGlobalEvent('hazelnotsettimescaleSTATIC')
		else
			hasCellChanged(self.cell)
		end
	else
		hasCellChanged(self.cell)
	end
	wasMoving = isMoving
	oldPosition = self.position
end

return {
	engineHandlers = {
		onUpdate = doTimescaleCheck
	}
}
