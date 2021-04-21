local effects = require("classStartingSpells.effects")
local spells = require("classStartingSpells.spells")
local class = require("classStartingSpells.classes")
local config

event.register("modConfigReady", function()
    require("classStartingSpells.mcm")
	config  = require("classStartingSpells.config")
end)

local function prepareStartingSpells(e)
	for spell in tes3.iterateObjects(tes3.objectType.spell) do
		spells.removeFromStarting(spell)
	end
	local menu = tes3ui.findMenu(tes3ui.registerID("MenuCreateClass"))
	local playerClass = menu and class.getFromCreationMenu(menu) or tes3.player.baseObject.class
	class.addSpells(playerClass)
end	

--[[ Schema:
MenuClassChoice:

MenuClassMessage - MenuClassMessage_cancel_button (sic!)
MenuChooseClass - MenuChooseClass_Okbutton - -32588
MenuCreateClass - MenuCreateClass_Okbutton

local menu = e.element
button = menu.name .. "_Okbutton"
button = menu:findChild(tes3ui.registerID(button))
tes3.messageBox(button.name)
button:unregister("mouseClick", prepareStartingSpells)
button:register("mouseClick", prepareStartingSpells)

]]

local function registerMouseButton(e)
	event.unregister("mouseButtonDown", prepareStartingSpells)
	event.register("mouseButtonDown", prepareStartingSpells)
	timer.delayOneFrame(
		function()
			event.unregister("mouseButtonDown", prepareStartingSpells)
			spells.fixFortifyAttribute()
		end
	)
end

local function initialized(e)
	if config.modEnabled then
		class.crusaderFix()
		tes3.findGMST(tes3.gmst.fAutoPCSpellChance).value = 0
		event.register("uiActivated", prepareStartingSpells, {filter = "MenuClassMessage"})
		event.register("uiActivated", registerMouseButton, {filter = "MenuChooseClass"})
		event.register("uiActivated", registerMouseButton, {filter = "MenuRaceSex"})
		--event.register("uiActivated", registerMouseButton, {filter = "MenuBirthSign"})
		event.register("uiActivated", registerMouseButton, {filter = "MenuCreateClass"})
		mwse.log("[Class Starting Spells: Enabled]")
	else
		mwse.log("[Class Starting Spells: Disabled]")
	end
end

event.register("initialized", initialized)