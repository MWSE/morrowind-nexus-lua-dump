--- Configuration stuff
local default_config = {
    enabled         = true,
    forgetting      = false,
    logLevel        = mwse.logLevel.info,
    daysToRemember  = 30,
}

local confPath = "SA_ForgetMeNot_config"

local config        = mwse.loadConfig(confPath, default_config) ---@cast config table
config.confPath     = confPath
config.default      = default_config

local log = mwse.Logger.new{
    modName = "Forget Me Not",
    level   = config.logLevel
}

-- Variables


-- Auxiliary functions
local function getData()
    local data = tes3.player.data.SA_ForgetMeNot
    -- If data is nil, then initialize it
    if data == nil then
        tes3.player.data.SA_ForgetMeNot = {}
        data = tes3.player.data.SA_ForgetMeNot
    end
    return data
end


-- When the dialogue starts, we log the actor (except if guard)

--- @param e uiActivatedEventData
local function uiActivatedCallback(e)
    -- If the mod is not enabled, exit
    if not config.enabled then log:trace("Mod disabled") return end
    -- If it was not just created, exit the code
    if not e.newlyCreated then log:trace("UI not newly created %s", e.element.id) return end

    -- Get the interlocutor
    local interlocutor = tes3ui.getServiceActor()
    if interlocutor == nil then log:error("There is no service actor") return end

    local data = getData()
    -- If it is a guard, do not save
    if interlocutor.object.isGuard then log:debug("Service actor is a guard, id: %s", interlocutor.object.id) return end

    -- Ok, now save the actor with the timestamp
    data[interlocutor.reference.baseObject.id] = tes3.getSimulationTimestamp(false)

end
event.register(tes3.event.uiActivated, uiActivatedCallback, {filter = 'MenuDialog'})


--- @param e mobileActivatedEventData
local function mobileActivatedCallback(e)
    -- If the mod is not enabled, exit
    if not config.enabled then log:trace("Mod disabled") return end

    -- If it is not a creature or an NPC, exit
    if not (    (e.mobile.objectType == tes3.objectType.mobileCreature)
            or  (e.mobile.objectType == tes3.objectType.mobileNPC))
    then log:debug("Mobile is neither a creature or an NPC") return end

    -- If the id doesn't exist in the table, exit
    local data = getData()
    local object = e.mobile.object
    local id   = object.id
    if data[id] == nil then log:debug("Actor id %s is not registered", id) return end

    -- If it exists, then check against the forget mechanic if enabled
    local now = tes3.getSimulationTimestamp(false)
    local daysPassed = math.floor((now - data[id] )/24)
    if config.forgetting and ( daysPassed > config.daysToRemember)  then
        data[id] = nil
        log:debug("Forgetting id %s because it has been %d days, and maximum days to remember is set to %d", id, daysPassed, config.daysToRemember)
        return
    end

    -- Now that we have cleared all the hurdles, set the talkedTo to true
    e.mobile.talkedTo = true

end
event.register(tes3.event.mobileActivated, mobileActivatedCallback)

--- MCM stuff
--- @param self mwseMCMInfo|mwseMCMHyperlink
local function center(self)
	self.elements.info.absolutePosAlignX = 0.5
end

local authors = {
	{
		name = "Storm Atronach",
		url = "https://next.nexusmods.com/profile/StormAtronach0",
	},
}


--- Adds default text to sidebar. Has a list of all the authors that contributed to the mod.
--- @param container mwseMCMSideBarPage
local function createSidebar(container)
	container.sidebar:createInfo({
		text =      "Forget me not\n\n" ..
                    "A mod that remembers people that you have talked to beyond the 72 in-game hours that were hardcoded in Morrowind.\n" ..
                    "It does this by keeping a list of NPCs and creatures that you have talked to, and adjusting the talkedTo flag when their mobile is loaded \n" ..
                    "\n\nMade by:",
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
		name = "Forget Me Not",
		config = config,
		defaultConfig = config.default,
		showDefaultSetting = true,
	})
    template:saveOnClose(confPath, config)


	local page = template:createSideBarPage({
		label = "Settings",
		showReset = true,
	}) --[[@as mwseMCMSideBarPage]]
	createSidebar(page)

    -- Settings
    page:createOnOffButton({
        label = "Enable Mod",
        description = "Toggle the mod on or off.",
        configKey = "enabled",
    })

    page:createOnOffButton({
        label = "Enable Forgetting",
        description = "If enabled, NPCs will 'forget you' after a set number of days.",
        configKey = "forgetting",
    })

    page:createSlider({
        label = "Days to Remember",
        description = "How many days before an NPC forgets you (only if forgetting is enabled).",
        min = 1,
        max = 365,
        step = 1,
        jump = 10,
        configKey = "daysToRemember",
    })

    page:createLogLevelOptions({
        configKey = "logLevel"
    })
    template:register()
end
event.register("modConfigReady", registerModConfig)