--local core = require('openmw.core')  -- for timer
local ui = require('openmw.ui') -- for displaying messages
local self = require('openmw.self') -- for coordinates etc?
local ambient = require('openmw.ambient') -- 0.49 required?
local iui = require('openmw.interfaces').UI -- to disable rest menu if needed
local doOnce = true -- operate on first update that script is enabled, or when settings are changed
local input = require('openmw.input') -- this is literally only here to check if chargen is done for version 0.48
local hasStats = false -- used to determine if chargen is done

-- shader
local postprocessing = require('openmw.postprocessing')
local pulse_shader = postprocessing.load('CellLockedPulse')
local grid_shader = postprocessing.load('CellLockedGrid')

-- settings functions
local function boolSetting(sKey, sDef)
    return {
        key = sKey,
        renderer = 'checkbox',
        name = sKey..'_name',
        description = sKey..'_desc',
        default = sDef,
    }
end
local function numbSetting(sKey, sDef, sInt, sMin, sMax)
    return {
        key = sKey,
        renderer = 'number',
        name = sKey..'_name',
        description = sKey..'_desc',
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
   key = 'SolBodzCellLocked',
   l10n = 'SolBodzCellLocked',
   name = 'name',
   description = 'description',
})
-- default values!
local enabled = true
local modUnlockCount = 0
local loseCurrentCell = false
local nCellsPerSkillLevel = 0.25
local nCellsPerCharaLevel = 1
local healthCost = 5
local healthCostAccel = 5
local timerVal = 3.0
local doPercent = true
local allowRestWhileHurt = false
local shaderRed = 1.0
local shaderGreen = 1.0
local shaderBlue = 1.0
local shaderOpacity = 0.35
local shaderThickness = 5
local shaderFadeDist = 1500
I.Settings.registerGroup({
	key = 'Settings_SolBodzCellLocked_Cell',
	page = 'SolBodzCellLocked',
	l10n = 'SolBodzCellLocked',
	name = 'settingsGroupCell',
	permanentStorage = true,
	settings = {
		boolSetting('enabled',enabled),
		numbSetting('modUnlockCount',modUnlockCount, true,-10,10),
		boolSetting('loseCurrentCell',loseCurrentCell),
		numbSetting('nCellsPerSkillLevel',nCellsPerSkillLevel, false,0.0,1.0),
		numbSetting('nCellsPerCharaLevel',nCellsPerCharaLevel, true,0,10),
	},
})
local settingsGroupCell = storage.playerSection('Settings_SolBodzCellLocked_Cell')
I.Settings.registerGroup({
	key = 'Settings_SolBodzCellLocked_Hurt',
	page = 'SolBodzCellLocked',
	l10n = 'SolBodzCellLocked',
	name = 'settingsGroupHurt',
	permanentStorage = true,
	settings = {
		numbSetting('healthCost',healthCost, true,0,100),
		numbSetting('healthCostAccel',healthCostAccel, true,0,100),
		numbSetting('timerVal',timerVal, false,1.0,5.0),
		boolSetting('doPercent',doPercent),
		boolSetting('allowRestWhileHurt',allowRestWhileHurt),
	},
})
local settingsGroupHurt = storage.playerSection('Settings_SolBodzCellLocked_Hurt')
I.Settings.registerGroup({
	key = 'Settings_SolBodzCellLocked_Shader',
	page = 'SolBodzCellLocked',
	l10n = 'SolBodzCellLocked',
	name = 'settingsGroupShader',
	permanentStorage = true,
	settings = {
		numbSetting('shaderRed',shaderRed, true,0.0,1.0),
		numbSetting('shaderGreen',shaderGreen, true,0.0,1.0),
		numbSetting('shaderBlue',shaderBlue, true,0.0,1.0),
		numbSetting('shaderOpacity',shaderOpacity, false,0.0,1.0),
		numbSetting('shaderThickness',shaderThickness, true,2,20),
		numbSetting('shaderFadeDist',shaderFadeDist, true,0,5000),
	},
})
local settingsGroupShader = storage.playerSection('Settings_SolBodzCellLocked_Shader')
-- update
local function updateSettings()
	enabled = settingsGroupCell:get('enabled')
	if enabled then
		pulse_shader:enable()
		grid_shader:enable()
	else
		pulse_shader:disable() -- force disable just in case
		grid_shader:disable()
	end	
	modUnlockCount = settingsGroupCell:get('modUnlockCount')
	loseCurrentCell = settingsGroupCell:get('loseCurrentCell')
	nCellsPerSkillLevel = settingsGroupCell:get('nCellsPerSkillLevel')
	nCellsPerCharaLevel = settingsGroupCell:get('nCellsPerCharaLevel')
	healthCost = settingsGroupHurt:get('healthCost')
	healthCostAccel = settingsGroupHurt:get('healthCostAccel')
	timerVal = settingsGroupHurt:get('timerVal')
	doPercent = settingsGroupHurt:get('doPercent')
	allowRestWhileHurt = settingsGroupHurt:get('allowRestWhileHurt')
	doOnce = true
	-- and update the shader settings
	shaderRed = settingsGroupShader:get('shaderRed')
	grid_shader:setFloat("red", shaderRed)
	shaderGreen = settingsGroupShader:get('shaderGreen')
	grid_shader:setFloat("green", shaderGreen)
	shaderBlue = settingsGroupShader:get('shaderBlue')
	grid_shader:setFloat("blue", shaderBlue)
	shaderOpacity = settingsGroupShader:get('shaderOpacity')
	grid_shader:setFloat("lineOpacity", shaderOpacity)
	shaderThickness = settingsGroupShader:get('shaderThickness')
	grid_shader:setFloat("lineThickness", shaderThickness)
	shaderFadeDist = settingsGroupShader:get('shaderFadeDist')
	grid_shader:setFloat("fadeDistance", shaderFadeDist)
end
local function init()
    updateSettings()
end
settingsGroupCell:subscribe(async:callback(updateSettings))
settingsGroupHurt:subscribe(async:callback(updateSettings))
settingsGroupShader:subscribe(async:callback(updateSettings))

-- init.... these should be saved between sessions
local savedLevel = 0 -- track character level at point of last cell unlock to determine when ready to unlock next
local savedSkills = 0 -- track skill total level too...
local cellsToUnlock = 0 -- track number of cells ready to be unlocked
local savedCellX = 0 -- "current" cell coordinates for comparison
local savedCellY = 0
local cellTableX = {} -- table of cell coordinates
local cellTableY = {}
local outOfCell = false -- needed if you load in in an interior
local unlockCell = false -- needed if you load in outside your cell but have unlocks available
-- interior handling, so you can reenter the same interior and be safe, but then leave again and be unsafe
local wasInside = false
local updateSafeInterior = false
local interiorName = ''
local lastSafeInterior = ''
local preInteriorCellX = 0
local preInteriorCellY = 0

-- init variables used in current session only
local checkTime = 0.0
local cycleOnce = false -- white and red pulses should cycle once
local cycleDone = false
local cycleTime = 0.0 -- each pulse will have a different cycle time
local shaderTime = 0.0
local buildString = ''
-- health drain logic
local hurtTime = 0.0
local currentHealthCost = 0
local types = require('openmw.types')
local dynamic = types.Actor.stats.dynamic -- health etc
local skills = types.NPC.stats.skills -- use SkillStat.base 

local function fncSave() -- save what variables need to be saved
	return {
		savedLevel = savedLevel,
		savedSkills = savedSkills,
		cellsToUnlock = cellsToUnlock,
		savedCellX = savedCellX, -- must be saved in case you save in an interior
		savedCellY = savedCellY,
		cellTableX = cellTableX, -- must be saved for continuity
		cellTableY = cellTableY,
		outOfCell = outOfCell,
		unlockCell = unlockCell,
		wasInside = wasInside,
		updateSafeInterior = updateSafeInterior,
		interiorName = interiorName,
		lastSafeInterior = lastSafeInterior,
		preInteriorCellX = preInteriorCellX,
		preInteriorCellY = preInteriorCellY
	}
end

local function fncLoad(data) -- load saved variables
	savedLevel = data.savedLevel
	savedSkills = data.savedSkills
	cellsToUnlock = data.cellsToUnlock
	savedCellX = data.savedCellX
	savedCellY = data.savedCellY
	cellTableX = data.cellTableX
	cellTableY = data.cellTableY
	outOfCell = data.outOfCell
	unlockCell = data.unlockCell
	wasInside = data.wasInside
	updateSafeInterior = data.updateSafeInterior
	interiorName = data.interiorName
	lastSafeInterior = data.lastSafeInterior
	preInteriorCellX = data.preInteriorCellX
	preInteriorCellY = data.preInteriorCellY
end

local function inList() -- check if current cell is already unlocked
	for k,v in pairs(cellTableX) do
	  	if v == savedCellX then
			if cellTableY[k] == savedCellY then
				return true
			end
		end
	end
	return false
end

local function removeCurrentFromList() -- if current cell is unlocked, then remove it
	for k,v in pairs(cellTableX) do
		if v == savedCellX then
		  	if cellTableY[k] == savedCellY then
				table.remove(cellTableX,k)
				table.remove(cellTableY,k)
			  	return true
		  	end
	  end
  end
  return false
end

local function getCharaLevel() -- get PC's current level
	return types.Actor.stats.level(self).current
end

local function getSkillsLevel() -- get sum of PC's current skill levels
	local skillTotal = 0
	skillTotal = skillTotal + skills.acrobatics(self).base
	skillTotal = skillTotal + skills.alchemy(self).base
	skillTotal = skillTotal + skills.alteration(self).base
	skillTotal = skillTotal + skills.armorer(self).base
	skillTotal = skillTotal + skills.athletics(self).base
	skillTotal = skillTotal + skills.axe(self).base
	skillTotal = skillTotal + skills.block(self).base
	skillTotal = skillTotal + skills.bluntweapon(self).base
	skillTotal = skillTotal + skills.conjuration(self).base
	skillTotal = skillTotal + skills.destruction(self).base
	skillTotal = skillTotal + skills.enchant(self).base
	skillTotal = skillTotal + skills.handtohand(self).base
	skillTotal = skillTotal + skills.heavyarmor(self).base
	skillTotal = skillTotal + skills.illusion(self).base
	skillTotal = skillTotal + skills.lightarmor(self).base
	skillTotal = skillTotal + skills.longblade(self).base
	skillTotal = skillTotal + skills.marksman(self).base
	skillTotal = skillTotal + skills.mediumarmor(self).base
	skillTotal = skillTotal + skills.mercantile(self).base
	skillTotal = skillTotal + skills.mysticism(self).base
	skillTotal = skillTotal + skills.restoration(self).base
	skillTotal = skillTotal + skills.security(self).base
	skillTotal = skillTotal + skills.shortblade(self).base
	skillTotal = skillTotal + skills.sneak(self).base
	skillTotal = skillTotal + skills.spear(self).base
	skillTotal = skillTotal + skills.speechcraft(self).base
	skillTotal = skillTotal + skills.unarmored(self).base
	return skillTotal
end

return {
  engineHandlers = { 
    -- init settings
    onActive = init,
	onSave = fncSave,
	onLoad = fncLoad,

    onUpdate = function(dt)
		if enabled then
			if doOnce then
				-- do not proceed further until chargen is done
				-- for 0.49, a better check will be for the first quest's status, inside an ambient block
				if not hasStats and input.getControlSwitch(input.CONTROL_SWITCH.ViewMode) then -- 0.48-compatible check
					hasStats = true
				elseif not hasStats then
					return
				end
				
				if hasStats then
					doOnce = false
					-- enable the grid shader
					grid_shader:enable()
					if (not (modUnlockCount == 0)) or (loseCurrentCell) then -- if manually modifying cell unlocks...
						if not (modUnlockCount == 0) then -- mod unlock count
							ui.showMessage('Modifying unlock count from ' .. tostring(cellsToUnlock) .. ' to ' .. tostring(math.max(0, cellsToUnlock + modUnlockCount) .. '.'))
							cellsToUnlock = math.max(0, cellsToUnlock + modUnlockCount)
							-- revert setting when done
							modUnlockCount = 0
							settingsGroupCell:set('modUnlockCount',0)
						end
						if loseCurrentCell then -- remove current cell from list
							if self.cell.isExterior then
								if removeCurrentFromList() then
									ui.showMessage('Removing current cell (' .. tostring(savedCellX) .. ', ' .. tostring(savedCellY) .. ') from unlock list.')
									ui.showMessage('Prisoner! Return to your cell!') -- show warning again lol
									outOfCell = true
								else
									ui.showMessage('Cannot remove current cell (' .. tostring(savedCellX) .. ', ' .. tostring(savedCellY) .. '), as it is not unlocked.')
								end
							else
								ui.showMessage('Cannot remove current cell while you are in interior.')
							end
							-- revert setting when done
							loseCurrentCell = false
							settingsGroupCell:set('loseCurrentCell',false)
						end
						doOnce = false -- modifying settings group resets this to true because of updateSettings(), so let's set it false again lol
					else -- only show welcome call if not manually modifying cell unlocks
						if ((savedLevel == 0) and (savedSkills == 0)) then -- if this is the very first time this thing's ever been run, display a unique welcome message
							ui.showMessage('Welcome to Cell Locked! If you would like to start in a different cell, please disable the mod for now, and enable it once you reach your desired starting cell.')
						else
							-- build welcome string piece by piece
							buildString = 'Welcome to Cell Locked!'
							-- if you have unlocks pending
							if cellsToUnlock > 0 then
								if cellsToUnlock == 1 then
									buildString = buildString  .. ' 1 cell unlock available.'
								else
									buildString = buildString  .. ' ' .. tostring(cellsToUnlock) .. ' cell unlocks available.'
								end
							end
							-- if you gain unlocks per level
							if (nCellsPerCharaLevel > 0) then
								buildString = buildString  .. ' Next unlock in 1 character level'
								if (nCellsPerSkillLevel > 0.0) then
									buildString = buildString .. ', or'
								else
									buildString = buildString .. '.'
								end
							end
							-- if you gain unlocks for skills
							if (nCellsPerSkillLevel > 0.0) then
								if not (nCellsPerCharaLevel > 0) then
									buildString = buildString  .. ' Next unlock in'
								end
								if (1.0/nCellsPerSkillLevel - (getSkillsLevel() - savedSkills)) == 1 then
									buildString = buildString  .. ' 1 skill level.'
								else
									buildString = buildString  .. ' ' .. tostring(1.0/nCellsPerSkillLevel - (getSkillsLevel() - savedSkills)) .. ' skill levels.'
								end
							end
							-- if you never gain unlocks automatically
							if (nCellsPerSkillLevel == 0.0) and (nCellsPerCharaLevel == 0) then
								buildString = buildString  .. ' No unlocks upcoming due to settings. You are a true prisoner.'
							end
							-- if you have unlocked multiple cells already
							if (#cellTableX > 0) then
								if (#cellTableX == 1) then
									buildString = buildString  .. ' You have unlocked a total of 1 cell.'
								else
									buildString = buildString  .. ' You have unlocked a total of ' .. tostring(#cellTableX) .. ' cells.'
								end
							end
							ui.showMessage(buildString)
						end
					end
				end
				--print(nCellsPerSkillLevel, 1.0/nCellsPerSkillLevel, getSkillsLevel(), savedSkills)
			end

			-- levelling logic
			checkTime = checkTime + dt
			if checkTime > 1.0 then -- check once per second for now
				checkTime = 0.0

				-- hardcoded override setting everything up, first time this is run
				if (savedLevel == 0) and (savedSkills == 0) then
					cellsToUnlock = 1
					savedLevel = getCharaLevel()
					savedSkills = getSkillsLevel()
					ui.showMessage(tostring(cellsToUnlock) .. ' cell unlock(s) available!')
				else
					-- handle character level
					if getCharaLevel() > savedLevel then
						cellsToUnlock = cellsToUnlock + nCellsPerCharaLevel
						savedLevel = getCharaLevel()
						ui.showMessage(tostring(cellsToUnlock) .. ' cell unlock(s) available!')
					end
					-- handle skill levels
					if (getSkillsLevel() - savedSkills)*nCellsPerSkillLevel >= 1.0 then
						cellsToUnlock = cellsToUnlock + 1
						savedSkills = getSkillsLevel()
						ui.showMessage(tostring(cellsToUnlock) .. ' cell unlock(s) available!')
					end
				end

				-- diagnostics
			--	print(getCharaLevel(), savedLevel)
			--	print(getSkillsLevel(), savedSkills)
			--	print('(', self.cell.gridX, ',', self.cell.gridY, ') vs ', savedCellX, ',', savedCellY)
			--	print('level ', savedLevel, ', skills ', savedSkills, '... vs ', cellsToUnlock)
			--	print('status ', outOfCell, ', healthCost ', currentHealthCost)
			end

			-- cell logic
			if self.cell.isExterior then
				if wasInside then -- update last interior cell
					wasInside = false
					if updateSafeInterior then -- if you were safe while inside, then save off this stuff for reference just in case
						updateSafeInterior = false
						lastSafeInterior = interiorName
						preInteriorCellX = savedCellX
						preInteriorCellY = savedCellY
					end
				end
				-- if the player's current cell changes, then 
				if (not ((savedCellX == self.cell.gridX) and (savedCellY == self.cell.gridY))) or (outOfCell and (cellsToUnlock > 0)) then
					-- update current cell
					savedCellX = self.cell.gridX
					savedCellY = self.cell.gridY
					-- check cell logic vs unlocked list
					if inList() then
						if outOfCell then
							outOfCell = false
							ui.showMessage('Safe!')
						end
						if unlockCell then
							unlockCell = false
							ui.showMessage('Unlock cancelled.')
						end
						currentHealthCost = 0
						hurtTime = 0.0 -- don't reset hurtTime on any cell change, as that will allow out-of-cell swap stalling
						-- in cell reset to default
						pulse_shader:setFloat("red", 0.0)
						pulse_shader:setFloat("green", 0.0)
						pulse_shader:setFloat("blue", 0.0)
						pulse_shader:setFloat("lineOpacity", 0.0)
						cycleDone = true
					else
						-- check if they have unlocks available
						if cellsToUnlock > 0 then
							-- unlock cell blue
							pulse_shader:setFloat("red", 0.0)
							pulse_shader:setFloat("green", 1.0)
							pulse_shader:setFloat("blue", 1.0)
							pulse_shader:setFloat("lineOpacity", 0.5)
							cycleDone = false
							cycleOnce = false
							cycleTime = timerVal/3.0 -- 3 pulses before unlocked
							shaderTime = 0.0
						-- if so, trigger mwscript asking them if they want to unlock this cell
						--	cellsToUnlock = cellsToUnlock - 1
						--	ui.showMessage('Unlocking cell (' .. tostring(savedCellX) .. ', ' .. tostring(savedCellY) ..'). ' .. tostring(cellsToUnlock) .. ' cell unlocks available!')
						--	cellTableX[#cellTableX+1] = savedCellX
						--	cellTableY[#cellTableX] = savedCellY -- reference size of cellTableX to ensure both table indices match
							outOfCell = false -- update just to be safe
							-- or... do it after a delay
							unlockCell = true
							ui.showMessage('Preparing to unlock cell (' .. tostring(savedCellX) .. ', ' .. tostring(savedCellY) ..')! ' .. tostring(cellsToUnlock) .. ' cell unlock(s) available.')
						else
							-- out of cell red
							pulse_shader:setFloat("red", 1.0)
							pulse_shader:setFloat("green", 0.0)
							pulse_shader:setFloat("blue", 0.0)
							pulse_shader:setFloat("lineOpacity", 0.5)
							cycleDone = false
							cycleOnce = true
							cycleTime = timerVal
							shaderTime = 0.0
							unlockCell = false -- update just to be safe
							-- if not, trigger warning and check health cost
							if not outOfCell then
								ui.showMessage('Prisoner! Return to your cell!') -- only show on cell change
							end
							outOfCell = true
						end
					end
				end
			else
				interiorName = self.cell.name -- is there a way I can avoid updating this every update?
				if not wasInside then -- if you were outside, then set yourself to inside
					wasInside = true
					if not (outOfCell or unlockCell) then -- and if you were safe, then set yourself to safe
						updateSafeInterior = true
					end
				end
				-- if you were NOT safe, but your current interior matches your last safe interior, then you're good
				if (outOfCell or unlockCell) and (interiorName == lastSafeInterior) then
					-- revert saved cell info
					savedCellX = preInteriorCellX
					savedCellY = preInteriorCellY
					-- copied from "if inList() then"
					if outOfCell then
						outOfCell = false
						ui.showMessage('Safe!')
					end
					if unlockCell then
						unlockCell = false
						ui.showMessage('Unlock cancelled.')
					end
					currentHealthCost = 0
					hurtTime = 0.0 -- don't reset hurtTime on any cell change, as that will allow out-of-cell swap stalling
					-- in cell reset to default
					pulse_shader:setFloat("red", 0.0)
					pulse_shader:setFloat("green", 0.0)
					pulse_shader:setFloat("blue", 0.0)
					pulse_shader:setFloat("lineOpacity", 0.0)
					cycleDone = true
				end
			end

			-- unlock logic
			if unlockCell then
				hurtTime = hurtTime + dt
				if hurtTime > timerVal then -- if enough time has passed
					-- new cell white
						pulse_shader:setFloat("red", 1.0)
						pulse_shader:setFloat("green", 1.0)
						pulse_shader:setFloat("blue", 1.0)
						pulse_shader:setFloat("lineOpacity", 0.5)
						cycleDone = false
						cycleOnce = true
						cycleTime = timerVal
						shaderTime = 0.0
					hurtTime = 0.0
					if self.cell.isExterior then
						cellsToUnlock = cellsToUnlock - 1
						ui.showMessage('Unlocking cell (' .. tostring(savedCellX) .. ', ' .. tostring(savedCellY) ..'). ' .. tostring(cellsToUnlock) .. ' cell unlock(s) remain!')
						cellTableX[#cellTableX+1] = savedCellX
						cellTableY[#cellTableX] = savedCellY -- reference size of cellTableX to ensure both table indices match
					else
						outOfCell = true -- if you reenter an interior to prevent unlocking the cell, then you will be considered outOfCell since you didn't unlock your last entered exterior cell
						ui.showMessage('Unlock cancelled. Prisoner, you are unsafe! Return to your cell or unlock a new one.')
					end
					unlockCell = false -- update to remove condition so it stops trying to unlock more
				end
			end

			-- health logic
			if outOfCell then
				hurtTime = hurtTime + dt
				if hurtTime > timerVal then -- if enough time has passed
					hurtTime = 0.0
					-- update health cost
					if currentHealthCost < 1 then
						currentHealthCost = healthCost
					else
						currentHealthCost = currentHealthCost + healthCostAccel
					end
					-- if health cost positive, then hit health each second
					if math.floor(currentHealthCost) > 0 then
						if ambient then --0.49 check
							ambient.playSound("Health Damage")
						else
							ui.showMessage("Health Damage")
						end
						if not doPercent then
							dynamic.health(self).current = math.max(0,dynamic.health(self).current - math.ceil(currentHealthCost)) -- don't set to below 0					
						else
							dynamic.health(self).current = math.max(0,dynamic.health(self).current - math.ceil(0.01*currentHealthCost*dynamic.health(self).base)) -- don't set to below 0					
						end
					end
				end
			end

			-- shader handler
			if not cycleDone then
				shaderTime = shaderTime + dt
				if shaderTime >= cycleTime then
					shaderTime = 0.0
					if cycleOnce then
						cycleDone = true
						pulse_shader:setFloat("lineOpacity", 0.0)
					end
				end
				pulse_shader:setFloat("cellCycle", shaderTime/cycleTime)
			end

			pulse_shader:setVector3("playerPos", self.position)
		else
			doOnce = true
		end
	end,

	onFrame = function(dt)
		if enabled and outOfCell and (not allowRestWhileHurt) then
			if iui.getMode()=="Rest" then
				iui.removeMode("Rest")
			end
		end
	end,
  }
}