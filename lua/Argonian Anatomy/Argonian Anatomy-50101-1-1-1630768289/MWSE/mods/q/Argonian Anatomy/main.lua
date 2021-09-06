
local config = include("q.Argonian Anatomy.config")

-- This function returns references to all actors in active cells, and optionally the Player reference.
-- A filter parameter can be passed (optional). Filter is a table with tes3.objectType.* constants. If no filter is passed, 
-- { tes3.objectType.npc } is used as a filter.
---@param includePlayer boolean
---@param filter table
---@return "tes3reference" reference
local function actorsInActiveCells(includePlayer, filter )
    includePlayer = includePlayer or false
    filter = filter or { tes3.objectType.npc }

    return coroutine.wrap(function()
        for _, cell in pairs(tes3.getActiveCells()) do
            for reference in cell:iterateReferences(filter) do
                coroutine.yield(reference)
            end
        end
        if includePlayer then
            coroutine.yield(tes3.player)
        end
    end)
end

---@param reference "tes3reference"
local function loadSkeleton(reference)
    if config[reference.object.race.id:lower()] then
        
        tes3.loadAnimation{
            reference = reference,
            file = "zilla\\base_animkna.nif"
        }
    end
end

local function processNPCs()
    for reference in actorsInActiveCells(false, { tes3.objectType.npc }) do
        loadSkeleton(reference)
    end
end

event.register("initialized", function ()
    event.register("loaded", function ()
        loadSkeleton(tes3.player)
    end)
    event.register("cellChanged", processNPCs)
end)

event.register("modConfigReady", function()
	dofile("q.Argonian Anatomy.mcm")
end)