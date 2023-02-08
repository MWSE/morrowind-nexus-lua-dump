-- OAAB Glowbugs MWSE spawn manager
-->>>---------------------------------------------------------------------------------------------<<<--


-->>>---------------------------------------------------------------------------------------------<<<--
-- Imports

local re = require("re")
local config = require("OAAB.glowbugs.config")


-->>>---------------------------------------------------------------------------------------------<<<--
-- Variables

local activeBugs, bugCells, bugsVisible = {}, {}, {}

local glowbugs, WtC, wc


-->>>---------------------------------------------------------------------------------------------<<<--
-- Constants

local DISTANCE_OFFSET = 2048

local HEIGHTS = {20, 50, 85, 120, 250, 420, 630, 820, 950}

local ALLOWED_REGEX = re.compile[[ "flora" / "ab_f_" ]]
local DENIED_REGEX = re.compile[[ "kelp" / "lilypad" ]]


-->>>---------------------------------------------------------------------------------------------<<<--
-- Functions

--- Detect when bug references are created, and start tracking them.
---@param e referenceSceneNodeCreatedEventData
local function refCreated(e)
    local ref = e.reference
    if ref.sceneNode:hasStringDataWith("HasBugsRoot") then
        activeBugs[ref] = true
        local refCell = ref.cell
        if refCell then
            bugCells[refCell] = true
        end
    end
end


--- Detect when bug references are deleted, and stop tracking them.
---@param e objectInvalidatedEventData
local function refDeleted(e)
    local ref = e.object
    activeBugs[ref] = nil
    local refCell = ref.cell
    if refCell then
        bugCells[refCell] = nil
    end
end


--- Wait for one frame and then remove ref from activeBugs table and set it to delete.
---@param ref tes3reference
local function safeDelete(ref)
    timer.delayOneFrame(
        function()
            activeBugs[ref] = nil
            bugCells[ref.cell] = nil
            ref:delete()
        end
    )
end


--- Check if the ref comes from outside of an .esp file.
---@param ref tes3reference
---@return boolean
local function isSourcelessRef(ref)
    return not ref.sourceMod or string.endswith(ref.sourceMod, ".ess")
end


--- Toggle visibility for all currently active bugs references and update tracked cell table.
---@param state boolean
local function toggleBugsVisibility(state)
    local index = state and 1 or 0
    for ref, _ in pairs(activeBugs) do
        if isSourcelessRef(ref) and not state then
            safeDelete(ref)
        elseif ref and ref.sceneNode then
            local root = ref.sceneNode:getObjectByName("BugsRoot")
            if root and root.switchIndex ~= index then
                root.switchIndex = index
            end
        end
    end
end


--- Decimate the table to hold random items clamped by max density.
---@param t table
---@return table
local function getTrimmedPositions(t)
    local bugDensity = config.bugDensity
    local trimmedPositions = {}
    local numItems = math.min(bugDensity, #table.keys(t))
    for k, _ in pairs(t) do
        if math.random() < (numItems / bugDensity) then
            trimmedPositions[k] = true
        end
        if #table.keys(trimmedPositions) >= numItems then
            break
        end
    end
    return trimmedPositions
end


--- Check if object id matches our blacklist.
---@param id string
---@return boolean
local function isIdDenied(id)
    return re.find(id, DENIED_REGEX) ~= nil
end


--- Check if object id matches our whitelist.
---@param id string
---@return boolean
local function isIdAllowed(id)
    return (re.find(id, ALLOWED_REGEX) ~= nil) and not (isIdDenied(id))
end


--- Check if the position of the object is not too close to the player.
---@param playerPos tes3vector3
---@param pos tes3vector3
---@return boolean
local function isDistantObject(playerPos, pos)
    return playerPos:distance(pos) > DISTANCE_OFFSET
end


--- Iterate over objects of specific type in a cell and insert them into the table.
---@param t table
---@param objectType number
---@param cell tes3cell
---@param playerPos tes3vector3
local function iterObjects(t, objectType, cell, playerPos)
    for ref in cell:iterateReferences(objectType) do
        local id = ref.object.id:lower()
        local pos = ref.position:copy()
        if isIdAllowed(id) and isDistantObject(playerPos, pos) then
            if not t[pos] then
                t[pos] = true
            end
        end
	end
end


--- Scan cells for flora statics and containers and get a list of their positions.
---@param cell tes3cell
---@return table
local function getBugPositions(cell)
    local positions = {}
    local playerPos = tes3.player.position:copy()
    iterObjects(positions, tes3.objectType.static, cell, playerPos)
    iterObjects(positions, tes3.objectType.container, cell, playerPos)
    return table.keys(getTrimmedPositions(positions))
end

--- Get a random zpos from preset height data for a glowbug to spawn at.
---@return integer
local function getRandomZPos()
    local index = math.random(1, #HEIGHTS)
    return HEIGHTS[index]
end

--- Create references for available glowbugs per cell.
---@param availableBugs table
---@param cell tes3cell
local function spawnBugs(availableBugs, cell)
    local positions = getBugPositions(cell)
    if table.empty(positions) then return end

    local maxDensity = math.floor(config.bugDensity / #availableBugs)
    local orient = tes3vector3.new()

    for _, bug in ipairs(availableBugs) do
        for i = 1, maxDensity do
            local index = math.random(1, #positions)
            local pos = positions[index]
            tes3.createReference{
                object = bug,
                cell = cell,
                orientation = orient,
                position = {pos.x, pos.y, pos.z + getRandomZPos()}
            }
        end
    end

    toggleBugsVisibility(true)
end


--- Return a table with available glowbug types given the region id.
---@param regionID string
---@return table
local function getAvailableBugs(regionID)
    local availableBugs = {}
    for _, glowbugType in pairs(glowbugs) do
        if glowbugType.regions[regionID] and glowbugType.object then
            table.insert(availableBugs, glowbugType.object)
        end
    end
    return availableBugs
end


--- Check if it's dark.
---@param hour number
---@return boolean
local function isActiveHours(hour)
    return (hour <= WtC.sunriseHour + 1) or (hour >= WtC.sunsetHour + 1)
end


--- Check if the weather index matches clear weather types.
---@param weather number
---@return boolean
local function isValidWeather(weather)
    return weather < tes3.weather.rain
end


--- Check the roll chance for day chance.
---@param day number
---@return boolean
local function isValidDay(day)
    return bugsVisible[day]
end


--- Check if the cell is in the wilderness.
---@param cell tes3cell
---@return boolean
local function isWilderness(cell)
    return (not cell.name)
end


--- Check if the player's mobile is waiting or travelling.
---@return boolean
local function isPlayerAvailable()
    local mop = tes3.mobilePlayer
    return not (mop.waiting) and not (mop.traveling)
end

--- Condition check for active bugs. Runs once per hour.
local function conditionCheck()
    if not isPlayerAvailable() then return end
    local cell = tes3.player.cell
    if not cell then return end

    local isBugsVisible = true
    local availableBugs = {}

    if (cell.isOrBehavesAsExterior) then
        -- exterior cells require valid hours/weathers
        local hour = wc.hour.value
        local day = wc.daysPassed.value
        local weather = WtC.currentWeather.index
        local regionID = tes3.player.cell.region.id

        -- we don't want log spam if someone yeets our of worldspace
        if not regionID then return end

        -- percentage chance to spawn on any given day
        -- we only want to calculate this once per day!
        if bugsVisible[day] == nil then
            local roll = math.random(100)
            bugsVisible[day] = roll <= config.spawnChance
        end

        availableBugs = getAvailableBugs(regionID)

        isBugsVisible = isActiveHours(hour) and isValidWeather(weather) and isValidDay(day) and isWilderness(cell) and not (table.empty(availableBugs))
    end

    toggleBugsVisibility(isBugsVisible)

    if isBugsVisible and not (bugCells[cell]) then
        spawnBugs(availableBugs, cell)
    end
end


--- Register our condition check one frame after wait menu is destroyed.
---@param e uiActivatedEventData
local function onWaitMenu(e)
	local element = e.element
	element:registerAfter(tes3.uiEvent.destroy, function()
		timer.delayOneFrame(conditionCheck)
	end)
end


--- Detect when custom bug references are decativated, set them to delete stop tracking them.
---@param e referenceDeactivatedEventData
local function refDeactivated(e)
    local ref = e.reference
    if (activeBugs[ref]) and isSourcelessRef(ref) then
        safeDelete(ref)
    end
end


--- Harvest a single bug. Called on "activate" event.
---@param e activateEventData
---@return boolean|nil
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


--- Start a time to update bugs once per hour.
local function startBugsTimer()
    timer.start{
        type = timer.game,
        iterations = -1,
        duration = 1,
        callback = conditionCheck
    }
end


-->>>---------------------------------------------------------------------------------------------<<<--
-- Events

--- Register our events
event.register("initialized", function()
    if tes3.isModActive("OAAB_Data.esm") then
        event.register("referenceSceneNodeCreated", refCreated)
        event.register("objectInvalidated", refDeleted)
        event.register("referenceDeactivated", refDeactivated)
        event.register("cellChanged", conditionCheck)
        event.register("weatherTransitionFinished", conditionCheck)
        event.register("activate", harvestBugs, {priority = 600})
        event.register("loaded", startBugsTimer)
        event.register("uiActivated", onWaitMenu, { filter = "MenuTimePass"})

        WtC = tes3.worldController.weatherController
        wc = tes3.worldController

        glowbugs = {
            green = {
                object = tes3.getObject("AB_r_GlowbugsLargeGreen"),
                regions = config.greenBugsRegions
            },
            blue = {
                object = tes3.getObject("AB_r_GlowbugsLargeBlue"),
                regions = config.blueBugsRegions
            },
            red = {
                object = tes3.getObject("AB_r_GlowbugsLargeRed"),
                regions = config.redBugsRegions
            },
            violet = {
                object = tes3.getObject("AB_r_GlowbugsLargeViol"),
                regions = config.violetBugsRegions
            }
        }

    end
end)


--- Register MCM menu
event.register("modConfigReady", function()
    dofile("Data Files\\MWSE\\mods\\OAAB\\glowbugs\\mcm.lua")
end)
