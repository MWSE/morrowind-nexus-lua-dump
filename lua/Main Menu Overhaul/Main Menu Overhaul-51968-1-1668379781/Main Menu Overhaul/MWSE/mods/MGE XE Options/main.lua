local gui = require("MGE XE Options.gui")

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
	
	local B = PAR:createFillBar{current = mwse.getVirtualMemoryUsage()/1024/1024, max = 4000}	B.width = 200	B.height = 20	B.borderTop = 20	local BW = B.widget		local N = BW.normalized		BW.fillColor = {N*2, 2-N*2, 0}
	B:register("help", function() tes3ui.createTooltipMenu():createLabel{text = "Memory usage"} end)

	MM:findChild("MenuOptions_Exit_container"):register("mouseClick", function() mwse.log("Forcing exit!")	os.exit() end)
	MM.autoWidth = true		MM.autoHeight = true		MM:updateLayout()
end end		event.register("uiActivated", onCreatedMenuOptions, {filter = "MenuOptions"})


local function addGammaResetButton(e) if e.newlyCreated then	local gamma = e.element:findChild("MenuVideo_GamaSlider")	if gamma then
	local r = gamma.parent:createButton{id = "MGE-XE:ResetGamma", text = "Reset"}		r.absolutePosAlignX = 1		r.absolutePosAlignY = 0.38
	r:register("mouseClick", function(e) gamma.widget.current = 50	gamma:triggerEvent("PartScrollBar_changed")		gamma:getTopLevelMenu():updateLayout() end)
	gamma:getTopLevelMenu():updateLayout()
end end end		event.register(tes3.event.uiActivated, addGammaResetButton, {filter = "MenuVideo"})


local function onInitialized(mod)
	gui.i18n = mwse.loadTranslations("MGE XE Options")
end
event.register("initialized", onInitialized)