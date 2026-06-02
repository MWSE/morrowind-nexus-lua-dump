core  = require('openmw.core')
self  = require('openmw.self')
types = require('openmw.types')
async = require('openmw.async')
I     = require('openmw.interfaces')
ui    = require('openmw.ui')
util  = require('openmw.util')
time  = require('openmw_aux.time')

MODNAME = "Jewelcrafting"
saveData = {}

G_skillId         = "jewelcrafting"
G_skillStat       = nil
G_hasSimplyMining = core.contentFiles.has("SimplyMining.omwscripts")
G_testBoost       = 1

G_eventHandlers = {}
-- .openCraftingUI (ralts)
-- .gemMiningProgress (mining)
-- .fallbackActivation (mining)
-- .notifyGemFound (mining)
-- .UiModeChanged (unlocking)

G_engineHandlers = {}
-- .onConsoleCommand (ralts)
-- .onQuestUpdate (unlocking)

G_onActiveJobs = {}
-- [1] = ralts
-- [#] = unlocking

G_onLoadJobs = {}
-- unlocking
-- mining

require("scripts.Jewelcrafting.JC_gems") -- builds G_gems
require("scripts.Jewelcrafting.JC_ralts")
require("scripts.Jewelcrafting.JC_mining")
require("scripts.Jewelcrafting.JC_unlocking")

G_engineHandlers.onLoad = function(data)
	saveData = data or {}
	for _, job in pairs(G_onLoadJobs) do job(data) end
end
G_engineHandlers.onInit = G_engineHandlers.onLoad
G_engineHandlers.onSave = function() return saveData end
G_engineHandlers.onActive = function()
	for _, job in pairs(G_onActiveJobs) do job() end
end

G_eventHandlers.Test_toggleBoost = function(val) G_testBoost = val end

-- inventory extender
async:newUnsavableSimulationTimer(0.5, function()
	if not I.InventoryExtender then return end
	local BASE = I.InventoryExtender.Templates.BASE
	local constants = I.InventoryExtender.Constants
	local labelColor = (constants and constants.Colors and constants.Colors.DISABLED) or util.color.rgb(0.6, 0.6, 0.6)
	I.InventoryExtender.registerTooltipModifier("Jewelcrafting_Tooltips", function(item, layout)
		local rid = item.recordId:lower()
		local text
		if rid == "jc_pliers_common" then
			text = "A tool used to craft jewelry\nsuch as rings and amulets."
		elseif rid:sub(1, 6) == "jc_rs_" then
			text = "A jewelcrafting recipe.\nDestroyed after reading."
		else
			return layout
		end
		local ok, content = pcall(function() return layout.content[1].content[1].content end)
		if not ok or not content then return layout end
		content:add(BASE.intervalV(8))
		content:add({ template = I.MWUI.templates.horizontalLine, props = { size = util.vector2(200, 2) } })
		content:add(BASE.intervalV(4))
		content:add({
			template = BASE.textNormal,
			props = {
				text = text,
				textColor = labelColor,
				multiline = true,
				textAlignH = ui.ALIGNMENT.Center,
			},
		})
		return layout
	end)
end)

return {
	engineHandlers = G_engineHandlers,
	eventHandlers  = G_eventHandlers,
}