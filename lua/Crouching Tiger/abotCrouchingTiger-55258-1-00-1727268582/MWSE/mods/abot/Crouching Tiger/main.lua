--[[
Allow to jump from crouching position
(getting some temporary Acrobatics buff in the process).
]]

local common = require('abot.Crouching Tiger.common')

local modPrefix = common.modPrefix
local config = common.config or {}

local jumpDelay, jumpDelayWalk, jumpDelayRun, acrobaticsBuffPerc
local logLevel
local logLevel1---, logLevel2, logLevel3

local function updateFromConfig()
	if logLevel3 then
		mwse.log('%s: updateFromConfig()', modPrefix)
	end
	jumpDelay = config.jumpDelay
	acrobaticsBuffPerc = config.acrobaticsBuffPerc
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	---logLevel2 = logLevel >= 2
	---logLevel3 = logLevel >= 3
end
common.updateFromConfig = updateFromConfig
updateFromConfig()

local function tapBinding(keybind)
	local inputConfig = tes3.getInputBinding(keybind)
	if not inputConfig then
		return
	end
	local device = inputConfig.device
	---mwse.log('inputConfig.device = %s', device)
	if device == 0 then
		tes3.tapKey(inputConfig.code)
	end
end

local tes3_skill_acrobatics = tes3.skill.acrobatics

 -- loaded in loaded(), saved to player.data in save()
local ab01snkAcrBuff

-- set in initialized
local inputController

-- set in loaded()
local player, mobilePlayer

local function addAcrobaticsBuff()
	local stat = mobilePlayer:getSkillStatistic(tes3_skill_acrobatics)
	local prev = stat.current
	ab01snkAcrBuff = math.floor( (prev * acrobaticsBuffPerc / 100) + 0.5 )
	tes3.modStatistic({reference = player,
		skill = tes3_skill_acrobatics, current = ab01snkAcrBuff})
	if logLevel1 then
		mwse.log('%s: addAcrobaticsBuff() Acrobatics buffed from %s to %s',
			modPrefix, prev, stat.current)
	end
end

local function removeAcrobaticsBuff()
	if not ab01snkAcrBuff then
		return
	end
	local stat = mobilePlayer:getSkillStatistic(tes3_skill_acrobatics)
	local prev = stat.current
	tes3.modStatistic({reference = player,
		skill = tes3_skill_acrobatics, current = -ab01snkAcrBuff})
	if logLevel1 then
		mwse.log('%s: removeAcrobaticsBuff() Acrobatics reset from %s to %s',
			modPrefix, prev, stat.current)
	end
	ab01snkAcrBuff = nil
end

local function ab01crtgPT1(e)
	local timer = e.timer
	if mobilePlayer.isJumping
	and (timer.iterations > 1) then
		return
	end
	removeAcrobaticsBuff()
	timer:cancel()
end

local tes3_keybind_jump = tes3.keybind.jump

local function tapJump()
	if (acrobaticsBuffPerc > 0)
	and (not ab01snkAcrBuff) then
		-- persistent time timer
		addAcrobaticsBuff()
		timer.start({duration = 3, iterations = 30,
			callback = 'ab01crtgPT1'})
	end
	tapBinding(tes3_keybind_jump)
end

local tes3_keyTransition_upThisFrame = tes3.keyTransition.upThisFrame

local function keyUp()
	if tes3.menuMode() then
		return
	end
	if not mobilePlayer.isSneaking then
		return
	end
	if not inputController:keybindTest(tes3_keybind_jump,
			tes3_keyTransition_upThisFrame) then
		return
	end
	mobilePlayer.forceSneak = false
	if mobilePlayer.jumpingDisabled then
		return
	end
	timer.start({duration = jumpDelay, callback = tapJump})
	---return false
end

--[[ --nope
local function keybindTested(e)
	if not e.result then
		return
	end
	if not (e.transition == tes3_keyTransition_upThisFrame) then
		return
	end
	if tes3.menuMode() then
		return
	end
	if not mobilePlayer.isSneaking then
		return
	end
	mobilePlayer.forceSneak = false
	if mobilePlayer.jumpingDisabled then
		return
	end
	timer.start({duration = jumpDelay, callback = tapJump})
	return false
end
event.register('keybindTested', keybindTested, {filter = tes3_keybind_jump})
]]

local function mcmOnClose()
	--[[if not (config.modEnabled == modEnabled) then
		toggleEvents(config.modEnabled)
	end]]
	updateFromConfig()
	common.saveConfig()
end
common.mcmOnClose = mcmOnClose

local function save()
	player.data.ab01snkAcrBuff = ab01snkAcrBuff
end

local loadedOnceDone = false
local function loadedOnce()
	if loadedOnceDone then
		return
	end
	loadedOnceDone = true
	timer.register('ab01crtgPT1', ab01crtgPT1) -- persistent timer
	event.register('save', save)
	event.register('keyUp', keyUp)
end

local function loaded()
	player = tes3.player
	mobilePlayer = tes3.mobilePlayer
	ab01snkAcrBuff = player.data.ab01snkAcrBuff
	loadedOnce()
end

local function modConfigReady()
	common.modConfigReady()
end
event.register('modConfigReady', modConfigReady)

event.register('initialized',
function ()
	inputController = tes3.worldController.inputController
	event.register('loaded', loaded)
end, {doOnce = true}
)
