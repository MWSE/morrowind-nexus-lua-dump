local sb_autocomplete = require("sb_autocomplete.interop")
local command_data = require("sb_auto_mcc.autocomplete.command_data")
local data = require("JosephMcKean.commands.data")

local commands_with_params = {
    "addall",
    "additem",
    "addone",
    "coc",
    "join",
    "levelup",
    "position",
    "recall",
    "set",
    "spawn",
    "weather"
}

local params = {
    { command_data.suggestObjectType, "" },
    { command_data.suggestItem,       "" },
    { command_data.suggestItem,       "" },
    { command_data.suggestCell },
    { command_data.suggestFaction,    "" },
    { command_data.suggestSkill,      "" },
    { command_data.suggestNPC },
    { command_data.suggestMark },
    { command_data.suggestAttribute,  "" },
    { command_data.suggestObject },
    { command_data.suggestWeather }
}

local function init()
    for command, value in pairs(data.commands) do
        sb_autocomplete:registerSuggestion(command, "lua")
    end

    for index, command in ipairs(commands_with_params) do
        sb_autocomplete:registerCommand(command, "lua", params[index])
    end
end

event.register("initialized", init)
