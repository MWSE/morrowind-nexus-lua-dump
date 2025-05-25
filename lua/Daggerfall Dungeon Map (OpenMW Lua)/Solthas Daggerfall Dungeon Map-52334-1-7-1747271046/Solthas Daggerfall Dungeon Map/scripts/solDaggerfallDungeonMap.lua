local camera = require('openmw.camera')
local core = require('openmw.core')
local input = require('openmw.input')
local ui = require('openmw.ui')
local self = require('openmw.self')
local util = require('openmw.util')
local debug = require('openmw.debug')
local ambient = require('openmw.ambient') -- requires 0.49?

-- shader
local postprocessing = require('openmw.postprocessing')
local shader = postprocessing.load('josPainting')

-- settings functions
local function boolSetting(sKey, sDef)
	return {
		key = sKey,
		renderer = 'checkbox',
		name = sKey .. '_name',
		description = sKey .. '_desc',
		default = sDef,
	}
end
local function numbSetting(sKey, sDef, sInt, sMin, sMax)
	return {
		key = sKey,
		renderer = 'number',
		name = sKey .. '_name',
		description = sKey .. '_desc',
		default = sDef,
		argument = {
			integer = sInt,
			min = sMin,
			max = sMax,
		},
	}
end
-- handle settings
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local async = require('openmw.async')
I.Settings.registerPage({
	key = 'SolDaggerfallDungeonMap',
	l10n = 'SolDaggerfallDungeonMap',
	name = 'name',
	description = 'description',
})
-- default values!
local enabled = true
local doShader = true
local wobbleIntensity = 0.5
local moveMult = 2
local doHealthDrain = true
local healthCost = 5
local magickaCost = 10
local fatigueCost = 25
I.Settings.registerGroup({
	key = 'Settings_SolDaggerfallDungeonMap',
	page = 'SolDaggerfallDungeonMap',
	l10n = 'SolDaggerfallDungeonMap',
	name = 'group_name',
	permanentStorage = true,
	settings = {
		boolSetting('enabled', enabled),
		boolSetting('doShader', doShader),
		numbSetting('wobbleIntensity', wobbleIntensity, false, 0.0, 1.0),
		numbSetting('moveMult', moveMult, false, 0.5, 4.0),
		boolSetting('doHealthDrain', doHealthDrain),
		numbSetting('healthCost', healthCost, true, 0, 100),
		numbSetting('magickaCost', magickaCost, true, 0, 100),
		numbSetting('fatigueCost', fatigueCost, true, 0, 1000),
	},
})
local settingsGroup = storage.playerSection('Settings_SolDaggerfallDungeonMap')
-- update
local wobbleMax = 10 * wobbleIntensity
local function updateSettings()
	enabled = settingsGroup:get('enabled')
	doShader = settingsGroup:get('doShader')
	if not (doShader and enabled) then
		shader:disable() -- force disable just in case
	end
	wobbleIntensity = settingsGroup:get('wobbleIntensity')
	wobbleMax = 10 * wobbleIntensity
	moveMult = settingsGroup:get('moveMult')
	doHealthDrain = settingsGroup:get('doHealthDrain')
	healthCost = settingsGroup:get('healthCost')
	magickaCost = settingsGroup:get('magickaCost')
	fatigueCost = settingsGroup:get('fatigueCost')
end
local function init()
	updateSettings()
end
settingsGroup:subscribe(async:callback(updateSettings))

-- init
local buttonWasPressed = false
local savedMode = nil
local doOnce = true
-- health drain logic
local hurtTime = 0
local types = require('openmw.types')
local dynamic = types.Actor.stats.dynamic
local costMult = 1
local endEarly = false
local attributes = types.Actor.stats.attributes
local skills = types.NPC.stats.skills
return {
	engineHandlers = {
		-- init settings
		onActive = init,

		onUpdate = function(dt)
			if enabled then
				local buttonPressed = input.isActionPressed(input.ACTION.ToggleSpell) and
					input.isActionPressed(input.ACTION.Activate)
				if (endEarly) or (buttonPressed and not buttonWasPressed) then
					endEarly = false
					if savedMode then
						camera.setMode(savedMode)
						savedMode = nil
						--ui.showMessage('Free camera is off')
						if ambient then
							ambient.playSound("spellmake fail", { volume = 0.25, pitch = 0.3 })
						end
						input.setControlSwitch(input.CONTROL_SWITCH.Controls, true)
						if doShader then
							shader:disable()
						end
						doOnce = true
					else
						savedMode = camera.getMode()
						if savedMode == camera.MODE.Static then
							savedMode = nil
						else
							camera.setMode(camera.MODE.Static)
							--ui.showMessage('Free camera is on')
							ui.showMessage('You contact Azura to witness Prophecy.')
							if ambient then
								ambient.playSound("spellmake success", { volume = 0.35, pitch = 0.5 })
							end
							input.setControlSwitch(input.CONTROL_SWITCH.Controls, false)
							if doShader then
								shader:enable()
							end
						end
					end
				end
				buttonWasPressed = buttonPressed

				if camera.getMode() == camera.MODE.Static and savedMode then
					if doOnce then
						hurtTime = 0
						doOnce = false
						-- modify shader effect based on junk
						if doShader then
							if wobbleIntensity == 0 then
								shader:setFloat("depthEffect", 0.0)
								shader:setFloat("wobbleSpeed", 0.0)
								shader:setFloat("displacement", 0.0)
							else
								local heaPct = math.sqrt(1 - (dynamic.health(self).current / dynamic.health(self).base))
								local fatPct = math.sqrt(1 - (dynamic.fatigue(self).current / dynamic.fatigue(self).base))
								local magPct = math.sqrt(1 - (dynamic.magicka(self).current / dynamic.magicka(self).base))
								shader:setFloat("depthEffect", 5 * fatPct)
								shader:setFloat("wobbleSpeed", 5 * magPct)
								shader:setFloat("displacement",
									wobbleMax * (0.35 * math.max(fatPct, magPct) + 0.65 * heaPct))
							end
						end
						-- 		move the camera up outside your head on first frame or whatever?
						--		offset = util.transform.rotateZ(camera.getYaw()) * util.vector3(0, -100, 25)
						--		camera.setStaticPosition(camera.getPosition() + offset)
					end

					-- health drain logic
					if doHealthDrain then
						hurtTime = hurtTime + dt
						if hurtTime > 10 then -- if enough time has passed
							hurtTime = 0
							if not debug.isGodMode() then
								if ambient then
									ambient.playSound("Health Damage",{volume=0.5,pitch=0.5})
								end
								costMult = 150 / (50 + skills.mysticism(self).modified) -- 3x at 0, 0.3x at 100
								dynamic.health(self).current = math.max(0,
									dynamic.health(self).current -
									math.ceil(costMult * healthCost * 0.01 * dynamic.health(self).base)) -- don't set to below 0
								costMult = 150 / (50 + attributes.willpower(self).modified)
								dynamic.magicka(self).current = math.max(0,
									dynamic.magicka(self).current -
									math.ceil(costMult * magickaCost * 0.01 * dynamic.magicka(self).base)) -- don't set to below 0
								costMult = 150 / (50 + attributes.endurance(self).modified)
								dynamic.fatigue(self).current = math.max(0,
									dynamic.fatigue(self).current -
									math.ceil(costMult * fatigueCost * 0.01 * dynamic.fatigue(self).base)) -- don't set to below 0
							end
							-- modify shader effect based on junk
							if doShader then
								if wobbleIntensity > 0 then
									local heaPct = math.sqrt(1 -
										(dynamic.health(self).current / dynamic.health(self).base))
									local fatPct = math.sqrt(1 -
										(dynamic.fatigue(self).current / dynamic.fatigue(self).base))
									local magPct = math.sqrt(1 -
										(dynamic.magicka(self).current / dynamic.magicka(self).base))
									shader:setFloat("depthEffect", 5 * fatPct)
									shader:setFloat("wobbleSpeed", 5 * magPct)
									shader:setFloat("displacement",
										wobbleMax * (0.35 * math.max(fatPct, magPct) + 0.65 * heaPct))
								end
							end
							-- show message
							if dynamic.magicka(self).current < 1 then
								ui.showMessage('Your ability to maintain the link falters.')
								endEarly = true
								doOnce = true
							elseif dynamic.fatigue(self).current < 1 then
								ui.showMessage('Your concentration falters.')
								endEarly = true
								doOnce = true
							else
								--ui.showMessage('Astral projection has weakened your connection the material plane.')
								ui.showMessage('Witnessing Prophecy enacts its toll.')
							end
						end
					end

					camera.showCrosshair(false)
					camera.setExtraPitch(0)
					camera.setExtraYaw(0)
					camera.setExtraRoll(0)
					-- following section is for camera controls when you cannot control the player
					self.controls.jump = false
					self.controls.movement = 0
					self.controls.sideMovement = 0
					self.controls.yawChange = 0
					self.controls.pitchChange = 0

					camera.setPitch(camera.getPitch() + (input.getMouseMoveY() * 0.005) +
						(input.getAxisValue(input.CONTROLLER_AXIS.LookUpDown) * 0.05))
					camera.setYaw(camera.getYaw() + (input.getMouseMoveX() * 0.005) +
						(input.getAxisValue(input.CONTROLLER_AXIS.LookLeftRight) * 0.05))
					camera.setRoll(0)

					local moveForward = 0
					local moveRight = 0
					local moveUp = 0
					if input.isActionPressed(input.ACTION.MoveForward) then moveForward = moveForward + dt end
					if input.isActionPressed(input.ACTION.MoveBackward) then moveForward = moveForward - dt end
					if input.isActionPressed(input.ACTION.MoveLeft) then moveRight = moveRight - dt end
					if input.isActionPressed(input.ACTION.MoveRight) then moveRight = moveRight + dt end
					if input.isActionPressed(input.ACTION.Jump) then moveUp = moveUp + dt end
					if input.isActionPressed(input.ACTION.Sneak) then moveUp = moveUp - dt end
					local speedBoost = math.min(3, moveMult * (0.5 + attributes.speed(self).modified / 100))
					local offset = util.transform.rotateZ(camera.getYaw()) *
						util.vector3(moveRight * speedBoost * 200, moveForward * speedBoost * 200,
							moveUp * speedBoost * 150)
					camera.setStaticPosition(camera.getPosition() + offset)
				end
			end
		end
	}
}
