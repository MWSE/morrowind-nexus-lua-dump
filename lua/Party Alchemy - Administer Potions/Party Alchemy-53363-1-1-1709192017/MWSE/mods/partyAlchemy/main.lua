--[[
    Party Alchemy
    By Shanjaq
--]]

-- File name for Party Alchemy config.
local config = require("partyAlchemy.config")

-- File name for Controlled Consumption config.
local CCconfigName = "Controlled Consumption"

-- Array of module names, relating to the modules keys.
local CCmoduleNames = {}

-- The path that Party Alchemy Controlled Consumption modules are stored in.
local CCmoduleDir = "Data Files/MWSE/mods/partyAlchemy/ccmodule"

local isControlledConsumptionInstalled = tes3.isLuaModActive(CCconfigName)
local CCconfig = mwse.loadConfig(CCconfigName) or {}

-- Set of moduleName:table.
local CCmodules = {}

-- Reference to the currently active module.
local currentCCModule = nil



-- Loads a module from disk, does version checking, and sets up the state.
local function loadModule(file)
	-- Execute the file to get its module.
	local module = dofile(string.format("%s/%s.lua", CCmoduleDir, file))

	-- Report success, insert into module lists.
	mwse.log("[Controlled Consumption] Found module: %s", module.name)
	table.insert(CCmoduleNames, module.name)
	CCmodules[module.name] = module
end

-- Sets the active module, invoking any needed callbacks.
local function setModule(name)
	-- Let the previous module know it is deactivated.
	if (currentCCModule) then
		local onSetInactive = currentCCModule.onSetInactive
		if (onSetInactive) then
			onSetInactive(config, moduleConfigPane)
		end
	end

	-- Set the current module variable.
	currentCCModule = CCmodules[name]
	if (currentCCModule == nil) then
		error("[Party Alchemy] Could not determine active [Controlled Consumption] module!")
	end
	config.currentCCModule = currentCCModule.name

	-- Let the module know it is activated.
	local onSetActive = currentCCModule.onSetActive
	if (onSetActive) then
		onSetActive(config, moduleConfigPane)
	end

	mwse.log("[Party Alchemy] Set [Controlled Consumption] module: %s", name)
end

-- Load the desired configuration module.
local function onInitialized(mod)
  if isControlledConsumptionInstalled then
    if (mwse.buildDate == nil or mwse.buildDate < 20180712) then
      tes3.messageBox("[Party Alchemy] Controlled Consumption module requires a newer version of MWSE. Please run MWSE-Update.exe.", mwse.buildDate)
      return
    end

    -- Look through our module folder and load any modules.
    for file in lfs.dir(CCmoduleDir) do
      local path = string.format("%s/%s", CCmoduleDir, file)
      local fileAttributes = lfs.attributes(path)
      if (fileAttributes.mode == "file" and file:sub(-4, -1) == ".lua") then
        loadModule(file:match("(.+)%..+"))
      end
    end

    -- Try to use the selected module.
    local module = CCconfig.currentModule
    tes3.messageBox("Switched to module: [%s]", module)
    if ((module == nil or CCmodules[module] == nil) and #CCmoduleNames > 0) then
      module = CCmodules["Vanilla NPC Style"] and "Vanilla NPC Style" or CCmoduleNames[1]
    end
    setModule(module)
    return
  end
  
  local file = "disabled.lua"
  local path = string.format("%s/%s", CCmoduleDir, file)
  local fileAttributes = lfs.attributes(path)
  if (fileAttributes.mode == "file" and file:sub(-4, -1) == ".lua") then
    loadModule(file:match("(.+)%..+"))
  end
  
  -- Try to use the default module.
  local module = config.currentCCModule
  if ((module == nil or CCmodules[module] == nil) and #CCmoduleNames > 0) then
    module = CCmodules["Disabled"] and "Disabled" or CCmoduleNames[1]
  end
  setModule(module)
end
event.register("initialized", onInitialized)





local function addPAFlask()
	local menu = tes3ui.findMenu(tes3ui.registerID("MenuDialog"))
	if not menu then return end

	local companionShareButton = menu:findChild("MenuDialog_service_companion")
	if not companionShareButton then return end

	companionShareButton:register("mouseClick", function(e)
    local companion = tes3ui.getServiceActor()
    local count = mwscript.getItemCount{reference=companion.reference, item="misc_pa_flask"}
    if count == 0 then
        mwscript.addItem({ reference=companion.reference, item="misc_pa_flask", count=1 })
    elseif count > 1 then
        mwscript.removeItem({ reference=companion.reference, item="misc_pa_flask", count=(count-1) })
    end
    e.source:forwardEvent(e)
	end)
end
event.register("initialized", function()
    -- load modules
    dofile("partyAlchemy.partyalch")
    event.register("uiActivated", addPAFlask, { filter = "MenuDialog" })
end)

---@param e deathEventData
event.register(tes3.event.death, function(e)
    local isPotentialCompanion = (e.reference.context and e.reference.context["companion"]) and true or false
    if not isPotentialCompanion then return end
    
    local count = mwscript.getItemCount{reference=e.reference, item="misc_pa_flask"}
    if count > 0 then
      mwscript.removeItem({ reference=e.reference, item="misc_pa_flask", count=(count) })
    end
end)

local function onMGEXEOptions()
  --tes3.messageBox("[Party Alchemy] some mod changed its settings?")
  CCconfig = mwse.loadConfig(CCconfigName) or {} --shan have to reload to see updated settings?
  if not (config.currentCCModule == CCconfig.currentModule) then
    setModule(CCconfig.currentModule)
  end
end

--below detects when any mod, including Controlled Consumption, options change
local menuOptionsID = "MenuOptions"
local MCMButtonID = "MenuOptions_MCM_container"
local MCMID = "MWSE:ModConfigMenu"
-- Monitor if MGE XE distant land settings were changed
---@param e uiActivatedEventData
local function onOptionsCreated(e)
    if isControlledConsumptionInstalled then
        e.element:findChild(MCMButtonID):registerAfter(tes3.uiEvent.mouseClick, function()
            local menu = tes3ui.findMenu(MCMID)
            if not menu then
                return
            end
            if not e.newlyCreated then
                return
            end
            
            menu:registerAfter(tes3.uiEvent.destroy, function()
                timer.delayOneFrame(onMGEXEOptions, timer.real)
            end)
        end)
    end
end
event.register(tes3.event.uiActivated, onOptionsCreated, { filter = menuOptionsID })