-- compatibility/animatedMorrowindController.lua
---@omw-context global

local core = require('openmw.core')
local I = require('openmw.interfaces')

local M = {}

local function odarStaticActorInterface()
    local odar = I and I["ODAR"] or nil
    if not (odar and type(odar.staticActor) == "function") then return nil end
    return odar.staticActor
end

function M.registerExternalPlacementController(npc, position, controller)
    if controller ~= "odar_static_actor" then return false, "unsupported_controller" end
    local staticActor = odarStaticActorInterface()
    if not staticActor then return false, "odar_interface_missing" end

    -- ODAR accepts duplicate static actor entries and applies older entries last.
    -- Remove any previous pin first so a stale high-Z entry cannot win.
    pcall(staticActor, { object = npc, remove = true })
    local ok, err = pcall(staticActor, { object = npc, position = position })
    pcall(function()
        core.sendGlobalEvent("actorMonitor", { actor = npc, reset = false })
    end)
    if ok then return true, "odar_static_actor" end
    return false, err or "odar_static_actor_failed"
end

return M
