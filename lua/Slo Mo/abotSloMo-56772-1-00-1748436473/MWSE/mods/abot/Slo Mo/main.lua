local defaultConfig = {
modEnabled = true,
sloMoOnDeath = true, -- fun!
sloMoOnKnock = true, -- extra fun!
sloMoOnHit = false, -- too much fun though!
mouseWheelExitSloMo = true,
mouseWheelEnterSloMo = false, -- illegal fun! set false for no cheat
menuEnterResetSloMo = true,
resetMouseCombo = {	mouseButton = 2,
isAltDown = true, isShiftDown = false
},
slowMoMul = 0.8,
slowMoStop = 0.02,
animDetectDelay = 5,
wheelMul = 0.8,
logLevel = 0
}

local author = 'abot'
local modName = 'Slo Mo'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)
assert(config)

local modEnabled, sloMoOnDeath, sloMoOnKnock, sloMoOnHit
local mouseWheelExitSloMo, mouseWheelEnterSloMo
local menuEnterResetSloMo, resetMouseCombo
local slowMoMul, slowMoStop, animDetectDelay, wheelMul
local logLevel, logLevel1, logLevel2, logLevel3, logLevel4

local groupsDict = {}

local function addGroup(v, k)
	if not groupsDict[v] then
		if logLevel2 then
			mwse.log('groupsDict[%s] = %s', v, k)
		end
		groupsDict[v] = k
	end
end

local function setGroupsDict()
	---local startTime = os.clock()
	groupsDict = {}
	if logLevel2 then
		mwse.log('%s: setGroupsDict()', modPrefix)
	end
	for k, v in pairs(tes3.animationGroup) do
		local lck = string.lower(k)
		if sloMoOnDeath
		and string.find(lck, 'death', 1, true) then
			addGroup(v, k)
		end
		if sloMoOnKnock
		and string.find(lck, 'knock', 1, true) then
			addGroup(v, k)
		end
		if sloMoOnHit
		and string.find(lck, 'hit', 1, true) then
			addGroup(v, k)
		end
	end
	-- if logLevel1 then
		-- mwse.log('%s: setGroupsDict() elapsed time: %s sec',
			-- modPrefix, os.clock() - startTime)
	-- end
end

-- set in loaded()
local player, mobilePlayer, playGroupTimer
---local player1stPerson

-- set in modConfigready, updatedin loaded()
local worldController

-- used to skip playGroup event
local skipPlayGroup = false

local function resetTimeScalar()
	if logLevel3 then
		mwse.log('%s: resetTimeScalar()', modPrefix)
		tes3.messageBox('resetTimeScalar()')
	end
	worldController.simulationTimeScalar = 1.0
end

local function resetTimer()
	assert(playGroupTimer)
	if playGroupTimer then
		---if logLevel3 then
			---mwse.log('%s: resetTimer()', modPrefix)
		---end
		skipPlayGroup = true
		-- restart timer for re-enabling playGroup event
		playGroupTimer:reset()
	end
end

local function resetTimerAndTimeScalar()
	if playGroupTimer then
		if logLevel3 then
			mwse.log('%s: resetTimerAndTimeScalar()', modPrefix)
		end
		skipPlayGroup = true
		-- restart timer for re-enabling playGroup event
		playGroupTimer:reset()
	end
	worldController.simulationTimeScalar = 1
end

local function isAnotherModChangingTimeScalar()
	local data = player.data
	if not data then
		return false
	end
	if data.ggw_slowTimeContext then
		return true -- Halls Of Colossus
	end
	local neph = data.neph
	if neph then
		local neph58 = neph[58]
		if neph58
		and (neph58 == 1) then
			return true -- Power Fantasy
		end
	end
	return false
end

local tes3_aiBehaviorState_attack = tes3.aiBehaviorState.attack
local tes3_aiBehaviorState_flee = tes3.aiBehaviorState.flee

local function playGroup(e)
	local ref = e.reference
	local tempData = ref.tempData
	local groupId = groupsDict[e.group]
	if not groupId then
		if skipPlayGroup
		and tempData.ab01slomo then
			tempData.ab01slomo = nil
			skipPlayGroup = false
		end
		return
	end
	if skipPlayGroup then
		return
	end
	local mob = ref.mobile
	---assert(mob)

	if isAnotherModChangingTimeScalar() then
		return
	end

	if not (mob == mobilePlayer) then
		local actionData = mob.actionData
		if not actionData then
			return
		end
		local target = actionData.target
		if not target then
			return
		end
		if not (target == mobilePlayer) then
			return
		end
		local aiBehaviorState = actionData.aiBehaviorState
		if not (
			(aiBehaviorState == tes3_aiBehaviorState_attack)
			or (aiBehaviorState == tes3_aiBehaviorState_flee)
		) then
			return
		end
		if logLevel3 then
			mwse.log('%s: playGroup("%s"), mob = "%s", aiBehaviorState = %s',
				modPrefix, groupId, ref, aiBehaviorState)
		end
		if (aiBehaviorState == tes3_aiBehaviorState_flee) then
			if mob.health.normalized > 0.33 then
				actionData.aiBehaviorState = tes3_aiBehaviorState_attack
				tes3.messageBox('No flee')
			end
		end
	end

	local timeScalar = worldController.simulationTimeScalar
	--[[if ref == player1stPerson then
		if math.abs(1 - timeScalar) > 0.01 then
			worldController.simulationTimeScalar = 1
		end
		return
	end]]
	local newTimeScalar = timeScalar * slowMoMul
	if newTimeScalar < slowMoStop then
		newTimeScalar = slowMoStop
	elseif newTimeScalar > 1 then
		newTimeScalar = 1
	end
	if math.abs(newTimeScalar - timeScalar) > 0.01 then
		if logLevel3 then
			tes3.messageBox('playGroup("%s"), timeScalar = %.3f',
				groupId, newTimeScalar)
			if logLevel4 then
				mwse.log('%s: playGroup("%s"), timeScalar = %.3f',
					modPrefix, groupId, newTimeScalar)
			end
		end
		if not tempData.ab01slomo then
			tempData.ab01slomo = true
		end
		worldController.simulationTimeScalar = newTimeScalar
	end
end


local function mouseWheel(e)
	if not e.isAltDown then
		return
	end
	if tes3.menuMode()
	and menuEnterResetSloMo then
		return
	end

	if isAnotherModChangingTimeScalar() then
		return
	end

	local delta = e.delta
	local timeScalar = worldController.simulationTimeScalar
	local scrollDown = (delta < 0)
	local scrollUp = (delta > 0)
	local newTimeScalar = timeScalar
	if scrollDown -- mouse wheel back/zoom out/scroll down
	and mouseWheelEnterSloMo then
		newTimeScalar = timeScalar * wheelMul -- slower motion
	elseif scrollUp -- mouse wheel forward/zoom in/scroll up
	and mouseWheelExitSloMo then
		if e.isCtrlDown then
			resetTimerAndTimeScalar()
			return
		end
		newTimeScalar = timeScalar / wheelMul -- faster motion
	else
		return
	end
	if newTimeScalar > 1 then
		newTimeScalar = 1
	elseif newTimeScalar < slowMoStop then
		newTimeScalar = slowMoStop
		resetTimer()
	elseif logLevel3 then
		local s
		if scrollDown then
			s = 'backward'
		elseif scrollUp then
			s = 'forward'
		end
		if s then
			mwse.log('%s: mouseWheel(%s) %s timescalar from %.3f to %.3f',
				modPrefix, delta, s, timeScalar, newTimeScalar)
			tes3.messageBox('timeScalar = %.3f', newTimeScalar)
		end
	end
	if math.abs(newTimeScalar - timeScalar) < 0.01 then
		return
	end
	---if newTimeScalar < (slowMoStop + 0.25) then
		---resetTimer()
	---end
	worldController.simulationTimeScalar = newTimeScalar
end

local function menuEnter()
	resetTimeScalar()
end

--- @param e mouseButtonUpEventData
local function mouseButtonUp(e)
	if tes3.menuMode()
	and menuEnterResetSloMo then
		return
	end
	if tes3.isKeyEqual({actual = e, expected = resetMouseCombo}) then
		resetTimerAndTimeScalar()
	end
end

local playGroupRegistered = false
local function checkRegisterPlayGroup(on)
	if logLevel3 then
		mwse.log('%s: checkRegisterPlayGroup(%s)', modPrefix, on)
	end
	if playGroupRegistered then
		if not on then
			playGroupRegistered = false
			event.unregister('playGroup', playGroup)
		end
	elseif on then
		playGroupRegistered = true
		event.register('playGroup', playGroup)
	end
end

local mouseWheelRegistered = false
local function checkRegisterMouseWheel(on)
	---if logLevel2 then
		---mwse.log('%s: checkRegisterMouseWheel(%s)', modPrefix, on)
	---end
	if mouseWheelRegistered then
		if not on then
			mouseWheelRegistered = false
			---if logLevel2 then
				---mwse.log("%s: event.unregister('mouseWheel', mouseWheel)", modPrefix)
			---end
			event.unregister('mouseWheel', mouseWheel)
		end
	elseif on then
		mouseWheelRegistered = true
		---if logLevel2 then
			---mwse.log("%s: event.register('mouseWheel', mouseWheel)", modPrefix)
		---end
		event.register('mouseWheel', mouseWheel)
	end
end

local mouseButtonUpRegistered = false
local function checkRegisterMouseButtonUp(on)
	if mouseButtonUpRegistered then
		if not on then
			mouseButtonUpRegistered = false
			event.unregister('mouseButtonUp', mouseButtonUp)
		end
	elseif on then
		mouseButtonUpRegistered = true
		event.register('mouseButtonUp', mouseButtonUp)
	end
end

local menuEnterRegistered = false
local function checkRegisterMenuEnter(on)
	if menuEnterRegistered then
		if not on then
			menuEnterRegistered = false
			event.unregister('menuEnter', menuEnter)
		end
	elseif on then
		menuEnterRegistered = true
		event.register('menuEnter', menuEnter)
	end
end

local function checkRegister()
	---mwse.log('>>> %s: checkRegister()', modPrefix)
	checkRegisterMouseButtonUp(resetMouseCombo
		and modEnabled)
	checkRegisterPlayGroup(
		(sloMoOnDeath
		or sloMoOnKnock)
		and modEnabled
	)
	checkRegisterMouseWheel(
		(mouseWheelEnterSloMo
		or mouseWheelExitSloMo)
		and modEnabled)
	checkRegisterMenuEnter(menuEnterResetSloMo
		and modEnabled)
end

local function updateFromConfig()
	---mwse.log('>>> %s: updateFromConfig()', modPrefix)
	modEnabled = config.modEnabled
	slowMoMul = config.slowMoMul
	slowMoStop = config.slowMoStop
	animDetectDelay = config.animDetectDelay
	resetMouseCombo = config.resetMouseCombo
	wheelMul = config.wheelMul
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
	logLevel3 = logLevel >= 3
	logLevel4 = logLevel >= 4
	if not (
		(config.sloMoOnDeath == sloMoOnDeath)
		and (config.sloMoOnKnock == sloMoOnKnock)
		and (config.sloMoOnHit == sloMoOnHit)
	) then
		sloMoOnDeath = config.sloMoOnDeath
		sloMoOnKnock = config.sloMoOnKnock
		sloMoOnHit = config.sloMoOnHit
		setGroupsDict()
	end
	mouseWheelEnterSloMo = config.mouseWheelEnterSloMo
	mouseWheelExitSloMo = config.mouseWheelExitSloMo
	menuEnterResetSloMo = config.menuEnterResetSloMo
end

local function onClose()
	---mwse.log('>>> %s: onClose()', modPrefix)
	updateFromConfig()
	checkRegister()
	mwse.saveConfig(configName, config, {indent = true})
end

local function modConfigReady()
	---mwse.log('>>> %s: modConfigReady()', modPrefix)
	worldController = tes3.worldController
	---assert(worldController)
	updateFromConfig()

	local optionList = {'Off', 'Low', 'Medium', 'High', 'Max'}
	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = string.format("%s. %s",
				i - 1, optionList[i]), value = i - 1}
		end
		return options
	end

	local function getDropDownDescription(variableId)
		local i = defaultConfig[variableId]
		return string.format('Default: %s. %s', i, optionList[i+1])
	end

	local template = mwse.mcm.createTemplate({name = mcmName,
		config = config, defaultConfig = defaultConfig,
		showDefaultSetting = true, onClose = onClose})

	local sideBarPage = template:createSideBarPage({
		label = 'Slo, Mo!',
		showHeader = true,
		description = [[Slo, Mo! Fun!
By default you can enter Slow Motion mode only on kill/knock animations,
making it some sort of bonus for your combat prowess.
For added fun you can try enabling the on hit option or even thr Alt + mouse wheel scroll down combo to enter Slo-Mo any time.
This can be very handy to live test any animation related mod too.
Note: if you temporarily disable all the on Death/Knock/Hit animation events, the reset normal speed timer will be disabled too allowing to fully control the Slow Motion from Alt + mouse wheel.]],
		showReset = true,
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.1
			self.elements.sideToSideBlock.children[2].widthProportional = 0.9
		end
	})

	local category = sideBarPage:createCategory({})

	category:createYesNoButton({
		label = 'Enable mod effects',
		description = [[Mod effects toggle.
Useful in case of conflicts investigation to temporarily suspend the mod effects without uninstalling it.

Note: the mod effects should already automatically/temporarily disable if related spell effects from Hall of the Colossus, Power Fantasy mods are detected.

Khajiit on skooma slow time effect on Hit from PVP mod should still work well enough with both mod effects running but let me know if there are problems.]],
		configKey = 'modEnabled',
		callback = checkRegister
	})

	category:createYesNoButton({
		label = 'Slo-Mo on Death',
		description = [[Enter Slow Motion on Death animation events.]],
		configKey = 'sloMoOnDeath'
	})
	category:createYesNoButton({
		label = 'Slo-Mo on Knock',
		description = [[Enter Slow Motion on Knock animation events.]],
		configKey = 'sloMoOnKnock'
	})
	category:createYesNoButton({
		label = 'Slo-Mo on Hit',
		description = [[Enter Slow Motion on Hit animation events.]],
		configKey = 'sloMoOnHit'
	})

	category:createYesNoButton({
		label = 'Alt + mouse wheel scroll up control',
		description = [[Slow-Mo increase speed on Alt + mouse wheel scroll up / forward / zoom in.
Exit Slo-Mo/Reset normal speed on Ctrl + Alt + mouse wheel scroll up / forward / zoom in.]],
		configKey = 'mouseWheelExitSloMo'
	})

	category:createYesNoButton({
		label = 'Alt + mouse wheel scroll down control',
		description = [[Slow-Mo decrease speed on Alt + mouse wheel scroll down / back / zoom out.
Note: this option may be considered a little cheating/for fun,
allowing to enter Slo-Mo at any time, not only on death/knock animations.
It may also be useful for testing anything related to animation at low speed in game.]],
		configKey = 'mouseWheelEnterSloMo'
	})

	category:createYesNoButton({
		label = 'Menu Enter Reset',
		description = [[Exit Slo-Mo/Reset normal speed on entering menu mode.]],
		configKey = 'menuEnterResetSloMo'
	})

	category:createMouseBinder({
		label = 'Reset Combo',
		description = [[Hotkey/Mouse Combo to exit Slo-Mo and reset normal speed.
The combo must include a mouse button and cannot include the Shift key.]],
		configKey = 'resetMouseCombo',
		converter = function(v)
			v.isShiftDown = false
			if not v.mouseButton then
				v.mouseButton = defaultConfig.resetMouseCombo.mouseButton
			end
			return v
		end
	})
	category:createSlider({
		label = 'Slo-Mo Multiplier: %s',
		description = [[Slow-Mo time scalar multiplier.
Slow-Mo animation time scalar multiplier.]],
		configKey = 'slowMoMul',
		decimalPlaces = 2, min = 0.1, max = 0.99, step = 0.01, jump = 0.05
	})

	category:createSlider({
		label = 'Slo-Mo Stop: %s',
		description = [[Minimun Slow-Mo time scalar.
Minimum Slow-Mo animation time scalar.]],
		configKey = 'slowMoStop',
		decimalPlaces = 3, min = 0.01, max = 0.5, step = 0.001, jump = 0.01
	})

	category:createSlider({
		label = 'Slo-Mo Anim delay: %s',
		description = [[Slow-Mo animation detection delay on forced time scalar reset.]],
		configKey = 'animDetectDelay',
		decimalPlaces = 1, min = 0.5, max = 10, step = 0.1, jump = 1
	})

	category:createSlider({
		label = 'Wheel Multiplier: %s',
		description = [[Alt + Mouse wheel time scalar effect multiplier.]],
		configKey = 'wheelMul',
		decimalPlaces = 2, min = 0.5, max = 0.99, step = 0.01, jump = 0.1
	})

	category:createDropdown({
		label = 'Log level:',
		options = getOptions(),
		showDefaultSetting = false,
		description = getDropDownDescription('logLevel') .. [[

Set level of debug information written to the Morrowind\MWSE.log file.

Should be kept to 0 during normal gameplay, but if you encounter a problem with the mod, you could try and save the game right before the problem happens, crank the Log level up, exit the game and reload.

When the problem happens again, exit the game, and send the Morrowind\MWSE.log file with your error report to the mod author.]],
		configKey = 'logLevel'
	})

	mwse.mcm.register(template)

end
event.register('modConfigReady', modConfigReady)

local function timerCallback()
	if sloMoOnDeath
	or sloMoOnKnock
	or sloMoOnHit then
		resetTimeScalar()
		skipPlayGroup = false
	end
end

local function loaded()
	player = tes3.player
	mobilePlayer = tes3.mobilePlayer
	---player1stPerson = tes3.player1stPerson
	---assert(tes3.worldController == worldController)
	worldController = tes3.worldController
	resetTimeScalar()
	playGroupTimer = timer.start({duration = animDetectDelay,
		iterations = -1, callback = timerCallback})
end

event.register('initialized', function ()
	---mwse.log('>>> %s: initialized())', modPrefix)
	checkRegister()
	event.register('loaded', loaded)
end, {doOnce = true})

