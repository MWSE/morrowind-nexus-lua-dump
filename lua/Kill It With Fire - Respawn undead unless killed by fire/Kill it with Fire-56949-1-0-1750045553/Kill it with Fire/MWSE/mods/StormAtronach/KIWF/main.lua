-- Configuration and variable definition
---@class template.defaultConfig
local default = {
	enabled = true,
	messageEnabled = true,
	logLevel = mwse.logLevel.info,
	timeToUnlife = 1, -- in in-game hours

	}
local fileName = "Kill it with Fire"


---@class template.config : template.defaultConfig
---@field version string A [semantic version](https://semver.org/).
---@field default template.defaultConfig Access to the default config can be useful in the MCM.
---@field fileName string

local config = mwse.loadConfig(fileName, default) --[[@as template.config]]
config.version = "1.0"
config.default = default
config.fileName = fileName

-- Logging stuff
local log = mwse.Logger.new({
	name = fileName,
	level = config.logLevel,
})
---@param reference tes3reference
local function unlife(reference)
	if not reference.mobile then log:trace("Reference has no mobile attached.") return end
	local playerCell = tes3.mobilePlayer.cell.id
	local mobileCell = reference.mobile.cell.id
	log:trace("Player cell %s, undead cell %s", playerCell, mobileCell)

	if reference.disabled then reference:enable() end
	if playerCell == mobileCell then
	tes3.createVisualEffect({
		object = "VFX_Summon_Start",
		reference = reference,
		repeatCount = 1,
	})
	end
	reference.mobile:resurrect({resetState = false})
end

-- Registering the timer
timer.register("sa_kiwf_unlifeStart", function(e)
	local actorId = e.timer.data.actorId
	local actor = tes3.getReference(actorId)
	if actor then unlife(actor) end
	end)

--- @param e damagedEventData
local function damagedCallback(e)
	-- Is the mod enabled?
	if not config.enabled then return end
	-- Is this a killing blow?
	if not e.killingBlow then return end
	-- Is the actor undead?
	local actor = e.reference
	local isUndead = actor.object.objectType == tes3.objectType.creature and actor.object.type == tes3.creatureType.undead
	log:trace("Actor id %s, is undead %s", e.reference.id, isUndead)
	if not isUndead then return end
	-- Special case of Dagoth Baler
	if actor.id:lower() == "dagoth baler" then return end
	-- Was it done by fire damage?
	local hasFire = false
	if e.magicSourceInstance then
	for _,effect in pairs(e.magicSourceInstance.sourceEffects) do
		if effect.id == tes3.effect.fireDamage then
		hasFire = true
		break
		end
	end
	end
	-- If it has fire damage, then do nothing
	if hasFire then
		if config.messageEnabled then tes3.messageBox("Killed it with fire!") end
	return end
	-- Now, if we have reached this stage, let us raise the dead again after an hour (or as defined by config)
	-- Thank God I remembered the Object Lifetimes guide:
	---@type mwseSafeObjectHandle

	timer.start({
		type = timer.game,
		duration = config.timeToUnlife,
		callback = "sa_kiwf_unlifeStart",
		data = {actorId = actor.id}
	})

end
event.register(tes3.event.damaged, damagedCallback)

local authors = {
	{
		name = "Storm Atronach",
		url = "https://next.nexusmods.com/profile/StormAtronach0",
	},
}


--- @param self mwseMCMInfo|mwseMCMHyperlink
local function center(self)
	self.elements.info.absolutePosAlignX = 0.5
end

--- Adds default text to sidebar. Has a list of all the authors that contributed to the mod.
--- @param container mwseMCMSideBarPage
local function createSidebar(container)
	container.sidebar:createInfo({
		text = "\nKill it with Fire!\n\nNow unless you kill undead with a spell containing fire damage, they will raise again within the configured in-game hours (default: 1). Tomb robbing got a lot riskier :D \n\nHover over a feature for more info.\n\nMade by:",
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
-- MCM stuff
local function registerModConfig()
	local template = mwse.mcm.createTemplate({
		name = "Kill it with Fire",
		config = config,
		defaultConfig = config.default,
		showDefaultSetting = true,
	})
	template:register()
	template:saveOnClose(config.fileName, config)

	local page = template:createSideBarPage({
		label = "Settings",
		showReset = true,
	}) --[[@as mwseMCMSideBarPage]]
	createSidebar(page)

	page:createOnOffButton({
		label = "Enable mod",
		description = "Whether the mod is enabled or not",
		configKey = "enabled"
	})

	page:createOnOffButton({
		label = "Enable message",
		description = "Whether the message is shown when killing an undead with fire",
		configKey = "messageEnabled"
	})

	page:createSlider({
		label = "Time to rise again",
		description = "The time until the dead rise again, in in-game hours",
		min = 1,
		max = 36,
		step = 1,
		jump = 4,
		configKey = "timeToUnlife",
	})

	page:createLogLevelOptions({
		configKey = "logLevel",
	})
end

event.register(tes3.event.modConfigReady, registerModConfig)