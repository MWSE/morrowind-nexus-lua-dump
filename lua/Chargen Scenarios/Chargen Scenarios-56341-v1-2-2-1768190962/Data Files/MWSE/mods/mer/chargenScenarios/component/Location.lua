---@class (exact) ChargenScenariosLocationInput
---@field name string? @The name of the location, required for scenarios where you can choose the location
---@field position table<number, number> @The position where the player will be spawned
---@field orientation number @The orientation where the player will be spawned
---@field cellId? string @The cell where the player will be spawned. Nil for exteriors
---@field items? table<number, ChargenScenariosItemPickInput> @The items to add to the player's inventory. Overrwrites items defined in parent scenario
---@field requirements? ChargenScenariosRequirementsInput @The requirements that need to be met for this location to be used
---@field onStart? fun(self: ChargenScenariosLocation):string @Callback triggered when a scenario starts at this location
---@field clutter nil|string[]|ChargenScenariosClutterInput[] @The clutter for the location

local common = require("mer.chargenScenarios.common")
local logger = common.createLogger("Location")
local Validator = require("mer.chargenScenarios.util.validator")
local ItemList = require("mer.chargenScenarios.component.ItemList")
local ItemPick = require("mer.chargenScenarios.component.ItemPick")
local Requirements = require("mer.chargenScenarios.component.Requirements")
local ClutterList = require("mer.chargenScenarios.component.ClutterList")


---@class ChargenScenariosLocation : ChargenScenariosLocationInput
---@field items? ChargenScenarios.ItemList
---@field requirements ChargenScenariosRequirements
---@field clutterList? ChargenScenariosClutterList
local Location = {
    registeredLocations = {},
    --input schema, not identical to final object structure
    schema = {
        name = "Location",
        fields = {
            position = { type = "table", childType = "number", required = true },
            orientation = { type = "number", required = true },
            cellId = { type = "string", required = false },
            items = { type = "table", childType = ItemPick.schema, required = false },
            requirements = { type = Requirements.schema, required = false },
            onStart = { type = "function", required = false, default = function() end },
        }
    }
}

---Register a location that can be used in multiple scenarios
---@param id string @The id of the location
---@param locationData ChargenScenariosLocationInput @The location data
function Location.register(id, locationData)
    local location = Location:new(locationData)
    Location.registeredLocations[id] = location
    return location
end

function Location.get(id)
    return Location.registeredLocations[id]
end

--Constructor
---@param data ChargenScenariosLocationInput
---@return ChargenScenariosLocation
function Location:new(data)
    --Validate
    Validator.validate(data, self.schema)


    ---@type ChargenScenariosLocation
    local location = {
        name = data.name,
        position = data.position,
        orientation = data.orientation,
        cellId = data.cellId,
        requirements = Requirements:new(data.requirements),
        onStart = data.onStart,
        clutterList = data.clutter and ClutterList:new(data.clutter),
    }
    --Create Location
    setmetatable(location, self)
    self.__index = self

    --Add items
    location.items = data.items and ItemList:new{
        name = "Location: " .. location:getName(),
        active = true,
        items = data.items,
    }

    return location
end

function Location:moveTo()
    logger:debug("Moving to location: %s\n %s", self.cellId, json.encode(self.position))
    return tes3.positionCell{
        reference = tes3.player,
        position = self.position,
        orientation = {
            0, 0, self.orientation
        },
        cell = self.cellId
    }
end

function Location:doItems()
    if self.items then
        return self.items:doItems()
    end
end

function Location:isValid()
    return self.requirements:check()
        and self:checkCellValid()
end

function Location:checkCellValid()
    if self.cellId then
        return tes3.getCell{ id = self.cellId } ~= nil
    else
        return tes3.getCell{ position = self.position } ~= nil
    end
end

function Location:doIntro()
    if self.onStart then
        return self.onStart(self)
    end
end

---@param self ChargenScenariosLocation
function Location.doClutter(self)
    if self.clutterList then
        return self.clutterList:doClutter()
    end
end

--Checks name, then cell, then region
function Location:getName()
    if self.name then
        return self.name
    end
    if self.cellId then
        return self.cellId
    end
    local cell = tes3.getCell{ position = self.position }
    if cell and cell.region then
        return cell.region.name
    end
    return "Unknown Location"
end

return Location