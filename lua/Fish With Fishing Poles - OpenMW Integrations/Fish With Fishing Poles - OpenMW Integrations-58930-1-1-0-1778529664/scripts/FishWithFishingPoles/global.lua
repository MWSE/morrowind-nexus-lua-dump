local world = require("openmw.world")
local core = require("openmw.core")
local mwscript = world.mwscript

local isFishing = {}
local fishingCount = 0

local checkInterval = 0.1 -- Should be low enough to feel responsive (e.g. skill raise notifications)
local checkTimer = 0

local function doCheck()
    for _, player in ipairs(world.players) do
        local script = mwscript.getGlobalScript('a_lets_fish', player)

        if script then
            local fishing = script.variables.playerfishing == 1

            if isFishing[player.id] ~= true and fishing then
                -- Started fishing
                if isFishing[player.id] == false then
                    -- Don't trigger from nil, only from false to true, to avoid triggering on load
                    player:sendEvent('FWFP_StartFishing')
                end
                fishingCount = fishingCount + 1
            elseif isFishing[player.id] == true and not fishing then
                -- Stopped fishing
                fishingCount = math.max(fishingCount - 1, 0)
            end

            isFishing[player.id] = fishing
        end
    end
end

local function onUpdate(dt)
    if dt == 0 then return end

    if fishingCount > 0 then
        checkTimer = 0
    end

    if checkTimer > 0 then
        checkTimer = checkTimer - dt
    else
        checkTimer = checkInterval
        doCheck()
    end
end

local globals = mwscript.getGlobalVariables()
if globals and globals.fishingoatr then
    local activeLibraries = 0
    if core.contentFiles.has('OAAB_Data.esm') or (globals.ab_enchantbonus ~= nil) then
        activeLibraries = 1
    end

    if core.contentFiles.has('Tamriel_Data.esm') or (globals.t_glob_passtimehours ~= nil) then
        activeLibraries = activeLibraries + 2
    end

    globals.fishingoatr = activeLibraries
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
    eventHandlers = {
        FWFP_AdjustGlobal = function(data)
            local globals = mwscript.getGlobalVariables(data.player)
            if globals and globals.fishingcastcount then
                globals.fishingcastcount = data.value
            end
        end,
    }
}