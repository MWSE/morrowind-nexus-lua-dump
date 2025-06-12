---@class ChargenScenariosRequirementsInput
---@field plugins? table<number, string> @A list of required plugins
---@field excludedPlugins? table<number, string> @the array of plugins that are excluded
---@field classes? table<number, string> @A list of required classes
---@field races? table<number, string> @A list of required races

--[[
    Represents a set of requirements for a scenario or location.
]]
---@class ChargenScenariosRequirements : ChargenScenariosRequirementsInput
local Requirements = {
    schema = {
        name = "Requirements",
        fields = {
            plugins = { type = "table", childType = "string", required = false },
            excludedPlugins = { type = "table", childType = "string", required = false },
            classes = { type = "table", childType = "string", required = false },
            races = { type = "table", childType = "string", required = false },
        }
    }
}

local function convertArrayToDict(tbl)
    local dict = {}
    for _, val in ipairs(tbl) do
        dict[val:lower()] = true
    end
    return dict
end

--Constructor
---@param data ChargenScenariosRequirementsInput
---@return ChargenScenariosRequirements
function Requirements:new(data)
    local requirements = {}
    --If no data provided, return an empty requirements object where check() always returns true
    if data then
        requirements.plugins = data.plugins or {}
        requirements.excludedPlugins = data.excludedPlugins or {}
        requirements.classes = convertArrayToDict(data.classes or {})
        requirements.races = convertArrayToDict(data.races or {})
    end
    setmetatable(requirements, self)
    self.__index = self
    return requirements
end

local function addRequirement(self, requirementType, value)
    local requirementTypes = {
        plugins = true,
        classes = true,
        races = true,
        excludedPlugins = true
    }
    assert(type(requirementType) == "string", "requirementType must be a string")
    assert(requirementTypes[requirementType],
        string.format("%s is not a valid requirement type. Available options are: %s.",
            requirementType, table.concat(table.keys(requirementTypes), ", ")))
    assert(type(value) == "string", string.format("% needs to be a string", requirementType))
    self[requirementType][value:lower()] = true
end

function Requirements:addPlugin(plugin)
    addRequirement(self, "plugins", plugin)
end

function Requirements:addClass(class)
    addRequirement(self, "classes", class)
end

function Requirements:addRace(race)
    addRequirement(self, "races", race)
end

function Requirements:addExcludedPlugin(plugin)
    addRequirement(self, "excludedPlugins", plugin)
end


function Requirements:checkPlugins()
    if self.plugins and #self.plugins > 0 then
        for _, plugin in ipairs(self.plugins) do
            if not tes3.isModActive(plugin) then
                return false
            end
        end
    end
    return true
end

function Requirements:checkExcludedPlugins()
    if self.excludedPlugins and #self.excludedPlugins > 0 then
        for _, plugin in ipairs(self.excludedPlugins) do
            if tes3.isModActive(plugin) then
                return false
            end
        end
    end
    return true
end

function Requirements:checkClass()
    if self.classes and table.size(self.classes) > 0 then
        local playerClass = tes3.player.object.class.id:lower()
        return self.classes[playerClass] == true
    end
    return true
end

function Requirements:checkRace()
    if self.races and table.size(self.races) > 0 then
        local playerRace = tes3.player.object.race.id:lower()
        return self.races[playerRace] == true
    end
    return true
end

function Requirements:check()
    return self:checkPlugins()
    and self:checkExcludedPlugins()
    and self:checkClass()
    and self:checkRace()
end

function Requirements:getDescription()
    local description = {"Требования: "}
    local raceTranslations = {
        ["argonian"] = "аргонианин",
        ["khajiit"] = "хаджит"
    }
    if self.plugins and #self.plugins > 0 then
        table.insert(description, string.format("- Плагины: %s", table.concat(self.plugins, ", ")))
    end
    if self.races and table.size(self.races) > 0 then
        --table.insert(description, string.format("- Раса: %s", table.concat(table.keys(self.races), ", ")))
        local translatedRaces = {}
        for raceId in pairs(self.races) do
            table.insert(translatedRaces, raceTranslations[raceId:lower()] or raceId)
        end
        table.insert(description, string.format("- Раса: %s", table.concat(translatedRaces, ", ")))
    end
    if self.classes and table.size(self.classes) > 0 then
        table.insert(description, string.format("- Класс: %s", table.concat(table.keys(self.classes), ", ")))
    end
    return #description > 1 and table.concat(description, "\n") or ""
end


return Requirements