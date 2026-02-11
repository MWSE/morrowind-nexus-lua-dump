local common = require("mer.chargenScenarios.common")
local logger = common.createLogger("Scenario")
local ItemList = require("mer.chargenScenarios.component.ItemList")
local Location = require("mer.chargenScenarios.component.Location")
local Requirements = require("mer.chargenScenarios.component.Requirements")
local SpellList = require("mer.chargenScenarios.component.SpellList")
local ClutterList = require("mer.chargenScenarios.component.ClutterList")

---@class ChargenScenariosScenarioInput
---@field id string A unique ID for the scenario
---@field name string The name of the Scenario. Will be displayed in the scenario selection menu.
---@field description string The description of the Scenario. Will be displayed in the scenario selection menu.
---@field location nil|string|ChargenScenariosLocationInput The location of the scenario. If used instead of 'locations', this location will be used for the scenario.
---@field locations nil|string[]|ChargenScenariosLocationInput[] A list of locations. If used instead of 'location', one from this list will be randomly selected for the scenario.
---@field items nil|ChargenScenariosItemPickInput[] A list of items that will be added to the player's inventory.
---@field spells nil|ChargenScenariosSpellPickInput[] A list of spells that will be added to the player
---@field requirements nil|ChargenScenariosRequirementsInput The requirements that need to be met for this scenario to be used.
---@field clutter nil|string|ChargenScenariosClutterInput[] The clutter for the location. Can be a list of clutter data or a cluterList ID
---@field onStart nil|fun(self: ChargenScenariosScenario) Callback triggered when a scenario starts.
---@field weather? tes3.weather|`random` (Default: tes3.weather.clear) The weather for the scenario
---@field time? number The starting time
---@field journalEntry? string A custom journal entry that is written as soon as the scenario starts
---@field journalUpdates? { id: string, index: number, showMessage: boolean }[] A list of journal entries that are updated when the scenario starts
---@field topics? string[] A list of topics that are added when the scenario starts
---@field factions? { id: string, rank?: number }[] (Default rank: 0) A list of factions and ranks that the player is added to when the scenario starts.

---@class (exact) ChargenScenariosScenario : ChargenScenariosScenarioInput
---@field getSelectedScenario fun():ChargenScenariosScenario Get the selected scenario
---@field setSelectedScenario fun(scenario:ChargenScenariosScenario) Set the selected scenario
---@field requirements ChargenScenariosRequirements the requirements for the scenario
---@field locations ChargenScenariosLocation[] the list of locations for the scenario
---@field itemList ChargenScenarios.ItemList the list of items for the scenario
---@field spellList? ChargenScenariosSpellList the list of spells given to the player for this scenario. May include abilities, diseases etc
---@field clutterList? ChargenScenariosClutterList the clutter for the location
---@field decidedLocation? ChargenScenariosLocation the index of the location that was decided for this scenario
---@field registeredScenarios table<string, ChargenScenariosScenario> the list of registered scenarios
---@field weather tes3.weather|`random` The weather for the scenario
local Scenario = {
    registeredScenarios = {},
}

local selectedScenario
event.register("loaded", function()
    selectedScenario = nil
end)

---@return ChargenScenariosScenario
function Scenario.getSelectedScenario()
    return selectedScenario or Scenario.registeredScenarios.vanilla
end

---@param scenario ChargenScenariosScenario
function Scenario.setSelectedScenario(scenario)
    selectedScenario = scenario
end

--- Construct a new Scenario
---@param data ChargenScenariosScenarioInput
---@return ChargenScenariosScenario
function Scenario:new(data)
    --resolve location/locations
    local locationList = data.location and {data.location} or data.locations

    --Resolve clutter
    local clutter
    if type(data.clutter) == "string" then
        clutter = ClutterList.get(clutter)
    else
        clutter = data.clutter and ClutterList:new(data.clutter)
    end

    local scenario = {
        id = data.id,
        name = data.name,
        description = data.description,
        requirements = Requirements:new(data.requirements),
        locations = locationList and common.convertListTypes(locationList, Location) or {},
        itemList = ItemList:new{
            name = "Scenario: " .. data.name,
            items = data.items or {},
            active = true,
        },
        items = data.items,
        spellList = data.spells and SpellList:new(data.spells),
        clutterList = clutter,
        onStart = data.onStart,
        time = data.time,
        weather = data.weather or tes3.weather.clear,
        journalEntry = data.journalEntry,
        journalUpdates = data.journalUpdates,
        topics = data.topics,
        factions = data.factions,
    }

    --Create scenario
    setmetatable(scenario, { __index = Scenario })

    event.register("loaded", function()
        scenario.decidedLocation = nil
        scenario.itemList.active = scenario.itemList.defaultActive
    end)

    return scenario --[[@as ChargenScenariosScenario]]
end

--- Register a new scenario
---@param data ChargenScenariosScenarioInput
---@return ChargenScenariosScenario
function Scenario:register(data)
    local scenario = self:new(data)
    logger:debug("Adding %s to scenario list", scenario.name)
    Scenario.registeredScenarios[scenario.id] = scenario
    return scenario
end

--- Add a location to the scenario
---@param locationInput ChargenScenariosLocationInput
function Scenario:addLocation(locationInput)
    local location = Location:new(locationInput)
    table.insert(self.locations, location)
end

--- Add an item to the scenario
---@return ChargenScenariosLocation?
function Scenario:getStartingLocation()
    if not self.locations then
        logger:error("Scenario %s has no locations", self.name)
    end
    --Decide starting location once
    if self.decidedLocation then
        return self.decidedLocation
    end
    local validLocations = self:getValidLocations()
    if #validLocations == 0 then
        logger:error("No valid locations for scenario %s", self.name)
        return nil
    end
    self.decidedLocation = table.choice(validLocations)
    return self.decidedLocation
end

---@return ChargenScenariosLocation[]
function Scenario:getValidLocations()
    local validLocations = {}
    for _, location in pairs(self.locations) do
        if location:isValid() then
            table.insert(validLocations, location)
        end
    end
    return validLocations
end

--- Move the player to the starting location
function Scenario:moveToLocation()
    if not self.locations then
        logger:error("Scenario %s has no locations", self.name)
    end
    return self:getStartingLocation():moveTo()
end

--- Check if the scenario can be used
---@return boolean
function Scenario:checkRequirements()
    return self.requirements:check()
end

--- Check if the scenario has a valid location
---@return boolean
function Scenario:hasValidLocation()
    if not self.locations then
        logger:error("Scenario %s has no locations", self.name)
        return false
    end
    return #self:getValidLocations() > 0
end

function Scenario:isVisible()
    return self:hasValidLocation()
        and self.requirements:checkPlugins()
        and self.requirements:checkExcludedPlugins()
end



--- Place the clutter for this scenario
---@return tes3reference[]|nil
function Scenario:doClutter()
    local locationAddedClutter = self:getStartingLocation():doClutter()
    if locationAddedClutter then
        return locationAddedClutter
    elseif self.clutterList then
        return self.clutterList:doClutter()
    end
end

--- Give the player spells for this scenario
function Scenario:doSpells()
    if self.spellList then
        return self.spellList:doSpells()
    end
end

--- Update current weather to the scenario weather
function Scenario:doWeather()
    local weather = self.weather
    if weather == "random" then
        logger:debug("Random weather")
        weather = table.choice(tes3.weather)
    end
    logger:debug("Setting weather to %s", table.find(tes3.weather, weather))
    tes3.changeWeather{
        immediate = true,
        id = weather,
    }
end

---Update the current game time to the scenario time
function Scenario:doTime()
    if self.time then
        tes3.worldController.hour.value = self.time
    end
end

function Scenario:doJournal()
    if self.journalUpdates then
        for _, update in ipairs(self.journalUpdates) do
            logger:debug("Updating journal %s to %s", update.id, update.index)
            tes3.updateJournal{ id = update.id, index = update.index or 1, showMessage = update.showMessage }
        end
    end
    if self.journalEntry then
        tes3.addJournalEntry{ text = self.journalEntry, showMessage = true }
    end
end

function Scenario:doTopics()
    if self.topics then
        for _, topic in ipairs(self.topics) do
            mwse.log("Adding topic %s", topic)
            tes3.addTopic{
                topic = topic,
            }
        end
    end
end

---Do factions
function Scenario:doFactions()
    if self.factions then
        for _, factionData in ipairs(self.factions) do
            local faction = tes3.getFaction(factionData.id)
            if faction then
                faction.playerJoined = true
                faction.playerRank = factionData.rank or 0
            end
        end
    end
end

--- Do the location and scenario callbacks
function Scenario:doIntro()
    if self.onStart then
        self:onStart()
    end
    local location = self:getStartingLocation()
    if location and location.onStart then
        location:onStart()
    end
end

--- Start the scenario
function Scenario:start()
    self:doTime()
    self:moveToLocation()
    self:doWeather()
    self:doClutter()
    timer.delayOneFrame(function()
        event.trigger("ChargenScenarios:ScenarioStarted", {scenario = self})
        self:doSpells()
        self:doJournal()
        self:doTopics()
        self:doFactions()
        self:doIntro()
    end)
end

return Scenario