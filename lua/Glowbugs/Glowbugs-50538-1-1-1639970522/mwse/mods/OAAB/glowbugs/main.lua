local bugObjects = {
    ["ab_o_glowbugsgrouplarge"] = true,
	["ab_o_glowbugsgroupsmall"] = true,
    ["ab_o_glowbugsgroup"] = true,
}


local activeBugs = {}


--- Detect when bug references are created, and start tracking them.
---
local function refCreated(e)
    if bugObjects[e.reference.baseObject.id:lower()] then
        activeBugs[e.reference] = true
    end
end
event.register("referenceActivated", refCreated)


--- Detect when bug references are deleted, and stop tracking them.
---
local function refDeleted(e)
    activeBugs[e.object or e.reference] = nil
end
event.register("referenceDeactivated", refDeleted)
event.register("objectInvalidated", refDeleted)


--- Toggle visibility for all currently active bugs references.
---
local function toggleBugsVisibility(state)
    local index = state and 1 or 0
    for ref in pairs(activeBugs) do
        if not ref.cell.isInterior then
            local root = ref.sceneNode:getObjectByName("BugsRoot")
            if root.switchIndex ~= index then
                root.switchIndex = index
            end
        end
    end
end


--- Global manager for active bugs. Runs once per hour.
---
local function updateBugs()
    if not next(activeBugs) then return end

    local wc = tes3.worldController

    local hour = wc.hour.value
    local weather = wc.weatherController.currentWeather.index

    local isActiveHours = (hour >= 18) or (hour <= 6)
    local isValidWeather = weather < tes3.weather.rain

    toggleBugsVisibility(isActiveHours and isValidWeather)
end
event.register("cellChanged", updateBugs)
event.register("weatherTransitionFinished", updateBugs)


--- Harvest a single bug. Called on "activate" event.
---
local function harvestBugs(e)
    if not activeBugs[e.target] then
        return
    end

    local rayHit = tes3.rayTest{
        position = tes3.getPlayerEyePosition(),
        direction = tes3.getPlayerEyeVector(),
        root = e.target.sceneNode,
    }
    if not (rayHit and rayHit.object) then
        return
    end

    -- hide the bug
    rayHit.object.parent.parent.parent.appCulled = true

    -- add the loot
    for _, stack in pairs(e.target.baseObject.inventory) do
        local item = stack.object
        if item.canCarry ~= false then
            if item.objectType == tes3.objectType.leveledItem then
                item = item:pickFrom()
            end
            if item then
                tes3.addItem{reference=e.activator, item=item}
                tes3.messageBox("You harvested %s %s.", stack.count, item.name)
            else
                tes3.playSound{reference=e.activator, sound="scribright"}
                tes3.messageBox("You failed to harvest anything of value.")
            end
        end
    end

    return false
end
event.register("activate", harvestBugs, {priority = 600})


--- Update bugs once per hour.
---
event.register("loaded", function()
    timer.start{
        type = timer.game,
        iterations = -1,
        duration = 1,
        callback = function()
            timer.delayOneFrame(updateBugs)
        end
    }
end)
