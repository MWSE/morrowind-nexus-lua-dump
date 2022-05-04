--[[
	Mod Loading Splash Screens
	Author: rfuzzo

	This mod displys splash screens during the cell loading phase instead of freezing the current frame
	Splash screens are randomly taken from the installed splash screen pool
]] --
local config = require("rfuzzo.LoadingSplashScreens.config")

local splashScreens = {}
local isEnabled = false

--- local logger
--- @param msg string
--- @vararg any *Optional*. No description yet available.
local function mod_log(msg, ...)
	local str = "[ %s/%s ] " .. msg
	local arg = { ... }
	return mwse.log(str, config.author, config.id, unpack(arg))
end

--[[
    modifies the loading UI to display the splash screen
]]
--- @param e uiActivatedEventData
local function uiActivatedCallback(e)
	local menu = e.element
	local name = menu.name

	if (isEnabled == false) then
		return
	end

	if (tes3.mobilePlayer == nil) then
		return
	end

	local i = math.random(1, #splashScreens)
	local p = splashScreens[i]
	-- mwse.log("[ LSS ] ".. i .. ": " .. p)

	-- local width, height = tes3.getViewportSize()
	-- local scale = tes3ui.getViewportScale()
	local uwidth, uheight = tes3ui.getViewportSize()

	local frame = menu:createBlock{}
	frame.width = uwidth
	frame.height = uheight
	frame.childAlignX = 0.5
	frame.alpha = 0.0
	frame.paddingAllSides = 3

	local image = frame:createImage{ id = i, path = p }
	image.widthProportional = 1.0
	image.heightProportional = 1.0
	image.width = uwidth
	image.height = uheight
	image.scaleMode = true
	image.alpha = config.alpha / 100
	-- image.paddingAllSides = 15

	-- Final setup
	menu:updateLayout()
end

--[[
    Init mod and find all installed splash screens
]]
--- @param e initializedEventData
local function initializedCallback(e)
	-- get a list of all installed splash screens
	local base, _ = lfs.currentdir()
	local path = base .. "/Data Files/Splash"

	if (lfs.directoryexists(path)) then
		for file in lfs.dir(path) do
			if file ~= "." and file ~= ".." then
				local relpath = "Splash/" .. file
				table.insert(splashScreens, relpath)
				-- mwse.log("[ LSS ] adding: " .. relpath)
			end
		end
		mod_log("Found %s splash screens to use", #splashScreens)
	end

	-- init mod
	mod_log("%s v%.1f Initialized", config.mod, config.version)
end

--[[
    hacks to only enable mod once a save has been loaded properly
    and not on saving
]]
--- @param e saveEventData
local function saveCallback(e)
	isEnabled = false
end
--- @param e savedEventData
local function savedCallback(e)
	isEnabled = true
end
--- @param e loadEventData
local function loadCallback(e)
	isEnabled = false
end
--- @param e loadedEventData
local function loadedCallback(e)
	isEnabled = true
end

--[[
    event hooks
]]
event.register(tes3.event.initialized, initializedCallback)
event.register(tes3.event.uiActivated, uiActivatedCallback, { filter = "MenuLoading" })

event.register(tes3.event.loaded, loadedCallback)
event.register(tes3.event.save, saveCallback)
event.register(tes3.event.load, loadCallback)
event.register(tes3.event.saved, savedCallback)

--
-- Handle mod config menu.
--
require("rfuzzo.LoadingSplashScreens.mcm")
