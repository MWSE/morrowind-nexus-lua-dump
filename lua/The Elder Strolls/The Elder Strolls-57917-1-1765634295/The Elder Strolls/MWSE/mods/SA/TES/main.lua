local default_config = {
    enabled     = true,
    confPath    = "SA_TES_config",
    logLevel    = mwse.logLevel.info,
    fightLevel  = 1
}

local config    = mwse.loadConfig(default_config.confPath, default_config) ---@cast config table
config.default  = default_config

local log = mwse.Logger.new({
    modName = "The Elder Strolls",
    level = config.logLevel
})

---@param e mobileActivatedEventData
local function mobileActivatedCallback(e)
    if not config.enabled then return end

	-- Debug log to verify that the event is being fired
	log:debug("Mobile activated: %s", e.mobile.object.id)
    
    if e.mobile.fight then
        e.mobile.fight = config.fightLevel
    end

end
event.register(tes3.event.mobileActivated, mobileActivatedCallback)

--- Adds default text to sidebar. Has a list of all the authors that contributed to the mod.
--- @param container mwseMCMSideBarPage
local function createSidebar(container)
	container.sidebar:createInfo({
		text =      "The Elder Strolls\n\n" ..
                    "A simple mod for a pacifist playthrough or for testing stuff when modding. \n" ..
                    "You can also go the other way, if you set the slider to 100, and everything will fight you. \n\nMade by:",
		postCreate = center,
	})
	for _, author in ipairs(authors) do
		container.sidebar:createHyperlink({
			text = author.name,
			url = author.url,
			postCreate = center,
		})
	end
end

local function registerModConfig()
	local template = mwse.mcm.createTemplate({
		name = "Second Wind",
		config = config,
		defaultConfig = config.default,
		showDefaultSetting = true,
	})
	template:register()
	template:saveOnClose(config.confPath, config)

	local page = template:createSideBarPage({
		label = "Settings",
		showReset = true,
	}) --[[@as mwseMCMSideBarPage]]
	createSidebar(page)

    page:createOnOffButton{
        label = "Enable Mod",
        description = "Toggle the mod on or off.",
        configKey = "enabled",
    }

    page:createSlider{
        label = "Fight level to be set",
        description = "This is the value of the stamina regeneration per second while wandering",
        min = 0, max = 100, step = 1, jump =10,
        configKey ="fightLevel",
    }

    end
event.register("modConfigReady", registerModConfig)