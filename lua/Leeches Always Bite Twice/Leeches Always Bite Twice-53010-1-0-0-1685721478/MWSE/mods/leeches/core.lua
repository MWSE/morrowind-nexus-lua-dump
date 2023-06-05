local utils = require("leeches.utils")
local Leeches = require("leeches.leeches")

local TICK_RATE = 0.75

---@type table<tes3reference, boolean>
local leechedReferences = {}


--- Attach leeches to actors currently standing in scum.
---
--- Runs on a timer every `TICK_RATE` seconds.
---
---@param timestamp number
local function globalAttachLeeches(timestamp)
    for ref in utils.bitterCoastActorRefs() do
        if math.random() < utils.getAttachChance(ref)
            and utils.isInWater(ref)
        then
            local leeches = Leeches.getOrCreate(ref)
            leeches:addLeech(ref, timestamp)
            leechedReferences[ref] = true
        end
    end
end


--- Detach leeches that are past their expireTime.
---
--- Runs on a timer every `TICK_RATE` seconds.
---
---@param timestamp number
local function globalDetachLeeches(timestamp)
    for ref in pairs(leechedReferences) do
        local leeches = Leeches.get(ref)
        if leeches then
            leeches:removeExpired(ref, timestamp)
            if leeches:numActive() == 0 then
                leechedReferences[ref] = nil
            end
        end
    end
end


--- Timer to periodically run the above functions.
---
event.register("loaded", function()
    timer.start({
        iterations = -1,
        duration = TICK_RATE,
        callback = function()
            local timestamp = tes3.getSimulationTimestamp()
            globalDetachLeeches(timestamp)
            globalAttachLeeches(timestamp)
        end,
    })
end)


--- Allow shaking off leeches by attacking.
---
---@param e attackEventData
local function onAttack(e)
    local ref = e.reference

    local leeches = Leeches.get(ref)
    if leeches == nil then
        return
    end

    -- Remove 15% of leeches on each attack.
    local numActive = leeches:numActive()
    local numRemove = math.max(math.ceil(numActive * 0.15), 4)
    for _ = 1, numRemove do
        local leech = leeches:getOldestActiveLeech()
        if leech then
            leeches:removeLeech(ref, leech)
        end
    end

    if leeches:numActive() == 0 then
        leechedReferences[ref] = nil
    end
end
event.register("attack", onAttack)


--- Prevent resting while leeches are attached.
---
---@param e calcRestInterruptEventData
event.register("calcRestInterrupt", function(e)
    local leeches = Leeches.get(tes3.player)
    if leeches and leeches:numActive() > 0 then
        e.claim = true
        tes3.wakeUp()
        tes3.messageBox("You can't rest with leeches on you.")
    end
end, { priority = 1000 })


--- Stop tracking references when deactivated.
---
event.register("referenceDeactivated", function(e)
    leechedReferences[e.reference] = nil
end)


--- Start tracking references if re-activated.
---
event.register("referenceActivated", function(e)
    local leeches = Leeches.get(e.reference)
    if leeches == nil then
        return
    end

    for leech in leeches:iterActiveLeeches() do
        leech:addVisuals(e.reference)
    end

    leeches:addSounds(e.reference)

    leechedReferences[e.reference] = true
end)
