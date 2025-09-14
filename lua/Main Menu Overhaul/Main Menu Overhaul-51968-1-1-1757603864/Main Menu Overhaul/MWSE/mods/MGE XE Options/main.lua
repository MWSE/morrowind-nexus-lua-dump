local gui = require("Main Menu.gui")		gui.i18n = mwse.loadTranslations("Main Menu")
local cf = mwse.loadConfig("Main Menu", {})

local function onCreatedMenuOptions(e) if e.newlyCreated then		local MM = e.element	local PAR = MM:findChild("MenuOptions_New_container").parent
	local BMGE = PAR:createImageButton{id = tes3ui.registerID("MGE_Button"), idle = "textures/menu_options.dds", over = "textures/menu_options_over.dds", pressed = "textures/menu_options_pressed.dds"}
	BMGE.height = 50	BMGE.autoHeight = false
	BMGE:register("mouseClick", function()
		if not tes3.onMainMenu() then MM.visible = false end
		local mgeMenu = gui.run()		mgeMenu:register("destroy", function() local MOpt = tes3ui.findMenu("MenuOptions")	if MOpt then MOpt.visible = true end end)
	end)
	PAR:reorderChildren(MM:findChild("MenuOptions_Credits_container"), BMGE, 1)

	if tes3.onMainMenu() then	
		local BCON = PAR:createImageButton{id = tes3ui.registerID("Pete_ContinueButton"), idle = "textures/menu_continue.dds", over = "textures/menu_continue_over.dds", pressed = "textures/menu_continue_pressed.dds"}
		BCON.height = 50	BCON.autoHeight = false
		BCON:register("mouseClick", function() timer.frame.delayOneFrame(function()		local Sav, modif	local newest = 0
			for file in lfs.dir("saves") do if string.endswith(file, ".ess") then modif = lfs.attributes("saves/" .. file, "modification")	if modif > newest then Sav = file	newest = modif end end end
			if Sav then MM.visible = false		tes3.loadGame(Sav) end
		end) end)
		PAR:reorderChildren(MM:findChild("MenuOptions_New_container"), BCON, 1)
	else MM:findChild("MenuOptions_New_container").visible = false		MM:findChild("MenuOptions_Credits_container").visible = false end
	
	local B = PAR:createFillBar{current = mwse.getVirtualMemoryUsage()/1024/1024, max = 4000}	B.width = 200	B.height = 20	B.borderTop = 20	local BW = B.widget
	local N = BW.normalized * 4			BW.fillColor = {N-2, 2-math.abs(2-N), 2-N}
	B:findChild("PartFillbar_text_ptr").color = {1,1,1}
	B:register("help", function() tes3ui.createTooltipMenu():createLabel{text = ("Memory usage, %d MB from lua"):format(collectgarbage("count")/1024)} end)

	MM:findChild("MenuOptions_Exit_container"):register("mouseClick", function() mwse.log("Forcing exit!")	os.exit() end)
	
	MM:findChild("MenuOptions_MCM_container"):registerAfter("mouseClick", function() timer.frame.delayOneFrame(function() local El = tes3ui.getMenuOnTop()
		if cf.ModX then El.positionX = cf.ModX		El.positionY = cf.ModY		El.width = cf.ModW		El.height = cf.ModH		El:updateLayout() end
		El:registerBefore("destroy", function(ee) cf.ModX = El.positionX	cf.ModY = El.positionY 	 cf.ModW = El.width		cf.ModH = El.height		mwse.saveConfig("Main Menu", cf) end)
	end) end)
	
	MM.autoWidth = true		MM.autoHeight = true		MM:updateLayout()
end end		event.register("uiActivated", onCreatedMenuOptions, {filter = "MenuOptions"})


local function addGammaResetButton(e) if e.newlyCreated then	local gamma = e.element:findChild("MenuVideo_GamaSlider")	if gamma then
	local r = gamma.parent:createButton{id = "MGE-XE:ResetGamma", text = "Reset"}		r.absolutePosAlignX = 1		r.absolutePosAlignY = 0.38
	r:register("mouseClick", function() gamma.widget.current = 50	gamma:triggerEvent("PartScrollBar_changed")		gamma:getTopLevelMenu():updateLayout() end)
	gamma:getTopLevelMenu():updateLayout()
end end end		event.register(tes3.event.uiActivated, addGammaResetButton, {filter = "MenuVideo"})


mwse.memory.writeBytes{address=0x4BB4EA, bytes={0xEB}}		-- Skip Error: "Could not find correct versions of master file"
mwse.memory.writeBytes{address=0x4C479B, bytes={0xEB}}		-- Skip Error: "Required file has been altered since this file was saved."
mwse.memory.writeBytes{address=0x4C4770, bytes={0xEB}}		-- Skip Error: "Required plugin / master file not found or not currently loaded."
mwse.memory.writeByte{address = 0x4A1B00, byte = 0xEB}		-- Jumps over the error message entirely.	Better Clothes Patch