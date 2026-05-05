local I = require("openmw.interfaces")
local storage = require("openmw.storage")

local settings = storage.playerSection("SettingsCharacterTraits")
local API = I.StatsWindow
local C = API.Constants
local namespace = "CharacterTraits_"

local statsWindow = {}

-- capitalizes every word
local function capitalize(str)
    return (str:gsub("(%a)([%w']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end))
end

local function initTraitLine(lineName, trait)
    API.addLineToSection(
        lineName,
        C.DefaultSections.LEVEL_STATS,
        {
            label = capitalize(trait.type),
            labelColor = C.Colors.DEFAULT_LIGHT,
            value = function()
                return { string = trait.name }
            end,
            tooltip = function()
                return API.TooltipBuilders.HEADER(trait.name, trait.description)
            end
        })
end

local function modifyTraitLine(lineName, trait)
    API.modifyLine(
        lineName,
        {
            value = function()
                return { string = trait.name }
            end,
            tooltip = function()
                return API.TooltipBuilders.HEADER(trait.name, trait.description)
            end
        })
end

statsWindow.updateTraitLine = function(trait)
    if trait.id == "nil" and not settings:get("displayNilTraits") then return end

    local lineName = namespace .. trait.type
    if not API.getLine(lineName) then
        initTraitLine(lineName, trait)
    else
        modifyTraitLine(lineName, trait)
    end
end

return statsWindow
