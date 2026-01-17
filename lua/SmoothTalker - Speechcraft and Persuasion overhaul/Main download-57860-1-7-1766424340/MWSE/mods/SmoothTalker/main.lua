--[[
    Smooth Talker
    Enhanced Persuasion System for Morrowind
	By Pegaz
--]]

local logger = require("logging.logger")
local log = logger.new{
    name = "SmoothTalker",
    logLevel = "WARN",
    logToConsole = false,
    includeTimestamp = true,
}

local vanillaDialog = require("SmoothTalker.vanillaDialog")
local ui = require("SmoothTalker.ui")
local npcParams = require("SmoothTalker.npcParams")

-- ============================================================================
-- EVENT HANDLING
-- ============================================================================

local function onMenuDialog(e)
	local npcRef = e.element:getPropertyObject("PartHyperText_actor").reference
	if npcRef.object.objectType ~= tes3.objectType.npc then
		return
	end

	-- Check and apply decay when opening dialog
	npcParams.checkAndApplyDecay(npcRef)

	-- Find and replace the persuasion button callback
	local persuasionButton = e.element:findChild(tes3ui.registerID("MenuDialog_persuasion"))
	if persuasionButton then
		-- Register before vanilla callback to block it
		persuasionButton:registerBefore("mouseClick", function()
			-- Don't open persuasion menu if there's an active dialogue choice
			if vanillaDialog.hasActiveDialogueChoice() then
				return false
			end

			ui.buildPersuasionMenu(npcRef)
			return false
		end)
	end
	vanillaDialog.updateVanillaBars(npcRef)

    event.register(tes3.event.menuExit, vanillaDialog.exitMenu)
end

local function onSkillRaised(e)
	if e.skill ~= tes3.skill.speechcraft then return end

	-- If the persuasion menu is open, rebuild it to show newly unlocked features
	if ui.isPersuasionMenuOpen() then
		ui.rebuildPersuasionMenu()
	end
end

local function onCellActivated(e)
	-- Apply decay to all NPCs in the newly activated cell
	for ref in e.cell:iterateReferences(tes3.objectType.npc) do
		npcParams.checkAndApplyDecay(ref)
	end
end

local function initialized(e)
	event.register("uiActivated", onMenuDialog, {filter = "MenuDialog"})
	event.register("skillRaised", onSkillRaised)
	event.register("cellActivated", onCellActivated)
	event.register("keyUp", vanillaDialog.checkForCombatNPCs, { filter = tes3.scanCode.space })
	event.register("infoResponse", vanillaDialog.onInfoResponse)
	event.register("postInfoResponse", vanillaDialog.postInfoResponseUpdate)
	event.register("uiObjectTooltip", ui.updateTooltip)
end

event.register("initialized", initialized)

-- Load MCM (Mod Configuration Menu)
require("SmoothTalker.mcm")
