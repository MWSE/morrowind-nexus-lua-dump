--[[this looks hacky and dumb, but my goal was to avoid player button presses. all the menus are
 clicked on through, and then there's a save/load because otherwise you'd have dunmer 1st-person hands
until you saved yourself. and again, i wanted no work on the player's part.]]--

local config = require("OEA.OEA10 Fresh.config")

local function BirthEnter(e)
	if (config.AltStart == false) then
		return
	end

	local menu = tes3ui.findMenu(tes3ui.registerID("MenuBirthSign"))
	if (menu == nil) then
		return
	end

	local child = menu:findChild(tes3ui.registerID("MenuBirthSign_Okbutton"))
	if (child == nil) then
		return
	end

	tes3ui.enterMenuMode(menu)
	child:triggerEvent("mouseClick")
	timer.start({ duration = 0.5, type = timer.real, callback = 
		function()
			local Magic = tes3ui.findMenu(tes3ui.registerID("MenuMagic"))
			local Map = tes3ui.findMenu(tes3ui.registerID("MenuMap"))
			local Stuff = tes3ui.findMenu(tes3ui.registerID("MenuInventory"))
			local Stat = tes3ui.findMenu(tes3ui.registerID("MenuStat"))

			Magic:destroy()
			Map:destroy()
			Stuff:destroy()
			Stat:destroy()
			tes3ui.leaveMenuMode(Stat)
			tes3.saveGame({ file = "fargothaltstart", name = "Fargoth Start Save" })
			timer.start({ duration = 2, type = timer.real, callback = 
				function()
					tes3.loadGame({ filename = "fargothaltstart.ess" })
				end
			})
		end
	})
end

local function ClassEnter(e)
	if (config.AltStart == nil) then
		return
	end

	local menu = e.element
	if (menu == nil) then
		return
	end

	local child = menu:findChild(tes3ui.registerID("MenuChooseClass_Okbutton"))
	if (child == nil) then
		return
	end

	child:triggerEvent("mouseClick")

	timer.start({ duration = 0.5, type = timer.real, callback = 
		function()
			tes3.runLegacyScript({ command = "EnableBirthMenu" })
		end
	})
end

local function ClassChoiceEnter(e)
	if (config.AltStart == nil) then
		return
	end

	local menu = e.element
	if (menu == nil) then
		return
	end

	local child = menu:findChild(tes3ui.registerID("MenuClassChoice_PickClassbutton"))
	if (child == nil) then
		return
	end

	child:triggerEvent("mouseClick")
end

local function Object(e)
	if (config.AltStart == false) then
		return
	end

	local menu = tes3ui.findMenu(tes3ui.registerID("MenuRaceSex"))
	if (menu == nil) then
		return
	end

	local child = menu:findChild(tes3ui.registerID("MenuRaceSex_Okbutton"))
	if (child == nil) then
		return
	end

	tes3ui.enterMenuMode(menu)
	child:triggerEvent("mouseClick")
	timer.start({ duration = 0.5, type = timer.real, callback = 
		function()
			tes3.runLegacyScript({ command = "EnableClassMenu" })
		end
	})
end

event.register("uiActivated", BirthEnter, { filter = "MenuBirthSign" })
event.register("uiActivated", ClassEnter, { filter = "MenuChooseClass" })
event.register("uiActivated", ClassChoiceEnter, { filter = "MenuClassChoice" })
event.register("uiObjectTooltip", Object)