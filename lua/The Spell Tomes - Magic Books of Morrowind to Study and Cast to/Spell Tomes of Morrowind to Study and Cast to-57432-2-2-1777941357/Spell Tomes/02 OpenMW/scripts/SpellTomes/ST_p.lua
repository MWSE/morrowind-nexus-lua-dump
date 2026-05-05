local types = require('openmw.types')
local self = require('openmw.self')
local core = require('openmw.core')
local time = require('openmw_aux.time')
local ui = require('openmw.ui')
local util = require('openmw.util')
local ambient = require('openmw.ambient')
local v2 = util.vector2
I = require('openmw.interfaces')
storage = require('openmw.storage')
async = require('openmw.async')
 
require("scripts.SpellTomes.ST_database")
 
MOD_NAME = "SpellTomes"
S = {} -- settings cache
local S = S
require("scripts.SpellTomes.ST_settings")
 
-- registerSpellTome(def) and defs from SpellTomes/*.lua
require("scripts.SpellTomes.ST_api")

-- merits of service interop. self-disables if mos isn't loaded.
require("scripts.SpellTomes.ST_merits")
 
local currentCell
local stopTimer
 
local skills = {
	alteration = 0,
	conjuration = 0,
	destruction = 0,
	illusion = 0,
	mysticism = 0,
	restoration = 0,
}
 
local function convertJob()
	if self.cell then
		if not currentCell or self.cell.id ~= currentCell.id then
			core.sendGlobalEvent("SpellTomes_convertBooksInCell", {
				player = self,
			})
			currentCell = self.cell
		end
	end
	-- skill change: re-register to rebuild the cast-chance pool
	for skill, level in pairs(skills) do
		local newLevel = types.NPC.stats.skills[skill](self).modified
		if level ~= newLevel then
			skills[skill] = newLevel
			core.sendGlobalEvent("SpellTomes_registerPlayer", {
				player = self,
			})
		end
	end
end
 
local function onLoad(data)
	core.sendGlobalEvent("SpellTomes_registerPlayer", {
		player = self,
	})
	currentCell = nil
	stopTimer = time.runRepeatedly(convertJob, 0.489 * time.second, { -- do we need a timer?
		type = time.SimulationTime,
		initialDelay = 0.489 * time.second,
	})
end
 
-- inventory extender tooltip
async:newUnsavableSimulationTimer(0.5, function()
	if not I.InventoryExtender then
		return
	end
	
	local BASE = I.InventoryExtender.Templates.BASE
	
	-- Tooltip colors
	local COLORS = {
		MAGIC = util.color.rgb(0.7, 0.5, 0.9),
		KNOWN = util.color.rgb(0.5, 0.9, 0.5),
		UNREAD = util.color.rgb(0.8, 0.3, 0.3),
	}
	
	I.InventoryExtender.registerTooltipModifier("SpellTomes_Books", function(item, layout)
		local spellId = spellTomes[item.recordId]
		if not spellId then return layout end
		spellId = spellId:lower()
		
		local spellRecord = core.magic.spells.records[spellId]
		if not spellRecord then return layout end
		
		local ok, content = pcall(function()
			return layout.content[1].content[1].content
		end)
		if not ok or not content then return layout end
		
		content:add(BASE.intervalV(8))
		content:add({
			template = I.MWUI.templates.horizontalLine,
			props = { size = v2(200, 2) },
		})
		content:add(BASE.intervalV(4))
		
		-- teaches x spell
		content:add({
			template = BASE.textNormal,
			props = {
				text = "Teaches the spell " .. spellRecord.name .. ".",
				textColor = COLORS.MAGIC,
				multiline = true,
				textAlignH = ui.ALIGNMENT.Center,
			},
		})
		
		content:add(BASE.intervalV(2))
		
		-- known / unread indicator
		local known = false
		for _, spell in pairs(types.Player.spells(self)) do
			if spell.id == spellId then
				known = true
				break
			end
		end
		content:add({
			template = BASE.textNormal,
			props = {
				text = known and "Known" or "Unread",
				textColor = known and COLORS.KNOWN or COLORS.UNREAD,
				multiline = true,
				textAlignH = ui.ALIGNMENT.Center,
			},
		})
		
		return layout
	end)
end)
 
-- learning tomes without mwscript
local function playerKnowsSpell(spellId)
	for _, spell in pairs(types.Player.spells(self)) do
		if spell.id == spellId then return true end
	end
	return false
end
 
-- needs to really be fixed up
local function teachSpellTome(tomeId)
	tomeId = tomeId:lower()
	local spellId = spellTomes[tomeId]
	if not spellId then return end
	if playerKnowsSpell(spellId) then return end
	
	types.Player.spells(self):add(spellId)
	
	local def = registeredTomes[tomeId]
	local spellRecord = core.magic.spells.records[spellId]
	local spellName = spellRecord and spellRecord.name or spellId
	
	local message = (def and def.learnedMessage) or ("You have learned the spell " .. spellName .. ".")
	ui.showMessage(message)
	
	if def and def.learnedSoundFile then
		ambient.playSoundFile(def.learnedSoundFile)
	else
		ambient.playSound((def and def.learnedSound) or "skillraise")
	end
	
	if def and def.onLearned then
		local ok, err = pcall(def.onLearned, self, spellId)
		if not ok then
			print("SpellTomes: onLearned callback failed for '"..tomeId.."': "..tostring(err))
		end
	end
end
 
local function UiModeChanged(data)
	local currentUiMode = data.newMode
	if (currentUiMode == "Book" or currentUiMode == "Scroll") and data.arg then
		local tomeId = data.arg.recordId and data.arg.recordId:lower()
		if not tomeId then return end
		local def = registeredTomes[tomeId]
		if def and def.learnTrigger ~= "read" then return end
		teachSpellTome(tomeId)
	end
end
 
-- from the global script's book activation handler
local function SpellTomes_activateLearn(data)
	if data and data.tomeId then
		teachSpellTome(data.tomeId)
	end
end
 
local API = {
	version = 1,
	registerTome = function(def) -- forwards defs to global script
		local result = registerSpellTome(def)
		if result then
			core.sendGlobalEvent("SpellTomes_registerTome", result)
		end
		return result
	end,
	getTome = function(tomeId)
		return registeredTomes[tomeId:lower()]
	end,
	teach = teachSpellTome,
}
 
return {
	interfaceName = "SpellTomes",
	interface = API,
	engineHandlers = {
		onLoad = onLoad,
		onInit = onLoad,
	},
	eventHandlers = {
		UiModeChanged = UiModeChanged,
		SpellTomes_activateLearn = SpellTomes_activateLearn,
	},
}