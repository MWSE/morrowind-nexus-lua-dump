--[[
ErnSpellBooks for OpenMW.
Copyright (C) 2025 Erin Pentecost

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]] --local world = require('openmw.world')
local core = require("openmw.core")
--local settings = require("scripts.ErnSpellBooks.settings")
local interfaces = require('openmw.interfaces')
local types = require("openmw.types")
--local spellUtil = require("scripts.ErnSpellBooks.spellUtil")
local async = require('openmw.async')
--local localization = core.l10n(settings.MOD_NAME)

if require("openmw.core").API_REVISION < 62 then
	print("OpenMW 0.49 or newer is required!")
	print("OpenMW 0.49 or newer is required!")
	print("OpenMW 0.49 or newer is required!")
	return
end

local clearVFXCallback = async:registerTimerCallback('resurgenceClearVFXCallback', function(data)
	animation.removeVfx(self, data.vfxID)
end)


local recentResurgences = {}

local repeatCallback = async:registerTimerCallback('ernRepeatCallback', function(data)
	if types.Actor.isDead(self) or not data["effectID"] then
		return
	end
	local effect = core.magic.effects.records[data["effectID"]]
	if effect then
		if effect.castSound then
			core.sound.playSound3d(effect.castSound, self, {
				loop = false,
				volume = 0.9,
				pitch = 1.0
			})
		end
		if effect.hitSound then
			core.sound.playSound3d(effect.hitSound, self, {
				loop = false,
				volume = 1.0,
				pitch = 1.0
			})
		end
		if effect.hitStatic then
			local staticRecord = types.Static.record(effect.hitStatic)
			if staticRecord then
				local vfxID = "resurgence" .. tostring(data["spellID"]) .. math.random()
				animation.addVfx(self, staticRecord.model, {
					vfxId = vfxID,
					particuleTextureOverride = effect.particle,
					loop = effect.continuousVfx
				})
				async:newSimulationTimer(data["duration"] or 0, clearVFXCallback, {
					actor = self,
					vfxID = vfxID
				})
			end
		end
	end
	playerActiveSpells:add({
		id = data['spellID'],
		effects = {data["index"]}
	})
	recentResurgences[data['spellID']] = core.getRealTime()
end)


------------------------------------------------------------------
local function userDataLength (userData)
	local i = 0
	for _ in pairs(userData) do
		i=i+1
	end
	return i
end
local spellCount = 0
local lastCheck = 999999999

-- time skip fix
table.insert(onFrameJobs, function(dt)
	if saveData.blessings and saveData.blessings.resurgence then
		local now = core.getRealTime()
		local newSpellCount = userDataLength(playerActiveSpells)
		local timePassed = math.max(0,now-lastCheck)
		if newSpellCount ~=spellCount then
			for a,activeSpell in pairs(playerActiveSpells) do
				--local spell = core.magic.spells.records[activeSpell.id] --nil for enchantments
				if (recentResurgences[activeSpell.id] or 0) < now-0.15 then
					local friendlyFire = false
					for i,activeSpellEffect in pairs(activeSpell.effects) do
						local effect = core.magic.effects.records[activeSpellEffect.id]
						--print (activeSpell.id)
						--print(effect.id)
						--print("????",effect.boltSound)
						--print("????",effect.castSound )
						--print("????",effect.hitSound)
						if not effect.harmful and activeSpellEffect.duration and (activeSpellEffect.duration - activeSpellEffect.durationLeft)<=timePassed then
							if effect.id ~= "restorefatigue" and effect.id ~= "restorehealth" and effect.id ~= "restoremagicka" then
								local duration = activeSpellEffect.duration-0.15
								async:newSimulationTimer(duration, repeatCallback, {
									['spellID'] = activeSpell.id,
									['index'] = activeSpellEffect.index,
									['effectID'] = activeSpellEffect.id,
									['duration'] = activeSpellEffect.duration,
								})
								recentResurgences[activeSpell.id] = now
							end
						end
					end
				end
			end
		end
		spellCount = newSpellCount
		lastCheck = now
	end
end)