--[[
	Mod Initialization: BlueMagic
	Version 1.0
	Author: mort
	       
	Blue Magic - Learn spells by observing them
]] --

local config = require("BlueMagic.config")

-- Ensure that the player has the necessary MWSE version.
if (mwse.buildDate == nil or mwse.buildDate < 20260105) then
	mwse.log("[Blue Magic] Build date of %s does not meet minimum build date of 2026-01-05.", mwse.buildDate)
	event.register(
		"initialized",
		function()
			tes3.messageBox("Blue Magic requires a newer version of MWSE. Please run MWSE-Update.exe.")
		end
	)
	return
end

-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
    require("BlueMagic.mcm")
end)

-- function to remove starting spells

local function spellCastCallback(e)
	if config.enableBlueMagic == false then
		return
	end
	
	if tes3.player.object.spells:contains(e.source) then
		return
	end
	
	if e.source.castType ~= 0 then
		return
	end
	
	if e.caster.object.objectType == tes3.objectType.npc then
		tes3.addSpell({ reference = tes3.player, spell = e.source})
		tes3.messageBox({ message = "You have learned " ..e.source.name})
	end
	
	if e.caster.object.objectType == tes3.objectType.creature then
		if config.learnCreatureSpells == true then
			tes3.addSpell({ reference = tes3.player, spell = e.source})
		tes3.messageBox({ message = "You have learned " ..e.source.name})
		end
	end
	
end

local function disableSpellOptions(e)
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuDialog"))
	if not menu then return end
	
	if config.enablePurchasingSpells == false then
		local spellButton = menu:findChild(tes3ui.registerID("MenuDialog_service_spells"))
		if spellButton then
			timer.delayOneFrame(function()
				if not spellButton.visible then
					return
				end
				spellButton.visible = false
			end, timer.real)
		end
	end

	if config.enableCraftingSpells == false then
		local spellmakingButton = menu:findChild(tes3ui.registerID("MenuDialog_service_spellmaking"))
		if spellmakingButton then
			timer.delayOneFrame(function()
				if not spellmakingButton.visible then
					return
				end
				spellmakingButton.visible = false
			end, timer.real)
		end
	end
end

local function keepDisablingSpellOptions(e)
	local menu = tes3ui.findMenu(tes3ui.registerID("MenuDialog"))
	if not menu then return end
	
	if config.enablePurchasingSpells == false then
		local spellButton = menu:findChild(tes3ui.registerID("MenuDialog_service_spells"))
		if spellButton then
			spellButton.visible = false
		end
	end

	if config.enableCraftingSpells == false then
		local spellmakingButton = menu:findChild(tes3ui.registerID("MenuDialog_service_spellmaking"))
		if spellmakingButton then
			spellmakingButton.visible = false
		end
	end
end

local function removeStartingSpells(e)
	if config.removeStartingSpells == false then
		return
	end
	
	local spellsToRemove = {}
	
	for index, spell in pairs(tes3.player.object.spells) do
		if spell.castType == tes3.spellType.spell then
			table.insert(spellsToRemove, spell)
		end
	end
	
	for _, spell in ipairs(spellsToRemove) do
		tes3.removeSpell({ reference = tes3.player, spell = spell})
	end
end	

local function onInitialized()
	event.register(tes3.event.uiActivated, removeStartingSpells, {filter = "MenuStatReview"})
	event.register(tes3.event.uiActivated, disableSpellOptions, { filter = "MenuDialog" })
	event.register(tes3.event.dialogueFiltered, keepDisablingSpellOptions)
	event.register(tes3.event.spellCast, spellCastCallback)
	
	mwse.log("[Blue Magic] Initialized")
end
event.register("initialized", onInitialized)