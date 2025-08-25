local ui = require('openmw.ui')
I = require("openmw.interfaces")
async = require('openmw.async')
local time = require('openmw_aux.time')
local core = require("openmw.core")
local types = require('openmw.types')
local self = require('openmw.self')
local storage = require('openmw.storage')
local skills = require('openmw.types').NPC.stats.skills
local attributes = require('openmw.types').Actor.stats.attributes
MOD_NAME = "AbiliesAreModifiers"
playerSection = storage.playerSection("Settings"..MOD_NAME)
require("scripts.AbilitiesAreModifiers.AAM_settings")
ENABLED = playerSection:get("ENABLED")
NCGD = core.contentFiles.has("ncgdmw.omwscripts")

local function dbg(...)
	if playerSection:get("DEBUG") then
		print(...)
	end
end

local function warn(...)
	if playerSection:get("WARNINGS") then
		print(...)
	end
end

function undoAdjustments()
	dbg("Undoing adjustments...")
	
	for skill, adjustment in pairs(saveData.skillAdjustments or {}) do
		local stat = skills[skill](self)
		local baseBefore = stat.base
		local modifierBefore = stat.modifier
		stat.base = stat.base + adjustment
		stat.modifier = stat.modifier - adjustment
		dbg(skill..": "..baseBefore.."+"..modifierBefore.." -> "..stat.base.."+"..stat.modifier)
	end
	
	for attr, adjustment in pairs(saveData.attributeAdjustments or {}) do
		local stat = attributes[attr](self)
		local baseBefore = stat.base
		local modifierBefore = stat.modifier
		stat.base = stat.base + adjustment
		stat.modifier = stat.modifier - adjustment
		dbg(attr..": "..baseBefore.."+"..modifierBefore.." -> "..stat.base.."+"..stat.modifier)
	end
	
	saveData.skillAdjustments = {}
	saveData.attributeAdjustments = {}
end


function handleAbilityBuffs()
	if not ENABLED then
		return
	end
	
	local skillBuffs = {}
	local attributeBuffs = {}
	
	for spellInstance, spellData in pairs(types.Actor.activeSpells(self)) do
		if spellData.affectsBaseValues then

			for effectIndex, effect in pairs(spellData.effects) do
				if effect.id == "fortifyattribute" and not NCGD then
					local attr = effect.affectedAttribute
					if attr and attr ~= "endurance" then
						attributeBuffs[attr] = (attributeBuffs[attr] or 0) + effect.magnitudeThisFrame
						dbg(spellData.id..": "..attr.." +"..effect.magnitudeThisFrame)
					end
				elseif effect.id == "fortifyskill" then
					local skill = effect.affectedSkill
					if skill then
						skillBuffs[skill] = (skillBuffs[skill] or 0) + effect.magnitudeThisFrame
						dbg(spellData.id..": "..skill.." +"..effect.magnitudeThisFrame)
					end
				end
			end
		end
	end
	for skill in pairs(saveData.skillAdjustments) do
		skillBuffs[skill] = skillBuffs[skill] or 0
	end
	for attr in pairs(saveData.attributeAdjustments) do
		attributeBuffs[attr] = attributeBuffs[attr] or 0
	end
	
	
	for skill, buffMagnitude in pairs(skillBuffs) do
		local stat = skills[skill](self)
		local currentAdjustment = saveData.skillAdjustments[skill] or 0
		local neededAdjustment = buffMagnitude
		
		if currentAdjustment ~= neededAdjustment then
			local adjustmentDelta = neededAdjustment - currentAdjustment
			
			local baseBefore = stat.base
			local modifierBefore = stat.modifier
			if modifierBefore < currentAdjustment then
				warn("WARNING ::: WARNING ::: WARNING ::: AbilitiesAreModifiers ::: ERROR")
				warn(skill, currentAdjustment, modifierBefore)
				warn("WARNING")
				warn("WARNING")
				ui.showMessage("AbilitiesAreModifiers ERROR")
				ui.showMessage(skill..", "..currentAdjustment..", "..modifierBefore)
			end
			
			stat.base = baseBefore - adjustmentDelta
			stat.modifier = modifierBefore + adjustmentDelta
			
			saveData.skillAdjustments[skill] = neededAdjustment
			
			dbg(skill..": "..baseBefore.."+"..modifierBefore.." -> "..stat.base.."+"..stat.modifier)
		end
	end
	
	for attr, buffMagnitude in pairs(attributeBuffs) do
		local stat = attributes[attr](self)
		local currentAdjustment = saveData.attributeAdjustments[attr] or 0
		local neededAdjustment = buffMagnitude
		
		if currentAdjustment ~= neededAdjustment then
			local adjustmentDelta = neededAdjustment - currentAdjustment
			
			local baseBefore = stat.base
			local modifierBefore = stat.modifier
			if modifierBefore < currentAdjustment then
				warn("WARNING ::: WARNING ::: WARNING ::: AbilitiesAreModifiers ::: ERROR")
				warn(attr, currentAdjustment, modifierBefore)
				warn("WARNING")
				warn("WARNING")
				ui.showMessage("AbilitiesAreModifiers ERROR")
				ui.showMessage(attr..", "..currentAdjustment..", "..modifierBefore)
			end
			
			stat.base = baseBefore - adjustmentDelta
			stat.modifier = modifierBefore + adjustmentDelta
			
			saveData.attributeAdjustments[attr] = neededAdjustment
			
			dbg(attr..": "..baseBefore.."+"..modifierBefore.." -> "..stat.base.."+"..stat.modifier)
		end
	end
end



local activeSpellCount = 0
local function getActiveSpellCount()
	local count = 0
	for _, sp in pairs(types.Actor.activeSpells(self)) do
		if sp.affectsBaseValues then
			count = count + 1
		end
	end
	return count
end


local function onFrame(dt)
	--if dt == 0 then return end
	
	local currentSpellCount = getActiveSpellCount()
	if currentSpellCount ~= activeSpellCount then
		activeSpellCount = currentSpellCount
		handleAbilityBuffs()
	end
end


local function onLoad(data)
	if not data then 
		dbg("Initializing AbiliesAreModifiers...") 
	end
	saveData = data or {}
	saveData.skillAdjustments = saveData.skillAdjustments or {}
	saveData.attributeAdjustments = saveData.attributeAdjustments or {}
	
	handleAbilityBuffs()
	activeSpellCount = getActiveSpellCount()
	
	stopTimerFn = time.runRepeatedly(onFrame, 10 * time.second, {
		type = time.SimulationTime,
		initialDelay = 10 * time.second
	})
end


local function onSave()
	return saveData
end

return {
	engineHandlers = {
		--onFrame = onFrame,
		onInit = onLoad,
		onLoad = onLoad,
		onSave = onSave,
	}
}