--[[

	No Rest Without Beds prevents the player from resting unless they use a bed.

]]--Kaedius

local configPath = "NoRestWithoutBeds"

local config = mwse.loadConfig(configPath)
if (config == nil) then
	config = { enabled = true, interiors = false, interiorsNoBed = false }
end

local function onUiShowRestMenu(e)
	if not config.enabled then return end
	
	local bool = true
	local isInterior
	local isIllegal
	
	if ( config.interiors or config.interiorsNoBed ) then
		local playerCell = tes3.getPlayerCell()
		isInterior = playerCell.isInterior
		isIllegal = playerCell.restingIsIllegal
		
		if ( config.interiors and not isInterior ) then
			bool = false
		end
	end
	
	if ( ( e.scripted and bool ) or ( config.interiorsNoBed and isInterior and not isIllegal ) ) then
		e.allowRest = true
	else
		e.allowRest = false
	end
end

local function onInitialized()
	event.register("uiShowRestMenu", onUiShowRestMenu)
	
	if ( config.enabled ) then
		tes3.findGMST(57).value = "Wait for how long?"
		tes3.findGMST(745).value = "Rest for how long?"
		tes3.findGMST(507).value = "You can only rest or wait on solid ground."
		tes3.findGMST(508).value = "You can't rest or wait here; enemies are nearby"
	end
	
	mwse.log("[No Rest Without Beds] Initialized")
end

event.register("initialized", onInitialized)

--------------------------------------------
--MCM
--------------------------------------------
local mcm = require("easyMCM.EasyMCM")
local function registerMCM()
    local sidebarDefault = 
	(
        "No Rest Without Beds prevents you from resting unless you activate a bed. " ..
        "You may optionally enable to only allow resting in interior cell locations, " ..
		"or allow resting in interiors without beds. "
    )
	
    local template = mcm.createTemplate("No Rest Without Beds")
    template:saveOnClose(configPath, config)
	
    local page = template:createSideBarPage
	{
        description = sidebarDefault
    }
	
    page:createOnOffButton
	{
        label = "Enable No Rest Without Beds",
        variable = mcm.createTableVariable
		{
            id = "enabled", 
            table = config
        },
        description = "Turn this mod on or off. Restart game required to reset rest/wait messages"
    }
	
	page:createOnOffButton
	{
        label = "Enable interior cell resting only",
        variable = mcm.createTableVariable
		{
            id = "interiors", 
            table = config
        },
        description = "You can only rest in interior cells."
	}
	
	page:createOnOffButton
	{
        label = "Enable interior cell resting without beds",
        variable = mcm.createTableVariable
		{
            id = "interiorsNoBed", 
            table = config
        },
        description = "You can rest in interior cells without a bed."
	}
    template:register()
end
event.register("modConfigReady", registerMCM)