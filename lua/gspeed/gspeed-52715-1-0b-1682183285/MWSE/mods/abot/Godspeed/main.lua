--[[
hotkeys to adjust player speed
]]

local defaultConfig = {
slowKey = {keyCode = tes3.scanCode.one, isShiftDown = false, isAltDown = true, isControlDown = false,},
fastKey = {keyCode = tes3.scanCode.two, isShiftDown = false, isAltDown = true, isControlDown = false,},
fixStrafeSpeed = true,
}

local author = 'abot'
local modName = 'Godspeed'
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)

-- set in loaded()
local player, mobilePlayer

local minMul = 0.25
local maxMul = 4
local delta = 0.025

local walkMul = 1
local runMul = 1
local sneakMul = 1

-- updated in modConfigReady()
local slowKey = config.slowKey
local fastKey = config.fastKey
local fixStrafeSpeed = config.fixStrafeSpeed

local invsqrt2 = 1 / math.sqrt(2)

local function calcMoveSpeed(e)
	if not (e.reference == player) then
		return
	end
	if mobilePlayer.isSneaking then
		e.speed = e.speed * sneakMul
	elseif mobilePlayer.isRunning then
		e.speed = e.speed * runMul
	elseif mobilePlayer.isWalking then
		e.speed = e.speed * walkMul
	end
	if fixStrafeSpeed then
		if mobilePlayer.isMovingForward
		or mobilePlayer.isMovingBack then
			if mobilePlayer.isMovingLeft
			or mobilePlayer.isMovingRight then
				---local before = e.speed
				if mobilePlayer.is3rdPerson then
					e.speed = e.speed * 0.77
				else
					e.speed = e.speed * invsqrt2
				end
				---tes3ui.showNotifyMenu('speed before: %s\nspeed after = %s', before, e.speed)
			end
		end
	end
end

local function keyDown(e)
	if tes3ui.menuMode() then
		return
	end
	local keyCode = e.keyCode
	local x
	if (keyCode == slowKey.keyCode) then
		if (e.isAltDown == slowKey.isAltDown)
		and (e.isShiftDown == slowKey.isShiftDown)
		and (e.isControlDown == slowKey.isControlDown) then
			if mobilePlayer.isSneaking then
				x = sneakMul - delta
				if x >= minMul then
					sneakMul = x
					tes3ui.showNotifyMenu('Sneak Speed Multiplier: %5.3f', x)
				end
			elseif mobilePlayer.isRunning then
				---tes3ui.showNotifyMenu('slowKey')
				x = runMul - delta
				if x >= minMul then
					runMul = x
					tes3ui.showNotifyMenu('Run Speed Multiplier: %5.3f', x)
				end
			elseif mobilePlayer.isWalking then
				x = walkMul - delta
				if x >= minMul then
					walkMul = x
					tes3ui.showNotifyMenu('Walk Speed Multiplier: %5.3f', x)
				end
			end
			return false
		end
	end
	if (keyCode == fastKey.keyCode) then
		if (e.isAltDown == fastKey.isAltDown)
		and (e.isShiftDown == fastKey.isShiftDown)
		and (e.isControlDown == fastKey.isControlDown) then
			if mobilePlayer.isSneaking then
				x = sneakMul + delta
				if x <= maxMul then
					sneakMul = x
					tes3ui.showNotifyMenu('Sneak Speed Multiplier: %5.3f', x)
				end
			elseif mobilePlayer.isRunning then
				x = runMul + delta
				if x <= maxMul then
					runMul = x
					tes3ui.showNotifyMenu('Run Speed Multiplier: %5.3f', x)
				end
			elseif mobilePlayer.isWalking then
				x = walkMul + delta
				if x <= maxMul then
					walkMul = x
					tes3ui.showNotifyMenu('Walk Speed Multiplier: %5.3f', x)
				end
			end
			return false
		end
	end
end

local function save()
	local data = player.data
	if not data then
		player.data = {}
		data = player.data
	end
	local ab01gs = data.ab01gs
	if not ab01gs then
		data.ab01gs = {}
		ab01gs = data.ab01gs
	end
	ab01gs.sm = sneakMul
	ab01gs.rm = runMul
	ab01gs.wm = walkMul
end

local function loaded()
	player = tes3.player
	mobilePlayer = tes3.mobilePlayer
	local data = player.data
	if data then
		local ab01gs = data.ab01gs
		if ab01gs then
			sneakMul = ab01gs.sm 
			runMul = ab01gs.rm
			walkMul = ab01gs.wm
		end
	end
end	

local function modConfigReady()
	local function createConfigVariable(varId)
		return mwse.mcm.createTableVariable{id = varId,	table = config}
	end
	local template = mwse.mcm.createTemplate(mcmName)
	template:register()
	template.onClose = function()
		slowKey = config.slowKey
		fastKey = config.fastKey
		fixStrafeSpeed = config.fixStrafeSpeed
		mwse.saveConfig(configName, config, {indent = true})
	end

	local preferences = template:createSideBarPage({
		label="Info",
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.3
			self.elements.sideToSideBlock.children[2].widthProportional = 0.7
		end
	})
	local controls = preferences:createCategory({})

	controls:createKeyBinder({
		label = 'Decrease Speed Hotkey', allowCombinations = true,
		description = 'Run/Walk/Sneak to tweak related speeds.',
		variable = createConfigVariable('slowKey')
	})
	controls:createKeyBinder({
		label = 'Increase Speed Hotkey', allowCombinations = true,
		description = 'Run/Walk/Sneak to tweak related speeds.',
		variable = createConfigVariable('fastKey')
	})
	controls:createOnOffButton({
		label = 'Fix Strafe Speed',
		description = 'Same as RunFix mod. So disable this if you are running RunFix too.',
		variable = createConfigVariable('fixStrafeSpeed')
	})
	event.register('loaded', function()
		event.register('keyDown', keyDown)
		event.register('calcMoveSpeed', calcMoveSpeed)
	end, {doOnce = true}
	)
	event.register('save', save)
	event.register('loaded', loaded)
end

event.register('modConfigReady', modConfigReady)
