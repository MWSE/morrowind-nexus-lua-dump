--[[---------------------------------------------------------------------------
-------------------------------------------------------------------------------
  _____           _              _      _                     _ 
 |_   _|         | |            | |    | |                   | |
   | |  _ __  ___| |_ __ _ _ __ | |_   | |     ___   __ _  __| |
   | | | '_ \/ __| __/ _` | '_ \| __|  | |    / _ \ / _` |/ _` |
  _| |_| | | \__ \ || (_| | | | | |_   | |___| (_) | (_| | (_| |
 |_____|_| |_|___/\__\__,_|_| |_|\__|  |______\___/ \__,_|\__,_|
                                                               
    by Svengineer99

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  _______ _                 _                          _  
 |__   __| |               | |                        | | 
    | |  | |__   __ _ _ __ | | _____    __ _ _ __   __| | 
    | |  | '_ \ / _` | '_ \| |/ / __|  / _` | '_ \ / _` | 
    | |  | | | | (_| | | | |   <\__ \ | (_| | | | | (_| | 
    |_|  |_| |_|\__,_|_| |_|_|\_\___/  \__,_|_| |_|\__,_|
   _____              _ _ _     _            
  / ____|            | (_) |   | |         _ 
 | |     _ __ ___  __| |_| |_  | |_ ___   (_)
 | |    | '__/ _ \/ _` | | __| | __/ _ \     
 | |____| | |  __/ (_| | | |_  | || (_) |  _ 
  \_____|_|  \___|\__,_|_|\__|  \__\___/  (_)
  
  Petethegoat for Continue and NulCascade for SSS
  Hrnchamd for UI Inspector, etc.
  NullCascade and team for MWSE lua scripting development and docs
  NullCascade, Greatness7, Merlord, Petethegoat, Mort, ... for
     Released and unreleased lua scripting references
     Morrowind Discord #MWSE channel chat discussion, help, ...
  
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
 __          __              _                               _ 
 \ \        / /             (_)                             | |
  \ \  /\  / /_ _ _ __ _ __  _ _ __   __ _    __ _ _ __   __| |
   \ \/  \/ / _` | '__| '_ \| | '_ \ / _` |  / _` | '_ \ / _` |
    \  /\  / (_| | |  | | | | | | | | (_| | | (_| | | | | (_| |
     \/  \/ \__,_|_|  |_| |_|_|_| |_|\__, |  \__,_|_| |_|\__,_|
                                      __/ |                    
  _____  _          _       _        |___/                     
 |  __ \(_)        | |     (_)                      _ 
 | |  | |_ ___  ___| | __ _ _ _ __ ___   ___ _ __  (_)
 | |  | | / __|/ __| |/ _` | | '_ ` _ \ / _ \ '__|     
 | |__| | \__ \ (__| | (_| | | | | | | |  __/ |     _ 
 |_____/|_|___/\___|_|\__,_|_|_| |_| |_|\___|_|    (_)
                                                                 
  Not well optimized, organized, commented; sometimes hacky scripting below.
  No reflection of MWSE devs and other scripters superior example and practice.
  Not recommended as a reference unless no other can be found.

]]------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local config = mwse.loadConfig("instant load")
if not config then
	config = {
		enabled = true,
		continue = true,
		blockKey = tes3.scanCode.space,
		overrideFile = false,
		delay = 0.125,
		runInBackground = true,
	}
end
mwse.setConfig("RunInBackground", config.runInBackground)

-- 
--Re-stolen from Continue.  Thank you Pete and Null!
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

local retryCount = 0
local function onCreatedMenuOptions()
	local function instantLoad()
		local inputController = tes3.worldController.inputController
		if inputController:isKeyDown(config.blockKey) then
mwse.log("block key detected, abort instant load")		
		-- abort
		elseif retryCount < 5 then
		-- seems to take a few frames for inputController to start reporting a key held down
			retryCount = retryCount + 1
mwse.log("onCreatedMenuOptions retryCount:" .. retryCount)			
			timer.start({ duration = config.delay/5, callback = instantLoad, type = timer.real })
			return
		else
			if tes3ui.findMenu(tes3ui.registerID("MenuOptions")) == nil then return end
			local file = config.overrideFile
			if config.continue then file = getNewestSaveFile() end
			if file and file ~= "" and saveFileExists(file) then
				tes3.loadGame(file)
			end
		end
		retryCount = 0
	end
	if config.enabled then
		instantLoad()
	end	 
end

local function onLoaded()
	event.unregister("uiActivated", onCreatedMenuOptions, { filter = "MenuOptions" })
	event.unregister("loaded", onLoaded)
end

event.register("uiActivated", onCreatedMenuOptions, { filter = "MenuOptions" })
event.register("loaded", onLoaded)

--ModConfig
local modConfig = {}

function modConfig.onCreate(container)

	local pane = container:createThinBorder{}
	pane.widthProportional = 1.0
	pane.heightProportional = 1.0
	pane.paddingAllSides = 12
	pane.flowDirection = "top_to_bottom"
	
	local header = pane:createLabel{ text = "Instant Load" }
	header.color = tes3ui.getPalette("header_color")
	header.borderBottom = 15

	-- Description and credits

	local txtBlock = pane:createBlock()
	txtBlock.widthProportional = 1.0
	txtBlock.autoHeight = true
	txtBlock.borderBottom = 25

	local txt = txtBlock:createLabel{}
	txt.wrapText = true
	txt.text = "Instantly loads the latest save game or override save game without any key or mouse click, even if alt-tabbed to another window during loading.\n\nInspired by and largely copied from PeteTheGoat's Continue Mod instaload feature, changed to occur by default rather than requiring holding a key down; and added the RunInBackground (default enabled) new MWSE2.1 Sol3 feature made available by NullCascade.  This modshould not confict with Pete's Continue mod, provided that mod instaload feature has not been manually enabled.\n\nSpecial thanks and credit to PeteTheGoat and NullCascade."

	-- enable
	local enableBlock = pane:createBlock()
	local blockKeyBlock = pane:createBlock()
	local continueBlock = pane:createBlock()
	local overrideFileBlock = pane:createBlock()
	local RunInBackgroundBlock = pane:createBlock()

	local function updateVisible()
		blockKeyBlock.visible = config.enabled
		continueBlock.visible = config.enabled
		overrideFileBlock.visible = config.enabled and not config.continue
		RunInBackgroundBlock.visible = config.enabled
	end
	
	enableBlock.flowDirection = "left_to_right"
	enableBlock.widthProportional = 1.0
	enableBlock.autoHeight = true
	enableBlock.paddingAllSides = 6
	local enableButton = enableBlock:createButton({ text = config.enabled and "Enabled" or "Disabled" })
        enableButton:register("help", function()
		local tooltip = tes3ui.createTooltipMenu()
		tooltip:createLabel{ text = 	"Enable this Mod or\n" ..
						"Disable this Mod."}
	end)
	enableBlock:createLabel({ text = "Instant Load (this Mod)" })
	enableButton.borderRight = 10
	enableButton.borderAllSides = 0
	enableButton:register("mouseClick", function()
		config.enabled = not config.enabled
		enableButton.text = config.enabled and "Enabled" or "Disabled"
		updateVisible()
	end)
	
	-- blockKey
   	local scanCodeText = {}
	for text,code in pairs(tes3.scanCode) do
		if scanCodeText[code] == nil
		or string.len(text) < string.len(scanCodeText[code]) then scanCodeText[code] = text end
	end
	blockKeyBlock.flowDirection = "left_to_right"
	blockKeyBlock.widthProportional = 1.0
	blockKeyBlock.autoHeight = true
	blockKeyBlock.paddingAllSides = 6
	blockKeyBlock.paddingLeft = 26
	local blockKeyButton = blockKeyBlock:createButton({ text = scanCodeText[config.blockKey] or "TBD"})
        blockKeyButton:register("help", function()
		local tooltip = tes3ui.createTooltipMenu()
		tooltip:createLabel{ text = 	"Click Button while Press/Holding Key Down to Redefine\n\n" ..
						"Hold This Key Down During First Session Start Up to\n" ..
						"Suppress Instant Load and Stop at the Main Menu." }
					    
	end)
	--blockKeyButton.minWidth = hideButton.width
	blockKeyButton.borderRight = 10
	blockKeyButton.borderAllSides = 0
	blockKeyButton:register("mouseClick", function()
	
		local inputController = tes3.worldController.inputController
		for code,text in pairs(scanCodeText) do
			if inputController:isKeyDown(code) then
				config.blockKey = code
				blockKeyButton.text = text

				break
			end
		end
	end)
	-- sve comment: can not seem to get button text to center... giving up
	-- blockKeyButton:updateLayout()
	-- blockKeyButton.children[1].absolutePosAlignX = 0.5
	blockKeyBlock:createLabel({ text = "Key to Hold Down to Suppress Instant Load" })
	
	-- continue or override
	continueBlock.flowDirection = "left_to_right"
	continueBlock.widthProportional = 1.0
	continueBlock.autoHeight = true
	continueBlock.paddingAllSides = 6
	continueBlock.paddingLeft = 26
	local continueButton = continueBlock:createButton({ text = config.continue and "Continue" or "Load" })
        continueButton:register("help", function()
		local tooltip = tes3ui.createTooltipMenu()
		tooltip:createLabel{ text = 	"Continue: Instant load the latest dated save file.\n" ..
						"Load: Instant load the defined override save file defined below.\n"}
	end)
	local continueLabel = continueBlock:createLabel({ text = config.continue and "Latest Save Game or Toggle to Load the Override Save Game" or "Override Save Game or Toggle to Continue Latest Save Game" })
	continueButton.borderRight = 10
	continueButton.borderAllSides = 0
	continueButton:register("mouseClick", function()
		config.continue = not config.continue
		continueButton.text = config.continue  and "Continue" or "Load"
		continueLabel.text = config.continue and "Latest Save Game or Toggle to Load the Override Save Game" or "Override Save Game or Toggle to Continue Latest Save Game"
		overrideFileBlock.visible = config.enabled and not config.continue
	end)
	
	-- overrideFile
	overrideFileBlock.flowDirection = "left_to_right"
	overrideFileBlock.widthProportional = 1.0
	overrideFileBlock.autoHeight = true
	overrideFileBlock.paddingAllSides = 6
	overrideFileBlock.paddingLeft = 46
	if not saveFileExists(config.overrideFile) then config.overRideFile = false end
	local overrideFileButton = overrideFileBlock:createButton({ text = config.overrideFile or "Not Defined" })
        overrideFileButton:register("help", function()
		local tooltip = tes3ui.createTooltipMenu()
		tooltip:createLabel{ text = "Click to Select"}
	end)
	overrideFileButton.borderRight = 10
	overrideFileButton.borderAllSides = 0
	overrideFileButton:register("mouseClick", function()
		local menu = tes3ui.findMenu(tes3ui.registerID("MenuOptions"))
		if menu == nil then return end
		local button = menu:findChild(tes3ui.registerID("MenuOptions_Load_container"))
		if button == nil then return end
		local function onLoad(e)
mwse.log("onLoad skip filename:" .. tostring(e.filename))
			config.overrideFile = e.filename and e.filename .. ".ess" or false
			overrideFileButton.text = config.overrideFile or "Not Defined"
			return false
		end
		local function onMenuLoad(e)
mwse.log("MenuLoad prepped")
			local element = e.element:findChild(tes3ui.registerID("MenuLoad_savelabel"))
			if element ~= nil then element.text = "Instant Load Override Save Game" end
			element = e.element:createBlock{ id = tes3ui.registerID("sve load menu destroy detection invisible element")}
			element.visible = false
			local retryCount = 0
			local function unregisterLoadEvents()
				-- seems to take at least one frame after the load menu is destroyed for the load event to trigger..
				if retryCount < 5 then
					retryCount = retryCount + 1
mwse.log("onMenuLoad destroy retryCount:" .. retryCount)				
					timer.start({ duration = config.delay/5, callback = unregisterLoadEvents, type = timer.real })
					return
				end
mwse.log("unregister load, uiActivated")				
				event.unregister("load", onLoad, { priority = 10000 } )
				event.unregister("uiActivated", onMenuLoad, { filter = "MenuLoad" } )
			end
			element:register("destroy", unregisterLoadEvents)
		end
		event.register("load", onLoad, { priority = 10000 })
		event.register("uiActivated", onMenuLoad, { filter = "MenuLoad" } )
		button:triggerEvent("mouseClick")
	end)
	overrideFileBlock:createLabel({ text = "Override Save Game File" })
	
	-- RunInBackground
	RunInBackgroundBlock.flowDirection = "left_to_right"
	RunInBackgroundBlock.widthProportional = 1.0
	RunInBackgroundBlock.autoHeight = true
	RunInBackgroundBlock.paddingAllSides = 6
	RunInBackgroundBlock.paddingLeft = 26
	local RunInBackgroundButton = RunInBackgroundBlock:createButton({ text = config.runInBackground and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value })
        RunInBackgroundButton:register("help", function()
		local tooltip = tes3ui.createTooltipMenu()
		tooltip:createLabel{ text = "Forces Morrowind to run in the background.\nThat enables Instant Load to not Pause at the Main Menu after Alt-Tabing."}
	end)
	RunInBackgroundButton.borderRight = 10
	RunInBackgroundButton.borderAllSides = 0
	RunInBackgroundButton:register("mouseClick", function()
		config.runInBackground = not config.runInBackground
		RunInBackgroundButton.text = config.runInBackground and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value
	end)
	RunInBackgroundBlock:createLabel({ text = "Run Morrowind In Background" })

	updateVisible()
	pane:updateLayout()
end

function modConfig.onClose()
	mwse.saveConfig("instant load", config, { indent = true })
end

local function registerModConfig()
	mwse.registerModConfig("Instant Load", modConfig)
end
event.register("modConfigReady", registerModConfig)

