--[[
	New Game Confirmation
	v1.02
	by hardek
]]--

-- Start a new game when Yes is pressed, and do nothing when No is pressed
local function onNGButtonClicked()
	tes3.worldController.menuClickSound:play()
	tes3.messageBox({
		message = "Do you want to start a new game?",
		buttons = { tes3.findGMST(tes3.gmst.sYes).value, tes3.findGMST(tes3.gmst.sNo).value },
		callback = function(e)
			if (e.button == 0) then
				mwse.log("[New Game Confirmation] Starting new game after confirmation.")
				tes3.newGame()
			end
		end
	})
end

-- When the UI is created, change the new game button's behavior.
local function rebindNGButton(e)
	-- Try to find the main menu New Game button
	local NGButton = e.element:findChild(tes3ui.registerID("MenuOptions_New_container"))
	if (NGButton == nil) then
		mwse.log("[New Game Confirmation] Error: couldn't find new game button UI element.")
		return
	end
	-- Set our new event handler.
	if tes3.onMainMenu() then
		NGButton:register("mouseClick", onNGButtonClicked)
	end
end
event.register("uiCreated", rebindNGButton, { filter = "MenuOptions" })

-- Show initialization event in the log.
local function onInitialized()
	mwse.log("[New Game Confirmation] Mod initialized.")
end
event.register("initialized", onInitialized)
