local core = require('openmw.core')
local ui = require('openmw.ui')
local input = require('openmw.input')
local self = require('openmw.self')
local types = require('openmw.types')
local async = require('openmw.async')
local camera = require("openmw.camera")
local Actor = require('openmw.types').Actor

-- handle settings
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

I.Settings.registerPage({
   key = 'SevenSprint',
   l10n = 'SevenSprint',
   name = 'name',
   description = 'description',
})

-- default values!
local enabled = true
local verbose = true
local buffSpeed = 50
local buffAcrobatics = 50
local fatigueBase = 1
local sprintWeaponReady = false
local noBackwardRun = true
local zoomSprint = false
local holdAltSprint = true
local holdUseSprint = false
local tapActivateSprint = false
local doubleTapSprint = false
local doubleTapWait = 0.5
local allowSwimming = true

local zoomStrengh = 0.15
local zoomIn = 0.5
local zoomOut = 1.0

I.Settings.registerGroup({
   key = 'Settings_SevenSprint',
   page = 'SevenSprint',
   l10n = 'SevenSprint',
   name = 'group_name',
   permanentStorage = true,
   settings = {
      {
         key = 'enabled',
         default = enabled,
         renderer = 'checkbox',
         name = 'enabled_name',
      },
      {
         key = 'verbose',
         default = verbose,
         renderer = 'checkbox',
         name = 'verbose_name',
      },
      {
         key = 'buffSpeed',
         default = buffSpeed,
         renderer = 'number',
         name = 'buffSpeed_name',
         description = 'buffSpeed_description',
         argument = {
            integer = true,
            min = 1,
            max = 100,
         },
      },
      {
         key = 'buffAcrobatics',
         default = buffAcrobatics,
         renderer = 'number',
         name = 'buffAcrobatics_name',
         description = 'buffAcrobatics_description',
         argument = {
            integer = true,
            min = 0,
            max = 100,
         },
      },
      {
         key = 'fatigueBase',
         default = fatigueBase,
         renderer = 'number',
         name = 'fatigueBase_name',
         description = 'fatigueBase_description',
         argument = {
   	    integer = true,
            min = 1,
            max = 10,
         },
      },
	{
         key = 'sprintWeaponReady',
         default = sprintWeaponReady,
         renderer = 'checkbox',
         name = 'sprintWeaponReady_name',
      },
	{
         key = 'allowSwimming',
         default = allowSwimming,
         renderer = 'checkbox',
         name = 'allowSwimming_name',
      },
	{
         key = 'noBackwardRun',
         default = noBackwardRun,
         renderer = 'checkbox',
         name = 'noBackwardRun_name',
      },
	{
         key = 'zoomSprint',
         default = zoomSprint,
         renderer = 'checkbox',
         name = 'zoomSprint_name',
      },
	{
         key = 'holdAltSprint',
         default = holdAltSprint,
         renderer = 'checkbox',
         name = 'holdAltSprint_name',
      },
	{
         key = 'holdUseSprint',
         default = holdUseSprint,
         renderer = 'checkbox',
         name = 'holdUseSprint_name',
      },
	{
         key = 'tapActivateSprint',
         default = tapActivateSprint,
         renderer = 'checkbox',
         name = 'tapActivateSprint_name',
      },
	{
         key = 'doubleTapSprint',
         default = doubleTapSprint,
         renderer = 'checkbox',
         name = 'doubleTapSprint_name',
      },
      {
         key = 'doubleTapWait',
         default = doubleTapWait,
         renderer = 'number',
         name = 'doubleTapWait_name',
         argument = {
            min = 0.1,
            max = 1.0,
         },
      },

   },
})
local settingsGroup = storage.playerSection('Settings_SevenSprint')

-- update
local function updateSettings()
  enabled = settingsGroup:get('enabled')
  verbose = settingsGroup:get('verbose')
  buffSpeed = settingsGroup:get('buffSpeed')
  buffAcrobatics = settingsGroup:get('buffAcrobatics')
  fatigueBase = settingsGroup:get('fatigueBase')
  sprintWeaponReady = settingsGroup:get('sprintWeaponReady')
  allowSwimming = settingsGroup:get('allowSwimming')
  noBackwardRun = settingsGroup:get('noBackwardRun')
  zoomSprint = settingsGroup:get('zoomSprint')
  holdAltSprint = settingsGroup:get('holdAltSprint')
  holdUseSprint = settingsGroup:get('holdUseSprint')
  tapActivateSprint = settingsGroup:get('tapActivateSprint')
  doubleTapSprint = settingsGroup:get('doubleTapSprint')
  doubleTapWait = settingsGroup:get('doubleTapWait')
end
local function init()
    updateSettings()
end
settingsGroup:subscribe(async:callback(updateSettings))

-- shorthand for convenience
local attributes = types.Actor.stats.attributes
local skills = types.NPC.stats.skills
local dynamic = types.Actor.stats.dynamic

-- change Speed attribute
local function spdMod(modSign,modVal)
  if modVal > 0 then -- if positive effect, then modifier; else damage
    modVal = math.abs(modVal)
    attributes.speed(self).modifier = math.max(0,attributes.speed(self).modifier + modSign*modVal)
  else
    modVal = math.abs(modVal)
    attributes.speed(self).damage = math.max(0,attributes.speed(self).damage + modSign*modVal)
  end
end

-- change Acrobatics skill
local function acrobaticsMod(modSign,modVal)
  if modVal > 0 then -- if positive effect, then modifier; else damage
    modVal = math.abs(modVal)
    skills.acrobatics(self).modifier = math.max(0,skills.acrobatics(self).modifier + modSign*modVal)
  else
    modVal = math.abs(modVal)
    skills.acrobatics(self).damage = math.max(0,skills.acrobatics(self).damage + modSign*modVal)
  end
end


local buffTotal = 0
local acrobaticsTotal = 0
local fatigueTime = 0
local fatigueWait = 0.1

local sprintTime = 0

local function onSave()
    return{
	buffTotal = buffTotal, acrobaticsTotal = acrobaticsTotal
    }
end

local function onLoad(data)
  if data then	
	if data.buffTotal then
		buffTotal = data.buffTotal
	else
		buffTotal = 0
	end
	if data.acrobaticsTotal then
		acrobaticsTotal = data.acrobaticsTotal
	else
		acrobaticsTotal = 0
	end

	spdMod(-1,buffTotal)
	buffTotal = 0

	acrobaticsMod(-1,acrobaticsTotal)
	acrobaticsTotal = 0
  end
end

local function apply_fov(magnitude)
  return camera.setFieldOfView((camera.getBaseFieldOfView() * (1 - (0.5 * magnitude))))
end

local zoomTotal = 0
local zoomOutTime = 0

local tapTime = 0
local tapState = 0
-- 0 - not moving, waiting to press FORWARD
-- 1 - waiting to release FORWARD
-- 2 - waiting to press FORWARD second time
-- 3 - sprint active until player stops or runs out of fatigue

local useActive = false
local activateActive = false
local prevActivatePressed = input.isActionPressed(input.ACTION.Activate)

local function onFrame()
	local is_run = self.controls.run
	local currentFatigue = dynamic.fatigue(self).current
	local mf = self.controls.movement
	local isSneakPressed = input.isActionPressed(input.ACTION.Sneak)
	local isForwardPressed = (input.isActionPressed(input.ACTION.MoveForward) or input.getAxisValue(input.CONTROLLER_AXIS.MoveForwardBackward) > 0)
	local isSidePressed = (input.isActionPressed(input.ACTION.MoveLeft) or input.isActionPressed(input.ACTION.MoveRight) or self.controls.sideMovement ~= 0)
	local sprintTimeDiff = core.getRealTime() - sprintTime
	local zoomOutTimeDiff = core.getRealTime() - zoomOutTime
	local sprintKey = false
	local tapTimeDiff = core.getRealTime() - tapTime
	local sprintCondition = false
	local weaponReady = (Actor.stance(self) == Actor.STANCE.Weapon)
	local emptyHands = (Actor.stance(self) == Actor.STANCE.Nothing)
	local isUsePressed = input.isActionPressed(input.ACTION.Use)
	local isActivatePressed = false

	if input.isActionPressed(input.ACTION.Activate) == true and prevActivatePressed == false then
		isActivatePressed = true
	end
	prevActivatePressed = input.isActionPressed(input.ACTION.Activate)	

--	if  types.Actor.isOnGround(self) and is_run and currentFatigue >= 1 and mf > 0 and not isSneakPressed and self.controls.use==0 then
	--if  types.Actor.isOnGround(self) and is_run and currentFatigue >= 1 and not isSneakPressed and self.controls.use==0 then
	if (types.Actor.isOnGround(self) or allowSwimming and types.Actor.isSwimming(self)) and currentFatigue >= 1 and not isSneakPressed and self.controls.use == 0 and not isSidePressed and (sprintWeaponReady or not weaponReady) then
		sprintCondition = true
	end

	if enabled and holdUseSprint and isUsePressed and emptyHands and sprintCondition and mf > 0 then
		useActive = true
	else
		useActive = false
	end

	if activateActive == false and enabled and tapActivateSprint and isActivatePressed and sprintCondition and mf > 0 then
		activateActive = true
	elseif activateActive == true then 
		if not sprintCondition or mf <= 0 or isActivatePressed then
			activateActive = false
		end		
	end

	-- code to detect double tap FORWARD within 0.5s
	if tapState == 0 then
		-- waiting to start moving and press FORWARD
		if enabled and doubleTapSprint and sprintCondition and isForwardPressed and mf <= 0 then
			tapState = 1
		        tapTime = core.getRealTime()
			--ui.showMessage('state 1')
		end
	elseif tapState == 1 then
		-- waiting to release FORWARD
		if not sprintCondition or tapTimeDiff > doubleTapWait then
			tapState = 0
			--ui.showMessage('state 1 -> 0')
		elseif not isForwardPressed then
			tapState = 2
			--ui.showMessage('state 2')
		end
	elseif tapState == 2 then
		-- waiting to press FORWARD second time
		if not sprintCondition or tapTimeDiff > doubleTapWait then
			tapState = 0
			--ui.showMessage('state 2 -> 0')
		elseif isForwardPressed then
			tapState = 3
			--ui.showMessage('state 3')
		end
	elseif tapState == 3 then
		-- sprint active
		if not sprintCondition or mf <= 0 then
			tapState = 0
			--ui.showMessage('state 3 -> 0')
		end
	else
		-- incorrect state
		tapState = 0
	end


	if holdAltSprint and input.isAltPressed() then
		sprintKey = true
	end

	if doubleTapSprint and tapState == 3 then
		sprintKey = true
	end

	if useActive or activateActive then
		sprintKey = true
	end

	if enabled and sprintKey and sprintCondition and is_run and mf > 0 then
		-- possibly start sprint
		if buffTotal == 0 then
--			buffTotal = (buffSpeed + skills.athletics(self).modified / 4) * (200 - math.min(100, skills.athletics(self).modified)) / 200
			buffTotal = buffSpeed + math.min(skills.athletics(self).modified, 100) / 4
			spdMod(1, buffTotal)
			-- remember when started sprint
			sprintTime = core.getRealTime()
         
			if verbose then
				ui.showMessage('Sprint!')
				--ui.showMessage(msg("startSprint"))
			end
		else
			if zoomSprint then
				-- sprint is active, player on the ground
				zoomTotal = math.max(zoomTotal, math.min(zoomStrengh, sprintTimeDiff * zoomStrengh / zoomIn))
				if camera.getMode() == camera.MODE.FirstPerson then
					apply_fov(zoomTotal)
				end
			end
			if sprintTimeDiff > 0.5 and acrobaticsTotal == 0 and buffAcrobatics > 0 then
				acrobaticsTotal = buffAcrobatics * (200 - math.min(100, skills.acrobatics(self).modified)) / 200
				acrobaticsMod(1, acrobaticsTotal)
--				ui.showMessage('Acrobatics buff')
			end
		end
	elseif buffTotal > 0 and ( not sprintCondition or not sprintKey ) then
		-- stop sprint
		if verbose then
			ui.showMessage('End sprint!')
			--ui.showMessage(msg("endSprint"))
		end
		spdMod(-1,buffTotal)
		buffTotal = 0
		
		acrobaticsMod(-1, acrobaticsTotal)
		acrobaticsTotal = 0
--		ui.showMessage('stop Acrobatics')

		sprintTime = 0
		zoomOutTime = 0
    	end

	-- reset camera zoom 
	if buffTotal == 0 and zoomTotal > 0 and (types.Actor.isOnGround(self) or types.Actor.isSwimming(self)) then
		if zoomOutTime == 0 then
			--ui.showMessage('Start zooming out')
			-- start zooming out
			zoomOutTime = core.getRealTime()
		else
			-- apply zooming out
			zoomTotal = math.max(0, zoomTotal - zoomOutTimeDiff * zoomStrengh / zoomOut)
			if camera.getMode() == camera.MODE.FirstPerson then
				apply_fov(zoomTotal)
			end
			if zoomTotal == 0 then
				--ui.showMessage('Zoomed out')
			end
		end
	end

	if self.controls.run == true and noBackwardRun and self.controls.movement < 0 then
		self.controls.run = false  -- prevent running
		--ui.showMessage("why are u running?")
	end
end

return { 
  engineHandlers = { 
    -- init settings
    onActive = init,
    -- save and load handling so you don't get stuck with modified stats
    onSave = onSave,
    onLoad = onLoad,
    -- update every frame
    onFrame = onFrame,
    
    onInputAction = function(id)
      if enabled then
      end
    end,
  
    onUpdate = function(dt)
	if enabled and buffTotal > 0 and (types.Actor.isOnGround(self) or allowSwimming and types.Actor.isSwimming(self)) then -- if running, drain fatigue
		-- apply extra fatigue when sprinting
		local mf = self.controls.movement
		local ms = self.controls.sideMovement
		
		if mf ~= 0 or ms ~= 0 then -- if moving
			fatigueTime = fatigueTime + dt
			if fatigueTime > fatigueWait then -- if enough time has passed
				local currentFatigue = dynamic.fatigue(self).current
				local fatigueCost = fatigueBase + (skills.athletics(self).modified / 25)
				-- faster fatigue drain when sorinting with weapon in hands
				if Actor.stance(self) == Actor.STANCE.Weapon then
					fatigueCost = fatigueCost + 1
				end
				-- correct fatigueCost according to time spent
				fatigueCost = fatigueCost * fatigueTime / fatigueWait
				dynamic.fatigue(self).current = math.max(0,currentFatigue - fatigueCost)
				fatigueTime = 0
			end
		end
	end
    end,
  } 
}
