local fileName = "Leveled Filled Soul Gem"
local defaults = {
	logLevel = "INFO",
	filledChance = 5,
	creatures = {
		"guar",
		"bonewalker",
		"guar_pack",
		"clannfear",
		"alit",
		"kagouti",
		"mudcrab",
		"scamp",
		"dreugh",
		"scrib",
		"slaughterfish",
		"nix-hound",
		"skeleton",
		"kwama worker",
		"kwama warrior",
		"kwama queen",
		"ash_ghoul",
		"ancestor_ghost",
		"ash_slave",
		"ash_zombie",
		"shalk",
		"netch_bull",
		"netch_betty",
		"bonelord",
		"cliff racer",
		"corprus_stalker",
		"daedroth",
		"dremora",
		"dwarven ghost",
		"atronach_flame",
		"atronach_frost",
		"kwama forager",
		"corprus_lame",
		"ogrim",
		"atronach_storm",
		"rat",
		"hunger",
		"golden saint",
		"Bonewalker_Greater",
		"Slaughterfish_Small",
		"skeleton_weak",
		"durzog_wild",
		"BM_riekling",
		"BM_riekling_mounted",
		"BM_frost_boar",
		"BM_wolf_red",
		"BM_wolf_skeleton",
		"BM_draugr01",
		"ascended_sleeper",
		"goblin_grunt",
		"goblin_bruiser",
		"lich",
		"winged twilight",
		"T_Mw_Fau_BeetleBr_01",
		"T_Mw_Fau_BeetleBl_01",
		"T_Mw_Fau_BeetleGr_01",
		"T_Mw_Fau_BeetleHr_01",
		"T_Mw_Fau_MolecDs_01",
		"T_Mw_Und_BonewkGrPl_01",
		"T_Mw_Fau_Yethbug_01",
		"T_Mw_Fau_Orn_01",
	},
	soulgems = { ["misc_soulgem_petty"] = true, ["misc_soulgem_lesser"] = true, ["misc_soulgem_common"] = true, ["misc_soulgem_greater"] = true, ["misc_soulgem_grand"] = true },
}

---@class leveledFilledSoulGems.config
---@field logLevel mwseLoggerLogLevel
---@field filledChance number
---@field creatures string[]
---@field soulgems table<string,boolean>
local config = mwse.loadConfig(fileName, defaults)

local logging = require("logging.logger")
local log = logging.new({ name = fileName, logLevel = config.logLevel })

---@param soulgem tes3misc
---@return boolean
local function canBeFilled(soulgem) return config.soulgems[soulgem.id:lower()] == true end

---@param spawner tes3reference?
---@return boolean
local function spawnerFilled(spawner)
	if not spawner then return false end
	if not spawner.supportsLuaData then return false end
	if not spawner.data.filledSpawnerState then
		spawner.data.filledSpawnerState = 1
		local safeRef = tes3.makeSafeObjectHandle(spawner)
		if not safeRef then return false end
		timer.delayOneFrame(function()
			if safeRef:valid() then
				safeRef:getObject().data.filledSpawnerState = 2
				log:trace("processing spawner %s", spawner.id)
			end
		end)
		return false
	elseif spawner.data.filledSpawnerState == 1 then
		return false
	elseif spawner.data.filledSpawnerState == 2 then
		return true
	end
	return false
end

---@param creatureId string
---@param soulgem tes3misc
---@return tes3creature?
local function validForSoulGem(creatureId, soulgem)
	local soul = tes3.getObject(creatureId)
	if not soul then return end
	if soul.soul <= soulgem.soulGemCapacity and soul.soul / soulgem.soulGemCapacity >= 1 / 3 then return soul end
end

---@param soulgem tes3misc
---@return tes3creature? soul 
local function getRandomSoul(soulgem)
	local creatureId
	if math.random(100) > config.filledChance then return end
	local attempts = 0
	local MAX_ATTEMPTS = 100
	while attempts < MAX_ATTEMPTS do
		creatureId = table.choice(config.creatures)
		local soul = validForSoulGem(creatureId, soulgem)
		if soul then return soul end
		attempts = attempts + 1
	end
end

---@param e leveledItemPickedEventData
local function leveledItemPicked(e)
	if not e.spawner then return end
	if spawnerFilled(e.spawner) then return end
	log:trace("resolving %s in %s", e.list.id, e.spawner.id)
	local pick = e.pick
	log:trace("picked %s", pick and pick.id)
	if not pick then return end
	if not pick.isSoulGem then return end
	if not canBeFilled(pick) then return end
	local soul = getRandomSoul(pick)
	if not soul then
		log:trace("no soul is picked to filled %s", pick.id)
		return
	end
	log:trace("random soul %s is picked to filled %s", soul.id, pick.id)
	tes3.addItem({ reference = e.spawner, item = pick.id, soul = soul })
	e.pick = nil
end

event.register("initialized", function() event.register("leveledItemPicked", leveledItemPicked) end)

local function centerInfo(self)
	local info = self.elements.info
	info.absolutePosAlignX = 0.5
	info.widthProportional = nil
end

local function borderAllSides(self)
	local outerContainer = self.elements.outerContainer
	outerContainer.borderAllSides = 10
end

local function leftToRightSliderStyle(self)
	local outerContainer = self.elements.outerContainer
	outerContainer.flowDirection = tes3.flowDirection.leftToRight
end

local function leftToRightDropDownStyle(self)
	local outerContainer = self.elements.outerContainer
	outerContainer.flowDirection = tes3.flowDirection.leftToRight
	local labelBlock = self.elements.labelBlock
	labelBlock.wrapText = true
	local innerContainer = self.elements.innerContainer
	innerContainer.widthProportional = nil
	innerContainer.minWidth = 100
end

local function registerModConfig()
	local template = mwse.mcm.createTemplate { name = fileName }
	template:register()
	template:saveOnClose(fileName, config)
	local preferences = template:createPage({ label = "Mod Preferences", noScroll = true })
	preferences:createInfo({
		text = "\nLeveled Filled Soul Gems\n",
		postCreate = function(self)
			centerInfo(self)
			borderAllSides(self)
		end,
	})
	preferences:createInfo({
		text = "Created by JosephMcKean\n",
		postCreate = function(self)
			centerInfo(self)
			borderAllSides(self)
		end,
	})
	preferences:createSlider({
		label = "Filled Soul Gems Chance",
		min = 1,
		max = 100,
		step = 1,
		jump = 5,
		variable = mwse.mcm.createTableVariable { id = "filledChance", table = config },
		postCreate = function(self)
			leftToRightSliderStyle(self)
			borderAllSides(self)
		end,
	})
	preferences:createDropdown({
		label = "Set the log level to",
		options = {
			{ label = "TRACE", value = "TRACE" },
			{ label = "DEBUG", value = "DEBUG" },
			{ label = "INFO", value = "INFO" },
			{ label = "ERROR", value = "ERROR" },
			{ label = "NONE", value = "NONE" },
		},
		variable = mwse.mcm.createTableVariable({ id = "logLevel", table = config }),
		callback = function(self) log:setLogLevel(self.variable.value) end,
		postCreate = function(self)
			leftToRightDropDownStyle(self)
			borderAllSides(self)
		end,
	})
end
event.register("modConfigReady", registerModConfig)

