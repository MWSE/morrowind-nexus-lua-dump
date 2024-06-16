-- take from: https://github.com/MWSE/morrowind-nexus-lua-dump/blob/master/lua/Leeches%20Always%20Bite%20Twice/Leeches%20Always%20Bite%20Twice-53010-1-0-0-1685721478/MWSE/mods/leeches/quests/trailing.lua#L15

local lib = require("Flin.lib")
local log = lib.log

local this = {}

---@alias PathingCallback fun(timer: mwseTimer, data: FlinNpcData): any
---@type table<string, PathingCallback>
local pathingCallbacks = {}

--- Register a pathing callback.
---
---@param name string
---@param callback PathingCallback
function this.registerCallback(name, callback)
    pathingCallbacks[name] = callback
end

---@class PackageData
---@field type integer
-- activate
---@field target tes3reference|tes3mobileActor|nil
---@field reset boolean?
-- escort follow travel
---@field destination tes3vector3?
---@field duration integer?
---@field cell tes3cell|string|nil
-- wander
---@field idles integer[]?
---@field range integer?
---@field time integer?

---@class PathingData
---@field data FlinNpcData
---@field destination tes3vector3?
---@field onFinish string
---@field resetAi boolean

---@param data PathingData
function this.startPathing(data)
    timer.start({
        iterations = 40, -- 40 seconds
        duration = 0.1,
        callback = "flin:pathing:update", ---@diagnostic disable-line
        persist = true,
        data = data,
    })
end

local oldPackage = nil ---@type PackageData?
local pathingStarted = false

---@param nodes tes3aiPackageWanderIdleNode[]
---@return integer[]
local function convert(nodes)
    local idles = {} ---@type integer[]
    for _, node in ipairs(nodes) do
        table.insert(idles, node.chance)
    end
    return idles
end

---@param package tes3aiPackage
local function storeAiPackage(package)
    log:debug("Storing AI Package %s", package.type)

    oldPackage = {
        type = package.type,
        reset = true -- TODO
    }

    if package.type == tes3.aiPackage.activate then
        ---@cast package tes3aiPackageActivate
        oldPackage.target = package.activateTarget
    elseif package.type == tes3.aiPackage.escort then
        ---@cast package tes3aiPackageEscort
        oldPackage.target = package.targetActor
        oldPackage.destination = package.destination
        oldPackage.duration = package.duration
        oldPackage.cell = package.destinationCell
    elseif package.type == tes3.aiPackage.follow then
        ---@cast package tes3aiPackageFollow
        oldPackage.target = package.targetActor
        oldPackage.destination = package.destination
        oldPackage.duration = package.duration
        oldPackage.cell = package.destinationCell
    elseif package.type == tes3.aiPackage.travel then
        ---@cast package tes3aiPackageTravel
        oldPackage.destination = package.destination
    elseif package.type == tes3.aiPackage.wander then
        ---@cast package tes3aiPackageWander
        oldPackage.idles = convert(package.idles)
        oldPackage.range = package.distance
        oldPackage.duration = package.duration
        oldPackage.time = package.hourOfDay
    end
end

---@param ref tes3reference
---@param package PackageData
local function restoreAiPackage(ref, package)
    log:debug("Restoring AI for %s to %s", ref.id, package.type)

    if package.type == tes3.aiPackage.activate then
        tes3.setAIActivate({ reference = ref, target = package.target })
    elseif package.type == tes3.aiPackage.escort then
        tes3.setAIEscort({
            reference = ref,
            target = package.target,
            destination = package.destination,
            duration = package.duration,
            cell = package.cell
        })
    elseif package.type == tes3.aiPackage.follow then
        tes3.setAIFollow({
            reference = ref,
            target = package.target,
            destination = package.destination,
            duration = package.duration,
            cell = package.cell
        })
    elseif package.type == tes3.aiPackage.travel then
        tes3.setAITravel({ reference = ref, destination = package.destination })
    elseif package.type == tes3.aiPackage.wander then
        tes3.setAIWander({
            reference = ref,
            idles = package.idles,
            range = package.range,
            duration = package.duration,
            time = package.time
        })
    else
        -- dummy
        tes3.setAIWander({ reference = ref, idles = { 0, 0, 0, 0, 0, 0, 0, 0 } })
    end
end

---@param e mwseTimerCallbackData
local function update(e)
    ---@type PathingData
    local data = e.timer.data

    -- Get the reference.
    if not data.data.npcHandle:valid() then
        log:error("pathing: invalid handle")
        e.timer:cancel()
        return
    end

    local ref = data.data.npcHandle:getObject()
    if ref == nil then
        log:error("pathing: invalid reference")
        e.timer:cancel()
        return
    end

    -- Ensure the reference is alive.
    if ref.isDead then
        log:debug("pathing: dead reference (%s)", ref.id)
        e.timer:cancel()
        return
    end

    -- Ensure the reference is in an active cell.
    local mobile = ref.mobile
    if not (mobile and mobile.activeAI) then
        log:debug("pathing: inactive reference (%s)", ref.id)
        return
    end

    -- Start pathing.
    local package = ref.mobile.aiPlanner:getActivePackage()
    if not pathingStarted then
        -- store old package
        if not data.resetAi then
            if package then
                storeAiPackage(package)
            else
                -- if the npc has no active package, we need to store a dummy package
                oldPackage = {
                    type = tes3.aiPackage.none
                }
            end
        end

        -- Start pathing
        tes3.setAITravel({ reference = ref, destination = data.destination })
        pathingStarted = true
        log:debug("pathing: started (%s)", ref.id)
        return
    end

    -- Wait for pathing to finish.
    if not package.isDone then
        local iterationsLeft = e.timer.iterations
        log:trace("pathing: timeLeft (%s)", iterationsLeft)
        if iterationsLeft < 2 then
            -- skip to end
            package.isDone = true
        else
            return
        end
    end

    -- If we finished but we're not at the destination, teleport.
    if ref.position:distance(data.destination) > 1024 then
        tes3.positionCell({ reference = ref, position = data.destination })
    end

    -- Pop the destination.
    data.destination = nil

    -- Trigger the onFinish callback.
    if data.onFinish then
        local callback = assert(pathingCallbacks[data.onFinish])
        callback(e.timer, data.data)
    end

    -- All finished, end the timer.
    -- Reset the AI.
    if data.resetAi then
        restoreAiPackage(ref, oldPackage)
        oldPackage = nil
    end

    pathingStarted = false
    log:debug("pathing: finished (%s)", ref.id)
    e.timer:cancel()
end
timer.register("flin:pathing:update", update)

return this
