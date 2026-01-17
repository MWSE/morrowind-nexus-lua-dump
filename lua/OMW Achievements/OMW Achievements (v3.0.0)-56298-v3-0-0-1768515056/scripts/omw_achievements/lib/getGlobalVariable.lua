local world = require('openmw.world')
local sk00maUtils = require('scripts.omw_achievements.utils.sk00maUtils')
local achievements = require('scripts.omw_achievements.achievements.achievements')

local function getGlobalVariable()
    local players = world.players
    for i = 1, #players do
        local globalVariables = world.mwscript.getGlobalVariables(players[i])
        for k = 1, #achievements do
            if achievements[k].type == "global_variable" then

                if achievements[k].operator(achievements[k], globalVariables[achievements[k].variable]) then
                    players[i]:sendEvent('gettingAchievement', {
                        id = achievements[k].id,
                        icon = achievements[k].icon,
                        bgColor = achievements[k].bgColor,
                        name = achievements[k].name,
                        description = achievements[k].description
                    })
                end

            end
        end
    end
end

local function getGlobalVariableProgress()
    local players = world.players

    for k = 1, #players do

        local globalVariables = world.mwscript.getGlobalVariables(players[k])
        local currentProgressTable = {}

        for i = 1, #achievements do
            if achievements[i].type == "global_variable" then
                local variable = achievements[i].variable
                local currentProgress = globalVariables[variable]
                currentProgressTable[variable] = currentProgress
            end
        end

        players[k]:sendEvent('updateGlobalVariables', sk00maUtils.tableToString(currentProgressTable))

    end

    -- --- Debug
    -- print("getGlobalVariableProgress: " .. variable .. ": " .. globalVariables[variable])
end

return {
    eventHandlers = {
        getGlobalVariable = getGlobalVariable,
        getGlobalVariableProgress = getGlobalVariableProgress
    }
}