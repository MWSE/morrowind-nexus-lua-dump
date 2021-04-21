-- Instantload- hold the instant load key during start up or on the main menu to immediately load the specified save.
--local instantLoad = "quiksave.ess"
--local instantLoadKey = tes3.scanCode.z

local config = mwse.loadConfig("pg_continue_config")
if not config then
	config = {
		hideCredits = false,
		hideNewGame = false,
	}
end

local menu_continue_id = tes3ui.registerID("Pete_ContinueButton")
local menu_id = tes3ui.registerID("MenuOptions")
local menu_new_id = tes3ui.registerID("MenuOptions_New_container")
local menu_credits_id = tes3ui.registerID("MenuOptions_Credits_container")
local load_menu_id = tes3ui.registerID("MenuLoad")
local load_cancelButton_id = tes3ui.registerID("MenuLoad_Okbutton")


--Stolen (and modified) from Sophisticated Save System. Thank you NullCascade!
--https://github.com/NullCascade/morrowind-mods/blob/master/Data%20Files/MWSE/lua/nc/save/mod_init.lua
-- Modified so only one value is returned- the FILENAME of the latest save.
local function getNewestSaveFile()
	local newestSave = nil
	local newestTimestamp = 0
	for file in lfs.dir("saves") do
		if string.endswith(file, ".ess") then
			-- Check to see if the file is newer than our current newest file.
			local lastModified = lfs.attributes("saves/" .. file, "modification")
			if lastModified > newestTimestamp then
				newestSave = file
				newestTimestamp = lastModified;
			end
		end
	end

	if newestSave ~= nil then
		-- Return the whole filename, including extension.
		return newestSave
	end
end

local function saveFileExists(save)
	for file in lfs.dir("saves") do
		if file == save then
			return true
		end
	end

	return false
end


-- Instantly load a save for testing.
local function checkInstantLoad(e)
	if saveFileExists(instantLoad) then
		tes3.loadGame(instantLoad)
	end
end
event.register("key", checkInstantLoad, {filter = instantLoadKey})

local function onMenuMessage(e)
	local mainMenu = tes3ui.findMenu(tes3ui.registerID("MenuOptions"))
	if (mainMenu) then
		mainMenu.visible = true
	end
	event.unregister("uiActivated", onMenuMessage, {filter = "MenuMessage"})
end

local function onLoaded(e)
	event.unregister("key", checkInstantLoad, {filter = instantLoadKey})
end
event.register("loaded", onLoaded)

local function onClickContinueButton(e)
	-- Hide the main menu, or it flickers during the load screen.
	local mainMenu = tes3ui.findMenu(tes3ui.registerID("MenuOptions"))
	mainMenu.visible = false

	-- Prepare to show the menu again if a dialog pops up, and the user cancels loading.
	event.register("uiActivated", onMenuMessage, {filter = "MenuMessage", doOnce = true})

	-- We don't error check here, since the button doesn't show up without a save file.
	-- If a user deletes their save after starting the game, they deserve a crash. But they won't be able to.
	timer.frame.delayOneFrame(function (e)
		tes3.loadGame(getNewestSaveFile())
	end)
	-- We also delay one frame before loading, to prevent weird input behaviour (eg. this callback being called repeatedly)
end

local function onCreatedMenuOptions(e)
	if not e.newlyCreated then
		return
	end

	local mainMenu = e.element

	-- Don't show the continue button in game, only at the main menu.
	if not tes3.onMainMenu() then
		if config.hideNewGame and tes3.mobilePlayer.health.current > 0 then
			mainMenu:findChild(menu_new_id).visible = not config.hideNewGame
		end
		return
	end

	--Optionally hide the credits button so we bloat the menu a little less.
	local creditsButton = mainMenu:findChild(menu_credits_id)
	creditsButton.visible = not config.hideCredits

	if getNewestSaveFile() == nil then
		return
	end

	local newGameButton = mainMenu:findChild(menu_new_id)
	local buttonContainer = newGameButton.parent

	local button = buttonContainer:createImageButton({
		id = menu_continue_id,
		idle = "textures/menu_continue.dds",
		over = "textures/menu_continue_over.dds",
		pressed = "textures/menu_continue_pressed.dds",
	})
	button.height = 50
	button.autoHeight = false
	button:register("mouseClick", onClickContinueButton)

	buttonContainer:reorderChildren(newGameButton, button, -1)

	mainMenu.autoWidth = true
	mainMenu.autoHeight = true

	mainMenu:updateLayout()
end
event.register("uiActivated", onCreatedMenuOptions, { filter = "MenuOptions" })

-- Sanity in case some asshole deletes all their saves and wants to continue.
local function onCreatedMenuLoad(e)
	local cancelButton = e.element:findChild(load_cancelButton_id)
	cancelButton:register("mouseClick", function(e)
		if getNewestSaveFile() == nil then
			local menu = tes3ui.findMenu(menu_id)
			if (menu) then
				local continue = menu:findChild(menu_continue_id)
				if (continue) then
					continue.visible = false
				end
			end
		end
		e.source:forwardEvent(e)
	end)
end
event.register("uiActivated", onCreatedMenuLoad, { filter = "MenuLoad" })

--ModConfig
local modConfig = {}

function modConfig.onCreate(container)
	local pane = container:createThinBorder{}
	pane.widthProportional = 1.0
	pane.heightProportional = 1.0
	pane.paddingAllSides = 12
	pane.flowDirection = "top_to_bottom"

	local header = pane:createLabel{ text = "Continue\nversion 1.6" }
	header.color = tes3ui.getPalette("header_color")
	header.borderBottom = 25

	-- Description and credits

	local txtBlock = pane:createBlock()
	txtBlock.widthProportional = 1.0
	txtBlock.autoHeight = true
	txtBlock.borderBottom = 25

	local txt = txtBlock:createLabel{}
	txt.wrapText = true
	txt.text = "Adds a Continue button to the main menu, which will load the most recent save game. Can optionally hide the Credits button to prevent menu bloat.\n\nSpecial thanks to NullCascade, Melchior Dahrk, Greatness7, and qqqbbb.\n\nCreated by Petethegoat."

	-- Hide Credits

	local creditsBlock = pane:createBlock()
	creditsBlock.flowDirection = "left_to_right"
	creditsBlock.widthProportional = 1.0
	creditsBlock.autoHeight = true

	creditsBlock:createLabel({ text = "Hide Credits Button:" })

	local creditsButton = creditsBlock:createButton({ text = config.hideCredits and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value })
	creditsButton.absolutePosAlignX = 1.0
	creditsButton.paddingTop = 2
	creditsButton.borderRight = 6
	creditsButton:register("mouseClick", function(e)
		config.hideCredits = not config.hideCredits
		creditsButton.text = config.hideCredits and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value
	end)

	-- Hide New Game

	hideBlock = pane:createBlock()
	hideBlock.flowDirection = "left_to_right"
	hideBlock.widthProportional = 1.0
	hideBlock.autoHeight = true

	hideBlock:createLabel({ text = "Hide New Game Button (In Game):" })

	hideButton = hideBlock:createButton({ text = config.hideNewGame and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value })
	hideButton.absolutePosAlignX = 1.0
	hideButton.paddingTop = 2
	hideButton.borderRight = 6
	hideButton:register("mouseClick", function(e)
		config.hideNewGame = not config.hideNewGame
		hideButton.text = config.hideNewGame and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value
	end)

	pane:updateLayout()
end

function modConfig.onClose(container)
	mwse.saveConfig("pg_continue_config", config, { indent = true })

	if tes3.onMainMenu() then
		-- Make sure we update the credits button visiblity.
		local mainMenu = tes3ui.findMenu(tes3ui.registerID("MenuOptions"))
		local creditsButton = mainMenu:findChild(menu_credits_id)
		creditsButton.visible = not config.hideCredits
	end
end

local function registerModConfig()
	mwse.registerModConfig("Continue", modConfig)
end
event.register("modConfigReady", registerModConfig)