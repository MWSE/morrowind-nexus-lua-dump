local config = require("mer.Shinies.config")
local modName = config.modName

local logging = require("logging.logger")
local log = logging.new({ name = "Shinies", logLevel = config.logLevel })

local data

-- Container replacement-----------------------

local function rollForShiny()
	local rand = math.random(100)
	return rand < config.shinyChance
end

---@param ref tes3reference
local function replaceWithShiny(ref)
	local shinyId = table.choice(config.replacers) ---@type string
	if not tes3.getObject(shinyId) then
		log:debug("%s does not exist. ESP not loaded?", shinyId)
		return
	end
	log:debug("replacing %s with %s", ref.object.id, shinyId)
	local newRef = tes3.createReference { object = shinyId, position = ref.position:copy(), orientation = ref.orientation:copy(), cell = ref.cell }
	newRef.scale = ref.scale
	timer.delayOneFrame(function()
		ref:disable()
		ref:delete()
	end)
end

---@param cell tes3cell
local function getUniqueCellId(cell)
	if cell.isInterior then
		return cell.id:lower()
	else
		return string.format("%s (%s,%s)", cell.id:lower(), cell.gridX, cell.gridY)
	end
end

---@param ref tes3reference
local function canBeReplaced(ref) return config.replacees[ref.object.id:lower()] end

---@param e cellChangedEventData
local function addShinies(e)
	if not config.enabled then return end
	if not data then return end
	local cellId = getUniqueCellId(e.cell)
	-- have we added shinies to this cell already?
	if not data.shiniedCells[cellId] then
		log:debug("Adding shinies to %s", cellId)
		data.shiniedCells[cellId] = true

		---Look for containers to replace
		for ref in e.cell:iterateReferences(tes3.objectType.container) do
			if canBeReplaced(ref) then
				log:debug("%s can be replaced", ref.object.id)
				if rollForShiny() then replaceWithShiny(ref) end
			end
		end
	end
end

-- Inventory Shinies 
---@param ref tes3reference
local function addShiniesToActors(ref)
	if not ref.data then return end
	if not data then return end
	if not config.enabled then return end

	local obj = ref.object
	local baseObj = ref.baseObject
	for _, shinyData in ipairs(config.actorShinies) do
		if ref.data.hasShinyAdded then
			log:debug("%s has already had a shiny added.", obj.name)
		else
			local doAddShiny = false
			-- creatures
			if shinyData.creatureType then
				if baseObj.objectType == tes3.objectType.creature then
					---@cast baseObj tes3creature
					local isShinyCreature = baseObj.type == tes3.creatureType[shinyData.creatureType]
					if isShinyCreature then
						log:debug("Found Shiny %s", shinyData.creatureType)
						doAddShiny = true
					end
				end
			end
			-- npcs
			if shinyData.class then
				local isShinyNPC = (baseObj.objectType == tes3.objectType.npc) and (baseObj.class.id == shinyData.class)
				if isShinyNPC then doAddShiny = true end
			end

			if doAddShiny then
				ref.data.hasShinyAdded = true
				log:debug("Adding %s to %s", shinyData.shinyId, obj.name)
				local leveledItem = tes3.getObject(shinyData.shinyId)
				if not leveledItem then
					log:debug("Could not find %s, ESP not loaded?", shinyData.shinyId)
					return
				end
				if leveledItem.objectType ~= tes3.objectType.leveledItem then
					log:debug("%s is not a leveled Item!", shinyData.shinyId)
					return
				end
				---@cast leveledItem tes3leveledItem
				local pickedItem = leveledItem:pickFrom()
				tes3.addItem({ reference = ref, item = pickedItem, updateGUI = true })
			end
		end
	end

end

-- Data Initialisation
local function initData()
	log:debug("Init data")
	tes3.player.data.shinies = tes3.player.data.shinies or {}
	data = tes3.player.data.shinies
	data.shiniedCells = data.shiniedCells or {}

	-- because mobileActivated may have happened before data initialisation, 
	-- also add shinies here
	for ref in tes3.getPlayerCell():iterateReferences(tes3.objectType.npc) do addShiniesToActors(ref) end
	for ref in tes3.getPlayerCell():iterateReferences(tes3.objectType.creature) do addShiniesToActors(ref) end
end

event.register("initialized", function()
	event.register("loaded", initData)
	---@param e mobileActivatedEventData
	event.register("mobileActivated", function(e)
		local object = e.reference.baseObject
		if object.objectType == tes3.objectType.npc or object.objectType == tes3.objectType.cerature then addShiniesToActors(e.reference) end
	end)
	event.register("cellChanged", addShinies)
end)

-- MCM MENU
local function registerModConfig()
	local template = mwse.mcm.createTemplate { name = modName }
	template:saveOnClose(modName, config)
	template:register()

	local settings = template:createSideBarPage("Settings")
	settings.description = config.modDescription

	settings:createOnOffButton{ label = "Enable Shinies", description = "Turn the mod on or off.", variable = mwse.mcm.createTableVariable { id = "enabled", table = config } }
	settings:createSlider{
		label = "Replacement Chance",
		description = "The % chance that a chest will be replaced with a shiny.",
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable { id = "shinyChance", table = config },
	}
	settings:createDropdown({
		label = "Set the log level",
		options = {
			{ label = "TRACE", value = "TRACE" },
			{ label = "DEBUG", value = "DEBUG" },
			{ label = "INFO", value = "INFO" },
			{ label = "ERROR", value = "ERROR" },
			{ label = "NONE", value = "NONE" },
		},
		variable = mwse.mcm.createTableVariable { id = "logLevel", table = config },
		callback = function(self) for _, logger in pairs(logging.loggers) do logger:setLogLevel(self.variable.value) end end,
	})
end
event.register("modConfigReady", registerModConfig)
