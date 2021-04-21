local configPath = "No_Translation_Tooltips"

local defaultConfig = { 
	roadsigns =
		true,
	banners =
		true,
	markers =
		true		
}

local config = mwse.loadConfig(configPath, defaultConfig)

local signsToHide = {
 	"^active_sign_", -- Vanilla
 	"^T_Com_Set%a%a%a?_SignWay", -- Tamriel Data
 	"^STS_sign" -- Swappable Texture Signposts
}

local bannersToHide = {
 	"^Act_banner",
 	"^furn_banner",
	"^furn_de_banner",
 	"^furn_sign_",
	"^Ex_V_sign_"
}

local markersToHide = {
 	".*_roadmarker_.*"
}

local function hideTooltipFromList(id, hideList)
	--mwse.log("[OEA4] Starting the search")
 	for _, item in pairs(hideList) do
  		if id:match(item) then
			--mwse.log("[OEA4] Matched!")
			return true 
		end
 	end
 	return false
end

local function onSign(e)
	if e.reference and e.reference.id then
  		if config.roadsigns and hideTooltipFromList(e.reference.id, signsToHide) then 
			e.tooltip.maxWidth = 0
			e.tooltip.maxHeight = 0
			return 
 		end

  		if config.banners and hideTooltipFromList(e.reference.id, bannersToHide) then
			--mwse.log("[OEA4] Disabling the tooltip")
			e.tooltip.maxWidth = 0
			e.tooltip.maxHeight = 0
			return 
  		end

  		if config.markers and hideTooltipFromList(e.reference.id, markersToHide) then
			e.tooltip.maxWidth = 0
			e.tooltip.maxHeight = 0
			return 
  		end
	end
end
event.register("uiObjectTooltip", onSign, { priority = -100000 })

----MCM
local function registerModConfig()

    local template = mwse.mcm.createTemplate({ name = "No Translation Tooltips" })
    template:saveOnClose(configPath, config)

    local page = template:createPage()
    page.noScroll = true
    page.indent = 0
    page.postCreate = function(self)
        self.elements.innerContainer.paddingAllSides = 10
    end

 
    local sign = page:createYesNoButton{
        label = "Disable road sign tooltips?",
        variable = mwse.mcm:createTableVariable{
            id = "roadsigns",
            table = config
        }
    }

   local banner = page:createYesNoButton{
        label = "Disable banner tooltips?",
        variable = mwse.mcm:createTableVariable{
            id = "banners",
            table = config
        }
    }

   local marker = page:createYesNoButton{
        label = "Disable roadmarker (stone monolith) tooltips?",
        variable = mwse.mcm:createTableVariable{
            id = "markers",
            table = config
        }
    }

    mwse.mcm.register(template)
end

event.register("modConfigReady", registerModConfig)